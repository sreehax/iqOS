fetchkernel() {
	cd $TOP
	mkdir -p work/out
	rm -rf work/*
	cd work
	mkdir out
	curl -o linux.tar.gz $URL
	tar -xf linux.tar.gz
	rm linux.tar.gz
	mv linux* linux
	cd linux
	make mrproper
}
fetchbusybox() {
	cd $TOP
	if [ -d work/busybox ]; then
		cd work/busybox
		git pull
		make mrproper
	else
		cd work
		git clone git://busybox.net/busybox.git
		cd busybox
		make mrproper
	fi

}
buildkernel() {
	cd $TOP
	cp files/linux-config work/linux/.config
	cd work/linux
	make -j`nproc`
	cp arch/x86/boot/bzImage ../out/vmlinuz
}
buildbusybox() {
	cd $TOP
	cp files/busybox-config work/busybox/.config
	cd work/busybox
	make -j`nproc`
	cp busybox ../out/
}
packer() {
	cd $TOP
	mkdir -p work/initrd
	cd work/initrd
	rm -rf *
	mkdir dev sys proc lib bin sbin usr usr/bin usr/sbin etc tmp mnt mnt/boot mnt/roroot mnt/root
	ln -s lib lib64
	ln -s ../lib usr/lib
	ln -s ../lib usr/lib64
	cp ../out/busybox bin/
	chroot . /bin/busybox --install -s
	rm linuxrc
	cd ../linux
	make modules_install INSTALL_MOD_PATH=`realpath ../initrd`
	cd ../initrd
	cp ../../files/initrd-init ./init
	chmod +x init
	find . | cpio -H newc -o | gzip > ../out/initrd.img
	cd ..
	rm -rf out/fs.squash
	mksquashfs initrd out/fs.squash
}
buildiso() {
	cd $TOP
	mkdir -p work/efidir work/isodir
	cd work/efidir
	rm -rf *
	cd $TOP
	dd bs=500K count=5 if=/dev/zero of=work/out/efi.img
	mkfs.vfat work/out/efi.img
	mount -t vfat work/out/efi.img work/efidir
	cd work/efidir
	mkdir -p EFI/BOOT boot/grub
	cp ../../files/*.EFI EFI/BOOT/
	cp ../../files/grub.cfg boot/grub
	cd ..
	umount efidir
	mkdir -p isodir
	cd isodir
	rm -rf *
	mkdir isolinux
	cp -r ../../files/isolinux.* ../../files/ldlinux.c32 isolinux/
	cp -r ../out/efi.img .
	mkdir boot
	cp ../out/vmlinuz ../out/initrd.img boot/
	cp ../out/fs.squash .
	touch iqOS
	xorriso -as mkisofs -isohybrid-mbr ../../files/isohdpfx.bin -V iqOS -c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e efi.img -no-emul-boot -isohybrid-gpt-basdat -o $TOP/linux.iso  .
	cd $TOP
}
