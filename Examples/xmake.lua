set_project("simulator-learning-examples")
set_version("0.1.0")

add_rules("mode.debug", "mode.release")

-- Keep all generated Xmake output outside the source workspace.
set_targetdir(path.join(os.projectdir(), "..", "build", "examples", "$(plat)", "$(arch)", "$(mode)", "bin"))
set_objectdir(path.join(os.projectdir(), "..", "build", "examples", "$(plat)", "$(arch)", "$(mode)", "obj"))
set_dependir(path.join(os.projectdir(), "..", "build", "examples", "$(plat)", "$(arch)", "$(mode)", "dep"))

includes("mujoco")
includes("opencourant")
includes("peridyno")
includes("position-based-dynamics")
