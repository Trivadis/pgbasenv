#!/usr/bin/env bash

# Copyright 2020 Trivadis AG <info@trivadis.com>
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
# Author:  Aychin Gasimov (AYG)
# Desc: Script to parse and prepare sql scripts.
#
# Change log:
#   29.01.2021: Aychin: Initial version created
#   05.02.2021: Aychin: Changed to min. version concept and added styling and colors.



if [[ $1 == "list" ]]; then
printf "\n %s\n" "pgBaseEnv scripts:"
printf "┌" && printf "─%.0s" {1..31} && printf "┬" && printf "─%.0s" {1..13} && printf "┬" && printf "─%.0s" {1..74} && printf "%s\n" "┐"
printf "│ \033[1m%-30s\033[0m│ \033[1m%-12s\033[0m│ \033[1m%-73s\033[0m│\n" "Name (Variable)" "Min. Version" "Description"
printf "├" && printf "─%.0s" {1..31} && printf "┼" && printf "─%.0s" {1..13} && printf "┼" && printf "─%.0s" {1..74} && printf "%s\n" "┤"
count=0
  while read -r file
  do
  	 ignore_version=0
     s_name=$(grep "^--.*NAME:" $file | cut -d":" -f2 | xargs)
     [[ -z $s_name ]] && s_name=$(basename $file) && s_name=${s_name%%.sql}
     s_vers=$(grep "^--.*VERSION:" $file | cut -d":" -f2 | xargs)
     [[ -z $s_vers ]] && ignore_version=1 && unset s_vers
     s_desc=$(grep "^--.*DESCRIPTION:" $file | cut -d":" -f2 | xargs)
     if [[ ${TVD_PGVERSION} -ge ${s_vers:-0} || $ignore_version -eq 1 ]]; then
       ((count++))
       printf "│ \033[1;36m%-30s\033[0m│ %-12s│ %-73s│\n" ":${s_name}" "${s_vers:-*}" "${s_desc}"
     fi
  done < <(ls -1 $PGBASENV_BASE/scripts/*.sql)
printf "└" && printf "─%.0s" {1..31} && printf "┴" && printf "─%.0s" {1..13} && printf "┴" && printf "─%.0s" {1..74} && printf "%s\n" "┘"
printf " %s\n\n" "Count: $count"
fi


if [[ $1 == "prep" ]]; then
  echo "\set scripts '\\\! $PGBASENV_BASE/bin/scriptmgr.sh list'" > $PGBASENV_BASE/scripts/.run.${TVD_PGVERSION}
  while read -r file
  do
  	 ignore_version=0
     s_name=$(grep "^--.*NAME:" $file | cut -d":" -f2 | xargs)
     [[ -z $s_name ]] && s_name=$(basename $file) && s_name=${s_name%%.sql}
     s_vers=$(grep "^--.*VERSION:" $file | cut -d":" -f2 | xargs)
     [[ -z $s_vers ]] && ignore_version=1
     if [[ ${TVD_PGVERSION} -ge ${s_vers:-0} || $ignore_version -eq 1 ]]; then
        echo "\set ${s_name} '\\\i ${file}'" >> $PGBASENV_BASE/scripts/.run.${TVD_PGVERSION}    
     fi
  done < <(ls -1 $PGBASENV_BASE/scripts/*.sql)
fi
