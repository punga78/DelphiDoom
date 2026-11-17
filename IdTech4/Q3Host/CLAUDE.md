# IdTech4\Q3Host — note per Claude

Issue #254 (Quake III: dalle librerie a un eseguibile), fase 2a. Descrizione e tabella C -> Pascal: [README.md](README.md); piano e censimento: `docs\QUAKE3_CENSIMENTO.md`. Qui il metodo.

## Unit (una classe per unit, `DelphiDoom.Q3Host.*`)

`Types` (`TQ3Module`, `TQ3OpcodeEntry`, eccezioni `EQ3HostException` -> `EQ3ModuleErrorException`, `EQ3UnknownSyscallException`, `EQ3UnhandledSyscallException`), `Opcodes` e `OpcodeTables` (**generate**), `OpcodeCatalog` (`TQ3OpcodeCatalog`), `Intf` (`TQ3SyscallHandler` = `reference to function`, `IQ3SyscallRegistry`, `IQ3SyscallHost`, `IQ3HostConsole`, `IQ3HostTime`), `Arguments` (`TQ3SyscallArguments`), `SyscallHost` (`TQ3SyscallHost`: implementa `IQvmHost` e `IQ3SyscallRegistry`; `GetRegistry` rende `Self`, un solo oggetto), `CommonSyscalls` (`TQ3CommonSyscalls.Register`), `Factory` (`TQ3HostFactory`, composition root). Usa `IdTech4\Qvm` e `TQ3FloatMask` di `IdTech4\Decl`.

## Come si rifanno i dati (`Tools\Verifica\254`, gcc di `Reference\_dati\_strumenti\w64devkit`, i programmi C sono a 32 bit con float SSE)

```
sh Tools/Verifica/254/opcodes.sh <cartella> > Tests/Data/Q3Host/opcodes.golden.txt
sh Tools/Verifica/254/opcodes-pascal.sh <radice del repository>      # riscrive Opcodes.pas e OpcodeTables.pas dal golden
sh Tools/Verifica/254/init-golden.sh <cartella> > Tests/Data/Q3Host/init.golden.txt
sh Tools/Verifica/254/math.sh <cartella> > Tests/Data/Q3Host/math.golden.txt
```

- **I numeri non si scrivono a mano**: `opcodes.sh` estrae i nomi degli enum con awk e fa stampare i valori a un programma compilato con gli header veri. Trappola trovata: le `TRAP_MEMSET`...`TRAP_CEIL` di `game` non sono in `g_public.h` ma in `sharedTraps_t` di `qcommon.h`; la tabella degli import di `game` e' `gameImport_t` + `sharedTraps_t`. I `.asm` dei moduli (`equ trap_Print -1`: indirizzo = -1 - numero) sono una seconda fonte letta dal test.
- `Exports` e' una parola riservata di Delphi: i metodi del catalogo sono `ImportEntries`/`ExportEntries`.
- `init.golden.txt` non e' `Tests\Data\Qvm\openarena.golden.txt`: il pilota di `Tools\Verifica\120` risponde a `memset` e `memcpy` con la destinazione, `sv_game.c` con 0; `init-golden.sh` ricompila una copia del pilota con quelle due righe cambiate e il resto uguale. Le risposte che il pilota inventa (`G_GET_ENTITY_TOKEN`, `G_GET_CONFIGSTRING`, `CG_GETGAMESTATE`) stanno nel test (`DelphiDoom.Tests.Q3Host.Init`), perche' sono del pilota.
- Un `Com_Error` di un modulo (il `ui` di `mp-pak0` a `UI_INIT` per il file `ui/menus.txt` assente) e' `EQ3ModuleErrorException`: il test lo scrive come "X" e "E", come il pilota.

## Numeri (2026-11-16)

`Tests\DelphiDoom.Tests.Q3Host` (`Tools\build.bat Tests\DelphiDoom.Tests.Q3Host Release [Win64]`): **19 test alla fase 2a, 79 con la 2b**, verdi a Win32 e a Win64, 0 avvisi. Catalogo: 427 membri di enum uguali a gcc, 361 `equ` dei tre `.asm` risolti. Matematica: 4289 coppie x 6 funzioni x 3 moduli, bit per bit come il C (NaN contati uguali tra loro); a Win64 `Sin(-0)` della RTL perde il segno (corretto nel gestore). Inizializzazione: 12 `.qvm` di OpenArena, 19480 chiamate di sistema, valori di ritorno, testi, immagine dei dati, conteggio e impronta (FNV-1a 64 di argomenti e risultati) uguali al C.

## Fase 2b (2026-11-17, tag `ondata8-254-1`..)

