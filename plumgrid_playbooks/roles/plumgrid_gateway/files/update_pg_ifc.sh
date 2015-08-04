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

# (c) 2015, Javeria Khan <javeriak@plumgrid.com>

# This script takes an input interface name
# and uses that to update the pg-fabric
#
# Usage: sh update_pg_ifc.sh -i eth0

#!/bin/bash
set -e

usage() {
cat <<EOF
usage: $0 [--ifc X ]
-i | --ifc : interface name
-h | --help : help
EOF
exit 0
}

# Parsing arguments
while [ $# -gt 0 ]; do
  case "$1" in
    -i | --ifc ) interface=$2; shift 2 ;;
    -h | --help ) usage; shift ;;
    -- ) shift; break;;
    * )
      log "Unknown parameter: $1";
      usage; break;;
  esac
done

if [ -e /sys/class/net/$interface ]; then

  if [ -f /var/lib/libvirt/filesystems/plumgrid/var/run/plumgrid/lxc/ifc_list_gateway ]; then

    current_fabric=$(grep "fabric_core" /var/lib/libvirt/filesystems/plumgrid/var/run/plumgrid/lxc/ifc_list_gateway | cut -d ' ' -f1)
    echo Current Fabric interface is $current_fabric

    if [ "$current_fabric" = "$interface" ]; then
      echo $interface already onboarded as fabric...
      exit 0
    fi

    if [ -n "$current_fabric" ]; then
      # Removing old fabric interface
      if [ -e /sys/class/net/$current_fabric ]; then
        ifdown=$(/opt/pg/bin/ifc_ctl gateway ifdown $current_fabric)

        if [ -z "$ifdown" ]; then
          del_port=$(/opt/pg/bin/ifc_ctl gateway del_port $current_fabric)

          if [ -z "$del_port" ]; then
            echo Successfully removed $current_fabric as pg-fabric ......
          else
            echo $del_port
            exit 1
          fi
        else
          echo $ifdown
          exit 1
        fi
      fi
      sed -i "/$current_fabric = fabric_core host/d" /var/lib/libvirt/filesystems/plumgrid-data/conf/pg/ifcs.conf

      # Adding new fabric interface
      mac=$(cat /sys/class/net/$interface/address)
      add_port=$(/opt/pg/bin/ifc_ctl gateway add_port $interface)

      if [ -z "$add_port" ]; then
        ifup=$(/opt/pg/bin/ifc_ctl gateway ifup $interface fabric_core $mac)

        if [ -z "$ifup" ]; then
          echo $interface = fabric_core host >> /var/lib/libvirt/filesystems/plumgrid-data/conf/pg/ifcs.conf
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
      # Only onboard new fabric, nothing to remove
      mac=$(cat /sys/class/net/$interface/address)
      add_port=$(/opt/pg/bin/ifc_ctl gateway add_port $interface)

      if [ -z "$add_port" ]; then
        ifup=$(/opt/pg/bin/ifc_ctl gateway ifup $interface fabric_core $mac)

        if [ -z "$ifup" ]; then
          echo $interface = fabric_core host >> /var/lib/libvirt/filesystems/plumgrid-data/conf/pg/ifcs.conf
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
    fi
  else
    echo Interface file does not exist.... doing nothing.
    exit 1
  fi

else
  echo $interface does not exist! Please fix your node fabric specification
  exit 1
fi
