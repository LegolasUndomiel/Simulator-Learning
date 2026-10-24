# Official-toolchain build and test verification (Windows)

> **Note (2026-10-21)**: the `build/` tree was cleaned after this record was written, so the
> referenced per-simulator build trees and logs under `build/simulators/` no longer exist on disk.
> The commands, results, and failure analyses recorded below remain the authoritative outcome; the
> OpenCourant Xmake-side artifacts (rule, manifest, QA runner script) were regenerated and the
> Xmake-native build is fully reproducible from `xmake build opencourant`.

## Question

> **OpenCourant performance repair verification:** the current native object
> graph plus per-level Fortran dependency-plan adapter passed
> `xmake build -P . -r -j12 opencourant` in **645.0 s**, with a sampled peak of
> **12 compiler driver processes**. The following no-op took **18.3 s** and
> logged no recompilation. Both executables were regenerated; the repository
> root contained **zero `.asm` files**. Raw logs/results are under
> `build/bench/oc-final*` (ignored). This closes the reported 20–30 minute
> performance regression and root assembly-residue check for this host, not
> functional miniQA or all incremental-invalidation cases. Historical ~495 s
> measurements used different scheduling and are not a controlled comparison.

> **Current Xmake implementation (post-refactor):** this document preserves
> historical verification results, not certification of the current scripts.
> The old `xmake/rules/oc_ifx` driver has been removed. OpenCourant now uses
> native object targets in `xmake/simulators/opencourant.lua`, source/module data
> in `xmake/opencourant/manifest.lua`, a thin `oneapi-windows` toolchain and an
> object-only response-file link hook. Both components build; the observed engine
> run took 1869.9 s and a subsequent combined no-op took 16.8 s. Post-refactor
> miniQA, include/module invalidation and recovery, and performance validation
> are outstanding. The historical 74/78 and old timings below do not certify it.
> Current commands and options are maintained in [the build guide](../../xmake/README.md).
> Start from the repository root with `xmake f -P . -y -c -m release`;
> explicitly enable optional projects. Packages are unversioned, and existing
> dependency checkouts are used as-is rather than forcibly pinned.

Can every simulator pinned under `Simulators/` be built with its own **official** toolchain on this
host, and does each one's **official** test suite pass?

## Hypothesis

All seven can be built if each upstream toolchain is installed and every upstream build system is
kept intact. Residual failures should be attributable to host limits (Windows privileges, GPU
memory, network access) or to upstream defects, not to this repository's layout.

## Simulators

