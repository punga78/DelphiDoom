# Libs\Console

Meccanismo della console: registro dei comandi, interprete, variabili, coda, cronologia, riga di input.

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 21 (nome a punti `DelphiDoom.Console.*`).
- Interfacce dichiarate: `ICommandRegistry`, `IConsoleFileSystem`, `IConsoleInterpreter`, `IConsoleOutput`, `IConsoleScriptRunner`, `IConsoleStartupSource`, `IConsoleVariable`, `IConsoleVariableSource`.
- Punto di creazione delle classi: `DelphiDoom.Console.Factory`.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Console`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
