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
#   03.12.2020: Aychin: tput will be set to xterm. Required for remote execution.
#   03.12.2020: Aychin: Check lsof location. Required for remote execution.
#   05.02.2020: Aychin: New styling
#   12.02.2020: Aychin: Support for SUSE Linux
#   14.02.2020: Aychin: Added flock to prevent showing partial information.
#

declare -r LSOF=$([[ ! -f /bin/lsof ]] && which lsof || echo "lsof")

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

declare -r TPUT="tput -T xterm"

declare -r GREEN=$($TPUT setaf 2)
declare -r GREENB=$($TPUT setaf 2 && $TPUT bold)
declare -r RED=$($TPUT setaf 1)
declare -r NORMAL=$($TPUT sgr0)
declare -r WHITE=$($TPUT setaf 7)
declare -r BLUEBG=$($TPUT setab 4 && $TPUT bold)
declare -r CYAN=$($TPUT setaf 6)
declare -r BOLD=$($TPUT bold)

hl() {
    local delimiter
    for (( i=1; i<=$1; i++ )); do
      delimiter="${delimiter}─"
    done
    echo $delimiter
  }


print_pghometab() {
  local line delimiter

  local home_max=$(cat $pghometab_file | grep -vE '^ *#' | awk -F";" '{print $1}' | wc -L)
  local alias_max=$(cat $pghometab_file | grep -vE '^ *#' | awk -F";" '{print $4}' | wc -L)
  
  [[ $alias_max -lt 5 ]] && alias_max=5
  [[ $home_max -lt 8 ]] && home_max=8 
 
  local format_top="│${BOLD}%-${alias_max}s${NORMAL} │ ${BOLD}%7s${NORMAL} │ ${BOLD}%15s${NORMAL} │ ${BOLD}%-${home_max}s${NORMAL}│\n"
  local format="│${BOLD}%-${alias_max}s${NORMAL} │ %7s │ %15s │ %-${home_max}s│\n"
  local max=$((31+home_max+alias_max))
  
  printf "┌─" && printf "%s" "$(hl ${alias_max})" && printf "┬─" && printf "%s" "$(hl 7)" && printf "─┬─" && printf "%s" "$(hl 15)" && printf "─┬" && printf "%s" "$(hl ${home_max})" && printf "%s\n" "─┐"

  printf "$format_top" "ALIAS" "VER" "OPTIONS" "HOME DIR"
  printf "├─" && printf "%s" "$(hl ${alias_max})" && printf "┼─" && printf "%s" "$(hl 7)" && printf "─┼─" && printf "%s" "$(hl 15)" && printf "─┼" && printf "%s" "$(hl ${home_max})" && printf "%s\n" "─┤"
  
  while IFS=";" read -r home version options alias; do
    printf "$format" $alias $version $options $home
  done <<< "$(cat $pghometab_file | grep -vE '^ *#')"
 
  printf "└─" && printf "%s" "$(hl ${alias_max})" && printf "┴─" && printf "%s" "$(hl 7)" && printf "─┴─" && printf "%s" "$(hl 15)" && printf "─┴" && printf "%s" "$(hl ${home_max})" && printf "%s\n" "─┘" 
 printf "%s\n"

}

