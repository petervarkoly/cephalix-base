#!/bin/bash
# Copyright 2019 Peter Varkoly <peter@varkoly.de>

REGCODE=$1
METHOD=$2
CALL=$3
DATA=$4
if [ "$DATA" ]; then
   DATAFILE=$( mktemp /tmp/OSS_APIXXXXXXXXXXX )
   echo "$DATA" > $DATAFILE
   DATA=" -d @${DATAFILE}"
fi

TOKEN=$( oss_api_text.sh GET institutes/byRegcode/${REGCODE}/token )
IP=$( oss_api_text.sh GET institutes/byRegcode/${REGCODE}/ipVPN )
curl -s -X $METHOD --header 'Content-Type: application/json' $DATA --header 'Authorization: Bearer '${TOKEN} "http://${IP}/api/$CALL"
if [ "${DATAFILE}" ]; then
    rm ${DATAFILE}
fi
