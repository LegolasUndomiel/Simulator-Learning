-- Native Xmake build for PeriDyno.
--
-- The pinned upstream tree under Simulators/peridyno is read-only.  This file
-- mirrors the CUDA/MSVC targets and sends every generated artifact to build/.

local PD       = path.join(SIMULATORS, "peridyno")
local PD_SRC   = path.join(PD, "src")
local PD_CORE  = path.join(PD_SRC, "Core")
local PD_EXT   = path.join(PD, "external")
local PD_GL    = path.join(PD_SRC, "Rendering", "Engine", "OpenGL")
local PD_SHADER_OUT = path.join(BUILD, "simulators", "peridyno",
                                 "xmake-generated", "shader")
local CUDA_SDK = get_config("peridyno_cuda_sdk")
local PD_CORE_LIB = path.join(build_out("simulators", "lib"),
                              "dynoCore-1.5.0.lib")

local function peridyno_output(kind)
    set_targetdir(build_out("simulators", kind or "bin"))
    set_objectdir(build_out("simulators", "obj"))
    set_dependir(build_out("simulators", "dep"))
end

local function peridyno_cuda_settings()
    set_languages("cxx17")
    -- Upstream enables CUDA_RESOLVE_DEVICE_SYMBOLS but explicitly leaves
    -- CUDA_SEPARABLE_COMPILATION off. Xmake otherwise adds -rdc=true to every
    -- CUDA translation unit, which changes symbol linkage and causes duplicate
    -- device globals in Peridynamics.
    set_values("cuda.rdc", false)
    add_defines(
        "CUDA_BACKEND",
        "_CRT_SECURE_NO_WARNINGS",
        "CCCL_IGNORE_MSVC_TRADITIONAL_PREPROCESSOR_WARNING",
        "GLM_ENABLE_EXPERIMENTAL",
        "_ENABLE_EXTENDED_ALIGNED_STORAGE"
    )
    if is_plat("windows") then
        add_cxflags("/utf-8", "/Zc:preprocessor")
        add_cuflags("-Xcompiler=/Zc:preprocessor", "-Xcompiler=/utf-8",
                    "-Xcompiler=/wd4819")
    end
    add_cuflags("--expt-relaxed-constexpr", "-lineinfo")
    -- The repository is pinned and verified for the host RTX 4070 Ti SUPER.
    add_cugencodes("sm_" .. get_config("peridyno_cuda_arch"))
    -- Xmake injects these paths for .cu files, but PeriDyno's ordinary C++
    -- headers also include cuda_runtime.h and therefore need them explicitly.
    add_includedirs(path.join(CUDA_SDK, "include"))
    add_linkdirs(path.join(CUDA_SDK, "lib", "x64"))
    add_links("cudart", "cudadevrt")
end

local function peridyno_whole_core()
    if is_plat("windows") then
        -- Core contains relocatable CUDA device code. CMake's transitive
        -- dependency expansion lists Core twice, causing link.exe's second
        -- archive scan to pull the generated device-link member. Xmake
        -- deduplicates that list, so state the real intent explicitly.
        add_ldflags("/WHOLEARCHIVE:" .. PD_CORE_LIB)
    end
end

-- PeriDyno's root Core target is static.  Its CMake script recursively globs
-- ordinary Core sources while selecting only Backend/Cuda from the backends.
target("peridyno_core")
    set_kind("static")
    set_default(false)
    set_basename("dynoCore-1.5.0")
    set_policy("build.cuda.devlink", true)
    peridyno_cuda_settings()
    add_files(path.join(PD_CORE, "*.cpp"))
    add_files(path.join(PD_CORE, "Backend", "Cuda", "**.cu"))
    add_includedirs(
        PD_CORE,
        path.join(PD_CORE, "Backend", "Cuda"),
        PD_EXT,
        path.join(PD_EXT, "eigen"),
        path.join(PD_EXT, "glm-0.9.9.7"),
        {public = true}
    )
    peridyno_output("lib")

