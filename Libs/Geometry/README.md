# Libs\Geometry — tipi geometrici di idlib in Delphi

> Note per Claude e paragrafi di dettaglio (issue #178): [CLAUDE.md](CLAUDE.md).

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
| `Sphere` | `idSphere` | record di 16 byte; tutto tranne le rotazioni (in `Libs\MathCore`, `TIdBoundsRotation`) |
| `Box` | `idBox` | record di 60 byte; `AddPoint`, `AddBox`, assi separatori, silhouette |
| `Frustum` | `idFrustum` | `TGeoFrustum`, 68 byte: taglio, proiezioni, intersezioni con punti, bounds, sfere, scatole, frustum e winding |
| `Winding2D` | `idWinding2D` | classe, al massimo 16 punti (storage di 20); i piani 2D sono `TGeoVec3`; winding in senso orario; usa `TIdVec2` di IdLib |
| `DrawVert` | `idDrawVert` | record di 60 byte con `Lerp`, `LerpAll`, `Normalize`, colore little endian |
| `Surface` | `idSurface` | classe: spigoli (lo 0 e' finto), `Split`, `ClipInPlace`, raggio, segmento, connessione, chiusura |
| `Surface.Polytope` | `idSurface_Polytope` | tetraedro, esaedro, ottaedro, `FromPlanes` (corretto), `SplitPolytope` |
| `Surface.Patch` | `idSurface_Patch` | `Subdivide`, `SubdivideExplicit`, normali, tolta delle righe e colonne lineari |

Non portati perché non servono alla collisione: `idRotation`, `idQuat`, `idAngles`, matrici NxN, `idSurface_*`,
ottaedro, dodecaedro, cono e osso del trace model.

`Libs\MathCore` ha `TVec3 = array[0..2] of Single` (per il motore a punto fisso) senza operatori: non è riusabile qui.

## Seconda fetta della #96 e verifica

`Frustum`, `Winding2D`, `DrawVert`, `Surface`, `Surface.Polytope` e `Surface.Patch` (con `TIdJointMat` e `TIdJointQuat` in
`Libs\MathCore`) hanno il loro progetto di test, `Tests\DelphiDoom.Tests.Geometry` (118 test, Win32 e Win64), e due file
golden scritti dal **C++ vero** compilato con `bcc32c` (`Tests\Data\Geometry\surface.golden.txt` e `frustum.golden.txt`).
Per rifarli: `powershell -File Tools\Verifica\96\Build-Harness.ps1` (copia `Reference\doom3\neo\idlib` in una cartella
temporanea, con un `precompiled.h` finto e poche correzioni alla **copia**, elencate in testa allo script; nessun sorgente
C++ finisce nel repository). Le dipendenze: le unit nuove usano `TIdVec2` e `TIdMath` di `Libs\IdLib\Math`, quindi un
progetto che le compila ha `..\Libs\IdLib\Core;..\Libs\IdLib\Math;..\Libs\IdLib\Text` nel percorso delle unit. I difetti
dell'originale e le tolleranze sono nel paragrafo "seconda fetta" di `Libs\MathCore\CLAUDE.md`.