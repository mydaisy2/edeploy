SDIR=/root/edeploy
TOP=/var/lib/debootstrap
VERS=D7-F.1.0.0
DIST=wheezy

SRC=base
DST=pxe
IMG=initrd.pxe
ARCH=amd64
export PATH := /sbin:/bin::$(PATH)
SERV:=10.66.6.10

INST=$(TOP)/install/$(VERS)
META=$(TOP)/metadata/$(VERS)

all: $(INST)/$(IMG) $(INST)/mysql.done

pxe $(INST)/$(IMG): $(INST)/base.done init pxe.install detect.py hpacucli.py matcher.py diskinfo.py ipmi.py
	./pxe.install $(INST)/base $(INST)/pxe $(IMG) $(VERS)

img: pxe
	./img.install $(INST)/base $(IMG) $(VERS) $(INST) $(SERV)

base $(INST)/base.done: base.install policy-rc.d edeploy
	ARCH=$(ARCH) ./base.install $(INST)/base $(DIST) $(VERS)
	cp -p policy-rc.d edeploy $(INST)/base/usr/sbin/
	touch $(INST)/base.done

openstack $(INST)/openstack.done: openstack.install $(INST)/base.done
	./openstack.install $(INST)/base $(INST)/openstack $(VERS)
	touch $(INST)/openstack.done

openstack-compute $(INST)/openstack-compute.done: openstack-compute.install $(INST)/base.done
	./openstack-compute.install $(INST)/base $(INST)/openstack-compute $(VERS)
	touch $(INST)/openstack-compute.done

mysql $(INST)/mysql.done: mysql.install $(INST)/base.done
	./mysql.install $(INST)/base $(INST)/mysql $(VERS)
	touch $(INST)/mysql.done

ceph $(INST)/ceph.done: ceph.install $(INST)/base.done
	./ceph.install $(INST)/base $(INST)/ceph $(VERS)
	touch $(INST)/ceph.done

test: $(INST)/$(IMG)
	cd tests/tftpboot/; ln -sf $(INST)/base/boot/vmlinuz* vmlinuz; ln -sf $(INST)/initrd.pxe initrd;
	cd tests; ./run_kvm.sh $(TOP)

dist:
	tar zcvf ../edeploy.tgz Makefile init README.rst *.install edeploy update-scenario.sh *.py

clean:
	-rm -f *~ $(INST)/*.done

distclean: clean
	-rm -rf $(INST)/*
