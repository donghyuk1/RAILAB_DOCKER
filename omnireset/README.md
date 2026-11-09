# OmniReset server environment

[OmniReset](https://weirdlabuw.github.io/omnireset/) is implemented in
[UWLab](https://github.com/UW-Lab/UWLab). This image adds UWLab's `isaaclab2`
branch to `../isaaclab`, retaining Codex and Isaac Sim 5.1.0. Its installer selects
Isaac Lab 2.3.2, CUDA PyTorch, and the UWLab RSL-RL fork. The Dockerfile checks
that the installer targets the expected Isaac Lab revision before running it.
The current `main` UWLab branch uses a different simulator stack.

## Local PC

Transfer/push both sibling directories, then SSH into the server. Keep this
repository up to date on the server before building. No simulator installation
on your local PC is needed for the headless training workflow.

## Server host: build

First follow the [Isaac Lab prerequisites and license instructions](../isaaclab/README.md).
Build the vanilla image, then the OmniReset image:

```bash
cd ~/docker/RAILAB_DOCKER
export ACCEPT_EULA=Y
./isaaclab/build.bash
./omnireset/build.bash
cd omnireset
GPUS=0 ./runner.bash
```

Skip the first build if that image is already present. The default OmniReset
image is `railab/omnireset:isaaclab2-codex`, with container `omnireset-$USER`.
If the base image has a custom tag, pass it as `ISAACLAB_IMAGE` to the OmniReset
build script. The upstream UWLab installer fetches its own editable Isaac Lab
checkout; `ISAACLAB_PATH` points to that checkout in this image.

## Inside the container: first training check

```bash
codex --version
isaac-python /opt/railab/smoke.py
NUM_ENVS=64 omnireset-example train --max_iterations 2
```

The example is **peg insertion**, using the project's pre-generated cloud reset
datasets. Initial runs download robot/object assets and reset data; allow time
and network access. This tiny run checks task setup and PPO updates, not learning
quality. The default logger is TensorBoard, so no W&B login is required.

## Inside the container: longer training or pretrained evaluation

```bash
NUM_ENVS=512 omnireset-example train --max_iterations 1000

# Optional: download and evaluate the published peg policy
omnireset-example download
omnireset-example play
```

Play is headless and runs until interrupted. To save a video:

```bash
omnireset-example play --video --video_length 200
```

Video requires a compatible rendering GPU and additional memory. The checkpoint
is downloaded at runtime into `checkpoints/`, never bundled into the image.

## Server host: multi-GPU training

Exit the shell container before using its name again. Start with a small
single-GPU check, then scale according to available memory:

```bash
ACCEPT_EULA=Y GPUS=0,1,2,3 NUM_GPUS=4 NUM_ENVS=16384 DETACH=1 \
  ./runner.bash omnireset-example train

docker logs -f "omnireset-$USER"
docker exec -it "omnireset-$USER" bash
```

`NUM_GPUS` must match the number of selected devices. `NUM_ENVS` is **per GPU**,
so that command uses 65,536 environments total. The wrapper uses single-node
`torch.distributed.run` and the upstream `--distributed` flag. This is a large
training configuration; the project's guidance uses four GPUs with at least
24 GB each. Smaller counts are useful for testing, but do not reproduce the
reported throughput or convergence. See the
[branch-specific training guide](https://github.com/UW-Lab/UWLab/blob/isaaclab2/docs/source/publications/omnireset/rl_training.rst).

To stop/remove the container without deleting experiment volumes:

```bash
docker stop "omnireset-$USER"
docker rm "omnireset-$USER"
```

## Custom tasks and reset data

The helper forwards extra CLI arguments and Hydra overrides unchanged. Its
built-in object pair is peg/peghole. For another object pair, invoke the upstream
training script directly from `/workspace/UWLab`:

```bash
isaac-python scripts/reinforcement_learning/rsl_rl/train.py \
  --task OmniReset-Ur5eRobotiq2f85-RelCartesianOSC-State-v0 \
  --headless --num_envs 512 --logger tensorboard \
  env.scene.insertive_object=cube env.scene.receptive_object=cube
```

To use reset data you generated yourself, add this Hydra override to training:

```text
env.events.reset_from_reset_states.params.dataset_dir=./Datasets/OmniReset
```

The upstream [reset collection guide](https://github.com/UW-Lab/UWLab/blob/isaaclab2/docs/source/publications/omnireset/rl_training.rst)
describes partial assemblies, grasp sampling, and the four reset distributions.
These collection scripts are installed under `scripts_v2/tools` in the image.
Collection is optional for the provided cloud-backed example.

## Persistence, Codex, and TensorBoard

Source, generated datasets, downloaded checkpoints, and training logs remain in
`omnireset-$USER-workspace`, mounted at `/workspace`. Codex login remains in its
own `omnireset-$USER-codex` volume. Run `codex login --device-auth` inside the
container to sign in. For all launcher settings and backup/rebuild behavior,
see the [shared runner documentation](../isaaclab/README.md#storage-and-configuration).
Never reuse the vanilla Isaac Lab workspace volume for this image.

Inside the container:

```bash
isaac-python -m tensorboard.main --logdir /workspace/UWLab/logs --host 0.0.0.0 --port 6006
```

On the local PC:

```bash
ssh -L 6006:localhost:6006 YOUR_ACCOUNT@SERVER_IP
```

Open `http://localhost:6006`. If another job uses the server's port 6006, launch
this one with `TB_PORT=16006` and tunnel to server port 16006 instead.

`UWLAB_REF=isaaclab2` is a moving branch. Pin a compatible commit for experiments:

```bash
ACCEPT_EULA=Y ./build.bash --build-arg UWLAB_REF=YOUR_COMMIT_SHA
```

Use a fresh `WORKSPACE_VOLUME` after changing source/dependency versions. The
resolved UWLab revision and package versions are recorded at `/opt/uwlab-revision`
and `/opt/omnireset-python-versions.txt`. Changing Codex requires rebuilding the
base image with `CODEX_VERSION`, then rebuilding this image.

## Validation status

Shell syntax and mocked launch/training argument checks pass. A real Docker
build, GPU startup, downloads, and training have not run here: Docker is absent
and shell network access is unavailable. Validate first with the two-iteration
training check above before allocating a long multi-GPU run.
