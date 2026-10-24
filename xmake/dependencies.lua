-- Imported by lifecycle callbacks so filesystem/process APIs use Xmake's full
-- script environment rather than the description sandbox.
function ensure_checkout(dst, url, revision)
    if os.isdir(path.join(dst, ".git")) then return false end
    if os.exists(dst) then
        raise("dependency path exists but is not a git checkout: " .. dst)
    end
    local tmp = dst .. ".tmp"
    os.rm(tmp)
    os.vrunv("git", {"init", "-q", tmp})
    os.vrunv("git", {"-C", tmp, "remote", "add", "origin", url})
    os.vrunv("git", {"-C", tmp, "fetch", "-q", "--depth", "1", "origin", revision})
    os.vrunv("git", {"-C", tmp, "checkout", "-q", "--detach", "FETCH_HEAD"})
    os.mv(tmp, dst)
    return true
end
