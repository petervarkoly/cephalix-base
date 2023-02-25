#!/bin/bash
# Copyright 2022 Peter Varkoly <pvarkoly@cephalix.eu> Nuremberg

id=$1

IP=$( /usr/sbin/crx_api_text.sh GET institutes/$id/ipVPN )
if [ "$IP" ]; then
        grep -q $IP /usr/share/cephalix/templates/bad-server &> /dev/null && continue
        ping -W 2 -c 1 $IP
        if [ $? = 0 ]; then
		if [ "$( ssh $IP test -e /usr/share/cranix/tools/cephalix-client-check || echo NO )" ]; then
			scp /usr/share/cranix/tools/cephalix-client-check $IP:/usr/share/cranix/tools/cephalix-client-check
		fi
		if [ "$( ssh $IP test -e /usr/sbin/crx_system_status.sh || echo NO )" ]; then
			scp /usr/sbin/crx_system_status.sh  $IP:/usr/sbin/crx_system_status.sh
		fi
                ssh $IP  /usr/sbin/crx_system_status.sh > /tmp/institute-status-$id.json
                /usr/sbin/crx_api_post_file.sh institutes/$id/status /tmp/institute-status-$id.json
        fi
fi

