# Libs\MathCore

Parti pure di generatore casuale, hash, CRC, SHA-1, tabelle trigonometriche, aritmetica fixed, vettori e bbox.

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 24 (nome a punti `DelphiDoom.MathCore.*`).
- Interfacce dichiarate: `IEntropySource`, `IGameRandom`, `IStringHashTable`.
- Punto di creazione delle classi: `DelphiDoom.MathCore.Factory`.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.MathCore`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).

## Virgola mobile di id Tech 4 (issue #95, prima fetta)

`DelphiDoom.MathCore.Float.*`: `TIdAngles`, `TIdQuat`, `TIdCQuat`, `TIdMat3`, `TIdRotation`, `TIdComplex`, `TIdPolynomial` e `TIdRotationConversions` (conversioni tra angoli, matrice, quaternione e rotazione), record con operatori in `Single` come il `float` di `idlib\math` (Doom 3, GPL v3 con termini aggiuntivi), sopra `TIdVec3` e `TIdMath` di `Libs\IdLib\Math`. Parita' con il C++ vero (golden in `Tests\Data\MathCore\float.golden.txt`, tolleranza 2 ULP o 4e-6 relativo; radici di polinomi 2e-3): vedi [CLAUDE.md](CLAUDE.md). Non ancora: `idMat2`/`idMat4`/`idMat5`/`idMat6`/`idMatX`, vettori a 5, 6 e N componenti, `idLCP`, `idODE`, curve e interpolazioni.

## Geometria e volumi di id Tech 4 (issue #96, prima fetta)

Piani, bounds, sfere e scatole orientate di `idlib\bv` e `idlib\math\Plane` (Doom 3, GPL v3 con termini aggiuntivi). **Non sono tipi nuovi di MathCore**: stanno in `Libs\Geometry`, dove c'erano gia' `TGeoPlane`, `TGeoBounds`, `TGeoVec3`, `TGeoMat3`, `TGeoWinding` e `TTraceModel` (usati da `Libs\Collision`), e li si e' **estesi**: `TGeoPlane` (`Translate`, `Rotate`, `LineIntersection`, `RayIntersection`, `PlaneIntersection`, `FromVecs`, `Compare` con epsilon), `TGeoBounds` (raggio, volume, `Intersect`, `Expand`, `Rotate`, linea e raggio, `FromTransformedBounds`, `FromPoints`, traslazioni, `ToPoints`, `ToSphere`, proiezioni), `TGeoMat3.Compare`; nuovi `TGeoSphere` (`idSphere`) e `TGeoBox` (`idBox`, con le silhouette). In `Libs\MathCore` stanno solo i due pezzi che toccano i tipi di MathCore: `TIdGeometryAdapter` (`TIdVec3`/`TIdMat3` <-> `TGeoVec3`/`TGeoMat3`) e `TIdBoundsRotation` (i membri di `idBounds` e `idSphere` che prendono un `idRotation`). Parita' con il C++ vero: `Tests\Data\MathCore\geometry.golden.txt` (9109 righe), vedi [CLAUDE.md](CLAUDE.md). Non ancora: frustum, `idWinding2D`, `idSurface*`, `idJointTransform`, `idDrawVert`, `idBox::FromPoints`.