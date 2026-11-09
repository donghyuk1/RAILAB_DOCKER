# Follow Isaac Lab's official Docker layout and installer with a pinned source revision.
ARG ISAACSIM_IMAGE=nvcr.io/nvidia/isaac-sim:5.1.0
FROM node:22-bookworm-slim AS node
FROM ${ISAACSIM_IMAGE}
USER root
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG DEBIAN_FRONTEND=noninteractive
# Isaac Lab 2.3.2 revision also selected by UWLab's isaaclab2 installer.
ARG ISAACLAB_REF=37ddf626871758333d6ed89cf64ad702aef127d0
ARG CODEX_VERSION=latest
ARG ACCEPT_EULA
ENV LANG=C.UTF-8 TERM=xterm \
    ISAACSIM_ROOT_PATH=/isaac-sim ISAACSIM_PATH=/isaac-sim \
    ISAACLAB_PATH=/workspace/isaaclab \
    OMNI_KIT_ALLOW_ROOT=1 PYTHONUNBUFFERED=1 \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility,graphics,display
RUN test "$ACCEPT_EULA" = Y && test "$(uname -m)" = x86_64 && \
    apt-get update && apt-get install -y --no-install-recommends \
      build-essential cmake git git-lfs ca-certificates curl wget openssh-client \
      libglib2.0-0 ncurses-term less vim tmux && \
    rm -rf /var/lib/apt/lists/*
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules/npm /usr/local/lib/node_modules/npm
RUN ln -sf ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && \
    npm install -g "@openai/codex@${CODEX_VERSION}" && npm cache clean --force && codex --version
RUN git init "$ISAACLAB_PATH" && \
    git -C "$ISAACLAB_PATH" remote add origin https://github.com/isaac-sim/IsaacLab.git && \
    git -C "$ISAACLAB_PATH" fetch --depth 1 origin "$ISAACLAB_REF" && \
    git -C "$ISAACLAB_PATH" checkout --detach FETCH_HEAD && \
    git -C "$ISAACLAB_PATH" submodule update --init --recursive && \
    git -C "$ISAACLAB_PATH" rev-parse HEAD > /opt/isaaclab-revision && \
    ln -s /isaac-sim "$ISAACLAB_PATH/_isaac_sim"
WORKDIR /workspace/isaaclab
RUN ./isaaclab.sh -p -m pip install toml && \
    ./isaaclab.sh -p tools/install_deps.py apt source && \
    ./isaaclab.sh --install rsl_rl && \
    ./isaaclab.sh -p -m pip uninstall -y quadprog && \
    ./isaaclab.sh -p -m pip freeze > /opt/isaaclab-python-versions.txt && \
    rm -rf /var/lib/apt/lists/*
COPY isaac-python.bash /usr/local/bin/isaac-python
COPY train.bash /usr/local/bin/isaaclab-train
COPY smoke.py /opt/railab/smoke.py
RUN chmod +x /usr/local/bin/isaac-python /usr/local/bin/isaaclab-train && \
    mkdir -p /root/.codex /root/.cache /root/.nv/ComputeCache && \
    /isaac-sim/python.sh -c 'import importlib.metadata as m; print({p: m.version(p) for p in ("isaaclab", "rsl-rl-lib", "torch")})'
# Replace the base image's application launcher with an ordinary server shell.
ENTRYPOINT []
CMD ["bash"]
EXPOSE 6006
