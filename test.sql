select * from nl_data.corporations;

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


INSERT INTO nl_data.bag_buildings SELECT * FROM tmp.bag_buildings;

SELECT * FROM nl_data.corporations WHERE cyclomedia_support IS TRUE;
