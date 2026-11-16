# Framework\Bytes

Fondazione (strato L0) per chi legge byte: il cursore comune su un blocco di byte, il lettore "alla `std::ifstream`" e il contratto dell'archivio CAT. Nessuna dipendenza da altre librerie (solo la RTL). Nata dalla issue #229 (fetta 2), indice #227.

Il testo di riferimento (che cosa è unificato, che cosa no e perché) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 5 (nome a punti `DelphiDoom.Bytes.*`).
- `TByteReader` (`Reader`): numeri little endian (`ReadByte`, `ReadWord`, `ReadSmallInt`, `ReadCardinal`, `ReadInteger`) e big endian (`ReadWordBE`, `ReadCardinalBE`), `ReadBlock`, `Skip`, `Seek`, `StepBack`, `Remaining`, parte di un array (`Create(dati, inizio, quanti)`); una lettura oltre la fine chiama `RaiseOverrun`, che ogni libreria sovrascrive per sollevare la **propria** eccezione con il proprio messaggio (di base `EByteReaderException`).
- `TByteStreamReader` (`StreamReader`, già `TXcomBinaryReader`): le abitudini di `std::ifstream` (una lettura troncata copia i byte che ci sono e fallisce, dopo il primo fallimento non legge più): serve alla parità con OpenXcom.
- `ICatArchive` e `TCatEntry` (`Archive.Intf`, `Types`): il contratto dell'archivio `.CAT` di X-COM, già `IXcomCatArchive` e `TXcomCatEntry` (che restano come alias in `Games\XcomFormats`); lo usano `Games\XcomFormats` (implementazione) e `Framework\Opl` (musica Adlib).
- `EByteReaderException` (`Types`).

## Prova

- `Tests\DelphiDoom.Tests.Bytes` (`Tools\build.bat Tests\DelphiDoom.Tests.Bytes`): 25 test, nessun dato di gioco.

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
