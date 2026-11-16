# IdTech1\Demo

Formato dei byte delle demo di Doom, Heretic, Hexen e Strife: intestazione, comando di un tic e il taglio dei comandi dopo la morte del giocatore nelle demo vecchie.

Il testo di riferimento sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 5 (nome a punti `DelphiDoom.Demo.*`).
- Classi: `TDemoHeaderCodec` (intestazione), `TDemoCommandCodec` (un comando), `TDemoDeathTrimmer` (demo vecchie), `TDemoProfiles` (le differenze dei quattro giochi come dati); tipi in `DelphiDoom.Demo.Types`.
- Nessuna interfaccia e nessuna fabbrica: sono classi `sealed` di metodi statici su un puntatore, perche' girano a ogni tic durante una demo.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Demo` (25 test; il vecchio testo dei quattro giochi e' copiato nei test). Si compila con `Tools\build.bat Tests\DelphiDoom.Tests.Demo` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
- Chi la usa: `IdTech1\Doom\g_game`, `IdTech1\Heretic\g_game`, `IdTech1\Strife\g_game`, `IdTech1\Hexen\g_demo` (Radix32 e SpeedHaste32 usano quella di Doom).
