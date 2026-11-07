# Facciate storiche e chiamanti (issue #130)

Elenco delle unit storiche rimaste come facciata (hanno una `*_Configure*` o sono citate in `CLAUDE.md` come facciata sopra una libreria di `Libs\`), con le funzioni pubbliche e i loro chiamanti. Serve a decidere quali migrare a mano.

**Come leggerlo**
- Le unit sono ordinate per numero totale di chiamate crescente; dentro ogni unit le funzioni sono ordinate per chiamate crescente.
- "Chiamate" e il numero di occorrenze del nome in codice (commenti esclusi, stringhe incluse: copre `ps_import` e le registrazioni per nome) nei file che compilano insieme alla unit (le unit di un gioco non contano i file degli altri giochi), esclusi la unit stessa, `Libs\` e `Tests\`. Una voce `DelphiDoom.Engine.Composition` e il cablaggio (`*_Configure*`), non un chiamante di dominio.
- "[test: n]" sono i riferimenti nei test (di solito nomi omonimi: non sono chiamanti).
- Le unit `w_wadreader.pas` e `w_wadwriter.pas` hanno solo classi (`TWadReader`, `TWadWriter`), nessuna funzione: per toglierle i chiamanti (`w_pak`, `r_data`, `vx_*`, `s_pk3sounds`) dovrebbero usare `IWadDirectory` e `IWadBuilder`.
- Dati ricavati dal sorgente dopo la rimozione del codice morto della #130; il conteggio e statico, non sostituisce una lettura del chiamante.

### `Base\sc_evaluate.pas` - 1 funzioni pubbliche, 0 chiamate

**Tolta (#132)**: nessun chiamante (DD_IDE non la usava); `TEvaluator` non esiste piu.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `BoolToStr` | 0 | - [test: 21] |

### `Base\i_exec.pas` - 2 funzioni pubbliche, 1 chiamate

Per toglierla: un solo chiamante: sostituire con un `IProcessLauncher` iniettato.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `I_ExecProgram` | 0 | - |
| `I_ConfigureExec` | 1 | DelphiDoom.Engine.Composition |

### `Base\p_serializer.pas` - 1 funzioni pubbliche, 1 chiamate

Per toglierla: savegame: il formato non puo cambiare, resta facciata.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `P_ConfigureSerializer` | 1 | DelphiDoom.Engine.Composition |

### `OPENGL\gl_frustum.pas` - 6 funzioni pubbliche, 2 chiamate

Per toglierla: percorso caldo OpenGL: resta sopra `IGlFrustum`.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `fr_BoxInFrustum` | 0 | - |
| `fr_CubeInFrustum` | 0 | - |
| `fr_PointInFrustum` | 0 | - |
| `fr_SphereInFrustum` | 0 | - |
| `fr_CalculateFrustum` | 1 | gl_render |
| `GL_ConfigureFrustum` | 1 | DelphiDoom.Engine.Composition |

### `Base\vx_voxelsprite.pas` - 2 funzioni pubbliche, 2 chiamate

Per toglierla: voxel: poche chiamate, iniettare il servizio.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `VX_ConfigureVoxelSprites` | 1 | DelphiDoom.Engine.Composition |
| `VX_VoxelToSprite` | 1 | r_data |

### `Base\v_palettes.pas` - 5 funzioni pubbliche, 3 chiamate

Per toglierla: pochi chiamanti: iniettare `IPaletteBuilder`.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `V_CreateDoomPalette` | 0 | - |
| `V_CreateTranslation` | 0 | - |
| `V_FixBufferPalette` | 0 | - |
| `V_AutoGeneratePalettes` | 1 | DelphiDoom.Engine.Scanner.PaletteGenerator |
| `V_ConfigurePalettes` | 2 | DelphiDoom.Engine.Composition (2) |

### `OPENGL\mdl_base.pas` - 3 funzioni pubbliche, 3 chiamate

Per toglierla: modelli 3D: legato al disegno GL.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `MDL_ConfigureModels` | 1 | DelphiDoom.Engine.Composition |
| `MDL_Md2Parser` | 1 | mdl_md2 |
| `MDL_NewCommandStream` | 1 | mdl_ddmodel |

### `Base\m_sha1.pas` - 1 funzioni pubbliche, 3 chiamate

Per toglierla: pochi chiamanti: usare `TSha1` direttamente.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `SHA1_CalcSHA1Buf` | 3 | p_setup, s_pk3sounds, vx_voxelsprite |

### `Base\m_bbox.pas` - 2 funzioni pubbliche, 3 chiamate

Per toglierla: facciata con puntatori sopra `TBoundingBoxMath`: servirebbe cambiare le firme dei chiamanti (renderer e blockmap).

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `M_ClearBox` | 1 | p_setup |
| `M_AddToBox` | 2 | p_setup (2) |

### `OPENGL\gl_voxels.pas` - 3 funzioni pubbliche, 3 chiamate

Per toglierla: voxel OpenGL: legato al contesto GL.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `gld_ConfigureVoxelLoading` | 1 | DelphiDoom.Engine.Composition |
| `gld_InitVoxels` | 1 | gl_render |
| `gld_VoxelsDone` | 1 | gl_render |

### `Base\r_flatinfo.pas` - 5 funzioni pubbliche, 4 chiamate

Per toglierla: pochi chiamanti: iniettare il servizio di riduzione dei flat.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `R_FlatSizeFromSize` | 0 | - |
| `R_ConfigureFlatInfo` | 1 | DelphiDoom.Engine.Composition |
| `R_ConfigureFlatShrink` | 1 | DelphiDoom.Engine.Composition |
| `R_ParseFlatInfoLumps` | 1 | r_data |
| `R_ShrinkFlatTo64x64` | 1 | v_video |

### `Base\s_externalmusic.pas` - 4 funzioni pubbliche, 4 chiamate

**Tolta (issue #137)**: `s_sound` riceve `IExternalMusicCache` (`S_ConfigureExternalMusic`).

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `S_ConfigureExternalMusic` | 1 | DelphiDoom.Engine.Composition |
| `S_ExternalMusicInit` | 1 | s_sound |
| `S_ShutDownExternalMusic` | 1 | s_sound |
| `S_TryLoadExternalMusic` | 1 | s_sound |

### `Base\r_palette.pas` - 2 funzioni pubbliche, 4 chiamate

Per toglierla: pochi chiamanti: passare `IPaletteConverter`.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `R_ConfigurePalette` | 1 | DelphiDoom.Engine.Composition |
| `R_DefaultPalette` | 3 | r_colormaps, r_data, r_voxels |

### `Heretic\p_terrain.pas` - 2 funzioni pubbliche, 5 chiamate

Per toglierla: pochi chiamanti: iniettare la tabella del terreno.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `P_ConfigureTerrain` | 1 | DelphiDoom.Engine.Composition |
| `P_TerrainTypeForName` | 4 | r_data (4) |

### `Doom\p_terrain.pas` - 2 funzioni pubbliche, 5 chiamate

Per toglierla: pochi chiamanti: iniettare la tabella del terreno.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `P_ConfigureTerrain` | 1 | DelphiDoom.Engine.Composition |
| `P_TerrainTypeForName` | 4 | r_data (4) |

### `Base\p_blockmap.pas` - 3 funzioni pubbliche, 5 chiamate

Per toglierla: percorso caldo (blockmap): resta facciata sopra Libs\Blockmap.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `P_ConfigureBlockmap` | 1 | DelphiDoom.Engine.Composition |
| `P_LoadBlockMap` | 2 | p_setup (2) |
| `P_RemoveSlimeTrails` | 2 | p_setup (2) |

### `Hexen\p_terrain.pas` - 2 funzioni pubbliche, 5 chiamate

Per toglierla: pochi chiamanti: iniettare la tabella del terreno.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `P_ConfigureTerrain` | 1 | DelphiDoom.Engine.Composition |
| `P_TerrainTypeForName` | 4 | r_data (4) |

### `Base\mn_screenshot.pas` - 3 funzioni pubbliche, 6 chiamate

Per toglierla: servirebbe che `m_menu` ricevesse il servizio screenshot da Libs\Screenshot.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `MN_ConfigureScreenShot` | 1 | DelphiDoom.Engine.Composition |
| `MN_ScreenShotFromBlitBuffer` | 1 | r_main |
| `MN_ValidScreenShot` | 4 | Doom\m_menu, Heretic\m_menu, Hexen\m_menu, Strife\m_menu |

### `Base\sc_utils.pas` - 1 funzioni pubbliche, 6 chiamate

**#132**: i chiamanti ricevono `IScriptTextPreprocessor` da `ComposeEngine`; resta solo `vx_base` (file della fetta voxel): cambiato quello, la unit si cancella.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `SC_Preprocess` | 1 | vx_base |

### `Base\p_obituaries.pas` - 2 funzioni pubbliche, 6 chiamate

Per toglierla: chiamato dal codice dei messaggi di morte: iniettare l'interfaccia di Libs\Obituary.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `P_ConfigureObituaries` | 1 | DelphiDoom.Engine.Composition |
| `P_Obituary` | 5 | Doom\p_inter, Heretic\p_inter, Hexen\p_inter (2), Strife\p_inter |

### `Base\r_grow.pas` - 4 funzioni pubbliche, 6 chiamate

Per toglierla: cold path del renderer software: poche chiamate, sostituibili con un servizio iniettato.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `R_ConfigureGrow` | 1 | DelphiDoom.Engine.Composition |
| `R_GrowSpan64to512` | 1 | r_cache_flats |
| `R_GrowSpan64to128` | 2 | r_cache_flats (2) |
| `R_GrowSpan64to256` | 2 | r_cache_flats (2) |

### `Base\i_mp3.pas` - 6 funzioni pubbliche, 7 chiamate

**Tolta (issue #137)**: `TMp3MusicBackend` riceve `IMp3` dal costruttore e tiene il proprio `TMp3Player`.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `I_InitMp3` | 1 | DelphiDoom.Engine.Music.Mp3Backend |
| `I_PauseMP3` | 1 | DelphiDoom.Engine.Music.Mp3Backend |
| `I_PlayMP3` | 1 | DelphiDoom.Engine.Music.Mp3Backend |
| `I_ResumeMP3` | 1 | DelphiDoom.Engine.Music.Mp3Backend |
| `I_ShutDownMP3` | 1 | DelphiDoom.Engine.Music.Mp3Backend |
| `I_StopMP3` | 2 | DelphiDoom.Engine.Music.Mp3Backend (2) |

### `OPENGL\gl_clipper.pas` - 5 funzioni pubbliche, 7 chiamate

Per toglierla: percorso caldo OpenGL: resta sopra `IGlAngleClipper`.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `gld_ClipperAddViewRange` | 1 | r_main |
| `gld_ClipperDone` | 1 | gl_render |
| `GL_ConfigureClipper` | 1 | DelphiDoom.Engine.Composition |
| `gld_clipper_SafeAddClipRange` | 2 | r_bsp (2) |
| `gld_clipper_SafeCheckRange` | 2 | r_bsp (2) |

### `Base\vx_base.pas` - 6 funzioni pubbliche, 8 chiamate

Per toglierla: voxel: poche chiamate, iniettare il servizio.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `VX_AddVoxelState` | 1 | DelphiDoom.Engine.Voxel.DefinitionSink |
| `VX_AddVoxel` | 1 | DelphiDoom.Engine.Voxel.DefinitionSink |
| `VX_CheckVoxelSprite` | 1 | DelphiDoom.Engine.Voxel.DefinitionSink |
| `VX_ConfigureVoxels` | 1 | DelphiDoom.Engine.Composition |
| `VX_InitVoxels` | 2 | gl_voxels, r_voxels |
| `VX_VoxelsDone` | 2 | gl_voxels, r_voxels |

### `Base\sc_evaluate_actor.pas` - 5 funzioni pubbliche, 9 chiamate

**Tolta (#132)**: `TContextExpressionEvaluator` (`Libs\Scanner`) con `TEngineActorExpressionFunctions` e `TEngineActorExpressionVariables`, dato da `ComposeEngine` a `SC_ConfigureParams` di `sc_params`.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `SC_DeclareActorEvaluatorSingleToken` | 0 | - |
| `SC_InitActorEvaluator` | 1 | sc_actordef |
| `SC_IsActorEvaluatorSingleToken` | 1 | sc_params |
| `SC_ShutDownActorEvaluator` | 1 | sc_actordef |
| `SC_EvaluateActorExpression` | 6 | sc_params (6) |

### `Base\r_dynlights.pas` - 4 funzioni pubbliche, 9 chiamate

**Non più facciata (issue #137)**: le funzioni sono di `IDynLightRenderCache` (ricevuto da `r_main`, `r_softlights`, `gl_render`); l'unit resta con i buffer dei renderer.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `R_ConfigureDynamicLights` | 1 | DelphiDoom.Engine.Composition |
| `R_GetDynamicLight` | 2 | gl_render, r_softlights |
| `R_DynamicLightsDone` | 3 | gl_render, r_main (2) |
| `R_InitDynamicLights` | 3 | gl_render, r_main (2) |

### `Base\w_autoload.pas` - 2 funzioni pubbliche, 9 chiamate

**Tolta (issue #137)**: i quattro `d_main` ricevono `IAutoLoadReader` (`D_ConfigureAutoLoad`).

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `W_ConfigureAutoLoad` | 1 | DelphiDoom.Engine.Composition |
| `W_AutoLoadPakFiles` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |

### `Base\r_voxels.pas` - 4 funzioni pubbliche, 9 chiamate

Per toglierla: poche chiamate: iniettare il caricatore di voxel.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `R_ConfigureVoxelLoading` | 1 | DelphiDoom.Engine.Composition |
| `R_InitVoxels` | 2 | r_main (2) |
| `R_VoxelsDone` | 2 | r_main (2) |
| `R_DrawVoxel` | 4 | r_things (4) |

### `Base\sc_engine.pas` - 4 funzioni pubbliche, 9 chiamate

**Tolta (#132)**: i chiamanti usano `TScriptScanner` e `TScannerText` di `Libs\Scanner`.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `SC_ParamsToList` | 1 | sc_params |
| `SC_IsStringInQuotes` | 2 | sc_params (2) |
| `SC_RemoveLineQuotes` | 2 | Hexen\p_anim, Hexen\p_mapinfo |
| `SC_FixParenthesisLevel` | 4 | Doom\deh_main, Heretic\deh_main, Hexen\deh_main, Strife\deh_main |

### `Base\p_musinfo.pas` - 4 funzioni pubbliche, 10 chiamate

Per toglierla: pochi chiamanti: passare `IMusInfoCatalog` a `p_mobj`/`p_acs`.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `P_FindMusinfoMusic` | 0 | - |
| `P_ConfigureMusInfo` | 1 | DelphiDoom.Engine.Composition |
| `P_InitMusInfo` | 1 | p_setup [test: 4] |
| `A_MusicChanger` | 8 | Doom\deh_main (2), Heretic\deh_main (2), Hexen\deh_main (2), Strife\deh_main (2) |

### `Strife\p_terrain.pas` - 3 funzioni pubbliche, 10 chiamate

Per toglierla: pochi chiamanti: iniettare la tabella del terreno.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `P_ConfigureTerrain` | 1 | DelphiDoom.Engine.Composition |
| `P_TerrainTypeForName` | 4 | r_data (4) |
| `P_GetTerrainType` | 5 | p_enemy, p_mobj (4) |

### `Base\m_hash.pas` - 3 funzioni pubbliche, 11 chiamate

Per toglierla: pochi chiamanti: iniettare `IStringHashTable`.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `M_ConfigureHash` | 1 | DelphiDoom.Engine.Composition |
| `M_HashIndex` | 4 | r_data (4) |
| `M_HashUpdate` | 6 | r_data (6) |

### `Base\p_udmf.pas` - 6 funzioni pubbliche, 11 chiamate

Per toglierla: in carico alla #129: non toccata qui.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `P_ConfigureUdmf` | 1 | DelphiDoom.Engine.Composition |
| `UDMF_Check` | 2 | p_setup (2) |
| `UDMF_MakeLines` | 2 | p_setup (2) |
| `UDMF_MakeSectors` | 2 | p_setup (2) |
| `UDMF_MakeSegs` | 2 | p_setup (2) |
| `UDMF_MakeSides` | 2 | p_setup (2) |

### `Base\m_vectors.pas` - 10 funzioni pubbliche, 12 chiamate

Per toglierla: facciata con puntatori sopra `TVectorMath`: servirebbe cambiare i chiamanti del renderer.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `ConcatRotations` | 0 | - [test: 2] |
| `DEG2RAD` | 0 | - |
| `PerpendicularVector` | 0 | - [test: 5] |
| `ProjectPointOnPlane` | 0 | - [test: 2] |
| `RotatePointAroundVector` | 0 | - [test: 2] |
| `CalculateReflect2` | 1 | p_bouncing [test: 2] |
| `CrossProduct` | 1 | p_slopes |
| `VectorAdd` | 2 | DirectX (2) |
| `VectorLength` | 2 | p_common (2) |
| `VectorNormalize` | 6 | DirectX (2), Doom\p_mobj, Heretic\p_mobj, p_slopes, Strife\p_mobj |

### `Base\p_gender.pas` - 3 funzioni pubbliche, 12 chiamate

Per toglierla: pochi chiamanti: iniettare il catalogo dei generi.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `R_ConfigureGenders` | 1 | DelphiDoom.Engine.Composition |
| `R_GetGenderForName` | 5 | DelphiDoom.Engine.ActorDef.Catalog, Doom\deh_main, Heretic\deh_main, Hexen\deh_main, Strife\deh_main |
| `R_GenderName` | 6 | DelphiDoom.Engine.ActorDef.Catalog, Doom\deh_main, Heretic\deh_main, Hexen\deh_main, sc_actordef, Strife\deh_main |

### `Base\i_displaymodes.pas` - 5 funzioni pubbliche, 12 chiamate

**Tolta (issue #137)**: `i_video`, `gl_main` e i quattro `m_menu` ricevono `IDisplayModeCatalog`.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `I_ConfigureDisplayModes` | 1 | DelphiDoom.Engine.Composition |
| `I_ClearDisplayModes` | 2 | gl_main, i_video |
| `I_EnumDisplayModes` | 2 | gl_main, i_video |
| `I_FindWindowSize` | 3 | i_video (3) |
| `I_NearestDisplayModeIndex` | 4 | Doom\m_menu, Heretic\m_menu, Hexen\m_menu, Strife\m_menu |

### `Base\r_patch.pas` - 5 funzioni pubbliche, 13 chiamate

Per toglierla: renderer: colonne fisse, resta.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `R_ConfigureFixedColumn` | 1 | DelphiDoom.Engine.Composition |
| `R_GetFixedColumn` | 2 | r_data (2) |
| `R_EnableFixedColumn` | 3 | r_plane (2), r_segs |
| `R_InitFixedColumn` | 3 | r_data (3) |
| `R_DisableFixedColumn` | 4 | r_plane (3), r_segs |

### `Doom\p_switch.pas` - 4 funzioni pubbliche, 14 chiamate

Per toglierla: legato ai thinker dei bottoni: resta.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `P_ConfigureSwitches` | 1 | DelphiDoom.Engine.Composition |
| `P_InitSwitchList` | 1 | p_setup [test: 1] |
| `P_UseSpecialLine` | 4 | p_common, p_enemy (2), p_map |
| `P_ChangeSwitchTexture` | 8 | p_spec (7), udmf_spec |

### `Hexen\deh_main.pas` - 5 funzioni pubbliche, 16 chiamate

Per toglierla: applica la patch al gioco: resta come adattatore di `IDehackedPatch`.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `DEH_Configure` | 1 | DelphiDoom.Engine.Composition |
| `DEH_Parse` | 3 | deh_base (2), SynHighlighterActorDef [test: 18] |
| `DEH_ShutDown` | 3 | dd_compiler, d_main (2) |
| `DEH_CurrentSettings` | 4 | deh_base (4) |
| `DEH_Init` | 5 | dd_compiler, deh_base (2), d_main (2) |

### `Base\m_crc32.pas` - 3 funzioni pubbliche, 16 chiamate

Per toglierla: pochi chiamanti: usare `TCrc32` direttamente dove serve.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `GetCRC32` | 4 | Doom\d_check (3), Heretic\d_check |
| `GetLumpCRC32` | 12 | Doom\d_main, Heretic\d_main, Hexen\d_main, nd_main (4), p_udmf, Strife\d_check (3), Strife\d_main |

### `Heretic\deh_main.pas` - 5 funzioni pubbliche, 16 chiamate

Per toglierla: applica la patch al gioco: resta come adattatore di `IDehackedPatch`.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `DEH_Configure` | 1 | DelphiDoom.Engine.Composition |
| `DEH_Parse` | 3 | deh_base (2), SynHighlighterActorDef [test: 18] |
| `DEH_ShutDown` | 3 | dd_compiler, d_main (2) |
| `DEH_CurrentSettings` | 4 | deh_base (4) |
| `DEH_Init` | 5 | dd_compiler, deh_base (2), d_main (2) |

### `Doom\deh_main.pas` - 5 funzioni pubbliche, 16 chiamate

Per toglierla: applica la patch al gioco: resta come adattatore di `IDehackedPatch`.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `DEH_Configure` | 1 | DelphiDoom.Engine.Composition |
| `DEH_Parse` | 3 | deh_base (2), SynHighlighterActorDef [test: 18] |
| `DEH_ShutDown` | 3 | dd_compiler, d_main (2) |
| `DEH_CurrentSettings` | 4 | deh_base (4) |
| `DEH_Init` | 5 | dd_compiler, deh_base (2), d_main (2) |

### `Base\i_input.pas` - 6 funzioni pubbliche, 17 chiamate

**Tolta (issue #137)**: un solo `IInputPoller` dato a `i_system`, `i_main`/`gl_main` e ai quattro `g_game`.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `I_ConfigureInput` | 1 | DelphiDoom.Engine.Composition |
| `I_ProcessInput` | 2 | i_system (2) |
| `I_ShutDownInput` | 2 | i_system (2) |
| `I_SynchronizeInput` | 2 | gl_main, i_main |
| `I_InitInput` | 3 | DelphiDoom.Engine.Input.DirectKeyboard, i_system (2) |
| `I_GetCapsLock` | 7 | Doom\g_game (2), Heretic\g_game (2), Hexen\g_game (2), Strife\g_game |

### `Base\p_umapinfo.pas` - 4 funzioni pubbliche, 17 chiamate

Per toglierla: i record `mapentry_t` sono letti da molti moduli: servirebbe un `IMapInfoCatalog` passato a `g_game` e `p_setup`.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `U_ConfigureMapInfo` | 1 | DelphiDoom.Engine.Composition |
| `ubigstringtostring` | 4 | Doom\f_finale (2), Heretic\f_finale (2) |
| `U_FreeMapInfo` | 6 | Doom\d_main (2), Heretic\d_main (2), Strife\d_main (2) |
| `U_ParseMapInfo` | 6 | Doom\d_main (2), Heretic\d_main (2), Strife\d_main (2) |

### `Base\p_animdefs.pas` - 5 funzioni pubbliche, 19 chiamate

Per toglierla: un chiamante: `p_setup` o `r_data` potrebbero ricevere il parser.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `P_ConfigureAnimDefs` | 1 | DelphiDoom.Engine.Composition |
| `P_AnimateSurfaces` | 3 | Hexen\p_anim (2), p_tick |
| `P_InitAnimations` | 3 | Hexen\p_anim (2), p_setup |
| `P_ShutDownAnimations` | 3 | Hexen\p_anim (2), p_setup |
| `P_InitFTAnims` | 9 | Hexen\p_anim (7), Hexen\p_spec, p_setup |

### `Base\nd_main.pas` - 13 funzioni pubbliche, 21 chiamate

Per toglierla: costruzione dei nodi: `p_setup` dovrebbe chiamare `INodeBuilder` della libreria Nodes invece di `ND_*`.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `gld_GetGLMapLump` | 1 | p_setup |
| `gld_GetGLNodesVersion` | 1 | p_setup |
| `gld_GetGLVertexes` | 1 | gl_setup |
| `ND_Configure` | 1 | DelphiDoom.Engine.Composition |
| `ND_LoadNodes` | 1 | p_setup |
| `ND_LoadSegs` | 1 | p_setup |
| `ND_LoadSubsectors` | 1 | p_setup |
| `ND_ReadGwa` | 1 | p_setup |
| `ND_GetNodes` | 2 | p_setup (2) |
| `ND_LoadVertexes` | 2 | p_setup (2) |
| `ND_NodesCheck` | 2 | p_setup (2) |
| `ND_ReadLumpBytes` | 3 | p_setup (3) |
| `gld_BuildNodes` | 4 | Doom\d_main, Heretic\d_main, Hexen\d_main, Strife\d_main |

### `Base\e_endoom.pas` - 6 funzioni pubbliche, 22 chiamate

**Tolta (issue #137)**: `IEngineEndoomScreen` (`TEngineEndoomScreen`) dato a `d_main`, `g_game`, `d_net` e `gl_main`.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `E_ConfigureEndoom` | 1 | DelphiDoom.Engine.Composition |
| `E_Drawer` | 3 | Doom\d_main, Heretic\d_main, Strife\d_main |
| `E_Responder` | 3 | Doom\g_game, Heretic\g_game, Strife\g_game |
| `E_Ticker` | 3 | d_net (3) |
| `E_Init` | 6 | Doom\g_game (2), Heretic\g_game (2), Strife\g_game (2) |
| `E_ShutDown` | 6 | Doom\d_main (2), Heretic\d_main (2), Strife\d_main (2) |

### `Base\r_colormaps.pas` - 6 funzioni pubbliche, 23 chiamate

Per toglierla: renderer: colormap personalizzate; resta finche il renderer legge i puntatori.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `R_CustomColorMapColor32` | 0 | - |
| `R_ConfigureCustomColormaps` | 1 | DelphiDoom.Engine.Composition |
| `R_InitCustomColormaps` | 2 | r_main (2) |
| `R_RecalcColormaps` | 2 | r_main (2) |
| `R_ShutDownCustomColormaps` | 2 | r_main (2) |
| `R_CustomColorMapForName` | 16 | Doom\p_saveg (6), p_setup (3), r_data, Strife\p_saveg (6) |

### `Base\i_sound.pas` - 14 funzioni pubbliche, 25 chiamate

Per toglierla: la cache dei campioni (`I_CacheSFX`) e il motore di `s_sound`: servirebbe un `ISfxCache` e che `s_sound` ricevesse `ISfxPlayer`.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `I_ConfigureSound` | 1 | DelphiDoom.Engine.Composition |
| `I_DiscardExternalSfx` | 1 | DelphiDoom.Engine.Audio.SfxSampleSource |
| `I_GetSfxSample` | 1 | DelphiDoom.Engine.Audio.SfxSampleSource |
| `I_SetChannels` | 1 | s_sound |
| `I_SetUseExternalWav` | 1 | s_sound |
| `I_SfxName` | 1 | DelphiDoom.Engine.Audio.SfxSampleSource |
| `I_StopSound` | 1 | s_sound |
| `I_StoreSfxAverageBytes` | 1 | DelphiDoom.Engine.Audio.SfxSampleSource |
| `I_UpdateSoundParams` | 1 | s_sound |
| `I_ShutDownSound` | 2 | i_system (2) |
| `I_StartSound` | 2 | s_sound (2) |
| `I_GetSfxLumpNum` | 3 | s_sound (3) |
| `I_SoundIsPlaying` | 3 | s_sound (3) |
| `I_InitSound` | 6 | DelphiDoom.Engine.Audio.DirectSoundDevice (4), i_system (2) |

### `Base\i_tmp.pas` - 5 funzioni pubbliche, 27 chiamate

Per toglierla: file temporanei: i chiamanti dovrebbero ricevere `ITempFiles`.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `I_ConfigureTempFiles` | 1 | DelphiDoom.Engine.Composition |
| `I_ShutDownTempFiles` | 2 | i_system (2) |
| `I_DeclareTempFile` | 3 | nd_main, s_pk3sounds, vx_voxelsprite |
| `I_InitTempFiles` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `I_NewTempFile` | 13 | DelphiDoom.Engine.Music.MidiFileBackend, DelphiDoom.Engine.Music.XmiBackend, Doom\p_saveg (2), Heretic\p_saveg (2), Hexen\sv_save (2), nd_main, ps_dll, Strife\p_saveg (2), +1 altri |

### `Heretic\d_main.pas` - 17 funzioni pubbliche, 29 chiamate

Per toglierla: ciclo principale di gioco: resta.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `D_AddFile` | 0 | - |
| `D_FileInDoomPath` | 0 | - |
| `D_PageDrawer` | 0 | - |
| `D_AdvanceDemo` | 1 | g_game |
| `D_ConfigureIwad` | 1 | DelphiDoom.Engine.Composition |
| `D_Configure` | 1 | DelphiDoom.Engine.Composition |
| `D_PageTicker` | 1 | g_game |
| `D_PostEvent` | 1 | DelphiDoom.Engine.Input.Sink |
| `D_ProcessEvents` | 1 | DelphiDoom.Engine.Net.Services |
| `D_DoAdvanceDemo` | 2 | d_net (2) |
| `D_DoomMain` | 2 | gl_main, i_main |
| `D_ShutDown` | 2 | i_system (2) |
| `D_StartTitle` | 2 | g_game, m_menu |
| `D_EngineVersion` | 3 | d_net, m_misc (2) |
| `D_Display` | 4 | d_net (4) |
| `D_VersionBuilt` | 4 | deh_main, gl_main, i_main, i_startup |
| `D_Version` | 4 | deh_main, gl_main, i_main, i_startup |

### `Hexen\d_main.pas` - 17 funzioni pubbliche, 29 chiamate

Per toglierla: ciclo principale di gioco: resta.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `D_AddFile` | 0 | - |
| `D_FileInDoomPath` | 0 | - |
| `D_PageDrawer` | 0 | - |
| `D_AdvanceDemo` | 1 | g_demo |
| `D_ConfigureIwad` | 1 | DelphiDoom.Engine.Composition |
| `D_Configure` | 1 | DelphiDoom.Engine.Composition |
| `D_PageTicker` | 1 | g_game |
| `D_PostEvent` | 1 | DelphiDoom.Engine.Input.Sink |
| `D_ProcessEvents` | 1 | DelphiDoom.Engine.Net.Services |
| `D_DoAdvanceDemo` | 2 | d_net (2) |
| `D_DoomMain` | 2 | gl_main, i_main |
| `D_ShutDown` | 2 | i_system (2) |
| `D_StartTitle` | 2 | g_game, m_menu |
| `D_EngineVersion` | 3 | d_net, m_misc (2) |
| `D_Display` | 4 | d_net (4) |
| `D_VersionBuilt` | 4 | deh_main, gl_main, i_main, i_startup |
| `D_Version` | 4 | deh_main, gl_main, i_main, i_startup |

### `Doom\d_main.pas` - 17 funzioni pubbliche, 29 chiamate

Per toglierla: ciclo principale di gioco: resta.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `D_AddFile` | 0 | - |
| `D_FileInDoomPath` | 0 | - |
| `D_PageDrawer` | 0 | - |
| `D_AdvanceDemo` | 1 | g_game |
| `D_ConfigureIwad` | 1 | DelphiDoom.Engine.Composition |
| `D_Configure` | 1 | DelphiDoom.Engine.Composition |
| `D_PageTicker` | 1 | g_game |
| `D_PostEvent` | 1 | DelphiDoom.Engine.Input.Sink |
| `D_ProcessEvents` | 1 | DelphiDoom.Engine.Net.Services |
| `D_DoAdvanceDemo` | 2 | d_net (2) |
| `D_DoomMain` | 2 | gl_main, i_main |
| `D_ShutDown` | 2 | i_system (2) |
| `D_StartTitle` | 2 | g_game, m_menu |
| `D_EngineVersion` | 3 | d_net, m_misc (2) |
| `D_Display` | 4 | d_net (4) |
| `D_VersionBuilt` | 4 | deh_main, gl_main, i_main, i_startup |
| `D_Version` | 4 | deh_main, gl_main, i_main, i_startup |

### `Base\i_music.pas` - 21 funzioni pubbliche, 30 chiamate

Per toglierla: migrare i chiamanti di `I_PlaySong`/`I_RegisterSong` (`s_sound`) a `IMusicPlayer`; la parte MUS/midi stream e ancora in questa unit.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `I_ConfigureMusic` | 1 | DelphiDoom.Engine.Composition |
| `I_InitMus` | 1 | DelphiDoom.Engine.Music.MusBackend |
| `I_PauseSongMus` | 1 | DelphiDoom.Engine.Music.MusBackend |
| `I_PauseSong` | 1 | s_sound |
| `I_PlayMus` | 1 | DelphiDoom.Engine.Music.MusBackend |
| `I_PlaySong` | 1 | s_sound |
| `I_ProcessMusicMus` | 1 | DelphiDoom.Engine.Music.MusBackend |
| `I_ProcessMusic` | 1 | i_system |
| `I_RegisterMus` | 1 | DelphiDoom.Engine.Music.MusBackend |
| `I_ResumeSongMus` | 1 | DelphiDoom.Engine.Music.MusBackend |
| `I_SelectDefaultMidiDevice` | 1 | i_midi_new |
| `I_SetMusicVolumeMus` | 1 | DelphiDoom.Engine.Music.MusBackend |
| `I_SetMusicVolume` | 1 | s_sound |
| `I_StopSongMus` | 1 | DelphiDoom.Engine.Music.MusBackend |
| `I_UnRegisterSongMus` | 1 | DelphiDoom.Engine.Music.MusBackend |
| `I_UnRegisterSong` | 1 | s_sound |
| `I_InitMusic` | 2 | i_system (2) |
| `I_ResumeSong` | 2 | s_sound (2) |
| `I_ShutDownMusic` | 2 | i_system (2) |
| `I_StopMus` | 3 | DelphiDoom.Engine.Music.MidiFileBackend, DelphiDoom.Engine.Music.MusBackend, DelphiDoom.Engine.Music.XmiBackend |
| `I_RegisterSong` | 5 | DelphiDoom.Engine.Music.MidiFileBackend, DelphiDoom.Engine.Music.XmiBackend, s_externalmusic, s_sound (2) |

### `TEXLIB\t_main.pas` - 6 funzioni pubbliche, 30 chiamate

Per toglierla: `T_LoadHiResTexture` ha pochi chiamanti: iniettare i decoder.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `T_ConfigureTextures` | 1 | DelphiDoom.Engine.Composition |
| `T_LoadHiResImage` | 1 | DelphiDoom.Engine.Texture.Resolver |
| `T_IsTextureExtension` | 2 | r_pk3textures, w_sprite |
| `T_Init` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `T_ShutDown` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `T_LoadHiResTexture` | 10 | gl_tex (5), r_cache_flats (2), r_cache_walls, r_pk3textures, t_draw |

### `Strife\d_main.pas` - 17 funzioni pubbliche, 31 chiamate

Per toglierla: ciclo principale di gioco: resta.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `D_AddFile` | 0 | - |
| `D_FileInDoomPath` | 0 | - |
| `D_PageDrawer` | 0 | - |
| `D_AdvanceDemo` | 1 | g_game |
| `D_ConfigureIwad` | 1 | DelphiDoom.Engine.Composition |
| `D_Configure` | 1 | DelphiDoom.Engine.Composition |
| `D_PostEvent` | 1 | DelphiDoom.Engine.Input.Sink |
| `D_ProcessEvents` | 1 | DelphiDoom.Engine.Net.Services |
| `D_DoAdvanceDemo` | 2 | d_net (2) |
| `D_DoomMain` | 2 | gl_main, i_main |
| `D_PageTicker` | 2 | g_game (2) |
| `D_ShutDown` | 2 | i_system (2) |
| `D_EngineVersion` | 3 | d_net, m_misc (2) |
| `D_StartTitle` | 3 | f_finale, g_game, m_menu |
| `D_Display` | 4 | d_net (4) |
| `D_VersionBuilt` | 4 | deh_main, gl_main, i_main, i_startup |
| `D_Version` | 4 | deh_main, gl_main, i_main, i_startup |

### `Base\r_translations.pas` - 9 funzioni pubbliche, 37 chiamate

Per toglierla: passare `ITranslationNames` a chi chiede le tabelle (sprite e sangue).

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `R_BloodTranslation` | 0 | - |
| `R_GetTranslationTable` | 0 | - |
| `R_ConfigureTranslations` | 1 | DelphiDoom.Engine.Composition |
| `R_InitTranslations` | 2 | r_main (2) |
| `R_ShutDownTranslations` | 2 | r_main (2) |
| `R_GetBloodName` | 3 | psi_game, sc_actordef (2) |
| `R_GetBloodTranslationIdForName` | 6 | Doom\deh_main, Heretic\deh_main, Hexen\deh_main, psi_game, p_common, Strife\deh_main |
| `R_InitMobjTranslation` | 10 | Doom\p_mobj, Doom\p_saveg, Heretic\p_mobj, Heretic\p_saveg, Hexen\p_mobj, Hexen\sv_save, psi_game, p_common, +2 altri |
| `R_SetMobjBloodTranslation` | 13 | Doom\p_map (3), Doom\p_mobj, Heretic\p_map, Heretic\p_mobj (2), Hexen\p_map, Hexen\p_mobj (2), Strife\p_enemy, Strife\p_map, +1 altri |

### `Base\sc_actordef.pas` - 9 funzioni pubbliche, 40 chiamate

Per toglierla: i giochi chiamano `SC_ParseActordefLump`: passare il parser agli `*_main`.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `SC_ConfigureActorDef` | 1 | DelphiDoom.Engine.Composition |
| `SC_GetWeapondefDeclaration` | 1 | deh_base |
| `SC_ParseActordefLump` | 1 | DelphiDoom.Engine.Composition |
| `SC_SoundAlias` | 1 | sounds |
| `SC_GetActordefDeclaration` | 2 | dd_compiler, deh_base |
| `SC_ParseActordefLumps` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `SC_ParseSndInfoLumps` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `SC_Init` | 9 | dd_compiler, Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `SC_ShutDown` | 9 | dd_compiler, Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |

### `Base\c_con.pas` - 12 funzioni pubbliche, 51 chiamate

Per toglierla: separare il disegno della console (legato a `screens[]`) dal modello; il resto e gia a classi in Libs\Console.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `C_AddText` | 0 | - |
| `C_ConfigureInput` | 1 | DelphiDoom.Engine.Composition |
| `C_ConfigureScripts` | 1 | DelphiDoom.Engine.Composition |
| `C_ConsolePos` | 1 | gl_main |
| `C_AddCommand` | 2 | psi_system, p_common |
| `C_AdjustScreenSize` | 2 | gl_main, v_displaymode |
| `C_Ticker` | 2 | d_net (2) |
| `C_Responder` | 4 | Doom\d_main, Heretic\d_main, Hexen\d_main, Strife\d_main |
| `C_IsConsoleActive` | 5 | Doom\d_main, Heretic\d_main, Hexen\d_main, p_tick, Strife\d_main |
| `C_Init` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `C_ShutDown` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `C_Drawer` | 17 | Doom\d_main (4), gl_main, Heretic\d_main (4), Hexen\d_main (4), Strife\d_main (4) |

### `Base\sc_defines.pas` - 3 funzioni pubbliche, 53 chiamate

Per toglierla: solo i define di gioco: nessuna classe da introdurre.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `SC_InitGameDefines` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `SC_ShutDownGameDefines` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `SC_AddDefine` | 37 | Doom\d_main (22), Heretic\d_main (5), Hexen\d_main (5), Strife\d_main (5) |

### `Base\d_net.pas` - 10 funzioni pubbliche, 54 chiamate

Per toglierla: i chiamanti (`d_main`, `g_game`) dovrebbero ricevere `INetTicSync` invece di chiamare `NetUpdate`/`D_RunMultipleTicks`; richiede di toccare il ciclo principale di ogni gioco.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `D_ConfigureNet` | 1 | DelphiDoom.Engine.Composition |
| `D_ShutDownNetGame` | 1 | i_net |
| `D_QuitNetGame` | 2 | i_system (2) |
| `D_GetNetCommand` | 4 | Doom\g_game, Heretic\g_game, Hexen\g_game, Strife\g_game |
| `D_RunMultipleTicks` | 4 | Doom\d_main, Heretic\d_main, Hexen\d_main, Strife\d_main |
| `D_RunSingleTick` | 4 | Doom\d_main, Heretic\d_main, Hexen\d_main, Strife\d_main |
| `D_NetExpectedConsistency` | 7 | Doom\g_game (2), Heretic\g_game (2), Hexen\g_game (2), Strife\g_game |
| `D_CheckNetGame` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `D_VerifyNetConsistency` | 8 | Doom\g_game (2), Heretic\g_game (2), Hexen\g_game (2), Strife\g_game (2) |
| `NetUpdate` | 15 | Doom\d_main, Heretic\d_main, Hexen\d_main, r_main (11), Strife\d_main [test: 51] |

### `Base\am_map.pas` - 15 funzioni pubbliche, 55 chiamate

Per toglierla: spostare l'automap (Libs\Automap) dietro un IAutomap e passare i globali di vista (`viewx`, `players`, `lines`) come parametri; il disegno resta per fotogramma.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `FTOM` | 0 | - |
| `M_ZOOMIN` | 0 | - |
| `M_ZOOMOUT` | 0 | - |
| `AM_Configure` | 1 | DelphiDoom.Engine.Composition |
| `AM_GetWindow` | 1 | am_textured |
| `AM_rotate` | 1 | am_textured |
| `CXMTOF` | 1 | am_textured |
| `CYMTOF` | 1 | am_textured |
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
| `R_FillBackStatusbar` | 1 | v_video |
| `R_InitBuffer` | 1 | r_main |
| `R_InitTranslationTables` | 1 | r_main |
| `R_ConfigurePlayerTranslations` | 3 | DelphiDoom.Engine.Composition (3) |
| `R_DrawDiskBusy` | 4 | Doom\d_main, Heretic\d_main, Hexen\d_main, Strife\d_main |
| `R_VideoBlanc` | 5 | Doom\st_stuff (2), Strife\st_stuff (3) |
| `R_VideoErase` | 6 | hu_lib (6) |
| `R_DrawViewBorder` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `R_FillBackScreen` | 14 | Doom\d_main (2), Doom\g_game (2), Heretic\d_main (2), Heretic\g_game (2), Hexen\d_main (2), Strife\d_main (2), Strife\g_game (2) |
| `R_PlayerViewBlanc` | 17 | Doom\d_main (4), Heretic\d_main (4), Hexen\d_main (4), r_camera, Strife\d_main (4) |

### `Base\i_video.pas` - 9 funzioni pubbliche, 73 chiamate

Per toglierla: DirectDraw/blit legati a `screens[]` e al renderer (#41, #42); resta finche non c'e una superficie astratta.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `I_BlitBuffer` | 1 | mn_screenshot |
| `I_SetPalette64` | 1 | r_main |
| `I_InitGraphics` | 5 | Doom\d_main, Heretic\d_main, Hexen\d_main, Strife\d_main, v_displaymode |
| `I_ShutDownGraphics` | 5 | gl_main (2), i_system (2), v_displaymode |
| `I_FinishUpdate` | 6 | Doom\d_main, gl_main (2), Heretic\d_main, Hexen\d_main, Strife\d_main |
| `IV_SetPalette` | 7 | Doom\d_main, Doom\m_menu, Doom\st_stuff (2), Strife\d_main, Strife\st_stuff (2) |
| `I_ReadScreen32` | 8 | f_wipe (2), gl_main (2), mn_screenshot, m_misc, Strife\f_fade (2) |
| `I_ChangeFullScreen` | 10 | c_utils, Doom\m_menu (2), Heretic\m_menu (2), Hexen\m_menu (2), r_hires, Strife\m_menu (2) |
| `I_SetPalette` | 30 | Doom\d_main, Doom\m_menu, Doom\st_stuff (2), e_endoom (2), gl_main (2), Heretic\d_main, Heretic\f_finale (2), Heretic\in_stuff, +12 altri |

### `Base\p_acs.pas` - 14 funzioni pubbliche, 76 chiamate

Per toglierla: l'interprete ACS lavora sullo stato del gioco; servirebbe un `IAcsHost` completo (gia in parte) e togliere i globali `ACS*`.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `P_CheckACSStore` | 1 | Hexen\sv_save |
| `P_ConfigureAcs` | 1 | DelphiDoom.Engine.Composition |
| `P_LoadACScripts` | 2 | p_setup (2) |
| `P_StartLockedACS` | 2 | Hexen\p_spec, udmf_spec |
| `P_SuspendACS` | 2 | Hexen\p_spec, udmf_spec |
| `P_TerminateACS` | 2 | Hexen\p_spec, udmf_spec |
| `P_ACSInitNewGame` | 4 | Doom\g_game, Heretic\g_game, Hexen\g_game, Strife\g_game |
| `P_PolyobjFinished` | 4 | po_man (4) |
| `P_ACSInit` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `P_ACSShutDown` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `TH_InterpretACS` | 8 | DelphiDoom.Engine.Acs.Host, Doom\p_saveg (2), Heretic\p_saveg (2), Hexen\sv_save, Strife\p_saveg (2) |
| `P_TagFinished` | 10 | udmf_ceilng (2), udmf_doors (2), udmf_floor (4), udmf_plats (2) |
| `P_ACSMachine` | 12 | Hexen\sv_save (12) |
| `P_StartACS` | 12 | Hexen\p_enemy (7), Hexen\p_inter, Hexen\p_map (2), Hexen\p_spec, udmf_spec [test: 1] |

### `Base\w_pak.pas` - 13 funzioni pubbliche, 80 chiamate

Per toglierla: ~100 chiamanti `PAK_*`/`I_*` dei percorsi: passare `IEngineWadServices` ai moduli.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `PAK_AddDirectory` | 0 | - |
| `PAK_GetMatchingEntries` | 0 | - |
| `PAK_Configure` | 1 | DelphiDoom.Engine.Composition |
| `PAK_GetGlobalHash` | 2 | r_pk3textures (2) |
| `PAK_ReadAllFilesAsString` | 2 | DelphiDoom.Engine.ActorDef.Hooks, DelphiDoom.Engine.Scanner.IncludeSource |
| `PAK_FileNameIterator` | 3 | r_pk3textures, s_pk3sounds, vx_voxelsprite |
| `PAK_GetDirectoryListFromString` | 4 | Doom\d_main, Heretic\d_main, Hexen\d_main, Strife\d_main |
| `PAK_LoadPendingPaks` | 4 | Doom\d_main, Heretic\d_main, Hexen\d_main, Strife\d_main |
| `PAK_ReadFileAsString` | 6 | DelphiDoom.Engine.ActorDef.Hooks (2), DelphiDoom.Engine.Scanner.IncludeSource, ps_import, ps_main (2) |
| `PAK_InitFileSystem` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `PAK_ShutDown` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `PAK_StringIterator` | 17 | deh_base (3), DelphiDoom.Engine.DynLights.Services, DelphiDoom.Engine.MapInfo.TextSource, gl_models (2), r_flatinfo (2), sc_actordef (6), vx_base (2) |
| `PAK_AddFile` | 25 | DelphiDoom.Engine.Wad.AutoLoadSink, Doom\d_main (6), Heretic\d_main (6), Hexen\d_main (6), Strife\d_main (6) |

### `Base\m_misc.pas` - 15 funzioni pubbliche, 98 chiamate

Per toglierla: `M_LoadDefaults`/`M_SaveDefaults` leggono la tabella `defaults` con puntatori ai globali: servirebbe una tabella di impostazioni a oggetti.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `M_SetDefault` | 0 | - |
| `M_ConfigureDefaults` | 1 | DelphiDoom.Engine.Composition |
| `M_ConfigureFiles` | 1 | DelphiDoom.Engine.Composition |
| `M_ConfigureScreenshot` | 1 | DelphiDoom.Engine.Composition |
| `M_ForceDefaultInteger` | 2 | DelphiDoom.Engine.Scanner.CvarSetter, psi_system |
| `M_ForceDefaultString` | 2 | DelphiDoom.Engine.Scanner.CvarSetter, psi_system |
| `M_ForceDefaultBoolean` | 3 | DelphiDoom.Engine.Scanner.CvarSetter, Doom\d_main, psi_system |
| `M_SaveDefaults` | 5 | i_system (2), Launcher_defs (2), Launcher_main |
| `M_FixScreenshotFormat` | 8 | Doom\m_menu (2), Heretic\m_menu (2), Hexen\m_menu (2), Strife\m_menu (2) |
| `M_ScreenShot` | 8 | Doom\d_main, Doom\g_game, Heretic\d_main, Heretic\g_game, Hexen\d_main, Hexen\g_game, Strife\d_main, Strife\g_game |
| `M_SetDefaults` | 8 | Doom\m_menu (2), Heretic\m_menu (2), Hexen\m_menu (2), Strife\m_menu (2) |
| `M_LoadDefaults` | 11 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Launcher_defs (2), Launcher_main, Strife\d_main (2) |
| `M_WriteFile` | 13 | Doom\g_game (2), Heretic\g_game (2), Hexen\g_demo, psi_globals, Strife\g_game (4), Strife\p_saveg (2), w_utils |
| `M_ReadFile` | 14 | Doom\g_game (2), Heretic\g_game (2), Hexen\g_demo, Hexen\sv_save (2), psi_globals, Strife\g_game (3), Strife\m_menu (2), Strife\p_saveg |
| `M_AppendFile` | 21 | Doom\g_game (7), Heretic\g_game (7), Strife\g_game (7) |

### `Base\udmf_spec.pas` - 12 funzioni pubbliche, 114 chiamate

Per toglierla: gli esecutori `EVH_*` dei thinker non si possono astrarre (savegame): resta.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `P_ArgsToLine` | 0 | - |
| `P_LineToArgs` | 0 | - |
| `P_ConfigureLineSpecials` | 1 | DelphiDoom.Engine.Composition |
| `P_InitLightning` | 3 | Hexen\p_anim (2), p_setup |
| `P_ForceLightning` | 5 | Hexen\p_anim (2), Hexen\p_spec, psi_map (2) |
| `P_LightningFlash` | 5 | Doom\p_spec, Heretic\p_spec, Hexen\p_anim (2), Strife\p_spec |
| `P_FindSectorFromTag2` | 7 | DelphiDoom.Engine.Acs.Host (2), Hexen\p_spec (3), udmf_lights, udmf_plats |
| `P_FindLine` | 8 | DelphiDoom.Engine.Acs.Host (6), Hexen\p_spec (2) |
| `P_ExecuteLineSpecial` | 12 | DelphiDoom.Engine.Acs.Host, Hexen\p_enemy, Hexen\p_inter (6), Hexen\p_spec (3), Hexen\p_user |
| `P_FindSectorFromTag` | 12 | Hexen\p_spec (3), udmf_ceilng, udmf_doors, udmf_floor (7) |
| `P_ExecuteActorSpecial` | 27 | Doom\p_inter (8), Heretic\p_inter (15), Strife\p_inter (4) |
| `P_ActivateLine` | 34 | Doom\p_enemy, Doom\p_map (7), Heretic\p_enemy, Heretic\p_map (7), Hexen\p_enemy, Hexen\p_map (7), Hexen\p_spec (2), Strife\p_enemy, +1 altri |

### `Strife\deh_main.pas` - 6 funzioni pubbliche, 170 chiamate

Per toglierla: applica la patch al gioco: resta come adattatore di `IDehackedPatch`.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `DEH_Configure` | 1 | DelphiDoom.Engine.Composition |
| `DEH_Parse` | 3 | deh_base (2), SynHighlighterActorDef [test: 18] |
| `DEH_ShutDown` | 3 | dd_compiler, d_main (2) |
| `DEH_CurrentSettings` | 4 | deh_base (4) |
| `DEH_Init` | 5 | dd_compiler, deh_base (2), d_main (2) |
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

### `Base\m_cheat.pas` - 5 funzioni pubbliche, 185 chiamate

Per toglierla: i giochi chiamano `cht_CheckCheat` per ogni cheat: servirebbe la `TCheatTable` della libreria e una tabella per gioco.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `cht_CheckCheat` | 4 | Doom\st_stuff, Heretic\sb_bar, Hexen\sb_bar, Strife\st_stuff |
| `cht_GetParam` | 9 | Doom\st_stuff (2), Heretic\sb_bar (2), Hexen\sb_bar (2), Strife\st_stuff (3) |
| `get_cheatseq_string` | 172 | am_map (2), Doom\st_stuff (34), Heretic\sb_bar (44), Hexen\sb_bar (50), Strife\st_stuff (42) |

### `Base\r_data.pas` - 20 funzioni pubbliche, 208 chiamate

Per toglierla: renderer: texture e lookup, percorso caldo; resta come facciata.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `R_CacheFlat` | 0 | - |
| `R_ChangeColormap` | 1 | p_setup |
| `R_ConfigureColormaps` | 1 | DelphiDoom.Engine.Composition |
| `R_ConfigureComposite` | 1 | DelphiDoom.Engine.Composition |
| `R_ConfigureTextureDefs` | 1 | DelphiDoom.Engine.Composition |
| `R_FreeMemory` | 2 | r_main (2) |
| `R_GetDSs` | 2 | r_plane, r_slopes |
| `R_InitData` | 2 | r_main (2) |
| `R_NewFlatNumForLump` | 2 | Doom\p_spec, Strife\p_spec |
| `R_SafeFlatNumForName` | 2 | psi_game (2) |
| `R_SetupLevel` | 2 | p_setup (2) |
| `R_PrecacheLevel` | 3 | p_setup (3) |
| `R_NameForSideTexture` | 13 | Doom\p_saveg (3), Heretic\p_saveg (3), Hexen\sv_save (3), psi_game, Strife\p_saveg (3) |
| `R_GetLumpForFlat` | 15 | am_textured (3), Doom\m_menu, gl_render (6), Heretic\m_menu, Hexen\m_menu, r_cache_flats, Strife\m_menu, v_video |
| `R_GetDCs` | 16 | r_3dfloors (8), r_plane (6), r_segs (2) |
| `R_CheckTextureNumForName` | 19 | DelphiDoom.Engine.Definitions.AnimCatalog, DelphiDoom.Engine.Definitions.TextureLookup, Doom\g_game (4), Doom\p_spec, Heretic\g_game, Heretic\p_spec, Hexen\p_anim, Hexen\p_mapinfo, +6 altri |
| `R_GetColumn` | 21 | Hexen\r_cache_sky1, Hexen\r_cache_sky1_dbl, Hexen\r_cache_sky2 (2), r_3dfloors (4), r_cache_walls (4), r_plane (3), R_RenderSegLoop8 (5), r_segs |
| `R_SafeTextureNumForName` | 27 | Doom\p_saveg (6), Heretic\p_saveg (6), Hexen\sv_save (6), p_setup (3), Strife\p_saveg (6) |
| `R_TextureNumForName` | 37 | DelphiDoom.Engine.Acs.Host, Doom\g_game (5), Doom\p_spec (2), Heretic\g_game (5), Heretic\p_spec (2), Heretic\p_switch (2), Hexen\p_anim, Hexen\p_mapinfo (2), +5 altri |
| `R_FlatNumForName` | 41 | DelphiDoom.Engine.Acs.Host, Doom\g_game, Doom\m_menu (2), Doom\p_saveg (4), Doom\p_spec (2), Heretic\g_game, Heretic\m_menu (2), Heretic\p_saveg (4), +12 altri |

### `Base\r_main.pas` - 26 funzioni pubbliche, 279 chiamate

Per toglierla: renderer: resta.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `R_AddPointToBox` | 0 | - |
| `R_ApplyColormap` | 1 | c_con |
| `R_ConfigureLightTables` | 1 | DelphiDoom.Engine.Composition |
| `R_PointInSubsectorClassic` | 1 | r_subsectors |
| `R_PointOnSideVanilla` | 1 | Doom\p_map |
| `R_SetPalette64` | 1 | r_data |
| `R_PointOnLineSide` | 2 | p_bouncing (2) |
| `R_PointOnSide` | 2 | r_bsp (2) |
| `R_PointToDist` | 2 | ps_import (2) |
| `R_StOff` | 2 | Heretic\sb_bar, Hexen\sb_bar |
| `R_Ticker` | 2 | d_net (2) |
| `R_SetViewAngleOffset` | 3 | i_net (3) |
| `R_FullStOn` | 4 | Doom\d_main, Heretic\d_main, Hexen\sb_bar, Strife\d_main |
| `R_RenderPlayerView` | 4 | Doom\d_main, Heretic\d_main, Hexen\d_main, Strife\d_main |
| `R_SetRenderingFunctions` | 5 | Doom\d_main, Heretic\d_main, Hexen\d_main, r_data, Strife\d_main |
| `R_PointToAngleEx` | 7 | r_bsp (6), r_voxels |
| `R_ExecuteSetViewSize` | 8 | Doom\d_main, Doom\g_game, gl_main, Heretic\d_main, Heretic\g_game, Hexen\d_main, Strife\d_main, Strife\g_game |
| `R_Init` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `R_PointToAngle` | 8 | ps_import (2), r_bsp (2), r_softlights, r_things (3) |
| `R_ShutDown` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `R_PointOnSegSide` | 11 | R_DrawColumnLightmap32FF_Main, R_DrawColumnLightmap32Masked_Main, R_DrawColumnLightmap32_Main, R_DrawColumnLightmap8FF_Main, R_DrawColumnLightmap8Masked_Main, R_DrawColumnLightmap8_Main, r_subsectors, r_things (3), +1 altri |
| `R_SetViewSize` | 15 | Doom\m_menu (2), Heretic\m_menu (2), Hexen\m_menu (2), r_hires (7), Strife\m_menu (2) |
| `R_GetColormap32` | 16 | r_3dfloors (10), R_RenderSegLoop32 (2), r_segs (2), r_things, r_voxels |
| `R_GetColormapLightLevel` | 19 | r_3dfloors (4), r_plane (4), R_RenderSegLoop32 (2), r_segs, r_slopes (6), r_things, r_voxels |
| `R_PointInSubsector` | 45 | Doom\p_map, gl_lightmaps, Heretic\g_game, Heretic\p_map (3), Heretic\p_mobj (4), Heretic\p_pspr, Hexen\g_game, Hexen\p_map (3), +15 altri |
| `R_PointToAngle2` | 103 | Doom\p_enemy (4), Doom\p_inter, Doom\p_map (2), Doom\p_mobj (2), Doom\p_pspr (2), Doom\p_spec (3), Doom\p_telept (3), Doom\p_user (2), +34 altri |

### `Base\c_cmds.pas` - 8 funzioni pubbliche, 363 chiamate

Per toglierla: migrare le circa 320 chiamate `C_AddCmd` a un registratore per area (ogni modulo riceve `ICommandRegistry` dal composition root); poi `C_ExecuteCmd` diventa un metodo dell'interprete.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `C_CmdExists` | 1 | m_misc |
| `C_ConfigureCommands` | 1 | DelphiDoom.Engine.Composition |
| `C_GetMachingList` | 2 | m_argv, m_misc |
| `C_BoolEval` | 24 | am_map, DelphiDoom.Engine.Scanner.CvarSetter, i_system, r_aspect (2), r_hires (10), r_intrpl (2), r_main (5), s_sound (2) |
| `C_ExecuteCmd` | 38 | c_con (2), c_utils, Doom\g_game (3), Doom\m_menu (4), Doom\p_inter, Doom\st_stuff, Heretic\g_game (2), Heretic\m_menu (4), +12 altri |
| `C_AddCmd` | 297 | am_map, c_con (15), c_utils (8), Doom\deh_main (8), Doom\d_main (5), Doom\m_menu (23), Doom\p_mobj (2), Doom\st_stuff (9), +35 altri |

### `Base\m_argv.pas` - 7 funzioni pubbliche, 479 chiamate

Per toglierla: `M_CheckParm` ha ~400 chiamanti e `myargv`/`myargc` sono letti direttamente: servirebbe passare `ICommandLine` ai moduli.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `M_CmdShowCmdline` | 1 | c_con |
| `M_CmdShowCommandLineParams` | 1 | c_con |
| `M_ConfigureArgv` | 1 | DelphiDoom.Engine.Composition |
| `M_InitArgv` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `M_CheckParmCDROM` | 10 | Doom\d_main, Doom\g_game, Heretic\d_main, Heretic\g_game, Hexen\d_main, Hexen\g_demo, i_io, r_draw, +2 altri |
| `M_SaveFileName` | 72 | deh_base (9), DelphiDoom.Engine.Console.Startup, DelphiDoom.Engine.Platform.TempDirectory, DelphiDoom.Engine.Screenshot.Folders, Doom\d_check (3), Doom\d_main (2), Doom\g_game, Doom\m_menu (2), +19 altri |
| `M_CheckParm` | 386 | DelphiDoom.Engine.Console.Startup, Doom\d_main (95), Doom\g_game, Doom\info (2), Doom\p_spec (2), Heretic\d_main (86), Heretic\g_game, Heretic\p_spec (2), +15 altri |

### `Base\v_video.pas` - 52 funzioni pubbliche, 579 chiamate

Per toglierla: disegno sullo schermo (`screens[]`): resta.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `V_CalcPreserveTables` | 0 | - |
| `V_DrawBlock` | 0 | - |
| `V_DrawLongBlock` | 0 | - |
| `V_GetBlock` | 0 | - |
| `V_NeedsPreserve` | 0 | - |
| `V_PreserveH` | 0 | - |
| `V_PreserveW` | 0 | - |
| `V_PreserveX` | 0 | - |
| `V_ConfigureGamma` | 1 | DelphiDoom.Engine.Composition |
| `V_CopyAddRect` | 1 | c_con |
| `V_CopyCustomScreen` | 1 | e_endoom |
| `V_CopyRawDataToScreen` | 1 | c_con |
| `V_CopyScreenTransparent` | 1 | r_draw |
| `V_DrawPatchFullScreenTMP426x200` | 1 | Doom\wi_stuff |
| `V_StatusBarStretch` | 1 | Doom\st_stuff |
| `V_CalcColorMapPalette` | 2 | r_main (2) |
| `V_DrawPatchFlipped` | 2 | Doom\f_finale, Strife\f_finale |
| `V_DrawPatchTransparentMT` | 2 | Strife\st_stuff (2) |
| `V_FindAproxColorIndexExcluding` | 2 | r_trans8 (2) |
| `V_PreserveGLX` | 2 | hu_lib (2) |
| `V_RemoveTransparency` | 2 | r_draw (2) |
| `V_PreserveGLY` | 3 | hu_lib (3) |
| `V_ReInit` | 4 | gl_main, i_video (2), v_displaymode |
| `V_DrawPatchTransparent` | 6 | hu_stuff (2), p_simpledialog, Strife\st_stuff (3) |
| `V_ScreensSize` | 6 | Doom\d_main, Doom\f_finale, Heretic\d_main, Heretic\f_finale, Hexen\d_main, Strife\d_main |
| `V_TileScreen8` | 6 | Doom\f_finale, Heretic\f_finale, Heretic\in_stuff (4) |
| `V_CopyRectTransparentEx` | 8 | Doom\m_menu (2), Heretic\m_menu (2), Hexen\m_menu (2), Strife\m_menu (2) |
| `V_Init` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `V_ShutDown` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `V_DrawPatchZoomed` | 10 | am_map, Heretic\m_menu (2), Hexen\m_menu (3), Strife\m_menu (4) |
| `V_DrawPatchFullScreenTMP320x200` | 12 | c_con (2), Doom\f_finale, Doom\wi_stuff, Heretic\in_stuff (3), Strife\f_finale (5) |
| `V_ShadeBackground` | 12 | Doom\m_menu (3), Heretic\m_menu (3), Hexen\m_menu (3), Strife\m_menu (3) |
| `V_ShadeScreen` | 12 | Doom\m_menu (3), Heretic\m_menu (3), Hexen\m_menu (3), Strife\m_menu (3) |
| `V_FullScreenStretch` | 15 | Doom\f_finale (3), Doom\wi_stuff, Heretic\f_finale (3), Heretic\in_stuff, Hexen\f_finale, Hexen\in_stuff, Strife\f_finale (5) |
| `V_PreserveY` | 18 | gl_main (4), hu_lib (3), r_draw (6), r_main (5) |
| `V_FindAproxColorIndex` | 19 | DelphiDoom.Engine.Voxel.ColorMapper, Doom\r_diher (2), e_endoom, Hexen\in_stuff, psi_overlay (3), r_pk3textures (2), r_trans8 (5), r_voxels, +2 altri |
| `V_CopyRect` | 23 | am_map (2), c_con, Doom\f_finale (3), Doom\st_stuff (2), Doom\wi_stuff (2), Heretic\f_finale (3), Heretic\in_stuff, Hexen\f_finale, +4 altri |
| `V_CopyRectTransparent` | 25 | Doom\m_menu (2), Doom\st_stuff (2), Heretic\m_menu (2), Heretic\sb_bar, Hexen\m_menu (2), Hexen\sb_bar, Strife\m_menu (2), Strife\p_dialog, +1 altri |
| `V_SetPalette` | 27 | Doom\d_main, Doom\m_menu, Doom\st_stuff (2), e_endoom (2), Heretic\d_main, Heretic\f_finale (2), Heretic\in_stuff, Heretic\m_menu, +11 altri |
| `V_PageDrawer` | 30 | Doom\d_main, Doom\f_finale (5), Doom\m_menu (5), Heretic\d_main, Heretic\f_finale (6), Heretic\m_menu (3), Hexen\d_main, Hexen\m_menu (3), +2 altri |
| `V_GetScreenWidth` | 38 | c_con (2), Doom\d_main, Doom\m_menu (4), gl_main, Heretic\d_main, Heretic\m_menu (4), Hexen\d_main, Hexen\m_menu (4), +7 altri |
| `V_GetScreenHeight` | 41 | c_con (4), Doom\d_main, Doom\m_menu (4), gl_main, Heretic\d_main, Heretic\m_menu (4), Hexen\d_main, Hexen\m_menu (4), +6 altri |
| `V_DrawPatch` | 229 | c_con (7), Doom\d_main (2), Doom\f_finale (5), Doom\m_menu (41), Doom\st_lib (3), Doom\st_stuff (3), Doom\wi_stuff (2), Heretic\d_main (3), +18 altri |

### `Base\z_zone.pas` - 16 funzioni pubbliche, 697 chiamate

Per toglierla: zone memory: `Z_Malloc` e il cuore del motore (migliaia di chiamanti), resta.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `Z_DumpHeap` | 0 | - |
| `Z_FileDumpHeapf` | 0 | - |
| `Z_FileDumpHeap` | 0 | - |
| `Z_ConfigureZone` | 1 | DelphiDoom.Engine.Composition |
| `Z_MoveUsers` | 1 | w_wad |
| `Z_Size` | 1 | w_sprite |
| `Z_CheckMemory` | 2 | Doom\g_game, Strife\g_game |
| `Z_CheckHeap` | 4 | Doom\g_game, Heretic\g_game, Hexen\g_game, Strife\g_game |
| `Z_FreeTags` | 4 | p_setup (2), r_main (2) |
| `Z_Init` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `Z_ShutDown` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `Z_Malloc2` | 18 | Doom\g_game (3), gl_render (7), Heretic\g_game (3), Hexen\g_demo (2), Strife\g_game (3) |
| `Z_Realloc` | 33 | Doom\p_map (2), Doom\p_saveg (2), gl_render (11), Heretic\p_map (2), Heretic\p_saveg (2), Hexen\p_map (2), Hexen\sv_save (2), p_affectees, +6 altri |
| `Z_Free` | 124 | DelphiDoom.Engine.Music.ExternalSource, Doom\g_game (7), Doom\p_map, Doom\p_saveg (6), Doom\p_spec (2), Doom\wi_stuff, f_wipe, gl_render (2), +36 altri |
| `Z_ChangeTag` | 173 | am_map, c_con, Doom\d_main (2), Doom\f_finale, Doom\m_menu (3), Doom\st_lib, Doom\st_stuff (12), Doom\wi_stuff (28), +32 altri |
| `Z_Malloc` | 320 | DelphiDoom.Audio.SoundLibrary, DelphiDoom.Engine.Acs.Host, DelphiDoom.Engine.Music.ExternalSource, Doom\p_ceilng, Doom\p_doors (4), Doom\p_floor (8), Doom\p_genlin (8), Doom\p_lights (4), +77 altri |

### `Base\w_wad.pas` - 25 funzioni pubbliche, 955 chiamate

Per toglierla: circa mille chiamanti `W_*`: facciata voluta, non si migrano una per una.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `W_CacheLumpNum2` | 0 | - |
| `W_LumpIsNamed` | 0 | - |
| `W_AddPendingWADfromPAK` | 1 | w_pak |
| `W_CheckFirstNumForName` | 1 | r_data |
| `W_Configure` | 1 | DelphiDoom.Engine.Composition |
| `W_GetFirstNumForName` | 1 | r_data |
| `W_CheckNumForName2` | 2 | r_data (2) |
| `W_LumpFlags` | 2 | r_data (2) |
| `W_Reload` | 2 | p_setup (2) |
| `ExtractFileBase8` | 4 | Doom\g_game, Heretic\g_game, Hexen\g_demo, Strife\g_game |
| `W_TextLumpName` | 7 | Hexen\f_finale, Hexen\in_stuff, Hexen\p_anim, Hexen\p_mapinfo, Hexen\s_sndseq, Strife\f_finale, Strife\p_dialog |
| `W_ShutDown` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `W_RuntimeLoad` | 9 | nd_main, p_udmf, r_pk3textures (4), s_pk3sounds, vx_voxelsprite, v_palettes |
| `W_InitMultipleFiles` | 13 | Doom\d_main (4), Heretic\d_main (3), Hexen\d_main (3), Strife\d_main (3) |
| `W_ReadLump` | 16 | DelphiDoom.Engine.Nodes.LumpSource, DelphiDoom.Engine.TextureDefs.LumpSource, DelphiDoom.Engine.Voxel.FileSource, Doom\p_switch, p_blockmap, r_colormaps, r_data (4), r_draw (2), +3 altri |
| `stringtochar8` | 24 | Doom\g_game (2), Heretic\g_game (2), Hexen\g_game (2), p_levelinfo, p_musinfo, r_data (3), r_pk3textures, r_translations, +2 altri |
| `W_TextLumpNum` | 25 | deh_base (2), DelphiDoom.Engine.Console.Startup, DelphiDoom.Engine.DynLights.Services, DelphiDoom.Engine.MapInfo.TextSource (2), DelphiDoom.Engine.MusInfo.Services, DelphiDoom.Engine.Scanner.IncludeSource, DelphiDoom.Engine.Wad.AutoLoadLumps, gl_models, +11 altri |
| `W_NumLumps` | 36 | acs, deh_base, DelphiDoom.Engine.Console.Startup, DelphiDoom.Engine.DynLights.Services, DelphiDoom.Engine.MapInfo.TextSource, DelphiDoom.Engine.Nodes.LumpSource (2), DelphiDoom.Engine.Wad.AutoLoadLumps, gl_models, +13 altri |
| `W_GetNameForNum` | 56 | acs (2), c_con, deh_base, DelphiDoom.Engine.Console.Startup, DelphiDoom.Engine.DynLights.Services, DelphiDoom.Engine.MapInfo.TextSource, DelphiDoom.Engine.Nodes.LumpSource, DelphiDoom.Engine.Wad.AutoLoadLumps, +23 altri |
| `char8tostring` | 61 | c_con, deh_base, DelphiDoom.Engine.Console.Startup, DelphiDoom.Engine.DynLights.Services, DelphiDoom.Engine.MapInfo.TextSource, DelphiDoom.Engine.Nodes.LumpSource, DelphiDoom.Engine.TextureDefs.FlatCatalog, DelphiDoom.Engine.Wad.AutoLoadLumps, +27 altri |
| `W_LumpLength` | 76 | acs, am_map, DelphiDoom.Engine.Nodes.LumpSource (2), DelphiDoom.Engine.TextureDefs.LumpSource, DelphiDoom.Engine.Voxel.FileSource, Doom\g_game, Doom\p_spec, Doom\p_switch, +28 altri |
| `W_GetNumForName` | 93 | am_map (4), Doom\g_game, Doom\st_stuff (5), e_endoom, gl_render, Heretic\g_game, Heretic\in_stuff (4), Heretic\m_menu (3), +23 altri |
| `W_CacheLumpNum` | 162 | am_map (5), am_textured (2), Doom\d_main, Doom\f_finale, Doom\g_game, Doom\m_menu, Doom\p_spec, Doom\st_lib (2), +40 altri |
| `W_CheckNumForName` | 170 | am_map (2), deh_base, DelphiDoom.Engine.Definitions.AnimCatalog, DelphiDoom.Engine.MapInfo.Services, DelphiDoom.Engine.MusInfo.Services, DelphiDoom.Engine.Nodes.LumpSource, DelphiDoom.Engine.Scanner.IncludeSource, DelphiDoom.Engine.TextureDefs.LumpSource, +48 altri |
| `W_CacheLumpName` | 185 | c_con, Doom\f_finale (2), Doom\m_menu, Doom\st_lib, Doom\st_stuff (15), Doom\wi_stuff (33), Heretic\d_main, Heretic\f_finale (4), +18 altri |

### `Base\i_system.pas` - 47 funzioni pubbliche, 1115 chiamate

Per toglierla: e il punto di ingresso di log, clock e piattaforma (`I_Error`, `I_Warning`, `I_GetTime`, ~700 chiamanti): migrare a mano i chiamanti ai servizi iniettati, o tenerla come facciata definitiva.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `I_DetectOS` | 0 | - |
| `I_ConfigureClock` | 1 | DelphiDoom.Engine.Composition |
| `I_ConfigureLog` | 1 | DelphiDoom.Engine.Composition |
| `I_ConfigurePlatform` | 1 | DelphiDoom.Engine.Composition |
| `I_ConfigureVideo` | 1 | DelphiDoom.Engine.Composition |
| `I_CreateProcess` | 1 | i_threads |
| `I_GetExeImageSize` | 1 | z_zone |
| `I_ProcessWindows` | 1 | DelphiDoom.Engine.Net.Services |
| `I_WaitForProcess` | 1 | i_threads |
| `I_Destroy` | 2 | gl_main, i_main |
| `I_DirectoryExists` | 2 | w_pak (2) |
| `I_BaseTiccmd202` | 3 | Doom\g_game, Heretic\g_game, Hexen\g_game |
| `I_StartTic` | 3 | DelphiDoom.Engine.Net.Services (3) |
| `I_BaseTiccmd` | 4 | Doom\g_game, Heretic\g_game, Hexen\g_game, Strife\g_game |
| `I_ClearInterface` | 4 | i_video (4) |
| `I_GetSysTime` | 4 | Doom\d_main, Heretic\d_main, Hexen\d_main, Strife\d_main |
| `I_GetWindowDPI` | 4 | i_video (2), Launcher_utils (2) |
| `I_GoToWebPage` | 4 | c_utils, Launcher_main, Launcher_utils (2) |
| `I_SetCriticalCPUPriority` | 4 | Doom\d_main, Heretic\d_main, Hexen\d_main, Strife\d_main |
| `I_SetDPIAwareness` | 4 | gl_main, i_main, Launcher_utils (2) |
| `I_SetNormalCPUPriority` | 4 | Doom\d_main, Heretic\d_main, Hexen\d_main, Strife\d_main |
| `I_Sleep` | 4 | i_threads (2), r_wall32, r_wall8 |
| `I_StartFrame` | 4 | Doom\d_main, Heretic\d_main, Hexen\d_main, Strife\d_main |
| `I_GetFracTime` | 5 | hu_stuff, r_intrpl (4) |
| `I_VideoServices` | 6 | gl_main (2), i_video (4) |
| `I_WaitVBL` | 6 | DelphiDoom.Engine.Net.Services, Doom\m_menu, gl_main, Heretic\m_menu, Hexen\m_menu, Strife\m_menu |
| `I_IsCDRomDrive` | 7 | Launcher_main, Launcher_utils (2), m_argv (4) |
| `I_DetectCPU` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `I_FlashCachedOutput` | 8 | 8 .dpr |
| `I_GetTickCount` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `I_Init` | 8 | Doom\d_main (2), Heretic\d_main (2), Hexen\d_main (2), Strife\d_main (2) |
| `I_ScreenHeight` | 8 | Doom\d_main, gl_main, Heretic\d_main, Hexen\d_main, i_main, Launcher_utils (2), Strife\d_main |
| `I_ScreenWidth` | 8 | Doom\d_main, gl_main, Heretic\d_main, Hexen\d_main, i_main, Launcher_utils (2), Strife\d_main |
| `I_VersionBuilt` | 9 | DelphiDoom.Ide.Composition, Doom\d_main, Heretic\d_main, Hexen\d_main, ide_version (2), Launcher_about (2), Strife\d_main |
| `I_BeginDiskBusy` | 11 | deh_base, DelphiDoom.Audio.SoundLibrary (2), DelphiDoom.Wad.ReloadableSource, i_sound, r_translations, s_sound, t_main, w_wad (3) |
| `I_Quit` | 14 | Doom\g_game (2), Doom\m_menu, e_endoom (2), Heretic\g_game (2), Heretic\m_menu, Hexen\g_demo, Hexen\m_menu (2), Strife\g_game (2), +1 altri |
| `I_GameFinished` | 17 | DelphiDoom.Engine.Input.Gate, DelphiDoom.Engine.Net.Services, Doom\d_main (2), Doom\m_menu, d_net, gl_main, Heretic\d_main (2), Heretic\m_menu, +5 altri |
| `I_DevError` | 23 | Doom\d_main (7), gl_render, Heretic\d_main (2), Heretic\p_ambient, Hexen\d_main, i_sound, m_rnd, r_things (2), +4 altri |
| `I_DevWarning` | 24 | DelphiDoom.Engine.Scanner.Log, Doom\p_inter (2), gl_render, Heretic\p_inter (2), r_data (6), r_intrpl (3), r_things (4), Strife\p_inter (2), +1 altri |
| `I_GetNumCPUs` | 24 | am_textured, i_video (3), Launcher_main, Launcher_utils (2), mt_utils (2), psi_overlay (2), r_depthbuffer, r_flat32 (2), +6 altri |
| `I_GetTime` | 86 | DelphiDoom.Engine.Net.Services (2), Doom\d_main (4), Doom\g_game (2), Doom\m_menu (14), d_net, gl_main (2), Heretic\d_main (4), Heretic\g_game (2), +9 altri |
| `I_Error` | 373 | am_map (2), c_cmds, deh_base (3), DelphiDoom.Engine.Composition (4), DelphiDoom.Engine.Net.Services, DelphiDoom.Engine.Texture.JpegConverter, Doom\deh_main, Doom\d_main (4), +141 altri [test: 2] |
| `I_Warning` | 404 | am_map, deh_base (2), DelphiDoom.Engine.Music.MidiFileBackend, DelphiDoom.Engine.Music.XmiBackend, DelphiDoom.Engine.Scanner.Log (3), Doom\deh_main (17), Doom\d_main (12), Doom\g_game (12), +77 altri [test: 22] |

### `Base\m_rnd.pas` - 16 funzioni pubbliche, 1143 chiamate

Per toglierla: `P_Random` e il percorso caldo di ogni thinker (migliaia di chiamanti): chiamata indiretta gia presente; resta come facciata.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `M_ConfigureRandom` | 1 | DelphiDoom.Engine.Composition |
| `I_Random` | 2 | f_wipe, p_setup |
| `P_RandomFromSeed` | 2 | r_main (2) |
| `P_RandomHitscanAngle` | 2 | p_common (2) |
| `P_RandomHitscanSlope` | 2 | p_common (2) |
| `Sys_Random` | 3 | DelphiDoom.Engine.Scanner.ActorFunctions (3) |
| `M_ClearRandom` | 4 | Doom\g_game, Heretic\g_game, Hexen\g_game, Strife\g_game |
| `M_GetMenuRandomIndex` | 4 | Doom\g_game, Heretic\g_game, Hexen\g_game, Strife\g_game |
| `C_Random` | 7 | DelphiDoom.Engine.DynLights.Services, Doom\p_user, r_earthquake (4), Strife\p_user |
| `M_GetSystemRandomSeed` | 7 | Doom\g_game, Heretic\g_game, Hexen\g_demo, info_rnd, p_setup (2), Strife\g_game |
| `M_SetSystemRandomSeed` | 7 | Doom\g_game (2), Heretic\g_game, Hexen\g_demo (2), p_setup, Strife\g_game |
| `P_RestoreRandom` | 10 | Doom\p_map, Doom\p_mobj (2), Heretic\p_map, Heretic\p_mobj (2), Hexen\p_map, Strife\p_map, Strife\p_mobj (2) |
| `P_SaveRandom` | 10 | Doom\p_map, Doom\p_mobj (2), Heretic\p_map, Heretic\p_mobj (2), Hexen\p_map, Strife\p_map, Strife\p_mobj (2) |
| `M_Random` | 14 | Doom\st_stuff, Doom\wi_stuff (3), Hexen\m_menu, Hexen\p_user, Hexen\s_sndseq, Strife\p_dialog (2), s_sound (5) |
| `N_Random` | 118 | Doom\p_extra (15), Doom\p_genlin, Doom\p_inter (2), Doom\p_map (2), Doom\p_mobj (9), Doom\p_spec, Heretic\p_extra (2), Heretic\p_inter (2), +16 altri |
| `P_Random` | 950 | DelphiDoom.Engine.Acs.Host, Doom\g_game, Doom\p_enemy (44), Doom\p_extra (6), Doom\p_inter (3), Doom\p_lights (5), Doom\p_map (9), Doom\p_mobj (31), +47 altri |

### `Base\deh_base.pas` - 40 funzioni pubbliche, 2060 chiamate

Per toglierla: le liste dei flag e dei token servono ai dump; servirebbe un catalogo iniettato in `Libs\Dehacked` invece delle liste globali.

| Funzione | Chiamate | Moduli chiamanti |
|---|---:|---|
| `DEH_CurrentActordef` | 0 | - |
| `DEH_CurrentStateOwners` | 0 | - |
| `DEH_CurrentWeapondef` | 0 | - |
| `DEH_ActionDeclaration` | 1 | dd_compiler |
| `DEH_ActionEntry` | 1 | p_common |
| `DEH_ConfigureActions` | 1 | DelphiDoom.Engine.Composition |
| `DEH_MobjInfoCSV` | 1 | dd_compiler |
| `DEH_SpritesCSV` | 1 | dd_compiler |
| `DEH_StatesCSV` | 1 | dd_compiler |
| `DEH_PlayerClass` | 2 | DelphiDoom.Engine.ActorDef.Catalog, Hexen\deh_main |
| `DEH_PrintActordef` | 2 | sc_actordef (2) |
| `DEH_PrintStateOwners` | 2 | sc_actordef (2) |
| `DEH_PrintWeapondef` | 2 | sc_actordef (2) |
| `DEH_SaveActordef` | 2 | sc_actordef (2) |
| `DEH_SaveStateOwners` | 2 | sc_actordef (2) |
| `DEH_SaveWeapondef` | 2 | sc_actordef (2) |
| `DEH_ParseText` | 3 | DelphiDoom.Engine.ActorDef.Hooks (3) |
| `DEH_AddNullAction` | 4 | Doom\deh_main, Heretic\deh_main, Hexen\deh_main, Strife\deh_main |
| `DEH_FindActionByName` | 4 | Doom\deh_main, Heretic\deh_main, Hexen\deh_main, Strife\deh_main |
| `DEH_ParseLumpNames` | 4 | Doom\d_main, Heretic\d_main, Hexen\d_main, Strife\d_main |
| `DEH_ParseLumpNum` | 4 | Doom\d_main, Heretic\d_main, Hexen\d_main, Strife\d_main |
| `DEH_SearchActionFromHash` | 4 | Doom\deh_main, Heretic\deh_main, Hexen\deh_main, Strife\deh_main |
| `DEH_StringToCString` | 4 | Doom\deh_main, Heretic\deh_main, Hexen\deh_main, Strife\deh_main |
| `DEH_AmmoType` | 5 | DelphiDoom.Engine.ActorDef.Catalog, Doom\deh_main, Heretic\deh_main, Hexen\deh_main, Strife\deh_main |
| `DEH_WeaponType` | 5 | DelphiDoom.Engine.ActorDef.Catalog, Doom\deh_main, Heretic\deh_main, Hexen\deh_main, Strife\deh_main |
| `DEH_ActionName` | 7 | Doom\deh_main, Heretic\deh_main, Hexen\deh_main, info_export, sc_actordef (2), Strife\deh_main |
| `DEH_CStringToString` | 8 | Doom\deh_main (2), Heretic\deh_main (2), Hexen\deh_main (2), Strife\deh_main (2) |
| `DEH_PrintActions` | 8 | Doom\deh_main (2), Heretic\deh_main (2), Hexen\deh_main (2), Strife\deh_main (2) |
| `DEH_PrintCurrentSettings` | 8 | Doom\deh_main (2), Heretic\deh_main (2), Hexen\deh_main (2), Strife\deh_main (2) |
| `DEH_SaveCurrentSettings` | 8 | Doom\deh_main (2), Heretic\deh_main (2), Hexen\deh_main (2), Strife\deh_main (2) |
| `DEH_SaveMobjInfoCSV` | 8 | Doom\deh_main (2), Heretic\deh_main (2), Hexen\deh_main (2), Strife\deh_main (2) |
| `DEH_SaveSpritesCSV` | 8 | Doom\deh_main (2), Heretic\deh_main (2), Hexen\deh_main (2), Strife\deh_main (2) |
| `DEH_SaveStatesCSV` | 8 | Doom\deh_main (2), Heretic\deh_main (2), Hexen\deh_main (2), Strife\deh_main (2) |
| `DEH_StringValue` | 9 | Doom\deh_main (3), Heretic\deh_main (2), Hexen\deh_main (2), Strife\deh_main (2) |
| `DEH_ParseFile` | 12 | Doom\deh_main (2), Doom\d_main, Heretic\deh_main (2), Heretic\d_main, Hexen\deh_main (2), Hexen\d_main, Strife\deh_main (2), Strife\d_main |
| `DEH_ActionCount` | 13 | dd_compiler, Doom\deh_main (3), Heretic\deh_main (3), Hexen\deh_main (3), Strife\deh_main (3) |
| `DEH_ActionProc` | 16 | Doom\deh_main (4), Heretic\deh_main (4), Hexen\deh_main (4), Strife\deh_main (4) |
| `DEH_ParseLumpName` | 18 | Doom\deh_main, Doom\d_main (6), Heretic\deh_main, Heretic\d_main (4), Hexen\deh_main, Hexen\d_main (2), Strife\deh_main, Strife\d_main (2) |
| `DEH_AddAction` | 1872 | Doom\deh_main (420), Heretic\deh_main (448), Hexen\deh_main (549), Strife\deh_main (455) |


## Funzioni pubbliche senza chiamanti lasciate di proposito

Nessun chiamante fuori dalla unit (nemmeno test o librerie), non cancellate perche sono renderer, FixedMul/angoli, API storiche (W_*), facciate documentate in CLAUDE.md (r_*Frustum) o libreria di terzi (_clipper). BoolToStr, IsZeroes, parsefirstword, A_Fall, AngleToFixed, FloatMul, DEG2RAD hanno solo riferimenti omonimi in test o librerie: da verificare a mano.

- `Base\m_fixed.pas`: FixedDiv_fast, FixedDiv_Positive, FixedDivLW, FixedMulDiv16, FixedMulDiv8, FixedMulShl10, FixedMulShl14, FixedMulShl3, FixedMulShl4, FixedMulShl5, FixedMulShl8, FloatDiv, FloatMul
- `Base\m_vectors.pas`: DEG2RAD
- `Base\r_bsp.pas`: R_UnderWater
- `Base\r_clipper.pas`: CleanPolygons, ClosedPathsFromPolyTree, MinkowskiDiff, OpenPathsFromPolyTree, PolyTreeToPaths, ReversePaths, SimplifyPolygon, SimplifyPolygons
- `Base\r_colorcolumn.pas`: R_DrawColorColumnAlphaHi_Batch, R_DrawColorColumnAlphaMedium_Batch, R_DrawColorColumnAverageHi_Batch, R_DrawColorColumnAverageMedium_Batch
- `Base\r_colormaps.pas`: R_CustomColorMapColor32
- `Base\r_column.pas`: R_DrawColumnBase32
- `Base\r_data.pas`: R_CacheFlat
- `Base\r_flatinfo.pas`: R_FlatSizeFromSize
- `Base\r_hires.pas`: R_ColorBoost, R_ColorLightAdd, R_ColorLightAverage, R_FuzzLight, R_InverseLight, R_InverseLightAverage
- `Base\r_main.pas`: R_AddPointToBox
- `Base\r_tallcolumn.pas`: R_DrawTallColumnBase32
- `Base\r_translations.pas`: R_BloodTranslation
- `Base\r_utils.pas`: R_ColumnToScreenBuffer, R_PointToScreen, R_PointToScreenBufferEx2
- `Base\r_zbuffer.pas`: R_StartZBuffer
- `Base\tables.pas`: AngleToFixed
- `Base\v_palettes.pas`: V_FixBufferPalette
- `Base\v_video.pas`: V_DrawBlock, V_DrawLongBlock, V_GetBlock
- `Base\w_sprite.pas`: W_CacheSpriteName
- `Base\w_wad.pas`: W_CacheLumpNum2, W_LumpIsNamed
- `Common\d_delphi.pas`: IsZeroes, parsefirstword
- `Heretic\p_enemy.pas`: A_Fall
- `OPENGL\gl_ambient.pas`: gld_AmbientExecute
- `OPENGL\gl_frustum.pas`: fr_BoxInFrustum, fr_CubeInFrustum, fr_PointInFrustum, fr_SphereInFrustum
- `OPENGL\gl_misc.pas`: gl_f_max
- `OPENGL\gl_render.pas`: gld_DrawLine
- `OPENGL\gl_types.pas`: MakeGLVertex
- `OPENGL\mdl_script_proclist.pas`: MDL_Procs


## Funzioni pubbliche usate solo dentro la propria unit

Nessun chiamante esterno ma usate internamente: si possono togliere dalla sezione interface (diventano locali). Non fatto in questo lavoro: e una modifica di visibilita, non una cancellazione.

- `Base\am_map.pas`: FTOM, M_ZOOMIN, M_ZOOMOUT
- `Base\c_con.pas`: C_AddText
- `Base\deh_base.pas`: DEH_CurrentActordef, DEH_CurrentStateOwners, DEH_CurrentWeapondef
- `Base\hu_lib.pas`: HUlib_addLineToSText, HUlib_clearTextLine, HUlib_delCharFromIText
- `Base\hu_stuff.pas`: HU_FPS, HU_TITLE
- `Base\i_exec.pas`: I_ExecProgram
- `Base\i_system.pas`: I_DetectOS
- `Base\info_common.pas`: Info_ShutDownDnLookUp
- `Base\info_export.pas`: Info_GetMobjinfoPascal, Info_GetMobjinfoPascalConst, Info_GetStatesPascal
- `Base\m_misc.pas`: M_SetDefault
- `Base\m_vectors.pas`: ConcatRotations, PerpendicularVector, ProjectPointOnPlane, RotatePointAroundVector
- `Base\p_common.pas`: P_CheckCustomMeleeRange, P_CheckFov, P_CopyFriendliness, P_HealCorpse, P_LocalEarthQuake, P_NoiseAlertEx, P_RaiseActor, P_RoughTargetSearch, P_SeekerMissileEx
- `Base\p_musinfo.pas`: P_FindMusinfoMusic
- `Base\p_sight.pas`: P_CheckVisibility, P_SightPathTraverse
- `Base\r_clipper.pas`: CleanPolygon, DoublePoint, GetBounds, IntPoint, MinkowskiSum, PointInPolygon, ReversePath
- `Base\r_depthbuffer.pas`: R_DrawSpanToDepthBuffer, R_StoreSpanToDepthBufferMT
- `Base\r_plane.pas`: R_MapPlane, R_MapPlaneAngle
- `Base\r_things.pas`: R_NewVisSprite
- `Base\r_trans8.pas`: R_FastApproxColorIndex
- `Base\r_translations.pas`: R_GetTranslationTable
- `Base\r_zbuffer.pas`: R_ClearZBuffer, R_DrawVoxelColumnToZBuffer
- `Base\s_sound.pas`: S_StartVoiceAtVolume, S_StopMusic
- `Base\udmf_plats.pas`: PH_RemoveActivePlat
- `Base\udmf_spec.pas`: P_ArgsToLine, P_LineToArgs
- `Base\v_displaymode.pas`: V_DoSetDisplayMode
- `Base\v_palettes.pas`: V_CreateDoomPalette, V_CreateTranslation
- `Base\v_video.pas`: V_CalcPreserveTables, V_NeedsPreserve, V_PreserveH, V_PreserveW, V_PreserveX
- `Base\w_pak.pas`: PAK_AddDirectory, PAK_GetMatchingEntries
- `Base\z_zone.pas`: Z_DumpHeap, Z_FileDumpHeap, Z_FileDumpHeapf
- `Common\d_delphi.pas`: direxists, lastword, QSortFloats, QSortIntegers, secondword
- `Doom\d_main.pas`: D_AddFile, D_FileInDoomPath, D_PageDrawer
- `Doom\g_game.pas`: G_DoLoadGame
- `Doom\p_mobj.pas`: P_SpawnMissileAngleZSpeed
- `Doom\p_plats.pas`: P_RemoveActivePlat
- `Doom\p_spec.pas`: P_SpawnFriction, P_SpawnPushers, twoSidedS
- `Heretic\d_main.pas`: D_AddFile, D_FileInDoomPath, D_PageDrawer
- `Heretic\g_game.pas`: G_DoLoadGame
- `Heretic\m_menu.pas`: M_WriteText2
- `Heretic\p_mobj.pas`: P_SpawnMissileAngleZSpeed
- `Heretic\p_plats.pas`: P_ActivateInStasis, P_RemoveActivePlat
- `Heretic\p_pspr.pas`: A_FireMacePL1B
- `Heretic\p_user.pas`: P_PlayerNextArtifact, P_UndoPlayerChicken, P_UseArtifact
- `Hexen\a_action.pas`: A_TeloSpawn
- `Hexen\d_main.pas`: D_AddFile, D_FileInDoomPath, D_PageDrawer
- `Hexen\g_game.pas`: G_DoLoadGame
- `Hexen\m_menu.pas`: M_StringWidth2, M_WriteText2
- `Hexen\p_enemy.pas`: A_AccelBalls, A_CastSorcererSpell, A_DecelBalls, A_FiredSpawnRock, A_KSpiritSeeker, A_KSpiritWeave, A_SlowBalls, A_SorcOffense1, A_SorcOffense2, A_SorcUpdateBallAngle, A_StopBalls, A_WraithFX4, DragonSeek, FaceMovementDirection, KoraxFire1, KoraxFire2, KoraxFire3, KoraxFire4, KoraxFire5, KoraxFire6, KSpiritInit, P_CheckMeleeRange2, P_CheckMissileRange, P_NewChaseDir, P_UpdateMorphedMonster
- `Hexen\p_inter.pas`: P_ActiveMinotaur, P_AutoUseHealth, P_GiveKey, P_HideSpecialThing, P_MinotaurSlam, P_MorphMonster, P_PoisonPlayer, P_SetDormantArtifact, P_SpawnDroppedMobj, P_TryPickupArtifact, P_TryPickupWeapon, P_TryPickupWeaponPiece
- `Hexen\p_map.pas`: P_FakeZMovement, P_HitSlideLine, P_ThingHeightClip, PIT_ChangeSector, PIT_CheckLine, PIT_CheckOnmobjZ, PIT_RadiusAttack, PIT_ThrustStompThing, PTR_BounceTraverse, PTR_PuzzleItemTraverse, PTR_ShootTraverse, PTR_SlideTraverse, PTR_UseTraverse
- `Hexen\p_mobj.pas`: P_FloorBounceMissile, P_PlayerLandedOnThing, P_SpawnMissileAngleZSpeed, P_ZMovement
- `Hexen\p_pspr.pas`: A_CHolyWeave, A_MLightningAttack2, P_AdjustPlayerAngle, P_CheckMana, P_CHolyFindTarget, P_CHolySeekerMissile, P_CHolyTailFollow, P_CHolyTailRemove, P_FireWeapon, P_MStaffSpawn, P_MStaffSpawn2
- `Hexen\p_spec.pas`: EVH_LineSearchForPuzzleItem
- `Hexen\p_user.pas`: P_PlayerNextArtifact
- `Hexen\sv_save.pas`: P_ArchiveScreenShot, P_UnArchiveScreenShot
- `OPENGL\gl_render.pas`: gld_DrawBackgroundFrame, gld_StaticLight
- `OPENGL\gl_tex.pas`: gld_AddFlatToTexture, gld_AddNewGLPatchTexture, gld_AddNewGLTexture, gld_AddPatchToTexture, gld_AddPatchToTexture_UnTranslated, gld_GetTexDimension, gld_LoadExternalTextureAlpha, gld_SetTexturePalette
- `SCRIPT\psi_game.pas`: PS_GetMobjInfoGravity
- `SCRIPT\psi_globals.pas`: FreeHashList
- `Strife\d_main.pas`: D_AddFile, D_FileInDoomPath, D_PageDrawer
- `Strife\g_game.pas`: G_DoLoadGame
- `Strife\m_menu.pas`: M_StringWidth2, M_StringWidth3, M_WriteText2, M_WriteText3
- `Strife\m_saves.pas`: M_ClearSlotNum
- `Strife\p_mobj.pas`: P_SpawnMissileAngleZSpeed
- `Strife\p_plats.pas`: P_RemoveActivePlat
- `Strife\p_spec.pas`: P_SpawnFriction, P_SpawnPushers, twoSidedS
- `Strife\p_user.pas`: P_DropInventoryItem, P_ItemBehavior

