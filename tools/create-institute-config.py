#!/usr/bin/python3
import json
import socket
import os
import sys
from ipaddress import *
#Define some defaults
# The file with the default values.
DEFAULTS_FILE = "/usr/share/cephalix/templates/Defaults.ini"
# Attributes must be cleaned befor writing into defaults
TO_CLEAN = ( "uuid", "name", "type", "domain", "adminPW" )
# Attributes which must not be changed
READONLY = ( "CEPHALIX", "CEPHALIX_PATH", "CEPHALIX_DOMAIN", "CCODE", "LANGUAGE", "NTP", "ZADMIN" )

#Read datas from stdin
institute=json.loads(sys.stdin.read())
#Read the defaults from the config file
defaults=json.loads(open(DEFAULTS_FILE,"r").read())
SSLVARS = {}

CEPHALIX_PATH = defaults['CEPHALIX_PATH']

# The configuration files template file
xml_file          =  "/usr/share/cephalix/templates/autoyast-"+ institute.get("ayTemplate","default") + ".xml"
vpn_connect_file  =  "/usr/share/cephalix/templates/vpn-connect-institute-to-cephalix.sh"
full_connect_file =  "/usr/share/cephalix/templates/full-connect-institute-to-cephalix.sh"

#Set the read only values
for key in READONLY:
    institute[key] = defaults[key]

save_next     = institute.get("SAVE_NEXT",True)
save_next_vpn = institute.get("SAVE_NEXT_VPN",True)

# create some networks
network        = IPv4Network(institute['network'])
network_dhcp   = IPv4Network(institute['anonDhcpNetwork'])
network_server = IPv4Network(institute['serverNetwork'])
# calculate some network paramater
anon_dhcp_first = network_dhcp.network_address
anon_dhcp_last  = network_dhcp.network_address + network_dhcp.num_addresses -1
if network_dhcp.network_address == network.network_address: 
    anon_dhcp_first = anon_dhcp_first + 1
if anon_dhcp_last == network.network_address + network.num_addresses - 1:
    anon_dhcp_last = anon_dhcp_last - 1
institute['anonDhcpRange'] = "{} {}".format(anon_dhcp_first,anon_dhcp_last)
institute['netmask']       = network.prefixlen
institute['netmaskString'] = network.netmask
if 'WORKGROUP' not in institute:
    institute['WORKGROUP'] = institute['domain'].split('.')[0].upper()[0:15]

# Handle VPN
if institute["ipAdmin"] != institute['ipVPN']:
    vpn_net = IPv4Network("{}/{}".format(institute['ipVPN'],'30'),False)
    with open("/etc/openvpn/ccd/"+ institute['regCode'],"w") as ccd:
        ip_addresses = list(vpn_net.hosts())
        ccd.write("ifconfig-push {} {}\n".format(ip_addresses[0],ip_addresses[1]))
        if institute.get('fullrouting',False):
            ccd.write("iroute {} {}".format(network.network_address, network.netmask))
    if defaults['ipVPN'] == institute['ipVPN']:
        next_vpn_ip = vpn_net.network_address+5
        defaults['ipVPN'] = next_vpn_ip.exploded
# Create next network if necessary
if institute['saveNext'] and ( institute['network'] == defaults['network'] ):
    next_network_address = network.network_address + network.num_addresses
    next_network = IPv4Network("{}/{}".format(next_network_address, network.prefixlen))
    ip_addresses = list(next_network.hosts())
    defaults['network']  = next_network.exploded
    defaults['ipAdmin']  = ip_addresses[1].exploded
    defaults['ipMail']   = ip_addresses[2].exploded
    defaults['ipPrint']  = ip_addresses[3].exploded
    defaults['ipProxy']  = ip_addresses[4].exploded
    defaults['ipBackup'] = ip_addresses[5].exploded
    defaults['anonDhcp'] = '{} {}'.format(ip_addresses[255],ip_addresses[510])
    defaults['anonDhcpNetwork'] = '{}/{}'.format(ip_addresses[255],24)
    defaults['firstRoom']     = ip_addresses[511].exploded
    defaults['serverNetwork'] = '{}/{}'.format(next_network_address,network.prefixlen)
    defaults['ipGateway']     = ip_addresses[1].exploded

