# Libs\Speed - i dati di Speed Haste in un WAD (issue #166, fette S1 e S2)

> Note per Claude e paragrafi di dettaglio (issue #178): [CLAUDE.md](CLAUDE.md).

Speed (`Reference\Speed`, `GLSpeed`) è un fork di DelphiDoom 2.05 che fa girare **Speed Haste** (Noriaworks, 1995, corse di auto) sul motore di
Doom. Il gioco parte da `SPEEDH.JCL` e genera in memoria un WAD in formato Doom (`speed_xlat_wad.pas` e le unit `speed_*` che usa). Questa
libreria porta a classi **la parte pura**: il contenitore (S1) e il traduttore (S2). Tutto il resto del fork (regole, auto, IA, menu, HUD,
modelli I3D, `r_soft3d`) è S3 e oltre, vedi sotto.

## Il formato di `SPEEDH.JCL`

* In **fondo al file** c'è l'intestazione di 16 byte (`TSpeedJclHeader`): firma `$DF73B489`, due conteggi uguali, e quanti byte prima della fine
  comincia la directory. La directory è di 32 byte per file (`TSpeedJclEntryRecord`: nome di 24 byte `AnsiChar`, poi posizione e dimensione).
* La posizione di un file è una **distanza all'indietro dall'inizio della directory** (il contenitore è scritto dalla fine): il file comincia a
  `inizio directory - posizione`.
* Il vecchio traduttore ordinava la directory a bolle: prima per il numero con cui il nome comincia (`atoi` della parte prima del primo punto:
  `22.IS2` vale 22, `MENUS.S3M` vale 0), poi per nome. `TSpeedContainer` ha lo stesso ordine (ordinamento per inserzione, stabile) e `TSpeedNames`
  tiene le regole sui nomi (`atoi` di `d_delphi` con `0x`, `$`, `#`; "numero scritto in modo canonico").
* **La dimensione scritta nella directory di alcune immagini è più piccola di quanto dice l'immagine** (nello shareware `21.IS2`: 8192 byte, ma l'intestazione
  dice 37909 byte di dati): il vecchio codice rileggeva `len + 24` byte dal file; `ISpeedContainer.ReadAtLeast` fa lo stesso.
* Il file `.IS2` (`TSpeedIs2Header`, 24 byte): firma `.IS2`, larghezza e altezza, hot spot, rapporti, flag (1 = a righe), lunghezza dei dati; poi, per ogni colonna
  (o riga) la posizione di partenza e le sequenze di pixel con i salti fra una e l'altra; i pixel non coperti sono 255. Il vecchio `AttachIS2` non
  aveva `begin`/`end` attorno a un `if` e quindi il passo `Inc(x)` è per ogni pixel (conservato, con il commento).
