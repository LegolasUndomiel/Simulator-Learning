-- OpenCourant starter and engine, built with Xmake's native Fortran/C/C++
-- rules. The only local toolchain code supplies oneAPI paths because Intel's
-- setvars.bat is unreliable in non-interactive runners (see toolchains.lua).
--
-- The source lists and verified Fortran module levels are data generated from
-- the official Ninja graph. Xmake owns compilation, dependency tracking,
-- scheduling, response files, linking and interrupted-build recovery.

local OC = path.join(SIMULATORS, "opencourant")
local COMMON = path.join(OC, "common_source")
local SCRIPTS = path.join(OC, "Compiling_tools", "script")

target_end()
set_allowedplats("windows")
set_allowedarchs("x64")
set_allowedmodes("release")

includes(path.join(ROOT, "xmake", "opencourant", "manifest.lua"))

-- Xmake 3.1's default fortran.build runs a source batch serially. Our
-- manifest already separates module dependency levels, so files within each
-- level can use the native per-object job graph (and its global -j budget).
rule("oc.fortran")
    set_sourcekinds("fc")
    on_load(function (target) target:set("policy", "build.fence", true) end)
    -- Explicit file-rule overrides suppress Xmake's automatic object mapping.
    -- Restore that mapping before constructing the native per-file job graph.
    after_load(function (target)
        local batch = target:sourcebatches()["oc.fortran"]
        if not batch then return end
        batch.sourcekind = "fc"
        batch.objectfiles, batch.dependfiles = {}, {}
        for _, src in ipairs(batch.sourcefiles) do
            local obj = target:objectfile(src)
            table.insert(batch.objectfiles, obj)
            table.insert(batch.dependfiles, target:dependfile(obj))
        end
    end)
    on_build_files(function (target, graph, batch, opt)
        import("xmake.opencourant.build_fortran", {rootdir = os.projectdir()})
        build_fortran(target, graph, batch)
    end, {jobgraph = true, batch = true})
rule_end()

local REAL8 = "-DMYREAL8"
local CPP_MACH = "-DCPP_mach=CPP_p4win64"
local CPP_REL = "-DCPP_rel=00"
local H3D_INC = path.join(OC, "extlib", "h3d", "includes")
local ZLIB_INC = path.join(OC, "extlib", "zlib", "win64_mt", "include")
local MD5_INC = path.join(OC, "extlib", "md5", "include")

local function engine_flags(level)
    return {"/Qaxsse3", "/Qopenmp", "/O" .. level, "/fp:precise",
            "/Qfma-", "/Qftz", "/Qimf-use-svml:true",
            "/align:array64byte", REAL8, "-DMETIS5", CPP_MACH, CPP_REL,
            "/fpp", "/extend-source", "/assume:buffered_io"}
end

local STARTER_O1 = {REAL8, "-DMETIS5", CPP_MACH, CPP_REL,
                    "/extend-source", "/O1", "/fp:precise", "/Qopenmp",
                    "/Qftz", "/fpp"}
local STARTER_O2 = {REAL8, "-DMETIS5", CPP_MACH, CPP_REL,
                    "/extend-source", "/O2", "/Qopenmp", "/fp:precise",
                    "/Qftz", "/fpp"}

