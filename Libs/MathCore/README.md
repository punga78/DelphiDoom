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