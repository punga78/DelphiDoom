# Framework\NetTransport — note per Claude

Quarta fetta della issue #225 (2026-11-15): il trasporto UDP e' stato separato da `IdTech1\Net` **senza cambiare un byte di comportamento**. Strato **L0** (riga `'Framework\NetTransport' = 'L0'` in `docs\Strati.psd1`): dipende solo da `System` e da Winsock; lo usano `IdTech1\Net`, `EngineSystem`, `Greed` (modulo `Giochi`) e il motore, e `NetTransport` non usa nessuna libreria.

**Unit** (4): `DelphiDoom.Net.Transport.Intf` (`INetTransport`, stesso GUID), `DelphiDoom.Net.Transport.Types` (`ENetException`, `TNetNodeAddress`, `NET_DEFAULT_PORT`), `DelphiDoom.Net.WinsockTransport` (`TWinsockNetTransport`) e `DelphiDoom.Net.NodeListParser` (`TNetNodeListParser`). Le ultime due sono state spostate con `git mv` e conservano il nome; le prime due sono ricavate da `Net.Intf` e `Net.Types`, che mescolavano trasporto e protocollo di Doom (il testo e' identico, solo spostato). `ENetException` e' la base comune: `Net.Types` ne deriva `ENetVersionMismatchException` e `ENetConsistencyException`.

**Resta in `IdTech1\Net`** (protocollo di Doom): `Types` (`TNetPacket`, `TNetSetupInfo`, `TNetSyncSettings`, costanti `NCMD_*`), `Intf` (codec, input locale, sincronizzazione, arbitro), `PacketCodec`, `TicSync`, `ConsistencyTracker`, `StartArbiter`, `Factory`, piu' i messaggi a bit di id Tech 4. Chi usa `INetTransport`, `ENetException`, `TNetNodeAddress` o `NET_DEFAULT_PORT` deve avere `DelphiDoom.Net.Transport.*` nei `uses`.

**Prova**: `Tests\DelphiDoom.Tests.Net` (condiviso con `IdTech1\Net`).
