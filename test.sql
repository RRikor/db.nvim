select * from nl_data.cor_addresses limit 100;

select * from nl_data.corporations

create table tmp.brabantwonen_stacked as
select * from tmp.brabantwonen_sheet1
union
select * from tmp.brabantwonen_sheet2;
