# 🖥️ HPC_EXAM Simulation Management Script

This Bash script is designed to manage astrophysical simulations for HPC environments using the Gadget2 code. It supports compiling executables, configuring parameter files, submitting SLURM jobs, and reviewing simulation results.

---

## 📁 Directory Structure

- `outputs/` – Stores output data and logs from simulations
- `parameterfiles/` – Stores customized parameter files per run
- `executables/` – Holds compiled Gadget2 executables
- `jobs/` – Contains SLURM batch scripts
- `templates/` – Contains templates for parameters, job scripts, and menus

---

## 🚀 How to Use

When executed, the script presents a main menu with options:

### 🔹 Main Menu
- `[1] Run a simulation`
- `[2] View data from finished simulation`
- `[e] Exit`

---

## 🛠️ Running a Simulation

1. Select an available initial condition from the list (derived from `/home/work/HPC_Astro/ICs_exam/`).
2. Input the number of tasks (2–32).
3. The script:
   - Prepares the simulation-specific parameter file.
   - Calculates and sets gravitational softening.
   - Compiles a unique Gadget2 executable.
   - Prepares and submits a SLURM job file using `sbatch`.

🧠 *The script auto-handles node assignment based on task count.*

---

## 📊 Viewing Simulation Results

- Automatically detects finished simulations (via `snapshot_005`)
- Parses performance logs (e.g., `timings.txt`, `cpu.txt`)
- Aggregates data into:
  - Individual summaries (per simulation)
  - A general recap table for all runs
- Displays:
  - Workload balance
  - CPU time
  - Particle throughput
  - Memory load metrics

📌 Press `[a]` in view mode to see a tabulated summary of all finished simulations.

---

## 📦 Features

- Auto-compile Gadget2 with custom names
- Softening length and output paths dynamically assigned
- Uses templates to maintain consistency
- Cleans `restart.*` files to conserve space
- Highly modular and interactive

---

## 📄 Requirements

- SLURM-based HPC environment
- `gfortran` and `mpirun` installed
- Gadget2 source code under `gadget/`
- Pre-made templates in `templates/` directory

---

## 👨‍💻 Author

**Iustin Adrian Dinu**  
Script designed for Exercise 2 of HPC Astro coursework.
