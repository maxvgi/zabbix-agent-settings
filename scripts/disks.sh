#!/bin/sh

disks=`/bin/cat /proc/diskstats | /usr/bin/awk '{print $3}' | /bin/grep -v loop | /usr/bin/sort`

for x in $disks ; do
	if [ "$res" != "" ] ; then
		res=$res','
	fi
	res=$res'{"{#DISK}":"'$x'"}'
done
echo '{"data":['$res']}'
