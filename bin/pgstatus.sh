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
#
# Author:  Aychin Gasimov (AYG)
# Desc: Script to print out the information about currently set alias.
#
#
# Change log:
#   06.05.2020: Aychin: Initial version created
#   03.12.2020: Aychin: tput will be set to xterm. Required for remote execution.
#

declare -r TPUT="tput -T xterm"

declare -r GREEN=$($TPUT setaf 2)
declare -r RED=$($TPUT setaf 1)
declare -r NORMAL=$($TPUT sgr0)
declare -r WHITE=$($TPUT setaf 7)
declare -r BLUEBG=$($TPUT setab 4 && $TPUT bold)
declare -r CYAN=$($TPUT setaf 6)
declare -r BOLD=$($TPUT bold)

print_current_conf() {

  local format=" ${BOLD}%25s${NORMAL}: %-100s\n"
  local format2=" ${BOLD}%25s${NORMAL}: "

  
  echo -e "\n---${BLUEBG}[$PGBASENV_ALIAS]${NORMAL}:\n"
  [[ ! -z $TVD_PGCLUSTER_NAME ]] && printf "$format2" "Cluster name" && echo -e "${CYAN}$TVD_PGCLUSTER_NAME${NORMAL}"
  [[ ! -z $TVD_PGHOME ]] && printf "$format" "Installation home" "$TVD_PGHOME"
  [[ ! -z $PGDATA ]] && printf "$format" "Cluster data directory" "$PGDATA"
  [[ ! -z $PGPORT ]] && printf "$format" "Cluster port" "$PGPORT"
  
  if [[ ! -z $TVD_PGSTATUS ]]; then
     printf "$format2" "Cluster status"
     if [[ $TVD_PGSTATUS == "UP" ]]; then
        echo -e "${GREEN}$TVD_PGSTATUS${NORMAL}"
     else
        echo -e "${RED}$TVD_PGSTATUS${NORMAL}"
     fi
  fi

  [[ ! -z $TVD_PGVERSION ]] && printf "$format" "Cluster version" "$TVD_PGVERSION"
  if [[ ! -z $TVD_PGSTART_TIME ]]; then 
      [[ $TVD_PGSTATUS == "UP" ]] && printf "$format" "Cluster start time" "$TVD_PGSTART_TIME" || printf "$format" "Cluster last start time" "$TVD_PGSTART_TIME"
  fi
  if [[ $TVD_PGIS_STANDBY == "YES" ]]; then
     printf "$format2" "Cluster role" && echo -n "${CYAN}STANDBY${NORMAL}"
     echo -n " ["
     if [[ ! -z $TVD_PGSTANDBY_STATUS ]]; then 
        echo -n " Status: " 
        [[ $TVD_PGSTANDBY_STATUS == "streaming" ]] && echo -n "${GREEN}$TVD_PGSTANDBY_STATUS${NORMAL}" || echo -n "${RED}$TVD_PGSTANDBY_STATUS${NORMAL}"
     else
        echo -n " Status: "
        echo -n "${RED}no-wal-receiver${NORMAL}"
     fi
     if [[ ! -z $TVD_PGMASTER_HOST ]]; then 
        echo -n " Master: " 
        echo -n "${GREEN}${TVD_PGMASTER_HOST}:${TVD_PGMASTER_PORT}${NORMAL}"
     fi
     if [[ ! -z $TVD_PGIS_INRECOVERY ]]; then 
        echo -n " In recovery: " 
        [[ $TVD_PGIS_INRECOVERY == "YES" ]] && echo -n "${GREEN}$TVD_PGIS_INRECOVERY${NORMAL}" || echo -n "${RED}$TVD_PGIS_INRECOVERY${NORMAL}"
     fi
     echo -e " ]"
  fi
  [[ ! -z $TVD_PGCLUSTER_SIZE ]] && printf "$format" "Size of all tablespaces" "$TVD_PGCLUSTER_SIZE"
  [[ ! -z $TVD_PGARCHIVE_MODE ]] && printf "$format" "Cluster archive mode" "$TVD_PGARCHIVE_MODE"
  if [[ ! -z $TVD_PGCLUSTER_AGE ]]; then
     if [[ $TVD_PGCLUSTER_AGE -gt 1000000000 ]]; then
        printf "$format2" "Cluster age" 
        echo -e "${RED}$TVD_PGCLUSTER_AGE [Vacuum the database as soon as possible!]${NORMAL}"
     else
        printf "$format" "Cluster age" "$TVD_PGCLUSTER_AGE"
     fi
  fi

  if [[ ! -z $TVD_PGAUTOVACUUM_STATUS ]]; then 
     printf "$format2" "Autovacuum status" 
     if [[ $TVD_PGAUTOVACUUM_STATUS == "ACTIVE" ]]; then
        echo -e "${GREEN}$TVD_PGAUTOVACUUM_STATUS${NORMAL}"
     else
        echo -e "${RED}$TVD_PGAUTOVACUUM_STATUS${NORMAL}"
     fi
  fi
  
  [[ ! -z $TVD_PGCLUSTER_DATABASES ]] && printf "$format" "Cluster databases" "$TVD_PGCLUSTER_DATABASES"
  echo -e
  echo -e "---[$(date +"%d.%m.%Y %H:%M")]\n"


            
}



######### MAIN #####################################################

[[ $1 =~ .+ ]] && echo "ERROR: No argument accepted." && exit 1

print_current_conf

exit 0