-- Framework is a regular C++ DLL layered on Core.  CMake's
-- CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS is reproduced by Xmake's export rule.
target("peridyno_framework")
    set_kind("shared")
    set_default(false)
    set_basename("dynoFramework-1.5.0")
    add_rules("utils.symbols.export_all")
    peridyno_cuda_settings()
    add_files(path.join(PD_SRC, "Framework", "**.cpp"))
    add_files(path.join(PD_EXT, "tinyxml", "tinyxml2.cpp"))
    add_includedirs(
        path.join(PD_SRC, "Framework"),
        path.join(PD_EXT, "filesystem"),
        {public = true}
    )
    add_deps("peridyno_core")
    peridyno_whole_core()
    peridyno_output()

target("peridyno_topology")
    set_kind("shared")
    set_default(false)
    set_basename("dynoTopology-1.5.0")
    set_policy("build.cuda.devlink", true)
    add_rules("utils.symbols.export_all")
    peridyno_cuda_settings()
    -- Topology is the sole upstream engine target with separable compilation
    -- enabled; several kernels call device functions instantiated elsewhere.
    set_values("cuda.rdc", true)
    add_files(path.join(PD_SRC, "Topology", "Cuda", "**.cpp"))
    add_files(path.join(PD_SRC, "Topology", "Cuda", "**.cu"))
    add_includedirs(
        path.join(PD_SRC, "Topology", "Cuda"),
        path.join(PD_EXT, "filesystem"),
        {public = true}
    )
    add_deps("peridyno_core", "peridyno_framework")
    peridyno_whole_core()
    peridyno_output()

target("peridyno_render_core")
    set_kind("shared")
    set_default(false)
    set_basename("dynoRenderCore-1.5.0")
    add_rules("utils.symbols.export_all")
    peridyno_cuda_settings()
    add_files(path.join(PD_SRC, "Rendering", "Core", "*.cpp"))
    add_includedirs(path.join(PD_SRC, "Rendering", "Core"),
                    path.join(PD_EXT, "glm-0.9.9.7"), {public = true})
    add_deps("peridyno_core", "peridyno_framework")
    peridyno_whole_core()
    peridyno_output()

target("peridyno_glad")
    set_kind("shared")
    set_default(false)
    set_basename("glad-2.0.0")
    set_languages("c99")
    add_files(path.join(PD_EXT, "glad-4.6", "glad", "glad.c"))
    add_includedirs(path.join(PD_EXT, "glad-4.6"), {public = true})
    add_defines("GLAD_GLAPI_EXPORT", {public = true})
    add_defines("GLAD_GLAPI_EXPORT_BUILD")
    peridyno_output()

target("peridyno_imgui")
    set_kind("shared")
    set_default(false)
    set_basename("imgui-1.90.8")
    set_languages("cxx17")
    add_rules("utils.symbols.export_all")
    add_files(path.join(PD_EXT, "imgui", "*.cpp"))
    add_includedirs(path.join(PD_EXT, "imgui"), {public = true})
    add_deps("peridyno_glad")
    if is_plat("windows") then add_cxflags("/utf-8") end
    peridyno_output()

target("peridyno_gl_render_engine")
    set_kind("shared")
    set_default(false)
    set_basename("dynoGLRenderEngine-1.5.0")
    set_policy("build.cuda.devlink", true)
    add_rules("utils.symbols.export_all")
    peridyno_cuda_settings()
    add_packages("glslang")
    add_defines("PERIDYNO_API_EXPORTS")
    add_files(path.join(PD_GL, "**.cpp"))
    add_files(path.join(PD_GL, "**.cu"))
    remove_files(path.join(PD_GL, "Backend", "Vulkan", "**"))
    add_includedirs(
        PD_SHADER_OUT,
        PD_GL,
        path.join(PD_GL, "Backend"),
        path.join(PD_GL, "Backend", "Cuda"),
        path.join(PD_GL, "Backend", "Cuda", "Module"),
        {public = true}
    )
    add_deps("peridyno_core", "peridyno_framework",
             "peridyno_topology", "peridyno_render_core", "peridyno_glad",
             "peridyno_imgui")
    peridyno_whole_core()
    if is_plat("windows") then add_syslinks("opengl32") end
    -- Generate the same embedded SPIR-V headers as upstream, but use the
    -- Xmake-managed glslangValidator instead of CMake's glslang subproject.
    on_load(function (target)
        local pkg = target:pkg("glslang")
        local validator = path.join(pkg:installdir(), "bin",
                                    is_host("windows") and
                                    "glslangValidator.exe" or
                                    "glslangValidator")
        assert(os.isfile(validator), "glslangValidator was not installed: %s",
               validator)
        os.mkdir(PD_SHADER_OUT)
        for _, ext in ipairs({"vert", "frag", "geom"}) do
            for _, file in ipairs(os.files(path.join(PD_GL, "shader", "**." .. ext))) do
                local filename = path.filename(file)
                local variable = filename:gsub("%.", "_"):upper()
                local output = path.join(PD_SHADER_OUT, filename .. ".h")
                if not os.isfile(output) or os.mtime(output) < os.mtime(file) then
                    os.vrunv(validator, {"--target-env", "opengl", "--vn", variable,
                                        file, "-o", output})
                end
            end
        end
    end)
    peridyno_output()

