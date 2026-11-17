# IdTech4\Q3Host

Il lato "motore" delle chiamate di sistema dei tre moduli di Quake III Arena (`qagame`, `cgame`, `ui`), issue #254 (fase 2a, vedi `docs\QUAKE3_CENSIMENTO.md`). Port dello `switch` di `SV_GameSystemCalls` (`sv_game.c`), `CL_CgameSystemCalls` (`cl_cgame.c`) e `CL_UISystemCalls` (`cl_ui.c`) come **tabella da numero a gestore**. Licenza: GPL v2 o successiva ("Based on the Quake III Arena GPL Source Code"). Nessun chiamante nel motore di Doom.

```pascal
LHost := TQ3HostFactory.CreateHost(TQ3Module.Game, LConsole, LTime);   // IQ3SyscallHost: IQvmHost + registro
LHost.Registry.Register(G_CVAR_REGISTER, LHandler);                      // il motore aggiunge i suoi gruppi
LMachine := TQvmFactory.CreateMachine('qagame', LBytes, LHost);          // IdTech4\Qvm
LMachine.Call(GAME_INIT, [LevelTime, RandomSeed, 0]);
```

| C | Pascal |
|---|---|
| `gameImport_t`, `sharedTraps_t` (`TRAP_*`), `cgameImport_t`, `uiImport_t` e gli export | `DelphiDoom.Q3Host.Opcodes` (costanti, **generata**), `OpcodeTables`, `TQ3OpcodeCatalog` (numero <-> nome) |
| `switch ( args[0] )` | `TQ3SyscallHost` (`DelphiDoom.Q3Host.SyscallHost`) |
| `default: Com_Error( ERR_DROP, "Bad game system trap: %i" )` | `EQ3UnknownSyscallException` ("Bad game system trap: N") |
| `VMA`, `VMF`, `FloatAsInt` | `TQ3SyscallArguments.Buffer/Text`, `ToSingle`, `FromSingle` |
| `G_PRINT`/`CG_PRINT`/`UI_PRINT`, `*_ERROR`, `*_MILLISECONDS` | `TQ3CommonSyscalls` con `IQ3HostConsole`, `EQ3ModuleErrorException`, `IQ3HostTime` |
| `TRAP_MEMSET`..`TRAP_CEIL` (`CG_`, `UI_`) | `TQ3CommonSyscalls` (memset, memcpy, strncpy, sin, cos, atan2, sqrt, floor, ceil) |

Una trap che il modulo ha e nessuno ha registrato solleva `EQ3UnhandledSyscallException` col nome ("System trap G_FS_READ (..) of game has no handler"); con `Fallback` (un altro `IQvmHost`) si rimanda a lui.

## Fase 2b: le trap con servizio

