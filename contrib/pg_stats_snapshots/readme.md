
# pg_stat_statements History
pg_stat_statements doesn't provide historic query data by itself. To achiveve this the attached scripts have been created. 

## create_table.sql
Creates a table "public.stat_statements_snapshots" to save the pg_stat_statements. Information combined with the current timestamp index is added to get better performance while querying the data.

## pg_query_stats.sql
Creates a function to query historical pg_stat_statements data.
Usage: `SELECT public.query_stats('2021-05-11 13:00:00','2021-05-11 16:00:00')`

## pg_stat_statem_snap.sh
Shell script to collect the pg_stat_statements information and saves it to "public.stat_statements_snapshots". Adapt to your environment if needed.

## pg_stat_clean.sh
Shell script to cleanup pg_stat_statements data older than 2 months. Adapt to your needs.