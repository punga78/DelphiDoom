# IdTech4\Q3Render

Renderer di Quake III Arena **senza OpenGL**, fasi R0 e R1 (issue #254; piano e censimento: `docs\Q3RENDER_CENSIMENTO.md`, numeri sui `.qvm` di OpenArena: `docs\QUAKE3_CENSIMENTO.md` par. 9). Quello che cgame e ui chiedono al renderer (`re.RegisterShader`, `re.RegisterModel`, `re.LoadWorld`, `re.ModelBounds`, `re.LerpTag`, `re.inPVS`) si serve da dati veri: immagini decodificate, script `.shader` letti, md3 letti, BSP in liste di superfici. Non disegna e non apre nessun contesto. Una classe per unit, `DelphiDoom.Q3Render.*`, dipendenze iniettate, `TQ3RenderFactory` come composition root. **Nessun chiamante nel motore.**

```pascal
LSystem := TQ3RenderFactory.CreateSystem(LFileSystem);                       // IGameFileSystem di Framework\Wad
LRenderer := TQ3RenderFactory.CreateHostRenderer(LRecordingRenderer, LSystem); // IQ3HostRenderer per IQ3HostClientServices
// dopo CG_INIT:
LSystem.Shaders.RegisteredCount; LSystem.Images.MissingNames; LSystem.Models.LoadedCount;
```

## Mappa C -> Pascal

| C (`renderer\`) | Pascal | Note |
|---|---|---|
| `LoadTGA` (`tr_image.c`) | `TQ3TgaReader` (`Image.TgaReader`) | tipi 2, 3, 10; zero differenze dal C vero (23 file, tutti gli errori) |
| `LoadJPG` (`tr_image.c`) | `TQ3JpegReader` (`Image.JpegReader`) sopra `Framework\Jpeg` | IDCT float, filtro triangolare, RGB, alfa 255; tolleranza sotto |
| `R_LoadImage` | `TQ3ImageLoader` (`Image.Loader`) | `.tga` poi `.jpg`; con `AExtensionSearch` la ricerca di ioquake3 (OpenArena) |
| `R_FindImageFile` (senza GL) | `TQ3ImageCatalog` (`Image.Catalog`) | nome -> handle, mancanti ricordati |
| `R_FindShader`, `RE_RegisterShader` | `TQ3ShaderRegistry` (`Shader.Registry`) sopra `IdTech4\Decl` | le immagini degli stage; difettosa = handle 0 |
| `RE_RegisterModel`, `R_LoadMD3` (parte dei dati), `R_ModelBounds`, `R_LerpTag` | `TQ3ModelRegistry` (`Model.Registry`) sopra `Framework\Models` | LOD, shader delle superfici, modelli `*N` del mondo |
| `RE_LoadWorldMap`, `R_LoadSurfaces` e le altre `R_Load*` | `TQ3WorldLoader` (`World.Loader`) sopra `IdTech4\MapFile` | ordine del C; superfici per tipo |
| `world_t`, `R_PointInLeaf`, `R_inPVS` | `TQ3RenderWorld` (`World.Data`) | |
| `re.*` di `cl_cgame.c` e `cl_ui.c` | `TQ3HostRendererAdapter` (`Host.Adapter`), decora un `IQ3HostRenderer` | il registratore di `Q3Host` resta sotto |
| `ri.FS_ReadFile` | `IQ3RenderFiles`, `TQ3RenderGameFiles` (`Files.GameFs`) | |

## Parita'

- **TGA e JPEG col C vero**: `Tools\Verifica\254\imagegen.c` include senza modifiche `LoadTGA` e `LoadJPG` ritagliate da `tr_image.c` e il `jpeg-6` di Quake III; `Make-Image-Golden.ps1` scrive `Tests\Data\Q3Render\image.golden.txt` (23 file del repository in `Tests\Data\IdImages\tga`, `Tests\Data\Q3Render\tga` e `Tests\Data\Jpeg`, piu' 34 JPEG e 35 TGA di `pak0.pk3` di OpenArena letti da `Reference`, il test relativo e' ignorato se manca). TGA: **zero differenze**. JPEG dei file del repository (4:4:4): zero. JPEG di OpenArena: 33 su 34 uguali; uno ha 36 byte su 262 144 che differiscono di 1-2: l'IDCT float del C non e' stabile tra compilazioni (tre compilazioni del C danno due risultati diversi per quel file), la tolleranza del test e' dichiarata (`SameWithinFloatDct`: al piu' 3 JPEG, somma dei byte entro 128).
- **Il resto** non ha una risposta del C compilabile da solo e si prova con test sul comportamento letto dal C: shader (la lettura ha la sua parita' in `Tests.Decl`), md3 (letto da `Framework\Models`, parita' sul C in `Tests.Models`), BSP (parita' in `Tests.MapFile`). `TQ3WorldLoader` e' provato sui BSP di `Tests\Source\DelphiDoom.Tests.MapFile.BspSample` (nessun BSP nel repository) e su `oa_dm1` di OpenArena.
- **Prova sui dati veri** (`TTestQ3RenderReach`, saltata senza OpenArena): `qagame` fa `GAME_INIT`, `cgame` fa `CG_INIT` e un fotogramma, `ui` il menu, con l'adattatore al posto del registratore (stessi 12 `.qvm`, stesse chiamate): `reach.golden.txt`, Win32 = Win64.

## Differenze volute dal C

1. **Ricerca delle immagini di ioquake3** (opzione `AExtensionSearch`, attiva in `CreateSystem`): OpenArena scrive `clampmap menu/art/skill1` senza estensione e il suo motore (ioquake3) prova `.png`, `.tga`, `.jpg`, `.pcx`, `.bmp`; il `R_LoadImage` di Quake III 1.32 dice "nessuna immagine". Con `False` il comportamento e' quello di 1.32 (test).
2. PNG, PCX e BMP non si decodificano (contati in `TQ3ImageLoader.UnsupportedFound`); MD4 non portato.
3. Un file TGA che finisce prima dell'immagine, una larghezza o altezza negativa (il C la legge `short` con segno) o sopra 8192 sono `EQ3RenderException` (il C legge oltre il buffer o alloca gigabyte). Un JPEG in scala di grigi e' R = G = B (il C scrive 4 byte per pixel in un buffer da 1: testato sul C vero, un file del repository lo manda in un ciclo), un JPEG rovinato o troncato e' `False` (il C chiama `exit`).
4. Un'immagine che non carica (o che solleva) e' **mancante** e ricordata: non si rilegge (il C la cerca a ogni richiesta). I pixel si tengono solo con `AKeepPixels` (le immagini di un gioco sono centinaia di megabyte).
5. **`R_inPVS`** come `CM_ClusterPVS`: senza dati di visibilita' la riga e' tutta uno (si vede tutto); con i dati, un cluster fuori tabella ha la riga del cluster 0; un punto in una foglia solida (cluster -1) legge il byte prima della riga (`vis[-1 >> 3]`, bit 7: l'ultimo byte della riga precedente; per la prima riga il C legge memoria dell'heap prima del blocco, qui zero). Nessuna divergenza voluta se non quest'ultima.
6. Una superficie che i caricatori rifiutano (vertici o indici oltre i lump) e' contata in `RefusedCount` e lasciata fuori (il C legge fuori dal lump): `IdTech4\MapFile` le segnala.
7. Le shader di un md3 si registrano per ogni LOD letto, anche se solo il LOD 0 si tiene. Il modello che non carica non e' un modello difettoso nella tabella (il C tiene una voce `MOD_BAD`): qui e' ricordato come mancante e `Register` da' 0.
8. Le numerazioni dei handle sono quelle della libreria (1, 2, ...), **non** quelle del registratore di `Q3Host`: l'adattatore tiene la corrispondenza e ai moduli da' sempre i numeri del registratore.

## Difetti del C conservati

- `LoadTGA` accetta il tipo 3 con 24 o 32 bit (lo `switch` e' sulla profondita'), un'esecuzione RLE puo' passare da una riga all'altra e finisce all'ultima riga, il bit "origine in alto" e' solo un avviso (non capovolge): tutto conservato e nel golden.
- `LoadJPG` termina con `jpeg_destroy_compress` su un decompressore, e legge un blocco intero di 4096 byte oltre la fine del file.
- `R_ModelBounds` di un modello a maglia dice i limiti del **primo** fotogramma.

## R1: la lista di disegno e il backend sul registratore di chiamate GL (ondata 13, 2026-11-19)

Fase R1 del renderer (piano: `docs\Q3RENDER_CENSIMENTO.md` par. 2 e 4). Quello che cgame costruisce con `re.ClearScene`, `re.AddRefEntityToScene`, `re.AddPolyToScene`, `re.AddLightToScene`, `re.RenderScene`, `re.SetColor`, `re.DrawStretchPic` diventa una **lista di `drawSurf_t` ordinata per shader** (il fronte) e, tra `BeginFrame` e `EndFrame` dell'adattatore, un **flusso di chiamate GL scritte come testo** nel registratore di `Framework\OpenGlBinding\Recorder` (il backend). Nessun contesto OpenGL, nessuna texture: i numeri di texture sono 1, 2, 3... nell'ordine in cui le immagini si legano la prima volta.

```pascal
LGl := TGlCallRecorder.Create(LStream);                                  // IGlCallRecorder
LRenderer := TQ3RenderFactory.CreateRenderingHostRenderer(LRecorder, LSystem, LGl);
LAdapter := LRenderer as TQ3HostRendererAdapter;
LAdapter.BeginFrame;  { ...CG_DRAW_ACTIVE_FRAME, i re.* di cgame... }  LAdapter.EndFrame('cgame frame');
LAdapter.Renderer.Front.Stats; LAdapter.Renderer.Backend.Stats;         // drawSurf, batch, superfici non portate
```

| C (`renderer\`) | Pascal | Prova |
|---|---|---|
| `RE_ClearScene`, `RE_AddRefEntityToScene`, `RE_AddDynamicLightToScene`, `RE_AddPolyToScene` (limiti, fog dei poligoni) | `TQ3SceneBuffers` (`Scene.Buffers`) | test sul comportamento |
| `refEntity_t`, `refdef_t`, `polyVert_t` dalla memoria del modulo | `TQ3SceneReader` (`Scene.Reader`), tipi in `Scene.Types` | dimensioni e offset |
| `R_RotateForViewer`, `R_RotateForEntity`, `R_SetupFrustum`, `SetFarClip`, `R_SetupProjection` | `TQ3ViewSetup` (`View.Setup`) | **C vero** |
| `R_CullLocalBox`, `R_CullPointAndRadius`, `R_CullLocalPointAndRadius` | `TQ3ViewCuller` (`View.Culler`) | **C vero** (via `R_RecursiveWorldNode`) |
| `R_MarkLeaves`, `R_RecursiveWorldNode`, `R_CullSurface` (`R_CullGrid`, `R_CullTriSurf`), `R_DlightSurface`, `R_AddWorldSurface`, `R_AddWorldSurfaces`, `R_AddBrushModelSurfaces` | `TQ3WorldSurfaceAdder` (`World.Surfaces`) | **C vero** (brush model e griglie: solo test sul comportamento) |
| `R_AddDrawSurf`, `R_DecomposeSort` | `TQ3DrawList` (`Draw.List`) | **C vero** |
| `qsortFast`, `shortsort` | `TQ3DrawSurfSorter` (`Draw.Sorter`), passo per passo | **C vero** (l'ordine dei pari merito) |
| `R_GenerateDrawSurfs`, `R_AddEntitySurfaces`, `R_AddPolygonSurfaces`, `R_AddMD3Surfaces` (`R_CullModel`, `R_ComputeFogNum`), `R_SortDrawSurfs`, `R_RenderView`, `RE_RenderScene` | `TQ3FrontEnd` (`Scene.FrontEnd`) | **C vero** per mondo e ordinamento; entita' e md3: test sul comportamento |
| `R_FindShader` (chiave nome + indice di lightmap, shader di sola immagine), `CreateInternalShaders`, `SortNewShader` | `TQ3ShaderTable` (`Shader.Table`) | test sul comportamento |
| `renderCommandList_t`, `RE_BeginFrame`, `RE_SetColor`, `RE_StretchPic`, `R_AddDrawSurfCmd`, `RE_EndFrame` | `TQ3CommandList` (`Frame.Commands`), `TQ3Renderer` (`Frame.Renderer`) | test sul comportamento |
| `GL_Bind`, `GL_SelectTexture`, `GL_TexEnv`, `GL_Cull`, `GL_State` | `TQ3GlState` (`Backend.State`) | test sul comportamento |
| `RB_ExecuteRenderCommands`, `RB_DrawSurfs`, `RB_RenderDrawSurfList`, `RB_BeginDrawingView`, `RB_SetGL2D`, `RB_StretchPic`, `RB_BeginSurface`, `RB_EndSurface`, `RB_StageIteratorGeneric`, `RB_StageIteratorVertexLitTexture`, `RB_StageIteratorLightmappedMultitexture`, `DrawMultitextured`, `RB_SurfaceFace`, `RB_SurfaceTriangles` | `TQ3Backend` (`Backend.Executor`), `IQ3GlSink`/`TQ3GlRecordingSink` (`Backend.Gl`) | **golden di regressione, nessun oracolo** |

**Parita' (e dove non c'e')**. Il fronte e' provato contro il **vero** `tr_main.c` e `tr_world.c` di Quake III compilati con gcc (`Tools\Verifica\254\build-front.sh`: `frontgen.c` carica `maps/oa_dm1.bsp` come `R_LoadNodesAndLeafs`, `R_LoadMarksurfaces`, `R_LoadVisibility` e le `Parse*` di `tr_bsp.c` e fa girare `R_RenderView` su 6 viste di `Tests\Data\Q3Render\front.views.txt`, 2 con dlight): frustum, matrice di proiezione, limiti del visibile, e per ogni vista la lista ordinata di `(chiave di sort, superficie)` (600 drawSurf, 83 con i bit dei dlight) uguali **bit per bit** a Win32 e a Win64 (`front.golden.txt`, `TTestQ3Front`). Le shader della prova non sono quelle del gioco: la shader k del BSP ha `cullType = k mod 3`, `sort = SS_OPAQUE`, `sortedIndex = (3k mod 8) + 1` (pochi valori, molti pari merito: prova che l'ordine di `qsortFast` e' lo stesso). **Il backend non ha un oracolo**: il C disegna in un contesto vero e qui non c'e' ne' un contesto ne' un C che giri senza. `backend.golden.txt` (somma FNV di ogni fotogramma del registratore, contatori e superfici non portate su `oa_dm1`, 6 fotogrammi di una vista e di un 2D piu' uno solo 2D) dice solo che il flusso non cambia per caso: **non e' parita' con il C**. Win32 e Win64 danno lo stesso flusso.

**Numeri sul primo fotogramma di cgame di OpenArena** (`reach.render.golden.txt`, stesso pilota della R0: `oa_dm1`, uno snapshot finto): `CG_INIT` non fa nessuna scena; il primo fotogramma ne fa **una e produce 57 drawSurf**, tutte facce del mondo (nessuna entita': lo snapshot finto non ne ha), disegnate dal backend in **37 batch** con 53 `StretchPic` (HUD) e 24 texture; la ui fa altre 3 scene (nove superfici md3, col mondo spento: `RDF_NOWORLDMODEL`) e 897 `StretchPic`.

**Differenze volute dal C (R1)**
1. **Shader**: una shader che non carica non e' una voce propria della tabella (il C ne fa una con `defaultShader`): e' la voce 0. Cambia solo il numero assoluto di `sortedIndex`, non l'ordine di quelle disegnate. Le chiavi sono nome + indice di lightmap (`LIGHTMAP_2D` per `RE_RegisterShader`, `LIGHTMAP_NONE` per le shader dei md3 e della nebbia, `LIGHTMAP_BY_VERTEX` per le soup e i flare). Il collasso del multitexture e' applicato alle shader che il registro ha letto senza (la scheda ha due unita' e `GL_ADD`). **Ordine di registrazione**: le shader delle superfici di un md3 entrano nella tabella quando l'adattatore registra il modello (come `R_LoadMD3`), ma solo quelle del LOD 0 (le altre sono nel registro, non nella tabella); `sortedIndex` tiene i pari merito nell'ordine di registrazione, quindi un LOD con shader diverse puo' dare un ordine diverso di shader con la stessa `sort`. Nella prova col C vero la tabella e' finta e il problema non c'e'.
2. **Viste in specchio o portale** (`R_MirrorViewBySurface`): non fatte. Le superfici con `sort == SS_PORTAL` restano nella lista e sono contate in `Stats.PortalSurfaces`.
3. **md3**: solo LOD 0; **skin non tenute** (con `customSkin` le superfici prendono la shader di default, che e' quello che il C fa per una skin senza voce per la superficie); niente `R_SetupEntityLighting`; MD4 non portato.
4. `R_AddWorldSurfaces` con 32 dlight: `(1 << 32) - 1` e' 0 a x86 (shift mascherato), come il C. `r_showcluster` non c'e': il primo `R_MarkLeaves` marca sempre (il flag `modified` della cvar nuova).
5. Un fog che il BSP non rende possibile (mattone fuori dai lump) ha una scatola vuota (il C si ferma con un errore).
6. `RE_AddRefEntityToScene` con `reType` che non esiste, e `RE_RenderScene` senza mondo e senza `RDF_NOWORLDMODEL`, sono `EQ3RenderException` (il C: `ERR_DROP`); l'adattatore le prende e le segnala all'`ILog`.
7. **Backend non portato** (contato in `Backend.Stats`): ombre con lo stencil, `RB_Hyperspace`, `RB_ShowImages`, video map e i flare (nel C con i default non disegnano nulla: vedi R1b). Griglie, poligoni, sprite, raggi, md3, cielo, passo dei dlight e della nebbia sono della R1b. La scheda e' quella di OpenGL 1.x con `glLockArraysEXT` e due unita' di texture; `r_overBrightBits` 1 (luce di identita' 0,5). L'ordine di `glDrawElements`: l'indice, i vertici, le coordinate e i colori che il C legge dai puntatori sono impronte nella stessa chiamata (i puntatori delle `gl*Pointer` sono simbolici: il numero dice quale buffer).
8. Le texture si numerano al primo `glBindTexture` (il C le numera alla creazione).

**Difetti del C conservati**: `needDlights` come 0/1 passato come maschera (solo il dlight 0 per i brush model), `R_MarkLeaves` che scorre anche i nodi di decisione con cluster e area 0, `qsortFast` non stabile (e' l'ordine dei pari merito), `tr.viewCount` incrementato due volte per vista.

## R1b: le superfici del backend, il cielo e i passi (ondata 14, 2026-11-19)

Quello che la R1 contava soltanto ora e' disegnato sul registratore, **con parita' sul C vero dove il C e' autonomo**. Il C si compila con gcc a 32 bit (SSE, `-D__STRICT_ANSI__`) in `Tools\Verifica\254\surfgen.c` + `build-surf.sh`: `tr_surface.c`, `tr_curve.c`, `tr_shade_calc.c` e `tr_noise.c` come sono (l'unica modifica e' il taglio dell'assembler x86 di `myftol` in `tr_shade_calc.c`), e **inclusi** nello stesso file `tr_bsp.c` (`ParseMesh`, `R_StitchAllPatches`, `R_FixSharedVertexLodError`), `tr_sky.c` e `tr_shade.c` (cosi' `ProjectDlightTexture` e `RB_FogPass` girano davvero). I comandi stanno in `Tests\Data\Q3Render\surf.cases.txt` (letto dal C e dal test) e `surf.map.cases.txt` (le 42 patch di `maps/oa_ctf2.bsp` di `pak1-maps.pk3` da quattro punti di vista); le risposte in `surf.golden.txt` (1479 righe) e `surf.map.golden.txt` (340). `TTestQ3Surfaces` le rifa' con la libreria e le confronta riga per riga: **zero differenze a Win32 e a Win64**.

| C (`renderer\`) | Pascal | Prova |
|---|---|---|
| `RB_SurfaceGrid` (`LodErrorForVolume`, righe e colonne del LOD, passate multiple), `RB_SurfacePolychain`, `RB_SurfaceSprite` (`RB_AddQuadStamp`), `RB_SurfaceBeam` (i vertici della striscia), `RB_SurfaceRailCore`, `RB_SurfaceRailRings`, `RB_SurfaceLightningBolt`, `RB_SurfaceMesh` con `LerpMeshVertexes`, `RB_CheckOverflow` | `TQ3SurfaceTessellator` (`Backend.Surfaces`) | **C vero** (i comandi di `surf.cases.txt`: griglie da 3x3 a 65x65 con `r_lodCurveError` 250, 0, negativo e enorme, orientamento dell'entita' e specchio, poligoni da 3 a 64 vertici, md3 con LOD e `backlerp`, overflow con il flush) |
| griglie di una mappa vera | `TQ3WorldLoader` + `TQ3SurfaceTessellator` | **C vero** (`ParseMesh`, cucitura, errori di LOD: 42 patch x 4 viste) |
| `R_InitSkyTexCoords`, `RB_ClipSkyPolygons`, `MakeSkyVec`, `DrawSkyBox`, `R_BuildCloudData`, `RB_StageIteratorSky`, `RB_DrawSun` | `TQ3SkyBox` (`Backend.Sky`) | **C vero** (tabelle delle nuvole, facce toccate, strisce, nuvole in `tess`, sole) |
| `ProjectDlightTexture`, `RB_FogPass` (con `RB_CalcFogTexCoords` di `IdTech4\Decl`), `R_TransformDlights` | `TQ3ShadingPasses` (`Backend.Passes`) | **C vero** (`ProjectDlightTexture` e `RB_FogPass` di `tr_shade.c`: texture, stato, indici e impronte degli array del `glDrawElements`) / `R_TransformDlights` test sul comportamento |
| `R_LoadFogs` (colore, `tcScale`, piano di superficie) | `TQ3Backend.BuildFogs` | test sul comportamento (le nebbie di `oa_dm1` partecipano al golden del backend) |
| `R_ComputeLOD`, `ProjectRadius`, il LOD in `R_AddMD3Surfaces` e in `R_CullModel`, i livelli di `RE_RegisterModel` | `TQ3FrontEnd.ComputeLod`, `TQ3ModelRegistry.LodCount/GetModelLod` | test sul comportamento (vicino: livello 0, lontano: 2), **nessun oracolo**: il C vero di `tr_mesh.c` non e' stato compilato |
| `RB_SurfaceAxis` (modello nullo), `RB_SurfaceEntity` | `TQ3Backend` | test sul comportamento |

**Misure** (`reach.render.golden.txt`, `backend.golden.txt`): il primo fotogramma di cgame su `oa_dm1` e' sempre **57 drawSurf, 37 batch**; `oa_dm1` non ha patch (0 griglie), le 3 scene della ui disegnano 9 superfici md3 (prima contate), i 6 fotogrammi del golden del backend con le luci delle viste fanno **18 draw del passo dei dlight e 6 della nebbia**, 230 batch e 48 texture. Le superfici delle entita' e i poligoni sono provati con una scena fatta a mano (`TTestQ3Entities`, senza OpenArena): poligono, sprite, raggio, rail core e rings, lightning, md3, modello nullo, cielo di una shader `skyParms`, tre livelli di detail.

**Differenze volute dal C (R1b)**
1. **Le tabelle delle nuvole** (`s_cloudTexCoords`, `s_cloudTexP`) sono globali nel C e le riscrive ogni shader sky letta (vale l'ultima per tutti i cieli); qui `TQ3SkyBox` le calcola per l'altezza delle nuvole della shader che disegna. Con un solo cielo per mappa e' lo stesso.
2. **Il box esterno** si disegna se la shader nomina un'immagine per `outerbox[0]`; il C lo salta anche se l'immagine e' `tr.defaultImage` (non trovata): qui il catalogo non e' interrogato.
3. **Le maschere dei dlight** per superficie stanno nel `drawSurf` (`TQ3SurfaceRef.DlightMask`) e non nella superficie, dove il C le lascia da un fotogramma all'altro (una luce spenta puo' lasciare un bit vecchio: nessun test lo dipende). `R_TransformDlights` si fa a ogni cambio di entita', non solo per i brush model con `needDlights`.
4. **I modelli md3** con un frame fuori dal modello sono un'eccezione (il C legge oltre la superficie); il front end rimette a 0 i frame invalidi e li **scrive nell'entita'** (il C li scrive in `ent->e`), cosi' il backend li trova. Un livello di detail che i file non hanno e' quello piu' dettagliato che c'e' (il C ha un puntatore NULL e si ferma); `r_lodbias` non anticipa l'uscita del ciclo dei livelli.
5. **NaN**: alcune patch di `oa_ctf2` hanno coordinate della lightmap che sono NaN gia' nel file (una patch senza lightmap); le impronte sono uguali solo se tutti i NaN sono lo stesso valore: il confronto (C e Delphi) porta ogni NaN a `7fc00000`, perche' il payload dipende dall'istruzione (x87 o SSE). `TQ3Backend.Execute` maschera le eccezioni della FPU come fa il C.
6. **Flare**: non portati e il C non li disegna con i default: `r_flares` vale 0, `RB_AddDlightFlares` e' commentata in `RB_RenderFlares` e `RB_SurfaceFlare` (la superficie del mondo) e' vuota. Le 10 superfici flare di `oa_dm1` sono contate in `Backend.Stats.SkippedFlares` e non disegnano nulla, come nel C. `RB_DrawSun` e' portato (con parita') ma, come nel C (`#if 0` in `RB_RenderDrawSurfList`), non e' chiamato.
7. **Specchi e portali**, ombre con lo stencil e `RB_ShadowFinish`, skin dei md3, `R_SetupEntityLighting`: come nella R1.

**Difetti del C conservati**: `R_BuildCloudData` che riempie `tess` una volta per stage senza svuotarlo e con tre stage e un cielo ampio supera `SHADER_MAX_VERTEXES` (il C si ferma con `ri.Error`: qui `EQ3RenderException`); `RB_SurfaceBeam` che non disegna nulla per un raggio lungo zero; `FillCloudBox` con `if ( 1 )` al posto di `fullClouds` (il ramo che cambia `MIN_T` per faccia e' codice morto); `RB_SurfaceMesh` e `RB_SurfacePolychain` che non scrivono il secondo set di coordinate di texture.

## Cosa non c'e' (R2)

Il contesto WGL vero, `R_CreateImage` e le texture (mipmap, gamma, `glTexImage2D`), ombre con lo stencil, specchi e portali, `R_LightForPoint` (i dati del light grid ci sono: `IQ3RenderWorld.GetLightGrid`), `RE_MarkFragments`, `RE_RegisterFont`; finestra, input, suono e menu (sono dei moduli `Framework\GameHost` e del composition root `Quake3`). Il piano e' in `docs\Q3RENDER_CENSIMENTO.md`.

## Licenza

GPL v2 o successiva (intestazione "Based on the Quake III Arena GPL Source Code (id Software)" nelle unit portate). **Dipendenze da codice di Doom 3 (GPL v3 o successiva con i termini aggiuntivi, `docs\LICENZE.md`)**: il lettore md3 (`Framework\Models`, `Models.Static.Md3.*`, #105, da `Model_md3.cpp`), il gestore delle dichiarazioni (`IdTech4\Decl`, `TDeclManager` da `DeclManager.cpp`, da cui passa la tabella delle shader) e `Framework\IdLib`: un eseguibile che include `Q3Render` e' quindi GPL v3 o successiva, non v2. La libreria stessa e' v2 o successiva. Per un eseguibile solo v2 andrebbero riscritti il lettore md3 e il gestore delle shader dal C di Quake III; non e' stato fatto (decisione sulle licenze del 2026-11-17: v3 o successiva accettata).
