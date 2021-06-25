# readme.txt

pg_stat_statements doesn't provide historic query data by itself
to achiveve this the attached scripts have been created

1. create_table.sql

creates a table "public.stat_statements_snapshots" to save the pg_stat_statements information combined with the current timestamp
index is added to get better performance while querying the data 

2. pg_query_stats.sql

creates a function to query historical pg_stat_statements data 
usage: SELECT public.query_stats('2021-05-11 13:00:00','2021-05-11 16:00:00')

3. pg_stat_statem_snap.sh

shell script to collect the pg_stat_statements information and saves it to "public.stat_statements_snapshots"
adapt to your environment

4. pg_stat_clean.sh

shell script to cleanup pg_stat_statements data older than 2 monaths
adapt to your needs