-- MuJoCo core library, built natively by Xmake from read-only upstream sources.
--
-- The upstream CMake build pulls its third-party dependencies with
-- FetchContent at configure time. Xmake instead consumes the same
-- sources from deps/mujoco/ (restored automatically when missing), so this
-- build is self-sufficient and never writes into Simulators/mujoco.
--
-- Scope: the core library (engine + user + xml + mjz + render/noop +
-- render/classic + ui). Plugins, the simulate app, studio, filament and USD
-- support are deliberately out of scope for now.

local MJ    = path.join(SIMULATORS, "mujoco")
-- Source-level third-party clones (not build output) live under the root
-- deps/ tree so that cleaning build/ never removes them. The on_load hook
-- below restores missing checkouts at revisions declared by upstream CMake.
local DEPS  = path.join(ROOT, "deps", "mujoco")

local CCD   = path.join(DEPS, "ccd")
local QHULL = path.join(DEPS, "qhull")
local TXML  = path.join(DEPS, "tinyxml2")
local TOBJ  = path.join(DEPS, "tinyobjloader")
local LPNG  = path.join(DEPS, "lodepng")
local MINIZ = path.join(DEPS, "miniz")
local MCC   = path.join(DEPS, "marchingcubecpp")

-- CMake-configured headers that must exist but are not in the upstream clones
-- (ccd/config.h). Generated under build/, never into Simulators/.
local MJ_GEN = path.join(BUILD, "simulators", "mujoco", "xmake-generated")
-- miniz.h includes "miniz_export.h" flat, so the generated miniz/ subdir is
-- an include root of its own.
local MINIZ_GEN = path.join(MJ_GEN, "miniz")

local MJ_INC = path.join(MJ, "include")
local MJ_SRC = path.join(MJ, "src")

-- Revisions used only for missing checkouts. Existing trees are accepted
-- as-is; this table is a bootstrap compatibility baseline, not a project lock.
local MJ_DEPS = {
    {"ccd", "https://github.com/danfis/libccd.git", "7931e764a19ef6b21b443376c699bbc9c6d4fba8"},
    {"qhull", "https://github.com/qhull/qhull.git", "d1c2fc0caa5f644f3a0f220290d4a868c68ed4f6"},
    {"tinyxml2", "https://github.com/leethomason/tinyxml2.git", "e6caeae85799003f4ca74ff26ee16a789bc2af48"},
    {"tinyobjloader", "https://github.com/tinyobjloader/tinyobjloader.git", "2945a967c5303b2c8c14174117c45f3302591150"},
    {"lodepng", "https://github.com/lvandeve/lodepng.git", "22561883dd63fd1850f18e1f6adac321e4f609b0"},
    {"miniz", "https://github.com/richgel999/miniz.git", "77d0dce8627735138c51770d1799a1ef48f2117d"},
    {"marchingcubecpp", "https://github.com/aparis69/MarchingCubeCpp.git", "f03a1b3ec29b1d7d865691ca8aea4f1eb2c2873d"},
    {"glfw3", "https://github.com/glfw/glfw.git", "7b6aead9fb88b3623e3b3725ebb42670cbe4c579"},
}

local function mj_ensure_deps(target)
    import("xmake.dependencies", {rootdir = os.projectdir()})
    -- CMake-configured headers (upstream configures ccd/config.h and
    -- miniz/miniz_export.h during its own configure); generate them under
    -- build/, never into the clones.
    local ccd_config = path.join(MJ_GEN, "ccd", "config.h")
    if not os.isfile(ccd_config) then
        io.writefile(ccd_config, table.concat({
            "#ifndef __CCD_CONFIG_H__",
            "#define __CCD_CONFIG_H__",
            "",
            "/* MuJoCo builds libccd in double precision. */",
            "#define CCD_DOUBLE",
            "",
            "#endif /* __CCD_CONFIG_H__ */",
        }, "\n") .. "\n")
    end
    local miniz_export = path.join(MJ_GEN, "miniz", "miniz_export.h")
    if not os.isfile(miniz_export) then
        -- Static build (MINIZ_STATIC_DEFINE everywhere): the export macros
        -- expand to nothing, which is exactly what upstream's generated
        -- header does for its static configuration.
        io.writefile(miniz_export, table.concat({
            "#ifndef MINIZ_EXPORT_H",
            "#define MINIZ_EXPORT_H",
            "",
            "#define MINIZ_EXPORT",
            "#define MINIZ_NO_EXPORT",
            "",
            "#endif /* MINIZ_EXPORT_H */",
        }, "\n") .. "\n")
    end
    local missing = false
    for _, dep in ipairs(MJ_DEPS) do
        local dst = path.join(DEPS, dep[1])
        if not os.isdir(path.join(dst, ".git")) and os.exists(dst) then
            raise("mujoco: dependency path exists but is not a git checkout: " .. dst)
        elseif not os.isdir(path.join(dst, ".git")) then
            missing = true
        end
    end
    if not missing then return end
    os.mkdir(DEPS)
    for _, dep in ipairs(MJ_DEPS) do
        local dst = path.join(DEPS, dep[1])
        dependencies.ensure_checkout(dst, dep[2], dep[3])
    end
    raise("mujoco: dependencies cloned into " .. DEPS ..
          "; please re-run `xmake f` so the new sources are picked up")
