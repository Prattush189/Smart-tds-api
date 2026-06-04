#!/usr/bin/env python3
# Converts the SQL Server data dump (script.txt) -> PostgreSQL seed files,
# one per database (masterdbtds / smarttds25 / smarttds26).
#
# Handles, per the project's locked PG conversion rules:
#   * strips [dbo]. and [brackets]; lowercases all identifiers
#   * quotes reserved columns ("limit","desc")  (defensive; none in this data)
#   * N'...'                  -> '...'
#   * CAST(N'...' AS DateTime)-> '...'           (string literal -> timestamp col)
#   * bare 0x (empty varbinary) -> NULL          (profilepic)
#   * bit 0/1 -> false/true for known boolean columns (PG16 cast is explicit-only)
#   * Users.pwd plaintext     -> PBKDF2-HMAC-SHA256 hash (matches API PasswordHasher)
#   * EXCLUDES reference/master tables already seeded by 03_master_seed_data.sql
#   * resets identity sequences at end of each file
import re, os, base64, hashlib, sys

SRC = r"C:\Users\Prattush\Downloads\script.txt"
OUT = os.path.dirname(os.path.abspath(__file__))

# ---- reference tables already seeded by the migration: skip to avoid PK clashes
SKIP = {"applicationparams_master": True}  # see DB-specific skip below
SKIP_MASTER = {"applicationparams", "aymaster", "check_period", "country",
               "district", "state", "tdsded80", "tdsentriessection",
               "tdsnature", "tdsrate"}

# ---- boolean columns per table (from 01/02 schema)
BOOL = {
    "assessee": {"auditcase", "isdeleted", "whetherint", "pendingbill"},
    "assesseerep": {"isdeleted"},
    "bankdetails": {"isdeleted"},
    "billhead": {"isdeleted"},
    "consultant": {"flagdefault", "flagpendingbillsnotifications", "isdeleted"},
    "feepaidmarking": {"feepaid"},
    "groups": {"isdeleted"},
    "returndates": {"addresschangeorg", "addresschangeauth",
                    "isregularstatement", "isnilreturn"},
    "users": {"assesseeaddflag", "assesseeeditflag", "assesseedeleteflag",
              "viewpwdflag", "backupflag", "restoreflag", "efilingflag",
              "rptviewflag", "editfiledreturnflag", "isdeleted"},
    "addchallan": {"isfromitdportal"},
    "ddodet": {"isdeleted"},
    "f15hn": {"isdeleted"},
    "f15hnpayee": {"isdeleted"},
    "payee": {"freezepan", "dirflag"},
    "salary": {"whethermetro", "deductionundersection16iaflag"},
    "tdscompincome": {"isdeleted"},
    "tdsdeduction": {"senior", "ssenior", "severe", "isdeleted"},
    "tdsentry": {"evalid"},
}

# ---- identity column per table (for setval at end)
IDCOL = {
    "assessee": "subcode", "assesseerep": "id", "assesseeresstatus": "id",
    "bankdetails": "id", "billdetails": "id", "billhead": "id",
    "consultant": "conscode", "feepaidmarking": "id", "groups": "grpcode",
    "returndates": "id", "users": "userid",
    "addchallan": "id", "applicationparams": "id", "filingstatus": "id",
    "payee": "id", "salary": "id", "salarynaturedetails": "id",
    "tdscompincome": "id", "tdsdeduction": "id", "tdsentry": "id",
}

# source-col -> actual PG schema-col, where the PG schema renamed/typo'd a name
COLMAP = {
    "assessee": {"aadhaarenrolment": "aadhaarnrolment",
                 "aadhaarstatus": "aadharstatus",
                 "leivalidupto": "leivaldupto"},
    "returndates": {"aoapprovalno": "aoapprovalnu"},
}

RESERVED = {"limit", "desc", "user", "order", "group", "check", "default",
            "references", "primary", "foreign", "column", "table", "select",
            "where", "from", "values", "on", "offset", "distinct"}

