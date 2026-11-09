# Libs\Thinkers

Luci, porte, piattaforme, teletrasporti, passo di pavimenti e soffitti a classi.

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 35 (nome a punti `DelphiDoom.Thinkers.*`).
- Interfacce dichiarate: `IDoorOptions`, `IDoorPlaneMover`, `IDoorRunner`, `IDoorSectorQueries`, `IDoorSounds`, `IDoorSpawner`, `ILightFlickerRules`, `ILightPhaseSpawner`.
- Punto di creazione delle classi: `DelphiDoom.Thinkers.Door.Factory`, `DelphiDoom.Thinkers.Light.Factory`, `DelphiDoom.Thinkers.Platform.Factory`.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Thinkers`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
