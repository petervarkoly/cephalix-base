#!/usr/bin/python
import json
import socket
import os
import sys
from netaddr import *
#Define some defaults
# The file with the default values.
DEFAULTS_FILE = "/usr/share/cephalix/templates/Defaults.ini"
# Attributes must be cleaned befor writing into defaults
TO_CLEAN = ( "uuid", "name", "type", "domain", "adminPW" )
# Attributes which must not be changed
READONLY = ( "CEPHALIX", "CEPHALIX_PATH", "CEPHALIX_DOMAIN", "CCODE", "LANGUAGE", "NTP", "ZADMIN" )
# Attributes related to ssl
SSL = ( "REPLACE-SSHKEY",
        "REPLACE-CA-CERT",
        "REPLACE-VPN-CERT",
        "REPLACE-VPN-KEY",
        "REPLACE-SERVER-KEY",
        "REPLACE-SERVER-CERT",
        "REPLACE-ADMIN-CERT",
        "REPLACE-ADMIN-KEY",
        "REPLACE-SCHOOL-KEY",
        "REPLACE-SCHOOL-CERT")

#Read datas from stdin
institute=json.loads(sys.stdin.read())
#Read the defaults from the config file
defaults=json.loads(open(DEFAULTS_FILE,"r").read)
SSLVARS = []

CEPHALIX_PATH = defaults['CEPHALIX_PATH']

# The autoyast template file
xml_file  =  "/usr/share/cephalix/templates/autoyast-"+ institute.get("ayTemplate","default") + ".xml"

#Set the read only values
for key in READONLY:
    institute[key] = defaults[key]

save_next     = institute.get("SAVE_NEXT",True)
save_next_vpn = institute.get("SAVE_NEXT_VPN",True)

# create some networks
network = IPNetwork(institute['network'])
network_dhcp   = IPNetwork(institute['anonDhcpNetwork'])
network_server = IPNetwork(institute['serverNetwork'])

# Handle VPN
if institute["ipAdmin"] != institute['ipVPN']:
    vpn_net = IPNetwork("{}/{}".format(institute['ipVPN'],"255.255.255.252"))
    with open("/etc/openvpn/ccd/"+ institute['uuid'],"w") as ccd:
        ccd.write("ifconfig-push {} {}\n".format(IPAddress(vpn_net.first+1),IPAddress(vpn_net.last-1)))
        if institute.get('fullrouting',False):
            ccd.write("iroute {} {}".format(IPAddress(network.first), IPAddress(network.netmask)))
    if defaults['ipVPN'] == institute['ipVPN']:
        default['ipVPN'] = IPAddress(vpn_net.next().first + 1)

# Handle Certificates
if not os.path.isfile(CEPHALIX_PATH+'/CA_MGM/certs/admin.' + institute['domain'] + '.key.pem' ):
    cmd = CEPHALIX_PATH + '/create_server_certificates.sh -P ' + CEPHALIX_PATH + ' -O "' + institute['name'] + '"'
    if 'state' in institute:
        cmd += ' -S "' + institute['state'] + '"'
    if 'locality' in  institute:
        cmd += ' -L "' + institute['locality'] + '"'
    command = cmd + ' -D ' + institute['CEPHALIX_DOMAIN'] + ' -N "' + institute['uuid'] + '" -s'
    os.system(command)
    command = cmd + ' -D ' + institute['domain'] + ' -N admin'
    os.system(command)
    command = cmd + ' -D ' + institute['domain'] + ' -N schoolserver'
    os.system(command)
SSLVARS['REPLACE-SSHKEY']     = open('/root/.ssh/id_rsa.pub','r').read()
SSLVARS['REPLACE-CA-CERT']    = open(CEPHALIX_PATH + 'CA_MGM/cacert.pem','r').read()
SSLVARS['REPLACE-VPN-KEY']    = open(CEPHALIX_PATH + 'CA_MGM/certs/' + institute['uuid'] + '.' + institute['CEPHALIX_DOMAIN'] + '.key.pem','r').read()
SSLVARS['REPLACE-VPN-CERT']   = open(CEPHALIX_PATH + 'CA_MGM/certs/' + institute['uuid'] + '.' + institute['CEPHALIX_DOMAIN'] + '.cert.pem','r').read()
SSLVARS['REPLACE-ADMIN-KEY']  = open(CEPHALIX_PATH + 'CA_MGM/certs/admin.' + institute['domain'] + '.key.pem','r').read()
SSLVARS['REPLACE-ADMIN-CERT'] = open(CEPHALIX_PATH + 'CA_MGM/certs/admin.' + institute['domain'] + '.cert.pem','r').read()
SSLVARS['REPLACE-SCHOOL-KEY'] = open(CEPHALIX_PATH + 'CA_MGM/certs/schoolserver.' + institute['domain'] + '.key.pem','r').read()
SSLVARS['REPLACE-SCHOOL-CERT']= open(CEPHALIX_PATH + 'CA_MGM/certs/schoolserver.' + institute['domain'] + '.cert.pem','r').read()

xml_content = open(xml_file,'r').read()
for key in institute:
    xml_content.replace('###'+key+'###',institute[key])
for key in SSL:
    xml_content.replace(key,SSLVARS[key])
os.system('mkdir -p /srv/www/admin/{configs,isos}"')

#write the xml file
with open('/srv/www/admin/configs/' + institute['uuid'] + '.xml' ,'w') as f:
    f.write(xml_content)

#rewrite the defaults
with open(DEFAULTS_FILE,'w') as f:
    f.write(json.dumps(defaults))

#write apache configuration
with open('/etc/apache2/vhosts.d/admin-ssl/'+institute['uuid']+'.conf','w'):
    f.write("        ProxyPass          /{} http://{}/api\n".format(institute['uuid'],institute['ipVPN']))
    f.write("        ProxyPassReverse   /{} http://{}/api\n".format(institute['uuid'],institute['ipVPN']))
os.system('systemctl restart apache2')
os.system('/usr/share/cephalix/tools/create_institue_iso.sh {}'.format(institute['uuid']))

