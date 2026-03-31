#!/bin/bash
# run.sh - Start the container 
docker run --gpus all -it --shm-size=16g \
  --ulimit nofile=65535:65535 \
  -v $(pwd):/workspace/SparseOcc \
  -v /media/ace428/d0868705-3e72-4ad4-b84b-7e73f1dee3e5/nuscenes:/workspace/SparseOcc/data/nuscenes \
  sparseocc-env /bin/bash -c "cd /workspace/SparseOcc && python3 -c 'import models; print(\"✅ Environment Ready\")' && /bin/bash"