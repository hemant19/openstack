#!/bin/bash

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "You need to be 'root' dude." 1>&2
   exit 1
fi

source admin-openrc.sh

neutron net-create ext-net --shared --router:external=True

neutron subnet-create ext-net --name ext-subnet \
--allocation-pool start=192.168.18.10,end=192.168.18.20 \
--disable-dhcp --gateway 192.168.18.1 192.168.18.0/24

neutron net-create demo-net

neutron subnet-create demo-net --name demo-subnet \
  --gateway 10.0.0.1 10.0.0.0/24

neutron router-create demo-router

neutron router-interface-add demo-router demo-subnet

neutron router-gateway-set demo-router ext-net