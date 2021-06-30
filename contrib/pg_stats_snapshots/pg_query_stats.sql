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

-- creates a function to query historical pg_stat_statements data 
-- usage: SELECT public.query_stats('2021-05-11 13:00:00','2021-05-11 16:00:00')
create or replace function public.query_stats(day1 character varying, day2 character varying)
returns setof stat_statements_snapshots
language sql
as $function$
select * from stat_statements_snapshots sss where sss.created between day1::timestamp and day2::timestamp order by 1 desc;
$function$
;