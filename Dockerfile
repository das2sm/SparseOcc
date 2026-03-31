FROM nvidia/cuda:11.8.0-devel-ubuntu22.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    git wget curl python3-pip python3-dev \
    libgl1-mesa-glx libglib2.0-0 ninja-build build-essential \
    libgeos-dev libjpeg-dev zlib1g-dev libturbojpeg \
    && rm -rf /var/lib/apt/lists/*

ENV CUDA_HOME=/usr/local/cuda
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}
ENV TORCH_CUDA_ARCH_LIST="8.6"
ENV FORCE_CUDA="1"

RUN pip3 install --upgrade pip
RUN pip3 install setuptools==60.2.0 wheel==0.45.1

RUN pip3 install torch==2.0.0+cu118 torchvision==0.15.1+cu118 \
    --extra-index-url https://download.pytorch.org/whl/cu118

RUN git clone https://github.com/open-mmlab/mmcv.git /mmcv && \
    cd /mmcv && \
    git checkout v1.6.0 && \
    MMCV_WITH_OPS=1 FORCE_CUDA=1 TORCH_CUDA_ARCH_LIST="8.6" \
    pip3 install --no-build-isolation . && \
    cd / && rm -rf /mmcv

RUN pip3 install openmim && \
    mim install mmdet==2.28.2 --no-build-isolation && \
    mim install mmsegmentation==0.30.0 --no-build-isolation

RUN pip3 install \
    lyft-dataset-sdk nuscenes-devkit terminaltables \
    trimesh==4.11.5 numba==0.57.0 numpy==1.23.5 \
    PyYAML>=6.0 shapely plyfile scikit-image "networkx<3.0"

RUN pip3 install mmdet3d==1.0.0rc6 --no-deps --no-build-isolation

RUN pip3 install tensorboard wandb pyturbojpeg==1.7.1 && \
    pip3 uninstall -y pillow && \
    pip3 install pillow-simd==9.0.0.post1 || pip3 install pillow==9.5.0

RUN pip3 install "numpy<1.24" numba==0.57.0 --force-reinstall

WORKDIR /workspace/SparseOcc