#!/usr/bin/env bash
#
# GSKernel CI build script (wayne / MI 6X / SDM660)
# 专用于 GitHub Actions，自包含、干净，不依赖作者本地环境。
#
# 只编译一套配置：gskernel_wayne-AndroidQ_defconfig（Android 10 / Q）
# 产物：Image.gz-dtb + wlan_pie.ko 等模块，最后用 anykernel3 打包成 zip。
#
set -euo pipefail

KERNELDIR="$(cd "$(dirname "$0")" && pwd)"
cd "$KERNELDIR"

ARCH=arm64
SUBARCH=arm64
DEFCONFIG="gskernel_wayne-AndroidQ_defconfig"
DEVICE="wayne"

# ---- 工具链路径（由 workflow 通过环境变量传入） ----
# CLANG_DIR  : 若提供则用 clang 编译；留空则用 CROSS_COMPILE 指定的 GCC
# CROSS_COMPILE : aarch64 交叉工具链前缀，默认 aarch64-linux-gnu-
CLANG_DIR="${CLANG_DIR:-}"
CROSS_COMPILE="${CROSS_COMPILE:-aarch64-linux-gnu-}"
OUTDIR="${OUTDIR:-$KERNELDIR/out}"

# 构造 clang 的绝对路径
if [ -n "$CLANG_DIR" ]; then
    CLANG_BIN="$(cd "$CLANG_DIR" && pwd)/bin"
    export PATH="$CLANG_BIN:$PATH"
fi

export ARCH SUBARCH

JOBS="${JOBS:-$(nproc)}"
echo "==> Toolchain: gcc=$(${CROSS_COMPILE}gcc --version 2>/dev/null | head -1)"
echo "==> Jobs: $JOBS"
echo "==> Out: $OUTDIR"

# 公共 make 参数（有 CLANG_DIR 用 clang，否则用 GCC）
if [ -n "$CLANG_DIR" ]; then
    MAKE_ARGS=( O="$OUTDIR" ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE="$CROSS_COMPILE" )
else
    MAKE_ARGS=( O="$OUTDIR" ARCH=arm64 CC="${CC:-${CROSS_COMPILE}gcc}" CROSS_COMPILE="$CROSS_COMPILE" KCFLAGS="-fcommon" HOSTCFLAGS="-fcommon" )
fi

# ---- 1. 生成配置 ----
echo "==> make $DEFCONFIG"
make "${MAKE_ARGS[@]}" "$DEFCONFIG"

# ---- 2. 编译内核 ----
echo "==> make -j$JOBS"
make "${MAKE_ARGS[@]}" -j"$JOBS"

# ---- 3. 编译外部模块（wlan 等 .ko） ----
echo "==> make modules"
make "${MAKE_ARGS[@]}" -j"$JOBS" modules

# ---- 4. 校验内核镜像 ----
IMAGE="$OUTDIR/arch/arm64/boot/Image.gz-dtb"
if [ ! -f "$IMAGE" ]; then
    echo "ERROR: 未找到 $IMAGE" >&2
    exit 1
fi
echo "==> Image 生成成功: $(ls -lh "$IMAGE" | awk '{print $5}')"

# ---- 5. 收集 WiFi 模块 ----
# Android-Q 配置使用 CONFIG_QCA_CLD_WLAN_PIE=y，对应 qcacld-3.0_pie/wlan.ko
WLAN_PIE="$OUTDIR/drivers/staging/qcacld-3.0_pie/wlan.ko"
if [ -f "$WLAN_PIE" ]; then
    echo "==> 找到 wlan_pie.ko: $(ls -lh "$WLAN_PIE" | awk '{print $5}')"
else
    echo "WARN: 未找到 qcacld-3.0_pie/wlan.ko（可能模块名不同，继续）" >&2
fi

# ---- 6. 打包 anykernel3 zip ----
echo "==> 打包 anykernel3 zip"
BUILD_DIR="$KERNELDIR/BUILT-$DEVICE"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cp -r "$KERNELDIR/anykernel3/." "$BUILD_DIR/"

# 内核镜像：直接命名为 Image.gz-dtb，刷机脚本可无条件识别
cp -f "$IMAGE" "$BUILD_DIR/Image.gz-dtb"

# 也提供 -androidq 命名，兼容刷机脚本按 KERNEL_TYPE 选择时仍能匹配
cp -f "$IMAGE" "$BUILD_DIR/Image.gz-dtb-androidq"

# WiFi 模块放入 tools/（刷机脚本会 cp tools/wlan*.ko 到 /vendor/gskernel/）
if [ -f "$WLAN_PIE" ]; then
    cp -f "$WLAN_PIE" "$BUILD_DIR/tools/wlan_pie.ko"
fi

# 设置 device.name1=wayne（构建脚本原逻辑）
if [ -f "$BUILD_DIR/anykernel.sh" ]; then
    sed -i 's/device.name1=/device.name1=wayne/' "$BUILD_DIR/anykernel.sh"
fi

# 打 zip
ZIP_OUT="$KERNELDIR/READY_ZIP"
mkdir -p "$ZIP_OUT"
ZIP_NAME="GSKernel_${DEVICE}-Android10.zip"
(cd "$BUILD_DIR" && zip -rq "$ZIP_OUT/$ZIP_NAME" .)

echo ""
echo "=============================================="
echo " 构建完成！"
echo " 内核镜像: $IMAGE"
echo " 刷机包:   $ZIP_OUT/$ZIP_NAME"
echo "=============================================="
ls -lh "$ZIP_OUT/$ZIP_NAME"
