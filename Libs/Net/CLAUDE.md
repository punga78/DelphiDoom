# Libs\Net — note per Claude

Il paragrafo che riguarda trasporto UDP, protocollo dei pacchetti e sincronizzazione dei ticcmd sta nel CLAUDE.md di `Libs\DynLights`: [Libs/DynLights/CLAUDE.md](../DynLights/CLAUDE.md).

## Messaggi a bit di idTech 4 (issue #98, fetta 1)

`TBitMessage` (`DelphiDoom.Net.BitMessage`) e `TBitMessageDelta` (`DelphiDoom.Net.BitMessageDelta`) sono il **port** di `idBitMsg` e
`idBitMsgDelta` (`Reference\doom3\neo\idlib\BitMsg.h/.cpp`; GPL v3 con termini aggiuntivi, dichiarato nelle unit). **Non hanno
chiamanti nel motore** e non toccano il protocollo UDP di Doom (`PacketCodec`): sono per codice ispirato a idTech 4.

- Interfacce piccole (`DelphiDoom.Net.BitMessage.Intf`): `IBitMessageWriter` e `IBitMessageReader`, le sole cose che il delta chiede
  ai messaggi (bit, stringa, blocco di byte, dizionario, tre contatori); eccezione `EBitMessageException`, record
  `TBitMessageNetAddress` (6 byte `packed`, `SizeOf` testato) in `DelphiDoom.Net.BitMessage.Types`.
- Proprieta: il buffer e un `TBytes` del chiamante (`Init` lo condivide, non lo copia ne lo ridimensiona); `TBitMessage` **non e contato**
  (`TSingletonImplementation`): lo libera chi lo crea, i riferimenti a interfaccia non lo liberano. `TBitMessageDelta` non possiede niente.
- Riuso: `TIdMath.FloatToBits/BitsToFloat/FtoiFast/Ftoi/Fabs` e `TIdVec3` di `Libs\IdLib` (direzioni, float compatti, angoli),
  `TIdDict` di `Libs\Scanner` (i dizionari delta, chiavi senza distinzione di maiuscole), `TIdStrings.Icmp/Cmp`, `IIdLibLog` (avvisi di
  "value overflow", nil = silenzio). Scritto di nuovo: il flusso di bit (non c'era un equivalente con questo ordine dei bit e questo
  formato: i bit reader di `Libs\Jpeg`, `Mp3`, `Sound` e `Png` sono per altri formati).
- Differenze dal C++: `common->Error` e un'eccezione; `ReadString` restituisce la stringa invece di riempire un buffer (taglia a
  `ABufferSize - 1` ma consuma tutta la stringa, `%` diventa `.`); niente `WriteString(NULL)` (si scrive `''`: stesso byte);
  `WriteString(s, 0)` e un errore (l'originale scrive un byte fuori dallo spazio riservato); `ReadData` ha anche la forma che restituisce
  `TBytes`; `Init` verifica che la lunghezza stia nel buffer.
- **Difetti dell'originale riprodotti**: nei contatori delta (`WriteDeltaByte/Short/LongCounter`) la posizione 0 non e mai provata, quindi
  una differenza solo nel bit 0 si perde (il lettore restituisce il vecchio valore); una differenza nel bit piu alto da un conteggio
  che non entra nel campo (8 in 3 bit, 16 in 4, 32 in 5): l'originale avvisa e scrive 0 seguito da tutti i bit del valore.
  `idBitMsgDelta::WriteData` / `ReadData` confrontano con un buffer di 1024 byte: la lunghezza deve restare sotto.
- **Parita sul C++**: `Tools\Verifica\98\Build-Harness.ps1` compila le classi vere (`BitMsg.cpp`, `HashIndex.cpp`, `Compressor.cpp`) con il g++ di
  w64devkit e scrive `Tests\Data\Net\bitmsg-golden.txt` (4 scenari: tutti i tipi, stato di lettura e scrittura, overflow ed errori, delta con
  e senza base). `DelphiDoom.Tests.Net.BitMessageParity` li ripete e confronta riga per riga: byte dei messaggi in esadecimale, dimensioni,
  ogni valore riletto (i float come bit: confronto esatto, nessuna tolleranza) a Win32 e Win64.
- Test: `DelphiDoom.Tests.Net.BitMessage` (34 test con finti `IBitMessageWriter`/`Reader`), copertura di `Libs\Net` 96% (le due unit nuove 99%).

**Resta**: il codice di idTech 4 che usa i messaggi (non portato: la rete di idTech 4 non e nella #98); la rete di Quake III (#121: `msg.c`,
`huffman.c`, netchan) potra appoggiarsi a questi messaggi ma ha un formato proprio e non e stata fatta; i contenitori della #98 (idList,
idHashTable, idLinkList, idHierarchy, idStaticList) non sono stati toccati (`Libs\IdLib\Containers` ha gia HashIndex, LinkList,
Hierarchy; idList e idHashTable sono i generics della RTL, non verificato caso per caso).
