# Libs\XcomMenu - note per Claude

`Libs\XcomMenu` (issue #176, fetta "menu") ha gli stati di `Menu\` di **OpenXcom** gia' portati: `TXcomStartState` (riceve un `TXcomGameLoadTask`, la riga del prompt DOS e il testo della versione; all'`Init` avvia il task; al successo `Host.AdoptData` e `SetState(TXcomGoToMainMenuState)`; all'errore mostra l'errore e aspetta un tasto), `TXcomGoToMainMenuState` (`UpdateScale` della geoscape e `SetState(TXcomMainMenuState)`) `TXcomNewGameState` (popup verticale, cinque pulsanti di un `TXcomButtonGroup`, `TXcomToggleTextButton` Ironman; Cancel e Esc chiudono, OK non fa nulla: mancano il salvataggio e la geoscape) e `TXcomMainMenuState` (finestra con popup, sei pulsanti, titolo grande con la versione piccola sotto; Quit e New Game sono collegati). Sopra `Libs\XcomEngine` e `Libs\XcomUi`. **Non tocca** `ComposeEngine` ne' `TIdTechGeneration`. **Licenza**: derivato da OpenXcom, GPL v3 o successiva; la decide l'utente.

**Parita'**: 0 pixel diversi col vero OpenXcom (nightly 2026-06-05, TFTD, en-US, 640x400) sulla schermata di avvio (fase del cursore uguale), sul menu principale e sulla scelta della difficolta' (cursore compreso: sul quel cursore SDL_gfx e Bresenham danno gli stessi pixel); `Tests\Data\XcomEngine\frames.golden.txt`.

**Trappole**: la riga del prompt DOS (`CrossPlatform::getDosPath`, dal percorso dell'eseguibile) e il testo della versione si passano da fuori (`DosPathOf` in `OpenXcom\DelphiDoom.Xcom.GameComposition.pas`): per un confronto pixel per pixel vanno uguali a quelli del programma di riferimento (`-dospath`, `-version`); la schermata di avvio non usa risorse (il suo font e' quello del terminale); il menu principale vuole `IXcomResources` (`BACK01.SCR`, `FONT_BIG`, `FONT_SMALL`, l'interfaccia `mainMenu`) e la lingua gia' caricati.

**Non portato**: `NewBattleState`, `ListLoadState`/`ListSaveState`, `ModListState`, le `Options*State`, `PauseState`, `CutsceneState`, `VideoState`, `SlideshowState`, `StatisticsState`...

Test: `Tests\DelphiDoom.Tests.XcomEngine` (copertura XcomMenu 93%).
