-- Native Xmake jobs/compiler, with one dependency plan per module level.
-- Per-object Lua depfile writes are expensive on this Windows host; ifx also
-- cannot produce CL /showIncludes output. Track headers conservatively instead.
import("core.tool.compiler")
import("core.project.depend")
import("core.base.option")

function main(target, graph, batch)
    local fc = compiler.load("fc", {target = target})
    local flags = {}
    for i, src in ipairs(batch.sourcefiles) do
        flags[i] = fc:compflags({target = target, sourcefile = src})
    end
    local statefile = path.join(target:autogendir(), "fortran-plan.lua")
    -- depend.is_changed compares only one array level; keep values flat.
    local values = {fc:program()}
    for i, src in ipairs(batch.sourcefiles) do
        table.insert(values, src)
        table.insert(values, table.concat(flags[i], "\n"))
    end
    local prepared = false
    local function prepare()
        if prepared then return end
        local files, seen = {}, {}
        local function track(file)
            if not seen[file] then seen[file] = true; table.insert(files, file) end
        end
        track(path.join(os.projectdir(), "xmake", "opencourant", "build_fortran.lua"))
        for _, src in ipairs(batch.sourcefiles) do track(src) end
        for _, dep in ipairs(target:orderdeps()) do
            for _, obj in ipairs(dep:objectfiles()) do track(obj) end
        end
        -- Include directories cover the upstream .inc/.h files and generated
        -- messages. Add/remove detection uses the complete sorted input list.
        for _, dir in ipairs(target:get("includedirs") or {}) do
            for _, pattern in ipairs({"**.inc", "**.h"}) do
                for _, file in ipairs(os.files(path.join(dir, pattern))) do track(file) end
            end
        end
        table.sort(files)
        local old = depend.load(statefile) or {}
        local dirty = target:is_rebuilt() or depend.is_changed(old,
            {lastmtime = os.mtime(statefile), files = files,
             values = {values, files}})
        if dirty then
            -- Publish a plan only after invalidating its old outputs. If the
            -- build is interrupted, completed objects survive and missing ones
            -- are retried using this same plan.
            for _, obj in ipairs(batch.objectfiles) do os.tryrm(obj) end
            os.mkdir(path.directory(statefile))
            local tmp = statefile .. ".tmp"
            depend.save({files = files, values = {values, files}}, tmp)
            os.mv(tmp, statefile)
        end
        prepared = true
    end
    for i, src in ipairs(batch.sourcefiles) do
        local obj, compflags = batch.objectfiles[i], flags[i]
        graph:add(target:fullname() .. "/fc/" .. src, function ()
            if option.get("dry-run") then return end
            prepare()
            if os.isfile(obj) then return end
            os.mkdir(path.directory(obj))
            if option.get("verbose") then print(fc:compcmd(src, obj, {compflags = compflags})) end
            -- No CL dependency request: ifx ignores /showIncludes. The shared
            -- plan above accounts for include and module-order dependencies.
            local ok, err = fc:compile(src, obj, {compflags = compflags})
            if not ok then os.tryrm(obj); raise(err) end
        end)
    end
end
