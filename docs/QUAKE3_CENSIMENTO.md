# Quake III Arena: dalle librerie a un eseguibile che parte (issue #254)

Censimento dei moduli del C (`Reference\quake3\code`, righe contate il 2026-11-16 su `.c` e `.h`), cosa e' gia' stato portato, cosa manca per un eseguibile `Quake3` che carica un `.pk3` di OpenArena e fa giocare contro i bot, e le fasi con dipendenze. Licenza: GPL v2 o successiva (intestazione "Based on the Quake III Arena GPL Source Code"): nessuna decisione da prendere. Il gioco non si avvia in questo documento: tutto cio' che e' qui sotto "fatto" e' provato da test unitari e da programmi C compilati con gcc (`Reference\_dati\_strumenti\w64devkit`).

## 1. Moduli del C -> librerie nostre

| Modulo C | Righe | Libreria | Stato |
|---|---:|---|---|
| `botlib` | 34.690 | `IdTech4\Aas`, `IdTech4\BotAi` | quasi tutto (AAS, routing, reach, cluster; goal, move, gen, ea, chat, weapon, char); parita' sul C vero |
| `qcommon` `vm*.c` | ~1.700 | `IdTech4\Qvm` | fatto (#120); 12 `.qvm` di OpenArena caricati ed eseguiti |
| `qcommon` `cm_*.c` | ~6.500 | `IdTech4\Collision` | fatto (#118), 72 mappe di OpenArena |
| `qcommon` `msg.c`, `huffman.c`, `net_chan.c` | ~3.000 | `IdTech4\NetQ3` | fatto (#117, #237), demo `.dm_68` |
| `qcommon` `common.c`, `cmd.c`, `cvar.c` | ~4.500 | `Framework\Console` (profilo Quake III) | fatto in parte (cvar, comandi, riga di input); manca il ciclo `Com_Frame` |
| `qcommon` `files.c` | ~3.000 | `Framework\Wad` (`TPakPathResolver`, #251) | pk3 in lettura; mancano `FS_*` (handle, `fs_game`, pak pure, liste di file) |
| `qcommon` `unzip.c`, `md4.c` | ~2.000 | `Framework\Wad`, `Framework\MathCore` | fatto |
| `game/bg_*` | 3.700 | `IdTech4\Pmove` | fatto (#127), 192 scenari |
| `game` (qagame), `cgame`, `q3_ui`, `ui` | ~120.000 | **non si portano**: girano come `.qvm` | `IdTech4\Qvm` li esegue; i `.qvm` di OpenArena sono nei `.pk3` |
| trap di `game`/`cgame`/`ui` (`trap_*`) | ~4.500 | **`IdTech4\Q3Host` (questo giro)** | numeri e nomi (tutti), dispatcher, 12 trap comuni; le altre ~200 no |
| `server` (`sv_*`) | 8.980 | -- | manca; `NetQ3` ha solo codec |
| `client` (`cl_*`) | 15.757 | `IdTech4\NetQ3` (parser dei messaggi), `Framework\Input` | poco: manca il ciclo, il parse dello snapshot a regime, `cl_cgame`, `cl_ui` |
| `renderer` (`tr_*`) | 24.250 | `IdTech4\Decl` (shader), `IdTech4\MapFile` (BSP, superfici), `Framework\Models`, `Framework\Jpeg`, `Framework\Png` | circa un terzo; manca il backend (OpenGL via `Framework\OpenGlBinding`) |
| suono (`snd_*`) | ~5.500 | `Framework\Audio` (spazializzazione, canali, mixer), `Framework\AudioMix` | logica fatta; manca il collegamento al dispositivo |
| video RoQ (`cl_cin.c`) | ~1.700 | `Framework\Cinematic` | fatto (#114) |
| menu di Team Arena (`ui_shared.c`) | ~7.000 | `IdTech4\Gui` | fatto in lettura, senza disegno |
| `win32` | 11.615 | `Framework\GameHost`, `Framework\Platform`, `Framework\Input` | sostituibile, non portato |
| `splines`, `jpeg-6`, `unix`, `null` | ~39.000 | -- | non servono (Jpeg e' in `Framework\Jpeg`) |

## 2. Cosa manca per un eseguibile che parte

1. **L'host delle chiamate di sistema** dei tre moduli: ~200 `trap_*` oltre alle 12 comuni. Si divide in gruppi con un servizio ciascuno (cvar, comandi, file system, entita' e `trace`, configstring, renderer, suono, botlib).
2. **File system del motore** (`FS_*` con handle, `fs_game`, `fs_basepath`, pak pure).
3. **Il server** (`sv_init`, `sv_client`, `sv_game`, `sv_snapshot`, `sv_world`): stato dei client, albero delle entita' (`sv_world.c` sopra `IdTech4\Collision`), costruzione degli snapshot con PVS e aree (`SV_BuildClientSnapshot`), `sv_bot.c` come ponte verso `IdTech4\BotAi`.
4. **Il client** (`cl_main`, `cl_parse`, `cl_input`, `cl_cgame`, `cl_ui`, `cl_scrn`): ciclo, comandi dell'utente, host di `cgame` e `ui`.
5. **Il renderer backend**: OpenGL 1.x, superfici, shader a stadi, lightmap, modelli MD3/MDC/MDR, nebbia, flare, cielo, 2D (24.250 righe, un terzo gia' fatto).
6. **Suono e input** collegati a `Framework\GameHost`.
7. **Il programma `Quake3`**: composition root, `Tools\build.bat`, opzioni di prova (`-headless`, `-script`, `-shot`).

## 3. Fasi

| Fase | Contenuto | Dipende da | Stima | Stato |
|---|---|---|---|---|
| 1 | Verifica dei `.qvm` di OpenArena | `Qvm` | -- | **fatta** (`Tests\DelphiDoom.Tests.Qvm`, 12 su 12; init uguale al C) |
| 2a | Numeri e nomi di tutte le trap; dispatcher; trap comuni; init dei 12 `.qvm` attraverso l'host | 1 | 1 ondata | **fatta (questo giro)**: `IdTech4\Q3Host`, parita' sul C |
| 2b | Host di `qagame`: cvar, comandi, configstring, `locate_game_data`, entita', `trace`, `link`/`unlink`, `entities_in_box`; file; collisione di `cgame` | 2a, 3, `Collision` | 1-2 ondate | **fatta (ondata 8)** tranne botlib: vedi par. 5 |
| 2d | Ponte BOTLIB di `qagame`: 132 trap `BOTLIB_*` su 137 verso `BotAi` e `Aas` | 2b, `BotAi`, `Aas` | 1 ondata | **fatta (ondata 9)**: par. 6 |
| 2c | Host di `cgame` e `ui` (non-render): snapshot, usercmd, gamestate, key catcher | 2a, 3 | 1 ondata | da fare |
| 2c | Host di `cgame` e `ui` (non-render): snapshot, usercmd, gamestate, key catcher | 2a, 3 | 1 ondata | **fatta (ondata 9)**: vedi par. 6 |
| 3 | File system (`FS_*`), cvar e comandi nell'host, console | `Wad`, `Console` | 1 ondata | da fare (#251) |
| 4 | Server: mondo, snapshot, client; client: ciclo, parse, `cl_cgame`; parita' con `parsegen.c` e una demo `.dm_68` | 2b, 2c, 3, `NetQ3` | 2-3 ondate | da fare |
| 5 | Renderer backend OpenGL | `Decl`, `MapFile`, `Models`, `OpenGlBinding` | 3-4 ondate | da fare |
| 6 | Suono e input | `Audio`, `GameHost` | 1 ondata | da fare |
| 7 | Programma `Quake3` | 2-6 | 1 ondata | da fare |
| 8 | Prove: avvio, menu (UI QVM), mappa con bot, demo; decine di esecuzioni senza finestra | 7 | 1 ondata (a macchina scarica) | da fare |

Ordine di grandezza: 6-10 ondate da 5 agenti se i `.qvm` si riusano (resta vero). Rischi: prestazioni del renderer e del ciclo (misure a macchina scarica), residui senza oracolo di #237 (`sv_snapshot`, MDR/MD4, protocolli `.dm_70/.dm_71`, #251).

## 4. Cosa ha fatto la fase 2a

- `Tools\Verifica\254\opcodes.sh`: i **numeri** delle trap come li stampa gcc sugli header veri (`g_public.h`, `cg_public.h`, `ui_public.h`, e `sharedTraps_t` di `qcommon.h`: le `TRAP_MEMSET`...`TRAP_CEIL` di `game` stanno li', non in `g_public.h`) -> `Tests\Data\Q3Host\opcodes.golden.txt` (427 righe). I file `.asm` dei moduli veri (`g_syscalls.asm`, ...) sono una seconda fonte indipendente: ogni `equ` e' un import del catalogo.
- `Tools\Verifica\254\init-golden.sh`: l'inizializzazione dei 12 `.qvm` di OpenArena sul `vm.c` vero con un host che risponde a `memset`/`memcpy` come `sv_game.c` (0; lo stub di `Tools\Verifica\120` restituiva la destinazione) -> `Tests\Data\Q3Host\init.golden.txt`.
- `Tools\Verifica\254\mathgen.c`: `FloatAsInt( sin( VMF(1) ) )` e le altre cinque, 4289 coppie di float -> `Tests\Data\Q3Host\math.golden.txt`.
- (par. 5 sotto: la fase 2b.)
- Il collegamento delle tre trap che il pilota del C finge (`G_GET_ENTITY_TOKEN`, `G_GET_CONFIGSTRING`, `CG_GETGAMESTATE`) e' nel test, non nella libreria: sono risposte del pilota, non del motore.

## 5. Cosa ha fatto la fase 2b (ondata 8, 2026-11-17)

Codice e dettagli in `IdTech4\Q3Host` (README e CLAUDE.md); qui i numeri. Tutto provato da test unitari (`Tests\DelphiDoom.Tests.Q3Host`, 79 test, Win32 e Win64) e da gcc sui veri header per il layout della memoria; nessun gioco avviato.

- **Gruppi fatti**: cvar e comandi (`G_CVAR_*`, `CG_CVAR_*`, `UI_CVAR_*`, argc/argv/args, buffer dei comandi, `CG_ADDCOMMAND`/`REMOVECOMMAND`), file (`*_FS_*` con maniglie, lista dei file), collisione di `cgame` (`CG_CM_*` meno `LOADMODEL` e `MARKFRAGMENTS`, `CG_GET_ENTITY_TOKEN`, `CG_CM_LOADMAP`), mondo di `qagame` (`sv_world.c`: link, area, trace con le entita', contenuto, contatto, brush model, PVS e aree) e stato del server (configstring, userinfo, serverinfo, usercmd, comandi al server, slot dei bot, token delle entita', `G_LOCATE_GAME_DATA`), ora e `SnapVector` (tre moduli).
- **Parita'**: layout della memoria (`layout.golden.txt`) uguale ai veri header; cvar e comandi si appoggiano a `Framework\Console` che ha la parita' sul vero `cvar.c`/`cmd.c`; la collisione ha la parita' sul vero `cm_*.c`. **Senza risposta del C** (dichiarato): `SV_Trace`/`SV_AreaEntities`/`SV_LinkEntity` (`sv_world.c` include `server.h` e non si compila da solo; sono provati sul box delle entita' e sul BSP sintetico), le maniglie dei file (`files.c`).
- **Fin dove arrivano i 12 `.qvm`** di OpenArena (cartella vera, file system di `Framework\Wad`, mappa `oa_dm1`): **`qagame` esegue `GAME_INIT`, un client che si connette e inizia, e 100 fotogrammi fino in fondo**: baseoa 15389 chiamate di sistema, missionpack 11277 (zero trap non risposte; `bot_enable` e' 0, quindi nessuna `BOTLIB_*`). `cgame`: 5 chiamate poi `CG_R_REGISTERSHADER`; `ui`: baseoa 864 chiamate poi `UI_GETGLCONFIG`, missionpack 110. Il fermarsi di cgame e ui e' il renderer (fase 5), non un servizio mancante di questa fase. L'inizializzazione uguale al C (fase 2a) non e' cambiata. Golden: `Tests\Data\Q3Host\reach.golden.txt`.
- **Trap che restano** (`Tests\Data\Q3Host\unhandled.golden.txt`, 272): `qagame` 142 = 137 `BOTLIB_*` (setup, libvar, `PC_*`, `AAS_*`, `EA_*`, `AI_*`) + 5 `TRAP_*` matematiche di vettori; `cgame` 61 = renderer (`CG_R_*` 20, `CG_GETGLCONFIG`, `CG_UPDATESCREEN`, `CG_CM_LOADMODEL`, `CG_CM_MARKFRAGMENTS`), suono (`CG_S_*` 11), stato del client (`CG_GETGAMESTATE`, snapshot, comandi del server, usercmd), tasti (4), parser (`CG_PC_*` 5), filmati (5), `CG_MEMORY_REMAINING`, `CG_SENDCLIENTCOMMAND`; `ui` 66 = renderer 13, suono 4, tasti 9, `UI_LAN_*` 18, filmati 5, parser 5, stato del client, appunti, chiavi CD, `UI_GETGLCONFIG`, `UI_MEMORY_REMAINING`, `UI_VERIFY_CDKEY`.
- **Non fatto in questo giro**: il ponte `BOTLIB_*` (137 trap: la parte grande, handle e numeri verso `IdTech4\BotAi` e `IdTech4\Aas`: fase 2d); `IdTech4\Pmove` non ha trap (il codice di `bg_pmove.c` e' dentro i `.qvm`, che usano `G_TRACE` e `CG_CM_BOXTRACE`, ora serviti).

## 6. Cosa ha fatto la fase 2d (ondata 9, 2026-11-17)

`IdTech4\Q3Host\DelphiDoom.Q3Host.Bot.*` (README e CLAUDE.md della libreria): `be_interface.c`, i `BotImport_*` di `sv_bot.c` e le 132 trap `BOTLIB_*` di `qagame` (non le quattro `PC_*` di sorgente, che nessun modulo chiama). Layout delle strutture sui veri header (`botlayout.golden.txt`); 14 test di layout e 25 di chiamate, Win32 e Win64.

- **Misura** (`reach.bots.golden.txt`): con `bot_enable 1`, `.aas` e BSP veri di `oa_dm1`, `GAME_INIT`, un fotogramma, due `addbot`, 300 fotogrammi con `BOTAI_START_FRAME` prima di `GAME_RUN_FRAME`. **missionpack: 300 fotogrammi fino in fondo, 433006 chiamate di sistema, 332592 BOTLIB (5120 `BOTLIB_UPDATENTITY` ogni 5 fotogrammi, tutte le 1024 entita'), 67 BOTLIB distinte, nessun errore della libreria, Win32 = Win64.** **baseoa: `qagame` carica botlib, mappa, item e istanzia le AI del bot (20 BOTLIB distinte) e poi il QVM si ferma con `OP_BLOCK_COPY not dword aligned` in `ClientUserinfoChanged` del bot**; causa non trovata, aperta.
- `unhandled.golden.txt`: qagame 188 trap registrate su 197; restano 4 `BOTLIB_PC_*`, `TRAP_MATRIXMULTIPLY`, `TRAP_ANGLEVECTORS`, `TRAP_PERPENDICULARVECTOR`, `TRAP_TESTPRINTINT/FLOAT` (questi ultimi due non sono nello `switch` del C). cgame 61 e ui 66 restano come prima.
- **Resta**: il server vero che da' lo snapshot, lo userinfo e i comandi affidabili ai bot (fase 4: oggi `TQ3HostBotServer` e' senza rete e i bot non vedono entita' se nessuno chiama `SetSnapshot`), la causa dello stop di baseoa.
## 6. Cosa ha fatto la fase 2c (ondata 9, 2026-11-17)

Codice e dettagli in `IdTech4\Q3Host` (README e CLAUDE.md); qui i numeri. Provato da `Tests\DelphiDoom.Tests.Q3Host` (148 test, Win32 e Win64) e da gcc sui veri header; nessun gioco avviato.

- **Servite le trap di cgame e di ui del censimento, tranne sei**: stato del client (`CG_GETGAMESTATE`, `CG_GETCURRENTSNAPSHOTNUMBER`, `CG_GETSNAPSHOT`, `CG_GETSERVERCOMMAND`, `CG_GETCURRENTCMDNUMBER`, `CG_GETUSERCMD`, `CG_SETUSERCMDVALUE`, `CG_SENDCLIENTCOMMAND`, `UI_GETCLIENTSTATE`, `UI_GETCONFIGSTRING`), tasti (`*_KEY_*`), parser (`*_PC_*` sopra `TQ3SourceHandles`), suono (`*_S_*`), filmati (`*_CIN_*`, con `TQ3RoqCinematics` sul decoder RoQ), `UI_LAN_*` (le 18), appunti, CD key, `*_UPDATESCREEN`, `*_MEMORY_REMAINING`, `CG_ACOS`, e le trap del renderer (`*_R_*`, `*_GETGLCONFIG`, `CG_CM_MARKFRAGMENTS`, `UI_CM_LERPTAG`) con un renderer che registra le chiamate e da' numeri progressivi.
- **Fin dove arrivano i 12 `.qvm`** (`Tests\Data\Q3Host\reach-client.golden.txt`, file system vero, `oa_dm1`, con un `qagame` che ha fatto `GAME_INIT` e ha passato le sue configstring al client): **tutti arrivano in fondo, nessuna trap senza gestore**. cgame, `CG_INIT` e il primo `CG_DRAW_ACTIVE_FRAME`: baseoa 1293 chiamate di sistema (235 shader, 87 modelli, 1 scena, 53 `DrawStretchPic`, 216 chiamate al suono), missionpack 2900. ui, `UI_INIT`, menu principale e 3 `UI_REFRESH`: baseoa 2210 chiamate (897 `DrawStretchPic`, 3 scene), missionpack 33476 (legge i `.menu` con `PC_*`, 912 `DrawStretchPic`). Win32 e Win64 uguali.
- **Trap che restano** (`unhandled-client.golden.txt`, 6): cgame `CG_CM_LOADMODEL`, `CG_TESTPRINTINT`, `CG_TESTPRINTFLOAT` (non sono nello `switch` del C: "Bad cgame system trap"), `CG_PC_ADD_GLOBAL_DEFINE`; ui `UI_CM_LOADMODEL` (idem) e `UI_PC_ADD_GLOBAL_DEFINE` (il precompilatore non ha `PC_DefineFromString`; nessun `.qvm` la chiama).
- **Senza risposta del C** (dichiarato): `CL_GetSnapshot`, `CL_GetServerCommand`, `LAN_*`, il ping e lo stato dei server (`cl_cgame.c`, `cl_ui.c` e `cl_main.c` includono `client.h`), la CD key, il renderer vero (non c'e'). Hanno risposta del C: i nomi dei tasti, `CG_ACOS` (4222 ingressi) e il layout delle strutture.
- **Da collegare al motore**: il parser dei messaggi del server che riempie `TQ3ClientState` (fase 4), il renderer vero dietro `IQ3HostRenderer` (fase 5), il dispositivo del suono e la musica di sottofondo (fase 6), la rete per i ping e gli stati dei server.
