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
#
#
# Author:  Aychin Gasimov (AYG)
# Desc: Script to gather information about installation homes and data directories.
#       Script will generate pghometab and pgclustertab files.
#       Check README.md for details.
#
# Change log:
#   06.05.2020: Aychin: Initial version created
#
#

declare -r VERSION=1.1

owner=$(id -un)


PGBASENV_EXCLUDE_DIRS_DEF="tmp proc sys"
PGBASENV_EXCLUDE_FILESYSTEMS_DEF="nfs tmpfs"
PGBASENV_SEARCH_MAXDEPTH_DEF=7


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


if [[ -z $PGBASENV_VENDOR ]]; then
  [[ $owner == "enterprisedb" ]] && PGBASENV_VENDOR="enterprisedb" || PGBASENV_VENDOR="postgres"
else
  [[ ! $PGBASENV_VENDOR =~ enterprisedb|postgres ]] && echo "ERROR: PGBASENV_VENDOR can be postgres or enterprisedb. Current value is $PGBASENV_VENDOR." && exit 1
fi


[[ -z PGBASENV_EXCLUDE_DIRS ]] && PGBASENV_EXCLUDE_DIRS=$PGBASENV_EXCLUDE_DIRS_DEF
[[ -z PGBASENV_EXCLUDE_FILESYSTEMS ]] && PGBASENV_EXCLUDE_FILESYSTEMS=$PGBASENV_EXCLUDE_FILESYSTEMS_DEF
[[ -z PGBASENV_SEARCH_MAXDEPTH ]] && PGBASENV_SEARCH_MAXDEPTH=$PGBASENV_SEARCH_MAXDEPTH_DEF


# All big and small letters
declare -r LETTERS=$(printf '%b' $(printf '\\x%x' {{65..90},{97..122}}))

declare -r pghometab_file=$PGBASENV_BASE/etc/pghometab
declare -r pgclustertab_file=$PGBASENV_BASE/etc/pgclustertab


### Process parameters ######################
for d in $PGBASENV_EXCLUDE_DIRS; do
  xdirs=$xdirs" -I "$d
done

if [[ ! -z $PGBASENV_EXCLUDE_FILESYSTEMS ]]; then
for d in $PGBASENV_EXCLUDE_FILESYSTEMS; do
  xfstype="$xfstype -fstype $d -o "
done
  xfstype=${xfstype%-o*}
  xfstype=" ! \( $xfstype \)"
fi
#############################################



find_all_dirs() {
local d dir
local find_cmd="find /\$dir -maxdepth $PGBASENV_SEARCH_MAXDEPTH -type d \( -name bin -o -name global \) $xfstype 2>/dev/null"
for dir in $(ls / $xdirs); do
 eval "$find_cmd"
done
}


