-- PositionBasedDynamics, built natively by Xmake from read-only upstream sources.
--
-- Dependencies:
--   * Eigen            - vendored at Simulators/position-based-dynamics/extern/eigen
--   * GenericParameters - header-only; cloned into deps/position-based-dynamics
--   * Discregrid       - headers; cloned into deps/position-based-dynamics
--                        (Discregrid itself is only needed to *link* an exe that
--                         consumes Simulation; building it is a later step)
-- The clones are source-level inputs (not build output), so they live outside
-- build/ and are restored by the on_load hook when missing.
--
local PBD       = path.join(SIMULATORS, "position-based-dynamics")
local EIGEN     = path.join(PBD, "extern", "eigen")
local DEPS      = path.join(ROOT, "deps", "position-based-dynamics")
-- The clone nests its headers: GenericParameters/GenericParameters/*.h, and the
-- sources use #include "ParameterObject.h" (flat), so the include dir is the inner
-- GenericParameters/ directory. Discregrid keeps #include "Discregrid/..." with its
-- headers under discregrid/include/.
local GP_INC    = path.join(DEPS, "GenericParameters", "GenericParameters") -- header-only
local DG_INC    = path.join(DEPS, "Discregrid", "discregrid", "include")

-- Revisions used only when a checkout is missing. Existing dependency trees
-- are user-owned and accepted as-is, so updating the upstream simulator does
-- not force-reset or block a newer local dependency checkout.
local PBD_DEPS = {
    {"Discregrid", "https://github.com/InteractiveComputerGraphics/Discregrid.git",
     "ddf20dc0480874bf02e0bdc6ded76c1f101b17fb"},
    {"GenericParameters", "https://github.com/InteractiveComputerGraphics/GenericParameters.git",
     "a4e2744eea526270cfe38b826440d09f66473316"},
}

-- MSVC misreads a UTF-8 scissors literal in pybind/Utils headers on CP936; /utf-8
-- is build-only and touches no upstream file.
local PBD_FLAGS = {"/utf-8"}

-- Upstream's official CMake generates Utils/Version.h INTO the source tree
-- (Utils/CMakeLists.txt: configure_file(... ${CMAKE_CURRENT_SOURCE_DIR}/...)),
-- which pollutes the submodule's git status. We generate it under build/
-- instead; only Demos/Common/DemoBase.cpp includes it ("Utils/Version.h"), so
-- PBD_GEN is added to that target's include path below.
local PBD_GEN = path.join(BUILD, "simulators", "position-based-dynamics",
                          "xmake-generated")

local function pbd_generate_version(target)
    local hdr = path.join(PBD_GEN, "Utils", "Version.h")
    local version = "unknown"
    local vtxt = path.join(PBD, "version.txt")
    if os.isfile(vtxt) then
        version = (io.readfile(vtxt):gsub("%s+", ""))
    end
    local sha = os.iorunv("git", {"-C", PBD, "rev-parse", "--short=12", "HEAD"})
    local ref = os.iorunv("git", {"-C", PBD, "rev-parse", "--abbrev-ref", "HEAD"})
    local status = os.iorunv("git", {"-C", PBD, "status", "--porcelain"})
    sha = sha:gsub("%s+", "")
    ref = ref:gsub("%s+", "")
    status = status:match("%S") and "dirty" or "clean"
    local content = table.concat({
        "#ifndef __Version_h__",
        "#define __Version_h__",
        "",
        "#define STRINGIZE_HELPER(x) #x",
        "#define STRINGIZE(x) STRINGIZE_HELPER(x)",
        "#define WARNING(desc) message(__FILE__ \"(\" STRINGIZE(__LINE__) \") : Warning: \" #desc)",
        "",
        "#define GIT_SHA1 \"" .. sha .. "\"",
        "#define GIT_REFSPEC \"" .. ref .. "\"",
        "#define GIT_LOCAL_STATUS \"" .. status .. "\"",
        "",
        "#define PBD_VERSION \"" .. version .. "\"",
        "",
        "#ifdef DL_OUTPUT",
        "",
        "#endif",
        "",
        "#endif",
    }, "\n") .. "\n"
    -- Do not touch the output timestamp when its content is unchanged; doing
    -- so would needlessly rebuild DemoBase.cpp after every configure.
    if not os.isfile(hdr) or io.readfile(hdr) ~= content then
        io.writefile(hdr, content)
    end
end

-- on_load runs in the full script sandbox (os.vrunv available); use it to
-- restore the two configure-time clones when a cleaned build/ wiped them.
-- Glob patterns were already expanded during description, so after cloning we
-- stop with a clear instruction to re-run `xmake f` once.
local function pbd_ensure_deps(target)
    import("xmake.dependencies", {rootdir = os.projectdir()})
    os.mkdir(DEPS)
    local restored = false
    for _, dep in ipairs(PBD_DEPS) do
        local dst = path.join(DEPS, dep[1])
        restored = dependencies.ensure_checkout(dst, dep[2], dep[3]) or restored
    end
    if restored then
        raise("pbd: upstream dependencies restored into " .. DEPS ..
              "; please re-run `xmake f` so the new sources are picked up")
    end
end

target("pbd_utils")
    set_kind("static")
    set_languages("cxx14")
    set_default(true)
    on_load(pbd_ensure_deps)
    add_files(path.join(PBD, "Utils", "*.cpp"))
    add_includedirs(PBD, path.join(PBD, "Utils"), EIGEN, GP_INC)
    add_cxxflags(PBD_FLAGS)
    add_defines("WIN32")
    set_targetdir(build_out("simulators", "lib"))
    set_objectdir(build_out("simulators", "obj"))
    set_dependir(build_out("simulators", "dep"))

target("pbd_core")
    set_kind("static")
    set_languages("cxx14")
    set_default(true)
    add_files(path.join(PBD, "PositionBasedDynamics", "*.cpp"))
    add_includedirs(PBD, path.join(PBD, "PositionBasedDynamics"), EIGEN)
    add_cxxflags(PBD_FLAGS)
    add_defines("WIN32")
    set_targetdir(build_out("simulators", "lib"))
    set_objectdir(build_out("simulators", "obj"))
    set_dependir(build_out("simulators", "dep"))

target("pbd_simulation")
    set_kind("static")
    set_languages("cxx14")
    set_default(true)
    add_files(path.join(PBD, "Simulation", "*.cpp"))
    add_includedirs(PBD, path.join(PBD, "Simulation"), EIGEN, DG_INC, GP_INC)
    add_deps("pbd_utils", "pbd_core")
    add_cxxflags(PBD_FLAGS)
    add_defines("WIN32")
    set_targetdir(build_out("simulators", "lib"))
    set_objectdir(build_out("simulators", "obj"))
    set_dependir(build_out("simulators", "dep"))

-- Link/run check: a tiny consumer proving the xmake-built libraries are usable.
target("pbd_link_check")
    set_kind("binary")
    set_languages("cxx14")
    set_default(true)
    add_files(path.join(ROOT, "xmake", "checks", "pbd_link_check.cpp"))
    add_includedirs(PBD, path.join(PBD, "PositionBasedDynamics"), EIGEN)
    add_deps("pbd_core")
    add_cxxflags(PBD_FLAGS)
    add_defines("WIN32")
    add_tests("smoke")
    set_targetdir(build_out("simulators", "bin"))
    set_objectdir(build_out("simulators", "obj"))
    set_dependir(build_out("simulators", "dep"))

-- ---------------------------------------------------------------------------
-- Demo applications: the 16 *Demo.exe the official CMake build produces.
-- ---------------------------------------------------------------------------

local IMGUI = path.join(PBD, "extern", "imgui")
local GLFW  = path.join(PBD, "extern", "glfw")
local MD5   = path.join(PBD, "extern", "md5")
local DEMOS = path.join(PBD, "Demos")

-- Discregrid (signed-distance fields), built from the pinned upstream sources.
-- Its own sources include their headers flat (#include "discrete_grid.hpp"),
-- which live under include/Discregrid/, while consumers use "Discregrid/All",
-- so both include roots are needed.
target("pbd_discregrid")
    set_kind("static")
    set_default(false)
    set_languages("cxx14")
    add_files(path.join(DEPS, "Discregrid", "discregrid", "src", "**.cpp"))
    add_includedirs(DG_INC, path.join(DG_INC, "Discregrid"), EIGEN)
    add_cxxflags(PBD_FLAGS)
    set_targetdir(build_out("simulators", "lib"))
    set_objectdir(build_out("simulators", "obj"))
    set_dependir(build_out("simulators", "dep"))

-- GLFW (Win32 backend), from the vendored upstream sources.
target("pbd_glfw")
    set_kind("static")
    set_default(false)
    add_files(path.join(GLFW, "src", "*.c"))
    remove_files(
        path.join(GLFW, "src", "cocoa_*"),
        path.join(GLFW, "src", "glx_*"),
        path.join(GLFW, "src", "linux_*"),
        path.join(GLFW, "src", "null_*"),
        path.join(GLFW, "src", "posix_*"),
        path.join(GLFW, "src", "wl_*"),
        path.join(GLFW, "src", "x11_*"),
        path.join(GLFW, "src", "xkb_*")
    )
    add_includedirs(path.join(GLFW, "include"))
    add_defines("_GLFW_WIN32")
    set_targetdir(build_out("simulators", "lib"))
    set_objectdir(build_out("simulators", "obj"))
    set_dependir(build_out("simulators", "dep"))

-- Dear ImGui with the GLFW + OpenGL3 backends the demos use.
target("pbd_imgui")
    set_kind("static")
    set_default(false)
    set_languages("cxx14")
    add_files(path.join(IMGUI, "imgui.cpp"))
    add_files(path.join(IMGUI, "imgui_draw.cpp"))
    add_files(path.join(IMGUI, "imgui_tables.cpp"))
    add_files(path.join(IMGUI, "imgui_widgets.cpp"))
    add_files(path.join(IMGUI, "backends", "imgui_impl_glfw.cpp"))
    add_files(path.join(IMGUI, "backends", "imgui_impl_opengl3.cpp"))
    add_includedirs(IMGUI, path.join(IMGUI, "backends"), path.join(GLFW, "include"))
    set_targetdir(build_out("simulators", "lib"))
    set_objectdir(build_out("simulators", "obj"))
    set_dependir(build_out("simulators", "dep"))

-- MD5 helper used by the loaders.
target("pbd_md5")
    set_kind("static")
    set_default(false)
    set_languages("cxx14")
    add_files(path.join(MD5, "md5.cpp"))
    add_includedirs(MD5)
    set_targetdir(build_out("simulators", "lib"))
    set_objectdir(build_out("simulators", "obj"))
    set_dependir(build_out("simulators", "dep"))

-- Shared demo framework: Demos/Common + Demos/Visualization + the bundled GLAD.
target("pbd_demo_common")
    set_kind("static")
    set_default(false)
    set_languages("cxx17")
    on_load(pbd_generate_version)
    add_files(path.join(DEMOS, "Common", "*.cpp"))
    add_files(path.join(DEMOS, "Visualization", "MiniGL.cpp"))
    add_files(path.join(DEMOS, "Visualization", "Shader.cpp"))
    add_files(path.join(GLFW, "deps", "glad_gl.c"))
    add_includedirs(
        PBD_GEN, PBD, DEMOS, EIGEN, GP_INC,
        IMGUI, path.join(IMGUI, "backends"),
        path.join(GLFW, "include"), path.join(GLFW, "deps")
    )
    add_cxxflags(PBD_FLAGS)
    add_defines("WIN32")
    set_targetdir(build_out("simulators", "lib"))
    set_objectdir(build_out("simulators", "obj"))
    set_dependir(build_out("simulators", "dep"))

-- The 16 demo executables, mapped one-to-one to the official build's *Demo.exe.
local demo_deps = {
    "pbd_utils", "pbd_core", "pbd_simulation",
    "pbd_discregrid", "pbd_glfw", "pbd_imgui", "pbd_md5", "pbd_demo_common"
}
local demo_incdirs = {
    PBD, DEMOS, EIGEN, GP_INC, DG_INC,
    IMGUI, path.join(IMGUI, "backends"),
    path.join(GLFW, "include"), path.join(GLFW, "deps")
}
local demo_sources = {
    BarDemo                = {path.join(DEMOS, "BarDemo", "main.cpp")},
    ChainDemo              = {path.join(DEMOS, "RigidBodyDemos", "ChainDemo.cpp")},
    ClothCollisionDemo     = {path.join(DEMOS, "DistanceFieldDemos", "ClothCollisionDemo.cpp")},
    ClothDemo              = {path.join(DEMOS, "ClothDemo", "main.cpp")},
    CosseratRodsDemo       = {path.join(DEMOS, "CosseratRodsDemo", "main.cpp")},
    DeformableCollisionDemo = {path.join(DEMOS, "DistanceFieldDemos", "DeformableCollisionDemo.cpp")},
    DirectPositionBasedSolverForStiffRodsDemo = {
        path.join(DEMOS, "StiffRodsDemos", "DirectPositionBasedSolverForStiffRodsDemo.cpp"),
        path.join(DEMOS, "StiffRodsDemos", "StiffRodsSceneLoader.cpp")},
    ElasticRodDemo = {
        path.join(DEMOS, "PositionBasedElasticRodsDemo", "PositionBasedElasticRodsDemo.cpp"),
        path.join(DEMOS, "PositionBasedElasticRodsDemo", "PositionBasedElasticRodsConstraints.cpp"),
        path.join(DEMOS, "PositionBasedElasticRodsDemo", "PositionBasedElasticRodsModel.cpp"),
        path.join(DEMOS, "PositionBasedElasticRodsDemo", "PositionBasedElasticRodsTSC.cpp")},
    FluidDemo = {
        path.join(DEMOS, "FluidDemo", "main.cpp"),
        path.join(DEMOS, "FluidDemo", "FluidModel.cpp"),
        path.join(DEMOS, "FluidDemo", "TimeStepFluidModel.cpp")},
    GenericParticleConstraintsDemo = {
        path.join(DEMOS, "GenericConstraintsDemos", "GenericParticleConstraintsDemo.cpp"),
        path.join(DEMOS, "GenericConstraintsDemos", "GenericConstraints.cpp"),
        path.join(DEMOS, "GenericConstraintsDemos", "GenericConstraintsModel.cpp")},
    GenericRigidBodyConstraintsDemo = {
        path.join(DEMOS, "GenericConstraintsDemos", "GenericRigidBodyConstraintsDemo.cpp"),
        path.join(DEMOS, "GenericConstraintsDemos", "GenericConstraints.cpp"),
        path.join(DEMOS, "GenericConstraintsDemos", "GenericConstraintsModel.cpp")},
    JointDemo              = {path.join(DEMOS, "RigidBodyDemos", "JointDemo.cpp")},
    RigidBodyClothCouplingDemo = {path.join(DEMOS, "CouplingDemos", "RigidBodyClothCouplingDemo.cpp")},
    RigidBodyCollisionDemo = {path.join(DEMOS, "DistanceFieldDemos", "RigidBodyCollisionDemo.cpp")},
    SceneLoaderDemo        = {path.join(DEMOS, "SceneLoaderDemo", "SceneLoaderDemo.cpp")},
    StretchBendingTwistingDemo = {
        path.join(DEMOS, "StiffRodsDemos", "StretchBendingTwistingDemo.cpp"),
        path.join(DEMOS, "StiffRodsDemos", "StiffRodsSceneLoader.cpp")},
}

for name, sources in pairs(demo_sources) do
    target(name)
        set_kind("binary")
        set_default(true)
        set_languages("cxx17")
        add_files(table.unpack(sources))
        add_includedirs(table.unpack(demo_incdirs))
        add_deps(table.unpack(demo_deps))
        add_cxxflags(PBD_FLAGS)
        add_defines("WIN32")
        if is_plat("windows") then
            -- GLFW's Win32 backend needs GDI32 (pixel formats, bitmaps) and
            -- Shell32 (drag & drop) in addition to OpenGL.
            add_syslinks("opengl32", "glu32", "gdi32", "shell32", "user32")
        end
        set_targetdir(build_out("simulators", "bin"))
        set_objectdir(build_out("simulators", "obj"))
        set_dependir(build_out("simulators", "dep"))
end

-- ---------------------------------------------------------------------------
-- pyPBD: the Python bindings (pypbd.cp312-win_amd64.pyd in the official build).
-- Built as a shared library with the .pyd extension against the conda
-- `position-based-dynamics` interpreter (Python 3.12), using the vendored
-- pybind11 headers.
-- ---------------------------------------------------------------------------
local PY     = get_config("pbd_python_root")
local PYBIND = path.join(PBD, "extern", "pybind", "include")

if has_config("with_pypbd") then
target("pypbd")
    set_kind("shared")
    set_default(true)
    set_languages("cxx17")
    on_load(function (target)
        assert(PY and os.isfile(path.join(PY, "Include", "Python.h")),
               "pypbd: Python.h not found under pbd_python_root: %s",
               tostring(PY))
    end)
    add_files(path.join(PBD, "pyPBD", "*.cpp"))
    add_includedirs(
        PBD, path.join(PBD, "pyPBD"), EIGEN, GP_INC, DG_INC, PYBIND,
        path.join(PY, "Include")
    )
    -- The Simulation layer and the collision-detection module both use
    -- Discregrid (CubicLagrangeDiscreteGrid etc.), so it must be linked too.
    add_deps("pbd_utils", "pbd_core", "pbd_simulation", "pbd_discregrid")
    add_linkdirs(path.join(PY, "libs"))
    add_links("python312")
    add_cxxflags(PBD_FLAGS)
    add_defines("WIN32")
    set_basename("pypbd")
    set_extension(".pyd")
    set_targetdir(build_out("simulators", "lib"))
    set_objectdir(build_out("simulators", "obj"))
    set_dependir(build_out("simulators", "dep"))
end
