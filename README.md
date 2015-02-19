# openstack
Add cinder to other nodes

in nova.sh
# tracking ping - run openstack_disable_tracking.sh to disable
if [ ! -f ./trackrc ]; then
	curl -s "https://www.stackmonkey.com/api/v1/track?message=OpenStack%20nova%20controller%20script%20run." > /dev/null
fi

nova image-list

ask network settings in nova.conf

Modify the value of CACHES['default']['LOCATION'] in /etc/openstack-dashboard/local_settings.py to match the ones set in /etc/memcached.conf.  ------- horizon