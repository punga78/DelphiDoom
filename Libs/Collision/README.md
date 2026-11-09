# Libs\Collision — il modello di collisione di Doom 3 (id Tech 4) in Delphi

> Note per Claude e paragrafi di dettaglio (issue #178): [CLAUDE.md](CLAUDE.md).

Port a classi di `Reference\doom3\neo\cm` (`CollisionModel_*.cpp`, `CollisionModel.h`, `CollisionModel_local.h`),
con la matematica e la geometria di idlib in `Libs\Geometry`. **Non è collegato al motore**: DelphiDoom è un source
port di id Tech 1 e il modello di id Tech 4 non ha un chiamante in Doom, Heretic, Hexen e Strife
(vedi `WIRING.md` per come lo userebbe un chiamante).

## Licenza

Doom 3 è sotto **GPL v3 con termini aggiuntivi** (`Reference\doom3\COPYING.txt`, `README.txt`); il repository è
GPL v2 o successiva. Le unit di `Libs\Geometry` e `Libs\Collision` sono **codice derivato** (traduzione del
comportamento e della struttura del C++, non riscrittura da zero): portano l'intestazione di copyright di id Software
e la dicitura "GPL v3". L'opera che le contiene, quando le si compila insieme, ricade quindi nella GPL v3.
Fa eccezione `DelphiDoom.Collision.CmFile.Tokenizer`, scritto da zero a partire dal solo comportamento di `idLexer`
(è l'unico pezzo non derivato). Nessun sorgente C++ di Doom 3 è copiato nel repository, nemmeno nei test.

## Analisi del C++

### Cosa c'è in `neo\cm` (9300 righe)

| File | Righe | Contenuto | Port |
|---|---|---|---|
| `CollisionModel.h` | 150 | contratto `idCollisionModelManager`, `trace_t`, `contactInfo_t`, costanti | `Collision.Intf`, `Collision.Types` |
| `CollisionModel_local.h` | 530 | strutture `cm_*` (vertici, spigoli, poligoni, brush, nodi, modello), `cm_traceWork_t`, la classe locale | `Collision.Model.*`, `Collision.TraceWork`, `Collision.Manager` |
| `CollisionModel_load.cpp` | 3700 | costruzione da mappa e modelli, BSP assiale, hash di vertici e spigoli, fusione dei poligoni, spigoli interni, proc BSP, patch, ASE/LWO | in parte (vedi sotto) |
| `CollisionModel_translate.cpp` | 1120 | traslazione di un trace model (coordinate di Plücker) | `Collision.Translator`, `Collision.TranslationRunner` |
| `CollisionModel_trace.cpp` | 260 | discesa nel BSP assiale lungo la traccia | `Collision.Tracer` |
| `CollisionModel_contents.cpp` | 640 | test di posizione, contenuto di un punto | `Collision.ContentsTester`, `Collision.ContentsRunner` |
| `CollisionModel_contacts.cpp` | 75 | tutti i contatti di una traslazione | `Collision.Manager.Contacts` |
| `CollisionModel_files.cpp` | 620 | lettura e scrittura del formato `.cm` | `Collision.CmFile.*` |
| `CollisionModel_rotate.cpp` | 1700 | rotazione di un trace model | **non portato** |
| `CollisionModel_debug.cpp` | 490 | disegno, `cm_contentsNameByIndex`, cvar | solo i nomi dei contenuti (`Collision.ContentsNames`) |

### Grafo delle dipendenze

```
idCollisionModelManagerLocal
 ├─ idlib math      idVec3, idMat3, idPlane, idBounds, idPluecker, idRotation, idMath
 ├─ idlib geometry  idWinding (idFixedWinding), idTraceModel, idSurface_Patch
 ├─ idlib other     idHashIndex, idList, idStr, idLexer, idToken, idFile, Mem_Alloc, idBlockAlloc
 └─ motore          idMapFile/idMapEntity/idMapBrush/idMapPatch   (sorgente della geometria: mappa)
                    idMaterial + declManager                     (contenuti, nome, cull type)
                    idRenderModel + renderModelManager           (modelli ASE/LWO)
                    fileSystem                                   (apertura dei .cm e dei .proc)
                    common (Printf/Warning/Error), cvarSystem    (log, cvar di debug)
                    session->rw (DebugArrow), renderWorld        (disegno)
```

### Cosa è puro e cosa è legato al motore

Puro (portato così com'è): vettori, matrici, piani, box, Plücker, winding, trace model, hash index, il modello
(vertici, spigoli, poligoni, brush, nodi), la costruzione dal modello poligonale, il BSP assiale, le normali degli
spigoli, traslazione, tracciamento, test di posizione, contatti, formato `.cm`.

Legato al resto di id Tech 4, sostituito da una interfaccia o da un tipo piccolo:

| C++ | Delphi |
|---|---|
| `idMaterial` (`GetContentFlags`, `GetName`, `GetCullType`, `ShouldCreateBackSides`) + `declManager->FindMaterial` | `TCollisionMaterial` (nome, contenuti, due facce) + `ICollisionMaterialCatalog` |
| `idMapEntity`/`idMapBrush`/`idMapBrushSide` | `ICollisionGeometrySource` (brush con lati e poligoni sciolti) |
| `common->Printf/Warning` | `ILog` di `Libs\Logging` (può essere nil) |
| `common->Error`/`src->Error` | `ECollisionFormatException` (`ECollisionException`) |
| `fileSystem->OpenFile*`, `idLexer(fileName)` | `TStream`/`string` dati dal chiamante; `TCollisionTokenizer` |
| globali e statici (`checkCount`, `cm_vertexHash`, `cm_edgeHash`, `cm_modelBounds`, `static cm_traceWork_t tw`, `getContacts`, `contacts`) | `TCollisionCheckCounter`, `TCollisionGeometryTable`, `TCmTraceWork` (uno per chiamata), parametri e liste |
| `idCollisionModelManagerLocal::models[]` e `MAX_SUBMODELS` | `TObjectList` nel manager; `TRACE_MODEL_HANDLE` per lo slot del trace model |
| `cvarSystem` (`cm_debugCollision`, `cm_draw*`) | non portato (solo debug) |

## Fette e unit

**`Libs\Geometry`** (namespace `DelphiDoom.Geometry.*`): `Types` (costanti `PLANESIDE_*`, `PLANETYPE_*`, `MAX_WORLD_*`),
`FloatMath` (`TGeoMath`: `Rint` come `floorf(f+0.5f)`, macro del bit di segno, `1<<n` a 32 bit), `Vec3`, `Mat3`, `Plane`,
`Bounds`, `Pluecker` (record, con gli stessi byte del C++), `Winding` (classe: `BaseForPlane`, `ClipInPlace`,
`ReverseSelf`, `IsHuge`), `TraceModel` (box, cilindro, poligono e suo volume, normali degli spigoli). In `Libs\MathCore`
non c'era nulla di riusabile: `TVec3` di `m_vectors` è un `array[0..2] of Single` senza operatori, per il motore a punto
fisso.

**`Libs\Collision`** (namespace `DelphiDoom.Collision.*`), una classe per unit:

| Fetta | Unit |
|---|---|
| 1. tipi e contratti | `Types`, `Intf`, `Factory` |
| 2. modello e costruzione | `Model.Types` (`TCmVertex`, `TCmEdge`), `Model.Polygon`, `Model.Brush`, `Model.Node`, `Model`, `HashIndex`, `Builder.Table` (`GetVertex`/`GetEdge`), `Builder.Bsp` (BSP assiale), `Builder.EdgeNormals`, `Builder.Optimizer`, `Builder` |
| 3. tracce, contatti | `CheckCounter`, `Sidedness`, `TraceWork`, `Translator`, `ContentsTester`, `Tracer`, `ContentsRunner`, `TranslationRunner`, `TrmModel` (`SetupTrmModel`), `TrmExtractor` (`TrmFromModel`), `Manager` |
| 4. formato `.cm` | `ContentsNames`, `CmFile.Tokenizer`, `CmFile.Writer`, `CmFile.Reader` |

(`CmFile` e non `File` perché `file` è una parola riservata di Delphi e non può essere un segmento del nome di una unit.)

### Mappa C++ → Delphi

| C++ | Delphi |
|---|---|
| `idCollisionModelManagerLocal::Translation` | `TCollisionTranslationRunner.Translate` (via `ICollisionModelManager.Translation`) |
| `TranslateTrmThroughPolygon`, `TranslateTrmEdge/Vertex/PointThroughPolygon`, `TranslateVertexThroughTrmPolygon`, `TranslateEdgeThroughEdge`, `CM_TranslationPlaneFraction` | `TCollisionTranslator` |
| `SetupTrm`, `SetupTranslationHeartPlanes` | `TCmTraceWork.SetupTrm`, `.SetupTranslationHeartPlanes` |
| `TraceTrmThroughNode`, `TraceThroughAxialBSPTree_r`, `TraceThroughModel` | `TCollisionTracer` |
| `TestTrmVertsInBrush`, `TestTrmInPolygon` | `TCollisionContentsTester` |
| `PointNode`, `PointContents`, `TransformedPointContents`, `ContentsTrm` | `TCollisionContentsRunner` |
| `CM_SetVertexSidedness`, `CM_SetEdgeSidedness`, `CM_SetTrmEdgeSidedness`, `CM_SetTrmPolygonSidedness` | `TCollisionSidedness` |
| `Contacts` | `TCollisionModelManager.Contacts` |
| `GetVertex`, `GetEdge`, `HashVec`, `ClearHash` | `TCollisionGeometryTable` |
| `CM_FindSplitter`, `R_FilterPolygonIntoTree`, `R_FilterBrushIntoTree`, `R_CreateAxialBSPTree`, `CreateAxialBSPTree` | `TCollisionBspBuilder` |
| `CalculateEdgeNormals` | `TCollisionEdgeNormals.Calculate` |
| `RemapEdges`, `OptimizeArrays` | `TCollisionArrayOptimizer.Optimize` |
| `ConvertBrush`, `ConvertBrushSides`, `PolygonFromWinding`, `CreatePolygon`, `FinishModel`, `CollisionModelForMapEntity` | `TCollisionModelBuilder` |
| `SetupTrmModelStructure`, `SetupTrmModel` | `TCollisionTrmModelSlot` |
| `TrmFromModel_r`, `TrmFromModel` | `TCollisionTrmExtractor` |
| `AllocModel`, `Alloc*`, `AddPolygonToNode`, `AddBrushToNode`, `CM_GetNodeBounds`, `CM_GetNodeContents` | `TCollisionModel` |
| `WriteCollisionModel`, `WriteNodes/Polygons/Brushes`, `FS_WriteFloatString` | `TCollisionFileWriter` |
| `ParseCollisionModel` e `Parse*`, `LoadCollisionModelFile` | `TCollisionFileReader` |
| `ContentsFromString`, `StringFromContents` | `TCollisionContentsNames` |
| `GetModelName/Bounds/Contents/Vertex/Edge/Polygon`, `FindModel`, `FreeMap` | `TCollisionModelManager` |

### Portato e non portato

**Non portato, con il motivo**

- **Rotazione** (`CollisionModel_rotate.cpp`, 1700 righe, più `idRotation`, `Rotation180`, `BoundsForRotation`): è la parte
  più lunga e delicata del modulo e richiede `idRotation` e le matrici ausiliarie di idlib. Nessun chiamante da servire.
  La struttura lascia spazio: `TCmTraceWork` non ha i campi della rotazione, `TraceTrmThroughNode` non ha il ramo.
- **Patch** (`CreatePatchPolygons`, `ConvertPatch`, `idSurface_Patch`): serve la suddivisione delle superfici di Bézier
  (`Surface_Patch.cpp`). Una patch si può dare al builder già triangolata come poligoni sciolti.
- **Poligoni scartati perché dentro i brush o tagliati dal proc BSP** (`WindingOutsideBrushes`, `ChopWindingListWithBrush`,
  `ChoppedAwayByProcBSP`, `LoadProcBSP`): ottimizzazione che toglie poligoni invisibili. Senza di essa il modello ha
  poligoni in più ma le risposte restano giuste (un poligono dentro un brush è raggiunto solo dopo averne attraversato
  il bordo).
- **Fusione dei poligoni complanari** (`MergeTreePolygons`, `TryMergePolygons`) e **spigoli interni**
  (`FindInternalEdges`): **limite reale**. Una mesh di poligoni complanari adiacenti (un pavimento fatto di due
  triangoli) senza gli spigoli interni marcati può dare urti spuri di un trace model con lo spigolo in comune. I modelli
  fatti di brush (scatole, convessi) non ne sono toccati: gli spigoli tra lati di un brush non sono interni.
- Caricamento da modello di rendering (`LoadRenderModel`, ASE/LWO) e da mappa (`idMapFile`): la sorgente è
  `ICollisionGeometrySource`; un adattatore sta nel chiamante.
- Disegno e debug (`DrawModel`, `DebugOutput`, `ModelInfo`, `ListModels`, cvar `cm_*`), `WriteCollisionModelForMapEntity`
  (il file system è del chiamante), `idTraceModel` ottaedro, dodecaedro, cono, osso, `Rotate`, `Shrink`, proprietà di massa.

**Portato**: tutto il resto di `translate`, `trace`, `contents`, `contacts`, `files` e la parte del `load` che parte da
brush e poligoni (hash di vertici e spigoli, `CreatePolygon`, BSP assiale, normali degli spigoli, compattazione degli
array, `SetupTrmModel`, `TrmFromModel`).

## Decisioni di proprietà e traduzione

- **Memoria a pool** (`cm_nodeBlock_t`, `cm_polygonRefBlock_t`, `cm_brushBlock_t`, `Mem_Alloc`, struct a coda variabile
  `edges[1]`/`planes[1]`): sostituita da liste di oggetti posseduti dal modello (`TObjectList`); i polygon e brush hanno
  array dinamici. `TCollisionModel` possiede ogni nodo, poligono e brush: liberare il modello libera tutto.
- **Catene di riferimenti** (`cm_polygonRef_t`/`cm_brushRef_t`): `TList` con l'indice 0 in testa alla catena e inserimento
  in testa, per conservare l'ordine di visita del C++ (conta per i pareggi di frazione). Costo: l'inserimento è O(n).
- **`checkcount`**: un `TCollisionCheckCounter` condiviso dal manager, non un globale. `AddModel` azzera i `checkcount`
  dei modelli che riceve (un modello costruito o letto altrove potrebbe avere valori uguali a quelli del contatore).
  Dove il C++ usava `checkcount` solo per non visitare due volte un poligono nella costruzione, il Delphi usa
  l'insieme dei già visti (`TreePolygons`).
- **Indirizzo come numero** (`contact.modelFeature = *(int*)&poly`): il poligono ha un `Id` progressivo del modello;
  `GetModelPolygon(handle, id)` lo risolve. È valido anche a 64 bit.
- **Proprietà**: il manager possiede i modelli (`AddModel` li prende) e lo slot del trace model; il catalogo possiede i
  materiali e deve vivere quanto i modelli; i `TTraceModel` sono del chiamante; `Build` dà un modello che il chiamante
  possiede (o passa a `AddModel`). `TInterfacedObject` solo per `ICollisionModelManager` e per il catalogo.
- **Una traccia alla volta**: come il C++ (che ha un `tw` statico), un manager non è thread safe; ogni chiamata ha però il
  suo `TCmTraceWork`, quindi niente stato nascosto tra due chiamate.

## Verifica e parità

**Un compilatore C++ c'è**: non `cl`, `g++` o `clang` nel PATH, ma `bcc32c.exe` (clang di RAD Studio 11, `Studio\22.0\bin`)
compila e collega. Con un `precompiled.h` finto (le sole definizioni di motore che servono: `idCommon`, `idSys`,
`idRenderWorld`, `idSession`, `idCVar`, `netadr_t`, le macro di `sys_public.h`) si compilano **i sorgenti veri**
`CollisionModel_translate.cpp`, `_trace.cpp`, `_contents.cpp`, `_contacts.cpp` e la idlib vera (`math`, `bv`, `geometry`,
`Str`, `Heap`, `Lib`, `Token`, `HashIndex`), senza modificarli. Non si compilano `_load.cpp` e `_files.cpp`
(servono mappa, materiali, file system) né `_rotate.cpp` (non portato): ne bastano dei vuoti per la vtable.

**Parità dimostrata sul codice di interrogazione** (traslazione, tracciamento nel BSP, test di posizione, contatti):
`Tests\Data\Collision\parity.golden.txt` contiene le risposte del C++ vero a 2800 interrogazioni (1200 traslazioni con
trace model a scatola o con un punto, 1000 test di posizione, 600 ricerche di contatti) su quattro modelli: una scatola,
otto scatole (con albero), cento scatole (albero profondo) e cinque scatole più un cuneo (piani non assiali). I modelli
sono **costruiti dalla libreria Delphi** (il costruttore C++ vuole tutto il motore) e passati al C++ con le normali degli
spigoli già calcolate, quindi **si confronta il codice delle query, non la costruzione del modello** (che è controllata da
test a mano e dall'oracolo qui sotto). Il test `Collision.Parity` confronta:

| Campo | Esito su 2800 interrogazioni (Win32 e Win64) |
|---|---|
| colpisce / non colpisce, frazione (tolleranza 5e-5), posizione finale, normale, contenuto del contatto (260 colpi) | **0 differenze** |
| `Contents` (1000 test di posizione) | **0 differenze** |
| numero di contatti (600 interrogazioni) | **0 differenze** |
| quale elemento è riportato quando più elementi si toccano nello stesso istante (tipo di contatto, punto, distanza, numeri di spigolo e di vertice) | **40 interrogazioni su 400 con contatto (10%)** riportano un altro elemento |

Le 40 differenze sono parità di *spareggio*: un lato del trace model parallelo a una faccia del modello tocca il piano con
tutti i suoi vertici e spigoli nello stesso istante, e il primo che abbassa `trace.fraction` vince per il rumore degli
ultimi bit (per esempio un vertice del trace model contro la faccia, nel Delphi, e uno spigolo contro lo spigolo del
modello, nel C++, con la stessa frazione e la stessa normale). Le frazioni degli spigoli, che dividono numeri che si
annullano, possono differire di qualche 1e-5 a 1000 unità (2 casi). Il test chiede **zero** differenze nei campi duri e al
massimo un quarto di interrogazioni con un altro elemento. **Non è parità bit a bit** (e a 64 bit il risultato è lo stesso
che a 32: non è x87 contro SSE).

**Come si rigenera il golden** (gli strumenti stanno fuori dal repository, in una cartella temporanea: `harness.cpp`,
`precompiled.h` finto, `gen.dpr`): (1) copiare `Reference\doom3\neo\idlib` e `neo\cm` in una cartella `T\` e sostituire
`T\idlib\precompiled.h` con quello finto; (2) `bcc32c -c -w -std=c++11 -I T` su `T\cm\CollisionModel_{translate,trace,contents,
contacts}.cpp`, su `harness.cpp` e sulla idlib elencata, poi `bcc32c obj\*.o -o harness.exe`; (3) `gen.exe`, un programma
Delphi che con `Libs\Collision` costruisce i modelli, scrive `parity.in.txt` (i brush e le interrogazioni, in
`Tests\Data\Collision`) e `harness_model.txt` (i modelli con tutti i campi); (4) `harness.exe harness_model.txt
harness_traces.txt parity.golden.txt` esegue `Translation`, `Contents` e `Contacts` del C++ vero e scrive le risposte
con `%.9g`. I numeri del `.in` hanno 9 cifre significative: i `float` si rileggono identici.

Gli altri test (`Tests\DelphiDoom.Tests.Collision`) verificano:

1. **valori calcolati a mano** dalla formula del C++ (frazione di una traccia contro una faccia, `(d1 − 0.25) / (d1 − d2)`,
   normale, distanza, punto di contatto, scatole ruotate e spostate, trace model contro trace model, contatti di una
   scatola su un pavimento, numerazione di vertici e spigoli di un triangolo derivata da `GetEdge`);
2. **un oracolo indipendente**: per scatole contro scatole il tracciamento ha una soluzione analitica (somma di Minkowski
   e metodo delle lastre). Per migliaia di tracce con seme fisso si controlla che la traccia non passi mai oltre il primo
   contatto vero, che non dia urti falsi quando il percorso resta lontano più di 0,6 dalle scatole (il margine del clip
   è 0,25), che la posizione finale sia fuori dal solido e che il piano di contatto guardi verso l'inizio; lo stesso
   oracolo per il test di posizione (`Contents`) con un trace model lungo e sottile (incrocia le scatole senza avere un
   vertice dentro); il tutto sia con pochi brush sia con un albero BSP. Un guasto inserito di proposito nella discesa
   del BSP viene preso da quattro test;
3. **invarianti**: ogni spigolo di un box è usato due volte, una per verso; la geometria del trace model; simmetria e
   segni di Plücker; il formato `.cm`: testo di un triangolo derivato a mano dallo scrittore C++ (anche come file in
   `Tests\Data\Collision`), lettura, riscrittura, round trip di un modello con albero (dopo due giri il testo è
   identico), stesso risultato delle query su modello originale e modello riletto, file rifiutati (non CM, versione,
   crc, token sbagliato), contenuti numerici dei vecchi file.

**Cosa manca per una parità completa**: la costruzione del modello da brush e poligoni (`ConvertBrush`, `CreatePolygon`,
`R_CreateAxialBSPTree`, `CalculateEdgeNormals`, `OptimizeArrays`) non è confrontata con il C++ (servirebbe compilare
`_load.cpp` con uno stub di `idMapFile`, `idMaterial`, `declManager`, `idSurface_Patch`, `idRenderModel`) né il file `.cm`
scritto dal C++ vero (`_files.cpp` con `idFile`/`fileSystem`); un trace model non a scatola (cilindro, poligono); le
patch, la fusione dei poligoni e gli spigoli interni, che non sono portati; la rotazione, non portata.

## Differenze volute dal C++ e `float`

- **`float` e `Single`**: i `float` sono `Single`. A 32 bit il compilatore Delphi valuta le espressioni su `Single` in
  precisione estesa (x87) e arrotonda alla memorizzazione, MSVC con SSE arrotonda a ogni operazione: i risultati possono
  differire di un'unità nell'ultimo bit. A 64 bit (SSE) le espressioni su `Single` sono in precisione singola. I test
  usano tolleranze (1e-4 sulle frazioni) e passano sia a Win32 sia a Win64.
- **`idMath::InvSqrt`** del C++ è una tabella più due passi di Newton con precisione a 32 bit; qui è `1/Sqrt(x)` in
  `Double` arrotondato. I vettori normalizzati possono differire di un'unità nell'ultimo bit; per questo non sono
  garantiti bit-identici.
- **`idMath::Rint`** è `floorf(f+0.5f)`, non il `rint` di C: 2,5 dà 3 (conservato, con test).
- **Statici e globali** (`tw`, `checkCount`, `cm_*`): campi di oggetti; il `trace` del trace work parte da zero (il C++
  lascia in `tw.trace` valori vecchi nei campi che non sono validi se `fraction == 1`).
- **Un modello fatto solo di poligoni ha l'indice hash sul box ±256** come nel C++ (nessun brush), la fusione e gli
  spigoli interni mancano (vedi sopra).
- **Ordine dei brush e dei poligoni**: il builder converte prima tutti i brush e poi i poligoni sciolti; nel C++ le
  primitive di una entity hanno un ordine misto (brush e patch alternati). Cambia solo l'ordine di visita.
- **Il file `.cm`** è scritto con fine riga `\n` (l'originale su Windows scrive `\r\n`; il lettore accetta entrambi) e
  testo UTF-8 senza BOM (i nomi sono ASCII in pratica). I numeri si scrivono con `%1.10f` privato degli zeri finali e
  del punto, come `FS_WriteFloatString`; valori molto piccoli perdono quindi precisione relativa, come nel C++.
  `polygonMemory` e `brushMemory` usano le dimensioni delle struct C++ a 32 bit, solo per rendere identico il testo.
- **`abs(float)` in `CM_FindSplitter`**: il C++ chiama `abs` su un `float`; qui è il valore assoluto in virgola mobile.
  Se il compilatore del C++ risolvesse `abs(int)`, la forma dell'albero (non il risultato delle query) potrebbe cambiare.
- **`ContentsTrm` con `getContacts`**: il C++ non lo inizializza (statico); qui è sempre falso.
- **Difetti del C++ non copiati**: nessuno che cambi il comportamento osservabile; l'`assert` sulla sovrapposizione di
  `results` e degli argomenti, e il blocco `_DEBUG` con `cm_debugCollision`, non sono portati.

## Cosa resta da collegare

Un chiamante: vedi `WIRING.md`. Da fare se un domani serve: rotazione, patch, fusione dei poligoni e spigoli interni,
rimozione dei poligoni interni ai brush, adattatore da `idMapFile`/mappa di Doom a `ICollisionGeometrySource`,
un `ICollisionDebugDraw` per `DrawModel`.
