# Libs\Console

Meccanismo della console: registro dei comandi, interprete, variabili, coda, cronologia, riga di input.

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 21 (nome a punti `DelphiDoom.Console.*`).
- Interfacce dichiarate: `ICommandRegistry`, `IConsoleFileSystem`, `IConsoleInterpreter`, `IConsoleOutput`, `IConsoleScriptRunner`, `IConsoleStartupSource`, `IConsoleVariable`, `IConsoleVariableSource`.
- Punto di creazione delle classi: `DelphiDoom.Console.Factory`.

## Profilo id Tech 4 (issue #113)

Unit DelphiDoom.Console.CmdSystem.*, DelphiDoom.Console.CVar.* e DelphiDoom.Console.IdTech4.Factory (TIdTech4Console): sistema dei comandi e delle cvar di Doom 3 come oggetti, accanto al meccanismo di DelphiDoom senza cambiarlo. Parita' col C++ provata con golden del vero codice (Tests\Data\Console\IdTech4). Cosa e' fatto, cosa no e le differenze: CLAUDE.md.

## Profilo Quake III (issue #113, seconda fetta)

Unit `DelphiDoom.Console.Q3.*` (`Types`, `CVar`, `Intf`, `CommandArguments`, `CommandBuffer`, `CommandSystem`, `StandardCommands`, `CVarSystem`, `CVarCommands` e `Factory` con `TQ3Console`): buffer dei comandi (`Cbuf_*`), tokenizzatore, lista dei comandi, `exec`, `vstr`, `echo`, `wait`, `cmdlist`, cvar con flag (ROM, INIT, LATCH, CHEAT, USERINFO, SERVERINFO, SYSTEMINFO, ...), `set`/`seta`/`sets`/`setu`/`toggle`/`reset`/`cvarlist`/`cvar_restart`, `Register`/`Update` e info string dei flag (tramite `IQ3InfoStringWriter`), come oggetti e non come singleton, port di `cmd.c` e `cvar.c` di Quake III. Senza chiamanti nel motore; il meccanismo di DelphiDoom e il profilo id Tech 4 non sono toccati. Parita' sul C vero (`Tools\Verifica\113q3`, golden in `Tests\Data\Console\Q3`); dettagli, difetti del C conservati e cio' che resta in [CLAUDE.md](CLAUDE.md).

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Console`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