`TQ3HostFactory.CreateHostWithServices(modulo, console, orologio, TQ3HostServices)` registra i gruppi per cui il motore ha dato il servizio (`TQ3HostServices` ha tutti i campi opzionali; senza un servizio il gruppo non c'e' e la trap solleva col suo nome). Servizi piccoli in `DelphiDoom.Q3Host.Services.Intf`; cvar, comandi e buffer sono le interfacce di `Framework\Console` (profilo Quake III, gia' uguale al C), il clipmap e' `IQ3CollisionModel` di `IdTech4\Collision`, i file sono `IGameFileSystem` di `Framework\Wad`.

| C | Pascal |
|---|---|
| `Cvar_Register/Update/Set/VariableValue/VariableIntegerValue/VariableStringBuffer/SetValue/Reset/Get/InfoStringBuffer`, `Cmd_Argc/ArgvBuffer/ArgsBuffer`, `Cbuf_ExecuteText/AddText`, `Cmd_AddCommand/RemoveCommand` (`G_CVAR_*`, `CG_CVAR_*`, `UI_CVAR_*`, `*_ARGC`, `*_ARGV`, `CG_ARGS`, `G_SEND_CONSOLE_COMMAND`, `CG_SENDCONSOLECOMMAND`, `CG_ADDCOMMAND`, `CG_REMOVECOMMAND`, `UI_CMD_EXECUTETEXT`) | `TQ3CvarSyscalls` (il `vmCvar_t` da 272 byte letto e scritto nella memoria del programma) |
| `FS_FOpenFileByMode`, `FS_Read2`, `FS_Write`, `FS_FCloseFile`, `FS_Seek`, `FS_GetFileList` (`*_FS_*`) | `TQ3FileSyscalls` + `IQ3HostFileSystem` / `TQ3GameHostFiles` (63 maniglie, lettura da `IGameFileSystem`, scrittura da `IGameFileWriter`) |
| `CM_LoadMap` (cgame), `CM_NumInlineModels/InlineModel/TempBoxModel/PointContents/TransformedPointContents/BoxTrace/TransformedBoxTrace` e le varianti capsula (`CG_CM_*`), `CG_GET_ENTITY_TOKEN` | `TQ3CollisionSyscalls`, `IQ3HostClipMap` (`TQ3HostClipMap`: la mappa che server e client game condividono), `TQ3HostMapLoader` (`maps/x.bsp` dal file system), `TQ3EntityTokens` (`COM_Parse` sul testo delle entita'), `TQ3TraceMemory` (`trace_t` da 56 byte) |
| `sv_world.c` (`SV_LinkEntity`, `SV_UnlinkEntity`, `SV_AreaEntities`, `SV_Trace`, `SV_ClipToEntity` nel ciclo di `SV_ClipMoveToEntities`, `SV_PointContents`, `SV_EntityContact`) e `SV_SetBrushModel`, `SV_inPVS`, `SV_AdjustAreaPortalState`, `SV_LocateGameData` | `TQ3GameWorld` (stesso albero dei settori di 64 nodi: l'ordine di `G_ENTITIES_IN_BOX` e' quello del C) |
| `SV_SetConfigstring/GetConfigstring`, `SV_SetUserinfo/GetUserinfo`, `SV_GetServerinfo`, `SV_GetUsercmd`, `SV_BotAllocateClient/BotFreeClient`, `SV_GameSendServerCommand`, `SV_GameDropClient`, `G_GET_ENTITY_TOKEN` | `TQ3HostServerState`, `IQ3HostServerCommands`, `TQ3GameSyscalls` |
| `Com_RealTime`, `Sys_SnapVector` (`*_REAL_TIME`, `G_SNAPVECTOR`, `CG_SNAPVECTOR`) | `TQ3MiscSyscalls` + `IQ3HostCalendar` |

**Layout dei dati condivisi**: `Tests\Data\Q3Host\layout.golden.txt` (`Tools\Verifica\254\layout.sh`) ha `offsetof`/`sizeof` di `sharedEntity_t`, `entityState_t`, `entityShared_t`, `trace_t`, `vmCvar_t`, `usercmd_t`, `qtime_t` dai veri header (gcc -m32). Trappola: nel `g_public.h` che c'e' qui `entityShared_t` comincia con un suo `entityState_t` (208 byte), quindi `r.linked` e' a 416 e non a 208 + 4.

**Difetti del C conservati**: `FS_Seek` in un file di un pak rilegge dall'inizio e legge `offset` byte (l'origine conta solo con offset 0 e `FS_SEEK_SET`), con offset da 65536 in su e' un errore fatale; `SV_PointContents` usa `s.origin` e `s.angles` dell'entita' (non `currentOrigin`) e `SV_EntityContact` non azzera gli angoli di una scatola; `SV_AreaEntities` stampa "MAXCOUNT" e torna dal solo nodo pieno (gli altri rami continuano); il passo "il primo nodo che il box attraversa" e il limite di 16 cluster per entita' sono quelli del C; `Cvar_VariableStringBuffer` di una variabile che non c'e' scrive solo il primo byte; una `vmCvar_t` si riscrive solo quando il contatore cambia.

**Differenze volute**: (1) un indirizzo o una lunghezza fuori dalla memoria del programma e' un'eccezione (come nella 2a); (2) `G_SET_BRUSH_MODEL` con puntatore nullo o un nome che non comincia per `*` e' `EQ3HostException` (il C: `Com_Error`); (3) un buffer di lunghezza minore di 1 per `G_GET_CONFIGSTRING`, `G_GET_USERINFO`, `G_GET_SERVERINFO` e `G_GET_ENTITY_TOKEN` e' un errore (`Com_Error` del C); (4) `$modlist` di `G_FS_GETFILELIST` risponde 0 mod; (5) i nomi elencati da un pak sono in minuscolo (il file system di `Framework\Wad` li da' cosi'); (6) `G_DEBUG_POLYGON_*` rispondono 0 (disegno di debug); (7) `SV_inPVS` con un cluster di -1 (il C legge un byte prima della riga) risponde "non visibile"; (8) un puntatore a `FS_FOpenFileByMode` nullo in lettura dice solo se il file c'e' (1/0) come `FS_FOpenFileRead( name, NULL )`; (9) il nome che `SV_SetUserinfo` copia dalla info string non e' tenuto (il server lo legge da li').

