select * from nl_data.corporations

create table tmp.brabantwonen_stacked as
create table tmp.brabantwonen_stacked as
select * from tmp.brabantwonen_sheet1
union
select * from tmp.brabantwonen_sheet2;



select * from tmp.brabantwonen_sheet1
union
select * from tmp.brabantwonen_sheet2;

SELECT schemaname, tablename FROM pg_tables
ORDER BY schemaname, tablename;
