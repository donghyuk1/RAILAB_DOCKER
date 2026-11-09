#!/usr/bin/env bash
set -euo pipefail
cd "${ISAACLAB_PATH:-/workspace/isaaclab}"
exec isaac-python scripts/reinforcement_learning/rsl_rl/train.py \
    --task "${TASK:-Isaac-Cartpole-v0}" --headless \
    --num_envs "${NUM_ENVS:-64}" --logger tensorboard "$@"
