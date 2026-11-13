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

## Immagini di id Tech 4 (issue #103)

- `Rgba.Image` (`TImagingRgbaImage`), `Rgba.Sampler` (`TImagingRgbaSampler`: resample, dropsample, mipmap, blend, flip, rotazione), `ImageProgram.Operations`, `ImageProgram.Intf` (`IImagingProgramSource`) e `ImageProgram.Interpreter` (`TImagingImageProgram`): l'image program di Doom 3 (`addnormals( a, heightmap( b, 4 ) )`) sopra `TIdLexer` di `Libs\IdLib`. Sorgenti e differenze dal C++ in [CLAUDE.md](CLAUDE.md). Senza chiamanti nel motore. Parita' con il vero Doom 3 (golden in `Tests\Data\IdImages`).