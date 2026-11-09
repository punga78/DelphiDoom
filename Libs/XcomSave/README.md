# Libs\XcomSave

> Note per Claude: [CLAUDE.md](CLAUDE.md).

Gli oggetti di una **partita salvata** di **OpenXcom** (`Savegame\`) che si leggono e si scrivono in YAML, a classi. Issue #176 (quinta fetta, dopo `Libs\XcomFormats`, `Libs\Yaml`, `Libs\XcomSurface` e `Libs\XcomMod`): la prima fetta tiene gli oggetti che non dipendono da `Mod` ne' da `SavedGame` (data e ora, paese, regione, ricerca) e le funzioni dei numeri. Usa `Libs\Yaml` per i nodi e per l'**emitter** e `Libs\XcomMod` per le regole.

Non e' un gioco del motore Doom: nessun collegamento a `ComposeEngine` ne' a `TIdTechGeneration`.

## Licenza (da decidere)

Il codice deriva da OpenXcom, **GPL v3 o successiva** (intestazione di ogni unit); la licenza dell'opera che lo contiene la decide il proprietario del repository (questa fetta non cambia quella del repository). Nessun sorgente C++ e' nel repository (l'harness di parita' usa i file veri di OpenXcom ma sta fuori; il suo sorgente, senza codice di OpenXcom, e' in `Tools\Verifica\176\save`).

## Cosa c'e'

| C++ (OpenXcom) | Delphi |
|---|---|
| `GameTime` (`load`, `save`, `advance`, nomi di giorno e mese, `getDaylight`; `TimeTrigger`) | `TXcomGameTime`, `TXcomTimeTrigger` (`getDayString` e' `DayStringKey`: la `Language` non e' portata) |
| `Country` (`load`, `save`, `newMonth`, patto, tetto del finanziamento) | `TXcomCountry` (con `IXcomRandom` iniettato) |
| `Region` (`load`, `save`, `newMonth`, attivita') | `TXcomRegion` |
| `ResearchProject` (`load`, `save`, `step`, `getResearchProgress`) | `TXcomResearchProject` |
| `unserializeInt`, `serializeInt`, `serializeDouble` (`SerializationHelper`) | `TXcomSerialization` (`serializeDouble` usa `TYamlConvert.FormatGeneral` di `Libs\Yaml`: `%.17g`) |
| `node["k"] = value` e `vector<int>` di `save()` | `TXcomNodeWriter` (anche mappa vuota, sequenza, nodo dentro un nodo) |
| `Target` (`load`, `save`, `saveId`, `setLongitude`, `setLatitude`, `getDistance`, nome del marcatore) | `TXcomTarget` (astratta; i `MovingTarget` seguaci e i nomi con `Language` non sono portati) |
| `Waypoint`, `AlienBase`, `MissionSite` | `TXcomWaypoint`, `TXcomAlienBase`, `TXcomMissionSite` (regole minime `IXcomDeploymentRule`, `IXcomMissionRule`) |
| `Node` (RMP), `EquipmentLayoutItem` | `TXcomNode`, `TXcomEquipmentLayoutItem`; `convert<Position>` e' `TXcomPositionCodec` |
| `ItemContainer` (senza `getTotalSize`), `Vehicle`, `CraftWeapon`, `BaseFacility` (senza `inUse`) | `TXcomItemContainer`, `TXcomVehicle`, `TXcomCraftWeapon`, `TXcomBaseFacility` (regole minime `IXcomItemRule`, `IXcomFacilityRule`, `IXcomCraftWeaponRule`) |
| `Production` (dati, `getAmountProduced`, soldi; senza `step`) | `TXcomProduction` (usa `TXcomRuleManufacture` di `Libs\XcomMod`) |
| `UnitStats` e `convert<UnitStats>` | `TXcomUnitStats` (record con operatori), `TXcomUnitStatsCodec` |
| `BattleUnitKills`, `BattleUnitStatistics`, `SoldierDeath` | `TXcomBattleUnitKills`, `TXcomBattleUnitStatistics`, `TXcomSoldierDeath`; il ciclo `begin()`/`end()` su un nodo e' `TXcomNodeIteration`; le enumerazioni sono costanti in `DelphiDoom.XcomSave.UnitEnums` |

## Parita'

`Tests\Data\XcomSave\save.corpus.txt` ha 900 casi (un'intestazione con il tipo e gli argomenti e un nodo YAML casuale con seme fisso: campi giusti, mancanti, con tipo sbagliato, interi enormi) e `save.golden.txt` (12122 righe) e' cio' che i **veri** `GameTime.cpp`, `Country.cpp`, `Region.cpp`, `ResearchProject.cpp`, `SerializationHelper.cpp`, `RuleCountry.cpp`, `RuleRegion.cpp`, `RuleResearch.cpp` e `RNG.cpp` di OpenXcom con la **vera yaml-cpp 0.7.0** (g++ MinGW 32 bit, SSE) hanno stampato: lo stato dopo `load`, **il testo YAML che `save()` produce emesso dall'`Emitter` di yaml-cpp** (quindi vale anche come prova dell'emitter di `Libs\Yaml` su oggetti veri, per esempio la sequenza vuota che esce come `[]` su una riga a parte), e cio' che gli oggetti fanno dopo (40 `advance`, 4 `newMonth` con seme fisso, 14 mesi di una regione, `getResearchProgress`, `step`, interi di 1, 2 e 4 byte, nove `double` come testo). `TXcomSaveScenario` (in `Tests\Source`) fa lo stesso in Pascal: **zero differenze**.

### Seconda famiglia di oggetti (`objects.corpus.txt`, `objects.golden.txt`)

`Tests\Data\XcomSave\objects.corpus.txt` (2400 casi con seme fisso 1761) e `objects.golden.txt` (33946 righe) vengono da `Tools\Verifica\176\save\objharness.cpp`, che **non ricompila i sorgenti**: si collega agli oggetti (`objects.a`, senza `main.cpp.obj`) di una vera build 32 bit di OpenXcom (`Reference\_dati\openxcom_build`), cioe' alle classi `Savegame\*`, `Mod\*` e a yaml-cpp 0.7.0 vere. `build2.cmd <cartella>` crea `objharness.exe` (con le DLL di SDL accanto); `objharness gen <file> 2400 1761` scrive il corpus, `objharness run <corpus>` il golden. Lo stesso scenario in Pascal e' `TXcomSaveObjectScenario` (`Tests\Source\DelphiDoom.Tests.XcomSave.ObjectScenario.pas`): 0 differenze, compresi i testi delle eccezioni di yaml-cpp (`invalid node; first invalid key`, `operator[] call on a scalar`, `bad conversion`). I `double` di `Target` si confrontano come bit; le distanze con `%.10g` (libm contro x87). Per aggiungere un oggetto: tipo nel generatore, `RunCase` di `objharness.cpp` e di `TXcomSaveObjectScenario`, rigenerare.

## Differenze volute e cose trovate

- **Trovato dal golden (seconda famiglia)**: `node.as<T>(fallback)` decodifica in un `T` **nuovo** e restituisce il fallback solo se il tipo non e' quello giusto: per `UnitStats` un campo mancante e' 0, non il valore del fallback. I costruttori `BattleUnitKills(const Node&)` e `BattleUnitStatistics(const Node&)` non inizializzano i membri: un campo mancante o con tipo sbagliato e' un valore casuale in C++ (comportamento indefinito, evitato nel generatore; in Delphi e' 0). Un ciclo `begin()`/`end()` su una **mappa** come se fosse una sequenza da' un nodo non valido e la prima lettura lancia `invalid node` (un ciclo su una mappa vuota non fa nulla); su uno scalare nessun elemento.
- Un puntatore nullo del C++ (`_rules`, `_deployment`) e' `EXcomSaveException` nel costruttore; un angolo infinito o nan in `setLongitude` (ciclo infinito in C++) e' `EXcomSaveException`.

- **Comportamenti indefiniti del C++ resi errori**: un mese fuori da 1..12 in `advance` o nel nome del mese (`EXcomSaveRangeException`; l'harness li evita), un giorno della settimana fuori da 1..7 nel nome; `back()` di una lista vuota in `Country` e `Region` (`EXcomModException`), `serializeInt` con un valore che non entra (l'`assert` del C++) e dimensioni diverse da 1, 2 e 4 (`EXcomSerializationException`); un intervallo casuale vuoto (`generate(0, -1)` in `newMonth`) e' `EXcomModException` di `TXcomRandom`.
- `getResearchProgress` con un argomento di costo zero: il C++ divide un `float` per zero (+inf, -inf o nan) e Delphi darebbe un'eccezione FPU; qui i casi sono decisi a mano con lo stesso risultato (un nan fallisce ogni confronto).
- `GameTime::getDayString` ritorna il testo tradotto con il numero del giorno (usa `Language`): la libreria da' solo la chiave (`STR_DATE_FIRST`...).
- Un difetto del mio primo port, trovato dal golden: avevo letto `serializeInt` di un byte come "non scrive nulla" perche' la riga `**buffer = value;` era stata scartata da un filtro di ricerca; il golden ha mostrato `5B` dove avevo `00`.
- Le operazioni su `Single` e `Double` sono arrotondate a ogni passo (a 32 bit Delphi terrebbe 80 bit): variabili temporanee.

## Non portato

`SavedGame` (il file: intestazione, salvataggio e caricamento di tutto, `SaveInfo`), `SavedBattleGame`, `Base`, `Craft`, `Ufo`, `MovingTarget`, `Soldier`, `SoldierDiary`, `Production::step`, `Transfer`, `AlienStrategy`, `AlienMission`, `Tile`, `BattleUnit`, `BattleItem`, `SaveConverter`... : dipendono da `Mod` (offset, regole di oggetti e velivoli), da `Language` o da classi ancora da portare. Le prossime fette: `TXcomMod` (il registro delle regole), poi `Soldier`, `Base` e `SavedGame` con le sue sezioni, sempre con lo stesso metodo (veri file C++ + yaml-cpp, golden del testo emesso).

## Test

`Tests\DelphiDoom.Tests.XcomSave` (61 test: parita' sui 900 casi della prima famiglia e sui 2400 della seconda, e gli oggetti uno per uno; Release Win32; copertura 98%, 1068 righe su 1079). Win64 non provato.
