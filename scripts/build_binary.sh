#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/.build/manual"
ARCH="$(uname -m)"
# ScreenCaptureKit 的 SCScreenshotManager 需要 macOS 14
TARGET_TRIPLE="$ARCH-apple-macos14.0"
BUILD_CONFIG="${BUILD_CONFIG:-debug}"
MODULE_CACHE_DIR="$ROOT_DIR/.build/module-cache"

mkdir -p "$BUILD_DIR" "$MODULE_CACHE_DIR"

SWIFTC_FLAGS=(
    -module-cache-path "$MODULE_CACHE_DIR"
    -target "$TARGET_TRIPLE"
    -framework AppKit
    -framework ScreenCaptureKit
)

if [[ "$BUILD_CONFIG" == "release" ]]; then
    SWIFTC_FLAGS+=(-O)
else
    SWIFTC_FLAGS+=(-g)
fi

# 一次把 Core 和 App 的源码编到一起，不分模块 —— 所以 main.swift 里的
# `#if SWIFT_PACKAGE import MacBarWaiterCore` 在这条路径下不会生效，也不需要。
swiftc \
    "${SWIFTC_FLAGS[@]}" \
    "$ROOT_DIR"/Sources/MacBarWaiterCore/*.swift \
    "$ROOT_DIR"/Sources/MacBarWaiterApp/main.swift \
    -o "$BUILD_DIR/MacBarWaiter"

echo "Built $BUILD_DIR/MacBarWaiter"
