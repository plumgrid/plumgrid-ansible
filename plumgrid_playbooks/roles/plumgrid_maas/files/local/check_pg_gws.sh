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
#  - pg_gw_fabric_<name>: UP/DOWN
#  - pg_gw_services_name: UP/DOWN

metrics=()

lcm_ip=$1
lcm_zone=$2
sapi_version=$3

data=$(curl --connect-timeout 10 --silent -H 'Content-Type: application/json' \
      -X GET http://${lcm_ip}:8099/${sapi_version}/zones/${lcm_zone}/allIps)
status=$(echo $data | jq -r '.status' 2> /dev/null)
if [[ $status = success ]]; then
  pg_gateway_ips=$(echo $data | jq -r '.data.gateway_ips')
  pg_gateway_ips=$(echo $pg_gateway_ips | tr '/,' ' ')
else
  echo "status error: Could not get PLUMgrid Gateway IPs"
  exit 1
fi

# Check: PG Gateways fabric connectivity
fab_info=$(ssh -o ConnectTimeout=10 -o "StrictHostKeyChecking=no" root@${lcm_ip} \
        "pg-tools fabric-info --zone ${lcm_zone}" 2> /dev/null)
if [[ $? != 0 ]]; then
  echo "status error: Could not run fabric-info tool"
  exit 1
fi

for ip in ${pg_gateway_ips[@]}; do
  name=$(ssh -o ConnectTimeout=10 -o "StrictHostKeyChecking=no" root@${ip} \
          "cat /etc/hostname")
  if [[ $? != 0 ]]; then
    echo "status error: '$name'"
    exit 1
  fi
  fab_ip=$(echo "$fab_info"| grep -A2 ${ip} | tr '=,' ' ' | awk '{print $5}')
  if [[ -n $fab_ip && $fab_ip != NONE ]]; then
    metrics+=("metric pg_gw_fabric_${name} string UP")
  else
    metrics+=("metric pg_gw_fabric_${name} string DOWN")
  fi
  # Check: PG Gateway services
  check=$(ssh -o ConnectTimeout=10 -o "StrictHostKeyChecking=no" root@${ip} \
          "ps aux | grep launch_" 2> /dev/null)
  check=$(echo "$check" | grep -v "bash -c" | grep -v "root@${ip}" | grep -c "^")
  if [[ $check -eq 6 ]]; then
    metrics+=("metric pg_gw_services_${name} string UP")
  else
    metrics+=("metric pg_gw_services_${name} string DOWN")
  fi
done

echo "$(printf '%s\n' "${metrics[@]}")"
exit 0
