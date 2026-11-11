# Libs\XcomStrategy

> Note per Claude: [CLAUDE.md](CLAUDE.md).

Il gioco strategico di **OpenXcom** che gira mentre il tempo del geoscape passa, a classi e senza SDL (issue #176): la produzione, i velivoli di una base, le missioni aliene, i radar, gli script delle missioni e i passi del tempo di `GeoscapeState`.

| Unit | Classe | Origine C++ |
|---|---|---|
| `DelphiDoom.XcomStrategy.Simulation` | `TXcomGeoscapeSimulation` | `GeoscapeState::time5Seconds` ... `time1Month`, `timeAdvance` |
| `...UfoTracker`, `...CraftTracker`, `...BaseWork`, `...AlienPlanner` | i passi per UFO, velivoli, basi e aliene | le parti di `time*` |
| `...MissionScriptRunner` | `TXcomMissionScriptRunner` | `determineAlienMissions`, `processCommand` |
| `...UfoSpawner`, `...MissionSites`, `...MissionThinker`, `...UfoWaypointHandler` | missioni | `AlienMission::spawnUfo`, `think`, `ufoReachedWaypoint`, `ufoLifting`, `spawnMissionSite`, `spawnAlienBase` |
| `...BaseRadar` | `TXcomBaseRadar` | `Base::detect`, `Base::insideRadarRange` |
| `...ProductionStepper`, `...BaseCrafts` | produzione e velivoli della base | `Production::step`, `Base::getCraftCount`, `Base::removeCraft` |
| `...Geography` | `TXcomGeography` | `SavedGame::locateRegion`, `killSoldier`, `Nautical` |
| `...Events.Intf`, `...NullEvents`, `...Settings.Intf`, `...DefaultSettings` | eventi (i popup) e opzioni | `popup(...)`, `Options::...` |
| `...LandMap.Intf`, `...PolygonLandMap` | terra del globo | `Globe::insideLand` |
| `...Factory` | `TXcomStrategyFactory` | composition root |

Le dipendenze (ruleset, generatore casuale, eventi, opzioni) arrivano dal costruttore. Dogfight, battaglia di una base e cascata delle ricerche non sono portati (vedi CLAUDE.md). Licenza: derivato da OpenXcom, GPL v3 o successiva (la decide l'utente).

Test: `Tools\build.bat Tests\DelphiDoom.Tests.XcomStrategy`.


## Ricerca e rapporto mensile (issue #176)

`TXcomResearchRules`, `TXcomResearchCompletion` (la cascata delle ricerche finite, spenta di default) e `TXcomMonthlyReport`, con parita' sugli oggetti veri di OpenXcom (scenari `research` e `report` di `Tools\Verifica\176\save\simgen.cpp`). Dettagli in `CLAUDE.md`.
