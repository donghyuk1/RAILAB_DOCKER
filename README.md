# RailabServer Docker setups

The first setup is [RaiSim learning](raisim_learning/README.md), based on the
original files in `example/`. It installs the `raisim2Lib` ANYmal PPO
example, CUDA PyTorch, and Codex CLI. Future agent environments can live in
separate directories with their own images and dependency versions.

## Run on a server

Clone this repository on the server after configuring Docker and the NVIDIA
Container Toolkit (see the setup guide above):

```bash
mkdir -p ~/docker
cd ~/docker
git clone git@github.com:donghyuk1/RAILAB_SERVER.git
cd RAILAB_SERVER/raisim_learning
./build.bash
GPUS=0 ./runner.bash
```

Inside the container, run `raisim-train`. Supply your own RaiSim activation key;
keys and Codex credentials are never committed.
