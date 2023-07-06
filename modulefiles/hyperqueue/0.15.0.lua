local pwd = os.getenv("PWD")
local version = myModuleVersion()
prepend_path("PATH", pathJoin(pwd, "appl/hyperqueue", version))
