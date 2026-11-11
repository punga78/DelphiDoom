# Libs\XcomGeoscape

Il geoscape di OpenXcom (issue #176) a classi, senza SDL: il globo (`TXcomGlobe`), la schermata principale (`TXcomGeoscapeState`), la scelta del sito della prima base (`TXcomBuildNewBaseState`, `TXcomBaseNameState`) e l'avvio di una partita nuova (`TXcomNewGameStarter`).

Provare a mano: `OpenXcom\Xcom32 -data <cartella con common\ e standard\> -game <cartella di TFTD> -user <cartella> -seed 1`, Menu, New Game, OK.
Fotogrammi senza finestra: `-script "wait:3000;move:230,210;click:230,210;wait:800;move:238,343;click:238,343;wait:4000;shot:geo.png"`.

Il codice deriva da OpenXcom (GPL v3 o successiva): la licenza dell'opera e' decisa dall'utente; il repository non e' stato cambiato. Dettagli, parita' e differenze in `CLAUDE.md`.


## Popup degli eventi e intercettare (issue #176)

Gli eventi della simulazione sono stati di OpenXcom (`TXcomPopupGeoscapeEvents`: UFO rilevato o perso, siti, basi aliene, velivoli, trasferimenti, produzioni, ricerche, rapporto mensile), il clic sui bersagli del globo apre `MultipleTargetsState` e da `InterceptState` si manda un velivolo (`SelectDestinationState`, `ConfirmDestinationState`); `ConfirmNewBaseState` e `PlaceLiftState` fanno le basi dopo la prima. Il dogfight non c'e'. Dettagli, parita' e difetti in `CLAUDE.md`.

Aggiornamento (sessione "partita completa", #176): c'e' anche `TXcomGraphsState` (i grafici), il dogfight (`TXcomDogfightState`) e l'uscita verso la battaglia `IXcomMissionLauncher` (il Battlescape la implementa; senza, "Yes" di `ConfirmLandingState` chiude e basta). Vedi `CLAUDE.md`.

Aggiornamento (sessione "prova della partita", #176): le rotte dei velivoli in volo sono disegnate sul globo (`globeFlightPaths`); una partita persa passa dal rapporto mensile alle statistiche e al menu principale; a fine mese si aprono l'addestramento psi e il salvataggio automatico. Il giro di tutta la partita strategica e' un test: `Tools\build.bat Tests\DelphiDoom.Tests.XcomTour` (servono i dati di TFTD in `Reference\_dati\xcom_tftd`). Il pulsante Ufopaedia non fa ancora nulla.
