#!/bin/sh

if [ $DNS_SERVER ];then
	echo "nameserver $DNS_SERVER" > /etc/resolv.conf
fi

tail -f /dev/null