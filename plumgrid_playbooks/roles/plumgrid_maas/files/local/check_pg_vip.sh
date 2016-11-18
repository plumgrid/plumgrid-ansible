#!/bin/bash
#
# Copyright (c) 2016, PLUMgrid Inc, http://plumgrid.com
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Usage:
# Place this plugin in /usr/lib/rackspace-monitoring-agent/plugins
#
# Returns 2 metrics:
#  - status_pg_vip: UP/DWON
#  - pg_vip_dir: <name>

metrics=()
plumgrid_file=/etc/openstack_deploy/user_pg_vars.yml

lcm_ip=$1
lcm_zone=$2
sapi_version=$3

data=$(curl --connect-timeout 10 --silent -H 'Content-Type: application/json' \
      -X GET http://${lcm_ip}:8099/${sapi_version}/zones/${lcm_zone}/allIps)
status=$(echo $data | jq -r '.status' 2> /dev/null)
if [[ $status = success ]]; then
  pg_director_ips=$(echo $data | jq -r '.data.director_ips')
  pg_director_ips=$(echo $pg_director_ips | tr '/,' ' ')
  pg_vip=$(echo $data | jq -r '.data.virtual_ip')
else
  echo "status error: Solutions-API call returned $data"
  exit 1
fi

if [[ -r $plumgrid_file ]]; then
  mgmt_ifc=$(cat $plumgrid_file | grep pg_management: | grep -v "#" | awk '{print $2}')
else
  echo "status error: file: $plumgrid_file file missing."
  exit 1
fi

# Check: PG VIP
dir_num=1
found=0
for ip in ${pg_director_ips[@]}; do
  check=$(ssh -o ConnectTimeout=10 -o "StrictHostKeyChecking=no" root@${ip} \
          "ifconfig ${mgmt_ifc}:1 | grep ${pg_vip}" 2> /dev/null)
  if [[ $? != 0 ]]; then
    if [[ $dir_num -eq 3 && $found != 1 ]]; then
      metrics+=("metric status_pg_vip string DOWN")
      metrics+=("metric pg_vip_dir string xxxxx")
    fi
  else
    if [[ -n $check ]];then
      name=$(ssh -o ConnectTimeout=10 -o "StrictHostKeyChecking=no" root@${ip} \
              "cat /etc/hostname")
      if [[ $? != 0 ]]; then
        echo "status error: '$name'"
        exit 1
      fi
      metrics+=("metric status_pg_vip string UP")
      metrics+=("metric pg_vip_dir string $name")
      found=1
      break;
    else
      if [[ $dir_num -eq 3 ]]; then
        metrics+=("metric status_pg_vip string DOWN")
        metrics+=("metric pg_vip_dir string xxxxx")
      fi
    fi
  fi
  let dir_num=dir_num+1
done

echo "$(printf '%s\n' "${metrics[@]}")"

exit 0
