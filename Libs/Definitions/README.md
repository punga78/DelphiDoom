# Libs\Definitions

Lettura di ANIMDEFS, della tabella degli interruttori e della tabella del terreno.

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 9 (nome a punti `DelphiDoom.Definitions.*`).
- Interfacce dichiarate: `IDefAnimDefsParser`, `IDefAnimNameCatalog`, `IDefSwitchLumpReader`, `IDefSwitchSelector`, `IDefTerrainTable`, `IDefTextureLookup`.
- Punto di creazione delle classi: `DelphiDoom.Definitions.Factory`.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Definitions`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
