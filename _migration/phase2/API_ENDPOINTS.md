# SmartTds API — endpoint inventory

Live base: `https://api.smartbizin.com` · local: `http://localhost:5080` (Swagger at `/swagger`).
All `/api/*` except `/health` and `/api/auth/login` require a Bearer JWT. Year-DB endpoints require header `X-Assessment-Year` (e.g. `26`).

## ✅ Built & tested
| Group | Routes | DB | File |
|---|---|---|---|
| Health | `GET /health` | — | Program.cs |
| Auth + licensing | `POST /api/auth/login`, `POST /api/auth/logout` | master | AuthEndpoints.cs |
| Assessees | `GET /api/assessees`, `GET /api/assessees/{subCode}` (read) | master | AssesseeEndpoints.cs |
| Challans | `GET /api/challans?subCode=` (read) | year | ChallanEndpoints.cs |
| **Masters (reads)** | `GET /api/masters/`{states, countries, districts?stateCode, postoffices, subdistricts, pincode?pincode, aymaster, tdsnatures, tdsrates?ayId, tdsded80?ayId, tdsentriessections?formName, checkperiods?ayId, tdsaomasters, applicationparams} | master | MastersEndpoints.cs |
| **Payee** | `GET /api/payees?subCode=&ayId=`, `GET /{id}`, `POST`, `PUT /{id}`, `DELETE /{id}` | year | PayeeEndpoints.cs |
| **Salary** (+3 detail tables) | `GET /api/salaries?subCode=&ayId=`, `GET /{id}` (composite), `POST` (nested body `{salary,exemptAllowances,natureDetails,perquisiteDetails}`), `PUT /{id}`, `DELETE /{id}` | year | SalaryEndpoints.cs |
| **TdsEntry** | `GET /api/tdsentries?subCode=&ayId=&chId=&payeeId=`, `GET /{id}`, `POST`, `PUT /{id}`, `DELETE /{id}` | year | TdsEntryEndpoints.cs |

Conventions: inserts use `RETURNING id`; deletes are soft (`isdeleted=true`) where the column exists, else hard; reserved columns quoted (`"limit"`, `"desc"`); all parameterized.

## ⏳ Still to build (next batches)
- **Year DB:** AddChallan full CRUD (only list today), TdsDeduction, TdsCompIncome, FilingStatus, F15hn, F15hnPayee, Ddodet.
- **Master DB CRUD:** Assessee (create/update/delete — only read today), AssesseeRep, AssesseeResStatus, Consultant, Groups, BankDetails, ReturnDates, FeePaidMarking, AyMaster admin, Users management.
- **Billing:** BillHead, BillReceipts, BillDetails, Billmast, BillReceipt (replaces the `MasterDbTdsDataSet` TableAdapters) — **fix `MAX+1`→sequences here**.
- **Cross-DB:** TdsPayeeBal's `[MasterDbTds]…TdsEntriesSection` 3-part name → read master + year via separate connections.

## Note on coarse endpoints (perf)
For each desktop screen, prefer ONE endpoint returning everything the screen needs (e.g. a per-assessee dashboard) over many fine-grained calls — avoids WAN chattiness (Phase 0 risk #6).
