# IdTech4\Aas

Port a classi dell'**AAS di Quake III Arena** (Area Awareness System di `code\botlib`, GPL v2 o successiva, id Software), issue #122 (parte di #115, indice id Tech 3). **Prima fetta**: il file `.aas` in sola lettura e il campionamento che non dipende dal gioco (`aasfile.h`, `be_aas_file.c`, `be_aas_sample.c`); **seconda fetta**: il routing (`be_aas_route.c`, `be_aas_routealt.c`, sezione \"Routing di Quake III\" sotto). **In questa libreria sta anche la navigazione AAS di Doom 3** (issue #109, `DelphiDoom.Aas.D3.*`, sezione \"Navigazione AAS di Doom 3 a runtime\"). La libreria non ha chiamanti nel motore (percorso freddo). Intestazione di ogni unit: "Based on the Quake III Arena GPL Source Code (id Software)", GPL v2 o successiva.

**Non e' l'AAS di Doom 3.** `IdTech4\MapFile` (`DelphiDoom.MapFile.Aas.*`, #107) legge il formato di id Tech 4: testo (`DewmAAS`, versione `1.07`, numeri come token), non c'e' nulla di uguale al formato di Quake III (binario, identificatore `EASS`, versione 5, 14 lump di record `packed`). Non c'e' nulla da riusare di quella libreria e nessuna interfaccia comune e' stata forzata: i concetti uguali (area di un punto, tempo di viaggio) hanno ora le due implementazioni (`IAasRouter` per Quake III, `IAasNavigator` per Doom 3) con firme che seguono ognuna il suo originale: i tipi di travel flag, di raggiungibilita' (record contro classe, indici contro riferimenti) e di tempo (arrotondamento a `FtoiFast` contro troncamento, minimo 1) differiscono abbastanza da non meritare una interfaccia comune.

## Uso

```pascal
LReader := TAasFactory.CreateReader(Import, Files, LibVars);  // Import: IBotImport, Files: IBotFileSource, LibVars: IBotLibVars
if LReader.Load('maps/q3dm1.aas', LFile) = BLERR_NOERROR then  // legge, controlla identificatore, versione, checksum del BSP
begin
  LSampler := TAasFactory.CreateSampler(LFile, Import);        // IAasSampler: punto -> area
  LTracer := TAasFactory.CreateTracer(LFile, Import);          // IAasTracer: TraceAreas, TraceClientBBox
  LArea := LSampler.PointAreaNum(Origin);
end;
```

Verso il gioco e verso il file system solo interfacce **gia' esistenti in `IdTech4\BotAi`** (`DelphiDoom.BotAi.Import.Intf`: `IBotImport` = `botimport.Print`, `IBotFileSource` = `botimport.FS_*`, `IBotLibVars` = `LibVarGetString("sv_mapChecksum")`; `DelphiDoom.BotAi.Types`: `PRT_*`, `BLERR_NOERROR`): nessuna interfaccia duplicata. `ParseBytes` legge un file gia' in memoria e solleva `EAasFileException` (con il codice `BLERR_*`). L'import e' facoltativo (`nil`: niente messaggi).

## Mappa C -> Delphi

| C | Delphi |
|---|---|
| `aasfile.h` (costanti, `aas_header_t`, `aas_bbox_t`, `aas_plane_t`, `aas_edge_t`, `aas_face_t`, `aas_area_t`, `aas_areasettings_t`, `aas_reachability_t`, `aas_node_t`, `aas_portal_t`, `aas_cluster_t`) | `DelphiDoom.Aas.Types`: record `packed` (`SizeOf` testato: 124, 32, 20, 8, 24, 48, 28, 44, 12, 20, 16), `TVec3` di `Framework\MathCore` |
| `aas_trace_t`, `aas_areainfo_t` (`be_aas.h`) | `TAasTrace`, `TAasAreaInfo` (52 byte) |
| `aasworld` (i 14 array e i contatori) | `IAasFile` / `TAasFile` (`Aas.AasFile`): nessun globale, un mondo per oggetto |
| `AAS_LoadAASFile`, `AAS_LoadAASLump` | `IAasReader` / `TAasReader` (`Aas.Reader`) |
| `AAS_DData` | `TAasHeaderCipher` (`Aas.HeaderCipher`) |
| `AAS_SwapAASData` | `TAasByteSwapper` (`Aas.ByteSwapper`), attivato da `ASwapBytes` |
| `AAS_PointAreaNum`, `AAS_PointPresenceType`, `AAS_PointReachabilityAreaIndex` | `IAasSampler` / `TAasSampler` (`Aas.Sampler`) |
| `AAS_TraceAreas`, `AAS_TraceClientBBox` | `IAasTracer` / `TAasTracer` (`Aas.Tracer`) |
| `AAS_InsideFace`, `AAS_PointInsideFace`, `AAS_AreaGroundFace`, `AAS_TraceEndFace`, `AAS_FacePlane` | `IAasFaceTester` / `TAasFaceTester` (`Aas.FaceTester`) |
| `AAS_BBoxAreas` (con la discesa di `AAS_AASLinkEntity`) | `IAasBoxAreas` / `TAasBoxAreas` (`Aas.BoxAreas`) |
| `AAS_AreaCluster`, `AAS_AreaPresenceType`, `AAS_AreaInfo`, `AAS_AreaReachability`, `AAS_AreaGrounded/Ladder/Liquid/Swim/Lava/Slime/JumpPad/Teleporter/ClusterPortal/DoNotEnter` (`be_aas_reach.c`) | `IAasAreaQuery` / `TAasAreaQuery` (`Aas.AreaQuery`) |
| `AAS_PresenceTypeBoundingBox`, `AAS_BoxOriginDistanceFromPlane`, `AAS_BoxOnPlaneSide2` e la macro `AAS_BoxOnPlaneSide` | `TAasBoxMath` (`Aas.BoxMath`) |
| `DotProduct`, `VectorSubtract`, `CrossProduct`, `VectorLength`, `VectorNormalize`, `VectorMA` | `TAasVectorMath` (`Aas.VectorMath`) |
| `botimport.Print` | `TAasPrinter` (`Aas.Printer`) -> `IBotImport.Print` |
| creazione degli oggetti | `TAasFactory` (`Aas.Factory`) |

## Cosa non e' portato (e perche')

- **Compilatore `bspc` e raggiungibilita'** (`be_aas_reach.c` salvo i predicati sulle aree, `be_aas_cluster.c`, `be_aas_optimize.c`): le raggiungibilita' sono gia' nel file; l'issue #122 chiede in realta' di portare anche il calcolo (`AAS_InitReachability`, `AAS_InitClustering`): **non fatto** (dipende da `be_aas_move.c`, che non c'e' ancora), vedi \"Cosa resta di #122\".
- **Scrittura** (`AAS_WriteAASFile`, `AAS_WriteAASLump`): serve solo al compilatore. I test scrivono i file con `TAasSample.Layout`.
- **`AAS_DumpAASData`, `AAS_FileInfo`** (debug, `AASFILEDEBUG`): la memoria e' degli array dinamici.
- **Entita' collegate alle aree** (`AAS_LinkEntity`, `AAS_UnlinkFromAreas`, `AAS_AreaEntityCollision`, `be_aas_entity.c`): dipendono dal gioco (`AAS_EntityCollision`, BSP). `TraceClientBBox` accetta `APassEntity` ma, senza entita' collegate, non ne colpisce nessuna, come il C con liste vuote. La discesa dell'albero con un box e' portata come `BBoxAreas`; l'heap dei 6144 link non e' modellato.
- **`be_aas_move.c`** (previsione del movimento), **`be_aas_main.c`** (inizializzazione, tempo, frame), **`be_aas_bspq3.c`** (interfaccia col BSP del gioco), **`be_aas_debug.c`**: prossime fette di #122 (`be_aas_route.c` e `be_aas_routealt.c` sono fatte: sezione del routing).
- `aasworld.initialized` e' un parametro del campionatore (`AInitialized`): lo imposta il codice del routing, che non c'e' ancora.

## Difetti del C conservati

- **`AAS_LoadAASLump` non ricorda l'offset a cui e' saltato**: dopo un buco tra i lump, ogni lump successivo stampa di nuovo "AAS file not sequentially read" (la golden ha il caso: 9 avvisi).
- La divisione dei lump `lunghezza / sizeof` ignora il resto; il numero di record e' quello intero.
- Il checksum e' confrontato anche per la versione 4 (che ha l'intestazione in chiaro); versione 5: tutti i byte dopo identificatore e versione (checksum compreso) sono in XOR con `byte(i) * 119`.
- Le costanti `TRACEPLANE_EPSILON` e `0.125` sono `double` nel C: `front + 0.125`, la divisione e `VectorMA(.., -0.125, ..)` si fanno in doppia precisione e poi si arrotondano a `float`; sono riprodotte (vedi i commenti in `Aas.Tracer`).
- `AAS_TraceEndFace` ha una variabile `firstface` che non viene mai assegnata: restituisce sempre NULL se nessuna faccia contiene il punto.
- In `AAS_BBoxAreas` l'ordine delle aree e' quello della lista dei link (l'ultima trovata per prima) e con `maxareas` restano le ultime.

## Differenze volute (ognuna con un test)

- **Lump fuori dal file**: errore `BLERR_CANNOTREADAASLUMP` (il C legge quel che trova e lascia zero il resto); lunghezza o offset negativi, idem. File piu' corto dell'intestazione: `BLERR_WRONGAASFILEID`.
- **`AAS_PointReachabilityAreaIndex` su un'area portale**: il C scrive `cluster = portals[-cluster].frontcluster; areanum = portals[-cluster].clusterareanum[0];` e la seconda riga usa il cluster **gia' sostituito** (positivo): `portals[-1]`, lettura prima dell'array. Qui si usa il portale dell'area (cluster e numero dell'area dal portale). La golden non chiama la funzione su aree portale (`reach P`).
- **Dati incoerenti** (nodo, piano, area, faccia, spigolo, vertice fuori tabella; albero con un ciclo): il C legge fuori dagli array o non finisce; qui e' un messaggio `PRT_ERROR` (i testi del C compilato con `AAS_SAMPLE_DEBUG` dove esistono) e la risposta e' 0 / falso / la traccia fin li'. Il ciclo si ferma dopo `(nodi + 1) * 127 + 1024` passi.
- **Numeri di area o di faccia fuori dalla tabella** in `AAS_AreaGrounded` & co.: falso (il C legge fuori dall'array); `AAS_AreaCluster`/`AAS_AreaPresenceType`/`AAS_AreaInfo`/`AAS_AreaReachability` stampano gli stessi errori del C.
- **`AAS_SwapAASData` su una macchina big endian**: il C passa i `float` dei box a `LittleLong` come se fossero interi (converte il valore invece di invertire i byte); qui si invertono i byte come per ogni altro `float`. Su little endian (Windows) il C non fa nulla e nemmeno qui.
- `AAS_TraceAreas` con `maxareas <= 0`: lista vuota (il C scrive `areas[0]` fuori dal buffer).
- `AAS_PointPresenceType` per un'area oltre `areasettings` torna 0.

## Parita' col C

`Tools\Verifica\122` compila con gcc di `Reference\_dati\_strumenti\w64devkit` il **vero** `be_aas_file.c` e `be_aas_sample.c` (copiati senza modifiche) con le righe vere di `be_aas.h` (`aas_trace_t`, `aas_areainfo_t`), `q_math.c` (`VectorLength`, `VectorNormalize`), `be_aas_main.c` (`AAS_Error`), `be_aas_reach.c` (`AAS_AreaReachability` e i predicati sulle aree); stub minimi per il resto. Il pilota (`aasgen.c`) costruisce in memoria 4 file `.aas` di mondi piccoli (una fila di scatole da 64 unita': albero dei nodi, facce, spigoli condivisi con indici negativi, raggiungibilita', portali, cluster; variante 1 con un piano obliquo alla radice, variante 2 in versione 4, variante 3 con un buco tra i lump) piu' quattro file rovinati (identificatore, versione, checksum, file mancante), li carica con la vera `AAS_LoadAASFile` e campiona con punti di un xorshift32 a seme fisso (coordinate multiple di 1/8, esatte). `Tests\Data\Aas\aas.golden.txt` (2372 righe: conteggi, CRC-32 dei 14 lump, 480 punti con area / presenza / cluster / indice di raggiungibilita' / `AAS_AreaInfo`, 320 trace delle aree, 640 trace del box, 240 test di facce, 240 box, predicati e messaggi) e' riprodotto riga per riga, bit per bit sui `float`, da `TAasScenarioRunner` (`TTestAasGolden`): **zero differenze a 32 e a 64 bit**. Nessun file di un gioco e' nel repository: i file `.aas` li costruisce `Tests\Source\DelphiDoom.Tests.Aas.Sample.pas` con la stessa ricetta del pilota (i CRC dei lump e del file sono nella golden).

**Virgola mobile**: il C e' compilato per SSE (`-ffp-contract=off`, ogni operazione arrotondata a `float`); `TAasVectorMath` scrive ogni operazione in un'istruzione a parte perche' l'x87 di Win32 non tenga risultati intermedi in precisione estesa. Tolleranza: nessuna (confronto sui bit); non c'e' garanzia teorica a 32 bit per la divisione in doppia precisione (arrotondamento doppio dell'x87 prima di `Double`), mai visto differire.

**Prova sui file veri** (`TTestAasOpenArena`, solo in locale, ignorata se OpenArena non c'e'; `DELPHIDOOM_OPENARENA` = cartella `baseoa` o un `.pk3`; nessun dato nel repository): i 99 `.aas` di `pak6-misc.pk3` (49), `pak6-patch085.pk3` (12), `pak6-patch088.pk3` (38) si leggono senza errori ne' messaggi (checksum = quello dell'intestazione: il BSP non serve); il centro di 287195 aree su 287244 (99,98%) e' risolto nell'area stessa da `PointAreaNum`; 20 linee a seme fisso per file tra centri di aree partono dalla prima area. Le prove "area dei punti di partenza dai BSP" e "percorsi tra coppie casuali" di #122 aspettano il percorso e il lettore dei BSP collegato.

## Test

`Tests\DelphiDoom.Tests.Aas` (166 test; senza OpenArena e senza `DELPHIDOOM_ROUTE_GOLDENS` ne restano ignorati 10 e passano 156), copertura di tutta la libreria 96% (3037 righe su 3163, `Tools\Copertura.ps1 -Test Aas`; le unit nuove tra 90% e 100%). Win32 e Win64 (a 64 bit i dati si cercano in `bin\Win32\Release\Tests\Data`: `robocopy Tests\Data\Aas bin\Win32\Release\Tests\Data\Aas`). In un worktree serve `DCC_UnitSearchPath` con la cartella di DUnitX (vedi `Libs\War\CLAUDE.md`).

## Navigazione AAS di Doom 3 a runtime (issue #109)

`DelphiDoom.Aas.D3.*` (GPL v3 o successiva con i termini aggiuntivi di Doom 3, "Based on the Doom 3 GPL Source Code (id Software)": e' il testo che l'issue #109 chiede per le unit scritte dal codice di Doom 3) porta `game/ai/AAS.cpp`, `AAS_routing.cpp` e `AAS_pathing.cpp` **sopra il lettore `.aas` di `IdTech4\MapFile`** (`TAasFile`, `IAasSampler`): aree e raggiungibilita' a runtime, cache del routing (aree e portali), `RouteToGoalArea`, tempi di viaggio, percorsi a piedi e in volo, ostacoli, spigoli dei muri, `FindNearestGoal`. Non dipende dal gioco: il registro dei messaggi e' `IIdLibLog`, le prove di `FindNearestGoal` sono `IAasAreaCallback`; il tempo non serve (il routing non ne usa). **Non ha chiamanti nel motore.** Nome dei tipi: `TAasFile`, `TAasReachability`, `IAasSampler` ... di `DelphiDoom.MapFile.Aas.*` sono altri di quelli dell'AAS di Quake III (`DelphiDoom.Aas.*`): le unit D3 usano solo i primi, e un'unit che le usa tutte e due deve qualificare i nomi.

```pascal
LNavigator := TAasNavigationFactory.CreateNavigator(TAasFileFactory.CreateReader(FileSystem, Log), Log);  // IAasMapNavigator
if LNavigator.Init('maps/game/mars_city1.aas', MapCrc) then   // come idAASLocal::Init: "Keeping" se il file e' gia' quello
begin
  LArea := LNavigator.PointAreaNum(Origin);
  if LNavigator.WalkPathToGoal(LPath, LArea, Origin, GoalArea, GoalOrigin, TFL_WALK or TFL_AIR) then ...
end;
```

| C++ | Delphi |
|---|---|
| `idAAS` (interfaccia), `aasPath_t`, `aasGoal_t`, `aasObstacle_t`, `idAASCallback` | `IAasNavigator`, `IAasMapNavigator` (con `Init`/`Shutdown`), `TAasPath`, `TAasGoal`, `TAasObstacle`, `IAasAreaCallback` (`Aas.D3.Intf`, `Aas.D3.Types`) |
| `idAASLocal` | `TAasNavigator` (`Aas.D3.Navigator`: l'unico che conosce tutti gli altri; creata da `TAasNavigationFactory`) |
| `CalculateAreaTravelTimes`, `AreaTravelTime`, centro delle aree (`FinishAreas`) | `TAasTopology` (`Aas.D3.Topology`: array di aree e raggiungibilita' inverse, centri, tempi per riga), `TAasTravelTime` |
| `idRoutingCache`, `idRoutingUpdate` | `TAasRoutingCache`, `TAasRoutingUpdate` (`Aas.D3.RoutingCache`) |
| cache di aree e di portali, `LinkCache`..`DeleteOldestCache`, `RemoveRoutingCacheUsingArea` | `TAasCacheStore` (`Aas.D3.CacheStore`) |
| `RouteToGoalArea`, `TravelTimeToGoalArea`, `FindNearestGoal` | `TAasRouter` (`Aas.D3.Router`) |
| `SetAreaState`, `AddObstacle`, `RemoveObstacle`, `RemoveAllObstacles` | `TAasObstacleManager` (`Aas.D3.Obstacles`) |
| `EdgeSplitPoint`, `FloorEdgeSplitPoint`, `WalkPathValid`, `SubSampleWalkPath`, `WalkPathToGoal`, `FlyPathValid`, `FlyPathToGoal` | `TAasPathFinder` (`Aas.D3.PathFinder`) |
| `GetWallEdges`, `SortWallEdges`, `GetEdgeVertexNumbers`, `GetEdge` | `TAasWallEdges` (`Aas.D3.WallEdges`) |

**Proprieta' e prestazioni.** Il navigatore possiede le sue parti e le libera in ordine inverso; il file passato a `Attach`/`CreateNavigatorForFile` e' liberato solo con `AOwnsFile`. Le aree e le raggiungibilita' sono gli oggetti del file, non copie (come l'originale: `TravelFlags`, `Number`, `DisableCount`, `MaxAreaTravelTime` dei portali si cambiano nel file). Le liste del flood (`areaUpdate`, `portalUpdate`) sono array con indici, la lista delle cache e' fatta di riferimenti: nessuna chiamata a interfaccia per area nel ciclo interno; **l'unica chiamata per candidato e' il callback di `FindNearestGoal`**, come il virtuale dell'originale. `IAasMapNavigator` va tenuta come interfaccia (il navigatore passa se stesso al callback). La memoria delle cache e' contata con `sizeof(idRoutingCache)` del 32 bit (48 byte), non con quello dell'oggetto Delphi, cosi' le cache si buttano agli stessi momenti (`AAS_MAX_ROUTING_CACHE_MEMORY` 2 MB, parametro del costruttore).

**Cosa non e' portato.** `Test`, `ShowWalkPath`, `ShowFlyPath` e tutto `AAS_debug.cpp` (disegno: `Stats` stampa solo con `CacheCounts`/`CacheMemory`); `SubSampleFlyPath` (l'originale la chiama solo con `SUBSAMPLE_FLY_PATH` a 0); `idAASFileManager` (il lettore e' `IAasFileReader`). **Non esiste `AI_FindGoalNearby`** in `Reference\doom3`: `FindNearestGoal` e' chiamata da `idAI::FindCoverGoal`, `FindAttackPosition`, `FindOutOfRangeGoal` con tre `idAASCallback` (`idAASFindCover`, `idAASFindAttackPosition`, `idAASFindAreaOutOfRange`, in `AI.h`): dipendono dal PVS, dal clip del gioco e dall'entita' dell'IA, restano **fuori** (vanno scritte dal gioco con `IAasAreaCallback`). La parte geometrica di `AI_pathing.cpp` (`idAI::FindPathAroundObstacles`) e' portata nella sezione "Evitamento degli ostacoli di Doom 3" piu' sotto.

**Difetti dell'originale conservati.** (1) `AddObstacle` chiama `SetObstacleState( obstacle, true )` e `RemoveObstacle` con `false`, ma "true" e' *enable*: aggiungere un ostacolo scala `disableCount` (un `byte`: da 0 a 255, non e' `<= 0`) e non blocca nulla, rimuoverlo **invalida** le raggiungibilita' che attraversa e le lascia invalide (`disableCount` torna a 0 col giro del byte). La golden lo prova. (2) `RouteToGoalArea` partendo da un'area portale con un goal che il portale non raggiunge torna `true` con la prima raggiungibilita' e un tempo piccolo (`travelTimes[]` 0 piu' il tempo nell'area). (3) `FindNearestGoal` torna prima di calcolare `expAbsBounds` se la prima area e' accettata: gli ostacoli restano come l'argomento li aveva. (4) `GetWallEdges` scrive il primo elemento della coda sulla posizione dell'area di partenza (`areaQueue[queueEnd++]` con `queueEnd` 0). (5) `RemoveRoutingCacheUsingArea` tratta il cluster 0 come il portale 0.

**Differenze volute.** File non instradabile (raggiungibilita' verso o da un'area che non c'e', cluster o portale fuori dall'elenco, area con raggiungibilita' senza `AREA_REACHABLE_*`, piu' di `MAX_REACH_PER_AREA`, facce, spigoli o vertici fuori tabella): `EAasRoutingException` all'inizio, dove l'originale legge o scrive fuori dalla memoria o chiama `gameLocal.Error`; `Init` la trasforma in `False` con un avviso. Un goal che non e' un'area raggiungibile del suo cluster (l'originale scrive fuori dalla tabella delle cache): `RouteToGoalArea` torna `False`. `FloorEdgeSplitPoint` ecc. usano `Single` come l'originale e **un'espressione per istruzione solo dove il C++ ha un'istruzione per operazione**: `d1 / (d1 - d2)` e' una sola espressione (l'x87 del C++ tiene la differenza in precisione estesa), il resto passa per i tipi `TGeoVec3`/`TGeoPlane` di `Framework\Geometry` (verificati sul C++).

**Parita' col C++ vero.** `Tools\Verifica\109\Build-Harness.ps1` compila con `bcc32c` (clang 32 bit di Delphi 11, **senza `-std=c++14`**: a C++17 `Simd_Generic.cpp` ha `register`, che lo script toglie dalla copia) i veri `AAS.cpp`, `AAS_routing.cpp` e `AAS_pathing.cpp` con `AASFile.cpp`, `AASFile_sample.cpp` e `AASFileManager.cpp` del compilatore AAS e l'idlib; stub di `Game_local.h` (`gameLocal.Printf`, `Error`), `Pvs.h`; `private:` diventa `public:` nella copia di `AAS_local.h` per leggere la lista delle cache. Il pilota (`route_driver.cpp`) legge i tre mondi `Tests\Data\AasD3\*.aas` (`Make-RoutingAas.ps1`: griglie di scatole da 64 unita' con facce e spigoli condivisi, albero BSP, cluster a colonne, aree portale, ledge, acqua, crouch, raggiungibilita' di ogni tipo; **inventati**, nessun dato di Doom 3) e stampa 8453 righe: aree, cluster, portali e `maxAreaTravelTime`, tutte le coppie di aree con 3 insiemi di travel flags, cache (numero e memoria), `WalkPathToGoal`, `WalkPathValid`, `FlyPathToGoal`, `FlyPathValid`, `FindNearestGoal` con tre callback e un ostacolo, spigoli dei muri e loro ordinamento, `SetAreaState` e ostacoli (con il difetto 1), seconda `Init`. Con la memoria delle cache portata a 3000 byte (il pilota ricompila con `MAX_ROUTING_CACHE_MEMORY` cambiato) altre 8453 righe: le cache si buttano agli stessi momenti. `Tests\Data\AasD3\route.golden.txt` e `route_small.golden.txt` sono riprodotte da `TD3ScenarioRunner` (`TTestAasD3Golden`): **zero differenze a 32 e a 64 bit, sui bit dei `float`**. Non c'e' compilatore C++ nel PATH: serve `bcc32c` di Delphi 11 (`Reference\doom3` non e' nel repository, il pilota lavora in `C:\harness\d3`).

**Test.** `Tests\DelphiDoom.Tests.Aas` (166 test, sotto): `TTestAasD3Golden`, `TTestAasD3Routing`, `TTestAasD3TravelTime`, `TTestAasD3Files` (sette file non instradabili), `TTestAasD3Navigator` (navigatore senza file come `idAASLocal` con `file == NULL`, `Init` e "Keeping", prove sulle risposte). Copertura (`Tools\Copertura.ps1 -Test Aas`, Debug): CacheStore 99,2%, Factory, RoutingCache e TravelTime 100%, Router 94,1%, WallEdges 93,5%, Topology 92,9%, Navigator 93,9%, Obstacles 90,4%, PathFinder >= 90% (dopo aver tolto `SubSampleFlyPath`, che non e' mai chiamata).

## Routing di Quake III (issue #122, seconda fetta)

`DelphiDoom.Aas.Route.*` (GPL v2 o successiva, "Based on the Quake III Arena GPL Source Code (id Software)") porta `be_aas_route.c` e `be_aas_routealt.c` **sopra l'`IAasFile` gia' c'e'**: tempi di viaggio tra aree, cache delle aree e dei portali, `AAS_AreaRouteToGoalArea` (e i due wrapper), `AAS_PredictRoute`, `AAS_EnableRoutingArea`, `AAS_ReachabilityFromNum`, `AAS_NextAreaReachability`, `AAS_NextModelReachability`, `AAS_NearestHideArea`, `AAS_AlternativeRouteGoals`, `AAS_InitRouting` (tabelle dei viaggi nelle aree, portali, aree attraversate dalle raggiungibilita' con `IAasTracer.TraceAreas`).

| C | Delphi |
|---|---|
| `AAS_InitRouting` e i suoi passi (`AAS_InitTravelFlagFromType`, `AAS_InitAreaContentsTravelFlags`, `AAS_CreateReversedReachability`, `AAS_CalculateAreaTravelTimes`, `AAS_InitPortalMaxTravelTimes`, `AAS_InitReachabilityAreas`) | `TAasRouteData` (`Aas.Route.Data`) |
| `aas_routingcache_t`, `aas_routingupdate_t` | `TAasRouteCache`, `TAasRouteUpdate` (`Aas.Route.Cache`) |
| cache di aree e portali, `AAS_FreeOldestCache`, `AAS_RemoveRoutingCacheUsingArea` | `TAasRouteCacheStore` (`Aas.Route.CacheStore`) |
| route, previsione, aree disabilitate, raggiungibilita', nascondiglio | `TAasRouter` (`Aas.Route.Router`, `IAasRouter` in `Aas.Route.Intf`; `TAasFactory.CreateRouter`) |
| `be_aas_routealt.c` | `TAasAlternativeRoutes` (`Aas.Route.Alternative`) |
| `TFL_*`, `RSE_*`, `ALTROUTEGOAL_*`, `aas_predictroute_t`, `aas_altroutegoal_t` | `Aas.Route.Types` |
| `AvailableMemory` (`l_memory.c`) | `IAasRoutingMemory` (facoltativo: `nil` = mai a corto) |

**Parametri.** `bot_developer` e' un parametro (`ADeveloper`): gli errori su aree fuori tabella si stampano solo con lui. `AOrigin: PVec3` puo' essere `nil` come il `NULL` del C. Il tempo (`AAS_Time`, `cache->time`) non serve: l'ordine di uso e' la lista delle cache.

**Non portato.** `AAS_WriteRouteCache`/`AAS_ReadRouteCache` (la lettura trova sempre "nessun file": e' cosi' nel pilota), `AAS_RoutingInfo`, `AAS_CreateAllRoutingCache`, `AAS_RandomGoalArea` (serve la traccia del box e `random()`), `AAS_BridgeWalkable`, `AAS_AreaVisible` (e' uno stub che dice no: lo e' anche qui).

**Difetti dell'originale.** (1) `AAS_NearestHideArea` indicizza `aasworld.areaupdate` con il numero dell'area, ma l'array e' fatto per `maxreachabilityareas` voci: overflow di heap (in gcc crasha su `fan.aas`). Qui l'array e' di `AreaCount` voci. **Provata sul C patchato**: il pilota C (uild.sh) fa l'array di max(maxreachabilityareas, numareas) voci con un sed sull'allocazione (terza e ultima modifica del codice vero, dichiarata nell'intestazione di uild.sh) e stampa 12 righe HD per mappa (AAS_NearestHideArea con le tre combinazioni di travel flags); il gemello Delphi le rifa, zero differenze sulle mappe. (2) `AAS_UpdateAreaRoutingCache` legge `startareatraveltimes[128]` (sull'stack) con indici fino al numero di raggiungibilita' inverse dell'area goal: un'area con 266 (oa_koth1) legge oltre; qui sono zeri. La copia del C del pilota ha l'array di 4096. (3) `AAS_AreaTravelTimeToGoalArea` e `AAS_AreaReachabilityToGoalArea` non inizializzano `reachnum`: un percorso attraverso un portale senza origine legge `bestreachnum = *reachnum` e se e' negativo risponde "nessun percorso": dipende dallo stack. Qui parte da 0 (e la copia del C del pilota anche: `sed` su quella riga, l'unica altra modifica del codice vero). (4) Dal portale la cache dei portali non ha mai `reachabilities`: partendo da un'area portale si prende sempre la prima raggiungibilita'. (5) `TFL_DEFAULT` non ha parentesi: `TFL_DEFAULT & ~(...)` toglie solo l'ultimo termine (il pilota usa le parentesi).

**Differenze volute.** Un numero fuori dagli array del file (raggiungibilita' verso o da un'area che non c'e', cluster o portale fuori elenco, `clusterareanum` negativo, `firstreachablearea` fuori dal lump, indice dei portali fuori): `EAasRouteException` alla creazione, dove il C legge fuori memoria; un'area fuori dal suo cluster alla prima richiesta di cache (`GetAreaRoutingCache`): idem (e la cache a meta' non resta). `AAS_AlternativeRouteGoals` con zero posti: 0 (il C scrive il primo fuori dall'array). La memoria di una cache e' contata come il 32 bit del C (`ROUTE_CACHE_HEADER_SIZE` 64 + 3 byte a voce).

**Parita' col C vero.** `Tools\Verifica\122\route` (`build.sh` con gcc di w64devkit, `routegen.c`, `stub\botlib\be_aas_def.h`, `Make-Golden.ps1`) compila i veri `be_aas_file.c`, `be_aas_sample.c`, `be_aas_route.c` e `be_aas_routealt.c` (con le sole due modifiche del punto 2 e 3 sopra), carica i `.aas`, fa `AAS_InitRouting` e `AAS_InitAlternativeRouting` e stampa: il numero di aree, cluster, portali, raggiungibilita'; `portalmaxtraveltimes`; le aree attraversate dalle prime 4000 raggiungibilita'; un hash FNV di tutte le tabelle dei viaggi; `AAS_TravelFlagForType` per ogni tipo; 300 route con origine e senza (3 insiemi di travel flags); 60 previsioni con tutti gli eventi di stop; 12 liste di mete alternative; 4 aree disabilitate e riabilitate con route in mezzo; `AAS_NextAreaReachability`, `AAS_ReachabilityFromNum`, `AAS_NextModelReachability`; la lista delle cache (numero, memoria, aggiornamenti) a ogni passo. Il pilota Delphi gemello e' `TAasRouteScenario`. **I 71 `.aas` di OpenArena** (`pak6-misc`, `pak6-patch085`, `pak6-patch088`: dove un nome compare piu' volte vince l'ultimo pak) danno le stesse righe **a 32 e a 64 bit, bit per bit**; con la memoria corta (`AvailableMemory = limite - routingcachesize`, limite 1 MB + 20000 byte: si buttano le cache piu' vecchie) idem su `fan`, `oa_bases3`, `blitzkrieg3`. Nel repository stanno le golden di quelle tre mappe (`Tests\Data\Aas\route_*.golden.txt`, solo righe di numeri; i `.aas` non ci sono: `TTestAasRouteGolden` e' ignorato se OpenArena manca); la prova su **tutti** i 71 file si fa con `DELPHIDOOM_ROUTE_GOLDENS` (cartella delle golden di tutte le mappe, scritta da `Make-Golden.ps1 -Maps ...` o dal ciclo su `routegen.exe`).

**Test e copertura.** `TTestAasRouteGolden`, `TTestAasRoute` (22 prove su un mondo di tre aree costruito in memoria: tempi attesi calcolati a mano, aree disabilitate, tipi non permessi, previsione e suoi eventi, bandiere, raggiungibilita' e modelli, nascondiglio, file non instradabili, memoria corta). Copertura: CacheStore 99,6%, Data 99,0%, Router 97,0%, Alternative, Cache 100%.

**Stato di #122**: portati tutti i file della botlib che non dipendono dal gioco: `be_aas_file.c`, `be_aas_sample.c` (compresi i link delle entita'), `be_aas_route.c` (con `AAS_RandomGoalArea`, `Route.RandomGoal`: non provata sul C, il generatore e' iniettato), `be_aas_routealt.c`, `be_aas_move.c`, `be_aas_bspq3.c`, `be_aas_entity.c`, `be_aas_main.c`, `be_aas_reach.c`, `be_aas_cluster.c`, `be_aas_optimize.c`, `be_aas_def.h` (la struttura `aas_t` e' distribuita sulle classi). Non portato: `AAS_WriteAASFile`, la cache di routing su file, il disegno di debug. L'interfaccia che serve alla #123 (IA dei bot: `be_ai_goal.c`, `be_ai_move.c`) e' in `CLAUDE.md`.

## Cluster e ottimizzatore di Quake III (#122, terza fetta)

`be_aas_cluster.c` (`AAS_InitClustering` e tutto cio' che chiama) e `be_aas_optimize.c` (`AAS_Optimize`) sopra `IAasFile`, GPL v2 o successiva ("Based on the Quake III Arena GPL Source Code (id Software)"). Unit: `Aas.Cluster.World` (le tabelle del mondo e le tre tabelle da 65536 voci del C: portali, indice dei portali, cluster, con i contatori `numportals`, `portalindexsize`, `numclusters`), `Aas.Cluster.Builder` (`AAS_RemoveClusterAreas`, `AAS_UpdatePortal`, `AAS_FloodClusterAreas_r`, `AAS_FloodClusterAreasUsingReachabilities`, `AAS_NumberClusterAreas`, `AAS_FindClusters`, `AAS_CreatePortals`, `AAS_TestPortals`), `Aas.Cluster.PortalFinder` (`AAS_ConnectedAreas`, `AAS_CheckAreaForPossiblePortals`, `AAS_FindPossiblePortals`), `Aas.Cluster.Initializer` (`AAS_InitClustering`, `IAasClusterInitializer`), `Aas.Optimize.Optimizer` (`IAasOptimizer`), `Aas.Editor.Intf` (`IAasFileEditor`: le tabelle che cambiano lunghezza; `TAasFile` lo implementa; i getter di `IAasFile` restituiscono array condivisi, quindi le modifiche di un elemento sono sul posto). Creazione: `TAasFactory.CreateClusterInitializer(AFile, AImport, ALibVars)` e `CreateOptimizer(AFile, AImport)`.

**Difetti dell'originale conservati.** (1) `nofaceflood` e' un globale (qtrue): qui e' la proprieta' `NoFaceFlood` (True). (2) Nell'ottimizzatore l'indice 0 dei vertici vale anche "non ancora memorizzato": un vertice puo' essere aggiunto due volte; l'area 0 della tabella ottimizzata e' azzerata; `AAS_KeepFace` tiene solo le facce `FACE_LADDER` (le mappe di OpenArena sono gia' ottimizzate e non ne hanno: la parita' dell'ottimizzatore si prova sui mondi di prova con una faccia su sette di scala). (3) Il ciclo `while(1)` di `AAS_InitClustering` ritenta dopo un fallimento togliendo un flag di portale; se non ne toglie nessuno il C non finisce mai.

**Differenze volute.** Un numero fuori dagli array (raggiungibilita' verso un'area che non c'e', faccia o spigolo fuori elenco, `firstface` negativo...): `EAasClusterException` dove il C legge fuori memoria; lista di aree di un portale oltre `MAX_PORTALAREAS` (1024): idem; ciclo senza progresso (stesso numero di portali due giri di fila): idem; file non modificabile (senza `IAasFileEditor`): idem. L'ottimizzatore controlla solo cio' che raggiunge (lo spigolo 0 fittizio di un file gia' ottimizzato usa un vertice che non c'e': il C non lo legge).

**Parita' col C vero.** `Tools\Verifica\122\cluster` (`build.sh`, `clustergen.c`, `LEGGIMI.md`, gcc di w64devkit con `-O1`) compila i veri `be_aas_file.c`, `be_aas_sample.c`, `be_aas_cluster.c` e `be_aas_optimize.c` e per ogni `.aas` fa sei casi: A `AAS_InitClustering` senza forzare, B con `forceclustering`, C a cluster azzerati, D `AAS_Optimize`, E ottimizzazione con facce di scala, F cluster azzerati con `nofaceflood = qfalse`; stampa le tabelle riga per riga, gli hash e i messaggi (`P<n>|` e `L|`). Gemello Delphi: `TAasClusterScenario`. Nel repository le golden di `fan`, `oa_bases3`, `blitzkrieg3` e dei due mondi di prova (`Tests\Data\Aas\cluster_*.golden.txt`); la prova su tutti i 71 `.aas` di OpenArena con `DELPHIDOOM_CLUSTER_GOLDENS` (cartella con le golden di tutte le mappe) e `DELPHIDOOM_OPENARENA`. Zero differenze a 32 e a 64 bit. Copertura delle unit nuove (tutti i 71 file): Builder 90%, PortalFinder 97%, World 93%, Initializer 98%, Optimizer 94%; senza `DELPHIDOOM_CLUSTER_GOLDENS` PortalFinder scende al 78% (`AAS_ConnectedAreas` si raggiunge solo con alcune mappe).

**Non portato.** `AAS_Error`/`Log_Write` sono `IBotImport.Print(PRT_FATAL)` e `LogWrite`; non c'e' scrittura del file `.aas` (`AAS_WriteAASFile`) ne' `AAS_InitReachability`.

## Evitamento degli ostacoli di Doom 3 (issue #109, `DelphiDoom.Aas.D3.Avoid.*`)

La parte geometrica di `game/ai/AI_pathing.cpp` (GPL v3 o successiva con i termini di Doom 3, come il resto di `Aas.D3`): `idAI::FindPathAroundObstacles` con quello che usa. Le scatole delle entita' vicine sono proiettate sul pavimento in `idWinding2D` (`TGeoWinding2D` di `Framework\Geometry`), allargate della scatola di chi cammina, e agli ostacoli si aggiungono i muri dell'AAS (`GetWallEdges`); un albero di nodi gira in senso orario e antiorario attorno agli spigoli, viene potato, accorciato con scorciatoie e se ne sceglie il percorso piu' corto. Classi (una per unit): `TAvoidObstacle` (winding, bounds 2D, entita'), `TAvoidObstacleSet` (`PointInsideObstacle`, `GetPointOutsideObstacles`, `GetFirstBlockingObstacle`), `TAvoidPathNode` e `TAvoidPathTree` (`GetPathNodeDelta`, `BuildPathTree`, `PrunePathTree`, `LineIntersectsPath`, `FreePathTree_r`), `TAvoidPathOptimizer` (`OptimizePath`, `PathLength`, `FindOptimalPath`), `TAvoidObstacleCollector` (`GetObstacles` con il passo sopra gli ostacoli, la silhouette della scatola e i muri), `TAvoidPathFinder` (`FindPathAroundObstacles`: compone le parti sul navigatore `IAasNavigator`), `TAvoidBallistics` (`Ballistics` e `HeightForTrajectory`), tipi in `Avoid.Types`.

**Il gioco sta dietro `IAvoidBody`**: la fisica di chi cammina (scatola, gravita', origine, velocita') e i modelli che toccano un box (`ObstaclesTouchingBounds`). Le scelte che dipendono dalle entita' (`idActor`/`idMoveable`, se stessi, il nemico da ignorare, i morti, gli attori che vanno nella stessa direzione) le fa il gioco dentro quel metodo; il resto del test e' nella libreria. Un'entita' e' un numero (`AVOID_NO_ENTITY` = 0 e' il muro dell'AAS).

**Non portato**: `PathTrace`, `PredictPath`, `TestTrajectory` (chiamano `gameLocal.clip.Translation`/`Motion` e gli oggetti fisici: non esiste un modo di provarli senza il gioco), `DrawPathTree` e le frecce di debug (`ai_showObstacleAvoidance`).

**Difetti dell'originale** (tutti provati con un test): (1) `optimizedPath` di `FindOptimalPath` non e' inizializzato (con un percorso di un punto si legge la pila): l'originale vero e' stato provato con un `memset` nella copia del pilota, qui l'array e' azzerato; (2) `GetPathNodeDelta` gira per sempre su un winding con tutti i punti uguali: `EAasAvoidException`; (3) un percorso con piu' di `MAX_OBSTACLE_PATH` (64) punti scrive fuori dall'array: `EAasAvoidException`; (4) `GetPointOutsideObstacles` legge un elemento oltre la coda (`queue[++queueStart]`): la coda ha un posto in piu'; (5) il contatore dei nodi e' globale (`pathNodeAllocator`): qui e' dell'albero; (6) gli indici di ostacolo e spigolo che l'albero cita sono controllati.

**Parita' col C++**: `Tools\Verifica\109\Build-AvoidHarness.ps1` (bcc32c senza `-std=c++14`) estrae **le righe vere** di `AI_pathing.cpp` (da `obstacle_t` a `idAI::FreeObstacleAvoidanceNodes`, e `Ballistics`..`HeightForTrajectory`), le compila con il vero `idAASLocal` e un finto del gioco (`avoid_stub.h`: entita', fisica, clip) e riscrive `Tests\Data\AasD3\avoid.golden.txt` (6342 righe: 150 percorsi di `idAI::FindPathAroundObstacles` per ognuno dei tre mondi con 0..7 modelli di sette generi, 120 prove sulle funzioni su winding costruiti, 60 tiri). `TD3AvoidScenarioRunner` (`Tests\Source\DelphiDoom.Tests.Aas.D3.AvoidScenario.pas`) e `avoid_driver.cpp` sono gemelli: **cambiando uno si cambia l'altro**. Zero differenze a 32 e a 64 bit, **tranne i tiri**: `atan2( float, float )` e `cos( float )` della libm di bcc32c non sono arrotondate correttamente (un'unita' sull'ultimo bit), `AngleNormalize180` la ingrandisce (somma 360 e la toglie: qualche unita' sui gradi) e il tempo divide per un coseno che puo' essere vicino a zero: l'angolo puo' differire di 1E-4 gradi e il tempo di un 1E-4 relativo (`TTestAasD3AvoidGolden`); il resto e' uguale bit per bit. **Trappole**: (1) in Pascal `0.5 * (...)` e' `Extended` e fa scegliere l'overload `Extended` di `ArcTan2`: gli argomenti vanno in `Single` come nel C++; (2) gli argomenti di una chiamata e i costruttori di C++ sono valutati in ordine non specificato: il pilota C e il gemello Delphi scrivono ogni estrazione casuale in un'istruzione a parte.

**Test**: `TTestAasD3AvoidGolden` e `TTestAasD3Avoid` (20 prove: ostacoli, punto dentro e fuori, primo che blocca, limite di 256 ostacoli, nodo che cita un ostacolo che non c'e', winding vuoto e con punti uguali, percorso oltre 64 punti, albero senza primo passo, penalita' di svolta, senza navigatore, tiro senza soluzione). Copertura (`Tools\Copertura.ps1 -Test Aas`): Ballistics, Obstacle, PathNode, PathOptimizer 100%, PathTree 99%, ObstacleCollector 99%, ObstacleSet 97%, PathFinder 94%.

## Movimento di Quake III (#122, quarta fetta, `DelphiDoom.Aas.Move.*`)

`be_aas_move.c` (GPL v2 o successiva, "Based on the Quake III Arena GPL Source Code (id Software)") sopra `IAasFile`, `IAasSampler`, `IAasTracer`, `IAasFaceTester` e il BSP dietro `IAasBspWorld` (`PointContents`, `Trace`: `AAS_PointContents` e `AAS_Trace` di `be_aas_bspq3.c`, cioe' `botimport.PointContents` e `botimport.Trace`). Unit: `Move.Types` (`SE_*`, `TAasClientMove`, `TAasBspTrace`, `TAasMoveSettings`, `EAasMoveException`), `Move.Intf` (`IAasBspWorld`, `IAasMovement`), `Move.Settings` (`TAasMoveSettingsReader`: `AAS_InitSettings`, le variabili `phys_*` e `rs_*` con i loro default), `Move.Movement` (`TAasMovement`: `AAS_DropToFloor`, `AAS_AgainstLadder`, `AAS_OnGround`, `AAS_Swimming`, `AAS_SetMovedir`, `AAS_JumpReachRunStart`, `AAS_WeaponJumpZVelocity`, `AAS_RocketJumpZVelocity`, `AAS_BFGJumpZVelocity`, `AAS_ClipToBBox`, `AAS_PredictClientMovement`, `AAS_ClientMovementHitBBox`, `AAS_HorizontalVelocityForJump`, `AAS_Accelerate`, `AAS_ApplyFriction`), `Move.CollisionWorld` (`TAasCollisionWorld`: `IAasBspWorld` sopra `IQ3Collision` di `IdTech4\Collision`, il solo mondo, senza entita'). **La fisica e' quella di botlib, non quella di `IdTech4\Pmove` (`bg_pmove`)**: la previsione del movimento del bot e' una approssimazione a passi con regole proprie (gravita' all'inizio del frame, attrito in `AAS_ApplyFriction`, salto di `phys_jumpvel` meno un frame di gravita' + 5) e i bit devono essere quelli del C della botlib; `Pmove` darebbe numeri diversi, quindi non e' usato (decisione dichiarata, #122).

**Non portato**: il disegno di debug (`AAS_DebugLine`, `AAS_ShowReachability`: il parametro `visualize` c'e', ma non disegna e stampa solo il messaggio di partenza in solido).

**Trappole**: (1) `VectorMA(v, -DotProduct(v, n), n, v)` con destinazione uguale al vettore: la macro rivaluta la scala per ogni componente e i primi componenti sono gia' cambiati (gcc): il ciclo Delphi ricalcola `-Dot` a ogni componente; (2) espressioni miste: `0.5 * gravity` e' `double` (`CTenth`, `CQuarter` come `Double`), il letterale `0.1f` e' `Single`; (3) `abs(float)` del C e' l'`abs` intero: `Abs(Trunc(x))`; (4) in `AAS_ClipToBBox` con una direzione nulla `front / (front - back)` da' infinito o NaN e i confronti con NaN devono essere falsi come in SSE: l'x87 di dcc32 puo' dare vero, quindi `not IsNan(...)` davanti a ogni confronto, e il gemello di parita' maschera le eccezioni in virgola mobile come il motore.

**Parita'**: `Tools\Verifica\122\route` include il vero `be_aas_move.c` (modo `move` di `routegen`, `AngleVectors` estratto con awk) con i gemelli di `AAS_PointContents` e `AAS_Trace` basati sulla geometria AAS; gemello Delphi `TAasMoveScenario` (`Tests\Source\DelphiDoom.Tests.Aas.Move.Scenario.pas`): righe AC (accelerazione), FR (attrito), HV (velocita' orizzontale per il salto), CB (clip al box), MD (movedir), WO (mondo: `OnGround`, `Swimming`, `AgainstLadder`, `DropToFloor`), DF, JR (partenza della rincorsa), PI/PM (120 previsioni con ogni evento di stop), HB (12 previsioni contro un box), TB. Zero differenze su tutti i 71 `.aas` di OpenArena, a 32 e a 64 bit; nel repository le golden di tre mappe (`Tests\Data\Aas\move_*.golden.txt`), tutte e 71 con `DELPHIDOOM_ROUTE_GOLDENS`. La prova dimostra la logica della botlib con una trace basata sull'AAS (identica nel C e in Delphi); non e' una prova contro il BSP vero.

## BSP, entita' e sistema AAS di Quake III (#122, quinta fetta)

`be_aas_bspq3.c`, `be_aas_entity.c`, `be_aas_main.c` e il collegamento delle entita' alle aree di `be_aas_sample.c` (GPL v2 o successiva). Il BSP della botlib e' quasi tutto un passaggio verso il gioco (`botimport`): le interfacce piccole sono `IAasBspWorld` (contenuto di un punto e trace di un box) e `IAasBspModels` (`EntityData`, `EntityTrace`, `InPVS`, `ModelMinsMaxsOrigin`); `TAasCollisionModels` implementa la seconda sopra `IQ3CollisionModel` di `IdTech4\Collision` (stringa delle entita', PVS con `PointLeafnum`/`LeafCluster`/`ClusterPVS`, bounds di un modello con `InlineModel` e `ModelBounds`, allargati al raggio se ruotato come `BotImport_BSPModelMinsMaxsOrigin`; `EntityTrace` non collide: nessuna entita' nel modello di collisione).
- `Bsp.Entities` (`TAasBspEntities`, `IAasBspEntities`): `AAS_ParseBSPEntities` (scanner proprio: commenti `//` e `/* */`, stringhe senza escape e senza unione, `MAX_BSPENTITIES` = 2048), `AAS_NextBSPEntity`, `AAS_BSPEntityInRange`, `AAS_ValueForBSPEpairKey` (valore tagliato a `size - 1`; con una chiave ripetuta vince la **seconda**, perche' il C inserisce in testa), `AAS_VectorForBSPEpairKey` (`sscanf("%lf %lf %lf")`), `AAS_FloatForBSPEpairKey` (`atof`), `AAS_IntForBSPEpairKey` (`atoi`: `Bsp.CNumbers`). Un testo non valido svuota le entita' con un messaggio, come il C.
- `Links` (`TAasEntityLinks`): `AAS_InitAASLinkHeap`, `AAS_AllocAASLink`, `AAS_DeAllocAASLink`, `AAS_AASLinkEntity`, `AAS_LinkEntityClientBBox`, `AAS_UnlinkFromAreas` con l'heap di `max_aaslinks` (6144) link a indici: la lista libera, la lista delle aree di un'entita' (`next_area`, l'ultima area trovata per prima) e quella delle entita' di un'area (`next_ent`, l'ultima collegata per prima). `AAS_NO_LINK` = -1 e' il NULL. Heap pieno: `empty aas link heap` (PRT_FATAL solo con `bot_developer`) e lista parziale; un indice che non esiste e' `EAasLinkException` (il C legge fuori).
- `Entity.Table` (`TAasEntityTable`): `AAS_UpdateEntity` (collega al primo frame e quando cambiano angoli, box o origine; il modello del mondo `ENTITYNUM_WORLD` non si collega; i leaf del BSP non si collegano: le funzioni del C sono vuote), `AAS_EntityInfo`, `AAS_EntityOrigin`, `AAS_EntityModelindex`, `AAS_EntityType`, `AAS_EntityModelNum`, `AAS_OriginOfMoverWithModelNum`, `AAS_EntitySize`, `AAS_EntityBSPData`, `AAS_ResetEntityLinks`, `AAS_InvalidateEntities`, `AAS_UnlinkInvalidEntities`, `AAS_NearestEntity`, `AAS_BestReachableEntityArea`, `AAS_NextEntity`. `AAS_BestReachableLinkArea` sta in `be_aas_reach.c`: arriva come funzione iniettata (`TAasBestLinkArea`). Un numero di entita' fuori tabella in `AAS_UpdateEntity` e' `EAasEntityException` (il C scrive fuori).
- `Main.System` (`TAasSystem`, `IAasFrameState`): `AAS_Setup` (`maxclients`, `maxentities`), `AAS_LoadMap` (entita' del BSP, file `maps/<nome>.aas` dal `IAasReader`, `AAS_InitSettings`, collegamenti, `AAS_InitReachability`, `AAS_InitAlternativeRouting`), `AAS_StartFrame`, `AAS_ContinueInit` (reachability a piu' frame, clustering, ottimizzazione, routing, `AAS_SetInitialized`), `AAS_Shutdown`, `AAS_ProjectPointOntoVector`, `AAS_Time`, `AAS_Loaded`, `AAS_Initialized`; i passi dell'inizializzazione stanno dietro `IAasInitSteps` (calcolo delle raggiungibilita', cluster, ottimizzatore, routing) e la mappa che li costruisce dietro `IAasMapBuilder`: il sistema non conosce le classi concrete. `Main.StringIndexes` (`AAS_UpdateStringIndexes`, `AAS_ModelFromIndex`, `AAS_IndexFromModel`: una stringa vuota vale "non data").

**Non portato**: `AAS_WriteAASFile` (con `savefile` o `forcewrite` il sistema scrive "couldn't write ..." nel log), `AAS_WriteRouteCache`/`AAS_ReadRouteCache` e il resto della diagnostica di `AAS_StartFrame` (`showcacheupdates`, `showmemoryusage`, `memorydump`), `AAS_BoxEntities` e il collegamento ai leaf (sono vuoti nel C), `AAS_BSPTraceLight` (restituisce 0).

**Test**: `TTestAasCNumbers`, `TTestAasBspEntities` (`DelphiDoom.Tests.Aas.Bsp.Units`), `TTestAasLinks`, `TTestAasStringIndexes`, `TTestAasEntityTable`, `TTestAasSystem` (`DelphiDoom.Tests.Aas.Main.Units`: mondo di tre aree costruito in memoria con due piani; finti per lo stato, i modelli, il lettore, le variabili e i passi di inizializzazione).

## Raggiungibilita' di Quake III (#122, sesta fetta, `DelphiDoom.Aas.Reach.*`)

Issue #122, quarta fetta. Port di `Reference\quake3\code\botlib\be_aas_reach.c` (4548 righe, GPL v2 o successiva, "Based on the
Quake III Arena GPL Source Code (id Software)" in ogni unit) in classi `DelphiDoom.Aas.Reach.*`: il calcolo di **tutte** le
raggiungibilita' di un file `.aas` (nessun globale: `aasworld`, `aassettings`, l'heap e i contatori `reach_*` sono nel contesto).
**Percorso freddo, nessun chiamante nel motore.**

### Mappa C -> Delphi

| C (`be_aas_reach.c`) | Delphi |
|---|---|
| `aas_lreachability_t`, costanti (`INSIDEUNITS` ...), `reach_*` | `Reach.Types` (`TAasLinkedReach`, `PAasLinkedReach`, `TAasReachCounters`, `EAasReachException`) |
| `AAS_SetupReachabilityHeap`, `AAS_AllocReachability`, `AAS_FreeReachability`, `areareachability`, `AAS_ReachabilityExists` | `Reach.Heap` (`TAasReachHeap`) |
| `AAS_FaceArea`, `AAS_AreaVolume`, `AAS_AreaGroundFaceArea`, `AAS_FaceCenter` | `Reach.Geometry` (`TAasReachGeometry`, `IAasReachGeometry`) |
| `AAS_FallDamageDistance`, `AAS_FallDelta`, `AAS_MaxJumpHeight`, `AAS_MaxJumpDistance`, `AAS_BarrierJumpTravelTime` | `Reach.Physics` (`TAasReachPhysics`, `IAasReachPhysics`) |
| `AAS_AreaGrounded`, `AAS_AreaSwim`, `AAS_AreaCrouch`, `AAS_AreaLadder`, `AAS_AreaJumpPad`, `AAS_AreaTeleporter`, `AAS_AreaClusterPortal`, `AAS_TravelFlagsForTeam` | `Reach.Context` (`TAasReachContext`); per `AAS_AreaLava/Slime/Liquid/DoNotEnter/Reachability` resta `IAasAreaQuery` |
| macro `VectorMA` con scala int o float, `VectorScale`, `VectorMiddle`, `VectorDistance`, `VectorBetweenVectors`, `traveltime += x` | `Reach.Vectors` (`TAasReachVectors`; `VectorMA` con scala `double` e' `TAasVectorMath.MultiplyAdd`) |
| `AAS_ClosestEdgePoints` | `Reach.EdgePoints` |
| `AAS_Reachability_Swim` | `Reach.Swim` |
| `AAS_Reachability_EqualFloorHeight` | `Reach.EqualFloor` |
| `AAS_Reachability_Step_Barrier_WaterJump_WalkOffLedge` | `Reach.Step` |
| `AAS_Reachability_Jump` | `Reach.Jump` |
| `AAS_Reachability_Ladder` | `Reach.Ladder` |
| `AAS_Reachability_Grapple` | `Reach.Grapple` |
| `AAS_Reachability_WeaponJump`, `AAS_SetWeaponJumpAreaFlags` | `Reach.WeaponJump`, `Reach.WeaponFlags` |
| `AAS_Reachability_WalkOffLedge` | `Reach.WalkOffLedge` |
| `AAS_GetJumpPadInfo` | `Reach.JumpPadInfo` |
| `AAS_Reachability_JumpPad` | `Reach.JumpPad` |
| `AAS_Reachability_Teleport` | `Reach.Teleport` |
| `AAS_Reachability_Elevator` (func_plat) | `Reach.Elevator` |
| `AAS_FindFaceReachabilities`, `AAS_Reachability_FuncBobbing` | `Reach.FuncBobbing` |
| `AAS_BestReachableLinkArea`, `AAS_BestReachableArea`, `AAS_BestReachableFromJumpPadArea` | `Reach.BestReachable` (`TAasReachBest`; sull'interfaccia `IAasBestReachable` sta il calcolatore) |
| `AAS_InitReachability`, `AAS_ContinueInitReachability`, `AAS_StoreReachability` | `Reach.Calculator` (`TAasReachCalculator`: `IAasReachInitializer` e `IAasBestReachable`) |
| creazione | `Reach.Factory` (`TAasReachFactory`) |
| contratti | `Reach.Intf` (`IAasReachGeometry`, `IAasReachPhysics`, `IAasBestReachable`, `IAasReachInitializer`, `IAasReachabilityEditor`) |

`TAasFile` implementa anche `IAasReachabilityEditor` (`ReplaceReachability`: `AAS_StoreReachability` alloca una tabella nuova); `TAasBspTrace`
(`Move.Types`) ha il campo nuovo `SurfaceFlags` (`bsp_trace_t.surface.flags`, la fune non si attacca al cielo: `SURF_SKY`),
riempito da `TAasCollisionWorld` dal `SurfaceFlags` della trace di `IdTech4\Collision`. Il resto di `Move.*`, `Links`, `Bsp.*` e'
usato com'e'.

### Cosa e' diverso da quello che diceva il compito

* **Non ci sono "15 aree per ciclo"**: `REACHABILITYAREASPERCYCLE` e' definita e mai usata. Il ciclo vero fa `todo = numreachabilityareas +
  framereachability` con `framereachability = 2000`, si ferma se `Sys_MilliSeconds() - start_time > reachability_delay (1000)` e
  **dopo ogni area** quando `numreachabilityareas * 1000 / numareas > lastpercentage` (`lastpercentage` resta a 0 fino alla fine della
  chiamata: con meno di 1000 aree ogni chiamata fa un'area). Il parametro `time` non e' usato. L'orologio e' dato dal costruttore
  (`TAasMilliseconds`, nil = 0). I tre `static` (`framereachability`, `reachability_delay`, `lastpercentage`) sono campi.
  `ContinueInitReachability` da' `True` anche alla chiamata che memorizza la tabella: si ripete finche' da' `False`.
* **`AAS_RandomGoalArea` e' in `be_aas_route.c`** (riga 2001), non in reach: non e' portata qui (serve la traccia del box e `random()`;
  resta fuori come scritto nel README del routing).
* **Le mappe di OpenArena non hanno la geometria quasi mai**: sono state ottimizzate (`bspc -optimize`): 52 file su 71 hanno 1 faccia, 1 spigolo
  e 0 vertici (`GEO 1 1 0 0` nelle golden). Li' i calcoli sulle facce non trovano niente e restano solo quelli delle entita' (ascensori,
  teletrasporti, trampolini). Hanno la geometria `am_galmevish`, `ce1m7`, `dm4ish`, `dm6ish`, `islanddm`, `kaos`, `oa_bases3cl`, `oa_bases5`,
  `oa_dm1`..`oa_dm7`, `oa_rpg3dm2`, `oa_shine`, `ps37ctf`, `q3dm6ish`: le golden del repository (digest: un hash per area e le righe della prima area
  con ogni tipo di viaggio, 100 KB in tutto) sono `fan` (ascensori), `oa_dm4` (geometria), `oa_shine` (func_bobbing, trampolini) e `kaos`
  (trampolini), non `oa_bases3` e `blitzkrieg3` (senza geometria). **Nessuna mappa ha una scala** (`reach_ladder` e' 0 su tutte e 71): la scala e' provata
  con tre mondi di prova (`Tests\Source\DelphiDoom.Tests.Aas.Reach.Worlds.pas`, dalla fila di scatole di `TAasSample` con gli assi scambiati e i
  flag `FACE_LADDER`; i file li scrive il test `ScrivereIMondiDiProvaPerIlPilotaC` con `DELPHIDOOM_WRITE_WORLDS`, `Make-Golden.ps1 -Worlds` li fa
  calcolare al C: `reach_world_1..3.golden.txt`, parita' completa sulle righe `R`).

### Parita' col C vero

`Tools\Verifica\122\reach`: `reachgen.c` include i VERI `be_aas_file.c`, `be_aas_sample.c`, `be_aas_move.c`, `be_aas_reach.c` (copiati da
`build.sh`, **nessuna modifica** al codice vero), butta via le raggiungibilita' del file, chiama il vero `AAS_InitReachability` e
`AAS_ContinueInitReachability` finche' non finisce e stampa per ogni area `A <area> <n> <areaflags> <hash>` (e le `R` complete: tutte in
`full`, solo quelle della prima area con ogni tipo di viaggio in `digest`), i contatori `reach_*`, i messaggi (le righe di percentuale, circa una
per area, sono solo contate e fatte hash: `PCT`). Gemello Delphi: `TAasReachScenario` (`Tests\Source\DelphiDoom.Tests.Aas.Reach.Scenario.pas`);
**se si cambia uno si cambia l'altro** e si rifanno le golden (`Make-Golden.ps1`, con `-All` anche le 71 complete in
`C:\harness\q3reach\goldens`, da dare in `DELPHIDOOM_REACH_GOLDENS`). La parita' prova la **logica**: il BSP del gioco e' sostituito da
gemelli uguali in C e in Delphi (il contenuto di un punto e la trace sono quelli del file AAS, `surface.flags` 0; le entita' e i limiti dei
modelli vengono dal `.bsp` di OpenArena, lump 0 e 7, con i limiti allargati di un'unita' come fa `cm_load.c`; le funzioni `AAS_*BSPEpairKey` sono un
piccolo gemello del parser: l'ultima coppia con la stessa chiave vince come nell'originale), quindi le raggiungibilita' calcolate **non sono
quelle del file del gioco** (che erano per il BSP vero): conta solo che C e Delphi diano le stesse righe. Le trace con grapple 1
(`grapplereach`) sono nelle golden.

**Risultato**: zero righe diverse su tutte e 71 le mappe (golden complete) e sui 3 mondi con le scale, a 32 e a 64 bit (grapple compreso).
Test: `Tests\DelphiDoom.Tests.Aas` 264 (`Reach.Golden`, `Reach.Units`, `Links`); copertura di `IdTech4\Aas` 94% con `Tools\Copertura.ps1 -Test Aas
-Cartella IdTech4\Aas` (le unit `Reach.*` tra 89% e 100%, `Links` 95%; `BestReachable` e `Ladder` 89%).

### Difetti del C vero conservati

* **`AAS_FaceCenter(face2num)` con il numero con segno** (`WeaponJump`, `JumpPad`, `Grapple`): un numero negativo legge `faces[-n]`, la memoria
  prima delle facce. Il pilota ci mette facce a zero (`calloc` prima del vettore, `reachgen.c`); una faccia a zero ha centro `0 * inf` = NaN.
  `TAasReachGeometry.FaceCenter` da' un centro NaN per un numero negativo; `WeaponJump` e `JumpPad` saltano la faccia (nel C nessun confronto
  con NaN e' vero e non succede niente: provato leggendo `AAS_HorizontalVelocityForJump`), `Grapple` segue il percorso del C con il NaN.
* **`abs()` e' intero** nel ladder: `abs(DotProduct(..)) < 0.1` e' vero per ogni prodotto tra -1 e 1 (il float e' troncato a 0); `0.7` idem.
* **`AAS_Reachability_Jump` e `_Grapple` danno sempre `qfalse`** anche se creano la raggiungibilita': `ContinueInit` non fa `continue`.
* **`AAS_Reachability_JumpPad` esce con `continue` senza `AAS_UnlinkFromAreas`** quando la velocita' orizzontale supera 100: i link restano nello
  heap (qui lo stesso, `Links.FreeCount` scende).
* **`lreach = AAS_AllocReachability()` senza controllo in `FuncBobbing`**: heap esaurito = NULL e crash nel C; qui `EAasReachException`.
* **`AAS_Reachability_Step_..._WalkOffLedge` riusa `dist`** (la distanza del piano) come distanza minima dentro il ciclo sugli spigoli di area 2:
  il valore cambia per gli spigoli dopo il primo; conservato (stessa variabile).
* `FuncBobbing` modifica `startreach->start` dentro il ciclo su `endreach` (si vede dalle coppie successive); `Elevator` allarga `mins` e `maxs` a
  ogni giro e non li ripristina; `AAS_GetJumpPadInfo` con un bersaglio sopra il trampolino da' `sqrt` di un numero negativo: NaN, e `!time` non lo prende.
* L'heap: l'errore `AAS_MAX_REACHABILITYSIZE` si stampa quando si da' l'**ultimo** link (che e' dato lo stesso); il successivo da' NULL.

### Trappole viste

1. **`VectorMA` con scala intera o float** (5, 2, 48, 64, -32, -3, -15, 8, 16, 1, -500, 4) fa due arrotondamenti a float (`float(v + float(b*s))`):
   `TAasReachVectors.MultiplyAdd`; con scala `double` (`0.1`, `0.5`) e' `TAasVectorMath.MultiplyAdd` (un arrotondamento a double).
2. **`fabs` da' un `double`**: `rs_startwalkoffledge + fabs(d) * 50 / gravity` e `rs_startgrapple + VectorLength(dir) * 0.25` sono interamente double e
   si troncano una volta a `unsigned short`; le espressioni senza `fabs` (Jump, Elevator, FuncBob) sono float. `traveltime += float` e' float e poi
   `unsigned short` (`AddTravelTime`, `Word(Trunc(x) and $FFFF)`).
3. **Confronti con un'espressione** (`mins > maxs + 10`, `dist < bestdist + 1`, `facecenter[2] < areastart[2] + 64`): float nel C, in una variabile
   `Single` prima di confrontare; quelli con `0.1`, `0.5`, `0.7` sono double (costanti `Double` tipate).
4. **Indici dei `for` dopo il ciclo** (`i >= 3`, `l >= 16`, `p >= 3`, `n = 9999` negli ascensori, `l != numedges` nel ladder): cicli `while` con un flag.
5. **`dir[p] < origin[p] + mins[p] || ...`** negli ascensori: `break` = fuori dal box, `p >= 3` = dentro e si salta.
6. **Eccezioni della FPU e precisione**: `TAasReachFloatMode` mette la maschera di tutte le eccezioni e la precisione `double` dell'x87 per la durata di
   ogni chiamata (Delphi a 32 bit arrotonda due volte un'operazione `double`); a 64 bit e' SSE e non cambia niente.
7. **Stampe con `%f`**: `printf` arrotonda al pari sul valore esatto, `Format` di Delphi no: `TAasReachFormat.Fixed`.
8. **`AAS_BestReachableArea(origin, mins, maxs, origin)`** passa lo stesso vettore due volte (`AAS_SetWeaponJumpAreaFlags`): il codice cambia `goalorigin`
   e poi legge `origin`: `TAasReachBest.BestReachableAreaInPlace`.
9. **Gli indici dei vettori del file** si controllano con `{$R+}` nelle unit di calcolo; `ERangeError` diventa `EAasReachException`.
10. Una `TAasReachContext` non e' contata: la possiede `TAasReachCalculator`, che e' un `TInterfacedObject` (l'interfaccia che si tiene vivo basta).
    La factory da' `IAasReachInitializer`; `Supports(x, IAasBestReachable)` da' le tre funzioni per `be_ai_goal.c`.

### Interfacce per la #123 (`be_ai_goal.c`, `be_ai_move.c`) e per `be_aas_entity.c`

* `IAasBestReachable`: `BestReachableArea(origin, mins, maxs, var goalorigin)`, `BestReachableLinkArea(head)` (**la testa e' una lista di
  `TAasEntityLinks`**: e' quello che chiama `AAS_BestReachableEntityArea` di `be_aas_entity.c`), `BestReachableFromJumpPadArea`.
* `IAasReachGeometry`: `FaceArea`, `AreaVolume`, `AreaGroundFaceArea`, `FaceCenter`. `IAasReachPhysics`: `FallDamageDistance`, `FallDelta`,
  `MaxJumpHeight`, `MaxJumpDistance`, `BarrierJumpTravelTime`.
* `IAasReachInitializer`: `InitReachability`, `ContinueInitReachability(time)` (per `AAS_ContinueInit` di `be_aas_main.c`: reach -> `AAS_InitClustering`
  -> `AAS_InitRouting`), `NumReachabilityAreas`, `Counters`.
* I predicati sulle aree (`AAS_AreaSwim`, `AAS_AreaGrounded`, `AAS_AreaLadder`, `AAS_AreaJumpPad` ...) sono `IAasAreaQuery`, gia' esistente.

### Non portato

`AAS_RandomGoalArea` (in `be_aas_route.c`), `AAS_PermanentLine` e le funzioni di disegno (`AAS_DebugLine`: nessun disegno), `Log_Write` (il registro
dei `funcbob`), `REACH_DEBUG`, il ramo `BSPC` (il compilatore di mappe), `bot_visualizejumppads` (le chiamate di movimento hanno `visualize` falso),
l'avviso `AAS_BestReachableArea: aas not loaded` (il file e' sempre caricato).

## Collegamento: `TAasSystemFactory` (`Main.Factory`, `Main.MapBuilder`, `Main.InitSteps`, `Main.Map`)

`TAasSystemFactory.CreateSystem(Import, Files, LibVars, World, Models, Memory, Clock, Developer)` e' il composition root del sistema AAS di Quake III: fa il lettore e, per ogni mappa caricata (`TAasMapBuilder`), i link delle entita', il campionatore, il tracciatore, il movimento, il calcolo delle raggiungibilita', il clustering, l'ottimizzatore e (a fine inizializzazione) il router; `TAasInitSteps` mette in fila `AAS_InitReachability`, `AAS_ContinueInitReachability`, `AAS_InitClustering`, `AAS_Optimize`, `AAS_InitRouting`. Le impostazioni (`AAS_InitSettings`) si leggono alla costruzione del movimento; le rotte alternative si fanno con il router (dopo il clustering: dipendono solo dal numero delle aree); `SaveFile` e' vero se la reach e' stata calcolata e non letta. Il gioco da' `IAasBspWorld` e `IAasBspModels` (`TAasCollisionWorld` e `TAasCollisionModels` sopra `IdTech4\Collision`). Test: `TTestAasSystemFactory` (mondo di prova `TAasSample`, lettore, reach, clustering e routing veri; finti solo il BSP e i file).