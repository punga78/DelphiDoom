# Libs\Compression

Compressori senza perdita di id Tech 4 (`idCompressor` di Doom 3, `framework\Compressor.cpp`) a classi, sopra un `TStream`.
**Nessun chiamante nel motore** di Doom, Heretic, Hexen e Strife: e una base per codice ispirato a idTech 4 (messaggi di rete,
file compressi). Il deflate resta a [Libs\Zlib](../Zlib/README.md).

Il testo di riferimento (decisioni, differenze dal C++, difetti trovati) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Interfaccia `ICompressor` (`DelphiDoom.Compression.Intf`): `Init(stream, compress, wordLength)`, `Write`, `Read`,
  `FinishCompress`, `GetCompressionRatio`, `Length`, `Tell`, `Seek` (sempre un errore, come l'originale).
- Una classe per unit: `TCompressorNone`, `TCompressorBitStream`, `TCompressorRunLength`, `TCompressorRunLengthZeroBased`,
  `TCompressorHuffman` (Huffman adattivo), `TCompressorArithmetic`, `TCompressorLzss`, `TCompressorLzssWordAligned`,
  `TCompressorLzw`.
- Punto di creazione: `TCompressorFactory` (`CreateNoCompression`, `CreateBitStream`, `CreateRunLength`, ... come
  `idCompressor::Alloc*`).
- Eccezione: `ECompressionException` (`DelphiDoom.Compression.Types`).

```pascal
LCompressor := TCompressorFactory.CreateLzss;
LCompressor.Init(LStream, True, 8);      // comprime scrivendo su LStream
LCompressor.Write(LData);
LCompressor.FinishCompress;
// ... poi, su un flusso con gli stessi byte:
LCompressor := TCompressorFactory.CreateLzss;
LCompressor.Init(LStream, False, 8);
LCompressor.Read(@LBack[0], Length(LData));   // si chiede la lunghezza esatta
```

## Prova

- `Tests\DelphiDoom.Tests.Compression` (21 test, copertura 96%): `Tools\build.bat Tests\DelphiDoom.Tests.Compression`.
- Parita sul C++: `Tests\Data\Compression\golden.txt`, scritto dalle classi vere di Doom 3 (`Tools\Verifica\98`).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
- I messaggi a bit (`idBitMsg`) stanno in [Libs\Net](../Net/README.md); il contenitore `idHashIndex` di LZW e quello di
  [Libs\IdLib](../IdLib/README.md).
