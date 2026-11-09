# Build ../isaaclab first. Its simulator, developer tools, and Codex are inherited.
ARG ISAACLAB_IMAGE=railab/isaaclab:2.3.2-codex
FROM ${ISAACLAB_IMAGE}
USER root
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG UWLAB_REF=isaaclab2
ARG ACCEPT_EULA
ENV UWLAB_PATH=/workspace/UWLab
RUN test "$ACCEPT_EULA" = Y && \
    git init "$UWLAB_PATH" && \
    git -C "$UWLAB_PATH" remote add origin https://github.com/UW-Lab/UWLab.git && \
    git -C "$UWLAB_PATH" fetch --depth 1 origin "$UWLAB_REF" && \
    git -C "$UWLAB_PATH" checkout --detach FETCH_HEAD && \
    git -C "$UWLAB_PATH" submodule update --init --recursive && \
    git -C "$UWLAB_PATH" rev-parse HEAD > /opt/uwlab-revision && \
    ln -s /isaac-sim "$UWLAB_PATH/_isaac_sim"
WORKDIR /workspace/UWLab
# Fail clearly if a supplied revision targets a different Isaac Lab stack.
RUN grep -Fq '37ddf626871758333d6ed89cf64ad702aef127d0' uwlab.sh && \
    chmod +x uwlab.sh && ./uwlab.sh --install rsl-rl && \
    /isaac-sim/python.sh -c 'import importlib.metadata as m; print({p: m.version(p) for p in ("uwlab_rl", "isaaclab", "rsl-rl-lib", "torch")})' && \
    /isaac-sim/python.sh -m pip freeze > /opt/omnireset-python-versions.txt && \
    codex --version
# UWLab's installer installs its pinned Isaac Lab checkout here in editable mode.
ENV ISAACLAB_PATH=/workspace/UWLab/_isaaclab/IsaacLab
COPY example.bash /usr/local/bin/omnireset-example
RUN chmod +x /usr/local/bin/omnireset-example
CMD ["bash"]
