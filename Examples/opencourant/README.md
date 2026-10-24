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

Personal compiled examples will use this directory's `xmake.lua`, with simulator-prefixed targets and output under `build/examples/`. No personal example targets are defined yet. OpenCourant retains its official build system as the reference; the root project also provides opt-in native Xmake targets. See [the build guide](../../xmake/README.md) for Windows requirements, commands and post-refactor validation limits. Official build trees use `build/simulators/opencourant/`; Xmake binaries use `build/simulators/windows/x64/release/bin/`.

## Related Documentation

See `Docs/opencourant/`.
