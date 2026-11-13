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
### 2d. Modelli statici di id Tech 4: LWO, ASE, MD3 (issue #105, prima fetta)

Unit `DelphiDoom.Models.Static.*` (una classe per unit), **derivate da Doom 3** (GPL v3 con i termini aggiuntivi, intestazione come in `Libs\IdLib`).

| Unit | Ruolo (C++ di origine) |
|---|---|
| `Static.Types` | `TStaticDrawVert` (`idDrawVert`, 60 byte: xyz, st, normale, due tangenti, colore: **l'unico tipo di vertice dei modelli statici**), `TStaticColor`, `TStaticLoadOptions` (le cvar `r_mergeModelSurfaces`, `r_slopVertex` 0.01, `r_slopTexCoord` 0.001, `r_slopNormal` 0.02 e `fastLoad`), `EStaticModelException` (riga per ASE, offset per LWO e MD3), messaggi |
| `Static.Triangles` | `TStaticTriangles` (la parte di `srfTriangles_t` che i caricatori riempiono: vertici, indici, `generateNormals`; `CalcBounds` = `R_BoundTriSurf`; `Merge` = `R_MergeTriangles`), `TStaticSurface` (`modelSurface_t`: id, nome del materiale, geometria) |
| `Static.Intf`, `Static.Model` | `IStaticModel` (superfici, bounds, avvisi), `IStaticModelLoader` (`Load(bytes, nome)`), `TStaticModel` (`AddSurface`, `AddGeometry` che unisce, `Finish`) |
| `Static.VectorSubset`, `Static.VertexWelder`, `Static.SurfacePlanner` | `idVectorSubset` (sopra `TIdHashIndex`), `matchVert_t` con la catena per posizione, la ricerca delle superfici dello stesso materiale (`mergeTo`) |
| `Static.ByteReader`, `Static.Numbers` | lettore di byte (big endian per gli IFF, little endian per MD3, `getVX`, `getS0`) e `atoi`/`atof` del C |
| `Static.Lwo.*` | `TLwoReader` (FORM LWO2: LAYR, PNTS, POLS, VMAP/VMAD, PTAG SURF/PART/SMGP, TAGS, SURF con COLR e SMAN; normali dei poligoni e dei vertici con angolo di smussatura e gruppi, poligoni e vertici dei punti, riferimenti alle mappe), `TLwoConverter` (`ConvertLWOToModelSurfaces`: assi scambiati Y/Z, t invertita, saldatura, colore dalla superficie o dalla mappa RGBA), `TLwoModelLoader` |
| `Static.Ase.*` | `TAseParser` (gli `ASE_Key*` come metodi: materiali con bitmap e matrice di texture, oggetti, mesh, vertici, texture vertex, colori, facce, normali con la matrice del nodo, fotogrammi), `TAseConverter` (`ConvertASEToModelSurfaces`), `TAseModelLoader` (un `TStaticPathResolver` iniettato fa il lavoro di `OSPathToRelativePath`) |
| `Static.Md3.*` | `TMd3Reader` (`InitFromFile`: versione, limiti di 1000 vertici e 2000 triangoli, nomi in minuscolo senza `_1`), `TMd3ModelData` (`IMd3Model`: frame, tag di ogni frame, superfici; `Instantiate(frame, vecchio, backlerp)` = `LerpMeshVertexes` + `InstantiateDynamicModel`; `Bounds` del primo frame), `TMd3ModelLoader` |
| `Static.Factory` | `TStaticModelFactory` (loader LWO, ASE, MD3, per estensione) |

**Riuso**: vettori (`TIdVec2/3`), bounds (`TGeoBounds`), `TIdHashIndex`, `TIdMath` sono quelli di `Libs\IdLib` e `Libs\Geometry`; i tipi di `Md5.*` non servono (MD5 e' scheletrico, i modelli statici no). `TStaticDrawVert` e' nuovo perche' non c'era un vertice completo (`TMapDrawVert` e `TPatchDrawVert` hanno meno campi); le unit esistenti non sono state toccate.

**Differenze volute dal C++** (dove l'originale legge memoria fuori dall'intervallo, o dipende dal resto del motore): i materiali sono nomi (niente `declManager`: nessun `renderbump`, nessun materiale "discreto"; due materiali sono lo stesso se i nomi sono uguali senza maiuscole); i modelli ASE senza materiali vanno in una superficie `_default` (il C++ legge il materiale 0 di una lista vuota); un indice di punto, tag, vertice, texture, frame o materiale fuori intervallo e' un'eccezione (nel C++ e' memoria letta a caso); `lwGetPoints` scrive i punti di un secondo chunk PNTS dall'inizio (qui da dopo i primi, con un solo PNTS per layer, come in ogni file vero, non cambia nulla); `lwResolvePolySurfaces` accetta un indice di tag uguale al conteggio (`>` al posto di `>=`: qui e' un errore); le facce ASE non lette dal file partono a zero (nel C++ memoria non inizializzata, nel golden l'harness azzera la memoria); un LWO con poligoni e senza TAGS e' un errore (nel C++ puntatore nullo); i capitoli ENVL, CLIP e i canali di una superficie diversi da COLR e SMAN si saltano senza leggerli (il C++ li legge e puo' fallire su un file danneggiato che qui passa).
**Difetti del C++ conservati**: `R_MergeSurfaceList` non copia `generateNormals` (il risultato di un'unione e' sempre `false`); con `fastLoad` la soglia delle normali e' 1 e il test `dot > 1` non unisce mai due vertici uguali; il controllo di `*MESH_NUMCVFACES` confronta le facce di texture (un ASE con colori e senza texture e' rifiutato); `memset(currentMesh, 0, sizeof(puntatore))` pulisce solo `timeValue` (l'ultima `transform` dell'oggetto resta nel mesh); `ConvertASEToModelSurfaces` ignora `fastLoad` per la soglia delle normali; il numero di poligoni di un LWO con piu' di 3 vertici viene avvisato per ogni superficie.
**Parita'** col C++: l'harness (`Tests\Data\Models\static\harness`, fuori dal repository come gli altri) compila con `bcc32c` il vero `Model_lwo.cpp`, `Model_ase.cpp`, `HashIndex.cpp`, `Math.cpp`, le funzioni `ConvertASEToModelSurfaces` e `ConvertLWOToModelSurfaces` di `Model.cpp` e `R_MergeTriangles` di `tr_trisurf.cpp` (estratte per intervallo di righe) su stub del renderer (`idMaterial`, `declManager` con materiali per nome senza maiuscole, `idFile` in memoria, `SIMDProcessor->MinMax`); 15 casi su 9 file scritti per i test (`static.golden.txt`: superfici, conteggi, indici, vertici come bit, bounds): **zero differenze** con tolleranza 2 ULP o 4e-6 relativo (come MD5). **MD3 non e' confrontato col C++** (`idRenderModelMD3` dipende dal renderer): i test usano valori calcolati a mano (posizioni xyz/64, interpolazione, tag).
**Non portato in questa fetta** (MA, finitura delle superfici e gestore dei modelli sono poi in 2f e 2h): **MA** (Maya ASCII, 1107 righe di `Model_ma.cpp`), il formato **LWOB** (LightWave 5, `lwGetObject5`), i canali di superficie, le texture e gli shader del LWO, la **finitura di `idRenderModelStatic`** (`FinishSurfaces`/`R_CleanupTriangles`: triangoli degeneri, vertici duplicati, `R_DeriveNormals`/`R_DeriveTangents` quando `generateNormals`, bordi di silhouette, `tr_trisurf` in generale: i vertici hanno normale e tangenti ma le tangenti sono zero), l'uso dei materiali (`renderbump`, discreti), i `.skin` di Quake 3, l'animazione dei giocatori. Test: `StaticSupport`, `StaticLwo`, `StaticAse`, `StaticMd3`, `StaticParity` (112 nuovi, suite 334), copertura delle unit nuove 89-100% (Factory 89% senza il test dei costruttori senza opzioni, ora coperto). **Win64**: compila e i 112 test passano; resta il rosso noto `md2.merges`.
### 2e. Modelli dei giocatori di Quake III: `animation.cfg`, animazioni a due livelli, tag (issue #126, prima fetta)

`DelphiDoom.Models.Q3Player.*`, percorso freddo, senza chiamanti nel motore; **il tempo e' sempre un argomento** (nessun orologio nelle classi). **Licenza**: derivate da `code\cgame\cg_players.c`, `cg_ents.c`, `code\renderer\tr_model.c` e `code\game\q_math.c` di Quake III Arena (GPL v2 o successiva, intestazione "Based on the Quake III Arena GPL Source Code (id Software)"; nessun sorgente C nel repository, i dati di prova sono scritti per i test). Sopra l'MD3 gia' presente (`IMd3Model` e `TMd3Reader` di 2d: nessun lettore nuovo).

| C | Delphi |
|---|---|
| `COM_Parse`, `Q_stricmp` | `TQ3TokenReader` (`Next`, `SaveState`/`RestoreState` come `prev`, `SameWord`; una parola di 1024 caratteri o piu' e' scartata, un byte nullo e' la fine) |
| `CG_ParseAnimationFile` (le parti `footsteps`, `headoffset`, `sex`, `fixedlegs`, `fixedtorso`, le righe `first num looping fps`, la sottrazione di `skip` per `LEGS_*`, le animazioni della bandiera che mancano, quelle derivate `LEGS_BACKCR`, `LEGS_BACKWALK`, `FLAG_*`) | `TQ3AnimationParser` (`IQ3AnimationParser`), `TQ3AnimationConfig` (`IQ3AnimationConfig`: opzioni e le 37 `TQ3Animation`), `TQ3AnimationLoader` (la lettura dalla `IQ3TextSource` iniettata) |
| `lerpFrame_t`, `CG_SetLerpFrameAnimation`, `CG_RunLerpFrame`, `CG_ClearLerpFrame` | `TQ3LerpFrame`, `TQ3LerpFrameRunner` (`IQ3LerpFrameRunner`: `SetAnimation`, `Run`, `Clear`; `cg_animSpeed` 0 e' il parametro `AAnimationsEnabled`) |
| `CG_PlayerAnimation` (gambe e busto, `LEGS_TURN` mentre le gambe girano, fretta 1,5) | `TQ3PlayerAnimator` (`IQ3PlayerAnimator`; `cg_noPlayerAnims` e' un parametro) |
| `CG_SwingAngles` | `TQ3AngleSwinger.Swing` |
| `CG_PlayerAngles` (la parte che calcola assi: direzione del movimento, oscillazione del busto, inclinazione verso la velocita', `fixedlegs`/`fixedtorso`, `CG_AddPainTwitch`), `AnglesToAxis`, `AngleMod`, `AngleSubtract`, `MatrixMultiply` | `TQ3PlayerAngles` (`IQ3PlayerAngles`; `cg_swingSpeed` 0,3 e' il parametro), `TQ3FloatMath` |
| `R_GetTag`, `R_LerpTag` | `TQ3TagLerper` (`IQ3TagLerper`) |
| `CG_PositionEntityOnTag`, `CG_PositionRotatedEntityOnTag` | `TQ3TagPositioner` (`IQ3TagPositioner`) |
| la composizione di `CG_Player` (busto su `tag_torso` delle gambe, testa su `tag_head` del busto) e l'arma su `tag_weapon` | `TQ3PlayerAssembler` (`IQ3PlayerAssembler`) |

`TQ3PlayerFactory` e' il punto di composizione. **Riuso**: `TIdVec3` (`Libs\IdLib`), `TPatchVertexMath.Normalize` e `Dot` (`Libs\MathCore`, il `VectorNormalize` di `q_math.c` gia' portato dalla #117 con la stessa aritmetica `float` passo per passo), `TStaticNumbers.Atoi/Atof` (di 2d: `atoi`/`atof` del C), `ILog` (`Libs\Logging`) per gli avvisi, `IMd3Model` e `TMd3Reader` per i tag. Nuovi solo i tipi del gioco (`TQ3Animation`, `TQ3LerpFrame`, `TQ3Orientation`, `TQ3Entity`), perche' `TIdAngles`/`TIdMat3` (Doom 3) hanno un'altra convenzione degli assi e un'altra aritmetica e qui serve il C di Quake III bit per bit: `AnglesToAxis` e `MatrixMultiply` sono quelli di `q_math.c`.

**Parita'** con il C: `Tools\Verifica\126` compila con il gcc di w64devkit (SSE, un'operazione `float` alla volta) le **funzioni vere** (intervalli di righe dei sorgenti, `q_shared.c` intero) con stub minimi; `Tests\Data\Models\q3player\q3player.golden.txt` (567 righe) ha 7 file `.cfg` scritti per i test (le 37 animazioni di ciascuno e gli avvisi), cinque percorsi a seme fisso (200 passi di `CG_PlayerAngles` + `CG_PlayerAnimation` con tempi irregolari, pause, cambi di animazione con il bit di alternanza, fretta, morte, dolore, `fixedlegs`/`fixedtorso`; gli ultimi due finiscono con i due `CG_Error`), 100 `R_LerpTag` e 100 posizionamenti sui tag di `tags.md3` (6 fotogrammi, 4 tag, assi non unitari, fotogrammi oltre l'ultimo, tag mancanti, nomi con altra maiuscola). Interi, parole e avvisi **identici**; i `float` entro **4 ULP o 1e-6 assoluto** (a Win32 le espressioni restano nei registri x87 e `sin`/`cos` vengono da due librerie; il massimo visto sui valori da 0,1 in su e' 16 ULP, che e' l'errore assoluto di 1e-6). Gli angoli arrotondati da `AngleMod` coincidono sempre (i passi di 360/65536 non hanno mai cambiato lato). **Win64**: compila e i 72 test nuovi passano (SSE come il C); nella suite a 64 bit restano due rossi che non sono di questa fetta: `md2.merges` (noto) e `StaticParity` "due oggetti ase separati" (`two_objects.ase.nomerge s1: vertexes`, 16 attesi e 26 letti; non confrontato con la base).

**Differenze volute** (ognuna con un test): (1) `CG_ParseAnimationFile` **non esce mai** dal ciclo dei parametri opzionali se il file finisce prima del primo numero (il suo controllo `if (!token)` e' su un puntatore che `COM_Parse` non da' mai nullo): qui `EQ3PlayerException` con la riga; (2) un file mancante o vuoto e' `EQ3AnimationMissingException` (il C ritorna `qfalse` in silenzio), uno troppo lungo (19999 byte) o con animazioni mancanti e' `EQ3PlayerException` con lo stesso messaggio che il C scrive; (3) `AngleSubtract` con un angolo di 2^31 o piu' non finirebbe mai (`a -= 360` non cambia `a`): eccezione; con NaN restituisce NaN come il C; (4) `R_GetTag` con un fotogramma negativo legge prima dei tag: eccezione; (5) `CG_PlayerAnimation` con `cg_noPlayerAnims` lascia i `backlerp` non scritti: qui 0; (6) un numero di animazione fuori da 0..36 e' `EQ3PlayerException` (`CG_Error`), come una direzione di movimento fuori da 0..7 (a meno che il corpo sia morto).
**Difetti del C conservati**: `1000 / fps` e' una divisione `float` troncata (18,5 fps danno 54 ms) e una frequenza negativa da' un periodo negativo; una frequenza sopra i 1000 fotogrammi al secondo da' periodo 0 e `CG_RunLerpFrame` torna subito (l'animazione si ferma: "shouldn't happen"); le animazioni `LEGS_BACKCR` e `LEGS_BACKWALK` copiano anche `flipflop`; `flipflop` non e' mai acceso (le righe sono commentate nell'originale) ma e' portato; la normalizzazione dei tag lascia a zero un asse nullo; un tag mancante lascia l'entita' sull'origine del genitore.
**Non portato** (resta nella #126 e nelle altre della #115): il lettore dei `.skin` e la ricerca dei file del modello (`CG_RegisterClientModel`, `CG_FindClientModelFile`, `CG_RegisterClientSkin`), i suoni e le icone, `CG_Player` fuori dall'assemblaggio (ombra, sprite, polvere, acqua, `CG_AddRefEntityWithPowerups`, il teschio e i token di Team Arena), `CG_PlayerFlag`, `CG_AddPlayerWeapon` (solo il posizionamento sul tag), `CG_ResetPlayerEntity` (c'e' `Clear` per i due livelli), l'interpolazione dei vertici di un fotogramma di MD3 (c'e' gia' `IMd3Model.Instantiate`) e i formati MDR/MD4. **Non verificato**: la prova sui modelli dei giocatori di OpenArena (`pak2-players*.pk3`) non e' stata fatta (la richiesta della #126 e' lasciata aperta: servono il lettore del PK3 e dei `.skin`, e i dati non possono stare nel repository); la parita' a 64 bit e' solo di compilazione e dei test a mano.
Test: `DelphiDoom.Tests.Models.Q3PlayerParity` (7), `Q3PlayerValues` (65: lettore di parole, aritmetica, parser, corsie di animazione, tag, posizionamento, assemblaggio, angoli); suite di `Tests.Models` 406; copertura delle 14 unit nuove 96-100%.

### 2f. Normali, tangenti, deform info e finitura delle superfici (issue #104 e #105)

Unit `DelphiDoom.Models.Static.*` e `Md5.SurfaceBuilder`, **derivate da Doom 3** (GPL v3 con i termini aggiuntivi, intestazione come in `Libs\IdLib`): il pezzo di `tr_trisurf.cpp` che mancava a MD5 (normali e tangenti dei vertici) e ai modelli statici (`FinishSurfaces`).

| Unit | Ruolo (C++ di origine) |
|---|---|
| `Static.Deform.Types` | `TStaticDominantTri` (`dominantTri_s`), `TStaticDeformInfo` (`deformInfo_t`: indici, `silIndexes`, vertici specchiati, coppie `dupVerts`, triangoli dominanti) |
| `Static.DeformBuilder` | `R_BuildDeformInfo` (`R_CreateSilRemap` con `TIdHashIndex`, `R_CreateSilIndexes`, `R_DuplicateMirroredVertexes`, `R_CreateDupVerts`, `R_BuildDominantTris`, `R_RangeCheckIndexes`) |
| `Static.TangentDeriver` | `R_DeriveFacePlanes`, `R_DeriveTangents`, `R_DeriveTangentsWithoutNormals`, `R_DeriveUnsmoothedTangents` e le funzioni di `idSIMD_Generic` che usano (`DeriveTriPlanes`, `DeriveTangents` con il bit del segno, `DeriveUnsmoothedTangents`, `NormalizeTangents`); `idMath::RSqrt` come nel motore |
| `Static.SurfaceFinisher` | `R_CleanupTriangles` (senza bordi di silhouette: triangoli degeneri tolti sui `silIndexes`, vertici specchiati, `dupVerts`, tangenti lisce, non levigate o senza normali), `R_ReverseTriangles` |
| `Static.ModelFinisher`, `Static.MaterialInfo.Intf` | `idRenderModelStatic::FinishSurfaces` (copia al rovescio per i materiali a due facce, pulizia di ogni superficie, bounds): `IStaticMaterialInfo` risponde per `ShouldCreateBackSides` e `UseUnsmoothedTangents` (i materiali sono nomi); `TStaticMaterialInfoNone` e' il default |
| `Static.DefaultModel` | `AddCubeFace` e `MakeDefaultModel` (il cubo di mezzo lato 8 con normali generate), e il modello vuoto di `_BEAM` e `_SPRITE` |
| `Md5.SurfaceBuilder` | `idMD5Mesh::ParseMesh` (la deform info sui vertici della posa del file) e `UpdateSurface` (posizioni dai pesi, anche con la scala della pelle, vertici della cucitura copiati, `R_DeriveTangents`); il materiale e' il nome dello shader del mesh |

`USE_INVA` e `DERIVE_UNSMOOTHED_BITANGENT` sono definiti in `tr_trisurf.cpp`: le tangenti delle facce sono moltiplicate per il segno dell'area e il bitangente non levigato e' ortogonalizzato con la normale, come nel C++. **Parita'** con le funzioni vere di `tr_trisurf.cpp` e `Simd_Generic.cpp` (estratte per intervallo di righe, `Tests\Data\Models\deform\harness`, compilate con `bcc32c` su stub del renderer; `deform.golden.txt`, 106 righe): tre mesh scritte per i test (una striscia con una cucitura specchiata, un vertice con la stessa posizione e un triangolo degenere; un cubo di 8 vertici; una griglia) con posizioni perturbate da un generatore fisso (con aree uguali l'ordine di `qsort` dei triangoli di un vertice non e' definito: nei dati non ce ne sono), piu' il cubo di default; deform info (conteggi, vertici specchiati, coppie, indici, `silIndexes`, triangoli dominanti), piani, tangenti con e senza normali, `R_CleanupTriangles` nelle quattro combinazioni: interi identici, `float` entro 2 ULP o 4e-6 relativo o 1e-5 assoluto (zero differenze).
**Non portato**: i bordi di silhouette (`R_IdentifySilEdges`, `silEdges`: servono ai volumi d'ombra), le cache dei vertici, le aree dei materiali, i bounds piu' larghi dei materiali con `deform`, il codice SIMD (`asm`) e la scelta `r_useDeferredTangents`. **Differenza**: nel C++ con triangoli di area uguale per un vertice `qsort` decide (non stabile); qui si prende l'ordine in cui compaiono. Test: `DeformParity` (3), `Md5Surface` (13), `Manager` (`TTestSurfaceFinisher`, 15).

### 2g. Animazioni e MODELDEF (issue #104)

`DelphiDoom.Models.Anim.*`, **derivate da Doom 3** (`game\anim\Anim.cpp`, `Anim_Blend.cpp`, `Anim.h`). Percorso freddo: le dipendenze del gioco (funzioni di script, eventi, skin, fx, entityDef, suoni) sono un'interfaccia iniettata, il file system e' `IModelFileSource` (`Source.Intf`, un solo metodo `ReadFile(nome, dati, data)`: l'adattatore sul file system del motore, #99, lo fa un altro lavoro).

| Unit | Ruolo (C++ di origine) |
|---|---|
| `Anim.Types`, `Anim.Intf` | canali, `TAnimFrameCommandType` (`frameCommandType_t`), `TAnimFlags`, `TAnimJointInfo`; `IAnimManager`, `IAnim`, `IModelDef`, `IModelDefSource`, `IModelDefParser`, `IModelDefGameLookup` |
| `Anim.Manager` | `idAnimManager`: cache degli `.md5anim` per nome (un fallimento si ricorda e non si ripete), `JointIndex`/`JointName`, contatori di riferimenti e `FlushUnusedAnims`, `ReloadAnims`, `CheckModelHierarchy` |
| `Anim.Anim` | `idAnim`: le md5anim sincronizzate, i nomi, le flag e i comandi dei fotogrammi con la stessa tabella `frameLookup`/`frameCommands` di `AddFrameCommand`; `Clone` (il costruttore di copia) |
| `Anim.ModelDef`, `Anim.ModelDefParser`, `Anim.FrameCommandParser` | `idDeclModelDef` (giunti con canali, `FindJoint`, `GetJointList` con `-` e `*`, `GetAnim` con anim a caso, `SetupJoints`) e `Parse`/`ParseAnim` (`inherit`, `skin`, `mesh`, `remove`, `anim` con flag e `frame N comando`, `offset`, `channel`), i 40 comandi dei fotogrammi di `AddFrameCommand` |
| `Anim.PermissiveLookup`, `Anim.Factory` | la lookup che accetta tutto (senza gioco), il punto di composizione |

Un errore di una definizione e' un avviso nel log e il risultato e' la definizione "di default" vuota (`MakeDefault`, `Defaulted` True); un'anim con giunti diversi dal modello e' `EAnimException` (`gameLocal.Error`). **Differenze volute**: gli md5anim non si aggiornano sul posto con `ReloadAnims` (le interfacce sono immutabili: la tabella prende l'oggetto nuovo e chi ha quello vecchio lo tiene); lo `skin` e' un nome (la verifica e' della lookup); l'`GetJoint` di C++ accetta `jointHandle == Num()` (qui e' un errore); un nome di animazione di un solo carattere piu' cifre (`a1`) e' non valido anche nel C++ (il ciclo si ferma a `i = 0`). **Non portato**: tutto `Anim_Blend.cpp` oltre la definizione (`idAnimBlend`, `idAnimator`, `idDeclModelDef::Touch` e il disegno), le anim `ik_*` e `idAnimator::CreateFrame`. **Parita'**: `idDeclModelDef::Parse` dipende dall'intero gioco (`gameLocal`, `declManager`) e non si compila da solo: i test (`Models.Anim`: gestore delle anim, `idAnim`, comandi dei fotogrammi, parser; copertura 93-100%) sono scritti sul testo del C++ riga per riga, con un cubo a due giunti (`Tests\Data\Models\md5`) e finti per file e gioco.

### 2h. Maya ASCII (MA) e gestore dei modelli (issue #105)

`Static.Ma.*`, **derivate da Doom 3** (`Model_ma.cpp`, `Model.cpp`): `TMaParser` (`MA_Parse` sopra `TIdParser` di `Libs\Scanner`, con `LEXFL_NOSTRINGCONCAT`: trasformazioni annidate, mesh con vertici, bordi, normali, facce `f`/`mu`/`mf`/`fc`, colori, coordinate di texture, vertici `pt`, nodi `file` e di materiale, `connectAttr`; assi Y/Z scambiati; le trasformazioni dei genitori applicate ai vertici nello stesso ordine di `MA_ApplyTransformation`), `TMaConverter` (`ConvertMAToModelSurfaces`: una superficie per materiale, saldatura di posizioni, texture, colori e normali; **il colore di un vertice senza colore e' l'ultimo letto**, come nel C++), `TMaModelLoader` (`MA_Load`; gli errori del lexer sono `EStaticModelException`), `TStaticModelFactory.CreateMaLoader` e il `.ma` in `CreateLoaderFor`. Gli errori di formato sono i messaggi del C++ (`Maya Loader '%s': ...`). **Parita'** con `Model_ma.cpp` vero e `ConvertMAToModelSurfaces` compilati con `bcc32c` (`Tests\Data\Models\ma\harness`; `idParser`, `idLexer`, `idStr`, `idHashTable` veri, due correzioni di sintassi alle copie di `HashTable.h` e `Parser.cpp` per clang: `numItems` non dichiarato e l'indice sul token di `__DATE__`): 3 file scritti per i test (un quad con normali condivise, colori, texture, trasformazione e catena materiale-file; due triangoli sotto due trasformazioni annidate con `pt`, `mf` e due reti di shading sulla stessa immagine; un triangolo semplice) letti e convertiti con unione, senza unione e `fastLoad`, e 4 file con un errore: **identici** (float entro 2 ULP o 4e-6). **Differenze**: gli indici fuori intervallo (che nel C++ sono memoria fuori dai vettori) sono `EStaticModelException`; gli array non scritti dal file partono a zero (il C++ non li inizializza: `tVertexNum` senza `mu`/`mf`); un modello senza oggetti e' vuoto come nel C++ (il risultato della conversione e' ignorato); il materiale e' un nome (`OSPathToRelativePath` e' il `TStaticPathResolver` iniettato); `timeStamp` non e' nel modello statico.

`Manager.*` (**derivate** da `ModelManager.cpp` e `Model.cpp`; in sola logica, senza renderer): `IRenderModelManager` (`TRenderModelManager`: `Init` con i modelli `_DEFAULT`, `_BEAM`, `_SPRITE`; `FindModel`/`CheckModel` con il confronto senza maiuscole e l'ultimo modello aggiunto per primo; un nome di tipo sconosciuto da' il modello di default e l'avviso `unknown model type`; `AddModel`/`RemoveModel`/`FreeModel` con i tre modelli di base protetti; `ReloadModels` sui tempi dei file; `BeginLevelLoad`/`EndLevelLoad` con purghe e ricarichi), `IRenderModelLoaderTable` (`TRenderModelLoaderTable`: **il caricatore per estensione**; `TRenderModelManagerFactory.CreateStandardLoaders` registra `ase`, `lwo`, `ma`, `md3` e `md5mesh`), `TStaticRenderModelLoader` (file dall'`IModelFileSource`, formato dall'estensione, finitura di 2f; un file mancante o rotto da' il cubo di default e `Couldn't load model`), `TMd5RenderModelLoader` (un md5mesh rotto e' un modello "di default": il C++ in quel caso si ferma con un errore fatale), `TRenderModelDefSource` (`IModelDefSource` per il parser di MODELDEF: i modelli dal gestore, le definizioni da ereditare da un cercatore iniettato), `TRenderModel`. **Non portato**: `flt`, `prt`, `liquid`, `beam` e `sprite` come modelli disegnabili (si registrano con `Register` da chi ha il renderer), i comandi della console, `WritePrecacheCommands`, la memoria, `R_CheckForEntityDefsUsingModel`. Test: `Models.StaticMa` (22), `Models.Manager` (43, con `TTestSurfaceFinisher` di 2f). Suite `DelphiDoom.Tests.Models`: 593 test (406 prima di questo lavoro), copertura delle 25 unit nuove 98% (da 90% a 100% ognuna). **Win64**: compila e 592 passano su 593; resta `md2.merges` (MD2, non di questo lavoro).
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
