#!/bin/sh
export PGHOME="/usr/pgsql-13/"
export PATH="${PGHOME}/bin:${PATH}"
export PGDATABASE=db01
export PGPORT=20001

# collect pg_stat_statements
psql -c "INSERT INTO stat_statements_snapshots SELECT now(), * FROM pg_stat_statements;" >>/tmp/pg_stat_stat.log

