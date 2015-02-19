#!/bin/bash


# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "You need to be 'root' dude." 1>&2
   exit 1
fi


sed -i '/net.ipv4.conf.all.rp_filter/c\net.ipv4.conf.all.rp_filter=0' /etc/sysctl.conf
sed -i '/net.ipv4.conf.default.rp_filter/c\net.ipv4.conf.default.rp_filter=0' /etc/sysctl.conf

apt-get install neutron-common neutron-plugin-ml2 neutron-plugin-openvswitch-agent openvswitch-datapath-dkms

echo "
[default]
verbose = True
lock_path = $state_path/lock

rpc_backend = neutron.openstack.common.rpc.impl_kombu
rabbit_host = controller
rabbit_password = guest

auth_strategy = keystone

core_plugin = ml2
service_plugins = router
allow_overlapping_ips = True

notify_nova_on_port_status_changes = True
notify_nova_on_port_data_changes = True
nova_url = http://controller:8774/v2
nova_admin_auth_url = http://controller:35357/v2.0
nova_region_name = regionOne
nova_admin_username = nova
nova_admin_tenant_id = $(keystone tenant-get service | awk '/ id / {print $4}')
nova_admin_password = $MY_PASSWORD

network_api_class = nova.network.neutronv2.api.API
neutron_url = http://controller:9696
neutron_auth_strategy = keystone
neutron_admin_tenant_name = service
neutron_admin_username = neutron
neutron_admin_password = $MY_PASSWORD
neutron_admin_auth_url = http://controller:35357/v2.0
linuxnet_interface_driver = nova.network.linux_net.LinuxOVSInterfaceDriver
firewall_driver = nova.virt.firewall.NoopFirewallDriver
security_group_api = neutron

[database]
connection = mysql://neutron:$MY_PASSWORD@controller/neutron

[keystone_authtoken]
auth_uri = http://controller:5000
auth_host = controller
auth_protocol = http
auth_port = 35357
admin_tenant_name = service
admin_user = neutron
admin_password = $MY_PASSWORD
" > /etc/neutron/neutron.conf

echo "
[ml2]
type_drivers = gre
tenant_network_types = gre
mechanism_drivers = openvswitch

[ml2_type_gre]
tunnel_id_ranges = 1:1000

[ovs]
local_ip = 10.0.0.1
tunnel_type = gre
enable_tunneling = True

[securitygroup]
firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
enable_security_group = True
" >  /etc/neutron/plugins/ml2/ml2_conf.ini

service openvswitch-switch restart
ovs-vsctl add-br br-int

service nova-compute restart
service neutron-plugin-openvswitch-agent restart