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

Schermate e collegamento:

| Unit | Classe | Origine C++ |
|---|---|---|
| `...DebriefingState` | `TXcomDebriefingState` | `DebriefingState` (le due pagine, il messaggio dell'alieno morto senza contenimento, i tooltip) |
| `...CannotReequipState` | `TXcomCannotReequipState` | `CannotReequipState` |
| `...CommendationState` | `TXcomCommendationState` | `CommendationState` (medaglie) |
| `...CommendationLateState` | `TXcomCommendationLateState` | `CommendationLateState` (medaglie dei caduti) |
| `...CommendationNames` | `TXcomCommendationNames` | il nome del livello di una medaglia (il ciclo `skipCounter` delle due schermate) |
| `...PromotionsState` | `TXcomPromotionsState` | `PromotionsState` |
| `...ManageAlienContainmentState` | `TXcomManageAlienContainmentState` | `Basescape\ManageAlienContainmentState` |
| `...FollowUp` | `TXcomDebriefingFollowUp` | `DebriefingState::btnOkClick` (quali schermate seguono e in che ordine, salvataggio ironman o automatico) |
| `...Debriefer.Intf`, `...Debriefer` | `IXcomMissionDebriefer`, `TXcomMissionDebriefer` | la facciata che il Battlescape chiama a battaglia finita |

`Soldier::calcStatString` e' in `TXcomSoldier.CalcStatString` (`Libs\XcomSave`) e il debriefing lo richiama per i soldati che tornano.

Parita' dei pixel col vero OpenXcom (risorse vere di TFTD, `debriefgen` con `DEBRIEF_PIXELS=1`): le due pagine del debriefing, `CannotReequipState`, `PromotionsState`, `ManageAlienContainmentState`, `CommendationState` e `CommendationLateState` a **0 pixel diversi** su 93 casi (569 schermate, 36,4 milioni di pixel); 5 casi sono nel repository (`Tests\Data\XcomDebriefing\pixels`). Cosa non e' confrontato: vedi CLAUDE.md.

Aggiornamento (sessione "collegamenti", #176): parita' col vero `DebriefingState` anche su siti di missione, basi aliene, carri e zombie (48 casi nuovi, 0 differenze); musica del debriefing (`TXcomDebriefingState.Music`).
