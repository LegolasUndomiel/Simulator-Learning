# Documentation Workspace

`foundations/` contains simulator-independent theory. Every simulator directory is a separate MkDocs project for architecture, theory, source-study notes, and learning progress.

Create the documentation-only environment with:

```bash
conda env create -f Docs/environment.yml
conda activate simulator-docs
```

Then run `mkdocs serve` or `mkdocs build` inside one project. Generated sites are placed in `build/docs/<project>/` at the repository root. Markdown remains the source of truth.
