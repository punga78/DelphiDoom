# Libs\XcomDebriefing

> Note per Claude: [CLAUDE.md](CLAUDE.md).

La fine di una missione di **OpenXcom** a classi e senza SDL (issue #176): `DebriefingState::prepareDebriefing` e il punteggio, i diari, le medaglie e le promozioni che seguono.

| Unit | Classe | Origine C++ |
|---|---|---|
| `DelphiDoom.XcomDebriefing.Debriefing` | `TXcomDebriefing.Run` | `DebriefingState::init` |
| `...Calculator` | `TXcomDebriefingCalculator` | `prepareDebriefing` |
| `...Recovery` | `TXcomMissionRecovery` | `recoverItems`, `recoverAlien` |
| `...CraftReequipper` | `TXcomCraftReequipper` | `reequipCraft` |
| `...BaseFacilityRemover` | `TXcomBaseFacilityRemover` | `Base::destroyFacility`, `destroyDisconnectedFacilities` |
| `...Promotions` | `TXcomSoldierPromotions` | `SavedGame::handlePromotions` |
| `...Scorer` | `TXcomDebriefingScorer` | punteggio, valutazione, medaglie, diari |
| `...Types` | `TXcomDebriefingReport`, `TXcomDebriefingStat` | `DebriefingStat`, `ReequipStat`, `RecoveryItem` |

Parita' col vero `DebriefingState` su 93 esiti (0 differenze su resoconto, seme e salvataggio). Licenza: derivato da OpenXcom, GPL v3 o successiva (la decide l'utente).

Test: `Tools\build.bat Tests\DelphiDoom.Tests.XcomDebriefing`.
