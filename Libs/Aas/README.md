# Libs\Aas

Port a classi dell'**AAS di Quake III Arena** (Area Awareness System di `code\botlib`, GPL v2 o successiva, id Software), issue #122 (parte di #115, indice id Tech 3). **Prima fetta**: il file `.aas` in sola lettura e il campionamento che non dipende dal gioco (`aasfile.h`, `be_aas_file.c`, `be_aas_sample.c`). La libreria non ha chiamanti nel motore (percorso freddo). Intestazione di ogni unit: "Based on the Quake III Arena GPL Source Code (id Software)", GPL v2 o successiva.

**Non e' l'AAS di Doom 3.** `Libs\MapFile` (`DelphiDoom.MapFile.Aas.*`, #107) legge il formato di id Tech 4: testo (`DewmAAS`, versione `1.07`, numeri come token), non c'e' nulla di uguale al formato di Quake III (binario, identificatore `EASS`, versione 5, 14 lump di record `packed`). Non c'e' nulla da riusare di quella libreria e nessuna interfaccia comune e' stata forzata: i concetti uguali (area di un punto, tempo di viaggio) avranno un'interfaccia comune quando ci sara' anche il percorso (`be_aas_route.c`, resta da fare).

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

Verso il gioco e verso il file system solo interfacce **gia' esistenti in `Libs\BotAi`** (`DelphiDoom.BotAi.Import.Intf`: `IBotImport` = `botimport.Print`, `IBotFileSource` = `botimport.FS_*`, `IBotLibVars` = `LibVarGetString("sv_mapChecksum")`; `DelphiDoom.BotAi.Types`: `PRT_*`, `BLERR_NOERROR`): nessuna interfaccia duplicata. `ParseBytes` legge un file gia' in memoria e solleva `EAasFileException` (con il codice `BLERR_*`). L'import e' facoltativo (`nil`: niente messaggi).

## Mappa C -> Delphi

| C | Delphi |
|---|---|
| `aasfile.h` (costanti, `aas_header_t`, `aas_bbox_t`, `aas_plane_t`, `aas_edge_t`, `aas_face_t`, `aas_area_t`, `aas_areasettings_t`, `aas_reachability_t`, `aas_node_t`, `aas_portal_t`, `aas_cluster_t`) | `DelphiDoom.Aas.Types`: record `packed` (`SizeOf` testato: 124, 32, 20, 8, 24, 48, 28, 44, 12, 20, 16), `TVec3` di `Libs\MathCore` |
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

- **Compilatore `bspc` e raggiungibilita'** (`be_aas_reach.c` salvo i predicati sulle aree, `be_aas_cluster.c`, `be_aas_optimize.c`): le raggiungibilita' sono gia' nel file.
- **Scrittura** (`AAS_WriteAASFile`, `AAS_WriteAASLump`): serve solo al compilatore. I test scrivono i file con `TAasSample.Layout`.
- **`AAS_DumpAASData`, `AAS_FileInfo`** (debug, `AASFILEDEBUG`): la memoria e' degli array dinamici.
- **Entita' collegate alle aree** (`AAS_LinkEntity`, `AAS_UnlinkFromAreas`, `AAS_AreaEntityCollision`, `be_aas_entity.c`): dipendono dal gioco (`AAS_EntityCollision`, BSP). `TraceClientBBox` accetta `APassEntity` ma, senza entita' collegate, non ne colpisce nessuna, come il C con liste vuote. La discesa dell'albero con un box e' portata come `BBoxAreas`; l'heap dei 6144 link non e' modellato.
- **`be_aas_route.c`** (tempi di viaggio, cache), **`be_aas_routealt.c`**, **`be_aas_move.c`** (previsione del movimento), **`be_aas_main.c`** (inizializzazione, tempo, frame), **`be_aas_bspq3.c`** (interfaccia col BSP del gioco), **`be_aas_debug.c`**: prossime fette di #122.
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

`Tests\DelphiDoom.Tests.Aas` (103 test, 100 senza OpenArena), copertura 97% (850 righe su 872, ogni unit >= 92%) con `Tools\Copertura.ps1 -Test Aas`. Win32 e Win64 (a 64 bit i dati si cercano in `bin\Win32\Release\Tests\Data`: `robocopy Tests\Data\Aas bin\Win32\Release\Tests\Data\Aas`). In un worktree serve `DCC_UnitSearchPath` con la cartella di DUnitX (vedi `Libs\War\CLAUDE.md`).
