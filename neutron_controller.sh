#!/bin/bash


# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "You need to be 'root' dude." 1>&2
   exit 1
fi

apt-get install vlan qemu-kvm libvirt-bin ubuntu-vm-builder bridge-utils -y

apt-get install ntp -y
service ntp restart


sed -e "
/^server ntp.ubuntu.com/i server 127.127.1.0
/^server ntp.ubuntu.com/i fudge 127.127.1.0 stratum 10
/^server ntp.ubuntu.com/s/^.*$/server ntp.ubuntu.com iburst/;
" -i /etc/ntp.conf

echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl net.ipv4.ip_forward=1

. ./setuprc

service_pass=$MY_PASSWORD

mysql -u root -p$MY_PASSWORD <<EOF
CREATE DATABASE nova;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '$service_pass';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '$service_pass';
EOF

source admin-openrc.sh

keystone user-create --name neutron --pass $MY_PASSWORD --email $MY_EMAIL
keystone user-role-add --user neutron --tenant service --role admin
keystone service-create --name neutron --type network --description "OpenStack Networking"

keystone endpoint-create \
  --service-id $(keystone service-list | awk '/ network / {print $2}') \
  --publicurl http://controller:9696 \
  --adminurl http://controller:9696 \
  --internalurl http://controller:9696

apt-get install neutron-server neutron-plugin-ml2 python-neutronclient

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
[ml2]
type_drivers = gre
tenant_network_types = gre
mechanism_drivers = openvswitch

[ml2_type_gre]
tunnel_id_ranges = 1:1000

[securitygroup]
firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
enable_security_group = True

" > /etc/neutron/plugins/ml2/ml2_conf.ini

service nova-api restart
service nova-scheduler restart
service nova-conductor restart
service neutron-server restart