# Requires variable ALL_DIRS with the list of all directories to be checked for pg home
# Output format
# HOME;VERSION;WITH_SSL:SEG_SIZE:BLOCK_SIZE;HOME_IDENTIFIER
find_pg_homes() {
[[ $PGBASENV_VENDOR == "enterprisedb" ]] && local pgbinary="edb-postgres" || local pgbinary="postgres"
local existing_home_ids="$1"
local existing_ids=" $(echo "$existing_home_ids" | cut -d";" -f2) "
local d i dir home_dir home_config with_ssl seg_size block_size version home_ids home_id existing_home_id id_length orig_length skip
for d in $(echo $ALL_DIRS); do
   if [[ -f $d/pg_ctl && -f $d/$pgbinary ]]; then
     home_dir="$(dirname $d)"
     # Save home configuration to the variable
     home_config="$($home_dir/bin/pg_config)"

     # Extract ssl option, segment size and block size
     with_ssl=$(echo "$home_config" | grep "^CONFIGURE" | grep -c "\--with-openssl")
     [[ -z $with_ssl ]] && with_ssl="no-ssl" || with_ssl="ssl"
     seg_size=$(echo "$home_config" | grep "^CONFIGURE" | grep -oE "\--with-segsize=[0-9]+" | cut -d"=" -f2)
     [[ -z $seg_size ]] && seg_size="1G" || seg_size="${seg_size}G"
     block_size=$(echo "$home_config" | grep "^CONFIGURE" | grep -oE "\--with-blocksize=[0-9]+" | cut -d"=" -f2)
     [[ -z $block_size ]] && block_size="8K" || block_size="${block_size}K"   

     # Extract version of the home
     version=$(echo "$home_config" | grep "^VERSION" | cut -d"=" -f2 | awk '{print $2}' | xargs)

     # Define id for the current home
     if [[ -z $existing_home_ids ]]; then
       home_id="pgh${version//./}"
       skip=0
     else
       # Home id was already defined then we will use the same one
       existing_home_id=$(echo "$existing_home_ids" | grep "${home_dir};" | cut -d";" -f2)
       if [[ ! -z $existing_home_id ]]; then 
          home_id=$existing_home_id && skip=1
       else
          home_id="pgh${version//./}" && skip=0
       fi
     fi
     

     # Check if such id was already discovered. If yes then add a letter to the end.
     if [[ $skip -eq 0 ]]; then
       i=0; orig_length=${#home_id}
       while [[ *$home_ids* =~ " $home_id " || *$existing_ids* =~ " $home_id " ]]; do 
         # To not accumulate letters, on each iteration we will subtract the last added letter
         [[ $i -gt 0 ]] && id_length=${#home_id} && orig_length=$((id_length - 1))
         home_id=${home_id:0:$orig_length} 
         home_id="$home_id"${LETTERS:$i:1}
         ((i++))
       done
     fi
     home_ids=" $home_ids $home_id "
     
     # Output
     echo "${home_dir};${version};${with_ssl}:${seg_size}:${block_size};${home_id}"
   fi
done
}



# Output: 
# DATADIR;VERSION;LAST_ACTIVE_HOME;LAST_START_TIME;SIZE
find_pg_data() {
local existing_data_ids="$1"
local existing_ids=" $(echo "$existing_data_ids" | cut -d";" -f4) "
local d dir size ftime home fhtime version data_id data_ids existing_data_id id_length orig_length skip existing_port existing_home
for d in $(echo $ALL_DIRS); do
  if [[ -f $d/pg_control ]]; then
    dir="$(dirname $d)"
    version=$(head -1 $dir/PG_VERSION)
    if [[ -f $dir/postmaster.opts ]]; then
      home=$(dirname $(dirname $(cat $dir/postmaster.opts | awk '{print $1}')))
    else
      home=""
    fi

    # Define id for the current data dir
     if [[ -z $existing_data_ids ]]; then
       data_id="pgd${version//./}"
       skip=0
     else
       # Data dir id was already defined then we will use the same one
       existing_data_id=$(echo "$existing_data_ids" | grep "${dir};" | cut -d";" -f4)
       # Get also already defined HOME and PORT
       existing_home=$(echo "$existing_data_ids" | grep "${dir};" | cut -d";" -f2)
       existing_port=$(echo "$existing_data_ids" | grep "${dir};" | cut -d";" -f3)
       if [[ ! -z $existing_data_id ]]; then 
          data_id=$existing_data_id && skip=1
       else
          data_id="pgd${version//./}" && skip=0
       fi
     fi

     # Check if such id was already discovered. If yes then add a letter to the end.
     if [[ $skip -eq 0 ]]; then
       i=0; orig_length=${#data_id}
       while [[ *$data_ids* =~ " $data_id " || *$existing_ids* =~ " $data_id " ]]; do
         # To not accumulate letters, on each iteration we will subtract the last added letter
         [[ $i -gt 0 ]] && id_length=${#data_id} && orig_length=$((id_length - 1))
         data_id=${data_id:0:$orig_length} 
         data_id="$data_id"${LETTERS:$i:1}
         ((i++))
       done
     fi

     data_ids=" $data_ids $data_id "

     [[ ! -z $existing_home ]] && home=$existing_home
    #Output
    echo "${dir};${version};${home};${existing_port};${data_id}"

  fi
done
}




# Find running PostgreSQL porcesses. Output format:
# PID;HOME;DATADIR;PORT
find_running_procs() {
local i dir
for i in $(ps -o ppid= -C postgres -C postmaster | sort | uniq -c | awk '{ if ($1 > 1 && $2 > 1) print $2}'); do
  dir=$(readlink -f /proc/$i/exe)
  dir=$(dirname $dir)
  [[ -f $dir/pg_ctl ]] && echo "$i;$(dirname $dir);$(find_datadir_of_running_proc $i);$(find_port_of_running_proc $i)"
done
}

find_datadir_of_running_proc() {
local d
for d in $(lsof -p $1 2> /dev/null | grep DIR | awk '{print $9}'); do
  [[ -f $d/global/pg_control ]] && echo $d
done
}


find_port_of_running_proc() {
netstat -ltnp 2>/dev/null| grep -E "^tcp .* $1" | awk '{print $4}' | cut -d":" -f2
}





generate_pghometab() {
  local home_ids
  # Check if pghometab exists
  if [[ -f $pghometab_file ]]; then
    # File exists. Save all existing home_ids from the pghometab
    home_ids="$(cat $pghometab_file | grep -vE '^ *#' | awk -F";" '{print $1";"$4}')"
    # Pass home ids to the home discovery function
    local save_comments="$(cat $pghometab_file | grep -E '^ *#')"
    if [[ -z $save_comments ]]; then 
       find_pg_homes "$home_ids" > $pghometab_file
    else
       echo "$save_comments" > $pghometab_file       
       find_pg_homes "$home_ids" >> $pghometab_file
    fi

    
  else
    # File not found, will be created
    echo -e "#\n# HOME;VERSION;[OPTIONS WITH_SSL:SEGMENT_SIZE:BLOCK_SIZE];ALIAS\n#" > $pghometab_file
    find_pg_homes >> $pghometab_file

  fi

}


generate_pgclustertab() {
  local data_ids
  # Check if pgclustertab exists
  if [[ -f $pgclustertab_file ]]; then
    # File exists. Save all existing data_ids from the pgclustertab
    data_ids="$(cat $pgclustertab_file | grep -vE '^ *#' | awk -F";" '{print $1";"$3";"$4";"$5}')"
    # Pass data dir ids to the data dir discovery function
    local save_comments="$(cat $pgclustertab_file | grep -E '^ *#')"
    if [[ -z $save_comments ]]; then
      find_pg_data "$data_ids" > $pgclustertab_file
    else
     echo "$save_comments" > $pgclustertab_file
     find_pg_data "$data_ids" >> $pgclustertab_file
    fi
    
  else
    # File not found, will be created
    echo -e "#\n# PGDATA;VERSION;HOME;PORT;ALIAS\n#" > $pgclustertab_file
    find_pg_data >> $pgclustertab_file

  fi

}




###### MAIN ##########################################

[[ ! $1 =~ --force|--version|^$ ]] && echo "ERROR: Wrong argument $1. It can be --force or --version." && exit 1

[[ $1 == "--version" ]] && echo "$VERSION" && exit 0
if [[ $1 == "--force" ]]; then
   echo -e "\nExecuting in force mode.\n"
   rm $pghometab_file 2> /dev/null 
   rm $pgclustertab_file 2> /dev/null 
fi

ALL_DIRS=$(find_all_dirs)

generate_pghometab

generate_pgclustertab

exit 0

