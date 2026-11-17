# IdTech4\D3Host — note per Claude

`IdTech4\D3Host` (issue #255, fase 1 di `docs\DOOM3_CENSIMENTO.md`) e' il lato "motore" di Doom 3 che non dipende ne' dalla sessione, ne' dal renderer, ne' dal gioco: le parti di `idCommon` che stampano, tengono gli avvisi, classificano gli errori e leggono la riga di comando, `idEventLoop` (fase 1) e, dalla fase 2a-2c, tasti, campo di testo, usercmd, console e ciclo di vita (sezione sotto). **Non ha chiamanti nel motore** (nessun eseguibile `Doom3` ancora). Port di `Reference\doom3\neo\framework\Common.cpp` (le funzioni elencate sotto) e `EventLoop.cpp/.h`. Licenza: **GPL v3 o successiva con gli "Additional Terms" di `Reference\doom3\COPYING.txt`** (decisione dell'utente del 2026-11-17), dichiarata nell'intestazione di ogni unit; il motore di Doom resta GPL v2 o successiva.

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

`Tools\Verifica\255\Build-Harness.ps1` costruisce con `bcc32c` (nella cartella temporanea, mai nel repository): il vero **`EventLoop.cpp`**, il vero idlib e i **corpi veri** delle funzioni di `Common.cpp` **tagliati dal sorgente al momento della costruzione** (`BeginRedirect` ... `AddStartupCommands`; due blocchi `#ifdef _WIN32` tolti: il messaggio di finestra per gli editor e Notepad; `asctime` e' fisso). `Common.cpp` intero non si compila: tira dentro il motore. I finti del motore (`precompiled.h`, `harness.cpp`) scrivono ogni chiamata; 18 scenari in `Tests\Data\D3Host\scenarios` danno `Tests\Data\D3Host\golden` (3181 righe: stampa, troncamento, avvisi con il tetto di 256, errori con renderer / senza / `fs_copyfiles` / ricorsione / tempesta / editor, file di log, riga di comando, modo strumenti, eventi, eventi inseriti, diario). Il test `TTestD3HostParity` rifa gli stessi scenari sulle classi Delphi (`DelphiDoom.Tests.D3Host.Scenario` interpreta gli stessi comandi sul `TD3FakeWorld`) e confronta riga per riga. **Senza risposta del C++** (dichiarato): la localizzazione, `WriteConfigToFile`, `InitTool` (non portati; `Quit`, `Init`, `Frame`, `Async` e `InitGame` hanno ora il secondo harness, sotto); il formato del diario con un puntatore a 64 bit.

Test: `Tests\DelphiDoom.Tests.D3Host` (27 test: 18 scenari di parita' e 9 sulle classi), `Tools\build.bat Tests\DelphiDoom.Tests.D3Host Release both`.

## Fasi 2a-2c e 5c (ondata 10, 2026-11-17)

Unit nuove (una classe per unit, licenza GPL v3 o successiva con gli Additional Terms, tranne `Session`, `Session.Intf` e i test: GPL v2 o successiva, scritte da zero):

| C++ | Pascal |
|---|---|
| `keyNum_t`, `usercmd_t`, `usercmdButton_t`, `userCmdStrings[]`, `keynames[]` | `Input.Types` (costanti `K_*`, `UB_*`, `TD3Usercmd`, le tabelle) |
| `StringToKeyNum`, `KeyNumToString`, `ArgCompletion_KeyName` | `TD3KeyNames` (`KeyNames`) |
| `idKeyInput` (stati dei tasti, `bind`, `unbind`, `unbindall`, `bindunbindtwo`, `listBinds`, `WriteBindings`, `KeysFromBinding`, anello dei trucchi) | `TD3KeyInput` (`KeyInput`) |
| `idEditField` (senza `Draw`) | `TD3EditField` (`EditField`; `Assign` copia tutto, anche il completamento) |
| `idUsercmdGenLocal` (senza `Sys_Poll*`: dispositivi dietro `ID3InputDevices`) | `TD3UsercmdGen` (`UsercmdGen`) |
| `idConsoleLocal` (senza `Draw*`, `LoadGraphics`, `SCR_Draw*`) | `TD3Console` (`Console`) |
| `idCommonLocal::Init`, `Shutdown`, `InitGame`, `ShutdownGame`, `Frame`, `GUIFrame`, `SingleAsyncTic`, `Async`, `Quit` | `TD3Lifecycle` (`Lifecycle`, contratti in `Lifecycle.Intf`) |
| `idSessionLocal` | **non portata**: `TD3Session` (`Session`, `Session.Intf`) e' una sessione minima scritta da zero (nessuna mappa o una mappa in corso, `Map`/`Stop`, un fotogramma di gioco per ogni `Frame`) |

Contratti: `Input.Intf` (`ID3KeyStates`, `ID3KeyBindingExecutor`, `ID3UsercmdActions`, `ID3UsercmdControl`, `ID3KeyText`, `ID3CVarServices`, `ID3CVarValues`, `ID3Clipboard`, `ID3InputDevices`, `ID3AsyncState`, `ID3DebugOutput`, `ID3UsercmdGenerator`, `ID3ConsolePlatform`, `ID3EventClock`, `ID3ScreenUpdater`), `Lifecycle.Intf` (`ID3Subsystem`, `ID3ConsoleControl`, `ID3SessionLifecycle`, `ID3SoundSystem`, `ID3AsyncNetwork`, `ID3FileSystemSetup`, `ID3EventLoopControl`, `ID3SystemLifecycle`, `ID3CommandLineControl`, `ID3WarningControl`, `ID3LogFileControl`, `ID3StartupSteps`, `ID3FrameSteps`), `Intf` (nuovi `ID3ErrorReporter`, `ID3WarningSink`). Comandi e completamento passano da `ICmdCommands`/`ICmdBuffer` di `Framework\Console`; `TD3CommonState` ha ora `TicNumber`, `FrameTime`, `FrameNumber` e i tempi di `com_speeds`. `TD3Printer`, `TD3CommandLine` implementano anche `ID3LogFileControl` e `ID3CommandLineControl`; `TD3KeyInput` e `TD3Console` implementano `ID3Subsystem` e `ID3ConsoleControl`.

Decisioni:

- **Il ciclo di vita parla solo per interfacce**: i sistemi che il C++ chiama come globali (`cmdSystem->Init`, `soundSystem`, `declManager`, `renderSystem`...) sono `ID3Subsystem` o interfacce piccole nel record `TD3LifecycleServices`; i passi che non si portano (`InitSIMD`, `InitCommands`, `InitRenderSystem`, `LoadGameDLL`, `SetMachineSpec`, `PrintLoadingMessage`, `WriteConfiguration`) sono `ID3StartupSteps`/`ID3FrameSteps`. Il programma Doom3 dovra' dare adattatori (per esempio da `TD3Diagnostics` e `TD3EventLoop`, che non sono contati, a `ID3WarningControl` e `ID3EventLoopControl`): non scritti.
- **Cicli di proprieta'**: `TD3KeyInput` tiene lo usercmd con `[weak]` (`SetUsercmd`); l'ordine di costruzione e' tasti, usercmd, `SetUsercmd`. Il `TD3Lifecycle` implementa `ID3CommonLifecycle` (per `TD3ErrorHandler`): la fabbrica che lo collega non c'e' ancora (il test li compone a mano).
- **Statici del C++ diventati campi**: storia del mouse e contatore (`MouseMove`), `lastTicMsec`, `com_asyncStats`, anello dei trucchi, modo overstrike (sopravvivono a `Shutdown`/`Init` dei tasti).
- **`char` con segno**: il compilatore dell'originale (bcc32c) lo ha con segno; sono conservati con `ShortInt(Byte(...))` il confine di parola della stampa della console, il taglio dei blank finali di `Dump` (un `é` finale sparisce; il salto delle righe vuote invece guarda `& 0xFF`) e `Paste` (un byte alto arriva negativo, `< 32`, e viene scartato). Il confronto `text[...] <= ' '` della console e' sulla cella intera (colore compreso): dopo qualsiasi testo colorato non e' mai vero.
- **Angoli**: `ANGLE2SHORT` e' `Round` (pari) del `Double` portato a `Single`; a Win32 e Win64 i 15 scenari sono uguali al C++ (x87) senza tolleranze.
- **`GetUserCommandName` sull'ultimo indice** (il terminatore della tabella) da' `NULL` nel C++: qui stringa vuota (il pilota stampa la stessa cosa). `BindingFromKey` ha un `out AFound` dove il C++ da' `NULL`. Il `Shutdown` non chiama `DumpWarnings` (e' sotto `#ifdef DEBUG`).
- `LoadGraphics` e tutti i `Draw*` della console e `idEditField::Draw` non sono portati (renderer).

Difetti del C++ conservati: `Print` della console lascia `y` della riga a inizio ciclo anche dopo un `Linefeed` dentro il ciclo del tab; la console non azzera il testo in `Init` (solo `Clear`); `idKeyInput::Key` per `UB_IMPULSE62` e `63` non imposta l'impulso; `MouseMove` non azzera `strafeMx` dopo un delta enorme; `GetUserCommandName( NUM_USER_COMMANDS - 1 )` e' `NULL`.

## Parita' col C++ del secondo harness (Win32 e Win64)

`Tools\Verifica\255\Build-Harness-Host.ps1` (dopo `Build-Harness.ps1` con lo stesso `-Work`, che compila idlib): compila con `bcc32c` il **vero** `KeyInput.cpp`, il vero `EditField.cpp` senza `Draw`, il vero `UsercmdGen.cpp` e i **corpi veri** (tagliati dal sorgente al momento della costruzione) di `Console.cpp` (tutto cio' che non disegna) e di `Common.cpp` (`Init`...`Quit`), con `precompiled_host.h`, `host_common_local.h` e `harness_host.cpp` (finti che scrivono ogni chiamata; la testata del driver elenca i comandi). 15 scenari in `Tests\Data\D3Host\scenarios_host` danno `golden_host` (3648 righe): nomi dei tasti, associazioni, stati e trucchi, modifica e completamento del campo, usercmd da tastiera/mouse/vari (angoli non nulli, smoothing, strafe, run/crouch/zoom a scatto, impulsi, buffer di 64), console (stampa, eventi, storia, scroll, dump, frazione), avvio, fotogramma (con `fail <punto>` per i rami di eccezione), chiusura. `TTestD3HostHostParity` rifa gli stessi scenari con `THostScenarioRunner` (`Tests\Source\DelphiDoom.Tests.D3Host.HostScenario`, finti in `HostWorld`) e confronta riga per riga: **zero differenze, nessuna tolleranza**. Trappole dell'harness (bcc32c): un'eccezione C++ che non e' `idException` che attraversa una funzione con `try` (`Frame`) manda in crash il processo: le chiamate che non tornano (`Sys_Quit`, `Sys_Error`, `FatalError`) escono con `longjmp` da una funzione senza `try`; un inline degli oggetti di idlib (`OpenExplicitFileRead`) o una funzione di `Heap.cpp` (`Mem_EnableLeakTest`) con lo stesso nome del finto vince sul finto al collegamento: `#define` che li rinominano. **Senza risposta del C++** (dichiarato): `Draw*`, `LoadGraphics`, tutto `idSessionLocal`, la sessione minima, `InitSIMD`, `InitCommands`, `WriteConfiguration` (finti tracciati) e `UsercmdInterrupt` con piu' thread.

## Prova senza dati (fase 5c)

`Tests\Source\DelphiDoom.Tests.D3Host.Proof.pas` (2 test): una mappa `.map` generata nel test (3 entita'), le dichiarazioni `entityDef` in memoria (`TDeclMemorySource`, cartella `def` registrata come fa il gioco), uno script `void main()` con `sys.wait` e chiamate a eventi di entita' (`TDoomScriptTestRig`): il comando `Map` di `TD3Session` carica tutto e avvia `main`; il ciclo (`Async` + `Frame`) fa girare i fotogrammi dello script, `main` finisce dopo l'attesa. **Nessun golden del C++**: i pezzi hanno la loro parita' (MapFile, Decl, DoomScript, questo harness) e qui si prova che lavorano insieme; con i dati veri (`pak000.pk4`) solo l'utente puo' provare. Il progetto di test ha ora nel percorso delle unit `DoomScript`, `MapFile`, `Decl`, `Collision`, `Scanner`, `Geometry`, `Imaging`, `Logging`, `Wad`.

Test: `Tests\DelphiDoom.Tests.D3Host` (44: 18 + 15 scenari di parita', 9 sulle classi, 2 della prova), `Tools\build.bat Tests\DelphiDoom.Tests.D3Host Release both`.

## Cosa resta (vedi il censimento)

Il programma `Doom3` (fase 3): composition root che costruisca `TD3LifecycleServices` con adattatori su `Framework\Console` (`TIdTech4Console`: cmd e cvar), `Framework\Wad` (file system, `ID3FileSystemSetup`), `IdTech4\Decl`, `Framework\Clock`, il registro dei tasti da `ID3InputDevices` e un adattatore per `TD3Diagnostics`/`TD3EventLoop`; registrare i cvar di `D3_USERCMD_CVARS`, `con_speed`, `com_*` e `net_serverDedicated`; `idSessionLocal` vera (menu, `MapLoad`, `ExecuteMapChange`, salvataggi, demo), `idAsyncNetwork`, il suono, il renderer e il gioco (fase 4: entita', fisica, giocatore, IA) con gli eventi di mondo di `idThread` (5a, 5b). Senza il gioco un eseguibile parte, esegue `Init` e un ciclo di fotogrammi senza entita'.