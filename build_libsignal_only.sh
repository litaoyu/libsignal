#!/bin/bash

set -e

echo "====== libsignal iOS 一键编译脚本 ======"

# ========== libsignal 根目录 ==========
LIBSIGNAL_PATH="$(pwd)"

cd "$LIBSIGNAL_PATH"
echo "当前目录: $(pwd)"

# echo "====== 清理 Rust 缓存 ======"
cargo clean

echo "====== 安装 iOS Targets（如未安装） ======"
rustup target add aarch64-apple-ios
rustup target add aarch64-apple-ios-sim

# ================= 检查 rust-src =================
TOOLCHAIN=$(rustup show active-toolchain | cut -d' ' -f1)
if ! rustup component list --toolchain "$TOOLCHAIN" | grep 'rust-src.*installed' >/dev/null; then
    echo "⚡ rust-src 未安装，自动安装中..."
    rustup component add rust-src --toolchain "$TOOLCHAIN"
else
    echo "✅ rust-src 已安装"
fi

# ========== 进入 FFI 目录 ==========
cd rust/bridge/ffi
echo "当前目录: $(pwd)"

# ================= 真机编译 ===================
echo "====== 编译 iOS 真机 (aarch64-apple-ios) ======"
export SDKROOT=$(xcrun --sdk iphoneos --show-sdk-path)
echo "使用 SDKROOT: $SDKROOT"
cargo build --release --target aarch64-apple-ios \
    -Z build-std=core,alloc,std \
    -Z build-std-features=compiler-builtins-mem

# # ================= 模拟器编译 ==================
# echo "====== 编译 iOS 模拟器 (aarch64-apple-ios-sim) ======"
# export SDKROOT=$(xcrun --sdk iphonesimulator --show-sdk-path)
# echo "使用 SDKROOT: $SDKROOT"
# cargo build --release --target aarch64-apple-ios-sim \
#     -Z build-std=core,alloc,std \
#     -Z build-std-features=compiler-builtins-mem

# ================= 校验产物 ==================
# 回到根目录查找
cd "$LIBSIGNAL_PATH"
DEVICE_LIB=$(find target/aarch64-apple-ios -name "libsignal_ffi.a" | head -n 1)
# SIM_LIB=$(find target/aarch64-apple-ios-sim -name "libsignal_ffi.a" | head -n 1)

echo "====== 校验产物 ======"
if [ -f "$DEVICE_LIB" ]; then
    echo "✅ 真机库生成成功: $DEVICE_LIB"
else
    echo "❌ 真机库缺失，请检查编译日志"
    exit 1
fi

# if [ -f "$SIM_LIB" ]; then
#     echo "✅ 模拟器库生成成功: $SIM_LIB"
# else
#     echo "❌ 模拟器库缺失，请检查编译日志"
#     exit 1
# fi

echo "====== 完成 ✅ libsignal .a 文件编译完成 ======"