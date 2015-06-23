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

This set of playbooks integrate with the os-ansible-deployment project to deploy the PLUMgrid Controller and Compute components that help manage the PLUMgrid neutron plugin. The plugin itself must be enabled through the os-ansible-deployment neutron playbooks as follows.

1. Set the following parameter to ``plumgrid`` in the ``rpc_deployment/inventory/group_vars/neutron_all.yml`` file.

.. code-block:: yaml

  # Neutron Plugins
  neutron_plugin_type: plumgrid


2. Also in the same file, disable the installation of all neutron-agents in the ``neutron_services`` dictionary, by setting their ``service_en`` keys to ``false``

3. The PLUMgrid playbooks can then be cloned into the ``../playbooks/`` directory.

4. Create a user variables file, using the sample in ``etc/user_pg_vars.yml.example`` and place it in ``/etc/rpc_deploy/``

5. Run the playbooks with (do this before the openstack-setup.yml playbook is run):

.. code-block:: yaml

   openstack-ansible playbooks/plumgrid-ansible/plumgrid_playbooks/plumgrid_all.yml

Notes
-------

Contact PLUMgrid for an Installation pack (including Full/Trial License, deployment documentation): info@plumgrid.com

