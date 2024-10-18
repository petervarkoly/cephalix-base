#!/usr/bin/python
import json
import os
import sys

#Create an open task if something goes wrong
def create_open_task(institute):
  TASK = "/var/adm/cranix/opentasks/100-modify-institute-" + os.popen('uuidgen -t').read().rstrip()
  with open(TASK, "w") as f:
    f.write(json.dumps(institute,sort_keys=True,ensure_ascii=False,encoding="utf-8"))

institute=json.loads(sys.stdin.read())

ip=institute['ipVPN']
cephalixPW=institute['cephalixPW']
adminPW=institute['adminPW']
regCode=institute['regCode']
os.system("/root/bin/add_regcode_to_hwpass.sh {0}".format(regCode))

if cephalixPW != "":
  cmd="ssh " + ip + " /usr/bin/samba-tool user setpassword cephalix --newpassword='" + cephalixPW +"'"
  if os.system(cmd) !=0:
    create_open_task(institute)

if adminPW != "":
  cmd="ssh " + ip + " /usr/bin/samba-tool user setpassword Administrator --newpassword='" + adminPW +"'"
  if os.system(cmd) !=0:
    create_open_task(institute)
