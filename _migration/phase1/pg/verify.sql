\echo == row counts ==
select rpad(t,18)||cnt from (select 'district' t,count(*) cnt from district union all select 'tdsrate',count(*) from tdsrate union all select 'country',count(*) from country union all select 'tdsentriessection',count(*) from tdsentriessection union all select 'tdsnature',count(*) from tdsnature union all select 'state',count(*) from state union all select 'tdsded80',count(*) from tdsded80 union all select 'check_period',count(*) from check_period union all select 'applicationparams',count(*) from applicationparams union all select 'aymaster',count(*) from aymaster) x order by t;
\echo == total ==
select count(*) as total_seed from (select 1 from district union all select 1 from tdsrate union all select 1 from country union all select 1 from tdsentriessection union all select 1 from tdsnature union all select 1 from state union all select 1 from tdsded80 union all select 1 from check_period union all select 1 from applicationparams union all select 1 from aymaster) z;
\echo == tdsded80 row1 booleans (expect t t t t f f f f) ==
select ind,indnr,huf,hufnr,firm,company,companynr,coop from tdsded80 where ded80id=1;
\echo == reserved limit column ==
select section,paycode,"limit" from tdsentriessection where paycode=21;
\echo == sequence works: next district id should be > max ==
select nextval(pg_get_serial_sequence('district','id')) as next_district_id, (select max(id) from district) as max_id;