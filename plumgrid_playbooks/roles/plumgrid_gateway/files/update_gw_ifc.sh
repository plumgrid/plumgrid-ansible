#
# Copyright (c) 2015, PLUMgrid Inc, http://plumgrid.com
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
#
# # (c) 2015, Javeria Khan <javeriak@plumgrid.com>

# This script takes input for interface name and update option,
# to add or remove it from the PLUMgrid platform.
# This interface is compared to the ones alreay onboarded onto
# the PLUMgrid platform and appropiate action is taken
#
# Usage: sh update_gw_ifc.sh -i eth0 -u add


#!/bin/bash
set -e

update_option=add

usage() {
cat <<EOF
usage: $0 [--ifc X --update Y]
-i | --ifc : interface name
-u | --update : update option (add or remove)
-h | --help : help
EOF
exit 0
}

# Parsing arguments
while [ $# -gt 0 ]; do
  case "$1" in
    -i | --ifc ) interface=$2; shift 2 ;;
    -u | --update ) update_option=$2; shift 2 ;;
    -h | --help ) usage; shift ;;
    -- ) shift; break;;
    * )
      log "Unknown parameter: $1";
      usage; break;;
  esac
done

if [ "$update_option" = "add" ]; then
  if grep -Fq "$interface" /var/lib/libvirt/filesystems/plumgrid/var/run/plumgrid/lxc/ifc_list_gateway
  then
    echo $interface already onboarded, do nothing......
  else
    if [ -e /sys/class/net/$interface ]; then
      mac=$(cat /sys/class/net/$interface/address)
      add_port=$(/opt/pg/bin/ifc_ctl gateway add_port $interface)
      if [ -z "$add_port" ]; then
        ifup=$(/opt/pg/bin/ifc_ctl gateway ifup $interface access_phys $mac)
        if [ -z "$ifup" ]; then
          echo $interface = access_phys >> /var/lib/libvirt/filesystems/plumgrid-data/conf/pg/ifcs.conf
          echo Successfully added $interface......
          exit 0
        else
          echo $ifup
          exit 1
        fi
      else
        echo $add_port
        exit 1
      fi
    else
      echo $interface does not exist! Please fix your gateway input specification
      exit 1
    fi
  fi
elif [ "$update_option" = "remove" ]; then
  if [ -e /sys/class/net/$interface ]; then
    mac=$(cat /sys/class/net/$interface/address)
    ifdown=$(/opt/pg/bin/ifc_ctl gateway ifdown $interface access_phys $mac)
    if [ -z "$ifdown" ]; then
      del_port=$(/opt/pg/bin/ifc_ctl gateway del_port $interface)
      if [ -z "$del_port" ]; then
        sed -i "/$interface = access_phys/d" /var/lib/libvirt/filesystems/plumgrid-data/conf/pg/ifcs.conf
        echo Successfully removed $interface......
        exit 0
      else
        echo $del_port
        exit 1
      fi
    else
      echo $ifdown
      exit 1
    fi
  else
    echo $interface does not exist! Please fix your ifcs.conf
    exit 1
  fi
else
  echo Unkown Update Option specified
  exit 1
fi