# Handle Certificates
if not os.path.isfile(CEPHALIX_PATH+'/CA_MGM/certs/admin.' + institute['domain'] + '.key.pem' ):
    cmd = CEPHALIX_PATH + '/create_server_certificates.sh -P ' + CEPHALIX_PATH + ' -O "' + institute['name'] + '"'
    if 'state' in institute:
        cmd += ' -S "' + institute['state'] + '"'
    if 'locality' in  institute:
        cmd += ' -L "' + institute['locality'] + '"'
    command = cmd + ' -D ' + institute['CEPHALIX_DOMAIN'] + ' -N "' + institute['regCode'] + '" -s'
    os.system(command)
    command = cmd + ' -D ' + institute['domain'] + ' -N admin'
    os.system(command)
    command = cmd + ' -D ' + institute['domain'] + ' -N schoolserver'
    os.system(command)
if not os.path.isfile(CEPHALIX_PATH+'CA_MGM/certs/' + institute['regCode'] + '.' + institute['CEPHALIX_DOMAIN'] + '.key.pem'):
    cmd = CEPHALIX_PATH + '/create_server_certificates.sh -P ' + CEPHALIX_PATH + ' -O "' + institute['name'] + '"'
    if 'state' in institute:
        cmd += ' -S "' + institute['state'] + '"'
    if 'locality' in  institute:
        cmd += ' -L "' + institute['locality'] + '"'
    command = cmd + ' -D ' + institute['CEPHALIX_DOMAIN'] + ' -N "' + institute['regCode'] + '" -s'
    os.system(command)
SSLVARS['REPLACE-SSHKEY']     = open('/root/.ssh/id_rsa.pub','r').read()
SSLVARS['REPLACE-CA-CERT']    = open(CEPHALIX_PATH + 'CA_MGM/cacert.pem','r').read()
SSLVARS['REPLACE-VPN-KEY']    = open(CEPHALIX_PATH + 'CA_MGM/certs/' + institute['regCode'] + '.' + institute['CEPHALIX_DOMAIN'] + '.key.pem','r').read()
SSLVARS['REPLACE-VPN-CERT']   = open(CEPHALIX_PATH + 'CA_MGM/certs/' + institute['regCode'] + '.' + institute['CEPHALIX_DOMAIN'] + '.cert.pem','r').read()
SSLVARS['REPLACE-ADMIN-KEY']  = open(CEPHALIX_PATH + 'CA_MGM/certs/admin.' + institute['domain'] + '.key.pem','r').read()
SSLVARS['REPLACE-ADMIN-CERT'] = open(CEPHALIX_PATH + 'CA_MGM/certs/admin.' + institute['domain'] + '.cert.pem','r').read()
SSLVARS['REPLACE-SCHOOL-KEY'] = open(CEPHALIX_PATH + 'CA_MGM/certs/schoolserver.' + institute['domain'] + '.key.pem','r').read()
SSLVARS['REPLACE-SCHOOL-CERT']= open(CEPHALIX_PATH + 'CA_MGM/certs/schoolserver.' + institute['domain'] + '.cert.pem','r').read()

institute['network']       = network.network_address
xml_content = open(xml_file,'r').read()
vpn_connect_content  = open(vpn_connect_file,'r').read()
full_connect_content = open(vpn_connect_file,'r').read()
for key in institute:
    value = "{}".format(institute[key])
    rkey  = '###'+key+'###'
    xml_content = xml_content.replace(rkey,value)
    vpn_connect_content  = vpn_connect_content.replace(rkey,value)
    full_connect_content = full_connect_content.replace(rkey,value)
for key in SSLVARS:
    xml_content = xml_content.replace(key,SSLVARS[key])
    vpn_connect_content = vpn_connect_content.replace(key,SSLVARS[key])
    full_connect_content = full_connect_content.replace(key,SSLVARS[key])
os.system('mkdir -p /srv/www/admin/{configs,isos}')

#write the config files
with open('/srv/www/admin/configs/' + institute['regCode'] + '.xml' ,'w') as f:
    f.write(xml_content)
with open('/srv/www/admin/configs/' + institute['regCode'] + 'vpn-connect.sh' ,'w') as f:
    f.write(vpn_connect_content)
with open('/srv/www/admin/configs/' + institute['regCode'] + 'full-connect.sh' ,'w') as f:
    f.write(full_connect_content)
#rewrite the defaults
with open(DEFAULTS_FILE,'w') as f:
    f.write(json.dumps(defaults))

#write apache configuration
with open('/etc/apache2/vhosts.d/admin-ssl/'+institute['uuid']+'.conf','w') as f:
    f.write("        ProxyPass          /{} http://{}/api\n".format(institute['uuid'],institute['ipVPN']))
    f.write("        ProxyPassReverse   /{} http://{}/api\n".format(institute['uuid'],institute['ipVPN']))
os.system('systemctl reload apache2')
os.system('/usr/share/cephalix/tools/create_institue_iso.sh {}'.format(institute['regCode']))

