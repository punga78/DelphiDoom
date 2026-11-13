# Tests\Data\Audio

Dati dei test di `Libs\Audio`.

- `audio.golden.txt`: l'uscita del vecchio `I_CacheSFX` e del vecchio `GetSongLength`/`I_MusToMidi` (vedi `Libs\Audio\CLAUDE.md`).

## Preset EFX e intestazione WAVE di Doom 3 (issue #112)

Confronto di `TEfxEffectsFile` e di `TWaveHeaderReader` con i **veri** `snd_efxfile.cpp` e `snd_wavefile.cpp` di Doom 3. Nessun dato di Doom 3 e' nel repository: i casi sono scritti per il test.

- `efx.input.txt`: 11 casi. Un caso va da `@case nome` a `@end`; dentro: `@file percorso` (un file in memoria: le righe fino alla prossima direttiva) e `@op operazione`: `load PERCORSO [os]` (`idEFXFile::LoadFile`, con `os` un percorso del sistema operativo; i file letti si **aggiungono** alla lista), `find NOME` (`FindEffect`, il nome puo' avere spazi o mancare), `unload`, `size` (`sizeof(EAXREVERBPROPERTIES)`). `efx.golden.txt`: `ret=`, `ERR` con il messaggio del lexer ("file F, line N: ..."), e dopo ogni `load` e `unload` `n=` e per ogni effetto il nome, la dimensione e ogni campo (float come i loro 32 bit esadecimali, interi in decimale).
- `wave.input.txt`: 14 casi (31 file). `@file percorso` e righe di byte con le parole `T:abcd` (quattro caratteri, `_` e' uno spazio: `T:fmt_`), `B:n`, `W:n` (16 bit), `D:n` (32 bit), `Z:n` (n zeri), `X:hex`, tutte in little endian; `@op wave PERCORSO` (`idWaveFile::Open`) e `@op size`. `wave.golden.txt`: `ret=0` con il formato (`mpwfx`), `GetOutputSize`, `GetMemorySize`, `mseekBase` e `mck.cksize`, o `ret=-1`.
- I test: `TTestEfxGolden` (`DelphiDoom.Tests.Audio.Efx`) e `TTestWaveHeaderGolden` (`DelphiDoom.Tests.Audio.WaveHeader`); il confronto e' **esatto**, senza tolleranza (se non coincide scrivono `DelphiDoom.Tests.Audio.efx.actual.txt` o `.wave.actual.txt` accanto all'eseguibile).
- Come sono stati prodotti: l'harness e' quello del sound shader (`Tests\Data\Decl\README.md`, `Tests\Data\Decl\harness\sound`: stessi `precompiled.h.txt`, `snd_local.h.txt` e `build.ps1.txt`) con i due driver di `harness\` (`driver_efx.cpp.txt` come `idlib\driver_efx.cpp` e `driver_wave.cpp.txt` come `idlib\driver_wave.cpp`); `build.ps1.txt` compila tre programmi (`snd`, `efx`, `wave`) e `efx.exe efx.input.txt` e `wave.exe wave.input.txt` scrivono i golden. Per l'EFX il driver ha `Mem_Alloc` azzerato (il C++ non lo e': i campi non letti sono memoria a caso) e un file system in memoria (`OpenFileRead`); per l'intestazione WAVE il file e' un `idFile` in memoria con `Seek` e `Tell`, `ReadFile` dice sempre "non c'e'" (il percorso `.ogg` di `Open` non si prova) e `OpenOGG`, `ReadOGG` e `CloseOGG` rifiutano.
- Non nei casi: un file di meno di 12 byte o con la dimensione dei dati tagliata dalla fine del file (il C++ legge memoria non inizializzata: la classe rifiuta), il parametro non valido di un `.efx` con un lexer che non solleva (il C++ usa un blocco liberato), `Read`/`Seek` di `idWaveFile` e il percorso `.ogg`.