end

-- ------------------------------------------------------------------
-- Third-party dependencies (all static, mirroring the upstream setup)
-- ------------------------------------------------------------------

target("mj_dep_ccd")
    set_kind("static")
    set_default(false)
    on_load(mj_ensure_deps)
    add_files(path.join(CCD, "src", "*.c"))
    add_includedirs(path.join(CCD, "src"), MJ_GEN)
    add_defines("CCD_STATIC_DEFINE", "CCD_HIDE_ALL_SYMBOLS")
    if is_plat("windows") then
        -- libCCD unconditionally redefines _CRT_SECURE_NO_WARNINGS (MSVC C4005).
        add_cflags("/wd4005")
    end
    set_targetdir(build_out("simulators", "lib"))
    set_objectdir(build_out("simulators", "obj"))
    set_dependir(build_out("simulators", "dep"))

target("mj_dep_qhull")
    set_kind("static")
    set_default(false)
    add_files(path.join(QHULL, "src", "libqhull_r", "*.c"))
    add_includedirs(path.join(QHULL, "src", "libqhull_r"))
    set_targetdir(build_out("simulators", "lib"))
    set_objectdir(build_out("simulators", "obj"))
    set_dependir(build_out("simulators", "dep"))

target("mj_dep_tinyxml2")
    set_kind("static")
    set_default(false)
    set_languages("cxx14")
    add_files(path.join(TXML, "tinyxml2.cpp"))
    add_includedirs(TXML)
    set_targetdir(build_out("simulators", "lib"))
    set_objectdir(build_out("simulators", "obj"))
    set_dependir(build_out("simulators", "dep"))

target("mj_dep_tinyobjloader")
    set_kind("static")
    set_default(false)
    set_languages("cxx14")
    add_files(path.join(TOBJ, "tiny_obj_loader.cc"))
    add_includedirs(TOBJ)
    set_targetdir(build_out("simulators", "lib"))
    set_objectdir(build_out("simulators", "obj"))
    set_dependir(build_out("simulators", "dep"))

target("mj_dep_lodepng")
    set_kind("static")
    set_default(false)
    set_languages("cxx14")
    add_files(path.join(LPNG, "lodepng.cpp"))
    add_includedirs(LPNG)
    set_targetdir(build_out("simulators", "lib"))
    set_objectdir(build_out("simulators", "obj"))
    set_dependir(build_out("simulators", "dep"))

target("mj_dep_miniz")
    set_kind("static")
    set_default(false)
    add_files(path.join(MINIZ, "miniz.c"))
    add_files(path.join(MINIZ, "miniz_tdef.c"))
    add_files(path.join(MINIZ, "miniz_tinfl.c"))
    add_files(path.join(MINIZ, "miniz_zip.c"))
    add_includedirs(MINIZ, MJ_GEN, MINIZ_GEN)
    -- miniz_export.h is a generated export header; for a static build it must
    -- see MINIZ_STATIC_DEFINE, otherwise MINIZ_EXPORT becomes __declspec(dllimport).
    add_defines("MINIZ_STATIC_DEFINE")
    set_targetdir(build_out("simulators", "lib"))
    set_objectdir(build_out("simulators", "obj"))
    set_dependir(build_out("simulators", "dep"))

