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
# Desc: Script to install pgBasEnv from scratch or upgrade existing version.
#       Check README.md for details.
#
# Change log:
#   06.05.2020: Aychin: Initial version created
#   29.01.2021: Aychin: Added support for scripts. psqlrc file.
#

# Defaults
TVDBASE_DEF=$HOME/tvdtoolbox
PGBASENV_EXCLUDE_DIRS_DEF="bin boot dev etc lib lib32 lib64 proc root run sbin sys tmp usr"
PGBASENV_EXCLUDE_FILESYSTEMS_DEF="autofs nfs nfs4 ramfs tmpfs"
PGBASENV_SEARCH_MAXDEPTH_DEF=7
PGBASENV_INITIAL_ALIAS_DEF=



#########################################################################################

unset TVDBASE

[[ ! $1 =~ --force|--silent|^$ ]] && echo "ERROR: Wrong argument $1. It can be --force or --silent." && exit 1

if [[ $1 == "--force" ]]; then
  FORCE=1
else
  FORCE=
fi

if [[ $1 == "--silent" ]]; then
  echo -e "\nInstalling in silent mode.\n"
  FORCE=1
  SILENT=1
  shift
  while (( "$#" )); do
    _par=${1%%=*} && _val=${1##*=}
    eval "${_par}=\"${_val}\""
    shift
  done
fi

command -v lsof > /dev/null
if [[ $? -gt 0 ]]; then
  if [[ -z $SILENT ]]; then
     read -p "Cannot find lsof command. It is required to correctly identify PGDATA of the running cluster. Ignore Y or N [N]: " IGNORE_LSOF
     IGNORE_LSOF=${IGNORE_LSOF:-N}
     [[ "$IGNORE_LSOF" == "N" ]] && exit 0
  else
     echo "ERROR: Cannot find lsof command. It is required to correctly identify PGDATA of the running cluster."
     exit 1
  fi
fi

# Check if md5sum is installed, required by scriptmgr.sh
command -v md5sum > /dev/null
if [[ $? -gt 0 ]]; then
  if [[ -z $SILENT ]]; then
     read -p "Cannot find md5sum command. It is required to correctly execute scriptmgr.sh used in .psqlrc. Ignore Y or N [N]: " IGNORE_MD5SUM
     IGNORE_MD5SUM=${IGNORE_MD5SUM:-N}
     [[ "$IGNORE_MD5SUM" == "N" ]] && exit 0
  else
     echo "ERROR: Cannot find md5sum command. It is required to correctly execute scriptmgr.sh used in .psqlrc."
     exit 1
  fi
fi

TARFILE=$(ls -1 pgbasenv-*.tar 2>/dev/null | sort -n -t"-" -k2 | tail -1)
if [[ -z $TARFILE ]]; then
	echo "ERROR: Tar file pgbasenv-(VERSION).tar do not found in current directory!"
	exit 1
else
  echo "Installing from $TARFILE"
  echo
fi

echo -e "\n>>> INSTALLATION STEP: Creating main \$HOME/.PGBASENV_HOME file.\n"

[[ $FORCE ]] && rm $HOME/.PGBASENV_HOME 2> /dev/null

if [[ -f $HOME/.PGBASENV_HOME ]]; then
  echo "F=$FORCE"
  TVDBASE=$(grep TVDBASE= $HOME/.PGBASENV_HOME | cut -d"=" -f2 | xargs)
  if [[ ! -z $TVDBASE ]]; then
    echo "TVDBASE already defined as $TVDBASE"
  fi
fi


if [[ -z $TVDBASE ]]; then
  [[ -z $SILENT ]] && read -p "Enter the directory location for the TVD Base. [$TVDBASE_DEF]: " TVDBASE
  [[ -z $TVDBASE ]] && TVDBASE=$TVDBASE_DEF
fi

TVDBASE=$(eval "echo $TVDBASE")

echo "TVDBASE: $TVDBASE"

echo "TVDBASE=$TVDBASE" > $HOME/.PGBASENV_HOME
echo "PGBASENV_BASE=\$TVDBASE/pgbasenv" >> $HOME/.PGBASENV_HOME
echo "PGOPERATE_BASE=\$TVDBASE/pgoperate" >> $HOME/.PGBASENV_HOME

PGBASENV_BASE=$TVDBASE/pgbasenv

echo -e "\n>>> INSTALLATION STEP: Creating directory if not exists $TVDBASE/pgbasenv.\n"
mkdir -p $TVDBASE/pgbasenv
[[ $? -gt 0 ]] && echo "ERROR: Cannot continue! Check the path specified." && exit 1 || echo "SUCCESS"

echo -e "\n>>> INSTALLATION STEP: Extracting files into $TVDBASE/pgbasenv.\n"
tar -xvf $TARFILE -C $TVDBASE
[[ $? -gt 0 ]] && echo "ERROR: Cannot continue! Check the output and fix issue." && exit 1 || echo "SUCCESS"

echo -e "\n>>> INSTALLATION STEP: Creating pgBasEnv environment file \$HOME/.pgbasenv_profile.\n"
echo "# pgBasEnv environment file.
# Consider that this file will be sourced from third party scripts also.

# args variable used to save and then restore positional arguments of the parent script. Do not remove these commands!
args=( \$@ ); set --
. ~/.PGBASENV_HOME
. \$PGBASENV_BASE/bin/pgsetenv.sh
set -- \"\${args[@]}\"
" > $HOME/.pgbasenv_profile
[[ $? -gt 0 ]] && echo "ERROR: Cannot continue! Failed to create \$HOME/.pgbasenv_profile." && exit 1 || echo "SUCCESS"


echo -e "\n>>> INSTALLATION STEP: Update $HOME/.pgsql_profile.\n"

if [[ -f $HOME/.pgsql_profile ]]; then
  cp $HOME/.pgsql_profile $HOME/.pgsql_profile.bak
  [[ $? -eq 0 ]] && echo "Backup created in $HOME/.pgsql_profile.bak" || exit 1
else
  touch $HOME/.pgsql_profile
fi

# Remove from .bash_profile
sed -i.bak '/pgBasEnv/d' $HOME/.bash_profile
sed -i.bak '/pgbasenv_profile/d' $HOME/.bash_profile

sed -i.bak '/pgBasEnv/d' $HOME/.pgsql_profile
sed -i.bak '/pgbasenv_profile/d' $HOME/.pgsql_profile
echo "# Added by pgBasEnv installer" >> $HOME/.pgsql_profile
echo "[[ -f ~/.pgbasenv_profile ]] && source ~/.pgbasenv_profile && pgup && pgsetenvsta --default" >> $HOME/.pgsql_profile
[[ $? -eq 0 ]] && echo "SUCCESS" || exit 1


echo -e "\n>>> INSTALLATION STEP: Creating \$PGBASENV_BASE/etc/pgbasenv.conf.\n"

if [[ -f $PGBASENV_BASE/etc/pgbasenv.conf && ! $FORCE ]]; then
  echo "File already exists. Skipping."

else

pgbasenv_conf_created=1
  
echo "##############
# Extra Vars #
##############" > $PGBASENV_BASE/etc/pgbasenv.conf

[[ -z $SILENT ]] && read -p "Setting parameter PGBASENV_EXCLUDE_DIRS. List of the root level directories to skip during scan [$PGBASENV_EXCLUDE_DIRS_DEF]: " PGBASENV_EXCLUDE_DIRS
[[ -z $PGBASENV_EXCLUDE_DIRS ]] && PGBASENV_EXCLUDE_DIRS=$PGBASENV_EXCLUDE_DIRS_DEF
echo -e "PGBASENV_EXCLUDE_DIRS: Accepted value: $PGBASENV_EXCLUDE_DIRS\n"

[[ -z $SILENT ]] && read -p "Setting parameter PGBASENV_EXCLUDE_FILESYSTEMS. List of the file system types to skip during scan [$PGBASENV_EXCLUDE_FILESYSTEMS_DEF]: " PGBASENV_EXCLUDE_FILESYSTEMS
[[ -z $PGBASENV_EXCLUDE_FILESYSTEMS ]] && PGBASENV_EXCLUDE_FILESYSTEMS=$PGBASENV_EXCLUDE_FILESYSTEMS_DEF
echo -e "PGBASENV_EXCLUDE_FILESYSTEMS: Accepted value: $PGBASENV_EXCLUDE_FILESYSTEMS\n"

[[ -z $SILENT ]] && read -p "Setting parameter PGBASENV_SEARCH_MAXDEPTH. Maximum directory depth during discovery [$PGBASENV_SEARCH_MAXDEPTH_DEF]: " PGBASENV_SEARCH_MAXDEPTH
[[ -z $PGBASENV_SEARCH_MAXDEPTH ]] && PGBASENV_SEARCH_MAXDEPTH=$PGBASENV_SEARCH_MAXDEPTH_DEF
echo -e "PGBASENV_SEARCH_MAXDEPTH: Accepted value: $PGBASENV_SEARCH_MAXDEPTH\n"


echo "
PGBASENV_EXCLUDE_DIRS=\"$PGBASENV_EXCLUDE_DIRS\"
#
#       -> Directories to be excluded during search for home and data directories. These are top level directories under / directory.
#

PGBASENV_EXCLUDE_FILESYSTEMS=\"$PGBASENV_EXCLUDE_FILESYSTEMS\"
#
#       -> Filesytems to be excluded during search for home and data directories
#

PGBASENV_SEARCH_MAXDEPTH=\"$PGBASENV_SEARCH_MAXDEPTH\"
#
#       -> Maximum search depth during discovery. Default is 7.
#
" >> $PGBASENV_BASE/etc/pgbasenv.conf

fi

echo -e "\nSUCCESS"

echo -e "\n>>> INSTALLATION STEP: Create/update .psqlrc file.\n"

if [[ -f ~/.psqlrc ]]; then
   cp ~/.psqlrc ~/.psqlrc.backup
   sed -i '/PGBASENV BEGIN/,/PGBASENV END/d' ~/.psqlrc
else
   touch ~/.psqlrc
fi
echo "-- PGBASENV BEGIN ---------------------------------" >> ~/.psqlrc
echo "\set pgbasenv_base \`echo \"$PGBASENV_BASE\"\`" >> ~/.psqlrc
echo "\! $PGBASENV_BASE/bin/scriptmgr.sh prep" >> ~/.psqlrc
echo "select substring(''||:'VERSION_NAME', 1, position('.' in ''||:'VERSION_NAME')-1) as pgreleasenum" >> ~/.psqlrc
echo "\gset" >> ~/.psqlrc
echo "\i :pgbasenv_base/scripts/.run.:pgreleasenum" >> ~/.psqlrc
echo "-- PGBASENV END -----------------------------------" >> ~/.psqlrc


echo -e "\n>>> INSTALLATION STEP: Executing first scan of the system.\n"

source $HOME/.pgbasenv_profile
pgbasenv
pgsetenv
pgup

if [[ $pgbasenv_conf_created ]]; then
  [[ -z $SILENT ]] && read -p "Setting parameter PGBASENV_INITIAL_ALIAS. Alias name to set by default. If not provided then will be set automatically: " PGBASENV_INITIAL_ALIAS
  [[ -z $PGBASENV_INITIAL_ALIAS ]] && PGBASENV_INITIAL_ALIAS=$PGBASENV_INITIAL_ALIAS_DEF
  [[ -z $PGBASENV_INITIAL_ALIAS ]] && echo "PGBASENV_INITIAL_ALIAS: Will be set automatically." || echo "PGBASENV_INITIAL_ALIAS: Accepted value: $PGBASENV_INITIAL_ALIAS"

echo "
PGBASENV_INITIAL_ALIAS=$PGBASENV_INITIAL_ALIAS
#
#       -> specifies the default alias to load on login
#       -> default is
#               1) The latest version running Cluster
#               2) The latest version stopped Cluster
#               3) The latest version installation home
#" >> $PGBASENV_BASE/etc/pgbasenv.conf
fi

echo -e "\nInstallation successfully competed. Exit the shell and login again please."

exit 0
