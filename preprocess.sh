#!/bin/bash

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "You need to be 'root' dude." 1>&2
   exit 1
fi

#-------------Update your computer----------------#
apt-get update
apt-get dist-upgrade

#-----Install all the basic services required---------#
apt-get install ntp rabbitmq-server

#-----------------Load Variables---------------------#
sh setup.sh

#---------Change rabbitmq password--------------------#
rabbitmqctl change_password guest $RABBIT_PASS
