# Libs\Mikmod

Lettore di moduli tracker (MOD, S3M, XM, IT) in Pascal.

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 27 (nome a punti `DelphiDoom.Mikmod.*`).
- Interfacce dichiarate: `IMikMod`, `IMikModPlayer`, `ITrackerAudioDevice`, `ITrackerOutputFactory`, `ITrackerWorker`.
- Punto di creazione delle classi: `DelphiDoom.Mikmod.Provider`.
- Progetti nella cartella: `DDMikmod`.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Mikmod`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
