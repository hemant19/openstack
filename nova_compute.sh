#!/bin/bash

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "You need to be 'root' dude." 1>&2
   exit 1
fi

# source the setup file
. ./setuprc

clear

# some vars from the SG setup file getting locally reassigned 
password=$MY_PASSWORD    
managementip=$MY_CONTROLLER_IP
rignic=$MY_CONTROLLER_NIC

# install packages
apt-get install -y nova-compute-kvm
apt-get install -y python-novaclient


# make the kernel listen to us
dpkg-statoverride  --update --add root root 0644 /boot/vmlinuz-$(uname -r)

echo "
#!/bin/sh
version="$1"
# passing the kernel version is required
[ -z "${version}" ] && exit 0
dpkg-statoverride --update --add root root 0644 /boot/vmlinuz-${version}
" > /etc/kernel/postinst.d/statoverride

# create the dnsmasq-nova.conf file
echo "
cache-size=0
" > /etc/nova/dnsmasq-nova.conf

# write out a new nova file
echo "
[DEFAULT]

# LOGS
verbose=True
debug=False
logdir=/var/log/nova
glance_host=$managementip

# STATE
auth_strategy=keystone

# RABBIT
rabbit_host=$managementip
rabbit_port=5672
rpc_backend = nova.openstack.common.rpc.impl_kombu
rabbit_userid=guest
rabbit_password=guest


# VNC CONFIG
my_ip = $managementip
vnc_enabled = True
vncserver_listen = 0.0.0.0
vncserver_proxyclient_address = $managementip
novncproxy_base_url = http://$managementip:6080/vnc_auto.html


[database]
connection = mysql://nova:$password@$managementip/nova

[keystone_authtoken]
auth_uri = http://$managementip:5000
auth_host = $managementip
auth_port = 35357
auth_protocol = http
admin_tenant_name = service
admin_user = nova
admin_password = $password
" > /etc/nova/nova.conf

rm -f /var/lib/nova/nova.sqlite 


# restart nova
service nova-api restart
service nova-cert restart
service nova-api restart
service nova-conductor restart
service nova-consoleauth restart
service nova-network restart
service nova-compute restart
service nova-novncproxy restart
service nova-scheduler restart


echo;
echo "###################################################################################################"
echo;
echo "Do a 'nova-manage service list' and a 'nova image-list' to test.  Do './openstack_horizon.sh' next."
echo;
echo "###################################################################################################"
echo;