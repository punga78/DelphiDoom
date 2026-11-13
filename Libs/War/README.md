# Libs\War

> Note per Claude e paragrafi di dettaglio: [CLAUDE.md](CLAUDE.md).

Port in classi della **lettura dell'archivio `DATA.WAR`** di *Warcraft: Orcs & Humans* (Blizzard, 1994), dal remake in C **war1** di Alejandro Coto Gutierrez (`acoto87/war1`, in `Reference\war1`, sola lettura): `war_file.c`/`war_file.h` (l'archivio e la decompressione), la tabella `assets[]` di `war_database.h` (che cos'e' ogni record) e `wres_tryGetPredefinedCustomMapIndex` di `war_resources.c`. Issue #191 (indice: #203; licenza e fuori ambito: #202; dati: #190). Senza dipendenze dal motore; usa solo `Libs\MathCore` (`TCrc32`) nei test.

**Licenza.** Il remake e' **zlib License** ((C) 2019 Alejandro Coto Gutierrez), compatibile con la GPL v2 o successiva del repository; il testo e' in [LICENSE-war1.txt](LICENSE-war1.txt) e ogni unit derivata dice nell'intestazione di essere una **versione modificata** del remake (clausola 2). I dati di gioco sono commerciali (Blizzard): **non sono nel repository** e non si ridistribuiscono (`Reference\_dati\MANIFEST.md`, `Tools\Verifica\190`).

## Formato

```
0   u32  archiveID       0x18 (24) o 0x1A = gioco completo, 0x19 (25) = demo
4   u32  numberOfEntries 583 nel DATA.WAR DOS (al massimo 586)
8   u32[numberOfEntries]  offset di ogni record; 0 o 0xFFFFFFFF = segnaposto (la demo non ha il record)
...  record: u32 (bit 0-28 = lunghezza espansa, bit 29-31 != 0 = compresso) e i dati
```

La lunghezza che un record occupa nel file e' la distanza dall'offset del successivo **che non e' un segnaposto** (l'ultimo: fino alla fine del file). La compressione e' una finestra di 4096 byte (tutti zero all'inizio) con gruppi di 8 elementi e un byte di maschera letto dal bit basso: 1 = byte letterale, 0 = due byte (12 bit di posizione nella finestra, 4 bit di lunghezza meno 3).

## Mappa nome C -> classe

| C (`Reference\war1\src`) | Delphi |
|---|---|
| `WarFile` / `WarRawResource` (`war_resources.h`) | `TWarArchive` (`IWarArchive`) e `TWarRecordInfo` (la riga della directory, senza i byte) |
| `wfile_loadWarFile`: lettura, intestazione, tabella, calcolo delle lunghezze, controlli | costruttore e `BuildDirectory` di `TWarArchive` |
| `wfile_loadWarFile`: la decompressione | `TWarDecompressor.Expand` |
| `wfile_freeWarFile` | niente: i byte non si tengono, `ReadRecord` li dà |
| `wfile_readU16LE`, `wfile_readU32LE` | `TWarLittleEndian.ReadWord`, `ReadCardinal` |
| `WarFileType`, `WarResourceType`/`DatabaseEntryType`, `MAX_RESOURCES_COUNT` | `TWarFileType`, `TWarRecordType`, `WAR_MAX_RESOURCES_COUNT` (`DelphiDoom.War.Types`) |
| `assets[]` (`war_database.h`, 579 voci) | `TWarCatalog` (`IWarCatalog`) con i dati di `DelphiDoom.War.Catalog.Data` (generato) |
| `skipDecompress[]` di `wg_loadDataFile` | `IWarCatalog.IsSkipped` e `wrsSkipped` nella directory |
| `wres_tryGetPredefinedCustomMapIndex` | `IWarCatalog.TryGetPredefinedCustomMapIndex` |
| `SDL_IOFromFile`/`SDL_ReadIO` | `IWarSource` (`TWarStreamSource` sopra un `TStream`) |
| `logError(...)` e segnaposto | `Status` (`TWarRecordStatus`) della riga della directory; l'eccezione `EWarException` per i guasti dell'archivio |

Una `TWarFactory` crea tutto (`OpenFile`, `OpenStream`, `CreateCatalog`).

## Non portato (fetta #191)

- Tutto il resto di `war_resources.c` (palette, immagini, sprite, livelli, tileset, testi, musica, suoni, cursori): sono le fette #192, #193 e #198.
- `wfile_loadWarMapFile` (le mappe `.w1m` dell'editor del remake): fuori ambito (#202).
- Gli archivi Macintosh (id big endian, `0x1A000000`): l'originale non li legge.

## Verifica

`Tools\build.bat DelphiDoom.Tests.War` e poi `bin\Tests\DelphiDoom.Tests.War.exe`. 82 test (archivio costruito in memoria con un finto del file, decompressore, catalogo, sorgente su stream, parita'), copertura 99% (`Tools\Copertura.ps1 -Test War`). **Parita' con il C**: `Tools\Verifica\191` compila con gcc (w64devkit) il `wfile_loadWarFile` ORIGINALE (estratto alla lettera da `war_file.c`) e lo fa girare sul `DATA.WAR` vero: i golden `Tests\Data\War\datawar.retail.golden.txt` (come `wg_loadDataFile`: 68 voci saltate), `datawar.retail.noskip.golden.txt` e `catalog.golden.txt` sono la sua uscita; le 583 voci (offset, compresso, lunghezze e CRC-32 dei byte espansi) danno **zero differenze**. I test sui dati veri (`DELPHIDOOM_WAR_DATA` o `Reference\_dati\warcraft`) sono **ignorati**, non verdi, se `DATA.WAR` manca.
