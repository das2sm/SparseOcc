# SparseOcc Docker Setup Guide

## Why Docker Instead of Conda

SparseOcc's dependencies are a tangle of pinned versions from 2023 that conflict with a modern system
environment. Rather than fighting these conflicts on the host machine, Docker encapsulates the entire
legacy stack in an isolated container. The host system stays clean, and the environment is fully
reproducible.

---

## What the Dockerfile Fixes and Why

### Problem 1: Wrong Package Name for Lyft SDK
The original install command used `lyft_dataset_predata` which does not exist on PyPI.

**Fix:** Replace with the correct package name:
```dockerfile
pip3 install lyft-dataset-sdk nuscenes-devkit
```

### Problem 2: pillow-simd Build Failure
`pillow-simd` is a C extension that requires JPEG and zlib development headers to compile. The base
CUDA image does not include them by default.

**Fix:** Add build dependencies to the apt block and use a fallback in case pillow-simd still fails:
```dockerfile
# In apt-get install block, add:
libjpeg-dev zlib1g-dev

# In pip install, use fallback:
pip3 uninstall -y pillow && \
pip3 install pillow-simd==9.0.0.post1 || pip3 install pillow==9.5.0
```
The `||` operator means: try pillow-simd, and if it fails install regular pillow instead.
pillow-simd is faster but optional — regular pillow works fine for training.

### Problem 3: numba Version Does Not Exist
mmdet3d==1.0.0rc6 pins `numba==0.53.0` which does not exist on PyPI. The closest available versions
jump from 0.51.x to 0.55.x.

**Fix:** Pre-install a compatible numba version before mmdet3d, then install mmdet3d with `--no-deps`
to skip its broken dependency resolver:
```dockerfile
RUN pip3 install llvmlite==0.40.0 numba==0.57.0
RUN mim install mmdet3d==1.0.0rc6 --no-deps
```

### Problem 4: Volume Mount Path Was Literal
Running the container with `/path/to/SparseOcc` literally means the container sees an empty directory.

**Fix:** Always use the absolute path on your machine:
```bash
docker run --gpus all -it \
    -v /home/ace428/Soham/SparseOcc:/workspace/SparseOcc \
    -v /home/ace428/Soham/SparseOcc/data/nuscenes:/workspace/SparseOcc/data/nuscenes \
    sparseocc_env bash
```

### Problem 5: CUDA Extension Not Found After Build
Building with `python3 setup.py build_ext --inplace` places the `.so` file inside `models/csrc/`.
Python cannot find it when importing from the repo root.

**Fix:** Install the extension properly after building:
```bash
cd models/csrc
python3 setup.py build_ext --inplace
python3 setup.py install
```

---

## The Complete Working Dockerfile

```dockerfile
# Use CUDA 11.8 for legacy SparseOcc kernel compatibility
FROM nvidia/cuda:11.8.0-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV FORCE_CUDA=1
ENV CUDA_FORCE_PTX_JIT=1
ENV TORCH_CUDA_ARCH_LIST="8.0;8.6;9.0"

# System dependencies — includes libjpeg-dev and zlib1g-dev for pillow-simd
RUN apt-get update && apt-get install -y \
    git python3-pip python3-dev libgl1-mesa-glx libglib2.0-0 \
    libturbojpeg ninja-build wget \
    libjpeg-dev zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*

# Fix pip and setuptools for legacy builds
RUN pip3 install --upgrade pip==23.0.1
RUN pip3 install setuptools==59.5.0

# PyTorch with CUDA 11.8
RUN pip3 install torch==2.0.0+cu118 torchvision==0.15.1+cu118 \
    --extra-index-url https://download.pytorch.org/whl/cu118

# Pre-install numba at a version that exists on PyPI and supports Python 3.10
RUN pip3 install llvmlite==0.40.0 numba==0.57.0

# OpenMMLab stack — mmdet3d installed with --no-deps to skip broken numba pin
RUN pip3 install openmim && \
    mim install mmcv-full==1.6.0 && \
    mim install mmdet==2.28.2 && \
    mim install mmsegmentation==0.30.0 && \
    mim install mmdet3d==1.0.0rc6 --no-deps && \
    pip3 install lyft-dataset-sdk nuscenes-devkit

# Additional dependencies — pillow-simd with fallback to regular pillow
RUN pip3 install numpy==1.23.5 wandb terminaltables trimesh pyturbojpeg && \
    pip3 uninstall -y pillow && \
    pip3 install pillow-simd==9.0.0.post1 || pip3 install pillow==9.5.0

WORKDIR /workspace/SparseOcc
```

---

## How to Build and Run

### Build the image
```bash
cd /home/ace428/Soham/SparseOcc
docker build -t sparseocc_env .
```

### Run the container
```bash
docker run --gpus all -it \
    -v /home/ace428/Soham/SparseOcc:/workspace/SparseOcc \
    -v /home/ace428/Soham/SparseOcc/data/nuscenes:/workspace/SparseOcc/data/nuscenes \
    sparseocc_env bash
```

### Compile CUDA extensions (first time only, inside container)
```bash
cd /workspace/SparseOcc/models/csrc
python3 setup.py build_ext --inplace
python3 setup.py install
```

### Verify everything works
```bash
cd /workspace/SparseOcc
python3 -c "import torch; print(torch.__version__); print(torch.cuda.is_available())"
python3 -c "import mmdet3d; print(mmdet3d.__version__)"
python3 -c "import torch; import _msmv_sampling_cuda; print('SUCCESS')"
```

Expected output:
```
2.0.0+cu118
True
1.0.0rc6
SUCCESS
```

---

## Prepare Data (Before Training)

Make sure your data directory has this structure:
```
data/nuscenes/
├── maps/
├── samples/
├── sweeps/
├── v1.0-test/
├── v1.0-trainval/
├── nuscenes_infos_train_sweep.pkl
├── nuscenes_infos_val_sweep.pkl
├── nuscenes_infos_test_sweep.pkl
└── occ3d/
    ├── scene-0001/
    │   ├── 0037a705a2e04559b1bba6c01beca1cf/
    │   │   └── labels.npz
    ...
```

Download links:
- **pkl info files**: https://drive.google.com/file/d/1uyoUuSRIVScrm_CUpge6V_UzwDT61ODO/view
- **Occ3D ground truth**: https://drive.google.com/file/d/1kiXVNSEi3UrNERPMz_CfiJXKkgts_5dY/view

---

## Run Training (Inside Container)

```bash
# Single GPU
python3 train.py --config configs/sparseocc_r50_nuimg_704x256_8f.py

# Multi GPU (e.g. 4 GPUs)
torchrun --nproc_per_node 4 train.py --config configs/sparseocc_r50_nuimg_704x256_8f.py
```

---

## Key Lessons for Future Legacy Research Code

| Situation | What To Do |
|---|---|
| Package name not found on PyPI | Search PyPI directly — names often use `-` not `_` |
| Pinned dependency version doesn't exist | Install a nearby version first, then use `--no-deps` |
| C extension build fails | Check if dev headers are missing (`apt-get install lib*-dev`) |
| Module not found after building `.so` | Run `python3 setup.py install` after `build_ext --inplace` |
| Empty workspace in container | Check volume mount paths are absolute, not literal placeholders |
| CUDA arch mismatch | Set `TORCH_CUDA_ARCH_LIST` to match your GPU's compute capability |