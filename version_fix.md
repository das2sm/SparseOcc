# SparseOcc on RTX 5070 Ti (Blackwell) — 2026 Setup Guide

## Why the Original Setup Breaks

SparseOcc was written in 2023 for PyTorch 2.0 and CUDA 11.8. Running it on an RTX 5070 Ti in 2026 breaks for three distinct reasons:

### 1. Architecture Gap
The RTX 5070 Ti uses the **Blackwell architecture (sm_120)**. CUDA 11.8 has no knowledge of this GPU — it predates Blackwell entirely. Attempting to compile CUDA kernels with CUDA 11.8 on this card will fail because the compiler cannot generate code for sm_120.

### 2. The CCCL Header Relocation
Between 2023 and 2025/2026, NVIDIA reorganized how CUDA is packaged. Core C++ headers (including `nv/target`) were moved into a dedicated sub-package called `cuda-cccl`. The original SparseOcc build script was written before this change and cannot find these headers, causing a cascade of 100+ compiler errors starting with:
```
fatal error: nv/target: No such file or directory
```

### 3. GCC Compatibility
The SparseOcc CUDA extensions were written for older GCC versions. While CUDA 12.8 officially supports GCC 14, the SparseOcc C++ extension code itself has compatibility issues with GCC 13/14. Using GCC 11 inside the Conda environment is the safe and stable choice for building this specific codebase.

> **Note:** The GCC issue here is a **codebase compatibility** problem, not a CUDA restriction. CUDA 12.8 itself supports GCC 14 — it is the SparseOcc source code that does not.

---

## The Fix: The 2026 Blackwell Stack

### Step A: Create a Fresh Environment with the Modern Stack

```bash
# Create and activate a fresh environment
conda create -n sparseocc python=3.10 -y
conda activate sparseocc

# Install the 2026 Blackwell-ready CUDA Toolkit and Compiler
conda install -c nvidia cuda-toolkit=12.8 cuda-nvcc=12.8 cuda-cccl=12.8 -y

# Install PyTorch with native CUDA 12.8 support
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

# Install a GCC 11 compiler inside Conda (avoids SparseOcc source compatibility issues)
conda install -c conda-forge gxx_linux-64=11 gcc_linux-64=11 -y
```

### Step B: Install Dependencies and Fix the CCCL Headers

```bash
pip install openmim ninja setuptools==59.5.0 numpy==1.23.5
mim install mmcv-full==1.6.0
mim install mmdet==2.28.2
mim install mmsegmentation==0.30.0
mim install mmdet3d==1.0.0rc6

# Optional but recommended for faster data loading
sudo apt-get update && sudo apt-get install -y libturbojpeg
pip install pyturbojpeg
pip uninstall -y pillow
pip install pillow-simd==9.0.0.post1
```

The `cuda-cccl=12.8` installed in Step A provides the relocated headers. The `CPATH` export in Step D tells the compiler exactly where to find them.

### Step C: Why GCC 11

GCC 11 is used because:
- It is well within the range CUDA 12.8 supports
- The SparseOcc C++ extension source is compatible with it
- It avoids subtle ABI and template resolution issues present in GCC 13/14 with this specific codebase

By setting `CC` and `CXX` to point to the Conda GCC 11 binaries, the build script uses this compiler instead of the system default.

### Step D: Build the CUDA Extensions for sm_120

```bash
cd models/csrc
rm -rf build/

# 1. Force use of the compatible GCC 11 compiler
export CC=$CONDA_PREFIX/bin/x86_64-conda-linux-gnu-gcc
export CXX=$CONDA_PREFIX/bin/x86_64-conda-linux-gnu-g++

# 2. Map the relocated CUDA headers (fixes the nv/target error)
export CUDA_HOME=$CONDA_PREFIX
export PATH=$CONDA_PREFIX/bin:$PATH
export CPATH="$CONDA_PREFIX/include:$CONDA_PREFIX/targets/x86_64-linux/include:$CPATH"

# 3. Target the RTX 5070 Ti specifically (Blackwell = sm_120)
export TORCH_CUDA_ARCH_LIST="12.0"
export FORCE_CUDA=1

# 4. Build and install in editable mode
pip install --no-build-isolation .
```

`TORCH_CUDA_ARCH_LIST="12.0"` tells the compiler to build specifically for Blackwell rather than attempting to auto-detect or compile for all architectures. This ensures the sparse convolution kernels are optimized for the Tensor Cores in the RTX 5070 Ti.

---

## Verify the Installation

```bash
python -c "import torch; import _msmv_sampling_cuda; print('SUCCESS: SparseOcc is running on Blackwell (5070 Ti)')"
```

---

## Summary of Root Causes and Fixes

| Problem | Root Cause | Fix |
|---|---|---|
| CUDA 11.8 doesn't know sm_120 | Blackwell postdates CUDA 11.8 | Upgrade to CUDA 12.8 + PyTorch cu128 |
| `nv/target: No such file or directory` | CUDA headers relocated to cuda-cccl package | Install cuda-cccl=12.8, set CPATH |
| SparseOcc C++ source incompatibility | Source written for older GCC | Install GCC 11 in Conda, set CC/CXX |
| Wrong GPU kernels compiled | Default arch list doesn't include sm_120 | Set TORCH_CUDA_ARCH_LIST="12.0" |