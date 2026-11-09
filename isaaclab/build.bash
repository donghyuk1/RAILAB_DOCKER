#!/usr/bin/env bash
set -euo pipefail
if [[ ${1:-} == --help ]]; then
    echo 'Usage: ACCEPT_EULA=Y ./build.bash [docker build options]'
    echo 'IMAGE_NAME defaults to railab/isaaclab:2.3.2-codex; CODEX_VERSION defaults to latest.'
    exit 0
fi
[[ ${ACCEPT_EULA:-} == Y ]] || { echo 'Review the NVIDIA Isaac Sim license, then set ACCEPT_EULA=Y (see README.md).' >&2; exit 1; }
command -v docker >/dev/null || { echo 'Install Docker on the server first.' >&2; exit 1; }
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
exec docker build --tag "${IMAGE_NAME:-railab/isaaclab:2.3.2-codex}" \
    --build-arg ACCEPT_EULA=Y --build-arg "CODEX_VERSION=${CODEX_VERSION:-latest}" "$@" "$script_dir"
