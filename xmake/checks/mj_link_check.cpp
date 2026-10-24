// Link/run check for the Xmake-built MuJoCo core library: a tiny consumer
// proving mujoco.dll links and runs.
#include "mujoco/mujoco.h"

#include <cstdio>
#include <cstring>

int main()
{
    std::printf("mj_versionString: %s\n", mj_versionString());
    char error[1000] = "";
    mjVFS vfs;
    mj_defaultVFS(&vfs);
    const char* xml = "<mujoco/>";
    mj_addBufferVFS(&vfs, "model.xml", xml, (int) strlen(xml));
    mjModel* m = mj_loadXML("model.xml", &vfs, error, sizeof(error));
    if (!m)
    {
        std::printf("mj_loadXML failed: %s\n", error);
        return 1;
    }
    mjData* d = mj_makeData(m);
    mj_step(m, d);
    std::printf("mj_step ok, time=%g\n", d->time);
    mj_deleteData(d);
    mj_deleteModel(m);
    mj_deleteVFS(&vfs);
    return 0;
}
