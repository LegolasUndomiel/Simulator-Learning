# MuJoCo Examples

Status: Planned

## Purpose

Hold minimal C/C++ and Python programs for learning the MuJoCo API and validating source-level understanding.

## Environment

Python work uses the `mujoco` Conda environment defined in `environment.yml`. The environment starts with the upstream Python requirement (`>=3.10`); simulator packages will be added only when a concrete example requires them.

## Directory Structure

- `python/`: Python API studies.
- `cpp/`: C and C++ API studies.
- Future examples should grow through `01_basics/`, `02_concepts/`, and `03_source_study/` as needed.

## Build / Run

Compiled examples will be registered in this directory's `xmake.lua` and invoked through `Examples/xmake.lua`. No targets exist yet. Generated files belong in `build/examples/`.

## Related Documentation

See `Docs/mujoco/`.