local function add_peridyno_cuda_library(target_name, basename, source_dir,
                                          includes, deps, links)
    target(target_name)
        set_kind("shared")
        set_default(false)
        set_basename(basename)
        set_policy("build.cuda.devlink", true)
        add_rules("utils.symbols.export_all")
        peridyno_cuda_settings()
        add_cuflags("--expt-extended-lambda")
        add_defines("PERIDYNO_API_EXPORTS")
        for _, ext in ipairs({"cpp", "cc", "c", "cu"}) do
            for _, file in ipairs(os.files(path.join(source_dir, "**." .. ext))) do
                add_files(file)
            end
        end
        add_includedirs(source_dir, {public = true})
        for _, inc in ipairs(includes or {}) do add_includedirs(inc, {public = true}) end
        add_deps("peridyno_core")
        for _, dep in ipairs(deps or {}) do add_deps(dep) end
        for _, link in ipairs(links or {}) do add_links(link) end
        peridyno_whole_core()
        peridyno_output()
end

add_peridyno_cuda_library(
    "peridyno_io", "dynoIO-1.5.0", path.join(PD_SRC, "IO", "Cuda"), {},
    {"peridyno_framework", "peridyno_topology", "peridyno_gl_render_engine"})

add_peridyno_cuda_library(
    "peridyno_interaction", "dynoInteraction-1.5.0",
    path.join(PD_SRC, "Interaction"), {},
    {"peridyno_framework", "peridyno_topology", "peridyno_gl_render_engine"})

add_peridyno_cuda_library(
    "peridyno_modeling", "dynoModeling-1.5.0", path.join(PD_SRC, "Modeling"), {},
    {"peridyno_io", "peridyno_framework", "peridyno_topology",
     "peridyno_gl_render_engine", "peridyno_render_core"})

local PD_DYNAMICS = path.join(PD_SRC, "Dynamics", "Cuda")

add_peridyno_cuda_library(
    "peridyno_particle_system", "dynoParticleSystem-1.5.0",
    path.join(PD_DYNAMICS, "ParticleSystem"), {PD_DYNAMICS},
    {"peridyno_io", "peridyno_framework", "peridyno_topology",
     "peridyno_modeling", "peridyno_gl_render_engine"})

add_peridyno_cuda_library(
    "peridyno_peridynamics", "dynoPeridynamics-1.5.0",
    path.join(PD_DYNAMICS, "Peridynamics"), {PD_DYNAMICS},
    {"peridyno_io", "peridyno_topology", "peridyno_particle_system"})

add_peridyno_cuda_library(
    "peridyno_rigid_body", "dynoRigidBody-1.5.0",
    path.join(PD_DYNAMICS, "RigidBody"), {PD_DYNAMICS},
    {"peridyno_io", "peridyno_framework", "peridyno_topology",
     "peridyno_gl_render_engine", "peridyno_modeling"})

add_peridyno_cuda_library(
    "peridyno_volume", "dynoVolume-1.5.0",
    path.join(PD_DYNAMICS, "Volume"), {PD_DYNAMICS},
    {"peridyno_io", "peridyno_framework", "peridyno_topology",
     "peridyno_modeling", "peridyno_gl_render_engine"})

