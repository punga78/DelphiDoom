# Libs\XcomGeoscape

Il geoscape di OpenXcom (issue #176) a classi, senza SDL: il globo (`TXcomGlobe`), la schermata principale (`TXcomGeoscapeState`), la scelta del sito della prima base (`TXcomBuildNewBaseState`, `TXcomBaseNameState`) e l'avvio di una partita nuova (`TXcomNewGameStarter`).

Provare a mano: `OpenXcom\XcomGame -data <cartella con common\ e standard\> -game <cartella di TFTD> -user <cartella> -seed 1`, Menu, New Game, OK.
Fotogrammi senza finestra: `-script "wait:3000;move:230,210;click:230,210;wait:800;move:238,343;click:238,343;wait:4000;shot:geo.png"`.

Il codice deriva da OpenXcom (GPL v3 o successiva): la licenza dell'opera e' decisa dall'utente; il repository non e' stato cambiato. Dettagli, parita' e differenze in `CLAUDE.md`.
