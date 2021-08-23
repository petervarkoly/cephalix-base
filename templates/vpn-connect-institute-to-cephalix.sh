#!/bin/bash

mkdir -p /etc/openvpn/CEPHALIX
zypper -n install openvpn
cat <<EOF >> /root/.ssh/authorized_keys
REPLACE-SSHKEY
EOF

cat <<EOF > /etc/openvpn/CEPHALIX/vpncacert.pem
REPLACE-CA-CERT
EOF

cat <<EOF > /etc/openvpn/CEPHALIX/vpncert.pem
REPLACE-VPN-CERT
EOF

cat <<EOF > /etc/openvpn/CEPHALIX/vpnkey.pem
REPLACE-VPN-KEY
EOF
chmod 640 /etc/openvpn/CEPHALIX/vpnkey.pem

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
ca   /etc/openvpn/CEPHALIX/vpncacert.pem
cert /etc/openvpn/CEPHALIX/vpncert.pem
key  /etc/openvpn/CEPHALIX/vpnkey.pem
proto udp
remote ###CEPHALIX### 1194
nobind
EOF

#Allow Cephalix all access
echo '###ZADMIN### zadmin' >> /etc/hosts
if [ -e /usr/bin/firewall-cmd ]
then
	firewall-cmd --zone=trusted  --add-interface=tun0 --permanent
else
	. /etc/sysconfig/SuSEfirewall2
	if [ "$FW_TRUSTED_NETS" = "${FW_TRUSTED_NETS/zadmin}" ];
	then
		sed -i "s/^FW_TRUSTED_NETS=.*/FW_TRUSTED_NETS=\"zadmin ###CEPHALIX### $FW_TRUSTED_NETS\"/" /etc/sysconfig/SuSEfirewall2
	fi
	SuSEfirewall2
fi

systemctl start   openvpn@CEPHALIX
systemctl enable  openvpn@CEPHALIX

