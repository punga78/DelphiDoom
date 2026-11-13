# Libs\Compression — note per Claude

`Libs\Compression` (issue #98, fetta 1 della parte "compressori") e il port a classi dei compressori di id Tech 4
(`Reference\doom3\neo\framework\Compressor.cpp/.h`, GPL v3 con termini aggiuntivi: **port**, stesso algoritmo e stessi
byte; il repository e GPL v2 o successiva, le unit lo dichiarano nell'intestazione). **Non ha chiamanti nel motore.**

## Portato e non portato

Portati: `idCompressor_None`, `_BitStream`, `_RunLength`, `_RunLength_ZeroBased`, `_Huffman`, `_Arithmetic`, `_LZSS`,
`_LZSS_WordAligned`, `_LZW` e le `Alloc*` (`TCompressorFactory`). Non portato: nulla del file.
Il deflate resta a `Libs\Zlib`. La rete di Quake III (#121) **non e** qui e non e stata toccata: la #121 prevede l'Huffman adattivo di `huffman.c`
in questa libreria e i messaggi in `Libs\Net` accanto a `TBitMessage`; l'adattivo di idTech 4 (`TCompressorHuffman`) e della stessa
famiglia (Sayood) ma ha strutture e interfaccia diverse da `Huff_*` e non e stato confrontato con `huffman.c`: il riuso va
valutato in quella issue (non verificato qui).

## Mappa C++ -> Pascal

| C++ | Pascal |
|---|---|
| `idCompressor` (e `idFile`) | `ICompressor` sopra un `TStream` (`Init(AStream, ...)`: il flusso resta del chiamante) |
| `idCompressor_None` | `TCompressorNone` (`DelphiDoom.Compression.None`), base di tutti |
| `idCompressor_BitStream` | `TCompressorBitStream` (cursori di bit in lettura e scrittura, buffer da 64 KiB) |
| `_RunLength`, `_RunLength_ZeroBased` | `TCompressorRunLength`, `TCompressorRunLengthZeroBased` |
| `_Huffman` | `TCompressorHuffman`: i puntatori dell'albero e delle liste sono indici in array (-1 = NULL); il `huffmanNode_t **head` e l'indice di uno slot di `FNodePtrs`, i cui slot liberi formano la lista tramite il loro valore, come nell'originale |
| `_Arithmetic` | `TCompressorArithmetic` (aritmetica su `Cardinal` a 32 bit e `Word`, come un `long` a 32 bit del C di Windows) |
| `_LZSS`, `_LZSS_WordAligned` | `TCompressorLzss`, `TCompressorLzssWordAligned` |
| `_LZW` (con `idHashIndex`) | `TCompressorLzw` con il `TIdHashIndex` di `Libs\IdLib` |
| `idCompressor::Alloc*` | `TCompressorFactory.Create*` (restituiscono `ICompressor`, contato) |

## Riuso

`TStream` della RTL al posto di `idFile`; `TIdHashIndex` (`Libs\IdLib\Containers`) per LZW; `TCrc32` (`Libs\MathCore`) solo nei
test. Nel repository non esisteva un compressore con questo formato: i bit reader di `Libs\Jpeg`, `Libs\Mp3`, `Libs\Sound`
(Vorbis) e `Libs\Png` sono lettori di formati di terzi (marcatori, solo lettura) e `Libs\Keen` (`Huffman`, `Lzh`) decomprime i formati di Keen; sono
stati guardati per nome e struttura, non letti riga per riga, e non producono i byte di idTech 4: nessuna unificazione provata.

## Parita con il C++

`Tools\Verifica\98\Build-Harness.ps1` copia da `Reference\doom3` i sorgenti veri (`Compressor.cpp`, `BitMsg.cpp`,
`HashIndex.cpp`) in una cartella temporanea, li compila **senza modifiche** con il g++ di w64devkit (`-std=c++14`) insieme a un
`precompiled.h` finto (`Tools\Verifica\98\stub`: idStr, idVec3, idDict, idFile, common) e a `main.cpp`, esegue 33 casi e scrive
`Tests\Data\Compression\golden.txt` (e `Tests\Data\Net\bitmsg-golden.txt` per i messaggi a bit). Per ogni caso: lunghezza e CRC-32 dei
byte compressi, rapporto di compressione (bit del float), esito e CRC-32 della decompressione, e i byte compressi dei casi
piccoli. I dati di prova sono generati da un LCG (`1664525`, `1013904223`) identico in C++ e Pascal; nessun dato di Doom 3 e nel
repository. `DelphiDoom.Tests.Compression.Parity`: **i 33 casi danno gli stessi byte del C++** (Win32 e Win64), il rapporto entro
1e-3, e i byte che il C++ ha scritto si decomprimono qui negli stessi dati. Differenze di valutazione: nessuna trovata.

## Difetti e stranezze dell'originale (riprodotti)

- **RLE e RLE a zeri leggono una parola oltre i dati in ogni `Write`**: ogni chiamata aggiunge una parola finale, e l'uscita di
  piu `Write` piccoli **non si decomprime** (`rle8-text-chunked` del golden: esito 0). Si comprime con una sola `Write`.
- Lettura oltre la fine del flusso compresso: i decompressori `BitStream` ricominciano dal buffer, quindi producono dati
  stantii fino a riempire il blocco; si chiede sempre la lunghezza esatta. Il buffer del C++ non e inizializzato, qui parte
  azzerato (i test confrontano solo i byte richiesti).
- `Write` di `idCompressor_LZW` non controlla la direzione (le altre tornano 0 se il compressore e in decompressione).
- `idCompressor_Arithmetic::WriteOverflowBits` lascia `underflowBits` a `0xFFFFFFFF` (il `-- > 0` decrementa anche l'ultima
  volta); si azzera nella `InitProbabilities` che segue.
- `1 << wordLength` con `wordLength` 31 o 32 e indefinito in C++; i compressori a parole sono provati a 4, 5, 8 e 16 bit.
- Il rapporto di compressione con denominatore zero da infinito/NaN in C (qui lo stesso, senza eccezione).

## Cosa resta

- Il formato su disco con intestazione (idTech 4 lo mette fuori dal compressore: `idFile_Memory`/`idDeclTable`).
- Collegare i compressori a un chiamante (messaggi di rete di idTech 4, salvataggi): oggi non ce n'e.
- `TCompressorLzss` usa un `TArray<Integer>` da 524280 voci per istanza (2 MB, come l'originale): se ne servono molte, condividerlo.