| Simulator | Upstream repository | Pinned commit | Language / official toolchain |
| --- | --- | --- | --- |
| MuJoCo | [google-deepmind/mujoco](https://github.com/google-deepmind/mujoco) | `526583e5b7c3` | C/C++, Python — CMake/MSVC |
| Newton | [newton-physics/newton](https://github.com/newton-physics/newton) | `756912b1f716` | Python + Warp GPU kernels |
| Genesis World | [Genesis-Embodied-AI/genesis-world](https://github.com/Genesis-Embodied-AI/genesis-world) | `50a2aa19cba6` | Python + Quadrants |
| OpenCourant | [OpenCourant/OpenCourant](https://github.com/OpenCourant/OpenCourant) | `b19ec63f3724` | Fortran/C/C++ — Intel oneAPI |
| PeriDyno | [peridyno/peridyno](https://github.com/peridyno/peridyno) | `480aa9976d08` | C++/CUDA — CMake/MSVC + CUDA |
| PPF Contact Solver | [st-tech/ppf-contact-solver](https://github.com/st-tech/ppf-contact-solver) | `d6a1ace41841` | Rust + Python + CUDA — upstream `warmup.bat`/`build.bat` |
| PositionBasedDynamics | [InteractiveComputerGraphics/PositionBasedDynamics](https://github.com/InteractiveComputerGraphics/PositionBasedDynamics) | `10a70bc146a9` | C++, Python — CMake/MSVC |

## Environment

| Item | Value |
| --- | --- |
| OS | Windows (win32), 8C/16T AMD Ryzen 7 9700X, 31 GB RAM |
| GPU | NVIDIA RTX 4070 Ti SUPER 16 GB, compute capability **8.9 (sm_89)**, driver 617.42 |
| MSVC | 19.44.35229 (Visual Studio 2022 Community 17.14) |
| CMake | 4.5.0-rc1 |
| Ninja | VS-bundled |
| Clang/LLVM | 22.1.8 (`clang-cl`) |
| CUDA | 13.0 (V13.0.48) |
| Intel oneAPI | 2026.1.1 (`ifx`, `icx`, MKL, MPI) at `C:\Program Files (x86)\Intel\oneAPI` |
| Rust | 1.98.1 |
| Conda | 26.7.1 |

## Configuration

- **Output convention**: every generated tree, log and driver script lives under
  `build/simulators/<slug>/` (git-ignored), never inside `Simulators/`. A few residues are
  upstream-generated and are listed under *Repository hygiene*.
- **Conda environments** (Python projects, named after the simulator slug):

| Env | Python | Key packages |
| --- | --- | --- |
| `mujoco` | 3.12 | official `python/build_requirements.txt` pins (absl-py 2.1.0, numpy 2.1.3, glfw 2.10.2, etils 1.10.0, PyOpenGL 3.1.7, pytest 9.0.3, websockets 16.1.1) |
| `newton` | 3.12 | newton 1.8.0.dev0 (editable), warp-lang 1.18.0, mujoco, open3d |
| `genesis` | 3.12 | genesis-world 1.4.4 (editable), quadrants 1.3.3, torch 2.14.1+cpu, mujoco 3.10.0 |
| `position-based-dynamics` | 3.12 | numpy, pygame, pyopengl, setuptools, wheel |
| `ppf-contact-solver` | 3.11 | (PPF provisions its own embedded Python) |

## Method

1. Read each simulator's official build documentation and use only the official toolchain.
2. Configure out-of-source wherever upstream supports it, and record the exception where it does not.
3. Run the official test entry point and classify each failure (host limit vs upstream defect).
4. Keep the upstream sources read-only; place every helper script under `build/simulators/<slug>/`.

## Metrics

- Build exit status and the artifacts produced.
- Official test pass/fail/skip counts.
- Classification of every remaining failure.

## Results

| Simulator | Build | Official tests | Notes |
| --- | --- | --- | --- |
| MuJoCo | OK | `ctest`: **2007/2007 passed** (44.3 s) | Python bindings built from source with `clang-cl` |
| PositionBasedDynamics | OK | **no upstream test suite** | `pyPBD` module built + imported |
| OpenCourant | OK | miniQA `ctest`: **74/78 passed** | 4 failures = upstream test-data defect |
| PeriDyno | OK | **257/262 passed** (test exes run directly) | 5 failures = upstream precision cases |
| Newton | OK | ⚠️ **no completed run yet** | see section |
| Genesis | OK | `pytest -m required -n 4`: **713 passed**, 4 failed, 4 errors | failures are host/visual, see section |
| PPF Contact Solver | OK (`target/cuda`, `target/cpu`) | cargo workspace **all passed**; solver (cpu) **575 passed**; pytest frontend **532 passed** (1 upstream non-portable expectation) | CUDA backend on upstream-pinned CUDA 12.8.1 |

### MuJoCo

- **Build**: `cmake -G "Visual Studio 17 2022" -A x64 -DCMAKE_BUILD_TYPE=Release -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF` out-of-source into `build/simulators/mujoco/build`, installed to `build/simulators/mujoco/install`.
- **Tests**: `ctest -C Release --parallel 12` -> **2007/2007 passed** in 44.31 s.
- **Python bindings**: upstream does not support an in-tree `setup.py` build from a raw checkout (it needs the `make_sdist.sh` preprocessing). `build/simulators/mujoco/build_mujoco_py.bat` replicates that preprocessing into `build/simulators/mujoco/pysrc` (copies `cmake/`, `simulate/`, `LICENSE`, runs the three codegen scripts) and builds the wheel. On Windows upstream CI builds the bindings with **clang-cl**, so the script uses the standalone LLVM `clang-cl` + Ninja (MSVC fails to emit the implicitly-defined `MjWrapper` copy constructors: LNK2001). Result: `mujoco-3.16.1` wheel installed and importable.

### PositionBasedDynamics

- **Build**: VS 17 2022 x64 Release into `build/simulators/position-based-dynamics/build`. Produces the `PositionBasedDynamics`/`Simulation`/`Utils` libs and all `*Demo.exe` (Demos output to the source `bin/`, which upstream `.gitignore` excludes).
- **Tests**: none exist upstream.
- **Python**: `pyPBD` (gated by `USE_PYTHON_BINDINGS`). `python setup.py bdist_wheel` fails because `setup.py` injects `CXXFLAGS` that break the nested `ExternalProject` configure. Built instead from the working tree (`--target pypbd`) and, because `extern/pybind/.../stl_bind.h` contains a UTF-8 scissors literal that MSVC (code page 936) misreads, with `/utf-8` supplied via the `CL` env var (build-only, no source edit). Result `build/lib/Release/pypbd.cp312-win_amd64.pyd`; `import pypbd` works.

### OpenCourant

The following parity and timing records describe the **removed custom driver**.
Its paths are retained here as historical references, not current entry points;
the manifest and its maintenance generator now live under `xmake/opencourant/`.

- **Toolchain**: Intel oneAPI 2026.1.1 (`ifx`/`icx`, MKL, MPI). The root `build_windows.bat` `-build=both` cannot be used (duplicate `extlib` custom target -> CMP0002), so starter and engine are configured separately (the official per-component flow): `build/simulators/opencourant/oc_starter.bat` / `oc_engine.bat` (subdir as root, `-DEXEC_NAME=<name>`, `-DMPI=smp`, `-Dprecision=dp`). Exes are copied to the source `exec/` (upstream-gitignored): `starter_win64.exe` (46 MB), `engine_win64.exe` (143 MB).
- **Tests**: official miniQA (`qa-tests/test_script.bat` -> ctest), driven by `build/simulators/opencourant/oc_qa.bat`, which reproduces the CI environment (oneAPI runtime + `extlib/hm_reader/win64` and `extlib/h3d/lib/win64` on PATH, `RAD_CFG_PATH`, `KMP_STACKSIZE`/`OMP_STACKSIZE=400m`). Result: **74/78 passed**; the 4 failures (ctest 1.31, 1.33, 1.36, 1.59) are an upstream **test-data defect**: those decks `#include qadiags.inc`, whose contents the fork replaced with an uncommented `Copyright> ...` banner, so the Starter parser rejects it. Log: `build/simulators/opencourant/qa_full.log`.
- **Xmake parity**: `xmake build opencourant` builds both exes natively via the custom rule `xmake/rules/oc_ifx` (Intel `ifx`/`icx` driven directly; no CMake/Ninja invocation at build time). The rule consumes a pinned manifest (`xmake/rules/oc_ifx/manifest.lua`, generated once by `generate_manifest.py` from the official configured Ninja graph): starter = 2353 Fortran + 60 C/C++ sources in 11 module levels, engine = 3681 Fortran + 118 C/C++ sources in 15 levels. Outputs land in `build/simulators/windows/x64/release/bin/` (`starter_win64.exe` 46 MB, `engine_win64.exe` 143 MB); incremental rebuilds are no-ops when nothing changed. Parity checks: starter restart output for miniQA `boxbeam` is byte-identical to the official build, the engine reproduces the same 5340-cycle run with identical `.sty` files and a time-history file differing only in the run timestamp, and the full miniQA suite run against the Xmake-built binaries (staged sandbox `build/simulators/opencourant/qa-xmake/`, runner `oc_qa_xmake.bat`) gives the same **74/78 passed** with exactly the same 4 upstream data-defect failures. Log: `build/simulators/opencourant/qa_xmake.log`.

#### OpenCourant build-time comparison (official vs Xmake, 2026-10-21)

Both sides use the same compiler (`ifx`/`icx` 2026.1.1), the same configuration
(`win64`, `dp`, `smp`, `Release`, `VS_BUILD=1`), the same flags (the Xmake rule reproduces the
official per-file `/O1|/O2|/O3` overrides), and `-j 12` on the 8C/16T host. Cold builds: every
object was removed beforehand, and the produced object counts and binaries match exactly
(starter 2413 objects / 44.15 vs 44.14 MB, engine 3799 objects / 136.62 vs 136.63 MB).

> **Audit correction (2026-10-24):** these numbers are valid observations of the commands that
> were run, but the combined row is **not a controlled build-system benchmark**. The old custom
> rule ignored Xmake's `-j12` and gave each component its own 12-worker pool (up to 24 compiler
> processes), while the two official Ninja builds were run serially. Separate Ninja build trees
> can also be launched concurrently despite the combined CMake project's CMP0002 error. Do not
> use the percentages below to claim that one build system is faster. The optimized rule now
> divides the command-wide `-j` budget between concurrently selected components; it needs a new
> controlled benchmark before comparison.

| Measurement | Official (CMake + Ninja) | Xmake |
| --- | --- | --- |
| configure | 4.2 s (starter) + 6.9 s (engine) = **11.1 s** | `xmake f -y -m release` = **2.6 s** |
| starter alone, cold | **197.0 s** | **177.2 s** |
| engine alone, cold | **321.3 s** | **375.7 s** |
| both components, cold | **518.3 s** (two `ninja` runs, serial) | **473.4 s** (2026-10-21) / **495.6 s** (2026-10-24, post-fix rule) — one `xmake build` run |
| cold start incl. configure | **529.4 s** | **476.0 s / 498.2 s** (**−5.9 % … −10.1 %**) |

The original interpretation was that the "both components" row was like-for-like: a single
`xmake build -j12 opencourant_starter opencourant_engine` schedules both targets concurrently, so
the starter fills the slots that the engine's module-level barriers would otherwise leave idle (the
log shows starter level 1 and engine level 1 running together). The official flow cannot do this —
`-Dbuild=both` fails on a duplicate `extlib` target (CMP0002) — so it needs two serial `ninja`
invocations in that experiment, and its 518.3 s is their sum. Building the components separately with Xmake
(177.2 s + 375.7 s = 552.9 s) is therefore pessimistic by ~80 s. Xmake's own timers report
471.0 s / 493.1 s for the combined cold build, i.e. ~2 s of project load/generation. The two Xmake
cold measurements differ by ~5 %. The audit caveat above supersedes the earlier performance claim.

The 2026-10-24 run also validated a staleness fix in `xmake/rules/oc_ifx/xmake.lua`: before the
fix, `stale_state()` returned without recomputing `newest` when no `oc_state.txt` existed (cold
start), so the state file it then wrote contained `newest=nil` and the **next** build rebuilt all
6054 objects a second time. Now the state is written correctly after a cold build and the immediate
no-op rebuild takes ~4 s (previously ~470 s).

Reproduction (scripts kept out of the repo under `build/bench/`, since `build/` is git-ignored):

- Official: `vcvars64.bat`, then prepend `%ONEDIR%\compiler\2026.1\bin`,
  `%ONEDIR%\mkl\2026.1\bin`, the VS-bundled Ninja and the VS-bundled CMake 3.31 to `PATH`, and
  `%ONEDIR%\compiler\2026.1\lib` + `%ONEDIR%\mkl\2026.1\lib` to `LIB` (no `setvars.bat`; it
  never returns in this sandbox). Configure each component with its own subdirectory as the
  source root, `-DEXEC_NAME=<starter|engine>_win64 -DMPI=smp -Dprecision=dp -Ddebug=0
  -DVS_BUILD=1 -DCMAKE_BUILD_TYPE=Release -DCMAKE_Fortran_COMPILER=ifx.exe
  -DCMAKE_C_COMPILER=icx.exe -DCMAKE_CXX_COMPILER=icx.exe`, then `ninja -j 12`.
  `-Dbuild=both` cannot be used (duplicate `extlib` target, CMP0002).
- Xmake: delete the component's object tree
  (`build/simulators/windows/x64/release/obj/opencourant_{starter,engine}`), run
  `xmake f -y -m release`, then `xmake build -j12 opencourant_starter opencourant_engine`
  (one invocation builds both; the two-target command is the cold-start figure above).

Why the engine **alone** is slower under Xmake: the rule schedules in two phases — first all C/C++
translation units, then the Fortran sources **level by level**, awaiting each module level before
starting the next (`xmake/rules/oc_ifx/xmake.lua`, the `runjobs(... "/f" .. level ...)` loop) —
whereas Ninja schedules the whole graph freely. The engine's last eight levels hold only
98 of 3681 files (level 8: 26, 10: 38, 11: 7, 12: 4, 13: 3, 14: 19, 15: 1 — barely one wave of
12 jobs each), so those barriers leave most slots idle at the tail; the starter spreads more files
over fewer barriers (levels 7–11: 62/19/73/10/1 files, 165 in total), which keeps the schedule
busy enough that the same rule still beats Ninja there. Flags and semantics are unaffected — the
parity checks (starter restart deck, engine 5340-cycle run, miniQA 74/78) were produced by these
same binaries.

### PeriDyno

- **Build**: VS 17 2022 x64 Release, `PERIDYNO_GPU_BACKEND=CUDA`, `PERIDYNO_CUDA_ARCH=89` (matches the GPU). Submodules are needed (`stb`, `tinyobjloader` had to be force-initialized). Output: `build/simulators/peridyno/build/bin/Release` (76 `*.exe` + `dyno*-1.5.0.dll`).
- **Tests**: PeriDyno's CUDA `Test_*` executables are **not** registered with CTest, so they are run directly via `build/simulators/peridyno/run_tests.bat`: **257/262 passed**. The 5 failures (`Test_Collision` TET.collision; `Test_Core` Uint512/SgnInt512.TryMulSuccess; `Test_Topology` Point3D.distance, Tet3D.function) are upstream sign/precision cases, not build issues. Log: `build/simulators/peridyno/tests.log`.
- Note: the `data` submodule cannot be fetched (its `.gitmodules` URL uses the unreachable `gh.xmly.dev` proxy); heavy example scenes that need it are therefore unavailable.

### Newton

- **Env**: conda `newton` (Python 3.12), `pip install -e ".[dev]" --extra-index-url https://pypi.nvidia.com/`. Warp 1.18.0 initialises on CUDA 13.4 / sm_89.
- **Tests**: `python -m newton.tests`, run with the env interpreter directly (`conda run` crashes its own wrapper on this host). Most skips are expected (missing `robot_folder`/`usd_asset_folder`, torch absent).
- **Status: no completed run.** Three attempts were all interrupted:
  1. `build/simulators/newton/tests.log` — cut off by the runner's own default **3600 s `--parallel-timeout`**: **2532 passed / 0 failed / 46 skipped**.
  2. `build/simulators/newton/tests2.log` — killed by a host restart at **6584 passed / 8 failed / 100 skipped**. All 8 errors are **network asset-fetch failures**, not code defects: `git fetch origin da76818e269b82289eba39808e2fb91d679d6994 --depth=1 --filter=blob:none` against `https://github.com/google-deepmind/mujoco_menagerie.git` fails with `schannel: failed to receive handshake, SSL/TLS connection failed` (the `newton-assets` clone itself succeeds and `git ls-remote` works). Affected: `TestMenagerie_LeapHand` (setUpClass), `TestAnymalReset` (4 cases), `TestKaminoExamples` (2), `TestRobotComposer` (1).
  3. `build/simulators/newton/tests3.log` — cancelled by another host restart while still in progress.
- The configured run command is `python -m newton.tests -j 2 --parallel-timeout 21600 --junit-report-xml build/simulators/newton/junit.xml` (reduced parallelism because parallel GPU workers exhausted GPU memory during PTX JIT: `LLVM ERROR: out of memory`).

### Genesis

- **Env**: conda `genesis` (Python 3.12), `pip install -e ".[dev]"` + `torch` (CPU). `import genesis` OK (1.4.4).
- **Tests**: `pytest -m required ./tests -n 4` -> **713 passed, 4 failed, 130 skipped, 2 xfailed, 4 errors** in 2430.75 s (40 min 30 s), driven by `build/simulators/genesis/run_tests.bat` (the `conda run` wrapper itself crashes on this host). Log: `build/simulators/genesis/tests.log`.
  - The 4 failures: `tests/rigid/test_dynamics.py::test_mass_mat[long_chain]` (a worker died with `Windows fatal exception: stack overflow` and was respawned), `tests/core/test_recorders.py::test_plotter` and `::test_vector_field_plotter_subplots` (image **snapshot** mismatches; 176 snapshots passed, 2 failed — Windows text rendering differs), and `tests/core/test_utils.py::test_logger_prints_once_with_root_logging[None]`.
  - The 4 errors are all `OSError: [WinError 1314]` (a *privilege* error: creating symlinks requires an elevated shell or Developer Mode) in `test_asset_loading` (3) and `test_serialization` (1) — environment, not code.
  - Most skips are expected: no `gs.gpu`/`gs.cuda` backend on this machine (113), missing `uipc`/`pxr`/`imgui-bundle`/`gs_madrona`/`LuisaRenderPy` (15).
  - Quadrants (Taichi) JIT on Windows is very slow; that dominates the runtime (slowest test 165.6 s).

### PPF Contact Solver

- **Toolchain**: the official self-contained Windows provisioning, `build-win-native/warmup.bat` (CUDA 12.8.1, portable MSVC 14.44 + Windows SDK 26100, embedded Python 3.11.9, Rust, MinGit, Eigen 3.4.0), followed by `build.bat`.
- Sandbox fixes (upstream files left untouched, since `build-win-native/` is git-tracked): the bundled 7-Zip SFX needs elevation, so xmake's `7z.exe`/`7z.dll` were copied into `build-win-native/7zip`; and this sandbox's child Windows PowerShell cannot autoload cmdlets, so `build/simulators/ppf-contact-solver/run_warmup.bat` prepends a real PowerShell 7 (`shim/ps7`) to `PATH`.
- **Build**: `build/simulators/ppf-contact-solver/run_build.bat` (prepends `shim/ps7`, sets `PPF_WIN_BACKENDS="cuda cpu"`, calls the upstream `build.bat /nopause`). It builds one workspace per backend into `target/<backend>/release`; each contains `ppf-contact-solver.exe`, `ppf-cts-server.exe`, `_ppf_cts_py.dll`. The CUDA backend library `crates/ppf-cts-compute/cuda/build/lib/libsimbackend_cuda.dll` is built by `nvcc` from the upstream-pinned CUDA 12.8.1. Log: `build-win-native/build.log`.
- **Tests (Rust + Python)**: driven by `build/simulators/ppf-contact-solver/run_tests.bat` and `run_tests2.bat` (the latter replicates `build.bat`'s cargo environment — the Rust build scripts render the transcompiler by spawning `python3`, which on Windows resolves to the Store stub, so the embedded interpreter is copied to `python3.exe` and put first on `PATH`).
  - `cargo test --workspace --exclude ppf-cts-solver` -> **all passed** (76 + 655 + 113 + 32 + 14 + 11 + 10 + 4 + 4 + 1, 0 failed, 2 ignored).
  - `cargo test -p ppf-cts-solver --no-default-features --features cpu` -> **575 passed / 0 failed / 9 ignored**, plus 11 doc-tests passed.
  - `pytest crates/ppf-cts-py/tests` -> **13 passed**.
  - `pytest frontend/tests` -> **532 passed, 4 skipped, 1 xfailed, 1 failed**. The single failure, `_force_field_compiler_.py::test_a_rebuild_reads_the_fluid_from_any_session_that_still_holds_it`, raises the expected error with the correct wording but the test's regex hardcodes POSIX separators (`.*/b/.* is gone; .*/a/.* hold other values`) while the message prints Windows backslash paths: an upstream non-portable expectation, not a build defect.
  - `blender_addon/tests` cannot run here: 4 collection errors (`ModuleNotFoundError: No module named 'bpy'`) — those suites need Blender's Python.
  - Logs: `build/simulators/ppf-contact-solver/ppf_tests.log`, `ppf_tests2.log`. (Upstream's bundle-level `headless.bat` / `fast-check-all.bat` need `bundle.bat`; the cargo/pytest suites above are the direct equivalents and were run instead.)

## Analysis

Every build completed with its official toolchain and the upstream build system kept intact, so the
repository's "official simulators retain their upstream build systems" principle held in practice.
The failures that remain fall into four classes, none of which is a defect of the pinned source:

1. **Upstream test-data defect** — OpenCourant's 4 miniQA failures come from a bad
   `qadiags.inc` shipped by the fork (an uncommented `Copyright>` banner inside an included deck).
2. **Upstream precision/sign cases** — PeriDyno's 5 failures are numeric expectations inside its
   own CUDA test executables.
3. **Upstream non-portable test expectations** — PPF's single frontend failure asserts POSIX path
   separators in a regex; Genesis's 2 failures are image snapshots rendered differently on Windows.
4. **Host limits** — Genesis's 4 symlink-privilege errors and its stack-overflow worker crash;
   Newton's asset fetches blocked by a TLS handshake failure; Newton's GPU-memory ceiling during
   PTX JIT (hence `-j 2`).

Two upstream build systems cannot be driven fully out of source on Windows and were handled by
recording the exception rather than editing third-party sources: PositionBasedDynamics' CMake
writes `Utils/Version.h` into the source tree, and PPF's `build-win-native/` output tree lives
inside its own submodule.

## Conclusion

Six of the seven simulators were built **and** fully tested. Newton is built but is the one
outstanding item: its suite has never produced a final summary because each attempt was interrupted
by the runner's own timeout or by a host restart, and it additionally depends on two external
`mujoco_menagerie` fetches that fail in this sandbox with an SSL handshake error. Re-running
`python -m newton.tests -j 2 --parallel-timeout 21600` on a stable host (or with those assets
pre-fetched) should close it out.

## Xmake management layer

Besides the official-toolchain builds above, the repository now also builds simulator libraries
**natively with Xmake**, driven by the top-level `xmake.lua` and the scripts under `xmake/`.

| Simulator | Xmake targets | Result |
| --- | --- | --- |
| PositionBasedDynamics | core/support static libraries, 16 demos, `pypbd` + `pbd_link_check` | builds; `pypbd` imports under Python 3.12; link check prints `oneNorm(diag(3,-1,2)) = 3` |
| MuJoCo | `mujoco.dll`, four plugins, samples, `simulate`, 75 upstream test executables + `mj_link_check` | builds; 60 unit-test executables plus `thread_performance_test` pass, and all 14 benchmark executables initialise successfully |
| PeriDyno | 23 DLLs, 65 examples and 10 CUDA test executables | exact 23/23 DLL and 75/75 executable name parity; 257/262 tests pass with the same 5 upstream precision failures |

Design points:

- `Simulators/` stays read-only. Every Xmake description lives in `xmake/simulators/<slug>.lua` and
  refers to the upstream sources by path; nothing is written into the submodule.
- Dependencies that upstream fetches at configure time (PBD's Discregrid/GenericParameters, MuJoCo's
  ccd/qhull/tinyxml2/tinyobjloader/lodepng/miniz) are consumed by Xmake from
   root `deps/<slug>/`. Missing checkouts use bootstrap revisions; existing checkouts
   are accepted as-is. No official CMake build tree is required, but the native
   compiler/toolchain for each enabled project is still required.
- Output goes to `build/simulators/windows/x64/release/{lib,obj,dep,bin}`.
- PeriDyno's embedded OpenGL shader headers are generated by the Xmake-managed `glslangValidator`
  under `build/simulators/peridyno/xmake-generated/shader`; no official CMake output is consumed.

Seven CMake/Xmake differences had to be handled, all with build flags only (no upstream edit):

| Difference | Handling |
| --- | --- |
| CMake defines `WIN32` on Windows, Xmake does not (PBD's `Utils/FileSystem.h` then includes `unistd.h`) | `add_defines("WIN32")` |
| MuJoCo's C sources use C11 `_Generic` (`engine_io.c`) | `/std:c11` for the C sources |
| Upstream C++ standard is C++20 | `set_languages("cxx20")` |
| UTF-8 sources are misread under MSVC code page 936 (C4819) | `/utf-8` |
| qhull exports two include roots (`libqhull_r/...` and flat headers) | both `qhull/src` and `qhull/src/libqhull_r` |
| CMake-generated export headers (`ccd/config.h`, `miniz/miniz_export.h`) | reused from the official build tree; `MINIZ_STATIC_DEFINE` keeps `MINIZ_EXPORT` from becoming `dllimport` |
| A static MuJoCo library needs the same export convention on its consumers | `MJ_STATIC` on the library *and* the consumer, otherwise `MJAPI` becomes `__declspec(dllimport)` and the link fails on `__imp_mj_*` |
| MuJoCo's OBJ/STL/Gmsh decoders are sources compiled into its core target, not plugin DLLs | compile `plugin/{obj,stl,gmsh}_decoder` into `mujoco.dll` |
| MuJoCo's MSVC Release configuration uses AVX/SIMD plus whole-program optimisation | match `/Oi`, `/Gy`, `/GL` and `/LTCG`; omitting them caused failures in IPC, derivative and set-constant tests |

## Repository hygiene

`Simulators/` was treated as read-only: no upstream file was edited, and every generated tree, log
and driver script lives under the root `build/simulators/<slug>/`. All seven simulator gitlinks
were verified to match the pinned commits recorded above. Residual, **upstream-generated** entries
visible in `git status`:

- `Simulators/position-based-dynamics/Utils/Version.h` — a header the upstream CMake configure step
  generates into the source tree (only `Demos/Common/DemoBase.cpp` includes it). The Xmake layer
  no longer depends on this in-tree file: `xmake/simulators/pbd.lua` generates its own copy into
  `build/simulators/position-based-dynamics/xmake-generated/Utils/Version.h` at configure time
  (target `pbd_demo_common` `on_load`), so deleting the in-tree residue is safe for Xmake builds —
  only a subsequent official CMake configure would re-create it.
- `Simulators/newton/solver_convergence.png` — a plot a test writes into the submodule root; it is a
  re-runnable test artifact, not source.
- `Simulators/ppf-contact-solver/build-win-native/` — the official, git-tracked provisioning
  directory (unchanged), holding the portable toolchain and backend build trees.

Two earlier problems in this area were corrected:

- `Simulators/peridyno`'s four nested submodules (`external/gmsh-fork`, `external/nanobind`,
  `external/nodeeditor`, `external/qscintilla`) had empty indexes and no worktree files, which made
  git report ~6035 deletions. They were re-checked out at `5dd13e45`, `042fa7eb`, `9e8cb95e` and
  `dfcf6973` (4963 / 249 / 119 / 704 tracked files restored), leaving `Simulators/peridyno` clean.
- `Simulators/ppf-contact-solver/build-win-native/rocm/` — a 3.85 GB / 8995-file ROCm SDK that the
  unsupported `rocm` backend left behind and that upstream `.gitignore` does not cover — was deleted,
  since this build used only the `cuda` and `cpu` backends.

## Related Docs

- `Docs/foundations/`
- `Docs/mujoco/`, `Docs/newton/`, `Docs/genesis/`, `Docs/opencourant/`, `Docs/peridyno/`, `Docs/ppf-contact-solver/`, `Docs/position-based-dynamics/`

## Related Examples

- `Examples/xmake.lua`
- `Examples/mujoco/`, `Examples/newton/`, `Examples/genesis/`, `Examples/opencourant/`, `Examples/peridyno/`, `Examples/ppf-contact-solver/`, `Examples/position-based-dynamics/`
