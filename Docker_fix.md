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
    # Replace nuscenes path with actual path
    sudo docker run --gpus all -it --shm-size=16g \
        -v $(pwd):/workspace/SparseOcc \
        -v /media/ace428/d0868705-3e72-4ad4-b84b-7e73f1dee3e5/nuscenes:/workspace/SparseOcc/data/nuscenes \
        sparseocc-env /bin/bash
    ```

---

## III. Post-Reboot "Sync" Steps (Inside the Container)

1.  **Final Acid Test:**
    Run this command to confirm everything is linked correctly.
    ```bash
    cd /workspace/SparseOcc
    python3 -c "import torch; import models; print('\n3090 STATUS: READY\nENVIRONMENT: FULLY LOADED')"
    ```

---
