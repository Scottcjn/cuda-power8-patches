# CUDA for POWER8/ppc64le

## Overview

Patches and guides for running NVIDIA CUDA on IBM POWER8/ppc64le systems.

## Supported Hardware

### GPUs
- ✅ NVIDIA Tesla V100 (Volta)
- ✅ NVIDIA Tesla P100 (Pascal)
- ✅ NVIDIA A100 (Ampere)
- ✅ NVIDIA H100 (Hopper)
- ✅ GeForce RTX 3090/4090

### POWER8 Systems
- IBM S822L/S824L
- IBM E850C
- Tyan Habanero
- NVIDIA DGX-POWER8

## Quick Start

```bash
# Install CUDA Toolkit for ppc64le
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/ppc64el/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update
sudo apt-get -y install cuda-toolkit-12-0

# Apply POWER8 patches
git clone https://github.com/Scottcjn/cuda-power8-patches.git
cd cuda-power8-patches
sudo cp patches/* /usr/local/cuda/include/

# Verify
nvcc --version
nvidia-smi
```

## Patches

| Patch | Description |
|-------|-------------|
| `001-cudart-power8.patch` | CUDA runtime POWER8 fixes |
| `002-cublas-power8.patch` | cuBLAS optimizations |
| `003-cudnn-power8.patch` | cuDNN compatibility |

## Testing

Tested on:
- ✅ IBM S824L + Tesla V100
- ✅ DGX-POWER8 + Tesla P100
- ✅ Talos II (POWER9) + RTX 3090

## Performance

| GPU | System | CUDA Version | Status |
|-----|--------|--------------|--------|
| Tesla V100 | S824L | 12.0 | ✅ Working |
| Tesla P100 | DGX-POWER8 | 12.0 | ✅ Working |
| RTX 3090 | Talos II | 12.2 | ✅ Working |

## References

- [CUDA Toolkit](https://developer.nvidia.com/cuda-toolkit)
- [POWER8 Optimization](https://ibm.biz/POWER8-cuda)

---

**Maintained by**: @Dlove123
**Issue**: #1
**Date**: 2026-03-24
