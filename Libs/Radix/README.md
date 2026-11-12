# Libs\Radix - i dati di Radix in un WAD (issue #169, fetta F2 di Rad-X)

> Note per Claude e dettagli: [CLAUDE.md](CLAUDE.md).

Rad-X (`Reference\Rad-X`, fork di DelphiDoom 2.06) fa girare **Radix - beyond the void** (Epic MegaGames, 1995, sparatutto spaziale) sul motore di Doom.
Il gioco parte da `RADIX.DAT` e genera in memoria un WAD in formato Doom (`Radix\radix_xlat_wad.pas` e le unit `radix_*` che usa, circa 9000 righe
con i dati dei font). Questa libreria porta a classi il traduttore (completo, vedi "Cosa e' fatto").

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
| `DelphiDoom.Radix.Editions` | `TRadixEditions`: quale RADIX.DAT e' (1.0, 1.1, 2.0; shareware o registered) dal CRC-32 dell'intero file (`radix_version.pas`) |
| `DelphiDoom.Radix.LumpAliases` | `TRadixLumpAliases` (`IRadixLumpAliases`): le righe `LUMP=nome` di `RADIXINF`; il gioco chiede un'immagine con il nome che ha in RADIX.DAT (`MainMenuButton1`) e ottiene il lump (`radix_alias.pas`) |
| `DelphiDoom.Radix.MapInfo.Types`, `MapInfo.Reader` | `TRadixMapInfoReader` (`IRadixMapInfoReader`): il testo del lump `RMAP` di un livello (posizione, pendenze, angoli dei flat e flag dei settori; flag, punti ferita e trigger dei muri), cioe' il parser di `RX_LoadRadixMapInfo` |
| `DelphiDoom.Radix.SlopePlanes` | `TRadixSlopePlanes`: il piano di un pavimento o soffitto inclinato dai tre punti del settore (`calc_radix_plane`, `RX_CalcFloorSlope`, `RX_CalcCeilingSlope`) e l'angolo di un flat nell'unita' del motore |

Il costruttore di patch e il WAD in memoria sono quelli di `Libs\GameData` (`TGamePatchOptions.Radix`: buco 254, palette 0..255).

## Cosa e' fatto

Il traduttore e' **completo**: 2534 lump su 2534 (Radix 2.0 shareware) e 2456 su 2456 (1.0 shareware) sono identici a quelli del vecchio `Radix2WAD_Game`, byte per byte e
nello stesso ordine, `RADIXINF` compreso (`Tools\Verifica\169\RadixDiff.exe`, e il test di parita' controlla anche il numero dei lump).

| Passo (unit) | Lump |
|---|---|
| `PalettePart` | `PALETTE`, `SHADES`, `TRN_RED`, `TRN_GREE`, `TRN_YELL` (i nomi si cambiano con `TRadixLumpNames`) |
| `TexturePart` | `P_START`..`P_END`, `RDXWnnnn`, cieli, `PNAMES0`, `TEXTURE0` |
| `LevelPart` (e `DelphiDoom.Radix.Level.*`) | 9 x 17 lump per livello: `E1M1`, `THINGS`, `LINEDEFS`, `SIDEDEFS`, `VERTEXES`, `SECTORS` e i lump di Radix (`RMAP`, `RTHINGS`, `RGRID`, `RACTION`, `RMAPGRID`, `RTRIGGER`); `SEGS`, `SSECTORS`, `NODES`, `REJECT` e `BLOCKMAP` sono vuoti (il vecchio non costruiva nodi: li fa il motore) |
| `FlatPart` | `F_START`..`F_END`, `RDXFnnnn`, `F_SKY1` |
| `GraphicsPart` | schermate e immagini dei menu (`HELPnn`, `TITLEPIC`, `RADIXnnn`, `OBJnnPRI`...) |
| `SmallFontPart`, `BigFontPart`, `DosFontPart` | `SMALLFNT`, `FNTAnnn`, `BIGFA/B/C` (rumore di Perlin), `DOSFA/B`, `DOSSA/B` (i dati dei font in `FontData`) |
| `MenuTranslationPart` | `TRN_MENU` |
| `SpritePart` (con `SpriteCatalog`, `SpriteList`, `SpriteData`, `Things`) | `S_START`..`S_END`, `XRnn..`, `Xnnn..`, `PLAY..`, `EXPB..`, `TNT1A0`, `GEAR1A0` |
| `LumpGroupPart` | `D_INTRO`, `D_EiMj`, `MNTEXTij`, `BRIEF_ij`, `CiTEXT` |
| `CockpitPart`, `SoundPart` | `COCKPIT`, `DS_nnnnn` e `SNDINFO` |

**Non portati, di proposito** (non sono parte della conversione di gioco `Convert_Game`, e il golden non li ha): `GenerateExtraSprites` (mai chiamata dal vecchio:
`IFOG*`, `TFOG*`, chiavi e teschi di `radix_extra_sprites.pas`), `GenerateCSVs` e la modalita' editor (`Convert_Edit`, flag `R2W_*`, strumento VCL `rad2wad`).

`TRadixLumpNames` (`Original`: `PNAMES0`, `TEXTURE0`, `PALETTE`, `SHADES`; `Doom`: `PNAMES`, `TEXTURE1`, `PLAYPAL`, `COLORMAP`) e `TRadixFactory.CreateTranslator(nomi)` danno al
motore di Doom (che non e' quello del fork) i nomi che legge; l'uscita con i nomi `Original` e' quella del golden.
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
stesso FNV-1a). Test in `Tests\DelphiDoom.Tests.Radix` (255; quelli sui dati veri si saltano o si ignorano con il motivo se `RADIX.DAT` manca).

Le classi del gioco (edizioni, alias, `RMAP`, piani delle pendenze) non hanno un'uscita del vecchio codice con cui confrontarsi (il vecchio eseguibile non arriva a
caricare un livello): sono provate su casi sintetici e sui dati veri (il CRC del file 2.0 shareware, la tabella `RADIXINF` del golden, i nove `RMAP` del primo episodio:
ogni settore e' nominato e ogni piano passa per i tre punti del suo settore entro mezza unita').
