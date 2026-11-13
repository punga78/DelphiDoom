# Libs\Texture - le texture esterne del motore (issue #45)

> Note per Claude e paragrafi di dettaglio (issue #178): [CLAUDE.md](CLAUDE.md).

Questa libreria sostituisce il codice di `TEXLIB\` che legge i file di immagine delle texture esterne (hi-res,
sprite, flat) e che tiene l'immagine in memoria: BMP, PCX, TGA, PNG, JPEG, `.PATCH`, `.FLAT`, `.MATERIAL`.
Non dipende dal motore: lavora su `TBytes` e su buffer di pixel. Dipende solo da `Libs\Logging` (`ILog`, per gli
avvisi) e da `Libs\Imaging` (`TImagingColorMath.Add`, la somma dei colori di `R_ColorAdd`).

## 1. Analisi (da dove si parte)

`TEXLIB\` aveva 13 unit, quasi 8000 righe. Chi le usa:

| Chi | Cosa chiama | Quando |
|---|---|---|
| `r_cache_walls.pas` (muri, software 32 bit) | `T_LoadHiResTexture`, `ScaleTo`, `Mirror`, `GetColumn32`, `GetPalettedColumn32` | la prima volta che una colonna di una texture ha bisogno del suo ingrandimento: a freddo, il risultato resta nella cache del renderer |
| `r_cache_flats.pas` (flat, software 32 bit) | `T_LoadHiResTexture`, `ScaleTo`, `SetPalColor`, `GetTransformedPalette`, `GetImage`, `ConvertTo32bit` | una volta per flat |
| `r_pk3textures.pas`, `w_sprite.pas` | `T_LoadHiResTexture`, `GetColumn32`, `GetRow32`, `SetRow32`, `SetColumn32`, `SetDefaultAlphaChannel`, `RemoveTransparency`, `ScaleTo`, `LoadFromStream` | all'avvio e al caricamento di un livello, per fare patch e flat dalle texture dei PK3 e degli sprite PNG |
| `Libs\OpenGl\Legacy\gl_tex.pas`, `gl_ambient.pas` | `ConvertTo32bit`, `SwapRGB`, `Set*AlphaChannel*`, `ScaleTo`, `GetImage`, `GetRow32` | al caricamento di una texture OpenGL: a freddo |
| `t_draw.pas` -> `TEngineDrawTextures` (`T_DrawFullScreenPatch`) | `GetRow32`, `GetPalettedRow32` | **per ogni fotogramma** in cui si vede una pagina a tutto schermo esterna: una chiamata per riga dello schermo |
| `w_pak.pas`, `v_video.pas` | `T_IsValidPatchImage`, `T_IsValidFlatImage`, `T_IsValidPCXHeader` | a freddo (riconoscere il tipo di una voce di un PAK) |
| `m_defs.pas` | `pngtransparentcolor`, `pngtransparentcolor2`, `assumecommontranspantcolors`, `preferetexturesnamesingamedirectory` | impostazioni del file `.ini` |
| `d_main.pas` dei 4 giochi | `T_Init`, `T_ShutDown` | avvio e chiusura |

**Percorso caldo del renderer**: nessuno. Le colonne e gli span che il renderer disegna a ogni fotogramma leggono
buffer del motore (`dc32cache`, `ds32cache`, `screen32`), non un `PTexture`. Il solo uso per fotogramma è
`T_DrawFullScreenPatch`, che chiama un metodo per riga (non per pixel): ha lo stesso costo di prima (un ciclo sulla
riga) e resta nel motore, perché legge `screen32`, `gammatable` e usa MMX.

## 2. Le fette

| Fetta | Dove | Perché |
|---|---|---|
| decodificatori di formato (BMP, TGA, PCX, PNG, JPEG, patch, flat, material) | **qui** (`Decoder.*`), uno per classe, dietro `ITextureDecoder` | sono a freddo, puri, e il vecchio codice mescolava lettura da `TDStream`, VCL (PCX) e stato globale |
| immagine in memoria e sue operazioni (`TTexture` di `t_main`: ridimensionamento, conversioni, colonne e righe a 32 bit, alfa) | **qui** (`Image`, `Alpha`, `Colors`) | pure su `TBytes`; il vecchio codice usava `asm` (`pixel15to24`, `SwapRGBData`, `EncodeColor*`) e puntatori a memoria da `malloc` |
| tabella dei decoder per estensione | **qui** (`Formats`, `Factory`) | sostituisce la lista concatenata di `GetImageFormat` |
| controlli di tipo (`T_IsValid*`) | **qui** (`PatchInspector`, `Decoder.Flat`, `Decoder.Pcx`) | puri; il motore li chiama direttamente (`TPakFileSystem` per `HI_START`/`TX_START`, `V_TileScreen8`): `t_detect.pas` non esiste piu (issue #146) |
| `T_LoadHiResTexture`, `PTexture`, ricerca nei PAK | **resta nel motore** come classi (`TEngineTextureFiles` dietro `IEngineTextureFiles`, `TTexture` di `DelphiDoom.Engine.Texture.Item`) | trova i file con il file system PAK (`IPakFileSystem`) ricevuto dal costruttore; `t_main.pas` non esiste piu (issue #146): i chiamanti ricevono `IEngineTextureFiles` dal composition root |
| `T_DrawFullScreenPatch`, cache `drawtextures[]` | **resta nel motore** (`TEngineDrawTextures`, ex `t_draw.pas`) | legato a `screen32`, ai gamma, a MMX e alla zone memory |
| `DelphiDoom.Texture.PngFileWriter`, `DelphiDoom.Texture.JpegBitmap` | **sono in questa cartella** (spostate da `TEXLIB`, issue #171) (già a classi, già testati nei progetti Png e Jpeg) | |

## 3. Struttura

```
Intf        ITextureDecoder, ITextureFormats, ITexturePaletteSource, ITextureResolver, ITexturePngReader,
            ITexturePngSettings, ITextureJpegConverter, TTexturePngData
Types       costanti, palette web safe, ETextureException
Colors      Pixel15To24, SwapRedBlue, Gray, PaletteEntry (le funzioni di colore che erano asm)
ByteReader  lettore sequenziale (zeri oltre la fine)
Image       TTextureImage (immagine a 1, 2 o 4 byte per pixel, palette, offset, colori trasparenti)
Alpha       TTextureAlpha (canale alfa e colori trasparenti)
Decoder.*   Bmp, Tga, Pcx (+ PcxLegacy), Flat, Patch, Material, Png (PngBase, PngTexture, PngSprite), Jpeg
PatchInspector, Formats, Factory
```

Nel motore (`Base\DelphiDoom.Engine.Texture.*`): `PaletteSource` (`default_palette`), `PngReader` (libreria PNG),
`PngSettings` (opzioni in `TEngineTextureSettings`, ex variabili di `t_png`), `JpegConverter` (libreria JPEG; un JPEG rotto ferma il gioco, come prima),
`Resolver` (le texture che un `.material` nomina; tiene un riferimento debole ai file, che a loro volta hanno i decoder),
`Item` (`PTexture`/`TTexture`, gli stessi metodi di prima sopra `TTextureImage`) e `Files` (`TEngineTextureFiles`:
`LoadImage`, `LoadTexture`, `Decode`, `IsTextureExtension`; il vecchio `T_LoadHiResImage`). `ComposeTexture` (in
`ComposeEngine`) crea i decoder con `TTextureFactory.CreateFormats`, poi `TEngineTextureFiles` con il file system PAK, e li
da a chi li usa: `V_ConfigureDrawTextures` (`v_video`), `W_ConfigureSpriteTextures` (`w_sprite`), `R_ConfigurePK3Textures`
(`r_pk3textures`), `R_ConfigureFlatTextures` e `R_ConfigureWallTextures` (software), `gld_ConfigureTextureFiles` (OpenGL).
`t_main.pas` e `t_detect.pas` sono stati cancellati (issue #146); `t_png.pas` teneva le impostazioni (ora `TEngineTextureSettings`) (anche
`preferetexturesnamesingamedirectory`) e `d_main` chiama `T_InitDrawTextures`/`T_ShutDownDrawTextures` al posto di `T_Init`/`T_ShutDown`.

## 4. Differenze volute dal vecchio codice

Difetti corretti (con test che li coprono):

- `pixel15to24` era assembler che azzerava il registro con il parametro (`xor eax, eax` prima di leggerlo) e
  dava sempre 0: le immagini a 16 bit (TGA a 16 bit) erano nere. Ora il colore è convertito; il bit 15 si ignora.
- La palette trasformata (`GetTransformedPalette`) non era riempita finché non si aggiungeva un colore diverso da 0
  (conteneva ciò che aveva l'heap) e la copia di ritorno si fermava alla voce 254. Ora parte come copia della palette e si rifà intera.
- BMP a 1 e 4 bit: andavano in access violation (non leggevano la palette). Ora si leggono. I pixel sono letti dall'offset che
  l'intestazione dà (prima da 54).
- PCX: niente più file temporaneo, `TBitmap` e `TGraphic` della VCL; i formati che nessuno dei due lettori prendeva
  (4 bit a un piano, file troncati) davano `true` con un'immagine vuota o fermavano il gioco con un errore, ora danno
  `false` con un avviso.
- TGA in scala di grigi, con mappa dei colori di dimensione non valida o con un tipo che non va con la profondità dei pixel: davano
  `true` con un'immagine vuota, ora `false`.
- `.MATERIAL` con una texture a palette: copiava 4 byte per pixel da un buffer di 1; ora converte a 32 bit.
- Patch, BMP RLE, PCX: i byte fuori dai limiti (colonne fuori dal lump, codici RLE che escono dall'immagine, righe che passano
  il buffer) non si leggono e non si scrivono più (prima memoria corrotta o garbage); i buffer nuovi sono a zero, non garbage.
- Un'immagine che non si legge parte sempre da un'immagine vuota per ogni estensione provata (prima `T_LoadHiResTexture`
  riusava l'oggetto, con dimensioni e formato del tentativo precedente).
- Il limite di un lato è `TEXTURE_MAX_DIMENSION` (16384): oltre, il file non si legge (prima si passava a una `Word`).

Difetti conservati, perché il comportamento visibile è quello di sempre:

- `GetImageFormat('.PNG')` dà il decoder di `.PNGSPRITE` (la lista ha lo sprite prima della texture e il confronto è "contiene il testo"):
  le texture PNG esterne si leggono con le regole degli sprite. `TTextureFormats.FindDecoder` fa lo stesso.
- `GetPalettedRow32` chiede il colore da sommare ma legge la palette senza (la colonna lo somma).
- La palette dei TGA a 15 e 16 bit ha sempre il blu a 0; il lettore PCX principale prende `$C0` per un pixel e tiene la riga lunga
  come la larghezza (un'immagine a 8 bit di larghezza dispari esce spostata); un TGA parte sempre dal basso senza guardare il bit
  di origine; la mappa dei colori parte dalla prima voce senza guardare `cmorg`.
- Il secondo lettore PCX arrotonda i colori a 6 bit (valore / 4 * 4 + 3: il nero è 3, 3, 3).

## 5. Collegamento e verifica

Collegato: i quattro giochi (software e OpenGL) e i `ddc_*`. Verifica:

- confronto con il vecchio codice nello stesso eseguibile (harness temporaneo in `Doom32`, poi tolto): 5294 controlli, uno per
  file o per caso (BMP, TGA, PCX, flat, patch, 150 file di dimensione casuale, PNG con una libreria PNG finta, 168 operazioni
  su immagini, palette, `PutPixels`, ricerca dell'estensione, riconoscimento di patch e PCX); le uscite del vecchio codice sono in
  `Tests\Data\Texture\*.golden.txt`. Le differenze elencate sopra sono nei golden come "KNOWN DIFFERENCE" e i test le controllano a mano.
- con un PK3 di prova in `bin\Doom\TEXTURES` (BMP, TGA RLE, PCX, PNG, JPEG, `.MATERIAL`) Doom 1 al livello E1M1 carica e disegna
  tutti i formati senza avvisi né `crash.txt`.
- `Tests\DelphiDoom.Tests.Texture` (186 test).

## 6. Cosa non c'è

- Non provati a runtime: `.PATCH` e `.FLAT` come texture esterne (cioè da un PK3 con voci senza estensione), la memoria del `.MATERIAL`
  con un'immagine a palette, OpenGL con texture esterne (si avvia e non va in crash, ma le texture non sono state guardate).
- I due `Decoder` PCX non fanno 16 e 32 bit né i file a 4 bit.
- `T_DrawFullScreenPatch` non è stato spostato (vedi sopra).

## DDS e TGA di id Tech 4 (issue #103)

- `Dds.Types`, `Dds.BlockDecoder`, `Dds.Reader`, `Dds.Writer`, `Decoder.Dds`, `Tga.IdReader`: lettura DDS (DXT1/3/5, non compresso, mipmap), decompressione dei blocchi, scrittura di un DDS BGRA e lettore TGA di Doom 3. Il DDS si legge dalla descrizione del formato (Doom 3 non lo legge), il resto viene da Doom 3. Dettagli, limiti e prove in [CLAUDE.md](CLAUDE.md). Non registrati in `TTextureFactory`, senza chiamanti nel motore.
- Test: `Tests\DelphiDoom.Tests.Texture` (250 test).