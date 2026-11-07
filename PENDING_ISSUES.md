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

- `Base\sc_utils.pas` (`SC_Preprocess`) per il solo `vx_base` (VOXELDEF), che appartiene alla fetta voxel della stessa ondata: quando `vx_base` riceve l'`IScriptTextPreprocessor` (per esempio da `VX_ConfigureVoxels`, o con `SC_ParseVoxelDefinition` dentro `TEngineVoxelDefinitionSink`), `sc_utils.pas` si cancella con le sue righe nei 12 `.dpr`.
- I 12 moduli che leggono un testo con `TScriptScanner` (`sc_states`, i quattro `p_mobj` per `spawnmobj`/`summon`, `p_common`, `Hexen\p_anim`, `Hexen\p_mapinfo`, `Hexen\s_sndseq`, `gl_models`, `gl_render`, quattro funzioni di `psi_overlay`) creano il log con `TEngineScannerLog` invece di riceverlo: sono procedure storiche (comandi di console, parser di Hexen, funzioni host di PascalScript). Per riceverlo ognuno dovrebbe diventare una classe (o i parser di Hexen passare a `Libs\Definitions`/`Libs\MapInfo`, circa 1 giorno per parser) e le funzioni di PascalScript un oggetto host registrato: fuori da questa ondata.
- `sc_params` (`TCustomParamList`) riceve il valutatore con `SC_ConfigureParams`: le liste sono create da `DEH_Apply` dei quattro `deh_main` e da `p_common`, procedurali; per passarlo dal costruttore servirebbe portare `DEH_Apply` a classe.
## #136 — Facciate dei dati di gioco rimaste

Cancellate (i chiamanti usano le classi senza stato della libreria): i quattro `p_terrain.pas` (`TTerrainTables.KindForName` da `r_data`), `Base\p_blockmap.pas` (`TBlockmapFactory` da `p_setup`); senza più configurazione `p_gender.pas` (resta solo `gender_t`) e `p_obituaries.pas` (resta `P_Obituary`, logica del motore). Restano facciate, perché i loro servizi hanno dipendenze (log, catalogo dei nomi, ricerca delle texture, sorgenti dei testi, suoni) e i chiamanti sono procedurali:

- `Base\p_udmf.pas`, `Base\p_musinfo.pas` (`P_InitMusInfo`), `Base\p_animdefs.pas` (`P_InitFTAnims`, `P_InitAnimations`, `P_ShutDownAnimations`), `Doom\p_switch.pas` (`P_InitSwitchList`): l'unico chiamante è `P_SetupLevel` di `Base\p_setup.pas` (circa 2000 righe di procedure sui globali del livello). Servirebbe una classe `TLevelLoader` che riceva dal costruttore convertitore UDMF e applicatori, loader MusInfo, parser ANIMDEFS e servizi degli interruttori, e che `G_DoLoadLevel` dei quattro `g_game` riceva dal composition root: una fetta a sé (stima L).
- `P_AnimateSurfaces` (da `p_tick` a ogni tic) e `A_MusicChanger` (azione di stato registrata per puntatore nei quattro `deh_main`): sono procedure chiamate per puntatore o dal ciclo dei tic, servono i dati di modulo; il loro stato (liste delle animazioni, catalogo MusInfo) andrebbe in un oggetto del livello.
- `Base\p_umapinfo.pas` (`U_ParseMapInfo`/`U_FreeMapInfo` da `D_DoomMain` di tre `d_main`): i record `mapentry_t` (`gamemapinfo`, `u_mapinfo`) sono letti da circa 20 moduli (`g_game`, `f_finale`, `p_setup`, `p_enemy`, `p_user`, `wi_stuff`, `st_stuff`, `sb_bar`, `hu_stuff`, `s_sound`, `udmf_spec`, `d_player`); servirebbe un `IMapInfoCatalog` passato a quei moduli al posto dei record.
- `Doom\p_switch.pas` contiene anche `P_UseSpecialLine` e `P_ChangeSwitchTexture` (special di linea e bottoni, legati ai thinker: fase thinker).
## #135 — Facciate di palette e immagini (fase 2, ondata 1)

Cancellate `v_palettes.pas` e `r_grow.pas`; `r_flatinfo.pas` e `mn_screenshot.pas` non sono più facciate (solo tipi e dati del motore). Restano, con il motivo:

- `r_palette.pas`: `R_DefaultPalette` è un servizio con stato (palette letta una volta) chiamato da `r_colormaps`, `r_data` e `r_voxels` (quest'ultimo fuori da questa ondata, voxel). Per toglierla: un `IDefaultPalette` (classe del motore sopra `IPaletteUnpacker` e `V_ReadPalette`) dato da `ComposeEngine` ai tre chiamanti con i loro `*_Configure*`, e `palette_t` spostato in `r_defs`; circa mezza giornata.
- `r_colormaps.pas` e `r_patch.pas`: sono le cache del motore (colormap personalizzate in zone memory lette dal renderer e da `p_saveg`; `fixedcolumns[]` in `PU_LEVEL`), che restano del motore per decisione; chiamano già la libreria.
- `TEnginePaletteGenerator` ha ancora un costruttore senza argomenti perché lo crea `sc_utils.pas` (ondata dello scanner): quando le direttive saranno assemblate da `ComposeEngine` va tolto e il costruttore delle palette passato dal composition root.
## #143 — Facciate dell'audio (fase 2, ondata 2)

Cancellate `Base\i_sound.pas` e `Base\i_music.pas`; `s_pk3sounds` riceve `ITempFiles` (`S_ConfigurePK3Sounds`). Resta `Base\i_tmp.pas`, con chiamanti fuori dall'audio:

- i savegame (`p_saveg` di Doom, Heretic, Strife e `Hexen\sv_save`: lo stato PascalScript della mappa passa da un file temporaneo, `I_NewTempFile`) e `SCRIPT\ps_dll` (una DLL in un PAK copiata su file prima di `LoadLibrary`): procedure storiche senza un oggetto a cui darlo. Servirebbe un `ITempFiles` passato a `G_DoSaveGame`/`G_DoLoadGame` (o un oggetto dello stato degli script di mappa) e alla registrazione delle funzioni di PascalScript; circa mezza giornata, fuori dall'ondata (savegame).
- `DelphiDoom.Engine.Scanner.PaletteGenerator` (creato da `sc_utils`, fetta dello scanner) e `DelphiDoom.Engine.Voxel.SpriteGenerator` (fetta voxel): classi del motore che possono riceverlo dal costruttore quando il loro chiamante è assemblato da `ComposeEngine`; poche righe ciascuna.
- `i_system` (`I_ShutDownTempFiles`) e i quattro `d_main` (`I_InitTempFiles`): il ciclo di vita, resta finché restano i chiamanti sopra.

`s_sound.pas` non è diventato una classe: tiene il player degli effetti, quello della musica e la cache delle musiche esterne ricevuti da `ComposeEngine` (`S_ConfigureSound`, `S_ConfigureMusic`, `S_ConfigureExternalMusic`) e li chiama direttamente. Portarlo a classe vuol dire portare i canali (`channels[]`, `sobjs`) e le circa 40 procedure `S_*` chiamate da tutto il gioco (azioni, thinker, menu, ACS): stima L, fuori dall'ondata.
