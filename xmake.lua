-- Simulator Learning - top-level Xmake entry point.
--
-- This repository is now compiled through Xmake. This file is the single entry
-- point; running `xmake` here builds the managed targets. Xmake modules and
-- per-simulator build descriptions live under xmake/; Examples/ and
-- Experiments/ sub-projects are attached with includes().
--
-- Hard constraints honored here:
--   * Simulators/ stays read-only; the xmake descriptions under xmake/simulators/
--     reference the upstream sources by path and never write into them.
--   * All generated output goes under the root build/ tree (see xmake/paths.lua).

set_project("simulator-learning")
-- Minimum feature level, not a project/dependency version lock. Xmake 3.1
-- provides the APIs and Intel ifx toolchain used by this build layer.
set_xmakever("3.1.0")

add_rules("mode.debug", "mode.release")
set_defaultmode("release")

-- Apply the standard release flags (e.g. /DNDEBUG) instead of dropping them,
-- so a release build matches the semantics of the upstream CMake Release builds.
set_policy("check.auto_ignore_flags", false)

-- Keep heavy, platform-specific projects opt-in. set_default(false) only keeps
-- a target out of a default build; it does not prevent its script, tool checks
-- and packages from loading during configuration.
for _, item in ipairs({
    {"pbd",          true,  "Build PositionBasedDynamics targets"},
    {"mujoco",       true,  "Build MuJoCo targets and tests"},
    {"peridyno",     false, "Build PeriDyno CUDA targets"},
    {"opencourant",  false, "Build OpenCourant (Windows x64 Release only)"},
}) do
    option("with_" .. item[1])
        set_default(item[2])
        set_showmenu(true)
        set_description(item[3])
    option_end()
end

option("with_pypbd")
    set_default(false)
    set_showmenu(true)
    set_description("Build PBD Python bindings (requires pbd_python_root)")
option_end()

option("with_mujoco_tests")
    set_default(false)
    set_showmenu(true)
    set_description("Build MuJoCo unit-test and benchmark executables")
option_end()

option("pbd_python_root")
    set_default(os.getenv("PBD_PYTHON_ROOT") or "")
    set_showmenu(true)
    set_description("Python installation root used by pypbd")
option_end()

option("peridyno_cuda_arch")
    set_default(os.getenv("PERIDYNO_CUDA_ARCH") or "89")
    set_showmenu(true)
    set_description("CUDA SM architecture for PeriDyno, without the sm_ prefix")
option_end()

option("peridyno_cuda_sdk")
    set_default(os.getenv("CUDA_PATH") or "")
    set_showmenu(true)
    set_description("CUDA Toolkit root used by PeriDyno")
option_end()

option("opencourant_python")
    set_default(os.getenv("OPENCOURANT_PYTHON") or "")
    set_showmenu(true)
    set_description("Python executable for OpenCourant code generation (empty: search PATH)")
option_end()

if (has_config("with_mujoco") and has_config("with_mujoco_tests")) or
   has_config("with_peridyno") then
    add_requires("gtest")
end
if has_config("with_mujoco") and has_config("with_mujoco_tests") then
    add_requires("benchmark", "abseil")
end
if has_config("with_peridyno") then
    -- Build-time tool only; simulator code does not link glslang libraries.
    add_requires("glslang", {configs = {tools = true, binaryonly = true}})
end

-- Path helpers (ROOT / SIMULATORS / build output conventions).
includes("xmake/paths.lua")

if has_config("with_opencourant") then
    includes("xmake/toolchains.lua")
end

-- Managed simulator builds (read-only upstream sources, built natively by Xmake).
if has_config("with_pbd") then includes("xmake/simulators/pbd.lua") end
if has_config("with_mujoco") then includes("xmake/simulators/mujoco.lua") end
if has_config("with_peridyno") then includes("xmake/simulators/peridyno.lua") end
if has_config("with_opencourant") then includes("xmake/simulators/opencourant.lua") end
