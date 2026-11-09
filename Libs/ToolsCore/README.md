# Libs\ToolsCore

Codice comune dei tool: annulla/rifai, file recenti, impostazioni, avanzamento, copia di sicurezza.

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 9 (nome a punti `DelphiDoom.ToolsCore.*`).
- Interfacce dichiarate: `IProgressObserver`, `IProgressReporter`, `IRecentFiles`, `ISettingsStore`, `IToolFileBackup`, `IToolFileSystem`, `IToolUndoHistory`.
- Punto di creazione delle classi: `DelphiDoom.Tools.Factory`.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.ToolsCore`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
