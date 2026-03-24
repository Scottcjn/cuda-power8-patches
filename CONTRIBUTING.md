# Contributing to CUDA POWER8 Patches

Thank you for your interest in bringing NVIDIA CUDA support to IBM POWER8 systems! This project enables CUDA 10.2, 11.8, and 12.0 on POWER8 (S822, S824, etc.) with V100 GPUs.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Environment](#development-environment)
- [How to Contribute](#how-to-contribute)
- [Patch Development](#patch-development)
- [Testing](#testing)
- [Documentation](#documentation)
- [Pull Request Process](#pull-request-process)
- [Community](#community)

## Code of Conduct

We are committed to providing a welcoming and inspiring community for all. Be respectful, constructive, and helpful in all interactions.

## Getting Started

### Prerequisites

**Required Hardware** (one of):
- IBM Power System S822, S824, or S821 (any POWER8 model)
- NVIDIA Tesla V100 GPU (SXM2 or PCIe)
- OCuLink adapter (for SXM2) or direct PCIe connection

**Software Requirements**:
- Ubuntu 20.04 LTS ppc64le (recommended)
- RHEL 8 ppc64le (alternative)
- Root access for driver installation

**Development Tools**:
```bash
sudo apt-get update
sudo apt-get install build-essential git cmake ninja-build
sudo apt-get install nvidia-driver-525  # or appropriate version
```

### Repository Structure

```
cuda-power8-patches/
├── patches/              # Binary patches for CUDA drivers
│   ├── cuda-10.2/       # CUDA 10.2 specific patches
│   ├── driver-440/      # Driver 440.x patches
│   └── common/          # Shared patch utilities
├── scripts/             # Build and installation scripts
│   ├── build_cuda_11.8.sh
│   ├── build_cuda_12.0.1.sh
│   └── install_driver.sh
├── docs/                # Documentation
│   ├── BCOS.md          # BCOS certification
│   ├── HARDWARE.md      # Tested hardware list
│   └── TROUBLESHOOTING.md
├── tests/               # Validation tests
└── README.md
```

## Development Environment

### Physical POWER8 System

**Recommended Setup**:
```bash
# 1. Provision POWER8 system (IBM Cloud, on-premise, or shared access)
# 2. Install Ubuntu 20.04 ppc64le
# 3. Install base development tools

sudo apt-get install -y \
  build-essential git cmake ninja-build \
  python3 python3-pip \
  linux-headers-$(uname -r)

# 4. Clone repository
git clone https://github.com/YOUR_USERNAME/cuda-power8-patches.git
cd cuda-power8-patches

# 5. Run system check
./scripts/check_system.sh
```

### QEMU Emulation (Limited)

```bash
# For patch development only (no GPU access)
sudo apt-get install qemu-system-ppc qemu-user-static

# Create POWER8 VM
qemu-system-ppc64 \
  -machine power8 \
  -cpu power8 \
  -m 8192 \
  -smp 4 \
  -drive file=ubuntu-ppc64le.qcow2,format=qcow2 \
  -netdev user,id=net0 -device virtio-net-pci,netdev=net0
```

**Note**: QEMU cannot access physical GPUs. Use for patch/script development only.

### IBM Cloud POWER8 Instance

```bash
# Provision via IBM Cloud CLI
ibmcloud sl vs create \
  --hostname cuda-dev \
  --domain example.com \
  --cpu 8 \
  --memory 32768 \
  --os UBUNTU_20_64 \
  --datacenter dal13 \
  --flavor B1_8X32X100

# After provisioning, install CUDA prerequisites
ssh root@<instance-ip>
```

## How to Contribute

### Types of Contributions

- **New CUDA Version Support**: Patches for newer CUDA versions
- **Driver Patches**: Binary patches for different driver versions
- **Build Scripts**: Automation for different distributions
- **Documentation**: Guides, troubleshooting, hardware compatibility
- **Test Cases**: Validation scripts and benchmarks
- **Bug Fixes**: Fixes for existing patches

### Finding Work

Check our [GitHub Issues](../../issues) for:
- `good first issue` - Easy tasks for newcomers
- `help wanted` - Tasks needing community help
- `new cuda version` - Support for newer CUDA releases
- `documentation` - Docs and guides needed

### Contribution Workflow

1. **Fork** the repository on GitHub
2. **Clone** your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/cuda-power8-patches.git
   cd cuda-power8-patches
   ```
3. **Create a branch**:
   ```bash
   git checkout -b feature/cuda-12-2-support
   # or
   git checkout -b fix/driver-535-patch
   ```

## Patch Development

### Understanding CUDA Driver Structure

CUDA drivers are binary blobs that check CPU architecture:

```
Driver File Structure:
├── nvidia.ko          # Kernel module
├── nvidia-uvm.ko      # Unified Virtual Memory
├── libcuda.so         # CUDA runtime library
└── nvidia-smi         # System management interface
```

### Binary Patch Guidelines

1. **Patch Format**:
   ```
   patches/
   ├── cuda-<version>/
   │   ├── README.md          # Patch description
   │   ├── patch.sh           # Application script
   │   └── *.patch            # Binary diffs
   └── driver-<version>/
       └── ...
   ```

2. **Patch Documentation**:
   Every patch must include:
   - Target CUDA/driver version
- What CPU check is being bypassed
- Why it's safe (POWER8 vs POWER9 differences)
- Test results

3. **Example Patch Structure**:
   ```bash
   # patches/cuda-10.2/patch.sh
   #!/bin/bash
   # CUDA 10.2 POWER8 CPU Check Bypass
   # 
   # Target: NVIDIA driver 440.33.01
   # Location: nvidia.ko +0x123456
   # Change: JNZ (0x75) -> JMP (0xEB)
   # 
   # The driver checks for POWER9+ CPU architecture.
   # POWER8 is binary-compatible for CUDA 10.2 purposes.
   # 
   # Safety: Verified on S824 with V100-SXM2
   
   set -e
   DRIVER_PATH="$1"
   
   if [ -z "$DRIVER_PATH" ]; then
     echo "Usage: $0 <path/to/nvidia.ko>"
     exit 1
   fi
   
   # Apply patch at offset 0x123456
   printf '\xEB' | dd of="$DRIVER_PATH" bs=1 seek=$((0x123456)) conv=notrunc
   
   echo "Patch applied successfully"
   ```

### Finding CPU Check Locations

```bash
# 1. Download target driver
wget https://us.download.nvidia.com/tesla/440.33.01/NVIDIA-Linux-ppc64le-440.33.01.run

# 2. Extract
sh NVIDIA-Linux-ppc64le-440.33.01.run --extract-only
cd NVIDIA-Linux-ppc64le-440.33.01

# 3. Search for CPU check strings
grep -a "POWER9" nvidia.ko | head -5
strings nvidia.ko | grep -i "cpu\|power"

# 4. Disassemble (requires powerpc64le-linux-gnu-objdump)
powerpc64le-linux-gnu-objdump -d nvidia.ko | grep -A 10 -B 10 "cpu_check"

# 5. Identify branch instruction to patch
# Look for: beq, bne, bgt, etc. following CPU check
```

### Safety Requirements

Before submitting binary patches:

1. **Test on Real Hardware**: Patches must be tested on actual POWER8 + V100
2. **Verify No Side Effects**: Ensure patch only affects CPU check
3. **Document Risks**: Clearly state any potential issues
4. **Provide Rollback**: Include unpatch script

## Testing

### Pre-Submission Checklist

- [ ] Patch applies cleanly to target driver version
- [ ] Driver loads without errors: `sudo modprobe nvidia`
- [ ] CUDA samples compile: `cd /usr/local/cuda/samples && make`
- [ ] DeviceQuery works: `./deviceQuery` shows V100
- [ ] BandwidthTest passes: `./bandwidthTest`
- [ ] No kernel panics or instability after 24 hours

### Test Scripts

```bash
# Run full validation
./scripts/run_tests.sh

# Individual tests
./tests/test_driver_load.sh
./tests/test_cuda_runtime.sh
./tests/test_memory_bandwidth.sh
./tests/test_p2p_bandwidth.sh  # If multiple GPUs
```

### Benchmark Requirements

For performance-related patches:

```bash
# Run before/after benchmarks
cd /usr/local/cuda/samples/1_Utilities/bandwidthTest
make
./bandwidthTest --device=0 --mode=quick > before.txt

# Apply patch, rebuild driver, run again
./bandwidthTest --device=0 --mode=quick > after.txt

# Compare results - should be within 5% of expected V100 performance
```

### Hardware Compatibility Testing

Test matrix for new patches:

| Hardware | CUDA 10.2 |