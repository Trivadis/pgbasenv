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
# Desc: Script to print the contents of the pghometab and pgclustertab.
#       Output will be merged with the runtime information.
#       Check README.md for details.
#
# Change log:
#   06.05.2020: Aychin: Initial version created
#
#


# Set PGBASENV environment 
if [[ -z $PGBASENV_BASE ]]; then
  if [[ -f ~/.PGBASENV_HOME ]]; then
    . ~/.PGBASENV_HOME
  else
    echo "No ~/.PGBASENV_HOME file found."
    exit 1
  fi
fi

if [[ -f $PGBASENV_BASE/etc/pgbasenv.conf ]]; then
  . $PGBASENV_BASE/etc/pgbasenv.conf
else
  echo "No $PGBASENV_BASE/etc/pgbasenv.conf config file found."
  exit 1
fi



declare -r pghometab_file=$PGBASENV_BASE/etc/pghometab
declare -r pgclustertab_file=$PGBASENV_BASE/etc/pgclustertab


declare -r GREEN=$(tput setaf 2)
declare -r GREENB=$(tput setaf 2 && tput bold)
declare -r RED=$(tput setaf 1)
declare -r NORMAL=$(tput sgr0)
declare -r WHITE=$(tput setaf 7)
declare -r BLUEBG=$(tput setab 4 && tput bold)
declare -r CYAN=$(tput setaf 6)
declare -r BOLD=$(tput bold)


print_pghometab() {
  local line delimiter

  local home_max=$(cat $pghometab_file | grep -vE '^ *#' | awk -F";" '{print $1}' | wc -L)
  local alias_max=$(cat $pghometab_file | grep -vE '^ *#' | awk -F";" '{print $4}' | wc -L)
  
  local format_top="${BOLD}%-${alias_max}s${NORMAL} | ${BOLD}%7s${NORMAL} | ${BOLD}%15s${NORMAL} | ${BOLD}%-${home_max}s${NORMAL}\n"
  local format="${BOLD}%-${alias_max}s${NORMAL} | %7s | %15s | %-${home_max}s\n"
  local max=$((31+home_max+alias_max))
  
  for (( i=1; i<=$max; i++ )); do
    delimiter="${delimiter}="
  done

  printf "%s\n" "$delimiter"
  printf "$format_top" "ALIAS" "VER" "OPTIONS" "HOME DIR"
  printf "%s\n" "$delimiter"

  
  while IFS=";" read -r home version options alias; do
    printf "$format" $alias $version $options $home
  done <<< "$(cat $pghometab_file | grep -vE '^ *#')"
  
  printf "%s\n\n" "$delimiter"

}

