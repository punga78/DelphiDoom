# Libs\TableExport

Scrittura delle tabelle correnti del motore come DEH, ACTORDEF, WEAPONDEF, CSV e sorgente Pascal.

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 14 (nome a punti `DelphiDoom.TableExport.*`).
- Interfacce dichiarate: `IExportActorDefWriter`, `IExportCsvWriter`, `IExportDehWriter`, `IExportEnumNames`, `IExportFlagNames`, `IExportLookups`, `IExportPascalWriter`, `IExportSettingsSource`.
- Punto di creazione delle classi: `DelphiDoom.TableExport.Factory`.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.TableExport`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
