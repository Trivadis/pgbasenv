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
# Desc: Script to generate installation bundle from current pgBasEnv base.
#       Check README.md for details.
#
# Change log:
#   06.05.2020: Aychin: Initial version created
#
#

bundle_dir=$1

dir=$(pwd) && dir=${dir//\/pgbasenv\/bin/}
[[ $? -gt 0 ]] && echo -e "\nFAILURE\n" && exit 1

[[ ! -f pgbasenv.sh ]] && echo "Execute this script from the pgbasenv bin directory." && exit 1

#current_version=$(./pgbasenv.sh --version)
current_version=$(grep "VERSION=" ./pgbasenv.sh | awk -F= {'print $2'})
[[ $? -gt 0 ]] && echo -e "\nFAILURE\n" && exit 1

echo -e "\nCurrent version: ${current_version}\n"

[[ -z $bundle_dir ]] && bundle_dir="$dir/pgbasenv/bundle"

echo -e "Destination directory: $bundle_dir\n"

cp install_pgbasenv.sh $bundle_dir
[[ $? -gt 0 ]] && echo -e "\nFAILURE\n" && exit 1

cd $dir

self=$(basename $0)
[[ $? -gt 0 ]] && echo -e "\nFAILURE\n" && exit 1

echo -e "Creating tar file: pgbasenv-${current_version}.tar\n"

tar --exclude="pgbasenv/.git" --exclude="pgbasenv/.gitignore" --exclude="pgbasenv/bin/$self" --exclude="pgbasenv/bin/install_pgbasenv.sh" --exclude="pgbasenv/etc/*tab" --exclude="pgbasenv/etc/*.env" --exclude="pgbasenv/etc/pgbasenv.conf" --exclude="pgbasenv/bundle/*" -cvf "$bundle_dir/pgbasenv-${current_version}.tar" pgbasenv

if [[ $? -eq 0 ]]; then
	echo -e "\nSUCCESS\n"
    exit 0
else
    exit 1
fi
