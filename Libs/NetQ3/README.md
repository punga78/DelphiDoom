# Libs\NetQ3

Rete di Quake III Arena (id Tech 3), port a classi di `qcommon` (GPL v2 o successiva, "Based on the Quake III Arena GPL Source Code (id Software)"). Spostata da `Libs\Net` nella #237 senza cambiare le unit (stessi nomi `DelphiDoom.Net.Q3.*`). Modulo `IdTech4` di `docs\Strati.psd1`.

## Contenuto

- **Rete di Quake III / id Tech 3** (issue #121, prima fetta): `msg.c`, `huffman.c` e `net_chan.c` a classi, unit `DelphiDoom.Net.Q3.*`:
  `TQ3Message` (bit con Huffman e out-of-band), `TQ3AdaptiveHuffman`, `TQ3MessageHuffman`, `TQ3HuffmanCompressor`, delta di `usercmd_t`,
  `entityState_t` e `playerState_t` (`TQ3UserCmdCodec`, `TQ3EntityStateCodec`, `TQ3PlayerStateCodec`, `TQ3NetFieldTable`), `TQ3Netchan`
  (sequenze e frammenti) sopra `IQ3NetTransport`, `TQ3NetFactory`. Senza chiamanti nel motore; parita byte per byte sul C con
  `Tests\Data\Net\q3net-golden.txt` (`Tools\Verifica\121`). Cosa e portato, cosa no e i difetti del C: [CLAUDE.md](CLAUDE.md).
- **Rete di Quake III, seconda fetta** (issue #121): `TQ3InfoString` (info string `\chiave\valore` di `q_shared.c`),
  `TQ3ServerMessageParser` (`cl_parse.c`: server command, gamestate, snapshot delta-compressi) con il sink `IQ3ServerMessageSink`,
  `TQ3DemoReader` (contenitore `.dm_68`). Senza chiamanti nel motore; parita sul C con `q3info-golden.txt` e `q3demo-golden.txt`
  (`Tools\Verifica\121\build-info.sh`, `build-demo.sh`). Dettagli e cosa resta: [CLAUDE.md](CLAUDE.md).
- **Rete di Quake III, terza fetta** (#237): il clamp di `reliableAcknowledge` e il ping dello snapshot di `cl_parse.c` (`TQ3ServerMessageParser.ReliableSequence`, `OutgoingSequence`, `RealTime`, `SetOutPacket`, `TQ3Snapshot.Ping`), con parita' sul C nello stesso golden della demo.

## Prova

- Progetto di test `DelphiDoom.Tests.Net` (con `Tests\Data\Net`), `DelphiDoom.Tests.Pmove` e `DelphiDoom.Tests.Console` usano queste unit. Parita': `Tools\Verifica\121`.

## Legami

- Note di metodo: [CLAUDE.md](CLAUDE.md). Indice: [CLAUDE.md di radice](../../CLAUDE.md).