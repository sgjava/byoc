#!/bin/bash
#
# Quick and dirty networking restart if ping fails. Typically you can use your
# gateway IP for testing. Script coded to go in /opt/scripts dir.
#
# Add "*/5  *  *   *   *  bash" (without quotes) to /opt/scripts/checknet.sh
# to "sudo crontab -e" for network check every 5 minutes.

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

x=`ping -c1 192.168.1.1 2>&1 | grep 'nreachable\|100\%'`
if [ ! "$x" = "" ]; then
	echo "$(date) ping failed, reatarting networking" >>/opt/scripts/checknet.log
        service networking restart >>/opt/scripts/checknet.log 2>&1
fi

