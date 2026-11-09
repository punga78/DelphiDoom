# Facciate storiche e chiamanti (issue #130, aggiornato dopo le ondate 3 e 4)

Aggiornato dalla #163: tolte le routine senza alcun riferimento (13 righe delle tabelle e le voci corrispondenti delle sezioni in fondo); il resto e invariato.

Elenco delle unit storiche che erano facciate (hanno una `*_Configure*` o sono citate in `CLAUDE.md` come facciata sopra una libreria di `Libs\`), con le funzioni pubbliche e i loro chiamanti. Serve a decidere quali migrare a mano. Rigenerato dal sorgente (master 0f6ff81c) dopo le ondate 1 (#132-#137), 2 (#145) e 3-4 (#142-#144, #146, #148-#156, #41, #48, #83) della fase 2: le unit tolte restano nell'elenco con la nota di chi ne ha preso il posto; dalle ondate 3 e 4 sono entrate le facciate dei thinker (luci, porte, pavimenti, soffitti, piattaforme, teletrasporti), dei thread (`i_threads`, `mt_utils`) e del midi stream (`i_midi_new`). Il conteggio e stato rifatto con uno script che, applicato al commit 094a89bd, riproduce le tabelle del file precedente (572 righe su 573 uguali: `I_Warning` dava una chiamata in meno).

**Come leggerlo**
- Le unit sono ordinate per numero totale di chiamate crescente (prima quelle cancellate o senza funzioni pubbliche); dentro ogni unit le funzioni sono ordinate per chiamate crescente.
- "Chiamate" e il numero di occorrenze del nome in codice (commenti esclusi, stringhe incluse: copre `ps_import` e le registrazioni per nome) nei file che compilano insieme alla unit (le unit di un gioco non contano i file degli altri giochi), esclusi la unit stessa, `Libs\` e `Tests\` (contano anche i file `.inc`, `DD_IDE\`, `Launcher\` e i `.dpr`, questi ultimi come "n .dpr"). Una voce `DelphiDoom.Engine.Composition` e il cablaggio (`*_Configure*`), non un chiamante di dominio.
- "[test: n]" sono i riferimenti nei test (di solito nomi omonimi: non sono chiamanti).
- Le unit `w_wadreader.pas` e `w_wadwriter.pas` hanno solo classi (`TWadReader`, `TWadWriter`), nessuna funzione: per toglierle i chiamanti (`w_pak`, `r_data`, `vx_*`, `s_pk3sounds`) dovrebbero usare `IWadDirectory` e `IWadBuilder`.
- Il conteggio e statico, non sostituisce una lettura del chiamante.

### `Base\sc_evaluate.pas` - cancellata

**Tolta (#132)**: nessun chiamante (DD_IDE non la usava); `TEvaluator` non esiste piu.

### `Base\i_exec.pas` - cancellata

**Tolta (#133)**: `I_ExecProgram` non aveva chiamanti; dalla #145 non c'e piu nemmeno `TProcessRunner` in `Libs\Platform`.

### `OPENGL\gl_frustum.pas` - cancellata

**Tolta (#134)**: i piani del frustum non li leggeva nessuno; dalla #145 non c'e piu nemmeno `TGlFrustum` in `Libs\GlMath`.

### `Base\vx_voxelsprite.pas` - cancellata

**Tolta (#134)**: gli sprite dei voxel li scrive `TEngineVoxelSpriteGenerator` (`IEngineVoxelSprites`), dato da `ComposeEngine` a `r_data`.

### `Base\v_palettes.pas` - cancellata

**Tolta (#135)**: `#CREATEPALETTE` (`TEnginePaletteGenerator`) usa `IPaletteBuilder` di `Libs\Palette`.

### `OPENGL\mdl_base.pas` - nessuna funzione pubblica

**Non piu facciata (#134)**: resta solo con i tipi dei modelli.

### `Base\m_sha1.pas` - cancellata

**Tolta (#145)**: codice morto, l'ultimo chiamante (`vx_voxelsprite`) era stato cancellato dalla #134; chi calcola uno SHA-1 usa `TSha1` di `Libs\MathCore`.

### `Base\m_bbox.pas` - cancellata

**Tolta (#133)**: i chiamanti usano `TBoundingBoxMath` di `Libs\MathCore`.

### `Base\r_flatinfo.pas` - nessuna funzione pubblica

**Non piu facciata (#135)**: restano i tipi e i dati del motore.

### `Base\s_externalmusic.pas` - cancellata

**Tolta (issue #137)**: `s_sound` riceve `IExternalMusicCache` (`S_ConfigureExternalMusic`).

### `Base\r_palette.pas` - cancellata

**Tolta (#145)**: non era codice morto (`r_colormaps`, `r_data` e `r_voxels` la chiamavano): la palette di base e `TEngineDefaultPalette` (`IEngineDefaultPalette`), data da `ComposeEngine` a `R_ConfigureColormaps`, `R_ConfigureCustomColormaps` e `R_ConfigureVoxelPalette`.

### `Heretic\p_terrain.pas` - cancellata

**Tolta (#136)**: `r_data` chiama `TTerrainTables.KindForName` (statica).

### `Doom\p_terrain.pas` - cancellata

**Tolta (#136)**: `r_data` chiama `TTerrainTables.KindForName` (statica).

### `Base\p_blockmap.pas` - cancellata

**Tolta (#136)**: `p_setup` usa `TBlockmapFactory`.

### `Hexen\p_terrain.pas` - cancellata

**Tolta (#136)**: `r_data` chiama `TTerrainTables.KindForName` (statica).

### `Base\mn_screenshot.pas` - nessuna funzione pubblica

**Non piu facciata (#135)**: resta il record `menuscreenbuffer_t` del savegame; la miniatura e di `Libs\Imaging`.

### `Base\r_grow.pas` - cancellata

**Tolta (#135)**: `r_cache_flats` riceve `IImagingSpanGrower` (`R_ConfigureFlatCache`).

### `Base\i_mp3.pas` - cancellata

**Tolta (issue #137)**: `TMp3MusicBackend` riceve `IMp3` dal costruttore e tiene il proprio `TMp3Player`.

### `Base\sc_evaluate_actor.pas` - cancellata

**Tolta (#132)**: `TContextExpressionEvaluator` (`Libs\Scanner`) con `TEngineActorExpressionFunctions` e `TEngineActorExpressionVariables`, dato da `ComposeEngine` a `SC_ConfigureParams` di `sc_params`.

### `Base\w_autoload.pas` - cancellata

**Tolta (issue #137)**: i quattro `d_main` ricevono `IAutoLoadReader` (`D_ConfigureAutoLoad`).

### `Base\sc_engine.pas` - cancellata

**Tolta (#132)**: i chiamanti usano `TScriptScanner` e `TScannerText` di `Libs\Scanner`.

### `Strife\p_terrain.pas` - cancellata

**Tolta (#136)**: `r_data` chiama `TTerrainTables.KindForName` (statica).

### `Base\m_hash.pas` - cancellata

**Tolta (#133)**: `r_data` riceve `IStringHashTable` (`R_ConfigureNameHash`).

### `Base\m_vectors.pas` - cancellata

**Tolta (#133)**: i chiamanti usano `TVectorMath` di `Libs\MathCore`.

### `Base\p_gender.pas` - nessuna funzione pubblica

**Non piu facciata (#136)**: resta solo il tipo `gender_t`.

### `Base\i_displaymodes.pas` - cancellata

**Tolta (issue #137)**: `i_video`, `gl_main` e i quattro `m_menu` ricevono `IDisplayModeCatalog`.

### `Base\m_crc32.pas` - cancellata

**Tolta (#145)**: l'ultimo chiamante, `p_udmf`, chiama `W_LumpCRC32` (stessa funzione: `GetLumpCRC32` la richiamava e basta).

### `Base\i_input.pas` - cancellata

**Tolta (issue #137)**: un solo `IInputPoller` dato a `i_system`, `i_main`/`gl_main` e ai quattro `g_game`.

### `Base\e_endoom.pas` - cancellata

**Tolta (issue #137)**: `IEngineEndoomScreen` (`TEngineEndoomScreen`) dato a `d_main`, `g_game` e `gl_main`; dalla #145 il suo tic lo fa `TEngineNetGame`.

### `Base\c_con.pas` - nessuna funzione pubblica

**Tolta come facciata (#145)**: la console e `TEngineConsoleScreen` (`IEngineConsole`), data da `ComposeEngine` a `d_main`, `gl_main`, `v_displaymode`, `p_tick`, `p_common`, `psi_system` e al ciclo della rete; l'unit resta con le sole opzioni (`ConsoleColormap`, `mirror_stdout`, `autoexecfile`, `DEFAUTOEXEC`), lette dalla tabella dei default.

### `Base\d_net.pas` - nessuna funzione pubblica

**Tolta come facciata (#145)**: il ciclo della rete e `TEngineNetGame` (`IEngineNetGame`), dato da `ComposeEngine` a `d_main`, `g_game`, `r_main` e `i_system`; l'unit resta con i dati letti dal gioco (`ticdup`, `firstinterpolation`, `S_ERR_DIF_NET`).

### `Base\m_misc.pas` - nessuna funzione pubblica

**Tolta come facciata (#145)**: i default del file di configurazione sono `TEngineDefaults` (`IEngineDefaults`; la tabella `defaults` resta in `m_defs`), gli screenshot `TEngineScreenshotService` (`IEngineScreenshot`) e i file interi `TEngineFiles` (`IEngineFiles`), dati da `ComposeEngine` ai loro chiamanti; l'unit resta con le opzioni degli screenshot e i testi dei booleani.

### `Base\sc_utils.pas` - cancellata

**Tolta (#144)**: il preprocessore dei testi e `IScriptTextPreprocessor` (`TScriptTextPreprocessor`, `ComposeScanner`), dato ai costruttori di chi legge script; `SC_Preprocess` non esiste piu.

### `Base\p_udmf.pas` - nessuna funzione pubblica

**Non piu facciata (#142)**: il caricamento delle mappe UDMF e `TEngineUdmfMapLoader` (`ILevelUdmf`, dato a `TLevelLoader`); restano solo i dati (record `extra*_t`, variabili `udmf*`, costanti alias della libreria).

### `Base\i_sound.pas` - cancellata

**Tolta (#143)**: `s_sound` riceve la fabbrica del player degli effetti da `ComposeEngine` (`S_ConfigureSound`); la cache dei campioni (il vecchio `I_CacheSFX`) e `TEngineSfxSampleSource`.

### `Base\i_music.pas` - cancellata

**Tolta (#143)**: `s_sound` riceve `IMusicPlayer` (`S_ConfigureMusic`) e chiama i backend (`Base\DelphiDoom.Engine.Music.*`); `I_SelectDefaultMidiDevice` sta in `i_midi`.

### `TEXLIB\t_main.pas` - cancellata (e con lei `t_draw.pas`, `t_png.pas`: classi `TEngineDrawTextures` e `TEngineTextureSettings`, issue #171; `TEXLIB` non esiste più)

**Tolta (#146)**, con `TEXLIB\t_detect.pas`: `T_LoadHiResImage` e i caricatori sono `TEngineTextureFiles` (`IEngineTextureFiles`, dato da `ComposeTexture`); la classe `TTexture` e in `Base\DelphiDoom.Engine.Texture.Item.pas`; il riconoscimento di patch, PCX e flat lo fanno `TTexturePatchInspector`, `TTexturePcxDecoder` e `TTextureFlatDecoder` di `Libs\Texture`.

### `Base\sc_actordef.pas` - cancellata

**Tolta (#144)**: i lump ACTORDEF/DECORATE/SNDINFO e le costanti sono `TEngineActorDefLumps` (`IEngineActorDefLumps`, dato ai `d_main` da `D_ConfigureActorDef`); `SC_GetActordefDeclaration` sta in `deh_base`.

### `Base\sc_defines.pas` - cancellata

**Tolta (#144)**: i define di gioco sono `TScriptGameDefines` (`IScriptGameDefines`), dati ai `d_main` con `D_ConfigureGameDefines` e al preprocessore da `ComposeScanner`.

### `Base\p_serializer.pas` - 1 funzioni pubbliche, 1 chiamate

Per toglierla: savegame: il formato non puo cambiare, resta facciata.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `P_ConfigureSerializer` | 1 | DelphiDoom.Engine.Composition |

### `OPENGL\gl_voxels.pas` - 2 funzioni pubbliche, 2 chiamate

**Non piu facciata (#134)**: resta il disegno dei voxel in OpenGL (`gld_InitVoxels`, `gld_VoxelsDone`), legato al contesto GL.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `gld_InitVoxels` | 1 | gl_render |
| `gld_VoxelsDone` | 1 | gl_render |

### `Base\r_dynlights.pas` - 1 funzioni pubbliche, 2 chiamate

**Non più facciata (issue #137)**: le funzioni sono di `IDynLightRenderCache` (ricevuto da `r_main`, `r_softlights`, `gl_render`); l'unit resta con i buffer dei renderer.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `R_FreeDynamicLightItems` | 2 | gl_render, r_main |

### `Heretic\p_telept.pas` - 2 funzioni pubbliche, 4 chiamate

Per toglierla: i teletrasporti non sono thinker (#154, `P_ConfigureTeleport`): la geometria e le uscite sono di `Libs\Thinkers` (`TTeleportGeometry`, `TTeleportLineExit`, `TTeleportPlacement`); restano qui il giro dei thinker per trovare l'arrivo, `P_TeleportMove` e le scritture sul mobj e sul giocatore (campi diversi per gioco).

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `P_Teleport` | 1 | p_user |
| `EV_Teleport` | 3 | p_spec (2), udmf_telept |

### `Base\p_obituaries.pas` - 1 funzioni pubbliche, 5 chiamate

**Non piu facciata (#136)**: resta `P_Obituary`, logica del motore che chiama `Libs\Obituary`.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `P_Obituary` | 5 | Doom\p_inter, Heretic\p_inter, Hexen\p_inter (2), Strife\p_inter |

### `OPENGL\gl_clipper.pas` - 5 funzioni pubbliche, 7 chiamate

Per toglierla: percorso caldo OpenGL: resta sopra `IGlAngleClipper`.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `GL_ConfigureClipper` | 1 | DelphiDoom.Engine.Composition |
| `gld_ClipperAddViewRange` | 1 | r_main |
| `gld_ClipperDone` | 1 | gl_render |
| `gld_clipper_SafeCheckRange` | 2 | r_bsp (2) |
| `gld_clipper_SafeAddClipRange` | 2 | r_bsp (2) |

### `Base\nd_main.pas` - 3 funzioni pubbliche, 7 chiamate

**Non piu facciata (#142)**: i nodi del livello sono `TEngineLevelNodes`; restano i record GL letti da `OPENGL\gl_setup.pas` e `gld_GetGLVertexes`. **#158**: `gld_BuildNodes` e `ND_RunGlbsp` sono `TEngineGlbspRunner` (`IEngineGlbspRunner`), data a `TEngineLevelNodes` e, in OpenGL, ai `d_main` con `D_ConfigureGlbsp`.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `gld_GetGLVertexes` | 1 | gl_setup |

### `Base\vx_base.pas` - 7 funzioni pubbliche, 9 chiamate

Per toglierla: il registro dei voxel di VOXELDEF: voxel, poche chiamate, iniettare il servizio.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `VX_ConfigureVoxels` | 1 | DelphiDoom.Engine.Composition |
| `VX_FindVoxel` | 1 | DelphiDoom.Engine.Voxel.DefinitionSink |
| `VX_AddVoxel` | 1 | DelphiDoom.Engine.Voxel.DefinitionSink |
| `VX_AddVoxelState` | 1 | DelphiDoom.Engine.Voxel.DefinitionSink |
| `VX_CheckVoxelSprite` | 1 | DelphiDoom.Engine.Voxel.DefinitionSink |
| `VX_InitVoxels` | 2 | gl_voxels, r_voxels |
| `VX_VoxelsDone` | 2 | gl_voxels, r_voxels |

### `Base\udmf_telept.pas` - 2 funzioni pubbliche, 9 chiamate

Per toglierla: teletrasporto di Hexen e UDMF (#154): usa `TTeleportGeometry` e `TTeleportLineExit` di `Libs\Thinkers`; restano il giro dei thinker e le scritture sul mobj e sul giocatore.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `EVH_Teleport` | 4 | Hexen\p_spec (2), udmf_spec (2) |
| `PH_Teleport` | 5 | Hexen\p_enemy (2), Hexen\p_user (3) |

### `Base\r_voxels.pas` - 4 funzioni pubbliche, 9 chiamate

**Non piu facciata (#134, #145)**: e il disegno dei voxel del renderer software; riceve la palette di base (`R_ConfigureVoxelPalette`).

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `R_ConfigureVoxelPalette` | 1 | DelphiDoom.Engine.Composition |
| `R_InitVoxels` | 2 | r_main (2) |
| `R_VoxelsDone` | 2 | r_main (2) |
| `R_DrawVoxel` | 4 | r_things (4) |

### `Base\p_musinfo.pas` - 3 funzioni pubbliche, 9 chiamate

Per toglierla: `P_InitMusInfo` non esiste piu (#142: `TLevelLoader.Initialize` carica con `IMusInfoLoader`); resta `A_MusicChanger` (azione di stato); `P_FindMusinfoMusic`, che nessuno chiamava da fuori, dalla #158 non e piu pubblica.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `P_FindMusinfoMusic` | 0 | - |
| `P_ConfigureMusInfo` | 1 | DelphiDoom.Engine.Composition |
| `A_MusicChanger` | 8 | Doom\deh_main (2), Heretic\deh_main (2), Hexen\deh_main (2), Strife\deh_main (2) |

### `Base\i_midi_new.pas` - cancellata

**Tolta (#158)**: il corpo e `TEngineMidiSongPlayer` (`IEngineMidiSongPlayer`), creata da `ComposeMusic` e data a `i_midi` con `I_ConfigureMidi`. Storia: dalla #83 il sequencer dei buffer di stream e `Libs\Midi` (`IMidiStreamSequencer`) e il dispositivo e `TEngineMidiStreamPlayer` (`I_ConfigureMidiStream`, dato da `ComposeMusic`); resta la vecchia API `I_*Midi_New` che `i_midi` chiama. Scritta senza compilatore, vedi `RUN-83.md`.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `I_ConfigureMidiStream` | 1 | DelphiDoom.Engine.Composition |
| `I_PlayMidi_New` | 1 | i_midi |
| `I_StopMidi_New` | 1 | i_midi |
| `I_PauseMidi_New` | 1 | i_midi |
| `I_ResumeMidi_New` | 1 | i_midi |
| `I_InitMidi_New` | 1 | i_midi |
| `I_ShutDownMidi_New` | 1 | i_midi |
| `I_SetMusicVolumeMidi_New` | 1 | i_midi |
| `I_ProcessMidi_New` | 1 | i_midi |

### `Hexen\deh_main.pas` - 2 funzioni pubbliche, 10 chiamate

**Valutata nella #159, lasciata** (vale per i quattro `deh_main`): non e una facciata ma i dati del gioco. `DEH_Init` costruisce le liste dei nomi (`mobj_tokens`, `state_tokens`, i flag...) e registra le circa 1900 azioni, e le liste sono variabili di unit che leggono `ActorDef.Catalog`, `TableExport.Names/Settings`, `info_common`, `p_common`, `r_renderstyle` e, in Strife, 12 moduli del gioco per `DEH_GetString`. Spostare il corpo in una classe cambierebbe solo il nome dell'unit e le liste restano globali; servirebbe prima dare le liste a quei lettori (un `IDehackedTables`) e a `deh_base`, e portare a dati le registrazioni (stima L, come in `PENDING_ISSUES.md`). Per toglierla: dalla #144 la patch la applica `TEngineDehackedApplier` (una classe per gioco, `DelphiDoom.Engine.Dehacked.Applier`) e `DEH_Parse` e `DEH_Configure` non esistono piu; restano le tabelle dei nomi (`DEH_Init`/`DEH_ShutDown`) e le azioni.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `DEH_ShutDown` | 3 | dd_compiler, d_main (2) |
| `DEH_Init` | 7 | dd_compiler, deh_base (3), DelphiDoom.Engine.Dehacked.Applier, d_main (2) |

### `Heretic\deh_main.pas` - 2 funzioni pubbliche, 10 chiamate

Vedi `Hexen\deh_main.pas` (#159, lasciata). Per toglierla: dalla #144 la patch la applica `TEngineDehackedApplier` (una classe per gioco, `DelphiDoom.Engine.Dehacked.Applier`) e `DEH_Parse` e `DEH_Configure` non esistono piu; restano le tabelle dei nomi (`DEH_Init`/`DEH_ShutDown`) e le azioni.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `DEH_ShutDown` | 3 | dd_compiler, d_main (2) |
| `DEH_Init` | 7 | dd_compiler, deh_base (3), DelphiDoom.Engine.Dehacked.Applier, d_main (2) |

### `Doom\deh_main.pas` - 2 funzioni pubbliche, 10 chiamate

Vedi `Hexen\deh_main.pas` (#159, lasciata). Per toglierla: dalla #144 la patch la applica `TEngineDehackedApplier` (una classe per gioco, `DelphiDoom.Engine.Dehacked.Applier`) e `DEH_Parse` e `DEH_Configure` non esistono piu; restano le tabelle dei nomi (`DEH_Init`/`DEH_ShutDown`) e le azioni.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `DEH_ShutDown` | 3 | dd_compiler, d_main (2) |
| `DEH_Init` | 7 | dd_compiler, deh_base (3), DelphiDoom.Engine.Dehacked.Applier, d_main (2) |

### `Doom\p_switch.pas` - 2 funzioni pubbliche, 12 chiamate

**Valutata nella #159, lasciata**: non e una facciata ma codice dei bottoni di Doom (`P_UseSpecialLine`, `P_ChangeSwitchTexture`, il thinker `button_t`), legato ai thinker. `P_InitSwitchList` e `P_ConfigureSwitches` non esistono piu (#142: `TEngineSwitchListLoader` e le regole di livello di Doom); `P_UseSpecialLine` e `P_ChangeSwitchTexture` sono legati ai thinker dei bottoni: restano.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `P_UseSpecialLine` | 4 | p_common, p_enemy (2), p_map |
| `P_ChangeSwitchTexture` | 8 | p_spec (7), udmf_spec |

### `Base\r_patch.pas` - 5 funzioni pubbliche, 13 chiamate

**Non piu facciata (#135)**: e la cache delle colonne fisse del motore (`fixedcolumns[]`), che chiama gia la libreria. **Valutata nella #159, lasciata**: `R_EnableFixedColumn`/`R_DisableFixedColumn` sono chiamate dal percorso caldo (`r_plane`, `r_segs`) e `R_GetFixedColumn` da `r_data`; non c'e un oggetto a cui darle senza una chiamata a interfaccia per colonna.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `R_ConfigureFixedColumn` | 1 | DelphiDoom.Engine.Composition |
| `R_GetFixedColumn` | 2 | r_data (2) |
| `R_InitFixedColumn` | 3 | r_data (3) |
| `R_EnableFixedColumn` | 3 | r_plane (2), r_segs |
| `R_DisableFixedColumn` | 4 | r_plane (3), r_segs |

### `Base\i_tmp.pas` - 4 funzioni pubbliche, 12 chiamate

**Ridotta (#159)**: `TEnginePaletteGenerator` e `TEngineVoxelSpriteGenerator` ricevono `ITempFiles` dal costruttore (`ComposeEngine`). Restano i salvataggi (`p_saveg` di Doom, Heretic, Strife e `Hexen\sv_save`: lo stato PascalScript della mappa passa da un file) e `ps_dll`, procedure storiche senza un oggetto a cui darlo, e `i_system` per la chiusura.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `I_ConfigureTempFiles` | 1 | DelphiDoom.Engine.Composition |
| `I_DeclareTempFile` | 0 | - |
| `I_ShutDownTempFiles` | 2 | i_system (2) |
| `I_NewTempFile` | 9 | Doom\p_saveg (2), Heretic\p_saveg (2), Hexen\sv_save (2), ps_dll, Strife\p_saveg (2) |

### `Heretic\p_ceilng.pas` - 4 funzioni pubbliche, 15 chiamate

Per toglierla: soffitti: non migrati (#153 ha portato a classi solo il passo, `TPlaneMover`): `T_MoveCeiling` e `EV_DoCeiling` intrecciano suoni, special ed enum per gioco e chiamano `T_MovePlane`; i thinker restano record nella zone memory con il puntatore a funzione salvato grezzo da `p_saveg`/`sv_save` (il formato dei salvataggi non puo cambiare): non si portano a classi.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `P_AddActiveCeiling` | 1 | p_saveg |
| `T_MoveCeiling` | 2 | p_saveg (2) |
| `EV_CeilingCrushStop` | 2 | p_spec (2) |
| `EV_DoCeiling` | 10 | p_spec (7), p_switch (3) |

### `Base\p_animdefs.pas` - 1 funzioni pubbliche, 3 chiamate

**Ridotta (#159)**: `P_InitAnimations` e `P_ShutDownAnimations` non esistono piu: le liste delle immagini animate le crea `TEngineAnimDefsLoader.Load` e le libera `IEngineAnimDefsLoader.Release` (le regole di livello di Doom, Heretic e Strife). Resta `P_AnimateSurfaces` (chiamata a ogni tic da `p_tick`) con i dati delle animazioni (`AnimDefs[]`, `FrameDefs[]`, le due liste), che il renderer legge; `Hexen\p_anim` ha una copia propria.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `P_AnimateSurfaces` | 3 | Hexen\p_anim (2), p_tick |

### `Base\p_umapinfo.pas` - nessuna funzione pubblica

**Non piu facciata (#159)**: `U_ParseMapInfo`, `U_FreeMapInfo`, `U_ConfigureMapInfo` e `ubigstringtostring` non esistono piu: li fa `TEngineMapInfoRecords` (`DelphiDoom.Engine.MapInfo.Records`, `IEngineMapInfoRecords`), dato da `ComposeEngine` ai tre `d_main` (`D_ConfigureMapInfo`); `f_finale` chiama `TEngineMapInfoRecords.BigStringToString` (statica). L'unit resta con i record `mapentry_t` e le variabili `u_mapinfo` e `default_mapinfo`, letti da circa 20 moduli (vedi `PENDING_ISSUES.md`).

### `Base\i_threads.pas` - 4 funzioni pubbliche, 19 chiamate

Per toglierla: dalla #148 e una facciata sottile `TDThread` sopra `IWorkerThread` di `Libs\Threading` (`I_ConfigureThreads`) per chi si crea i propri thread (muri software, `r_fake3d`, `r_depthbuffer`, `am_textured`, `m_menu`): passare un `IWorkerThreadFactory` a quei moduli. `TestActiveThreads` non fa piu nulla.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `I_ConfigureThreads` | 1 | DelphiDoom.Engine.Composition |
| `ThreadInc` | 4 | r_flat32, r_flat8, r_wall32, r_wall8 |
| `ThreadSet` | 4 | r_flat32, r_flat8, r_wall32, r_wall8 |
| `TestActiveThreads` | 10 | r_main (10) |

### `Heretic\p_plats.pas` - 6 funzioni pubbliche, 21 chiamate

Per toglierla: facciata delle piattaforme (#154, `P_ConfigurePlats`): il tic e i tipi sono di `Libs\Thinkers` (`TPlatMachine`); restano le liste `activeplats` e la ricerca dei settori; i thinker restano record nella zone memory con il puntatore a funzione salvato grezzo da `p_saveg`/`sv_save` (il formato dei salvataggi non puo cambiare): non si portano a classi.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `P_ActivateInStasis` | 0 | - |
| `P_AddActivePlat` | 1 | p_saveg |
| `P_RemoveActivePlat` | 1 | DelphiDoom.Engine.Plat.Host |
| `T_PlatRaise` | 2 | p_saveg (2) |
| `EV_StopPlat` | 2 | p_spec (2) |
| `EV_DoPlat` | 15 | p_spec (7), p_switch (8) |

### `Heretic\p_doors.pas` - 5 funzioni pubbliche, 21 chiamate

Per toglierla: facciata delle porte verticali (#152, `P_ConfigureDoors`): il tic e i valori delle porte nuove sono di `Libs\Thinkers` (`TDoorRunner`, `TDoorSpawner`); restano qui la ricerca dei settori, le chiavi e i messaggi (dipendono da `player_t`); i thinker restano record nella zone memory con il puntatore a funzione salvato grezzo da `p_saveg`/`sv_save` (il formato dei salvataggi non puo cambiare): non si portano a classi.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `EV_VerticalDoor` | 1 | p_switch |
| `P_SpawnDoorCloseIn30` | 1 | p_spec |
| `P_SpawnDoorRaiseIn5Mins` | 1 | p_spec |
| `T_VerticalDoor` | 2 | p_saveg (2) |
| `EV_DoDoor` | 16 | p_spec (10), p_switch (6) |

### `Doom\p_telept.pas` - 3 funzioni pubbliche, 21 chiamate

Per toglierla: i teletrasporti non sono thinker (#154, `P_ConfigureTeleport`): la geometria e le uscite sono di `Libs\Thinkers` (`TTeleportGeometry`, `TTeleportLineExit`, `TTeleportPlacement`); restano qui il giro dei thinker per trovare l'arrivo, `P_TeleportMove` e le scritture sul mobj e sul giocatore (campi diversi per gioco).

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `EV_SilentTeleport` | 6 | p_spec (4), p_switch (2) |
| `EV_Teleport` | 7 | p_spec (4), p_switch (2), udmf_telept |
| `EV_SilentLineTeleport` | 8 | p_spec (8) |

### `Base\r_colormaps.pas` - 6 funzioni pubbliche, 23 chiamate

**Non piu facciata (#135)**: e la cache delle colormap personalizzate del motore (lette dal renderer e da `p_saveg`); riceve preparatore e palette di base da `ComposeEngine`. **Valutata nella #159, lasciata**: `R_CustomColorMapForName` e chiamata da `p_saveg` di Doom e Strife (12 volte) e dalle linee colormap; sono le cache in zone memory del motore e i salvataggi, senza un oggetto a cui darle.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `R_ConfigureCustomColormaps` | 1 | DelphiDoom.Engine.Composition |
| `R_InitCustomColormaps` | 2 | r_main (2) |
| `R_ShutDownCustomColormaps` | 2 | r_main (2) |
| `R_RecalcColormaps` | 2 | r_main (2) |
| `R_CustomColorMapForName` | 16 | DelphiDoom.Engine.Level.ColormapLines (3), Doom\p_saveg (6), r_data, Strife\p_saveg (6) |

### `Strife\p_telept.pas` - 3 funzioni pubbliche, 24 chiamate

Per toglierla: i teletrasporti non sono thinker (#154, `P_ConfigureTeleport`): la geometria e le uscite sono di `Libs\Thinkers` (`TTeleportGeometry`, `TTeleportLineExit`, `TTeleportPlacement`); restano qui il giro dei thinker per trovare l'arrivo, `P_TeleportMove` e le scritture sul mobj e sul giocatore (campi diversi per gioco).

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `EV_SilentTeleport` | 6 | p_spec (4), p_switch (2) |
| `EV_SilentLineTeleport` | 8 | p_spec (8) |
| `EV_Teleport` | 10 | p_spec (7), p_switch (2), udmf_telept |

### `Base\udmf_doors.pas` - 3 funzioni pubbliche, 25 chiamate

Per toglierla: facciata delle porte a script (#152, Hexen e UDMF): `TDoorRunner` e `TDoorSpawner` di `Libs\Thinkers` con il profilo della famiglia UDMF; i thinker restano record nella zone memory con il puntatore a funzione salvato grezzo da `p_saveg`/`sv_save` (il formato dei salvataggi non puo cambiare): non si portano a classi.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `EVH_VerticalDoor` | 6 | Hexen\p_spec (3), udmf_spec (3) |
| `TH_VerticalDoor` | 7 | Doom\p_saveg (2), Heretic\p_saveg (2), Hexen\sv_save, Strife\p_saveg (2) |
| `EVH_DoDoor` | 12 | Hexen\p_spec (4), psi_map (4), udmf_spec (4) |

### `Heretic\p_lights.pas` - 11 funzioni pubbliche, 28 chiamate

Per toglierla: facciata dei thinker delle luci (#149, P_ConfigureLights): il calcolo e di `Libs\Thinkers` (`TLightFireFlicker`, `TLightFlash`, `TLightStrobe`, `TLightGlow`); i thinker restano record nella zone memory con il puntatore a funzione salvato grezzo da `p_saveg`/`sv_save` (il formato dei salvataggi non puo cambiare): non si portano a classi.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `P_SpawnFireFlicker` | 1 | p_spec |
| `P_SpawnLightFlash` | 1 | p_spec |
| `EV_StartLightStrobing` | 1 | p_spec |
| `P_SpawnGlowingLight` | 1 | p_spec |
| `T_StrobeFlash` | 2 | p_saveg (2) |
| `T_Glow` | 2 | p_saveg (2) |
| `T_LightFlash` | 2 | p_saveg (2) |
| `T_FireFlicker` | 2 | p_saveg (2) |
| `EV_TurnTagLightsOff` | 3 | DelphiDoom.Engine.Door.Thinker (2), p_spec |
| `P_SpawnStrobeFlash` | 5 | p_spec (5) |
| `EV_LightTurnOn` | 8 | DelphiDoom.Engine.Door.Thinker (2), p_spec (6) |

### `Base\r_translations.pas` - 5 funzioni pubbliche, 28 chiamate

**Valutata nella #159, lasciata**: `R_InitMobjTranslation` e `R_SetMobjBloodTranslation` sono chiamate dai `p_mobj`, `p_map`, `p_saveg`/`sv_save` dei giochi, da `p_common` e da `psi_game` (thinker, salvataggi, PascalScript): vanno con la fase dei thinker. Per toglierla: dalla #146 `R_GetTranslationTable` e le funzioni del sangue non esistono piu (il sangue e `TTranslationBlood`, statica; le tabelle dei PK3 passano dal file system PAK); restano `R_InitMobjTranslation` e `R_SetMobjBloodTranslation`: passare `ITranslationNames` a chi chiede le tabelle degli sprite.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `R_ConfigureTranslations` | 1 | DelphiDoom.Engine.Composition |
| `R_InitTranslations` | 2 | r_main (2) |
| `R_ShutDownTranslations` | 2 | r_main (2) |
| `R_InitMobjTranslation` | 10 | Doom\p_mobj, Doom\p_saveg, Heretic\p_mobj, Heretic\p_saveg, Hexen\p_mobj, Hexen\sv_save, psi_game, p_common, +2 altri |
| `R_SetMobjBloodTranslation` | 13 | Doom\p_map (3), Doom\p_mobj, Heretic\p_map, Heretic\p_mobj (2), Hexen\p_map, Hexen\p_mobj (2), Strife\p_enemy, Strife\p_map, +1 altri |

### `Base\udmf_plats.pas` - 5 funzioni pubbliche, 33 chiamate

Per toglierla: facciata delle piattaforme a script (#154, Hexen e UDMF): `TUdmfPlatMachine` di `Libs\Thinkers`; restano `hactiveplats` e la ricerca dei settori; i thinker restano record nella zone memory con il puntatore a funzione salvato grezzo da `p_saveg`/`sv_save` (il formato dei salvataggi non puo cambiare): non si portano a classi.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `PH_RemoveActivePlat` | 1 | DelphiDoom.Engine.Plat.UdmfHost |
| `EVH_StopPlat` | 2 | Hexen\p_spec, udmf_spec |
| `PH_AddActivePlat` | 4 | Doom\p_saveg, Heretic\p_saveg, Hexen\sv_save, Strife\p_saveg |
| `TH_PlatRaise` | 8 | Doom\p_saveg (2), Heretic\p_saveg (2), Hexen\sv_save (2), Strife\p_saveg (2) |
| `EVH_DoPlat` | 18 | Hexen\p_spec (5), psi_map (8), udmf_spec (5) |

### `Hexen\d_main.pas` - 25 funzioni pubbliche, 37 chiamate

Per toglierla: ciclo principale di gioco: resta. Dalla #145 riceve console, rete, default e screenshot (`D_Configure*`); dalle #142-#144 anche livello, ACTORDEF e define di gioco (`D_ConfigureLevel`, `D_ConfigureActorDef`, `D_ConfigureGameDefines`). **#160**: i file di risposta (`@file`), le liste `wads_autoload`/`paks_autoload`, la parte dimensioni di `D_CheckCommonParams` e il ciclo delle cartelle di `D_IdentifyGameDirectories` sono classi (`IResponseFileExpander`, `TCommandLineFileList`, `IScreenSizeResolver`, `TPakGameDirectories`, date da `D_ConfigureStartup`); restano `D_AddFile` (una per gioco, con il GWA in OpenGL), `D_AddWADFiles/PAKFiles/DEHFiles`, `D_CmdAddPakFile`, `D_CheckCommonParams` (opzioni che scrivono i globali del gioco) e `D_DoomMain`.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `D_AddFile` | 0 | - |
| `D_PageDrawer` | 0 | - |
| `D_FileInDoomPath` | 0 | - |
| `D_ProcessEvents` | 1 | DelphiDoom.Engine.Net.Services |
| `D_PostEvent` | 1 | DelphiDoom.Engine.Input.Sink |
| `D_PageTicker` | 1 | g_game |
| `D_AdvanceDemo` | 1 | g_demo |
| `D_Configure` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureIwad` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureGameDefines` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureActorDef` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureAutoLoad` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureConsole` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureNetGame` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureDefaults` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureScreenshot` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureLevel` | 1 | DelphiDoom.Engine.Composition |
| `D_DoAdvanceDemo` | 2 | DelphiDoom.Engine.Net.Game (2) |
| `D_DoomMain` | 2 | gl_main, i_main |
| `D_StartTitle` | 2 | g_game, m_menu |
| `D_ShutDown` | 2 | i_system (2) |
| `D_EngineVersion` | 3 | DelphiDoom.Engine.Configuration.Defaults (2), DelphiDoom.Engine.Net.Game |
| `D_Display` | 4 | DelphiDoom.Engine.Net.Game (4) |
| `D_Version` | 4 | DelphiDoom.Engine.TableExport.Settings, gl_main, i_main, i_startup |
| `D_VersionBuilt` | 4 | DelphiDoom.Engine.TableExport.Settings, gl_main, i_main, i_startup |

### `Heretic\d_main.pas` - 26 funzioni pubbliche, 38 chiamate

Per toglierla: ciclo principale di gioco: resta. Dalla #145 riceve console, rete, default e screenshot (`D_Configure*`); dalle #142-#144 anche livello, ACTORDEF e define di gioco (`D_ConfigureLevel`, `D_ConfigureActorDef`, `D_ConfigureGameDefines`). **#160**: i file di risposta (`@file`), le liste `wads_autoload`/`paks_autoload`, la parte dimensioni di `D_CheckCommonParams` e il ciclo delle cartelle di `D_IdentifyGameDirectories` sono classi (`IResponseFileExpander`, `TCommandLineFileList`, `IScreenSizeResolver`, `TPakGameDirectories`, date da `D_ConfigureStartup`); restano `D_AddFile` (una per gioco, con il GWA in OpenGL), `D_AddWADFiles/PAKFiles/DEHFiles`, `D_CmdAddPakFile`, `D_CheckCommonParams` (opzioni che scrivono i globali del gioco) e `D_DoomMain`.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `D_AddFile` | 0 | - |
| `D_PageDrawer` | 0 | - |
| `D_FileInDoomPath` | 0 | - |
| `D_ProcessEvents` | 1 | DelphiDoom.Engine.Net.Services |
| `D_PostEvent` | 1 | DelphiDoom.Engine.Input.Sink |
| `D_PageTicker` | 1 | g_game |
| `D_AdvanceDemo` | 1 | g_game |
| `D_Configure` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureIwad` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureGameDefines` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureActorDef` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureAutoLoad` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureConsole` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureNetGame` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureDefaults` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureScreenshot` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureEndoom` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureLevel` | 1 | DelphiDoom.Engine.Composition |
| `D_DoAdvanceDemo` | 2 | DelphiDoom.Engine.Net.Game (2) |
| `D_DoomMain` | 2 | gl_main, i_main |
| `D_StartTitle` | 2 | g_game, m_menu |
| `D_ShutDown` | 2 | i_system (2) |
| `D_EngineVersion` | 3 | DelphiDoom.Engine.Configuration.Defaults (2), DelphiDoom.Engine.Net.Game |
| `D_Display` | 4 | DelphiDoom.Engine.Net.Game (4) |
| `D_Version` | 4 | DelphiDoom.Engine.TableExport.Settings, gl_main, i_main, i_startup |
| `D_VersionBuilt` | 4 | DelphiDoom.Engine.TableExport.Settings, gl_main, i_main, i_startup |

### `Doom\d_main.pas` - 26 funzioni pubbliche, 38 chiamate

Per toglierla: ciclo principale di gioco: resta. Dalla #145 riceve console, rete, default e screenshot (`D_Configure*`); dalle #142-#144 anche livello, ACTORDEF e define di gioco (`D_ConfigureLevel`, `D_ConfigureActorDef`, `D_ConfigureGameDefines`). **#160**: i file di risposta (`@file`), le liste `wads_autoload`/`paks_autoload`, la parte dimensioni di `D_CheckCommonParams` e il ciclo delle cartelle di `D_IdentifyGameDirectories` sono classi (`IResponseFileExpander`, `TCommandLineFileList`, `IScreenSizeResolver`, `TPakGameDirectories`, date da `D_ConfigureStartup`); restano `D_AddFile` (una per gioco, con il GWA in OpenGL), `D_AddWADFiles/PAKFiles/DEHFiles`, `D_CmdAddPakFile`, `D_CheckCommonParams` (opzioni che scrivono i globali del gioco) e `D_DoomMain`.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `D_AddFile` | 0 | - |
| `D_PageDrawer` | 0 | - |
| `D_FileInDoomPath` | 0 | - |
| `D_ProcessEvents` | 1 | DelphiDoom.Engine.Net.Services |
| `D_PostEvent` | 1 | DelphiDoom.Engine.Input.Sink |
| `D_PageTicker` | 1 | g_game |
| `D_AdvanceDemo` | 1 | g_game |
| `D_Configure` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureIwad` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureGameDefines` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureActorDef` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureAutoLoad` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureConsole` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureNetGame` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureDefaults` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureScreenshot` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureEndoom` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureLevel` | 1 | DelphiDoom.Engine.Composition |
| `D_DoAdvanceDemo` | 2 | DelphiDoom.Engine.Net.Game (2) |
| `D_DoomMain` | 2 | gl_main, i_main |
| `D_StartTitle` | 2 | g_game, m_menu |
| `D_ShutDown` | 2 | i_system (2) |
| `D_EngineVersion` | 3 | DelphiDoom.Engine.Configuration.Defaults (2), DelphiDoom.Engine.Net.Game |
| `D_Display` | 4 | DelphiDoom.Engine.Net.Game (4) |
| `D_Version` | 4 | DelphiDoom.Engine.TableExport.Settings, gl_main, i_main, i_startup |
| `D_VersionBuilt` | 4 | DelphiDoom.Engine.TableExport.Settings, gl_main, i_main, i_startup |

### `Doom\p_plats.pas` - 6 funzioni pubbliche, 39 chiamate

Per toglierla: facciata delle piattaforme (#154, `P_ConfigurePlats`): il tic e i tipi sono di `Libs\Thinkers` (`TPlatMachine`); restano le liste `activeplats` e la ricerca dei settori; i thinker restano record nella zone memory con il puntatore a funzione salvato grezzo da `p_saveg`/`sv_save` (il formato dei salvataggi non puo cambiare): non si portano a classi.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `P_ActivateInStasis` | 1 | p_genlin |
| `P_RemoveActivePlat` | 1 | DelphiDoom.Engine.Plat.Host |
| `P_AddActivePlat` | 2 | p_genlin, p_saveg |
| `T_PlatRaise` | 4 | p_doors, p_genlin, p_saveg (2) |
| `EV_StopPlat` | 4 | p_spec (2), p_switch (2) |
| `EV_DoPlat` | 27 | p_spec (14), p_switch (13) |

### `Strife\p_lights.pas` - 11 funzioni pubbliche, 40 chiamate

Per toglierla: facciata dei thinker delle luci (#149, P_ConfigureLights): il calcolo e di `Libs\Thinkers` (`TLightFireFlicker`, `TLightFlash`, `TLightStrobe`, `TLightGlow`); i thinker restano record nella zone memory con il puntatore a funzione salvato grezzo da `p_saveg`/`sv_save` (il formato dei salvataggi non puo cambiare): non si portano a classi.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `P_SpawnFireFlicker` | 1 | p_spec |
| `P_SpawnLightFlash` | 1 | p_spec |
| `P_SpawnGlowingLight` | 1 | p_spec |
| `T_StrobeFlash` | 2 | p_saveg (2) |
| `T_Glow` | 2 | p_saveg (2) |
| `T_LightFlash` | 2 | p_saveg (2) |
| `T_FireFlicker` | 2 | p_saveg (2) |
| `EV_StartLightStrobing` | 4 | p_spec (2), p_switch (2) |
| `P_SpawnStrobeFlash` | 5 | p_spec (5) |
| `EV_TurnTagLightsOff` | 6 | DelphiDoom.Engine.Door.Thinker (2), p_spec (2), p_switch (2) |
| `EV_LightTurnOn` | 14 | DelphiDoom.Engine.Door.Thinker (2), p_spec (6), p_switch (6) |

### `Strife\d_main.pas` - 26 funzioni pubbliche, 40 chiamate

Per toglierla: ciclo principale di gioco: resta. Dalla #145 riceve console, rete, default e screenshot (`D_Configure*`); dalle #142-#144 anche livello, ACTORDEF e define di gioco (`D_ConfigureLevel`, `D_ConfigureActorDef`, `D_ConfigureGameDefines`). **#160**: i file di risposta (`@file`), le liste `wads_autoload`/`paks_autoload`, la parte dimensioni di `D_CheckCommonParams` e il ciclo delle cartelle di `D_IdentifyGameDirectories` sono classi (`IResponseFileExpander`, `TCommandLineFileList`, `IScreenSizeResolver`, `TPakGameDirectories`, date da `D_ConfigureStartup`); restano `D_AddFile` (una per gioco, con il GWA in OpenGL), `D_AddWADFiles/PAKFiles/DEHFiles`, `D_CmdAddPakFile`, `D_CheckCommonParams` (opzioni che scrivono i globali del gioco) e `D_DoomMain`.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `D_AddFile` | 0 | - |
| `D_PageDrawer` | 0 | - |
| `D_FileInDoomPath` | 0 | - |
| `D_ProcessEvents` | 1 | DelphiDoom.Engine.Net.Services |
| `D_PostEvent` | 1 | DelphiDoom.Engine.Input.Sink |
| `D_AdvanceDemo` | 1 | g_game |
| `D_Configure` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureIwad` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureGameDefines` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureActorDef` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureAutoLoad` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureConsole` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureNetGame` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureDefaults` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureScreenshot` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureEndoom` | 1 | DelphiDoom.Engine.Composition |
| `D_ConfigureLevel` | 1 | DelphiDoom.Engine.Composition |
| `D_DoAdvanceDemo` | 2 | DelphiDoom.Engine.Net.Game (2) |
| `D_DoomMain` | 2 | gl_main, i_main |
| `D_PageTicker` | 2 | g_game (2) |
| `D_ShutDown` | 2 | i_system (2) |
| `D_StartTitle` | 3 | f_finale, g_game, m_menu |
| `D_EngineVersion` | 3 | DelphiDoom.Engine.Configuration.Defaults (2), DelphiDoom.Engine.Net.Game |
| `D_Display` | 4 | DelphiDoom.Engine.Net.Game (4) |
| `D_Version` | 4 | DelphiDoom.Engine.TableExport.Settings, gl_main, i_main, i_startup |
| `D_VersionBuilt` | 4 | DelphiDoom.Engine.TableExport.Settings, gl_main, i_main, i_startup |

### `Doom\p_lights.pas` - 11 funzioni pubbliche, 40 chiamate

Per toglierla: facciata dei thinker delle luci (#149, P_ConfigureLights): il calcolo e di `Libs\Thinkers` (`TLightFireFlicker`, `TLightFlash`, `TLightStrobe`, `TLightGlow`); i thinker restano record nella zone memory con il puntatore a funzione salvato grezzo da `p_saveg`/`sv_save` (il formato dei salvataggi non puo cambiare): non si portano a classi.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `P_SpawnFireFlicker` | 1 | p_spec |
| `P_SpawnLightFlash` | 1 | p_spec |
| `P_SpawnGlowingLight` | 1 | p_spec |
| `T_StrobeFlash` | 2 | p_saveg (2) |
| `T_Glow` | 2 | p_saveg (2) |
| `T_LightFlash` | 2 | p_saveg (2) |
| `T_FireFlicker` | 2 | p_saveg (2) |
| `EV_StartLightStrobing` | 4 | p_spec (2), p_switch (2) |
| `P_SpawnStrobeFlash` | 5 | p_spec (5) |
| `EV_TurnTagLightsOff` | 6 | DelphiDoom.Engine.Door.Thinker (2), p_spec (2), p_switch (2) |
| `EV_LightTurnOn` | 14 | DelphiDoom.Engine.Door.Thinker (2), p_spec (6), p_switch (6) |

### `Doom\p_doors.pas` - 6 funzioni pubbliche, 40 chiamate

Per toglierla: facciata delle porte verticali (#152, `P_ConfigureDoors`): il tic e i valori delle porte nuove sono di `Libs\Thinkers` (`TDoorRunner`, `TDoorSpawner`); restano qui la ricerca dei settori, le chiavi e i messaggi (dipendono da `player_t`); i thinker restano record nella zone memory con il puntatore a funzione salvato grezzo da `p_saveg`/`sv_save` (il formato dei salvataggi non puo cambiare): non si portano a classi.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `EV_VerticalDoor` | 1 | p_switch |
| `P_SpawnDoorCloseIn30` | 1 | p_spec |
| `P_SpawnDoorRaiseIn5Mins` | 1 | p_spec |
| `EV_DoLockedDoor` | 2 | p_switch (2) |
| `T_VerticalDoor` | 4 | p_genlin (2), p_saveg (2) |
| `EV_DoDoor` | 31 | p_enemy (2), p_spec (15), p_switch (14) |

### `Strife\p_plats.pas` - 6 funzioni pubbliche, 42 chiamate

Per toglierla: facciata delle piattaforme (#154, `P_ConfigurePlats`): il tic e i tipi sono di `Libs\Thinkers` (`TPlatMachine`); restano le liste `activeplats` e la ricerca dei settori; i thinker restano record nella zone memory con il puntatore a funzione salvato grezzo da `p_saveg`/`sv_save` (il formato dei salvataggi non puo cambiare): non si portano a classi.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `P_ActivateInStasis` | 1 | p_genlin |
| `P_RemoveActivePlat` | 1 | DelphiDoom.Engine.Plat.Host |
| `P_AddActivePlat` | 2 | p_genlin, p_saveg |
| `T_PlatRaise` | 3 | p_genlin, p_saveg (2) |
| `EV_StopPlat` | 4 | p_spec (2), p_switch (2) |
| `EV_DoPlat` | 31 | p_spec (14), p_switch (17) |

### `Base\udmf_lights.pas` - 5 funzioni pubbliche, 44 chiamate

Per toglierla: facciata degli special a script delle luci (#149, Hexen e UDMF): `TLightScripted`, `TLightPhase` e `TLightSequence` di `Libs\Thinkers`; i thinker restano record nella zone memory con il puntatore a funzione salvato grezzo da `p_saveg`/`sv_save` (il formato dei salvataggi non puo cambiare): non si portano a classi.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `P_SpawnPhasedLight` | 2 | DelphiDoom.Engine.Light.PhaseSpawner, Hexen\p_spec |
| `P_SpawnLightSequence` | 4 | Doom\p_spec, Heretic\p_spec, Hexen\p_spec, Strife\p_spec |
| `TH_Light` | 7 | Doom\p_saveg (2), Heretic\p_saveg (2), Hexen\sv_save, Strife\p_saveg (2) |
| `TH_Phase` | 7 | Doom\p_saveg (2), Heretic\p_saveg (2), Hexen\sv_save, Strife\p_saveg (2) |
| `EVH_SpawnLight` | 24 | Hexen\p_spec (7), psi_map (10), udmf_spec (7) |

### `Base\udmf_ceilng.pas` - 4 funzioni pubbliche, 44 chiamate

Per toglierla: soffitti a script: non migrati (#153 ha portato a classi solo il passo); i thinker restano record nella zone memory con il puntatore a funzione salvato grezzo da `p_saveg`/`sv_save` (il formato dei salvataggi non puo cambiare): non si portano a classi.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `EVH_CeilingCrushStop` | 3 | Hexen\p_spec, psi_map, udmf_spec |
| `PH_AddActiveCeiling` | 4 | Doom\p_saveg, Heretic\p_saveg, Hexen\sv_save, Strife\p_saveg |
| `TH_MoveCeiling` | 8 | Doom\p_saveg (2), Heretic\p_saveg (2), Hexen\sv_save (2), Strife\p_saveg (2) |
| `EVH_DoCeiling` | 29 | Hexen\p_spec (6), psi_map (15), udmf_floor (2), udmf_spec (6) |

### `Strife\p_ceilng.pas` - 5 funzioni pubbliche, 45 chiamate

Per toglierla: soffitti: non migrati (#153 ha portato a classi solo il passo, `TPlaneMover`): `T_MoveCeiling` e `EV_DoCeiling` intrecciano suoni, special ed enum per gioco e chiamano `T_MovePlane`; i thinker restano record nella zone memory con il puntatore a funzione salvato grezzo da `p_saveg`/`sv_save` (il formato dei salvataggi non puo cambiare): non si portano a classi.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `P_ActivateInStasisCeiling` | 1 | p_genlin |
| `P_AddActiveCeiling` | 3 | p_genlin (2), p_saveg |
| `T_MoveCeiling` | 4 | p_genlin (2), p_saveg (2) |
| `EV_CeilingCrushStop` | 4 | p_spec (2), p_switch (2) |
| `EV_DoCeiling` | 33 | p_spec (16), p_switch (17) |

### `Doom\p_ceilng.pas` - 5 funzioni pubbliche, 45 chiamate

Per toglierla: soffitti: non migrati (#153 ha portato a classi solo il passo, `TPlaneMover`): `T_MoveCeiling` e `EV_DoCeiling` intrecciano suoni, special ed enum per gioco e chiamano `T_MovePlane`; i thinker restano record nella zone memory con il puntatore a funzione salvato grezzo da `p_saveg`/`sv_save` (il formato dei salvataggi non puo cambiare): non si portano a classi.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `P_ActivateInStasisCeiling` | 1 | p_genlin |
| `P_AddActiveCeiling` | 3 | p_genlin (2), p_saveg |
| `T_MoveCeiling` | 4 | p_genlin (2), p_saveg (2) |
| `EV_CeilingCrushStop` | 4 | p_spec (2), p_switch (2) |
| `EV_DoCeiling` | 33 | p_spec (17), p_switch (16) |

### `Heretic\p_floor.pas` - 4 funzioni pubbliche, 47 chiamate

Per toglierla: facciata dei pavimenti (#153, `P_ConfigurePlanes`): `T_MovePlane` chiama `TPlaneMover` di `Libs\Thinkers`; `T_MoveFloor`, `EV_DoFloor`, scale, donut e ascensori intrecciano suoni, special ed enum per gioco e restano qui (non migrati); i thinker restano record nella zone memory con il puntatore a funzione salvato grezzo da `p_saveg`/`sv_save` (il formato dei salvataggi non puo cambiare): non si portano a classi.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `T_MovePlane` | 4 | DelphiDoom.Engine.Door.Host, DelphiDoom.Engine.Plat.Host, p_ceilng (2) |
| `T_MoveFloor` | 4 | p_saveg (2), p_spec (2) |
| `EV_BuildStairs` | 4 | p_spec (2), p_switch (2) |
| `EV_DoFloor` | 35 | p_enemy (3), p_spec (20), p_switch (12) |

### `Base\am_map.pas` - 8 funzioni pubbliche, 51 chiamate

**Non piu facciata (#145)**: le funzioni che passavano il modello (`FTOM`, `CXMTOF`, `CYMTOF`, `M_ZOOMIN`, `M_ZOOMOUT`, `AM_rotate`, `AM_GetWindow`) non esistono piu: `am_map` e `am_textured` chiamano `IAutomapView`, `TAutomapTransform` e `TAutomapRotation`. Resta il disegno dell'automap (per fotogramma) con i suoi tasti, che riceve il modello da `AM_Configure`.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `AM_Configure` | 1 | DelphiDoom.Engine.Composition |
| `AM_Start` | 2 | gl_main, v_displaymode |
| `AM_Responder` | 4 | Doom\g_game, Heretic\g_game, Hexen\g_game, Strife\g_game |
| `AM_Ticker` | 4 | Doom\g_game, Heretic\g_game, Hexen\g_game, Strife\g_game |
| `AM_Init` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `AM_ShutDown` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `AM_Drawer` | 12 | Doom\d_main (3), Heretic\d_main (3), Hexen\d_main (3), Strife\d_main (3) |
| `AM_Stop` | 12 | Doom\g_game, Doom\p_inter, gl_main, Heretic\g_game, Heretic\in_stuff, Heretic\p_inter, Hexen\g_game, Hexen\in_stuff, +4 altri |

### `Base\r_draw.pas` - 10 funzioni pubbliche, 60 chiamate

Per toglierla: renderer software: resta.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `R_InitBuffer` | 1 | r_main |
| `R_InitTranslationTables` | 1 | r_main |
| `R_FillBackStatusbar` | 1 | v_video |
| `R_ConfigurePlayerTranslations` | 3 | DelphiDoom.Engine.Composition (3) |
| `R_DrawDiskBusy` | 4 | Doom\d_main, Heretic\d_main, Hexen\d_main, Strife\d_main |
| `R_VideoBlanc` | 5 | Doom\st_stuff (2), Strife\st_stuff (3) |
| `R_VideoErase` | 6 | hu_lib (6) |
| `R_DrawViewBorder` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `R_FillBackScreen` | 14 | Doom\d_main (2), Doom\g_game (2), Heretic\d_main (2), Heretic\g_game (2), Hexen\d_main (2), Strife\d_main (2), Strife\g_game (2) |
| `R_PlayerViewBlanc` | 17 | Doom\d_main (4), Heretic\d_main (4), Hexen\d_main (4), r_camera, Strife\d_main (4) |

### `Base\w_pak.pas` - 11 funzioni pubbliche, 67 chiamate

Per toglierla: dalla #146 e la vecchia API procedurale sopra `TPakFileSystem` (`IPakFileSystem`, creata da `ComposePak`); `PAK_AddDirectory` e `PAK_GetMatchingEntries` non esistono piu e `PAK_GetGlobalHash` non ha piu chiamanti. Restano i chiamanti `PAK_*` di `d_main`, degli script e dei lettori di testi: passare `IPakFileSystem` ai moduli.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `PAK_Configure` | 1 | DelphiDoom.Engine.Composition |
| `PAK_FileNameIterator` | 1 | s_pk3sounds |
| `PAK_ReadAllFilesAsString` | 2 | DelphiDoom.Engine.ActorDef.Hooks, DelphiDoom.Engine.Scanner.IncludeSource |
| `PAK_GetDirectoryListFromString` | 4 | Doom\d_main, Heretic\d_main, Hexen\d_main, Strife\d_main |
| `PAK_LoadPendingPaks` | 4 | Doom\d_main, Heretic\d_main, Hexen\d_main, Strife\d_main |
| `PAK_ReadFileAsString` | 6 | DelphiDoom.Engine.ActorDef.Hooks (2), DelphiDoom.Engine.Scanner.IncludeSource, ps_import, ps_main (2) |
| `PAK_InitFileSystem` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `PAK_ShutDown` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `PAK_StringIterator` | 9 | deh_base (3), DelphiDoom.Engine.ActorDef.Lumps, DelphiDoom.Engine.MapInfo.TextSource, gl_models (2), vx_base (2) |
| `PAK_AddFile` | 24 | Doom\d_main (6), Heretic\d_main (6), Hexen\d_main (6), Strife\d_main (6) |

### `Base\i_video.pas` - 10 funzioni pubbliche, 73 chiamate

Per toglierla: DirectDraw/blit legati a `screens[]` e al renderer (#41, #42); resta finche non c'e una superficie astratta.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `I_ConfigureDisplayModes` | 1 | DelphiDoom.Engine.Composition |
| `I_BlitBuffer` | 1 | r_main |
| `I_SetPalette64` | 1 | r_main |
| `I_InitGraphics` | 5 | Doom\d_main, Heretic\d_main, Hexen\d_main, Strife\d_main, v_displaymode |
| `I_ShutDownGraphics` | 5 | gl_main (2), i_system (2), v_displaymode |
| `I_FinishUpdate` | 6 | Doom\d_main, gl_main (2), Heretic\d_main, Hexen\d_main, Strife\d_main |
| `IV_SetPalette` | 7 | Doom\d_main, Doom\m_menu, Doom\st_stuff (2), Strife\d_main, Strife\st_stuff (2) |
| `I_ReadScreen32` | 8 | DelphiDoom.Engine.Screenshot.Service, f_wipe (2), gl_main (2), r_main, Strife\f_fade (2) |
| `I_ChangeFullScreen` | 10 | c_utils, Doom\m_menu (2), Heretic\m_menu (2), Hexen\m_menu (2), r_hires, Strife\m_menu (2) |
| `I_SetPalette` | 29 | DelphiDoom.Engine.Video.Screens, Doom\d_main, Doom\m_menu, Doom\st_stuff (2), gl_main (2), Heretic\d_main, Heretic\f_finale (2), Heretic\in_stuff, +12 altri |

### `Base\p_acs.pas` - 14 funzioni pubbliche, 75 chiamate

Per toglierla: l'interprete ACS lavora sullo stato del gioco; servirebbe un `IAcsHost` completo (gia in parte) e togliere i globali `ACS*`.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `P_CheckACSStore` | 1 | Hexen\sv_save |
| `P_ConfigureAcs` | 1 | DelphiDoom.Engine.Composition |
| `P_SuspendACS` | 2 | Hexen\p_spec, udmf_spec |
| `P_TerminateACS` | 2 | Hexen\p_spec, udmf_spec |
| `P_StartLockedACS` | 2 | Hexen\p_spec, udmf_spec |
| `P_LoadACScripts` | 2 | DelphiDoom.Engine.Level.Loader (2) |
| `P_PolyobjFinished` | 4 | po_man (4) |
| `P_ACSInitNewGame` | 4 | Doom\g_game, Heretic\g_game, Hexen\g_game, Strife\g_game |
| `TH_InterpretACS` | 8 | DelphiDoom.Engine.Acs.Host, Doom\p_saveg (2), Heretic\p_saveg (2), Hexen\sv_save, Strife\p_saveg (2) |
| `P_ACSInit` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `P_ACSShutDown` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `P_TagFinished` | 9 | udmf_ceilng (2), udmf_doors, udmf_floor (4), udmf_plats (2) |
| `P_StartACS` | 12 | Hexen\p_enemy (7), Hexen\p_inter, Hexen\p_map (2), Hexen\p_spec, udmf_spec [test: 1] |
| `P_ACSMachine` | 12 | Hexen\sv_save (12) |

### `Strife\p_doors.pas` - 11 funzioni pubbliche, 76 chiamate

Per toglierla: facciata delle porte verticali (#152, `P_ConfigureDoors`): il tic e i valori delle porte nuove sono di `Libs\Thinkers` (`TDoorRunner`, `TDoorSpawner`); restano qui la ricerca dei settori, le chiavi e i messaggi (dipendono da `player_t`); i thinker restano record nella zone memory con il puntatore a funzione salvato grezzo da `p_saveg`/`sv_save` (il formato dei salvataggi non puo cambiare): non si portano a classi.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `EV_VerticalDoor` | 1 | p_switch |
| `EV_SlidingDoor` | 1 | p_switch |
| `P_SpawnDoorCloseIn30` | 1 | p_spec |
| `P_SpawnDoorRaiseIn5Mins` | 1 | p_spec |
| `P_InitSlidingDoorFrames` | 1 | p_spec |
| `T_SlidingDoor` | 1 | p_saveg |
| `EV_ClearForceFields` | 2 | p_spec, p_switch |
| `EV_RemoteSlidingDoor` | 2 | p_switch (2) |
| `T_VerticalDoor` | 5 | p_genlin (2), p_saveg (3) |
| `EV_DoLockedDoor` | 8 | p_switch (8) |
| `EV_DoDoor` | 53 | p_dialog (4), p_enemy (3), p_inter (4), p_spec (23), p_switch (19) |

### `Base\udmf_floor.pas` - 11 funzioni pubbliche, 101 chiamate

Per toglierla: `TH_MovePlane` e `TH_FloorWaggle` chiamano `TPlaneMover` e `TPlaneWaggle` (#153); `EVH_DoFloor`, scale, pilastri e `TH_MoveFloor` non sono migrati; i thinker restano record nella zone memory con il puntatore a funzione salvato grezzo da `p_saveg`/`sv_save` (il formato dei salvataggi non puo cambiare): non si portano a classi.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `EVH_OpenPillar` | 3 | Hexen\p_spec, psi_map, udmf_spec |
| `EVH_FloorCrushStop` | 3 | Hexen\p_spec, psi_map, udmf_spec |
| `EVH_StartFloorWaggle` | 3 | Hexen\p_spec, psi_map, udmf_spec |
| `TH_MovePlane` | 4 | DelphiDoom.Engine.Door.Host, DelphiDoom.Engine.Plat.UdmfHost, udmf_ceilng (2) |
| `EVH_BuildPillar` | 6 | Hexen\p_spec (2), psi_map (2), udmf_spec (2) |
| `EVH_DoFloorAndCeiling` | 6 | Hexen\p_spec (2), psi_map (2), udmf_spec (2) |
| `TH_MoveFloor` | 7 | Doom\p_saveg (2), Heretic\p_saveg (2), Hexen\sv_save, Strife\p_saveg (2) |
| `TH_BuildPillar` | 7 | Doom\p_saveg (2), Heretic\p_saveg (2), Hexen\sv_save, Strife\p_saveg (2) |
| `TH_FloorWaggle` | 7 | Doom\p_saveg (2), Heretic\p_saveg (2), Hexen\sv_save, Strife\p_saveg (2) |
| `EVH_BuildStairs` | 8 | Hexen\p_spec (4), udmf_spec (4) |
| `EVH_DoFloor` | 47 | Hexen\p_enemy (2), Hexen\p_spec (12), psi_map (21), udmf_spec (12) |

### `Doom\p_floor.pas` - 8 funzioni pubbliche, 104 chiamate

Per toglierla: facciata dei pavimenti (#153, `P_ConfigurePlanes`): `T_MovePlane` chiama `TPlaneMover` di `Libs\Thinkers`; `T_MoveFloor`, `EV_DoFloor`, scale, donut e ascensori intrecciano suoni, special ed enum per gioco e restano qui (non migrati); i thinker restano record nella zone memory con il puntatore a funzione salvato grezzo da `p_saveg`/`sv_save` (il formato dei salvataggi non puo cambiare): non si portano a classi.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `T_MoveElevator` | 2 | p_saveg (2) |
| `T_MovePlane` | 4 | DelphiDoom.Engine.Door.Host, DelphiDoom.Engine.Plat.Host, p_ceilng (2) |
| `EV_DoDonut` | 4 | p_spec (2), p_switch (2) |
| `T_MoveFloor` | 5 | p_genlin (3), p_saveg (2) |
| `EV_BuildStairs` | 8 | p_spec (4), p_switch (4) |
| `EV_DoChange` | 8 | p_spec (4), p_switch (4) |
| `EV_DoElevator` | 12 | p_spec (6), p_switch (6) |
| `EV_DoFloor` | 61 | p_enemy (4), p_spec (29), p_switch (28) |

### `Base\udmf_spec.pas` - 12 funzioni pubbliche, 117 chiamate

Per toglierla: gli esecutori `EVH_*` dei thinker non si possono astrarre (savegame): resta.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `P_LineToArgs` | 0 | - |
| `P_ArgsToLine` | 0 | - |
| `P_ConfigureLineSpecials` | 1 | DelphiDoom.Engine.Composition |
| `P_ForceLightning` | 5 | Hexen\p_anim (2), Hexen\p_spec, psi_map (2) |
| `P_LightningFlash` | 5 | Doom\p_spec, Heretic\p_spec, Hexen\p_anim (2), Strife\p_spec |
| `P_InitLightning` | 6 | Doom\DelphiDoom.Engine.Level.DoomRules, Heretic\DelphiDoom.Engine.Level.HereticRules, Hexen\DelphiDoom.Engine.Level.HexenRules, Hexen\p_anim (2), Strife\DelphiDoom.Engine.Level.StrifeRules |
| `P_FindSectorFromTag2` | 7 | DelphiDoom.Engine.Acs.Host (2), Hexen\p_spec (3), udmf_lights, udmf_plats |
| `P_FindLine` | 8 | DelphiDoom.Engine.Acs.Host (6), Hexen\p_spec (2) |
| `P_FindSectorFromTag` | 12 | Hexen\p_spec (3), udmf_ceilng, udmf_doors, udmf_floor (7) |
| `P_ExecuteLineSpecial` | 12 | DelphiDoom.Engine.Acs.Host, Hexen\p_enemy, Hexen\p_inter (6), Hexen\p_spec (3), Hexen\p_user |
| `P_ExecuteActorSpecial` | 27 | Doom\p_inter (8), Heretic\p_inter (15), Strife\p_inter (4) |
| `P_ActivateLine` | 34 | Doom\p_enemy, Doom\p_map (7), Heretic\p_enemy, Heretic\p_map (7), Hexen\p_enemy, Hexen\p_map (7), Hexen\p_spec (2), Strife\p_enemy, +1 altri |

### `Strife\p_floor.pas` - 8 funzioni pubbliche, 121 chiamate

Per toglierla: facciata dei pavimenti (#153, `P_ConfigurePlanes`): `T_MovePlane` chiama `TPlaneMover` di `Libs\Thinkers`; `T_MoveFloor`, `EV_DoFloor`, scale, donut e ascensori intrecciano suoni, special ed enum per gioco e restano qui (non migrati); i thinker restano record nella zone memory con il puntatore a funzione salvato grezzo da `p_saveg`/`sv_save` (il formato dei salvataggi non puo cambiare): non si portano a classi.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `T_MoveElevator` | 2 | p_saveg (2) |
| `EV_DoDonut` | 4 | p_spec (2), p_switch (2) |
| `T_MoveFloor` | 5 | p_genlin (3), p_saveg (2) |
| `T_MovePlane` | 8 | DelphiDoom.Engine.Door.Host, DelphiDoom.Engine.Plat.Host, p_ceilng (2), p_doors (4) |
| `EV_DoChange` | 8 | p_spec (4), p_switch (4) |
| `EV_BuildStairs` | 11 | p_spec (5), p_switch (6) |
| `EV_DoElevator` | 12 | p_spec (6), p_switch (6) |
| `EV_DoFloor` | 71 | p_enemy (5), p_inter, p_spec (33), p_switch (32) |

### `Strife\deh_main.pas` - 3 funzioni pubbliche, 164 chiamate

Vedi `Hexen\deh_main.pas` (#159, lasciata). Per toglierla: dalla #144 la patch la applica `TEngineDehackedApplier` (una classe per gioco, `DelphiDoom.Engine.Dehacked.Applier`) e `DEH_Parse` e `DEH_Configure` non esistono piu; restano le tabelle dei nomi (`DEH_Init`/`DEH_ShutDown`) e le azioni.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `DEH_ShutDown` | 3 | dd_compiler, d_main (2) |
| `DEH_Init` | 7 | dd_compiler, deh_base (3), DelphiDoom.Engine.Dehacked.Applier, d_main (2) |
| `DEH_GetString` | 154 | d_check (4), d_main (19), f_finale (42), g_game, m_menu (5), p_dialog (11), p_doors (41), p_enemy (3), +5 altri |

### `Base\r_precalc.pas` - 5 funzioni pubbliche, 182 chiamate

Per toglierla: tabelle del renderer: resta.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `R_ConfigurePrecalc` | 1 | DelphiDoom.Engine.Composition |
| `R_InitPrecalc` | 2 | r_main (2) |
| `R_ShutDownPrecalc` | 2 | r_main (2) |
| `R_GetFogPrecalc32Tables` | 48 | Hexen\r_col_fog (3), Hexen\r_col_ms_fog (4), Hexen\r_span32_fog, Hexen\r_span32_fog_ripple, r_tallcolumn (3), R_Wall32_BatchFuncs (36) |
| `R_GetPrecalc32Tables` | 129 | r_batchcolumn (2), r_colorcolumn (9), r_column (4), r_col_ms (6), R_DrawColorColumnHi_bc (60), r_flat32, r_flat32_ripple, r_span32, +5 altri |

### `Base\m_cheat.pas` - 3 funzioni pubbliche, 185 chiamate

Per toglierla: i giochi chiamano `cht_CheckCheat` per ogni cheat: servirebbe la `TCheatTable` della libreria e una tabella per gioco.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `cht_CheckCheat` | 4 | Doom\st_stuff, Heretic\sb_bar, Hexen\sb_bar, Strife\st_stuff |
| `cht_GetParam` | 9 | Doom\st_stuff (2), Heretic\sb_bar (2), Hexen\sb_bar (2), Strife\st_stuff (3) |
| `get_cheatseq_string` | 172 | am_map (2), Doom\st_stuff (34), Heretic\sb_bar (44), Hexen\sb_bar (50), Strife\st_stuff (42) |

### `Base\mt_utils.pas` - 18 funzioni pubbliche, 207 chiamate

Per toglierla: dalla #148 i tre gruppi di thread sono `IWorkerPool` creati da `MT_Init` (`MT_ConfigureThreads`); `MT_Execute*`, `MT_Iterate` e i task sono chiamati dal renderer e dal disegno (percorso caldo): restano.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `MT_ConfigureThreads` | 1 | DelphiDoom.Engine.Composition |
| `MT_memset` | 2 | am_map (2) |
| `MT_memseti` | 3 | am_map, psi_overlay (2) |
| `MT_WaitTask` | 4 | r_main (4) |
| `MT_WaitTasks` | 4 | DelphiDoom.Engine.Level.Loader (2), gl_main, v_displaymode |
| `MT_memcpy` | 6 | f_wipe, i_video, psi_overlay (2), r_cache_flats, Strife\f_fade |
| `MT_ScheduleTask` | 6 | r_main (6) |
| `MT_ExecutePendingTask` | 6 | r_main (6) |
| `MT_Execute12` | 7 | psi_overlay (2), r_flat32 (2), r_flat8 (2), r_sprite |
| `MT_Execute16` | 7 | psi_overlay (2), r_flat32 (2), r_flat8 (2), r_sprite |
| `MT_Init` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `MT_ShutDown` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `MT_Execute8` | 8 | psi_overlay (2), r_flat32 (2), r_flat8 (2), r_hires, r_sprite |
| `MT_Execute6` | 9 | psi_overlay (2), r_flat32 (2), r_flat8 (2), r_intrpl (2), r_sprite |
| `MT_Iterate` | 10 | r_pk3textures, r_softlights, v_video (8) |
| `MT_Execute4` | 12 | psi_overlay (2), r_flat32 (2), r_flat8 (2), r_hires, r_intrpl (2), r_sprite, r_voxels (2) |
| `MT_ZeroMemory` | 25 | Doom\d_main, Doom\m_menu (2), gl_main, gl_tex (3), Heretic\d_main, Heretic\in_stuff, Heretic\m_menu (2), Heretic\sb_bar, +9 altri |
| `MT_Execute` | 81 | i_video (5), psi_overlay (22), r_depthbuffer (2), r_flat32 (20), r_flat8 (20), r_sprite (10), r_trans8, Strife\f_fade |

### `Base\r_data.pas` - 24 funzioni pubbliche, 215 chiamate

Per toglierla: renderer: texture e lookup, percorso caldo; resta come facciata. `R_GenerateLookup` usa `IRendererTextureLookup` (#156, `R_ConfigureTextureLookup`); FLATINFO e le texture PK3 passano dal file system PAK (#146).

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `R_ConfigureTextureDefs` | 1 | DelphiDoom.Engine.Composition |
| `R_ConfigureFlatInfo` | 1 | DelphiDoom.Engine.Composition |
| `R_ConfigureColormaps` | 1 | DelphiDoom.Engine.Composition |
| `R_ConfigureComposite` | 1 | DelphiDoom.Engine.Composition |
| `R_ConfigureVoxelSprites` | 1 | DelphiDoom.Engine.Composition |
| `R_ConfigureNameHash` | 1 | DelphiDoom.Engine.Composition |
| `R_ConfigureTextureLookup` | 1 | DelphiDoom.Engine.Composition |
| `R_ChangeColormap` | 1 | Hexen\DelphiDoom.Engine.Level.HexenRules |
| `R_GetDSs` | 2 | r_plane, r_slopes |
| `R_InitData` | 2 | r_main (2) |
| `R_FreeMemory` | 2 | r_main (2) |
| `R_SafeFlatNumForName` | 2 | psi_game (2) |
| `R_NewFlatNumForLump` | 2 | Doom\p_spec, Strife\p_spec |
| `R_SetupLevel` | 2 | DelphiDoom.Engine.Level.Loader (2) |
| `R_PrecacheLevel` | 3 | DelphiDoom.Engine.Level.Loader (3) |
| `R_NameForSideTexture` | 13 | Doom\p_saveg (3), Heretic\p_saveg (3), Hexen\sv_save (3), psi_game, Strife\p_saveg (3) |
| `R_GetLumpForFlat` | 15 | am_textured (3), Doom\m_menu, gl_render (6), Heretic\m_menu, Hexen\m_menu, r_cache_flats, Strife\m_menu, v_video |
| `R_GetDCs` | 16 | r_3dfloors (8), r_plane (6), r_segs (2) |
| `R_CheckTextureNumForName` | 19 | DelphiDoom.Engine.Definitions.AnimCatalog, DelphiDoom.Engine.Definitions.TextureLookup, Doom\g_game (4), Doom\p_spec, Heretic\g_game, Heretic\p_spec, Hexen\p_anim, Hexen\p_mapinfo, +6 altri |
| `R_GetColumn` | 21 | Hexen\r_cache_sky1, Hexen\r_cache_sky1_dbl, Hexen\r_cache_sky2 (2), r_3dfloors (4), r_cache_walls (4), r_plane (3), R_RenderSegLoop8 (5), r_segs |
| `R_SafeTextureNumForName` | 27 | DelphiDoom.Engine.Level.ColormapLines (3), Doom\p_saveg (6), Heretic\p_saveg (6), Hexen\sv_save (6), Strife\p_saveg (6) |
| `R_TextureNumForName` | 40 | DelphiDoom.Engine.Acs.Host, DelphiDoom.Engine.Definitions.AnimDefsLoader, Doom\g_game (5), Doom\p_spec (2), Heretic\DelphiDoom.Engine.Level.HereticRules (3), Heretic\g_game (5), Heretic\p_spec (2), Heretic\p_switch (2), +6 altri |
| `R_FlatNumForName` | 41 | DelphiDoom.Engine.Acs.Host, DelphiDoom.Engine.Definitions.AnimDefsLoader, DelphiDoom.Engine.Level.MapReader (2), Doom\g_game, Doom\m_menu (2), Doom\p_saveg (4), Doom\p_spec (2), Heretic\g_game, +12 altri |

### `Base\r_main.pas` - 29 funzioni pubbliche, 282 chiamate

Per toglierla: renderer: resta. Dalla #145 riceve la rete (`R_ConfigureNetGame`) per i `NetUpdate` durante il disegno.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `R_ApplyColormap` | 1 | DelphiDoom.Engine.Console.Screen |
| `R_PointOnSideVanilla` | 1 | Doom\p_map |
| `R_PointInSubsectorClassic` | 1 | r_subsectors |
| `R_ConfigureLightTables` | 1 | DelphiDoom.Engine.Composition |
| `R_ConfigureMenuThumbnail` | 1 | DelphiDoom.Engine.Composition |
| `R_ConfigureDynamicLights` | 1 | DelphiDoom.Engine.Composition |
| `R_SetPalette64` | 1 | r_data |
| `R_ConfigureNetGame` | 1 | DelphiDoom.Engine.Composition |
| `R_PointOnSide` | 2 | r_bsp (2) |
| `R_PointOnLineSide` | 2 | p_bouncing (2) |
| `R_PointToDist` | 2 | ps_import (2) |
| `R_StOff` | 2 | Heretic\sb_bar, Hexen\sb_bar |
| `R_Ticker` | 2 | DelphiDoom.Engine.Net.Game (2) |
| `R_SetViewAngleOffset` | 3 | i_net (3) |
| `R_RenderPlayerView` | 4 | Doom\d_main, Heretic\d_main, Hexen\d_main, Strife\d_main |
| `R_FullStOn` | 4 | Doom\d_main, Heretic\d_main, Hexen\sb_bar, Strife\d_main |
| `R_SetRenderingFunctions` | 5 | Doom\d_main, Heretic\d_main, Hexen\d_main, r_data, Strife\d_main |
| `R_PointToAngleEx` | 7 | r_bsp (6), r_voxels |
| `R_PointToAngle` | 8 | ps_import (2), r_bsp (2), r_softlights, r_things (3) |
| `R_Init` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `R_ShutDown` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `R_ExecuteSetViewSize` | 8 | Doom\d_main, Doom\g_game, gl_main, Heretic\d_main, Heretic\g_game, Hexen\d_main, Strife\d_main, Strife\g_game |
| `R_PointOnSegSide` | 11 | R_DrawColumnLightmap32FF_Main, R_DrawColumnLightmap32Masked_Main, R_DrawColumnLightmap32_Main, R_DrawColumnLightmap8FF_Main, R_DrawColumnLightmap8Masked_Main, R_DrawColumnLightmap8_Main, r_subsectors, r_things (3), +1 altri |
| `R_SetViewSize` | 15 | Doom\m_menu (2), Heretic\m_menu (2), Hexen\m_menu (2), r_hires (7), Strife\m_menu (2) |
| `R_GetColormap32` | 16 | r_3dfloors (10), R_RenderSegLoop32 (2), r_segs (2), r_things, r_voxels |
| `R_GetColormapLightLevel` | 19 | r_3dfloors (4), r_plane (4), R_RenderSegLoop32 (2), r_segs, r_slopes (6), r_things, r_voxels |
| `R_PointInSubsector` | 45 | Doom\p_map, gl_lightmaps, Heretic\g_game, Heretic\p_map (3), Heretic\p_mobj (4), Heretic\p_pspr, Hexen\g_game, Hexen\p_map (3), +15 altri |
| `R_PointToAngle2` | 103 | DelphiDoom.Engine.Level.Nodes, Doom\p_enemy (4), Doom\p_inter, Doom\p_map (2), Doom\p_mobj (2), Doom\p_pspr (2), Doom\p_spec (3), Doom\p_telept (3), +34 altri |

### `Base\c_cmds.pas` - 3 funzioni pubbliche, 307 chiamate

Per toglierla: migrare le circa 270 chiamate `C_AddCmd` a un registratore per area (ogni modulo riceve `ICommandRegistry` dal composition root); poi `C_ExecuteCmd` diventa un metodo dell'interprete. `C_BoolEval` e `C_GetMachingList` non esistono piu (#150: `TConsoleNumbers.EvaluateBoolean`).

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `C_ConfigureCommands` | 1 | DelphiDoom.Engine.Composition |
| `C_ExecuteCmd` | 34 | c_utils, Doom\g_game (3), Doom\m_menu (4), Doom\p_inter, Doom\st_stuff, Heretic\g_game (2), Heretic\m_menu (4), Heretic\p_inter, +10 altri |
| `C_AddCmd` | 272 | am_map, c_utils (8), DelphiDoom.Engine.Console.Screen (6), Doom\deh_main (8), Doom\d_main (5), Doom\m_menu (21), Doom\p_mobj (2), Doom\st_stuff (9), +33 altri |

### `Base\m_argv.pas` - 5 funzioni pubbliche, 459 chiamate

Per toglierla: `M_CheckParm` ha ~380 chiamanti e `myargv`/`myargc` sono letti direttamente: servirebbe passare `ICommandLine` ai moduli. Dalla #150 `M_CheckParm` chiede all'`ICommandLine` (`M_ConfigureArgv`), le classi del motore ricevono `ICommandLine`/`IQueriedCommandLine`/`ISaveFileNames` e `M_CmdShowCmdline`/`M_CmdShowCommandLineParams` non esistono piu (sono comandi di `TEngineConsoleScreen`).

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `M_ConfigureArgv` | 1 | DelphiDoom.Engine.Composition |
| `M_InitArgv` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `M_CheckParmCDROM` | 10 | Doom\d_main, Doom\g_game, Heretic\d_main, Heretic\g_game, Hexen\d_main, Hexen\g_demo, i_io, r_draw, +2 altri |
| `M_SaveFileName` | 61 | deh_base (9), Doom\d_check (3), Doom\d_main (2), Doom\g_game, Doom\m_menu (2), Heretic\d_check (3), Heretic\d_main (2), Heretic\g_game, +12 altri |
| `M_CheckParm` | 379 | Doom\d_main (95), Doom\g_game, Doom\info (2), Doom\p_spec (2), Heretic\d_main (86), Heretic\g_game, Heretic\p_spec (2), Hexen\d_main (85), +9 altri |

### `Base\v_video.pas` - 44 funzioni pubbliche, 579 chiamate

Per toglierla: disegno sullo schermo (`screens[]`): resta.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `V_PreserveX` | 0 | - |
| `V_PreserveW` | 0 | - |
| `V_PreserveH` | 0 | - |
| `V_NeedsPreserve` | 0 | - |
| `V_CalcPreserveTables` | 0 | - |
| `V_CopyCustomScreen` | 1 | DelphiDoom.Engine.Video.Screens |
| `V_CopyAddRect` | 1 | DelphiDoom.Engine.Console.Screen |
| `V_CopyScreenTransparent` | 1 | r_draw |
| `V_CopyRawDataToScreen` | 1 | DelphiDoom.Engine.Console.Screen |
| `V_DrawPatchFullScreenTMP426x200` | 1 | Doom\wi_stuff |
| `V_ConfigureGamma` | 1 | DelphiDoom.Engine.Composition |
| `V_ConfigureFlatShrink` | 1 | DelphiDoom.Engine.Composition |
| `V_StatusBarStretch` | 1 | Doom\st_stuff |
| `V_CalcColorMapPalette` | 2 | r_main (2) |
| `V_RemoveTransparency` | 2 | r_draw (2) |
| `V_DrawPatchTransparentMT` | 2 | Strife\st_stuff (2) |
| `V_DrawPatchFlipped` | 2 | Doom\f_finale, Strife\f_finale |
| `V_PreserveGLX` | 2 | hu_lib (2) |
| `V_FindAproxColorIndexExcluding` | 2 | r_trans8 (2) |
| `V_PreserveGLY` | 3 | hu_lib (3) |
| `V_ReInit` | 4 | gl_main, i_video (2), v_displaymode |
| `V_ScreensSize` | 6 | Doom\d_main, Doom\f_finale, Heretic\d_main, Heretic\f_finale, Hexen\d_main, Strife\d_main |
| `V_DrawPatchTransparent` | 6 | hu_stuff (2), p_simpledialog, Strife\st_stuff (3) |
| `V_TileScreen8` | 6 | Doom\f_finale, Heretic\f_finale, Heretic\in_stuff (4) |
| `V_Init` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `V_ShutDown` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `V_CopyRectTransparentEx` | 8 | Doom\m_menu (2), Heretic\m_menu (2), Hexen\m_menu (2), Strife\m_menu (2) |
| `V_DrawPatchZoomed` | 10 | am_map, Heretic\m_menu (2), Hexen\m_menu (3), Strife\m_menu (4) |
| `V_ShadeBackground` | 12 | Doom\m_menu (3), Heretic\m_menu (3), Hexen\m_menu (3), Strife\m_menu (3) |
| `V_ShadeScreen` | 12 | Doom\m_menu (3), Heretic\m_menu (3), Hexen\m_menu (3), Strife\m_menu (3) |
| `V_DrawPatchFullScreenTMP320x200` | 12 | DelphiDoom.Engine.Console.Screen (2), Doom\f_finale, Doom\wi_stuff, Heretic\in_stuff (3), Strife\f_finale (5) |
| `V_FullScreenStretch` | 15 | Doom\f_finale (3), Doom\wi_stuff, Heretic\f_finale (3), Heretic\in_stuff, Hexen\f_finale, Hexen\in_stuff, Strife\f_finale (5) |
| `V_PreserveY` | 18 | gl_main (4), hu_lib (3), r_draw (6), r_main (5) |
| `V_FindAproxColorIndex` | 19 | DelphiDoom.Engine.Video.Screens (2), Doom\r_diher (2), Hexen\in_stuff, psi_overlay (3), r_pk3textures (2), r_trans8 (5), r_voxels, Strife\r_diher (2), +1 altri |
| `V_CopyRect` | 23 | am_map (2), DelphiDoom.Engine.Console.Screen, Doom\f_finale (3), Doom\st_stuff (2), Doom\wi_stuff (2), Heretic\f_finale (3), Heretic\in_stuff, Hexen\f_finale, +4 altri |
| `V_CopyRectTransparent` | 25 | Doom\m_menu (2), Doom\st_stuff (2), Heretic\m_menu (2), Heretic\sb_bar, Hexen\m_menu (2), Hexen\sb_bar, Strife\m_menu (2), Strife\p_dialog, +1 altri |
| `V_SetPalette` | 26 | DelphiDoom.Engine.Video.Screens, Doom\d_main, Doom\m_menu, Doom\st_stuff (2), Heretic\d_main, Heretic\f_finale (2), Heretic\in_stuff, Heretic\m_menu, +11 altri |
| `V_PageDrawer` | 30 | Doom\d_main, Doom\f_finale (5), Doom\m_menu (5), Heretic\d_main, Heretic\f_finale (6), Heretic\m_menu (3), Hexen\d_main, Hexen\m_menu (3), +2 altri |
| `V_GetScreenWidth` | 38 | DelphiDoom.Engine.Console.Screen (2), Doom\d_main, Doom\m_menu (4), gl_main, Heretic\d_main, Heretic\m_menu (4), Hexen\d_main, Hexen\m_menu (4), +7 altri |
| `V_GetScreenHeight` | 41 | DelphiDoom.Engine.Console.Screen (4), Doom\d_main, Doom\m_menu (4), gl_main, Heretic\d_main, Heretic\m_menu (4), Hexen\d_main, Hexen\m_menu (4), +6 altri |
| `V_DrawPatch` | 229 | DelphiDoom.Engine.Console.Screen (7), Doom\d_main (2), Doom\f_finale (5), Doom\m_menu (41), Doom\st_lib (3), Doom\st_stuff (3), Doom\wi_stuff (2), Heretic\d_main (3), +18 altri |

### `Base\z_zone.pas` - 16 funzioni pubbliche, 644 chiamate

Per toglierla: zone memory: `Z_Malloc` e il cuore del motore (migliaia di chiamanti), resta. Dalla #151 le classi del motore ricevono `IZoneAllocator` (`TEngineZoneAllocator`: un puntatore che non e della zone e un `I_Error`, non un'eccezione) e non chiamano piu `Z_*`.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `Z_DumpHeap` | 0 | - |
| `Z_FileDumpHeapf` | 0 | - |
| `Z_FileDumpHeap` | 0 | - |
| `Z_ConfigureZone` | 1 | DelphiDoom.Engine.Composition |
| `Z_MoveUsers` | 1 | w_wad |
| `Z_Size` | 2 | DelphiDoom.Engine.Zone.Allocator, w_sprite |
| `Z_CheckMemory` | 2 | Doom\g_game, Strife\g_game |
| `Z_FreeTags` | 3 | DelphiDoom.Engine.Level.Loader, r_main (2) |
| `Z_CheckHeap` | 4 | Doom\g_game, Heretic\g_game, Hexen\g_game, Strife\g_game |
| `Z_Init` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `Z_ShutDown` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `Z_Malloc2` | 18 | Doom\g_game (3), gl_render (7), Heretic\g_game (3), Hexen\g_demo (2), Strife\g_game (3) |
| `Z_Realloc` | 34 | DelphiDoom.Engine.Zone.Allocator, Doom\p_map (2), Doom\p_saveg (2), gl_render (11), Heretic\p_map (2), Heretic\p_saveg (2), Hexen\p_map (2), Hexen\sv_save (2), +7 altri |
| `Z_Free` | 100 | DelphiDoom.Engine.Audio.SfxSampleSource (2), DelphiDoom.Engine.Zone.Allocator, Doom\DelphiDoom.Engine.Level.DoomRules, Doom\g_game (7), Doom\p_map, Doom\p_saveg (6), Doom\p_spec (2), Doom\wi_stuff, +31 altri |
| `Z_ChangeTag` | 168 | am_map, DelphiDoom.Engine.Console.Screen, DelphiDoom.Engine.Renderer.PatchSource, Doom\d_main (2), Doom\f_finale, Doom\m_menu (3), Doom\st_lib, Doom\st_stuff (12), +30 altri |
| `Z_Malloc` | 295 | DelphiDoom.Audio.SoundLibrary, DelphiDoom.Engine.Audio.SfxSampleSource, Doom\DelphiDoom.Engine.Definitions.SwitchListLoader, Doom\DelphiDoom.Engine.Level.DoomRules (2), Doom\DelphiDoom.Engine.Level.VanillaNodes (3), Doom\p_ceilng, Doom\p_doors (4), Doom\p_floor (8), +71 altri |

### `Base\w_wad.pas` - 26 funzioni pubbliche, 834 chiamate

Per toglierla: circa mille chiamanti `W_*`: facciata voluta, non si migrano una per una. Dalla #151 le classi del motore ricevono `IEngineLumps` (`TEngineLumps`, `DelphiDoom.Engine.Wad.Lumps`) invece di chiamare `W_*`: per questo le chiamate sono scese.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `W_Configure` | 1 | DelphiDoom.Engine.Composition |
| `W_AddPendingWADfromPAK` | 1 | DelphiDoom.Pak.FileSystem |
| `W_CheckFirstNumForName` | 1 | r_data |
| `W_GetFirstNumForName` | 1 | r_data |
| `W_Reload` | 2 | DelphiDoom.Engine.Level.Loader, DelphiDoom.Engine.Wad.Lumps |
| `W_CheckNumForName2` | 2 | r_data (2) |
| `W_LumpFlags` | 2 | DelphiDoom.Engine.Renderer.PatchSource, r_data |
| `ExtractFileBase8` | 4 | Doom\g_game, Heretic\g_game, Hexen\g_demo, Strife\g_game |
| `W_RuntimeLoad` | 6 | DelphiDoom.Engine.Wad.Lumps, r_pk3textures (4), s_pk3sounds |
| `W_TextLumpName` | 7 | Hexen\f_finale, Hexen\in_stuff, Hexen\p_anim, Hexen\p_mapinfo, Hexen\s_sndseq, Strife\f_finale, Strife\p_dialog |
| `W_ShutDown` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `W_LumpCRC32` | 8 | DelphiDoom.Engine.Wad.Lumps, Doom\d_main, Heretic\d_main, Hexen\d_main, Strife\d_check (3), Strife\d_main |
| `W_InitMultipleFiles` | 13 | Doom\d_main (4), Heretic\d_main (3), Hexen\d_main (3), Strife\d_main (3) |
| `W_TextLumpNum` | 13 | deh_base (2), DelphiDoom.Engine.Wad.Lumps, gl_models, gl_render, p_acs, p_obituaries, p_simpledialog, r_data, +3 altri |
| `W_ReadLump` | 14 | DelphiDoom.Engine.Wad.Lumps, Doom\DelphiDoom.Engine.Definitions.SwitchListLoader, nd_main, r_colormaps, r_data (4), r_draw (2), r_translations, Strife\p_dialog (2), +1 altri |
| `W_NumLumps` | 17 | acs, deh_base, DelphiDoom.Engine.Wad.Lumps, gl_models, gl_tex (3), p_acs, r_colormaps, r_data (4), +4 altri |
| `stringtochar8` | 24 | Doom\g_game (2), Heretic\g_game (2), Hexen\g_game (2), p_levelinfo, p_musinfo, r_data (3), r_pk3textures, r_translations, +2 altri |
| `W_GetNameForNum` | 37 | acs (2), deh_base, DelphiDoom.Engine.Console.Screen, DelphiDoom.Engine.Wad.Lumps, Doom\DelphiDoom.Engine.Level.VanillaNodes (3), Doom\m_menu, gl_models, gl_tex (2), +16 altri |
| `char8tostring` | 41 | deh_base, DelphiDoom.Engine.Console.Screen, DelphiDoom.Engine.TextureDefs.FlatCatalog, DelphiDoom.Engine.Wad.Lumps, Doom\DelphiDoom.Engine.Level.VanillaNodes (3), Doom\g_game, Doom\m_menu, gl_models, +18 altri |
| `W_LumpLength` | 53 | acs, am_map, DelphiDoom.Engine.Audio.SfxSampleSource, DelphiDoom.Engine.Wad.Lumps, Doom\DelphiDoom.Engine.Definitions.SwitchListLoader, Doom\g_game, Doom\p_spec, gl_setup (9), +21 altri |
| `W_GetNumForName` | 89 | am_map (4), DelphiDoom.Engine.Audio.SfxSampleSource, DelphiDoom.Engine.Level.Loader, DelphiDoom.Engine.Wad.Lumps, Doom\g_game, Doom\st_stuff (5), gl_render, Heretic\g_game, +21 altri |
| `W_CacheLumpNum` | 144 | am_map (5), am_textured (2), DelphiDoom.Engine.Audio.SfxSampleSource, DelphiDoom.Engine.Renderer.PatchSource, DelphiDoom.Engine.Wad.Lumps, Doom\d_main, Doom\f_finale, Doom\g_game, +37 altri |
| `W_CheckNumForName` | 163 | am_map (2), deh_base, DelphiDoom.Engine.Audio.SfxSampleSource (2), DelphiDoom.Engine.Wad.Lumps, Doom\DelphiDoom.Engine.Definitions.SwitchListLoader, Doom\d_main (15), Doom\g_game (5), Doom\m_menu (7), +39 altri |
| `W_CacheLumpName` | 183 | DelphiDoom.Engine.Console.Screen, Doom\f_finale (2), Doom\m_menu, Doom\st_lib, Doom\st_stuff (15), Doom\wi_stuff (33), Heretic\d_main, Heretic\f_finale (4), +17 altri |

### `Base\m_rnd.pas` - 16 funzioni pubbliche, 1112 chiamate

Per toglierla: `P_Random` e il percorso caldo di ogni thinker (migliaia di chiamanti): chiamata indiretta gia presente; resta come facciata. Dalla #150 le classi (`TEngineAcsHost`, `TLevelLoader`, regole di livello, luci, porte, piattaforme) ricevono `IGameRandom` e non chiamano piu le funzioni `*_Random`.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `M_ConfigureRandom` | 1 | DelphiDoom.Engine.Composition |
| `I_Random` | 1 | f_wipe |
| `P_RandomFromSeed` | 2 | r_main (2) |
| `P_RandomHitscanAngle` | 2 | p_common (2) |
| `P_RandomHitscanSlope` | 2 | p_common (2) |
| `Sys_Random` | 3 | DelphiDoom.Engine.Scanner.ActorFunctions (3) |
| `M_ClearRandom` | 4 | Doom\g_game, Heretic\g_game, Hexen\g_game, Strife\g_game |
| `M_GetMenuRandomIndex` | 4 | Doom\g_game, Heretic\g_game, Hexen\g_game, Strife\g_game |
| `M_GetSystemRandomSeed` | 5 | Doom\g_game, Heretic\g_game, Hexen\g_demo, info_rnd, Strife\g_game |
| `C_Random` | 6 | Doom\p_user, r_earthquake (4), Strife\p_user |
| `M_SetSystemRandomSeed` | 6 | Doom\g_game (2), Heretic\g_game, Hexen\g_demo (2), Strife\g_game |
| `P_SaveRandom` | 10 | Doom\p_map, Doom\p_mobj (2), Heretic\p_map, Heretic\p_mobj (2), Hexen\p_map, Strife\p_map, Strife\p_mobj (2) |
| `P_RestoreRandom` | 10 | Doom\p_map, Doom\p_mobj (2), Heretic\p_map, Heretic\p_mobj (2), Hexen\p_map, Strife\p_map, Strife\p_mobj (2) |
| `M_Random` | 14 | Doom\st_stuff, Doom\wi_stuff (3), Hexen\m_menu, Hexen\p_user, Hexen\s_sndseq, Strife\p_dialog (2), s_sound (5) |
| `N_Random` | 118 | DelphiDoom.Engine.Scanner.ActorFunctions (10), Doom\p_extra (15), Doom\p_genlin, Doom\p_inter (2), Doom\p_map (2), Doom\p_mobj (9), Doom\p_spec, Heretic\p_extra (2), +16 altri |
| `P_Random` | 924 | DelphiDoom.Engine.Scanner.ActorFunctions, Doom\g_game, Doom\p_enemy (44), Doom\p_extra (6), Doom\p_inter (3), Doom\p_map (9), Doom\p_mobj (31), Doom\p_pspr (17), +37 altri |

### `Base\i_system.pas` - 46 funzioni pubbliche, 1121 chiamate

Per toglierla: e il punto di ingresso di log, clock e piattaforma (`I_Error`, `I_Warning`, `I_GetTime`, ~700 chiamanti): migrare a mano i chiamanti ai servizi iniettati, o tenerla come facciata definitiva. Dalla #155 le classi del motore ricevono `ILog`, `IClock` e `IEngineShutdown` (le chiamate di classe sono scese); `I_CreateProcess`, `I_WaitForProcess` e `I_Sleep` non hanno piu chiamanti.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `I_Sleep` | 0 | - [test: 1] |
| `I_DetectOS` | 0 | - |
| `I_ConfigureInput` | 1 | DelphiDoom.Engine.Composition |
| `I_ConfigureLog` | 1 | DelphiDoom.Engine.Composition |
| `I_ConfigureClock` | 1 | DelphiDoom.Engine.Composition |
| `I_ConfigureVideo` | 1 | DelphiDoom.Engine.Composition |
| `I_ProcessWindows` | 1 | DelphiDoom.Engine.Net.Services |
| `I_GetExeImageSize` | 1 | z_zone |
| `I_ConfigurePlatform` | 1 | DelphiDoom.Engine.Composition |
| `I_ConfigureNetGame` | 1 | DelphiDoom.Engine.Composition |
| `I_ConfigureDefaults` | 1 | DelphiDoom.Engine.Composition |
| `I_Destroy` | 2 | gl_main, i_main |
| `I_DirectoryExists` | 2 | DelphiDoom.Pak.FileSystem (2) |
| `I_StartTic` | 3 | DelphiDoom.Engine.Net.Services (3) |
| `I_GetSysTime` | 4 | Doom\d_main, Heretic\d_main, Hexen\d_main, Strife\d_main |
| `I_StartFrame` | 4 | Doom\d_main, Heretic\d_main, Hexen\d_main, Strife\d_main |
| `I_BaseTiccmd` | 4 | Doom\g_game, Heretic\g_game, Hexen\g_game, Strife\g_game |
| `I_SetCriticalCPUPriority` | 4 | Doom\d_main, Heretic\d_main, Hexen\d_main, Strife\d_main |
| `I_SetNormalCPUPriority` | 4 | Doom\d_main, Heretic\d_main, Hexen\d_main, Strife\d_main |
| `I_ClearInterface` | 4 | i_video (4) |
| `I_GoToWebPage` | 4 | c_utils, Launcher_main, Launcher_utils (2) |
| `I_SetDPIAwareness` | 4 | gl_main, i_main, Launcher_utils (2) |
| `I_GetWindowDPI` | 4 | i_video (2), Launcher_utils (2) |
| `I_GetFracTime` | 5 | hu_stuff, r_intrpl (4) |
| `I_WaitVBL` | 5 | Doom\m_menu, gl_main, Heretic\m_menu, Hexen\m_menu, Strife\m_menu |
| `I_VideoServices` | 6 | gl_main (2), i_video (4) |
| `I_IsCDRomDrive` | 7 | DelphiDoom.Engine.Composition, Launcher_main, Launcher_utils (2), m_argv (3) |
| `I_Init` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `I_FlashCachedOutput` | 8 | 8 .dpr |
| `I_DetectCPU` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `I_ScreenWidth` | 8 | Doom\d_main, gl_main, Heretic\d_main, Hexen\d_main, i_main, Launcher_utils (2), Strife\d_main |
| `I_ScreenHeight` | 8 | Doom\d_main, gl_main, Heretic\d_main, Hexen\d_main, i_main, Launcher_utils (2), Strife\d_main |
| `I_GetTickCount` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `I_VersionBuilt` | 9 | DelphiDoom.Ide.Composition, Doom\d_main, Heretic\d_main, Hexen\d_main, ide_version (2), Launcher_about (2), Strife\d_main |
| `I_BeginDiskBusy` | 11 | deh_base, DelphiDoom.Audio.SoundLibrary (2), DelphiDoom.Engine.Audio.SfxSampleSource, DelphiDoom.Engine.Texture.Files, DelphiDoom.Wad.ReloadableSource, r_translations, s_sound, w_wad (3) |
| `I_Quit` | 13 | DelphiDoom.Engine.Shutdown, Doom\g_game (2), Doom\m_menu, Heretic\g_game (2), Heretic\m_menu, Hexen\g_demo, Hexen\m_menu (2), Strife\g_game (2), +1 altri |
| `I_GameFinished` | 17 | DelphiDoom.Engine.Input.Gate, DelphiDoom.Engine.Net.Game, DelphiDoom.Engine.Net.Services, Doom\d_main (2), Doom\m_menu, gl_main, Heretic\d_main (2), Heretic\m_menu, +5 altri |
| `I_DevWarning` | 22 | DelphiDoom.Engine.Midi.StreamPlayer (2), DelphiDoom.Engine.Scanner.Log, Doom\p_inter (2), gl_render, Heretic\p_inter (2), r_data (2), r_intrpl (3), r_things (4), +2 altri |
| `I_DevError` | 23 | Doom\d_main (7), gl_render, Heretic\d_main (2), Heretic\p_ambient, Hexen\d_main, m_rnd, r_things (2), Strife\d_main (2), +3 altri |
| `I_GetNumCPUs` | 24 | am_textured, i_video (3), Launcher_main, Launcher_utils (2), mt_utils (2), psi_overlay (2), r_depthbuffer, r_flat32 (2), +6 altri |
| `I_GetTime` | 83 | Doom\d_main (4), Doom\g_game (2), Doom\m_menu (14), gl_main (2), Heretic\d_main (4), Heretic\g_game (2), Heretic\m_menu (14), Hexen\d_main (4), +7 altri |
| `I_Warning` | 375 | am_map, deh_base (2), DelphiDoom.Engine.Scanner.Log (3), DelphiDoom.Pak.FileSystem (6), DelphiDoom.Pak.Stream, Doom\DelphiDoom.Engine.Dehacked.Applier (17), Doom\d_main (12), Doom\g_game (12), +73 altri [test: 26] |
| `I_Error` | 418 | am_map (2), c_cmds, deh_base (10), DelphiDoom.Engine.Composition (7), DelphiDoom.Engine.Door.Services, DelphiDoom.Engine.Light.Services, DelphiDoom.Engine.Midi.StreamPlayer (5), DelphiDoom.Engine.Plane.Services, +120 altri [test: 2] |

### `Base\deh_base.pas` - 43 funzioni pubbliche, 2053 chiamate

Per toglierla: le liste dei flag e dei token servono ai dump; servirebbe un catalogo iniettato in `Libs\Dehacked` invece delle liste globali. Dalla #144 l'applicazione delle patch e `TEngineDehackedApplier` (`DEH_ConfigureApplier`).

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `DEH_CurrentSettings` | 0 | - |
| `DEH_CurrentActordef` | 0 | - |
| `DEH_CurrentWeapondef` | 0 | - |
| `DEH_CurrentStateOwners` | 0 | - |
| `DEH_ConfigureApplier` | 1 | DelphiDoom.Engine.Composition |
| `DEH_ConfigureExport` | 1 | DelphiDoom.Engine.Composition |
| `DEH_ActorDeclaration` | 1 | dd_compiler |
| `DEH_MobjInfoCSV` | 1 | dd_compiler |
| `DEH_StatesCSV` | 1 | dd_compiler |
| `DEH_SpritesCSV` | 1 | dd_compiler |
| `DEH_ActionName` | 1 | DelphiDoom.Engine.TableExport.States |
| `DEH_ConfigureActions` | 1 | DelphiDoom.Engine.Composition |
| `DEH_ActionDeclaration` | 1 | dd_compiler |
| `DEH_ActionEntry` | 1 | p_common |
| `DEH_PrintActordef` | 2 | DelphiDoom.Engine.ActorDef.Lumps (2) |
| `DEH_SaveActordef` | 2 | DelphiDoom.Engine.ActorDef.Lumps (2) |
| `DEH_PrintWeapondef` | 2 | DelphiDoom.Engine.ActorDef.Lumps (2) |
| `DEH_SaveWeapondef` | 2 | DelphiDoom.Engine.ActorDef.Lumps (2) |
| `DEH_PrintStateOwners` | 2 | DelphiDoom.Engine.ActorDef.Lumps (2) |
| `DEH_SaveStateOwners` | 2 | DelphiDoom.Engine.ActorDef.Lumps (2) |
| `DEH_PlayerClass` | 2 | DelphiDoom.Engine.ActorDef.Catalog, Hexen\DelphiDoom.Engine.Dehacked.Applier |
| `DEH_ParseText` | 3 | DelphiDoom.Engine.ActorDef.Hooks (3) |
| `DEH_ParseLumpNames` | 4 | Doom\d_main, Heretic\d_main, Hexen\d_main, Strife\d_main |
| `DEH_ParseLumpNum` | 4 | Doom\d_main, Heretic\d_main, Hexen\d_main, Strife\d_main |
| `DEH_AddNullAction` | 4 | Doom\deh_main, Heretic\deh_main, Hexen\deh_main, Strife\deh_main |
| `DEH_SearchActionFromHash` | 4 | Doom\DelphiDoom.Engine.Dehacked.Applier, Heretic\DelphiDoom.Engine.Dehacked.Applier, Hexen\DelphiDoom.Engine.Dehacked.Applier, Strife\DelphiDoom.Engine.Dehacked.Applier |
| `DEH_FindActionByName` | 4 | Doom\DelphiDoom.Engine.Dehacked.Applier, Heretic\DelphiDoom.Engine.Dehacked.Applier, Hexen\DelphiDoom.Engine.Dehacked.Applier, Strife\DelphiDoom.Engine.Dehacked.Applier |
| `DEH_AmmoType` | 5 | DelphiDoom.Engine.ActorDef.Catalog, Doom\DelphiDoom.Engine.Dehacked.Applier, Heretic\DelphiDoom.Engine.Dehacked.Applier, Hexen\DelphiDoom.Engine.Dehacked.Applier, Strife\DelphiDoom.Engine.Dehacked.Applier |
| `DEH_WeaponType` | 5 | DelphiDoom.Engine.ActorDef.Catalog, Doom\DelphiDoom.Engine.Dehacked.Applier, Heretic\DelphiDoom.Engine.Dehacked.Applier, Hexen\DelphiDoom.Engine.Dehacked.Applier, Strife\DelphiDoom.Engine.Dehacked.Applier |
| `DEH_CStringToString` | 8 | Doom\DelphiDoom.Engine.Dehacked.Applier (2), Heretic\DelphiDoom.Engine.Dehacked.Applier (2), Hexen\DelphiDoom.Engine.Dehacked.Applier (2), Strife\DelphiDoom.Engine.Dehacked.Applier (2) |
| `DEH_PrintCurrentSettings` | 8 | Doom\deh_main (2), Heretic\deh_main (2), Hexen\deh_main (2), Strife\deh_main (2) |
| `DEH_SaveCurrentSettings` | 8 | Doom\deh_main (2), Heretic\deh_main (2), Hexen\deh_main (2), Strife\deh_main (2) |
| `DEH_PrintActions` | 8 | Doom\deh_main (2), Heretic\deh_main (2), Hexen\deh_main (2), Strife\deh_main (2) |
| `DEH_SaveMobjInfoCSV` | 8 | Doom\deh_main (2), Heretic\deh_main (2), Hexen\deh_main (2), Strife\deh_main (2) |
| `DEH_SaveStatesCSV` | 8 | Doom\deh_main (2), Heretic\deh_main (2), Hexen\deh_main (2), Strife\deh_main (2) |
| `DEH_SaveSpritesCSV` | 8 | Doom\deh_main (2), Heretic\deh_main (2), Hexen\deh_main (2), Strife\deh_main (2) |
| `DEH_StringValue` | 9 | Doom\DelphiDoom.Engine.Dehacked.Applier (3), Heretic\DelphiDoom.Engine.Dehacked.Applier (2), Hexen\DelphiDoom.Engine.Dehacked.Applier (2), Strife\DelphiDoom.Engine.Dehacked.Applier (2) |
| `DEH_ParseFile` | 12 | Doom\deh_main (2), Doom\d_main, Heretic\deh_main (2), Heretic\d_main, Hexen\deh_main (2), Hexen\d_main, Strife\deh_main (2), Strife\d_main |
| `DEH_ActionCount` | 13 | dd_compiler, Doom\DelphiDoom.Engine.Dehacked.Applier (3), Heretic\DelphiDoom.Engine.Dehacked.Applier (3), Hexen\DelphiDoom.Engine.Dehacked.Applier (3), Strife\DelphiDoom.Engine.Dehacked.Applier (3) |
| `DEH_ActionProc` | 16 | Doom\DelphiDoom.Engine.Dehacked.Applier (4), Heretic\DelphiDoom.Engine.Dehacked.Applier (4), Hexen\DelphiDoom.Engine.Dehacked.Applier (4), Strife\DelphiDoom.Engine.Dehacked.Applier (4) |
| `DEH_ParseLumpName` | 18 | Doom\deh_main, Doom\d_main (6), Heretic\deh_main, Heretic\d_main (4), Hexen\deh_main, Hexen\d_main (2), Strife\deh_main, Strife\d_main (2) |
| `DEH_AddAction` | 1872 | Doom\deh_main (420), Heretic\deh_main (448), Hexen\deh_main (549), Strife\deh_main (455) |

## Funzioni pubbliche senza chiamanti lasciate di proposito

Nessun chiamante fuori dalla unit (riferimenti in `Tests\` e `Libs\` esclusi), non cancellate perche sono renderer, FixedMul/angoli, API storiche (W_*) o libreria di terzi (_clipper). BoolToStr, IsZeroes, parsefirstword, A_Fall, AngleToFixed, FloatMul, DEG2RAD hanno solo riferimenti omonimi in test o librerie: da verificare a mano.

- `Base\deh_base.pas`: DEH_StringToCString
- `Base\i_system.pas`: I_Sleep, I_WaitForProcess
- `Base\m_fixed.pas`: FixedDivLW, FixedDiv_fast, FixedMulDiv16, FixedMulDiv8, FixedMulShl10, FixedMulShl14, FixedMulShl3, FixedMulShl4, FixedMulShl5, FixedMulShl8, FloatMul
- `Base\r_bsp.pas`: R_UnderWater
- `Base\r_clipper.pas`: CleanPolygons, ClosedPathsFromPolyTree, DoublePoint, MinkowskiDiff, MinkowskiSum, OpenPathsFromPolyTree, PolyTreeToPaths, ReversePaths, SimplifyPolygon, SimplifyPolygons
- `Base\r_colorcolumn.pas`: R_DrawColorColumnAverageMedium_Batch
- `Base\r_colormaps.pas`: R_CustomColorMapColor32
- `Base\r_column.pas`: R_DrawColumnBase32
- `Base\r_data.pas`: R_CacheFlat
- `Base\r_hires.pas`: R_ColorBoost, R_FuzzLight, R_InverseLightAverage
- `Base\r_main.pas`: R_AddPointToBox
- `Base\r_tallcolumn.pas`: R_DrawTallColumnBase32
- `Base\r_trans8.pas`: R_FastApproxColorIndex
- `Base\r_utils.pas`: R_PointToScreenBufferEx2
- `Base\r_zbuffer.pas`: R_StartZBuffer
- `Base\tables.pas`: AngleToFixed
- `Base\v_video.pas`: V_GetBlock
- `Base\w_pak.pas`: PAK_GetGlobalHash
- `Base\w_sprite.pas`: W_CacheSpriteName
- `Base\w_wad.pas`: W_LumpIsNamed
- `Common\d_delphi.pas`: IsZeroes, lastword, parsefirstword, RightStr, secondword
- `Doom\p_spec.pas`: P_FindMinSurroundingLight
- `Heretic\p_enemy.pas`: A_Fall
- `Heretic\p_spec.pas`: P_InitLava
- `OPENGL\gl_ambient.pas`: gld_AmbientExecute
- `OPENGL\gl_misc.pas`: gl_f_max
- `OPENGL\gl_render.pas`: gld_DrawLine
- `OPENGL\gl_tex.pas`: gld_LoadExternalTextureAlpha
- `OPENGL\gl_types.pas`: MakeGLVertex
- `OPENGL\mdl_script_proclist.pas`: MDL_Procs
- `Strife\p_spec.pas`: P_FindMinSurroundingLight


## Funzioni pubbliche usate solo dentro la propria unit

Nessun chiamante esterno ma usate internamente: si possono togliere dalla sezione interface (diventano locali). Non fatto in questo lavoro: e una modifica di visibilita, non una cancellazione.

- `Base\deh_base.pas`: DEH_CurrentActordef, DEH_CurrentSettings, DEH_CurrentStateOwners, DEH_CurrentWeapondef
- `Base\hu_lib.pas`: HUlib_addLineToSText, HUlib_clearTextLine, HUlib_delCharFromIText
- `Base\hu_stuff.pas`: HU_FPS, HU_TITLE
- `Base\info_common.pas`: Info_ShutDownDnLookUp
- `Base\info_export.pas`: Info_GetMobjinfoPascal, Info_GetMobjinfoPascalConst, Info_GetStatesPascal
- `Base\i_system.pas`: I_DetectOS
- `Base\p_common.pas`: P_CheckCustomMeleeRange, P_CheckFov, P_CopyFriendliness, P_HealCorpse, P_LocalEarthQuake, P_NoiseAlertEx, P_RaiseActor, P_RoughTargetSearch, P_SeekerMissileEx
- `Base\p_musinfo.pas`: P_FindMusinfoMusic
- `Base\p_sight.pas`: P_CheckVisibility, P_SightPathTraverse
- `Base\r_cache_flats.pas`: R_Get_ds32
- `Base\r_clipper.pas`: CleanPolygon, GetBounds, IntPoint, PointInPolygon, ReversePath
- `Base\r_depthbuffer.pas`: R_DrawSpanToDepthBuffer, R_StoreSpanToDepthBufferMT
- `Base\r_plane.pas`: R_MapPlane, R_MapPlaneAngle
- `Base\r_things.pas`: R_NewVisSprite
- `Base\r_zbuffer.pas`: R_ClearZBuffer, R_DrawVoxelColumnToZBuffer
- `Base\s_sound.pas`: S_ShutDownSound, S_StartVoiceAtVolume, S_StopMusic
- `Base\udmf_spec.pas`: P_ArgsToLine, P_LineToArgs
- `Base\v_displaymode.pas`: V_DoSetDisplayMode
- `Base\v_video.pas`: V_CalcPreserveTables, V_NeedsPreserve, V_PreserveH, V_PreserveW, V_PreserveX
- `Base\z_zone.pas`: Z_DumpHeap, Z_FileDumpHeap, Z_FileDumpHeapf
- `Common\d_delphi.pas`: direxists, QSortFloats, QSortIntegers
- `Doom\d_main.pas`: D_AddFile, D_FileInDoomPath, D_PageDrawer
- `Doom\g_game.pas`: G_DoLoadGame
- `Doom\p_mobj.pas`: P_SpawnMissileAngleZSpeed
- `Doom\p_spec.pas`: P_SpawnFriction, P_SpawnPushers, twoSidedS
- `Heretic\d_main.pas`: D_AddFile, D_FileInDoomPath, D_PageDrawer
- `Heretic\g_game.pas`: G_DoLoadGame
- `Heretic\m_menu.pas`: M_WriteText2
- `Heretic\p_mobj.pas`: P_SpawnMissileAngleZSpeed
- `Heretic\p_plats.pas`: P_ActivateInStasis
- `Heretic\p_pspr.pas`: A_FireMacePL1B
- `Heretic\p_user.pas`: P_PlayerNextArtifact, P_UndoPlayerChicken, P_UseArtifact
- `Hexen\a_action.pas`: A_TeloSpawn
- `Hexen\d_main.pas`: D_AddFile, D_FileInDoomPath, D_PageDrawer
- `Hexen\g_game.pas`: G_DoLoadGame
- `Hexen\m_menu.pas`: M_StringWidth2, M_WriteText2
- `Hexen\p_enemy.pas`: A_AccelBalls, A_CastSorcererSpell, A_DecelBalls, A_FiredSpawnRock, A_KSpiritSeeker, A_KSpiritWeave, A_SlowBalls, A_SorcOffense1, A_SorcOffense2, A_SorcUpdateBallAngle, A_StopBalls, A_WraithFX4, DragonSeek, FaceMovementDirection, KoraxFire1, KoraxFire2, KoraxFire3, KoraxFire4, KoraxFire5, KoraxFire6, KSpiritInit, P_CheckMeleeRange2, P_CheckMissileRange, P_NewChaseDir, P_UpdateMorphedMonster
- `Hexen\p_inter.pas`: P_ActiveMinotaur, P_AutoUseHealth, P_GiveKey, P_HideSpecialThing, P_MinotaurSlam, P_MorphMonster, P_PoisonPlayer, P_SetDormantArtifact, P_SpawnDroppedMobj, P_TryPickupArtifact, P_TryPickupWeapon, P_TryPickupWeaponPiece
- `Hexen\p_map.pas`: PIT_ChangeSector, PIT_CheckLine, PIT_CheckOnmobjZ, PIT_RadiusAttack, PIT_ThrustStompThing, PTR_BounceTraverse, PTR_PuzzleItemTraverse, PTR_ShootTraverse, PTR_SlideTraverse, PTR_UseTraverse, P_FakeZMovement, P_HitSlideLine, P_ThingHeightClip
- `Hexen\p_mobj.pas`: P_FloorBounceMissile, P_PlayerLandedOnThing, P_SpawnMissileAngleZSpeed, P_ZMovement
- `Hexen\p_pspr.pas`: A_CHolyWeave, A_MLightningAttack2, P_AdjustPlayerAngle, P_CheckMana, P_CHolyFindTarget, P_CHolySeekerMissile, P_CHolyTailFollow, P_CHolyTailRemove, P_FireWeapon, P_MStaffSpawn, P_MStaffSpawn2
- `Hexen\p_spec.pas`: EVH_LineSearchForPuzzleItem
- `Hexen\p_user.pas`: P_PlayerNextArtifact
- `Hexen\sv_save.pas`: P_ArchiveScreenShot, P_UnArchiveScreenShot
- `OPENGL\gl_render.pas`: gld_DrawBackgroundFrame, gld_StaticLight
- `OPENGL\gl_tex.pas`: gld_AddFlatToTexture, gld_AddNewGLPatchTexture, gld_AddNewGLTexture, gld_AddPatchToTexture, gld_AddPatchToTexture_UnTranslated, gld_GetTexDimension, gld_SetTexturePalette
- `Libs\ScriptHost\psi_game.pas`: PS_GetMobjInfoGravity
- `Libs\ScriptHost\psi_globals.pas`: FreeHashList
- `Strife\d_main.pas`: D_AddFile, D_FileInDoomPath, D_PageDrawer
- `Strife\g_game.pas`: G_DoLoadGame
- `Strife\m_menu.pas`: M_StringWidth2, M_StringWidth3, M_WriteText2, M_WriteText3
- `Strife\m_saves.pas`: M_ClearSlotNum
- `Strife\p_mobj.pas`: P_SpawnMissileAngleZSpeed
- `Strife\p_spec.pas`: P_SpawnFriction, P_SpawnPushers, twoSidedS
- `Strife\p_user.pas`: P_DropInventoryItem, P_ItemBehavior
