# Libs\XcomMod

> Note per Claude: [CLAUDE.md](CLAUDE.md).

Le **regole** (ruleset) di **OpenXcom** lette da YAML, a classi: primo gruppo di `Rule*` e il necessario per leggerle. Issue #176 (quarta fetta, dopo `Libs\XcomFormats`, `Libs\Yaml` e `Libs\XcomSurface`). Usa `Libs\Yaml` (il port di yaml-cpp 0.7.0) per leggere i nodi.

Non e' un gioco del motore Doom: nessun collegamento a `ComposeEngine` ne' a `TIdTechGeneration`.

## Licenza (da decidere)

Il codice deriva da OpenXcom, **GPL v3 o successiva** (intestazione di ogni unit); la licenza dell'opera che lo contiene la decide il proprietario del repository (questa fetta non cambia quella del repository, GPL v2 o successiva). Il generatore casuale e' xorshift64* di Sebastiano Vigna (pubblico dominio). Nessun sorgente C++ e' nel repository (l'harness di parita' ne usa i file veri ma sta fuori; il suo sorgente, che non contiene codice di OpenXcom, e' in `Tools\Verifica\176\mod`).

## Cosa c'e'

| C++ (OpenXcom) | Delphi |
|---|---|
| `RuleInventory` (`load`, `checkSlotInPosition`, `getCost`; `RuleSlot`) | `TXcomRuleInventory`, `TXcomRuleSlot` |
| `RuleCountry` (`load`, `generateFunding`, `insideCountry`) | `TXcomRuleCountry` |
| `RuleRegion`, `MissionArea`, `MissionZone` (`load`, `insideRegion`, `getRandomPoint`) | `TXcomRuleRegion`, `TXcomMissionArea`, `TXcomMissionZone` |
| `WeightedOptions` (`load`, `set`, `choose`, `getNames`) | `TXcomWeightedOptions` |
| `RuleResearch`, `RuleManufacture`, `AlienRace` | `TXcomRuleResearch`, `TXcomRuleManufacture`, `TXcomAlienRace` |
| `UfoTrajectory`, `TrajectoryWaypoint` | `TXcomUfoTrajectory`, `TXcomTrajectoryWaypoint` |
| `RuleMusic`, `MapBlock` (con `Position`), `RuleCommendations` | `TXcomRuleMusic`, `TXcomMapBlock`, `TXcomPosition`, `TXcomRuleCommendations`, `TXcomKillCondition` |
| `RNG` (`generate`, `setSeed`) | `IXcomRandom` / `TXcomRandom` (iniettato: il C++ ha un globale) |
| `Deg2Rad`, `Rad2Deg` (`fmath.h`), le caselle lon/lat dei paesi e delle regioni | `XcomDegToRad`, `XcomRadToDeg`, `TXcomGlobeAreas` |
| `std::map<std::string, V>` (ordinata per byte UTF-8) | `TXcomStringMap<V>` |
| `node["k"].as<T>(default)` e i convertitori `std::vector`, `std::map` di yaml-cpp | `TXcomNodeReader` (sopra `IYamlNode` di `Libs\Yaml`) |

## Parita'

