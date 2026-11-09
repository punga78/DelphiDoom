# Libs\ScriptHost

Il **collegamento di Pascal Script al motore** (issue #172, spostato qui da `SCRIPT\`): registra nell'interprete le classi, le funzioni e le variabili del gioco, cioè ciò che gli script ACTORDEF/DECORATE possono vedere e chiamare.

| Unit | Ruolo |
|---|---|
| `ps_import` | `TDoomCompiler` e `TDoomExec`: compilatore e interprete con le classi del gioco registrate |
| `ps_main` | avvio, ciclo di compilazione/esecuzione degli script del gioco |
| `ps_events` | eventi del gioco chiamati negli script |
| `ps_serializer` | salvataggio e caricamento dello stato degli script |
| `ps_proclist` | elenco delle funzioni host e delle dichiarazioni |
| `ps_dll` | DLL contenute in un PAK, copiate su file prima di `LoadLibrary` |
| `psi_game`, `psi_overlay`, `psi_map`, `psi_globals`, `psi_system` | le circa 1.600 funzioni `PS_*` che gli script chiamano (giocatori, mobj, overlay, mappa, sistema) |

## Registro delle funzioni (issue #173, fetta 2a)

Le funzioni che gli script chiamano stanno in un **registro a gruppi** (schema di `Libs\`: interfaccia, classi, factory):

| Unit | Ruolo |
|---|---|
| `DelphiDoom.ScriptHost.Intf` | `IScriptFunctionTable` (dove un gruppo scrive le sue funzioni), `IScriptFunctionGroup` (una unit di script: nome e `Describe`), `IScriptFunctionRegistry` (`AddGroup`, `RemoveGroup`, `Contains`, `UnitNames`, `CompilerUnitNames`, `Declarations`, `Reset`, `RegisterCompiler`, `RegisterExecutor`, `RegisterExecutorForAll`) |
| `DelphiDoom.ScriptHost.Types` | `EScriptHostException`, `TScriptFunctionEntry`, nomi `SYSTEM`/`ALL` |
| `DelphiDoom.ScriptHost.FunctionList` | `TScriptFunctionList`: le funzioni di una unit, le stesse regole di `TProcedureList` (punto e virgola, nome calcolato dal compilatore, flag "computed" e `Reset`) senza memoria a mano |
| `DelphiDoom.ScriptHost.Registry` | `TScriptFunctionRegistry`: le unit in ordine alfabetico (`TStringList` ordinata, maiuscole indifferenti); una unit si registra una volta |
| `DelphiDoom.ScriptHost.CallbackGroup` | `TScriptCallbackGroup`: un gruppo le cui funzioni le scrive una procedura (PS_GAME e PS_OVERLAY, in `ps_import`, finché non sono classi) |
| `DelphiDoom.ScriptHost.System.Intf` | `IScriptSystemOutput`, `IScriptSystemEnvironment`, `IScriptSystemConsole` (cosa chiede SYSTEM all'applicazione) e `IScriptSystemFunctions` (i corpi, a cui i `PS_*` di `psi_system` inoltrano) |
| `DelphiDoom.ScriptHost.System.Functions` | `TScriptSystemFunctions`: la unit `SYSTEM` (56 funzioni): le dichiarazioni (`SCRIPT_SYSTEM_DECLARATIONS`, verbatim e nello stesso ordine), un enum con una voce per funzione (`TScriptSystemRoutine`) e i corpi di quelle che non hanno bisogno del motore |
| `DelphiDoom.ScriptHost.Fixed.Functions` | `TScriptFixedFunctions`: la unit `PS_FIXED` (9 funzioni, senza corpo: gli script chiamano `m_fixed`) |
| `DelphiDoom.ScriptHost.Factory` | `TScriptHostFactory`: l'unico punto che conosce le classi |

**Collegamento al motore**: `ComposeScriptHost` (in `ComposeEngine`, dopo `ComposeScanner`) crea il registro con i gruppi `SYSTEM` (con `TEngineScriptOutput`, `TEngineScriptEnvironment`, `TEngineScriptConsole` e l'`IGameRandom` di `ComposeMathCore`) e `PS_FIXED`, e lo dà a `PS_ConfigureScriptRegistry` di `ps_import`; `PS_InitProcLists` (chiamata da `PS_Init` e da `DD_InitDoomEngine`) aggiunge `PS_GAME` e `PS_OVERLAY` come gruppi a procedura; `PS_ScriptOnUses`, `TDoomExec.LoadData` e `PS_ResetProcLists` chiedono al registro; `dd_compiler` legge nomi e dichiarazioni dal registro. Senza `ComposeEngine` il registro dà `I_Error`. Le routine che l'interprete chiama sono le stesse di prima: i **`PS_*` di `psi_system` restano come thunk** (strada A del piano: stessa convenzione di chiamata, nessun cambio per le dichiarazioni) e inoltrano a `TScriptSystemFunctions` tramite `PS_ConfigureSystem`; `Base\DelphiDoom.Engine.Script.Routines` (`TEngineScriptRoutines`) dà il puntatore di ogni routine (i thunk di `psi_system`, le `PS_*` di `psi_globals`, `P_Random`, i controlli di intervallo, `m_fixed`) alle due classi. Nel motore: `Base\DelphiDoom.Engine.Script.Output` (`printf`, il file di debug, il formato con avviso), `.Environment` (`leveltime` e le tabelle degli angoli) e `.Console` (`IEngineConsole`, `IEngineDefaults` e la tabella `defaults`).

**Verifica** (la rete di sicurezza è in `Tools\Verifica\scripthost\`, vedi `LEGGIMI.md`): i golden della registrazione di `Tests\Data\ScriptHost\<Gioco>.registration.golden.txt`, fatti dal codice di `919a19ef`, sono **identici** per i quattro giochi con il codice nuovo (dichiarazioni verbatim di ogni unit, funzioni registrate con parametri, tipi, membri delle classi, costanti e variabili); test in `Tests\DelphiDoom.Tests.ScriptHost` (67, copertura 95%: registro e funzioni con finti, compilatore e interprete di Pascal Script veri per `uses` e `uses all`, dichiarazioni di `SYSTEM` e `PS_FIXED` uguali al golden).

**Differenze dal vecchio**: `ps_proclist.pas` e `PS_ImportUnits` non esistono più; una unit registrata due volte è `EScriptHostException` (la vecchia lista non lo controllava); `PS_ConfigureConsole` e `PS_ConfigureDefaults` di `psi_system` sono state tolte (le riceve `TEngineScriptConsole`). `PS_Format` e le funzioni di `Get/SetConsole*` non sono cambiate nei risultati; `BreakPoint` ricorda l'ultimo messaggio nell'oggetto invece che in una variabile della unit.

**Non provato a runtime** (nessun gioco è stato avviato): gli otto eseguibili con uno script che chiama le funzioni di `SYSTEM`, la batteria L2 e i salvataggi (le esecuzioni e i confronti sono a cura di chi avvia i giochi, comandi in `Tools\Verifica\scripthost\LEGGIMI.md`).

## Cosa resta

La **fetta 2b e le seguenti** (`docs\SCRIPTHOST_PIANO.md`, sezione 5): variabili (`psi_globals`), eventi e serializzatore, speciali di settore, `ps_dll`, e per ultime `psi_game` (attori, linee, settori...), `ps_import`/`ps_main` e l'overlay. La spike di `RegisterDelphiMethod` (`Tools\Verifica\scripthost\spike`) passa a 32 e 64 bit: le fette seguenti possono togliere i thunk. Il nucleo dell'interprete sta in `Libs\PascalScript`; il compilatore da riga di comando in `Libs\Ddc`.