* `.PIX`: immagini di 320 pixel di larghezza (l'altezza è la dimensione diviso 320); se esiste un `.PAL` con lo stesso nome (768 byte, 6 bit) i colori vanno
  alla palette del gioco, altrimenti i colori fuori da 16..239 prendono quello del pixel prima. `.RAW`: campioni a 8 bit senza intestazione. `GRAFS.DAT`: tessere
  64x64 (i flat), `GRAFS.PAL`: la palette (6 bit), `MAPnn.DAT/.SEC/.PTH`: le piste.

## Che cosa c'è (S1 e S2)

| Unit | Ruolo |
|---|---|
| `Types`, `Intf` | i record su disco (`packed`, con un test su `SizeOf`), le costanti, le interfacce (`ISpeedContainer`, `ISpeedTranslator`, ...) |
| `Names` | `TSpeedNames`: `atoi`, ordinamento, estensioni |
| `Container` | `TSpeedContainer` (**S1**): intestazione, directory, lettura per nome e per indice |
| `PaletteBuilder` | `SH_CreateDoomPalette`: PLAYPAL (14 palette) e COLORMAP (34 mappe) dalla palette del gioco |
| `Is2Decoder` | `TSpeedBitmap.AttachIS2` |
| `CircuitReader` | la lettura di `CIRCUITS.LST` (sopra `TScriptScanner` di `Libs\Scanner`) |
| `LevelBuilder` | `SH_CreateDoomLevel`: una pista come livello di Doom (THINGS, LINEDEFS, SIDEDEFS, VERTEXES, SECTORS, PATH, più le correzioni di E1M1 ed E1M8 per le piste originali, riconosciute dal CRC32 del `.DAT`) |
| `MapBitmapBuilder` | `GenerateMapBitmap`: le 64x64 tessere ruotate in un'immagine di 4096x4096 (il lump `FMAPnn`, 16 MB) |
| `FontData`, `FontBuilder` | `GenerateFonts`: i caratteri 33..127 in due misure e cinque colori, con il rumore di Perlin |
| `RawSound` | `SH_RawToWAV` |
| `Translator` | `TSpeedTranslator` (**S2**): `TSpeedToWADConverter` (PLAYPAL, COLORMAP, texture dei muri con PNAMES e TEXTURE1, flat e le 24 traduzioni del flat 62, FMAPnn, livelli con MAPDATA, immagini, font, sprite, musica, suoni con SNDINFO, GRAFSPAL/GRAFSDAT, SPEEDINF e FLATSIZE) |
| `Factory` | `TSpeedFactory`, l'unico punto che conosce le classi |

Uso: `TSpeedFactory.CreateTranslator(log).Translate(TSpeedFactory.OpenContainer('SPEEDH.JCL'), TGameDataFactory.CreateWadComposer)` riempie il WAD e dà le voci
`MODELS\xxx.I3D` (posizione e dimensione nel contenitore: i modelli non entrano nel WAD, il motore li legge dal `.JCL`, come il vecchio `PAK_AddEntry`).
`composer.ToBytes` è il WAD, che il motore apre con `TWadFactory.OpenBytes`.

## Verifica

* **Parità sul vecchio codice**: l'intero `speed_xlat_wad.pas` del fork, con le unit che usa (`d_delphi`, `w_wadwriter`, `speed_*`...), compilato con Delphi 11 in un
  harness **fuori dal repository** (`Tests\Data\Speed\README.md` dice com'è fatto), ha tradotto `SPEEDH.JCL` (shareware di Speed Haste, `Reference\_dati\speed`: 376 file, 1613 lump) e un
  gioco sintetico (`TJclBuilder.SyntheticGame`, 363 KB, con i casi che lo shareware non ha: salto di dimensione della directory, `.PIX` con `.PAL`, il flat 62, due piste e una
  pista senza i file). I due `translation.*.golden.txt` hanno numero, nome, dimensione e impronta FNV-1a di ogni lump più le voci del PAK: **la libreria dà le stesse righe,
  nessuna differenza** (1664 righe sul gioco vero, 1154 sul sintetico; il vecchio codice traduce lo shareware in circa 2 secondi, la libreria in meno di 1).
  Il test sul gioco vero si salta se `SPEEDH.JCL` non c'è (`bin\Speed\`, `Reference\_dati\speed\`).
* Test in `Tests\DelphiDoom.Tests.Speed` (133, copertura 96%): nomi, contenitore (anche contenitori rotti), decodifica IS2 (anche dati troncati), palette, circuiti, livello, tessere,
  suoni, traduttore.

## Differenze dal vecchio codice (e difetti Unicode che non si ereditano)

* **Unicode**: `speedlump_t.filename` era `array[0..23] of char` (48 byte in Delphi 11: la directory si leggeva male, e l'avvio si fermava su
  `stringtochar8(): length of WALL... > 8`); ora è `AnsiChar`. `CIRCUITS.LST` si leggeva con un `PChar` (due byte per carattere); `TWadWriter.AddString` scriveva due byte per carattere
  e `TDStrings.GetTextStr` copiava `L` byte per `L` caratteri (testi dei lump SNDINFO, SPEEDINF, FLATSIZE e MAPDATA rovinati). Nell'harness queste tre cose sono state corrette al minimo
  per avere un'uscita da confrontare (e `sc_engine`, che dopo circa 90 token dava caratteri a caso, è stato sostituito da un dividitesto semplice); la libreria legge un byte per carattere.
* **Dati sbagliati** (il vecchio leggeva o scriveva fuori dai buffer, o si fermava con `I_Error`): una directory fuori dal file o con la firma sbagliata è `ESpeedException` all'apertura;
  un file fuori dal contenitore lo è alla lettura; un `.IS2` che non è un'immagine, o una patch più alta di 255, danno un avviso all'`ILog` e il lump manca; un `.SEC` incompleto, con più linee
  di quanto dice l'intestazione, con un vertice che non c'è o con una texture più lunga di 8 caratteri, dà un avviso e la pista manca; un `.DAT` troppo corto per le tessere non dà il flat né il livello;
  un `.PTH` senza firma dà un avviso e un lump PATH vuoto (il vecchio ne leggeva il numero di punti da byte a caso); una tessera che il `GRAFS.DAT` non ha è nera.
* **Non portato perché non serviva**: le tre tabelle di traduzione (`RedFromBluePal`, ...) che il vecchio calcolava e non usava mai; `AddPAKFileSystemEntry` (senza chiamanti).
* **Conservato**: se manca `MENUS.S3M` non c'è nessuna musica; `GRAFSDAT` si scrive (anche vuoto) se c'è `GRAFS.PAL`; gli sprite di cui manca l'immagine sono comunque in `SPEEDINF`; il
  limite di 8 piste; `ground=` di `MAPDATA` è il flat della prima tessera della pista. La palette del file non si modifica (il vecchio la moltiplicava per 4 nel buffer del chiamante).
* **Aritmetica**: il rumore dei font usa `Integer` con il giro (`{$Q-}{$R-}` nell'unit, come l'originale) e `Double`: le impronte dei 950 caratteri coincidono (Win32).

## Che cosa non è fatto (S3 e oltre)

| Fetta | Che cosa | Note |
|---|---|---|
| S3 (fatta, #168) | `Libs\Models`: parser e disegno su contratto dei modelli I3D (`Libs\OpenGl\Legacy\i3d_*`, `mdl_i3d`), vedi `Libs\Models\README.md` sez. 2b | il traduttore dà le voci `MODELS\x.I3D`; manca solo l'adattatore OpenGL nel motore (con S5) |
| S4 (fatta, #168) | `Libs\Racing`: auto, guida, IA, percorso, gara, record, campionato (`speed_cars`, `speed_path`, `speed_race`, `speed_score`, `speed_particles`, `speed_championship`), vedi `Libs\Racing\README.md` | parità con il vecchio codice compilato in un harness (0 differenze su 111 righe); il `double` del `mobj_t` resta nel `TRacingCarState` che il gioco copia da e verso l'oggetto; a 64 bit compila ma la parità è provata solo a 32 |
| S5 (iniziata, #168) | cartella `Speed\` e il gioco: `mobj_t`/`player_t` propri, azioni, HUD, menu, schermate, record su disco, `m_base` e `TSpeedLevelRules`, profilo Iwad; eseguibile `GLSpeed32` | **fatto**: `Speed\Speed32.dpr` (`Tools\build.bat Speed\Speed32`), programma di prova senza finestra né motore che traduce `SPEEDH.JCL` e fa correre le auto del computer sui dati veri (`-list`, `-level`, `-laps`, `-cars`, `-tics`; `DelphiDoom.Speed.RaceSimulation`). **Resta tutto il gioco**: il meccanismo di profilo è in `Libs\GameData\README.md`; i savegame vanno a `Libs\Serializer` con la tabella del gioco |
| S6 | `r_soft3d` (rasterizzatore software dell'auto del menu) | opzionale: Speed è solo OpenGL |

Non verificato a runtime nel motore: nulla di questa libreria è collegato al motore (non esiste ancora il gioco Speed); la parità è sui byte dei lump. `Speed32` ha fatto correre le auto di `Libs\Racing` sui lump veri dello shareware (E1M1 ed E1M2) senza errori, ma senza un riferimento dal vecchio gioco.
