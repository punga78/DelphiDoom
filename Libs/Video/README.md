# Libs\Video

Parte del video indipendente dall'API grafica: palette, limiti, catalogo dei modi, risoluzione.

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 11 (nome a punti `DelphiDoom.Video.*`).
- Interfacce dichiarate: `IDisplayMetrics`, `IDisplayModeCatalog`, `IDisplayModeSource`, `IMemoryStallHack`, `IPaletteConverter`, `IScreenSizeResolver`, `ISizeLimiter`, `IVideoServices`.
- Punto di creazione delle classi: `DelphiDoom.Video.Factory`.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Video`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
