#!/bin/bash
# Build CUDA 11.8 for POWER8 (NO PATCH REQUIRED!)
# NVIDIA removed the CPU check in driver 520+

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${WORK_DIR:-$HOME/cuda-power8-build}"
CUDA_VERSION="11.8"
DRIVER_VERSION="520.61.05"
CUDA_URL="https://developer.download.nvidia.com/compute/cuda/11.8.0/local_installers/cuda_11.8.0_520.61.05_linux_ppc64le.run"
CUDA_FILE="cuda_11.8.0_ppc64le.run"

echo "=============================================="
echo "CUDA 11.8 for POWER8 - Clean Build"
echo "(No patching required!)"
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
    echo "[1/4] Downloading CUDA $CUDA_VERSION (2.9 GB)..."
    wget -c "$CUDA_URL" -O "$CUDA_FILE"
else
    echo "[1/4] CUDA installer already downloaded"
fi

# Extract
echo "[2/4] Extracting CUDA installer..."
chmod +x "$CUDA_FILE"
rm -rf cuda_11.8_extracted
./"$CUDA_FILE" --target cuda_11.8_extracted --noexec

# Extract the driver
echo "[3/4] Extracting NVIDIA driver..."
cd cuda_11.8_extracted/builds
chmod +x NVIDIA-Linux-ppc64le-${DRIVER_VERSION}.run
./NVIDIA-Linux-ppc64le-${DRIVER_VERSION}.run --extract-only --target nvidia-driver-520

# Build kernel modules
echo "[4/4] Building kernel modules..."
cd nvidia-driver-520/kernel
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
echo "  sudo $SCRIPT_DIR/install_driver.sh 11.8"
