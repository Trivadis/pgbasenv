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
# Desc: Script to set Postgres or EnterpriseDB environment.
#       Can set general environment, alias based or data directory based environment.
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
    return 1
  fi
fi

if [[ -f $PGBASENV_BASE/etc/pgbasenv.conf ]]; then
  . $PGBASENV_BASE/etc/pgbasenv.conf
else
  echo "No $PGBASENV_BASE/etc/pgbasenv.conf config file found."
  return 1
fi

export TVDBASE
export PGBASENV_BASE
export PGOPERATE_BASE

owner=$(id -un)

if [[ -z $PGBASENV_VENDOR ]]; then
  [[ $owner == "enterprisedb" ]] && PGBASENV_VENDOR="enterprisedb" || PGBASENV_VENDOR="postgres"
else
  [[ ! $PGBASENV_VENDOR =~ enterprisedb|postgres ]] && echo "ERROR: PGBASENV_VENDOR can be postgres or enterprisedb. Current value is $PGBASENV_VENDOR." && exit 1
fi



pgunsource() {
   [[ -z $1 ]] && echo "File name required." && return 1
   local pgunsource_file="$(
      grep -oE "^ *export *[^ ]+=" $1 | cut -d"=" -f1 | awk '{print "unset "$2" 2>/dev/null"}'
      grep -oE "^ *[^ ]+=" $1 | awk -F"=" '{print "unset "$1" 2>/dev/null"}'
      grep -oE "^ *alias *[^ ]+=" $1 | cut -d"=" -f1 | awk '{print "unalias "$2" 2>/dev/null"}'
    )"
   eval "$pgunsource_file"
}

