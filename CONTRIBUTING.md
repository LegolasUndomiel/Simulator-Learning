# Contributing

This is a personal learning repository, but these rules apply equally to future maintainers and coding agents.

## Directory Rules

- `Simulators/`: pinned, official upstream source used for reading and reference.
- `Docs/`: common theory and simulator-specific understanding.
- `Examples/`: minimal programs that learn or verify one capability.
- `Experiments/`: reproducible work intended to answer a technical question.
- `build/`: ignored generated output. Prefer `build/simulators/<slug>/`, `build/examples/`, and `build/docs/`.

Do not commit large datasets, model weights, meshes, binaries, videos, checkpoints, caches, logs, Conda environments, or build output. Do not hide arbitrary `build/` directories throughout the repository: an accidentally generated noncanonical build directory should remain visible so it can be corrected.

## Submodule Rules

Do not directly modify upstream source by default. Do not configure submodules to follow a moving branch automatically. Upgrade one simulator explicitly, verify related Docs and Examples, and then record the new gitlink in the superproject. Use a fork only when maintaining an upstream modification becomes necessary.

## Docs Rules

Every formal document must:

- begin with YAML metadata using lowercase keys;
- remain Markdown-first and avoid unnecessary renderer-specific syntax;
- include `references`, `related_examples`, and `related_experiments`;
- record the actual upstream commit when it documents one simulator;
- use stable repository-relative paths for cross-references.

## Example Rules

Each Example must have one clear objective, remain as small as practical, include a README or source-level explanation, point to related Docs, and leave all generated output under the root `build/` directory. Python uses a simulator-specific Conda environment. Xmake never manages Conda or Python packages.

## Experiment Rules

Each Experiment must state its question, method, metrics, result, and conclusion. Preserve small summaries when useful, but do not commit raw bulk results.

## Commit Style

Use informative prefixes such as:

```text
docs: explain contact model
example: add minimal mujoco stepping sample
experiment: compare timestep stability
build: configure example output directory
chore: update simulator submodule
fix: correct invalid solver parameter
```

Avoid vague messages such as `update`, `test`, or `fix things`.
