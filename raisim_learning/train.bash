#!/usr/bin/env bash
set -euo pipefail
[[ -s /root/.raisim/activation.raisim ]] || { echo 'Mount a valid RaiSim activation key using LICENSE_FILE.' >&2; exit 1; }
cd "${WORKSPACE:-/raisim_ws}/raisim2Lib/raisimGymTorch"
python - <<'PY'
import torch
assert torch.cuda.is_available(), 'CUDA is unavailable; check the host driver and GPU allocation.'
x = torch.ones(16, device='cuda')
assert (x @ x).item() == 16
print('Training GPU:', torch.cuda.get_device_name())
PY
exec python raisimGymTorch/env/envs/rsg_anymal/runner.py "$@"
