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

## Non portato

`Mod` (`Mod.cpp`, 3769 righe: carica i file e collega tutto) e le altre regole: `RuleItem`, `RuleCraft`, `RuleCraftWeapon`, `RuleUfo`, `RuleBaseFacility`, `RuleSoldier`, `Armor`, `Unit`, `RuleTerrain`, `AlienDeployment`, `AlienMission`, `MapScript`, `MapDataSet`/`MapData` (usano `mod->loadSoundOffset/loadSpriteOffset/getOffset...`, cioe' la tabella degli offset del `Mod`), `RuleGlobe`, `RuleInterface`, `RuleVideo`, `Texture`, `City` (eredita `Target` del salvataggio), `SoldierNamePool`, `StatString`, `ExtraSprites/Sounds/Strings`. Le prossime fette: `TXcomMod` come registro delle regole per tipo (con `delete`/`ignore`, `listOrder` e gli offset) e poi ognuna di queste regole con lo stesso metodo.

## Test

`Tests\DelphiDoom.Tests.XcomMod` (40 test: parita' sui 2600 casi e le regole una per una; Release Win32; copertura 92%, 775 righe su 838). Win64 e Debug non provati.
