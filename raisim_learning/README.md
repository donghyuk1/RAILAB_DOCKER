# RaiSim learning server

This installs [raisimTech/raisim2Lib](https://github.com/raisimTech/raisim2Lib)
and its RaisimGymTorch ANYmal learning example. The CMake configure step downloads
the matching RaiSim and rayrai binary packages from upstream releases.

The image uses Ubuntu 22.04, CUDA 11.8 development tools, Python 3.10 in a
virtual environment, PyTorch 2.5.1/cu118, and Node.js 22 with Codex CLI. It
installs RaiSim and rayrai to `/raisim_build` and compiles the C++20/nanobind learning environment. It also installs upstream Python requirements, including ONNX tools, with pinned PyTorch/torchvision versions.
`python`, `python3`, and `pip` use the virtual environment without changing
Ubuntu's system Python. The target is an x86_64 Linux NVIDIA server. This CUDA
11.8 stack is for older GPUs; newer GPUs such as Blackwell need a newer
CUDA/PyTorch setup. Check the actual GPU before selecting this image.

## Updating the server copy from the earlier RaiSim 1 setup

On your **local PC**, copy the updated files:

```bash
scp -r /home/dongg/RailabServer/raisim_learning YOUR_ACCOUNT@SERVER_IP:~/docker/
```

On the **server host**:

```bash
cd ~/docker/raisim_learning
chmod +x *.bash
./build.bash
GPUS=0 ./runner.bash
```

Inside the **container**:

```bash
python -c 'from raisimGymTorch.env.bin import rsg_anymal; print("RaiSim 2 import OK")'
raisim-train
```

The new default image is `railab/raisim2-learning:cu118` and the default container
is `raisim2-$USER`. This also creates a new workspace volume, leaving the previous
RaiSim 1 workspace intact. If you set `WORKSPACE_VOLUME` yourself, choose a fresh
name. A key already saved as the single file `~/.raisim` is accepted by the runner
and mounted at the correct RaiSim 2 path. For a new installation, use:

```bash
mkdir -p ~/.raisim
cp /path/to/activation-key ~/.raisim/activation.raisim
chmod 600 ~/.raisim/activation.raisim
```

## Host preparation (administrator, once per server)

Install a working NVIDIA driver and Docker Engine using the
[official Ubuntu Docker instructions](https://docs.docker.com/engine/install/ubuntu/).
Then install the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html):

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey |
  sudo gpg --dearmor --yes -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list |
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' |
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

Coordinate the Docker restart with other server users. Create individual host
accounts and add them to the Docker group:

```bash
sudo adduser ACCOUNT_NAME
sudo usermod -aG docker ACCOUNT_NAME
```

Log out and reconnect as that account. Docker group membership grants root-level
host access. Keep server passwords out of this repository.

```bash
docker run --rm hello-world
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
```

## Build and start

Run from this directory. Building requires internet access and several GB of
free disk space. No activation key or Codex credentials are included in the image.

```bash
./build.bash
# Place your activation key at ~/.raisim/activation.raisim on the server, then:
./runner.bash
```

The container runs as root, matching the original server workflow. The key is
mounted read-only at `/root/.raisim/activation.raisim`. To use a different file:

```bash
LICENSE_FILE=/absolute/path/to/activation.raisim ./runner.bash
```

For multiple users or experiments, select unique names and host ports:

```bash
CONTAINER_NAME=alice-raisim2 GPUS=0 TB_PORT=16006 VIEWER_PORT=18080 ./runner.bash
# Multiple GPUs: GPUS=0,1
```

`./runner.bash --help` lists all options. Commands and their arguments are
forwarded unchanged. The default shell container is removed when it exits;
its Docker volumes remain. A second shell in a running container is:

```bash
docker exec -it "raisim2-$USER" bash
```

## Train and inspect

Inside the container:

```bash
nvidia-smi
python -c 'import torch; print(torch.__version__, torch.cuda.is_available())'
codex --version
raisim-train
```

`raisim-train` checks the license file and performs a CUDA tensor operation
before launching upstream's runner. The validity of the activation key is
checked by RaiSim itself. The configuration is at
`/raisim_ws/raisim2Lib/raisimGymTorch/raisimGymTorch/env/envs/rsg_anymal/cfg.yaml`;
adjust the environment and thread counts for your server allocation.

To keep training after SSH disconnects, launch from the host:

```bash
DETACH=1 ./runner.bash raisim-train
docker logs -f "raisim2-$USER"
# Stop the job when needed:
docker stop "raisim2-$USER"
# Inspect logs before removing the stopped container:
docker rm "raisim2-$USER"
```

Detached containers remain after completion so their logs can be inspected.
Remove the stopped container before reusing its name. No restart policy is
applied: a completed or failed training job is not silently restarted.

## TensorBoard and visualization

Host ports default to loopback-only `6006` (TensorBoard) and `8080` (RaiSim
server). Use SSH forwarding from your laptop:

```bash
ssh -L 6006:localhost:6006 -L 8080:localhost:8080 YOUR_ACCOUNT@SERVER
```

TensorBoard must listen on `0.0.0.0` inside Docker. The upstream helper may
launch its own instance on container localhost. Stop that instance first if
port 6006 is occupied, then run in a second container shell:

```bash
tensorboard --logdir /raisim_ws/raisim2Lib/raisimGymTorch/raisimGymTorch/data --host 0.0.0.0 --port 6006
```

Open `http://localhost:6006` on your laptop. Use a matching RaiSim 2 `rayrai_tcp_viewer` on your local PC for port 8080.
The container runs the simulation server; no desktop viewer is launched. Training
does not require an X11 display. `BIND_IP=0.0.0.0` enables direct network access
when needed. Docker's `EXPOSE` is metadata: host and container port numbers do
not need to match; `TB_PORT=16006` forwards host 16006 to container 6006.

## Codex

[Codex CLI](https://developers.openai.com/codex/cli/) is installed through npm.
In the container, use the documented
[headless login](https://developers.openai.com/codex/auth/):

```bash
codex login --device-auth
codex
```

Enable device-code login in your account/workspace settings if required.
Credentials and configuration persist in the dedicated Codex volume. Treat
that volume as private account data; use a separate volume per user.

## Persistence and rebuilding

| Location | Storage |
| --- | --- |
| `/raisim_ws` | `raisim2-$USER-workspace` volume; source, compiled environment, training data |
| `/root/.codex` | `raisim2-$USER-codex` volume; credentials and settings |
| `/root/.raisim/activation.raisim` | Read-only host activation-key file |
| `/raisim_build`, `/opt/venv` | Image; recreate through `build.bash` |

Volume names follow `CONTAINER_NAME` unless `WORKSPACE_VOLUME` or `CODEX_VOLUME`
is set. Docker initializes a new workspace volume from the image. An existing
volume retains its old source and compiled extensions after an image rebuild.
When changing Python, RaiSim revisions, or dependencies, use a new
`WORKSPACE_VOLUME` and copy your data across after checking it. Back up volumes
before deleting them. Packages installed interactively outside the workspace
are lost when the container is removed; add lasting dependencies to the image.

Build overrides:

```bash
IMAGE_NAME=railab/raisim2-learning:experiment ./build.bash \
  --build-arg RAISIM_REF=YOUR_COMMIT_SHA \
  --build-arg CODEX_VERSION=YOUR_CODEX_VERSION \
  --build-arg BUILD_JOBS=4
IMAGE_NAME=railab/raisim2-learning:experiment WORKSPACE_VOLUME=raisim-experiment ./runner.bash
```

The defaults `RAISIM_REF=master`, `CODEX_VERSION=latest`, and base-image tags
float. Pin these for reproducible experiments. The image records the resolved
RaiSim revision at `/opt/raisim-source-revision` and Python package versions at
`/opt/raisim-python-versions.txt`. PyTorch uses the official
[2.5.1 CUDA 11.8 wheel installation](https://pytorch.org/get-started/previous-versions/).

## Validation status

Shell syntax and launcher behavior were checked with a mock Docker executable.
The Dockerfile includes package-consistency and compiled-environment import
checks. A real image build, GPU execution, license activation, and training
have **not** been validated in the authoring workspace because Docker is not
installed there and shell access to GitHub is unavailable. Run the build and
GPU checks above on the target server before using this for experiments.
