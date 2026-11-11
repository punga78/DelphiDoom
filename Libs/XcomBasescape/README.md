# Libs\XcomBasescape

Il basescape di OpenXcom (issue #176) a classi, senza SDL: la schermata di una base (`TXcomBasescapeState`), la griglia delle strutture (`TXcomBaseView`), le mini mappe (`TXcomMiniBaseView`) e il formato dei fondi (`TXcomFunding`).

Provare a mano: `OpenXcom\XcomGame -data <common+standard> -game <TFTD> -user <cartella> -seed 1`, New Game, OK, un clic sul mare per il sito della prima base, il nome, Invio, poi BASES.

Il codice deriva da OpenXcom (GPL v3 o successiva): la licenza dell'opera e' decisa dall'utente; il repository non e' stato cambiato. Dettagli in `CLAUDE.md`.


## Costruire, ricerca e produzione (issue #176)

`TXcomPlaceLiftState`, `TXcomBuildFacilitiesState`, `TXcomPlaceFacilityState`, `TXcomDismantleFacilityState`, le tre schermate della ricerca e le quattro della produzione. Acquisti, vendite, trasferimenti e le schermate di soldati e velivoli (oltre quelle di prima) non ci sono ancora. Dettagli in `CLAUDE.md`.
