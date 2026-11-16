# Verifica #236 (parte B), #114: JPEG dei fotogrammi di Doom 3

`jpegfast.c` decodifica con il **vero** `jpeg-6` di Doom 3 (`Reference\doom3\neo\renderer\jpeg-6`, non modificato; compilato con bcc32c, 32 bit) i flussi di `Tests\Data\Jpeg\doom3\cases.pack` con le impostazioni di `JPEGBlit` (`Cinematic.cpp`): `dct_method = JDCT_FASTEST` (che nel `jconfig.h` di Doom 3 e' `JDCT_FLOAT`: l'IDCT in virgola mobile `jidctflt.c`) e `do_fancy_upsampling = FALSE`. Stampa una riga per flusso: nome, larghezza, altezza, componenti, esito (0 = decodificato, 1 = errore) e l'impronta FNV-1a dei pixel (R, G, B per un'immagine a colori, un byte per una grigia).

```
powershell -NoProfile -File Tools\Verifica\236b\jpeg\build.ps1 -Out C:\ddparity_236b\jpeg
C:\ddparity_236b\jpeg\jpegfast.exe Tests\Data\Jpeg\doom3\cases.pack > Tests\Data\Jpeg\doom3\doom3.golden.txt
jpegfast.exe cases.pack doom3 <nome>      # scrive anche <nome>.raw, i pixel
```

- `cases.pack`: 232 flussi di `TJpegCases` (non alterati, fino a 3500 byte; record: lunghezza del nome, nome, lunghezza dei dati, dati; little endian), fatti dalla stessa lista dei test di `Framework\Jpeg`.
- Il `jpeg-6` di Doom 3 e' **IJG 6** (non 6b) con solo la IDCT float compilata (`DCT_ISLOW_SUPPORTED` e `DCT_IFAST_SUPPORTED` sono `#undef`) e **senza** `D_MULTISCAN_FILES_SUPPORTED`: i JPEG progressivi o a piu' scansioni sono "Requested feature was omitted at compile time" (93 flussi del pack). `RGB_PIXELSIZE` e' 4: un'immagine YCbCr ha il quarto byte non scritto (l'impronta guarda solo R, G, B); un JPEG con componenti R, G, B scrive i pixel compatti a tre byte (come `null_convert`).
- Il programma da' `jpg_Error` e `jpg_Printf` (richiesti da `jerror.c`), una sorgente in memoria che finiti i byte da' `FF D9`, e `error_exit` con `longjmp`.
- Differenza nota 6 / 6b: quando i dati finiscono prima dell'immagine (`patch-sof-height-65500`) la 6 continua a leggere bit a zero come simboli, la 6b lascia i blocchi a zero: i pixel sotto i dati non coincidono (escluso dal test, con il motivo scritto).
