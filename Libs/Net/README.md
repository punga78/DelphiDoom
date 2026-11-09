# Libs\Net

Trasporto UDP, protocollo dei pacchetti e sincronizzazione dei ticcmd.

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 9 (nome a punti `DelphiDoom.Net.*`).
- Interfacce dichiarate: `INetAbortCheck`, `INetConsistency`, `INetLocalInput`, `INetPacketCodec`, `INetPacketPort`, `INetPlayers`, `INetStartArbiter`, `INetTicPlanner`.
- Punto di creazione delle classi: `DelphiDoom.Net.Factory`.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Net`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
