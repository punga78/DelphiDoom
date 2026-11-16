# Framework\NetTransport

Trasporto UDP dei giochi separato da `IdTech1\Net` (issue #225, quarta fetta): socket Winsock (`TWinsockNetTransport`), elenco dei computer della riga di comando (`TNetNodeListParser`), il contratto `INetTransport` e i tipi del trasporto (`ENetException`, `TNetNodeAddress`, `NET_DEFAULT_PORT`).

Il testo di riferimento sta in [CLAUDE.md](CLAUDE.md). Le unit `WinsockTransport` e `NodeListParser` hanno ancora il nome `DelphiDoom.Net.*`: sono state spostate con `git mv`; `DelphiDoom.Net.Transport.Intf` e `DelphiDoom.Net.Transport.Types` sono ricavate da `Net.Intf` e `Net.Types`.

## Contenuto

- Unit nella cartella: 4. Strato **L0** in `docs\Strati.psd1`; non dipende da nessuna altra libreria.
- Chi la usa: `IdTech1\Net` (protocollo di Doom, `TicSync`, `Factory`), `IdTech1\EngineSystem`, `Games\Greed` e `Games\Greed\`, `Base` (`i_net`, `DelphiDoom.Engine.Net.*`).

## Prova

- Progetto di test: `Tests\DelphiDoom.Tests.Net` (condiviso con `IdTech1\Net`, ha `..\Framework\NetTransport` nel percorso): `Tests\Source\DelphiDoom.Tests.Net.WinsockTransport` e `...NodeListParser`.

## Legami

- [IdTech1\Net](../../IdTech1/Net/README.md) per il protocollo dei pacchetti e la sincronizzazione dei ticcmd; indice e regole generali nel [CLAUDE.md di radice](../../CLAUDE.md).
