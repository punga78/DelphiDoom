# Libs\Radix - i dati di Radix in un WAD (issue #169, fetta F2 di Rad-X)

> Note per Claude e dettagli: [CLAUDE.md](CLAUDE.md).

Rad-X (`Reference\Rad-X`, fork di DelphiDoom 2.06) fa girare **Radix - beyond the void** (Epic MegaGames, 1995, sparatutto spaziale) sul motore di Doom.
Il gioco parte da `RADIX.DAT` e genera in memoria un WAD in formato Doom (`Radix\radix_xlat_wad.pas` e le unit `radix_*` che usa, circa 9000 righe
con i dati dei font). Questa libreria porta a classi **una parte del traduttore**; il resto e' elencato in "Cosa resta".

## Il formato di `RADIX.DAT`

* Intestazione di 25 byte (`TRadixHeaderRecord`): firma `NSRes:Radix`, 6 byte sconosciuti, numero di lump, posizione della directory.
* Directory: 46 byte per lump (`TRadixLumpRecord`: nome di 32 caratteri terminato da zero, posizione, lunghezza, due campi sconosciuti). Vince il primo lump
  con un nome. I nomi sono quelli del gioco (`Palette[1]`, `WorldData[1][2]`, `MainTitle`, `SmallFont`...).
* `WallBitmaps`: una parola con il numero di bitmap, la posizione della tabella (intero), poi un record di 40 byte per bitmap (`TRadixBitmapRecord`:
  nome, posizione dei pixel, **altezza, poi larghezza**). I pixel dei muri sono **per colonne** (`x * altezza + y`).
* Le immagini senza palette (`OrderInfo`, `CrossHair`...): larghezza e altezza (parole), poi i pixel per righe. Quelle con palette (`MainTitle`, `MainMenu`...): due
  byte, larghezza a 2, altezza a 4, la palette VGA (6 bit) a 32, i pixel (indici) a 800.
* Il cielo (`MainEpisodeImage[i]`, `FillEpisodeImage[i]`): altezza, larghezza, i pixel per colonne.

## Che cosa c'e'

| Unit | Ruolo |
|---|---|
| `DelphiDoom.Radix.Types` | record `packed` del formato (un byte per carattere di un nome: il fork li aveva a 2 byte), costanti, `ERadixException` |
| `DelphiDoom.Radix.Intf` | `IRadixContainer`, `IRadixPaletteBuilder`, `IRadixTranslator` |
| `DelphiDoom.Radix.Container` | `TRadixContainer`: directory, lettura per nome o per posizione |
| `DelphiDoom.Radix.PaletteBuilder` | `TRadixPaletteBuilder`: PLAYPAL (22 palette), COLORMAP (34 tabelle), tabelle di traduzione (`radix_palette.pas`) |
| `DelphiDoom.Radix.Context` | `TRadixTranslationContext` (lo stato che i campi di `TRadixToWADConverter` tenevano tra i passi) e `IRadixPart` (un passo) |
| `DelphiDoom.Radix.BitmapTable` | la tabella di `WallBitmaps` (letta allo stesso modo da texture e flat) |
| `PalettePart`, `TexturePart`, `FlatPart`, `GraphicsPart`, `SmallFontPart`, `LumpGroupPart` | i passi: palette e traduzioni; texture dei muri, cieli, PNAMES e TEXTURE0; flat; schermate e immagini dei menu (`HELPnn`, `TITLEPIC`, `RADIXnnn`, `OBJnnPRI`); font piccolo; musica, testi e briefing copiati cosi' come sono |
| `DelphiDoom.Radix.Translator` | `TRadixTranslator`: esegue i passi nell'ordine del vecchio codice e scrive `RADIXINF` (le righe `RDXW0001=nome`) |
| `DelphiDoom.Radix.Factory` | `TRadixFactory`: l'unico punto che conosce le classi |

Il costruttore di patch e il WAD in memoria sono quelli di `Libs\GameData` (`TGamePatchOptions.Radix`: buco 254, palette 0..255).

## Cosa e' fatto e cosa resta

