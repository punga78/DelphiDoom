# Libs\Net

Protocollo dei pacchetti e sincronizzazione dei ticcmd di Doom. Il trasporto UDP (`INetTransport`, Winsock, elenco dei computer) e' in [Framework\NetTransport](../../Framework/NetTransport/README.md) (#225, quarta fetta).

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 9 (nome a punti `DelphiDoom.Net.*`).
- Interfacce dichiarate: `INetAbortCheck`, `INetConsistency`, `INetLocalInput`, `INetPacketCodec`, `INetPacketPort`, `INetPlayers`, `INetStartArbiter`, `INetTicPlanner`.
- Punto di creazione delle classi: `DelphiDoom.Net.Factory`.
- **Messaggi a bit di idTech 4** (issue #98): `TBitMessage` e `TBitMessageDelta` (port di `idBitMsg` e `idBitMsgDelta`), interfacce
  `IBitMessageWriter` e `IBitMessageReader`, `EBitMessageException`, `TBitMessageNetAddress` (unit `DelphiDoom.Net.BitMessage*`). Senza
  chiamanti nel motore; parita sul C++ con `Tests\Data\Net\bitmsg-golden.txt`. Dettagli in [CLAUDE.md](CLAUDE.md). I compressori sono in
  [Framework\Compression](../../Framework/Compression/README.md).

- **Rete di Quake III / id Tech 3**: spostata in [IdTech4\NetQ3](../../IdTech4/NetQ3/README.md) (#237).

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Net`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
