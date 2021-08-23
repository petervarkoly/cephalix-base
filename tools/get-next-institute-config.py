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

#Read the defaults from the config file
defaults=json.loads(open(DEFAULTS_FILE,"r").read())
SSLVARS = {}

CEPHALIX_PATH = defaults['CEPHALIX_PATH']

save_next     = defaults.get("SAVE_NEXT",True)
save_next_vpn = defaults.get("SAVE_NEXT_VPN",True)

# Handle VPN
if save_next_vpn:
    vpn_net = IPv4Network("{}/{}".format(defaults['ipVPN'],'30'),False)
    next_vpn_ip = vpn_net.network_address+5
    defaults['ipVPN'] = next_vpn_ip.exploded
# Create next network if necessary
if save_next:
    # create some networks
    network        = IPv4Network(defaults['internalNetwork'])
    network_dhcp   = IPv4Network(defaults['anonDhcpNetwork'])
    network_server = IPv4Network(defaults['serverNetwork'])
    defaults['netmask']       = network.prefixlen
    defaults['netmaskString'] = network.netmask.exploded
    next_network_address = network.network_address + network.num_addresses
    next_network = IPv4Network("{}/{}".format(next_network_address, network.prefixlen))
    ip_addresses = list(next_network.hosts())
    defaults['internalNetwork']  = "{}/{}".format(next_network_address, network.prefixlen)
    defaults['ipAdmin']  = ip_addresses[1].exploded
    defaults['ipMail']   = ip_addresses[2].exploded
    defaults['ipPrint']  = ip_addresses[3].exploded
    defaults['ipProxy']  = ip_addresses[4].exploded
    defaults['ipBackup'] = ip_addresses[5].exploded
    defaults['anonDhcpRange']   = '{} {}'.format(ip_addresses[255],ip_addresses[510])
    defaults['anonDhcpNetwork'] = '{}/{}'.format(ip_addresses[255],network_dhcp.prefixlen)
    defaults['firstRoom']     = ip_addresses[511].exploded
    defaults['serverNetwork'] = '{}/{}'.format(next_network_address,network_server.prefixlen)
    defaults['ipGateway']     = ip_addresses[1].exploded
#rewrite the defaults
with open(DEFAULTS_FILE,'w') as f:
    f.write(json.dumps(defaults,sort_keys=True, indent=4,ensure_ascii=False))

