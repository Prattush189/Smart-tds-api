# BAL → API port plan (online-only build)

Strategy: rewrite each BAL method to call the central API via `ApiGateway` (UI untouched); delete SQL/DAL as we go. `MasterBal`/`SmartTdsBAL` compile locally (`dotnet build`) for verification; user rebuilds `SmartTdsWinUI` in VS2022 periodically. Endpoints live in `SmartTdsApi`; deploy via `git push` → `deploy-server.sh`.

Pattern (read): `=> ApiGateway.List<Entity>("api/...")` / `.One<Entity>(...)`.
Pattern (write): `ApiGateway.Post<T>("api/...", body)` / `.Put(...)` / `.Delete(...)`.
Watch: entities with `DateTime` fields over `dd/MM/yyyy` varchar → parse server-side, return a concrete record (not `List<object>`).

| Phase | BAL classes | Endpoints needed | Status |
|---|---|---|---|
| 0 Foundation | ApiGateway, refs, ApplicationParamsBal | (existing) | ✅ done |
| **A Navigable** | AssesseeBal, ConsultantBal, GroupBal, AssesseeResStatusBal | assessee CRUD, consultant CRUD, group CRUD, assesseeresstatus | ▶ in progress |
| B Masters | State/District/Country/SubDistrict/PostOffice/Pincode/TdsNature/TdsRate/Tdsded80/TdsEntriesSection/CheckPeriod/Tdsaomaster/AyMaster | mostly exist (reads) + a few writes | todo |
| C TDS entry | TdsEntryBal, TdsPayeeBal, AddChallanBal, PayeeBal, TdsDeductionBal, DdodetBal, FilePendingBAL, F15hnBal, F15hnPayeeBal, DateplaceBal, DofBal, DepchildBal | payee/salary/tdsentry CRUD exist; challan CRUD; rest new | todo |
| D Salary/income | SalaryBal, TdsCompIncomeBal, TaxCalcBal | salary CRUD exists; tdscompincome | todo |
| E Billing | BillHeadBal, BillReceiptsBal, BillmastBal, BillDetailsBal, BillReceiptBal | billing CRUD (+ MAX+1→sequences) | todo |
| F Admin/users | UsersBal, BankDetailsBal, ReturnDatesBal, FeePaidMarkingBal, BillHeadBal(rest) | user mgmt, bank, returndates, fee | todo |
| G Cleanup | delete *DAL projects + DbBaseClass refs; remove SQL conn-string config | — | todo |

Deploy/build cadence: after each phase, `git push` API + `deploy-server.sh`, and user Rebuilds in VS2022.
