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

create table public.stat_statements_snapshots as
select null::timestamp with time zone as created, *
from pg_stat_statements limit 0;
 
create index stat_statements_created_idx
on public.stat_statements_snapshots (created);