pgunsetclsenv() {
  unset TVD_PGCLUSTER_NAME
  unset PGDATA
  unset PGPORT
  unset PGSQL_BASE
  unset TVD_PGHOME
  unset TVD_PGSTATUS
  unset TVD_PGVERSION
  unset TVD_PGSTART_TIME
  unset TVD_PGIS_STANDBY
  unset TVD_PGIS_INRECOVERY
  unset TVD_PGCLUSTER_SIZE
  unset TVD_PGCLUSTER_DATABASES
  unset TVD_PGUSER_DATABASES
  unset TVD_PGAUTOVACUUM_STATUS
  unset TVD_PGCLUSTER_AGE
  unset TVD_PGLOG_COLLECTOR
  unset TVD_PGLOG_DIR
  unset TVD_PGLOG_FILE
  unset TVD_PGCONF
  unset TVD_PGHBA
  unset TVD_PGARCHIVE_MODE
  unset PGBASENV_ALIAS
  unset EDBHOME
  unset PGDATABASE
  unset PGLOCALEDIR
  unset MANPATH
  export PATH=${PATH//PGBASENV:*:PGBASENV:/}

  # Unalias all db aliase
  local a
  for a in $(alias -p | awk '{print $2}' | grep -E "^db." | cut -d"=" -f1); do
    unalias "$a"
  done;
 
  # Unsource all alias env files
  local env_file
  for env_file in $(ls -1 $PGBASENV_BASE/etc/*.env 2>/dev/null); do
    pgunsource $env_file  
  done

}


pgunsetenv() {
  unset TVD_PGUP_CLUSTERS

  if [[ -f $PGBASENV_BASE/etc/pghometab ]]; then
    while IFS=";" read -r _ _ _ alias; do
       unalias $alias 2> /dev/null
    done <<< "$(cat $PGBASENV_BASE/etc/pghometab | grep -vE '^ *#')"
  fi

  if [[ -f $PGBASENV_BASE/etc/pgclustertab ]]; then
    while IFS=";" read -r _ _ _ _ alias; do
       unalias $alias 2> /dev/null
    done <<< "$(cat $PGBASENV_BASE/etc/pgclustertab | grep -vE '^ *#')"
  fi
  
}


pgunsetconf() {
 
 if [[ -f $PGBASENV_BASE/etc/pgbasenv_standard.conf ]]; then
   pgunsource $PGBASENV_BASE/etc/pgbasenv_standard.conf
 fi

 if [[ -f $PGBASENV_BASE/etc/pgbasenv.conf ]]; then
   pgunsource $PGBASENV_BASE/etc/pgbasenv.conf
 fi

  eval "$unset_pgbasenv_std"
  eval "$unset_pgbasenv"

}


# Try to read $PGDATA/current_logfiles, if not exists, then
#   replaces %x patterns in logfile name and try to get last modified file matching the pattern
pglogfile() {
   [[ $TVD_PGLOG_COLLECTOR == "off" ]] && return 1
     local dbv_log_file=$(grep stderr $PGDATA/current_logfiles 2>/dev/null | awk '{print $2}' | xargs)
     if [[ ! -z $dbv_log_file ]]; then
       [[ $dbv_log_file =~ ^/ ]] && echo $dbv_log_file || echo $PGDATA/$dbv_log_file
       return 0
     else
       if [[ ! -z $TVD_PGLOG_FILE ]]; then
           echo $(ls -1tr ${TVD_PGLOG_FILE//%?/*} 2> /dev/null | tail -1 | xargs)
           return 0
       fi
     fi
    return 1
}


pgsetclsenv() {
  local psqlout dbv_cl_name dbv_is_recmode dbv_cls_size dbv_dbs dbv_dbs_user dbv_cls_age dbv_av_stat dbv_log_collector dbv_log_dir dbv_log_file dbv_conf dbv_hba dbv_arch

  dv() {
    echo "$psqlout" | grep "${1}:" | cut -d":" -f2 | tr '\n' ' ' | xargs
  }

  [[ -z $PGBASENV_CHECK_USER ]] && PGBASENV_CHECK_USER=$USER
  [[ -z $PGBASENV_CHECK_DATABASE ]] && PGBASENV_CHECK_DATABASE=template1


  # Is standby cluster
  if [[ $(echo $TVD_PGVERSION | cut -d"." -f1) -ge 12 ]]; then
    [[ -f $PGDATA/standby.signal ]] && export TVD_PGIS_STANDBY="YES" || export TVD_PGIS_STANDBY="NO"
  else
    [[ $(grep standby_mode $PGDATA/recovery.conf 2>/dev/null | cut -d"=" -f2 | xargs) =~ on|ON|On ]] && export TVD_PGIS_STANDBY="YES" || export TVD_PGIS_STANDBY="NO"
  fi

  # Check if psql can be used
  $TVD_PGHOME/bin/psql -U $PGBASENV_CHECK_USER -d $PGBASENV_CHECK_DATABASE -c ";" -t  2> /dev/null
  if [[ $? -gt 0 || "$TVD_PGSTATUS" == "DOWN" ]]; then
     return 1
  fi


psqlout="$($TVD_PGHOME/bin/psql -U $PGBASENV_CHECK_USER -d $PGBASENV_CHECK_DATABASE -t <<EOF
select 'dbv_cl_name:'||setting from pg_settings where name='cluster_name';
select 'dbv_is_recmode:'||pg_is_in_recovery();
select 'dbv_cls_size:'||pg_size_pretty(sum(pg_tablespace_size(spcname))) from pg_tablespace;
select 'dbv_dbs:'||datname from pg_database;
select 'dbv_dbs_user:'||datname from pg_database where datname not in ('postgres','enterprisedb','template0','template1');
select 'dbv_cls_age:'||max(age(datfrozenxid)) from pg_database;
select 'dbv_av_stat:'||setting from pg_settings where name in ('autovacuum','track_counts');
select 'dbv_log_collector:'||setting from pg_settings where name='logging_collector';
select 'dbv_log_dir:'||setting from pg_settings where name='log_directory';
select 'dbv_log_file:'||setting from pg_settings where name='log_filename';
select 'dbv_conf:'||setting from pg_settings where name='config_file';
select 'dbv_hba:'||setting from pg_settings where name='hba_file';
select 'dbv_arch:'||setting from pg_settings where name='archive_mode';
EOF
)"


  # Cluster name
  dbv_cl_name=$(dv dbv_cl_name)
  [[ ! -z $dbv_cl_name ]] && export TVD_PGCLUSTER_NAME=$dbv_cl_name
  
  # Is standby recovery
  dbv_is_recmode=$(dv dbv_is_recmode)
  if [[ ! -z $dbv_is_recmode ]]; then 
        [[ ${dbv_is_recmode:0:1} == "t" ]] && export TVD_PGIS_INRECOVERY="YES" || export TVD_PGIS_INRECOVERY="NO"
  fi

  # Overall cluster size, including all tablespaces
  dbv_cls_size=$(dv dbv_cls_size)
  [[ ! -z $dbv_cls_size ]] && export TVD_PGCLUSTER_SIZE=${dbv_cls_size// /}
  
  # Databases in cluster
  dbv_dbs=$(dv dbv_dbs)
  [[ ! -z $dbv_dbs ]] && export TVD_PGCLUSTER_DATABASES=${dbv_dbs// /,}
  
  # Set db. aliases for databases
  local db
  for db in $dbv_dbs; do
    alias "db.${db}"="export PGDATABASE=${db} && psql"
  done;
  
  # User databases in cluster
  dbv_dbs_user=$(dv dbv_dbs_user)
  [[ ! -z $dbv_dbs_user ]] && export TVD_PGUSER_DATABASES=${dbv_dbs_user// /,}

  # CLuster age
  dbv_cls_age=$(dv dbv_cls_age)
  [[ ! -z $dbv_cls_age ]] && export TVD_PGCLUSTER_AGE=$dbv_cls_age

  # Is autovacuum enabled
  dbv_av_stat=$(dv dbv_av_stat)
  if [[ ! -z $dbv_av_stat ]]; then
        [[ $dbv_av_stat == "on on" ]] && export TVD_PGAUTOVACUUM_STATUS="ACTIVE" || export TVD_PGAUTOVACUUM_STATUS="NOTACTIVE"
  fi

  # Logging collector status
  dbv_log_collector=$(dv dbv_log_collector)
  [[ ! -z $dbv_log_collector ]] && export TVD_PGLOG_COLLECTOR=$dbv_log_collector
  
  # Logging collector directory
  dbv_log_dir=$(dv dbv_log_dir)
  if [[ ! -z $dbv_log_dir ]]; then 
       [[ $dbv_log_dir =~ ^/ ]] && export TVD_PGLOG_DIR=$dbv_log_dir || export TVD_PGLOG_DIR=$PGDATA/$dbv_log_dir
  fi

  # Logging collector current logfile
  if [[ $TVD_PGLOG_COLLECTOR == "on" ]]; then
    dbv_log_file=$(dv dbv_log_file)
    [[ ! -z $dbv_log_file ]] && export TVD_PGLOG_FILE=$TVD_PGLOG_DIR/"$dbv_log_file"
  fi

  # Cluster main config file 
  dbv_conf=$(dv dbv_conf)
  [[ ! -z $dbv_conf ]] && export TVD_PGCONF=$dbv_conf

  # Cluster hba config file 
  dbv_hba=$(dv dbv_hba)
  [[ ! -z $dbv_hba ]] && export TVD_PGHBA=$dbv_hba

  # Cluster archive mode status 
  dbv_arch=$(dv dbv_arch)
  [[ ! -z $dbv_arch ]] && export TVD_PGARCHIVE_MODE=$dbv_arch

  # Set PGSQL_BASE from pgOperate parameters_<alias>.conf file if exists.
  if [[ -f $PGOPERATE_BASE/etc/parameters_${pgbasenv_pgalias}.conf ]]; then
    local pgsql_base=$(grep -E "^PGSQL_BASE.*=" $PGOPERATE_BASE/etc/parameters_${pgbasenv_pgalias}.conf)
    eval "export $pgsql_base"
  fi


}


pgsetenvsta() { 
   . $PGBASENV_BASE/bin/pgsetenv.sh $1 $2
   $PGBASENV_BASE/bin/pgstatus.sh
}

export -f pgunsource
export -f pgunsetconf
export -f pglogfile 
export -f pgunsetenv
export -f pgsetclsenv
export -f pgunsetclsenv
export -f pgsetenvsta


######### MAIN #####################################################


[[ ${1:0:1} == "-" && ! $1 =~ --default ]] && echo "ERROR: Wrong argument $1. It can be --default or alias or no argument at all." && return 1


# Input variables
# First can be alias or cluster data directory. The second is pg installation home alias to set with data directory alias
pgbasenv_pgalias=$1
pgbasenv_pghome=$2


pgunsetconf

[[ -f $PGBASENV_BASE/etc/pgbasenv_standard.conf ]] && . $PGBASENV_BASE/etc/pgbasenv_standard.conf || echo "Failed to load $PGBASENV_BASE/etc/pgbasenv_standard.conf"
[[ -f $PGBASENV_BASE/etc/pgbasenv.conf ]] && . $PGBASENV_BASE/etc/pgbasenv.conf || echo "Failed to load $PGBASENV_BASE/etc/pgbasenv.conf"

# Set default alias
if [[ $pgbasenv_pgalias == "--default" ]]; then
   if [[ ! -z $PGBASENV_INITIAL_ALIAS ]]; then
     pgbasenv_pgalias=$PGBASENV_INITIAL_ALIAS
   else
     pgbasenv_pgalias="$($PGBASENV_BASE/bin/pgup.sh --list | grep ";UP;" | awk -F";" '{print $2" "$1}' | sort -uh | tail -1)"
     [[ -z $pgbasenv_pgalias ]] && pgbasenv_pgalias="$($PGBASENV_BASE/bin/pgup.sh --list | grep ";DOWN;" | awk -F";" '{print $2" "$1}' | sort -uh | tail -1)"
     [[ -z $pgbasenv_pgalias ]] && pgbasenv_pgalias="$(cat $PGBASENV_BASE/etc/pghometab | grep -vE '^ *#' | awk -F";" '{print $2" "$4}' | sort -uh | tail -1)"
     pgbasenv_pgalias=${pgbasenv_pgalias//* /}
   fi
fi

if [[ -z $pgbasenv_pgalias ]]; then 

# SET GENERAL ENVIRONMENT 

  pgunsetenv
  
  $PGBASENV_BASE/bin/pgbasenv.sh

  # Begin exporting functions
  pgbasenv() { $PGBASENV_BASE/bin/pgbasenv.sh "$@";   }
  pgup()     { $PGBASENV_BASE/bin/pgup.sh "$@";       }
  pgstatus() { $PGBASENV_BASE/bin/pgstatus.sh "$@";   }
  pgsetenv() { . $PGBASENV_BASE/bin/pgsetenv.sh "$@"; }
  export -f pgbasenv pgup pgstatus pgsetenv
  # End exporting functions

  
  if [[ -f $PGBASENV_BASE/etc/pghometab ]]; then
    while IFS=";" read -r _ _ _ alias; do
       alias $alias="pgsetenvsta $alias"
    done <<< "$(cat $PGBASENV_BASE/etc/pghometab | grep -vE '^ *#')"
  else
    echo "Failed to load $PGBASENV_BASE/etc/pghometab. File not exist."
  fi

  if [[ -f $PGBASENV_BASE/etc/pgclustertab ]]; then
    while IFS=";" read -r _ _ _ _ alias; do
       alias $alias="pgsetenvsta $alias"
    done <<< "$(cat $PGBASENV_BASE/etc/pgclustertab | grep -vE '^ *#')"
  else
    echo "Failed to load $PGBASENV_BASE/etc/pgclustertab. File not exist."
  fi

  export TVD_PGUP_CLUSTERS=$($PGBASENV_BASE/bin/pgup.sh --list | grep ";UP;" | awk -F";" '{print $1}' | xargs)

else

# SET ENVIRONMENT BY ALIAS

pgunsetclsenv

# If pgbasenv_pgalias will include "/" then treat it as PGDATA and use it to set environment instead of alias.
[[ $pgbasenv_pgalias =~ .*/.* ]] && use_pgdata_as_alias=1 || unset use_pgdata_as_alias 

unset PGBASENV_ALIAS

[[ ! $use_pgdata_as_alias ]] && pgbasenv_PGHOME_ITEM=$(cat $PGBASENV_BASE/etc/pghometab | grep -vE '^ *#' | grep -E ";$pgbasenv_pgalias$")


if [[ -z $pgbasenv_PGHOME_ITEM ]]; then
   [[ ! $use_pgdata_as_alias ]] && pgbasenv_PGCLUSTER_ITEM=$($PGBASENV_BASE/bin/pgup.sh --list | grep -E "${pgbasenv_pgalias};" | head -1)
   [[   $use_pgdata_as_alias ]] && pgbasenv_PGCLUSTER_ITEM=$($PGBASENV_BASE/bin/pgup.sh --list | grep -E ";${pgbasenv_pgalias};")
fi

if [[ -z $pgbasenv_PGHOME_ITEM && ! -z $pgbasenv_PGCLUSTER_ITEM ]]; then
# CLUSTER DATA DIRECOTRY ALIAS

  #export PS1="\h[$pgbasenv_pgalias]$ "
  pgbasenv_pgalias=$(echo $pgbasenv_PGCLUSTER_ITEM | cut -d";" -f1)
  export PGDATA=$(echo $pgbasenv_PGCLUSTER_ITEM | cut -d";" -f7)
  export TVD_PGSTATUS=$(echo $pgbasenv_PGCLUSTER_ITEM | cut -d";" -f3)
  export TVD_PGVERSION=$(echo $pgbasenv_PGCLUSTER_ITEM | cut -d";" -f2)
  export TVD_PGSTART_TIME=$(echo $pgbasenv_PGCLUSTER_ITEM | cut -d";" -f8)

  pgbasenv_cluster_port=$(echo $pgbasenv_PGCLUSTER_ITEM | cut -d";" -f4)
  if [[ ! -z $pgbasenv_cluster_port ]]; then
    export PGPORT=$pgbasenv_cluster_port
  else
    # If it will be null, then libpq will use default port and if on this default port already running some other instance,
    # then it will come to unexpected results.
    export PGPORT=1
  fi

  if [[ ! -z $pgbasenv_pghome ]]; then
    pgbasenv_PGHOME_ITEM=$(cat $PGBASENV_BASE/etc/pghometab | grep -vE '^ *#' | grep -E ";$pgbasenv_pghome$")
    pgbasenv_cluster_home=$(echo $pgbasenv_PGHOME_ITEM | cut -d";" -f1)
  else
    pgbasenv_cluster_home=$(echo $pgbasenv_PGCLUSTER_ITEM | cut -d";" -f9)
  fi

  if [[ -z $pgbasenv_cluster_home ]]; then
    echo "Warning: PATH was not set, because cluster home is unknown."
    export PATH=${PATH//PGBASENV:*:PGBASENV:/}
    unset TVD_PGHOME
  else
    export TVD_PGHOME=$pgbasenv_cluster_home
    export PATH=${PATH//PGBASENV:*:PGBASENV:/}
    export PATH=PGBASENV:$pgbasenv_cluster_home/bin:PGBASENV:$PATH
  fi
  

  [[ ! $use_pgdata_as_alias ]] && export PGBASENV_ALIAS=$pgbasenv_pgalias || export PGBASENV_ALIAS=$(echo $pgbasenv_PGCLUSTER_ITEM | cut -d";" -f1)


  if [[ $PGBASENV_VENDOR == "enterprisedb" ]]; then
     [[ ! -z $TVD_PGHOME ]] && export EDBHOME=$TVD_PGHOME
     export PGDATABASE=edb
  else
     export PGDATABASE=postgres
     [[ ! -z $TVD_PGHOME ]] && export MANPATH=$MANPATH:$TVD_PGHOME/share/man
  fi

  [[ ! -z $TVD_PGHOME ]] && export PGLOCALEDIR=$TVD_PGHOME/share/locale

  # Set cluster specific environment
  pgsetclsenv

  [[ -f $PGBASENV_BASE/etc/${PGBASENV_ALIAS}.env ]] && source $PGBASENV_BASE/etc/${PGBASENV_ALIAS}.env


elif [[ ! -z $pgbasenv_PGHOME_ITEM ]]; then
# CLUSTER HOME ALIAS
  pgbasenv_cluster_home=$(echo $pgbasenv_PGHOME_ITEM | cut -d";" -f1)
  if [[ -z $pgbasenv_cluster_home ]]; then
    echo "Error: PATH was not set, because cluster home is unknown."
    export PATH=${PATH//PGBASENV:*:PGBASENV:/}
    unset PGBASENV_ALIAS
  else
    #export PS1="\h[$pgbasenv_pgalias]$ "
    export PGBASENV_ALIAS=$pgbasenv_pgalias
    export TVD_PGHOME=$pgbasenv_cluster_home
    export PATH=${PATH//PGBASENV:*:PGBASENV:/}
    export PATH=PGBASENV:$pgbasenv_cluster_home/bin:PGBASENV:$PATH
    if [[ $PGBASENV_VENDOR == "enterprisedb" ]]; then
      export EDBHOME=$TVD_PGHOME
    else
      export MANPATH=$MANPATH:$TVD_PGHOME/share/man
    fi

   export PGLOCALEDIR=$TVD_PGHOME/share/locale
   
   [[ -f $PGBASENV_BASE/etc/${PGBASENV_ALIAS}.env ]] && source $PGBASENV_BASE/etc/${PGBASENV_ALIAS}.env

  fi

fi


if [[ -z $PGBASENV_ALIAS ]]; then
  pgunsetclsenv
  [[ ! $use_pgdata_as_alias ]] && echo "Error: No such alias." || echo "Error: No such cluster data directory."
fi

fi


unset pgbasenv_cluster_home pgbasenv_cluster_port pgbasenv_PGHOME_ITEM pgbasenv_pgalias pgbasenv_PGCLUSTER_ITEM pgbasenv_pghome use_pgdata_as_alias
