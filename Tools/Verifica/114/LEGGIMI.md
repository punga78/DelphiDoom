# Tools\Verifica\114 - parita' del decoder RoQ (issue #114)

Strumenti che producono le risposte di riferimento di `Libs\Cinematic` con il **codice di Quake III Arena** (`Reference\quake3\code\client\cl_cin.c`, sola lettura). Non c'e' un compilatore C nel PATH: si usa il gcc del kit `Reference\_dati\_strumenti\w64devkit`.

- `build.sh [cartella]` (sh, da Git Bash): costruisce `roq_original.inc` con intervalli di righe di `cl_cin.c` (l'originale non e' riscritto), compila `roqextract.exe` (con il gcc **i686** del kit) e `roqgen.exe`. Le variabili `DELPHIDOOM_ROOT` (radice del repository principale, dove sta `Reference\`) cambia il percorso di default `/c/Progetti/DelphiDoom`.
- `stubs.h`: i sostituti minimi del motore (file system su un buffer in memoria, `S_RawSamples`, orologio, `glConfig`).
- `roqextract.c`: il pilota. `roqextract file.roq` fa girare `RoQInterrupt` dell'originale e stampa `fps`, `size`, `frame N crc` (CRC-32 dei `W*H*4` byte del fotogramma), `audio N channels C rate R samples S consumed X full Y` (`consumed` e' quello che il mixer legge, `full` tutto il blocco decodificato) e i totali. `roqextract --tables` stampa `yuv crc` (le 16.777.216 terne di `yuv_to_rgb24`) e le righe `rll ...` (i quattro `RllDecode*`, buffer di 4096 byte da un LCG con seme 12345, quattro flag).
- `roqgen.c`: `roqgen basic|wide|stereo out.roq` fa i file di prova sintetici (semi fissi; nessun materiale commerciale).

- `modeextract.c`: il pilota dei modi del codebook (seconda fetta della #114). `modeextract > modes.golden.txt` stampa `yuv565 crc` (CRC-32 di `yuv_to_rgb` su tutte le terne) e, per 32 bit, 16 bit e grigi, ognuno normale, `smootheddouble` e `half` (piu' `half + smootheddouble` a 32 bit), una riga per ognuno dei tre chunk di `decodeCodeBook` (flag `0000`, `1004`, `0003`, byte di un LCG con seme 987654321, tabella dei grigi `(i*37+11)&255` che l'originale non riempie) con il CRC-32 di `vq2`, `vq4` e `vq8` interi.

Per rifare i dati di `Tests\Data\Cinematic`:

```
sh Tools/Verifica/114/build.sh <cartella nuova>
roqgen.exe basic basic.roq   (idem wide, stereo)
roqextract.exe basic.roq > basic.golden.txt   (idem wide, stereo)
roqextract.exe --tables > tables.golden.txt
roqextract.exe idlogo.RoQ > idlogo.golden.txt
```

`idlogo.RoQ` e' `video/idlogo.RoQ` in `Reference\openarena\openarena-0.8.8\baseoa\pak6-misc.pk3` (920336 byte, 512x512, 124 fotogrammi, 123 blocchi audio stereo): **non e' nel repository** (c'e' solo il golden con i CRC). Le ultime 11 righe `frame` del golden sono i fotogrammi fantasma di Quake III (vedi `Libs\Cinematic\CLAUDE.md`, "Difetti del C"). Il file `.sh` deve restare con le fine riga LF.
