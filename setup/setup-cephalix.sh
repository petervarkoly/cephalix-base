mkdir /root/.ssh
if [ ! -e /root/.ssh/id_dsa ]; then
	/usr/bin/ssh-keygen -t dsa -N "" -f /root/.ssh/id_dsa
fi
echo  -n "   CEPHALIX domain name: "; read domain
echo  -n "Country code (DE,EN ..): "; read C
echo  -n "      State//Bundesland: "; read STATE
echo  -n "             City/Stadt: "; read L
echo  -n "The name of your organisation: "; read O
echo     "The IP Address of CEPHALIX server from which the servers will be connected: ";
echo  -n "If the servers will be connected  via VPN this is  the VPN-tunnel  address: "; read zadmin
echo     "The official IP Addres or DNS name of the CEPHALIX. "
echo  -n "This is only  required for the VPN connections.: "; read CEPHALIX
echo  -n "Standard IP address in transport network for the servers: "; read trip
echo  -n "Standard netmask  in transport network for the servers: "; read trnm
echo  -n "Standard gateway in transport network for the servers: "; read trgw
echo     "The internal network of the first server. Several IP-Adresses"
echo  -n "of the server will be calculated based on this: X.X.X.2, X.X.X.3:"; read NET
echo  -n "The netmask of the internal network (255.255.0.0):"; read NM

mkdir -p /usr/share/oss/templates/CEPHALIX/

admin=$( echo $NET | gawk -F "." '{ print $1 "." $2 "." $3 ".2" }' )
mail=$( echo $NET | gawk -F "." '{ print $1 "." $2 "." $3 ".3" }' )
print=$( echo $NET | gawk -F "." '{ print $1 "." $2 "." $3 ".4" }' )
proxy=$( echo $NET | gawk -F "." '{ print $1 "." $2 "." $3 ".5" }' )
backup=$( echo $NET | gawk -F "." '{ print $1 "." $2 "." $3 ".6" }' )
anon=$( echo $NET | gawk -F "." '{ print $1 "." $2 "." $3+1 ".0 " $1 "." $2 "." $3+1 ".15" }' )
room=$( echo $NET | gawk -F "." '{ print $1 "." $2 "." $3+2 ".0" }' )

cat<<EOF > /usr/share/oss/templates/CEPHALIX/Defaults.ini
[Defaults]
CEPHALIX_PATH=/root/CEPHALIX/
CEPHALIX_DOMAIN=$domain
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
REPLACE-TRNM=$trn
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
REPLACE-anon=$anon
REPLACE-room=$room
EOF

/root/CEPHALIX/create_server_certificates.sh -N "CA" -D "$domain" -C $C -S "$STATE" -L "$L" -O "CEPHALIX of $O"
/root/CEPHALIX/create_server_certificates.sh -N "cephalix" -D "$domain" -C $C -S "$STATE" -L "$L" -O "CEPHALIX of $O"

