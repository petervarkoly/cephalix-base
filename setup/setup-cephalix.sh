mkdir /root/.ssh
if [ ! -e /root/.ssh/id_dsa ]; then
	/usr/bin/ssh-keygen -t dsa -N "" -f /root/.ssh/id_dsa
fi
echo  -n "   CEPHALIX domain name: "; read DOMAIN
echo  -n "Country code (DE,EN ..): "; read C
echo  -n "       State/Bundesland: "; read STATE
echo  -n "             City/Stadt: "; read locality
echo  -n "The name of your organisation: "; read O
echo     "The IP Address of CEPHALIX server from which the servers will be connected.";
echo  -n "If the servers will be connected  via VPN this is  the VPN-tunnel  address: "; read zadmin
echo     "The official IP Addres or DNS name of the CEPHALIX."
echo  -n "This is only  required for the VPN connections.: "; read CEPHALIX
echo  -n "The VPN IP-Adress of the first server: "; read ipVPN
echo  -n "Standard IP address in transport network for the servers: "; read ipTrNet
echo  -n "Standard netmask  in transport network for the servers: "; read nmTrNet
echo  -n "Standard gateway in transport network for the servers: "; read gwTrNet
echo     "The internal network of the first server. Several IP-Adresses"
echo  -n "of the server will be calculated based on this: X.X.X.2, X.X.X.3:"; read network
echo  -n "The netmask of the internal network (255.255.0.0):"; read netmask

ipAdmin=$( echo $NET | gawk -F "." '{ print $1 "." $2 "." $3 ".2" }' )
ipMail=$( echo $NET | gawk -F "." '{ print $1 "." $2 "." $3 ".3" }' )
ipPrint=$( echo $NET | gawk -F "." '{ print $1 "." $2 "." $3 ".4" }' )
ipProxy=$( echo $NET | gawk -F "." '{ print $1 "." $2 "." $3 ".5" }' )
ipBackup=$( echo $NET | gawk -F "." '{ print $1 "." $2 "." $3 ".6" }' )
anonDhcp=$( echo $NET | gawk -F "." '{ print $1 "." $2 "." $3+1 ".0 " $1 "." $2 "." $3+1 ".15" }' )
firstRoom=$( echo $NET | gawk -F "." '{ print $1 "." $2 "." $3+2 ".0" }' )

cat<<EOF > /tmp/initial-school
{
  "id": 1,
  "uuid": "template",
  "adminPW": "",
  "anonDhcp": "$anonDhcp",
  "cephalixPW": "",
  "domain": "",
  "firstRoom": "$firstRoom",
  "gwTrNet": "$gwTrNet",
  "ipAdmin": "$ipAdmin",
  "ipBackup": "$ipBackup",
  "ipMail": "$ipMail",
  "ipPrint": "$ipPrint",
  "ipProxy": "$ipProxy",
  "ipTrNet": "$ipTrNet",
  "ipVPN": "$ipVPN",
  "locality": "$locality",
  "name": "Institute Template",
  "netmask": "$netmask",
  "network": "$network",
  "nmServerNet": "255.255.255.0",
  "nmTrNet": "$nmTrNet",
  "type": "string",
  "regCode": "string"
}
EOF

cat<<EOF > /usr/share/cephalix/templates/Defaults.ini
CEPHALIX_PATH=/root/CEPHALIX/
CEPHALIX_DOMAIN=$DOMAIN
VPN_IP=10.255.0.8
REPLACE-zadmin=$zadmin
REPLACE-L=$L
REPLACE-STATE=$STATE
REPLACE-LANGUAGE=$C
REPLACE-CCODE"=$C
REPLACE-sn=
REPLACE-CN=
REPLACE-type=
REPLACE-dom=
REPLACE-PW=
REPLACE-WORKGROUP=
REPLACE-CEPHALIX=$CEPHALIX
REPLACE-TRIP=$trip
REPLACE-TRNM=$trnm
REPLACE-GW=$trgw
REPLACE-NET=$NET
REPLACE-NM=$NM
REPLACE-NET-GW=$admin
REPLACE-admin=$admin
REPLACE-mail=$mail
REPLACE-print=$print
REPLACE-proxy=$proxy
REPLACE-backup=$backup
REPLACE-ntp=ptbtime1.ptb.de
REPLACE-SERVER_NET_NM=24
REPLACE-CEPHALIX=$CEPHALIX
REPLACE-LANGUAGE=$C
REPLACE-CCODE=$C
REPLACE-STATE=$STATE
EOF

TOKEN=$( grep de.openschoolserver.api.auth.localhost= /opt/oss-java/conf/oss-api.properties | sed 's/de.openschoolserver.api.auth.localhost=//' )
curl -s -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d @/tmp/initial-school --header 'Authorization: Bearer '${TOKEN} "http://localhost:9080/api/institutes/add"

mkdir -p /root/CEPHALIX/{CA_MGM,configs}
cp /usr/share/cephalix/setup/create_server_certificates.sh /root/CEPHALIX/
chmod 750 /root/CEPHALIX/create_server_certificates.sh

/root/CEPHALIX/create_server_certificates.sh -N "CA" -D "$DOMAIN" -C $C -S "$STATE" -L "$locality" -O "CEPHALIX of $O"
/root/CEPHALIX/create_server_certificates.sh -N "cephalix" -D "$DOMAIN" -C $C -S "$STATE" -L "$locality" -O "CEPHALIX of $O"

