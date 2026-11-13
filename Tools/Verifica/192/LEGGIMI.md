# Verifica #192: parita' della parte grafica di Libs\War con il C del remake

`war1` (acoto87/war1, zlib) e' in `Reference\war1` (sola lettura). I decodificatori ORIGINALI di `war_resources.c` si compilano e si
eseguono con gcc di `Reference\_dati\_strumenti\w64devkit` (non c'e' un compilatore C nel PATH) sul `DATA.WAR` vero.

```
powershell -NoProfile -File Compila-GfxRef.ps1 -Out <cartella nuova fuori dal repository>
war_gfx_ref.exe <DATA.WAR> gfx          > Tests\Data\War\graphics.golden.txt   (una riga per record grafico, ordine di assets[])
war_gfx_ref.exe -         fonts         > Tests\Data\War\fonts.golden.txt      (la tabella fontsData[] dei due font)
war_gfx_ref.exe <DATA.WAR> dump N file  (i byte RGBA dell'immagine, cursore o tileset N)
powershell -NoProfile -File Make-WarFonts.ps1 -Fonts Tests\Data\War\fonts.golden.txt -Out Libs\War\DelphiDoom.War.Font.Data.pas
```

`Compila-GfxRef.ps1` **non modifica** il remake: legge `war_file.c` (come #191), `war_resources.h` (le struct), `war_enums.h`,
`war_database.h` (`assets[]`), `war_sprites.h` (`WarSpriteFrame`), `war.h` (le costanti), `war_font.c` (`fontsData[]`) e di
`war_resources.c` `wres_getPalette`, `wres_loadPaletteResource`, `wres_loadImageResource`, `wres_loadSpriteResource`, `wres_loadTileset`,
`wres_loadTiles`, `wres_loadCursor` (+ `buildRgbaLut`); li scrive alla lettera in `-Out` (cercando le righe per testo) e li compila con
`war_gfx_ref.c`, che ha soltanto gli stub di SDL, Tracy, `wm_alloc` (-> `calloc`: la zone del remake e' azzerata) e del log e la
struct `WarContext`. Il programma carica **tutte** le voci di `assets[]` nell'ordine della tabella (come `wg_loadDataFile`) e poi stampa:

```
P indice crc32(768 byte)                              palette (x4 e correzioni di 255 e 217)
I indice larghezza altezza crc32(RGBA)                immagine
S indice fotogrammi largh. alt. crc32(testate) crc32(pixel di tutti i fotogrammi)
C indice hotx hoty larghezza altezza crc32(RGBA)      cursore
T indice palette1 palette2 lunghezza crc32(byte)      tiles
X indice tegole crc32(immagine 512 x 256 RGBA)        tileset
```

Risultato (2026-11-13, `DATA.WAR` DOS 12852768 byte): 184 righe (14 palette, 57 immagini, 91 sprite, 16 cursori, 3 tiles, 3 tileset), nessuna
riga `E`; `Tests\DelphiDoom.Tests.War` da' le stesse 184 righe. Nessuna palette cerca una palette che viene dopo nella tabella
(verificato sulla tabella): per questo `TWarGraphics` puo' decodificare ogni record a richiesta, in qualunque ordine.

PNG per l'ispezione visiva (fuori dal repository): con `DELPHIDOOM_WAR_PNG_OUT=<cartella>` il test
`DovrebbeScrivereAlcuniPNGPerLIspezioneVisiva` scrive `image.png`, `sprite_frame0.png`, `cursor.png`, `tileset.png` (senza la variabile e' ignorato).
Per compilare i test in un worktree serve `DCC_UnitSearchPath` con la cartella `DUnitX\Source` (vedi `Libs\War\CLAUDE.md`).
