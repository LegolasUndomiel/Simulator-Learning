# OpenCourant Examples

Status: Planned

## Purpose

Hold small Fortran, C, or C++ programs used to understand explicit dynamics concepts and OpenCourant interfaces without changing upstream source.

## Environment

No Python environment is created because the current learning scope is compiled-language focused. Toolchain requirements will be documented per example.

## Directory Structure

- `fortran/`: Fortran studies.
- `c/`: C studies.
- `cpp/`: C++ studies.

## Build / Run

Personal compiled examples will use this directory's `xmake.lua`, with simulator-prefixed targets and output under `build/examples/`. OpenCourant itself continues to use its official build system, preferably with output under `build/simulators/opencourant/` where supported.

## Related Documentation

See `Docs/opencourant/`.
