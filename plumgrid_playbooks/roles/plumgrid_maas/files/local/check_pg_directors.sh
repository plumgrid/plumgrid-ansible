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
# Returns 3 metrics:
#  - status_pg_director_<name>: UP/DWON
#  - status_pg_director_<name>: UP/DWON
#  - status_pg_director_<name>: UP/DWON

metrics=()

lcm_ip=$1
lcm_zone=$2
sapi_version=$3

data=$(curl --connect-timeout 10 --silent -H 'Content-Type: application/json' \
      -X GET http://${lcm_ip}:8099/${sapi_version}/zones/${lcm_zone}/allIps)
status=$(echo $data | jq -r '.status' 2> /dev/null)
if [[ $status = success ]]; then
  pg_director_ips=$(echo $data | jq -r '.data.director_ips')
  pg_director_ips=$(echo $pg_director_ips | tr '/,' ' ')
else
  echo "status error: Solutions-API call returned $data"
  exit 1
fi

pg_status=$(ssh -o ConnectTimeout=10 -o "StrictHostKeyChecking=no" root@${lcm_ip} \
            "pg-tools get-status --zone ${lcm_zone} -v" 2> /dev/null)

# Check: Directors
dir_num=1
for ip in ${pg_director_ips[@]}; do
  name=$(ssh -o ConnectTimeout=10 -o "StrictHostKeyChecking=no" root@${ip} \
          "cat /etc/hostname")
  if [[ $? != 0 ]]; then
    echo "status error: '$name'"
    exit 1
  fi
  check=$(echo "$pg_status" | grep "Director at ${ip} alive")
  if [[ -n $check ]];then
    metrics+=("metric status_pg_director_${name} string UP")
  else
    metrics+=("metric status_pg_director_${name} string DOWN")
  fi
  let dir_num=dir_num+1
done

echo "$(printf '%s\n' "${metrics[@]}")"

exit 0