local COMPONENTS = {
    starter = {
        exe = "starter_win64",
        header_roots = {path.join(OC, "starter", "share"), COMMON},
        fortran_flags = {REAL8, "-DMETIS5", CPP_MACH, CPP_REL,
                         "-DCPP_comp=f90", "/Qaxsse3", "/O2",
                         "/fp:precise", "/Qfma-", "/Qftz", "/Qopenmp",
                         "/fpp", "/extend-source", "/assume:buffered_io"},
        fortran_overrides = {
            ["starter/source/starter/lectur.F"] = STARTER_O1,
            ["starter/source/tools/sect/prelecsec.F"] = STARTER_O2,
            ["starter/source/elements/sph/nbsph.F"] = STARTER_O1,
        },
        fortran_extra = {
            ["starter/source/devtools/hm_reader/hm_s_ale.F90"] =
                {"-DHM_READER_NO_STRUCTURED_ALE"},
        },
        c_flags = {"/MT", REAL8, "-DMETIS5", CPP_MACH, CPP_REL,
                   "/Qaxsse3", "/O2", "/fp:precise", "/Qfma-", "/Qftz",
                   "/Qopenmp", "-DH3D_DEFINE_BOOL"},
        cxx_flags = {"/MT", REAL8, "-DMETIS5", CPP_MACH, CPP_REL,
                     "/Qaxsse3", "/O2", "/fp:precise", "/Qfma-",
                     "/Qftz", "/Qopenmp", "-DH3D_DEFINE_BOOL"},
        c_overrides = {},
        fortran_extra_incdirs = {},
        c_extra_incdirs = {ZLIB_INC, H3D_INC, MD5_INC},
        linkdirs = {
            path.join(OC, "extlib", "hm_reader", "win64"),
            path.join(OC, "extlib", "metis", "win64"),
            path.join(OC, "extlib", "zlib", "win64_mt"),
            path.join(OC, "extlib", "md5", "win64"),
        },
        links = {"hm_reader_win64", "mkl_intel_lp64_dll",
                 "mkl_intel_thread_dll", "mkl_core_dll",
                 "libmetis_win64_i2018_1_vs2015", "zlib1", "md5",
                 "svml_dispmd", "advapi32", "user32"},
        ldflags = {"/F1500000000", "/STACK:1500000000",
                   "/INCREMENTAL:NO", "/subsystem:console"},
    },
    engine = {
        exe = "engine_win64",
        header_roots = {path.join(OC, "engine", "share"), COMMON},
        fortran_flags = {"/O3", "/QaxCORE-AVX2,COMMON-AVX512", "/Qfma-",
                         "/Qimf-use-svml:true", "/align:array64byte", REAL8,
                         "/Qopenmp", "/fp:precise", "/Qftz",
                         "/extend-source", "/assume:buffered_io",
                         "-DH3D_DEFINE_BOOL", "-DMETIS5", CPP_MACH,
                         CPP_REL, "/fpp"},
        fortran_overrides = (function ()
            local result = {}
            for _, rel in ipairs({
                "engine/source/elements/forintp.F",
                "engine/source/engine/resol_init.F",
                "engine/source/input/redkey0.F",
                "engine/source/interfaces/inter3d/i3fri3.F",
                "engine/source/mpi/interfaces/spmd_i7tool.F",
                "engine/source/airbag/fv_up_switch.F",
                "engine/source/airbag/fvbag.F",
                "engine/source/airbag/fvbag0.F",
                "engine/source/airbag/fvbag1.F",
                "engine/source/airbag/fvbag2.F"}) do
                result[rel] = engine_flags("1")
            end
            for _, rel in ipairs({
                "engine/source/elements/shell/coqueba/cbasumg3.F",
                "engine/source/engine/resol.F",
                "engine/source/output/restart/arralloc.F",
                "engine/source/model/remesh/admmap4.F",
                "engine/source/elements/elbuf/w_elbuf_str.F"}) do
                result[rel] = engine_flags("2")
            end
            for _, rel in ipairs({
                "engine/source/interfaces/int21/i21mainf.F",
                "engine/source/elements/sph/spbuc3.F",
                "engine/source/elements/sph/spclasv.F",
                "engine/source/interfaces/intsort/i24cor3t.F",
                "engine/source/interfaces/intsort/i25cor3t.F",
                "engine/source/interfaces/int11/i11cor3.F",
                "engine/source/interfaces/intsort/i11pen3.F",
                "engine/source/interfaces/int07/i7cor3t.F",
                "engine/source/interfaces/int20/i20cor3t.F",
                "engine/source/interfaces/int23/i23cor3t.F",
                "engine/source/interfaces/intsort/i20sto.F",
                "engine/source/materials/mat/mat044/sigeps44c.F",
                "engine/source/interfaces/intsort/i25pen3_e2s.F"}) do
                result[rel] = engine_flags("3")
            end
            return result
        end)(),
        fortran_extra = {},
        c_flags = {"/MT", "/O2", "/Qfma-", "/Qimf-use-svml:true", REAL8,
                   "/Qopenmp", "/fp:precise", "/Qftz",
                   "-DH3D_DEFINE_BOOL", "-DMETIS5", CPP_MACH, CPP_REL},
        cxx_flags = {"/MT", "/O2", "/Qfma-", "/Qimf-use-svml:true",
                     REAL8, "/Qopenmp", "/fp:precise", "/Qftz",
                     "-DH3D_DEFINE_BOOL", "-DMETIS5", CPP_MACH, CPP_REL},
        c_overrides = {
            ["engine/source/output/tools/ieee.cpp"] =
                {"/MT", CPP_MACH, CPP_REL},
            ["engine/source/coupling/rad2rad/rad2rad_c.c"] =
                {"/MT", CPP_MACH, CPP_REL},
        },
        fortran_extra_incdirs = {H3D_INC},
        c_extra_incdirs = {H3D_INC, MD5_INC, ZLIB_INC},
        linkdirs = {
            path.join(OC, "extlib", "zlib", "win64_mt"),
            path.join(OC, "extlib", "md5", "win64"),
        },
        links = {"mkl_intel_lp64", "mkl_intel_thread", "mkl_core", "zlib1",
                 "md5", "libifport", "svml_dispmt", "libifcoremt", "libmmt",
                 "Psapi", "libvcruntime", "advapi32", "user32"},
        ldflags = {"/F1500000000", "/STACK:1500000000", "/manifest:no",
                   "/INCREMENTAL:NO", "/subsystem:console"},
    },
}

