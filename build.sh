#!/bin/bash

# Trap for catching errors
set -eE
trap 'catch $? $LINENO' ERR

catch() {
    echo "❌ Build failed at line $2 with exit code $1" >&2
    exit $1
}

# Start logging
exec > build.log 2>&1

export KBUILD_BUILD_USER=nobody
export KBUILD_BUILD_HOST=android-build

export PATH=${PWD}/toolchain/bin:${PATH}
export AnyKernel3=AnyKernel3
export LLVM_DIR=${PWD}/toolchain/bin
export LLVM=1
export modpath=${AnyKernel3}/modules/vendor/lib/modules

export ARCH=arm64
export DEVICE=fogos

if [[ -z "$1" || "$1" = "-c" ]]; then
    echo "Clean Build"
    rm -rf out
elif [ "$1" = "-d" ]; then
    echo "Dirty Build"
else
    echo "Error: Set $1 to -c or -d"
    exit 1
fi

ARGS="
ARCH=arm64
CC=clang
LLVM=1
LLVM_IAS=1
LD=${LLVM_DIR}/ld.lld
AR=${LLVM_DIR}/llvm-ar
NM=${LLVM_DIR}/llvm-nm
OBJCOPY=${LLVM_DIR}/llvm-objcopy
OBJDUMP=${LLVM_DIR}/llvm-objdump
READELF=${LLVM_DIR}/llvm-readelf
STRIP=${LLVM_DIR}/llvm-strip
"

make ${ARGS} O=out fogos_defconfig
make ${ARGS} O=out -j$(nproc --all)

if [ ! -e out/arch/arm64/boot/Image ]; then
    echo "❌ ERROR: Image binary not found in expected location, fix compile!"
    exit 1
fi

make O=out ${ARGS} -j$(nproc --all) INSTALL_MOD_PATH=modules INSTALL_MOD_STRIP=1 modules_install

git clone --depth=1 https://github.com/MondayNitro/AnyKernel3 ${AnyKernel3}
rm -rf ${AnyKernel3}/.github
mkdir -p ${modpath}
kver=$(make kernelversion)
kmod=$(echo ${kver} | awk -F'.' '{print $3}')

cp out/.config kernel_config
cp out/arch/arm64/boot/Image ${AnyKernel3}/Image
cp out/arch/arm64/boot/dtb.img ${AnyKernel3}/dtb
cp out/arch/arm64/boot/dtbo.img ${AnyKernel3}/dtbo.img
cp $(find out/modules/lib/modules/5.4* -name '*.ko') ${modpath}/
cp out/modules/lib/modules/5.4*/modules.{alias,dep,softdep} ${modpath}/
cp out/modules/lib/modules/5.4*/modules.order ${modpath}/modules.load

# Fix module paths
sed -i 's/\(kernel\/[^: ]*\/\)\([^: ]*\.ko\)/\/vendor\/lib\/modules\/\2/g' ${modpath}/modules.dep
sed -i 's/.*\///; s/\.ko$//' ${modpath}/modules.load

cd ${AnyKernel3}
zip -r9 build.zip * -x .git README.md *placeholder config
echo "✅ Build completed successfully!"
