#!/bin/bash

DATE=$( /usr/share/cranix/tools/crx_date.sh )
BACKUP="/backup/${DATE}/"

for i in $( /root/bin/crx_get_schools )
do
    mkdir -p $BACKUP/$i
    /root/bin/backup-school.sh $BACKUP $i &
    sleep 5
done

