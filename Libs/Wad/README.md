# Libs\Wad

Lettura e scrittura di WAD, PAK, ZIP e cartelle; directory dei lump del motore.

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 37 (nome a punti `DelphiDoom.Wad.*`).
- Interfacce dichiarate: `ILumpCache`, `ILumpReader`, `IPakIndex`, `IPakPathResolver`, `IWadBuilder`, `IWadDirectory`, `IWadDll`, `IWadDllBuilder`.
- Punto di creazione delle classi: `DelphiDoom.Wad.Factory`.
- Progetti nella cartella: `DDWad`.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Wad`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
