# Libs\XcomBasescape

Il basescape di OpenXcom (issue #176) a classi, senza SDL: la schermata di una base (`TXcomBasescapeState`), la griglia delle strutture (`TXcomBaseView`), le mini mappe (`TXcomMiniBaseView`) e il formato dei fondi (`TXcomFunding`).

Provare a mano: `OpenXcom\Xcom32 -data <common+standard> -game <TFTD> -user <cartella> -seed 1`, New Game, OK, un clic sul mare per il sito della prima base, il nome, Invio, poi BASES.

Il codice deriva da OpenXcom (GPL v3 o successiva): la licenza dell'opera e' decisa dall'utente; il repository non e' stato cambiato. Dettagli in `CLAUDE.md`.


## Costruire, ricerca e produzione (issue #176)

`TXcomPlaceLiftState`, `TXcomBuildFacilitiesState`, `TXcomPlaceFacilityState`, `TXcomDismantleFacilityState`, le tre schermate della ricerca e le quattro della produzione. Acquisti, vendite, trasferimenti e le schermate di soldati e velivoli (oltre quelle di prima) non ci sono ancora. Dettagli in `CLAUDE.md`.

Aggiornamento (sessione "partita completa", #176): acquisti, vendite, trasferimenti, soldati, velivoli, equipaggio, `TXcomSoldierMemorialState`, `TXcomAllocatePsiTrainingState` e `TXcomPsiTrainingState` ci sono; mancano il diario dei soldati, `SelectStartFacilityState` e `ManufactureDependenciesTreeState`. Vedi `CLAUDE.md`.

Aggiornamento (sessione "prova della partita", #176): ogni schermata della base e' provata dal giro `Tests\DelphiDoom.Tests.XcomTour`; le statistiche a partita finita portano al menu principale.

Aggiornamento (sessione "schermate mancanti", #176): `TXcomSelectStartFacilityState` e `TXcomPlaceStartFacilityState` (base iniziale personalizzata, `customInitialBase`) ci sono. Vedi `CLAUDE.md`.
