# Libs\Keen

> Note per Claude e paragrafi di dettaglio (issue #178): [CLAUDE.md](CLAUDE.md).

Port in Delphi di **Commander Keen in Keen Dreams** (id Software 1991, sorgenti C per Borland C++ 2.0 / DOS 16 bit, rilasciati nel 2014 da Javier M. Chavez, **GPL v2 o successiva**; i dati di gioco restano proprietari e non sono nel repository). Issue #165.

Non e' un gioco del motore Doom: ha il suo eseguibile (`Keen\Keen32.dpr`, composition root `Keen\DelphiDoom.Keen.Composition.pas`) e **non tocca** `ComposeEngine` ne' `TIdTechGeneration` (Keen non e' id Tech 1). Riusa `Libs\Video` (`IPaletteConverter`), `Libs\Png` (`TPngClient`), `Libs\Platform` (`IFileStore`) e `Libs\MathCore` (CRC nei test).

## Stato: fette K0-K7 e il motore dei livelli di K8 (`Reference\_analisi\xgreed-keen.md`)

| Fetta | Fatto | Dove |
|---|---|---|
| K0 | struttura, tipi, eccezioni | `Types`, `Intf`, `Factory`, `LittleEndian` |
| K1 | Huffman (`CAL_HuffExpand`, `CAL_OptimizeNodes`) e RLEW (`CA_RLEWexpand`) | `Huffman`, `Rlew` |
| K2 | file a chunk: `EGAHEAD/EGAGRAPH`, `MAPHEAD/GAMEMAPS`, `AUDIOHHD/AUDIOT`, nomi dei file | `OffsetTable`, `ChunkSource`, `GraphicsLayout`, `ExplicitLayout`, `MemoryFiles`, `FolderFiles`, `FileNames`, `GameLoader`, `GameData` |
| K3 | mappe a 3 piani, `tileinfo`, `pictable`, tile 8/16 e mascherati, tabella degli sprite | `MapSource`, `Map`, `TileInfo`, `Graphics` |
| K4 | EGA planare -> un byte per pixel, palette EGA, mappa intera, PNG | `PlanarConverter`, `EgaPalette`, `MapRenderer`, `PngEncoder`, `MapExporter`, `Keen32` |
| K5 | memoria video EGA a 4 piani con latch, `ID_VW`: pixel, linee, barre, blocchi, tile, immagini, sprite | `EgaMemory`, `Video`, `DisplayCapture`, `Arithmetic` |
| K6 | shift degli sprite (`CAL_CacheSprite`), `ID_RF`: scroll su tre schermi, tile animati, sprite e priorita', `Keen32 -view` | `SpriteShifter`, `SpriteCache`, `Refresh`, `WorkingMap`, `ManualClock`, `ViewExporter` |
| K7 | `ID_IN`: tastiera (scan code), mouse, joystick, controlli, demo | `InputTypes`, `ScanTables`, `Input`, `DemoTape`, `KeyboardPump`, `MouseAdapter`, `JoystickAdapter` |
| K8 (parte) | il motore dei livelli (`kd_play.c`): attori, stati, clipping, scansione del piano info, ciclo dei frame; tabella dei 213 stati generata | `GameTypes`, `StateTypes`, `ObjectList`, `ActorMover`, `StateMachine`, `LevelScanner`, `PlayLoop`, `Random`, `StateTable`, `ActionIds`, `GraphicsIds`, `AudioIds` |

**Non fatto**: le **azioni degli stati** e i `Spawn*` (K8b: `kd_keen.c` il giocatore, `kd_act1.c`, `kd_act2.c` i nemici: ~5000 righe di think, contact e react), `CheckKeys`/`DebugKeys`/`GameLoop`/`HandleDeath` e `kd_main.c` (partenza e ciclo di gioco: vanno con `ID_US`), audio digitalizzato e PC speaker (K9), AdLib (K10: serve un emulatore OPL2 che non esiste), `ID_US` (menu, finestre, `KDREAMS.CFG`, salvataggi, `NewGame`/`SaveGame`/`LoadGame` di `kd_demo.c`: K11), schermate di avvio (`KDREAMS.CMP`: `lzhuf.c`, `jam_io.c`, `soft.c`: K12), i caratteri proporzionali di `ID_VW` (`VW_DrawPropString`) e il doppio buffer dei menu (`VW_MarkUpdateBlock`, `VW_UpdateScreen`), dissolvenze e cursore. `ID_MM` (memoria XMS/EMS) **non si porta**: array dinamici.

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
| `RFL_NewTile`, `RFL_MaskForegroundTiles` (cosa disegnano) | `TKeenMapRenderer` (la mappa intera); `TKeenRefresh` (i tile come li disegna il gioco) |
| memoria video EGA, `EGAWRITEMODE`/`EGAMAPMASK`/latch | `TKeenEgaMemory` (`CopyByte` = latch, `Fill` = `VW_ClearVideo`) |
| `VW_Plot`, `VW_Hlin`, `VW_Vlin`, `VW_Bar`, `VW_MaskBlock`, `VW_MemToScreen`, `VW_ScreenToMem`, `VW_ScreenToScreen`, `VW_DrawTile8/16`, `VW_DrawPic`, `VW_DrawMPic`, `VW_DrawSprite`, `VW_SetLineWidth`, `VW_SetScreen`, `ylookup` | `TKeenVideo` (`IKeenVideo`) |
| `CAL_ShiftSprite`, tabelle `shiftdata0..7`, `CAL_CacheSprite`, `spritetype` | `TKeenSpriteShifter.ShiftWord/ShiftSprite`, `TKeenSpriteCache.Build`, `TKeenSprite` |
| `RF_Startup`, `RF_NewMap`, `RF_MarkTileGraphics`, `RF_NewPosition`, `RF_Scroll`, `RF_PlaceSprite`, `RF_RemoveSprite`, `RF_Refresh`, `RF_ForceRefresh`, `RF_SetRefreshHook`, `RFL_*` | `TKeenRefresh` (`IKeenRefresh`) |
| `mapsegs[]` | `TKeenWorkingMap` (`IKeenWorkingMap`) |
| `TimeCount` | `IKeenClock` (`TKeenManualClock`) |
| `IN_*`, `INL_KeyService`, `INL_GetJoyDelta`, `ControlInfo`, `KeyboardDef`, `JoystickDef`, `ASCIINames`... | `TKeenInput` (`IKeenInput`), `TKeenScanTables`, tipi in `InputTypes` |
| demo di `IN_ReadControl` | `TKeenDemoTape` |
| `INL_GetMouseDelta/Buttons`, `IN_GetJoyAbs`, `INL_GetJoyButtons` | `IKeenMouse` (`TKeenMouseAdapter`), `IKeenJoysticks` (`TKeenJoystickAdapter`) |
| `objtype`, `gametype`, `classtype`, `exittype`, `statetype` | `TKeenObject`, `TKeenGameState`, `TKeenClass`, `TKeenExit`, `TKeenStateDef` |
| `InitObjArray`, `GetNewObj`, `RemoveObj` | `TKeenObjectList` |
| `MoveObjVert/Horiz`, `ClipToWalls`, `ClipToEnds`, `ClipToEast/WestWalls`, `ClipToSprite`, `ClipToSpriteSide`, `wallclip[][]` | `TKeenActorMover` |
| `DoActor`, `StateMachine`, `NewState` | `TKeenStateMachine` (`DoActor`, `Run`, `NewState`) |
| `HandleInfo`, `ScanInfoPlane`, `PatchWorldMap`, `lumpneeded[]` | `TKeenLevelScanner` |
| `PlayLoop`, `ScrollScreen`, `CalcInactivate`, `GivePoints`, `CalcSingleGravity` | `TKeenPlayLoop` |
| `US_RndT`, `US_InitRndT` | `TKeenRandom` |
| i 213 `statetype`, le funzioni think/contact/react, `graphkdr.h`, `audiokdr.h` | `StateTable`, `ActionIds` (id numerici), `GraphicsIds`, `AudioIds` (generati da `Tools\Keen\GenerateKeenTables.pl`) |

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

**K5-K8: l'osservabile e' il confronto tra due strade dentro lo stesso programma**, non un golden dell'originale (non e' stato eseguito un harness DOS per queste fette: vedi "Cosa resta"). Il disegno del gioco (`TKeenVideo` + `TKeenRefresh`) deve dare, dopo ogni `Refresh`, lo stesso 320x200 della mappa intera di `TKeenMapRenderer` ritagliata all'origine (tile + pel panning, senza il pixel dispari come `xpanmask`): con dati finti (tile casuali, animazioni, tile mascherati, sprite con tutte e quattro le copie, giro dei 64 KB, modo `comp`) e con i **18 livelli veri dello shareware 1.13** (3 posizioni per livello, 500 passi di scroll sul mondo). I test degli sprite confrontano ogni copia con uno spostamento fatto bit a bit (`ShiftWord` e' controllata sulle tabelle di `id_vw_a.asm`). `Keen32 -view X Y` scrive il PNG della schermata. Il motore degli attori (`ObjectList`, `ActorMover`, `StateMachine`, `PlayLoop`) e' provato con stati e mappe costruiti nei test e con i livelli veri solo per `ScanInfoPlane` (un solo punto di partenza di Keen per livello, mai oltre i 100 attori); non c'e' un golden del C per la fisica.

