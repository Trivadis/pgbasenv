
# pg_stat_statements History
pg_stat_statements doesn't provide historic query data by itself. To achiveve this the attached scripts have been created.
As a first step make sure that the [extenstion](https://www.postgresql.org/docs/13/pgstatstatements.html) is loaded.
```
vi postgresql.conf

shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.max = 10000
pg_stat_statements.track = all

# Restart the database cluster

$ psql
postgres=# CREATE EXTENSION pg_stat_statements;
```

## create_table.sql
Creates a table "public.stat_statements_snapshots" to save the pg_stat_statements. Information combined with the current timestamp index is added to get better performance while querying the data.
```
$ psql
postgres=# \i create_table.sql
```

## pg_query_stats.sql
Creates a function to query historical pg_stat_statements data.
```
$ psql
postgres=# \i pg_query_stats.sql
```

## pg_stat_statem_snap.sh
Shell script to collect the pg_stat_statements information and saves it to "public.stat_statements_snapshots". Adapt to your environment if needed. This script must be scheduled, e.g. in Crontab. Every 30 minutes is a good start.
```
$ crontab -e
00,30 * * * *  . ~/.bash_profile; pgsetenv <pgbasenv alias>; ~/pg_stat_statem_snap.sh
```

## pg_stat_clean.sh
Shell script to cleanup pg_stat_statements data older than 2 months. Adapt to your needs. This script must be scheduled, e.g. in Crontab. Once a day is a good interval.
```
$ crontab -e
$ 00 22 * * *  . ~/.bash_profile; pgsetenv <pgbasenv alias>; ~/pg_stat_clean.sh
```

## Query the data
With the above created function the historical queries can be selected.
```
$ psql
postgres=# postgres=# SELECT public.query_stats('2021-05-11 13:00:00','2021-05-11 16:00:00')
```
