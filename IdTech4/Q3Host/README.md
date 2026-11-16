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

**Non portato** (restano da fare, fase 2b e 2c): le ~200 trap che richiedono un servizio (cvar, comandi, file system, `G_LOCATE_GAME_DATA`, `G_TRACE`, entita', snapshot, renderer, suono, botlib `BOTLIB_*`); `MatrixMultiply`, `AngleVectors`, `PerpendicularVector` (`TRAP_MATRIXMULTIPLY`...), `CG_ACOS`/`UI_ACOS`, `TRAP_TESTPRINT*`; `MISSIONPACK` (gli enum sono quelli di baseq3).

**Difetti del C conservati**: nessuno rilevante. **Differenze volute**: (1) un intervallo di memoria (`memset`, `memcpy`, `strncpy`) che esce dall'immagine del programma e' un'eccezione (`EQvmExecutionException`); il C maschera l'indirizzo e poi si fida della lunghezza, cioe' legge e scrive memoria del processo; (2) un puntatore a stringa nullo e' `EQ3HostException` (il C legge l'indirizzo 0); (3) `memset` e `memcpy` rispondono 0 come il C, `strncpy` l'indirizzo di destinazione nel programma (il C da' il puntatore dell'host troncato a 32 bit, inutilizzabile); (4) `sqrt` di un negativo da' il NaN `FFC00000`, `sin(-0)` da' `-0` anche a Win64 (la RTL lo perde): ogni NaN e' considerato uguale a un altro NaN nel confronto col C (segno e payload dipendono dall'unita' in virgola mobile).

Parita': vedi `CLAUDE.md`.
