# Libs\Palette - come collegarla al motore (issue #74, parte della #45)

La libreria costruisce palette, colormap e tabelle di traduzione dei colori **come classi pure**: ingresso = byte
di lump o parametri, uscita = `TBytes` / `TArray<Cardinal>` / `TArray<Integer>`. Non conosce `curpal`, `colormaps`,
`screens[]`, la zone memory né nessun globale del renderer. Dipende solo da `System.*` e da `Libs\Video`
(`IPaletteConverter`, riusato da `TPaletteUnpacker`: non si duplica il convertitore a `$00RRGGBB`). Il collegamento
non è stato fatto (non era compito di questo lavoro): qui sotto c'è cosa serve. Nessun file esistente è stato modificato.

## 1. Unit da aggiungere ai `.dpr`

Servono in tutti i progetti che oggi compilano `v_palettes`, `r_palette`, `r_colormaps`, `r_translations`, `r_precalc`
(`Doom32`, `GLDoom32`, `Heretic32`, `GLHeretic32`, `Hexen32`, `GLHexen32`, `Strife32`, `GLStrife32`; `ddc_*` solo se
usano `V_*`). `DelphiDoom.Video.*` ci sono già. Righe:

```
  DelphiDoom.Palette.Types in 'Libs\Palette\DelphiDoom.Palette.Types.pas',
  DelphiDoom.Palette.Intf in 'Libs\Palette\DelphiDoom.Palette.Intf.pas',
  DelphiDoom.Palette.GammaData in 'Libs\Palette\DelphiDoom.Palette.GammaData.pas',
  DelphiDoom.Palette.Profiles in 'Libs\Palette\DelphiDoom.Palette.Profiles.pas',
  DelphiDoom.Palette.ColorMatcher in 'Libs\Palette\DelphiDoom.Palette.ColorMatcher.pas',
  DelphiDoom.Palette.Builder in 'Libs\Palette\DelphiDoom.Palette.Builder.pas',
  DelphiDoom.Palette.TranslationBuilder in 'Libs\Palette\DelphiDoom.Palette.TranslationBuilder.pas',
  DelphiDoom.Palette.PlayerTranslations.Doom in 'Libs\Palette\DelphiDoom.Palette.PlayerTranslations.Doom.pas',
  DelphiDoom.Palette.PlayerTranslations.Heretic in 'Libs\Palette\DelphiDoom.Palette.PlayerTranslations.Heretic.pas',
  DelphiDoom.Palette.PlayerTranslations.Strife in 'Libs\Palette\DelphiDoom.Palette.PlayerTranslations.Strife.pas',
  DelphiDoom.Palette.GammaTables in 'Libs\Palette\DelphiDoom.Palette.GammaTables.pas',
  DelphiDoom.Palette.ColormapPreparer in 'Libs\Palette\DelphiDoom.Palette.ColormapPreparer.pas',
  DelphiDoom.Palette.LightTables in 'Libs\Palette\DelphiDoom.Palette.LightTables.pas',
  DelphiDoom.Palette.TranslationNames in 'Libs\Palette\DelphiDoom.Palette.TranslationNames.pas',
  DelphiDoom.Palette.PrecalcTables in 'Libs\Palette\DelphiDoom.Palette.PrecalcTables.pas',
  DelphiDoom.Palette.BufferFixer in 'Libs\Palette\DelphiDoom.Palette.BufferFixer.pas',
  DelphiDoom.Palette.Unpacker in 'Libs\Palette\DelphiDoom.Palette.Unpacker.pas',
  DelphiDoom.Palette.Factory in 'Libs\Palette\DelphiDoom.Palette.Factory.pas',
```

(`PlayerTranslations.Heretic`/`Strife` si possono compilare ovunque: non hanno `{$IFDEF}`; il composition root sceglie.)

Riga da aggiungere in `build.bat`, alla fine della lista `TESTS`: ` Tests\DelphiDoom.Tests.Palette`.
Il progetto di test (`Tests\DelphiDoom.Tests.Palette.dpr/.dproj`) cerca `..\Libs\Palette;..\Libs\Video`.

## 2. Cosa sostituisce cosa

