# Framework\Bytes — note per Claude

`Framework\Bytes` (issue #229, fetta 2 del framework, indice #227) è lo strato **L0** per la lettura di byte: nessuna dipendenza (solo la RTL). Contiene tre cose: il cursore comune `TByteReader`, il lettore "alla `std::ifstream`" `TByteStreamReader` e il contratto dell'archivio CAT (`ICatArchive`, `TCatEntry`).

## Come si usa `TByteReader`

Una libreria che ha un'eccezione e un messaggio propri **non** la solleva da `Framework\Bytes` (L0 non conosce i tipi degli strati sopra): crea una sottoclasse sottile con `RaiseOverrun` sovrascritto, come per le cinque già fatte. Il comportamento osservabile (tipo e argomenti dell'eccezione) resta quello di prima. Il controllo `Need(ACount)` fallisce se `ACount < 0`, se la posizione è negativa o se `posizione + ACount` supera la fine (aritmetica a 64 bit: niente giro di `Integer`); `Seek` non controlla (lo fa la lettura dopo), ed è `virtual` perché `TTrackerByteReader` rifiuta una posizione fuori dai dati. Con `Create(dati, inizio, quanti)` il cursore vede solo quella parte (`Remaining`, `AtEnd` e `StepBack` ne tengono conto); una parte fuori dai dati è `EArgumentOutOfRangeException`.

**Unificati** (tutti con `RaiseOverrun` proprio, API e test esistenti invariati): `TVoxelByteReader` (`Libs\Voxel`), `TVoxelEditorByteReader` (`Libs\VoxelEditor`), `TTrackerByteReader` (`Framework\Mikmod`: più il testo e `ReadBytes` che tronca), `TStaticByteReader` (`Framework\Models`: i nomi `ReadU1/U2/U4` del C++ di Doom 3, stringhe e `ReadVX`), `TXmiByteReader` (`Framework\Xmi`: finestra start/count e numeri a lunghezza variabile di MIDI e XMI). `TXcomBinaryReader` è passato (`git mv`) in `Framework\Bytes` come `TByteStreamReader`, con i suoi test.

**Differenze volute** (solo dove prima c'era un comportamento indefinito): `posizione + ACount` che girava oltre `MaxInt` ora è un errore di lettura invece di un accesso fuori dai limiti.

## Lasciati fuori, con il motivo

- **`TTextureByteReader`** (`Framework\Texture`) e **`TSoundByteReader`** (`Framework\Sound`, un `record`): la politica è "oltre la fine dà zeri e imposta `Overrun`", ma sono **diverse tra loro** nei dati troncati (Texture copia i byte che ci sono e azzera il resto, quindi una parola con un byte solo vale il byte basso; Sound dà 0 per tutta la lettura), e i decoder BMP/PCX/TGA e i formati audio di libsndfile hanno la parità con i file veri e con i difetti conservati. Unificarli significherebbe scegliere uno dei due comportamenti e cambiare l'altro; Sound è un `record` copiato per valore (passarlo a una classe cambierebbe la semantica). Non fatto.
- **`TKeenLittleEndian`** (`Libs\Keen`) e **`TWarLittleEndian`** (`Libs\War`): funzioni statiche `(array, offset)` senza stato, con eccezione propria; non sono cursori, e ognuna è usata in decine di punti con il suo messaggio `[n, offset, len]`. Non fatto.
- **`TPngByteOrder`** (`Framework\Png`): su `PByte` nel percorso di decodifica, senza controlli di limiti: non è un lettore di `TBytes`. Letture simili in `Greed.Demo.Reader`, `M2m.MidiReader`, `Jpeg.ByteSource`, `Qvm.Memory`, `Net.*`: hanno altre semantiche (flusso, bit, memoria della macchina virtuale).
- **`TGreedFliDecoder`**: vedi `Framework\Flic\CLAUDE.md` (differisce nei byte).

## Prova

`Tests\DelphiDoom.Tests.Bytes`, 25 test: 14 sul cursore (little e big endian, segno, blocco, salti, eccezione comune e della sottoclasse, lunghezze e posizioni negative, parte di un array, `StepBack`), 11 sul lettore `std::ifstream` (spostati da `DelphiDoom.Tests.Xcom`). La parità dei cinque adattatori è data dai test già esistenti delle loro librerie, **non modificati**: Voxel 123, VoxelEditor 215 (23 di parità con il vecchio codice), Mikmod 315, Models 736, Xmi 126.
