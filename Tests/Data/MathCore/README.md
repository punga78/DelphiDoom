# Dati di prova di Libs\MathCore (issue #75)

I file `*.golden.txt` sono l'uscita del **vecchio codice del motore** (`Base\m_fixed.pas`, `tables.pas`,
`m_vectors.pas`, `m_bbox.pas`, `m_rnd.pas`, `m_stack.pas`, `m_hash.pas`, `m_crc32.pas`, `m_sha1.pas`),
compilato con Delphi 11 Win32, con ottimizzazioni spente, in un programma di prova **fuori dal repository**
(l'harness non si committa). Ogni riga è `chiave=impronta/conteggio`: l'impronta è un FNV-1a a 64 bit dei risultati
(`DelphiDoom.Tests.MathCore.Fingerprint`), il conteggio il numero di valori; per i checksum il valore è l'esadecimale.

Gli ingressi sono gli stessi in harness e test (`DelphiDoom.Tests.MathCore.Samples`): 40 valori di bordo
(0, segni, 1.0, 0.5, limiti di `Integer`, schemi di bit) in tutte le coppie (1600) più 4000 coppie pseudo casuali
(xorshift32 con seme fisso), a più grandezze; per i vettori serie di 1000-2000 vettori casuali; per i testi 3000 testi
fino a 24 caratteri (anche oltre 255); per i file di CRC 13 dimensioni (0, 1, 255, 256, 257, ... 65543 byte); per
SHA-1 le lunghezze 0..130 e 1000, 4099, 65599. Una funzione che solleva un'eccezione conta come "eccezione" nella
serie, in entrambe le parti.

| File | Contenuto |
|---|---|
| `fixed.golden.txt` | tutte le `FixedMul*`, `FixedDiv*`, `FixedMod`, conversioni, `FixedSqrt`, `FixedInt64`, `FixedMul64`, `FloatDiv/Mul` (`.edge` = coppie di bordo, `.random` = casuali) |
| `trigonometry.golden.txt` | impronta di ogni tabella (finesine, finecosine, finetangent, tantoangle, tantoangle_ex, fixedsine, fixedcosine), `SlopeDiv`, `SlopeDivEx`, `FixedToAngle`, `AngleToFixed`, `DegToSlope` |
| `vectors.golden.txt` | i bit di ogni funzione di `m_vectors` (a 32 bit: `float` = `Single`, espressioni in `Extended`) |
| `boundingbox.golden.txt` | sequenza di `M_ClearBox`/`M_AddToBox` |
| `random.golden.txt` | `M_Random`, `P_Random`, `N_Random`, `Sys_Random` (6 semi), `C_Random`, `P_RandomFromSeed`, save/restore, `P_RandomHitscanAngle/Slope` |
| `hash.golden.txt` | 3000 `M_HashUpdate` e 3500 `M_HashIndex` |
| `stack.golden.txt` | sequenze di push/pop e add/remove di `TIntegerStack` e `TIntegerQueue` |
| `checksums.golden.txt` | `GetCRC32` su file, `SHA1_CalcSHA1Buf` (esadecimale). Verificati anche con i valori noti degli standard (`123456789` = CBF43926, `abc` = A9993E36...) |

Le tabelle sono copiate dal vecchio codice con un `awk` sulle righe di `Base\tables.pas`, `m_rnd.pas` e `m_crc32.pas`
(non a mano) e il test confronta le impronte con quelle delle tabelle vecchie.

## Differenze volute dal vecchio codice

- Niente `asm`: le funzioni sono Pascal puro e danno gli stessi bit (anche a 64 bit).
- `FixedDiv2` (`DivideRaw`), `FixedDiv_fast`, `FixedDivLW` e `FixedDiv_Positive` con un quoziente che non entra in 32 bit
  o con divisore zero (dove il vecchio sollevava l'eccezione del processore, `idiv`) sollevano `EMathCoreException`.
- `FixedMulEx`, `SlopeDivEx`, `FixedToAngle`, `AngleToFixed` sono fatte con interi a 64 bit invece che con `Extended`:
  il risultato è identico a 32 bit (i prodotti stanno nei 64 bit di mantissa dell'FPU) ma ora lo è anche a 64 bit.
- `AngleToSlope` (non esportata dal vecchio `tables`, ma usata da `DegToSlope` e dal colpo hitscan) con `-ANG90` o il
  più piccolo intero faceva un overflow e leggeva fuori dalla tabella; ora dà l'ultimo elemento. Nessun altro ingresso cambia.
- `Sys_Random` con un indice fuori dalla tabella (seme negativo o troppo grande) leggeva fuori dai limiti: ora `EMathCoreException`.
- `VectorCompare` dà un `Boolean` invece di 0/1; i puntatori sono parametri `const`/`var`.
- `M_PopValue`/`P_RestoreRandom` con la pila vuota facevano `I_DevError`: ora `Pop` e `RestorePlayIndex` danno `False`.
- La pila globale e gli indici (`rndindex`, `prndindex`, `nrndindex`, `sysrndindex`, `sysrndseed`) stanno nell'oggetto.
- CRC e SHA-1 lavorano su buffer: la lettura di file e lump resta al chiamante (`GetCRC32` dava `DEADDEAD` per un file mancante).

## Difetti del vecchio codice conservati

- `M_AddToBox` (`else if`): dopo `M_ClearBox` il primo punto imposta solo sinistra e basso, non destra e alto.
- `FixedDiv_Positive` con `a` negativo: `a shr 14` è logico, quindi non satura mai verso `MAXINT` per i negativi.
- `FixedDivLW` divide i valori senza segno come numeri con segno (`idiv`), per `a` o `b` sopra `$7FFFFFFF`.
- `FixedMod` con `b` = 0 dà `a`; `FixedSqrt` di un numero negativo solleva l'eccezione dell'FPU.
- `M_Random`, `P_Random`, `N_Random` muovono l'indice prima di leggere: il primo numero è quello di indice 1.
- `P_RandomHitscanAngle` legge due volte `N_Random`, nell'ordine `t - N_Random`.
- L'hash SDBM legge i caratteri di una `string` a 16 bit (come prima).

## Come rigenerarli

L'harness è un programma console da 800 righe che usa gli stessi `Fingerprint` e `Samples` e le unit vecchie con tre finti
(`i_system`, `w_wad`, `z_zone`) al posto del motore; non è nel repository. Il test non lo richiede: confronta con i file già fatti.
Se si cambia un ingresso (`Samples`) vanno rifatti tutti i file.

## `geometry.golden.txt` (issue #96)

Risposte di `idPlane`, `idBounds`, `idSphere` e `idBox` veri (compilati con `bcc32c`, x87): 9109 righe `nome ingressi | uscite`, float come `#` più i bit in esadecimale, interi e flag in chiaro; gli ingressi stanno sulla riga. Test: `DelphiDoom.Tests.MathCore.Geometry.Parity`. Dettagli e tolleranze in `Libs\MathCore\CLAUDE.md`.
