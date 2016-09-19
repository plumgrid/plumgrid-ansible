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

ERROR='\033[1;31m'
GREEN='\033[0;32m'
TORQ='\033[0;96m'
INFO='\033[0;33m'
NORM='\033[0m'

neutron_env_file=/etc/openstack_deploy/env.d/neutron.yml
neutron_pb=/opt/openstack-ansible/playbooks/os-neutron-install.yml
neutron_conf_file=/etc/ansible/roles/os_neutron/templates/neutron.conf.j2
neutron_def_vars=/etc/ansible/roles/os_neutron/defaults/main.yml
inventory_file=/etc/openstack_deploy/openstack_inventory.json

search=$((cat $neutron_env_file | grep -n network_host | grep -v '#') || true)
if [[ -n $search ]]; then
  line_num=$(echo $search | tr ':' ' ' | awk '{print $1}')            # find out line number
  let line_num=line_num+1
  search=$(sed "${line_num}q;d" $neutron_env_file)
  if ! echo $search | grep -q "contains"; then
    sed -i "$line_num i \ \ \ \ contains:" $neutron_env_file
  fi
  let line_num=line_num+1
  search=$(sed "${line_num}q;d" $neutron_env_file)
  if ! echo $search | grep -q "neutron_lbaas_agent"; then
    sed -i "$line_num i \ \ \ \ \ \ - neutron_lbaas_agent" $neutron_env_file
  fi
else
  echo -e "${ERROR}physical_skel->network_hosts not found!${NORM}"
  exit 1
fi
search=$((cat $neutron_env_file | grep -n neutron_agents_container | grep -v '#') || true)
if [[ -n $search ]]; then
  line_num=$(echo $search | tr ':' ' ' | awk '{print $1}')            # find out line number
  let line_num=line_num+1
  search=$(sed "${line_num}q;d" $neutron_env_file)
  while ! echo $search | grep -q "neutron_server_container"; do
    if echo $search | grep -q "neutron_lbaas_agent"; then
      sed -i "$line_num d" $neutron_env_file
      break;
    fi
    let line_num=line_num+1
    search=$(sed "${line_num}q;d" $neutron_env_file)
  done
else
  echo -e "${ERROR}neutron_agents_container not found!${NORM}"
  exit 1
fi

search=$((cat $inventory_file | grep -n '"shared-infra_hosts":' ) || true)
if [[ -n $search ]]; then
  line_num=$(echo $search | tr ':' ' ' | awk '{print $1}')            # find out line number
  let line_num=line_num+2
  search=$(sed "${line_num}q;d" $inventory_file)
  infras=()
  while ! echo $search | grep -q "]"; do
    infras+=($search)
    let line_num=line_num+1
    search=$(sed "${line_num}q;d" $inventory_file)
  done
else
  echo -e "${ERROR}shared-infra_hosts not found in inventory file!${NORM}"
  exit 1
fi
search=$((cat $inventory_file | grep -n '"neutron_lbaas_agent":' ) || true)
if [[ -n $search ]]; then
  line_num=$(echo $search | tr ':' ' ' | awk '{print $1}')            # find out line number
  let line_num=line_num+3
  for infra in ${infras[@]}; do
  sed -i "$line_num d" $inventory_file
  sed -i "$line_num i \ \ \ \ \ \ \ \ \ \ \ \ $infra" $inventory_file
  let line_num=line_num+1
  done
else
  echo -e "${ERROR}neutron_lbaas_agent not found in inventory file!${NORM}"
  exit 1
fi

search=$((cat $neutron_pb | grep -n "set local_ip fact (is_metal)" | grep -v '#') || true)
if [[ -n $search ]]; then
  line_num=$(echo $search | tr ':' ' ' | awk '{print $1}')            # find out line number
  let line_num=line_num+1
  search=$(sed "${line_num}q;d" $neutron_pb)
  while ! echo $search | grep -q "name:"; do
    if echo $search | grep -q "set_fact:"; then
      let line_num=line_num+1
      sed -i "$line_num d" $neutron_pb
      sed -i "$line_num i \ \ \ \ \ \ \ \ _local_ip: \"{{ hostvars[inventory_hostname]['ansible_ssh_host'] }}\"" $neutron_pb
      break;
    fi
    let line_num=line_num+1
    search=$(sed "${line_num}q;d" $neutron_pb)
  done
else
  echo -e "${ERROR}Task: \"set local_ip fact (is_metal)\" not found in neutron playbook!${NORM}"
  exit 1
fi

search=$((cat $neutron_conf_file | grep -n "service_plugins") || true)
if [[ -n $search ]]; then
  line_num=$(echo $search | tr ':' ' ' | awk '{print $1}')            # find out line number
  let line_num=line_num-1
  search=$(sed "${line_num}q;d" $neutron_conf_file)
  if echo $search | grep -q "neutron_plugin_type"; then
    sed -i "$line_num d" $neutron_conf_file
    let line_num=line_num+1
    sed -i "$line_num d" $neutron_conf_file
  fi
else
  echo -e "${ERROR}serice_plugin not found in file $neutron_conf_file${NORM}"
  exit 1
fi

search=$((cat $neutron_def_vars | grep -n "neutron-lbaas-agent:" | grep -v '#') || true)
if [[ -n $search ]]; then
  line_num=$(echo $search | tr ':' ' ' | awk '{print $1}')            # find out line number
  let line_num=line_num+1
  search=$(sed "${line_num}q;d" $neutron_def_vars)
  while ! echo $search | grep -q "service_group:"; do
    if [[ ${search:0:1} != " " ]]; then                              # check if next yaml variable
      echo -e "${ERROR}service_group not found under neutron-lbaas-agent${NORM}"
      exit 1
    fi
    let line_num=line_num+1
    search=$(sed "${line_num}q;d" $neutron_def_vars)
  done
  sed -i "$line_num d" $neutron_def_vars
  sed -i "$line_num i \ \ \ service_group: network_hosts" $neutron_def_vars
else
  echo -e "${ERROR}neutron_services->neutron-lbaas-agent not found!${NORM}"
  exit 1
fi

echo -e "${GREEN}LBaaS changes successfully made.${NORM}"
exit 0
