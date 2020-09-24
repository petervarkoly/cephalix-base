#!/bin/bash
uuid=$1
cp /srv/www/admin/configs/${uuid}.xml /usr/share/cephalix/templates/iso/cranix.xml
sed 's/halt config:type="boolean">false/halt config:type="boolean">true/' /srv/www/admin/configs/${uuid}.xml > /usr/share/cephalix/templates/iso/cranix-usb.xml

mksusecd --create /srv/www/admin/isos/${uuid}.iso \
	--vendor "Dipl.Ing. Peter Varkoly" \
	--application "$uuid installer" \
	/usr/share/cephalix/templates/CRANIX.iso \
	/usr/share/cephalix/templates/iso/

