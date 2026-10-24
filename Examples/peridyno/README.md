# PeriDyno Examples

Status: Planned

## Purpose

Hold focused C++ and CUDA programs for studying PeriDyno concepts and implementation details.

## Environment

No Python environment is created. Compiler, CUDA, and linked-library requirements will be documented for each implemented example.

## Directory Structure

- `cpp/`: C++ studies.
- `cuda/`: CUDA studies.

## Build / Run

Personal examples will use this directory's `xmake.lua` and simulator-prefixed targets. Output belongs in `build/examples/`; no personal example targets are defined yet. PeriDyno retains upstream CMake as the reference and also has opt-in native Xmake targets in the root project. See [the build guide](../../xmake/README.md) for CUDA configuration and commands. Official out-of-source builds use `build/simulators/peridyno/`; Xmake binaries use `build/simulators/windows/x64/release/bin/`.

## Related Documentation

See `Docs/peridyno/`.