| Funzione storica | Sostituita da |
|---|---|
| `V_BestColor` (`v_palettes.pas`) | `IColorMatcher.BestColor(r, g, b, palette, low, high)` |
| `V_FindAproxColorIndex` (`v_video.pas`) | `IColorMatcher.FindApproximateIndex(colori, colore, da, a)` |
| `V_CreateDoomPalette`, `V_ColorShiftPalette`, `V_CopyPalette` | `IPaletteBuilder.Build(palette, conColormap, conFogmap): TPaletteSet` (`Playpal`, `Colormap`, `Fogmap`, `BasePalette`), profilo `TPaletteProfiles.Doom` (Doom, Heretic, Strife) o `.Hexen` |
| `V_CreateTranslation` | `ITranslationBuilder.Build(da, a)` (e `Identity` per le `colorregions` senza lump) |
| `V_FixBufferPalette` | `IPaletteBufferFixer.Fix` (su un `TBytes`; il motore ha un `PByteArray`: o si copia o resta la funzione storica, è chiamata solo dal codice di disegno) |
| `V_AutoGeneratePalettes` | resta nel motore: legge il lump, chiama `Build`, scrive il WAD con `TWadWriter`, `W_RuntimeLoad` |
| `R_DefaultPalette` e il ciclo identico di `R_InitCustomColormaps` e `R_InitData` | `IPaletteUnpacker.Unpack(768 byte): TArray<Cardinal>`; `r_palette.pas` tiene `dpal` e il flag e copia il risultato in `dpal` |
| `aprox_black := V_FindAproxColorIndex(@cpal, 0, 1, 255)` (`R_InitData`) | `FindApproximateIndex(colori, 0, 1, 255)` |
| zeri → `aprox_black` in `def_colormaps`/`colormaps`/`fog_colormaps`, `inversecolormap32` (Doom) | `IColormapPreparer.ReplaceZeros`, `RowColors(colormap, 32, colori)`, `PrepareFog(fog, colormap, nero, colori)` (dà `Indexes` e `Colors`, cioè `fog_colormaps` e `fog_colormaps32`) |
| `R_InitCustomColormaps` (parte dei byte) | `ReplaceZeros`, `ExpandRows(colormap, NUMCOLORMAPS, nummaps)`, `RowColors(colormap, 0, colori)` (= `basepal`) |
| `R_InitLightTables` (`r_main.pas`), `R_RecalcColormaps` (`r_colormaps.pas`), il ciclo di `scalelight` di `R_ExecuteSetViewSize` | `ILightTableCalculator.ZLight`, `.ScaleLight(config, viewwidth, SCREENWIDTH)`, `.HiResZLight` |
| `R_InitPrecalc`, `R_GetPrecalc32Tables` (indice) | `IPrecalcTables` (`Multiply`, `Fog`, `ByteToLong`, `ByteToWord`, `InverseColor`, `Average`, `AddClamp`, `LightIndex`) |
| `gammatable` (`v_video.pas`) | `IGammaTables.Table(livello)` (i dati sono `GAMMA_DATA`, copiati byte per byte) |
| `R_InitTranslationTables` | `IPlayerTranslations.Build` (Doom: 3 tabelle; Heretic: 3; Strife: 7) |
| nomi di `R_GetTranslationTable`, `R_GetBloodTranslationIdForName`, `R_GetBloodName`, `R_BloodTranslation` | `ITranslationNames` (`FindSlot`, `AddSlot`, `LumpCandidates`, `BloodIdForName`, `BloodName`, `BloodRegion`) |

## 3. Come il motore passa i parametri e riceve i buffer

La libreria **dà solo byte e indici**; chi possiede la memoria resta il motore (`Z_Malloc`, `PU_STATIC`).

* **PLAYPAL / COLORMAP / FOGMAP** (`V_AutoGeneratePalettes`): `Build(TBytes(lump PLAYPAL), True, <gioco ha fogmap>)`.
  Il numero di byte copiato dal lump è 768; il vecchio codice scriveva la palette a 8 bit sul lump stesso (palette a
  6 bit moltiplicata per 4): ora c'è `BasePalette`, e chi voleva quell'effetto collaterale lo prende da lì. Hexen: `AWithFogmap = False`
  (la FOGMAP vera sta nel suo WAD). `TPaletteSet.Playpal` ha 14 (28 Hexen) palette di 768 byte.
