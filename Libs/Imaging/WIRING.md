# Libs\Imaging - come collegarla al motore (issue #77, parte della #45)

La libreria decodifica patch e flat in buffer di pixel, ricostruisce le colonne di una texture, ingrandisce i
flat, calcola le tabelle di colore delle texture ad alta risoluzione, la scala dei muri e fa il melt del wipe,
tutto su byte o buffer di pixel che riceve (`TBytes`, `TArray<Cardinal>`). Non conosce `screens[]`, le zone di
memoria, i globali del renderer né OpenGL. Dipende solo da `System.*`. Il collegamento non è stato fatto (non
era compito di questo lavoro): qui sotto c'è cosa serve e cosa è rimasto fuori.

**Le routine di disegno dei renderer (`r_col_*`, `r_draw*`, `r_span*`, `r_batchcolumn`, `r_flat32`, ...) non sono
state toccate né portate: restano nel motore per le prestazioni.**

## 1. Unit da aggiungere ai `.dpr`

Servono ai progetti che compilano `r_data`, `r_patch`, `r_grow`, `r_scale`, `r_hires`, `f_wipe`,
`r_cache_flats`, `r_flatinfo` (giochi software e OpenGL, e i `ddc_*` solo se compilano `r_data`):

```
  DelphiDoom.Imaging.Types in 'Libs\Imaging\DelphiDoom.Imaging.Types.pas',
  DelphiDoom.Imaging.Intf in 'Libs\Imaging\DelphiDoom.Imaging.Intf.pas',
  DelphiDoom.Imaging.ColorMath in 'Libs\Imaging\DelphiDoom.Imaging.ColorMath.pas',
  DelphiDoom.Imaging.ColumnPainter in 'Libs\Imaging\DelphiDoom.Imaging.ColumnPainter.pas',
  DelphiDoom.Imaging.ColumnRebuilder in 'Libs\Imaging\DelphiDoom.Imaging.ColumnRebuilder.pas',
  DelphiDoom.Imaging.FixedColumn in 'Libs\Imaging\DelphiDoom.Imaging.FixedColumn.pas',
  DelphiDoom.Imaging.PatchReader in 'Libs\Imaging\DelphiDoom.Imaging.PatchReader.pas',
  DelphiDoom.Imaging.FlatReader in 'Libs\Imaging\DelphiDoom.Imaging.FlatReader.pas',
  DelphiDoom.Imaging.FlatShrinker in 'Libs\Imaging\DelphiDoom.Imaging.FlatShrinker.pas',
  DelphiDoom.Imaging.SpanGrower in 'Libs\Imaging\DelphiDoom.Imaging.SpanGrower.pas',
  DelphiDoom.Imaging.ColumnExpander in 'Libs\Imaging\DelphiDoom.Imaging.ColumnExpander.pas',
  DelphiDoom.Imaging.HiResTables in 'Libs\Imaging\DelphiDoom.Imaging.HiResTables.pas',
  DelphiDoom.Imaging.MeltWipe in 'Libs\Imaging\DelphiDoom.Imaging.MeltWipe.pas',
  DelphiDoom.Imaging.SineTable in 'Libs\Imaging\DelphiDoom.Imaging.SineTable.pas',
  DelphiDoom.Imaging.WallScale in 'Libs\Imaging\DelphiDoom.Imaging.WallScale.pas',
  DelphiDoom.Imaging.Factory in 'Libs\Imaging\DelphiDoom.Imaging.Factory.pas',
```

Riga da aggiungere in `Tools\build.bat`, alla fine della lista `TESTS`:
` Tests\DelphiDoom.Tests.Imaging`

## 2. Cosa sostituisce cosa

