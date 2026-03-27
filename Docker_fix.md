# SparseOcc Docker Setup Guide
## How to Build and Run

### Build the image
```bash
cd /home/ace428/Soham/SparseOcc
sudo docker build -t sparseocc_env .
```

### Run the container
```bash
sudo docker run --gpus all -it \
    -v /home/ace428/Soham/SparseOcc:/workspace/SparseOcc \
    -v /home/ace428/Soham/SparseOcc/data/nuscenes:/workspace/SparseOcc/data/nuscenes \
    sparseocc_env bash
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
