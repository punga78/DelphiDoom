# Libs\Net

Trasporto UDP, protocollo dei pacchetti e sincronizzazione dei ticcmd.

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 9 (nome a punti `DelphiDoom.Net.*`).
- Interfacce dichiarate: `INetAbortCheck`, `INetConsistency`, `INetLocalInput`, `INetPacketCodec`, `INetPacketPort`, `INetPlayers`, `INetStartArbiter`, `INetTicPlanner`.
- Punto di creazione delle classi: `DelphiDoom.Net.Factory`.
- **Messaggi a bit di idTech 4** (issue #98): `TBitMessage` e `TBitMessageDelta` (port di `idBitMsg` e `idBitMsgDelta`), interfacce
  `IBitMessageWriter` e `IBitMessageReader`, `EBitMessageException`, `TBitMessageNetAddress` (unit `DelphiDoom.Net.BitMessage*`). Senza
  chiamanti nel motore; parita sul C++ con `Tests\Data\Net\bitmsg-golden.txt`. Dettagli in [CLAUDE.md](CLAUDE.md). I compressori sono in
  [Libs\Compression](../Compression/README.md).

- **Rete di Quake III / id Tech 3** (issue #121, prima fetta): `msg.c`, `huffman.c` e `net_chan.c` a classi, unit `DelphiDoom.Net.Q3.*`:
  `TQ3Message` (bit con Huffman e out-of-band), `TQ3AdaptiveHuffman`, `TQ3MessageHuffman`, `TQ3HuffmanCompressor`, delta di `usercmd_t`,
  `entityState_t` e `playerState_t` (`TQ3UserCmdCodec`, `TQ3EntityStateCodec`, `TQ3PlayerStateCodec`, `TQ3NetFieldTable`), `TQ3Netchan`
  (sequenze e frammenti) sopra `IQ3NetTransport`, `TQ3NetFactory`. Senza chiamanti nel motore; parita byte per byte sul C con
  `Tests\Data\Net\q3net-golden.txt` (`Tools\Verifica\121`). Cosa e portato, cosa no e i difetti del C: [CLAUDE.md](CLAUDE.md).
- **Rete di Quake III, seconda fetta** (issue #121): `TQ3InfoString` (info string `\chiave\valore` di `q_shared.c`),
  `TQ3ServerMessageParser` (`cl_parse.c`: server command, gamestate, snapshot delta-compressi) con il sink `IQ3ServerMessageSink`,
  `TQ3DemoReader` (contenitore `.dm_68`). Senza chiamanti nel motore; parita sul C con `q3info-golden.txt` e `q3demo-golden.txt`
  (`Tools\Verifica\121\build-info.sh`, `build-demo.sh`). Dettagli e cosa resta: [CLAUDE.md](CLAUDE.md).

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Net`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
