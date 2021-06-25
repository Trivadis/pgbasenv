-- creates a function to query historical pg_stat_statements data 
-- usage: SELECT public.query_stats('2021-05-11 13:00:00','2021-05-11 16:00:00')
create or replace function public.query_stats(day1 character varying, day2 character varying)
returns setof stat_statements_snapshots
language sql
as $function$
select * from stat_statements_snapshots sss where sss.created between day1::timestamp and day2::timestamp order by 1 desc;
$function$
;