print_pgclustertab() {
  local line delimiter ftime fhtime size

  local pgdata_max=$(cat $pgclustertab_file | grep -vE '^ *#' | awk -F";" '{print $1}' | wc -L)
  local home_max=$(cat $pgclustertab_file | grep -vE '^ *#' | awk -F";" '{print $3}' | wc -L)
  local alias_max=$(cat $pgclustertab_file | grep -vE '^ *#' | awk -F";" '{print $5}' | wc -L)

  local format_top="${BOLD}%-${alias_max}s${NORMAL} | ${BOLD}%5s${NORMAL} | ${BOLD}%4s${NORMAL} | ${BOLD}%5s${NORMAL} | ${BOLD}%7s${NORMAL} | ${BOLD}%5s${NORMAL} | ${BOLD}%-${pgdata_max}s${NORMAL} | ${BOLD}%16s${NORMAL} | ${BOLD}%-${home_max}s${NORMAL}\n"
  local format="${BOLD}%-${alias_max}s${NORMAL} | %5s | %4s | %5s | %7s | %5s | %-${pgdata_max}s | %16s | %-${home_max}s\n"
  local format_up="${GREENB}%-${alias_max}s${NORMAL}${GREEN} | %5s | %4s | %5s | %7s | %5s | %-${pgdata_max}s | %16s | %-${home_max}s${NORMAL}\n"

  local max=$((66+pgdata_max+home_max+alias_max))

  if [[ ! $MODE == "--list" ]]; then
  for (( i=1; i<=$max; i++ )); do
    delimiter="${delimiter}="
  done

  printf "%s\n" "$delimiter"
  printf "$format_top" "ALIAS" "VER" "STAT" "PORT" "PID" "SIZE" "PGDATA" "LAST START" "LAST START HOME" 
  printf "%s\n" "$delimiter"
  fi
  
  while IFS=";" read -r pgdata version last_home port alias; do

    [[ -z $port ]] && port=" "
    running_cluster=$(echo "$ALL_RUNNING_INSTANCES" | grep ";${pgdata};" | cut -d";" -f3)

    fhtime=""
    [[ -f $pgdata/postmaster.opts ]] && ftime=$(stat -c %Y $pgdata/postmaster.opts) && fhtime=$(date -d @$ftime +"%Y-%m-%d %H:%M")
    size=$(du -sh $pgdata | awk '{print $1}')
    
    if [[ ! -z $running_cluster ]]; then
      running_pid=$(echo "$ALL_RUNNING_INSTANCES" | grep ";${pgdata};" | cut -d";" -f1)
      running_home=$(echo "$ALL_RUNNING_INSTANCES" | grep ";${pgdata};" | cut -d";" -f2)
      running_port=$(echo "$ALL_RUNNING_INSTANCES" | grep ";${pgdata};" | cut -d";" -f4)


      if [[ ! $MODE == "--list" ]]; then
        #echo -en "${GREEN}"
        printf "$format_up" "$alias" $version "UP" $running_port $running_pid $size $pgdata "$fhtime" $running_home
        #echo -en "${NORMAL}"
      else
        echo "$alias;$version;UP;$running_port;$running_pid;$size;$pgdata;$fhtime;$running_home"
      fi

    else
      if [[ ! $MODE == "--list" ]]; then
        printf "$format" "$alias" $version "DOWN" "$port" " " $size $pgdata "$fhtime" $last_home
      else
        echo "$alias;$version;DOWN;${port// /};;$size;$pgdata;$fhtime;$last_home"
      fi
    fi

  done <<< "$(cat $pgclustertab_file | grep -vE '^ *#')"
  
  printf "%s\n\n" "$delimiter"
  
}


# Find running PostgreSQL porcesses. Output format:
# PID;HOME;DATADIR;PORT
find_running_procs() {
local i dir
for i in $(ps -o ppid= -C postgres -C postmaster -C edb-postgres | sort | uniq -c | awk '{ if ($1 > 1 && $2 > 1) print $2}'); do
  dir=$(readlink -f /proc/$i/exe)
  if [[ ! -z $dir ]]; then 
     dir=$(dirname $dir)
     [[ -f $dir/pg_ctl ]] && echo "$i;$(dirname $dir);$(find_datadir_of_running_proc $i);$(find_port_of_running_proc $i)"
  fi
done
}

find_datadir_of_running_proc() {
local d
for d in $(lsof -p $1 | grep DIR | awk '{print $9}'); do
  [[ -f $d/global/pg_control ]] && echo $d
done
}


find_port_of_running_proc() {
netstat -ltnp 2>/dev/null| grep -E "^tcp .* $1" | awk '{print $4}' | cut -d":" -f2
}




######### MAIN #####################################################

[[ ! $1 =~ --list|^$ ]] && echo "ERROR: Wrong argument $1. It can be --list only." && exit 1

declare MODE=$1

ALL_RUNNING_INSTANCES=$(find_running_procs)

if [[ ! $MODE == "--list" ]]; then
 echo -e "\npgBasEnv ${BOLD}v$(pgbasenv --version)${NORMAL} by Trivadis AG"
 echo -e
 echo "Installation homes:"
 print_pghometab
fi

[[ ! $MODE == "--list" ]] && echo "Cluster data directories:"
print_pgclustertab

exit 0

