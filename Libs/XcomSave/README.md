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
| `node["k"] = value` e `vector<int>` di `save()` | `TXcomNodeWriter` |

## Parita'

`Tests\Data\XcomSave\save.corpus.txt` ha 900 casi (un'intestazione con il tipo e gli argomenti e un nodo YAML casuale con seme fisso: campi giusti, mancanti, con tipo sbagliato, interi enormi) e `save.golden.txt` (12122 righe) e' cio' che i **veri** `GameTime.cpp`, `Country.cpp`, `Region.cpp`, `ResearchProject.cpp`, `SerializationHelper.cpp`, `RuleCountry.cpp`, `RuleRegion.cpp`, `RuleResearch.cpp` e `RNG.cpp` di OpenXcom con la **vera yaml-cpp 0.7.0** (g++ MinGW 32 bit, SSE) hanno stampato: lo stato dopo `load`, **il testo YAML che `save()` produce emesso dall'`Emitter` di yaml-cpp** (quindi vale anche come prova dell'emitter di `Libs\Yaml` su oggetti veri, per esempio la sequenza vuota che esce come `[]` su una riga a parte), e cio' che gli oggetti fanno dopo (40 `advance`, 4 `newMonth` con seme fisso, 14 mesi di una regione, `getResearchProgress`, `step`, interi di 1, 2 e 4 byte, nove `double` come testo). `TXcomSaveScenario` (in `Tests\Source`) fa lo stesso in Pascal: **zero differenze**.

## Differenze volute e cose trovate

- **Comportamenti indefiniti del C++ resi errori**: un mese fuori da 1..12 in `advance` o nel nome del mese (`EXcomSaveRangeException`; l'harness li evita), un giorno della settimana fuori da 1..7 nel nome; `back()` di una lista vuota in `Country` e `Region` (`EXcomModException`), `serializeInt` con un valore che non entra (l'`assert` del C++) e dimensioni diverse da 1, 2 e 4 (`EXcomSerializationException`); un intervallo casuale vuoto (`generate(0, -1)` in `newMonth`) e' `EXcomModException` di `TXcomRandom`.
- `getResearchProgress` con un argomento di costo zero: il C++ divide un `float` per zero (+inf, -inf o nan) e Delphi darebbe un'eccezione FPU; qui i casi sono decisi a mano con lo stesso risultato (un nan fallisce ogni confronto).
- `GameTime::getDayString` ritorna il testo tradotto con il numero del giorno (usa `Language`): la libreria da' solo la chiave (`STR_DATE_FIRST`...).
- Un difetto del mio primo port, trovato dal golden: avevo letto `serializeInt` di un byte come "non scrive nulla" perche' la riga `**buffer = value;` era stata scartata da un filtro di ricerca; il golden ha mostrato `5B` dove avevo `00`.
- Le operazioni su `Single` e `Double` sono arrotondate a ogni passo (a 32 bit Delphi terrebbe 80 bit): variabili temporanee.

## Non portato

`SavedGame` (il file: intestazione, salvataggio e caricamento di tutto, `SaveInfo`), `SavedBattleGame`, `Base`, `Craft`, `Ufo`, `Soldier`, `Production`, `Transfer`, `AlienStrategy`, `AlienMission`, `Target`, `Waypoint`, `MissionSite`, `Tile`, `BattleUnit`... : dipendono da `Mod` (offset, regole di oggetti e velivoli), da `Language` o da classi ancora da portare. Le prossime fette: `TXcomMod` (il registro delle regole), poi `Soldier`, `Base` e `SavedGame` con le sue sezioni, sempre con lo stesso metodo (veri file C++ + yaml-cpp, golden del testo emesso).

## Test

`Tests\DelphiDoom.Tests.XcomSave` (25 test: parita' sui 900 casi e gli oggetti uno per uno; Release Win32; copertura 100%, 332 righe su 332). Win64 e Debug non provati.
