# Libs\XcomFormats

> Note per Claude e paragrafi di dettaglio (issue #178): [CLAUDE.md](CLAUDE.md).

Lettori in Delphi dei **formati dei dati originali di UFO: Enemy Unknown e X-COM: Terror from the Deep** (Microprose 1994/1995), nella forma in cui li legge **OpenXcom** (`Reference\OpenXcom`). Solo classi pure: niente SDL, YAML né finestra. Issue #176, prima fetta del port di OpenXcom (analisi in `Reference\_analisi\openxcom.md`).

Non è un gioco del motore Doom: ha il suo eseguibile (`OpenXcom\Xcom32.dpr`, che e' anche il gioco: issue #180; composition root dell'esportazione `OpenXcom\DelphiDoom.Xcom.Composition.pas`) e **non tocca** `ComposeEngine` né `TIdTechGeneration`. Riusa `Libs\Video` (`IPaletteConverter`), `Libs\Png` (`TPngClient`) e `Libs\Platform` (`IFileStore`).

## Licenza (da decidere)

OpenXcom è **GPL v3 o successiva** (le intestazioni dei suoi sorgenti); il repository DelphiDoom è GPL v2 o successiva. **Il codice di questa libreria deriva da OpenXcom** (gli algoritmi dei loader sono stati letti dai sorgenti e riscritti in Pascal, e il formato dei golden e dei casi di prova è costruito sui loro comportamenti): è quindi **GPL v3 o successiva**, e lo dichiara l'intestazione di ogni unit. **La licenza dell'opera che lo contiene va decisa dal proprietario del repository prima di distribuirlo**: questa fetta non cambia la licenza del repository (resta GPL v2+ dichiarata altrove) e nessun sorgente C++ di OpenXcom è stato copiato nel repository (l'harness di parità sta fuori, vedi sotto). I dati di gioco di UFO e TFTD sono proprietari e non sono nel repository.

## Cosa c'è

| Formato | Classe | Sorgente C++ letto |
|---|---|---|
| `.PCK` + `.TAB` (sprite RLE; il TAB dà solo il numero dei fotogrammi) | `TXcomPckDecoder` | `SurfaceSet::loadPck` |
| `.DAT` di immagini grezze | `TXcomDatDecoder` | `SurfaceSet::loadDat` |
| `.SCR` (320x200 grezzo) | `TXcomScrDecoder` | `Surface::loadScr` (`loadRaw`/`rawCopy`) |
| `.SPK` (RLE a parole) | `TXcomSpkDecoder` | `Surface::loadSpk` |
| `.BDY` (RLE tipo PackBits, TFTD) | `TXcomBdyDecoder` | `Surface::loadBdy` |
| `GEODATA\PALETTES.DAT`, `BACKPALS.DAT` (6 bit, per 4) | `TXcomPaletteReader`, `TXcomPalette` | `Palette::loadDat`, `Mod::loadVanillaResources` |
| `.CAT` (indice di voci con nome) | `TXcomCatArchive` | `CatFile` |
| `.MAP` (blocchi del battlescape, **tre `Shortint` all'inizio**) | `TXcomMapReader`, `TXcomMap` | `BattlescapeGenerator::loadMAP` |
| `.RMP` (nodi dei percorsi, collegamenti 251-255, nodi fuori blocco) | `TXcomRouteReader` | `BattlescapeGenerator::loadRMP` |
| `.MCD` (terreno, record da 62 byte `packed`) | `TXcomMcdReader` | `MapDataSet::loadData` |
| `WORLD.DAT` (poligoni del globo, ottavi di grado -> radianti) | `TXcomWorldReader` | `RuleGlobe::loadDat`, `Xcom2Rad` |
| `LOFTEMPS.DAT` (parole a 16 bit) | `TXcomWordTableReader` | `MapDataSet::loadLOFTEMPS` |
| `.LBM` (IFF PBM/ILBM, come `IMG_Load` di SDL_image 1.2.12) | `TXcomLbmReader` | `Surface::loadImage` (via SDL_image) |
| `UFOGRAPH\D0..D3.LBM` -> palette del battlescape di TFTD | `TXcomBattlescapePalette` | `Mod::loadVanillaResources`, `Palette::setColors` |

Supporto: `TXcomBinaryReader` (le abitudini di `std::ifstream`: lettura che fallisce copia i byte che ci sono, dopo il primo fallimento non si legge più), `TXcomImage` (immagine a 8 bit con palette opzionale: `Surface` senza SDL), `TXcomSpriteSheet` (i fotogrammi in una griglia), `TXcomMapPicture` (vista schematica di un piano del blocco), `TXcomGameData` (`IXcomGameData`: i file di UFO/TFTD per nome), `TXcomFolderFiles` e `TXcomMemoryFiles` (`IXcomDataFiles`), `TXcomPngEncoder` (`IXcomImageEncoder`, sopra `IPaletteConverter` e `TPngClient`) e `TXcomImageExporter`. `TXcomFactory` è l'unico punto che conosce le classi. Tipi e record `packed` senza puntatori (con `SizeOf` coperto da test) in `DelphiDoom.Xcom.Types`; interfacce piccole in `DelphiDoom.Xcom.Intf`.

## Esportazione (`Xcom32`)

`OpenXcom\Xcom32.dpr` (`Tools\Build.bat Xcom32`, uscita in `bin\OpenXcom`) e' l'unico eseguibile di OpenXcom (issue #180): senza argomenti, o con quelli del gioco, apre il gioco (vedi `Libs\XcomEngine`); **quando la riga di comando ha `-pck`, `-dat`, `-scr` o `-map`** esporta un file di dati come PNG (`TXcomExportArguments`, `TXcomExportTool` in `OpenXcom\`):

```
Xcom32 [-data <cartella>]... [-pal <n>] [-png <file>]
       -pck <file> [-tab <file>] [-w n] [-h n] [-columns n]   fotogrammi di un PCK (32x40) come PNG con alfa
     | -dat <file> [-w n] [-h n] [-columns n]
     | -scr <file> [-w n] [-h n]                               .SCR, .SPK o .BDY dall'estensione (320x200)
     | -map <file> [-rmp <file>] [-z n]                        celle e nodi su stdout, un piano come PNG
```

`-data` nell'esportazione (ripetibile; `-game` vale lo stesso) è la cartella del gioco (quella con `GEODATA\PALETTES.DAT`); `-pal 4` è la palette del battlescape con il gradiente grigio degli ultimi 16 colori. Provato su file sintetici (palette, SCR, PCK/TAB con trasparenze, MAP e RMP con un nodo fuori blocco) e, dalla seconda prova, **sui dati veri di TFTD** (vedi "Dati veri" sotto): `BACK01.SCR` con la palette 0 e i terreni (`PORT01.PCK`) escono giusti.

## Verifica e parità

La parità con il C++ è stata ottenuta così (i dati originali non c'erano quando è stata fatta; ora ci sono, vedi "Dati veri" più sotto):

- **Harness C++ fuori dal repository** (`scratchpad`, non committato: contiene codice di OpenXcom). Le funzioni foglia sono copiate alla lettera dai sorgenti (`SurfaceSet::loadPck/loadDat`, `Surface::loadScr/loadSpk/loadBdy`, `Palette::loadDat`, `CatFile`, il corpo di lettura di `loadMAP` e di `loadRMP` con una lista di nodi finta, `MapDataSet::loadData` e `loadLOFTEMPS`, `RuleGlobe::loadDat` con `Xcom2Rad`) con uno stub di `Surface` (buffer a 8 bit con il pitch `GetPitch` di OpenXcom), `SDL_Color`, `SDL_SwapLE*` ed `Exception`. Compilato con **g++ 16.2 (MinGW i686, `w64devkit` in `Reference\_dati\_strumenti`)** con `-std=c++11 -O0 -msse2 -mfpmath=sse -static` (doppi veri a 64 bit, senza x87 esteso). Cambiamenti rispetto agli originali: `Uint8 value = 0` in `loadPck` e `loadSpk` (nell'originale è non inizializzata e un file vuoto la legge), e 60 byte a zero in coda ai `.CAT` di prova (una voce che tiene il nome non legge mai oltre la fine del file, dove il C++ dà byte che nessuno ha scritto).
- **Casi pseudo casuali**: un generatore `x = x * 1664525 + 1013904223` a 32 bit (numero = 16 bit alti) dà 300 file per ognuno dei 12 formati (dimensioni piccole, flussi con molti 254/255 e 65534/65535, troncamenti a metà di una sequenza, nomi di voce da 0 a 255, byte di intestazione `.MAP` oltre 127, nodi `.RMP` fuori blocco e con collegamenti 245-255, terreni validi e non, angoli del globo agli estremi). `DelphiDoom.Tests.Xcom.Cases` è lo stesso generatore in Pascal: stessi numeri nello stesso ordine.
- **`Tests\Data\Xcom\xcom_golden.txt`**: 3600 righe, la risposta del C++ (impronte FNV-1a dei pixel, dei record, dei nodi; bit dei doppi). `DelphiDoom.Tests.Xcom.Golden` le confronta una per una: **0 differenze** in Win32 (Release e Debug) e in **Win64**, anche sui doppi del globo.
- Test a mano per ogni classe con file costruiti in memoria, e test sui **dati veri** (`DelphiDoom.Tests.Xcom.RealData`: ogni PCK con il suo TAB, ogni SCR, ogni MAP, RMP e MCD, le cinque palette) che si saltano se la cartella del gioco non c'è (`DELPHIDOOM_XCOM_DATA`, `Reference\_dati\xcom` o `Reference\_dati\xcom_tftd\TFTD`). Eseguiti su dati veri di TFTD: vedi "Dati veri".
- Numeri: 196 test (Win32 Release 196/196, Debug 196/196 senza perdite di memoria, Win64 196/196), copertura **99%** (628 righe su 631, `Tools\Copertura.ps1 -Test Xcom -Cartella Libs\XcomFormats`).

Per rifare i golden serve ricompilare l'harness: copiare le funzioni citate sopra da `Reference\OpenXcom\src` in un `.cpp` fuori dal repository con gli stub descritti e lo stesso generatore (la ricetta è in questo file e in `Tests\Data\README.md`).

## Comportamenti del C++ riprodotti (e dove ci si discosta)

Riprodotti perché sono ciò che il gioco fa con i dati veri:

- **`char` con segno**: le tre dimensioni di un `.MAP` sono `Shortint` (128..255 diventano negativi; `ReadHeader` le dà così). `Read` rifiuta un blocco con una dimensione non positiva o con più celle di quante ne dica la dimensione (nel C++ la differenza compare più tardi, nel confronto con la dimensione del blocco delle regole, o è un comportamento indefinito).
- **`std::ifstream`**: una lettura che trova meno byte di quanti ne chiede li copia comunque e fallisce, e dopo il primo fallimento non legge più; i decoder non controllano ciò che leggono, quindi un file troncato dà gli stessi pixel del C++ (ultimo valore letto ripetuto, byte basso di una parola troncata): `TXcomBinaryReader`.
- Il primo byte di ogni fotogramma `.PCK` è il numero di **righe vuote** anche se vale 255 (non è la fine del fotogramma); il `.TAB` serve solo a contare i fotogrammi (dimensione divisa per 2 o per 4 secondo il primo valore a 32 bit, `off != 0` -> offset a 16 bit): gli offset non sono usati.
- `.BDY`: una ripetizione e una sequenza non passano mai alla riga dopo; ciò che resta è scartato.
- Palette: `valore * 4` nel byte (un valore sopra 63 si avvolge), alfa 0 per il colore 0 e per quelli che il file non ha.
- `.RMP`: `connectID <= 250` somma `nodeOffset`, 251-255 sono direzioni (`-5..-1`), un nodo fuori blocco è un finto che resta nell'elenco e i collegamenti a lui diventano -1.
- `.CAT`: il primo valore dell'indice dà il numero di voci (`/ 8`); una voce con primo byte <= 56 comincia con un nome (saltato, a meno di tenerlo).

Differenze volute (difetti o comportamenti indefiniti del C++), ognuna con un test: un `.TAB` di 1-3 byte (il C++ legge una variabile non inizializzata) o oltre 65536 fotogrammi è un errore; un `.DAT` più corto di un fotogramma dà zero fotogrammi (il C++ va in crash); una voce `.CAT` oltre l'indice è un errore (il C++ restituisce 0) e una più grande di 256 MB pure; i byte di una voce `.CAT` oltre la fine del file sono zero (il C++ lascia la memoria com'era); `CatFile::load(i, true)` del C++ somma ogni volta la lunghezza del nome a `_size[i]` e una seconda lettura ne darebbe di più: `Load` non ha stato; una palette con più di 256 colori o un offset negativo sono errori; `SetLength` di Delphi non azzera i byte nuovi, quindi `TXcomImage.Create` li azzera (il test di parità lo ha trovato: il primo giro dava pixel a caso).

## Non fatto (fette successive)

`Libs\Yaml` (parser delle regole `.rul`, opzioni, lingue, salvataggi), `Libs\XcomSurface` (`Surface8` con blit, ombra, `Zoom`, linee) e `Libs\Opl`; i formati `LOC.DAT`, `SCANG.DAT`, `TEXTURE.DAT`, `INTERWIN.DAT` (è un `.SCR`, già leggibile), `LOFTEMPS` come voxel di tile, i file `.CAT` di suoni (`SoundSet`: conversione a 11025 Hz e WAV), `GM.CAT`, i filmati `.FLC` (`Libs\Flic`) e il `Palette::savePal`; **`GEO.DAT`** non ha un lettore nel C++ con questo nome (non l'ho trovato in `src`). Poi `XcomMod`, `XcomSave`, `XcomUi`, il Geoscape, il Basescape e il Battlescape (generatore, `TileEngine`, `Pathfinding`, AI). Il collegamento delle classi di questa libreria a un `Mod` è la fetta successiva a `Yaml`.

## Dati veri (TFTD, 2026-11-09)

L'utente ha fornito X-COM: Terror from the Deep su floppy (`disk1..4.img`: il gioco completo) e la demo PC Gamer (`PCGamerTerrorFromTheDeepDemo.zip`), in `Reference\_dati\_download` (non fidati: mai eseguiti da lì). `Tools\Verifica\176` li prepara senza eseguire nulla:

- `Extract-Fat12.ps1` apre un'immagine floppy FAT12 (BPB, FAT a 12 bit, cartella radice e sottocartelle) e copia i file in una cartella nuova; `Extract-TftdZips.ps1`: `TFTD.001..004` sono **33 archivi ZIP in fila** (ognuno con il suo central directory, offset relativi al proprio inizio; non uno ZIP suddiviso), si concatenano, si taglia dopo ogni "end of central directory" e si apre ogni pezzo con `System.IO.Compression`: 1115 file, 12602490 byte, tutti nella stessa cartella; `Make-TftdLayout.ps1` li mette nelle cartelle del gioco (`GEODATA`, `GEOGRAPH`, `UFOGRAPH`, `UNITS`, `TERRAIN`, `MAPS`, `ROUTES`, `SOUND`, `FLOP_INT`; i file che OpenXcom cerca in due posti si copiano in entrambi). Il gioco ha 298 `.MAP`, 297 `.RMP`, 64 `.MCD`, 94 `.PCK` (93 `.TAB`: `UNIBORD.PCK` non ne ha), 151 `.BDY`, 53 `.LBM`, 17 `.SCR`, 5 `.CAT`.
- **OpenXcom vero** (nightly ufficiale 2026-06-05, mod `xcom2`) parte con questi dati e mostra la geoscape (globo con la texture di `TEXTURE.DAT`/`WORLD.DAT`), la nuova base, le relazioni internazionali, il basescape con i sottomarini Triton e i menu in italiano: `Run-OpenXcomTftd.ps1`. L'originale parte in DOSBox Staging (`Run-TftdDos.ps1`, `terror.com`, `sbtype none`): scelta della lingua, logo MicroProse, introduzione (Marte, titolo); dopo l'introduzione la geoscape originale resta su schermo nero fino a 90 secondi (non diagnosticato: si è guardato il gioco con OpenXcom). Le cartelle che cerca il lanciatore sono `UFOEXE\`, `UFO2EXE\` e `SOUND\` con gli eseguibili dentro (`LEGGIMI.md` della cartella).
- **Test sui dati veri** (`DelphiDoom.Tests.Xcom.RealData`, ora 11): **201 test passano** (196 di prima + 5 nuovi) con TFTD. Ogni `.PCK` con il suo `.TAB`, ogni `.SCR`, 298 `.MAP`, 297 `.RMP`, ogni `.MCD`, ogni `.CAT` del suono (le voci stanno dentro il file), `WORLD.DAT` (più di 100 poligoni di 3 o 4 punti con texture 0..31), `LOFTEMPS.DAT` (parole in multipli di 16), ogni `.BDY` e `.SPK` (320x200 con dati) e i fotogrammi degli oggetti dei terreni dentro il rispettivo `.PCK`. Il confronto con le immagini del gioco (a mano, sui PNG di `Xcom32`): `BACK01.SCR` è lo sfondo del menu del gioco con la palette 0; `PORT01.PCK` mostra i blocchi del porto subacqueo; `TDXCOM_0.PCK` i soldati.
- **Cosa hanno trovato i dati veri**: (1) `PALETTES.DAT` di TFTD ha **tre** palette (2322 byte = 3 x 774), non cinque come UFO: il test che ne chiedeva cinque era sbagliato (non la libreria: una palette oltre la fine del file è tutta alfa 0) e ora conta quelle del file; la palette del battlescape di TFTD non sta in `PALETTES.DAT` ma in un `.LBM` (`BACKG.LBM`, il motore la prende da lì), perciò `Xcom32 -pal 4` colora male i soldati e i terreni di TFTD (le forme sono giuste); (2) gli oggetti 39, 40 e 41 di `XBASES05.MCD` hanno fotogrammi (74, 75, 76) oltre i 74 del suo `.PCK`: è un difetto dei dati originali (il gioco non li disegna mai), il test lo ammette solo lì. Nessun difetto della libreria è emerso.
- **Non provato**: i dati di UFO: Enemy Unknown (non ci sono), le animazioni (`ANIMS`) e i campioni `SAMPLE2.CAT` che il gioco floppy non ha, la lettura dei `.LBM` (non è in questa libreria), il battlescape di OpenXcom (non lo si è avviato).

## Un solo eseguibile (issue #180)

`Xcom32.exe` e' anche il gioco (prima `XcomGame.exe`). Il modo dipende dalla riga di comando: con `-pck`, `-dat`, `-scr` o `-map` esporta, altrimenti apre il gioco. `-data` nell'esportazione e' la cartella del gioco (ripetibile, e `-game` vale lo stesso); nel gioco e' la cartella con `common\` e `standard\`. Il programma e' GUI: il testo dell'esportazione si legge con una pipe (`Xcom32 ... | Out-String` in PowerShell). Dettagli e verifica in `CLAUDE.md` di questa cartella.

Aggiornamento (sessione "schermate mancanti", #176): `TXcomFlcDecoder` legge le animazioni FLI/FLC (il decoder di `FlcPlayer`); 891 fotogrammi di `UFOINT.FLI` uguali al vero. Vedi `CLAUDE.md`.
