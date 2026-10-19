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

Personal examples will use this directory's `xmake.lua` and simulator-prefixed targets. Output belongs in `build/examples/`. PeriDyno itself remains under its upstream CMake build and should use `build/simulators/peridyno/` when configured out of source.

## Related Documentation

See `Docs/peridyno/`.