## Difetti del C e dei dati

**Conservati** (servono per dare gli stessi byte):
- il chunk degli 8x8 dello shareware (e il suo mascherato) ha i dati di **40 tile (30)** e non dei 72 (36) di `graphkdr.h`: il C espande lo stesso 2304 (1440) byte e dopo i dati legge cio' che il buffer aveva (non deterministico: ne' stabile ne' usato dal gioco). `TKeenGraphicsLayout.IsLenient` dice che quei due chunk si leggono fino alla fine dei dati e il resto e' zero; i primi 1281 byte (1200) sono uguali al C;
- il file audio dello shareware e' piu' corto della sua testata (i suoni digitalizzati non ci sono, la testata e' quella completa, e l'ultima voce e' la fine del file: 3498): un chunk che esce dal file si legge fino alla fine (lettura corta); un suono (il 44) ha un byte in meno di quanto dica la sua lunghezza e il C legge dopo i dati. Per l'audio `IsLenient` e' sempre vero;
- le mappe usano il tile 0 del primo piano come "nessun tile" e un tile negativo come "mai disegnato" (`RF_MarkTileGraphics`);
- `RFL_NewTile` mette in cache sul master screen il primo tile disegnato per ogni numero e dopo lo copia con le latch; `RFL_AnimateTiles` azzera la cache del tile **nuovo** e non del vecchio (la cache di un tile che e' stato sostituito resta sul vecchio indirizzo);
- la riproduzione di un demo (`IN_ReadControl`) da' ogni byte una volta in piu' del conteggio (`!DemoBuffer[off]--`), mentre la registrazione conta i giri (il primo vale 1): registrare e riprodurre non riporta lo stesso numero di tic; un demo registrato con la tastiera ha in un byte i bit di `±127 + 1` shiftati, quindi tagliati;
- `NewState` chiama `ClipToWalls` due volte quando l'attore e' clippato e ogni chiamata somma `xmove`/`ymove` (con un `xmove` diverso da 0 l'attore fa due passi);
- `US_RndT` e' la tabella da 256 byte letta in cerchio (stesso numero a ogni partenza se non si randomizza);
- `PatchWorldMap`, `ScanInfoPlane` e `HandleInfo`: un numero del piano info che non genera nulla mette a dormire l'**ultimo** attore creato (`new->active = false` e' fuori dallo `switch`).

**Differenze volute** (difetti del C corretti, ognuna con un test):
- dati Huffman che finiscono prima della lunghezza chiesta, o una ripetizione RLEW oltre la fine: `EKeenDataException` (il C legge dopo il buffer o scrive dopo il buffer: "a repeat count that produces 0xfff0 bytes can blow this");
- `CA_Startup` espande la tabella delle immagini mascherate con la lunghezza della tabella delle immagini (`NUMPICS * 4` in un buffer da `NUMPICM * 4`): qui ogni tabella ha la lunghezza del suo chunk;
- la dimensione di un piano (`width * height * 2`) e' `unsigned` a 16 bit nel C e avvolge: una mappa con piani oltre 65535 byte e' rifiutata;
- i valori dei nodi del dizionario sono controllati (il C li prende per indirizzi di memoria);
- **K5-K8**: un tile senza dati (chunk rado) e' disegnato nero, un tile di primo piano senza dati non si disegna (il C disegna ciò a cui punta il chunk non caricato); `VW_DrawMPic` usa `picmtable` (il C usa `pictable`: nessuno lo chiama, `VWB_DrawMPic` e' giusto); `VW_Vlin`/`VW_Bar` salgono di `linewidth` come il C e non con `ylookup`; i muri fuori dalla mappa non esistono (il C legge fuori dal piano) e un tile del primo piano fuori tabella non e' un muro; una forma `-1` (stato invisibile) non ha rettangolo di urto in `ClipToWalls` (il C legge una riga che non c'e' della tabella degli sprite quando `NewState` entra in uno stato con forma -1: nel gioco ne esiste uno, `s_powerblink2`); uno stato senza stato seguente che riceve piu' tic di quelli che ha toglie l'attore (il C leggeva uno stato nullo); la registrazione di un demo avanza dall'offset 0 (il C scriveva sempre la prima coppia); in riproduzione il demo e' il moto (il C usa una variabile `realdelta` non inizializzata); la riproduzione lavora su una copia e non conta i giri nel buffer di chi la chiama; `RemoveObj` decrementa il numero degli attori (il C no); un intervallo di joystick nullo da' `EKeenException` (il C ha una divisione per zero). Ognuna ha un test.

## Collegare al motore

Niente: Keen32 e' un programma a parte (per ora scrive PNG: `-map`, `-view`). Per giocare servono, in ordine: le azioni degli stati e i `Spawn*` (K8b: sono la logica del giocatore e dei nemici, 67 funzioni di think/contact/react, gia' elencate in `DelphiDoom.Keen.ActionIds` con il nome del C; il motore le chiama tramite `IKeenActions` e `IKeenActorSpawner`), una finestra che mostri `TKeenDisplayCapture` con `TKeenEgaPalette` e un ciclo di tic a 70 Hz sopra `Libs\Clock` (`IKeenClock`, `TKeenKeyboardPump` come `IKeenInputPump`), poi `ID_US` e le schermate (K11, K12).

## Cosa resta da verificare con l'originale

Un harness DOS che giri il C compilato con Open Watcom (`Reference\_dati\keen_build\src`) in DOSBox e scarichi con `VW_ScreenToMem` la memoria video dopo N refresh darebbe un golden dei piani EGA per `ID_VW`/`ID_RF` e, con i tasti iniettati, lo stato degli attori dopo N tic; non e' stato fatto in questa sessione (il confronto e' quello descritto sopra). Non provati: modo `comp` e joystick/mouse su una macchina vera.
