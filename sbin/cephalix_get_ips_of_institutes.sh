for id in $( echo "SELECT id from CephalixInstitutes where not deleted='Y' " | /usr/bin/mysql  CRX )
do
        IP=$( /usr/sbin/crx_api_text.sh GET institutes/$id/ipVPN )
        if [ "$IP" -a ${IP:0:7} != '{"code"' ]; then
                echo $IP
        fi
done
