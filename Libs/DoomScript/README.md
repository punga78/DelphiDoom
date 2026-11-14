# Libs\DoomScript

Il linguaggio di script di Doom 3 (id Tech 4) a classi: compilatore, programma, interprete, thread, eventi e
salvataggio, port di `game\script\Script_*.cpp`, `game\gamesys\Event.cpp` e della parte di `Class.cpp` che serve agli
eventi. **Nessun chiamante nel motore** di Doom, Heretic, Hexen e Strife: e' una base per codice ispirato a idTech 4.
Le unit derivano dal sorgente GPL v3 di Doom 3 e lo dichiarano nell'intestazione.

Il testo di riferimento (mappa C++ -> Pascal, proprieta' degli oggetti, differenze, difetti dell'originale, harness)
sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- `TDoomScriptFactory.CreateMachine(host, world, log, fileSystem)` da' una `TDoomScriptMachine`: l'unico punto che
  conosce le classi concrete. Nessuno stato globale: due macchine sono indipendenti.
- L'host implementa `IDoomScriptHost` (tempo, numeri casuali, percorsi, cvar `g_debugScript`/`developer`/`g_disasm`,
  testo per lo sviluppatore) e, se ha un mondo, `IDoomScriptWorld` (cerca e crea entita', segnali). Log e file sono
  `IIdLibLog` e `IIdLibFileSystem` di `Libs\IdLib`.
- Le entita' dell'host sono `TDoomScriptEventTarget` (una classe di eventi dichiarata sotto `idClass`, con i gestori
  aggiunti con `AddEvent`) registrate in `Machine.Entities` con un numero da 0 a 4095; lo script le vede come
  numero + 1.
- Gli eventi di `sys` che non toccano il mondo sono della libreria (attese, stampa, matematica, stringhe, argomenti
  di spawn, thread); quelli di mondo (`say`, `trigger`, cvar, camera, trace, fade, musica, danno, disegni di debug...)
  sono definiti ma senza gestore: l'host li aggiunge alla classe dei thread.

```pascal
LMachine := TDoomScriptFactory.CreateMachine(LHost, LWorld, LLog, LFiles);
LMachine.ScriptProgram.Startup('script/doom_main.script');   // include script/doom_defs.script
// un evento di mondo dato dall'host
LMachine.Context.ThreadClass.AddEvent(LMachine.SysEvents.Say,
  procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
  begin
    LConsole.Say(AArgs[0].StringValue);
  end);
LThread := LMachine.CreateThread(LMachine.ScriptProgram.FindFunction('main'));
LThread.DelayedStart(0);
// a ogni fotogramma, dopo aver avanzato il tempo dell'host:
LMachine.ServiceEvents;
// salvataggio: programma, thread, coda degli eventi
LMachine.Save(LStream);
```

Gli errori sono eccezioni: `EDoomScriptError` (il `gameLocal.Error` dell'originale: compilazione fallita, errore a
runtime di uno script), `EDoomScriptMemoryError` (un accesso che nell'originale era fuori dalla memoria della
macchina: salvataggio guasto, puntatore a un oggetto rimosso, programma danneggiato), `EIdLexerException` (errori
diretti del lexer e del parser, come un `#include` che non si trova).

## Prova

- `Tests\DelphiDoom.Tests.DoomScript` (`Tools\build.bat Tests\DelphiDoom.Tests.DoomScript Release [Win64]`): 324 test
  a Win32 e a Win64, copertura 96% delle righe (`Tools\Copertura.ps1 -Test DoomScript`).
- **Parita' col C++ vero di Doom 3**: 16 scenari (`Tests\Data\DoomScript\scenarios`), 16660 righe di golden scritte
  dall'harness `Tools\Verifica\110` (i veri `Script_*.cpp`, `Event.cpp`, `Class.cpp` e idlib compilati con bcc32c);
  il driver Pascal (`Tests\Source\DelphiDoom.Tests.DoomScript.Parity.*`) da' le stesse righe a 32 e a 64 bit. Le
  uniche differenze accettate sono dichiarate in `TTestDoomScriptParity` (vedi CLAUDE.md).
- `Tools\Verifica\110\Prova-Pascal.ps1` compila, esegue e lascia le righe del driver in `logs\doomscript-parity`;
  `Tools\Verifica\110\Righe-Scoperte.ps1` elenca le righe non coperte di un'unit.

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
- Parser e dizionario di idTech 4 (`TIdParser`, `TIdDict`): [Libs\Scanner](../Scanner/README.md); lexer, stringhe,
  vettori, MD4, log e file: [Libs\IdLib](../IdLib/README.md); angoli: [Libs\MathCore](../MathCore/README.md).
