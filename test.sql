select * from nl_data.corporations

create table tmp.brabantwonen_stacked as
create table tmp.brabantwonen_stacked as
select * from tmp.brabantwonen_sheet1
union
select * from tmp.brabantwonen_sheet2;



select * from tmp.brabantwonen_sheet1
union
select * from tmp.brabantwonen_sheet2;


SELECT * FROM nl_data.bag_buildings limit 10000;