| Vecchio codice | Nuova classe (`TImagingFactory`) | Note per il collegamento |
|---|---|---|
| `R_DrawColumnInCache`, `R_DrawColumnInCacheMultipatch` (`r_data.pas`) | `CreateColumnPainter` → `IImagingColumnPainter.Paint` | un metodo solo: con `AMarks` vuoto è la versione senza segni |
| il blocco "ricostruisci le colonne dai segni" di `R_GenerateComposite` (`r_data.pas`) | `CreateColumnRebuilder` → `Rebuild` | in sito sul blocco, dalla testata del primo post |
| `_generatedata128`, `_generatedataTL` di `R_GetFixedColumn` (`r_patch.pas`) | `CreateFixedColumnBuilder` → `Repeat128`, `FromPosts` | la cache `fixedcolumns[]` (hash, Z_Malloc, PU_LEVEL) **resta nel motore** |
| lettura di un patch in un'immagine (nuova, sopra il pittore) | `CreatePatchReader` → `Read` | immagine a righe con maschera di opacità |
| conversione di un flat con la palette in `R_ReadDS32Cache` (`r_cache_flats.pas`) | `CreateFlatReader` → `Read` | la cache `ds32cache[]`, i flat hi-res esterni (`T_LoadHiResTexture`) e le palette personalizzate restano nel motore |
| `R_ShrinkFlatTo64x64` (`r_flatinfo.pas`) | `CreateFlatShrinker` → `Shrink` | corregge un difetto (vedi sotto) |
| `R_GrowSpan64to128/256/512`, `R_InitSpanTables` (`r_grow.pas`) | `CreateSpanGrower` → `Grow64to128/256/512` | le tabelle sono interne alla classe |
| `R_ExpandColumn` (`r_grow.pas`) | `CreateColumnExpander` → `Expand` | in sito, serve un buffer di 129 * fattore pixel |
| `R_ColorAdd`, `R_ColorAverage`, ... (`r_hires.pas`) | `TImagingColorMath` (funzioni di classe, senza fabbrica) | `R_ColorMidAverage` ha ancora l'`asm` commentato nel vecchio: qui è solo Pascal |
| `R_CalcHiResTables_SingleThread` e le versioni a 2/4 thread (`r_hires.pas`) | `CreateHiResTableBuilder` → `Build(palette)` | dà `8 * 256 * 256` colori, indice `(livello * 256 + primo) * 256 + secondo`; i thread li decide il chiamante |
| `wipe_initMelt`, `wipe_doMelt` (`f_wipe.pas`) | `CreateMeltWipe(random)` → `Start`, `Advance` | `TImagingWipeSettings` ha passo e alfa della destinazione: software = (`SCREENWIDTH`, 0), OpenGL = (`WIPESCREENWIDTH`, `$FF000000`) |
| `R_ScaleFromGlobalAngle`, `_Fixed`, `_DBL` (`r_scale.pas`) | `CreateWallScale` → `FromGlobalAngle`, `FromGlobalAngleFixed`, `FromGlobalAngleDouble` | `viewangle`, `rw_normalangle`, `rw_distance`, `projectiony`, `max_rwscale`, `precisescalefromglobalangle` vanno nel `TImagingScaleContext` |
| `fixedsine` (`tables.pas`) | `CreateSineTable` (calcolata; il test la confronta con quella del motore) | `CreateWallScale` senza argomenti la usa; il motore può passare la sua dietro `IImagingSineTable` |

`IImagingRandom` (per il melt): l'adattatore del motore chiama `I_Random`. Va dato al composition root come
gli altri servizi (`ComposeEngine`); oggi non c'è un posto per le librerie di immagini, va aggiunto un
`ComposeImaging` accanto a `ComposeMusic`.

## 3. Rischio principale: i buffer

La libreria lavora su `TBytes` e `TArray<Cardinal>`, che **non possono avvolgere memoria del motore**
(`screens[]`, `screen32`, zone memory, `PByteArray`). Collegare così com'è vuol dire copiare:

