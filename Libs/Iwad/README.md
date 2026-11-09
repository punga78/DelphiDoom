# Libs\Iwad

Ricerca e riconoscimento degli IWAD.

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 15 (nome a punti `DelphiDoom.Iwad.*`).
- Interfacce dichiarate: `IIwadEnvironment`, `IIwadFileSystem`, `IIwadIdentifier`, `IIwadLocator`, `IIwadOptions`, `IIwadProfile`, `IIwadSearchPath`, `IIwadSteam`.
- Punto di creazione delle classi: `DelphiDoom.Iwad.Factory`.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Iwad`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
