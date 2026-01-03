# CUDA on IBM POWER8 - Unofficial Support

Run NVIDIA CUDA 10.2, 11.8, and 12.0 on IBM POWER8 systems (S822, S824, etc.) with V100 GPUs.

> **NVIDIA officially only supports POWER9 for V100 GPUs, but we found that CUDA 11.8+ works on POWER8 without modification, and CUDA 10.2 works with a simple binary patch.**

## Quick Summary

| CUDA Version | Driver | Patch Required | Status |
|--------------|--------|----------------|--------|
| **10.2.89** | 440.33.01 | **YES** - CPU check bypass | Working |
| **11.8.0** | 520.61.05 | **NO** | Working |
| **12.0.1** | 525.85.12 | **NO** | Working |

**Recommendation**: Use CUDA 12.0.1 for best compatibility and features.

## Hardware Tested

- IBM Power System S824 (8286-42A) - Dual 8-core POWER8, 576GB RAM
- IBM Power System S822 - Single 6-core POWER8
- NVIDIA Tesla V100-SXM2-16GB (via OCuLink adapter)
- Ubuntu 20.04 LTS (ppc64le)

## Installation

### For CUDA 11.8 or 12.0.1 (No Patch Required)

```bash
# Clone this repo
git clone https://github.com/YOUR_USERNAME/cuda-power8-patches.git
cd cuda-power8-patches

# Download and build (choose one):
./scripts/build_cuda_11.8.sh
# OR
./scripts/build_cuda_12.0.1.sh

# Install (after connecting GPU)
sudo ./scripts/install_driver.sh 12.0.1
```

### For CUDA 10.2 (Requires Patch)

```bash
# Download and patch
./scripts/build_cuda_10.2_patched.sh

# Install
sudo ./scripts/install_driver.sh 10.2
```

## What's the Patch?

CUDA 10.2's driver (440.33.01) contains a CPU check function `rm_get_cpu_type` that only accepts POWER9 (PVR family 0x4E). The patch changes a conditional branch to unconditional:

```
Original:  beq cr7, <valid_cpu>    ; Branch if POWER9
Patched:   b <valid_cpu>           ; Always branch (accept any POWER CPU)
```

**Technical Details:**
- File: `nv-kernel.o_binary` (proprietary blob)
- Function: `rm_get_cpu_type` at offset 0xa68ab0
- Patch offset: 0xa68af4
- Original bytes: `41 9e 00 3c` (beq)
- Patched bytes: `48 00 00 3c` (b)

NVIDIA removed this check in driver 520+, so CUDA 11.8 and 12.x work without modification.

## Why Does This Work?

POWER8 and POWER9 are architecturally similar enough that the GPU driver functions correctly on both. The CPU check was likely a business/support decision rather than a technical requirement.

Key compatibility factors:
- Same VSX/AltiVec SIMD extensions
- Same memory model and cache coherency
- Same PCIe interface
- IBM NVLink support on both (though POWER9 has NVLink 2.0)

## OCuLink GPU Connection

POWER8 systems don't have native PCIe slots suitable for modern GPUs, but you can use an OCuLink adapter to connect external GPUs:

1. Install OCuLink M.2 adapter in available slot
2. Connect V100 via OCuLink cable
3. GPU appears as standard PCIe device

## Build Requirements

- Ubuntu 20.04 LTS (ppc64le) - last version with POWER8 support
- GCC 9 (must match kernel compiler)
- Kernel headers: `apt install linux-headers-$(uname -r)`
- Build tools: `apt install build-essential`

## Files in This Repository

```
cuda-power8-patches/
├── README.md                 # This file
├── LICENSE                   # MIT License (for scripts/docs only)
├── patches/
│   └── cuda_10.2_power8.bin  # Binary patch for driver 440.33.01
├── scripts/
│   ├── build_cuda_10.2_patched.sh  # Download, patch, build CUDA 10.2
│   ├── build_cuda_11.8.sh          # Download and build CUDA 11.8
│   ├── build_cuda_12.0.1.sh        # Download and build CUDA 12.0.1
│   └── install_driver.sh           # Install built modules
└── docs/
    ├── TECHNICAL_DETAILS.md        # Deep dive into the patch
    └── TROUBLESHOOTING.md          # Common issues
```

## Legal Notice

**This repository does NOT contain any NVIDIA proprietary code.**

- The patch file contains only the byte differences, not the original binary
- All scripts download CUDA directly from NVIDIA's servers
- Users must accept NVIDIA's EULA when downloading
- The kernel wrapper code is MIT/GPL dual-licensed by NVIDIA

This is provided for educational and research purposes. Use at your own risk.

## Performance Notes

On POWER8 S824 with V100:
- CUDA compute works normally
- cuBLAS, cuDNN functional
- Some NVLink features may be limited (POWER8 has NVLink 1.0)

## Contributing

Found this useful? Tested on different hardware? Open an issue or PR!

## Credits

- Elyan Labs - Initial research and patches
- IBM POWER community
- Everyone running vintage iron

## Disclaimer

This is an unofficial community project. NVIDIA does not support POWER8 for V100 GPUs. If something breaks, you get to keep both pieces.