add_peridyno_cuda_library(
    "peridyno_height_field", "dynoHeightField-1.5.0",
    path.join(PD_DYNAMICS, "HeightField"), {PD_DYNAMICS},
    {"peridyno_io", "peridyno_framework", "peridyno_topology",
     "peridyno_rigid_body", "peridyno_gl_render_engine"}, {"cufft"})

add_peridyno_cuda_library(
    "peridyno_semi_analytical", "dynoSemiAnalyticalScheme-1.5.0",
    path.join(PD_DYNAMICS, "SemiAnalyticalScheme"), {PD_DYNAMICS},
    {"peridyno_particle_system"})

add_peridyno_cuda_library(
    "peridyno_multiphysics", "dynoMultiphysics-1.5.0",
    path.join(PD_DYNAMICS, "Multiphysics"), {PD_DYNAMICS},
    {"peridyno_particle_system", "peridyno_peridynamics",
     "peridyno_rigid_body", "peridyno_volume"})

add_peridyno_cuda_library(
    "peridyno_euler_fluid", "dynoEulerFluid-1.5.0",
    path.join(PD_DYNAMICS, "EulerFluid"), {PD_DYNAMICS},
    {"peridyno_io", "peridyno_framework", "peridyno_topology",
     "peridyno_modeling", "peridyno_gl_render_engine", "peridyno_volume"})

local GLFW = path.join(PD_EXT, "glfw-3.3.0")
local GLFW_SRC = path.join(GLFW, "src")

target("peridyno_glfw")
    set_kind("shared")
    set_default(false)
    set_basename("glfw3")
    set_languages("c99")
    add_rules("utils.symbols.export_all")
    add_defines("_GLFW_WIN32", "_CRT_SECURE_NO_WARNINGS")
    add_files(
        path.join(GLFW_SRC, "context.c"), path.join(GLFW_SRC, "init.c"),
        path.join(GLFW_SRC, "input.c"), path.join(GLFW_SRC, "monitor.c"),
        path.join(GLFW_SRC, "vulkan.c"), path.join(GLFW_SRC, "window.c"),
        path.join(GLFW_SRC, "win32_init.c"),
        path.join(GLFW_SRC, "win32_joystick.c"),
        path.join(GLFW_SRC, "win32_monitor.c"),
        path.join(GLFW_SRC, "win32_time.c"),
        path.join(GLFW_SRC, "win32_thread.c"),
        path.join(GLFW_SRC, "win32_window.c"),
        path.join(GLFW_SRC, "wgl_context.c"),
        path.join(GLFW_SRC, "egl_context.c"),
        path.join(GLFW_SRC, "osmesa_context.c")
    )
    add_includedirs(path.join(GLFW, "include"), {public = true})
    add_includedirs(GLFW_SRC)
    if is_plat("windows") then
        add_syslinks("user32", "gdi32", "shell32")
        -- The export-all rule drives MSVC through the C++ frontend; GLFW is C.
        add_cxflags("/TC", "/utf-8")
    end
    peridyno_output()

add_peridyno_cuda_library(
    "peridyno_imwidgets", "dynoImWidgets-1.5.0",
    path.join(PD_SRC, "Rendering", "GUI", "ImWidgets"),
    {path.join(PD_SRC, "Rendering", "GUI")},
    {"peridyno_framework", "peridyno_render_core", "peridyno_imgui"})

add_peridyno_cuda_library(
    "peridyno_glfw_gui", "dynoGlfwGUI-1.5.0",
    path.join(PD_SRC, "Rendering", "GUI", "GlfwGUI"),
    {PD_SRC, path.join(PD_SRC, "Rendering", "GUI")},
    {"peridyno_framework", "peridyno_render_core",
     "peridyno_gl_render_engine", "peridyno_imwidgets", "peridyno_glfw",
     "peridyno_imgui"})

target("peridyno_glfw_gui")
    if is_plat("windows") then add_syslinks("user32") end

