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
# Returns 1 metric:
#  - status_pg_neutron_db: CONSISTENT/INCONSISTENT

metrics=()

lcm_ip=$1
lcm_zone=$2
sapi_version=$3

plumgrid_file=/etc/openstack_deploy/user_pg_vars.yml
openstack_config=/etc/openstack_deploy/openstack_user_config.yml
openstack_secrets=/etc/openstack_deploy/user_osa_secrets.yml

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
  pg_user=$(cat $plumgrid_file | grep pg_username: | grep -v "#" | awk '{print $2}')
  pg_pass=$(cat $plumgrid_file | grep pg_password: | grep -v "#" | awk '{print $2}')

  if [[ -r $openstack_config ]]; then
    horizon_ip=$(cat $openstack_config | grep external_lb_vip_address: | \
                 grep -v "#" | awk '{print $2}')
  else
    echo "status error: file: $openstack_config is missing"
    exit 1
  fi

  if [[ -r $openstack_secrets ]]; then
    admin_pass=$(cat $openstack_secrets | grep keystone_auth_admin_password: | \
                 grep -v "#" | awk '{print $2}')
  else
    echo "status error: file: $openstack_secrets is missing"
    exit 1
  fi
else
  echo "status error: file: $plumgrid_file file missing."
  exit 1
fi

# Check: Neutron PG database consistency
check=$(ssh -o ConnectTimeout=10 -o "StrictHostKeyChecking=no" root@${lcm_ip} \
        "cat > /tmp/neutron_pg_db_config <<DELIM__
[creds]
os_auth_url=http://${horizon_ip}:5000/v2.0
os_admin_user=admin
os_admin_tenant=admin
os_admin_password=${admin_pass}
pg_virtual_ip=${pg_vip}
pg_username=${pg_user}
pg_password=${pg_pass}
[misc]
check_security_groups=False
DELIM__" 2> /dev/null)
if [[ $? != 0 ]]; then
  echo "Could not write config file to PG-LCM"
  exit 1
fi

check=$(ssh -o ConnectTimeout=10 -o "StrictHostKeyChecking=no" \
        root@${lcm_ip} "python /opt/pg/scripts/neutrondb_consistency.py \
        --config_file /tmp/neutron_pg_db_config" 2> /dev/null)
check=$(echo "$check" | grep "Neutron DB is consistent with PLUMgrid")
if [[ -n $check ]]; then
  metrics+=("metric status_pg_neutron_db string CONSISTENT")
else
  metrics+=("metric status_pg_neutron_db string INCONSISTENT")
fi
echo "$(printf '%s\n' "${metrics[@]}")"

ssh -o ConnectTimeout=10 -o "StrictHostKeyChecking=no" root@${lcm_ip} \
"rm /tmp/neutron_pg_db_config" 2> /dev/null
exit 0
