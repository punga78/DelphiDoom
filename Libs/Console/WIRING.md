# Libs\Console - come collegarla al motore (issue #76, parte della #45)

La libreria porta il **meccanismo** della console: registro dei comandi (con alias), interprete della riga,
variabili `get`/`set`/`typeof`, `list`, `exec`, `printf`, file `.con`, testi di comandi, autoexec, coda dei
comandi, cronologia, riga di input, completamento con TAB e le sequenze dei cheat (`m_cheat.pas`).
Dipende solo da `System.*`, `Libs\Logging` (`ILog`) e `Libs\GameState` (`IGameContext`, per sapere se la partita
e' in rete). Non conosce il motore: il collegamento non e' stato fatto (non era compito di questo lavoro).

## 1. Unit da aggiungere ai `.dpr`

Servono in tutti i progetti che oggi compilano `c_cmds`/`c_con`/`m_cheat`: `Doom32`, `GLDoom32`, `Heretic32`,
`GLHeretic32`, `Hexen32`, `GLHexen32`, `Strife32`, `GLStrife32` (e i `ddc_*` solo se compilano `c_cmds`).
`DelphiDoom.Logging.*` e `DelphiDoom.GameState.Intf` ci sono gia'. Righe:

```
  DelphiDoom.Console.Types in 'Libs\Console\DelphiDoom.Console.Types.pas',
  DelphiDoom.Console.Intf in 'Libs\Console\DelphiDoom.Console.Intf.pas',
  DelphiDoom.Console.Text in 'Libs\Console\DelphiDoom.Console.Text.pas',
  DelphiDoom.Console.Numbers in 'Libs\Console\DelphiDoom.Console.Numbers.pas',
  DelphiDoom.Console.MaskMatcher in 'Libs\Console\DelphiDoom.Console.MaskMatcher.pas',
  DelphiDoom.Console.CommandRegistry in 'Libs\Console\DelphiDoom.Console.CommandRegistry.pas',
  DelphiDoom.Console.Interpreter in 'Libs\Console\DelphiDoom.Console.Interpreter.pas',
  DelphiDoom.Console.CommandLister in 'Libs\Console\DelphiDoom.Console.CommandLister.pas',
  DelphiDoom.Console.VariableCommands in 'Libs\Console\DelphiDoom.Console.VariableCommands.pas',
  DelphiDoom.Console.StandardCommands in 'Libs\Console\DelphiDoom.Console.StandardCommands.pas',
  DelphiDoom.Console.ScriptRunner in 'Libs\Console\DelphiDoom.Console.ScriptRunner.pas',
  DelphiDoom.Console.AutoExec in 'Libs\Console\DelphiDoom.Console.AutoExec.pas',
  DelphiDoom.Console.CommandQueue in 'Libs\Console\DelphiDoom.Console.CommandQueue.pas',
  DelphiDoom.Console.History in 'Libs\Console\DelphiDoom.Console.History.pas',
  DelphiDoom.Console.Completer in 'Libs\Console\DelphiDoom.Console.Completer.pas',
  DelphiDoom.Console.InputLine in 'Libs\Console\DelphiDoom.Console.InputLine.pas',
  DelphiDoom.Console.CheatScrambler in 'Libs\Console\DelphiDoom.Console.CheatScrambler.pas',
  DelphiDoom.Console.CheatSequence in 'Libs\Console\DelphiDoom.Console.CheatSequence.pas',
  DelphiDoom.Console.CheatSequenceReader in 'Libs\Console\DelphiDoom.Console.CheatSequenceReader.pas',
  DelphiDoom.Console.CheatTable in 'Libs\Console\DelphiDoom.Console.CheatTable.pas',
  DelphiDoom.Console.Factory in 'Libs\Console\DelphiDoom.Console.Factory.pas',
```

Riga da aggiungere in `build.bat`, alla fine della lista `TESTS`: ` Tests\DelphiDoom.Tests.Console`.
Il progetto di test usa `Tests\Data\Console` (corpus, golden e `scripts\*.con`): vedi il suo `README.md`.

## 2. Cosa sostituisce cosa

| Vecchio | Nuovo |
|---|---|
| `C_AddCmd(name, proc)` (array di 300 `cmd_t`, ordinamento, ricerca binaria) | `ICommandRegistry.Add(name, handler)`; `TConsoleCommandHandler = reference to procedure(const AParam1, AParam2: string)`. Gli alias separati da virgola funzionano come prima. Una `procedure(const parm1, parm2: string)` si passa com'e'; per `procedure` senza parametri o con uno solo serve un wrapper (`procedure(const p1, p2: string) begin C_CmdCD; end`): il vecchio codice lo evitava con il cast `@` e la convenzione di chiamata |
| `C_GetCmd`, `C_CmdExists` | `ICommandRegistry.Find`, `Contains` |
| `C_ExecuteCmd(line)`, `(name, parm)`, `(name, p1, p2)` | `IConsoleInterpreter.Execute` (tre overload, stesso taglio e stesso ripiego `get`/`set`) |
| `C_ExecuteCmd(@cmd, ...)` | `Find(...)` e chiamare il gestore |
| `C_BoolEval` | `TConsoleNumbers.EvaluateBoolean` |
| `atoi` per `set` | `TConsoleNumbers.ParseInteger` |
| `C_GetMachingList` | `TConsoleMaskMatcher.Filter` |
| `C_CmdList` | `TConsoleCommandLister.List` (registrato da `TConsoleStandardCommands`) |
| `C_UnknowCommandMsg` | resta `'Unknown command'#13#10` nell'output di `TConsoleInputLine.Submit` e di `get`/`set` |
| `Cmd_Set`, `Cmd_Get`, `Cmd_TypeOf` (`m_misc`) | `TConsoleVariableCommands` (`GetVariable`, `SetVariable`, `TypeOfVariable`, `Register`) |
| `C_ExecCommandFile` | `IConsoleScriptRunner.RunFile` |
| `C_ExecCommands` | `IConsoleScriptRunner.RunText` |
| `C_RunAutoExec` | `TConsoleAutoExec.Run` |
| `C_AddCommand` + `pendingcommands` + il ciclo di `C_Responder` | `TConsoleCommandQueue.Enqueue` / `ExecutePending` (`Enabled := true` in `C_Init`: e' il vecchio `ConsoleInitialized`) |
| `CommandsHistory`, `PrevCommandHead`, `NextCommand` | `TConsoleHistory` (`Add`, `Previous`, `Next`) |
| `ConsoleInputBuff`, `C_ResetInputBuff`, `C_IsInputBuffEmpty`, il tasto Invio, Backspace, frecce | `TConsoleInputLine` (`Reset`, `IsEmpty`, `AppendChar`, `Backspace`, `HistoryPrevious/Next`, `Submit`, `Complete`; `NeedsUpdate` e' `con_needsupdate`) |
| `cheatseq_t`, `cht_CheckCheat`, `cht_GetParam`, `SCRAMBLE` | `TCheatSequence.Check`, `.Param`, `TCheatScrambler.Scramble`; `cheatstatus_t` = `TCheatStatus` (`csUnknown/csPending/csAcquired`) |
| `get_cheatseq_string(array)` | `TCheatSequenceReader.FromBytes(array of Byte)`; `get_cheatseq_string(0)` sparisce (lo stato iniziale e' `Create`/`Reset`) |
| la catena `else if check_cheat(...)` di `ST_Responder` / `SB_Responder` | `TCheatTable.Add(name, sequence, enabled)` e `Feed(key, out acquired)`: lo `ateit` e' il risultato, il primo cheat completo ferma la catena come il vecchio `else if` |

## 3. Cosa deve fare il motore (composition root)

1. Creare il registro e l'interprete **una volta**, per esempio in `ComposeEngine` (`ComposeConsole`):
   ```
   LRegistry := TConsoleFactory.CreateRegistry;
   LInterpreter := TConsoleFactory.CreateInterpreter(LRegistry);
   ```
   `C_AddCmd`, `C_ExecuteCmd`, `C_GetCmd` restano come facciate sottili sopra questi due oggetti (circa 700 chiamanti:
   non si migrano uno a uno), come per le `W_*`.
2. Adattatori nel motore (nuove unit `Base\DelphiDoom.Engine.Console.*`, una classe per unit):
   - `IConsoleOutput`: `Write` = `printf(AText)` (come per `TEngineLogSink`: la catena `outproc` arriva a `C_AddText`);
   - `IConsoleVariable` + `IConsoleVariableSource`: sopra la tabella `defaults` di `m_defs.pas` (`pd.name`, `_type`,
     `location`, `setable`); `setable` e' `DFS_NEVER=[]`, `DFS_SINGLEPLAYER=[camSinglePlayer]`, `DFS_NETWORK=[camNetwork]`,
     `DFS_ALWAYS=[camSinglePlayer, camNetwork]`; i `tGroup` non vanno esposti; `Find(name)` cerca per nome minuscolo e
     da' il primo trovato come il vecchio ciclo;
   - `IConsoleFileSystem`: `fexpand`, `fexists`, e `ReadLines` con `assign/readln` (o `TStringList.LoadFromFile`);
   - `IConsoleStartupSource`: `autoexecfile`, `fexists(DEFAUTOEXEC)`, `M_SaveFileName` + `SaveToFile`, i lump `AUTOEXEC`
     (`W_TextLumpNum`), `M_CheckParm('-con')` (dare `''` se manca o se e' l'ultimo argomento);
   - `ILog` e `IGameContext` ci sono gia' (`ComposeEngine`).
3. Registrare i comandi: `TConsoleFactory.CreateVariableCommands(...).Register` (al posto delle tre `C_AddCmd` di `m_menu.pas`) e
   `CreateStandardCommands(...).Register` (al posto di `cmdlist`, `exec`, `printf` di `C_Init`). **Questi due oggetti vanno tenuti
   vivi quanto il registro**: i gestori registrati catturano `Self` (liberarli in `C_ShutDown`).
4. `C_Responder`: la riga di input diventa un `TConsoleInputLine` (`CreateInputLine(']', Interpreter, Output, CreateHistory, CreateCompleter(...))`);
   il motore continua a filtrare i caratteri validi (`HU_FONTSTART..HU_FONTEND`, shift) e chiama `AppendChar`; Invio chiama `Submit`;
   su Tab (nuovo, il vecchio non lo gestiva) `Complete`. `C_Drawer` legge `Buffer` e `NeedsUpdate`.
5. Cheat: in `ST_Init` creare un `TCheatTable` per gioco (`Add('god', TCheatSequenceReader.FromBytes(cheat_god_seq), nil)`, per i cheat che
   dipendono dal gioco passare `enabled`) e in `ST_Responder` chiamare `Feed(Ord(ev.data1), acquired)`; il parametro
   si legge con `Find('mus').Param`. Gli array `cheat_*_seq` (byte rimescolati) restano nel motore (sono dati dei giochi).

## 4. Non portato (resta nel motore, con il motivo)

- **Disegno della console** (`C_Drawer`, `C_DrawConsoleBackground`, font, colormap, cursore, scorrimento `C_DoPageUp/Down`, `C_AddLine`,
  `C_RestoreFromBuffer`, buffer di testo `ConsoleText`): dipende da `screens[]`, dai font di `hu_stuff` e dal renderer.
- **Gestione dei tasti** di `C_Responder` (`KEY_CON`, `KEY_ESCAPE`, `KEY_PAGEUP`, shift, `console_paused`, `ev_keydown`): sono eventi del motore;
  la libreria riceve solo i caratteri gia' scelti.
- **Variabili e comandi del gioco** (`defaults` con i puntatori ai globali, tutti i `C_AddCmd(...)` degli altri moduli): restano dove sono.
- **Comandi di `c_utils.pas`** (`dir`, `cd`, `cat`, `gotowebpage` ...): usano file del sistema, `I_GoToWebPage`, il video; restano
  e si registrano con `C_AddCmd`.
- **`C_CmdCloseConsole/OpenConsole/ConsoleColormap/Cls/PauseConsole`**: toccano lo stato grafico della console.
- **Tabelle dei cheat dei giochi** (`cheat_*_seq`) e il codice dei loro effetti (`ST_CmdIDDT`, godmode ...): sono del gioco.
- **Hexen/Heretic**: stessa `m_cheat.pas` (una sola unit per tutti): vale lo stesso collegamento in `sb_bar.pas`.

## 5. Differenze dal vecchio e rischi

Elencate in `Tests\Data\Console\README.md` (limite 300 comandi tolto, nome registrato due volte = vince l'ultimo, coda dei comandi,
tasti oltre 255, completamento TAB nuovo, `Param` senza la tabella dei caratteri del sistema). Rischi:

- i gestori sono closure: un `C_AddCmd` che oggi riceve `@Proc` con un'altra firma (senza parametri, o con uno) va riscritto con un wrapper;
- l'ordine dell'elenco `list` ora e' sempre alfabetico;
- il nome dato a `get`/`set` dal ripiego `nome valore` e' in maiuscolo anche nei nuovi messaggi, come nel vecchio (e' nel golden): non "correggerlo" senza rifare il golden;
- `TConsoleInputLine` libera `TConsoleHistory` e `TConsoleCompleter` che riceve.
