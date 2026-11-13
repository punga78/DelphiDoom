# Libs\Models e Libs\GlMath - analisi di `Libs\OpenGl\Legacy\` e cosa è stato portato (issue #45)

> Note per Claude e paragrafi di dettaglio (issue #178): [CLAUDE.md](CLAUDE.md).

La cartella `Libs\OpenGl\Legacy\` ha 28 unit (39831 righe). Questo documento dice, unit per unit, chi la chiama, se sta sul percorso
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
| `mdl_script`, `mdl_script_proclist`, `mdl_script_functions` | 187, 376, 1020 | 0 | `mdl_script_model` | compilazione ed esecuzione con **PascalScript** (`Libs\PascalScript\ps_*`); ~60 funzioni (matematica in `Extended`, `Format`, `Write`...) registrate per indirizzo con la convenzione `register` | restano: è la colla del vecchio motore PascalScript (`Libs\Script` ha l'analisi di come sostituirlo, non è collegata) |
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
(`Libs\OpenGl\Legacy\DelphiDoom.Engine.Models.Renderer.pas`, le chiamate `gl*` di prima). Il rendering resta nel motore.

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

### 2b. Modelli I3D di Speed Haste (issue #168, fetta S3 di Speed)

Il formato I3D ("OBJECT3D" di Iguana, 1995) è quello dei modelli di Speed (`Reference\Speed\OPENGL\i3d_*`, `mdl_i3d`). Sta in
`Libs\Models` e non in `Libs\Speed` perché non dipende dal contenitore `SPEEDH.JCL` (il parser prende i byte, che arrivano da
`ISpeedContainer.TryRead` o da un file) e non dalle regole del gioco; `Libs\Models` non conosce `Libs\Speed` e il test sul gioco vero
(che ha bisogno del contenitore) sta nel progetto di test di Speed.

**Il formato.** Il file è: firma `$443342` ("B3D"), la dimensione dell'immagine, l'immagine, poi i pixel delle texture. L'immagine è lo
**scarico di memoria** dell'oggetto (`TI3dDiskObject`, 60 byte): conteggi, flag, cinque puntatori che nel file sono offset dall'inizio
dell'immagine (vertici di 36 byte, normali di 28, materiali di 28, e la "cache delle facce": per ogni faccia un'intestazione di 48 byte e
i suoi vertici di 20 byte che puntano al vertice e alla normale), scala e centro. Ogni materiale con `TextureOffset <> 0` ha una texture di
64x64 byte (256x64 con il flag `I3D_MATERIAL_WIDE`) che segue l'immagine nell'ordine dei materiali; i pixel sono indici della palette fissa
di 256 colori a 6 bit (`TI3dPalette`). Il flag `I3D_OBJECT_HAS_TIRES` dice che le prime 64 facce sono le quattro gomme (16 a testa). I record
su disco sono `packed`, senza puntatori (uguali a 32 e 64 bit), con `SizeOf` coperto da test.

| Unit | Ruolo |
|---|---|
| `DelphiDoom.Models.I3d.Types` | record su disco, record neutri (`TI3dHeader`, `TI3dMaterial`, `TI3dTexture`, `TI3dFace`, `TI3dFaceVertex`, `TI3dCorrection`, `TI3dTireState`), costanti, messaggi |
| `DelphiDoom.Models.I3d.Intf` | `II3dParser`, `II3dModel`, `II3dCorrectionReader`, `II3dRenderTarget` (estende `IModelRenderer`), `II3dModelRenderer`; `Models.Intf` non è toccata |
| `DelphiDoom.Models.I3d.Factory` | `TI3dFactory`, l'unico punto che conosce le classi (separata da `TModelsFactory` perché gli eseguibili senza I3D non la linkino) |
| `DelphiDoom.Models.I3d.Parser` | `TI3dParser` (`II3dParser`): dai byte al modello; ogni offset è controllato contro la dimensione dell'immagine |
| `DelphiDoom.Models.I3d.Model` | `TI3dModel` (`II3dModel`): intestazione, facce (ogni vertice ha la sua copia della posizione), materiali, texture, le quattro gomme, correzioni |
| `DelphiDoom.Models.I3d.CorrectionReader` | `TI3dCorrectionReader`: il file `.txt` accanto al modello (`face 3 vertex 1 visible 1 x .. y .. z .. tx .. ty .. color ..`) |
| `DelphiDoom.Models.I3d.Renderer` | `TI3dModelRenderer` (`II3dModelRenderer`): il vecchio `RenderGL` su un `II3dRenderTarget` |
| `DelphiDoom.Models.I3d.TireAnimator` | `TI3dTireAnimator`: dalla distanza percorsa alla rotazione di una gomma (la parte di `RenderGLEx`) |
| `DelphiDoom.Models.I3d.Coordinates` | `TI3dCoordinates`: vertice -> mondo, punti di texture (`UVtoGL`/`GLtoUV`) |
| `DelphiDoom.Models.I3d.Palette` | `TI3dPalette`: la palette fissa (colore come frazioni o `$00BBGGRR`, indice del colore più vicino) |

`II3dRenderTarget` estende `IModelRenderer` (le chiamate di `BeginPrimitive`, `Vertex3f`, `Color4f`, `PushMatrix`...) con la sola scelta della
texture (`SetTexturing`, `BindTexture(indice)`, `ResetTextureCache`): è il contratto che un adattatore OpenGL del motore realizzerà (una classe come
`TEngineModelRenderer` che tiene le texture GPU, create da `II3dModel.TextureToRgba`, e cambia quella di un `.material` per nome con
`FindMaterialByTextureName`, come faceva `RenderGLEx`); **non c'è ancora nel motore**: `Libs\OpenGl\` non è stata toccata e il disegno esistente non
passa da qui. Il renderer non ha stato e scorre le facce una volta per modello (una chiamata a interfaccia per faccia e per vertice, come per i
comandi MD2).

**Verifica (parità).** Un harness **fuori dal repository** (`mdl_i3d`/`i3d_model.pas` e `i3d_structs.pas` del fork con le sole correzioni per compilare:
`char` -> `AnsiChar` nei nomi delle texture, `TStream`, `glBegin`/`glVertex3f`... sostituiti da una classe che registra le chiamate, `CreateTexture`
senza GL) ha letto con il vecchio `TI3DModelLoader.LoadFromStream` i 50 modelli I3D di `SPEEDH.JCL` (shareware) e tre file sintetici di
`TI3dFileBuilder` (con gomme, texture larghe, scala 0, materiale trasparente), e ha scritto per ognuno: intestazione, impronta FNV-1a di facce (conteggi,
flag, materiale, vertici, punti di texture) e di texture, centro e altezza delle gomme, e tre chiamate di `RenderGL` (con scala e offset diversi, una faccia
selezionata, gomme che girano) con numero di triangoli, di chiamate e impronta dei loro argomenti (i bit delle `Single`); poi le stesse righe dopo 12
correzioni (`ApplyCorrection` più `FindTireCenters`, alcune fuori dal modello). I file sono `Tests\Data\Speed\i3d.shareware.golden.txt` (800 righe) e
`Tests\Data\Models\i3d.synthetic.golden.txt` (48). **La libreria dà le stesse righe, zero differenze** (anche le chiamate di disegno, bit per bit, con lo
stesso `Single` dopo i calcoli in `Extended`/`Double`). Test: `Tests\DelphiDoom.Tests.Models` (101, copertura 99%) e `Tests\DelphiDoom.Tests.Speed`
(`DelphiDoom.Tests.Speed.I3dModels`, 2: i 50 modelli letti dal contenitore; si salta se `SPEEDH.JCL` manca).

**Differenze volute dal vecchio.** Un file danneggiato (firma, dimensione, array o riferimenti fuori dall'immagine, texture che non c'è nel file) è
`EModelsException` (il vecchio leggeva memoria a caso o tornava `false` solo per la firma); un riferimento a un vertice, una normale o un materiale deve
cadere sull'inizio di un elemento del suo array (il vecchio prendeva un puntatore qualsiasi); una faccia senza materiale (puntatore 0) ha
`MaterialIndex = -1`, `Color = 0` e si disegna bianca senza texture (il vecchio andava in access violation); il nome della texture è di 8 `AnsiChar`
(`texname: array[0..7] of char` in Delphi 11 sono 16 byte e sposterebbe tutti i campi seguenti); il colore corretto da una correzione è quello **della
faccia** (il vecchio lo scriveva nella copia del materiale della faccia, uguale per costruzione); le gomme senza il flag o con meno di 64 facce hanno
centro e altezza zero. **Conservato**: una faccia di meno di tre vertici conta `n - 2` triangoli (anche negativo); `TI3dPalette.IndexOf` confronta il
colore a 8 bit con la palette a 6 bit senza scalare (lo usa solo l'editor delle correzioni); un vertice corretto ha la sua copia (non cambia le altre
facce che usavano lo stesso vertice).

**Non portato.** `RenderSoft`/`RenderSoftEx` (rasterizzatore software `r_soft3d`, fetta S6 opzionale), `AddCorrection`, `SaveCorrections*` (editor), la
creazione delle texture GL e dei `TBitmap` (`CreateTexture`, `i3d_textures`, `gld_RegisterI3DTexture`: sono del motore), `mdl_i3d`/`mn_drawmodel` (classe del
motore sopra `TBaseModel`), e l'effetto di `carinfo_t` (le texture della livrea e `mobj.tiredistance` sono dati del gioco: `TI3dTireAnimator` li riceve come numeri).

### 2c. Modelli MD5 di id Tech 4 (issue #104, prima fetta)

`DelphiDoom.Models.Md5.*` legge i file `md5mesh` e `md5anim` di Doom 3 e calcola scheletro e vertici, senza OpenGL, senza materiali e senza chiamanti nel motore (percorso freddo). **Licenza**: derivate da `renderer\Model_md5.cpp`, `game\anim\Anim.cpp` e `idlib` di Doom 3 (GPL v3 con i termini aggiuntivi, intestazione "Based on the Doom 3 GPL Source Code (id Software)"); `Md5.Factory` e' nostra. Nel repository non c'e' nessun modello di Doom 3: i file di prova sono un cubo con due giunti scritto per i test (`Tests\Data\Models\md5`).

| Unit | Contenuto | Originale C++ |
|---|---|---|
| `Md5.Types` | costanti (`MD5_VERSION`, bit `ANIM_*`), `TMd5Joint`, `TMd5FrameBlend`, `TMd5AnimJointInfo`, messaggi | `Model.h`, `Anim.h` |
| `Md5.JointQuat`, `Md5.JointMat` | `TMd5JointQuat` (rotazione e traslazione relative), `TMd5JointMat` (3x4: `SetRotation`, `Rotate`, `Apply`, `TransformBy`/`UntransformBy` = `*=` e `/=`, `ToJointQuat`) | `JointTransform.h/.cpp` |
| `Md5.Intf` | `IMd5Skeleton`, `IMd5Mesh`, `IMd5Model`, `IMd5Anim`, `IMd5ModelParser`, `IMd5AnimParser` | - |
| `Md5.Skeleton` | `TMd5Skeleton`: da quaternioni a matrici, `TransformJoints`, `UntransformJoints`, `ToAbsolute`, `BlendJoints` (slerp e lerp) | `Simd_Generic.cpp` |
| `Md5.Mesh`, `Md5.MeshParser` | punti di texture, triangoli, pesi gia' scalati; `TransformVerts`, `TransformScaledVerts`, `CalcBounds`, `NearestJoint` | `idMD5Mesh` |
| `Md5.Model`, `Md5.ModelParser` | giunti, posa predefinita relativa, matrici assolute del file, bounds, ricerca del giunto per nome | `idRenderModelMD5` |
| `Md5.Anim`, `Md5.AnimParser` | frame di base, componenti animati, bounds, tempo in fotogrammi, origine e rotazione della radice, fotogramma interpolato e singolo | `idMD5Anim` |
| `Md5.Factory` | `TMd5Factory`: unico posto che conosce le classi concrete | - |

La lettura usa `TIdLexer` di `Libs\IdLib` (stesse bandiere dell'originale); gli errori sono `EIdLexerException` con "file F, line N: testo". Vettori, quaternioni (`TIdQuat`, `Slerp`, `CalcW`), `TIdCQuat` e matrici (`TIdMat3`) sono quelli di `Libs\IdLib` e `Libs\MathCore`; i bounds sono `TGeoBounds` di `Libs\Geometry`.

**Parita'**: le classi vere di `idlib` (idLexer, idQuat, idMat3, idJointMat, `idSIMD_Generic`) e le funzioni di `idMD5Anim` estratte per intervallo di righe da `Anim.cpp` (`LoadAnim`, `ConvertTimeToFrame`, `GetOrigin`, `GetOriginRotation`, `GetBounds`, `GetInterpolatedFrame`, `GetSingleFrame`) sono state compilate con `bcc32c` (`-std=c++17`, con un `precompiled.h` finto) in un harness **fuori dal repository**; `idMD5Mesh::ParseMesh` e `LoadModel` non si compilano da soli (dipendono dal renderer) e il loro calcolo (pose relative, pesi, `NearestJoint`) e' copiato nell'harness. L'uscita (347 righe, float come bit `#xxxxxxxx`) e' in `Tests\Data\Models\md5\cube.golden.txt`: pose, matrici assolute, pesi, vertici in posa di riferimento, bounds, `NearestJoint`, intestazione dell'animazione, 14 tempi per 3 numeri di cicli (blend, origine, rotazione, bounds, giunti interpolati, scheletro assoluto, vertici) e i fotogrammi singoli. **Tolleranza**: 2 ULP, oppure 4e-6 relativo, oppure 1e-5 assoluto (il clang di `bcc32c` arrotonda a `float` ogni operazione, l'x87 di Delphi tiene l'espressione in registro; l'assoluto serve alle cancellazioni vicino a zero). Win32 e Win64 passano.

**Differenze volute dal C++** (dove l'originale legge memoria fuori dall'intervallo o non termina): una frequenza di fotogrammi 0 e' un errore (la lunghezza divide per essa); un genitore di un giunto non precedente nell'md5mesh, un indice di peso o di vertice fuori dall'intervallo, un peso con indici negativi e componenti di un giunto oltre quelle del fotogramma sono errori (`ParseMesh` mette solo un avviso e poi legge fuori, `LoadAnim` non controlla `firstComponent + componenti`); `ConvertTimeToFrame` moltiplica in `Int64` (in `int` il C++ va in overflow dopo circa un giorno di animazione); il messaggio di `Invalid size` di `ParseMesh` stampa il numero e non il nome dello shader. `TransformScaledVerts` e' scritto come voleva l'autore: nel C++ la funzione moltiplica una copia locale **non inizializzata** (`alloca` senza copia dei pesi), quindi il risultato originale e' indefinito. **Difetti conservati**: `NearestJoint` non guarda mai l'ultimo peso di un vertice (il ciclo `weightIndex[i*2+1] == 0` si ferma su di esso); il controllo del genitore `num >= joints.Num() - 1`; `NearestJoint` e' per indice di mesh, non per `surfaceNum` (che appartiene all'istanza dinamica del renderer).

**Non portato** (resta nella #104): le normali, le tangenti e il resto di `R_BuildDeformInfo` (`R_DeriveTangents`, spigoli di sagoma, vertici specchiati: sono nel renderer e dipendono da `srfTriangles_t`), i materiali e `shader->UseUnsmoothedTangents`, `InstantiateDynamicModel`/`DrawJoints`, il caricamento da file system (`LoadModel` con `fileSystem->ReadFile`, il modello di riserva `MakeDefaultModel`), `idAnimManager`, `idAnimBlend`/canali e `CheckModelHierarchy` (si fa con `IMd5Model` + `IMd5Anim`), `GetOrigin`-correlati di `idAnim`, le esportazioni. Resta anche una issue per usare MD5 in MODELDEF (come dice la #104).
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
