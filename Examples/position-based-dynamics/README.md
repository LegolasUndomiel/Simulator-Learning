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

Personal C++ examples will use this directory's `xmake.lua` and targets prefixed with `pbd_`. Output belongs in `build/examples/`. The upstream library continues to use CMake and should use `build/simulators/position-based-dynamics/` for out-of-source builds.

## Related Documentation

See `Docs/position-based-dynamics/`.
