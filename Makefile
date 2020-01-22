#
# Copyright (c) 2018 Peter Varkoly Nürnberg, Germany.  All rights reserved.
#
DESTDIR         = /
SHARE           = $(DESTDIR)/usr/share/cephalix/
OSSSHARE        = $(DESTDIR)/usr/share/oss/
TOPACKAGE       = Makefile etc setup tools templates plugins sbin README.md
HERE            = $(shell pwd)
PACKAGE         = cephalix-base
REPO		= /data1/OSC/home:varkoly:OSS-4-1:leap15.1/

install:
	mkdir -p $(SHARE)/{setup,templates,tools,plugins}
	mkdir -p $(OSSSHARE)/plugins/
	mkdir -p $(DESTDIR)/etc
	mkdir -p $(DESTDIR)/usr/sbin
	mkdir -p $(DESTDIR)/$(FILLUPDIR)
	rsync -a etc/       $(DESTDIR)/etc/
	rsync -a tools/     $(SHARE)/tools/
	rsync -a templates/ $(SHARE)/templates/
	rsync -a setup/     $(SHARE)/setup/
	rsync -a plugins/   $(OSSSHARE)/plugins/
	install -m 755 sbin/* $(DESTDIR)/usr/sbin/

dist:
	if [ -e $(PACKAGE) ] ;  then rm -rf $(PACKAGE) ; fi   
	mkdir $(PACKAGE)
	for i in $(TOPACKAGE); do \
	    cp -rp $$i $(PACKAGE); \
	done
	find $(PACKAGE) -type f > files;
	tar jcpf $(PACKAGE).tar.bz2 -T files;
	rm files
	rm -rf $(PACKAGE)
	if [ -d $(REPO)/$(PACKAGE) ] ; then \
	    cd $(REPO)/$(PACKAGE); osc up; cd $(HERE);\
	    mv $(PACKAGE).tar.bz2 $(REPO)/$(PACKAGE); \
	    cd $(REPO)/$(PACKAGE); \
	    osc vc; \
	    osc ci -m "New Build Version"; \
	fi

