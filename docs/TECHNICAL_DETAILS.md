# Technical Details: CUDA 10.2 POWER8 Patch

## The Problem

NVIDIA's CUDA 10.2 driver (440.33.01) contains a CPU detection function that explicitly checks for POWER9 and rejects POWER8 systems. This is a soft block - the hardware is capable, but the driver refuses to load.

## The Function: `rm_get_cpu_type`

Located in the proprietary binary blob `nv-kernel.o_binary`, this function:

1. Reads the Processor Version Register (PVR)
2. Extracts the CPU family identifier
3. Compares against known POWER9 values
4. Returns success only for POWER9

### Disassembly (POWER8 Little Endian)

```asm
rm_get_cpu_type:
    ; ... prologue ...

    ; Read PVR value from kernel structure
    lwz     r10, 380(r9)        ; Load PVR

    ; Extract CPU family
    xoris   r9, r10, 40960      ; XOR with 0xA000

    ; Compare with POWER9 family (9)
    cmpwi   cr7, r9, 9          ; Is it POWER9?

    ; Original: Branch if equal (POWER9 only)
    beq     cr7, valid_cpu      ; ← THIS IS WHAT WE PATCH

    ; Fall through = invalid CPU
    li      r9, 0               ; Return 0 (invalid)
    ...

valid_cpu:
    li      r9, 1               ; Return 1 (valid)
    ...
```

## The Patch

We change the conditional branch (`beq`) to an unconditional branch (`b`):

| Instruction | Encoding | Meaning |
|-------------|----------|---------|
| `beq cr7, valid_cpu` | `41 9e 00 3c` | Branch if CR7 equal |
| `b valid_cpu` | `48 00 00 3c` | Branch always |

### Byte-Level Change

- **File**: `nv-kernel.o_binary`
- **Offset**: `0xa68af4` (may vary slightly by driver version)
- **Original**: `41 9e 00 3c`
- **Patched**: `48 00 00 3c`

Note: PowerPC is big-endian in instruction encoding, but ppc64le stores data little-endian. The file shows these bytes in little-endian order: `3c 00 9e 41` → `3c 00 00 48`.

## Why POWER8 Works

POWER8 and POWER9 share:
- Same ISA (Power ISA 3.0 backward compatible)
- Same VSX vector extensions
- Same memory coherency model
- Same PCIe interface for GPUs
- Both have NVLink support (1.0 vs 2.0)

The driver's GPU-facing code doesn't actually care whether it's running on POWER8 or POWER9. The check appears to be for:
1. Support boundary enforcement
2. Certification/validation scope
3. Business decisions

## Driver Version History

| Driver | CUDA | CPU Check | Notes |
|--------|------|-----------|-------|
| 440.33.01 | 10.2 | Present (`rm_get_cpu_type`) | Requires patch |
| 450.51.06 | 11.0 | Present | Likely needs patch |
| 470.42.01 | 11.4 | Unknown | Not tested |
| 520.61.05 | 11.8 | **Removed** | Works without patch |
| 525.85.12 | 12.0 | **Removed** | Works without patch |

NVIDIA removed the explicit CPU check sometime between driver 470 and 520.

## Verifying the Patch

After patching, disassemble to confirm:

```bash
powerpc64le-linux-gnu-objdump -d nv-kernel.o_binary | grep -A20 "rm_get_cpu_type"
```

You should see `b` instead of `beq` at the comparison point.

## Alternative Approaches Considered

1. **Environment variable override**: Not supported in this driver
2. **Kernel parameter**: No such option exists
3. **LD_PRELOAD hook**: Would need to intercept kernel module, not practical
4. **Rebuild from source**: Binary blob is closed-source

The binary patch is the most reliable method.

## PVR Values Reference

| CPU | PVR (hex) | Family (decimal) |
|-----|-----------|------------------|
| POWER7 | 0x003F | 63 |
| POWER8 | 0x004B | 75 |
| POWER8E | 0x004C | 76 |
| POWER8NVL | 0x004C | 76 |
| POWER9 | 0x004E | 78 (passes as family 9 after XOR) |

The XOR with 0xA000 and comparison with 9 is specifically designed to match POWER9's characteristics.
