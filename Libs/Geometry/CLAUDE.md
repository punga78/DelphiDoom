# Libs\Geometry — note per Claude

Il paragrafo che riguarda questa libreria sta nel CLAUDE.md di `Libs\Collision`: [Libs/Collision/CLAUDE.md](../Collision/CLAUDE.md).

Le unit della issue #96 (piani, bounds, sfere, scatole; frustum, winding 2D, vertici, superfici, polytope e patch) sono descritte nel CLAUDE.md di `Libs\MathCore` ("Issue #96"), dove stanno anche la parita' col C++ e i difetti dell'originale; i test sono in `Tests\DelphiDoom.Tests.Geometry`. `TGeoMath` e' un ponte a `TIdMath` (`Libs\IdLib\Math`).

**Issue #236:** `TGeoVec3` delega a `TIdVec3` le funzioni duplicate (vedi `Libs\MathCore\CLAUDE.md`); `idSurface_SweptSpline` e' `TIdSurfaceSweptSpline` in MathCore con il golden `Tests\Data\Geometry\swept.golden.txt`.
