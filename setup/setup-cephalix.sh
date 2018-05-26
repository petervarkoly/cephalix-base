mkdir /root/.ssh
if [ ! -e /root/.ssh/id_dsa ]; then
	/usr/bin/ssh-keygen -t dsa -N "" -f /root/.ssh/id_dsa
fi
echo  -n "            Domain name:"; read domain
echo  -n "Country code (DE,EN ..):"; read C
echo  -n "      State//Bundesland:"; read STATE
echo  -n "             City/Stadt:"; read L

cat<<EOF > /usr/share/oss/templates/CEPHALIX/Defaults.ini
[Defaults]
CEPHALIX_PATH=/root/CEPHALIX/
CEPHALIX_DOMAIN=$domain
VPN_IP=10.255.0.8
REPLACE-zadmin=10.255.0.1
REPLACE-L=$L
REPLACE-STATE=$STATE
REPLACE-LANGUAGE=$C
REPLACE-CCODE"=$C
REPLACE-sn=
REPLACE-CN=
REPLACE-type=
REPLACE-dom=
REPLACE-ldap=
REPLACE-PW=
REPLACE-WORKGROUP=
REPLACE-CEPHALIX=188.40.130.99
REPLACE-TRIP=192.168.1.2
REPLACE-TRNM=255.255.255.0
REPLACE-GW=192.168.1.1
REPLACE-NET=10.9.0.0
REPLACE-NM=255.255.0.0
REPLACE-NET-GW=10.9.0.2
REPLACE-admin=10.9.0.2
REPLACE-mail=10.9.0.3
REPLACE-print=10.9.0.4
REPLACE-proxy=10.9.0.5
REPLACE-backup=10.9.0.6
REPLACE-ntp=ptbtime1.ptb.de
REPLACE-SERVER_NET_NM=24
REPLACE-anon=10.9.1.0 10.9.1.31
REPLACE-room=10.9.2.0
EOF

/root/CEPHALIX/create_server_certificates.sh -N "CA" -D "$vdomain" -C $C -S "$STATE" -L "$L" -O "Cephalix for the Schools of $L"
/root/CEPHALIX/create_server_certificates.sh -N "cephalix" -D "$vdomain" -C $C -S "$STATE" -L "$L" -O "Cephalix for the Schools of $L"

