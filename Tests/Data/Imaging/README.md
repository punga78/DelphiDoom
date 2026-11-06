# Tests\Data\Imaging

I file `*.golden.txt` hanno una riga `nome=valore` per ogni caso. Li ha scritti un harness **temporaneo, fuori dal
repository**, che compila il vecchio codice del motore (le routine di `r_hires`, `r_grow`, `r_scale`, `r_data`,
`r_patch`, `r_cache_flats`, `r_flatinfo` e `f_wipe`, copiate come sono con i globali trasformati in variabili; per
`FixedMul`, `FixedDiv` e `fixedsine` usa le unit vere `m_fixed` e `tables`) sugli stessi ingressi sintetici che
`Tests\Source\DelphiDoom.Tests.Imaging.Samples.pas` dà ai test. Non c'è nessun WAD commerciale: patch, flat,
colonne, palette e schermate sono costruiti da un generatore congruenziale deterministico.

Il valore è un'impronta FNV-1a a 64 bit (in esadecimale) dei byte o dei pixel, tranne dove è scritto per
esteso (le liste di post del ricostruttore, `topdelta:lunghezza:impronta`).

| File | Cosa contiene |
|---|---|
| `colormath.golden.txt` | un'impronta per funzione di colore (`add`, `average`, `lightaverage`, ...) su una griglia di colori e di fattori, anche fuori da `0..FRACUNIT` |
| `painter.golden.txt` | `R_DrawColumnInCacheMultipatch`: cache e segni di 17 colonne (post vuoti, tagliati, sovrapposti, origine negativa, altezza 0) |
| `rebuild.golden.txt` | i post che `R_GenerateComposite` riscrive dai segni, per altezze da 1 a 600 (anche le colonne alte che terminano) |
| `fixed_repeat.golden.txt`, `fixed_posts.golden.txt` | le due colonne di `R_GetFixedColumn` |
| `patch.golden.txt` | patch decodificati colonna per colonna con il vecchio pittore: dimensioni, scostamenti, pixel e maschera |
| `flat.golden.txt` | conversione di flat da 0 byte a 1 MB con la palette, con e senza la dimensione di FLATINFO |
| `shrink.golden.txt` | `R_ShrinkFlatTo64x64` da 4096 byte a 16 MB; per i flat da 128x128 in su l'uscita vecchia è letta con il passo 128 (vedi sotto) |
| `grow.golden.txt`, `expand.golden.txt` | `R_GrowSpan64to128/256/512` e `R_ExpandColumn` per i fattori da 1 a 8 |
| `hires.golden.txt` | la tabella di `R_CalcHiResTables_SingleThread` per due palette |
| `wipe.golden.txt` | `wipe_initMelt`/`wipe_doMelt`: l'impronta della destinazione dopo ogni chiamata, software (passo = larghezza) e OpenGL (passo di una potenza di 2, alfa `$FF000000`), con tic da 0 a 100 |
| `scale.golden.txt` | l'impronta della tabella `fixedsine` e dei risultati di `R_ScaleFromGlobalAngle`, `_Fixed` e `_DBL` su 3000 contesti casuali |

## Differenze volute e difetti conservati

Sono elencati in `Libs\Imaging\WIRING.md` (sezioni 5 e 6). Qui solo ciò che riguarda i golden:

- **Colonne alte che non terminano**: nessun golden. Il vecchio ricostruttore girava all'infinito (un run oltre
  il pixel 254 a più di 254 dal precedente); i casi di `rebuild.golden.txt` sono scelti perché terminino.
- **`shrink.golden.txt`**: da 128x128 in su il vecchio scriveva con passo 128 fuori dal buffer; l'harness gli dà
  un buffer abbastanza grande e legge l'uscita con quel passo. La libreria scrive con passo 64: i pixel sono
  gli stessi, uguali all'impronta.
- **Pixel non scritti**: nei casi dei flat e delle colonne fisse l'harness azzera la memoria (il vecchio la
  lasciava com'era); la libreria dà 0.

## Come rifarli

L'harness non è nel repository. Per rifarli si ricompila il vecchio codice come sopra (le funzioni sono quelle
dei file elencati, una per una) e si fa girare sugli ingressi di `DelphiDoom.Tests.Imaging.Samples.pas`; se
si cambiano i campioni vanno rifatti tutti i file.
