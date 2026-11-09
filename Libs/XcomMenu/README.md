# Libs\XcomMenu

> Note per Claude: [CLAUDE.md](CLAUDE.md).

Gli stati di `Menu\` di **OpenXcom** a classi (issue #176): `TXcomStartState` (il terminale DOS che mostra il caricamento), `TXcomGoToMainMenuState`, `TXcomMainMenuState`. Sopra `Libs\XcomEngine` e `Libs\XcomUi`. Licenza: derivato da OpenXcom, GPL v3 o successiva (da decidere per l'opera).

Cosa fanno oggi con i dati veri di TFTD: la schermata di avvio (stesse righe, stesso cursore lampeggiante, `Loading OpenXcom ...`), poi il menu principale con il popup e il testo (`Quit` chiude; gli altri pulsanti non fanno ancora nulla: `NewGameState`, `NewBattleState`, `ListLoadState`, `ModListState` e le opzioni non sono portati). Parita': 0 pixel diversi col vero OpenXcom su entrambi i frame (`Libs\XcomEngine\README.md`).

Non portato: tutti gli altri stati di `Menu\` (opzioni in primis: servono `ComboBox`, `TextEdit`, `ArrowButton`, `ToggleTextButton`), `CutsceneState`, `VideoState`, `SlideshowState`.
