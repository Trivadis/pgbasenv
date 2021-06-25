create table public.stat_statements_snapshots as
select null::timestamp with time zone as created, *
from pg_stat_statements limit 0;
 
create index stat_statements_created_idx
on public.stat_statements_snapshots (created);