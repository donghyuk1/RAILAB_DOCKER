#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
export IMAGE_NAME=${IMAGE_NAME:-railab/omnireset:isaaclab2-codex}
export CONTAINER_NAME=${CONTAINER_NAME:-omnireset-${USER:-user}}
exec "$script_dir/../isaaclab/runner.bash" "$@"
