# Libs\Imaging

Patch, flat e immagini a classi su buffer, ricampionatore, miniatura dei salvataggi.

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 20 (nome a punti `DelphiDoom.Imaging.*`).
- Interfacce dichiarate: `IImagingColorIndex`, `IImagingColumnExpander`, `IImagingColumnPainter`, `IImagingColumnRebuilder`, `IImagingFixedColumnBuilder`, `IImagingFlatReader`, `IImagingFlatShrinker`, `IImagingHiResTableBuilder`.
- Punto di creazione delle classi: `DelphiDoom.Imaging.Factory`.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Imaging`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
