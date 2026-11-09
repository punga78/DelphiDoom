# Libs\Renderer - analisi del renderer e prima fetta (issue #156)

> Note per Claude e paragrafi di dettaglio (issue #178): [CLAUDE.md](CLAUDE.md).

Il renderer (software e OpenGL) e rimasto storico per scelta: chiamate per fotogramma, `screens[]`, zone memory, circa 580 globali condivisi. Questo documento e l'**analisi unit per unit** richiesta dalla #156, la proposta di `IRenderer` e l'ordine di migrazione a fette. La libreria contiene le **prime due fette senza rischio** (la tabella delle colonne di una texture e le misure del livello), con test di parita.

## 1. Metodo e come leggere i numeri

Ho letto le unit (non solo le intestazioni): `Base\r_main.pas`, `r_data`, `r_segs`, `r_segs2`, `r_bsp`, `r_plane`, `r_draw`, `r_sky`, `r_aspect`, `r_things` (funzioni), `r_fake3d`, `r_subsectors`, `Libs\OpenGl\Legacy\gl_*.pas` (elenco delle funzioni e lettura delle parti fredde). I conteggi sono di uno script (perl, fuori dal repository) che:

- prende i **globali dell'interfaccia** (blocchi `var` della sezione `interface`) di 89 unit `r_*`, `v_video`, `v_data`, `gl_*`: **582 nomi**;
- per ogni unit conta quanti di quei globali, dichiarati in *altre* unit, vengono **letti** (compaiono nel testo, commenti e stringhe esclusi) e quanti **scritti** (compaiono a sinistra di `:=`, anche con indici e campi: `dc_x := ...`, `ylookup[i] := ...`, `x.campo := ...`);
- conta i `{$IF...}` di gioco (`ifdef`) e le righe `asm`.

Limiti: non vede i globali dichiarati nella sezione `implementation`, ne le variabili passate per riferimento (`var`), ne le scritture fatte da una procedura chiamata; una scrittura a un campo di un puntatore (`curline.x := ...`) conta come scrittura del puntatore. Sono **ordini di grandezza** per decidere dove sta l'accoppiamento, non una verifica formale. "Caldo" = eseguito per colonna, per pixel, per muro o per oggetto in ogni fotogramma (dalla lettura del codice, non da un profiler).

Totali: circa 79700 righe in `Base\r_*.pas`, `v_video`, `v_data` e `Libs\OpenGl\Legacy\gl_*.pas`; 582 globali; 142 `{$IF}` di gioco nella sola `r_main`; 3 unit con `asm` (`r_hires` 1, `r_softlights` 1, `r_mmx` 6: sono della #41).

## 2. Come gira un fotogramma

`R_RenderPlayerView` (`Base\r_main.pas:3934`) sceglie tra quattro percorsi: `R_DoRenderPlayerView_SingleThread` (`:3854`), `R_DoRenderPlayerView8_MultiThread` (`:3693`), `R_DoRenderPlayerView32_MultiThread` (`:3774`) e, in OpenGL, il ramo `{$IFDEF OPENGL}` dello stesso ciclo singolo.

Software (single thread): `R_Fake3DPrepare` -> `R_SetupFrame` (`:3378`, scrive i globali della vista: `viewx`, `viewy`, `viewz`, `viewangle`, `viewsin`, `viewcos`, `extralight`, `fixedcolormap`...) -> `R_Calc8bitTables` / `R_CalcHiResTables_*` -> `R_ClearClipSegs`, `R_ClearDrawSegs`, `R_ClearPlanes`, `R_Fake3DAdjustPlanes`, `R_ClearSprites` -> `R_RenderBSPNode(numnodes - 1)` (`r_bsp.pas:1555`: per nodo `R_CheckBBox` `:925`, per subsector `R_Subsector` `:1103`, per linea `R_AddLine` `:721` che chiama `R_StoreWallRange` `r_segs.pas:1262`) -> `R_ProjectAdditionalThings` -> `R_SetUpDrawSegLists` -> `R_DrawPlanes` (`r_plane.pas:1213`) -> `R_DrawFFloors` (3D floors) -> `R_DrawMasked_*` (sprite e muri trasparenti, `r_things.pas:3042/3071`) -> `R_Execute3DTransform` -> `R_DrawPlayer`. In mezzo `R_NetGame.Update` (rete) ripetuto tre volte.

OpenGL: stessa impostazione, ma `R_RenderBSPNode` riempie liste (`gld_AddWall` `gl_render.pas:3506`, `gld_AddFlat` `:4179`, `gld_AddSprite` `:5255`) e `gld_DrawScene` (`:5595`) le disegna con le chiamate `gl*`.

I colori si scelgono una sola volta per cambio di dettaglio: `R_SetRenderingFunctions` (`r_main.pas:1719`-`2780`, circa 1060 righe di `case setdetail` che assegnano **puntatori a procedura** `colfunc`, `batchcolfunc`, `*_mt`...). E gia una strategia: la procedura giusta e scelta a freddo, il ciclo caldo chiama il puntatore. Le procedure di un muro sono 256 combinazioni di 8 bandiere (8/32 bit, ottimizzata, double, 3D floors, "Vis", Z-buffer, muri alti, offset speciali) fatte da due `.inc` (`R_RenderSegLoop8.inc`, 577 righe, `R_RenderSegLoop32.inc`, 621) incluse 128 volte ciascuna in `r_segs2.pas:179`-`4007`.

## 3. Il "registro" dei colonne e dei span

La comunicazione tra chi sceglie cosa disegnare e chi disegna e fatta da **globali usati come registri**: `dc_x`, `dc_yl`, `dc_yh`, `dc_iscale`, `dc_texturemid`, `dc_source`, `dc_colormap`... (`r_column.pas`, 18 globali) e `ds_x1`, `ds_x2`, `ds_y`, `ds_xfrac`, `ds_yfrac`, `ds_xstep`, `ds_ystep`, `ds_source`, `ds_scale`... (`r_span.pas`, 19). Le unit che li **scrivono** (le altre li leggono nel ciclo):

| Globale | Dichiarato in | Unit che lo leggono | Unit che lo scrivono |
|---|---|---|---|
| `dc_x`, `dc_yh`, `dc_yl` | `r_column` | 11-12 | 9: `r_3dfloors`, `r_batchsky`, `r_depthbuffer`, `r_plane`, `r_segs`, `r_things`, `r_voxels`, `r_wall32`, `r_wall8` (+`r_batchcolumn` per `dc_yl/dc_yh`) |
| `dc_iscale`, `dc_texturemid` | `r_column` | 11-13 | 7 (le stesse senza `r_batchsky`, `r_depthbuffer`) |
| `dc_source` | `r_column` | 9 | 8, tra cui `r_data` (`R_GetDCs`) e `r_cache_walls` |
| `dc_colormap`, `dc_colormap32`, `dc_lightlevel`, `dc_fog` | `r_column` | 5-9 | 4-5 |
| `ds_x1`, `ds_x2`, `ds_y`, `ds_xfrac`, `ds_yfrac`, `ds_xstep`, `ds_ystep` | `r_span` | 0-4 | 5: `r_flat32`, `r_flat32_ripple`, `r_flat8`, `r_plane`, `r_slopes` |
| `columnofs` | `r_draw` | 26 | 1 (`r_pk3textures`) |
| `ylookup`, `ylookupl` | `r_draw` | 15-17 | 1 (`r_fake3d`) |
| `centery`, `viewheight`, `viewwidth`, `viewx`, `viewy`, `viewz` | `r_main`, `r_draw` | 11-19 | `centery`: `r_things`, `r_softlights`; `viewx`, `viewy`: `r_camera`, `r_earthquake`; `viewz`: `r_camera`; `viewwidth`, `viewheight`: `r_main` |

Conseguenza: **non si puo spostare un pezzo del percorso caldo senza spostare il registro**; farlo (un record `TRenderState` passato per puntatore) cambia centinaia di righe e interagisce con l'`asm` e con le versioni MT (che copiano i registri nei task). Va pianificato dopo la #41, non prima (vedi fetta 11).

## 4. Tabella unit per unit - software (`Base\`)

Colonne numeriche: righe; globali dichiarati nell'interfaccia (**dich.**); globali altrui letti (**L**) e scritti (**S**); `{$IF}` di gioco (**if**). Rischio: B = basso (a freddo, con un oracolo vecchio/nuovo), M = medio, A = alto (percorso caldo o stato condiviso).

| Unit | Righe | dich. | L | S | if | Contenuto | Dipendenze | Caldo? | Candidato a classe? | Rischio |
|---|---:|---:|---:|---:|---:|---|---|---|---|---|
| `r_main` | 3972 | 116 | 16 | 24 | 142 | vista (`R_ExecuteSetViewSize` `:2780`, `R_InitTextureMapping` `:1478`, `R_SetViewSize` `:1675`), scelta delle funzioni di disegno (`:1719`), geometria dei nodi (`R_PointOnSide*` `:755`-`1130`, in 32 e 64 bit; `R_PointToAngle*` `:1138`-`1377`; `R_PointInSubsector` `:3330`), `R_SetupFrame` `:3378`, il fotogramma `:3693`-`3966`, comandi di console `:2956`-`3150`, `R_Init` `:3164` | `viewwidth`, `centerx...`, `screens`, tabelle di luce, 8 interfacce delle librerie | geometria e fotogramma: **si**; vista, `R_Init`, comandi: no (a freddo) | vista a freddo: **si** (fetta 1); scelta delle funzioni: si (fetta 6); orchestrazione del fotogramma: si (fetta 8); geometria: no ora | B (vista), M (orchestrazione), A (geometria) |
| `r_bsp` | 1635 | 9 | 19 | 4 | 63 | BSP: `R_RenderBSPNode` `:1555`, `R_Subsector` `:1103`, `R_AddLine` `:721`, `R_CheckBBox` `:925`, clip delle colonne `:386`-`487`, `R_FakeFlat` `:157` (settori "finti" BOOM) | scrive `curline`, `frontsector`, `backsector`, `linedef`; letti da `r_segs`, `r_slopes`, `r_3dfloors`, `gl_render`, `gl_setup` | si: per nodo e per linea | no (stato condiviso con 4 unit) | A |
| `r_segs` | 1932 | 48 | 52 | 41 | 34 | `R_StoreWallRange` `:1262` (e `_DBL` `:617`): per muro, imposta l'ambiente delle colonne; `R_RenderMaskedSegRange` `:310`; `R_WiggleFix` `:159`/`:264` | 41 globali altrui scritti (`dc_*`, `rw_*`, `midtexture`...) | si: per muro | no | A |
| `r_segs2` | 4736 | 28 | 10 | 0 | 1 | 256 varianti di `R_RenderSegLoop*` (`:179`-`4007`) da due `.inc`; liste dei drawseg (`R_SetUpDrawSegLists`, `R_GetDrawsegsFor*`); **misure del livello** (ora in `Libs\Renderer`, fetta B); `R_DistToSeg`, `R_CalcSegOffset` (per muro, in `Double`) | `dc_*` | si: per colonna | no; solo `R_CalcSectors` e `R_PrecalcSegs` (**fatte**) | A |
| `r_plane` | 1788 | 19 | 49 | 37 | 75 | visplane: `R_FindPlane` `:749`, `R_CheckPlane` `:992`, `R_MakeSpans` `:1066`, `R_DoDrawPlane` `:1234`, `R_MapPlane` `:358`, `R_ClearPlanes` `:585` | `ds_*`, `floorclip`, `yslope`, `distscale`, `xoffs/yoffs` | si: per colonna e per span | no | A |
| `r_slopes` | 1917 | 6 | 71 | 78 | 20 | pendenze: `R_StoreSlopeRange` `:909`, `R_MapSlope` `:450`, `R_VisSlopesFromSubsector` `:1901` | l'accoppiamento piu alto (71 letti, 78 scritti) | si | no | A |
| `r_3dfloors` | 1553 | 16 | 27 | 27 | 1 | 3D floors: `R_StoreThickSideRange` `:134`, `R_RenderThickSideRange` `:1029`, `R_DrawFFloors` `:1512`; usa `r_clipper` | `dc_*`, `curline`... | si | no | A |
| `r_things` | 3176 | 24 | 93 | 30 | 66 | **a freddo**: `R_InstallSpriteLump` `:312`, `R_InitSpriteDefs` `:390`, `R_InitSprites` `:581`; **a caldo**: `R_ProjectSprite` `:1553` (per oggetto), `R_DrawVisSprite` `:1110`, `R_DrawMaskedColumn*` `:680`-`1017` (per colonna), `R_DrawMasked_*` `:3042` | letti 93 globali altrui | freddo: no; caldo: si | **sprite def: si** (fetta 3); il resto no | B (def) / A |
| `r_things_sortvissprites` | 520 | 0 | 1 | 1 | 3 | ordinamento dei vissprite: selezione, quicksort, radix, merge (`:99`-`447`) | solo l'array dei puntatori | per fotogramma, non per pixel | si: `IVissprite Sorter` come strategia | M |
| `r_sprite` | 3256 | 0 | 27 | 0 | 9 | disegno MT delle colonne di sprite (`R_Draw*MT`, `R_Draw*_BatchMT`, `R_SpriteRenderMT` `:3070`) | `dc_*` | si: per pixel | no | A |
| `r_column`, `r_tallcolumn`, `r_colorcolumn`, `r_batchcolumn`, `r_batchsky`, `r_col_l/ms/sk/tr`, `r_draw_additive/alpha/average/subtractive`, `r_trans8` | 599, 694, 1796, 2562, 727, 129-329, 318-441, 622 | 18 (r_column) | 4-27 | 0-6 | 0-17 | le procedure che scrivono i pixel di una colonna (8/32 bit, trasparenze, cielo, luci) | registri `dc_*`, `screen32`, `ylookup` | si: per pixel | no (restano procedure; vedi 6) | A |
| `r_span`, `r_span32`, `r_span32_ripple`, `r_flat8`, `r_flat32`, `r_flat32_ripple` | 411, 110, 103, 1147, 876, 123 | 19 | 4-8 | 0-13 | 0 | i span dei pavimenti (MT, `R_DrawSpan*`) | `ds_*` | si: per pixel | no | A |
| `r_wall8`, `r_wall32` | 691, 655 | 7+7 | 0-1 | 8-10 | 4-13 | colonne di muro MT | `dc_*` | si | no | A |
| `r_cache_main`, `r_cache_walls`, `r_cache_flats` | 176, 1080, 633 | 4+2 | 0-14 | 0-8 | 0-19 | cache a 32 bit di colonne (`R_ReadDC32Cache` `:978`, per colonna) e span (`R_ReadDS32Cache` `r_cache_flats:190`, per span); init e reset a freddo (`R_InitDC32Cache` `:1056`) | `dc_source32`, `textures`, `flats` | lettura: si; init: no | init: si (fetta 2) | M |
| `r_hires` | 1603 | 14 | 5 | 2 | 23 | tabelle di colore 32 bit (`R_CalcHiResTables_*` `:984`-`1488`, anche in thread), funzioni di colore inline, comandi di dettaglio `:316`-`518`; **asm 1** | `videomode`, `colormaps32`, palette | ricalcolo a ogni cambio di palette (anche i lampi di dolore): caldo | no (#41) | A |
| `r_softlights`, `r_dynlights`, `r_lights`, `r_vislight` | 1677, 105, 167, 103 | 6+5+5+2 | 0-16 | 0-5 | 0-3 | luci dinamiche (parte parser: `Libs\DynLights`, collegata); disegno delle luci per colonna `R_DrawColumnLightmap*` `:675`-`1295`; **asm 1** | `zbuffer`, `dc_*` | si | no (#41) | A |
| `r_fake3d` | 882 | 4 | 3 | 3 | 3 | prospettiva finta: `R_ComputeFake3DTables` `:150` (a freddo), `R_Execute3DTransform*` `:492`-`681` (per pixel, anche in thread), `R_Fake3DAdjustPlanes` `:357` | `ylookup`, `floorclip`, `screen32` | trasformazione: si; tabelle: no | tabelle: si (fetta 4b) | M |
| `r_depthbuffer`, `r_zbuffer` | 809, 807 | 3+3 | 7-13 | 1-4 | 0-9 | profondita per pixel (colonne e span scrivono/controllano) | `dc_*`, `ds_*` | si | no | A |
| `r_voxels` | 2092 | 3 | 35 | 24 | 8 | colonne dei voxel (`R_VoxelColumnsFromBuffer` `:746`: ottimizzazione a freddo; `R_DrawThingVoxel` `:1180`: a caldo); i file li legge `Libs\Voxel` | `dc_*` | disegno: si; preparazione: no | preparazione: possibile (dopo `Libs\Voxel`) | M |
| `r_draw` | 849 | 16 | 7 | 2 | 57 | `R_InitBuffer` `:343` (`columnofs`, `ylookup`, `ylookupl` con `screens[SCN_FG]`), `R_FillBackScreen` `:413` (bordo, `SCN_BG`), `R_VideoErase` `:712` (per fotogramma), `R_InitTranslationTables` `:260` (libreria) | `screens[]` (6 punti), `screen32` | `R_VideoErase`: per fotogramma; resto: a freddo | `R_InitBuffer`: con la vista (fetta 1); il bordo no | M |
| `r_data` | 2277 | 30 | 12 | 18 | 62 | **fredda**: `R_InitTextures` `:1045`, `R_GenerateLookup` `:569` (**fatta**), `R_InitFlats` `:1366`, `R_InitSpriteLumps` `:1415`, `R_InitColormaps` `:1583`, `R_PrecacheLevel`; **calda**: `R_GetColumn` `:653` (per colonna), `R_GetDCs`, `R_GetDSs`, `R_GetLumpForFlat` | scrive/legge le ~20 tabelle (`texturecolumnlump`, `texturecolumnofs`, `texturecomposite`, `texturewidth`, `textureheight`, `texturecolumnheight*`, `texturecompositesize`, `texturetranslation`, `flats`, `spritewidth/offset/topoffset`...) lette per colonna da `r_cache_walls`, `r_wall*`, `r_things` | freddo: si; caldo: no | freddo: **fetta A fatta**, poi 2 | M |
| `r_defs` | 980 | 7 | 13 | 0 | 40 | tipi condivisi (`seg_t`, `sector_t`, `line_t`, `vissprite_t`, `drawseg_t`, `patch_t`...) e le tabelle delle texture (`texturecolumnlump`, `texturecomposite`...) | tutto il motore | - | no (tipi su disco e nei salvataggi) | - |
| `r_sky` | 136 | 12 | 0 | 0 | 8 | `R_InitSkyMap`, `R_InitSky` (livello): scrivono `skytexturemid`, e in Hexen `SkyTexture`... da `P_GetMapSky*` | globali di cielo | no: a freddo | si (profilo di cielo per gioco) | B |
| `r_camera`, `r_earthquake` | 182, 87 | 3+0 | 3 | 3 | 3 | camera di inseguimento, terremoto globale: per fotogramma scrivono `viewx/viewy/viewz` | `viewx...` | per fotogramma | si (strategia di vista) | M |
| `r_aspect` | 243 | 3 | 0 | 1 | 0 | `R_InitAspect` `:173`: enumera i modi video (duplica `IDisplayModeCatalog` di `Libs\Video`), `R_GetRelativeAspect` `:223` | `relative_aspect`, `widescreensupport` | a freddo | **si** (fetta 4) | B |
| `r_subsectors` | 192 | 1 | 0 | 0 | 0 | `R_PrecalcPointInSubSector` `:88` (per livello) e `R_PointInSubsectorPrecalc` `:179` (per oggetto) | `nodes`, `segs`, `subsectors` | precalcolo: no; interrogazione: si | precalcolo: si (fetta 5) | M |
| `r_intrpl` | 1401 | 10 | 4 | 0 | 10 | interpolazione dei fotogrammi: memorizza e ripristina mobj, settori, linee, poligoni (`R_StoreInterpolationData` `:741`, `R_RestoreInterpolationData_*` `:948`-`1079`, in thread) | thinker, settori, linee | per fotogramma e per oggetto | si, ma tocca i dati dei salvataggi: no ora | A |
| `r_scale` | 203 | 2 | 4 | 0 | 0 | `R_ScaleFromGlobalAngle` in 3 varianti (`:82`, `:128`, `:171`) | `viewangle`, `projection` | si: per muro | no (e gia in `Libs\Imaging` la parte pura: `WallScale`, non collegata per il costo) | A |
| `r_precalc`, `r_colormaps`, `r_translations`, `r_patch`, `r_pk3textures`, `r_flatinfo`, `r_ripple`, `r_renderstyle` | 253, 354, 312, 285, 568, 73, 89, 92 | 12, 3, 0, 0, 1, 1, 3, 0 | 0-3 | 0-3 | 0-4 | tabelle di luce e colori (collegate a `Libs\Palette`), traduzioni, colonne fisse (`Libs\Imaging`), texture da PK3 (`R_InitPK3Textures`), dimensioni dei flat | `colormaps`, `textures` | `R_GetFixedColumn` (`r_patch`): per colonna; il resto a freddo | gia in buona parte fatto; `r_pk3textures` (568 righe a freddo) e un candidato (fetta 2b) | B/M |
| `r_utils`, `r_range`, `r_cliputils`, `r_visplanes`, `r_debug`, `r_mmx`, `r_col_*` minori | 281, 98, 92, 132, 138, 305, - | 0 | 0-13 | 0 | 0-10 | utilita (`R_PointToScreenBuffer*`), tipi, debug; `r_mmx` e solo `asm` | | per pixel (`r_mmx`) | no | - |
| `r_clipper` | 7132 | 0 | 0 | 0 | 58 | **non e codice del renderer**: e Clipper (Angus Johnson, licenza Boost) per i poligoni delle 3D floors e delle pendenze (usato da `r_3dfloors`, `r_cliputils`, `r_slopes`) | nessuno | per muro/settore | non toccare (codice di terzi) | - |
| `v_video`, `v_data` | 5786, 196 | 10+17 | 0-11 | 0-8 | 11-91 | video (non e del renderer: #148) | `screens[]` | - | altra issue | - |

## 5. Tabella unit per unit - OpenGL (`Libs\OpenGl\Legacy\`)

| Unit | Righe | dich. | L | S | if | Contenuto | Dipendenze | Caldo? | Candidato | Rischio |
|---|---:|---:|---:|---:|---:|---|---|---|---|---|
| `gl_render` | 5869 | 4 | 61 | 22 | 67 | tutto il disegno: `gld_Init` `:638`, liste di muri/flat/sprite (`gld_AddWall` `:3506`, `gld_AddFlat` `:4179`, `gld_AddSprite` `:5255`), `gld_DrawScene` `:5595`, modelli e voxel (`gld_DrawModel` `:4538`, `gld_DrawVoxel` `:4747`), luci (`gld_DrawDLights` `:5210`) e **geometria del livello a freddo**: `gld_FlatEdgeClipper` `:1534`, `gld_FlatConvexCarver` `:1628`, `gld_CarveFlats` `:1726`, `gld_PreprocessSectors` `:1913`, `gld_PreprocessSegs` `:3895` | contesto GL, `frontsector`, `backsector`, `linedef` | disegno: si (per fotogramma, ma pieno di `gl*`); geometria: no | geometria del livello: **si** (fetta 10); disegno: no | B (geometria, in `Double`) / A |
| `gl_main` | 1370 | 6 | 11 | 1 | 20 | finestra, contesto, `GL_InitGraphics` `:1026`, `I_FinishUpdate` `:804`, `I_ReadScreen32` `:1326` | WGL, `screens` | per fotogramma | no (contesto grafico: #148) | A |
| `gl_tex` | 2088 | 12 | 20 | 4 | 2 | texture GL: registrazione e legame (`gld_RegisterTexture` `:1310`, `gld_BindTexture` `:1370`), caricamento da file esterni, `gld_Precache` `:1887` | `textures`, `flats`, contesto GL | `Bind*`: per muro; resto a freddo | a freddo: parti | M |
| `gl_setup` | 452 | 1 | 0 | 4 | 0 | lettura dei nodi GL V3..V5 dalla cache (`P_LoadGLSegs` `:235`, `P_LoadSubsectorsV3V5` `:380`, `P_LoadNodesV4V5` `:417`) | `segs`, `subsectors`, `nodes` | a freddo | si: `Libs\Nodes` ha gia il parser (resta il puntatore nella cache) | M |
| `gl_sky` | 376 | 0 | 2 | 0 | 1 | `gld_CalculateSky` `:77`, `gld_DrawSky` `:351` | contesto GL | per fotogramma | no | M |
| `gl_lightmaps`, `gl_lights`, `gl_ambient`, `gl_shadows` | 874, 147, 156, 132 | 2+0+0+1 | 0-6 | 0-1 | 0 | lightmap dei voxel, luci (`gld_SetUplight`), ambiente, ombre | contesto GL | per fotogramma | no | M |
| `gl_models`, `gl_voxels` | 752, 1477 | 7+2 | 0-2 | 0 | 0 | MODELDEF (parser: `SC_DoParseModelDefinition` `:303`), voxel: ottimizzatore di mesh `TVoxelMeshOptimizer` (`:200`-`848`, a freddo, in classe) | `Libs\Models`, `Libs\Voxel` | modelli: per oggetto | l'ottimizzatore di mesh e gia una classe | B |
| `gl_automap` | 441 | 0 | 0 | 2 | 13 | disegno dell'automap GL | `Libs\Automap` | per fotogramma | no | M |
| `gl_clipper` | 148 | 0 | 3 | 0 | 0 | facciata di `Libs\GlMath` | - | per muro | gia fatto | - |
| `gl_defs`, `gl_types`, `gl_slopes`, `gl_misc` | 192, 93, 105, 96 | 27+0+0+0 | 0 | 0 | 0-1 | costanti e tipi di GL, pendenze (`gld_FloorHeight` `:84`), min/max | - | - | no | - |

## 6. Cosa e gia fuori dal renderer (non rifare)

Collegate: `Libs\Palette` (palette, colormap, tabelle di luce, traduzioni: `r_precalc`, `r_colormaps`, `r_translations`, `R_InitLightTables`), `Libs\Imaging` (composizione dei blocchi di texture, colonne fisse, ingrandimento dei flat), `Libs\TextureDefs` (`R_InitTextures`, FLATINFO), `Libs\Definitions` (ANIMDEFS, terreno), `Libs\DynLights` (parser), `Libs\Voxel` (file dei voxel), `Libs\Texture` (immagini esterne), `Libs\MathCore` (tabelle trigonometriche, vettori, hash dei nomi), `Libs\Blockmap`, `Libs\Nodes`, `Libs\GlMath` (clipper degli angoli), `Libs\Models` (MD2 e DDMODEL), `Libs\Automap` (finestra sulla mappa), `Libs\Endoom`, `Libs\Screenshot`. **Non collegato di proposito** (costo sul percorso caldo): `R_ScaleFromGlobalAngle*`, le tabelle hi-res, `R_ReadDS32Cache`, `V_FindAproxColorIndex`, il melt del wipe (vedi le sezioni `Libs\Imaging` e `Libs\Palette` di `CLAUDE.md`).

## 7. Prima fetta fatta in questa issue

Due fette **fredde**, cioe eseguite una volta per texture o per livello, senza toccare nulla di per-colonna o per-fotogramma. In entrambe la logica sta in una classe di `Libs\Renderer` con le dipendenze dal costruttore, e il codice storico resta la facciata.

**A. Tabella delle colonne di una texture** (`R_GenerateLookup` di `Base\r_data.pas:569`). `TRendererTextureLookup` (`IRendererTextureLookup.Build`) conta per ogni colonna quante patch la coprono e dove sta (la sola patch che la ha, `RENDERER_COLUMN_COMPOSITE` = -1 per il blocco composto, `RENDERER_COLUMN_WITHOUT_PATCH` = -2), e restituisce la dimensione del blocco composto. Le patch le dà `IRendererPatchSource` (nel motore `TEngineRendererPatchSource`, `Base\DelphiDoom.Engine.Renderer.PatchSource.pas`: `W_CacheLumpNum(lump, PU_STATIC)` mentre la patch e aperta, `Z_ChangeTag(PU_CACHE)` quando si rilascia; in Doom il controllo `TYPE_PATCH or TYPE_SPRITE`, in `{$IFDEF DOOM}` come prima), gli avvisi vanno a `ILog.DevWarning` con gli stessi testi di prima. `R_GenerateLookup` ora riempie un `TRendererTextureInfo` (nome, dimensioni, patch con lump e `originx`), copia in due array le colonne che ha, chiama `Build` e riscrive le tabelle (`texturecolumnlump`, `texturecolumnofs`, `texturecompositesize`). Le colonne che la libreria non scrive restano come il chiamante le ha date (come prima: `colofs` di una colonna senza patch era memoria non inizializzata, e `R_GetColumn` non la legge).

**B. Misure del livello del renderer software** (`R_CalcSectors` e `R_PrecalcSegs` di `Base\r_segs2.pas:4418` e `:4444`, chiamate da `TLevelLoader` a ogni livello). `TRendererLevelPrecalc` (`IRendererLevelPrecalc`): `MeasureHeights` (pavimento piu basso, soffitto piu alto e se servono le mura alte, soglia `RENDERER_TALL_WALL_OFFSET` = 2048 unita, con `Int64`) e `MeasureSegments` (lunghezza di ogni seg in unita di mappa con `Round` bancario e inverso in `Double`; le differenze delle coordinate si fanno in 32 bit e poi diventano `Double`, come prima, con `{$Q-}`/`{$R-}`). Le facciate copiano vertici e settori in array, chiamano la libreria e riscrivono `lowestfloor`, `highestceiling`, `level_needs_tall_walls`, `seg.map_length`, `seg.inv_length`. `R_DistToSeg` e `R_CalcSegOffset` (per muro, ogni fotogramma) **restano com'erano**: sono per muro e leggono `viewx/viewy`.

Il collegamento: `ComposeRenderer` in `DelphiDoom.Engine.Composition` crea le classi con `TRendererFactory` e le dà a `R_ConfigureTextureLookup` (`r_data`) e, nel software, a `R_ConfigureLevelPrecalc` (`r_segs2`); senza configurazione danno `I_Error` (come le altre facciate). Le unit sono nei 12 `.dpr`; i test sono in `Tests\DelphiDoom.Tests.Renderer` (aggiunto a `TESTS` di `Tools\build.bat`).

**Parita**: i test contengono il vecchio algoritmo copiato (stessi cicli, stessi nomi, sui byte delle patch) e lo confrontano con la libreria su 400 texture casuali (colonne, lump a 16 bit, dimensione del blocco, testo e ordine degli avvisi) e su 300 serie di settori e 2000 seg (bit per bit). Non c'e un golden di un'esecuzione vera del motore: il confronto vero (avvisi di `-devparm` con vecchio e nuovo eseguibile sui WAD di `bin\`) e descritto in `RUN-156.md`.

## 8. Fette non fatte, e perche

- **Vista** (`R_ExecuteSetViewSize` senza il ciclo caldo + `R_InitTextureMapping` + `R_InitBuffer`): e fredda ma **non e solo calcolo**: legge `ST_Y/SB_Y` e `V_PreserveY` (diversi per gioco e per software/GL: sono una decina di blocchi `{$IF}` nella sola procedura), `R_GetRelativeAspect`, `R_Fake3DAspectCorrection(viewplayer)`, `screens[SCN_FG]` e `screen32` (`ylookup`), e scrive una ventina di globali; con `oldfocallength` come cache. Si puo fare (vedi 10, fetta 1) ma richiede un harness di parita con 4 giochi x taglie di vista x aspetti: **senza compilatore ne esecuzione, in questa ondata, il rischio supera il vantaggio**. La parte aritmetica (altezza della vista come funzione di `setblocks`, `ST_Y`, schermo e gioco) e pura; le tabelle (`viewangletox`, `xtoviewangle`, `yslope`, `slyslope`, `distscale`) sono funzioni pure di `centerxfrac`, `viewwidth`, `fov`, `projectiony` e `finetangent`.
- **Resto di `r_data`** (`R_InitFlats`, `R_InitSpriteLumps`, `R_InitColormaps`, `R_PrecacheLevel`): fredde ma scrivono le tabelle lette per colonna (`spritewidth`, `flats`...) con `malloc` e puntatori (`W_CacheSpriteNum`, `V_*`); vanno dietro `IRendererTextureCatalog` con le stesse tabelle come uscita (fetta 2).
- **Tutto il percorso caldo** (tabella 4, rischio A): per la regola "niente chiamate a interfaccia per pixel/colonna" e per i registri `dc_*`/`ds_*` (sezione 3), non si migra in questa fase.

## 9. `IRenderer` proposto

Principio: **le interfacce sono a granularita di livello, di cambio di vista o di fotogramma** (al massimo per muro o per oggetto, qualche migliaio di chiamate al fotogramma: 2-5 ns ciascuna, ben sotto il 5%); **mai per colonna o per pixel**: li' restano procedure scelte a freddo (come `colfunc`, oggi) e registri in un record. Le differenze tra software e OpenGL e tra i giochi sono **strategie iniettate**, non `{$IF}` (un `TRendererProfile` per gioco, come `TUdmfGames`/`TActorDefProfiles`: `ST_Y`/`SB_Y`, sky, colormap predefinite, `aprox_black`...).

```pascal
IRenderer = interface              // facciata di r_main: R_Init, R_SetViewSize, R_RenderPlayerView...
  procedure Initialize;            // R_Init: costruisce le parti
  procedure SetViewSize(ABlocks, ADetail: Integer);
  procedure RenderPlayerView(const APlayer: Pointer);   // opaco
  procedure Ticker;
  procedure Shutdown;
end;

IRendererViewSetup = interface     // fetta 1: puro. Dal TRendererViewInput (setblocks, schermo, fov, aspetto, profilo)
  function Calculate(const AInput: TRendererViewInput): TRendererViewState;  // viewwidth, viewheight, centerx.., projection, pspritescale...
  function MapColumnsToAngles(...): TRendererAngleTables;                   // viewangletox, xtoviewangle, clipangle
  function SlopeTables(...): TRendererPlaneTables;                          // yslope, slyslope, distscale
end;

IRendererTextures  = interface     // R_InitTextures, texturetranslation, R_TextureNumForName: dati; R_GetColumn resta funzione
IRendererFlats     = interface     // R_InitFlats, FLATINFO, terreno
IRendererSprites   = interface     // fetta 3: R_InitSpriteDefs/R_InstallSpriteLump -> sprites[]; ordinamento (ISpriteSorter, strategia)
IRendererSky       = interface     // R_InitSky/R_InitSkyMap per gioco (profilo)
IRendererLights    = interface     // luce per livello (scalelight), luci dinamiche: gia IDynLightRenderCache
IRendererLevel     = interface     // misure del livello: IRendererLevelPrecalc (fatta) + precalcolo di punto-in-subsector (fetta 5)
IRendererFramePlan = interface     // fetta 8: i passi di un fotogramma come lista (BSP, piani, 3D floors, masked, post) per backend

IRendererBackend = interface       // strategia: TSoftwareBackend (8/32 bit, single/MT) e TOpenGlBackend
  procedure BeginFrame;  procedure DrawScene;  procedure EndFrame;
end;
```

`IRendererBackend` non nasce per sostituire `R_RenderBSPNode` (che e comune al disegno e riempie liste o scrive colonne): nasce per dire "come si chiude il fotogramma" (la sequenza di `R_DoRenderPlayerView*` e di `gld_StartDrawScene/gld_DrawScene/gld_EndDrawScene`). Le procedure delle colonne e degli span non entrano nell'interfaccia: restano puntatori a procedura risolti a freddo da una tabella (`R_SetRenderingFunctions` diventa dati: il dettaglio, la profondita di colore e il thread scelgono una riga).

Quello che **non** va in classi: thinker e savegame (formato su disco), `FixedMul`/`FixedDiv` e gli angoli (#41), `r_clipper` (terzi), `r_defs` (tipi).

## 10. Ordine di migrazione, stima e criteri

Stime in giorni di lavoro con compilatore e prove a runtime (una persona). Ogni fetta: libreria pura + facciata che resta + test con vecchio copiato nel test + prova a runtime.

| # | Fetta | Stima | Rischio | Criterio di verifica |
|---:|---|---:|---|---|
| 0 | **Fatta**: tabella delle colonne (`R_GenerateLookup`), misure del livello (`R_CalcSectors`, `R_PrecalcSegs`) | - | B | test di parita (400 texture, 300 livelli, 2000 seg); avvisi `-devparm` identici su `bin\<Gioco>` |
| 1 | Vista: `R_ExecuteSetViewSize` (senza `R_SetRenderingFunctions` e `R_RecalcColormaps`), `R_InitTextureMapping`, `R_InitBuffer` (le tabelle, non `ylookup`) | 1,5 | M | per 4 giochi x `screenblocks` 3..11 x dettaglio x aspetto 1,0/1,33/1,78: **impronta FNV-1a** di tutte le tabelle e dei globali scritti, vecchio contro nuovo nello stesso eseguibile |
| 2 | Resto di `r_data` freddo (`R_InitFlats`, `R_InitSpriteLumps`, `R_InitColormaps`, `R_PrecacheLevel`) e `r_pk3textures` (568 righe) | 2,5 | M | dump di `flats[]`, `spritewidth/offset/topoffset/present` e delle colormap: identici su 5 WAD (Freedoom 2, shareware, Heretic, Hexen, Strife) con e senza PK3 |
| 3 | Definizioni degli sprite (`R_InstallSpriteLump`, `R_InitSpriteDefs`) | 1 | B | dump di `sprites[]` (nome, frame, `lump`, `flip`) identico; mobj con sprite mancanti: stessi avvisi |
| 4 | Cielo, aspetto (con `IDisplayModeCatalog`), `r_camera`/`r_earthquake` come strategie; tabelle di `r_fake3d` | 1,5 | B/M | globali identici dopo `R_Init` e dopo ogni `R_SetupFrame` di 3 demo |
| 5 | Precalcolo punto-in-subsector (`r_subsectors:88`) | 1 | M | l'array precalcolato identico su tutte le mappe dei WAD di `bin\` |
| 6 | `R_SetRenderingFunctions` (1060 righe) come tabella di dati (per dettaglio, profondita, thread, gioco) | 2,5 | M | per ogni combinazione, i **puntatori** assegnati (almeno 60 variabili) uguali a quelli del vecchio nello stesso eseguibile |
| 7 | Geometria OpenGL a freddo (`gld_FlatEdgeClipper`, `gld_FlatConvexCarver`, `gld_CarveFlats`, `gld_PreprocessSectors`, `gl_render.pas:1534`-`2030`) | 4 | M | liste di vertici dei flat identiche (sono array in `Double`): confronto per mappa su 5 WAD |
| 8 | Orchestrazione del fotogramma (`R_DoRenderPlayerView*` `:3693`-`3966`) come `TRenderer` con la lista dei passi per backend | 3 | A | **parita di fotogramma** (sotto) su 3 demo di Doom e almeno una di Heretic, Hexen, Strife, single e multi thread |
| 9 | Ordinamento dei vissprite (`r_things_sortvissprites`) come strategie | 1,5 | M | stesso ordine su 3 demo; -timedemo entro +5% |
| 10 | Interpolazione (`r_intrpl`) a classi | 3 | A | stati dei mobj interpolati identici ogni tic su demo; salvataggi invariati |
| 11 | Il percorso caldo: registri `dc_*`/`ds_*` in un record, procedure di colonna e span, seg loops, piani, sprite, GL | 15+ | A | solo dopo la #41; una procedura alla volta; parita di fotogramma e -timedemo entro +5% a ogni passo |

**Parita di fotogramma** (criterio per le fette 8-11): impronta FNV-1a dello schermo a 32 bit (`screen32`, `SCREENWIDTH * SCREENHEIGHT` pixel) a ogni N tic di `-timedemo demo1/2/3` (Doom shareware), con `usemultithread = 0` e con 1, vecchio eseguibile contro nuovo: tutte le impronte uguali. Serve un gancio temporaneo nel motore (non committato: scrive in un file l'impronta di `screen32` in `I_FinishUpdate`, si toglie dopo la prova), come per le fette di `Libs\Imaging`. OpenGL non e confrontabile pixel per pixel (dipende dal driver): si confrontano le liste (muri, flat, sprite) prima di `gld_DrawScene`.

**Prestazioni** (criterio per le fette 8-11): `-timedemo demo1/2/3` di Doom e di Heretic, 4 prove per eseguibile con la macchina scarica (come nel `CLAUDE.md`: le prove vanno fatte a coppie, vecchio e nuovo vicini), `realtics` del nuovo non oltre +5% del vecchio; per i percorsi per muro, in piu un micro-benchmark della classe (ns per chiamata).

Le fette 0-7 non toccano il percorso caldo: il loro costo e a livello di livello o di vista, quindi basta la parita delle uscite.

## 11. Cose trovate leggendo (difetti e rifiuti, non toccati)

- `Base\r_main.pas:1418` (`R_InitPointToAngle`) e `:1440` (`R_InitTables`): il corpo che calcolava le tabelle e commentato (ora sono in `Libs\MathCore`); resta solo l'assegnazione di `finecosine` e `fixedcosine`. `R_InitPointToAngle` e vuota.
- `Base\r_aspect.pas:173` (`R_InitAspect`) enumera i modi video con `EnumDisplaySettings` per conto suo (cerca il modo a 32 bit piu grande di 640x480): ripete cio che fa `IDisplayModeCatalog` (`Libs\Video`).
- `texturecolumnlump` e un array di `SmallInt` (`Base\r_defs.pas:961`): un numero di lump oltre 32767 (un PK3 grande con le texture) viene troncato quando `R_GenerateLookup` scrive il lump della patch. **Conservato** dalla libreria (il test di parita copia il troncamento); la correzione richiede `Integer` e cambia la dimensione della tabella (`r_wall*` e `r_cache_walls` la leggono).
- `R_GetColumn` (`Base\r_data.pas:653`) tratta `lump > 0` come "patch intera": il lump numero 0 (mai una patch in un WAD valido) andrebbe nel blocco composto. Come in Doom originale.
- Le 256 varianti di `R_RenderSegLoop*` sono generate dall'inclusione dei due `.inc` con combinazioni di `{$DEFINE}`; `R_SetDrawSegFunctions` (`r_segs2.pas:4037`) le sceglie con una catena di `if` sulle stesse bandiere. E il candidato naturale per la tabella di strategie della fetta 11.
- `r_clipper.pas` (7132 righe) e il 9% del codice del renderer per righe e non e di DelphiDoom: conviene escluderlo dai conteggi.
