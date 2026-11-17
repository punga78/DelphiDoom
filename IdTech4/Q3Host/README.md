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
