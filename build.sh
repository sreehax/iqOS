#!/bin/bash
if [ `whoami` != root ]; then
	echo "root permissions required";
	exit
fi
source functions.sh
# DEFINITIONS
export KERNEL_VERSION=4.20
export OS_VERSION=0.0.1
export TOP=$PWD
export URL=https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-$KERNEL_VERSION.tar.gz
fetchkernel
fetchbusybox
buildkernel
buildbusybox
packer
buildiso
cd $TOP
