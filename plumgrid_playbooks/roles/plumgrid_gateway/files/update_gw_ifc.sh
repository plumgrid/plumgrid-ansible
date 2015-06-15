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
      echo $interface does not exist! Please fix your zone_config.yml
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
        sed -i "/$interface = access_phys/d' /var/lib/libvirt/filesystems/plumgrid-data/conf/pg/ifcs.conf
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
  echo "Unkown Update Option specified"
  exit 1
fi
