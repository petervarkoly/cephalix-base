#!/usr/bin/python3
import json
import os
import sys
from configobj import ConfigObj
config   = ConfigObj("/opt/cranix-java/conf/cranix-api.properties")
passwd   = config['de.cranix.dao.User.Register.Password']
dyndns=""

#Create an open task if something goes wrong
def create_open_task():
  TASK = "/var/adm/cranix/opentasks/100-validate-regcode-" + os.popen('uuidgen -t').read().rstrip()
  with open(TASK, "w") as f:
    f.write(json.dumps(dyndns,sort_keys=True,ensure_ascii=False))

dyndns=json.loads(sys.stdin.read())

ip=dyndns['ip']
hostname=dyndns['hostname']
domain=dyndns['domain']
oldip=dyndns.get('oldip','')

if oldip == '':
    if os.system("samba-tool dns add localhost " + domain + " " + hostname + " A " + ip + "  -U register%" + passwd ) != 0:
       create_open_task()
elif oldip != ip:
    if os.system("samba-tool dns update localhost " + domain + " " + hostname + " A " + oldip + " " + ip + "  -U register%" + passwd ) != 0:
       if os.system("samba-tool dns add localhost " + domain + " " + hostname + " A " + ip + "  -U register%" + passwd ) != 0:
          create_open_task()

