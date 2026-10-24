# PositionBasedDynamics Examples

Status: Planned

## Purpose

Hold minimal C++ and Python programs for studying constraints, solvers, collision handling, and the pyPBD interface.

## Environment

Use the `position-based-dynamics` Conda environment for Python work. The pinned upstream root packaging metadata does not state a Python version constraint, so none is invented here.

## Directory Structure

- `cpp/`: C++ implementation studies.
- `python/`: pyPBD API studies.

## Build / Run

Personal C++ examples will use this directory's `xmake.lua` and targets prefixed with `pbd_`. Output belongs in `build/examples/`; no personal example targets are defined yet. Upstream CMake remains the reference, while the root project builds PBD libraries and upstream demos natively with Xmake. See [the build guide](../../xmake/README.md), including the opt-in Python binding. Xmake generates `Utils/Version.h` under `build/`, not inside the submodule; official out-of-source CMake builds use `build/simulators/position-based-dynamics/` but may still generate that header in the source tree.

## Related Documentation

See `Docs/position-based-dynamics/`.
