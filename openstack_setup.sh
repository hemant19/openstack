#!/bin/bash

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "You need to be 'root' dude." 1>&2
   exit 1
fi

if [ -f ./setuprc ]
then
	echo "######################################################################################################"
	echo;
	echo "Setup has already been run.  Edit or delete the ./setuprc file in this directory to reconfigure setup."
	echo;
	echo "You can reset the installation by running './openstack_cleanup.sh'"
	echo;
	echo "#######################################################################################################"
	echo;
	exit
fi


#get the rigs ip address...
read -p "Enter the device name for this rig's NIC (eth0, etc.) : " rignic

rigip=$(/sbin/ifconfig $rignic| sed -n 's/.*inet *addr:\([0-9\.]*\).*/\1/p')

echo;
echo "#################################################################################################################"
echo;
echo "The IP address on this rig's NIC is probably $rigip.  If that's wrong, ctrl-c and edit this script."
echo;
echo "#################################################################################################################"
echo;