print_pgclustertab() {
  local line delimiter ftime fhtime size

  if [[ ! -f $pgclustertab_file ]]; then
    echo -e "\n --- No pgclustertab file found. --- \n"
    return 1
  fi
  local ddcnt=$(cat $pgclustertab_file | grep -vE '^ *#' | wc -l)
  if [[ $ddcnt -eq 0 ]]; then
    echo -e "\n --- No cluster data directories found. --- \n"
    return 0
  fi

  local pgdata_max=$(cat $pgclustertab_file | grep -vE '^ *#' | awk -F";" '{print $1}' | wc -L)
  local home_max=$(cat $pgclustertab_file | grep -vE '^ *#' | awk -F";" '{print $3}' | wc -L)
  local alias_max=$(cat $pgclustertab_file | grep -vE '^ *#' | awk -F";" '{print $5}' | wc -L)

  [[ $alias_max -lt 5 ]] && alias_max=5
  [[ $home_max -lt 15 ]] && home_max=15
  [[ $pgdata_max -lt 6 ]] && pgdata_max=6

  local format_top="│${BOLD}%-${alias_max}s${NORMAL} │ ${BOLD}%5s${NORMAL} │ ${BOLD}%4s${NORMAL} │ ${BOLD}%5s${NORMAL} │ ${BOLD}%7s${NORMAL} │ ${BOLD}%5s${NORMAL} │ ${BOLD}%-${pgdata_max}s${NORMAL} │ ${BOLD}%16s${NORMAL} │ ${BOLD}%-${home_max}s${NORMAL}│\n"
  local format="│${BOLD}%-${alias_max}s${NORMAL} │ %5s │ %4s │ %5s │ %7s │ %5s │ %-${pgdata_max}s │ %16s │ %-${home_max}s│\n"
  #local format_up="│${GREENB}%-${alias_max}s${NORMAL}${GREEN} │ %5s │ %4s │ %5s │ %7s │ %5s │ %-${pgdata_max}s │ %16s │ %-${home_max}s${NORMAL}│\n"
  local format_up="│\033[1;32m%-${alias_max}s\033[0m │ \033[1;32m%5s\033[0m │ \033[1;32m%4s\033[0m │ \033[1;32m%5s\033[0m │ \033[1;32m%7s\033[0m │ \033[1;32m%5s\033[0m │ \033[1;32m%-${pgdata_max}s\033[0m │ \033[1;32m%16s\033[0m │ \033[1;32m%-${home_max}s\033[0m│\n"
  
  local max=$((66+pgdata_max+home_max+alias_max))

  if [[ ! $MODE == "--list" ]]; then

  printf "┌─" && printf "%s" "$(hl ${alias_max})" && printf "┬─" && printf "%s" "$(hl 5)" && printf "─┬─" && printf "%s" "$(hl 4)" && printf "─┬─" && printf "%s" "$(hl 5)" && printf "─┬─" && printf "%s" "$(hl 7)" && printf "─┬─" && printf "%s" "$(hl 5)" && printf "─┬─" && printf "%s" "$(hl ${pgdata_max})" && printf "─┬─" && printf "%s" "$(hl 16)" && printf "─┬" && printf "%s" "$(hl ${home_max})" && printf "%s\n" "─┐"
  printf "$format_top" "ALIAS" "VER" "STAT" "PORT" "PID" "SIZE" "PGDATA" "LAST START" "LAST START HOME" 
printf "├─" && printf "%s" "$(hl ${alias_max})" && printf "┼─" && printf "%s" "$(hl 5)" && printf "─┼─" && printf "%s" "$(hl 4)" && printf "─┼─" && printf "%s" "$(hl 5)" && printf "─┼─" && printf "%s" "$(hl 7)" && printf "─┼─" && printf "%s" "$(hl 5)" && printf "─┼─" && printf "%s" "$(hl ${pgdata_max})" && printf "─┼─" && printf "%s" "$(hl 16)" && printf "─┼" && printf "%s" "$(hl ${home_max})" && printf "%s\n" "─┤"
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
  
  if [[ ! $MODE == "--list" ]]; then
    printf "└─" && printf "%s" "$(hl ${alias_max})" && printf "┴─" && printf "%s" "$(hl 5)" && printf "─┴─" && printf "%s" "$(hl 4)" && printf "─┴─" && printf "%s" "$(hl 5)" && printf "─┴─" && printf "%s" "$(hl 7)" && printf "─┴─" && printf "%s" "$(hl 5)" && printf "─┴─" && printf "%s" "$(hl ${pgdata_max})" && printf "─┴─" && printf "%s" "$(hl 16)" && printf "─┴" && printf "%s" "$(hl ${home_max})" && printf "%s\n" "─┘"
    printf "%s\n" 
  fi

}


# Find running PostgreSQL porcesses. Output format:
# PID;HOME;DATADIR;PORT
find_running_procs() {
local i dir
for i in $(ps -o ppid= -C postgres -C postmaster -C edb-postgres -C edb-postmaster | sort | uniq -c | awk '{ if ($1 > 1 && $2 > 1) print $2}'); do
  dir=$(readlink -f /proc/$i/exe | cut -d" " -f1)
  if [[ ! -z $dir ]]; then 
     dir=$(dirname $dir)
     [[ -f $dir/pg_ctl ]] && echo "$i;$(dirname $dir);$(find_datadir_of_running_proc $i);$(find_port_of_running_proc $i)"
  fi
done
}

find_datadir_of_running_proc() {
  local pid
  pid=$1
  if [[ -h /proc/${pid}/cwd && -f /proc/${pid}/cwd/global/pg_control ]]; then
    readlink -f /proc/${pid}/cwd
  else
    local d
    for d in $($LSOF -p $1 2> /dev/null | grep DIR | awk '{print $9}'); do
      [[ -f $d/global/pg_control ]] && echo $d
    done
  fi
}


find_port_of_running_proc() {
   local pid=$1
   if [[ -h /proc/${pid}/cwd && -f /proc/${pid}/cwd/postmaster.pid ]]; then
     #using the port from pid
     head -4 /proc/${pid}/cwd/postmaster.pid |tail -1
   else
     which netstat > /dev/null 2>&1
     local RC=$?
     if [[ $RC -eq 0 ]]; then
       netstat -ltnp 2>/dev/null| grep -E "^tcp .* ${pid}" | awk '{print $4}' | cut -d":" -f2
     else
       ss -ltnp | grep "pid=${pid}," | awk '{print $4}' | cut -d":" -f2
     fi
   fi
}




######### MAIN #####################################################

[[ ! $1 =~ --list|^$ ]] && echo "ERROR: Wrong argument $1. It can be --list only." && exit 1

declare MODE=$1

ALL_RUNNING_INSTANCES=$(find_running_procs)


if [[ ! $MODE == "--list" ]]; then
 echo -e "\npgBasEnv ${BOLD}v$(pgbasenv --version)${NORMAL} by Trivadis AG"
 echo -e
 echo "Installation homes:"
 exec 9<$pghometab_file
 flock -x -w 15 9
 print_pghometab
 exec 9>&-
fi

[[ ! $MODE == "--list" ]] && echo "Cluster data directories:"
exec 11<$pgclustertab_file
flock -x -w 15 11
print_pgclustertab
exec 11>&-

exit 0