Il traduttore e' **parziale**: 814 lump su 2534 (Radix 2.0 shareware) e 737 su 2456 (1.0 shareware) sono identici a quelli del vecchio, byte per byte (`RADIXINF` e' in piu',
con un sottoinsieme delle righe del vecchio).
Fatti: palette e SHADES, TRN_*, texture dei muri + cieli + TEXTURE0/PNAMES0, flat, HELPnn, TITLEPIC, M_RADIX, M_BRIEF, RADIXnnn, OBJnnPRI/SEC, SMALLFNT e FNTAnnn,
musica (`D_INTRO`, `D_EiMj`), testi delle missioni (`MNTEXTij`), briefing (`BRIEF_ij`), fine degli episodi (`CiTEXT`).

Non fatti (restano in `Radix\radix_xlat_wad.pas` del fork, `Reference\Rad-X`):

| Parte | Lump | Dove nel vecchio codice |
|---|---|---|
| Livelli | 9 x 17 lump (`E1M1`, `THINGS`, `LINEDEFS`..., `RMAP`, `RTHINGS`, `RGRID`, `RACTION`...) | `GenerateLevels`, `radix_level.pas` (2380 righe: costruisce la mappa Doom e i nodi) |
| Font grandi | `BIGFA/B/C`, 96 lump ciascuno | `GenerateBigFonts` (rumore di Perlin, tre colori) |
| Font del terminale | `DOSFA/B`, `DOSSA/B` | `GenerateDosFonts`, `radix_font.pas` (7600 righe, quasi tutte tabelle) |
| Traduzione dei menu | `TRN_MENU` | `GenerateMenuTranslation` |
| Sprite | `S_START`.. `XRnnA/B/C`... | `GenerateSprites` (900 righe), `radix_extra_sprites.pas` |
| Cabina | `COCKPIT` | `GenerateCockpitOverlay` (`TRadixBitmap`) |
| Suoni | `DS_nnnnn`, `SNDINFO` | `GenerateSounds`, `radix_sounds.pas` (tabella dei nomi) |
| CSV e modalita' editor | | `GenerateCSVs`, `Convert_Edit`, `Convert` con i flag `R2W_*` |

`RADIXINF` della libreria contiene gli alias dei passi fatti (un sottoinsieme, nello stesso ordine, di quello del vecchio).

## Differenze dal vecchio

* Il vecchio `GenerateOpaqueGraphicWithPalette` leggeva il lump in un blocco di `malloc(size)` con `size` **non inizializzato** (riga 1100): sovrascriveva lo heap
  (indagine in `Reference\_analisi\radx_crash.md`). Qui i buffer sono `TBytes`.
* I campi `array of char` dei record (2 byte in Delphi 11) sono `AnsiChar` (la traduzione dei nomi e' per byte).
* Un contenitore che non e' di Radix, una directory fuori dal file, un lump fuori dal file, una palette corta o un'immagine piu' corta del dichiarato danno
  `ERadixException`/`EGameDataException` (il vecchio ignorava il risultato di `ReadHeader` e leggeva fuori dai buffer).
* Nella tabella delle texture il vecchio `ExtraSkyPatch` aveva `stepdir` e `colormap` non inizializzati (variabile locale): qui sono 0; sui dati veri `TEXTURE0` e'
  identico al vecchio, quindi il valore che il vecchio scriveva era 0.
* `PAK_AddEntry` e' un dato restituito (`IRadixTranslator.PakEntries`), non una chiamata al file system PAK. Nota: la `PAK_AddEntry` del vecchio, prima che il file
  system sia pronto, scriveva `position := aSize` (difetto del fork, in `w_pak.pas`): qui la posizione e' quella vera.
* L'arrotondamento del grigio di COLORMAP e' quello del vecchio compilato in Win32 (`Extended` nelle espressioni intermedie): su Win64 puo' differire di un'unita' al
  limite di un `Trunc`; non provato.

## Verifica

`Tests\Data\Radix\translation.v20.golden.txt` e `translation.v10.golden.txt` (numero, nome, dimensione e FNV-1a di ogni lump) e `radixinf.*.golden.txt` (testo di `RADIXINF`)
sono l'uscita del **vecchio** `Radix2WAD_Game` (`Tools\Verifica\169`, compilato da una copia di `Reference\Rad-X` con le correzioni di `radx_crash.md`) su `RADIX.DAT` 2.0 e 1.0
shareware (`Reference\_dati\radix`). Il test confronta ogni lump della libreria con il lump con lo stesso nome piu' avanti nel WAD vecchio (stesso ordine, stessa dimensione,
stesso FNV-1a). Test in `Tests\DelphiDoom.Tests.Radix` (69; i due di parita' si saltano se `RADIX.DAT` manca).