* **Colormap di gioco** (`R_InitData`): il motore legge il lump con `W_ReadLump` in un `TBytes`, chiama
  `ReplaceZeros(bytes, aprox_black)` e ricopia in `colormaps`/`def_colormaps` (`Move`); `colormaps32` e `fog_colormaps32` si riempiono dal
  `Colors` di `PrepareFog` e da `RowColors`. `aprox_black`/`aprox_red` vengono dal `FindApproximateIndex` sui colori di `Unpack`.
* **Colormap personalizzate** (`R_InitCustomColormaps`): per ogni lump `ReplaceZeros` → `ExpandRows(.., NUMCOLORMAPS, n)` → `RowColors(.., 0, colori)`
  per `basepal`; il motore poi fa `R_CreateDiherTable` / `R_GetColormapFogColors` (non portati, vedi sotto).
* **Tabelle di luce**: `TLightTableConfig.Default` ha le costanti di `r_main.pas`; se il motore le cambia (non le cambia, sono `const`) le
  si passano nel record. `ZLight` e `ScaleLight` danno l'**indice** di riga della colormap: il motore fa
  `zlight[i][j] := @colormaps[indice * 256]` (cicli `i`, `j` come adesso, array piatto `[i * MAXLIGHTZ + j]`). `ScaleLight` va rifatto a ogni cambio di
  `viewwidth`; `SCREENWIDTH` (variabile del renderer) si passa come parametro, il vecchio codice la leggeva. `viewwidth <= 0` dà `EPaletteException`.
* **Tabelle di traduzione**: `R_InitTranslations` mette in `TStringList` solo i nomi; con la libreria il motore tiene un `TList<Pointer>` di
  tabelle indicizzato dallo **slot** (gli slot 0..23 sono i `CR_*`, in ordine di `crange_idx_e`: `colorregions[slot]`). `R_GetTranslationTable`:
  `slot := names.FindSlot(nome, chiave)`; se `slot >= 0` ritorna la tabella dello slot; altrimenti per ogni `c` di `names.LumpCandidates(nome)`
  prova prima `_dotry_pk3(c)` poi `_dotry_wad(c)` (il motore carica con `TPakStream`/`W_CheckNumForName`, lunghezza 256) e, se una riesce,
  `slot := names.AddSlot(chiave)` e memorizza la tabella. Attenzione all'ordine del vecchio `_try_load`: per ogni candidato si prova **pk3 e poi wad**
  su tutta la lista pk3, e solo se nessuno riesce la lista wad (`if not _try_load(name, pk3) then _try_load(name, wad)`): non alternati.
  `R_BloodTranslation(bt)` = `colorregions[names.BloodRegion(bt)]` (nil se -1). `R_GetBloodTranslationIdForName`, `R_GetBloodName`: chiamate dirette.
* **Colori dei giocatori**: `ComposeEngine` sceglie `CreateDoomPlayerTranslations`, `CreateHereticPlayerTranslations` o
  `CreateStrifePlayerTranslations` (il gioco di `_GAME`) e `R_InitTranslationTables` copia `Build` in `translationtables` (allineato a 256, come ora).
  Hexen: **non portato** (legge le tabelle dai lump `TRANTBL0`..: sono dati del WAD, nessun algoritmo).
* **Composition root**: `TPaletteFactory.CreateColorMatcher` è condiviso:
  ```
  matcher := TPaletteFactory.CreateColorMatcher;
  builder := TPaletteFactory.CreatePaletteBuilder(matcher, TPaletteProfiles.<Doom|Hexen>);
  unpack  := TPaletteFactory.CreatePaletteUnpacker(TVideoFactory.CreatePaletteConverter);
  ```
  Come `TEngineWadServices`, conviene una `TEnginePaletteServices` (unit `Base\DelphiDoom.Engine.Palette.Services.pas`) in `ComposeEngine`, che le unit
  storiche (`v_palettes`, `r_translations`, `r_data`) ricevono con un `P_Configure...` (senza di essa `I_Error`, come le altre fette).