add_peridyno_cuda_library(
    "peridyno_ubi_gui", "dynoUbiGUI-1.5.0",
    path.join(PD_SRC, "Rendering", "GUI", "UbiGUI"),
    {PD_SRC, path.join(PD_SRC, "Rendering", "GUI")},
    {"peridyno_glfw_gui"})

add_peridyno_cuda_library(
    "peridyno_plugin_objio", "plugin-ObjIO-1.5.0",
    path.join(PD, "plugins", "ObjIO"), {path.join(PD, "plugins")},
    {"peridyno_io", "peridyno_framework", "peridyno_topology",
     "peridyno_gl_render_engine"})

add_peridyno_cuda_library(
    "peridyno_plugin_stlio", "plugin-STLIO-1.5.0",
    path.join(PD, "plugins", "STLIO"), {path.join(PD, "plugins")},
    {"peridyno_io", "peridyno_framework", "peridyno_topology",
     "peridyno_gl_render_engine"})

-- Executables enabled by the pinned upstream default CUDA configuration.
-- Each example has a directory matching its output name and a small main.cpp;
-- linking the complete public engine surface keeps this declaration compact
-- while preserving the official executable set and names.
local PD_EXAMPLES = {
    "CPD_ClothDrop", "CPD_ClothOnTable", "CPD_ClothOverBall_1",
    "CPD_ClothOverBall_3", "CPD_ClothOverBall_6", "CPD_RealTimeCloth_v1",
    "CPD_RealTimeCloth_v2", "CPD_RotateCylinder", "CPD_ShootingCloth",
    "GL_BoxStack", "GL_Bricks", "GL_BrittleFracture", "GL_CapillaryWave",
    "GL_ChainPyramidImpact", "GL_Cloth", "GL_CollisionDetectionIn3D",
    "GL_CollisionMask", "GL_Comparison", "GL_DigitNumberVisualizer",
    "GL_Elasticity", "GL_EulerianFluid3D", "GL_FixedJoint", "GL_GhostSPH",
    "GL_GlfwGUI", "GL_GranularMedia", "GL_HingeChain", "GL_HingeJoint",
    "GL_HingeRing", "GL_HitBricks", "GL_InstanceVisualizer",
    "GL_MarchingCubes", "GL_MouseInteraction",
    "GL_MouseInteractionInGraphicsPipeline", "GL_MoutainTorrents", "GL_Ocean",
    "GL_OceanPatch", "GL_Overlap", "GL_ParticleEmitter", "GL_ParticleFluid",
    "GL_PhotorealisticInstanceRender", "GL_PhotorealisticRender",
    "GL_Plasticity", "GL_Pyramid", "GL_RigidCompound", "GL_RigidSandCoupling",
    "GL_SDFUniform", "GL_SDFUniformBoolean", "GL_SegmentVisualizer",
    "GL_SliderJoint", "GL_SurfaceTension", "GL_TankSandCoupling", "GL_Terrain",
    "GL_TestAttribute", "GL_Timing", "GL_Topology", "GL_UbiGUI",
    "GL_ViscosityFish", "GL_Wireframe", "Qt_Gear", "Qt_Multibody",
    "Qt_PresetArticulatedBody", "Qt_TrackedTank", "Qt_Viscosity", "Semi_Bar",
    "Semi_Barricade"
}

local PD_EXAMPLE_DEPS = {
    "peridyno_ubi_gui", "peridyno_interaction", "peridyno_particle_system",
    "peridyno_peridynamics", "peridyno_rigid_body", "peridyno_volume",
    "peridyno_height_field", "peridyno_semi_analytical",
    "peridyno_multiphysics", "peridyno_euler_fluid",
    "peridyno_plugin_objio", "peridyno_plugin_stlio"
}