- `R_DrawColumnInCache*`, `R_GetFixedColumn`, `R_GenerateComposite`: si chiamano alla creazione delle texture,
  non a ogni fotogramma; una copia per colonna è accettabile ma va misurata (`texturecompositesize` di una
  texture grande).
- `R_GrowSpan*`, `R_CalcHiResTables`, la conversione dei flat: si fanno al cambio di flat o di palette; la
  copia in uscita è dello stesso ordine del lavoro.
- **Il melt del wipe scrive a ogni tic in `screen32`**: copiare la destinazione a ogni fotogramma costa
  `SCREENWIDTH * SCREENHEIGHT * 4` byte (anche megabyte negli schermi grandi). Prima di collegarlo conviene un
  secondo passo che aggiunge alle interfacce una variante con puntatore e lunghezza (`PCardinal` + conteggio)
  accanto a quella con gli array; gli algoritmi non cambiano (sono già scritti sugli indici).

## 4. Non portato

- Disegno dei renderer (colonne, span, `r_col_*`, `r_draw*`, `r_span*`, `r_batchcolumn`): per decisione dell'issue.
- Le cache del motore (`fixedcolumns[]`, `ds32cache[]`, `texturecomposite[]`, `lumpcache[]`): sono zone memory
  e puntatori; la libreria non ne tiene una.
- `R_GenerateLookup`, `R_InitTextures` e la composizione dei patch per texture (`r_data.pas`): sono legate a
  `textures[]`, `texturecolumnlump[]`, `texturecolumnofs[]` e ai lump; la libreria dà solo le due parti pure
  (pittore e ricostruttore).
- `R_CmdLowestRes` ... `R_CmdUseExternalTextures`, `R_SetPalette`, `R_InitHiRes`, gamma e `pal_color`
  (`r_hires.pas`): comandi di console, globali e stato di video; `R_ColorLight*` che leggono tabelle del
  renderer non ci sono (i derivati puri sì: vedi `TImagingColorMath`).
- Il caricamento e il ridimensionamento delle texture hi-res esterne (`T_LoadHiResTexture`, `ScaleTo`,
  `ConvertTo32bit`, `t_*`): gestione dei file e delle immagini esterne (PNG, JPEG), fuori dal perimetro.
- `wipe_StartScreen`, `wipe_EndScreen`, `wipe_Ticker`, `wipe_ClearMemory`: leggono lo schermo
  (`I_ReadScreen32`, `I_ReverseScreen`) e allocano buffer; il tic e la lettura restano nel motore, che dà a
  `Advance` i buffer. `wipe_ColorXForm` non è mai stata implementata nel vecchio codice.
- `R_ShrinkFlatTo64x64` per i flat di 64x128: tiene i primi 64x64 come il vecchio.
- `V_DrawPatch*` e le altre routine di `v_video.pas` che disegnano un patch su `screens[]`: disegno, non
  decodifica.

## 5. Differenze volute dal vecchio codice

- **Dati controllati**: una colonna che non finisce, un post che esce dai byte, un patch con tabella o colonne
  fuori dal lump, un buffer troppo piccolo danno `EImagingException`; il vecchio leggeva memoria a caso.
- `R_ShrinkFlatTo64x64` da 128x128 in su scriveva con passo 128 (la variabile era dichiarata `128x128`) fuori
  dai 4096 byte del chiamante (`V_TileScreen8`), che poi leggeva con passo 64. Qui il passo è 64. I campioni
  presi sono gli stessi: il test confronta i golden letti con il passo vecchio.
- I pixel che il vecchio lasciava non scritti (colonna fissa, flat più corto del dovuto) sono 0, non memoria
  non inizializzata; un flat con la dimensione di FLATINFO più grande del lump non legge oltre il lump.
- Il ricostruttore di colonne alte: il vecchio girava all'infinito scrivendo post vuoti quando un run comincia
  oltre il pixel 254 e dista più di 254 dal precedente; qui è `EImagingException`.
