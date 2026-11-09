# Libs\Blockmap

Costruzione e lettura della blockmap e rimozione delle slime trails.

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 6 (nome a punti `DelphiDoom.Blockmap.*`).
- Interfacce dichiarate: `IBlockmapBuilder`, `IBlockmapLumpReader`, `ISlimeTrailRemover`.
- Punto di creazione delle classi: `DelphiDoom.Blockmap.Factory`.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Blockmap`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
