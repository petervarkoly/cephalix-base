#!/bin/bash

oldRegcode=$1
newRegcode=$2
if [ -z "$1" -o -z "$2" ]; then
	echo "usage $@ oldRegcode newRegcode"
	exit 1
fi
. /etc/sysconfig/cranix


passwd=$( grep de.cranix.dao.User.Register.Password= /opt/cranix-java/conf/cranix-api.properties | sed 's/de.cranix.dao.User.Register.Password=//' )

ip=$( host ${oldRegcode}.cephalix.eu | gawk '{ print $4 }' )
if [ ${oldRegcode} != "found:" ]; then
	samba-tool dns delete localhost $CRANIX_DOMAIN $oldRegcode  A $ip -U register%"$passwd"
	samba-tool dns add    localhost $CRANIX_DOMAIN $newRegcode  A $ip -U register%"$passwd"
fi

OLD_USER=${oldRegcode:0:9}
REPO_USER=${newRegcode:0:9}
REPO_PASSWORD=${newRegcode:10:9}

for i in /etc/apache2/vhosts.d/*.htpasswd
do
	IS=$( grep $OLD_USER $i )
	if [ "${IS}" ]; then
		sed -i /$OLD_USER/d $i
	        htpasswd -b $i ${REPO_USER} ${REPO_PASSWORD}
		MODIFIED="true"
	fi
done
if [ -z "${MODIFIED}" ]; then
	htpasswd -b /etc/apache2/vhosts.d/crx.htpasswd ${REPO_USER} ${REPO_PASSWORD}
fi
systemctl restart apache

