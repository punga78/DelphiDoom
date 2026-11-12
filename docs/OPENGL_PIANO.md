# Piano: far sparire `OPENGL\` (issue da aprire, dopo la #172/#173)

Analisi in sola lettura sul sorgente di `master` (de35da0c, 2026-11-09). Conteggi fatti con `wc`, `grep`, `awk` sulla cartella `OPENGL\` (non nelle copie sotto `.claude\worktrees` ne in `Reference\`). Dove un numero e una stima lo dico. Nessun file di codice e stato toccato, nessuna build, nessun gioco avviato.

Letti prima: `CLAUDE.md` e, nei `CLAUDE.md` di libreria, le sezioni `Libs\GlMath`, `Libs\Models`, `Libs\Renderer`, `Libs\Texture`, `Libs\DynLights`, `Libs\Renderer\README.md`, `Libs\Models\README.md`, `Libs\GlMath\README.md`, `docs\FACCIATE.md`, `docs\PENDING_ISSUES.md`, `docs\SCRIPTHOST_PIANO.md` (modello di questo piano) e la storia dei commit `8cbf7812` + `96c83939` (come e stata spostata `SCRIPT\`).

---

## 1. Che cosa c'e oggi

`OPENGL\` ha **27 file `.pas`, 37.822 righe**, nessun altro tipo di file. Sono compilati solo dai quattro `GL*32.dpr` (`Doom\GLDoom32.dpr`, `Heretic\GLHeretic32.dpr`, `Hexen\GLHexen32.dpr`, `Strife\GLStrife32.dpr`: 27 righe `in '..\OPENGL\...'` ciascuno, 108 in tutto). I quattro `.dproj` nominano `OPENGL` **solo nel define** (`<DCC_Define>OPENGL;DOOM;...`), **non** nei percorsi di ricerca: le unit entrano con `in '...'` nel `.dpr`. I progetti software (`Doom32.dpr`...) hanno solo `{$IFDEF OPENGL} {$Error ...}`. Nessun progetto di test, `build.bat`, `.ps1` o `.groupproj` cita `OPENGL\` (solo un commento in `Tests\Source\DelphiDoom.Tests.Scanner.GameDefines.pas` e tre README di `Tests\Data`).

Le 20.332 righe di `dglOpenGL.pas` sono il binding di terzi (DGL, MPL 1.1, "OpenGL 4.1 headertranslation"): le restanti **17.490 righe** sono codice del motore.

**API usata: OpenGL 1.x a funzione fissa, modo immediato.** Nessuno shader, nessun VBO: `glBegin/glEnd` 46 coppie, `glVertex3f` 123, `glTexCoord2f` 137, `glMatrixMode` 57, `glNewList/glCallList` 10/7 (display list per modelli e voxel), `glVertexPointer`/`glDrawArrays` 2/1 (solo i flat, `gl_render.pas:4037, 5561, 5736`). Estensioni: multitexture ARB (`glActiveTextureARB` 27 usi, per le lightmap), `GL_EXT_paletted_texture`/`shared_texture_palette` (`glColorTableEXT`), anisotropia, `GL_COMBINE_ARB`; GLU: `gluBuild*` (7), `gluPerspective`, `gluTesselator`. `gl_shaders.pas` non esiste piu (tolta come codice morto; resta solo nelle copie di `Reference\`). In tutto **94 simboli `gl*/glu*/wgl*` e 135 costanti `GL_*` distinti** sono usati da `OPENGL\` (1.217 occorrenze di chiamate): contro i circa 460 sottoprogrammi di `dglOpenGL.pas`.

Il contesto: `gl_main.pas` crea finestra, `PIXELFORMATDESCRIPTOR` (depth 16, stencil 16), `wglCreateContext`, `wglMakeCurrent`; `InitOpenGL` + `ReadExtensions` + `ReadImplementationProperties` (`gl_main.pas:1009, 1159-1160`). `I_ReadScreen32` e `glReadPixels` (`gl_main.pas:1294`): **lo schermo GL si puo leggere** (lo usa gia `TEngineScreenshotService`).

---

## 2. Inventario unit per unit

Colonne: righe (`wc -l`); `gl*` = occorrenze di chiamate `gl/glu/wgl` (`grep -o`); routine = `procedure/function` nel file; `{$IF}` = direttive di compilazione; pub = routine dichiarate in `interface`. "Globali" = letture/scritture di globali di altre unit contate dallo script di `Libs\Renderer\README.md` (582 nomi; ordini di grandezza). "Caldo" = per fotogramma, per muro, per flat o per sprite (da lettura del codice, non da un profiler).

| Unit | Righe | `gl*` | Rout. | `{$IF}` | pub | Ruolo | Globali (letti/scritti) | Percorso | Dove va |
|---|---:|---:|---:|---:|---:|---|---|---|---|
| `dglOpenGL` | 20.332 | - | 462 | molti | - | binding di terzi | - | - | `Libs\OpenGl\Binding` (sezione 3) |
| `gl_render` | 5.790 | 604 | 116 | 67 | 20 | tutto il disegno della scena | 61 / 22 (`frontsector`, `backsector`, `curline`, `linedef`, `viewx/y/z`, `players`, `sectors`, `sides`...) | misto (sotto) | `GlLevel` (geometria a freddo), `GlScene` (liste e disegno) |
| `gl_tex` | 1.990 | 137 | 57 | 2 | 25 | texture GL: costruzione, registrazione, legame, precache | 20 / 4 (`textures`, `flats`, `lumpinfo` via `w_wad`) | `Bind*`: per muro/flat/sprite; il resto a freddo | `GlTexture` |
| `gl_voxels` | 1.477 | 35 | 38 | 0 | 2 | mesh dei voxel (`TVoxelMeshOptimizer`, gia classe, righe 57-810), liste GL, `TVoxelModel` | pochi (usa `Libs\Voxel`) | ottimizzazione a freddo; disegno per voxel | ottimizzatore in `Libs\Voxel`; liste GL in `GlModels` |
| `gl_main` | 1.336 | 151 | 46 | 20 | 16 | finestra, contesto, modo video, `I_FinishUpdate*` (wipe, ENDOOM, overlay), alt-tab, `DoomMain` | 11 / 1 (`screens`, `SCREENWIDTH`...) | per fotogramma (`I_FinishUpdate`), il resto a freddo | `GlContext` |
| `gl_lightmaps` | 872 | 47 | 25 | 0 | 6 | lightmap dei voxel: calcolo per voxel (`gld_CalculateLightmapSTD` ~315 righe) e attivazione | pochi (settori, `vx_*`) | calcolo a freddo; attiva/disattiva per sprite | `GlEffects` |
| `gl_models` | 752 | 2 | 19 | 0 | 4 | registro modelli, `TModel.Draw`, parser MODELDEF (`SC_DoParseModelDefinition` righe 136-380) | `states[]`, `mobjinfo[]` | parser a freddo; `Draw` per oggetto | `GlModels` + `Libs\Models` (parser) |
| `gl_setup` | 452 | 0 | 12 | 0 | 5 | lettura nodi GL V3..V5 dalla cache (`P_LoadGLSegs`, `P_LoadSubsectorsV3V5`, `P_LoadNodesV4V5`) | 0 / 4 (`segs`, `subsectors`, `nodes`) | a freddo | `GlLevel`, sopra `Libs\Nodes` |
| `gl_automap` | 441 | 42 | 19 | 10 | 7 | disegno dell'automap GL (buffer di linee, patch, triangoli) | 2 / 13 | per fotogramma | strategia dell'automap (`Libs\Automap`) |
| `gl_sky` | 376 | 120 | 6 | 1 | 3 | `gld_CalculateSky`, `gld_DrawSky` | 1 / 0 | per fotogramma | `GlScene` |
| `mdl_script_proclist`, `mdl_script_functions`, `mdl_script`, `mdl_script_model` | 375, 1.020, 187, 394 | 14, 0, 0, 0 | 94, 102, 5, 36 | 0 | - | colla PascalScript dei modelli procedurali (~60 funzioni `register`) | 0 | a freddo (compilazione) + per fotogramma (esecuzione) | `Libs\Models\Script` (poi insieme a `Libs\ScriptHost`) |
| `mdl_md2`, `mdl_ddmodel`, `mdl_dllmodel`, `mdl_base` | 368, 278, 205, 78 | 13, 10, 5, 0 | 18, 8, 7, 2 | 1 | - | disegno dei modelli sopra `Libs\Models` (lettura gia portata, #134) | 0 | per oggetto | `GlModels` |
| `DelphiDoom.Engine.Models.Renderer` | 117 | 14 | 28 | 0 | - | `IModelRenderer` sulle chiamate GL (gia classe) | 0 | per comando di modello | `GlModels` (nome a punti gia giusto) |
| `gl_lights`, `gl_ambient`, `gl_shadows` | 147, 97, 132 | 20, 1, 0 | 3, 4, 6 | 0 | 1, 2, 3 | texture della luce, texture ambientale, tabella di 16 `GLDRenderLight` | 0 | per fotogramma (legame) | `GlEffects` |
| `gl_clipper` | 147 | 0 | 10 | 0 | 5 | facciata di `Libs\GlMath` (gia fatta) | 0 | per muro | resta facciata finche `GlScene` non riceve `IGlAngleClipper` |
| `gl_slopes` | 105 | 0 | 6 | 0 | 2 | altezza del piano inclinato in un punto (due formule su `Psector_t`) | `sectors` | caldo (per vertice) | `GlLevel` (funzioni statiche, nessuna interfaccia) |
| `gl_defs` | 192 | 2 | 1 | 1 | - | costanti e flag (`MAP_COEFF`, `GLDWF_*`) e tipi dei muri/flat | `doomdef`, `r_draw` | - | `GlScene` (tipi) / `GlContext` (opzioni) |
| `gl_types`, `gl_misc` | 80, 82 | 0 | 0, 4 | 0 | - | tipi dei vertici, `min/max` | - | - | `GlScene` |

### 2.1 `gl_render.pas` per blocco (le 5.790 righe)

I blocchi sono cosi netti che il file si spezza senza cambiare logica. Chiamate `gl*` per blocco (contate sul testo):

| Righe | Blocco | Righe | `gl*` | Fase |
|---|---|---:|---:|---|
| 53-470 | `gld_ConfigureDynamicLights`, tipi, variabili (254 righe `var` di implementazione) | 418 | - | stato |
| 472-636 | luce statica, `gld_InitExtensions`, `gld_VSync`, tabella di luce | 165 | - | a freddo |
| 637-776 | `gld_Init` | 140 | 35 | a freddo (contesto) |
| 777-1211 | `DrawNumPatch`, sfondo, arma, `SetPalette`, 2D | 435 | - | per fotogramma (HUD) |
| **1212-1978** | **geometria del livello a freddo**: `gld_AddGlobalVertexes`, `FlatEdgeClipper`, `FlatConvexCarver`, `CarveFlats`, `GetSubSectorVertices`, `PrepareSectorSpecialEffects`, `PreprocessSectors` (in `Double`, `Z_Realloc`) | 767 | **1** | a freddo |
| 1979-2253 | `infinitePerspective`, `gld_StartDrawScene`, `gld_EndDrawScene` | 275 | 65 | per fotogramma |
| 2254-2770 | `gld_AddDrawItem`, `CALC_*`, flood stencil, helper dei muri | 517 | - | per muro |
| 2771-3137 | `gld_DrawWall` | 367 | **93** | per muro (disegno) |
| 3138-3815 | `gld_AddFlat_Extra`, `_3dFloor`, `gld_AddMidWall`, `gld_AddWall` | 678 | **0** | per muro (raccolta) |
| 3816-3846 | `gld_PreprocessSegs` | 31 | 0 | a freddo |
| 3847-4099 | ripple, `gld_DrawFlat` | 253 | 57 | per flat |
| 4100-4319 | `gld_AddFlat`, `gld_AddPlane` | 220 | 0 | per flat (raccolta) |
| 4320-4852 | ombre/luci per sprite, modelli, voxel | 533 | 93 | per sprite |
| 4853-5056 | `gld_DrawSprite` | 204 | 58 | per sprite |
| 5057-5175 | luci dinamiche (`gld_DrawDLights`) | 119 | 19 | per fotogramma |
| 5176-5344 | `gld_AddSprite` | 169 | 0 | per sprite (raccolta) |
| 5345-5460 | nebbia | 116 | 13 | per fotogramma |
| 5461-5692 | `gld_DrawWalls`, `gld_DrawScene` | 232 | 28 | per fotogramma |
| 5693-5790 | cielo, `gld_PreprocessLevel`, liste, `R_ShutDownOpenGL` | 98 | - | a freddo |

Conclusione: **le fasi di raccolta (`gld_Add*`, 1.098 righe) non hanno nessuna chiamata GL** e leggono i globali del BSP (`frontsector`, `backsector`, `curline`...); **le fasi di disegno (`gld_Draw*`, circa 1.700 righe) sono quasi solo chiamate GL**; **la geometria a freddo (767 + 31 righe) e pura** (un solo `gl*`, il tesselatore). Questo decide l'ordine delle fette.

---

## 3. `dglOpenGL.pas`: dove va e alternative

**Proposta: `Libs\OpenGl\Binding\dglOpenGL.pas` tenuto com'e**, con un `README.md` accanto che dice: file di terzi (DGL, MPL 1.1; il resto del repository e GPL v2 o successiva: file separato e intatto), non si formatta, non si conta nelle righe del motore, non si copre con i test (come `r_clipper`, `DirectX.pas`, `PascalScript`: gia detto in `PENDING_ISSUES.md`). Lo spostamento e meccanico (nome dell'unit invariato: `uses dglOpenGL` non cambia in nessun file).

Alternative valutate:

| Alternativa | Pro | Contro | Giudizio |
|---|---|---|---|
| `Winapi.OpenGL` (RTL) | nessun file di terzi | espone OpenGL 1.1, GLU e WGL: mancano `glActiveTextureARB` (27 usi), `glColorTableEXT`, `GL_TEXTURE_MAX_ANISOTROPY_EXT`, `GL_COMBINE_ARB`, `GL_RGB_SCALE_ARB` e il caricamento di `ReadExtensions`; andrebbero scritti a mano con `wglGetProcAddress`; cambiano i nomi (`glBegin` e un'`external` e non una variabile: **si perde il punto di aggancio del registratore di chiamate della sezione 5**) | no |
| Binding ridotto scritto a mano (94 funzioni + 135 costanti, circa 600 righe) | file piccolo, nostro, testabile; Win64 chiaro | non aggiunge alcuna funzione; lavoro e rischio senza beneficio per l'utente; perde `ReadImplementationProperties`, usato da `gld_InitExtensions` | **dopo**, solo se serve (S-M) |
| Tenerlo com'e | zero rischio, zero lavoro | 20.332 righe di terzi in un albero che si vuole "classi" | **si** |

Rischio da annotare (non verificato): DGL 4.1a su Win64. Le dichiarazioni sono puntatori a procedura `stdcall` (`DGL_WIN`) e il file ha un ramo `{$IFDEF CPU64}` (riga 456); va compilato con `dcc64` quando si fa la #41-#44 (non oggi).

---

## 4. Che cosa e gia stato portato e che cosa resta procedurale

**Gia a classi (e collegato):**

| Pezzo | Dove | Nota |
|---|---|---|
| Intervalli di angoli nascosti dai muri (`gld_clipper_*`) | `Libs\GlMath` (`TGlAngleClipper`, `TGlViewAngle`), `gl_clipper.pas` e facciata di 147 righe | una chiamata a interfaccia in piu per muro: 110-130 ns contro 80-100, meno di 0,1 ms/fotogramma |
| `gl_frustum` | cancellata (#134) | piani che nessuno leggeva |
| Luci dinamiche (GLDEFS) | `Libs\DynLights` (`IDynLightRenderCache`); `gl_render` riceve `gld_ConfigureDynamicLights` e disegna da `GLDRenderLight`/`TDynLightRender` | resta il disegno (`gld_DrawDLights`, 119 righe) |
| Lettura MD2, lista di comandi dei modelli procedurali, DMX | `Libs\Models` (`TMd2Parser`, `TModelCommandStream`), `mdl_md2`/`mdl_ddmodel` li chiedono a `TModelsFactory` | resta il disegno dal puntatore ai vertici |
| Chiamate GL di un modello procedurale | `DelphiDoom.Engine.Models.Renderer` (`TEngineModelRenderer`, `IModelRenderer`, 117 righe) | gia una classe nel posto sbagliato (sta in `OPENGL\`) |
| Decoder delle texture esterne e `TTexture` | `Libs\Texture` (`IEngineTextureFiles`, `TEngineTextureFiles`); `gl_tex` riceve `gld_ConfigureTextureFiles` | resta la costruzione del buffer GL |
| Ottimizzatore di mesh dei voxel | `TVoxelMeshOptimizer` e due sottoclassi, in `gl_voxels.pas` (righe 57-810): **e gia una classe**, ma ha `RenderVertexGL`/`RenderGL` dentro | manca solo la separazione del disegno |
| Catalogo dei modi video, input, ENDOOM, console | `IDisplayModeCatalog`, `IInputPoller`, `IEngineEndoomScreen`, `IEngineConsole` dati a `gl_main` con `GL_Configure*` (#137, #145) | |
| Lettura dei nodi GL, GWA, glBSP | `Libs\Nodes` (`TNodesGlParser`, `TNodesGwaReader`), `TEngineGlbspRunner` (#158) | `gl_setup` ha ancora i puntatori nella cache |
| Voxel: formati e liste | `Libs\Voxel` (#78) | |

**Procedurale (e perche):** `gl_render` (5.790), `gl_main` (1.336), `gl_tex` (1.990), `gl_sky`, `gl_lightmaps`, `gl_automap`, `gl_ambient`, `gl_lights`, `gl_shadows`, `gl_slopes`, `gl_setup`, la parte di disegno di `gl_models`/`gl_voxels`/`mdl_*`, `mdl_dllmodel` (carica una DLL che disegna), `mdl_script*` (colla PascalScript). Il perche scritto in `PENDING_ISSUES.md` e `Libs\Renderer\README.md`: chiamate per fotogramma/muro/sprite, stato condiviso con il BSP (`frontsector`...), zone memory, contesto GL come stato globale del thread.

Dipendenze dall'esterno (chi usa `OPENGL\`): `gl_main` e usata da circa 30 unit (`i_system`, `d_main` x4, `m_menu` x4, `f_wipe`, `f_finale`, `in_stuff`, `sb_bar`, `st_stuff`, `p_pspr`, `p_user`...), `gl_defs` da circa 20, `gl_tex` da `r_main`, `r_hires`, `m_menu` x4; `gl_render` da `r_bsp`, `r_draw`, `r_main`, `r_things`, `st_stuff`, `sb_bar`, `DelphiDoom.Engine.Level.Loader`; `gl_setup` solo da `Level.Loader` e `Level.MapReader`; `gl_voxels`, `gl_models`, `gl_lightmaps`, `gl_shadows` da `m_defs` e `m_menu` (le opzioni del menu e del `.ini` sono variabili di queste unit: **`m_defs` ne indirizza una cinquantina**).

---

## 5. Parita e verifica: che cosa e fattibile

Fatti verificati leggendo il codice:

- `dglOpenGL` dichiara ogni funzione come **variabile di tipo procedura** (`glVertex3f: TglVertex3f;`, `dglOpenGL.pas:10185`, assegnata da `dglGetProcAddress`). Dopo `ReadExtensions` si puo sostituire ogni puntatore con un **registratore** che scrive `nome(argomenti)` e, se serve, chiama l'originale.
- `I_ReadScreen32` usa `glReadPixels` (`gl_main.pas:1294`): si puo leggere lo schermo vero.
- `-timedemo` e `-warp` funzionano anche nelle build GL; `Tools\Esegui-gioco.ps1` le avvia con il lock globale.

Cosa **non** e fattibile: confrontare pixel di driver diversi (non e deterministico tra schede; in VM peggio). Un confronto di pixel ha senso solo **tra due eseguibili sulla stessa macchina, con lo stesso driver**, e va prima provato vecchio contro vecchio (come per i salvataggi: se due esecuzioni dello stesso eseguibile non danno lo stesso, la tolleranza e un'altra).

Criteri, in ordine di forza:

1. **Flusso di chiamate GL registrato (golden testuale).** Un gancio temporaneo (`Tools\Verifica\OpenGl`, non committato nei sorgenti del motore; i risultati si, come `Tests\Data\...\*.golden.txt`) installa registratori dopo `ReadExtensions`; a ogni `gld_EndDrawScene` scrive in un file la sequenza delle chiamate del fotogramma (funzione, argomenti `Single`/`Integer` con i bit, nomi delle costanti per le `GLenum`) e ne fa l'impronta FNV-1a. Vale per ogni fetta che sposta codice di disegno: **la sequenza deve essere identica byte per byte**, perche il motore calcola in `Single`/`Double` con le stesse istruzioni. E indipendente dal driver (si puo far girare anche senza finestra visibile). E lo strumento principale del piano (fette 6-10). Costo: M, una tantum, fatto prima di qualunque conversione (come la fetta 2a-0 di ScriptHost).
2. **Liste di disegno e geometria prima di `gld_DrawScene`** (per le fasi di raccolta e di geometria): dump di `gld_drawinfo` (tipo, indice, vertici) e di `gld_vertexes`/`gld_texcoords`/loop dei flat, per ogni mappa dei WAD di `bin\` (Doom shareware 9, Freedoom 2 32, Heretic 9, Hexen 4, Strife 3) con impronta FNV-1a: lo stesso metodo di `Libs\Level` (`TLevelLoader`: impronta dei byte dopo ogni mappa, arena che riparte allo stesso indirizzo).
3. **Impronta dello schermo** (`I_ReadScreen32` ogni N tic di `-timedemo demo1/2/3`) con driver di Windows "GDI Generic" (o il driver della macchina), vecchio contro nuovo sulla stessa macchina: tolleranza zero se vecchio-vecchio e identico, altrimenti errore medio per canale <= 1/255 e nessun pixel oltre 8. Serve a vedere cio che il registratore non vede (stato GL non registrato, texture caricate male).
4. **Screenshot a posizioni fisse**: `-warp` + `-devparm` + una demo con `-timedemo`, uno screenshot ogni 35 tic per mappa, su 3 mappe per gioco (4 giochi), PNG confrontati con una tolleranza (media per canale) e, per i casi con differenze, con la mappa delle differenze. Si fa a mano o con un gancio in `G_Ticker` (come gli harness delle fette precedenti): utile per le fette di texture e contesto, dove il registratore non basta.
5. **`-timedemo` dei giochi GL**: `realtics` del nuovo non oltre +5% del vecchio, 4 prove a coppie, macchina scarica (come `CLAUDE.md`). Per le fette che non toccano il percorso caldo non serve.
6. **Prova a runtime** (`Tools\Esegui-gioco.ps1`, 25 secondi, niente `crash.txt` ne `I_Error`): GLDoom32, GLHeretic32, GLHexen32, GLStrife32, con `-warp` e con un PK3 di prova (modelli MD2, voxel, GLDEFS, texture esterne).

Test DUnitX: solo per le classi che non chiamano GL (geometria a freddo, lightmap, parser MODELDEF, ottimizzatore di mesh, costruzione dei buffer delle texture) con golden del vecchio codice copiato nello stesso eseguibile. Il codice che chiama `gl*` **non** si prova con DUnitX (non c'e contesto): la sua verifica e il registratore e le prove a runtime.

---

## 6. Divisione proposta in librerie

Nomi nello schema di `Libs\` (una classe per unit, `DelphiDoom.<Area>.<Classe>`, `Intf`/`Types`/`Factory`). Righe di oggi che ci finiscono dentro (somma = 37.822):

| Libreria | Contenuto | Righe oggi | Stato |
|---|---|---:|---|
| `Libs\OpenGl\Binding` | `dglOpenGL.pas` (terzi) | 20.332 | tenuto com'e |
| `Libs\GlContext` | finestra, formato dei pixel, contesto WGL, swap, vsync (`gld_VSync`), estensioni (`gld_InitExtensions`), modo video, alt-tab, `I_FinishUpdate*` (wipe/ENDOOM/overlay) | 1.336 + 192 + 80 + 82 | `IGlContext`, `IGlWindow`, `IGlFrameEnder` (strategia: wipe, ENDOOM, overlay, Strife `fade`) |
| `Libs\GlTexture` | costruzione dei buffer (`gld_AddPatchToTexture*`, `gld_AddFlatToTexture`, trasparenza, ripple), registrazione, legame, precache | 1.990 | a freddo: classi; `Bind*`: procedure a puntatore (per muro) |
| `Libs\GlLevel` | geometria del livello a freddo (flat: taglio dei bordi, carving convesso, vertici dei sottosettori), `gld_PreprocessSegs`, `gl_setup` (nodi GL), `gl_slopes` | 767 + 31 + 452 + 105 = 1.355 | classi pure con record neutri, test di parita |
| `Libs\GlScene` | raccolta (`gld_AddWall/Flat/Sprite`), disegno (`gld_DrawWall/Flat/Sprite/Walls/Scene`), cielo, nebbia, luci dinamiche, arma e HUD in 2D, automap | 4.992 + 376 + 147 + 441 = 5.956 | ultima (sezione 7, fette 9-10) |
| `Libs\GlEffects` | texture di luce/ambiente, ombre dinamiche, lightmap dei voxel | 147 + 97 + 132 + 872 = 1.248 | `gld_CalculateLightmapSTD` a classe; il resto resta GL |
| `Libs\GlModels` | `TModel.Draw`, `mdl_md2`, `mdl_ddmodel`, `mdl_dllmodel`, `mdl_base`, `TEngineModelRenderer`, liste GL dei voxel e `TVoxelModel` | 752 + 368 + 278 + 205 + 78 + 117 + 1.477 = 3.275 | parser MODELDEF in `Libs\Models`, ottimizzatore in `Libs\Voxel` (sotto) |
| `Libs\Models\Script` | `mdl_script*` | 1.976 | colla PascalScript: segue `Libs\ScriptHost` |
| `Libs\GlMath`, `Libs\Models`, `Libs\Voxel`, `Libs\Automap`, `Libs\Texture`, `Libs\DynLights` | esistenti | - | si estendono |

Non propongo `GlLights` separata: `gl_lights`, `gl_ambient`, `gl_shadows` sono 376 righe di creazione di texture e una tabella, e le luci dinamiche hanno gia `Libs\DynLights`. Non propongo `Libs\GlRender`: il nome si confonderebbe con `Libs\Renderer` (il renderer comune); `GlScene` dice cosa contiene.

Regola di costo (dalla #156): **interfacce a granularita di livello, di vista o di fotogramma; mai per vertice, colonna o pixel**. Il disegno di un muro (`gld_DrawWall`, 93 chiamate GL) puo stare in un metodo di una classe con stato nei campi, chiamata direttamente (non per interfaccia): il costo e una chiamata, 1-2 ns; la `gld_DrawScene` per fotogramma fa qualche migliaio di queste.

---

## 7. Fette, in ordine di rischio

Stime con la scala dei commit (XS 25 min, S 1h30, M 3 h, L 1 giorno, XL 2+ giorni), compilatore e prove a runtime incluse. Ogni fetta: modifica + verifica come indicato + documentazione (`CLAUDE.md`, `FACCIATE.md`, `PENDING_ISSUES.md`, `Libs\*\README.md`).

| # | Fetta | Stima | Rischio | Dipende da | Verifica |
|---:|---|---|---|---|---|
| **0** | **Spostamento meccanico** `OPENGL\` -> `Libs\OpenGl\` (sotto), poi riparazione dei percorsi nei 4 `GL*32.dpr` | **S** | **B** | - | build di tutti i progetti; i 4 GL partono 25 s senza `crash.txt`; `git diff -M` mostra 27 rinomini al 100% |
| 1 (**fatta il 2026-11-09: scritta e compilata, non ancora eseguita; vedi `Libs\OpenGl\README.md`, sezione Recorder**) | Registratore di chiamate GL e dump delle liste (`Tools\Verifica\OpenGl`), con i golden del codice **non ancora toccato** per 3 mappe x 4 giochi (flusso GL a 3 punti per mappa, liste, impronta dello schermo) e prova vecchio-vecchio | M | B (non tocca il motore) | 0 | due esecuzioni dello stesso eseguibile danno lo stesso flusso e le stesse impronte |
| 2 (**fatta il 2026-11-09, vedi Libs\OpenGl\CLAUDE.md**) | Ottimizzatore di mesh dei voxel (`TVoxelMeshOptimizer` e le due sottoclassi, `gl_voxels.pas:57-810`) in `Libs\Voxel`, il disegno dietro un `IVoxelMeshRenderer` (strategia come `IModelRenderer`) | M | B | 1 | golden dei quad dopo `Optimize`/`FastOptimize` su DDVOX, KVX e VOX di prova (vecchio copiato nel test) + flusso GL di un voxel identico |
| 3 (**fatta il 2026-11-09, vedi Libs\OpenGl\CLAUDE.md**) | Parser MODELDEF (`gl_models.pas:136-410`, ~270 righe) in `Libs\Models` su `Libs\Scanner`, i risultati dati a un sink (come `TActorDefParser`); il registro dei modelli resta | M-L | B/M | 0 | un MODELDEF di prova con ogni parola chiave, avvisi inclusi: stesso `models[]`; `gld_AddModelState` chiamato con gli stessi valori |
| 4 (**quasi fatta il 2026-11-09: carving dei flat e controlli sui settori (`TGlSectorPreprocessor`) in `Libs\GlLevel`, impronte di 57 mappe vecchio/nuovo UGUALI (`Impronte.ps1`); restano `gl_setup` (nodi GL V3..V5 non esercitati dall'harness) e `gl_slopes` (percorso caldo, non si migra), vedi Libs\OpenGl\CLAUDE.md**) | **Geometria del livello a freddo**: `gl_render.pas:1212-1978` e `3816-3846` in `Libs\GlLevel` (`IGlFlatCarver`, `IGlSectorPreprocessor`); `gl_setup` sopra `Libs\Nodes`; `gl_slopes` come funzioni statiche | **L-XL** | M (aritmetica `Double`, `Z_Realloc`, tesselatore GLU) | 1 | per ogni mappa di 5 WAD: impronta FNV-1a di `gld_vertexes`, `gld_texcoords`, loop dei flat e `sectorloops`, vecchio contro nuovo nello stesso eseguibile; zero differenze (e la fetta 7 della #156) |
| 5 (**fatta il 2026-11-09, vedi Libs\OpenGl\CLAUDE.md**) | **Costruzione dei buffer delle texture** (`gl_tex.pas:175-653`: patch, flat, trasparenza, ripple) in `Libs\GlTexture` sopra `Libs\Texture` e `Libs\Imaging`; registrazione e `Bind*` restano procedure | M-L | M | 1 | buffer RGBA prodotti per tutte le texture, flat e sprite di 5 WAD (impronta) identici; le chiamate `glTexImage2D`/`gluBuild*` nel flusso registrato identiche |
| 6 | **Lightmap dei voxel**: `gld_CalculateLightmapSTD` e le conversioni di coordinate in `Libs\GlEffects` (calcolo puro su settori e voxel); texture e attivazione restano | M | M | 1, 2 | lightmap (impronta byte) per voxel di prova e livelli identica; flusso GL di `gld_ActivateLightmap` identico |
| 7 | **Contesto**: `gl_main` in `Libs\GlContext` (`IGlWindow`, `IGlContext`, `IGlFrameEnder` con strategie wipe/ENDOOM/overlay/fade al posto dei 20 `{$IFDEF}`); `I_*` restano la facciata | **L-XL** | **M-A** (finestra, schermo intero, alt-tab, cambio di modo, device persi) | 0 | build x4; prova a mano: finestra, schermo intero, `Alt+Tab`, cambio di modo dal menu, wipe, ENDOOM, console; flusso GL del primo fotogramma invariato; **non verificabile in modo automatico** |
| 8 (**fatta il 2026-11-12 per la parte OpenGL: `Libs\GlAutomap` + `TEngineGlAutomapPainter`, `gl_automap` e' una facciata; gli `{$IFDEF OPENGL}` di `am_map`/`am_textured` restano, vedi Libs\OpenGl\CLAUDE.md**) | Automap GL: strategia dietro `Libs\Automap` (un `IAutomapRenderer` al posto degli `{$IFDEF OPENGL}` di `am_map`/`am_textured`); `gl_automap` diventa la sua implementazione | M | M | 1 | flusso GL dell'automap per 3 mappe identico |
| 9 (**fatta il 2026-11-12: lista di disegno in `Libs\GlScene`, raccolta di flat, muri e sprite in tre classi del motore chiamate direttamente; gli `{$IFDEF}` di gioco restano dove i record sono diversi; non fatto: `IRendererBackend` della #156; vedi Libs\OpenGl\CLAUDE.md**) | **`GlScene`: raccolta.** `gld_Add*` (1.098 righe, senza chiamate GL) a classi con le liste in campi; i globali del BSP (`frontsector`, `backsector`, `curline`...) passati in un record di vista; **insieme alla fetta 8 della #156** (`IRendererBackend`) | **XL** | **A** (percorso caldo per muro, 22 globali scritti) | 1, 4 | liste di disegno identiche su tutte le mappe + flusso GL identico + `-timedemo` +5% |
| 10 | **`GlScene`: disegno.** `gld_Draw*` (circa 1.700 righe, tutte GL) in una classe con stato nei campi, chiamata senza interfaccia dal fotogramma; le 254 righe `var` di implementazione diventano campi; cielo, nebbia, luci dinamiche, arma, HUD | **XL (piu giorni)** | **A** | 9 | flusso GL **byte per byte**; impronta dello schermo e screenshot; `-timedemo` +5% su 3 demo di Doom e una per gioco |
| 11 | Modelli: `GlModels` (draw MD2/DDMODEL/DLL e liste dei voxel) e `Libs\Models\Script` come spostamento; conversione di `mdl_script*` solo con `Libs\ScriptHost` | M (spostamento), XL (conversione) | M | 2, 3 | flusso GL di un PK3 con MD2, DDMODEL, DMX e uno script |
| 12 | Facciate: `gl_clipper` e le `gld_*`/`GL_Configure*` esposte a ~30 unit; `m_defs` e `m_menu` che indirizzano le opzioni; `Libs\OpenGl\Legacy` vuota e cancellata | L | M | tutte | build x8, prove a runtime, `FACCIATE.md` |

**Prima fetta proposta: la 0** (sotto). Dopo la 0, la 1 e il vero prerequisito di ogni conversione: senza il registratore non c'e modo di dire "uguale" per il codice che chiama `gl*`.

### 7.1 Fetta 0 in dettaglio (spostamento meccanico)

Come per `SCRIPT\` (`8cbf7812` solo `git mv`, poi `96c83939` percorsi), in due commit:

1. `git mv` senza toccare i contenuti: `OPENGL\dglOpenGL.pas` -> `Libs\OpenGl\Binding\dglOpenGL.pas`; gli altri 26 file -> `Libs\OpenGl\Legacy\` (stesso nome). `Legacy` dice che sono procedurali e che si svuotera fetta per fetta: ogni fetta successiva sposta le sue unit nella nuova libreria.
2. Percorsi: `OPENGL\` -> `Libs\OpenGl\Legacy\` in 26 righe di ciascuno dei 4 `GL*32.dpr` (la riga di `dglOpenGL` -> `Libs\OpenGl\Binding\`): **108 righe in 4 file**. I `.dproj` **non cambiano** (il nome `OPENGL` e solo nel define, non nei percorsi). `{$I Doom32.inc}` (25 file) si risolve con `DCC_IncludePath` (`..\Common`) come per `Libs\PascalScript`; non cambia niente. Nessun `build.bat`, `.groupproj`, test o script cita `OPENGL\`.
3. Documenti: i `Libs\<Nome>\CLAUDE.md` (cinque occorrenze di `OPENGL\...` nelle sezioni `Libs\GlMath`, `Libs\Models`, `Libs\Texture`, `Libs\DynLights`, `Libs\Voxel`), `docs\FACCIATE.md` (intestazioni `### \`OPENGL\gl_*.pas\``), `docs\PENDING_ISSUES.md` (3 righe), `Libs\Models\README.md`, `Libs\GlMath\README.md`, `Libs\Renderer\README.md`, `Libs\Texture\README.md`, `Libs\DynLights\WIRING.md`, `Libs\GameData\README.md`, `Libs\Speed\README.md`, `Libs\Script\README.md`, `Libs\PascalScript\README.md`, `docs\INTEGRAZIONE_GIOCHI.md`, `docs\SCRIPTHOST_PIANO.md`, tre README di `Tests\Data` (GlMath, Models, Voxel). Le copie sotto `.claude\worktrees` e `Reference\` **non** si toccano.
4. Un `Libs\OpenGl\README.md` (tabella delle unit con la loro nuova destinazione dalla sezione 6, il perche di `Binding` e `Legacy`, e la regola "interfaccia a granularita di fotogramma, mai per vertice").

