#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
command -v docker >/dev/null || { echo 'Docker is required on the host.' >&2; exit 1; }
exec docker build --tag "${IMAGE_NAME:-railab/raisim2-learning:cu118}" "$@" "$script_dir"
