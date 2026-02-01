#!/bin/bash

# ZMK Build Script for Corneish Zen v2
# This script builds firmware for both left and right sides using Docker
#
# Usage:
#   ./build.sh              # Build standard firmware
#   ./build.sh --studio     # Build with ZMK Studio support on left side

set -e  # Exit on any error

WORKSPACE=$(pwd)
BUILD_STUDIO=false

# Parse command line arguments
if [[ "$1" == "--studio" ]]; then
  BUILD_STUDIO=true
fi

echo "Building ZMK firmware for Corneish Zen v2..."
echo "Workspace: $WORKSPACE"
if [ "$BUILD_STUDIO" = true ]; then
  echo "Mode: ZMK Studio enabled (left side)"
else
  echo "Mode: Standard build"
fi
echo ""

# Build left side
if [ "$BUILD_STUDIO" = true ]; then
  echo "=== Building LEFT side (with ZMK Studio) ==="
  docker run --rm \
    -v "$WORKSPACE:/workspace" \
    -w /workspace \
    zmkfirmware/zmk-build-arm:stable \
    west build -s /workspace/zmk/app -d build/left_studio -b corneish_zen_v2_left -S studio-rpc-usb-uart -- \
      -DZMK_CONFIG=/workspace/config \
      -DZephyr_DIR=/workspace/zephyr/share/zephyr-package/cmake \
      -DCONFIG_ZMK_STUDIO=y
else
  echo "=== Building LEFT side ==="
  docker run --rm \
    -v "$WORKSPACE:/workspace" \
    -w /workspace \
    zmkfirmware/zmk-build-arm:stable \
    west build -s /workspace/zmk/app -d build/left -b corneish_zen_v2_left -- \
      -DZMK_CONFIG=/workspace/config \
      -DZephyr_DIR=/workspace/zephyr/share/zephyr-package/cmake
fi

echo ""
echo "=== Building RIGHT side ==="
docker run --rm \
  -v "$WORKSPACE:/workspace" \
  -w /workspace \
  zmkfirmware/zmk-build-arm:stable \
  west build -s /workspace/zmk/app -d build/right -b corneish_zen_v2_right -- \
    -DZMK_CONFIG=/workspace/config \
    -DZephyr_DIR=/workspace/zephyr/share/zephyr-package/cmake

echo ""
echo "=== Build Complete! ==="
if [ "$BUILD_STUDIO" = true ]; then
  echo "Left side (Studio):  build/left_studio/zephyr/zmk.uf2"
else
  echo "Left side:           build/left/zephyr/zmk.uf2"
fi
echo "Right side:          build/right/zephyr/zmk.uf2"
echo ""
echo "To flash your keyboard:"
echo "1. Put the keyboard into bootloader mode (double-tap reset)"
echo "2. Copy the appropriate .uf2 file to the USB drive that appears"
if [ "$BUILD_STUDIO" = true ]; then
  echo ""
  echo "ZMK Studio is now enabled on the left side!"
  echo "Connect via USB and visit: https://zmk.studio"
fi
