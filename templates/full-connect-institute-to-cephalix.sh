#!/bin/bash

mkdir -p /etc/ssl/servercerts/certs/
mkdir -p /etc/openvpn/CEPHALIX/
zypper -n install openvpn cephalix-client
cat <<EOF >> /root/.ssh/authorized_keys
REPLACE-SSHKEY
EOF

cat <<EOF > /etc/ssl/servercerts/cacert.pem
REPLACE-CA-CERT
EOF

cat <<EOF > /etc/openvpn/CEPHALIX/cacert.pem
REPLACE-CA-CERT
EOF

cat <<EOF > /etc/openvpn/CEPHALIX/vpncert.pem
REPLACE-VPN-CERT
EOF

cat <<EOF > /etc/openvpn/CEPHALIX/vpnkey.pem
REPLACE-VPN-KEY
EOF
chmod 640 /etc/openvpn/CEPHALIX/vpnkey.pem

cat <<EOF > /etc/ssl/servercerts/certs/admin.###domain###.cert.pem
REPLACE-ADMIN-CERT
EOF

cat <<EOF > /etc/ssl/servercerts/certs/admin.###domain###.key.pem
REPLACE-ADMIN-KEY
EOF
chmod 640 /etc/ssl/servercerts/certs/admin.###domain###.key.pem

cat <<EOF > /etc/ssl/servercerts/certs/cranix.###domain###.cert.pem
REPLACE-SCHOOL-CERT
EOF

cat <<EOF >> /etc/ssl/servercerts/certs/cranix.###domain###.key.pem
REPLACE-SCHOOL-KEY
EOF

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
ca   /etc/openvpn/CEPHALIX/cacert.pem
cert /etc/openvpn/CEPHALIX/vpncert.pem
key  /etc/openvpn/CEPHALIX/vpnkey.pem
proto udp
remote ###CEPHALIX### 1194
nobind
EOF

#Configure Cephalix Access for Apache2
sed -i 's/connectip/###ipVPN###/g' /etc/apache2/vhosts.d/cephalix_include.conf
sed -i 's/zadminip/###ZADMIN###/g' /etc/apache2/vhosts.d/cephalix_include.conf

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
systemctl restart apache
samba-tool user setpassword cephalix --newpassword='###cephalixPW###'

