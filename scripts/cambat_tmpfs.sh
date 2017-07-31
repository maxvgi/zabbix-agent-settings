#!/bin/bash

if [[ "$1" == "list" ]] ; then
	disks=`/bin/df | grep tmpfs | grep cambat | awk '{print $6;}'`
	for x in $disks ; do
		if [ "$res" != "" ] ; then
			res=$res','
		fi
		res=$res'{"{#DISK}":"'$x'"}'
	done
	echo '{"data":['$res']}'
elif [[ "$1" != "" ]] ; then
	/bin/df $1 | tail -n 1 | awk '{print $3;}'
else
	echo Wrong parameters
	exit 1
fi