Unit nuove (una classe per unit): `Services.Intf` (`IQ3HostFileSystem`, `IQ3HostMapLoader`, `IQ3HostClipMap`, `IQ3HostServerState`, `IQ3HostServerCommands`, `IQ3HostCalendar`), `CvarSyscalls`, `FileSyscalls`, `GameFiles` (`TQ3GameHostFiles` su `IGameFileSystem`/`IGameFileWriter`), `ClipMap`, `MapLoader`, `TraceMemory`, `EntityTokens`, `CollisionSyscalls` (cgame), `ServerState`, `GameWorld` (`TQ3GameWorld` = `sv_world.c`), `GameSyscalls` (qagame), `MiscSyscalls`; `Factory` ha `CreateHostWithServices(modulo, console, orologio, TQ3HostServices)` (record di servizi opzionali: il gruppo si registra solo se i suoi servizi ci sono; il mondo e i token delle entita' appartengono al host, `TQ3SyscallHost.Own`). Dettaglio C -> Pascal, difetti conservati e differenze volute: README.

- **Riuso, non duplicato**: cvar, comandi e buffer sono `IQ3CVarSystem`, `IQ3CommandArguments`, `IQ3CommandBuffer`, `IQ3CommandRegistry` di `Framework\Console` (parita' col C vero di cvar.c/cmd.c nei suoi test); la collisione e' `IQ3CollisionModel`; i file sono `IGameFileSystem`; `COM_Parse` e' `TQ3TokenReader` di `Framework\Models`.
- **Parita'**: `layout.golden.txt` (`Tools\Verifica\254\layout.sh`, gcc -m32 sui veri header: dimensioni e offset delle strutture condivise) e test DUnitX con finti scritti sul C letto (`sv_game.c`, `sv_world.c`, `files.c`, `cl_cgame.c`, `cl_ui.c`); `sv_world.c` non e' compilabile da solo (dipende da `server.h`): niente harness C, il mondo e' provato su `q3world0.bsp` (BSP sintetico di `IdTech4\Collision`, che ha la sua parita' sul C) con il box delle entita' e il tracciamento contro il loro box. **Lacuna dichiarata**: `SV_Trace` e l'ordine di `SV_AreaEntities` non hanno una risposta del C.
- **Fin dove arrivano i 12 `.qvm`** (`Tests\Data\Q3Host\reach.golden.txt`, `TTestQ3HostReach`, file system vero sulla cartella di OpenArena): `qagame` fa `GAME_INIT`, `GAME_CLIENT_CONNECT`, `GAME_CLIENT_BEGIN` e 100 `GAME_RUN_FRAME` **fino in fondo** (baseoa 15389 chiamate, missionpack 11277); `cgame` si ferma dopo 5 chiamate a `CG_R_REGISTERSHADER`, `ui` a `UI_GETGLCONFIG` (baseoa dopo 864, missionpack dopo 110): sono il renderer. Win32 e Win64 uguali. Il test di inizializzazione uguale al C (`TTestQ3HostInit`) non e' cambiato: usa solo le trap comuni piu' le tre risposte del pilota.
- `unhandled.golden.txt` (`TTestQ3HostCoverage`): le trap del catalogo senza gestore con tutti i servizi dati (game 55 su 197 registrate, cgame 41 su 102, ui 31 su 97). Si rifa con `DELPHIDOOM_Q3_UNHANDLED_OUT=<file>`, e `reach.golden.txt` con `DELPHIDOOM_Q3_REACH_OUT=<file>` e `DELPHIDOOM_OPENARENA=<cartella di openarena-0.8.8>` (in un worktree `Reference\` non c'e').
- Trappole: il `.dproj` dei test elenca ora le cartelle di Console, Collision, MapFile, IdLib e Scanner; `Assert.AreEqual` con `Single` e interi non deduce `T` (scrivere `Single(...)`); `Cvar_Set( name, NULL )` (un valore nullo) e' il reset: l'avevano scoperto i 100 frame di qagame.

## Resta da fare

Fase 2c (cgame e ui senza renderer: `CG_GETGAMESTATE`, snapshot, usercmd, key catcher, `UI_GETCLIENTSTATE`, `UI_LAN_*`, `*_PC_*`), il ponte botlib (`BOTLIB_*`: `IdTech4\BotAi`, `IdTech4\Aas`, handle e numeri). **`IdTech4\Pmove` non ha una trap**: `bg_pmove.c` e' compilato dentro `qagame` e `cgame`, che lo eseguono nella VM usando `G_TRACE`, `G_POINT_CONTENTS`, `CG_CM_BOXTRACE` e `CG_CM_POINTCONTENTS`, tutte servite da questa fase (la libreria Pmove serve a un server o a un client che predice fuori dal QVM). Poi renderer e suono. Una trap senza gestore solleva con il nome.
