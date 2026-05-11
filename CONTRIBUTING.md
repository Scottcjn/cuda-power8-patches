# Contributing to CUDA POWER8 Patches

Thanks for helping improve CUDA POWER8 Patches. This repository is a small,
hardware-focused project for documenting and testing CUDA driver builds on IBM
POWER8 systems, so clear reproduction notes and careful legal boundaries matter.

## Getting Started

1. Fork the repository and clone your fork:

   ```bash
   git clone https://github.com/YOUR_USERNAME/cuda-power8-patches.git
   cd cuda-power8-patches
   ```

2. Create a focused branch:

   ```bash
   git checkout -b fix/short-description
   ```

3. Read the project overview before editing:

   - `README.md` for supported CUDA versions, tested hardware, and usage notes
   - `docs/TECHNICAL_DETAILS.md` for patch details
   - `docs/TROUBLESHOOTING.md` for common installation problems
   - `scripts/` for build and install helpers

## Good Contribution Areas

Useful contributions include:

- confirming CUDA 10.2, 11.8, or 12.0.1 behavior on additional POWER8 systems
- improving setup or troubleshooting documentation
- fixing broken links, typos, or unclear steps
- making shell scripts safer or easier to audit
- adding checks that catch common environment or dependency problems
- documenting GPU, adapter, kernel, driver, and Ubuntu version combinations

Please keep each pull request focused on one type of change. For example, avoid
mixing a script change with unrelated README cleanup.

## Legal Boundaries

Do not commit NVIDIA proprietary files, downloaded CUDA installers, extracted
driver objects, kernel module build outputs, or generated binaries. The repository
should contain only source files, documentation, scripts, and small patch data
that can be redistributed.

If your change depends on a proprietary download, document how to obtain it from
the vendor rather than adding it to the repository.

## Script Changes

For shell script updates:

- use POSIX shell or Bash consistently with the existing script
- quote variables unless word splitting is required
- fail clearly when required commands, files, or kernel headers are missing
- keep hardware-specific assumptions visible in comments or messages
- avoid destructive commands unless they are already part of the documented
  install flow and are guarded by clear checks

When you change a shell script, normalize line endings if needed and test that
script's syntax locally:

```bash
bash -n scripts/path-to-script.sh
```

If `shellcheck` is available, run it on touched scripts and mention any justified
warnings in the pull request.

## Documentation Changes

For documentation updates:

- keep commands copy-pasteable
- include exact OS, kernel, CUDA, and NVIDIA driver versions when reporting
  compatibility
- describe hardware with enough detail to reproduce the setup
- update troubleshooting notes when a fix is specific to one CUDA or driver
  version
- prefer links to official vendor or project documentation when available

## Validation

Run the checks that fit your change:

```bash
git diff --check
bash -n scripts/path-to-script.sh  # for any shell script you changed
```

Hardware validation is not always possible. If you cannot run a build or install
on POWER8 hardware, say that clearly in the pull request and list the checks you
did run.

For successful hardware tests, include:

- system model and CPU
- GPU model and connection method
- Linux distribution and kernel version
- CUDA and NVIDIA driver version
- command output or logs that demonstrate the result

## Pull Request Checklist

Before opening a pull request, confirm that:

- the change is limited to the intended files
- no proprietary NVIDIA artifacts or generated build outputs are included
- documentation and commands match the current repository layout
- `git diff --check` passes
- shell script syntax checks pass for touched scripts, when applicable
- the pull request explains what was tested and what could not be tested

## Reporting Issues

When opening an issue, include the hardware, OS, kernel, CUDA, driver, and exact
command that failed. Paste only the relevant log excerpt and remove secrets,
hostnames, or unrelated local paths.

For compatibility reports, include whether the result was a clean build, a driver
load, CUDA sample execution, or another milestone.
