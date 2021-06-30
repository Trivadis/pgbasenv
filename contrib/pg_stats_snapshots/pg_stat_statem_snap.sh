#!/bin/sh

# Copyright 2021 Trivadis AG <info@trivadis.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Author:  Michael Muehlbeyer
# Desc: readme.md for details
#
# Change log:
#   29.06.2021: Michael: Initial version created
#

export PGHOME="/usr/pgsql-13/"
export PATH="${PGHOME}/bin:${PATH}"
export PGDATABASE=db01
export PGPORT=20001

# collect pg_stat_statements
psql -c "INSERT INTO stat_statements_snapshots SELECT now(), * FROM pg_stat_statements;" >>/tmp/pg_stat_stat.log

