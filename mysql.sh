#!/bin/bash

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "You need to be 'root' dude." 1>&2
   exit 1
fi

. ./setuprc

# throw in a few other services we need installed
apt-get install rabbitmq-server memcached python-memcache -y

echo;
echo "##############################################################################################"
echo;
echo "Setting up MySQL now.  You will be prompted to set a MySQL root password by the setup process."
echo;
echo "##############################################################################################"
echo;

apt-get install python-mysqldb mysql-server -y


# make mysql listen on 0.0.0.0
sed -i /^bind-address/s/127.0.0.1/$MY_CONTROLLER_IP/g /etc/mysql/my.cnf

# setup mysql to support utf8 and innodb
echo "
[mysqld]
default-storage-engine = innodb
innodb_file_per_table
collation-server = utf8_general_ci
init-connect = 'SET NAMES utf8'
character-set-server = utf8
" >> /etc/mysql/conf.d/openstack.cnf
	