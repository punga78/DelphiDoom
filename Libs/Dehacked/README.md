# Libs\Dehacked

Parser delle patch DEHACKED/BEX con modello neutro.

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 33 (nome a punti `DelphiDoom.Dehacked.*`).
- Interfacce dichiarate: `IDehackedFlagSet`, `IDehackedFlagSets`, `IDehackedLineSource`, `IDehackedParser`, `IDehackedPatch`, `IDehackedProfile`, `IDehackedSectionReader`.
- Punto di creazione delle classi: `DelphiDoom.Dehacked.Factory`.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Dehacked`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