DB_FILE = {
    "MasterDbTds": ("masterdbtds", "seed_data_prats_master.sql"),
    "SmartTds25": ("smarttds25", "seed_data_prats_25.sql"),
    "SmartTds26": ("smarttds26", "seed_data_prats_26.sql"),
}


def pbkdf2(password):
    salt = os.urandom(16)
    h = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, 100_000, 32)
    return "pbkdf2$100000$%s$%s" % (
        base64.b64encode(salt).decode(), base64.b64encode(h).decode())


def split_tuple(s):
    """Split a VALUES body into top-level fields, respecting '...' and parens."""
    out, depth, inq, start = [], 0, False, 0
    i = 0
    while i < len(s):
        ch = s[i]
        if inq:
            if ch == "'":
                if i + 1 < len(s) and s[i + 1] == "'":
                    i += 1
                else:
                    inq = False
        else:
            if ch == "'":
                inq = True
            elif ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
            elif ch == "," and depth == 0:
                out.append(s[start:i]); start = i + 1
        i += 1
    out.append(s[start:])
    return out


INSERT_RX = re.compile(
    r"^INSERT\s+\[dbo\]\.\[(?P<tbl>[^\]]+)\]\s*\((?P<cols>[^)]*)\)\s+VALUES\s+\((?P<vals>.*)\)\s*$",
    re.DOTALL)
CAST_RX = re.compile(r"CAST\(\s*('(?:[^']|'')*')\s+AS\s+DateTime\)", re.IGNORECASE)


