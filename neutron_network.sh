#!/bin/bash

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "You need to be 'root' dude." 1>&2
   exit 1
fi

sed -i '/net.ipv4.ip_forward/c\net.ipv4.ip_forward=1' /etc/sysctl.conf
sed -i '/net.ipv4.conf.all.rp_filter/c\net.ipv4.conf.all.rp_filter=0' /etc/sysctl.conf
sed -i '/net.ipv4.conf.default.rp_filter/c\net.ipv4.conf.default.rp_filter=0' /etc/sysctl.conf

sysctl -p

apt-get install neutron-plugin-ml2 neutron-plugin-openvswitch-agent openvswitch-datapath-dkms neutron-l3-agent neutron-dhcp-agent


echo "
[default]
verbose = True
lock_path = $state_path/lock

rpc_backend = neutron.openstack.common.rpc.impl_kombu
rabbit_host = controller
rabbit_password = $MY_PASSWORD

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

service_neutron_metadata_proxy = true
neutron_metadata_proxy_shared_secret = $MY_PASSWORD

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
[default]
verbose = True
interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver
use_namespaces = True
" > /etc/neutron/l3_agent.ini

echo "
[default]
verbose = True
interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
use_namespaces = True
dnsmasq_config_file = /etc/neutron/dnsmasq-neutron.conf
" > /etc/neutron/dhcp_agent.ini

echo "
dhcp-option-force=26,1454
" > /etc/neutron/dnsmasq-neutron.conf

killall dnsmasq

echo "
[DEFAULT]
verbose = True
auth_url = http://controller:5000/v2.0
auth_region = regionOne
admin_tenant_name = service
admin_user = neutron
admin_password = $MY_PASSWORD
nova_metadata_ip = controller
metadata_proxy_shared_secret = $MY_PASSWORD
" > /etc/neutron/metadata_agent.ini

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

service nova-api restart
service openvswitch-switch restart
 
ovs-vsctl add-br br-int
ovs-vsctl add-br br-ex
ovs-vsctl add-port br-ex $MY_CONTROLLER_NIC

service neutron-plugin-openvswitch-agent restart
service neutron-l3-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart