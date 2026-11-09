# Libs\TextureDefs

Lettura delle definizioni delle texture (PNAMES, TEXTURE1..3, TEXTURE0) e dei flat (FLATINFO).

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 10 (nome a punti `DelphiDoom.TextureDefs.*`).
- Interfacce dichiarate: `ITextureDefsFlatCatalog`, `ITextureDefsFlatInfoParser`, `ITextureDefsLoader`, `ITextureDefsLumpSource`, `ITextureDefsPatchNamesReader`, `ITextureDefsPk3Reader`, `ITextureDefsTextureLumpReader`.
- Punto di creazione delle classi: `DelphiDoom.TextureDefs.Factory`.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.TextureDefs`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
