all: supervision/hd rc/hdcompile rc/hrdrc rc/lib/functions.sh sysvinit control/service
supervision/hd:
	gcc supervision/hd.c -o supervision/hd -O3 -DNDEBUG
sysvinit:
	make -C init -j`nproc`
clean:
	rm supervision/hd
	make -C init distclean
install: all
	install -vm755 supervison/hd		/sbin/hd
	install -vm755 rc/hdcompile		/sbin/hdcompile
	install -vm755 rc/hrdrc			/etc/rc.d/hrdrc
	install -vm755 rc/lib/functions.sh	/etc/rc.d/lib/functions.sh
	install -vm755 control/service		/usr/bin/service
	make -C init install
