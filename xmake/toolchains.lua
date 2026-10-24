-- Minimal Windows oneAPI toolchain adapter.
--
-- Xmake 3.1 already knows how to compile/link with ifx and icx. Its built-in
-- Windows detector, however, requires setvars.bat; that script does not return
-- reliably in non-interactive runners. This adapter only supplies tool paths
-- and environment entries, then leaves compilation to Xmake's native rules.

toolchain("oneapi-windows")
    set_kind("standalone")

    on_load(function (toolchain)
        import("private.utils.toolchain", {alias = "toolchain_utils"})

        local root = os.getenv("ONEAPI_ROOT") or
                     [[C:\Program Files (x86)\Intel\oneAPI]]
        local compilers = os.dirs(path.join(root, "compiler", "2*"))
        local mkls = os.dirs(path.join(root, "mkl", "2*"))
        table.sort(compilers, function (a, b) return a > b end)
        table.sort(mkls, function (a, b) return a > b end)
        assert(compilers[1], "Intel oneAPI compiler not found under " .. root)
        assert(mkls[1], "Intel oneAPI MKL not found under " .. root)

        local compiler = compilers[1]
        local mkl = mkls[1]
        local bin = path.join(compiler, "bin")

        -- Reuse Xmake's own Visual Studio/Windows SDK discovery.
        toolchain_utils.check_vstudio(toolchain, function () return true end)
        toolchain_utils.add_vsenvs(toolchain)

        toolchain:set("toolset", "fc", path.join(bin, "ifx.exe"))
        toolchain:set("toolset", "fcld", path.join(bin, "ifx.exe"))
        toolchain:set("toolset", "fcsh", path.join(bin, "ifx.exe"))
        -- Xmake's icx flag probe inherits the GNU clang probe (-S -o),
        -- although its Windows compile adapter uses CL syntax. Select the
        -- matching CL adapter/probe explicitly; the executable is still icx.
        toolchain:set("toolset", "cc", "clang_cl@" .. path.join(bin, "icx.exe"))
        toolchain:set("toolset", "cxx", "clang_cl@" .. path.join(bin, "icx.exe"))
        toolchain:set("toolset", "mrc", "rc.exe")
        toolchain:set("toolset", "as", "ml64.exe")
        toolchain:set("toolset", "ar", "link.exe")

        toolchain:add("runenvs", "PATH", bin, path.join(mkl, "bin"))
        toolchain:add("runenvs", "LIB", path.join(compiler, "lib"),
                      path.join(mkl, "lib"))
    end)
toolchain_end()
