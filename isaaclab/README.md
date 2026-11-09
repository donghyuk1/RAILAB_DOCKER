# Isaac Lab server environment

Vanilla Isaac Lab **2.3.2**, Isaac Sim **5.1.0**, its bundled Python **3.11**,
RSL-RL, and Codex CLI. This is the baseline for `../omnireset` and can also be
used independently. It uses NVIDIA's simulator image and the upstream source
installer, following the [Isaac Lab Docker guide](https://isaac-sim.github.io/IsaacLab/v2.3.2/source/deployment/docker.html).
The source commit is pinned to `37ddf626871758333d6ed89cf64ad702aef127d0`.

The version is deliberate: UWLab's `isaaclab2` branch uses this stack; its
`main` branch now targets Isaac Lab 3.0 / Isaac Sim 6.1. See the
[UWLab branch compatibility notes](https://github.com/UW-Lab/UWLab/tree/isaaclab2).
Isaac Sim 5.1 is now an older, unsupported NVIDIA release; this setup prioritizes
compatibility with that OmniReset branch. Do not change only the simulator tag
or point UWLab at `main` without migrating the whole stack.

## Local PC

Make these new directories available in your server checkout (commit/push and
then `git pull` on the server, or copy both directories). SSH to your server:

```bash
ssh YOUR_ACCOUNT@SERVER_IP
```

Both `isaaclab/` and `omnireset/` must remain siblings: OmniReset reuses the
Isaac Lab launcher and image. You do not need to install Isaac Sim locally.

## Server host: prerequisites

Use an x86_64 Linux server with Docker and NVIDIA Container Toolkit already
configured, as for the RaiSim setup. Check the actual GPU and driver against
[NVIDIA's Isaac Sim 5.1 requirements](https://docs.isaacsim.omniverse.nvidia.com/5.1.0/installation/requirements.html).
A working CUDA test alone does not prove Isaac Sim compatibility: graphics/RTX
support matters, especially for camera workflows. Budget ample disk space for
the large simulator image, build layers, assets, and checkpoints. Downloads need
access to NVIDIA NGC, GitHub, Python package indexes, and asset hosts.

```bash
nvidia-smi
docker run --rm --gpus all nvidia/cuda:12.8.1-base-ubuntu22.04 nvidia-smi
```

## Server host: build and launch

Review the [NVIDIA software license](https://www.nvidia.com/en-us/agreements/enterprise-software/nvidia-software-license-agreement/).
Set `ACCEPT_EULA=Y` only if you agree; it is required by these build/run scripts.

```bash
cd ~/docker/RAILAB_DOCKER/isaaclab
export ACCEPT_EULA=Y
./build.bash
GPUS=0 ./runner.bash
```

For a workspace directly under your home, the directory is
`~/RailabServer/isaaclab` instead. If pulling the NVIDIA image reports an
authentication error, configure your NGC access with `docker login nvcr.io` and
retry. The first build and simulator startup can take a long time.

## Inside the container: test and train

Use `isaac-python` for simulator Python commands. It invokes `/isaac-sim/python.sh`
and sets up the libraries correctly; system `python` is not the training interpreter.

```bash
codex --version
isaac-python -c 'import torch; print(torch.__version__, torch.cuda.is_available())'
isaac-python /opt/railab/smoke.py
isaaclab-train --max_iterations 10
```

The smoke check starts Isaac Sim headlessly, exercises CUDA, performs 30
simulation steps, and exits. The training check runs Cartpole with 64
environments for 10 iterations. It verifies asset loading, task creation, and
PPO updates; it is not intended to produce a converged policy.

For a longer run inside the container:

```bash
NUM_ENVS=1024 isaaclab-train --max_iterations 1000
```

You can also use upstream commands from `/workspace/isaaclab`:

```bash
./isaaclab.sh -p scripts/reinforcement_learning/rsl_rl/train.py \
  --task Isaac-Cartpole-v0 --num_envs 64 --headless --max_iterations 10
```

## Server host: detached jobs and monitoring

Exit the interactive container before starting a new container with the same name.

```bash
ACCEPT_EULA=Y GPUS=0 DETACH=1 ./runner.bash isaaclab-train --max_iterations 1000
docker logs -f "isaaclab-$USER"
docker exec -it "isaaclab-$USER" bash
```

Detached containers keep running when SSH disconnects. Stop and remove one
when done (its volumes remain):

```bash
docker stop "isaaclab-$USER"
docker rm "isaaclab-$USER"
```

For TensorBoard, run inside the container:

```bash
isaac-python -m tensorboard.main --logdir /workspace/isaaclab/logs --host 0.0.0.0 --port 6006
```

On your local PC, open a separate SSH tunnel and then `http://localhost:6006`:

```bash
ssh -L 6006:localhost:6006 YOUR_ACCOUNT@SERVER_IP
```

## Storage and configuration

`./runner.bash --help` lists settings. Default image:
`railab/isaaclab:2.3.2-codex`; default container: `isaaclab-$USER`.
`GPUS=0,1` selects host devices; inside the container they are enumerated from 0.
The launcher uses isolated networking, an 8 GB shared-memory allocation, and
loopback-only TensorBoard publishing. It does not require a desktop, privileged
mode, or host networking. For simultaneous jobs, use separate container names,
GPU allocations, and `TB_PORT` values.

| Data | Persistent storage |
| --- | --- |
| `/workspace` (source edits, logs, checkpoints) | `$CONTAINER_NAME-workspace` |
| `/root/.codex` | `$CONTAINER_NAME-codex` |
| Download, shader, compute caches; simulator logs/data | Volumes prefixed by `$CACHE_PREFIX` (defaults to container name) |

Docker fills a new workspace volume from the image. Existing volumes keep their
old source after rebuilds. When changing source revisions or Python dependencies,
choose a new `WORKSPACE_VOLUME`, then copy needed experiments across. Keep the two
environments' workspace volumes separate. To retrieve logs from a running job:

```bash
docker cp "isaaclab-$USER:/workspace/isaaclab/logs" ./training-logs
```

Codex is installed via npm, as in the RaiSim image. Inside the container:

```bash
codex login --device-auth
codex
```

See [official Codex CLI documentation](https://developers.openai.com/codex/cli/)
and [headless authentication](https://developers.openai.com/codex/auth/).
Login data persists in the private Codex volume; no account keys go in the image.
Use `CODEX_VERSION=<version> ./build.bash` to pin the CLI (with `ACCEPT_EULA=Y`).
The node/base image tags and transitive Python dependencies are not fully locked.
Resolved source and package records are saved under `/opt/isaaclab-*` in the image.

## Validation status

Shell syntax and mocked launcher/build command checks pass locally. Docker is
not installed in the authoring environment, and shell DNS access to GitHub is
unavailable, so image builds, dependency resolution, simulation, and GPU training
remain to be validated on your server. The commands above are the acceptance
checks; report the final build error or simulator traceback if they fail.