`Tests\Data\XcomMod\rules.corpus.txt` ha 2600 casi (un'intestazione con il tipo di regola e un nodo YAML generato a caso con seme fisso: campi giusti, ripetuti, mancanti e con tipo sbagliato) e `rules.golden.txt` (8535 righe) e' cio' che i **veri** `RuleInventory.cpp`, `RuleCountry.cpp`, `RuleRegion.cpp`, `RuleResearch.cpp`, `RuleManufacture.cpp`, `AlienRace.cpp`, `UfoTrajectory.cpp`, `RuleMusic.cpp`, `MapBlock.cpp`, `RuleCommendations.cpp`, `WeightedOptions.cpp` e `RNG.cpp` di OpenXcom, collegati con la **vera yaml-cpp 0.7.0** (g++ MinGW 32 bit, SSE), hanno stampato dopo `load`: ogni campo (i `double` come 16 cifre esadecimali dei bit), le funzioni che si possono chiamare (posizione sugli slot, `insideCountry`, `insideRegion`, `generateFunding` e `getRandomPoint` con seme fisso, `choose`, `getCost`) e il messaggio dell'eccezione (`YAML_ERR` o `MOD_ERR`). `TXcomRuleScenario` (in `Tests\Source`) fa lo stesso in Pascal: **zero differenze**.

## Differenze volute e cose trovate

- `size_t` e' a **32 bit** (il golden viene da un eseguibile MinGW a 32 bit): `Cardinal`; un numero negativo in `[zone, altezza, velocita]` avvolge come in C++ (`as<int>` poi `size_t`).
- **Comportamenti indefiniti del C++ resi errori** (`EXcomModException`): un intervallo casuale senza divisore (`generate(-1, -2)`, cioe' `fundingBase: -1`), un'area di un paese o di una regione con meno di quattro numeri, `getCost` verso una sezione senza costo (`find(...)->second` su `end()`), `getMember` fuori dalla lista, `getRandomPoint` di una zona che non esiste o senza aree. Il golden non li stampa (l'harness li evita: `funding=undefined`, `cost=undefined`).
- `MissionArea::texture` non e' inizializzato dal C++ quando la riga ha meno di cinque numeri: qui vale 0 e non e' nel golden.
- `WeightedOptions::load` di una **sequenza** non vuota solleva `invalid node; this may result from using a map iterator as a sequence iterator...` (il C++ cammina la sequenza con un iteratore di mappa): trovato dal golden, test dedicato.
- `RuleMusic::getName` ritorna il tipo se la musica non ha un nome (trovato dal golden, `Name` e' una funzione).
- Le operazioni in virgola mobile sono arrotondate a `Double` a ogni passo (Delphi a 32 bit terrebbe 80 bit): `XcomDegToRad` e `TXcomRandom.Generate(Double, Double)` usano variabili temporanee; i letterali reali sono costanti `Double` tipizzate.
- `RNG::generate(double, double)` con `AMax = AMin` divide per zero nel C++ e da' +inf (quindi 0 + min): qui ritorna `AMin` senza eccezione FPU.
- Le stringhe sono `string` (UTF-16); le mappe confrontano i **byte UTF-8** come `std::string`.

## Il regolamento intero (`Mod::loadAll`)

`TXcomRuleset` e' la parte "regole" di `Mod`: una tabella per tipo (`TXcomRuleRegistry<T>`: mappa ordinata per nome e indice nell'ordine di arrivo, con `delete` come `Mod::loadRule`) e `LoadFile` (le 35 sezioni di `Mod::loadFile`: paesi, regioni, strutture, velivoli, armi, oggetti, UFO, inventari, terreni, corazze, soldati, unita', razze, schieramenti, ricerche, produzioni, Ufopaedia, base e tempo di partenza, costi, traiettorie, missioni, patch MCD, sprite/suoni/stringhe extra, stat string, interfacce, convertitore, costanti, script di mappa e di missione, video, musiche, menzioni, crescita delle statistiche). `TXcomModLoader.LoadAll` assegna a ogni mod posizione e spazio nei set condivisi (1000 x lo spazio dei mod prima, 1000 x il proprio), carica prima il file delle risorse (`soundDefs`, `transparencyLUTs`), poi i file di ogni mod in ordine, fa i controlli di `Mod::loadMod` (`ValidateMissions`) e alla fine `SortLists` (ordine degli indici per `listOrder`; a parita' l'ordine di arrivo).

| C++ (OpenXcom) | Delphi |
|---|---|
| `Mod::loadAll`, `loadMod`, `loadResourceConfigFile` | `TXcomModLoader.LoadAll` (`TXcomModSource`) |
| `Mod::loadFile`, le tabelle e `loadRule`, `getMapDataSet`, `sortLists`, i controlli di `loadMod` | `TXcomRuleset`, `TXcomRuleRegistry<T>`, `SortLists`, `ValidateMissions` |
| `RuleItem`, `RuleBaseFacility`, `RuleCraft`, `RuleUfo` | `TXcomRuleItem`, `TXcomRuleBaseFacility`, `TXcomRuleCraft`, `TXcomRuleUfo` |
| `RuleTerrain`, `MapDataSet`, `MapScript` | `TXcomRuleTerrain`, `TXcomMapDataSet`, `TXcomMapScript` |
| `Armor`, `RuleSoldier`, `SoldierNamePool`, `Unit`, `UnitStats` | `TXcomArmor`, `TXcomRuleSoldier`, `TXcomSoldierNamePool`, `TXcomRuleUnit`, `TXcomUnitStats` (+ `TXcomUnitStatsReader`) |
| `AlienDeployment`, `RuleAlienMission`, `RuleMissionScript` | `TXcomAlienDeployment`, `TXcomRuleAlienMission`, `TXcomRuleMissionScript` |
| `ArticleDefinition` e le sue 10 sottoclassi | `TXcomArticleDefinition` (un tipo solo: `Load` legge i campi del tipo) |
| `MCDPatch`, `ExtraSprites`, `ExtraSounds`, `ExtraStrings`, `StatString`, `StatStringCondition` | `TXcomMcdPatch`, `TXcomExtraSprites`, `TXcomExtraSounds`, `TXcomExtraStrings`, `TXcomStatString` |
| `RuleInterface`, `RuleVideo`, `RuleConverter`, `SoundDefinition` | `TXcomRuleInterface`, `TXcomRuleVideo`, `TXcomRuleConverter`, `TXcomSoundDefinition` |
| i `static` di `Mod` (porte, esplosioni, cursori, danni...), i membri numerici di `Mod` | `TXcomModConstants`, `TXcomRulesetSettings` |
| `FileMap` (cartelle e YAML virtuali), le dimensioni dei set (`SurfaceSet`, `SoundSet`) | `IXcomModFiles`, `IXcomSharedResources` |

### Parita' sui mod veri di TFTD

`Tools\Verifica\176\mod\modload.cpp` e' collegato **agli oggetti di una vera build di OpenXcom** (come l'harness di `Libs\XcomSave`), carica con `Mod::loadAll` i mod di TFTD (`Reference\_dati\xcom_tftd\openxcom`: `xcom2` da solo, e `xcom2` con 11 mod che cancellano e sovrascrivono regole) e scarica ogni regola come righe di testo (`Tests\Data\XcomMod\tftd.*.golden.txt.gz`, 170 KB ciascuno). `TTestXcomModReal` carica gli **stessi file YAML** con `TXcomModLoader` e dice **0 differenze** su 34 sezioni (22814 righe e 1,2 MB di testo per il solo `xcom2`: 150 oggetti per 85 campi, 768 righe di corazze, 34 liste di nomi di soldati, blocchi di mappa, articoli, script...). Il test si salta (`Assert.Pass`) senza i dati di TFTD, che non stanno nel repository. Non sono confrontati tre dati che il C++ non rende riproducibili: `MissionArea::texture` (non inizializzato), l'ordine degli `armor` senza oggetto (confronto fra puntatori) e l'ordine delle chiavi di `startingBase` (si ordinano). Rigenerare: `Tools\Verifica\176\mod\regen-real.ps1`.

## Non portato

`RuleGlobe`, `Polygon`, `Polyline`, `Texture` (il globo: `data` legge `WORLD.DAT`, che sa leggere `Libs\XcomFormats`), `City`, `MapData` e `MapDataSet::loadData` (gli MCD si leggono a battaglia: `Libs\XcomFormats`), la logica con il generatore casuale di `MapScript` e `RuleMissionScript` (`getNextBlock`, `generate`, `getMissionTypes`), e il resto di `Mod` che non e' regola: risorse (`loadVanillaResources`, `loadBattlescapeResources`, `loadExtraResources`, `modResources`, palette, font, suoni, musica), `newSave`, `genSoldier`, `ModScript`, `ModInfo` e `Options` (lista dei mod e `metadata.yml`: il caricatore riceve gia' nome, spazio e file).

## Test

`Tests\DelphiDoom.Tests.XcomMod` (79 test: parita' sui 3000 casi delle regole singole, parita' sui mod veri di TFTD, regolamento e caricatore con YAML scritto nei test; Release Win32; copertura 91%, 3390 righe su 3706 con i dati di TFTD presenti). Win64 e Debug non provati (Debug serve alla misura della copertura).
