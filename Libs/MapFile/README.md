# Libs\MapFile

> Note per Claude e paragrafi di dettaglio: [CLAUDE.md](CLAUDE.md).

Lettura e scrittura dei file **`.map` di id Tech 4** (Doom 3): modello neutro (mappa, entita', brush, facce, patch), lettore, scrittore. Issue #106 (indice: #94). Port a classi di `idMapFile`, `idMapEntity`, `idMapBrush`, `idMapBrushSide` e `idMapPatch` di `idlib\MapFile.cpp/.h` (`Reference\doom3`, sola lettura). **Non ha chiamanti nel motore** (percorso freddo): serve a creare e a leggere livelli (#47) e ai file compilati (#107: .proc e .aas, sezione sotto) e, in seguito, al BSP di Quake III (#116).

**Licenza.** Port di codice di Doom 3: **GPL v3 con i termini aggiuntivi di Doom 3**, dichiarato nell'intestazione di ogni unit ("Based on the Doom 3 GPL Source Code (id Software)"); il repository e' GPL v2 o successiva (vedi `Libs\IdLib\README.md`). Le unit scritte per questa libreria senza derivare da `MapFile.cpp` (`Factory`) hanno la licenza del repository.

## Cosa fa

- **Formato**: righe `Version N` (assente = versione 1), entita' `{ "chiave" "valore" ... }`, primitive `{ brushDef3 { ... } }`, `{ patchDef3 { ... } }`; sono letti anche `brushDef` / `brushDef2` (tre punti per faccia o piano, matrice 2x3), `patchDef2`, e i brush senza parola chiave di Quake III (tre punti, materiale, spostamento, rotazione e scala). Prima della versione 2 i materiali prendono il prefisso `textures/`. Si scrive sempre la versione 2: `brushDef3`, `patchDef2` (se la patch non ha le suddivisioni esplicite) e `patchDef3`.
- **Modello** (classi con proprieta', una per unit): `TMapFile` (entita' in ordine, versione, nome, ora del file, CRC geometrico, ricerca e rimozione), `TMapEntity` (`Epairs: TIdDict`, primitive), `TMapPrimitive` (base), `TMapBrush` + `TMapBrushSide` (piano `TGeoPlane`, matrice della texture, origine, vettori della texture), `TMapPatch` (griglia di `TMapPatchVertex`: posizione e coordinate s/t).
- **Lettura**: `TMapFileReader` (`IMapFileReader`: `Parse` da file con la ricerca di `.reg` prima di `.map`, `ParseText` da memoria) con `TMapEntityReader`, `TMapBrushReader` (anche `ParseQ3`), `TMapPatchReader`, `TMapDirectives` (le chiavi del worldspawn `removeEntities*`, `overrideMaterial`, `forceEntityNames`, `moveFuncGroups`). I punti dei brush a tre punti e dei punti delle patch sono spostati dall'`origin` dell'entita'.
- **Scrittura**: `TMapFileWriter` (`IMapFileWriter`: `Write` nel file system iniettato, `ToText`) con `TMapEntityWriter`, `TMapBrushWriter`, `TMapPatchWriter`, `TMapTextWriter` (buffer e formato dei float di `idFile::WriteFloatString`: dieci decimali, poi zeri e punto finali tolti).
- **CRC geometrico** (`TMapGeometryCrc`, `GetGeometryCrc` di ogni classe): non e' un CRC-32 ma uno xor dei bit dei float e di un hash del testo (`FloatCRC`, `StringCRC`).
- **Punto di creazione**: `TMapFileFactory` (`DelphiDoom.MapFile.Factory`).

## Riuso

| Si usa | Da |
|---|---|
| `TIdLexer`, `TIdToken`, `TIdStr`, `TIdStrings` (anche `FloatArrayToString` per i float scritti) | `Libs\IdLib\Text` |
| `TIdDict` (le coppie di entita' e primitive, `MatchPrefix`, `GetVector`) | `Libs\Scanner` |
| `TIdCNumbers.ScanFloats` (la chiave `origin`) | `Libs\Scanner` |
| `TGeoVec3`, `TGeoPlane` (`FromPoints`) | `Libs\Geometry` |
| `TIdVec4` (vettori della texture), `TIdMath` | `Libs\IdLib\Math` |
| `IIdLibFileSystem`, `IIdLibLog`, `EIdLibException` | `Libs\IdLib\Core` |

Estensione fatta altrove: `TIdStrings.FormatFixed` (`Libs\IdLib\Text`) e' ora esatta fino a **10 decimali** (prima 9).

## Differenze dal C++

- `idMapFile::Parse` riempie un oggetto passato; `IMapFileReader.Parse` **restituisce** una mappa nuova (o `nil` se il file non c'e'), il chiamante la libera.
- Il file system e' iniettato: `Write` non sceglie fra `fs_devpath` e un percorso esplicito (lo fa il file system). L'ora del file viene da `IIdLibFileSystem`.
- Gli errori sono `EMapFileException` (messaggio del lexer, "file F, line N: testo", e `Line`) invece di `common->Error`; un errore non torna `NULL` (nel C++ dopo `src.Error` si ritorna `NULL`, ma l'errore del lexer e' fatale: il ramo non si raggiunge).
- Una patch ha al massimo `MAX_PATCH_VERTICES` (1048576) punti: nel C++ non c'e' limite e il prodotto dei due numeri del file e' la dimensione dell'allocazione. Larghezza o altezza 0 sono un errore come nel C++ (`idSurface_Patch::SetSize`, errore fatale senza file e riga).
- Il modello di una patch tiene solo la griglia dei punti (posizione, s, t): la tassellazione di `idSurface_Patch` (`Subdivide`, normali, tangenti, indici) **non e'** portata.
- `RemoveEntities`/direttive: le chiavi `removeEntities*` si leggono **tutte** prima di rimuovere (nel C++ si continua a leggere il worldspawn anche se la rimozione lo ha liberato: comportamento indefinito).
- `NeedsReload` prende il file system come parametro. **Difetto del C++ conservato**: cerca il nome *senza* estensione, che non e' un file: per una mappa letta da disco chiede sempre di ricaricare.
- Un `TMapPatchVertex` non ha normale, tangenti e colore di `idDrawVert` (un file `.map` non li contiene).

## Difetti del C++ conservati (provati dal golden)

- Una chiave senza valore (`"dangling"` a fine riga) ha valore vuoto (`ReadTokenOnLine` ha azzerato il token).
- `StringCRC` usa `char` con segno: un carattere sopra 127 entra nel CRC come numero negativo a 32 bit.
- Il testo scritto non si rilegge uguale per i float piccoli: dieci decimali non bastano (`0.00048828125` si scrive `0.0004882812`) e il lexer converte i numeri a mano (anche il vero idLib). Dopo la prima riscrittura il testo e il CRC sono stabili.
- Le chiavi e i valori si scrivono senza escape: un `"` nel valore da' un file che non si rilegge.
- La scrittura mette `// primitive N` ma non scrive le coppie delle patch (le coppie dei brush si').

## Prova

- `Tests\DelphiDoom.Tests.MapFile` (`Tools\build.bat DelphiDoom.Tests.MapFile`): 96 test, copertura 97% delle unit nuove. **Parita' col vero C++** (`Tests\Data\MapFile\mapfile.golden.txt`, 557 righe): l'uscita di `MapFile.cpp`, `Lexer.cpp`, `Dict.cpp`, `Str.cpp`... compilati con `bcc32c` su 15 file `.map` e un `.reg` scritti per il test (17 casi) (versioni 1 e 2, brush e patch, Quake III, direttive, `.reg`, errori): conteggi, piani, matrici, CRC, punti delle patch e **testo riscritto** (byte per byte). Come e' fatta: [Tests\Data\MapFile\README.md](../../Tests/Data/MapFile/README.md).
- Win32 e Win64: 96 test passano in entrambi.

## Non portato (resta da fare)

- Le altre parti della #106: nessuna; resta fuori il **collegamento al motore** e al codice che usa le mappe (dmap, collisione: `Libs\Collision` ha un lettore e uno scrittore dei `.cm`, ma non legge le mappe).
- Scrittura nel formato di Quake III (la #115 la dice "da valutare"): la lettura c'e', la scrittura non.
- Tassellazione delle patch (`idSurface_Patch`).
- File compilati del livello `.proc`, `.cm`, `.aas` (#107): il `.cm` ha gia' lettore e scrittore in `Libs\Collision`; `.proc` e `.aas` mancano. BSP di Quake III (#116).

## File compilati del livello (#107, prima fetta): `.proc` e `.aas`

**Nello stesso schema del `.map`** (modello posseduto, lettore che riceve il testo dal file system iniettato, `Factory`, eccezioni con file e riga, percorso freddo, nessun chiamante nel motore). Licenza: codice derivato da Doom 3 (`RenderWorld_load.cpp`, `dmap\output.cpp`, `tools\compilers\aas\AASFile.cpp`, `AASFile_sample.cpp`), GPL v3 con termini aggiuntivi, dichiarato in ogni unit.

**`.cm`: non toccato.** Ha gia' lettore e scrittore in `Libs\Collision` (`TCollisionFileReader`, `TCollisionFileWriter`, `TCollisionTokenizer`): duplicarli non darebbe nulla, resta li' e non e' collegato a questa libreria.

**`.proc`** (file testuale `mapProcFile003`): lettura **e scrittura**. `TProcFile` (`DelphiDoom.MapFile.Proc.ProcFile`: modelli, modelli d'ombra, numero di aree, portali, nodi; tutto posseduto), `TProcModel`/`TProcSurface` (nome del materiale, vertici `TProcVertex` con posizione, s, t e normale, indici), `TProcShadowModel` (vertici, indici, `noCaps`, `noFrontCaps`, bit dei piani, `Bounds`), `TProcPortal` (punti e le due aree), `TProcNode` (piano a b c d e due figli). Lettori `TProcFileReader` (`IProcFileReader`: `Parse`, `ParseText`) con `TProcModelReader`, `TProcShadowModelReader`, `TProcPortalReader`, `TProcNodeReader`, `TProcParse`; scrittura `TProcFileWriter` (`IProcFileWriter`) con `TProcModelWriter`, `TProcShadowModelWriter`, `TProcPortalWriter`, `TProcNodeWriter`, `TProcMatrixWriter` nel **formato di dmap** (stessi commenti, 3 vertici e 18 indici per riga, interi senza decimali se entro 0,001); `TProcFileValidator` controlla i riferimenti (indici dei vertici, triangoli interi, conteggi dell'ombra, punti dei portali, figli dei nodi), cosa che il C++ non fa al caricamento. `TProcFileFactory`. Il file `.proc` si legge e si riscrive **identico** (test sul testo nel formato di dmap).

**`.aas`** (file testuale `DewmAAS "1.07"`): **sola lettura**. `TAasFile` (piani `TGeoPlane` con la distanza del file come `idPlane::SetDist`, vertici, spigoli, indice degli spigoli, facce, indice delle facce, aree `TAasArea`, nodi, portali, indice dei portali, cluster, `TAasSettings`), `TAasReachability` (un solo tipo con `TravelType`, il tipo speciale ha il `TIdDict`), `TAasFileReader` (`IAasFileReader`: `Parse(nome, crc)` e `ParseText`) con `TAasSettingsReader`, `TAasGeometryReader`, `TAasAreaReader`, `TAasTreeReader`, `TAasParse`; `TAasGeometry` (centri e bounds di spigoli, facce e aree, flag di viaggio, profondita' dell'albero); `TAasFileFactory`. Come `idAASFileLocal::Load`: i bounds e i flag di viaggio di ogni area si calcolano dopo la lettura, le reachability sono nell'ordine della catena del C++ (l'inverso del file) e collegate alle inverse (`ReverseReach`), un CRC atteso diverso e' `EAasFileOutOfDateException`, un albero piu' profondo di 128 e' un avviso nel log.

**Parita' col vero C++ dimostrata per l'`.aas`**: `Tests\Data\MapFile\aas.golden.txt` e' l'uscita del **vero** `AASFile.cpp` e `AASFile_sample.cpp` con `Lexer.cpp`, `Dict.cpp`, `Str.cpp`, `Token.cpp` e la matematica di idlib compilati con `bcc32c` (32 bit) su 8 file (`aas_rooms.aas` scritto da `Tools\Verifica\107\Make-AasSample.ps1`: tre stanze con 5 reachability di cui una speciale, albero, portale e cluster; minimo; versione, id, parola e file troncato sbagliati; CRC atteso giusto e sbagliato; file assente): piani, vertici, spigoli, facce, aree con bounds e flag, ogni reachability e la catena inversa, nodi, portali, cluster, impostazioni, profondita' e conteggio. **Zero differenze** (anche i bit dei float di gravita'). `TTestAasGolden` rifa ogni caso con le classi Delphi. Come si rifa: `Tests\Data\MapFile\harness\aas_build.ps1.txt`, `aas_driver.cpp.txt`, `aas_precompiled.h.txt`. Due scarti dichiarati nel test: `MaxAreaTravelTime` dei portali e' **non inizializzato** nel C++ dopo il caricamento (243 nell'harness; qui 0), e `GetCRC()` del C++ dà il CRC passato dal chiamante, non quello del file (qui `Crc` e' quello del file).

**Parita' del `.proc`: NON provata col C++.** `ParseModel`, `ParseShadowModel`, `ParseInterAreaPortals` e `ParseNodes` sono metodi di `idRenderWorldLocal` (renderer, gestore dei modelli, dichiarazioni dei materiali): non si compilano senza portare mezzo renderer in un harness. Il lettore e' scritto leggendo il C++ e lo scrittore leggendo `output.cpp`; la prova e' il giro identico sul testo nel formato di dmap scritto a mano (`Tests\Source\DelphiDoom.Tests.MapFile.ProcSample.pas`). Nessun livello di Doom 3 e' nel repository.

**Differenze dal C++ e difetti trovati** (`.proc` e `.aas`): (1) limiti sui conteggi (`MAX_PROC_ELEMENTS`, `MAX_AAS_ELEMENTS`, 4 milioni): il C++ alloca quanto dice il file; (2) numeri di area dei portali, aree e vertici/facce/spigoli indicizzati dalle facce e dalle aree, figli dei nodi e destinazioni delle reachability **fuori intervallo** sono errori: il C++ li usa come indici (lettura o scrittura fuori dai limiti); (3) **difetto del C++**: `idAASSettings::ParseBBoxes` scrive `boundingBoxes[numBoundingBoxes++]` senza controllare il massimo di 4 (scrittura fuori dall'array con 5 box): qui e' un errore; (4) **difetto del C++**: `idAASFileLocal::MaxTreeDepth_r` non ferma i cicli (un albero con un ciclo non termina) e con meno di due nodi legge `nodes[1]` fuori dalla lista: qui un nodo raggiunto due volte e' un errore (visita iterativa, senza ricorsione) e la profondita' e' 0; (5) l'`.aas` e' letto **senza `LEXFL_NOFATALERRORS`**: gli errori del lexer sono eccezioni invece di avvisi che fanno restituire `false` (e una impostazione sconosciuta ferma la lettura invece di essere un avviso); (6) il centro di un'area e' `AreaCenter`, non `AreaReachableGoal` (serve `Trace`, non portata): i file di prova non hanno aree con i flag `AREA_REACHABLE_*`; (7) `rev_next`/`areaTravelTimes` e il resto del routing non sono modellati; (8) modelli e modelli d'ombra sono due liste (il C++ ne ha una) e il materiale e' il suo nome (niente `declManager`).

**Prova**: 85 test nuovi in `Tests\DelphiDoom.Tests.MapFile` (181 in tutto), copertura 91-100% delle unit nuove (98% di tutta la libreria). Win32 e Win64: 181 passano (a 64 bit servono i dati in `bin\Tests\Data`, li copia `build.bat tests`).
## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
