# Converts SQL Server seed INSERTs (MasterDbTdsScript) -> PostgreSQL seed file.
# - de-brackets only the COLUMN LIST (values may contain '[' inside strings)
# - strips N'...' unicode prefixes
# - quotes reserved column names ("limit")
# - converts bit 0/1 -> false/true for known boolean columns, via a
#   quote/paren-aware tokenizer (PG16's built-in int->bool cast is explicit-only)
$src = "C:\SmartTds Backup\ProjectTDS - SQL\_migration\phase1\source\MasterDbTdsScript.utf8.sql"
$dst = "C:\SmartTds Backup\ProjectTDS - SQL\_migration\phase1\pg\03_master_seed_data.sql"

$reservedSet = @{}
@('limit','desc','user','order','group','check','default','references','primary',
  'foreign','column','table','select','where','from','and','or','not','null','end',
  'to','all','as','is','in','case','when','then','else','having','union','into',
  'values','on','using','like','offset','distinct') | ForEach-Object { $reservedSet[$_] = $true }

# tables -> set of boolean column names (from 02_master_schema.sql)
$boolCols = @{ 'tdsded80' = @{ind=1;indnr=1;huf=1;hufnr=1;firm=1;company=1;companynr=1;coop=1} }

# split a VALUES tuple body into top-level fields (respect '...' quotes and nested parens)
function Split-Tuple([string]$s) {
    $fields = New-Object System.Collections.Generic.List[string]
    $depth = 0; $inq = $false; $start = 0
    for ($i=0; $i -lt $s.Length; $i++) {
        $ch = $s[$i]
        if ($inq) {
            if ($ch -eq "'") { if ($i+1 -lt $s.Length -and $s[$i+1] -eq "'") { $i++ } else { $inq=$false } }
        } else {
            if ($ch -eq "'") { $inq=$true }
            elseif ($ch -eq '(') { $depth++ }
            elseif ($ch -eq ')') { $depth-- }
            elseif ($ch -eq ',' -and $depth -eq 0) { $fields.Add($s.Substring($start, $i-$start)); $start=$i+1 }
        }
    }
    $fields.Add($s.Substring($start))
    return $fields
}

$lines = Get-Content -LiteralPath $src -Encoding UTF8
$rx = [regex]'^INSERT\s+\[dbo\]\.\[(?<tbl>[^\]]+)\]\s*\((?<cols>[^)]*)\)\s+VALUES\s+(?<vals>.*)$'
$out = New-Object System.Collections.Generic.List[string]

foreach ($line in $lines) {
    $m = $rx.Match($line.Trim())
    if (-not $m.Success) { continue }
    $tbl  = $m.Groups['tbl'].Value.ToLower()
    $colNames = ($m.Groups['cols'].Value -split ',') | ForEach-Object { $_.Trim().Trim('[',']').ToLower() }
    $colsOut = ($colNames | ForEach-Object { if ($reservedSet.ContainsKey($_)) { '"'+$_+'"' } else { $_ } }) -join ', '

    $vals = $m.Groups['vals'].Value.Trim()
    $vals = [regex]::Replace($vals, "(?<=[(,\s])N'", "'")   # drop unicode prefix

    if ($boolCols.ContainsKey($tbl)) {
        $body = $vals.TrimStart('(').TrimEnd(';').TrimEnd().TrimEnd(')')
        $fields = Split-Tuple $body
        $bset = $boolCols[$tbl]
        for ($k=0; $k -lt $colNames.Count -and $k -lt $fields.Count; $k++) {
            if ($bset.ContainsKey($colNames[$k])) {
                $v = $fields[$k].Trim()
                if ($v -eq '1') { $fields[$k]=' true' } elseif ($v -eq '0') { $fields[$k]=' false' }
            }
        }
        $vals = '(' + ($fields -join ',') + ')'
    }
    $out.Add("INSERT INTO $tbl ($colsOut) VALUES $vals;") | Out-Null
}

$header = @"
-- =====================================================================
-- SmartTds MASTER seed/reference data  (PostgreSQL)
-- Auto-converted from MasterDbTdsScript.utf8.sql by convert_seed.ps1
-- Run AFTER 02_master_schema.sql, against the masterdbtds database.
-- bit 0/1 -> false/true done in-converter; ids inserted explicitly,
-- identity sequences reset at the end.
-- =====================================================================
BEGIN;
"@
$footer = @"

COMMIT;
-- reset identity sequences so future inserts don't collide with seeded ids
SELECT setval(pg_get_serial_sequence('district','id'),          COALESCE((SELECT MAX(id) FROM district),1));
SELECT setval(pg_get_serial_sequence('country','id'),           COALESCE((SELECT MAX(id) FROM country),1));
SELECT setval(pg_get_serial_sequence('state','id'),             COALESCE((SELECT MAX(id) FROM state),1));
SELECT setval(pg_get_serial_sequence('aymaster','id'),          COALESCE((SELECT MAX(id) FROM aymaster),1));
SELECT setval(pg_get_serial_sequence('tdsded80','ded80id'),     COALESCE((SELECT MAX(ded80id) FROM tdsded80),1));
SELECT setval(pg_get_serial_sequence('check_period','id'),      COALESCE((SELECT MAX(id) FROM check_period),1));
SELECT setval(pg_get_serial_sequence('applicationparams','id'), COALESCE((SELECT MAX(id) FROM applicationparams),1));
"@

[System.IO.File]::WriteAllText($dst, $header + "`n" + ($out -join "`n") + "`n" + $footer, (New-Object System.Text.UTF8Encoding $false))
Write-Output "Wrote $($out.Count) INSERT rows"