# Use CUDA 11.8 for legacy SparseOcc kernel compatibility
FROM nvidia/cuda:11.8.0-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV FORCE_CUDA=1
ENV CUDA_FORCE_PTX_JIT=1
ENV TORCH_CUDA_ARCH_LIST="8.0;8.6;9.0"

RUN apt-get update && apt-get install -y \
    git python3-pip python3-dev libgl1-mesa-glx libglib2.0-0 \
    libturbojpeg ninja-build wget \
    libjpeg-dev zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*

RUN pip3 install --upgrade pip==23.0.1
RUN pip3 install setuptools==59.5.0

RUN pip3 install torch==2.0.0+cu118 torchvision==0.15.1+cu118 \
    --extra-index-url https://download.pytorch.org/whl/cu118

RUN pip3 install llvmlite==0.40.0 numba==0.57.0

RUN pip3 install openmim && \
    mim install mmcv-full==1.6.0 && \
    mim install mmdet==2.28.2 && \
    mim install mmsegmentation==0.30.0 && \
    mim install mmdet3d==1.0.0rc6 --no-deps && \
    pip3 install lyft-dataset-sdk nuscenes-devkit

RUN pip3 install numpy==1.23.5 wandb terminaltables trimesh tensorboard && \
    pip3 install pyturbojpeg==1.7.1 && \
    pip3 uninstall -y pillow && \
    pip3 install pillow-simd==9.0.0.post1 || pip3 install pillow==9.5.0

WORKDIR /workspace/SparseOcc