local function append(dst, src)
    local result = {}
    for _, value in ipairs(dst) do table.insert(result, value) end
    for _, value in ipairs(src or {}) do table.insert(result, value) end
    return result
end

local function add_many(api, values)
    for _, value in ipairs(values or {}) do api(value) end
end

local function header_dirs(conf, generated)
    local result, seen = {}, {}
    for _, root in ipairs(conf.header_roots) do
        for _, pattern in ipairs({"**.inc", "**.h"}) do
            for _, file in ipairs(os.files(path.join(root, pattern))) do
                local dir = path.directory(file)
                local key = dir:lower()
                if not key:find("_inc_", 1, true) and
                   not key:find(path.join("share", "r4"):lower(), 1, true) and
                   not seen[key] then
                    seen[key] = true
                    table.insert(result, dir)
                end
            end
        end
    end
    table.insert(result, generated)
    return result
end

local function add_deps_many(names)
    for _, name in ipairs(names or {}) do add_deps(name) end
end

local function configure_common(name, deps)
    set_default(false)
    set_toolchains("oneapi-windows")
    set_objectdir(build_out("simulators", "obj"))
    set_dependir(build_out("simulators", "dep"))
    add_deps_many(deps)
end

local function add_fortran_settings(flags, incdirs, moddir)
    add_rules("oc.fortran")
    add_fcflags("-threads", "-libs:static", "/module:" .. moddir,
                "-I" .. moddir, {force = true})
    for _, flag in ipairs(flags) do add_fcflags(flag, {force = true}) end
    add_many(add_includedirs, incdirs)
    before_build(function () os.mkdir(moddir) end)
end

