#!/usr/bin/python3
import json
import socket
import os
import sys
from ipaddress import *
#Define some defaults
# The file with the default values.
DEFAULTS_FILE = "/usr/share/cephalix/templates/Defaults.ini"
# Attributes which must not be changed
READONLY = ( "CEPHALIX", "CEPHALIX_PATH", "CEPHALIX_DOMAIN", "CCODE", "LANGUAGE", "NTP", "ZADMIN" )

#Read datas from stdin
institute=json.loads(sys.stdin.read())
#Read the defaults from the config file
defaults=json.loads(open(DEFAULTS_FILE,"r").read())

CEPHALIX_PATH = defaults['CEPHALIX_PATH']

ident=institute['uuid']

#Set the read only values
for key in READONLY:
    institute[key] = defaults[key]

# Handle Certificates
cmd = CEPHALIX_PATH + '/create_server_certificates.sh -P ' + CEPHALIX_PATH + ' -O "' + institute['name'] + '"'
if 'state' in institute:
    cmd += ' -S "' + institute['state'] + '"'
if 'locality' in  institute:
    cmd += ' -L "' + institute['locality'] + '"'
if not os.path.isfile(CEPHALIX_PATH+'/CA_MGM/certs/' + ident +'.' + institute['CEPHALIX_DOMAIN'] + '.key.pem' ):
    command = cmd + ' -D ' + institute['CEPHALIX_DOMAIN'] + ' -N "' + ident + '" -s'
    os.system(command)
if not os.path.isfile(CEPHALIX_PATH+'/CA_MGM/certs/admin.' + institute['domain'] + '.key.pem' ):
    command = cmd + ' -D ' + institute['domain'] + ' -N admin'
    os.system(command)
if not os.path.isfile(CEPHALIX_PATH+'/CA_MGM/certs/cranix.' + institute['domain'] + '.key.pem' ):
    command = cmd + ' -D ' + institute['domain'] + ' -N cranix'
    os.system(command)
if not os.path.isfile(CEPHALIX_PATH+'/CA_MGM/certs/proxy.' + institute['domain'] + '.key.pem' ):
    command = cmd + ' -D ' + institute['domain'] + ' -N proxy'
    os.system(command)