- `R_ColorMidAverage` è la versione Pascal (la media di `R_ColorMean`), non l'`asm` MMX commentato.

## 6. Difetti del vecchio codice conservati (il test li fissa)

- `R_DrawColumnInCache*`: un post che comincia sopra la cache copia i **primi** pixel del post, non quelli che
  restano dentro (sposta la destinazione, non la sorgente). Il flag "tall patch" non cambia ciò che si dipinge.
- Ricostruzione delle colonne alte: un run più lungo di 254 pixel si divide in post che hanno tutti lo stesso
  `topdelta`, e gli scostamenti oltre 254 sono relativi all'inizio del run precedente.
- `R_GrowSpan64to128`: il pixel sotto l'originale si fonde per primo e quello che segue usa quel valore.
- `R_ExpandColumn` lavora in sito dall'ultimo gruppo al primo: con fattore 2 legge pixel che ha appena scritto.
- `R_ColorAverage`: il blu è mascherato con `$FF0000` senza essere spostato; il primo colore pesa
  `FRACUNIT - 1 - fattore`, quindi con fattore 0 si perde un passo per canale.
- Wipe: i pixel si copiano solo nell'ultimo tic di ogni chiamata di `Advance` (le colonne si muovono in tutti);
  `Advance(0)` dà `True`; una colonna che non è partita non si disegna.
- Scala dei muri: il confronto `den > FixedInt(num)` mette a confronto un numero 16.16 con un intero; `D_PI`
  vale `3.141592657` (non è il pi esatto) e il seno di `FromGlobalAngleDouble` usa quel valore.
- Un flat con lunghezza minore di 4096 dà solo righe intere da 64 pixel (la coda di meno di 64 byte si perde).

## 7. Fase 2 (issue #135): i chiamanti usano la libreria senza facciate

- `Base\r_grow.pas` è cancellata: `R_GrowSpan` sta in `r_cache_flats.pas` (l'unico chiamante), che riceve
  `IImagingSpanGrower` da `ComposeImaging` con `R_ConfigureFlatCache` (solo software).
- `R_ShrinkFlatTo64x64` e `R_ConfigureFlatShrink` di `r_flatinfo.pas` sono `V_ShrinkFlatTo64x64` e
  `V_ConfigureFlatShrink` di `v_video.pas` (l'unico chiamante, `V_TileScreen8`). `r_flatinfo.pas` tiene solo
  i tipi delle misure dei flat (`dsscale_t`, `FS*`, `dsscalesize`, `ds_scale`) usati da 14 unit del renderer;
  FLATINFO lo legge `R_InitFlats` di `r_data.pas` (`R_ConfigureFlatInfo`, con `Libs\TextureDefs`).
- La miniatura dei salvataggi: `TImagingSaveThumbnail` (`DelphiDoom.Imaging.Types`, 4014 byte, `SizeOf`
  coperto da test) e `TImagingSaveThumbnailFormat` (`DelphiDoom.Imaging.SaveThumbnail`: `IsValid`, `Fill`)
  sostituiscono `MN_ValidScreenShot` e la scrittura del marcatore `MENUSCREENSHOT`; la fa `R_MakeMenuThumbnail`
  di `r_main.pas` (`R_ConfigureMenuThumbnail`). `mn_screenshot.pas` tiene solo il record e l'ultima miniatura.
- **Restano** `r_patch.pas` (è la cache `fixedcolumns[]` del motore, PU_LEVEL: chiama già la libreria per
  `Repeat128`/`FromPosts`) e la parte di `r_cache_flats` che legge i pixel.
- Verifica (harness temporaneo nello stesso eseguibile, poi tolto): miniatura dallo schermo vero (4014 byte),
  120 ingrandimenti di flat casuali, 3676 riduzioni (tutti i flat di Freedoom 2 e 10 misure sintetiche) e
  FLATINFO di un PWAD di prova identici al vecchio codice.
