# Libs\Geometry — note per Claude

Il paragrafo che riguarda questa libreria sta nel CLAUDE.md di `Libs\Collision`: [Libs/Collision/CLAUDE.md](../Collision/CLAUDE.md).

Le unit della issue #96 (piani, bounds, sfere, scatole; frustum, winding 2D, vertici, superfici, polytope e patch) sono descritte nel CLAUDE.md di `Libs\MathCore` ("Issue #96"), dove stanno anche la parita' col C++ e i difetti dell'originale; i test sono in `Tests\DelphiDoom.Tests.Geometry`. `TGeoMath` e' un ponte a `TIdMath` (`Libs\IdLib\Math`).

**Issue #236:** `TGeoVec3` delega a `TIdVec3` le funzioni duplicate (vedi `Libs\MathCore\CLAUDE.md`); `idSurface_SweptSpline` e' `TIdSurfaceSweptSpline` in MathCore con il golden `Tests\Data\Geometry\swept.golden.txt`.

**Issue #236, parte A (modelli di collisione dei corpi AF):** `TTraceModel` ha ora `SetupOctahedron`, `SetupDodecahedron` e `SetupCone` (due forme ciascuno: bounds e misure; `SetupBone` e `SetupCylinder` c erano gia). Parita sul vero `TraceModel.cpp` di Doom 3 (bcc32c, `Tools\Verifica\96\trm-main.cpp`, `Build-Harness.ps1`): `Tests\Data\Geometry\trm.golden.txt` (196 righe: 80 ottaedri e dodecaedri con bounds casuali, 80 coni e cilindri con 0..100 lati compresi i limiti, 36 con le misure; tipo, conteggi, vertici, spigoli con normali, poligoni con piano e bounds), `TTestGeometryTraceModel` (6 test, Win32 e Win64): i valori discreti identici, i float entro 4 ULP o 1e-3 (anche `SetupCylinder`, mai confrontato prima, passa). Differenza del C++ conservata: `SetupCone` con meno di 2 lati ne usa 3 (il cilindro: meno di 3). `idAFFileManager` non e portabile: in Doom 3 esiste solo come `friend class` di `idDeclAF` (`DeclAF.h`), senza implementazione nei sorgenti. Resta fuori il gioco `idAF`/`idAFBody` (fisica e `idEntity`).
