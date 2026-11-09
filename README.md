# RailabServer Docker setups

| Setup | Contents |
| --- | --- |
| [RaiSim learning](raisim_learning/README.md) | RaiSim 2 ANYmal PPO, CUDA PyTorch, Codex |
| [Isaac Lab](isaaclab/README.md) | Vanilla Isaac Lab 2.3.2 / Isaac Sim 5.1, RSL-RL, Codex |
| [OmniReset](omnireset/README.md) | UWLab `isaaclab2`, peg-insertion training/evaluation, Codex |

Build Isaac Lab first, then OmniReset. Each environment has separate source,
cache, and credential volumes. The original RaiSim reference files remain in
`example/`. Follow each environment's README for server-host and container steps.

## Run on a server

Clone this repository on the server after configuring Docker and the NVIDIA
Container Toolkit (see the setup guide above):

```bash
mkdir -p ~/docker
cd ~/docker
git clone git@github.com:donghyuk1/RAILAB_DOCKER.git
cd RAILAB_DOCKER/raisim_learning
./build.bash
GPUS=0 ./runner.bash
```

Inside the container, run `raisim-train`. Supply your own RaiSim activation key;
keys and Codex credentials are never committed.