## 4. Differenze volute e difetti conservati

Vedi `Tests\Data\Palette\README.md`. In breve: nessun effetto collaterale sull'ingresso, errori al posto delle letture fuori dal buffer;
conservati il "Carmack's typo" (`/ 265`), la fogmap con grigio non invertito, le tabelle dei giocatori di Heretic che non cambiano nulla, il giro
del byte di Strife, le regole strane di `CR_`/`CR` nei nomi.

## 5. Parti non portate (e perché)

* **`R_CreateDiherTable`, `R_InitNonUniformDiherFactor`, `R_GetColormapFogColors`** (`r_diher.pas`, parte di `R_InitCustomColormaps`): dipendono dal
  renderer (`dihertable_t` 3D, `DIHERSHIFT`, variabili OpenGL del fog) e non sono tabelle di palette pure; restano nel motore.
* **`R_CustomColorMapForName`, `R_ShutDownCustomColormaps`, `customcolormap_t`, `R_RecalcColormaps` (parte dei puntatori)**: strutture e puntatori
  del renderer (`scalelight_t`, `zlight_t`, `colormap: PByteArray`); la libreria dà gli indici, il resto è collegamento.
* **`R_InitLightBoost` / `R_CmdLightBoostFactor`** (`r_lights.pas`): tabella legata a una variabile di console (`lightboost`) e a `malloc` del renderer.
* **`V_AutoGeneratePalettes`** (scrittura del WAD temporaneo), **`R_InitMobjTranslation`/`R_SetMobjBloodTranslation`** (scrivono in `mobj_t`),
  **caricamento dei lump `CR_START`** di `r_draw.pas` (`W_*`), **`TINTTAB`, `XLATAB`, `TRANTBL`**: sono accessi al WAD o al motore.
* **Tabelle di trasparenza e `r_trans8`**: fuori dal compito (`R_SetPalette64`, tabelle di blend sono routine di disegno).
* Win64: la libreria non usa `asm` né `.obj`; `FixedDivide` è Pascal puro (il `FixedDiv2` storico è `asm`) ed è provata contro quello.

## 6. Rischi

* `ITranslationNames` tiene lo stato degli slot: va creata una sola istanza (come la `TStringList` globale) e svuotata con `R_ShutDownTranslations` (si ricrea).
* Il test di parità vale per le palette sintetiche e per i quattro WAD commerciali del repository; un PLAYPAL molto diverso (mod) segue lo stesso codice ma non è provato.
* `IPaletteBufferFixer` lavora su `TBytes` (copia): se i chiamanti restano nei renderer, meglio lasciare la funzione storica e non pagare la copia.

## 7. Fase 2 (issue #135)

* `Base\v_palettes.pas` è cancellata: `V_CreateDoomPalette`, `V_CreateTranslation` e `V_FixBufferPalette` non avevano
  chiamanti; `V_AutoGeneratePalettes` è `TEnginePaletteGenerator.Generate` (`Base\DelphiDoom.Engine.Scanner.PaletteGenerator.pas`,
  la direttiva `#CREATEPALETTE`), che riceve `IPaletteBuilder` dal costruttore. Finché `sc_utils.pas` assembla da sé le
  direttive del preprocessore resta anche un costruttore senza argomenti che crea il costruttore del profilo del gioco.
  Verifica nello stesso eseguibile: PLAYPAL, COLORMAP e FOGMAP del WAD generato identici al vecchio codice negli otto giochi.
* `r_palette.pas` è cancellata (#145): la palette di base (letta una volta) è `TEngineDefaultPalette`
  (`Base\DelphiDoom.Engine.Palette.DefaultPalette.pas`, `IEngineDefaultPalette`, sopra `IPaletteUnpacker`), che `ComposePalette`
  dà a `R_ConfigureColormaps` (`r_data`), `R_ConfigureCustomColormaps` (`r_colormaps`) e `R_ConfigureVoxelPalette` (`r_voxels`).
* **Resta** `r_colormaps.pas` (le colormap personalizzate in zone memory, lette dal renderer e da
  `p_saveg`: sono dati del motore).
