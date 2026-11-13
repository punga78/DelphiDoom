# Tests\Data\Geometry

Golden files of the geometry library (issue #96), written by the real C++ idlib of Doom 3 compiled with bcc32c.

| File | Lines | Test |
|---|---|---|
| `surface.golden.txt` | 3856 | `DelphiDoom.Tests.Geometry.DrawVert`, `JointMat`, `Winding2D`, `Surface`, `SurfacePolytope`, `SurfacePatch` |
| `frustum.golden.txt` | 6800 | `DelphiDoom.Tests.Geometry.Frustum.Parity` |

Each line is `name inputs... | outputs...`; floats are `#` plus the eight hexadecimal digits of the bits. The meshes of the
surface tests are written once (`mesh <number> ...`) and referred to by number. To rewrite both files:
`powershell -File Tools\Verifica\96\Build-Harness.ps1` (needs `Reference\doom3` and `bcc32c`).
