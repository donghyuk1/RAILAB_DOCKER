# RaiSim 2 / RaisimGymTorch, Linux x86_64.
ARG CUDA_IMAGE=nvidia/cuda:11.8.0-devel-ubuntu22.04
FROM node:22-bookworm-slim AS node
FROM ${CUDA_IMAGE}
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG DEBIAN_FRONTEND=noninteractive
ARG RAISIM_REF=master
ARG CODEX_VERSION=latest
ARG BUILD_JOBS=4
ENV LANG=C.UTF-8 \
    WORKSPACE=/raisim_ws \
    LOCAL_INSTALL=/raisim_build \
    VIRTUAL_ENV=/opt/venv \
    PATH=/opt/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    CMAKE_PREFIX_PATH=/raisim_ws/raisim2Lib/raisim:/raisim_ws/raisim2Lib/rayrai:/raisim_build \
    LD_LIBRARY_PATH=/raisim_ws/raisim2Lib/raisim/lib:/raisim_ws/raisim2Lib/rayrai/lib:/raisim_ws/raisim2Lib/raisim/lib/openusd:/raisim_ws/raisim2Lib/rayrai/lib/openusd:/raisim_build/lib:/usr/local/nvidia/lib:/usr/local/nvidia/lib64 \
    MPLBACKEND=Agg \
    PYTHONUNBUFFERED=1 \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility
RUN test "$(uname -m)" = x86_64 && apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake ca-certificates curl git openssh-client \
    python3 python3-dev python3-venv libeigen3-dev libgomp1 libsdl2-dev libgl1-mesa-dev \
    libgl1 libglib2.0-0 libx11-6 libxext6 libxcb1 libxau6 libxdmcp6 \
    vim less tmux unzip && rm -rf /var/lib/apt/lists/*
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules/npm /usr/local/lib/node_modules/npm
RUN ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && \
    npm install -g "@openai/codex@${CODEX_VERSION}" && npm cache clean --force && codex --version
RUN python3 -m venv "$VIRTUAL_ENV" && \
    pip install --no-cache-dir pip==24.3.1 setuptools==65.5.1 wheel==0.45.1 && \
    pip install --no-cache-dir torch==2.5.1 torchvision==0.20.1 --index-url https://download.pytorch.org/whl/cu118
# Constrain core dependencies while installing the upstream learning requirements.
COPY requirements.txt /opt/raisim-requirements.txt
RUN pip install --no-cache-dir -r /opt/raisim-requirements.txt
RUN git clone --recursive https://github.com/raisimTech/raisim2Lib.git "$WORKSPACE/raisim2Lib" && \
    cd "$WORKSPACE/raisim2Lib" && git checkout "$RAISIM_REF" && \
    git submodule update --init --recursive && git rev-parse HEAD > /opt/raisim-source-revision && \
    cmake -S . -B /tmp/raisim-build -DCMAKE_INSTALL_PREFIX="$LOCAL_INSTALL" \
      -DRAISIM_EXAMPLE=OFF -DRAISIM_PY=OFF -DRAISIM_MATLAB=OFF && \
    cmake --install /tmp/raisim-build && rm -rf /tmp/raisim-build
WORKDIR /raisim_ws/raisim2Lib/raisimGymTorch
RUN pip install --no-cache-dir -c /opt/raisim-requirements.txt -r requirements.txt && \
    CMAKE_BUILD_PARALLEL_LEVEL="$BUILD_JOBS" python setup.py develop && \
    pip check && python -c 'from raisimGymTorch.env.bin import rsg_anymal' && \
    pip freeze > /opt/raisim-python-versions.txt
COPY train.bash /usr/local/bin/raisim-train
RUN chmod +x /usr/local/bin/raisim-train && mkdir -p /root/.codex /root/.raisim
EXPOSE 6006 8080
CMD ["bash"]
