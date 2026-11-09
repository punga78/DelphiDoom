# Libs\ScriptHost

> Note per Claude e paragrafi di dettaglio (issue #178): [CLAUDE.md](CLAUDE.md).

Il **collegamento di Pascal Script al motore** (issue #172, spostato qui da `SCRIPT\`): registra nell'interprete le classi, le funzioni e le variabili del gioco, cioè ciò che gli script ACTORDEF/DECORATE possono vedere e chiamare.

| Unit | Ruolo |
|---|---|
| `ps_import` | `TDoomCompiler` e `TDoomExec`: compilatore e interprete con le classi del gioco registrate |
| `ps_main` | avvio, ciclo di compilazione/esecuzione degli script del gioco |
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

## Variabili, eventi e serializzatore (issue #174, fette 2b e 2c)

| Unit | Ruolo |
|---|---|
| `DelphiDoom.ScriptHost.Variables.Intf` | `IScriptVariables` (variabili di mappa o di mondo: stringhe, interi e float per nome, senza distinguere le maiuscole; `Load/SaveToBuffer`, `StructureSize`, `Load/SaveToFile`), `IScriptVariablesFiles` (file interi), `IScriptVariablesFailure` (dove va un errore: nel motore `I_Error`) |
| `DelphiDoom.ScriptHost.Variables.Types` | `EScriptVariablesException`, i tre valori (`TScriptStringValue`, `TScriptIntegerValue`, `TScriptFloatValue`), costanti della tabella hash |
| `DelphiDoom.ScriptHost.Variables.HashTable` / `.HashList` | `TScriptHashTable` (8192 catene, le ultime 5 posizioni trovate provate per prime; il vecchio `THashTable`) e `TScriptHashStringList` (il vecchio `THashStringList`) |
| `DelphiDoom.ScriptHost.Variables` | `TScriptVariables` (il vecchio `TGlobalVariablesList`); formato su buffer e su file **invariato**: interi e float di 4 byte, stringhe con la lunghezza e 2 byte (UTF-16) per carattere, ordine stringhe, interi, float |
| `DelphiDoom.ScriptHost.Events.Table` / `.Intf` / `.Events` | `SCRIPT_EVENT_SIGNATURES` (nome, parametri e modello dell'editor dei 10 eventi), `IScriptEvents` e `TScriptEvents` (riceve un `TPSExec` e un `ILog`) |
| `DelphiDoom.ScriptHost.Serializer.Intf` / `.Serializer` | `IScriptSerializer` e `TScriptSerializer` (stato delle variabili globali di uno script: file, flusso, `SaveSize`), `SCRIPT_SERIALIZABLE_TYPES` |

`TScriptHostFactory` crea le tre cose (`CreateVariables`, `CreateEvents`, `CreateSerializer`). **Collegamento**: `PS_ConfigureVariables` (`psi_globals`, chiamata da `ComposePlatform` con `TEngineScriptVariablesFiles` e `TEngineScriptVariablesFailure` di `Base\`) e `PS_ConfigureStateServices` (`ps_main`, chiamata da `ComposeScriptHost` con l'`ILog`); senza di esse `I_Error`. `psi_globals` resta la facciata: `mapvars`/`worldvars` (`IScriptVariables`), `TGlobalVariablesList` (alias dell'interfaccia), le `PS_Get/SetMap/World*` e le sei classi `TMapStrings`...`TWorldFloats` che Pascal Script importa. **Verifica**: golden L1 invariati nei 4 giochi; `Tests\DelphiDoom.Tests.ScriptHost` ha 134 test (copertura 95% di `Libs\ScriptHost`; le unit nuove 91-100%): byte del salvataggio scritti a mano, `StructureSize` uguale ai byte scritti, nomi non ASCII e lunghi, buffer e file malformati, hash (valori dei vecchi `Hash`), eventi e serializzatore sul compilatore e sull'interprete veri. Non provato a runtime: L2 e un salvataggio con variabili degli script (`Tools\Verifica\scripthost\LEGGIMI.md`).

La **fetta 2d e le seguenti** (`docs\SCRIPTHOST_PIANO.md`, sezione 5): speciali di settore, `ps_dll`, e per ultime `psi_game` (attori, linee, settori...), `ps_import`/`ps_main` e l'overlay. La spike di `RegisterDelphiMethod` (`Tools\Verifica\scripthost\spike`) passa a 32 e 64 bit: le fette seguenti possono togliere i thunk. Il nucleo dell'interprete sta in `Libs\PascalScript`; il compilatore da riga di comando in `Libs\Ddc`.

## Speciali di settore e DLL dei PAK (issue #172, fette 2d e 2e)

**2d: le 77 funzioni di `psi_map`** (`Door_*`, `Ceiling_*`, `Floor_*`, `FloorAndCeiling_*`, `Light_*`, `Plat_*`, `Pillar_*`, `Polyobj_*`) restano nella unit di script `PS_GAME` (stesse dichiarazioni, stesso ordine: L1 identico) ma i corpi sono sette classi piccole che costruiscono gli 8 byte di argomenti e chiedono a **un solo gateway**:

| Unit | Ruolo |
|---|---|
| `DelphiDoom.ScriptHost.SectorSpecials.Types` | `TScriptSpecialArguments` (8 byte) e i generi delle special per nome (`TScriptCeilingKind`, `TScriptDoorKind`, `TScriptFloorKind`, `TScriptLightKind`, `TScriptPlatKind`, `TScriptPolyDoorKind`): il motore li traduce nelle sue costanti `CLEV_*`, `DREV_*`, `FLEV_*`, `LITE_*`, `PLAT_*`, `PODOOR_*` |
| `DelphiDoom.ScriptHost.SectorSpecials.Intf` | `IScriptSectorSpecials`: `DoCeiling`, `DoDoor`, `DoFloor`, `DoFloorAndCeiling`, `SpawnLight`, `DoPlat`, `BuildPillar`, `OpenPillar`, `OpenPolyDoor`, `MovePoly`, `RotatePoly`, `StartFloorWaggle`, `ForceLightning`, `...CrushStop`; gli argomenti sono `var` (come il buffer locale del vecchio codice: `FloorAndCeiling_LowerRaise` lo passa a due special di seguito) |
| `DelphiDoom.ScriptHost.SectorSpecials.Base` | `TScriptSectorSpecialsBase`: gateway dal costruttore (`EArgumentNilException`), `SetByte` e `SetSmallInt` (il valore che non sta nel byte si taglia ai bit bassi, come `args[0] := tag`) |
| `...SectorSpecials.Doors` / `.Ceilings` / `.Floors` / `.Lights` / `.Plats` / `.Pillars` / `.Polyobjects` | 4, 15, 25 (22 `Floor_*` e 3 `FloorAndCeiling_*`), 12, 8, 3 e 10 funzioni |
| `...SectorSpecials.Functions.Intf` / `.Functions` | `IScriptSectorSpecialFunctions` / `TScriptSectorSpecialFunctions`: possiede le sette classi |

Nel motore `Base\DelphiDoom.Engine.Script.SectorSpecials.pas` (`TEngineScriptSectorSpecials`) è l'unica classe che chiama `EVH_*`, `P_ForceLightning` e i polyobj (con l'`{$IFDEF HEXEN}` di prima per `p_anim`/`udmf_spec`); `ComposeScriptHost` la da a `PS_ConfigureSectorSpecials` (`psi_map`, senza di essa `I_Error`). **Strada A**: le 77 `PS_*` di `psi_map` sono thunk di una riga.

**2e: `ps_dll`** (DLL dentro un PK3: copiata in un file temporaneo e caricata da li) è `TScriptDllLoader` (`DelphiDoom.ScriptHost.Dll.Intf` / `.Loader` / `.WindowsLibrary`): `IScriptDllSource` (`KeyOf`, `Extract`: nel motore `TEngineScriptDllSource` sopra `IPakFileSystem` e `ITempFiles`), `IScriptDllLibrary` (`Load`/`Unload`: `TScriptDllWindowsLibrary` = `LoadLibrary`/`FreeLibrary`), `IScriptDllLoader` (`Load` conta gli usi, `Unload` scarica all'ultimo, `Shutdown`). `ps_dll.pas` è la facciata (`PS_PAKLoadDll`, `PS_PAKUnLoadDll`, `PS_ShutDownDLLLoader`; `PS_ConfigureDllLoader` da `ComposeScriptHost`); `PS_InitDLLLoader` non esiste piu. `PS_PAKLoadDll` ora dà un `NativeUInt` (era `LongWord`: sbagliato a 64 bit; `mdl_dllmodel` aggiornato).