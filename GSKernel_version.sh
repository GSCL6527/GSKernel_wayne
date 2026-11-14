#!/bin/sh

## GSKernel version info
KERNELDIR=`readlink -f .`

export GSKERNEL_VERSION_PREFIX="stable"
export GSKERNEL_VERSION="v16.0"
sed -i 's/v15.9_stable-EAS/v16.0_stable-EAS/' $KERNELDIR/arch/arm64/configs/gskernel_*
sed -i 's/ini_set("rom_version",	"v15.9_stable");/ini_set("rom_version",	"v16.0_stable");/' $KERNELDIR/anykernel3/META-INF/com/google/android/aroma-config

echo "	GSKernel Version info loaded."
