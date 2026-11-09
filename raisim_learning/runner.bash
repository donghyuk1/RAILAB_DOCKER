#!/usr/bin/env bash
# Every invocation creates a container; source, checkpoints and Codex state persist.
set -euo pipefail
if [[ ${1:-} == --help ]]; then
    cat <<'HELP'
Usage: ./runner.bash [COMMAND [ARG...]]
Default: interactive bash. Use ./runner.bash raisim-train to train ANYmal.
Settings (environment variables):
  IMAGE_NAME       railab/raisim2-learning:cu118
  CONTAINER_NAME   raisim2-$USER
  GPUS             all (or a GPU index / comma-separated indices)
  LICENSE_FILE     $HOME/.raisim/activation.raisim (optional for shell; required for training)
  WORKSPACE_VOLUME $CONTAINER_NAME-workspace
  CODEX_VOLUME     $CONTAINER_NAME-codex
  BIND_IP          127.0.0.1
  TB_PORT          6006 on host, forwarded to container 6006
  VIEWER_PORT      8080 on host, forwarded to container 8080
  SHM_SIZE         2g
  DETACH           1 for background jobs (container kept after exit)
HELP
    exit 0
fi
command -v docker >/dev/null || { echo 'Docker is required on the host.' >&2; exit 1; }
image=${IMAGE_NAME:-railab/raisim2-learning:cu118}
name=${CONTAINER_NAME:-raisim2-${USER:-user}}
license=${LICENSE_FILE:-$HOME/.raisim/activation.raisim}
# Accept the single-file location used by the previous server instructions.
if [[ -z ${LICENSE_FILE:-} && -f $HOME/.raisim ]]; then license=$HOME/.raisim; fi
gpus=${GPUS:-all}
if [[ $gpus != all ]]; then
    # Docker parses --gpus as CSV; quote the complete device field for lists.
    gpus="\"device=$gpus\""
fi
args=(run --init --name "$name" --gpus "$gpus" --shm-size "${SHM_SIZE:-2g}"
    --mount "type=volume,src=${WORKSPACE_VOLUME:-$name-workspace},dst=/raisim_ws"
    --mount "type=volume,src=${CODEX_VOLUME:-$name-codex},dst=/root/.codex"
    --publish "${BIND_IP:-127.0.0.1}:${TB_PORT:-6006}:6006"
    --publish "${BIND_IP:-127.0.0.1}:${VIEWER_PORT:-8080}:8080")
if [[ -f $license && -r $license ]]; then
    license=$(realpath -- "$license")
    args+=(--mount "type=bind,src=$license,dst=/root/.raisim/activation.raisim,readonly")
elif [[ -n ${LICENSE_FILE:-} ]]; then
    echo "LICENSE_FILE must be a readable activation-key file: $license" >&2
    exit 1
else
    echo 'No ~/.raisim/activation.raisim key found; training will require a valid key.' >&2
fi
if [[ ${DETACH:-0} == 1 ]]; then
    (($#)) || { echo 'DETACH=1 requires a command, e.g. raisim-train.' >&2; exit 1; }
    args+=(-d)
else
    args+=(--rm -i)
    if [[ -t 0 && -t 1 ]]; then args+=(-t); fi
fi
if (($# == 0)); then set -- bash; fi
exec docker "${args[@]}" "$image" "$@"
