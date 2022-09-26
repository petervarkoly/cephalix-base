#!/bin/bash
# Copyright 2021 Peter Varkoly <pvarkoly@cephalix.eu>
# Copyright Peter Varkoly <peter@varkoly.de>
UUID=$1
CALL=$2
DATA=$3
DATA=" -F file=@${DATA}"
TOKEN=$( /usr/sbin/crx_api_text.sh GET institutes/byUuid/${UUID}/token )
IP=$( /usr/sbin/crx_api_text.sh GET institutes/byUuid/${UUID}/ipVPN )
TOKEN=$( grep de.cranix.api.auth.localhost= /opt/cranix-java/conf/cranix-api.properties | sed 's/de.cranix.api.auth.localhost=//' )
curl -s -X POST --header 'Content-Type: multipart/form-data' $DATA --header 'Authorization: Bearer '${TOKEN} "http://localhost:9080/api/$CALL"


