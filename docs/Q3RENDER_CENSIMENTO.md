# Renderer di Quake III: censimento e fasi (issue #254, ondata 12a, 2026-11-18)

Censimento di `Reference\quake3\code\renderer` (GPL v2 o successiva, 23 893 righe in 26 file `tr_*.c`/`.h` e `qgl.h`) per portare il renderer dietro `IQ3HostRenderer` di `IdTech4\Q3Host`. Fa parte del piano `docs\QUAKE3_CENSIMENTO.md` (fase 5). Il numero di chiamate `qgl*` per file e' contato con grep: dice quanto di un file e' "stato OpenGL".

## 1. Moduli, cosa e' logica pura e cosa e' stato GL

| File (righe, chiamate `qgl*`) | Contenuto | Natura | Dove sta ora |
|---|---|---|---|
| `tr_shader.c` (3013, 1) | script `.shader`: `ParseShader`, `ParseStage`, `ParseVector`, `ParseTexMod`, `ParseDeform`, `ParseSkyParms`, `FinishShader`, `CollapseMultitexture`, `R_FindShader`, `RE_RegisterShader`, `R_RemapShader` | pura (parser e dati); `GeneratePermanentShader`, `SortNewShader`, `FixRenderCommandList` toccano le tabelle e la coda dei comandi del renderer | `IdTech4\Decl` (`Q3Shader.*`, #119 e #237, parita' col C vero); **`TQ3ShaderRegistry`** (R0) aggiunge le immagini degli stage e il numero di handle |
| `tr_shade_calc.c` (1205), `tr_noise.c` (95) | onde, colori, `tcMod`, `tcGen`, deformazioni, rumore, nebbia | pura (calcoli sui buffer) | `IdTech4\Decl` (`Q3Shader.Calc.*`, parita' zero differenze) |
| `tr_shade.c` (1361, 92) | `RB_StageIteratorGeneric`, `ComputeColors`, `ComputeTexCoords`, `DrawMultitextured`, luce dei vertici, `R_BindAnimatedImage` | meta' pura (`ComputeColors`, `ComputeTexCoords`: fatte), meta' stato GL (stati, blend, array di vertici, multitexture) | calcoli in `IdTech4\Decl`; il ciclo sugli stage e' **R1/R2** |
| `tr_image.c` (2520, 21) | `LoadTGA`, `LoadJPG`, `LoadPCX32`, `LoadBMP`, `R_LoadImage`, `R_FindImageFile`, `R_CreateImage` (miplevel, `GL_TexImage2D`), gamma, `R_InitFogTable`, `R_SkinList` | caricatori e tabella dei nomi puri; creazione della texture, mipmap con `r_picmip`, gamma e `glTexImage2D` sono GL | **R0**: `LoadTGA` e `LoadJPG` (`Image.TgaReader`, `Image.JpegReader`, parita' col C), `R_LoadImage` (`Image.Loader`), `R_FindImageFile` senza GL (`Image.Catalog`); PCX e BMP non portati; `R_CreateImage` e' R2 |
| `tr_bsp.c` (1862, 0) | `RE_LoadWorldMap`: `R_LoadLightmaps`, `R_LoadShaders`, `R_LoadPlanes`, `R_LoadFogs`, `R_LoadSurfaces` (`ParseFace`, `ParseMesh`, `ParseTriSurf`, `ParseFlare`), `R_LoadMarksurfaces`, `R_LoadNodesAndLeafs`, `R_LoadSubmodels`, `R_LoadVisibility`, `R_LoadEntities`, `R_LoadLightGrid`, `R_StitchAllPatches`, `R_FixSharedVertexLodError` | pura (nessuna chiamata GL: la lightmap e' un `R_CreateImage`) | `IdTech4\MapFile` (`Bsp.*`, #116 e #237, parita' col C vero); **`TQ3WorldLoader`** (R0) li compone nell'ordine di `RE_LoadWorldMap` |
| `tr_curve.c` (624) | `R_SubdividePatchToGrid`, `R_GridInsertColumn/Row`, `R_FixSharedVertexLodError` | pura | `Framework\MathCore` (`Patch.*`, #117) |
| `tr_model.c` (700, 0), `tr_animation.c` (171), `tr_mesh.c` (397) | `RE_RegisterModel`, `R_LoadMD3`, `R_LoadMD4`, `R_ModelBounds`, `R_LerpTag`, `R_AddMD3Surfaces`, `R_AddAnimSurfaces`, `R_CullModel`, scelta del LOD | caricamento e tag puri; `R_AddMD3Surfaces` mette le superfici nella lista di disegno (R1) | `Framework\Models` (md3 reader, `TagLerper`, #105 e #126); **`TQ3ModelRegistry`** (R0): `RE_RegisterModel` con i LOD e le shader delle superfici, `R_ModelBounds`, `R_LerpTag`, modelli `*N` del mondo; MD4 non portato (nessun file) |
| `tr_world.c` (668, 0), `tr_main.c` (1485, 10) | `R_PointInLeaf`, `R_inPVS`, `R_MarkLeaves`, `R_RecursiveWorldNode`, `R_CullSurface`, `R_SetupFrustum`, `R_RotateForEntity`, `R_CullLocalBox`, `R_Radix`, `R_SortDrawSurfs`, `R_DecomposeSort`, `R_RenderView` | quasi tutto puro (matematica e liste); `R_RenderView` chiama il backend | `R_PointInLeaf` e `R_inPVS` in **R0** (`World.Data`); il resto e' R1 (lista di disegno) |
| `tr_scene.c` (409) | `RE_ClearScene`, `RE_AddRefEntityToScene`, `RE_AddPolyToScene`, `RE_AddLightToScene`, `RE_RenderScene` | pura (liste e copia di strutture) piu' una chiamata a `R_RenderView` | oggi nel registratore di `Q3Host` (conta le chiamate); R1 le tiene |
| `tr_surface.c` (1215, 19) | `RB_SurfaceMesh`, `RB_SurfaceGrid` (tassellazione della patch), `RB_SurfaceFace`, `RB_SurfaceTriangles`, `RB_SurfaceBeam`, `RB_SurfaceRailCore/Rings`, `RB_SurfaceLightningBolt`, `RB_SurfaceSprite` | pura (riempie `tess`); le poche `qgl` sono il disegno dei fasci di debug | R1 (sopra i buffer, come i calcoli di `Decl`) |
| `tr_light.c` (395, 0) | `R_LightForPoint`, `R_SetupEntityLighting`, `R_TransformDlights`, `R_DlightBmodel` | pura | R0 ha i dati del light grid (`TBspLightGrid`); la funzione e' R1 |
| `tr_marks.c` (443, 0) | `RE_MarkFragments` (segni sulle pareti) | pura | non fatta (la risposta neutra del registratore resta: nessun frammento) |
| `tr_font.c` (542, 0) | `RE_RegisterFont`, `R_LoadScaledFont` | pura (legge il `.dat`) | il registratore risponde neutro; il formato dei `.dat` e' in `IdTech4\Gui` |
| `tr_sky.c` (845, 17) | `R_InitSkyTexCoords`, `RB_DrawSun`, `RB_StageIteratorSky`, `DrawSkyBox` | meta' pura (proiezione del cielo), meta' GL | R1 la parte pura |
| `tr_flares.c` (447, 11) | `RB_AddFlare`, `RB_RenderFlares` (con `glReadPixels` per la profondita') | mista | R2 |
| `tr_shadows.c` (341, 45) | ombre con lo stencil | stato GL | R2 |
| `tr_backend.c` (1143, 107), `tr_cmds.c` (447, 7) | coda dei comandi (`R_GetCommandBuffer`, `RE_BeginFrame`, `RB_ExecuteRenderCommands`), `GL_State`, `GL_Bind`, `RB_DrawSurfs`, `RB_SwapBuffers`, `RE_StretchPic`, `RE_SetColor` | stato GL e coda | la coda e' un'interfaccia da dare a R1; l'esecuzione e' R2 |
| `tr_init.c` (1217, 29) | `R_Init`, i cvar `r_*`, `R_InitFogTable`, `GfxInfo_f`, `R_Register` | misto (cvar puri, `glGetString`, `qglEnable`) | R1 (cvar) e R2 (contesto) |
| `qgl.h` (572) e `win32\win_qgl.c`, `win_glimp.c`, `win_gamma.c` | puntatori `qgl*`, finestra e pixel format di Windows | GL e piattaforma | `Framework\OpenGlBinding` (binding e **registratore** di chiamate), `Framework\GameHost` (finestra) |

Totale dei `qgl*` fuori da `tr_backend`, `tr_shade`, `tr_shadows`, `tr_init`: 86 chiamate in sette file; i file che non ne hanno nessuno (`tr_bsp`, `tr_model`, `tr_world`, `tr_light`, `tr_marks`, `tr_font`, `tr_curve`, `tr_scene`, `tr_mesh`, `tr_animation`, `tr_noise`, `tr_shade_calc`) sono la fase R0 e R1: **circa 10 500 righe su 23 893 (con `tr_shader.c`, che ne ha una sola) sono logica senza GL**, e la parte grossa e' gia' portata (shader, calcoli, BSP, curve, md3). Il resto e' la "lista di disegno" e lo stato GL.

## 2. Fasi proposte

- **R0 (questa ondata)**: tutto cio' che si puo' avere **senza una texture e senza una chiamata GL** e che serve a cgame e ui per vedere un renderer vero: immagini in RGBA, tabella degli shader con le immagini che nominano, modelli md3 con bounds e tag, mondo in liste di superfici con albero, visibilita', lightmap e light grid, l'adattatore `IQ3HostRenderer`. Libreria `IdTech4\Q3Render` (`DelphiDoom.Q3Render.*`).
- **R1 (con il registratore di chiamate `Framework\OpenGlBinding\Recorder`)**: la lista di disegno e i buffer: `tr_scene` (liste), `R_RenderView` fino a `R_SortDrawSurfs`, `R_MarkLeaves` e `R_RecursiveWorldNode`, `R_AddMD3Surfaces`, `tr_surface` (tassellazione in `tess`), `R_LightForPoint`, `ComputeColors/ComputeTexCoords` per ogni stage (gia' in `Decl`), il ciclo `RB_StageIteratorGeneric` che chiama `qgl*` **su un registratore**: criterio di parita' = la sequenza di chiamate GL del C (stesso metodo di `docs\PARITA_WAR.md` per SDL3 e di `Framework\OpenGlBinding\Recorder` per il renderer di Doom). `tr_marks` e `tr_font` si fanno qui o in R0b.
- **R2 (contesto vero)**: `R_CreateImage` e le texture, `GL_State`, il backend e la coda dei comandi, `tr_sky`, flare, ombre, finestra e swap (`Framework\GameHost`). Si prova con un contesto vero e le immagini guardate a occhio: non fa parte di nessuna ondata senza finestra.

Ordine di dipendenza: R0 -> R1 (il registratore verifica la sequenza di chiamate, nessuna finestra) -> R2 (finestra). R1 si puo' fare in piu' ondate: scena e liste, tassellazione, ciclo degli stage.

## 3. Cosa ha fatto R0 e dove sta

Vedi `IdTech4\Q3Render\README.md` e `IdTech4\Q3Render\CLAUDE.md` per la mappa C -> Delphi, i difetti conservati e le differenze volute, e `docs\QUAKE3_CENSIMENTO.md` par. 9 per i numeri sui `.qvm` di OpenArena.

- **Gia' portato prima, solo composto qui**: parser degli script (`ParseShader` e tutte le parole, `FinishShader`) in `IdTech4\Decl` con parita' sul C vero; `R_LoadSurfaces`, `R_LoadNodesAndLeafs`, `R_LoadVisibility`, `R_LoadLightGrid`, `R_LoadLightmaps` in `IdTech4\MapFile` con parita' sul C vero; il lettore md3 e `R_LerpTag` in `Framework\Models` con parita'. La richiesta originale di "riscrivere" questi tre pezzi e' stata sostituita dalla composizione: una copia sarebbe stata un doppione.
- **Portato qui**: `LoadTGA`, `LoadJPG`, `R_LoadImage`, `R_FindImageFile` senza GL; `R_FindShader`/`RE_RegisterShader` come tabella (immagini degli stage, shader difettosa se manca un'immagine, implicita da un'immagine); `RE_RegisterModel` con i LOD e le shader delle superfici, `R_ModelBounds` e `R_LerpTag` su un handle; `RE_LoadWorldMap` nell'ordine del C con le superfici per tipo; `R_PointInLeaf` e `R_inPVS`; l'adattatore.
- **Non portato in R0, con il motivo**: `LoadPCX32` e `LoadBMP` (nessun file di OpenArena li usa), PNG (OpenArena ne ha 7 in `pak0`; l'engine di OpenArena e' ioquake3, che li legge: non decodificati qui, contati), MD4, `R_LightForPoint` (R1), `RE_MarkFragments`, `RE_RegisterFont`, `R_CreateImage` e tutto cio' che e' stato GL.


## 4. Cosa ha fatto R1 (ondata 13, 2026-11-19, tag `ondata13-254-1`..`-4`): la lista di disegno e il backend sul registratore

Codice, mappa C -> Delphi e differenze in `IdTech4\Q3Render` (README, sezione "R1", e CLAUDE.md). Il piano del par. 2 e' stato seguito con questi scarti.

- **Fronte con parita' sul C vero**: `tr_scene.c`/`tr_main.c`/`tr_world.c` (scena, vista, frustum, proiezione, `R_MarkLeaves`, `R_RecursiveWorldNode`, culling delle superfici, `R_AddDrawSurf`, `qsortFast`, `R_SortDrawSurfs`). Il vero `tr_main.c` e `tr_world.c` si compilano con gcc (`Tools\Verifica\254\frontgen.c`, `build-front.sh`) e girano su `oa_dm1` per 6 viste: **zero differenze, bit per bit, a Win32 e a Win64** su frustum, proiezione, limiti del visibile e lista ordinata (600 drawSurf, 83 con i bit dei dlight). Le shader della prova sono finte (culling e posizione di sort fabbricati, molti pari merito: prova l'ordine di `qsortFast`); la tabella vera e' provata a parte.
- **Tabella delle shader**: `R_FindShader` con la chiave nome + indice di lightmap (le shader di sola immagine hanno gli stage di `LIGHTMAP_NONE`, `BY_VERTEX`, `2D`, `WHITEIMAGE` e della lightmap), il collasso del multitexture, `CreateInternalShaders`, `SortNewShader`. Test sul comportamento.
- **Backend senza oracolo**: `GL_State`, `GL_Bind`, `GL_Cull`, `GL_TexEnv`, `RB_BeginSurface`/`RB_EndSurface`, i tre iteratori di stage (generico, vertex lit, lightmapped multitexture), `DrawMultitextured`, `RB_SurfaceFace`/`RB_SurfaceTriangles`, `RB_StretchPic`, `RB_SetGL2D`, `RB_DrawSurfs`/`RB_RenderDrawSurfList`/`RB_BeginDrawingView` scrivono le chiamate GL come testo nel registratore. Il C disegna in un contesto vero: **non c'e' un oracolo**, il golden (`backend.golden.txt`) e' di regressione, Win32 = Win64.
- **Collegamento a `Q3Host`**: `TQ3HostRendererAdapter` costruisce anche la scena di cgame nel fronte (`AttachRenderer`, `CreateRenderingHostRenderer`); `BeginFrame`/`EndFrame` dell'adattatore sono il `SCR_UpdateScreen`. `IQ3HostRenderer` e il registratore di `Q3Host` non sono cambiati (`Tests.Q3Host` 210 su 210).
- **Misura**: il primo fotogramma di cgame di OpenArena su `oa_dm1` (stesso pilota della R0, uno snapshot finto) fa **1 scena e 57 drawSurf**, tutte facce del mondo, in 37 batch di backend e 53 `StretchPic`; `CG_INIT` non fa scene. La ui fa 3 scene in piu' (9 superfici md3 col mondo spento) e 897 `StretchPic`. Il mondo ha 0 patch: le griglie non sono state messe alla prova su una mappa.
- **Non fatto in R1** (e fatto in R1b, vedi sotto): viste in specchio e portale (contate), LOD e skin dei md3 (LOD: R1b), `R_SetupEntityLighting`, griglie delle patch (R1b), flare (R1b: non portati, dead code nel C), superfici di poligoni/sprite/raggi/md3 nel backend (R1b), cielo (`tr_sky.c`, R1b), passo dei dlight (R1b), passo della nebbia (R1b), ombre, `R_LightForPoint`, `RE_MarkFragments`, `RE_RegisterFont`.

## 4b. Cosa ha fatto R1b (ondata 14, 2026-11-19, tag `ondata14-254r-1`..`-7`): le superfici, il cielo e i passi sul registratore

Codice, mappa C -> Delphi, differenze volute e difetti conservati in `IdTech4\Q3Render\README.md` (sezione "R1b"). Il metodo e' quello della R1 portato piu' avanti: **il C vero si compila e gira** (`Tools\Verifica\254\surfgen.c`, `build-surf.sh`: `tr_surface.c`, `tr_curve.c`, `tr_shade_calc.c`, `tr_noise.c` come sono, e inclusi `tr_bsp.c`, `tr_sky.c`, `tr_shade.c` per le loro funzioni `static`), il resto del renderer sono stub che stampano.

| Punto | Esito |
|---|---|
| (1) griglie delle patch | `RB_SurfaceGrid` con `LodErrorForVolume` e le passate multiple di `tess`: **parita'** sul C vero con patch sintetiche (3x3 .. 65x65, cvar e orientamenti diversi) e sulle **42 patch di `oa_ctf2`** (le griglie dopo `R_StitchAllPatches` e `R_FixSharedVertexLodError` del C vero), a Win32 e a Win64. `R_SubdividePatchToGrid` non e' stata riportata: e' in `Framework\MathCore` (#117). `oa_dm1` ha 0 patch: la misura sul primo fotogramma non cambia |
| (2) poligoni, sprite, raggi | `RB_SurfacePolychain`, `RB_SurfaceSprite`, `RB_SurfaceBeam` (vertici), `RB_SurfaceRailCore`, `RB_SurfaceRailRings`, `RB_SurfaceLightningBolt`, `RB_SurfaceAxis`: **parita'** sul C vero (l'asse del modello nullo: test sul comportamento) |
| (3) cielo | `R_InitSkyTexCoords`, `RB_ClipSkyPolygons`, `DrawSkyBox`, `R_BuildCloudData`, `RB_StageIteratorSky`, `RB_DrawSun`: **parita'** sul C vero (impronte delle tabelle, facce, strisce, nuvole, sole); il sole nel C non e' mai chiamato (`#if 0`) |
| (4) flare | **non portati**: nel C con i default non disegnano nulla (`r_flares` 0, `RB_AddDlightFlares` commentata, `RB_SurfaceFlare` vuota); la lettura del depth buffer non serve a nulla. Le superfici flare del mondo restano contate |
| (5) dlight e nebbia | `ProjectDlightTexture` e `RB_FogPass` come draw (texture, stato, indici, array): **parita'** sul C vero di `tr_shade.c`; il collegamento (le nebbie del mondo `R_LoadFogs`, le maschere per superficie, `R_TransformDlights`) e' provato dal golden del backend e da test, senza oracolo |
| (6) md3 | `RB_SurfaceMesh` e `LerpMeshVertexes`: **parita'** sul C vero (frame, frame vecchio, `backlerp`, normali con la tabella dei seni); il LOD (`R_ComputeLOD`, `ProjectRadius`, i livelli di `RE_RegisterModel`, il livello nel cull e nei fog): test sul comportamento, **senza oracolo** |

Misure: primo fotogramma di cgame su `oa_dm1` invariato (57 drawSurf, 37 batch); la ui disegna ora 9 superfici md3 (erano contate); i 6 fotogrammi del golden del backend, con le luci delle viste, fanno 18 draw dei dlight e 6 della nebbia. `Tests.Q3Render` **79** (72 + 7), Win32 e Win64; `Tests.Q3Host` 210/210 a Win32.

### Cosa resta per R2 (aggiornato)

1. Contesto WGL vero e un `IQ3GlSink` su `dglOpenGL` (come in R1).
2. Texture (`R_CreateImage`, mipmap, gamma, `glTexImage2D`); oggi i numeri sono i primi `glBindTexture` e le texture del renderer (`*dlight`, `*fog`, `$whiteimage`, le lightmap) sono nomi.
3. **Ancora senza chiamata GL**: ombre con lo stencil (`tr_shadows.c`), viste in specchio e portale, `RB_Hyperspace`, `RB_ShowImages`, video map, skin dei md3, `R_SetupEntityLighting` (il colore delle entita' e' quello di `shaderRGBA`), `R_LightForPoint`, `RE_MarkFragments`, `RE_RegisterFont`.
4. Finestra, input, suono, menu: il composition root `Quake3` (fase 7 di `docs\QUAKE3_CENSIMENTO.md`).
5. Una prova a occhio (non si fa senza finestra).

### Cosa mancava per R2 alla fine della R1 (superato dal punto 4b: vedi "Cosa resta per R2 (aggiornato)")

1. **Contesto WGL vero** (`Framework\GameHost` ha la finestra GDI e OpenGL dei giochi di Doom): `IQ3GlSink` e' il punto in cui il backend chiama GL; un sink su `dglOpenGL` al posto del registratore e' la parte piccola.
2. **Texture**: `R_CreateImage` (mipmap con `r_picmip`, gamma, `glTexImage2D`), la lightmap come texture, `$whiteimage` e le immagini interne; i numeri di texture del backend oggi sono finti (primo bind).
3. **Il resto del backend**: griglie delle patch (`RB_SurfaceGrid`, LOD), cielo, flare, ombre, dlight e nebbia, superfici di entita' e md3 (`tr_surface.c`, `tr_mesh.c`, `tr_light.c`), specchi e portali.
4. **Finestra, input, suono, menu**: il composition root `Quake3` (fase 7 di `docs\QUAKE3_CENSIMENTO.md`) che chiama `BeginFrame`/`EndFrame` dell'adattatore dal `SCR_UpdateScreen`, la tastiera e il mouse di `Framework\Input`, il mixer di `Framework\Audio` (suono di Quake III gia' portato), il menu (`ui`) e i video RoQ (`Framework\Cinematic`).
5. Una prova a occhio, che non si fa senza finestra: nessuna ondata senza finestra la copre.
