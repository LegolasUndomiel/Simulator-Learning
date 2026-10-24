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
| MuJoCo | [google-deepmind/mujoco](https://github.com/google-deepmind/mujoco) | `Simulators/mujoco` | `526583e5b7c3` | C/C++, Python | built & tested |
| Newton | [newton-physics/newton](https://github.com/newton-physics/newton) | `Simulators/newton` | `756912b1f716` | Python, GPU kernels | built; test run incomplete |
| Genesis World | [Genesis-Embodied-AI/genesis-world](https://github.com/Genesis-Embodied-AI/genesis-world) | `Simulators/genesis` | `50a2aa19cba6` | Python | built & tested |
| OpenCourant | [OpenCourant/OpenCourant](https://github.com/OpenCourant/OpenCourant) | `Simulators/opencourant` | `b19ec63f3724` | Fortran, C/C++ | built & tested |
| PeriDyno | [peridyno/peridyno](https://github.com/peridyno/peridyno) | `Simulators/peridyno` | `480aa9976d08` | C++, CUDA | built & tested |
| PPF Contact Solver | [st-tech/ppf-contact-solver](https://github.com/st-tech/ppf-contact-solver) | `Simulators/ppf-contact-solver` | `d6a1ace41841` | Rust, Python | built & tested |
| PositionBasedDynamics | [InteractiveComputerGraphics/PositionBasedDynamics](https://github.com/InteractiveComputerGraphics/PositionBasedDynamics) | `Simulators/position-based-dynamics` | `10a70bc146a9` | C++, Python | built (no upstream tests) |

The commits above are read from the actual submodule checkouts. OpenCourant is the community continuation of the discontinued OpenRadioss project.

Each status above was verified on Windows by building the pinned commit with the simulator's official toolchain and running its official test suite; the per-simulator commands, results, and known upstream issues are recorded in [`Experiments/build-verification/README.md`](Experiments/build-verification/README.md).

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

### Building with Xmake

Xmake is the repository's unified native build entry point. The default configuration needs Visual Studio 2022 and Git only; CUDA, Intel oneAPI and Python are required only when their opt-in targets are enabled.

```powershell
xmake f -P . -y -c -m release # reset options and select root project: PBD + MuJoCo
                           # rerun if dependency restoration asks for it
xmake -j 12                # default targets: PBD libs + 16 demos,
                           # MuJoCo core + plugins + samples
# Add --with_mujoco_tests=y at configure time for test/benchmark executables.
xmake f -y -c -m release --with_peridyno=y --peridyno_cuda_arch=89
xmake build -j12 peridyno  # PeriDyno: 23 DLLs + 75 executables
xmake f -y -c -m release --with_opencourant=y
xmake build -j12 opencourant # OpenCourant (Windows x64 Release only)
xmake run pbd_link_check   # smoke check: PBD libraries link and run
xmake run mj_link_check    # smoke check: mujoco.dll links and runs
```

Run these commands from the repository root with Xmake 3.1 or newer. `-c` resets configuration options, not all objects; `-a` builds all enabled projects and does not replace `--with_*=y`.

Binaries, objects and dependency files land under `build/simulators/windows/x64/release/{bin,lib,obj,dep}`; generated headers and Fortran modules also stay under `build/`. Use `--with_pypbd=y --pbd_python_root=...` for the Python binding. Third-party sources live in root `deps/`: missing checkouts use bootstrap commits from the scripts; existing checkouts are used as-is, without forced pinning or overwriting. Review these dependencies and the OpenCourant manifest when updating upstream. Xmake package versions are unpinned and no package lock is enabled.

If a cached `oc-native-probe` project shadows the root project or causes `project not found`, run `xmake f -P . -y -m release` from the root; deleting `build/` is unnecessary.

OpenCourant now uses native Fortran/C/C++ object targets, a oneAPI environment adapter and a necessary response-file link hook. Both components build, but post-refactor functional parity, Fortran include/module invalidation and recovery, and performance remain under validation. Historical miniQA results and timings do not certify the new implementation. See [`xmake/README.md`](xmake/README.md) for detailed usage and limitations.

#### Build all projects in one invocation

Run from the repository root (Windows x64 Release):

```powershell
# Initial configuration: enable all four managed projects
xmake f -P . -y -c -m release --with_pbd=y --with_mujoco=y --with_peridyno=y --with_opencourant=y

# Build all enabled targets; reuse this command for incremental builds
xmake build -a -j12

# To force a full rebuild, use this instead
xmake build -a -r -j12
```

This includes PBD, MuJoCo, PeriDyno and OpenCourant, not Python/Rust projects.
MSVC, CUDA, Intel oneAPI/MKL and an available Python interpreter are required.
`-a` does not enable projects disabled in the configuration.

Append `--with_mujoco_tests=y` to the configure command for MuJoCo tests, or
`--with_pypbd=y --pbd_python_root="C:/path/to/python"` for PBD Python bindings.
The OpenCourant refactor builds successfully, but functional parity and
incremental dependency correctness remain under validation.

## Design Principles

1. Upstream source stays isolated through Git submodules.
2. Markdown is the source of truth for documentation.
3. Python environments are isolated by simulator using Conda.
4. Xmake is the repository's unified build entry point: it natively builds compiled-language Examples, Experiments, and the simulator libraries (descriptions under `xmake/simulators/`, referencing read-only upstream sources).
5. Examples and Experiments serve different purposes.
6. Docs and Examples reference each other with repository-relative paths.
7. Simulator versions are reproducible through pinned commits.
8. Where tooling permits, generated output is centralized under the root `build/`: official simulators use `build/simulators/<slug>/`, personal examples use `build/examples/`, and documentation sites use `build/docs/<slug>/`.
9. `.gitignore` precisely covers the root `/build/` plus unavoidable caches and fallback outputs such as `site/`. It intentionally does not use `**/build/`, so output created outside the agreed layout remains visible and can be corrected.
10. Official simulators keep their upstream build systems as the canonical reference. The repository additionally maintains native Xmake builds of the simulator libraries under `xmake/simulators/` that compile the same read-only upstream sources into `build/simulators/` without ever modifying the upstream trees.

Git is not storage for model weights, large datasets or meshes, build artifacts, rendered videos, simulator caches, or Conda environments. Git LFS can be evaluated separately if it becomes necessary.

See [CONTRIBUTING.md](CONTRIBUTING.md) for repository rules.
