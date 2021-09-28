#!/bin/bash
# Copyright 2021 Peter Varkoly <pvarkoly@cephalix.eu>

COMMAND=$1
if [ -z "$1" ]; then
       echo "You have to provide a command to execute"
       exit 1
fi

for IP in $( /usr/sbin/cephalix_get_institutes.sh  )
do
        ssh $IP $COMMAND
done
