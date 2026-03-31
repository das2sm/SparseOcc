### **Technical Report: SparseOcc Baseline Environment & Validation**
**Project:** Closed-Loop Sparse Perception  
**Date:** March 31, 2026  
**Hardware:** NVIDIA GeForce RTX 3090 (24GB)  
**Status:** **Phase 0 (Baseline) Complete**

---

## 1. Environment & Infrastructure
* **Containerization:** Successfully configured a custom Docker environment (`sparseocc-final`) with a functional CUDA/C++ toolchain.
* **Custom Kernels:** Compiled and linked the `dvr.so` (Differentiable Volumetric Rendering) module, resolving initial library path conflicts.
* **Data Pipeline:** Integrated an external 2TB SSD mount for the **nuScenes** dataset, successfully generating and verifying `.pkl` metadata indices.
* **System Optimization:** Resolved "Too many open files" errors by increasing the system limit (`ulimit -n 65535`), ensuring stability for multi-worker data loading.

## 2. Performance Metrics (Verified)
The model was validated using the `r50_nuimg_704x256_8f` configuration (ResNet-50 backbone with 8-frame temporal fusion).

| Metric | Result | Benchmark Notes |
| :--- | :--- | :--- |
| **RayIoU (Mean)** | **0.3680** | Matches SOTA paper results (>0.30 is strong). |
| **Inference Speed** | **16.0 FPS** | ~62.5ms latency; highly viable for real-time control. |
| **Driveable Surface IoU** | **0.739 (@RayIoU@4)** | Excellent spatial accuracy for road segmentation. |
| **VRAM Usage** | **~12-16GB** | Well within the 24GB limit of the RTX 3090. |

## 3. Visualization & Artifacts
* **Output:** Generated Bird’s Eye View (BEV) semantic occupancy maps.
* **Classes:** Successfully segmenting 17 categories including vehicles, pedestrians, and drivable surfaces.
* **Artifacts:** Created a baseline video/image sequence (`sem_xxxx.jpg`) to serve as the "Before" comparison for the final August "Hero Video."

## 4. Key Takeaways for Research
The **16.0 FPS** result is the most critical find for the 5-month project. It proves that the sparse 3D perception backbone is fast enough to support a **10Hz - 15Hz control loop**, which is the industry standard for smooth autonomous navigation in simulation.

---

**Next Objective (April):** Transition to **SparseDrive** to integrate the Planning head and begin extracting trajectory waypoints for the May Control module.

**Would you like me to save this summary into a `NOTES.md` file in your workspace so you have it as a permanent record?**