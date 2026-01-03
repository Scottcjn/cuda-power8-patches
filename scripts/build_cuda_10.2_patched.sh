#!/bin/bash
# Build CUDA 10.2 for POWER8 (with CPU check patch)
# This script downloads CUDA 10.2 from NVIDIA, applies the POWER8 patch, and builds the kernel modules.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${WORK_DIR:-$HOME/cuda-power8-build}"
CUDA_VERSION="10.2"
DRIVER_VERSION="440.33.01"
CUDA_URL="https://developer.download.nvidia.com/compute/cuda/10.2/Prod/local_installers/cuda_10.2.89_440.33.01_linux_ppc64le.run"
CUDA_FILE="cuda_10.2.89_ppc64le.run"

# Patch details
PATCH_OFFSET=0xa68af4
ORIGINAL_BYTES="419e003c"
PATCHED_BYTES="4800003c"

echo "=============================================="
echo "CUDA 10.2 for POWER8 - Patched Build"
echo "=============================================="
echo ""

# Check architecture
if [ "$(uname -m)" != "ppc64le" ]; then
    echo "ERROR: This script must be run on ppc64le (POWER8/9)"
    exit 1
fi

# Check for GCC 9
if ! command -v gcc-9 &> /dev/null; then
    echo "ERROR: gcc-9 is required (must match kernel compiler)"
    echo "Install with: sudo apt install gcc-9"
    exit 1
fi

# Create work directory
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Download CUDA if not present
if [ ! -f "$CUDA_FILE" ]; then
    echo "[1/5] Downloading CUDA $CUDA_VERSION (2.1 GB)..."
    wget -c "$CUDA_URL" -O "$CUDA_FILE"
else
    echo "[1/5] CUDA installer already downloaded"
fi

# Extract
echo "[2/5] Extracting CUDA installer..."
chmod +x "$CUDA_FILE"
rm -rf cuda_extracted
./"$CUDA_FILE" --target cuda_extracted --noexec

# Find and extract the driver
echo "[3/5] Extracting NVIDIA driver..."
cd cuda_extracted/builds
chmod +x NVIDIA-Linux-ppc64le-${DRIVER_VERSION}.run 2>/dev/null || true

# Check if standalone driver exists, otherwise look in nvidia-driver directory
if [ -f "NVIDIA-Linux-ppc64le-${DRIVER_VERSION}.run" ]; then
    ./NVIDIA-Linux-ppc64le-${DRIVER_VERSION}.run --extract-only --target nvidia-driver
elif [ -d "nvidia-driver" ]; then
    echo "Driver directory already exists"
else
    echo "ERROR: Cannot find NVIDIA driver package"
    exit 1
fi

# Apply the patch
echo "[4/5] Applying POWER8 CPU check bypass patch..."
BINARY="nvidia-driver/kernel/nvidia/nv-kernel.o_binary"

if [ ! -f "$BINARY" ]; then
    echo "ERROR: Cannot find nv-kernel.o_binary"
    exit 1
fi

# Backup original
cp "$BINARY" "${BINARY}.orig"

# Verify original bytes at patch location
CURRENT=$(xxd -s $PATCH_OFFSET -l 4 "$BINARY" | awk '{print $2$3}' | tr -d ' ')
CURRENT_SWAPPED="${CURRENT:6:2}${CURRENT:4:2}${CURRENT:2:2}${CURRENT:0:2}"

echo "  Offset: $PATCH_OFFSET"
echo "  Current bytes: $CURRENT_SWAPPED"
echo "  Expected (original): $ORIGINAL_BYTES"
echo "  Patch to: $PATCHED_BYTES"

# Apply patch using printf (writes little-endian)
printf '\x48\x00\x00\x3c' | dd of="$BINARY" bs=1 seek=$((PATCH_OFFSET)) conv=notrunc 2>/dev/null

# Verify patch
AFTER=$(xxd -s $PATCH_OFFSET -l 4 "$BINARY" | awk '{print $2$3}' | tr -d ' ')
AFTER_SWAPPED="${AFTER:6:2}${AFTER:4:2}${AFTER:2:2}${AFTER:0:2}"
echo "  After patch: $AFTER_SWAPPED"

if [ "$AFTER_SWAPPED" = "$PATCHED_BYTES" ]; then
    echo "  Patch applied successfully!"
else
    echo "  WARNING: Patch verification failed, but continuing..."
fi

# Build kernel modules
echo "[5/5] Building kernel modules..."
cd nvidia-driver/kernel
CC=gcc-9 make KERNEL_UNAME=$(uname -r)

echo ""
echo "=============================================="
echo "BUILD COMPLETE!"
echo "=============================================="
echo ""
echo "Built modules:"
ls -lh *.ko
echo ""
echo "To install, run:"
echo "  sudo $SCRIPT_DIR/install_driver.sh 10.2"
echo ""
echo "Or manually:"
echo "  sudo cp *.ko /lib/modules/\$(uname -r)/kernel/drivers/video/"
echo "  sudo depmod -a"
echo "  sudo modprobe nvidia"
