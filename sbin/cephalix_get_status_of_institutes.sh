#!/bin/bash
# Copyright 2022 Peter Varkoly <pvarkoly@cephalix.eu> Nuremberg
PIDDIR=/run/get_status_of_institutes
LOGDIR=/var/log/get_status_of_institute
mkdir -p ${PIDDIR} ${LOGDIR}
for id in $( echo "SELECT id from CephalixInstitutes where not deleted='Y' " | /usr/bin/mysql  CRX )
do
        /sbin/startproc -l ${LOGDIR}/${id}.log -p ${PIDDIR}/${id}.pid \
                /usr/share/cephalix/tools/get_status_of_institute.sh ${id}
        sleep 1
done
