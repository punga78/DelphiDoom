# Attività in sospeso

Registro delle issue non completate. Si aggiorna quando una issue viene saltata, quando emergono nuove informazioni e si svuota quando la issue è chiusa.

## Limiti noti del decoder Pascal rispetto al C (non bloccanti)

Il C è stato cancellato (ultimo commit che lo contiene: `a449cacd`). Queste differenze restano documentate in `CLAUDE.md`:

- **Non portati**: ALAC dentro CAF (nessun file di prova nel repository e l'encoder del C andava in access violation), Vorbis con floor di tipo 0 (nessun encoder lo produce), FLAC/Speex/PCM dentro Ogg, scrittura di qualsiasi formato, PVF, NIST, DWD, TXW, REX2 (nel C falliscono sempre). Se serve uno di questi: portarlo da `a449cacd`, costruire i file di prova in memoria e aggiungere gli scenari a `Tests\Data\sound_golden.txt`.
- Vorbis: un `Seek` oltre i dati decodificabili si ferma alla fine dei dati (come il C), ma non si emulano le letture a pezzi di un flusso in catena.
- FLAC: una lettura singola che attraversa un resync e la fine del suono perde l'ultimo frame nel C e non nel Pascal (coperto a pezzi).
- PAF a 24 bit e SDS: il C azzerava l'ultimo pacchetto dopo un `Seek` o a cavallo di due letture (difetto del C), il Pascal no.
- Tag ID3v2: dopo il tag si apre solo FLAC (WAV, AIFF e AU fallivano anche nel C di questa versione).
- Il test di parità non può più generare nuove risposte "dal C": i valori in `Tests\Data\sound_golden.txt` sono fissi.

## #12 — chiusa

Fatta: DD_IDE usa `System.ZLib` (tolti `zlibpas.pas` e i `.obj`), cancellati `C_LIB`, `Libs\Sndfile\Native`, `AUDIOLIB`, `MP3LIB`, `XMILIB`, `MIKWIN` e l'unica unit orfana. `ZLIB` (`z_files.pas`), `SCRIPT` e `FASTCODE` restano perché referenziate (`JPEGLIB` è stata poi sostituita dal decoder a classi di `Libs\Jpeg`). Prova a runtime: Doom, Heretic, Hexen e Strife girano 25 s senza crash né `I_Error` (shareware: i warning sulle patch mancanti sono normali). Non ho potuto ascoltare l'audio.

## #1 — Porting a Delphi 11 (XE11) e build da riga di comando

- **Stato**: issue contenitore ("Stato": Heretic con crash dopo il caricamento del livello, circa 900 warning di conversione tra stringhe). Non è chiudibile dal lavoro sul suono.
- **Domanda per una persona**: va chiusa quando #12 è finita, o resta aperta per i warning e il crash di Heretic?

## #48 — Prova dei percorsi PK3 (texture, voxel, suoni) con un PK3 reale

- **Stato**: aperta (nata dalla chiusura della #46). `w_pak.pas` legge i contenitori con `Libs\Wad` ed è stato provato solo con file sintetici. Mancano texture PNG/TGA/BMP/JPG, voxel e suoni reali (`r_pk3textures`, `vx_voxelsprite`, `s_pk3sounds`) e `HI_START`/`TX_START` con immagini vere. Un PK3 con un "wav" finto da 60 byte non ha fatto generare il WAD dei suoni temporanei: da capire.
- **Informazione mancante**: un PK3 reale (con licenza libera, se deve finire in `Tests\Data`).
- **Prossima azione**: provarlo con `-iwad FREEDOOM2.WAD -pakfile <file>.pk3` su Doom, Heretic, Hexen e Strife.

## Lavoro rimasto dalla chiusura della #46

- **Test a 64 bit di `Libs\Wad`**: dipendono dalla compilazione a 64 bit dell'intero progetto (#40–#44).
- `TEngineWadServices` e `ComposeEngine` non hanno test DUnitX (dipendono da `d_delphi`, che i progetti di test non linkano): sono coperti dall'avvio dei giochi.
## #45 — Motore a classi con dependency injection (conclusa)

Tutte le fette sono collegate al motore e il vecchio codice è cancellato dove c'era un equivalente: Wad, argomenti, configurazione, log, clock, input, video (parte pura), audio, ACS, UDMF, special di linea, scanner, preprocessore e valutatore, MapInfo, MusInfo, ActorDef, Dehacked, definizioni (ANIMDEFS, interruttori di Doom, terreno), palette, texture, console, immagini (parti fredde), MathCore, DynLights, rete, JPEG, texture esterne, modelli 3D e geometria di OpenGL. `Libs\Collision`, `Libs\Geometry` e `Libs\IdLib` (porting da Doom 3) non hanno chiamanti nel motore di id Tech 1: hanno un `WIRING.md` per un uso futuro.

Restano **codice storico, per scelta documentata** in `CLAUDE.md`:

- il renderer software e quello OpenGL (`gl_render`, `gl_main`, `gl_tex`, `gl_sky`, `gl_automap`, `gl_setup`, `gl_slopes`, `gl_lights`, `gl_ambient`, `gl_shadows`, `gl_voxels`, `gl_lightmaps`, il parser MODELDEF di `gl_models`, `mdl_dllmodel`, `mdl_script*`): chiamate per fotogramma, contesto grafico, `screens[]` e zone memory; astrarli richiederebbe un `IRenderer` e non sarebbe verificabile senza contesto;
- i thinker (`vldoor_t`, `floormove_t`…) e i savegame, il cui formato non può cambiare;
- `FixedMul`/`FixedDiv` e le funzioni sugli angoli (percorsi caldi, si rivedono con il 64 bit, #41);
- `V_FindAproxColorIndex`, il melt del wipe, la scala dei muri, le tabelle hi-res, `R_ReadDS32Cache`;
- gli interruttori di Heretic, Hexen e Strife e `Hexen\p_anim.pas`.

Da fare fuori dalla #45: Win64 (#40–#44), prova dei percorsi PK3 (#48), warning del compilatore (circa 800 W1057/W1058/W1024: vedi `logs\REPORT_WARNING.md`), crash intermittente di Heretic.

## #130 — Codice storico senza chiamanti

Cancellate 76 funzioni pubbliche e 117 dichiarazioni (var, const, puntatori) senza usi (analisi statica sui 12 `.dpr`, DD_IDE, DLL e stringhe PascalScript). `FACCIATE.md` elenca le facciate con i chiamanti. Restano di proposito: renderer, `FixedMul`/angoli, `W_*`, `r_clipper` (libreria di terzi), le funzioni usate solo dentro la propria unit (da rendere locali) e quelle con riferimenti omonimi in test o librerie (`BoolToStr`, `IsZeroes`, `parsefirstword`, `A_Fall`, `AngleToFixed`, `FloatMul`, `DEG2RAD`). `Tests.Scanner` ha 19 test che falliscono in questo worktree (i golden letti come una riga sola, line ending dei file): non dipendono da questo lavoro.

## #132 — Facciate dello scanner (in corso)

Cancellate `sc_engine.pas`, `sc_evaluate.pas` e `sc_evaluate_actor.pas`. Resta:

- ~~`Base\sc_utils.pas`~~: cancellata nella #144 (`vx_base` riceve il preprocessore da `VX_ConfigureVoxels`).
- I 12 moduli che leggono un testo con `TScriptScanner` (`sc_states`, i quattro `p_mobj` per `spawnmobj`/`summon`, `p_common`, `Hexen\p_anim`, `Hexen\p_mapinfo`, `Hexen\s_sndseq`, `gl_models`, `gl_render`, quattro funzioni di `psi_overlay`) creano il log con `TEngineScannerLog` invece di riceverlo: sono procedure storiche (comandi di console, parser di Hexen, funzioni host di PascalScript). Per riceverlo ognuno dovrebbe diventare una classe (o i parser di Hexen passare a `Libs\Definitions`/`Libs\MapInfo`, circa 1 giorno per parser) e le funzioni di PascalScript un oggetto host registrato: fuori da questa ondata.
- ~~`sc_params` con `SC_ConfigureParams`~~: fatto nella #144 (`TCustomParamList` riceve il valutatore dal costruttore).

## #144 — Facciate di script e definizioni (fase 2, ondata 2)

Cancellate `Base\sc_actordef.pas`, `Base\sc_defines.pas`, `Base\sc_utils.pas` e `TEngineScriptDefinesSource`; tolti `DEH_Parse`, `DEH_Configure` e `DEH_Apply` dai quattro `deh_main.pas` (ora `TEngineDehackedApplier`, una classe per gioco) e `SC_ConfigureParams` da `sc_params`. Restano, con il motivo:

- `Base\p_acs.pas` (`P_StartACS`, `P_SuspendACS`, `P_TerminateACS`, `P_StartLockedACS`, `P_TagFinished`, `P_PolyobjFinished`, `TH_InterpretACS`, `P_ACSMachine`…): i chiamanti sono gli special di linea (`Hexen\p_spec`, `udmf_spec`), i thinker dei piani (`udmf_floor`, `udmf_ceilng`, `udmf_doors`, `udmf_plats`, `po_man`), `p_enemy`/`p_inter`/`p_map` di Hexen e i salvataggi (`sv_save`, `p_saveg`); `TH_InterpretACS` è il puntatore a funzione di un thinker salvato grezzo, quindi deve restare una procedura. Per togliere la facciata quei moduli dovrebbero ricevere `IAcsMachine` come classi (fase thinker): stima XL. Non toccata in questa ondata (prestazioni e salvataggi invariati per costruzione).
- `deh_main.pas` resta con `DEH_Init`/`DEH_ShutDown` (le tabelle dei nomi e le circa 1900 `DEH_AddAction` dei quattro giochi: sono dati del gioco, non una facciata) e, in Strife, `DEH_GetString` (154 chiamate: la tabella delle stringhe del gioco). Portare `DEH_Init` a dati (una tabella per gioco data al registro delle azioni) è una fetta a sé, stima L.
- `deh_base.pas` resta facciata (`DEH_ParseText`, `DEH_ParseLumpName(s)`, `DEH_ParseFile`, export e azioni): circa 30 chiamanti procedurali (`d_main`, comandi di console, hook di ACTORDEF).
- `sounds.pas` (`S_ConfigureSoundAliases`) e i quattro `d_main` (`D_ConfigureGameDefines`, `D_ConfigureActorDef`) ricevono i servizi con un `*_Configure*` perché sono procedurali (`S_GetSoundNumForName` ha circa 200 chiamanti).
- `P_CheckStateArgs` (`p_common`, chiamata a runtime dalle azioni MBF21 per puntatore) crea liste di soli numeri con valutatore nil: è corretto perché una lista di numeri non chiede mai il valutatore (se succedesse, `I_Error` con la dichiarazione).
- `FACCIATE.md` non è aggiornato da questa issue (è di un'altra fetta della stessa ondata): le righe di `sc_actordef`, `sc_defines`, `sc_utils`, dei quattro `deh_main` (`DEH_Configure`, `DEH_Parse`) e di `sc_params` vanno segnate come tolte.
## #136 — Facciate dei dati di gioco rimaste

Cancellate (i chiamanti usano le classi senza stato della libreria): i quattro `p_terrain.pas` (`TTerrainTables.KindForName` da `r_data`), `Base\p_blockmap.pas` (`TBlockmapFactory` da `p_setup`); senza più configurazione `p_gender.pas` (resta solo `gender_t`) e `p_obituaries.pas` (resta `P_Obituary`, logica del motore). Restano facciate, perché i loro servizi hanno dipendenze (log, catalogo dei nomi, ricerca delle texture, sorgenti dei testi, suoni) e i chiamanti sono procedurali:

- ~~`Base\p_udmf.pas`, `Base\p_musinfo.pas` (`P_InitMusInfo`), `Base\p_animdefs.pas` (`P_InitFTAnims`), `Doom\p_switch.pas` (`P_InitSwitchList`)~~: fatto nella #142 (`TLevelLoader`, vedi sotto).
- `P_AnimateSurfaces` (da `p_tick` a ogni tic) e `A_MusicChanger` (azione di stato registrata per puntatore nei quattro `deh_main`): sono procedure chiamate per puntatore o dal ciclo dei tic, servono i dati di modulo; il loro stato (liste delle animazioni, catalogo MusInfo) andrebbe in un oggetto del livello.
- `Base\p_umapinfo.pas` (`U_ParseMapInfo`/`U_FreeMapInfo` da `D_DoomMain` di tre `d_main`): i record `mapentry_t` (`gamemapinfo`, `u_mapinfo`) sono letti da circa 20 moduli (`g_game`, `f_finale`, `p_setup`, `p_enemy`, `p_user`, `wi_stuff`, `st_stuff`, `sb_bar`, `hu_stuff`, `s_sound`, `udmf_spec`, `d_player`); servirebbe un `IMapInfoCatalog` passato a quei moduli al posto dei record.
- `Doom\p_switch.pas` contiene anche `P_UseSpecialLine` e `P_ChangeSwitchTexture` (special di linea e bottoni, legati ai thinker: fase thinker).
## #142 — Caricamento del livello a classi (fase 2, ondata 2)

Fatto: `P_SetupLevel`, `P_Init` e `P_ShutDown` di `Base\p_setup.pas` sono `TLevelLoader` (`ILevelLoader`), che `ComposeLevel` dà ai quattro `g_game` (`G_ConfigureLevel`) e ai quattro `d_main` (`D_ConfigureLevel`); le parti sono `TEngineLevelMapReader`, `TEngineLevelThings`, `TEngineLevelNodes`, `TEngineLevelBlockmap`, `TEngineUdmfMapLoader`, `TEngineAnimDefsLoader`, `TEngineSwitchListLoader` (Doom), `TEngineVanillaNodes` (Doom) e una classe di regole per gioco (`T<Gioco>LevelRules`). Non hanno più funzioni di facciata: `p_udmf.pas` (solo dati), `nd_main.pas` (record GL, `glnodesver`, `gld_GetGLVertexes`, `gld_BuildNodes`, `ND_RunGlbsp`), `p_setup.pas` (dati del livello, `P_GetMapName`, `P_GetMapTitle`, `P_GameValidThing`). Restano, con il motivo:

- Nessuna unit è stata cancellata: `p_udmf` (record `extra*_t` e variabili `udmf*`), `nd_main` (record GL letti da `gl_setup`/`gl_render`, `gld_BuildNodes` di `-buildnodes` nei `d_main`), `p_animdefs` (`P_AnimateSurfaces` chiamata a ogni tic da `p_tick`, liste lette da `r_data`), `p_musinfo` (`A_MusicChanger`, azione di stato registrata per puntatore, e `P_FindMusinfoMusic`) e `Doom\p_switch` (`P_UseSpecialLine`, `P_ChangeSwitchTexture`) tengono dati o codice della fase thinker. Spostare i dati di `p_udmf` in `p_setup` vorrebbe dire cambiare la `uses` di circa 20 moduli di altri lavori: non fatto (stima S, quando la fase thinker toccherà quei moduli).
- `Base\p_umapinfo.pas` (valutato, non fatto): `U_ParseMapInfo`/`U_FreeMapInfo` sono chiamate dai tre `d_main`, ma i record `mapentry_t` (`gamemapinfo`, `u_mapinfo`, `default_mapinfo`) sono letti da circa 20 moduli procedurali (`g_game`, `f_finale`, `p_enemy`, `p_user`, `wi_stuff`, `in_stuff`, `st_stuff`, `sb_bar`, `hu_stuff`, `s_sound`, `udmf_spec`, `d_player`, `p_setup` per `P_GetMapTitle`). Il caricamento del livello non li usa (solo il titolo della mappa di Heretic). Per toglierla servirebbe dare un `IMapInfoCatalog` (o un oggetto "informazioni della mappa corrente") a ognuno di quei moduli con un `*_Configure*`, e riscrivere le letture dei campi dei record: stima M-L (1-2 giorni), meglio insieme alla fase thinker/HUD.
- Le differenze tra i giochi stanno nelle quattro classi di regole; restano `{$IFDEF}` di gioco solo dove i record del motore sono diversi per costruzione e nelle `uses` (nessuno nel caricamento: `TLevelLoader`, `TEngineLevelMapReader`, `TEngineLevelThings`, `TEngineLevelNodes` hanno solo `{$IFDEF OPENGL}`), e nella scelta delle regole in `ComposeLevelRules`.
- `FACCIATE.md` (di un altro lavoro della stessa ondata) va aggiornato: le sezioni `p_udmf`, `p_musinfo` (`P_InitMusInfo`), `p_animdefs` (`P_InitFTAnims`, `P_ConfigureAnimDefs`), `Doom\p_switch` (`P_InitSwitchList`, `P_ConfigureSwitches`) e `nd_main` (`ND_*`, `gld_GetGLMapLump`, `gld_GetGLNodesVersion`) non hanno più quelle funzioni; il commento di `Base\i_tmp.pas` cita ancora `ND_Configure`.
## #135 — Facciate di palette e immagini (fase 2, ondata 1)

Cancellate `v_palettes.pas` e `r_grow.pas`; `r_flatinfo.pas` e `mn_screenshot.pas` non sono più facciate (solo tipi e dati del motore). Restano, con il motivo:

- `r_palette.pas`: `R_DefaultPalette` è un servizio con stato (palette letta una volta) chiamato da `r_colormaps`, `r_data` e `r_voxels` (quest'ultimo fuori da questa ondata, voxel). Per toglierla: un `IDefaultPalette` (classe del motore sopra `IPaletteUnpacker` e `V_ReadPalette`) dato da `ComposeEngine` ai tre chiamanti con i loro `*_Configure*`, e `palette_t` spostato in `r_defs`; circa mezza giornata.
- `r_colormaps.pas` e `r_patch.pas`: sono le cache del motore (colormap personalizzate in zone memory lette dal renderer e da `p_saveg`; `fixedcolumns[]` in `PU_LEVEL`), che restano del motore per decisione; chiamano già la libreria.
- `TEnginePaletteGenerator` ha ancora un costruttore senza argomenti perché lo crea `sc_utils.pas` (ondata dello scanner): quando le direttive saranno assemblate da `ComposeEngine` va tolto e il costruttore delle palette passato dal composition root.
## #145 — Facciate di console, menu, automap e rete (fase 2, ondata 2)

Tolte come facciate: `c_con.pas` (`TEngineConsoleScreen`), `m_misc.pas` (`TEngineDefaults`, `TEngineScreenshotService`, `TEngineFiles`), `d_net.pas` (`TEngineNetGame`), la parte di modello di `am_map.pas`; cancellate `m_crc32.pas`, `m_sha1.pas` (codice morto), `r_palette.pas` (`TEngineDefaultPalette`), `DelphiDoom.Engine.Input.DirectKeyboard.pas`, `TGlFrustum` (con i suoi test) e `TProcessRunner` (con i suoi test). Restano, con il motivo:

- `c_con.pas`, `m_misc.pas` e `d_net.pas` esistono ancora con i soli dati (opzioni della tabella `defaults` di `m_defs`, `ticdup`, `firstinterpolation`, `S_ERR_DIF_NET`, i testi dei booleani): la tabella dei default tiene l'indirizzo delle variabili e una ventina di moduli le leggono; spostarle in `m_defs` (o in un record di impostazioni) toccherebbe tutti quei moduli senza togliere una dipendenza. Stima: mezza giornata per `c_con`/`m_misc`, un'ora per `d_net`.
- `am_map.pas` resta come disegno dell'automap (`AM_Drawer`, `AM_Responder`, `AM_Ticker`, `AM_Start/Stop`, chiamati per fotogramma e per tasto da `d_main`, `g_game`, `gl_main`, `p_inter`, `in_stuff`...): portarlo a una classe `TEngineAutomapScreen` come la console vuol dire circa 2000 righe di disegno a puntatori e i suoi globali (`amstate`, `f_x/f_y/f_w/f_h`, `fb`, colori) letti da `gl_automap` e `am_textured`. Stima: 1-2 giorni, con il confronto dei fotogrammi disegnati (harness di impronte di `screens[]`).
- `c_cmds.pas` (`C_AddCmd`, circa 300 chiamate) non era in questa ondata: ogni modulo dovrebbe ricevere `ICommandRegistry`.
- La tabella `TCheatTable` e `TCheatSequenceReader` di `Libs\Console` restano nella libreria senza chiamanti nel motore (già documentato come "non collegato"); tolte dai 12 `.dpr` insieme a `DelphiDoom.Logging.Recorder` (serve solo ai test).
- `i_net.pas` resta: legge la riga di comando della rete per `TEngineNetGame.Start`.
- Non verificati a runtime: il disegno dell'automap testurizzato (`am_textured` riceve la finestra come parametro: stessa aritmetica per costruzione), la rete con due macchine, gli screenshot da tasto e da `-shot` (stesso codice spostato nella classe), i salvataggi di Strife e Hexen con `TEngineFiles` (stesso codice).
## #143 — Facciate dell'audio (fase 2, ondata 2)

Cancellate `Base\i_sound.pas` e `Base\i_music.pas`; `s_pk3sounds` riceve `ITempFiles` (`S_ConfigurePK3Sounds`). Resta `Base\i_tmp.pas`, con chiamanti fuori dall'audio:

- i savegame (`p_saveg` di Doom, Heretic, Strife e `Hexen\sv_save`: lo stato PascalScript della mappa passa da un file temporaneo, `I_NewTempFile`) e `SCRIPT\ps_dll` (una DLL in un PAK copiata su file prima di `LoadLibrary`): procedure storiche senza un oggetto a cui darlo. Servirebbe un `ITempFiles` passato a `G_DoSaveGame`/`G_DoLoadGame` (o un oggetto dello stato degli script di mappa) e alla registrazione delle funzioni di PascalScript; circa mezza giornata, fuori dall'ondata (savegame).
- `DelphiDoom.Engine.Scanner.PaletteGenerator` (creato da `sc_utils`, fetta dello scanner) e `DelphiDoom.Engine.Voxel.SpriteGenerator` (fetta voxel): classi del motore che possono riceverlo dal costruttore quando il loro chiamante è assemblato da `ComposeEngine`; poche righe ciascuna.
- `i_system` (`I_ShutDownTempFiles`) e i quattro `d_main` (`I_InitTempFiles`): il ciclo di vita, resta finché restano i chiamanti sopra.

`s_sound.pas` non è diventato una classe: tiene il player degli effetti, quello della musica e la cache delle musiche esterne ricevuti da `ComposeEngine` (`S_ConfigureSound`, `S_ConfigureMusic`, `S_ConfigureExternalMusic`) e li chiama direttamente. Portarlo a classe vuol dire portare i canali (`channels[]`, `sobjs`) e le circa 40 procedure `S_*` chiamate da tutto il gioco (azioni, thinker, menu, ACS): stima L, fuori dall'ondata.

## #150 - Facciate di servizio m_argv, c_cmds, m_rnd (parziale)

Fatto (non compilato ne' provato dall'agente: vedi `RUN.md`): le classi del motore ricevono `ICommandLine`, `ISaveFileNames`, `ICommandRegistry` e `IGameRandom` dal costruttore (elenco in `CLAUDE.md`, paragrafo `Libs\CommandLine`); `C_BoolEval` e `C_GetMachingList` cancellate (23 chiamate passano a `TConsoleNumbers.EvaluateBoolean`); `M_CmdShowCmdline`/`M_CmdShowCommandLineParams` e `cmdparams` di `m_argv` spostati in `TEngineConsoleScreen`/`TQueriedCommandLine`. Restano, con il motivo:

- `m_argv.pas`: circa 380 chiamate a `M_CheckParm` e 69 a `M_SaveFileName` in moduli procedurali (`d_main` x4 con circa 90 ciascuno, `g_game`, `i_*`, `r_*`...), piu' `myargv`/`myargc` letti direttamente. Servirebbe che ogni modulo ricevesse un `ICommandLine` con un `*_Configure*` (o diventasse classe). Stima L.
- `c_cmds.pas`: circa 280 `C_AddCmd` in moduli procedurali, registrati dentro procedure di init con puntatori a procedure con firme diverse (anche `G_LoadGame(slot: integer)` di Hexen, registrato con stringhe: difetto latente conservato) e `C_ExecuteCmd` (34 chiamate). Servirebbe un wrapper per comando con la firma giusta e `ICommandRegistry` per ogni modulo. Anche i comandi di gioco di `TEngineConsoleScreen` (`screenshot`, `playdemo`, `start`, `load`, `save`, `testmap`) usano ancora `C_AddCmd`. Stima XL.
- `m_rnd.pas`: `P_Random` (circa 950 chiamate nei thinker), `N_Random`, `M_Random`, `C_Random`, `I_Random`, `P_SaveRandom`/`P_RestoreRandom`, indici di g_game/g_demo: fase thinker, serie e ordine non si toccano. `TEngineScannerActorFunctions` (`Sys_Random`, `N_Random`, `P_Random`: soli `class function`, nessuna istanza) richiederebbe istanze al posto degli static (circa 60 funzioni): stima S-M. `M_Random` di menu e audio (14 chiamate) e' in moduli procedurali.


## #146 — Facciate di texture e PAK (fase 2, ondata 2)

Cancellate `TEXLIB\t_main.pas` (`TTexture` passa a `Base\DelphiDoom.Engine.Texture.Item.pas`, la ricerca dei file a `TEngineTextureFiles` dietro `IEngineTextureFiles`, che `ComposeTexture` dà a `t_draw`, `w_sprite`, `r_pk3textures`, `r_cache_flats`/`r_cache_walls` e `gl_tex`) e `TEXLIB\t_detect.pas` (i controlli chiamano `Libs\Texture` direttamente). Le regole dei percorsi PAK sono in `Libs\Wad` (`TPakIndex`, `TPakPathResolver`, `TPakNames`) e il file system è `TPakFileSystem` (riceve `IEngineWadServices`). I colori del sangue sono `TTranslationBlood` (statica), chiamata da `TEngineDehackedApplier` dei quattro giochi. Restano, con il motivo:

- `Base\w_pak.pas` (`TPakStream`, `PAK_*`): è l'API procedurale per 23 moduli (dopo il merge di #142–#145). Procedure storiche: `D_DoomMain` dei quattro `d_main` (`PAK_InitFileSystem`, `PAK_AddFile` per `-file`/`-pakfile`/autoload, `PAK_LoadPendingPaks`, `PAK_GetDirectoryListFromString`), `w_wad` (WAD dentro un PAK), `deh_base`, `vx_base`, `gl_models` (testi DEHACKED, VOXELDEF, MODELDEF), `s_sound`, `s_pk3sounds` (musiche e suoni dei PK3), `p_simpledialog`, `mdl_md2`, `mdl_ddmodel`, `ps_main`, `ps_import`, `ps_dll` (PascalScript). Otto sono classi del motore che prenderebbero `IPakFileSystem` dal costruttore con poche righe ciascuna: `TEngineAcsSourceProvider`, `TEngineActorDefHooks`, `TEngineActorDefLumps`, `TEngineIncludeSource`, `TEngineMapInfoTextSource`, `TSoundLibrary`, `TEngineSfxSampleSource`, `TEngineExternalMusicSource` (non toccate qui perché nelle aree delle altre issue della stessa ondata). Per togliere la facciata: quelle classi dal costruttore (circa 2 ore), un `*_Configure` con `IPakFileSystem` per ognuno dei moduli procedurali (circa mezza giornata) e `D_DoomMain` con `IPakContainers`; stima M.
- `Base\r_translations.pas`: tiene la cache delle tabelle di traduzione (slot di `ITranslationNames`, tabelle in `PU_STATIC`) che `R_InitMobjTranslation` e `R_SetMobjBloodTranslation` riempiono per ogni mobj: le chiamano `p_mobj`, `p_map`, `p_saveg`/`sv_save` dei quattro giochi, `p_common` e `psi_game` (thinker, salvataggi, funzioni di PascalScript). Per toglierla: una classe `TEngineTranslationTables` (nomi, file system PAK, lump) data a quei moduli; è codice dei thinker, quindi va con la fase dei thinker (stima mezza giornata più la verifica dei salvataggi).
- `Base\r_data.pas`, parte fredda: `R_InitTextures`, `R_InitFlats`, `R_InitSpriteLumps` e `R_InitColormaps` scrivono una ventina di tabelle di `r_data` (`textures[]`, `texturecolumnlump`, `texturecolumnofs`, `texturecomposite`, `flats[]`, `spritewidth`…) che il renderer legge per colonna e per span, e chiamano `R_GenerateLookup`. Una classe che le inizializzi o possiede quelle tabelle (e il renderer, percorso caldo, le legge da lei) o scrive i globali di `r_data` (una facciata rovesciata). Restano quindi `R_ConfigureTextureDefs`, `R_ConfigureFlatInfo` (ora con `IPakFileSystem`: `r_data` non usa più `w_pak`), `R_ConfigureColormaps`, `R_ConfigureComposite`, `R_ConfigureVoxelSprites`, `R_ConfigureNameHash`. Per toglierli serve prima un `IRenderTextures` che possieda le tabelle (insieme al renderer): stima L.
- **Difetti trovati, conservati** (parità): `PAK_AddFile` di una cartella diversa da quella corrente non aggiunge i suoi file (`findfiles` di `d_delphi` dà i nomi senza cartella e `AddContainer` li cerca nella cartella corrente); `R_GetTranslationTable` di un nome sconosciuto di 6 o più caratteri prova il lump `CR_` + nome, che supera 8 caratteri, e `stringtochar8` dà un `I_Error` (`CR_NOSUCH`): basta una cosa con `translation` sconosciuta per fermare il gioco. Anche `usepk3textures` non fa mai nulla: `R_AddTextureFileName` di `r_pk3textures` confronta `name + '.' + ext` con il nome, ma `fext` dà l'estensione con il punto (`'NEWTEX1..PNG'`), quindi nessuna texture del PK3 entra nell'elenco e i file di cache `pk3tex_*`/`pk3flat_*` non vengono mai scritti (verificato con un PK3 di prova sul vecchio e sul nuovo eseguibile). Ognuno va corretto con un test sul nuovo comportamento.
