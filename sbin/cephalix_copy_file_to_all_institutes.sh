#!/bin/bash -x
# Copyright 2021 Peter Varkoly <pvarkoly@cephalix.eu>

SOURCE=$1
DIRECTION=$1
if [ "$2" ]; then
	DIRECTION=$2
fi
if [ -z "$1" ]; then
       echo "You have to provide a file to copy"
       exit 1
fi

for IP in $( /usr/sbin/cephalix_get_institutes.sh  )
do
	DIR=$( dirname "${DIRECTION}" )
	ssh $IP mkdir -p "${DIR}"
	scp "${SOURCE}" $IP:"${DIRECTION}"
done

