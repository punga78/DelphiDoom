# Libs\DynLights

Parser e registro delle luci dinamiche (GLDEFS/LIGHTDEF).

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 11 (nome a punti `DelphiDoom.DynLights.*`).
- Interfacce dichiarate: `IDynLightAnimator`, `IDynLightBinder`, `IDynLightLoader`, `IDynLightObjectResolver`, `IDynLightParser`, `IDynLightRandom`, `IDynLightRegistry`, `IDynLightRenderCache`.
- Punto di creazione delle classi: `DelphiDoom.DynLights.Factory`.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.DynLights`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
