# Troubleshooting CUDA on POWER8

## Build Issues

### "Compiler version check failed"

```
The major and minor number of the compiler used to compile the kernel:
gcc version 9.4.0
does not match the compiler used here:
gcc version 10.5.0
```

**Solution**: Use GCC 9 to match the kernel:
```bash
sudo apt install gcc-9
CC=gcc-9 make KERNEL_UNAME=$(uname -r)
```

### "No rule to make target"

The kernel headers are missing.

**Solution**:
```bash
sudo apt install linux-headers-$(uname -r)
```

### Build succeeds but module won't load

Check `dmesg` for errors:
```bash
sudo modprobe nvidia
dmesg | tail -20
```

## Runtime Issues

### "NVRM: No NVIDIA GPU found"

1. Check if GPU is visible to system:
   ```bash
   lspci | grep -i nvidia
   ```

2. If using OCuLink, ensure:
   - Cable is properly connected
   - GPU has external power
   - System was rebooted after connecting

### "nvidia-smi: command not found"

The userspace tools weren't installed:
```bash
sudo cp /path/to/nvidia-driver/nvidia-smi /usr/bin/
sudo chmod +x /usr/bin/nvidia-smi
```

### "NVIDIA-SMI has failed... driver/library version mismatch"

Kernel module version doesn't match userspace library:

```bash
# Check loaded module version
cat /proc/driver/nvidia/version

# Ensure libraries match
ls -la /usr/lib/powerpc64le-linux-gnu/libcuda.so*
```

Reinstall with matching versions.

### GPU detected but shows "ERR!" in nvidia-smi

Power or thermal issue. Check:
- GPU power cables connected
- Adequate cooling/airflow
- `dmesg` for PCIe errors

## OCuLink Specific Issues

### GPU not detected after connecting

OCuLink is NOT hot-plug on most systems. You must:
1. Power off system completely
2. Connect GPU via OCuLink
3. Power on system
4. GPU should appear in `lspci`

### PCIe errors in dmesg

```
pcieport: AER: Corrected error received
```

Try:
- Different OCuLink cable
- Reseating the M.2 adapter
- BIOS/firmware update

## POWER8-Specific Notes

### NVLink limitations

POWER8 has NVLink 1.0, while V100 supports NVLink 2.0. The GPU will work but:
- NVLink peer-to-peer may be limited
- Some advanced memory features may not work
- PCIe communication works normally

### Memory considerations

POWER8's large memory (up to 1TB+) is great for:
- Loading large models
- Multi-GPU setups
- Data preprocessing

But the GPU's own memory is unchanged (16GB for V100-SXM2).

## Getting Help

1. Check `dmesg` output
2. Check `/var/log/syslog`
3. Run `nvidia-bug-report.sh` (included with driver)
4. Open an issue with full logs
