#!/bin/bash

gencert() {
    # Try to get a valid hostname...
    CN=$NAME.$DOMAIN
    if [ $NAME = "CA" ]; then
        CN="OSS_Default_CA";
    fi
    if [ "$SHORT" ]; then
       CN=$NAME
    fi
    email=admin@$DOMAIN

    openssl=/usr/bin/openssl

NOW=$(date +%s)
DAYS=$((1842897419-NOW))
DAYS=$((DAYS/86400-1))

cat<<EOF > $CPATH/openssl.cfg
[ ca ]
default_ca      = CA_default

[ CA_default ]

dir             = $CPATH
certs           = \$dir/certs
crl_dir         = \$dir/crl
database        = \$dir/index.txt
new_certs_dir   = \$dir/newcerts

certificate     = \$dir/cacert.pem
serial          = \$dir/serial
crl             = \$dir/crl.pem
private_key     = \$dir/private/cakey.pem
RANDFILE        = \$dir/private/.rand

x509_extensions = usr_cert

default_days    = $DAYS
default_md      = sha256
policy          = policy_anything

[ policy_anything ]

countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional


[ req ]
default_bits           = 2048
default_keyfile        = privkey.pem
distinguished_name     = req_distinguished_name
attributes             = req_attributes
x509_extensions        = v3_ca
prompt                 = no
output_password        = mypass

[ req_distinguished_name ]
C                      = $C
ST                     = $ST
L                      = $L
O                      = $O
OU                     = "CEPHALIX"
CN                     = $CN
emailAddress           = $email
subjectAltName         = DNS:${NAME}

[ req_attributes ]
challengePassword= REPLACE-PW challenge password

[ server_cert ]

basicConstraints=CA:FALSE
nsCertType = server
nsComment = $comment
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer:always
subjectAltName=email:copy
issuerAltName=issuer:copy


[ client_cert ]

basicConstraints=CA:FALSE
nsCertType = server
nsComment = $comment
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer:always
subjectAltName=email:copy
issuerAltName=issuer:copy

[ v3_ca ]

subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer:always
basicConstraints= CA:true
keyUsage= cRLSign, keyCertSign
nsCertType= sslCA, emailCA
subjectAltName=email:copy
issuerAltName=issuer:copy

[ usr_cert ]

basicConstraints=CA:FALSE
nsComment= $comment
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer:always

EOF
    if [ $NAME = "CA" ]; then
            sed -i '/subjectAltName         = DNS/d' $CPATH/openssl.cfg
            echo "creating CA request/certificate..."
            $openssl req -days 3601 -config $CPATH/openssl.cfg -new -x509 -nodes \
                -keyout $CPATH/private/cakey.pem -out $CPATH/cacert.pem || {
                    echo "error creating CA request/certificate"
                    return
                }
            chmod 755 $CPATH
            chmod 755 $CPATH/certs
            chmod 644 $CPATH/cacert.pem
    else
        if [ "$SHORT" ]; then
	    sed -i '/subjectAltName         = DNS/d' $CPATH/openssl.cfg
	fi
        echo "creating certificate request..."
        $openssl req -config $CPATH/openssl.cfg -new -nodes -keyout \
            $CPATH/certs/${NAME}.${DOMAIN}.key.pem -out $CPATH/certs/${NAME}.${DOMAIN}.req.pem || {
                echo "error creating certificate request"
                return
            }
    
        echo "signing server certificate..."
        $openssl ca -config $CPATH/openssl.cfg -notext -batch \
            -out $CPATH/certs/${NAME}.${DOMAIN}.cert.pem \
            -infiles $CPATH/certs/${NAME}.${DOMAIN}.req.pem || {
                echo "error signing server certificate"
                return
            }
    fi
}

usage() {
 echo
 printf "Usage: %s: [-csh] -N <Hostname|CA> -D <Domainname> -O <Organisation> [ -P <Path to CA_MGM> -C <Country> -S <State> -L <Location> ]\n" $0
 echo 
}
#Set the defaults
CLEAN=""
NAME=
DOMAIN=
comment="OSS Server Certificate"
C="DE"
ST="Bavaria"
L="Nurember"
U="OSS Server"
O=
SHORT=


#Getting the parameters
while getopts cshN:D:C:S:L:O:P: o
do
    case $o in
	c)   CLEAN=1;;
	s)   SHORT=1;;
	N)   NAME="$OPTARG";;
	D)   DOMAIN="$OPTARG";;
	C)   C="$OPTARG";;
	S)   ST="$OPTARG";;
	L)   L="$OPTARG";;
	O)   O="$OPTARG";;
	P)   P="$OPTARG";;
	?)   usage
	     exit 2;; 
    esac
done

if [ -z "$NAME" -o -z "$DOMAIN" -o -z "$ST" -o -z "$L" -o -z "O" ]; then
    usage
    exit 2
fi 

if [ -z "$P" ]
then
	P=$( pwd )
else
	cd $P
fi

CPATH="$P/CA_MGM"
#Let us do it
if [ "$CLEAN" ]; then
    rm -rf $CPATH/
fi

umask 077
if [ ! -d $CPATH/private ]; then
    mkdir -p $CPATH/private
    mkdir -p $CPATH/certs
    mkdir -p $CPATH/newcerts
    echo "01" > $CPATH/serial
    touch $CPATH/index.txt
fi 

gencert $NAME

