#!/bin/bash

# Trap for catching errors
set -eE
trap 'catch $? $LINENO' ERR

catch() {
    echo "❌ Build failed at line $2 with exit code $1" >&2
    exit $1
}

exec > build.log 2>&1

export KBUILD_BUILD_USER=nobody
export KBUILD_BUILD_HOST=android-build

export PATH=${PWD}/toolchain/bin:${PATH}
export LLVM_DIR=${PWD}/toolchain/bin
export LLVM=1

export ARCH=arm64
export DEVICE=fogos
export AnyKernel3=AnyKernel3

echo "Clean build"
rm -rf out
rm -rf ${AnyKernel3}

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
    echo "❌ ERROR: Image not found, build failed"
    exit 1
fi

git clone -b fogos --depth=1 https://github.com/MondayNitro/AnyKernel3 ${AnyKernel3}
rm -rf ${AnyKernel3}/{.git,.github,README.md} ${AnyKernel3}/*placeholder

cp out/.config kernel_config
cp out/arch/arm64/boot/Image ${AnyKernel3}/Image
cp out/arch/arm64/boot/dtb.img ${AnyKernel3}/dtb
cp out/arch/arm64/boot/dtbo.img ${AnyKernel3}/dtbo.img

echo "✅ Clean build completed successfully!"
