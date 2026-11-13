# Dati di prova dei modelli MD5 (issue #104)

`cube.md5mesh` e `cube.md5anim` sono un cubo con due giunti (`origin` e `arm`) e un'animazione di tre fotogrammi **scritti a mano per i test**: nessun dato di Doom 3 e' nel repository. Il cubo ha 8 vertici, 12 triangoli e 12 pesi (quattro vertici su un solo giunto, quattro su entrambi); l'animazione muove la radice (TX, TZ, QZ) e ruota il giunto figlio (QX, QY, QZ) a 24 fotogrammi al secondo.

`cube.golden.txt` e' l'uscita di un programma **fuori dal repository** (l'harness non si committa) compilato con `bcc32c -std=c++17` (clang di Delphi 11, x87) che usa le classi vere di `Reference\doom3\neo\idlib` (`idLexer`, `idQuat`, `idMat3`, `idJointMat`, `idSIMD_Generic` per `TransformVerts`, `BlendJoints`, `TransformJoints`...) con un `precompiled.h` finto, le funzioni di `idMD5Anim` (`LoadAnim`, `ConvertTimeToFrame`, `GetOrigin`, `GetOriginRotation`, `GetBounds`, `GetInterpolatedFrame`, `GetSingleFrame`) estratte per intervallo di righe da `game\anim\Anim.cpp`, e il calcolo di `idRenderModelMD5::LoadModel`/`idMD5Mesh::ParseMesh` (pose relative, pesi pre-scalati) e `idMD5Mesh::NearestJoint` copiato (queste classi dipendono dal renderer). Una riga e' `chiave argomenti | valori`; un float e' `#` e i 32 bit in esadecimale, un intero e' in decimale.

| Chiave | Contenuto |
|---|---|
| `pose i`, `abs i` | posa relativa (q xyzw, t xyz) e matrice 3x4 assoluta del giunto `i` |
| `weight k`, `ref i`, `bounds` | peso pre-scalato (xyzw, giunto, fine vertice), vertice nella posa di riferimento, bounds del modello |
| `nearest a b` | `NearestJoint(a, b, c)` per 9 combinazioni |
| `anim`, `delta`, `base i`, `fbounds f`, `fblend n` | intestazione, spostamento totale, base frame, bounds per fotogramma, `GetFrameBlend` |
| `blend t c`, `origin`, `originrot`, `abounds`, `interp`, `world`, `verts` | per 14 tempi (da -5 a 2500 ms) e 3 numeri di cicli (0, 1, 3): fotogrammi, origine, rotazione della radice, bounds, giunti interpolati, matrici assolute, vertici |
| `single f`, `defworld`, `defuntrans`, `matquats` | fotogrammi singoli e giri `TransformJoints`/`UntransformJoints`/`ConvertJointMatsToJointQuats` |

Il test (`DelphiDoom.Tests.Models.Md5Parity`) ricalcola ogni riga con le classi Pascal; tolleranza: 2 ULP, oppure 4e-6 relativo, oppure 1e-5 assoluto.