-- GLFW (Win32 backend) for the windowed samples and the simulate app, built
-- from the pinned upstream sources (GLFW 3.4).
target("mj_glfw")
    set_kind("static")
    set_default(false)
    add_files(path.join(DEPS, "glfw3", "src", "*.c"))
    remove_files(
        path.join(DEPS, "glfw3", "src", "cocoa_*"),
        path.join(DEPS, "glfw3", "src", "glx_*"),
        path.join(DEPS, "glfw3", "src", "linux_*"),
        path.join(DEPS, "glfw3", "src", "posix_*"),
        path.join(DEPS, "glfw3", "src", "wl_*"),
        path.join(DEPS, "glfw3", "src", "x11_*"),
        path.join(DEPS, "glfw3", "src", "xkb_*")
    )
    add_includedirs(path.join(DEPS, "glfw3", "include"))
    -- GLFW 3.4's platform.c references the null backend's connect function in
    -- _glfwSelectPlatform (the null platform is the universal fallback), so the
    -- null_* sources are kept and _GLFW_NULL is defined alongside _GLFW_WIN32
    -- (win32 remains the preferred platform). PBD's GLFW is 3.3 (no platform.c)
    -- and does not need this.
    add_defines("_GLFW_WIN32", "_GLFW_NULL")
    set_targetdir(build_out("simulators", "lib"))
    set_objectdir(build_out("simulators", "obj"))
    set_dependir(build_out("simulators", "dep"))

-- ------------------------------------------------------------------
-- Core library
-- ------------------------------------------------------------------

