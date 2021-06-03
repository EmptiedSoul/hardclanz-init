all: supervision/hd rc/hdcompile rc/hrdrc rc/lib/functions.sh sysvinit control/service
supervision/hd:
	gcc supervision/hd.c -o supervision/hd -Os -DNDEBUG
sysvinit:
	make -C init -j`nproc`
clean:
	rm supervision/hd
	make -C init distclean
install: all
	install -vm755 supervision/hd		/sbin/hd
	.install-scripts/install-base-layout
	.install-scripts/install-initscripts
	.install-scripts/install-rmcg
	make -C init install
