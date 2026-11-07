# Libs\Geometry — tipi geometrici di idlib in Delphi

Port della parte di idlib (`math`, `bv`, `geometry` di `Reference\doom3\neo\idlib`) che serve al modello di collisione
(`Libs\Collision`, vedi il suo `README.md`). Codice **derivato da Doom 3 GPL Source Code** (copyright id Software,
GPL v3 con termini aggiuntivi): le unit portano l'intestazione e l'opera ricade nella GPL v3.

| Unit | C++ | Note |
|---|---|---|
| `Types` | costanti di `Plane.h`, `Lib.h` | `PLANESIDE_*`, `PLANETYPE_*`, `ON_EPSILON`, `MAX_WORLD_COORD` |
| `FloatMath` | `idMath`, macro `FLOATSIGNBITSET` ... | `Rint` è `floorf(f+0.5f)`; `InvSqrt` è `1/Sqrt` in `Double` (il C++ usa tabella e Newton) |
| `Vec3` | `idVec3` | record di 12 byte con operatori; `FixDegenerateNormal`, `NormalVectors` |
| `Mat3` | `idMat3` | solo ciò che serve: prodotto, trasposta, `IsRotated`, `vec * mat` (come idlib: `v*M = x*M[0] + y*M[1] + z*M[2]`) |
| `Plane` | `idPlane` | `Dist = -d`; `Make(normale, distanza)`; `FixDegeneracies` |
| `Bounds` | `idBounds` | `Mins`/`Maxs`; `PlaneSide`, `PlaneDistance` |
| `Pluecker` | `idPluecker` | `FromLine`, `FromRay`, `PermutedInnerProduct` |
| `Winding` | `idWinding`/`idFixedWinding` | classe; senza le coordinate di texture di `idVec5` |
| `TraceModel` | `idTraceModel` | box, cilindro, poligono e volume, normali degli spigoli, `Translate` |

Non portati perché non servono alla collisione: `idRotation`, `idQuat`, `idAngles`, matrici NxN, `idSurface_*`,
ottaedro, dodecaedro, cono e osso del trace model.

`Libs\MathCore` ha `TVec3 = array[0..2] of Single` (per il motore a punto fisso) senza operatori: non è riusabile qui.
