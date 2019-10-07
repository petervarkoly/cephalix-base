#!/bin/bash
uuid=$1
tmpDir=$( mktemp /tmp/mkisoXXXXX )
cp /srv/www/admin/configs/${uuid}.xml /usr/share/cephalix/templates/iso/oss.xml
mkisofs --publisher 'Dipl.Ing. Peter Varkoly' -p 'CD-Team, http://www.cephalix.eu' \
        -r -J -f -pad -no-emul-boot -boot-load-size 4 -boot-info-table -b boot/x86_64/loader/isolinux.bin  \
        -c boot/boot.catalog -hide boot/boot.catalog -hide-joliet boot/boot.catalog -A - -V SU.001 \
	-o /srv/www/admin/isos/${uuid}.iso $tmpDir /usr/share/cephalix/templates/iso/ >/dev/null 2>&1

