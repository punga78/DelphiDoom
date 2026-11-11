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
## Partita, texture e tastiera di PS_GAME (issue #172, fetta 2f-1)

| Unit | Ruolo |
|---|---|
| `DelphiDoom.ScriptHost.Intf` | `IScriptFunctionSection` (una parte delle funzioni di una unit: `Describe`) e `IScriptFunctionTable.AddMethod` (funzione che e' un metodo di un oggetto: l'interprete la chiama con quell'oggetto come `Self`, `RegisterDelphiMethod`) |
| `DelphiDoom.ScriptHost.Types` | `TScriptGame` (Doom, Heretic, Hexen, Strife), `TScriptKey` (le azioni della tastiera) |
| `DelphiDoom.ScriptHost.Games` | `TScriptGames.TryFromName` |
| `DelphiDoom.ScriptHost.Game.Intf` | `IScriptGameInfoSource`, `IScriptTextureSource`, `IScriptKeyboardSource` (cosa chiedono al motore) |
| `DelphiDoom.ScriptHost.Game.Info` | `TScriptGameInfo`: `_GAME`, `GlobalEarthQuake`, `LocalEarthQuake`, `GameSkill`, `GameMap`, `GameEpisode` (solo Doom e Heretic) |
| `DelphiDoom.ScriptHost.Game.Textures` | `TScriptTextures`: `GetTextureWidth`, `GetTextureHeight`, `IsValidTexture` |
| `DelphiDoom.ScriptHost.Keys.Table` / `.Keys` | la tabella dei 56 `key_*`/`mouseb*`/`joyb*` (nome, tasto, giochi, protezione demo) e `TScriptKeys` (+ `TScriptKeyBinding`, uno per riga della tabella; `gamekeydown`, `mousebuttons`, `joybuttons`) |

Nel motore: `Base\DelphiDoom.Engine.Script.GameInfo`, `.Textures`, `.Keyboard` (le uniche a leggere i globali). `ComposeScriptHost` le crea e le da' a `PS_ConfigureGameFunctions` di `ps_import`, che le chiama da `PS_DescribeGameFunctions` al posto delle vecchie `ATable.Add` (stesso ordine, stesse dichiarazioni). I `PS_Game*`, `PS_*Texture*`, `PS_key_*`, `PS_mouseb*`, `PS_joyb*` di `psi_game` non esistono piu. Test: `Tests\Source\DelphiDoom.Tests.ScriptHost.GameSections` (25, anche uno script vero compilato ed eseguito con le tre sezioni).

## Attori di PS_GAME (issue #172, fetta 2f-5)

| Unit | Ruolo |
|---|---|
| `DelphiDoom.ScriptHost.Actors.Intf` | i campi (`TScriptActorField`: i numeri di un attore; `TScriptActorText`: nomi, traduzione, suoni; `TScriptActorRelation`: bersaglio, tracciante, padrone; `TScriptActorSelection`: le liste di `Actors.All*`), `IScriptActorContext` (l'attore implicito), `IScriptActorSource` (l'unica porta verso i mobj) e `IScriptActors` (le funzioni, per le proprieta' delle classi degli script) |
| `DelphiDoom.ScriptHost.Actors.KeyList` | `TScriptActorKeyList`: il vecchio `TActorKeyList` senza le scansioni dei thinker (stesso ordine delle chiavi: cercare una chiave la porta in testa) |
| `DelphiDoom.ScriptHost.Actors` | `TScriptActors`: le 114 funzioni (115 in Strife, che ha `GetActorName2`) nell'ordine delle dichiarazioni di prima; i numeri, i testi e le relazioni sono un oggetto per campo (`TScriptActorNumberBinding`, ...: lo stesso metodo con `Self` diverso), le altre sono metodi della classe; `GetPlayerActor` sta fra queste e chiede a `IScriptPlayers` |

Nel motore: `Base\DelphiDoom.Engine.Script.ActorContext(.Intf)` (`TEngineScriptActorContext`: l'attore corrente come puntatore a mobj, `Enter`/`Leave`/`MobjFromKey`; era la variabile `ps_currentactor`) e `Base\DelphiDoom.Engine.Script.Actors` (`TEngineScriptActors`: l'unica classe che legge e scrive `mobj_t` per le funzioni degli attori, con la scansione dei thinker per le liste, `_playsound` e la mappa dei flag). `ComposeScriptHost` le crea e le da' a `PS_ConfigureActorFunctions` (`psi_game`, senza di essa `I_Error`); `PS_EventActorDied`, `PS_EventPlayerEnter`... (gli eventi) e `TPSExecManager.RunScript` (il percorso di `A_RunScript`) chiamano `PS_ActorContext.Enter`/`Leave`. I `PS_*Actor*`, `PS_Actor`, `PS_TActor`, `PS_Spawn*`, `PS_RemoveActor`, `PS_PlaySound`, `mobj_from_key`, `_playsound` e `TActorKeyList` di `psi_game` non esistono piu: i 98 helper `TRTLActor*` delle classi degli script chiamano `PS_Actors.GetNumber(chiave, campo)`, `SetNumber`, `GetText`, `GetRelation`... Test: `Tests\Source\DelphiDoom.Tests.ScriptHost.Actors` (sorgente finta, due script veri compilati ed eseguiti, il contesto, la lista delle chiavi).

## Classi che gli script vedono e costanti di SYSTEM (issue #172, fetta 2g)

| Unit | Ruolo |
|---|---|
| `DelphiDoom.ScriptHost.Classes.Intf` | `IScriptClassCatalog` (le classi di un gioco: `AddClass`, `RegisterCompiler`, `RegisterRuntime`, `BindVariables`), `IScriptClassDescriptor` (i membri di una classe: proprieta' con lettore e scrittore, solo del runtime, metodi, costruttore, proprieta' predefinita, variabile) e `TScriptInstanceProvider` (l'oggetto di una variabile si chiede al caricamento dello script) |
| `DelphiDoom.ScriptHost.Classes.Descriptor` / `.Catalog` | `TScriptClassDescriptor` e `TScriptClassCatalog`: la stessa lista registra la classe nel compilatore (prima tutte le classi, poi i membri) e nell'interprete; ogni membro ha l'insieme dei giochi in cui esiste (compilatore e runtime possono differire) |
| `DelphiDoom.ScriptHost.Constants.Intf` / `.Compiler` / `.Chain` | `IScriptConstantTable` (`AddInteger`, `AddLongWord`, `AddExtended`), `IScriptConstantProvider`, la tabella che scrive nel compilatore e la catena che chiede ai provider nell'ordine dato |
| `DelphiDoom.ScriptHost.Constants.Basic` / `.Generalized` | `NaN`, `Infinity`, `NegInfinity`, `MAXINT` e le 81 costanti dei tipi generalizzati di Boom (tabella) |

Nel motore: `psi_game` (`PS_DescribeGameClasses`) e `psi_globals` (`PS_DescribeGlobalClasses`) descrivono le classi con i loro helper; `Base\DelphiDoom.Engine.Script.Constants.Mobj/Game/World/Groups` danno le altre costanti (flag, stati, tipi, enum del gioco, `p_local`, `tables`, gruppi MBF21; le `{$IFDEF}` di tipo restano li'). `ComposeScriptHost` crea il catalogo (`TScriptHostFactory.CreateClassCatalog`) e la catena (`CreateConstants`) e li da' a `PS_ConfigureClassCatalog` e `PS_ConfigureConstants` (`ps_import`). `SIRegister_Game`, `RIRegister_Game`, `SIRegister_GlobalVars`, `RIRegister_GlobalVars` e le `RIRegisterRTL_*` non esistono piu'. Test: `Tests\Source\DelphiDoom.Tests.ScriptHost.ClassCatalog`, `...ConstantsBasic`, `...ConstantsGeneralized`, `...ConstantChain`, `...ConstantsCompiler`.
## Servizi, define e manager degli script (issue #172, fetta 2h)

| Unit | Ruolo |
|---|---|
| `DelphiDoom.ScriptHost.Services.Intf` / `.Services` | `IScriptHostServices`: registro, catalogo delle classi, costanti, file, nome e gioco e define di un compilatore e di un interprete; `TScriptHostServices` li tiene (i define sono una funzione chiesta a ogni compilazione) |
| `DelphiDoom.ScriptHost.Source.Intf` | `IScriptSourceProvider`: i file degli script (nel motore `Base\DelphiDoom.Engine.Script.SourceProvider`, sopra il file system dei PAK) |
| `DelphiDoom.ScriptHost.Defines` | `TScriptDefines.ForGame`: i define del preprocessore degli script per un gioco |
| `DelphiDoom.ScriptHost.Manager` | `TScriptManager` (ex `TPSExecManager`): sorgenti, codice compilato e interpreti degli script; `ps_main` lo crea in `PS_Init` e lo da' con `PS_Manager` |

`ComposeScriptHost` crea i servizi e li da' a `PS_ConfigureHostServices`. Test: `...Tests.ScriptHost.Services`, `...Defines`.