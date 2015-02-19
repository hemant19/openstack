#!/bin/bash

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
   exit 1
fi

apt-get update -y
apt-get install curl -y
apt-get install python-pip -y

echo "#################################################################################################

System updated.  Now run './openstack_setup.sh' to run the system setup.

#################################################################################################
"
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

# controller install?
echo;
read -p "Is this the controller node? " -n 2 -r

if [[ $REPLY =~ ^[Yy]$ ]]
then
	# prompt for a few things we'll need for mysql
	echo;
	read -p "Enter a password to be used for the OpenStack services to talk to MySQL: " password
	echo;
	read -p "Enter the email address for service accounts: " email
	echo;
	read -p "Enter a short name to use for your default region: " region
	echo;

	# making a unique token for this install
	token=`cat /dev/urandom | head -c2048 | md5sum | cut -d' ' -f1`

# do not unindent this section!
# some of these envrionment variables are set again in stackrc later
cat > setuprc <<EOF
# set up env variables for install
export OS_TENANT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=$password
export OS_AUTH_URL="http://$rigip:5000/v2.0/"
export OS_REGION_NAME=$region
export MY_CONTROLLER_IP=$rigip
export MY_CONTROLLER_NIC=$rignic
export MY_TENANT_NAME=service
export MY_EMAIL=$email
export MY_PASSWORD=$password
export MY_TOKEN=$token
export MY_REGION=$region
EOF

	# single or multi?
	read -p "Is this a multi node install? " -n 2 -r
	if [[ $REPLY =~ ^[Yy]$ ]]
	then
		echo;
		echo "Please use the same setuprc file for other nodes..."
		echo;
	fi
	
# again, don't unindent!
# tack on an indicator we're the controller
cat >> setuprc <<EOF
export MY_CONTROLLER=1
EOF

else
	echo;
	read -p "Please provide the setuprc file from controller install... then press Y :  " -n 2 -r

	

# don't unindent!
# tack on the IP address for the compute rig
cat >> setuprc <<EOF
export MY_COMPUTE_IP=$rigip
export MY_COMPUTE_NIC=$rignic
EOF

	echo;
	echo "##########################################################################################"
	echo;
	echo "Setup configuration complete.  Continue the setup by doing a './cinder.sh'."
	echo;
	echo "##########################################################################################"
	echo;
	exit
fi


echo;
echo "##########################################################################################"
echo;
echo "Setup configuration complete.  Continue the setup by doing a './mysql.sh'."
echo;
echo "##########################################################################################"
echo;