def convert():
    text = open(SRC, encoding="utf-8", errors="replace").read()
    # split into batches on the 'GO' separator (own line). Values may contain
    # embedded newlines, so a line-based parse would split rows incorrectly.
    batches = re.split(r"(?m)^GO\s*$", text)
    buckets = {k: [] for k in DB_FILE}      # db -> list of insert strings
    tables_seen = {k: [] for k in DB_FILE}  # db -> ordered unique tables
    db = None
    stats = {}
    kept_sub = set()   # subcodes of assessees we keep (non-deleted)
    kept_bill = set()  # billhead ids we keep
    kept_sal = set()   # salary ids we keep
    dropped = {}       # (db, table, reason) -> count
    for batch in batches:
        b = batch.strip()
        mu = re.match(r"^USE \[(\w+)\]", b)
        if mu:
            db = mu.group(1)
            continue
        if not b.startswith("INSERT"):
            continue
        m = INSERT_RX.match(b)
        if not m or db not in DB_FILE:
            continue
        tbl = m.group("tbl").lower()
        if db == "MasterDbTds" and tbl in SKIP_MASTER:
            continue

        cols = [c.strip().strip("[]").lower() for c in m.group("cols").split(",")]
        remap = COLMAP.get(tbl, {})
        cols = [remap.get(c, c) for c in cols]
        cols_out = ", ".join('"%s"' % c if c in RESERVED else c for c in cols)

        vals = m.group("vals")
        # N'...' -> '...'
        vals = re.sub(r"(?<=[(,\s])N'", "'", vals)
        vals = re.sub(r"^N'", "'", vals)
        # CAST('...' AS DateTime) -> '...'
        vals = CAST_RX.sub(r"\1", vals)

        fields = [f.strip() for f in split_tuple(vals)]
        bset = BOOL.get(tbl, set())
        for k in range(min(len(cols), len(fields))):
            col, v = cols[k], fields[k]
            if col in bset:
                if v == "1":
                    fields[k] = "true"
                elif v == "0":
                    fields[k] = "false"
            # bare 0x empty varbinary -> NULL
            if v == "0x":
                fields[k] = "NULL"
            # hash plaintext user password
            if tbl == "users" and col == "pwd" and v.startswith("'"):
                plain = v[1:-1].replace("''", "'")
                fields[k] = "'%s'" % pbkdf2(plain)

        # ---- DATA CLEANUP FILTERS ------------------------------------------
        cidx = {c: i for i, c in enumerate(cols)}

        def fval(name):
            return fields[cidx[name]].strip() if name in cidx else None

        # 1) drop already soft-deleted rows (treat as permanently deleted)
        if fval("isdeleted") == "true":
            dropped[(db, tbl, "soft-deleted")] = \
                dropped.get((db, tbl, "soft-deleted"), 0) + 1
            continue

        # 2) track which assessees we keep (non-deleted), so children of a
        #    dropped/absent assessee are dropped too
        if tbl == "assessee":
            kept_sub.add(fval("subcode"))
        elif tbl == "billhead":
            kept_bill.add(fval("id"))
        elif tbl == "salary":
            kept_sal.add(fval("id"))

        # 3) drop ORPHANS — rows whose owner isn't in our kept assessee set
        sub = fval("subcode")
        if tbl != "assessee" and sub is not None and sub not in kept_sub:
            dropped[(db, tbl, "orphan")] = \
                dropped.get((db, tbl, "orphan"), 0) + 1
            continue
        if tbl == "billdetails" and fval("billid") not in kept_bill:
            dropped[(db, tbl, "orphan")] = \
                dropped.get((db, tbl, "orphan"), 0) + 1
            continue
        if tbl in ("salarynaturedetails", "salaryexemptallowances",
                   "salaryperquisitedetails") and fval("salid") not in kept_sal:
            dropped[(db, tbl, "orphan")] = \
                dropped.get((db, tbl, "orphan"), 0) + 1
            continue
        # --------------------------------------------------------------------

        buckets[db].append("INSERT INTO %s (%s) VALUES (%s);" %
                            (tbl, cols_out, ", ".join(fields)))
        if tbl not in tables_seen[db]:
            tables_seen[db].append(tbl)
        stats[(db, tbl)] = stats.get((db, tbl), 0) + 1

    for src_db, (pgdb, fname) in DB_FILE.items():
        rows = buckets[src_db]
        if not rows:
            continue
        seqs = []
        for t in tables_seen[src_db]:
            idc = IDCOL.get(t)
            if idc:
                seqs.append(
                    "SELECT setval(pg_get_serial_sequence('%s','%s'), "
                    "COALESCE((SELECT MAX(%s) FROM %s),1));" % (t, idc, idc, t))
        header = (
            "-- ============================================================\n"
            "-- SmartTds customer seed data  ->  %s  (PostgreSQL)\n"
            "-- Auto-converted from script.txt by convert_prats.py\n"
            "-- Reference/master tables (country/state/tdsrate/...) are\n"
            "-- intentionally OMITTED: already seeded by 03_master_seed_data.sql.\n"
            "-- CLEANED: orphan rows (owner assessee not exported) and already\n"
            "-- soft-deleted rows (isdeleted=true) are removed.\n"
            "-- Tables: %s\n"
            "-- ============================================================\n"
            "BEGIN;\n" % (pgdb, ", ".join(tables_seen[src_db])))
        footer = ("\n\nCOMMIT;\n-- reset identity sequences past seeded ids\n"
                  + "\n".join(seqs) + "\n")
        with open(os.path.join(OUT, fname), "w", encoding="utf-8", newline="\n") as f:
            f.write(header + "\n".join(rows) + footer)
        print("wrote %-28s %5d rows" % (fname, len(rows)))

    print("\n-- row counts by table (kept) --")
    for (d, t), n in sorted(stats.items()):
        print("  %-12s %-22s %5d" % (d, t, n))
    if dropped:
        print("\n-- dropped (cleanup) --")
        for (d, t, why), n in sorted(dropped.items()):
            print("  %-12s %-22s %-14s %5d" % (d, t, why, n))


if __name__ == "__main__":
    convert()
