# Libs\XcomMenu

> Note per Claude: [CLAUDE.md](CLAUDE.md).

Gli stati di `Menu\` di **OpenXcom** a classi (issue #176): `TXcomStartState` (il terminale DOS che mostra il caricamento), `TXcomGoToMainMenuState`, `TXcomMainMenuState`, `TXcomNewGameState` (la scelta della difficolta'). Sopra `Libs\XcomEngine` e `Libs\XcomUi`. Licenza: derivato da OpenXcom, GPL v3 o successiva (da decidere per l'opera).

Cosa fanno oggi con i dati veri di TFTD: la schermata di avvio (stesse righe, stesso cursore lampeggiante, `Loading OpenXcom ...`), poi il menu principale con il popup e il testo (`Quit` chiude, `New Game` apre la scelta della difficolta' con i cinque pulsanti di gruppo, l'interruttore Ironman, OK e Cancel; OK non fa ancora nulla, serve la geoscape; gli altri pulsanti non fanno nulla: `NewBattleState`, `ListLoadState`, `ModListState` e le opzioni non sono portati). Parita': 0 pixel diversi col vero OpenXcom sui tre frame (avvio, menu principale, scelta della difficolta' con il cursore) (`Libs\XcomEngine\README.md`).

Non portato: tutti gli altri stati di `Menu\` (opzioni in primis: servono `ComboBox`, `TextEdit`, `ArrowButton`, `ToggleTextButton`), `CutsceneState`, `VideoState`, `SlideshowState`.

Aggiornamento (sessione "schermate mancanti", #176): `TXcomCutsceneState`, `TXcomSlideshowState`, `TXcomVideoState` (filmati FLI/FLC e diapositive, introduzione con `playIntro`), `TXcomNewBattleState` (battaglia rapida) e `TXcomModConfirmExtendedState` ci sono; restano fuori `ListLoadOriginalState` e `TestState`. Vedi `CLAUDE.md`.
