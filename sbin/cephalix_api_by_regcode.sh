#!/bin/bash
# Copyright 2019 Peter Varkoly <peter@varkoly.de>

REGCODE=$1
METHOD=$2
CALL=$3
DATA=$4
if [ "$DATA" ]; then
   DATAFILE=$( mktemp /tmp/CRX_APIXXXXXXXXXXX )
   echo "$DATA" > $DATAFILE
   DATA=" -d @${DATAFILE}"
fi

TOKEN=$( /usr/sbin/crx_api_text.sh GET institutes/byRegcode/${REGCODE}/token )
IP=$( /usr/sbin/crx_api_text.sh GET institutes/byRegcode/${REGCODE}/ipVPN )
curl -s -X $METHOD --header 'Content-Type: application/json' $DATA --header 'Authorization: Bearer '${TOKEN} "http://${IP}/api/$CALL"
if [ "${DATAFILE}" ]; then
    rm ${DATAFILE}
fi
