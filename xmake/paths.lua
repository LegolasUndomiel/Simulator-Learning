-- Central path conventions for the Xmake-managed build layer.
--
-- Loaded by the root xmake.lua. Keeps every path in one place so that targets
-- under xmake/simulators/ (and later Examples/, Experiments/) stay consistent.

-- Repository root (the directory that holds the top-level xmake.lua).
ROOT = os.projectdir()

-- Read-only upstream simulator sources.
SIMULATORS = path.join(ROOT, "Simulators")

-- Root build tree (ignored by git; all generated output goes here).
BUILD = path.join(ROOT, "build")

-- build_out(scope, kind) -> an output directory under build/<scope>/.
--   scope: "simulators" | "examples" | "experiments"
--   kind:  "lib" | "bin" | "obj" | "dep"
function build_out(scope, kind)
    return path.join(BUILD, scope, "$(plat)", "$(arch)", "$(mode)", kind)
end
