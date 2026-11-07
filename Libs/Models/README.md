# Libs\Models e Libs\GlMath - analisi di `OPENGL\` e cosa è stato portato (issue #45)

La cartella `OPENGL\` ha 28 unit (39831 righe). Questo documento dice, unit per unit, chi la chiama, se sta sul percorso
caldo del fotogramma o è caricamento a freddo, e perché è stata portata a classi oppure no. Le due librerie nate da
questo lavoro sono `Libs\Models` (modelli 3D) e `Libs\GlMath` (geometria pura del renderer); `GlMath` ha il suo
paragrafo qui perché è nata dalla stessa analisi.

## 1. Analisi

Regola usata (come nelle altre librerie): si portano a classi le parti **pure e fredde**, senza chiamate a OpenGL
(`dglOpenGL`), senza `screens[]`, senza zone memory e senza i globali del renderer; resta nel motore ciò che tocca il
contesto GL, i buffer del renderer, o è sul percorso caldo (per muro, per sprite, per vertice).

| Unit | Righe | Chiamate GL | Chi la usa | Percorso | Decisione |
|---|---|---|---|---|---|
| `dglOpenGL` | 20332 | - | tutti | binding di terze parti | **non toccata** |
| `gl_types`, `gl_misc` | 93, 96 | 0 | `gl_render`, `gl_tex`, `mdl_*` | tipi e tre `min/max` | restano (tipi del renderer) |
| `gl_defs` | 192 | 0 | quasi tutti | costanti (`MAP_COEFF`...) e flag | resta |
| `gl_render` | 5842 | 540 | `r_main`, `r_bsp`, `r_things`... | **caldo** (muri, flat, sprite per fotogramma) | resta (percorso caldo, contesto GL) |
| `gl_main` | 1263 | 126 | `i_system`, `d_main`, menu, `f_wipe`, `m_misc`... (una trentina di unit) | finestra, contesto, swap | resta (legata al contesto) |
| `gl_tex` | 2088 | 125 | `r_main`, `r_hires`, menu, `gl_render` | carica e lega texture GL; usa `TEXLIB` (altro lavoro in corso) | resta |
| `gl_sky` | 376 | 112 | `gl_render` | disegno del cielo, ogni fotogramma | resta |
| `gl_automap` | 441 | 35 | `am_map`, `am_textured` | disegno dell'automap | resta |
| `gl_setup` | 452 | 0 | `p_setup` | prepara le strutture GL del livello (a freddo, ma dentro `sector_t`/`seg_t`) | resta (legata ai tipi del motore) |
| `gl_slopes` | 105 | 0 | `gl_render` | **caldo**: due formule su `Psector_t` per ogni vertice | resta |
| `gl_lights`, `gl_ambient`, `gl_shaders` | 147, 156, 208 | 16, 13, 12 | `r_lights` e `gl_render`; `gl_render`; **nessuno** (`gl_shaders`: `numshaders` non cresce mai, è codice morto) | creano texture/programmi GL | restano (solo GL) |
| `gl_shadows` | 132 | 0 | `gl_render`, `m_defs`, menu | tabella di 16 `GLDRenderLight` di cui il renderer tiene i puntatori | resta |
| `gl_lightmaps` | 874 | 44 | `gl_render`, `m_defs`, menu | calcolo a freddo per voxel, ma sopra `vx_*`, settori e GL | resta (candidata a una fetta futura) |
| `gl_voxels` | 1989 | 30 | `r_things`, `vx_base`, `gl_render` | costruisce le mesh dei voxel con il loader `vx_*` e liste GL | resta (candidata a una fetta futura) |
| **`gl_frustum`** | 346 | 3 (2 `glGetFloatv`) | `gl_render` (una chiamata per fotogramma) | matematica pura, i test `fr_*InFrustum` non hanno chiamanti | **portata a `Libs\GlMath`** (`TGlFrustum`); la unit è stata **cancellata** (#134): i piani non li leggeva nessuno |
| **`gl_clipper`** | 423 | 0 | `r_bsp` (per ogni muro), `r_main`, `gl_render` | lista di intervalli di angoli, matematica pura sull'angolo | **portata a `Libs\GlMath`** (`TGlAngleClipper`, `TGlViewAngle`), la unit è una facciata |
| **`gl_models`** | 727 | 2 | `r_things`, `gl_render`, `m_defs`, menu | registro di modelli e parser di MODELDEF (usa `sc_*`) | resta (legato a scanner, `states[]`, texture GL) |
| **`mdl_md2`** | 568 | 7 | `gl_models` | lettura del file a freddo + disegno (percorso caldo: `Draw`) | **lettura portata** (`Libs\Models`), il disegno resta |
| **`mdl_ddmodel`** | 255 | 8 | `gl_models` | caricamento a freddo + display list | **comandi portati** (`Libs\Models`), il disegno resta |
| **`mdl_script_model`** | 851 | 14 | `mdl_ddmodel`, proclist | lista di comandi + 16 funzioni host di PascalScript | **lista portata**, restano le 16 funzioni host (facciata sottile) |
| `mdl_dllmodel` | 205 | 4 | `gl_models` | carica una DLL e ne chiama `draw` (`stdcall`) | resta (carica codice esterno che disegna con GL) |
| `mdl_script`, `mdl_script_proclist`, `mdl_script_functions` | 187, 376, 1020 | 0 | `mdl_script_model` | compilazione ed esecuzione con **PascalScript** (`SCRIPT\ps_*`); ~60 funzioni (matematica in `Extended`, `Format`, `Write`...) registrate per indirizzo con la convenzione `register` | restano: è la colla del vecchio motore PascalScript (`Libs\Script` ha l'analisi di come sostituirlo, non è collegata) |
| `mdl_base` | 87 | 0 | `mdl_*` | classe base dei modelli | resta, solo `TBaseModel` (#134: `MDL_ConfigureModels`, `MDL_Md2Parser`, `MDL_NewCommandStream` cancellate) |

## 2. `Libs\Models`

| Unit | Ruolo |
|---|---|
| `DelphiDoom.Models.Types` | tipi (`TModelVertex`, `TModelTexCoord`, `TModelPlacement`), i record dei formati su disco (`TMd2Header` 68 byte, `TMd2Triangle`, `TMd2TexturePoint`, `TMd2FrameHead`, `TModelCommand` 24 byte, `packed`, `SizeOf` coperto da test), i codici dei comandi, `EModelsException` |
| `DelphiDoom.Models.Intf` | `IMd2Parser`, `IMd2Model`, `IModelRenderer` (una chiamata per comando: `BeginPrimitive`, `Vertex3f`...), `IModelCommandStream` |
| `DelphiDoom.Models.Md2Parser` | `TMd2Parser`: dai byte del file ai vertici di ogni fotogramma (stesso ordine degli assi e degli angoli del vecchio, stessa aritmetica) |
| `DelphiDoom.Models.Md2Model` | `TMd2Model`: fotogrammi (un array per fotogramma, il puntatore non si sposta), punti di texture, gruppi di animazione, unione di più file |
| `DelphiDoom.Models.CommandStream` | `TModelCommandStream`: lista dei comandi di un modello procedurale, elenco ordinato dei fotogrammi, file binario DMX, `Play` su un `IModelRenderer` (ricorsione limitata) |
| `DelphiDoom.Models.Factory` | `TModelsFactory`, l'unico punto che conosce le classi |

Nel motore (dalla #134, senza facciata): il lettore MD2 e la lista dei comandi non hanno stato condiviso né dipendenze,
quindi `mdl_md2` e `mdl_ddmodel` li chiedono a `TModelsFactory` (`CreateMd2Parser` per ogni file, `CreateCommandStream`
per ogni modello); `mdl_md2` legge i byte con `TPakStream`, li dà al parser e disegna dai puntatori ai vertici (nessuna
chiamata a interfaccia per vertice: i puntatori sono in `fframes`); `mdl_ddmodel` esegue lo script con
`MDL_AppendFromScript` (`mdl_script_model`: le funzioni `MDLS_*` aggiungono comandi allo stream), legge un DMX con
`LoadFromBytes` e suona il fotogramma nella display list con `TEngineModelRenderer`
(`OPENGL\DelphiDoom.Engine.Models.Renderer.pas`, le chiamate `gl*` di prima). Il rendering resta nel motore.

### Differenze volute dal vecchio codice

- **MD2: nome del fotogramma e vertici.** Il vecchio record `TMD2AliasFrame_T` dichiarava il nome come `array[0..15] of Char`:
  in Delphi 11 un `Char` è di 2 byte, quindi il nome occupava 32 byte, i vertici erano letti **16 byte dopo** (4 vertici di
  scarto, gli ultimi 4 oltre il buffer) e i nomi dei gruppi erano illeggibili. Il confronto (harness) lo mostra: con il
  codice com'è oggi l'impronta dei 40 modelli di prova è diversa da quella del nuovo, con `AnsiChar` (come in Delphi 7,
  dove nasce il codice) è identica byte per byte. Il nuovo legge il nome come 16 byte. Test di regressione `DovrebbeLeggereIlNomeDelFotogrammaDi16ByteSenzaSpostareIVertici`.
- **MD2: `MergeFrames`.** Il vecchio copiava i fotogrammi dell'altro modello all'indice `fNumFrames - i`, cioè 0 o negativo:
  funzionava solo se il secondo file aveva un fotogramma, con più fotogrammi leggeva prima dell'array. Ora copia il
  fotogramma `i - fNumFrames`. Test `DovrebbeUnireAncheFileConPiuFotogrammi`.
- **MD2: file malformati.** Il vecchio non controllava nulla (file corto, offset, indici, `skinWidth = 0` dava una divisione
  per zero del coprocessore); ora un `EModelsException` e il motore dà `I_Error` con lo stesso prefisso di prima. Il vecchio
  non usava `ofs_tris` e `ofs_frames` (leggeva di seguito dopo i punti di texture); ora li usa (uguale per i file standard).
  Un modello senza fotogrammi è un errore.
- **MD2: nome del fotogramma vuoto.** Il vecchio (`strtrim` o `Copy(...)[1]` su stringa vuota o di soli spazi) non terminava
  mai; ora il gruppo è `''`.
- **DMX/DDMODEL: elenco dei fotogrammi.** Il vecchio usava `TDHashNumberList`, la cui bandiera "ordinata" si aggiorna con un
  numero di ritardo e `Sort` non ordina se la bandiera dice di sì: se un fotogramma più basso arriva dopo uno più alto
  (per esempio `SetFrame(1)` come primo comando e poi `SetFrame(0)`) l'elenco restava `[1, 0]` e l'interpolazione tra
  indici usava i fotogrammi sbagliati. Ora l'elenco è sempre ordinato e senza doppioni. Test `DovrebbeOrdinareIFotogrammiAncheSeVengonoInDisordine`
  (le serie dei golden hanno sempre il fotogramma 0 per primo e i nuovi fotogrammi in ordine crescente, gli unici casi in cui il vecchio è giusto).
- **DMX: file corto.** Il vecchio leggeva meno byte di quelli dichiarati lasciando memoria non inizializzata; ora un errore.
- **`RenderTextureMask`** (variante del disegno per le maschere di texture) non aveva chiamanti ed è stata tolta.

### Difetti del vecchio codice conservati

- Un file DMX caricato con `AppendFromStream` **sostituisce** i comandi che c'erano, non li aggiunge (anche i `framemerge` di un
  DMX): `LoadFromBytes` lo documenta.
- `TDDModel.LoadFrom` apre sempre il file `fname` (il modello) e non `fn`: i `framemerge` di un DDMODEL rileggono lo stesso file
  (un DDMODEL così ha i comandi doppi). Non toccato: non cambio il comportamento dei modelli che esistono.

### Non portato

- Il disegno (`Draw`, `DrawSimple`, display list, `glCallList`): è nel percorso caldo e dipende dal contesto GL.
- `mdl_dllmodel`: carica una DLL che disegna con OpenGL.
- Le funzioni host e la compilazione PascalScript (`mdl_script*`): colla dell'engine PascalScript; vanno con `Libs\Script`.
- `gl_models` (registro dei modelli e MODELDEF): usa lo scanner del motore, `states[]` e le texture GL.

## 3. `Libs\GlMath`

| Unit | Ruolo |
|---|---|
| `DelphiDoom.GlMath.Types` | `TGlAngle`, costanti, `EGlMathException` |
| `DelphiDoom.GlMath.Intf` | `IGlAngleClipper` |
| `DelphiDoom.GlMath.AngleClipper` | `TGlAngleClipper`: lista ordinata di intervalli (nodi in un array con indici al posto dei puntatori, lista libera) |
| `DelphiDoom.GlMath.ViewAngle` | `TGlViewAngle.FrustumAngle`: il vecchio `gld_FrustumAngle` (mezza ampiezza della vista) |
| `DelphiDoom.GlMath.Factory` | `TGlMathFactory` |

Collegamento: `ComposeOpenGl` (in `ComposeEngine`, solo build OpenGL) dà `GL_ConfigureClipper` alla facciata
`gl_clipper.pas`, che tiene la vecchia API (`gld_clipper_SafeCheckRange`, `gld_clipper_SafeAddClipRange`,
`gld_ClipperAddViewRange`, `gld_ClipperDone`); senza configurazione `I_Error`. `gld_ClipperAddViewRange` legge `viewplayer`,
`monitor_relative_aspect` e `viewangle`. Resta una facciata perché i chiamanti sono il giro del BSP (`r_bsp`, per ogni muro) e
`r_main`: diventeranno classi con il renderer. `gl_frustum.pas` è stata cancellata (#134): `fr_CalculateFrustum` leggeva due
matrici con `glGetFloatv` a ogni fotogramma e calcolava piani che nessuno leggeva, e i test `fr_*InFrustum` non avevano
chiamanti; `TGlFrustum`, rimasto nella libreria senza chiamanti, è stato cancellato con i suoi test dalla #145. **Costo misurato** del clipper (una chiamata a interfaccia in più per ogni controllo, per muro): in un
fotogramma tipico (64 intervalli, 2000 controlli) il vecchio è circa 80-100 ns per operazione e il nuovo circa 110-130 ns,
cioè meno di 0,1 ms per fotogramma.

A 32 bit le espressioni in virgola mobile sono quelle di prima (le `Single` si calcolano in `Extended`) e i risultati hanno gli
stessi bit; a 64 bit i valori intermedi sono `Single` e l'ultimo bit di un piano può cambiare (i test di parità vanno rifatti).
