#!/bin/bash
# Copyright Peter Varkoly <peter@varkoly.de>
REGCODE=$1
CALL=$2
DATA=$3
DATA=" -F file=@${DATA}"
TOKEN=$( oss_api_text.sh GET institutes/byRegcode/${REGCODE}/token )
IP=$( oss_api_text.sh GET institutes/byRegcode/${REGCODE}/ipVPN )
TOKEN=$( grep de.openschoolserver.api.auth.localhost= /opt/oss-java/conf/oss-api.properties | sed 's/de.openschoolserver.api.auth.localhost=//' )
curl -s -X POST --header 'Content-Type: multipart/form-data' $DATA --header 'Authorization: Bearer '${TOKEN} "http://localhost:9080/api/$CALL"


