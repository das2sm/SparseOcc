# SparseOcc Docker Setup Guide
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
