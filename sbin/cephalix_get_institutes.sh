#!/bin/bash
# (C) 2021 Peter Varkoly <pvarkoly@cephalix.eu>

for id in $( echo "SELECT id from CephalixInstitutes where not deleted='Y' " | /usr/bin/mysql  CRX )
do
        IP=$( /usr/sbin/crx_api_text.sh GET institutes/$id/ipVPN )
	if [ -z "$IP" ]; then
		continue
	fi
	grep -q $IP /usr/share/cephalix/templates/bad-server &> /dev/null && continue
        if [ "$IP" ]; then
                ping -W 2 -c 1 $IP &> /dev/null
                if [ $? = 0 ]; then
                        echo $IP
                fi
        fi
done
