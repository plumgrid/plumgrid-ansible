PLUMgrid Playbooks for OpenStack
##########################################
:date: 2015-06-12 09:00
:tags: networking, openstack, cloud, ansible

License
-------
Copyright 2015 PLUMgrid Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at:

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Playbooks
-------

This set of playbooks integrate with the openstack-ansible project to deploy the PLUMgrid Controller and Compute components that help manage the PLUMgrid neutron plugin. The plugin itself must be enabled through the openstack-ansible neutron playbooks.

Follow the community installation guide for OSA PLUMgrid here for full installation steps:

 *http://docs.openstack.org/developer/openstack-ansible/install-guide/app-plumgrid.html*
 
Steps reproduced below: 

1. Set the ``neutron_plugin_type`` parameter to ``plumgrid`` in the ``playbooks/roles/os_neutron/defaults/main.yml`` file.

.. code-block:: yaml

  # Neutron Plugins
  neutron_plugin_type: plumgrid


2. Also in the same file, disable the installation of all neutron-agents in the ``neutron_services`` dictionary, by setting their ``service_en`` keys to ``False``

.. code-block:: yaml

  # Neutron Services
  neutron_services:
   neutron-dhcp-agent:
     service_name: neutron-dhcp-agent
     service_en: False
     service_conf: dhcp_agent.ini
     service_group: neutron_agent
     service_rootwrap: rootwrap.d/dhcp.filters
     config_options: --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/dhcp_agent.ini
     config_overrides: "{{ neutron_dhcp_agent_ini_overrides }}"
     config_type: "ini"
   neutron-linuxbridge-agent:
     service_name: neutron-linuxbridge-agent
     service_en: False
     service_conf: plugins/ml2/ml2_conf.ini
     service_group: neutron_linuxbridge_agent
     service_rootwrap: rootwrap.d/linuxbridge-plugin.filters
     config_options: --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini
     config_overrides: "{{ neutron_ml2_conf_ini_overrides }}"
     config_type: "ini"
   neutron-metadata-agent:
     service_name: neutron-metadata-agent
     service_en: False
     service_conf: metadata_agent.ini
     service_group: neutron_agent
     config_options: --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/metadata_agent.ini
     config_overrides: "{{ neutron_metadata_agent_ini_overrides }}"
     config_type: "ini"
   neutron-metering-agent:
     service_name: neutron-metering-agent
     service_en: False
     service_conf: metering_agent.ini
     service_group: neutron_agent
     config_options: --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/metering_agent.ini
     config_overrides: "{{ neutron_metering_agent_ini_overrides }}"
     config_type: "ini"
   neutron-l3-agent:
     service_name: neutron-l3-agent
     service_en: False
     service_conf: l3_agent.ini
     service_group: neutron_agent
     service_rootwrap: rootwrap.d/l3.filters
     config_options: --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/l3_agent.ini
     config_overrides: "{{ neutron_l3_agent_ini_overrides }}"
     config_type: "ini"

3. These PLUMgrid playbooks can then be cloned into the ``/opt/`` directory.

4. Create a user variables file, using the sample in ``etc/user_pg_vars.yml.example`` and place it in ``/etc/openstack_deploy/``

5. Run the playbooks with (do this before the openstack-setup.yml playbook is run):

.. code-block:: yaml

   cd /opt/plumgrid-ansible/plumgrid_playbooks
   openstack-ansible plumgrid_all.yml

Notes
-------

Contact PLUMgrid for an Installation pack (including Full/Trial License, deployment documentation): info@plumgrid.com