**Non portato**: `BOTLIB_*` e `G_BOT_*` oltre l'allocazione dello slot (botlib: `IdTech4\BotAi` e `IdTech4\Aas` hanno le funzioni ma non il ponte con handle e numeri: fase 2d); `CG_GETGAMESTATE`, snapshot, usercmd, key catcher, `CG_GET*`, `UI_GETCLIENTSTATE`, `UI_LAN_*` (fase 2c); renderer (`*_R_*`, `UI_GETGLCONFIG`), suono (`*_S_*`), filmati (`*_CIN_*`), `*_PC_*` (parser di `Framework\Scanner`: da collegare), `CG_CM_MARKFRAGMENTS`, `G_BOT_*` oltre i due slot; `SV_SetConfigstring` non manda "cs"/"bcs" ai client (e' il server a farlo dal callback `OnConfigstringChanged`); `FS_GetModList`. Elenco esatto: `Tests\Data\Q3Host\unhandled.golden.txt`.

**Non portato (fasi 2c e successive)**: `MatrixMultiply`, `AngleVectors`, `PerpendicularVector` (`TRAP_MATRIXMULTIPLY`...), `CG_ACOS`/`UI_ACOS`, `TRAP_TESTPRINT*`; `MISSIONPACK` (gli enum sono quelli di baseq3).

