#!/bin/bash

for id in $( echo "SELECT id from CephalixInstitutes where not deleted='Y' " | /usr/bin/mysql  CRX )
do
        IP=$( /usr/sbin/crx_api_text.sh GET institutes/$id/ipVPN )
        if [ "$IP" ]; then
		grep -q $IP /usr/share/cephalix/templates/bad-server &> /dev/null && continue
                ping -W 2 -c 1 $IP
                if [ $? = 0 ]; then
                        ssh $IP  /usr/sbin/crx_system_status.sh > /tmp/institute-status-$id.json
                        /usr/sbin/crx_api_post_file.sh institutes/$id/status /tmp/institute-status-$id.json
                fi
        fi
done

