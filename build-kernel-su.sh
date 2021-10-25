#!/bin/sh

# Build wsa kernel with LSPosed su patch
# Please do not run this script under Windows path of WSL
# Supply two arguments:
# 1. The path of the kernel source code
# 2. The path of the output kernel image

# Replace the following if you need to
KERNEL_URL=$1
DESTINATION=$(realpath $2)
KERNEL=$(pwd)/WSA-Kernel
SU=$(pwd)/WSA-Kernel-SU

ARCH=$(uname -m)

# check if docker is installed
if ! [ -x "$(command -v docker)" ]; then
  echo 'Error: docker is not installed.' >&2
  exit 1
fi

KERNEL_BASE=$KERNEL/drivers/base
SU_BASE=$SU/drivers/base

# download the kernel
curl -L $1 kernel.zip
unzip -o kernel.zip -d $KERNEL

# patch with su
git clone https://github.com/LSPosed/WSA-Kernel-SU.git $SU --depth=1 --single-branch --recurse-submodules
grep -q ASSISTED_SUPERUSER $KERNEL_BASE/Kconfig || cat $SU_BASE/Kconfig >> $KERNEL_BASE/Kconfig
grep -q ASSISTED_SUPERUSER $KERNEL_BASE/Makefile || cat $SU_BASE/Makefile >> $KERNEL_BASE/Makefile
cp $SU_BASE/superuser.c $KERNEL_BASE/superuser.c

# build the kernel
pushd $KERNEL
if [ $ARCH = "x86_64" ]; then
    cp configs/wsa/config-wsa-[^a]* .config
    docker run --rm -v "$KERNEL:/src" -it ghcr.io/kiruyamomochi/wsa-kernel-build:main
    cp $KERNEL/arch/x86/boot/bzImage $DESTINATION
elif [ $ARCH = "arm64" ]; then
    cp configs/wsa/config-wsa-arm64-* .config
    docker run --rm -v "$KERNEL:/src" -it ghcr.io/kiruyamomochi/wsa-kernel-build:main sh -c 'make -j$(nproc) LLVM=1 ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu Image'
    cp $KERNEL/arch/arm64/boot/Image $DESTINATION
fi
popd
