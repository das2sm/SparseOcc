---

# SparseOcc: Environment Setup & Workflow

This document assumes you have the `Dockerfile` in your project root directory (`/workspace/SparseOcc`).

## I. Initial Setup (One-Time Build)
Run these commands on your **host machine** (the server/PC where the 3090 is located) to build the environment and prepare the persistent container.

1.  **Build the Docker Image:**
    ```bash
    # Run this in the directory containing your Dockerfile
    sudo docker build -t sparseocc-env .
    ```

2.  **Verify Build:**
    Ensure the build completes without errors. Once finished, you will not need to perform this step again.

---

## II. Launching the Container (Every New Session)
To ensure your **compiled kernels** and **project progress** persist, always run the container by mapping your current directory to the container workspace.

1.  **Start the Container:**
    ```bash
    # Replace the volume path if your code is not in the current directory
    sudo docker run --gpus all -it --shm-size=16g \
      -v $(pwd):/workspace/SparseOcc \
      sparseocc-env /bin/bash
    ```

---

## III. Post-Reboot "Sync" Steps (Inside the Container)
Since your project relies on custom CUDA kernels that must be "seen" by Python, perform these checks **every time you start a new container session**:

1.  **Set the Python Path:**
    Ensure the interpreter can find your local code and the `models/` directory.
    ```bash
    export PYTHONPATH=$PYTHONPATH:/workspace/SparseOcc
    ```

2.  **Verify Kernel Compilation:**
    Because these kernels are in a mounted volume, they *should* be compiled, but if they are missing or you cleaned the build, re-run the local compile:
    ```bash
    cd /workspace/SparseOcc/models/csrc
    python3 setup.py build_ext --inplace
    ```

3.  **Final Acid Test:**
    Run this command to confirm everything is linked correctly.
    ```bash
    cd /workspace/SparseOcc
    python3 -c "import torch; import models; print('\n3090 STATUS: READY\nENVIRONMENT: FULLY LOADED')"
    ```

---

## IV. Data Preparation (NuScenes)
If this is your first time in the container, link your dataset:

```bash
# Link your lab's data path to the container
mkdir -p /workspace/SparseOcc/data
ln -s /path/to/your/actual/nuscenes_data /workspace/SparseOcc/data/nuscenes

# Verify linking
ls /workspace/SparseOcc/data/nuscenes
```

---