local PD_EXAMPLE_TARGETS = {}
for index, name in ipairs(PD_EXAMPLES) do
    local dirs = os.dirs(path.join(PD, "examples", "**", name))
    local target_name = "peridyno_example_" .. name:lower()
    table.insert(PD_EXAMPLE_TARGETS, target_name)
    target(target_name)
        set_kind("binary")
        set_default(false)
        set_basename(name)
        peridyno_cuda_settings()
        if is_plat("windows") then
            add_cuflags(is_mode("debug") and "-Xcompiler=/MDd" or
                        "-Xcompiler=/MD")
        end
        for _, ext in ipairs({"cpp", "cc", "c", "cu"}) do
            for _, file in ipairs(os.files(path.join(dirs[1], "**." .. ext))) do
                add_files(file)
            end
        end
        for _, dep in ipairs(PD_EXAMPLE_DEPS) do add_deps(dep) end
        peridyno_whole_core()
        if is_plat("windows") then
            add_syslinks("user32", "gdi32", "shell32", "opengl32")
            add_ldflags("/subsystem:console")
        end
        peridyno_output()
        -- Keep MSVC's /Fo path below the legacy Windows path limit for long
        -- example and source names (the depfile mirrors the same source path,
        -- so the dep directory needs the same treatment).
        set_objectdir(path.join(BUILD, "obj", "pd" .. index))
        set_dependir(path.join(BUILD, "dep", "pd" .. index))
end

target("peridyno")
    set_kind("phony")
    set_default(false)
    for _, dep in ipairs(PD_EXAMPLE_TARGETS) do add_deps(dep) end
    for _, dep in ipairs({
        "peridyno_test_core", "peridyno_test_topology", "peridyno_test_array",
        "peridyno_test_stl", "peridyno_test_ccd", "peridyno_test_field",
        "peridyno_test_pipeline", "peridyno_test_serialization",
        "peridyno_test_collision", "peridyno_test_volume"
    }) do add_deps(dep) end

-- First parity test target.  Upstream supplies its own main.cpp, so only the
-- gtest library (not gtest_main) is linked.
target("peridyno_test_core")
    set_kind("binary")
    set_default(false)
    set_basename("Test_Core")
    peridyno_cuda_settings()
    add_files(path.join(PD, "tests", "Cuda", "Test_Core", "*.cpp"))
    add_deps("peridyno_core")
    peridyno_whole_core()
    add_packages("gtest")
    if is_plat("windows") then
        add_ldflags("/subsystem:console")
    end
    peridyno_output()

target("peridyno_test_topology")
    set_kind("binary")
    set_default(false)
    set_basename("Test_Topology")
    peridyno_cuda_settings()
    add_files(path.join(PD, "tests", "Cuda", "Test_Topolopy", "*.cpp"))
    add_deps("peridyno_core", "peridyno_framework", "peridyno_topology")
    peridyno_whole_core()
    add_packages("gtest")
    if is_plat("windows") then
        add_ldflags("/subsystem:console")
    end
    peridyno_output()

local function add_peridyno_test(target_name, output_name, source_dir, deps)
    target(target_name)
        set_kind("binary")
        set_default(false)
        set_basename(output_name)
        peridyno_cuda_settings()
        add_files(path.join(PD, "tests", "Cuda", source_dir, "*.cpp"))
        add_deps("peridyno_core")
        for _, dep in ipairs(deps or {}) do add_deps(dep) end
        peridyno_whole_core()
        add_packages("gtest")
        if is_plat("windows") then add_ldflags("/subsystem:console") end
        peridyno_output()
end

add_peridyno_test("peridyno_test_array", "Test_Array", "Test_Array")
add_peridyno_test("peridyno_test_stl", "Test_STL", "Test_STL")
add_peridyno_test("peridyno_test_ccd", "Test_CCD", "Test_CCD",
                  {"peridyno_framework"})
add_peridyno_test("peridyno_test_field", "Test_Field", "Test_Field",
                  {"peridyno_framework"})
add_peridyno_test("peridyno_test_pipeline", "Test_Pipeline", "Test_Pipeline",
                  {"peridyno_framework"})
add_peridyno_test("peridyno_test_serialization", "Test_Serialization",
                  "Test_Serialization", {"peridyno_framework"})
add_peridyno_test("peridyno_test_collision", "Test_Collision", "Test_Collision",
                  {"peridyno_framework", "peridyno_topology"})
add_peridyno_test("peridyno_test_volume", "Test_Volume", "Test_Volume",
                  {"peridyno_framework", "peridyno_volume"})