Verifica: `build.bat giochi` e `build.bat all` verdi (log in `logs\`); ogni `GL*32.exe` avviato con `Tools\Esegui-gioco.ps1` (`-warp`, `-devparm -nomusic`, 25 s) vivo e senza `crash.txt`; `git diff -M --stat` 27 rinomini al 100%. Stima **S** (un'ora e mezza: lo spostamento e di minuti, le build sono 8 e i documenti 20 file). Rischio **B**: i nomi delle unit non cambiano e non si cambia una riga di codice.

---

## 8. Che cosa NON conviene fare

- **Interfacce per vertice, per chiamata GL o per muro** (un `IGlApi` che avvolge `glVertex3f`): il disegno di un fotogramma ha qualche migliaio di muri e decine di migliaia di vertici; costo e perdita del punto di aggancio del registratore. Le chiamate GL restano chiamate dirette a `dglOpenGL`.
- **Sostituire `dglOpenGL` con `Winapi.OpenGL`** o riscriverlo a mano ora: nessun beneficio visibile, perde il registratore e le estensioni.
- **Passare agli shader o ai VBO** (anche "gia che ci siamo"): cambia l'immagine e rompe ogni parita; e un altro lavoro (OpenGL 1.x resta il target dichiarato).
- **Convertire `gl_render` prima del registratore (fetta 1) e della geometria (4)**: 5.790 righe, 254 variabili di unit, 22 globali del renderer scritti; senza il flusso di chiamate come golden non c'e verifica.
- **Dividere `gl_render` in unit con procedure libere** "per ora": sposta le righe senza togliere stato globale e non e una classe; meglio saltare dallo stato globale alle classi di `GlLevel` (fetta 4) e `GlScene` (9-10).
- **Convertire `mdl_script*` (1.976 righe) da soli**: sono la colla del vecchio PascalScript; si spostano (fetta 11) e si convertono con `Libs\ScriptHost`, non prima.
- **Convertire `mdl_dllmodel`**: carica una DLL esterna che disegna con GL; nessun comportamento da riprodurre.
- **Togliere la facciata di `gl_clipper`** prima della fetta 9: e chiamata per muro da `r_bsp` e `r_main` e il costo e noto.
- **Confrontare pixel senza il controllo vecchio-vecchio** sullo stesso driver, ne tra macchine diverse.
- **Riformattare o rinominare** (`gld_*`, `gl_*`) in massa: vale la regola del `CLAUDE.md` per il codice storico.

---

## 9. Rischi

| Rischio | Dove | Mitigazione |
|---|---|---|
| Il modo immediato dipende dal driver: due esecuzioni diverse possono dare pixel diversi | fette 5-10 | il criterio principale e il flusso di chiamate (indipendente dal driver); i pixel solo a coppie vecchio-nuovo sulla stessa macchina |
| Aritmetica `Single` a 32 bit (x87) e `Double` nel carving dei flat | fetta 4, 9, 10 | stesso ordine delle operazioni; i test di parita copiano il vecchio nello stesso eseguibile; non "ripulire" le espressioni |
| Stato GL implicito (matrici, abilitazioni, texture legata): una classe che cambia l'ordine di una `glEnable` cambia il fotogramma anche se l'immagine "sembra" uguale | fette 7-10 | il registratore vede ogni chiamata; si confronta l'intera sequenza |
| `gl_render` scrive 22 globali del renderer e legge 61 | fetta 9-10 | record di vista passato esplicitamente; i globali storici si leggono solo nel composition root o nella facciata |
| Finestra/contesto: schermo intero, alt-tab, cambio di modo, perdita del dispositivo, cursore, DPI | fetta 7 | non automatizzabile: elenco di prove a mano nel documento `RUN-<n>.md` della fetta |
| Opzioni di menu e `.ini` indirizzano variabili di `gl_*` (`m_defs` ne indirizza circa 50) | fette 5-8, 12 | le variabili restano dove sono finche non c'e una classe che le possieda (come per `TEngineDefaults`) |
| Unit con `{$IFDEF DOOM/HERETIC/HEXEN/STRIFE}` (39 in `gl_render`, 20 in `gl_main`) | fette 7, 9, 10 | profili per gioco (`TGlRendererProfile`, come `TUdmfGames`) invece di `{$IF}` dove i record del motore lo permettono; dove i record sono diversi per costruzione resta l'`{$IFDEF}` come nel caricamento del livello |
| Win64: `dglOpenGL` e i 5 cast `Integer`/`LongWord` di `gl_tex`, 1 in `gl_main`, 1 in `gl_lightmaps` | #41-#44, non questo piano | annotati, da compilare con `dcc64` a suo tempo |
| Nessun progetto di test tocca `OPENGL\` oggi: la copertura di quello che si converte parte da zero | tutte | le classi nuove nascono con i loro test (finti per le dipendenze); il codice che chiama GL si prova con il registratore, non con DUnitX |
| Le copie in `.claude\worktrees\*` e `Reference\*\OPENGL` hanno gli stessi nomi | fetta 0 | non si toccano; la ricerca dei riferimenti esclude queste cartelle |

---

## 10. Riassunto

Cartella `OPENGL\`: 27 file, 37.822 righe, di cui 20.332 di terzi (`dglOpenGL`) e 17.490 del motore; 1.217 chiamate GL; OpenGL 1.x a funzione fissa, senza shader. `gl_render` (5.790 righe) si divide in 767 righe di geometria pura a freddo, 1.098 di raccolta senza GL e circa 1.700 di disegno quasi solo GL. Per toglierla servono 12 fette: la 0 e meccanica, la 1 (registratore delle chiamate GL) e il prerequisito di tutto il resto, le 9-10 (la scena) sono XL e vanno insieme alla fetta 8 della #156.

### Stato dopo la fetta 2 (2026-11-09)

- Fetta 1: il confronto del registratore e deterministico (orologio virtuale `HarnessGl_Clock` con `-glrecord`, `-nomouse -nojoystick`); vecchio contro vecchio **UGUALE** nei quattro giochi GL. Il registratore non vede le liste compilate al caricamento (voxel, modelli): per quelle il criterio e il confronto vecchio/nuovo nello stesso eseguibile.
- Fetta 2: fatta (vedi `Libs\OpenGl\CLAUDE.md`).
- Prossime a freddo: 3 (parser MODELDEF), 4 (geometria del livello a freddo), 5 (buffer delle texture). Non fatte in questa sessione.
- **Stato al 2026-11-12**: fatte 0, 1, 2, 3, 4 (tranne `gl_setup` e `gl_slopes`), 5 e 8 (parte OpenGL). Il registratore e' stato riparato dopo la sostituzione di `dglOpenGL.pas` e ora regge una `-timedemo` (input chiuso con `-glrecord`) e l'automap (`-glautomap`). Restano: 6 (lightmap dei voxel: serve un livello di prova con voxel e GLDEFS), 7 (contesto: prove a mano), 9 e 10 (scena: raccolta e disegno, XL, il vero percorso caldo; lo strumento per provarle c'e': flusso GL su una demo con `Confronta.ps1 -Scenario`), 11 (modelli), 12 (facciate e cancellazione di `Libs\OpenGl\Legacy`). Misura di riferimento per le prossime: `-timedemo demo3` di DOOM1.WAD in GLDoom32 su questa VM (Mesa/SVGA3D) = circa 5960-5980 realtic per 2134 gametic.
- Fetta 4 (seconda parte): fatta tranne gl_setup e gl_slopes; infrastruttura delle impronte dei livelli in Tools\Verifica\opengl\Impronte.ps1 (vedi Libs\OpenGl\CLAUDE.md). Nessun tesselatore GLU nel codice (era in gld_PrecalculateSector, gia' tolto).
- **Stato dopo la fetta 9 (2026-11-12)**: fatte 0, 1, 2, 3, 4 (tranne `gl_setup` e `gl_slopes`), 5, 8 e **9** (la raccolta: `TGlSceneDrawList`, `TEngineGlSceneFlatCollector`, `TEngineGlSceneWallCollector`, `TEngineGlSceneSpriteCollector`, `TEngineGlSceneLightMarker`; `gl_render.pas` da 5436 a 4032 righe; flusso GL UGUALE dopo ognuno dei quattro passi su sei scenari, misure in `Libs\OpenGl\CLAUDE.md`). **Resta la 10** (il disegno: `gld_DrawWall`, `gld_DrawFlat`, `gld_DrawSprite`, modelli e voxel degli sprite, luci dinamiche, nebbia, `gld_DrawScene`, `gld_StartDrawScene`/`gld_EndDrawScene`, HUD e arma: circa 2700 righe di `gl_render.pas` con le variabili di unit da portare in campi), non cominciata: ogni passo chiede circa 25 minuti di parita' e misure su questa VM. Ordine consigliato dei passi della 10, dal piu' isolato: nebbia (`gld_StartFog`, `gld_StartWhiteFog`), luci dinamiche (`gld_SortDlights`, `gld_DrawDLights`), flat (`gld_DrawFlat` con la matrice del ripple), muri (`gld_DrawWall` con il flood stencil), sprite (`gld_DrawSprite`, modelli, voxel), poi `gld_DrawScene` e l'inizio e la fine del fotogramma. Restano anche 6, 7, 11, 12 e `gl_setup`/`gl_slopes` della 4.
