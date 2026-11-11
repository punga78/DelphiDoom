# Libs\XcomBattleStates

Gli stati del Battlescape di **OpenXcom** a classi, senza SDL: lo schermo della battaglia (`BattlescapeState`), le
schermate che apre (menu delle azioni, timer della granata, inventario, statistiche dell'unita', minimappa, abbandono,
cambio di turno, messaggi), il briefing e l'ingresso nella battaglia dal geoscape o da un salvataggio.

Sta sopra `Libs\XcomBattle` (modello e regole della battaglia), `Libs\XcomBattlescape` (disegno della mappa),
`Libs\XcomEngine`, `Libs\XcomUi`, `Libs\XcomDebriefing` (fine della missione), `Libs\XcomGeoscape` (contratto
`IXcomMissionLauncher`) e `Libs\XcomAudio` (canali del mixer).

## Licenza

Codice derivato da OpenXcom (the OpenXcom Developers), **GPL v3 o successiva**: ogni unit lo dichiara
nell'intestazione. Il repository e' GPL v2 o successiva: la licenza dell'opera che contiene questa libreria la decide
l'utente (vedi `Libs\XcomFormats\README.md`).

## Uso

Il programma (`OpenXcom\Xcom32`, composition root `OpenXcom\DelphiDoom.Xcom.GameComposition.pas`) crea:

- `TXcomBattleFactory.CreateScreens(host, pausa)`: le schermate della battaglia;
- `TXcomBattleMixerAudio.Create(host, mixer)`: i suoni sui canali del mixer;
- `TXcomMissionLauncher.Create(host, schermi, audio)`: `IXcomMissionLauncher` per il geoscape ("Begin Mission? Yes");
- `TXcomBattleLauncher.Resume(host, schermi, audio)`: la battaglia di un salvataggio appena caricato.

## Test e verifica

- `Tools\build.bat Tests\DelphiDoom.Tests.XcomBattleStates` (eseguibile in `bin\Tests`): i test usano la battaglia
  `Tests\Data\XcomBattle\bg\g01_2` con le regole e la grafica vere di TFTD (`Reference\_dati\xcom_tftd`); senza i dati
  passano senza controllare.
- `Tools\Verifica\176\Compare-XcomBattle.ps1`: lo stesso salvataggio in `Xcom32` e nel vero OpenXcom, confronto dei
  pixel.

Dettagli, numeri e differenze dichiarate: `CLAUDE.md` di questa cartella.
