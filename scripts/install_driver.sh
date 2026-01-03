#!/bin/bash
# Install NVIDIA driver modules built for POWER8
# Usage: sudo ./install_driver.sh <version>
# Example: sudo ./install_driver.sh 12.0.1

set -e

WORK_DIR="${WORK_DIR:-$HOME/cuda-power8-build}"

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run as root"
    echo "Usage: sudo $0 <version>"
    echo "Example: sudo $0 12.0.1"
    exit 1
fi

VERSION="$1"
if [ -z "$VERSION" ]; then
    echo "Usage: sudo $0 <version>"
    echo "Available versions: 10.2, 11.8, 12.0.1"
    exit 1
fi

# Determine paths based on version
case "$VERSION" in
    "10.2")
        DRIVER_DIR="$WORK_DIR/cuda_extracted/builds/nvidia-driver/kernel"
        DRIVER_VER="440.33.01"
        LIB_DIR="$WORK_DIR/cuda_extracted/builds/nvidia-driver"
        ;;
    "11.8")
        DRIVER_DIR="$WORK_DIR/cuda_11.8_extracted/builds/nvidia-driver-520/kernel"
        DRIVER_VER="520.61.05"
        LIB_DIR="$WORK_DIR/cuda_11.8_extracted/builds/nvidia-driver-520"
        ;;
    "12.0.1")
        DRIVER_DIR="$WORK_DIR/cuda_12.0.1_extracted/builds/nvidia-driver-525/kernel"
        DRIVER_VER="525.85.12"
        LIB_DIR="$WORK_DIR/cuda_12.0.1_extracted/builds/nvidia-driver-525"
        ;;
    *)
        echo "ERROR: Unknown version '$VERSION'"
        echo "Available versions: 10.2, 11.8, 12.0.1"
        exit 1
        ;;
esac

if [ ! -d "$DRIVER_DIR" ]; then
    echo "ERROR: Driver directory not found: $DRIVER_DIR"
    echo "Did you run the build script first?"
    exit 1
fi

echo "=============================================="
echo "Installing NVIDIA Driver $DRIVER_VER"
echo "=============================================="
echo ""

# Unload existing modules
echo "[1/5] Unloading existing NVIDIA modules..."
for mod in nvidia-drm nvidia-modeset nvidia-uvm nvidia-peermem nvidia; do
    if lsmod | grep -q "^$mod "; then
        echo "  Unloading $mod..."
        modprobe -r $mod 2>/dev/null || true
    fi
done

# Copy kernel modules
echo "[2/5] Installing kernel modules..."
DEST="/lib/modules/$(uname -r)/kernel/drivers/video"
mkdir -p "$DEST"

for ko in nvidia.ko nvidia-drm.ko nvidia-modeset.ko nvidia-uvm.ko nvidia-peermem.ko; do
    if [ -f "$DRIVER_DIR/$ko" ]; then
        cp "$DRIVER_DIR/$ko" "$DEST/"
        echo "  Installed $ko"
    fi
done

# Update module dependencies
echo "[3/5] Updating module dependencies..."
depmod -a

# Install userspace libraries
echo "[4/5] Installing userspace libraries..."
LIB_DEST="/usr/lib/powerpc64le-linux-gnu"

if [ -f "$LIB_DIR/libcuda.so.$DRIVER_VER" ]; then
    cp "$LIB_DIR/libcuda.so.$DRIVER_VER" "$LIB_DEST/"
    ln -sf "libcuda.so.$DRIVER_VER" "$LIB_DEST/libcuda.so.1"
    ln -sf "libcuda.so.1" "$LIB_DEST/libcuda.so"
fi

if [ -f "$LIB_DIR/libnvidia-ml.so.$DRIVER_VER" ]; then
    cp "$LIB_DIR/libnvidia-ml.so.$DRIVER_VER" "$LIB_DEST/"
    ln -sf "libnvidia-ml.so.$DRIVER_VER" "$LIB_DEST/libnvidia-ml.so.1"
    ln -sf "libnvidia-ml.so.1" "$LIB_DEST/libnvidia-ml.so"
fi

if [ -f "$LIB_DIR/libnvidia-ptxjitcompiler.so.$DRIVER_VER" ]; then
    cp "$LIB_DIR/libnvidia-ptxjitcompiler.so.$DRIVER_VER" "$LIB_DEST/"
fi

if [ -f "$LIB_DIR/nvidia-smi" ]; then
    cp "$LIB_DIR/nvidia-smi" /usr/bin/
    chmod +x /usr/bin/nvidia-smi
fi

# Update library cache
echo "[5/5] Updating library cache..."
ldconfig

echo ""
echo "=============================================="
echo "INSTALLATION COMPLETE!"
echo "=============================================="
echo ""
echo "Driver version: $DRIVER_VER"
echo "Kernel modules installed to: $DEST"
echo ""
echo "To load the driver:"
echo "  sudo modprobe nvidia"
echo ""
echo "To verify:"
echo "  nvidia-smi"
echo ""
echo "NOTE: GPU must be connected before loading the driver."
