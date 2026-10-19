# Simulator Learning

[中文](README_zh.md)

Simulator Learning is a long-term learning and research repository for open-source simulators. It covers physics simulation, numerical methods, robotics and embodied-AI simulation, CAE, and differentiable simulation.

The repository keeps upstream source, study notes, small practice programs, and research experiments separate so that personal work does not contaminate third-party source trees.

## Repository Structure

```text
Simulators/   Official upstream source pinned as Git submodules
Docs/         Shared theory and independent MkDocs projects
Examples/     Small learning programs and source-study probes
Experiments/  Reproducible investigations that answer technical questions
build/        Ignored, centralized generated build and documentation output
```

`Simulators/<name>`, `Docs/<name>`, and `Examples/<name>` always use the same slug.

## Simulators

| Simulator | Upstream Repository | Local Path | Pinned Commit | Primary Language | Learning Status |
| --- | --- | --- | --- | --- | --- |
| MuJoCo | [google-deepmind/mujoco](https://github.com/google-deepmind/mujoco) | `Simulators/mujoco` | `526583e5b7c3` | C/C++, Python | planned |
| Newton | [newton-physics/newton](https://github.com/newton-physics/newton) | `Simulators/newton` | `756912b1f716` | Python, GPU kernels | planned |
| Genesis World | [Genesis-Embodied-AI/genesis-world](https://github.com/Genesis-Embodied-AI/genesis-world) | `Simulators/genesis` | `50a2aa19cba6` | Python | planned |
| OpenCourant | [OpenCourant/OpenCourant](https://github.com/OpenCourant/OpenCourant) | `Simulators/opencourant` | `b19ec63f3724` | Fortran, C/C++ | planned |
| PeriDyno | [peridyno/peridyno](https://github.com/peridyno/peridyno) | `Simulators/peridyno` | `480aa9976d08` | C++, CUDA | planned |
| PPF Contact Solver | [st-tech/ppf-contact-solver](https://github.com/st-tech/ppf-contact-solver) | `Simulators/ppf-contact-solver` | `d6a1ace41841` | Rust, Python | planned |
| PositionBasedDynamics | [InteractiveComputerGraphics/PositionBasedDynamics](https://github.com/InteractiveComputerGraphics/PositionBasedDynamics) | `Simulators/position-based-dynamics` | `10a70bc146a9` | C++, Python | planned |

The commits above are read from the actual submodule checkouts. OpenCourant is the community continuation of the discontinued OpenRadioss project.

## Getting Started

Clone with all submodules:

```bash
git clone --recurse-submodules <repository>
```

OpenCourant uses Git LFS for some assets. Install Git LFS before cloning if those assets are required. This repository initialization does not enable Git LFS in the superproject.

After a normal clone, or after pulling changes to the superproject:

```bash
git submodule update --init --recursive
git submodule status
```

`Simulators/` is an upstream source-reading area. Do not modify it by default. Put personal learning code in `Examples/`, research work in `Experiments/`, and theory or source understanding in `Docs/`. If an upstream kernel must eventually be changed, use an explicit upstream-to-fork-to-submodule workflow; no forks are configured here.

### Documentation

```bash
conda env create -f Docs/environment.yml
conda activate simulator-docs
cd Docs/mujoco
mkdocs serve
# or: mkdocs build
```

Each directory under `Docs/` is an independent MkDocs project. Markdown is the long-lived source of truth. Generated sites are written under the root `build/docs/` directory.

### Examples

Python environments are isolated by simulator, for example:

```bash
conda env create -f Examples/mujoco/environment.yml
conda activate mujoco
```

`Examples/xmake.lua` is the entry point for personal C, C++, CUDA, and Fortran examples. It writes generated files under `build/examples/`. There are no build targets yet. Official simulators retain their own upstream build systems; use out-of-source directories under `build/simulators/<slug>/` when the upstream system supports that workflow.

## Design Principles

1. Upstream source stays isolated through Git submodules.
2. Markdown is the source of truth for documentation.
3. Python environments are isolated by simulator using Conda.
4. Xmake only manages compiled-language Examples.
5. Examples and Experiments serve different purposes.
6. Docs and Examples reference each other with repository-relative paths.
7. Simulator versions are reproducible through pinned commits.
8. Where tooling permits, generated output is centralized under the root `build/`: official simulators use `build/simulators/<slug>/`, personal examples use `build/examples/`, and documentation sites use `build/docs/<slug>/`.
9. `.gitignore` precisely covers the root `/build/` plus unavoidable caches and fallback outputs such as `site/`. It intentionally does not use `**/build/`, so output created outside the agreed layout remains visible and can be corrected.
10. Official simulators retain their upstream build systems. If an upstream project cannot build out of source, document the exception instead of modifying third-party source or forcing it into Xmake.

Git is not storage for model weights, large datasets or meshes, build artifacts, rendered videos, simulator caches, or Conda environments. Git LFS can be evaluated separately if it becomes necessary.

See [CONTRIBUTING.md](CONTRIBUTING.md) for repository rules.