local function declare_codegen(component, gendir)
    local name = "oc_" .. component .. "_generated"
    target(name)
        set_kind("phony")
        set_default(false)
        set_values("oc_component", component)
        set_values("oc_generated_dir", gendir)
        set_values("oc_python", get_config("opencourant_python") or "")
        on_build(function (target)
            import("lib.detect.find_tool")
            local function value(key)
                local v = target:values(key)
                return type(v) == "table" and v[1] or v
            end
            local root = os.projectdir()
            local oc = path.join(root, "Simulators", "opencourant")
            local scripts = path.join(oc, "Compiling_tools", "script")
            local outdir = value("oc_generated_dir")
            local requested = value("oc_python")
            local python
            if requested and requested ~= "" then
                assert(os.isfile(requested), "OpenCourant Python not found: " .. requested)
                python = requested
            else
                local tool = find_tool("python")
                assert(tool, "python not found; set --opencourant_python=<path>")
                python = tool.program
            end
            os.mkdir(outdir)

            local component = value("oc_component")
            local outputs, inputs
            if component == "starter" then
                outputs = {
                    path.join(outdir, "fullstarter_message_description.txt"),
                    path.join(outdir, "starter_message_description.inc"),
                    path.join(outdir, "build_info.inc"),
                }
                inputs = {
                    path.join(oc, "starter", "source", "output", "message",
                              "starter_message_description.txt"),
                    path.join(oc, "hm_cfg_files", "messages", "CONFIG",
                              "msg_hw_radioss_reader.txt"),
                    path.join(scripts, "merge_files.py"),
                    path.join(scripts, "build_message.py"),
                    path.join(scripts, "or_build_info.py"),
                }
            else
                outputs = {
                    path.join(outdir, "engine_message_description.inc"),
                    path.join(outdir, "build_info.inc"),
                }
                inputs = {
                    path.join(oc, "engine", "source", "output", "message",
                              "engine_message_description.txt"),
                    path.join(scripts, "build_message.py"),
                    path.join(scripts, "or_build_info.py"),
                }
            end
            local newest, oldest = 0, math.maxinteger
            for _, input in ipairs(inputs) do
                newest = math.max(newest, os.mtime(input) or 0)
            end
            for _, output in ipairs(outputs) do
                oldest = math.min(oldest, os.mtime(output) or 0)
            end
            if oldest >= newest and oldest > 0 then return end

            if component == "starter" then
                os.vrunv(python, {path.join(scripts, "merge_files.py"),
                    "-file1=" .. inputs[1], "-file2=" .. inputs[2],
                    "-outfile=" .. outputs[1]})
                os.vrunv(python, {path.join(scripts, "build_message.py"),
                    "-inputfile=" .. outputs[1], "-outfile=" .. outputs[2]})
            else
                os.vrunv(python, {path.join(scripts, "build_message.py"),
                    "-inputfile=" .. inputs[1], "-outfile=" .. outputs[1]})
            end
            os.vrunv(python, {path.join(scripts, "or_build_info.py"),
                "-arch=win64", "-outfile=" .. outputs[#outputs]})
        end)
    target_end()
    return name
end

local function declare_object(name, language, files, flags, incdirs, deps, moddir)
    target(name)
        set_kind("object")
        configure_common(name, deps)
        for _, rel in ipairs(files) do
            if language == "fortran" then
                add_files(path.join(OC, rel), {rules = {"oc.fortran", override = true}})
            else
                add_files(path.join(OC, rel))
            end
        end
        if language == "fortran" then
            add_fortran_settings(flags, incdirs, moddir)
        elseif language == "c" then
            for _, flag in ipairs(flags) do add_cflags(flag, {force = true}) end
            add_many(add_includedirs, incdirs)
        else
            for _, flag in ipairs(flags) do add_cxxflags(flag, {force = true}) end
            add_many(add_includedirs, incdirs)
        end
    target_end()
end

local function declare_component(component)
    local conf = COMPONENTS[component]
    local sources = OC_IFX_MANIFEST[component]
    if not sources then raise("missing OpenCourant manifest for " .. component) end
    local genroot = path.join(BUILD, "simulators", "windows", "x64", "release",
                              "generated", "opencourant", component)
    local gendir = path.join(genroot, "includes")
    local moddir = path.join(genroot, "modules")
    local generated = declare_codegen(component, gendir)
    local base_includes = header_dirs(conf, gendir)
    local f_includes = append(base_includes, conf.fortran_extra_incdirs)
    local c_includes = append(base_includes, conf.c_extra_incdirs)

    local c_targets = {}
    local function add_language_group(language, files, baseflags)
        local regular = {}
        for _, rel in ipairs(files) do
            local override = conf.c_overrides[rel]
            if override then
                local name = "oc_" .. component .. "_cc_special_" ..
                             tostring(#c_targets + 1)
                declare_object(name, language, {rel}, override, c_includes,
                               {generated})
                table.insert(c_targets, name)
            else
                table.insert(regular, rel)
            end
        end
        if #regular > 0 then
            local name = "oc_" .. component .. "_" .. language
            declare_object(name, language, regular, baseflags, c_includes,
                           {generated})
            table.insert(c_targets, name)
        end
    end
    add_language_group("c", sources.c_sources, conf.c_flags)
    add_language_group("cxx", sources.cxx_sources, conf.cxx_flags)

    local previous = {generated}
    local final_files = sources.fortran_levels[#sources.fortran_levels]
    for level = 1, #sources.fortran_levels - 1 do
        local regular, specials = {}, {}
        for _, rel in ipairs(sources.fortran_levels[level]) do
            local override = conf.fortran_overrides[rel]
            local extra = conf.fortran_extra[rel]
            if override or extra then
                table.insert(specials, {rel = rel,
                    flags = append(override or conf.fortran_flags, extra)})
            else
                table.insert(regular, rel)
            end
        end
        local current = {}
        if #regular > 0 then
            local name = string.format("oc_%s_f%02d", component, level)
            declare_object(name, "fortran", regular, conf.fortran_flags,
                           f_includes, previous, moddir)
            table.insert(current, name)
        end
        for index, special in ipairs(specials) do
            local name = string.format("oc_%s_f%02d_special_%02d",
                                       component, level, index)
            declare_object(name, "fortran", {special.rel}, special.flags,
                           f_includes, previous, moddir)
            table.insert(current, name)
        end
        if #current == 0 then raise("empty OpenCourant Fortran level") end
        previous = current
    end

    for _, rel in ipairs(final_files) do
        if conf.fortran_overrides[rel] or conf.fortran_extra[rel] then
            raise("final Fortran source has special flags: " .. rel)
        end
    end

    target("opencourant_" .. component)
        set_kind("binary")
        configure_common("opencourant_" .. component,
                         append(append(previous, c_targets), {generated}))
        set_basename(conf.exe)
        set_targetdir(build_out("simulators", "bin"))
        for _, rel in ipairs(final_files) do
            add_files(path.join(OC, rel), {rules = {"oc.fortran", override = true}})
        end
        add_fortran_settings(conf.fortran_flags, f_includes, moddir)
        add_many(add_linkdirs, conf.linkdirs)
        add_many(add_links, conf.links)
        add_ldflags("-threads", "-libs:static", "/Qopenmp", {force = true})
        for _, flag in ipairs(conf.ldflags) do add_ldflags(flag, {force = true}) end
        -- ifx rejects /link inside an @response file. Xmake's generic Windows
        -- adapter puts the whole long command there; keep only objects in it.
        on_link(function (target)
            import("core.tool.linker")
            import("core.project.depend")
            local ld = linker.load(target:kind(), target:sourcekinds(), {target = target})
            local flags = ld:linkflags({target = target})
            local objects = target:objectfiles()
            depend.on_changed(function ()
                local rsp = path.join(target:autogendir(), "objects.rsp")
                local lines = {}
                for _, obj in ipairs(objects) do
                    table.insert(lines, '"' .. path.absolute(obj) .. '"')
                end
                os.mkdir(path.directory(rsp))
                io.writefile(rsp, table.concat(lines, "\n"))
                local driver, linkerflags = {}, {}
                for _, flag in ipairs(flags) do
                    if flag == "-threads" or flag == "-libs:static" or
                       flag == "/Qopenmp" or flag:sub(1, 2) == "/F" then
                        table.insert(driver, flag)
                    else
                        table.insert(linkerflags, flag)
                    end
                end
                os.mkdir(target:targetdir())
                os.vrunv(ld:program(), table.join(driver,
                    {"-o", target:targetfile(), "@" .. rsp, "/link"}, linkerflags),
                    {envs = target:toolchain("oneapi-windows"):runenvs()})
            end, {dependfile = target:dependfile(), files = objects,
                  values = {ld:program(), flags},
                  lastmtime = os.mtime(target:targetfile()),
                  changed = target:is_rebuilt()})
        end)
    target_end()
end

declare_component("starter")
declare_component("engine")

target("opencourant")
    set_kind("phony")
    set_default(false)
    add_deps("opencourant_starter", "opencourant_engine")
target_end()
