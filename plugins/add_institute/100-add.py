#!/usr/bin/python
import json
import os
import sys
from configobj import ConfigObj
config   = ConfigObj("/opt/oss-java/conf/oss-api.properties")
passwd   = config['de.openschoolserver.dao.User.Register.Password']
institute=""

#Create an open task if something goes wrong
def create_open_task():
  TASK = "/var/adm/oss/opentasks/100-add-institute-" + os.popen('uuidgen -t').read().rstrip()
  with open(TASK, "w") as f:
    f.write(json.dumps(institute,sort_keys=True,ensure_ascii=False,encoding="utf-8"))

institute=json.loads(sys.stdin.read())

ip=institute['ipVPN'] 
name=institute['uuid'] 
domain=os.popen('oss_api_text.sh GET system/configuration/DOMAIN').read()

if os.system("samba-tool dns add localhost " + domain + " " + name + " A " + ip + "  -U register%" + passwd ) != 0:
  create_open_task()
