# Doom 3: dalle librerie a un eseguibile che parte (issue #255)

Censimento dei moduli del C++ (`Reference\doom3\neo`, righe contate il 2026-11-17 su `.cpp` e `.h`), cosa e' gia' stato portato (verificato con `grep` sulle unit di `Framework\` e `IdTech4\`, non a memoria), cosa manca per un eseguibile `Doom3` che carica una mappa **senza renderer** (caricamento di mappa e dichiarazioni, entita' e classi del gioco, script, rete, `idCommon` e `idSys` di sistema), e le fasi con dipendenze. Modello: `docs\QUAKE3_CENSIMENTO.md`.

**Licenza** (decisa dall'utente il 2026-11-17): le unit derivate da Doom 3 dichiarano GPL v3 o successive con gli "Additional Terms" di `Reference\doom3\COPYING.txt` (avvisi di marchio e di copyright, manleva); il motore di Doom resta GPL v2 o successiva. L'intestazione e' in testa a ogni unit della libreria nuova (`IdTech4\D3Host`).

**Dati del gioco: non ci sono.** `Reference\doom3` e' solo il sorgente (`README.txt`: "does not contain any game data"); nessun `pak000.pk4` in `Reference\` ne' altrove sul disco (cercato il 2026-11-17). Quindi **"far eseguire a DoomScript il `main` di un livello caricato con i dati veri" non si puo' provare in questa tornata**; vedi la fase 5c con mappa e script sintetici. I dati commerciali sono dell'utente e non vanno mai nel repository.

## 1. Moduli del C++ -> librerie nostre

| Modulo C++ | Righe | Libreria | Stato |
|---|---:|---|---|
| `idlib` matematica, geometria, bv, hashing | ~77.500 | `Framework\IdLib`, `MathCore`, `Geometry` | fatto (vettori, matrici, quaternioni, piani, bounds, winding, polytope, CRC, MD4) |
| `idlib` testo e contenitori | ~22.600 | `Framework\IdLib` (`Str`, `Token`, `Lexer`, `CmdArgs`, `Dict`, `List`, `HashIndex`...) | fatto |
| `framework` compressione (`Compressor`) | 2.576 | `Framework\Compression` | fatto (#98) |
| `framework` `FileSystem`, `File`, `Unzip` | ~10.000 | `Framework\Wad` (`Wad.Fs.*`, #99, #236) | fatto: pk4 in lettura e scrittura, pak pure, restart checksums, `.dll` pak; residui senza oracolo in #251 |
| `framework` `CmdSystem`, `CVarSystem` | ~2.000 | `Framework\Console` (profilo id Tech 4, #113) | fatto, parita' sul C++ |
| `framework` `DeclManager` e tipi (`table`, `skin`, `entityDef`, `pda`, `fx`, `particle`, `af`, `material`) | ~8.500 | `IdTech4\Decl` (#100, #102) | fatto in gran parte (vedi CLAUDE.md della libreria per `af`/`particle`/`fx`) |
| `framework` `EditField`, `KeyInput`, `UsercmdGen`, `Console`, `DemoFile` | ~4.700 | -- | **manca** (`Console.Q3.Field` e' il campo di Quake III, non e' lo stesso testo) |
| `framework` **`Common`**, `EventLoop` | 3.375 | **`IdTech4\D3Host` (questo giro)** | messaggi, avvisi, errori, riga di comando, ciclo degli eventi: fatti; `Init`/`Frame`/`Async`/`InitGame`: mancano |
| `framework` `Session`, `Session_menu`, `Licensee` | ~5.000 | -- | manca |
| `framework/async` (server, client, canale di messaggi, scansione) | 8.448 | `IdTech1\Net` (`idBitMsg`, #98), `Framework\NetTransport` | solo i messaggi a bit e il trasporto UDP; manca tutto il protocollo (`MsgChannel`, `AsyncServer`, `AsyncClient`) |
| `cm` (collisione) | 9.258 | `IdTech4\Collision` (#108) | fatto |
| `game/script` | 9.974 | `IdTech4\DoomScript` (#110) | fatto: compilatore, programma, interprete, thread, eventi; **gli eventi di mondo di `idThread` sono dichiarati ma non collegati** (servono entita' e mondo) |
| `game/anim` | 8.311 | `Framework\Models` (`Models.Anim.*`, MD5, #104) | in gran parte (`idAnimBlend`, `idAnimator`, `idDeclModelDef`) |
| `game/ai` | 13.353 | `IdTech4\Aas` (navigazione AAS di Doom 3, #109) | solo la navigazione; manca l'IA (`AI.cpp`, `AI_events.cpp`, `AI_Vagary`...) |
| `game/gamesys` (`Class`, `Event`, `SysCmds`, `SysCvar`, `SaveGame`, `TypeInfo`) | 11.558 | `IdTech4\DoomScript` (`Event`, parte di `Class`) | solo gli eventi e il minimo di `idClass`; manca la riflessione completa (`idTypeInfo`, spawn per nome), `SaveGame`, `SysCmds` |
| `game/physics` (`Clip`, `Physics_*`, `Force_*`) | 24.069 | -- | **manca** (la parte piu' pesante dopo le entita': `idClip` sta sopra `IdTech4\Collision`) |
| `game` radice (`Entity`, `Player`, `Actor`, `Weapon`, `Mover`, `Item`, `Trigger`, `Target`, `Light`, `Camera`, `Misc`, `Projectile`, `AF*`, `Game_local`, `Pvs`...) | 68.260 | -- | **manca**: nessuna entita' |
| `d3xp` (Resurrection of Evil) | 147.572 | -- | fuori: e' una seconda copia estesa di `game`; si sceglie `game` (Doom 3 base) |
| `sound` | 8.486 (+ OggVorbis) | `Framework\Audio`, `AudioMix`, `Framework\Sound` | solo mixer e decodifica; manca il mondo del suono (`idSoundWorld`, `idSoundEmitter`, `idSoundSystem`) |
| `renderer` | 74.533 | `IdTech4\Decl` (materiali), `IdTech4\MapFile` (`.proc`, #107), `Framework\Models`, `Jpeg`, `Png`, `Cinematic` (RoQ) | circa 15%: manca il `RenderWorld` (portali, `.proc` caricato), frontend e backend ARB2 |
| `ui` (GUI `.gui`) | 19.331 | `IdTech4\Gui` (#111) | fatto, senza collegamento al motore |
| `sys` (`win32`, `linux`, `osx`) | ~20.100 | `Framework\GameHost`, `Platform`, `Input`, `Clock` | sostituibile; non si porta |
| `tools` (`Radiant`, `GUIed`, `MayaImport`...) | 134.472 | -- | fuori (nessun eseguibile di gioco li usa) |

Totale del C++ necessario per un `Doom3` giocabile: `idlib`+`framework`+`cm`+`game`+`sound`+`renderer`+`ui` circa 400.000 righe; di queste **circa 160.000 sono gia' portate**, circa 240.000 mancano, di cui 135.000 sono `game`.

## 2. Cosa manca per un eseguibile che parte senza renderer

1. **`idCommon`**: stampa, avvisi, errori (la regola "senza OpenGL ogni `Error` e' fatale"), riga di comando a `+`, ciclo degli eventi, poi `Init`, `Frame`, `Async`, `InitGame` (fase 1 e 2).
2. **Sessione** (`idSessionLocal`): macchina a stati menu/gioco/caricamento, `usercmd`, tasti, console, campo di testo (fase 2).
3. **Collegamento tra librerie gia' fatte** (fase 3): file system + cvar + comandi + dichiarazioni + `.map`/`.proc` + collisione dietro le interfacce di `idCommon`, nel composition root; programma `Doom3` in modalita' `-headless`.
4. **Il gioco** (fase 4, la piu' lunga): `idClass`/`idTypeInfo` con spawn per nome, `idEntity` e le sue sottoclassi, `idGameLocal` (spawn della mappa, ciclo `RunFrame`), `idClip` e la fisica, il giocatore (`usercmd` -> movimento), IA, armi, mover, trigger, salvataggi, PVS.
5. **Script collegati alle entita'** (fase 5): gli eventi di mondo di `idThread`, `main()` della mappa. Con i dati veri; senza, con una mappa e script sintetici.
6. **Rete** (`async`) e **suono** (mondo del suono) senza dispositivo; **renderer** per ultimo (fuori dalla definizione "senza renderer").
7. **Programma `Doom3`**: composition root, `Tools\build.bat`, opzioni `-headless`, `-script`, `-shot`.

## 3. Fasi

| Fase | Contenuto | Dipende da | Stima | Stato |
|---|---|---|---|---|
| 1 | **`idCommon` base e ciclo degli eventi**: `Printf`/`DPrintf`/`Warning`/`DWarning`, redirect, file di log, elenco avvisi (`PrintWarnings`, `DumpWarnings`), `Error`/`FatalError` con le regole di ricorsione, tempesta e renderer assente, riga di comando (`ParseCommandLine`, `SafeMode`, `StartupVariable`, `AddStartupCommands`, `CheckToolMode`), `idEventLoop` con il diario | `IdLib`, `Console`, `Clock` | 1 ondata | **fatta (questo giro)**: `IdTech4\D3Host`, parita' sul C++ |
| 2a | `idKeyInput`, `idEditField`, `idUsercmdGen` (senza dispositivi: eventi dati dall'esterno), `idConsole` (testo, storia, completamento) | 1, `Input` | 1 ondata | da fare |
| 2b | `idCommonLocal::Init`/`Shutdown`/`Frame`/`Async`/`SingleAsyncTic`/`GUIFrame`/`InitGame`: composizione dei sistemi, `com_ticNumber`, `com_frameTime`, scrittura della configurazione | 1, 2a | 1 ondata | da fare |
| 2c | `idSessionLocal` senza menu (`Session.cpp`: stati, caricamento mappa, `MapLoad`, `ExecuteMapChange`, `Frame`, `Stop`) | 2b, `Decl`, `MapFile` | 1-2 ondate | da fare |
| 3 | Programma `Doom3 -headless`: composition root che collega `Wad.Fs`, `Console`, `Decl`, `MapFile`, `Collision` ai contratti di `D3Host`; `-script` per comandi; nessun gioco: solo avvio, `map`, uscita | 2b, 2c | 1 ondata | da fare |
| 4a | `idClass`/`idTypeInfo` completi, `idEntity` base, `idGameLocal` (spawn delle entita' della mappa, `RunFrame`, `SysCvar`), `idClip` | `Collision`, `DoomScript`, 3 | 2-3 ondate | da fare |
| 4b | Fisica (`Physics_Base`, `Static`, `StaticMulti`, `Parametric`, `RigidBody`, `Player`, `Monster`, `Actor`, `AF`), forze | 4a | 3-4 ondate | da fare |
| 4c | Entita' di mondo: `Mover`, `Trigger`, `Target`, `Light`, `Camera`, `Item`, `Misc`, `Moveable`, `Fx`, `Sound`, `WorldSpawn`, `Pvs` | 4a, 4b | 3 ondate | da fare |
| 4d | Giocatore, armi, proiettili, danno | 4c | 3 ondate | da fare |
| 4e | IA (`AI*`, `Actor`), animazioni sul modello (`Anim_Blend` e' gia' in `Models`) | 4c, `Aas`, `Models` | 4-5 ondate | da fare |
| 4f | Salvataggi (`SaveGame`), `SysCmds`, PVS | 4a-4e | 2 ondate | da fare |
| 5a | Eventi di mondo di `idThread` collegati alle entita' | 4c, `DoomScript` | 1 ondata | da fare |
| 5b | `main()` di una mappa: `idThread` su `<mappa>::main` | 5a | 1 ondata | da fare |
| 5c | **Prova senza dati veri**: mappa `.map` sintetica e script `doom_main.script` + `maps\<x>.script` scritti per i test, `main` eseguito da `DoomScript` dentro `D3Host`, parita' con lo stesso scenario sul C++ vero | 5b | 1 ondata | da fare; **con i dati veri solo l'utente puo' provare** |
| 6 | Rete: `MsgChannel`, `AsyncServer`, `AsyncClient`, snapshot (`Game_network`) | 4a, `NetTransport` | 3-4 ondate | da fare |
| 7 | Suono: `idSoundWorld`, `idSoundEmitter`, `idSoundSystem` sopra `Audio`/`AudioMix` | `Audio` | 2 ondate | da fare |
| 8 | Renderer: `RenderWorld` (`.proc`, portali), frontend (cull, interazioni, ombre), backend ARB2 su `OpenGlBinding`, modelli LWO/ASE, particelle, decal, GUI 2D | `Decl`, `MapFile`, `Models`, `OpenGlBinding` | 8-12 ondate | da fare |
| 9 | Programma `Doom3` completo, opzioni, `Tools\build.bat`, groupproj | 3-8 | 1 ondata | da fare |
| 10 | Prove: avvio, menu, un livello, esecuzioni senza finestra, a macchina scarica | 9, **dati dell'utente** | 1 ondata | da fare |

Ordine di grandezza: **25-40 ondate da 5 agenti** (come scrive l'issue). Il grosso e' la fase 4 (circa 135.000 righe di `game`) e il renderer. Rischi: nessun dato con cui provare (fase 5c e 10), parita' dell'x87 nelle simulazioni di fisica (tolleranza dichiarata, come per Pmove), `idClip` e la fisica senza oracolo se non si compila `game` intero con `bcc32c` (rischio alto: `game` include l'intero motore; la parita' si fa per sottosistema con driver e finti, come per `DoomScript`).

## 4. Cosa ha fatto la fase 1 (2026-11-17)

Libreria `IdTech4\D3Host`, unit `DelphiDoom.D3Host.*`; dettagli, mappa C++ -> Pascal, decisioni e parita' in `IdTech4\D3Host\CLAUDE.md` e `README.md`. Nessun gioco avviato.

- **Messaggi** (`Common.cpp`: `VPrintf`, `Printf`, `DPrintf`, `Warning`, `DWarning`, `BeginRedirect`, `EndRedirect`, `CloseLogFile`, `SetRefreshOnPrint`).
- **Avvisi** (`PrintWarnings`, `ClearWarnings`, `DumpWarnings`, il tetto di 256).
- **Errori** (`Error`, `FatalError`): la regola "senza OpenGL ogni `Error` e' fatale" e' una dipendenza iniettata (`ID3RenderState`), non una scelta; senza renderer un eseguibile `-headless` non vedra' mai `ERP_DROP` a meno di dichiararlo.
- **Riga di comando** (`ParseCommandLine`, `ClearCommandLine`, `SafeMode`, `CheckToolMode`, `StartupVariable`, `AddStartupCommands`).
- **Ciclo degli eventi** (`EventLoop.cpp`): coda di 256 eventi, diario (`com_journal` 1 e 2), `GetEvent`, `PushEvent`, `ProcessEvent`, `RunEventLoop`, `Milliseconds`.
- **Parita'**: `Tools\Verifica\255` compila con `bcc32c` il vero `EventLoop.cpp` e i corpi veri delle funzioni di `Common.cpp` (estratti dal sorgente al momento della costruzione, mai copiati nel repository) con finti di sistema; golden in `Tests\Data\D3Host`.
