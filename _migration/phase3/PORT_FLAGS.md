# Port flags — deferred / needs-attention (after Phases A–F)

Core flows ported & compiling (API + MasterBal + SmartTdsBAL): auth, assessee, consultant, group, masters (state/district/country/subdistrict/postoffice/pincode/tdsnature/tdsrate/tdsded80/tdsentriessection/checkperiod/tdsaomaster/aymaster), payee, tdsentry, salary(+details), challan, tdsdeduction, ddodet, f15hn/f15hnpayee, tdscompincome, users/bank/returndates/fee, billing CRUD.

## A) Orphan tables — NOT in the PG schema → classes stubbed (NotImplementedException). Confirm DELETE in cleanup, or add the table+endpoints if still needed.
- Nature3Bal (nature3), TdsnscrateBal (tdsnscrate), Tdsnscrate2Bal (tdsnscrate2)
- TdsPayeeBal (tdspayee — was a SQL join view of tdsentry+payee+tdsentriessection; needs a server-side join endpoint if used)
- DateplaceBal (dateplace), DepchildBal (depchild), FilePendingBAL (filepending)
- (Note: DofBal.cs actually contains class FilingStatusBal → table `filingstatus` EXISTS; ported to `api/filingstatus`.)

## B) Endpoints still TODO (methods stubbed or pointing at unbuilt routes — throw/404 if that feature is used)
- **FilingStatus**: `api/filingstatus` GET/POST/PUT not built yet (FilingStatusBal ready). Build a year-DB CRUD for `filingstatus` before using the Filing-Status screen.
- **TdsEntry** specialized: aggregate sums (GetTotalColumnValue*, GetMonthlyTotalUnderSection), batch insert/link (InsertTdsEntryBatch, UpdateChIdBatch), bulk (DeleteAllForAy, DeleteByChId, SoftDeleteByPayeeId, UnlinkEntriesByChId, ClearCaughtUpTdsDedLater).
- **AddChallanBal.DeleteAllForAy**, **PayeeBal.GetModifiedPayeeList**, **F15hnPayeeBal.GetByFormId**.
- **BillReceiptsBal.GetLastBillReceiptNo** (FrmReceipt save) + **BillHeadBal.GetAllPendingBills**.
- **Salary child BALs** (SalaryExemptAllowances/Nature/Perquisite Bal) — all stubbed; salary children flow through the composite salary POST/PUT. If FrmSalaryGrossMode calls a child BAL directly, switch it to the composite Insert/UpdateWithDetails.

## C) Minor data-shape
- `tdsded80` read returns column `short`; entity prop is `shortName` → won't round-trip. Alias it (`short as shortname`) in the /tdsded80 endpoint if that field is needed.

## D) Cleanup (Phase G, after build is green)
- Delete `MasterDAL`, `SmartTdsDAL` projects + their references; remove `DbBaseClass`/`DbVariables` SQL plumbing; remove `MasterDbTdsDataSet.xsd`/Designer + remaining TableAdapter fields in billing forms; drop SQL connection strings from app.config; remove the legacy SQL path in FrmLogin.

Build cadence: deploy API (`deploy-server.sh`), then VS2022 **Rebuild** SmartTdsWinUI → fix any UI compile errors (most likely in the converted billing forms).
