# Libs\Console

Meccanismo della console: registro dei comandi, interprete, variabili, coda, cronologia, riga di input.

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 21 (nome a punti `DelphiDoom.Console.*`).
- Interfacce dichiarate: `ICommandRegistry`, `IConsoleFileSystem`, `IConsoleInterpreter`, `IConsoleOutput`, `IConsoleScriptRunner`, `IConsoleStartupSource`, `IConsoleVariable`, `IConsoleVariableSource`.
- Punto di creazione delle classi: `DelphiDoom.Console.Factory`.

## Profilo id Tech 4 (issue #113)

Unit DelphiDoom.Console.CmdSystem.*, DelphiDoom.Console.CVar.* e DelphiDoom.Console.IdTech4.Factory (TIdTech4Console): sistema dei comandi e delle cvar di Doom 3 come oggetti, accanto al meccanismo di DelphiDoom senza cambiarlo. Parita' col C++ provata con golden del vero codice (Tests\Data\Console\IdTech4). Cosa e' fatto, cosa no e le differenze: CLAUDE.md.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Console`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
