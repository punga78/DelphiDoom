# Tests\Data\Radix

Golden del vecchio traduttore di Radix (`Reference\Rad-X\Radix\radix_xlat_wad.pas`, `Radix2WAD_Game`). Un file per versione del gioco:

| File | Dati | Righe |
|---|---|---|
| `translation.v20.golden.txt` | `RADIX.DAT` 2.0 REMIX shareware (11150057 byte, SHA-256 `402fe534...`, vedi `Reference\_dati\MANIFEST.md`) | 2535 |
| `translation.v10.golden.txt` | `RADIX.DAT` 1.0 shareware (10077831 byte, SHA-256 `b734e2a7...`) | 2457 |
| `radixinf.v20.golden.txt`, `radixinf.v10.golden.txt` | il testo del lump `RADIXINF` (le righe `RDXW0001=nome`, `CRLF`) | |

Formato: `lumps N`, poi per ogni lump `indice nome dimensione impronta` (FNV-1a a 32 bit dei byte, 8 cifre esadecimali; `0 00000000` per un lump vuoto).

## Come sono stati fatti

`Tools\Verifica\169\build.sh RadixXlatDump.dpr` compila (dcc32, Win32) un programma console che chiama `Radix2WAD_Game(dat, wad)` del vecchio codice e rilegge il WAD
scritto. Il vecchio codice e' la copia `Reference\_dati\radix_indagine\src` di `Reference\Rad-X` (che resta intatta) con le correzioni di `Reference\_analisi\radx_crash.md`:
`malloc(bufsize)` al posto di `malloc(size)` in `GenerateOpaqueGraphicWithPalette`, i nomi dei record in `AnsiChar`, `TDStrings.GetTextStr` con `L * SizeOf(Char)` byte e
`TWadWriter.AddString` a un byte per carattere (l'ultima fa uscire `RADIXINF` e `SNDINFO` leggibili). Nota: il programma usa `DbgStack` della copia (un log per chiamata di `ReadLump`),
che il codice del repository non ha.

Per rifarli: adattare `SRC` in `build.sh`, `RadixXlatDump.exe RADIX.DAT out.wad out.golden.txt` (scrive anche `out.golden.txt.radixinf.txt`).
