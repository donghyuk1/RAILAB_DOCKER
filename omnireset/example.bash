#!/usr/bin/env bash
# Peg insertion using the upstream cloud reset datasets; no collection required.
set -euo pipefail
mode=${1:-help}
if (($#)); then shift; fi
if [[ $mode == help || $mode == --help ]]; then
    cat <<'HELP'
Usage: omnireset-example train [training arguments / Hydra overrides]
       omnireset-example download
       omnireset-example play [play arguments / Hydra overrides]
train defaults: peg insertion, headless, 512 envs, one GPU, TensorBoard.
Set NUM_ENVS and NUM_GPUS inside the container (or via runner.bash).
Download the pretrained peg checkpoint before play. Ctrl+C stops play.
HELP
    exit 0
fi
cd "${UWLAB_PATH:-/workspace/UWLab}"
checkpoint=checkpoints/peg_state_rl_expert_seed42.pt
case "$mode" in
    download)
        mkdir -p checkpoints
        # Download atomically so a failed request cannot appear as a valid checkpoint.
        curl --fail --location --retry 3 \
            https://huggingface.co/datasets/UW-Lab/uwlab-assets/resolve/main/Policies/OmniReset/state_based_experts/peg_state_rl_expert_seed42.pt \
            --output "$checkpoint.part"
        mv -- "$checkpoint.part" "$checkpoint"
        ;;
    train)
        count=${NUM_GPUS:-1}
        [[ $count =~ ^[1-9][0-9]*$ ]] || { echo 'NUM_GPUS must be a positive integer.' >&2; exit 1; }
        launch=(isaac-python)
        distributed=()
        if ((count > 1)); then
            launch+=(-m torch.distributed.run --standalone --nnodes=1 "--nproc_per_node=$count")
            distributed=(--distributed)
        fi
        exec "${launch[@]}" scripts/reinforcement_learning/rsl_rl/train.py \
            --task OmniReset-Ur5eRobotiq2f85-RelCartesianOSC-State-v0 \
            --headless --num_envs "${NUM_ENVS:-512}" --logger tensorboard \
            "${distributed[@]}" env.scene.insertive_object=peg env.scene.receptive_object=peghole "$@"
        ;;
    play)
        [[ -s $checkpoint ]] || { echo 'Run omnireset-example download first.' >&2; exit 1; }
        exec isaac-python scripts/reinforcement_learning/rsl_rl/play.py \
            --task OmniReset-Ur5eRobotiq2f85-RelCartesianOSC-State-Play-v0 \
            --headless --num_envs "${NUM_ENVS:-1}" --checkpoint "$checkpoint" \
            env.scene.insertive_object=peg env.scene.receptive_object=peghole "$@"
        ;;
    *) echo "Unknown action: $mode (use --help)." >&2; exit 1 ;;
esac
