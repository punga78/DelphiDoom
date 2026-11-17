# IdTech4\D3Host — note per Claude

`IdTech4\D3Host` (issue #255, fase 1 di `docs\DOOM3_CENSIMENTO.md`) e' il lato "motore" di Doom 3 che non dipende ne' dalla sessione, ne' dal renderer, ne' dal gioco: le parti di `idCommon` che stampano, tengono gli avvisi, classificano gli errori e leggono la riga di comando, piu' `idEventLoop`. **Non ha chiamanti nel motore** (nessun eseguibile `Doom3` ancora). Port di `Reference\doom3\neo\framework\Common.cpp` (le funzioni elencate sotto) e `EventLoop.cpp/.h`. Licenza: **GPL v3 o successiva con gli "Additional Terms" di `Reference\doom3\COPYING.txt`** (decisione dell'utente del 2026-11-17), dichiarata nell'intestazione di ogni unit; il motore di Doom resta GPL v2 o successiva.

## Classi (una per unit, `DelphiDoom.D3Host.*`)

| C++ | Pascal |
|---|---|
| `VPrintf`, `Printf`, `DPrintf`, `BeginRedirect`, `EndRedirect`, `CloseLogFile`, `SetRefreshOnPrint` | `TD3Printer` (`Printer`) |
| `Warning`, `DWarning`, `PrintWarnings`, `ClearWarnings`, `DumpWarnings`, `errorList` | `TD3Diagnostics` (`Diagnostics`) |
| `Error`, `FatalError` | `TD3ErrorHandler` (`ErrorHandler`) |
| `ParseCommandLine`, `ClearCommandLine`, `SafeMode`, `CheckToolMode`, `StartupVariable`, `AddStartupCommands` | `TD3CommandLine` (`CommandLine`) |
| `idEventLoop` (`GetRealEvent`, `PushEvent`, `GetEvent`, `ProcessEvent`, `RunEventLoop`, `Init`, `Shutdown`, `Milliseconds`, `JournalLevel`) | `TD3EventLoop` (`EventLoop`) |
| `com_errorEntered`, `com_refreshOnPrint`, `com_editors` | `TD3CommonState` (`Types`) |
| `sysEvent_t`, `ERP_*`, `EDITOR_*`, `MAX_*` | `TD3SysEvent`, costanti (`Types`) |
| il gruppo delle parti sopra | `TD3CommonHost` (`Common`), assemblato da `TD3HostFactory.CreateCommon(TD3HostServices)` (`Factory`) |

Contratti (`Intf`): `ID3CommonCVars`, `ID3CommonSettings`, `ID3CommonSystem` (le `Sys_*`), `ID3CommonConsole`, `ID3CommonSession`, `ID3CommonRenderState`, `ID3CommonFileSystem`/`ID3CommonFile`, `ID3CommonCalendar`, `ID3CommonLifecycle` (`Shutdown`), `ID3FatalErrorSink`, `ID3Printer`, `ID3StartupVariables`, `ID3KeyTracker`, `ID3EventSource`, `ID3JournalSettings`. Il buffer dei comandi e' `ICmdBuffer` di `Framework\Console` (profilo id Tech 4), i token sono `TIdCmdArgs` e `TIdStr` di `Framework\IdLib`. Nessun globale.

## Decisioni

- **Testo gia' formattato**: i `fmt` e i varargs del C++ non si portano; i chiamanti passano un `AnsiString` senza NUL. `Limit` (`TD3MessageText`) taglia a 4095 come `idStr::vsnPrintf` in un buffer da 4096; `Printf` taglia come `VPrintf` (4094 meno il prefisso del tempo, poi `\n`, e dice "truncated" a `Sys_Printf`).
- **Senza renderer ogni `Error` e' fatale**: `renderSystem->IsOpenGLRunning()` e' `ID3CommonRenderState`; un programma senza finestra deve dichiarare cosa vuole (se vuole le cadute `ERP_DROP` il suo stato risponde vero). La parita' prova entrambi i rami (`errors.scn` con renderer, `errors_nogl.scn` senza).
- **`Sys_Quit` e `Sys_Error` non tornano** nel motore: nei test il finto solleva `ETestExit`; il codice dopo la chiamata e' quello del C++ (che non viene eseguito).
- **Proprieta'**: `TD3CommonHost` possiede tutto; stampante, gestore degli errori e riga di comando sono contati (interfacce) e il gestore degli errori e' un `[weak]` nella stampante (il ciclo stampante - errori e' chiuso da `SetFatalErrorSink`). Non usare le parti dopo aver liberato il `TD3CommonHost`.
- **Diario**: un evento occupa 20 byte (4 interi + 4 byte del puntatore, scritti a 0: il C++ scrive il puntatore vero, 4 byte solo a 32 bit); un diario del C++ a 32 bit si rilegge, ma il contrario non e' provato.
- **`std::sort`/`qsort`**: la lista degli avvisi usa `idStr::Icmp`; i duplicati che differiscono solo per le maiuscole possono uscire in qualunque ordine (anche il `qsort` del C++ non e' stabile): non ci sono nei golden.

## Difetti del C++ conservati

- `idEventLoop::Init` dice "Couldn't open journal files" **anche quando non si e' chiesto il diario** (com_journal 0: i due file sono nulli): `events_journal_missing.scn`.
- `common->StartupVariable( "journal", false )` imposta una cvar `journal`, ma la cvar dell'event loop si chiama `com_journal`: la riga di comando `+set journal 1` non attiva il diario. Il composition root deve dare a `ID3StartupVariables`/`ID3JournalSettings` la stessa cvar se lo vuole.
- `ParseCommandLine` non azzera gli slot (un secondo `ParseCommandLine` aggiunge ai vecchi) e con piu' di 32 righe scrive fuori dall'array: qui `ED3HostException`.
- `VPrintf` salta tutto se `cvarSystem` non e' inizializzato (la stampa si perde); `DWarning` no.

## Parita' col C++ (Win32 e Win64)

`Tools\Verifica\255\Build-Harness.ps1` costruisce con `bcc32c` (nella cartella temporanea, mai nel repository): il vero **`EventLoop.cpp`**, il vero idlib e i **corpi veri** delle funzioni di `Common.cpp` **tagliati dal sorgente al momento della costruzione** (`BeginRedirect` ... `AddStartupCommands`; due blocchi `#ifdef _WIN32` tolti: il messaggio di finestra per gli editor e Notepad; `asctime` e' fisso). `Common.cpp` intero non si compila: tira dentro il motore. I finti del motore (`precompiled.h`, `harness.cpp`) scrivono ogni chiamata; 18 scenari in `Tests\Data\D3Host\scenarios` danno `Tests\Data\D3Host\golden` (3181 righe: stampa, troncamento, avvisi con il tetto di 256, errori con renderer / senza / `fs_copyfiles` / ricorsione / tempesta / editor, file di log, riga di comando, modo strumenti, eventi, eventi inseriti, diario). Il test `TTestD3HostParity` rifa gli stessi scenari sulle classi Delphi (`DelphiDoom.Tests.D3Host.Scenario` interpreta gli stessi comandi sul `TD3FakeWorld`) e confronta riga per riga. **Senza risposta del C++** (dichiarato): `Quit`, `Init`, `Frame`, `Async`, `InitGame`, la localizzazione, `WriteConfigToFile`, `InitTool` (non portati); il formato del diario con un puntatore a 64 bit.

Test: `Tests\DelphiDoom.Tests.D3Host` (27 test: 18 scenari di parita' e 9 sulle classi), `Tools\build.bat Tests\DelphiDoom.Tests.D3Host Release both`.

## Cosa resta (vedi il censimento)

`Init`/`Shutdown`/`Frame`/`Async`/`GUIFrame`/`InitGame` di `idCommonLocal` (fase 2b), `idKeyInput`, `idEditField`, `idUsercmdGen`, `idConsole` (fase 2a), `idSessionLocal` (2c), il programma `Doom3` che dia le interfacce di `Intf` (adattatori su `Framework\Console`, `Framework\Wad`, `Framework\Clock`) nel composition root (fase 3).
