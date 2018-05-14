#!/bin/bash

DATE=$( /usr/share/oss/tools/oss_date.sh )
BACKUP="/backup/${DATE}/"

for i in $( /root/bin/oss_get_schools )
do
    mkdir -p $BACKUP/$i
    /root/bin/backup-school.sh $BACKUP $i &
    sleep 5
done

