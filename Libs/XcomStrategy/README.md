# Libs\XcomStrategy

> Note per Claude: [CLAUDE.md](CLAUDE.md).

La logica strategica di **OpenXcom** che non sta negli oggetti del salvataggio (`Libs\XcomSave`): la produzione, i velivoli di una base e le missioni aliene, a classi e senza SDL. Issue #176.

| Unit | Classe | Origine C++ |
|---|---|---|
| `DelphiDoom.XcomStrategy.Types` | `EXcomStrategyException`, `TXcomProductionProgress` | `productionProgress_e` |
| `DelphiDoom.XcomStrategy.BaseCrafts` | `TXcomBaseCrafts` (`Count`, `Remove`) | `Base::getCraftCount`, `Base::removeCraft` |
| `DelphiDoom.XcomStrategy.ProductionStepper` | `TXcomProductionStepper` | `Production::step`, `startItem`, `haveEnoughMaterialsForOneMoreUnit` |

Le dipendenze (ruleset, generatore casuale) arrivano dal costruttore. Licenza: derivato da OpenXcom, GPL v3 o successiva (la decide l'utente).

Test: `Tools\build.bat Tests\DelphiDoom.Tests.XcomStrategy`.
