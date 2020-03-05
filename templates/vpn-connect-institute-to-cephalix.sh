#!/bin/bash

mkdir -p /etc/ssl/servercerts/certs/
zypper -n install openvpn
cat <<EOF >> /root/.ssh/autoirzed_keys
REPLACE-SSHKEY
EOF

cat <<EOF > /etc/ssl/servercerts/vpncacert.pem
REPLACE-CA-CERT
EOF

cat <<EOF > /etc/ssl/servercerts/vpncert.pem
REPLACE-VPN-CERT
EOF

cat <<EOF > /etc/ssl/servercerts/vpnkey.pem
REPLACE-VPN-KEY
EOF
chmod 640 /etc/ssl/servercerts/vpnkey.pem

cat <<EOF > /etc/openvpn/CEPHALIX.conf
client
dev tun
keepalive 10 30
persist-key
persist-tun
persist-local-ip
persist-remote-ip
comp-lzo
verb 4
mute 20
mute-replay-warnings
ca   /etc/ssl/servercerts/vpncacert.pem
cert /etc/ssl/servercerts/vpncert.pem
key  /etc/ssl/servercerts/vpnkey.pem
proto udp
remote ###CEPHALIX### 1194
nobind
EOF

#Allow Cephalix all access
echo '###ZADMIN### zadmin' >> /etc/hosts
. /etc/sysconfig/SuSEfirewall2
if [ "$FW_TRUSTED_NETS" = "${FW_TRUSTED_NETS/zadmin}" ];
then
	sed -i "s/^FW_TRUSTED_NETS=.*/FW_TRUSTED_NETS=\"zadmin ###CEPHALIX### $FW_TRUSTED_NETS\"/" /etc/sysconfig/SuSEfirewall2
fi
SuSEfirewall2

systemctl start   openvpn@CEPHALIX
systemctl enable  openvpn@CEPHALIX

