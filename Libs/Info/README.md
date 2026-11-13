# Libs\Info

Logica delle tabelle `info` del motore (cose, stati, sprite) a classi: ricerca per numero dell'editor e per nome, alias, ereditarieta', catene di stati, stati di uno sprite, nomi dei gruppi MBF21, mostri a caso e nomi degli stati che gli script danno alle azioni. Seconda fetta della fase 1 del piano "tutto a classi" (issue #185, `docs\PIANO_TUTTO_A_CLASSI.md`): `Base\info_common.pas`, `info_fnd.pas`, `info_rnd.pas` e `sc_states.pas` sono facciate sopra questa libreria. Le tabelle `mobjinfo`, `states` e `sprnames` restano dati nelle cartelle dei giochi.

Il testo di riferimento sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 12 (nome a punti `DelphiDoom.Info.*`), 8 classi di servizio piu' `TInfoSpriteNames`, `TInfoRange`.
- Interfacce dichiarate: `IInfoMobjSource`, `IInfoStateSource`, `IInfoSpriteSource`, `IInfoStateTokens`, `IInfoStateText`, `IInfoThingNames`, `IInfoNameList`, `IInfoConstSink`, `IInfoRandom`, `IInfoRandomRules`.
- Il collegamento ai globali del motore sta fuori dalla libreria, in `Base\DelphiDoom.Engine.Info.*`.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.InfoTables` (83 test, con la parita' contro il codice vecchio in `DelphiDoom.Tests.InfoTables.LegacyInfo`). Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
- Piano e stato della fetta: `docs\PIANO_TUTTO_A_CLASSI.md` (par. 8), facciate: `docs\FACCIATE.md`.
