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
1. **Shader**: una shader che non carica non e' una voce propria della tabella (il C ne fa una con `defaultShader`): e' la voce 0. Cambia solo il numero assoluto di `sortedIndex`, non l'ordine di quelle disegnate. Le chiavi sono nome + indice di lightmap (`LIGHTMAP_2D` per `RE_RegisterShader`, `LIGHTMAP_NONE` per le shader dei md3 e della nebbia, `LIGHTMAP_BY_VERTEX` per le soup e i flare). Il collasso del multitexture e' applicato alle shader che il registro ha letto senza (la scheda ha due unita' e `GL_ADD`).
2. **Viste in specchio o portale** (`R_MirrorViewBySurface`): non fatte. Le superfici con `sort == SS_PORTAL` restano nella lista e sono contate in `Stats.PortalSurfaces`.
3. **md3**: solo LOD 0; **skin non tenute** (con `customSkin` le superfici prendono la shader di default, che e' quello che il C fa per una skin senza voce per la superficie); niente `R_SetupEntityLighting`; MD4 non portato.
4. `R_AddWorldSurfaces` con 32 dlight: `(1 << 32) - 1` e' 0 a x86 (shift mascherato), come il C. `r_showcluster` non c'e': il primo `R_MarkLeaves` marca sempre (il flag `modified` della cvar nuova).
5. Un fog che il BSP non rende possibile (mattone fuori dai lump) ha una scatola vuota (il C si ferma con un errore).
6. `RE_AddRefEntityToScene` con `reType` che non esiste, e `RE_RenderScene` senza mondo e senza `RDF_NOWORLDMODEL`, sono `EQ3RenderException` (il C: `ERR_DROP`); l'adattatore le prende e le segnala all'`ILog`.
7. **Backend non portato** (contato in `Backend.Stats`): griglie delle patch, flare, superfici di poligoni, sprite, raggi e md3, cielo, passo dei dlight (`ProjectDlightTexture`), passo della nebbia (`RB_FogPass`: il fog number e' forzato a 0 nel calcolo dei colori), ombre con lo stencil, `RB_Hyperspace`, `RB_ShowImages`, video map. La scheda e' quella di OpenGL 1.x con `glLockArraysEXT` e due unita' di texture; `r_overBrightBits` 1 (luce di identita' 0,5). L'ordine di `glDrawElements`: l'indice, i vertici, le coordinate e i colori che il C legge dai puntatori sono impronte nella stessa chiamata (i puntatori delle `gl*Pointer` sono simbolici: il numero dice quale buffer).
8. Le texture si numerano al primo `glBindTexture` (il C le numera alla creazione).

**Difetti del C conservati**: `needDlights` come 0/1 passato come maschera (solo il dlight 0 per i brush model), `R_MarkLeaves` che scorre anche i nodi di decisione con cluster e area 0, `qsortFast` non stabile (e' l'ordine dei pari merito), `tr.viewCount` incrementato due volte per vista.

## Cosa non c'e' (R2)

Il contesto WGL vero, `R_CreateImage` e le texture (mipmap, gamma, `glTexImage2D`), cielo (`tr_sky.c`), flare, ombre, passo dei dlight e della nebbia, tassellazione delle griglie e superfici di entita'/poligoni/md3 (`tr_surface.c`, `tr_mesh.c`), `R_LightForPoint` (i dati del light grid ci sono: `IQ3RenderWorld.GetLightGrid`), `RE_MarkFragments`, `RE_RegisterFont`; finestra, input, suono e menu (sono dei moduli `Framework\GameHost` e del composition root `Quake3`). Il piano e' in `docs\Q3RENDER_CENSIMENTO.md`.

## Licenza

GPL v2 o successiva (intestazione "Based on the Quake III Arena GPL Source Code (id Software)" nelle unit portate). **Dipendenze da codice di Doom 3 (GPL v3 o successiva con i termini aggiuntivi, `docs\LICENZE.md`)**: il lettore md3 (`Framework\Models`, `Models.Static.Md3.*`, #105, da `Model_md3.cpp`), il gestore delle dichiarazioni (`IdTech4\Decl`, `TDeclManager` da `DeclManager.cpp`, da cui passa la tabella delle shader) e `Framework\IdLib`: un eseguibile che include `Q3Render` e' quindi GPL v3 o successiva, non v2. La libreria stessa e' v2 o successiva. Per un eseguibile solo v2 andrebbero riscritti il lettore md3 e il gestore delle shader dal C di Quake III; non e' stato fatto (decisione sulle licenze del 2026-11-17: v3 o successiva accettata).
