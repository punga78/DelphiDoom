# Libs\Keen

Port in Delphi di **Commander Keen in Keen Dreams** (id Software 1991, sorgenti C per Borland C++ 2.0 / DOS 16 bit, rilasciati nel 2014 da Javier M. Chavez, **GPL v2 o successiva**; i dati di gioco restano proprietari e non sono nel repository). Issue #165.

Non e' un gioco del motore Doom: ha il suo eseguibile (`Keen\Keen32.dpr`, composition root `Keen\DelphiDoom.Keen.Composition.pas`) e **non tocca** `ComposeEngine` ne' `TIdTechGeneration` (Keen non e' id Tech 1). Riusa `Libs\Video` (`IPaletteConverter`), `Libs\Png` (`TPngClient`), `Libs\Platform` (`IFileStore`) e `Libs\MathCore` (CRC nei test).

## Stato: fette K0-K4 del piano (`Reference\_analisi\xgreed-keen.md`)

| Fetta | Fatto | Dove |
|---|---|---|
| K0 | struttura, tipi, eccezioni | `Types`, `Intf`, `Factory`, `LittleEndian` |
| K1 | Huffman (`CAL_HuffExpand`, `CAL_OptimizeNodes`) e RLEW (`CA_RLEWexpand`) | `Huffman`, `Rlew` |
| K2 | file a chunk: `EGAHEAD/EGAGRAPH`, `MAPHEAD/GAMEMAPS`, `AUDIOHHD/AUDIOT`, nomi dei file | `OffsetTable`, `ChunkSource`, `GraphicsLayout`, `ExplicitLayout`, `MemoryFiles`, `FolderFiles`, `FileNames`, `GameLoader`, `GameData` |
| K3 | mappe a 3 piani, `tileinfo`, `pictable`, tile 8/16 e mascherati, tabella degli sprite | `MapSource`, `Map`, `TileInfo`, `Graphics` |
| K4 | EGA planare -> un byte per pixel, palette EGA, mappa intera, PNG | `PlanarConverter`, `EgaPalette`, `MapRenderer`, `PngEncoder`, `MapExporter`, `Keen32` |

**Non fatto** (K5-K12): framebuffer e disegno con i latch (`ID_VW`, `ID_RF`: dirty tile, scroll), shift degli sprite (`CAL_CacheSprite`), input e demo, il gioco (`kd_*.c`: 213 stati, `ScanInfoPlane`, thinker), audio digitalizzato e PC speaker, AdLib (serve un emulatore OPL2 che non esiste), `ID_US` (menu, `KDREAMS.CFG`, salvataggi), schermate di avvio (`KDREAMS.CMP`: `lzhuf.c`, `jam_io.c`, `soft.c`). `ID_MM` (memoria XMS/EMS) **non si porta**: array dinamici.

## Mappa nome C -> Delphi

| C | Delphi |
|---|---|
| `huffnode`, `CAL_OptimizeNodes`, `CAL_HuffExpand` | `TKeenHuffNode`, `TKeenHuffman` (`Expand`, `ExpandAvailable`) |
| `CA_RLEWexpand` | `TKeenRlew.Expand` |
| `grstarts`, `audiostarts` (EGAHEAD, AUDIOHHD) | `TKeenOffsetTable` (`IsSparse`, `EndOf`) |
| `CA_CacheGrChunk`, `CAL_ReadGrChunk`, `CAL_ExpandGrChunk`, `CA_CacheAudioChunk` | `TKeenChunkSource` (`ReadCompressed`, `Read`) con `TKeenGraphicsLayout` / `TKeenExplicitLayout` |
| `maptype`, `mapfiletype`, `pictabletype`, `spritetabletype`, `SoundCommon` | `TKeenMapHeader`, `TKeenMapFileHeader`, `TKeenPictureEntry`, `TKeenSpriteEntry`, `TKeenSoundCommon` (packed, `SizeOf` coperto da test) |
| `CAL_SetupMapFile`, `CA_CacheMap` | `TKeenMapSource` (`LoadMap`), `TKeenMap` |
| `tinf`, `SPEED`, `ANIM`, `NORTHWALL`... | `TKeenTileInfo` |
| `CAL_SetupGrFile` (pictable, picmtable, spritetable), `STARTTILE8`... | `TKeenGraphics` |
| `CA_Startup` (apertura dei file) | `TKeenGameLoader`, `TKeenFileNames` |
| `VW_MemToScreen`, `VW_MaskBlock` (cosa mettono sullo schermo) | `TKeenPlanarConverter` |
| registri della palette EGA (`colors[][]`) | `TKeenEgaPalette` |
| `RFL_NewTile`, `RFL_MaskForegroundTiles` (cosa disegnano) | `TKeenMapRenderer` |

Interfacce piccole in `DelphiDoom.Keen.Intf` (`IKeenHuffman`, `IKeenRlew`, `IKeenDataFiles`, `IKeenOffsetTable`, `IKeenChunkLayout`, `IKeenChunkSource`, `IKeenMap`, `IKeenTileInfo`, `IKeenMapSource`, `IKeenGraphics`, `IKeenGameData`, `IKeenMapRenderer`, `IKeenImageEncoder`, `IKeenMapExporter`); `TKeenFactory` e' l'unico punto che conosce le classi.

## Formati (dall'originale)

- `EGAHEAD.KDR`: 3017 offset `long` (`NUMCHUNKS + 1`), `-1` = chunk senza dati (tile sparsi); l'ultimo e' la fine del file. `EGADICT.KDR`: 1024 byte, 255 nodi da due word; testa = nodo 254; un valore < 256 e' un byte, >= 256 e' il nodo (valore - 256); i bit si leggono dal meno significativo.
- Un chunk prima di `STARTTILE8` (tabelle, font, immagini, sprite) comincia con la lunghezza espansa (`long`); i tile hanno lunghezza implicita (32, 40, 128, 160 byte per EGA; tutti gli 8x8 sono un chunk solo).
- Dati EGA planari: i 4 piani uno dopo l'altro (blu, verde, rosso, intensita'; `VW_MemToScreen` scrive con la maschera di piano 1, 2, 4, 8), il pixel piu' a sinistra e' il bit piu' alto del byte; una forma mascherata ha prima il piano della maschera (1 = lo schermo resta). Larghezza in byte.
- `MAPHEAD.KDR`: `RLEWtag` (word), 100 offset `long` delle intestazioni, 100 dimensioni `byte` (compresse), poi 11322 byte di tile info. Un piano di mappa: word (lunghezza di cio' che da' Huffman), dati Huffman, che danno una word (dimensione del piano, non usata) e i dati RLEW.
- I `.KDR` stanno nel gioco originale **linkati nell'eseguibile** (`static\makeobj`): qui sono file accanto ai dati (`TKeenFolderFiles` accetta piu' cartelle). `KDREAMS.EGA/.MAP/.AUD` hanno gli stessi nomi nello shareware 1.13 e nel sorgente 1.93; `TKeenFileNames` prova anche `EGAGRAPH.KDR`, `GAMEMAPS.KDR`, `AUDIOT.KDR`. `EGAHEAD`, `EGADICT`, `AUDIOHHD`, `AUDIODCT` della 1.13 (nell'EXE) e del sorgente sono **uguali** (confrontati byte per byte); `MAPHEAD`/`MAPDICT` **no**: per lo shareware 1.13 si estraggono dall'EXE (`Reference\_dati\keen_build\src\static113`).

## Parita'

I riferimenti vengono dall'originale compilato con Open Watcom (`Reference\_analisi\keen_build.md`): `kdgold.exe` collega `id_ca.c` e `id_mm.c` originali e scrive `KDGOLD.TXT` (copia in `Tests\Data\Keen`, descrizione in `Tests\Data\README.md`). `Tests\DelphiDoom.Tests.Keen.Golden` confronta con i dati veri dello shareware 1.13 (si salta se mancano; vedi `DelphiDoom.Tests.Keen.RealData`):

- 18 mappe (0..16 e 20): nome, dimensioni e CRC32 dei 3 piani dopo Huffman e RLEW (54 piani) **identici**;
- `pictable` (260 byte) e i 65 blocchi immagine planari **identici**;
- blocco `tileinfo` (11322 byte) **identico**;
- tile 8x8 e mascherati: vedi sotto (i primi 1280 e 1200 byte sono identici al dump `-raw` del C: `Tests\Data\Keen\KDGOLD_EXTRA.TXT`).

La conversione planare -> pixel e il disegno della mappa non hanno un golden del C (il C scrive sulla memoria video EGA): sono provati con dati costruiti a mano e con il PNG della mappa del mondo (`Keen32 -map 0`), confrontato a occhio con lo screenshot di DOSBox dell'originale (stessi colori e stessi tile).

## Difetti del C e dei dati

**Conservati** (servono per dare gli stessi byte):
- il chunk degli 8x8 dello shareware (e il suo mascherato) ha i dati di **40 tile (30)** e non dei 72 (36) di `graphkdr.h`: il C espande lo stesso 2304 (1440) byte e dopo i dati legge cio' che il buffer aveva (non deterministico: ne' stabile ne' usato dal gioco). `TKeenGraphicsLayout.IsLenient` dice che quei due chunk si leggono fino alla fine dei dati e il resto e' zero; i primi 1281 byte (1200) sono uguali al C;
- il file audio dello shareware e' piu' corto della sua testata (i suoni digitalizzati non ci sono, la testata e' quella completa, e l'ultima voce e' la fine del file: 3498): un chunk che esce dal file si legge fino alla fine (lettura corta); un suono (il 44) ha un byte in meno di quanto dica la sua lunghezza e il C legge dopo i dati. Per l'audio `IsLenient` e' sempre vero;
- le mappe usano il tile 0 del primo piano come "nessun tile" e un tile negativo come "mai disegnato" (`RF_MarkTileGraphics`).

**Differenze volute** (difetti del C corretti, ognuna con un test):
- dati Huffman che finiscono prima della lunghezza chiesta, o una ripetizione RLEW oltre la fine: `EKeenDataException` (il C legge dopo il buffer o scrive dopo il buffer: "a repeat count that produces 0xfff0 bytes can blow this");
- `CA_Startup` espande la tabella delle immagini mascherate con la lunghezza della tabella delle immagini (`NUMPICS * 4` in un buffer da `NUMPICM * 4`): qui ogni tabella ha la lunghezza del suo chunk;
- la dimensione di un piano (`width * height * 2`) e' `unsigned` a 16 bit nel C e avvolge: una mappa con piani oltre 65535 byte e' rifiutata;
- i valori dei nodi del dizionario sono controllati (il C li prende per indirizzi di memoria).

## Collegare al motore

Niente: Keen32 e' un programma a parte. Il prossimo passo (K5) e' il framebuffer EGA a 320x200 con la palette `TKeenEgaPalette` e il disegno dei tile 8x8 e 16x16 (`TKeenPlanarConverter` e' la base); poi gli sprite (`CAL_CacheSprite`, shift) e `ID_RF`.