**Difetti del C conservati**: nessuno rilevante. **Differenze volute**: (1) un intervallo di memoria (`memset`, `memcpy`, `strncpy`) che esce dall'immagine del programma e' un'eccezione (`EQvmExecutionException`); il C maschera l'indirizzo e poi si fida della lunghezza, cioe' legge e scrive memoria del processo; (2) un puntatore a stringa nullo e' `EQ3HostException` (il C legge l'indirizzo 0); (3) `memset` e `memcpy` rispondono 0 come il C, `strncpy` l'indirizzo di destinazione nel programma (il C da' il puntatore dell'host troncato a 32 bit, inutilizzabile); (4) `sqrt` di un negativo da' il NaN `FFC00000`, `sin(-0)` da' `-0` anche a Win64 (la RTL lo perde): ogni NaN e' considerato uguale a un altro NaN nel confronto col C (segno e payload dipendono dall'unita' in virgola mobile).

Parita': vedi `CLAUDE.md`.

## Fase 2d: il ponte BOTLIB di qagame

`TQ3HostServices.Bot` (`Files`: i botfiles e le mappe `.aas` come `IBotFileSource`; `Server`: `IQ3HostBotServer`, `TQ3HostBotServer` ne e' una senza rete; `Random`: nil e' il `rand()` del runtime Microsoft, seme 1). Con `Files` il gruppo si registra nell'host di qagame.

| C | Pascal |
|---|---|
| `Export_BotLibSetup/Shutdown/StartFrame/LoadMap/UpdateEntity/VarSet/VarGet` (`be_interface.c`), `SV_BotLibSetup` | `TQ3BotLibrary`, `TQ3BotCoreSyscalls` |
| `BotImport_*` (`sv_bot.c`): `Print` con `^3Warning: `, `^1Error: `, `^1Fatal: `, `Trace`, `EntityTrace`, `PointContents`, `inPVS`, `BSPEntityData`, `BSPModelMinsMaxsOrigin`, `BotClientCommand` | `TQ3BotImport`, `TQ3BotBsp`, `IQ3HostBotServer` |
| `SV_BotGetConsoleMessage`, `SV_BotGetSnapshotEntity`, `SV_ClientThink` (`BOTLIB_USER_COMMAND`) | `TQ3HostBotServer`, `TQ3BotCoreSyscalls` (chiamata annidata di `GAME_CLIENT_THINK`) |
| `aas_export_t` (22 trap `BOTLIB_AAS_*`) | `IQ3BotAas`, `TQ3BotAas`, `TQ3BotAasSyscalls` |
| `ea_export_t` (25 `BOTLIB_EA_*`), `ai_export_t` (caratteri, chat, obiettivi, movimento, armi, genetica) | `TQ3BotEaSyscalls`, `TQ3BotChatSyscalls`, `TQ3BotGoalSyscalls`, `TQ3BotMoveSyscalls` su `IBotAi` di `IdTech4\BotAi` |

**Non portato**: `BOTLIB_PC_LOAD_SOURCE`, `_FREE_SOURCE`, `_READ_TOKEN`, `_SOURCE_FILE_AND_LINE` (nessun modulo li chiama), `BOTLIB_TEST` risponde 0 (disegno di debug), `Log_Write` non scrive `botlib.log`, `TRAP_MATRIXMULTIPLY`, `TRAP_ANGLEVECTORS`, `TRAP_PERPENDICULARVECTOR`.

**Difetti del C conservati**: `BOTLIB_EA_ACTION` risponde -1 (`break` e poi `return -1`); `ValidEntityNumber` accetta `num == maxentities`; `BOTLIB_AI_GET_WEAPON_INFO`, `GET_TOP_GOAL`, `NEXT_CONSOLE_MESSAGE`, `GET_LEVEL_ITEM_GOAL`, `MOVEMENT_VIEW_TARGET` scrivono la struttura solo dove il C la scrive; `AAS_TraceAreas` azzera `areas[0]` anche senza mappa; `BOTLIB_AAS_VALUE_FOR_BSP_EPAIR_KEY` azzera `value[0]` prima di tutto.

**Differenze volute**: (1) `bot_consolemessage_t.prev/next` sono 0 (il C copia puntatori dell'host); (2) un'entita' con numero `== maxentities` e' `EAasEntityException` (il C scrive oltre la tabella); (3) l'inventario passato per puntatore e' letto per 256 interi (`MAX_ITEMS` del game: il C non conosce la lunghezza); (4) il testo cambiato sul posto (`UnifyWhiteSpaces`, `BotReplaceSynonyms`) e' scritto in un buffer da 256; (5) `PC_AddGlobalDefine` risponde 1 e non tiene il define; (6) il server senza rete scarta il comando affidabile piu' vecchio invece di buttare fuori il client; (7) `BOTLIB_GET_SNAPSHOT_ENTITY` e' -1 finche' il server non da' lo snapshot (`SetSnapshot`).

**Dopo la lettura del layout**: `bot_input_t` 40 byte, `bot_goal_t` 56, `aas_entityinfo_t` 140, `weaponinfo_t` 552, `bot_match_t` 328 (`char offset` + 3 di riempimento), `aas_altroutegoal_t` 24 (tre `unsigned short` e 2 byte di riempimento non scritti), `bot_consolemessage_t` 276.
## Fase 2c: cgame e ui senza il disegno (ondata 9)

Le voci "fase 2c" dei paragrafi "Non portato" qui sopra sono superate da questa sezione. I servizi del client sono nel campo `Client: TQ3HostClientServices` di `TQ3HostServices` (`DelphiDoom.Q3Host.Client.Services`; ogni campo opzionale, un gruppo si registra solo se ha il suo servizio). Interfacce piccole in `DelphiDoom.Q3Host.Client.Intf`.

| C | Pascal |
|---|---|
| `cl.gameState`, `cl.snapshots`, `clc.serverCommands`, `cl.cmds`: `CL_GetGameState`, `CL_ConfigstringModified`, `CL_GetCurrentSnapshotNumber`, `CL_GetSnapshot`, `CL_GetServerCommand` (con `bcs0/1/2`, `cs`, `map_restart`, `disconnect`), `CL_GetUserCmd`, `CL_SetUserCmdValue`, `CL_AddReliableCommand` (`CG_GETGAMESTATE`, `CG_GETCURRENTSNAPSHOTNUMBER`, `CG_GETSNAPSHOT`, `CG_GETSERVERCOMMAND`, `CG_GETCURRENTCMDNUMBER`, `CG_GETUSERCMD`, `CG_SETUSERCMDVALUE`, `CG_SENDCLIENTCOMMAND`, `UI_GETCONFIGSTRING`) | `TQ3ClientState` (`IQ3HostClientState`; il parser dei messaggi del server, che non e' qui, lo riempie con `ConfigstringModified`, `AddServerCommand`, `AddSnapshot`, `AddUserCommand`) + `TQ3ClientStateSyscalls` |
| `GetClientState`, `Hunk_MemoryRemaining`, `SCR_UpdateScreen`, `Sys_GetClipboardData` (`UI_GETCLIENTSTATE`, `*_MEMORY_REMAINING`, `*_UPDATESCREEN`, `UI_GETCLIPBOARDDATA`) | `IQ3HostUiConnection`, `IQ3HostClientSystem` |
| `keys[]`, `cls.keyCatchers`, `Key_StringToKeynum`, `Key_KeynumToString`, `Key_GetKey`, `Key_SetBinding`, `Key_ClearStates` (`CG_KEY_*`, `UI_KEY_*`) | `TQ3ClientKeys` (la tabella dei 107 nomi e' **generata** dal `cl_keys.c` vero: `DelphiDoom.Q3Host.Client.KeyNames`) + `TQ3KeySyscalls` |
| `PC_LoadSourceHandle`, `PC_FreeSourceHandle`, `PC_ReadTokenHandle`, `PC_SourceFileAndLine` (`CG_PC_*`, `UI_PC_*`) | `TQ3PrecompilerSyscalls` sopra `TQ3SourceHandles` di `Framework\Scanner` (port di `l_precomp.c` con parita' sul C); `TQ3HostScriptFiles` (file da `IGameFileSystem`), `TQ3HostScriptLog` |
| `S_RegisterSound`, `S_StartSound`, `S_StartLocalSound`, `S_*LoopingSound`, `S_UpdateEntityPosition`, `S_Respatialize`, `S_StartBackgroundTrack` (`CG_S_*`, `UI_S_*`) | `TQ3SoundSyscalls` + `IQ3HostSound`; `TQ3SoundSystemAdapter` lo porta su `TQ3SoundSystem` di `Framework\Audio` (la musica di sottofondo non e' nel sound system: non fa nulla) |
| `CIN_PlayCinematic`, `CIN_StopCinematic`, `CIN_RunCinematic`, `CIN_DrawCinematic`, `CIN_SetExtents` (`CG_CIN_*`, `UI_CIN_*`) | `TQ3CinematicSyscalls` + `IQ3HostCinematics`; `TQ3RoqCinematics` sul decoder e sul player RoQ di `Framework\Cinematic` (16 maniglie, `video/nome`, frame dal tempo dell'orologio, `OnDraw` consegna il frame e il rettangolo al renderer) |
| `re.*` di `cl_cgame.c` e `cl_ui.c`, `CL_GetGlconfig` (`CG_R_*`, `UI_R_*`, `CG_GETGLCONFIG`, `UI_GETGLCONFIG`, `CG_CM_MARKFRAGMENTS`, `UI_CM_LERPTAG`) | `TQ3RendererSyscalls` + `IQ3HostRenderer`; **`TQ3RecordingRenderer`** non disegna: conta e registra le chiamate, da' i numeri 1, 2, 3 ... ai modelli, alle skin, agli shader e ai font (stesso nome = stesso numero, senza badare alle maiuscole), risposte neutre (nessun tag, nessun frammento, nessuna luce, tutto nel PVS, bounds di 16 unita', finestra 640 x 480) |
| `LAN_*` di `cl_ui.c`, `NET_StringToAdr`, `NET_AdrToString`, `NET_CompareAdr` (`UI_LAN_*`) | `TQ3LanServers` (`IQ3HostLan`: quattro liste, aggiungi, togli, info string, confronto, visibilita'), `TQ3NetAddresses`, `TQ3LanSyscalls` |
| `CLUI_GetCDKey`, `CLUI_SetCDKey`, `CL_CDKeyValidate` (`UI_GET_CDKEY`, `UI_SET_CDKEY`, `UI_VERIFY_CDKEY`, `UI_SET_PBCLSTATUS`) | `TQ3ClientCdKey`, `TQ3CdKeySyscalls` (la chiave unica e' chiesta al modulo con `UI_HASUNIQUECDKEY`: una chiamata dentro la macchina da una trap) |
| `Q_acos` (`CG_ACOS`) | `TQ3ClientMathSyscalls` (si accende con `Client.Math`) |

**Layout**: `Tests\Data\Q3Host\client-layout.golden.txt` (`Tools\Verifica\254\client-layout.sh`, gcc -m32 sui veri header): `snapshot_t` 53772 byte (`ps` a 44, `numEntities` a 512, `entities` a 516, `serverCommandSequence` a 53768), `gameState_t` 20100, `playerState_t` 468, `uiClientState_t` 3084, `glconfig_t` 11332, `pc_token_t` 1040. **Nomi dei tasti**: `keys.golden.txt` (`client-keys.sh` taglia la tabella e le due funzioni dal `cl_keys.c` e le compila cosi' come sono; `client-keys-pascal.sh` scrive la tabella Pascal da quelle righe). **`CG_ACOS`**: `acos.golden.txt` (`acos.sh`: `Q_acos` copiata da `common.c`, 4222 ingressi, uguale bit per bit a Win32 e Win64).

**Difetti del C conservati**: `CG_R_REGISTERFONT` non ha `return` e prosegue in `CG_R_CLEARSCENE` (la scena si cancella dopo ogni font); `UI_CM_LERPTAG` risponde 0 qualunque cosa dica il renderer; `CL_GetSnapshot` non copia i comandi del server dello snapshot ("FIXME" del C: `numServerCommands` resta com'era); `LAN_GetServerAddressString`, `LAN_GetServerInfo`, `LAN_GetServerPing` e `LAN_ServerIsVisible` controllano l'indice contro la dimensione della lista e non contro i server contati (uno slot libero e' un indirizzo `bot`, ping 0); `LAN_MarkServerVisible( -1 )` marca tutta la lista; un indirizzo che non si risolve si aggiunge ogni volta (`NA_BAD` non e' mai uguale a un altro); `Key_StringToKeynum( "0xzz" )` da' 0 (le cifre non esadecimali valgono 0) e solo le lettere minuscole sono cifre; un carattere sopra 127 e' un tasto negativo (`char` con segno); `PC_ReadTokenHandle` fa `strcpy` nel campo del token (il testo e il suo zero, non il resto del campo) e scrive il token anche quando la lettura finisce.

**Differenze volute**: (1) un tasto fuori da 0..255 non e' mai premuto e un'associazione a lui e' ignorata (il C indicizza `keys[]`); (2) la cache `servercache.dat` non si legge ne' si scrive (`LoadCachedServers` la trova assente: i conteggi di globali, multiplayer e preferiti vanno a 0), la coda dei ping e' sempre vuota, nessun ping parte e nessuno stato di server arriva (non c'e' rete); (3) i nomi di host non si risolvono: solo `localhost`, quattro numeri e ":porta" sono un indirizzo, il resto e' `NA_BAD` (il C chiede al resolver) e anche le forme `a.b.c` di `inet_addr` non sono accettate; (4) `clientLevelShot` risponde falso (non c'e' un server locale, `com_sv_running` e' 0); (5) `TQ3RoqCinematics` non chiude il menu ne' cambia `cls.state` per un filmato con `CIN_system`, non manda l'audio da nessuna parte e usa l'orologio dell'host invece di `com_timescale`; (6) `CG_PC_ADD_GLOBAL_DEFINE` e `UI_PC_ADD_GLOBAL_DEFINE` non sono serviti: il precompilatore di `Framework\Scanner` non ha `PC_DefineFromString` e i dodici `.qvm` di OpenArena non li chiamano in init, primo fotogramma e refresh (misurato); `CG_CM_LOADMODEL`, `UI_CM_LOADMODEL`, `CG_TESTPRINTINT` e `CG_TESTPRINTFLOAT` non sono nello `switch` del C ("Bad cgame system trap") e restano senza gestore.

**Fin dove arrivano i dodici `.qvm`** (`reach-client.golden.txt`, `TTestQ3ClientReach`, file system vero, `oa_dm1`, un `qagame` che ha fatto `GAME_INIT`, un client, tre fotogrammi e ha detto le sue configstring al client): cgame e ui di baseoa e di missionpack **arrivano in fondo**, nessuna trap senza gestore. `CG_INIT` + un `CG_DRAW_ACTIVE_FRAME`: baseoa 1293 chiamate, 235 shader, 87 modelli, 1 scena disegnata, 53 `DrawStretchPic`, 216 chiamate al suono; missionpack 2900 chiamate, 246 shader. `UI_INIT` + `UI_SET_ACTIVE_MENU` (menu principale) + 3 `UI_REFRESH`: baseoa 2210 chiamate, 897 `DrawStretchPic`, 3 scene; missionpack 33476 chiamate (parte i `.menu` con `PC_*`), 912 `DrawStretchPic`. Nelle righe ui del golden `shaders=` e' cumulativo (include quelli registrati da cgame sullo stesso renderer). Win32 e Win64 uguali.

## Fase 2e: il server in memoria e il sink del client

| C | Pascal |
|---|---|
| `CL_ParseGamestate`, `CL_ParseCommandString`, `CL_ParseSnapshot` (i stores in `cl` e `clc`; il parser e' `TQ3ServerMessageParser` di `IdTech4\NetQ3`) | `TQ3ClientMessageSink` -> `TQ3ClientState` (`ClearState`, `GamestateConfigString`, `StoreServerCommand`, `AddParsedSnapshot`) |
| `SV_BuildClientSnapshot`, `SV_AddEntitiesVisibleFromPoint`, `SV_EmitPacketEntities`, `SV_WriteSnapshotToClient`, `SV_SendClientSnapshot` | `TQ3ServerSnapshots.WriteSnapshot` |
| `SV_SendClientGameState`, `SV_CreateBaseline` | `TQ3ServerSnapshots.WriteGamestate`, `CreateBaselines` |
| `SV_AddServerCommand`, `SV_SendServerCommand`, `SV_SetConfigstring` (cs e bcs0/1/2) | `TQ3ServerSnapshots.Send`, `ConfigstringChanged` |
| `OP_BLOCK_COPY` di ioquake3 (nessun controllo di allineamento) | `TQvmLimits.UnalignedBlockCopy` |

Difetti conservati: nessuno nuovo. Differenze volute: vedi `CLAUDE.md`, fase 2e. Il server non ha rete: i messaggi sono i byte che il parser legge (con `svc_EOF` finale, come `SV_Netchan_Transmit`).
