// Link/run check for the Xmake-built PositionBasedDynamics libraries:
// a tiny consumer of pbd_core proving the static library links and runs.
#include "PositionBasedDynamics/MathFunctions.h"

#include <cstdio>

int main()
{
    Matrix3r m;
    m << 3, 0, 0,
         0, -1, 0,
         0, 0, 2;
    const double n = PBD::MathFunctions::oneNorm(m);
    std::printf("oneNorm(diag(3,-1,2)) = %g\n", n);
    return n == 3.0 ? 0 : 1;
}