target("mujoco")
    set_kind("shared")
    set_default(true)
    set_languages("cxx20", "c11")
    -- Generates ccd/config.h and miniz/miniz_export.h before this target's
    -- sources compile (target load order is not guaranteed across targets).
    on_load(mj_ensure_deps)
    -- engine / user / model IO
    -- The engine directory mixes C (.c) and C++ (.cc) sources: engine_plugin.cc
    -- holds the resource-provider/decoder registry and engine_thread.cc holds
    -- mju_numThread, so both globs are required.
    add_files(path.join(MJ_SRC, "engine", "*.c"))
    add_files(path.join(MJ_SRC, "engine", "*.cc"))
    add_files(path.join(MJ_SRC, "user", "*.cc"))
    -- user_init.c defines the built-in default spec/plugin/skin resources
    -- (mjs_defaultSpec, mjs_defaultSkin, mjs_defaultPlugin).
    add_files(path.join(MJ_SRC, "user", "*.c"))
    -- XML front end and the binary (mjz) format
    add_files(path.join(MJ_SRC, "xml", "*.cc"))
    add_files(path.join(MJ_SRC, "xml", "mjz", "*.cc"))
    -- Mesh decoders are compiled directly into libmujoco upstream (their
    -- plugin/*_decoder/CMakeLists.txt adds the source to the mujoco target,
    -- they are not separate DLLs).  Without them every .obj/.stl/.msh mesh
    -- fails at runtime with "no decoder found".  tinyobjloader's
    -- implementation lives in mj_dep_tinyobjloader, so the define that
    -- upstream sets here would produce duplicate symbols.
    add_files(path.join(MJ, "plugin", "obj_decoder", "obj_decoder.cc"))
    add_files(path.join(MJ, "plugin", "stl_decoder", "stl_decoder.cc"))
    add_files(path.join(MJ, "plugin", "gmsh_decoder", "gmsh_decoder.cc"))
    -- renderers: the classic OpenGL renderer. render/noop is a SEPARATE optional
    -- static library upstream (mujoco::render_noop) that consumers link INSTEAD
    -- of the classic one for headless use; it defines the same mjr_* symbols and
    -- must NOT be part of libmujoco (a static lib tolerates the duplicates, a
    -- shared DLL does not).
    add_files(path.join(MJ_SRC, "render", "classic", "*.c"))
    add_files(path.join(MJ_SRC, "render", "classic", "glad", "glad.c"))
    add_files(path.join(MJ_SRC, "render", "classic", "glad", "loader.cc"))
    -- native user interface
    add_files(path.join(MJ_SRC, "ui", "*.c"))
    -- Public so that plugins, samples and the simulate app get the public
    -- headers (mujoco/*.h) just by linking this target.
    add_includedirs(MJ_INC, {public = true})
    add_includedirs(
        MJ_SRC,
        path.join(CCD, "src"),
        MJ_GEN,
        -- qhull exports two include roots: "src" (so that
        -- #include "libqhull_r/qhull_ra.h" resolves) and "src/libqhull_r"
        -- (for the flat libqhull_r headers upstream also adds).
        path.join(QHULL, "src"),
        path.join(QHULL, "src", "libqhull_r"),
        TXML,
        TOBJ,
        LPNG,
        MINIZ,
        MINIZ_GEN,
        MCC
    )
    -- Shared build: MUJOCO_DLL_EXPORTS makes mjexport.h expand MJAPI to
    -- __declspec(dllexport). The third-party libraries stay statically linked
    -- into the DLL.
    add_defines(
        "MUJOCO_DLL_EXPORTS", "CCD_STATIC_DEFINE", "MC_IMPLEM_ENABLE",
        "TINYOBJLOADER_IMPLEMENTATION", "_GNU_SOURCE",
        "_CRT_SECURE_NO_WARNINGS", "_CRT_SECURE_NO_DEPRECATE",
        "_FILE_OFFSET_BITS=64", "WIN32", "_WINDOWS"
    )
    -- Upstream defines mjUSEPLATFORMSIMD PUBLIC on the mujoco target.  It
    -- enables the AVX code paths in engine_support.c and
    -- engine_core_constraint.c when the TU is also compiled with __AVX__.
    add_defines("mjUSEPLATFORMSIMD", {public = true})
    -- miniz is linked statically, so its generated export header must not
    -- resolve MINIZ_EXPORT to __declspec(dllimport).
    add_defines("MINIZ_STATIC_DEFINE")
    -- Upstream builds the C sources as C11 (engine_io.c uses _Generic) and the
    -- C++ sources as C++20. /utf-8 is required because several headers contain
    -- UTF-8 text that MSVC would otherwise misread under code page 936.
    if is_plat("windows") then
        add_cflags("/std:c11")
        -- Matches CMake's EnableEnhancedInstructionSet=AVX for this target.
        -- Match CMake's actual Release command line: /O2 /Ob2 /Oi /GL /Gy.
        -- /GL also requires /LTCG at link time.
        add_cxflags("/utf-8", "/arch:AVX")
        if is_mode("release") then
            add_cxflags("/Oi", "/Gy", "/GL")
            add_ldflags("/LTCG")
        end
    end
    add_deps("mj_dep_ccd", "mj_dep_qhull", "mj_dep_tinyxml2",
             "mj_dep_tinyobjloader", "mj_dep_lodepng", "mj_dep_miniz")
    -- Put the DLL next to the executables so they find it at runtime.
    set_targetdir(build_out("simulators", "bin"))
    set_objectdir(build_out("simulators", "obj"))
    set_dependir(build_out("simulators", "dep"))

-- Optional headless renderer (upstream's separate mujoco::render_noop static
-- library): a stub of the mjr_* API that a consumer links INSTEAD of the
-- classic renderer for headless use. Kept out of libmujoco, matching upstream.
target("mujoco_render_noop")
    set_kind("static")
    set_default(false)
    set_languages("c11")
    add_files(path.join(MJ_SRC, "render", "noop", "*.c"))
    add_includedirs(MJ_INC, MJ_SRC)
    add_deps("mujoco")
    if is_plat("windows") then
        add_cflags("/std:c11", "/utf-8")
    end
    set_targetdir(build_out("simulators", "lib"))
    set_objectdir(build_out("simulators", "obj"))
    set_dependir(build_out("simulators", "dep"))

-- End-to-end check: load a model and read it back through the Xmake-built library.
target("mj_link_check")
    set_kind("binary")
    set_default(true)
    set_languages("cxx20")
    add_files(path.join(ROOT, "xmake", "checks", "mj_link_check.cpp"))
    add_includedirs(MJ_INC)
    add_deps("mujoco")
    add_tests("smoke")
    set_targetdir(build_out("simulators", "bin"))
    set_objectdir(build_out("simulators", "obj"))
    set_dependir(build_out("simulators", "dep"))

-- ---------------------------------------------------------------------------
-- Plugins: the four DLLs the official build produces. They self-register via a
-- CRT section initializer (mjPLUGIN_LIB_INIT), so they only need to link the
-- core library.
-- ---------------------------------------------------------------------------

local function mj_plugin(name, srcdir, sources)
    target("mj_plugin_" .. name)
        set_kind("shared")
        set_default(true)
        set_languages("cxx20", "c11")
        for _, f in ipairs(sources) do
            add_files(path.join(srcdir, f))
        end
        add_includedirs(MJ_INC, MJ_SRC)
        add_deps("mujoco")
        -- Name the DLL like the official one (actuator.dll, sdf_plugin.dll...).
        set_basename(name)
        if is_plat("windows") then
            add_cflags("/std:c11", "/utf-8")
        end
        set_targetdir(build_out("simulators", "bin"))
        set_objectdir(build_out("simulators", "obj"))
        set_dependir(build_out("simulators", "dep"))
end

mj_plugin("actuator",   path.join(MJ, "plugin", "actuator"),   {"pid.cc", "register.cc"})
mj_plugin("elasticity", path.join(MJ, "plugin", "elasticity"), {"elasticity.cc", "cable.cc", "register.cc"})
mj_plugin("sensor",     path.join(MJ, "plugin", "sensor"),     {"touch_grid.cc", "register.cc"})
mj_plugin("sdf_plugin", path.join(MJ, "plugin", "sdf"),
          {"sdf.cc", "bolt.cc", "bowl.cc", "gear.cc", "nut.cc", "torus.cc", "register.cc"})

-- ---------------------------------------------------------------------------
-- Samples: the six programs the official build produces. basic and record open
-- a GLFW window; render needs an OpenGL context.
-- ---------------------------------------------------------------------------

local function mj_sample(name, opts)
    opts = opts or {}
    target("mj_sample_" .. name)
        set_kind("binary")
        set_default(true)
        set_languages("cxx20", "c11")
        add_files(path.join(MJ, "sample", name .. ".cc"))
        add_includedirs(MJ_INC, MJ_SRC, LPNG, path.join(DEPS, "glfw3", "include"))
        add_deps("mujoco")
        if opts.glfw then
            add_deps("mj_glfw")
        end
        if opts.gl and is_plat("windows") then
            add_syslinks("opengl32", "gdi32", "shell32", "user32")
        end
        -- Name the exe like the official one (basic.exe, testspeed.exe...).
        set_basename(name)
        if is_plat("windows") then
            add_cflags("/std:c11", "/utf-8")
        end
        set_targetdir(build_out("simulators", "bin"))
        set_objectdir(build_out("simulators", "obj"))
        set_dependir(build_out("simulators", "dep"))
end

mj_sample("basic",        {glfw = true, gl = true})
mj_sample("compile",      {})
mj_sample("dependencies", {})
mj_sample("record",       {glfw = true, gl = true})
-- render.cc is NOT part of the official default build: it pulls in the Filament
-- renderer (render/filament/...), which is out of scope. The official output
-- likewise has no render.exe.
mj_sample("testspeed",    {})

-- ---------------------------------------------------------------------------
-- simulate: the official GUI application. Upstream builds it from main.cc plus
-- a platform_ui_adapter OBJECT library (glfw_adapter / glfw_dispatch /
-- platform_ui_adapter) and libmujoco_simulate; we compile those sources
-- directly into the executable instead. The macOS .mm files and the
-- dist/simulate.rc version/icon resource (which would need a file copied into
-- the read-only source tree) are omitted.
-- ---------------------------------------------------------------------------
target("mj_simulate")
    set_kind("binary")
    set_default(true)
    set_languages("cxx20", "c11")
    add_files(path.join(MJ, "simulate", "main.cc"))
    add_files(path.join(MJ, "simulate", "simulate.cc"))
    add_files(path.join(MJ, "simulate", "glfw_adapter.cc"))
    add_files(path.join(MJ, "simulate", "glfw_dispatch.cc"))
    add_files(path.join(MJ, "simulate", "platform_ui_adapter.cc"))
    add_includedirs(MJ_INC, MJ_SRC, path.join(MJ, "simulate"), LPNG,
                    path.join(DEPS, "glfw3", "include"))
    add_deps("mujoco", "mj_glfw", "mj_dep_lodepng")
    set_basename("simulate")
    if is_plat("windows") then
        add_cflags("/std:c11", "/utf-8")
        add_syslinks("opengl32", "gdi32", "shell32", "user32")
    end
    set_targetdir(build_out("simulators", "bin"))
    set_objectdir(build_out("simulators", "obj"))
    set_dependir(build_out("simulators", "dep"))

-- ---------------------------------------------------------------------------
-- Test suite: the *test / *benchmark executables from the official build.
-- Test-framework dependencies (gtest, benchmark, abseil) come from xmake-repo
-- (via add_requires at the top of this file); the simulator itself is built
-- from the pinned upstream sources.
-- ---------------------------------------------------------------------------
if has_config("with_mujoco_tests") then
local TEST = path.join(MJ, "test")

-- Shared test fixture (test/fixture.cc), built like upstream.
target("mj_test_fixture")
    set_kind("static")
    set_default(false)
    set_languages("cxx20", "c11")
    add_files(path.join(TEST, "fixture.cc"))
    add_includedirs(MJ, TEST, MJ_SRC, path.join(CCD, "src"), MJ_GEN, path.join(QHULL, "src"), path.join(QHULL, "src", "libqhull_r"), TXML, TOBJ, LPNG, MINIZ, MINIZ_GEN, MCC)
    -- MJSTATIC matches upstream (it is a different macro from mjexport.h's
    -- MJ_STATIC, so it does not change the export convention).
    add_defines("MJSTATIC", "CCD_STATIC_DEFINE", "MC_IMPLEM_ENABLE", "MINIZ_STATIC_DEFINE")
    add_deps("mujoco")
    -- fixture.h includes gmock/gmock.h, so the fixture needs gtest too.
    add_packages("abseil", "gtest")
    if is_plat("windows") then add_cflags("/std:c11", "/utf-8") end
    set_targetdir(build_out("simulators", "lib"))
    set_objectdir(build_out("simulators", "obj"))
    set_dependir(build_out("simulators", "dep"))

-- boxbox_legacy: a helper library used only by engine_collision_box_test.
target("mj_test_boxbox_legacy")
    set_kind("static")
    set_default(false)
    set_languages("c11")
    add_files(path.join(TEST, "engine", "boxbox_legacy.c"))
    add_includedirs(MJ, MJ_SRC)
    add_defines("MJSTATIC", "CCD_STATIC_DEFINE", "MC_IMPLEM_ENABLE", "MINIZ_STATIC_DEFINE")
    add_deps("mujoco")
    if is_plat("windows") then add_cflags("/std:c11", "/utf-8") end
    set_targetdir(build_out("simulators", "lib"))
    set_objectdir(build_out("simulators", "obj"))
    set_dependir(build_out("simulators", "dep"))

-- compare_model / compare_spec: helper libraries defined by upstream's
-- test/CMakeLists.txt and linked by several tests.
target("mj_test_compare_model")
    set_kind("static")
    set_default(false)
    set_languages("cxx20", "c11")
    add_files(path.join(TEST, "compare_model.cc"))
    add_includedirs(MJ, TEST, MJ_SRC, path.join(CCD, "src"), MJ_GEN, path.join(QHULL, "src"), path.join(QHULL, "src", "libqhull_r"), TXML, TOBJ, LPNG, MINIZ, MINIZ_GEN, MCC)
    add_defines("MJSTATIC", "CCD_STATIC_DEFINE", "MC_IMPLEM_ENABLE", "MINIZ_STATIC_DEFINE")
    add_deps("mujoco")
    add_packages("abseil", "gtest")
    if is_plat("windows") then add_cflags("/std:c11", "/utf-8") end
    set_targetdir(build_out("simulators", "lib"))
    set_objectdir(build_out("simulators", "obj"))
    set_dependir(build_out("simulators", "dep"))

target("mj_test_compare_spec")
    set_kind("static")
    set_default(false)
    set_languages("cxx20", "c11")
    add_files(path.join(TEST, "compare_spec.cc"))
    add_includedirs(MJ, TEST, MJ_SRC, path.join(CCD, "src"), MJ_GEN, path.join(QHULL, "src"), path.join(QHULL, "src", "libqhull_r"), TXML, TOBJ, LPNG, MINIZ, MINIZ_GEN, MCC)
    add_defines("MJSTATIC", "CCD_STATIC_DEFINE", "MC_IMPLEM_ENABLE", "MINIZ_STATIC_DEFINE")
    add_deps("mujoco")
    add_packages("abseil", "gtest")
    if is_plat("windows") then add_cflags("/std:c11", "/utf-8") end
    set_targetdir(build_out("simulators", "lib"))
    set_objectdir(build_out("simulators", "obj"))
    set_dependir(build_out("simulators", "dep"))

-- These *_test.cc files exist upstream but are not part of the official
-- default build configuration (USD, render, convergence and extra plugin
-- tests).  Everything else becomes an executable, mirroring mujoco_test().
local test_skip = {
    sort_benchmark_test = true,
    sqrmat_benchmark_test = true,
    engine_cg_convergence_test = true,
    engine_collision_sdf_test = true,
    engine_pgs_convergence_test = true,
    mjc_physics_scene_test = true,
    mjc_site_api_test = true,
    mjcf_file_format_test = true,
    decoder_test = true,
    encoder_test = true,
    sensor_test = true,
    usd_decoder_test = true,
    renderer_test = true,
    user_cache_test = true,
    user_resolver_test = true,
    user_threadpool_test = true,
    xml_schema_test = true,
}

local test_files = {}
-- Files directly under test/ (fixture_test, header_test, ...) plus all nested
-- subdirectories.
for _, f in ipairs(os.files(path.join(TEST, "*_test.cc"))) do table.insert(test_files, f) end
for _, f in ipairs(os.files(path.join(TEST, "**", "*_test.cc"))) do table.insert(test_files, f) end

for _, file in ipairs(test_files) do
    local name = path.basename(file)
    if not test_skip[name] then
        local is_benchmark = (path.filename(path.directory(file)) == "benchmark")
        target("mj_" .. name)
            set_kind("binary")
            set_default(true)
            set_languages("cxx20", "c11")
            add_files(file)
            add_includedirs(MJ, TEST, MJ_SRC, path.join(CCD, "src"), MJ_GEN, path.join(QHULL, "src"), path.join(QHULL, "src", "libqhull_r"), TXML, TOBJ, LPNG, MINIZ, MINIZ_GEN, MCC)
            add_defines("MJSTATIC", "CCD_STATIC_DEFINE", "MC_IMPLEM_ENABLE", "MINIZ_STATIC_DEFINE")
            -- compare_model / compare_spec / miniz are linked broadly: unused
            -- members are simply not pulled by the linker, and this avoids
            -- replicating upstream's per-test ADDITIONAL_LINK_LIBRARIES list.
            add_deps("mujoco", "mj_test_fixture", "mj_test_compare_model", "mj_test_compare_spec", "mj_dep_miniz")
            add_packages("abseil")
            if is_benchmark then
                -- The xmake-repo package links benchmark_main + benchmark;
                -- gtest is still needed for the assertion macros.
                add_packages("benchmark", "gtest")
            else
                -- gtest_main provides main() for the regular unit tests (the
                -- xmake-repo gtest package only links gtest + gmock).
                add_packages("gtest")
                add_links("gtest_main")
            end
            if is_plat("windows") then
                add_cflags("/std:c11")
                add_cxflags("/utf-8")
                add_syslinks("opengl32", "gdi32", "shell32", "user32")
                -- main() lives in gtest_main / benchmark_main (a static
                -- library).  Without an explicit subsystem the MSVC linker
                -- only infers the entry point from object files and fails
                -- with LNK1561.
                add_ldflags("/subsystem:console")
            end
            -- engine_collision_box_test also compares against the legacy box
            -- collision implementation.
            if name == "engine_collision_box_test" then
                add_deps("mj_test_boxbox_legacy")
            end
            if name == "ccd_benchmark_test" then
                add_deps("mj_dep_ccd")
            end
            set_targetdir(build_out("simulators", "bin"))
            set_objectdir(build_out("simulators", "obj"))
            set_dependir(build_out("simulators", "dep"))
    end
end
end -- with_mujoco_tests
