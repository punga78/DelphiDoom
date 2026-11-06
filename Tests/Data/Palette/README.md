# Tests\Data\Palette - golden della libreria Libs\Palette (issue #74)

I file `*.golden.txt` sono scritti dal **vecchio codice**, copiato tale e quale in un programma console
temporaneo (fuori dal repository, non committato), compilato con Delphi 11 Win32. Ogni riga e` `chiave=valore`:
il valore e` l'impronta FNV-1a a 64 bit seguita da `:` e dal numero di byte della tabella
(`TPaletteDigest` in `Tests\Source\DelphiDoom.Tests.Palette.Digest.pas`), oppure un testo breve o un numero.

| File | Compilato come | Contenuto |
|---|---|---|
| `palette.golden.txt` | senza `HEXEN` (Doom, Heretic, Strife) | `build.*` (PLAYPAL, COLORMAP, FOGMAP, palette di base), `translate.*`, `best.*`, `approx.*`, `unpack.*`, `fixbuf.*`, `colormap.*`, `fog.*`, `light.*`, `gamma.*`, `precalc.*`, `player.*`, `names.*` |
| `palette_hexen.golden.txt` | con `HEXEN` | solo `build.*` (28 palette, riga 255 della colormap, grigio non invertito) |
| `palette_real.golden.txt` | senza `HEXEN` | PLAYPAL e COLORMAP veri di `DOOM1.WAD`, `HERETIC1.WAD`, `STRIFE0.WAD` (`real.<gioco>.*`) |
| `palette_hexen_real.golden.txt` | con `HEXEN` | PLAYPAL, COLORMAP e FOGMAP veri di `HEXEN.WAD` |

I test `*_real` leggono `bin\<Gioco>\*.WAD` e si **saltano** se il WAD manca; gli altri usano dati sintetici
fissi, generati da `TPaletteFixtures` (un congruenziale lineare: palette di 8 bit, di 6 bit, con rampa di grigi
e colormap con degli zeri). Lo stesso `Fixtures.pas` e lo stesso `Digest.pas` sono usati dal programma temporaneo e
dai test, quindi gli ingressi e le impronte sono identici.

## Cosa e` stato copiato dal vecchio codice

`V_ColorShiftPalette`, `V_CopyPalette`, `V_BestColor`, `V_CreateDoomPalette`, `V_CreateTranslation`,
`V_FixBufferPalette` (`Base\v_palettes.pas`); `V_FindAproxColorIndex` e `gammatable` (`Base\v_video.pas`);
`R_InitLightTables` e il calcolo di `scalelight` (`Base\r_main.pas`, con `FixedDiv` e gli `_SHL/_SHR` in `asm`
originali); il codice di `R_InitCustomColormaps` e di `R_InitData` su colormap e fogmap (`Base\r_colormaps.pas`,
`Base\r_data.pas`); `R_InitPrecalc` (`Base\r_precalc.pas`); `R_InitTranslationTables` nei tre rami Doom, Heretic e
Strife (`Base\r_draw.pas`); la ricerca per nome, `_try_load` e le funzioni del sangue (`Base\r_translations.pas`).
Dove il vecchio codice scriveva puntatori nella zone memory, il programma scrive l'indice della riga di colormap.

## Per rigenerare

Servono i sorgenti storici dei file qui sopra: il programma temporaneo li incorpora, quindi basta rifarlo
(due compilazioni, con e senza `-DHEXEN`, con `bin\<Gioco>\*.WAD` a disposizione per i file `*_real`) e
confrontare. Una impronta che cambia senza che sia cambiato un algoritmo e` un difetto della libreria, non del golden.

## Differenze volute dal vecchio codice

- `V_CreateDoomPalette` scriveva sul **proprio ingresso** (palette di 6 bit moltiplicata per 4, sul buffer del
  lump). `IPaletteBuilder.Build` non lo tocca: la palette usata sta in `TPaletteSet.BasePalette`.
- Gli argomenti fuori limite (palette corta, intervallo di colori fuori dalla palette, riga di colormap che non
  esiste, `viewwidth` a zero, colormap senza nemmeno una riga) danno `EPaletteException`; il vecchio codice leggeva
  fuori dal buffer o andava in `EDivByZero`.
- `ExpandRows` su un lump di meno di 256 byte dava un indice negativo (`nummaps - 1 = -1`): ora e` un errore.

## Difetti del vecchio codice conservati (le impronte li contengono)

- Il grigio di COLORMAP/FOGMAP usa `green * 0.587 / 265` invece di `/ 256` (il "Carmack's typo"): conservato.
- La fogmap ha la riga grigia **non invertita** in tutti i giochi; la colormap la inverte tranne in Hexen.
- Il verde della tuta antiradiazione e` `(0, 256, 0)`: il 256 sfora il byte, ma il risultato resta entro 255.
- Heretic: `R_InitTranslationTables` testa `(i >= 255) and (i <= 240)`, mai vero: le tre tabelle dei giocatori
  sono l'identita` (la rampa 114/145/190 voluta non viene applicata).
- Strife: i valori sotto zero (`(i and $0f) - 80`) fanno il giro del byte, come l'assegnazione originale.
- `FindSlot`: dopo lo scarto di `CR_` si prova anche `CR` sul nome gia` accorciato (`CR_CRX` diventa `X`);
  `LumpCandidates` per un nome `CRxxx` inserisce `_` dopo `CR` (`CRAB` diventa `CR_AB`) e per `CR_xxx` toglie il
  `_` e basta (non prova altro).
- `R_GetBloodTranslationIdForName` di un numero fuori da 0..8 (o troppo grande per un intero) da` 0.
- `V_FindAproxColorIndex` legge il byte basso come "rosso" sia nel colore cercato sia nella palette: la distanza
  non cambia, ma il nome e` fuorviante; `aprox_red` cerca il rosso nel senso $00RRGGBB.
