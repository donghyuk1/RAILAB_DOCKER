"""Finite headless simulator check; run with isaac-python, on a GPU host."""
from isaaclab.app import AppLauncher

app = AppLauncher(headless=True).app
try:
    import torch
    import isaaclab.sim as sim_utils

    assert torch.cuda.is_available(), "No CUDA device available"
    value = torch.ones(16, device="cuda")
    assert (value @ value).item() == 16
    sim = sim_utils.SimulationContext(sim_utils.SimulationCfg(device="cuda:0"))
    sim.reset()
    for _ in range(30):
        sim.step()
    print("PASS: Isaac Sim started, CUDA works, and 30 simulation steps completed.")
finally:
    app.close()
