# ✅ SparseOcc Docker Environment Check

This guide verifies that your Docker environment is fully ready to run SparseOcc.

Run all commands **inside the container**.

---

# 1. GPU + CUDA Check

```bash
nvidia-smi
```

✅ Expected:

* GPU is visible (RTX 3090)
* No errors

---

# 2. PyTorch CUDA Check

```bash
python3 -c "import torch; print(torch.cuda.is_available()); print(torch.cuda.get_device_name(0))"
```

✅ Expected:

```
True
NVIDIA GeForce RTX 3090
```

---

# 3. MMCV Check

```bash
python3 -c "import mmcv; print(mmcv.__version__)"
```

✅ Expected:

```
1.6.0
```

---

# 4. MMCV CUDA Ops Check (CRITICAL)

```bash
python3 -c "from mmcv.ops import get_compiler_version; print(get_compiler_version())"
```

✅ Expected:

* Prints compiler version (e.g., GCC 11.x)
* No errors

---

# 5. Set PYTHONPATH

```bash
export PYTHONPATH=/workspace/SparseOcc
```

---

# 6. SparseOcc Module Import Check

```bash
python3 - <<EOF
import models
import loaders
import utils
print("SparseOcc core imports: OK")
EOF
```

✅ Expected:

```
SparseOcc core imports: OK
```

---

# 7. Full Sanity Check Script

```bash
python3 - <<EOF
import torch
print("CUDA:", torch.cuda.is_available())

import mmcv
print("MMCV:", mmcv.__version__)

from mmcv.ops import get_compiler_version
print("MMCV Ops: OK")

import models
import loaders
print("SparseOcc: OK")

print("=== ALL CHECKS PASSED ===")
EOF
```

---

# ✅ Final Criteria (ALL must pass)

* [ ] `nvidia-smi` works
* [ ] PyTorch detects GPU
* [ ] MMCV imports correctly
* [ ] MMCV CUDA ops work
* [ ] SparseOcc modules import

---

At this point, your environment is **fully ready for SparseOcc**.
