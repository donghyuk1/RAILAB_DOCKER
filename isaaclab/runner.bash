#!/usr/bin/env bash
set -euo pipefail
if [[ ${1:-} == --help ]]; then
    cat <<'HELP'
Usage: ACCEPT_EULA=Y ./runner.bash [COMMAND [ARG...]]
Default command: bash. Set GPUS=0 or GPUS=0,1 to select allocated host GPUs.
Settings:
  IMAGE_NAME, CONTAINER_NAME  Override the image and container name
  WORKSPACE_VOLUME           Defaults to $CONTAINER_NAME-workspace
  CODEX_VOLUME               Defaults to $CONTAINER_NAME-codex
  CACHE_PREFIX               Defaults to $CONTAINER_NAME
  SHM_SIZE                   8g by default
  TB_PORT, BIND_IP            Host TensorBoard port (6006), bind IP (127.0.0.1)
  DETACH=1                   Background command; keep container after exit
  NUM_ENVS, NUM_GPUS, TASK    Passed to training helpers when set
  WANDB_MODE                 offline by default; WANDB_API_KEY passed only if set
Commands use Isaac Sim Python through isaac-python. See README.md for examples.
HELP
    exit 0
fi
[[ ${ACCEPT_EULA:-} == Y ]] || { echo 'Review the NVIDIA Isaac Sim license, then set ACCEPT_EULA=Y (see README.md).' >&2; exit 1; }
command -v docker >/dev/null || { echo 'Install Docker on the server first.' >&2; exit 1; }
image=${IMAGE_NAME:-railab/isaaclab:2.3.2-codex}
name=${CONTAINER_NAME:-isaaclab-${USER:-user}}
cache=${CACHE_PREFIX:-$name}
gpus=${GPUS:-0}
if [[ $gpus != all ]]; then gpus="\"device=$gpus\""; fi
args=(run --init --name "$name" --gpus "$gpus" --shm-size "${SHM_SIZE:-8g}"
    --env ACCEPT_EULA=Y --env OMNI_KIT_ALLOW_ROOT=1
    --env NVIDIA_DRIVER_CAPABILITIES=compute,utility,graphics,display
    --env "WANDB_MODE=${WANDB_MODE:-offline}"
    --mount "type=volume,src=${WORKSPACE_VOLUME:-$name-workspace},dst=/workspace"
    --mount "type=volume,src=${CODEX_VOLUME:-$name-codex},dst=/root/.codex"
    --mount "type=volume,src=$cache-cache,dst=/root/.cache"
    --mount "type=volume,src=$cache-kit-cache,dst=/isaac-sim/kit/cache"
    --mount "type=volume,src=$cache-compute-cache,dst=/root/.nv/ComputeCache"
    --mount "type=volume,src=$cache-sim-logs,dst=/root/.nvidia-omniverse/logs"
    --mount "type=volume,src=$cache-kit-logs,dst=/isaac-sim/kit/logs"
    --mount "type=volume,src=$cache-sim-data,dst=/root/.local/share/ov/data"
    --publish "${BIND_IP:-127.0.0.1}:${TB_PORT:-6006}:6006")
for setting in NUM_ENVS NUM_GPUS TASK WANDB_API_KEY WANDB_PROJECT WANDB_ENTITY; do
    if [[ -v $setting ]]; then args+=(--env "$setting"); fi
done
if [[ ${DETACH:-0} == 1 ]]; then
    (($#)) || { echo 'DETACH=1 requires a command.' >&2; exit 1; }
    args+=(-d)
else
    args+=(--rm -i)
    if [[ -t 0 && -t 1 ]]; then args+=(-t); fi
fi
if (($# == 0)); then set -- bash; fi
exec docker "${args[@]}" "$image" "$@"
