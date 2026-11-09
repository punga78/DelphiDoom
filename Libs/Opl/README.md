# Libs\Opl - emulatore OPL2 (YM3812) e player Adlib di X-COM

Issue #176 (OpenXcom), fetta "Opl". Port a classi in Delphi 11 di tre file di OpenXcom (`Reference\OpenXcom\src\Engine\Adlib\fmopl.cpp`, `adlplayer.cpp` e `Engine\AdlibMusic.cpp`), senza SDL e senza dispositivo audio: la produzione dei campioni è pura (si riempie un buffer). Il chip si può usare anche da altri progetti che hanno la musica AdLib (**Keen Dreams**: vedi "Uso da Libs\Keen").

## Licenza

- `DelphiDoom.Opl.*` è derivato da `fmopl.c` (MAME 0.37a, Tatsuyuki Satoh; versione modificata per X-COM da Volutar e **rilicenziata LGPL 2.1 o successiva**): nell'intestazione di ogni unit c'è la riga "Port of fmopl.c (MAME 0.37a fork for OpenXcom, LGPL 2.1 or later)". LGPL 2.1+ è compatibile con la GPL v2+ del repository.
- `DelphiDoom.XcomAdlib.*` è derivato da `adlplayer.cpp` ("X-COM Adlib Player by Volutar") e da `AdlibMusic.cpp`, **GPL v3 o successiva** come tutto OpenXcom (le unit lo dichiarano). La licenza dell'opera la decide l'utente (stessa questione di `Libs\XcomFormats`): il repository non è stato cambiato. Chi vuole solo il chip (LGPL) può usare `DelphiDoom.Opl.*` senza il player.

## Contenuto

| Unit | Ruolo |
|---|---|
| `DelphiDoom.Opl.Types` | costanti di `fmopl.cpp` (`FREQ_BITS`, `EG_ENT`, `TL_BITS`...), i record `TOplSlot` e `TOplChannel` (`OPL_SLOT`, `OPL_CH`), `TOplChipType`, `EOplException` |
| `DelphiDoom.Opl.Intf` | `IOplChip`, `IOplChipListener` (i tre handler del C), `IOplNoiseSource` (`rand()`), `IOplTables` |
| `DelphiDoom.Opl.Tables` | `TOplTables`: `TL_TABLE`, `SIN_TABLE` (come indici in `TL_TABLE`), `ENV_CURVE`, `AMS_TABLE`, `VIB_TABLE` |
| `DelphiDoom.Opl.Noise` | `TOplMsvcrtNoise`: `rand()` della C runtime di Windows, per il rumore bianco del ritmo |
| `DelphiDoom.Opl.Chip` | `TOplChip`: `FM_OPL` con `OPLResetChip`, `OPLWrite`, `OPLRead`, `OPLTimerOver`, `YM3812UpdateOne` |
| `DelphiDoom.Opl.Factory` | `TOplFactory`: l'unico punto che conosce le classi; tabelle condivise del processo |
| `DelphiDoom.XcomAdlib.Types` | tabelle di `adlplayer.cpp` (frequenze, ottave, detune, ordine delle tracce), `EXcomAdlibException` |
| `DelphiDoom.XcomAdlib.Intf` | `IXcomAdlibRegisterWriter`, `IXcomAdlibSequencer`, `IXcomAdlibPlayer`, `IXcomAdlibMusicSource` |
| `DelphiDoom.XcomAdlib.RegisterWriter` | `TXcomAdlibRegisterWriter`: `adlib_reg` e `Transpose` (il secondo chip ha la copia trasposta) |
| `DelphiDoom.XcomAdlib.Sequencer` | `TXcomAdlibSequencer`: il resto di `adlplayer.cpp` (`func_*`, `decode_op`, `adlib_play_note`...) |
| `DelphiDoom.XcomAdlib.Player` | `TXcomAdlibPlayer`: `AdlibMusic::load/play/player` (due chip, sinistro e destro, un buffer a 16 bit) |
| `DelphiDoom.XcomAdlib.CatSource` | `TXcomCatAdlibSource`: i brani di `ADLIB.CAT`/`GM.CAT` (sopra `IXcomCatArchive` di `Libs\XcomFormats`) |
| `DelphiDoom.XcomAdlib.Factory` | `TXcomAdlibFactory`: crea il player (due chip, scrittore, sequencer) e la sorgente dei brani |

Non c'è alcun globale: le tabelle statiche del C (`TL_TABLE`, `SIN_TABLE`...) stanno in un `IOplTables` che i chip ricevono dal costruttore (la fabbrica ne tiene uno per processo, come il C le costruisce con il primo chip); lo stato di `adlplayer.cpp` (30 variabili globali) è nei campi del sequencer e dello scrittore.

## Mappa C -> Pascal

| C | Pascal |
|---|---|
| `OPLCreate(type, clock, rate)`, `OPL_initalize`, `init_timetables` | `TOplChip.Create`, `Initialize`, `InitTimeTables` |
| `OPLOpenTable` (`TL_TABLE`, `SIN_TABLE`, `ENV_CURVE`, `AMS_TABLE`, `VIB_TABLE`) | `TOplTables.Create` |
| `OPLResetChip` | `IOplChip.Reset` |
| `OPLWrite(OPL, a, v)` | `IOplChip.Write(port, valore)`; `WriteRegister(registro, valore)` fa le due scritture |
| `OPLWriteReg`, `set_mul`, `set_ksl_tl`, `set_ar_dr`, `set_sl_rr`, `CALC_FCSLOT`, `set_algorythm` | metodi privati di `TOplChip` con gli stessi nomi in commento |
| `OPLRead(OPL, a)` | `IOplChip.Read(port)` |
| `OPLTimerOver(OPL, c)` | `IOplChip.TimerOver(timer)` |
| `OPLSetTimerHandler`, `OPLSetIRQHandler`, `OPLSetUpdateHandler` | `IOplChip.SetListener` con un `IOplChipListener` |
| `YM3812UpdateOne(OPL, buffer, length, stripe, volume)` | `IOplChip.GenerateSamples(buffer, offset, length, stripe, volume)`; con `GenerateSamples(buffer, count)` stripe 1 e volume 1 |
| `OPL_CALC_SLOT`, `OPL_CALC_CH`, `OPL_CALC_RH` | `CalcSlot`, `CalcChannel`, `CalcRhythm` |
| `OPL_KEYON`, `OPL_KEYOFF`, `OPL_STATUS_SET/RESET`, `OPL_STATUSMASK_SET` | `KeyOn`, `KeyOff`, `StatusSet`, `StatusReset`, `StatusMaskSet` |
| `rand()` del rumore bianco | `IOplNoiseSource.NextBit` (`TOplMsvcrtNoise`) |
| `adlib_reg`, `Transpose` | `TXcomAdlibRegisterWriter.WriteRegister`, `Transpose` |
| `func_setup_music`, `init_music_data`, `init_music` | `Setup`, `InitMusicData`, `InitMusic` |
| `func_play_tick`, `decode_op`, `get_numseq` | `Tick`, `DecodeOp`, `GetNumSeq` |
| `func_mute`, `func_fade`, `fade_volume_if_need` | `Mute`, `Fade`, `FadeVolumeIfNeed` |
| `func_set_music_tempo`, `func_set_music_volume`, `func_get_polyphony`, `func_is_music_playing` | `SetTempo`, `SetVolume`, `Polyphony`, `IsPlaying` |
| `func_save_music_state`, `func_load_music_state` | `SaveState`, `LoadState` |
| `adlib_play_note`, `adlib_get_unused_channel`, `adlib_set_amplitude`, `adlib_set_instrument_pitch`, `get_pitched_freq_instr` | metodi privati del sequencer |
| `AdlibMusic::load(data, size)` | `TXcomAdlibPlayer.Load` e la lunghezza di `Play` (un brano con nome conta il nome due volte) |
| `AdlibMusic::play`, `AdlibMusic::player` | `TXcomAdlibPlayer.Play`, `Render` |
| `AdlibMusic::delayRates` | `TXcomAdlibPlayer.TickBytesOf` |

## Proprietà e aritmetica

- Interi a 32 bit come nel C: i prodotti senza segno (`Incr * vib / VIB_RATE`, `Cnt + con`) vanno in wraparound (le unit hanno `{$Q-}` `{$R-}`), gli shift a destra di valori con segno sono aritmetici (`Sar`), il rimando di un `float` a `int` è il troncamento della CPU (fuori intervallo dà `$80000000`).
- Le tabelle si calcolano con `Power`, `Sin` e `Log10` in `Double`; a Win32 la precisione dell'x87 è limitata a 53 bit mentre si calcolano (`SetPrecisionMode(pmDouble)`, come fa SSE nel C): gli interi coincidono in tutte le 34.817 voci delle cinque tabelle (il test confronta l'impronta di ogni tabella con quella del C); in Win64 il compilatore usa SSE e `SetPrecisionMode` non ha effetto.
- Il campione di uscita è `INT16`; la moltiplicazione per il volume è in `float` come nel C (`outd[0] *= volume`: l'intero perde precisione sopra 2^24 e il risultato è lo stesso del C).
- Due chip che fanno da canale sinistro e destro riempiono lo stesso buffer a 16 bit con `stripe = 2` e `offset` 0 e 1 (`AdlibMusic::player`).

## Differenze volute dal C

Ognuna ha un test o è coperta dal golden.

1. **Letture e scritture fuori dai limiti** che il C fa senza accorgersene diventano un'eccezione: `EOplException` per uno `stripe` minore di 1 o per un buffer troppo corto (con un numero dispari di slot il C scrive uno slot oltre la fine al secondo chip di una coppia); `EXcomAdlibException` per un brano letto oltre la sua fine, una nota fuori dalla tabella delle frequenze (nota 0 di un brano, o `note - 1` negativo con il pitch bend), una subtrack che non c'è, più di 128 subtrack, uno strumento di chorus oltre le 16 tracce, un registro oltre 255, un brano di formato vecchio con più di 16 tracce. Prima di sollevare l'eccezione il sequencer ferma la musica (`IsPlaying` è falso).
2. **Frequenza di campionamento** diversa da 8000, 11025, 16000, 22050, 32000, 44100, 48000: il C fa un ciclo infinito (la durata del tick è 0), qui è `EXcomAdlibException` alla creazione del player.
3. **`Render` vuole un numero di byte multiplo di 4** (campioni stereo a 16 bit): con altri valori il C scrive oltre il buffer.
4. **Stati salvati con `SaveState`**: gli indirizzi dentro uno stato puntano nel brano in cui è stato preso; il C continua a leggere la memoria di quel brano (e va in crash se non c'è più). Qui `LoadState` di uno stato preso con un altro brano è `EXcomAdlibException`. OpenXcom non chiama né `func_save_music_state` né `func_load_music_state`.
5. **Rumore bianco**: il C usa la `rand()` globale; qui è una sorgente iniettata (`TOplMsvcrtNoise` è lo stesso generatore della runtime di Windows, un oggetto per chip o uno condiviso come la `rand()` del C).
6. **`OPLTimerOver` con un timer maggiore di 1**: il C legge `T[c]` fuori dall'array; qui ogni numero diverso da 0 è il timer B (la chiamata al listener usa il numero dato).

## Difetti del C conservati (servono a dare gli stessi campioni)

- **Cache dei dati LFO**: `YM3812UpdateOne` copia in globali la profondità del tremolo e del vibrato (i bit 7 e 6 del registro `0xBD`) e l'incremento dell'LFO solo quando il chip che produce campioni cambia. Con un solo chip una modifica dei bit di profondità dopo il primo blocco non si sente mai; con due chip che si alternano (il player Adlib) la cache è rifatta a ogni cambio. Il comportamento è riprodotto con lo stato del "chip corrente" in `IOplTables.ActiveChip`; `IOplChip.LegacyLfoCache := False` dà quello dell'hardware.
- **Il registro 8** (modo CSM, selezione delle note) non è gestito: il C lo gestisce solo nella versione Y8950 che qui non è compilata, quindi `mode` resta 0 e il CSM non si attiva mai.
- I canali 9, 10 e 11 (i registri `A9`-`AB`, `B9`-`BB`, `C9`-`CB`) hanno stato ma non producono suono: il C li ha aggiunti per la polifonia di X-COM e ne calcola solo 9.
- La tabella dei tassi di attacco e decadimento è letta una voce oltre la fine (indice 75): il C legge il primo elemento dell'array che segue nella struttura, cioè 0; qui le tabelle hanno 76 voci.
- Nel player: una nota con `arg1 = 1` ha `cur_note = 0`, che indica "canale libero"; la polifonia può diventare negativa (note spente senza note accese); il tempo si calcola con `* 0.8` e `* 0.4` in `double` e si tronca; il volume iniziale di ogni traccia è 0 finché il brano non imposta il controller 7 (le note restano mute); i comandi `0xA0` e `0xD0` non leggono i loro argomenti. Tutto riprodotto.
- Lo stato dei canali e delle tracce non si azzera quando si imposta un altro brano (`cur_volume`, `hifreq`, la durata dei canali restano), come le globali del C; si azzera creando un altro player.

## Parità con il C++

Il C++ non è nel repository. I dati di `Tests\Data\Opl` sono l'uscita dei file veri di OpenXcom compilati da un harness fuori dal repository (g++ 16.2 MinGW, `-msse2 -mfpmath=sse`, identica con `-O0` e `-O2`):

| File | Contenuto |
|---|---|
| `opl.tables.golden.txt` (12 righe) | impronte FNV-1a delle 5 tabelle statiche e, per 7 coppie clock/rate, delle tabelle di attacco, decadimento e frequenza e degli incrementi LFO |
| `opl.script.txt`, `opl.golden.txt` (12.576 righe) | 80 scenari del chip: strumenti casuali su 9 canali, ritmo, registri casuali, due chip alternati, timer e interruzioni con i loro handler, blocchi di 1 campione, stripe 1 e 2, volumi 1, 0,5, 0,37, 2 e 0, con l'impronta di ogni blocco e le risposte di scrittura e lettura |
| `adlib.songs.txt` (14 brani), `adlib.script.txt`, `adlib.golden.txt` (660 righe) | 21 scenari del player a 7 frequenze: formato nuovo e vecchio, subtrack, cromatico, giro, tempo, volume, dissolvenza, mute, salvataggio e ripristino; per ogni blocco l'impronta dei campioni, l'impronta di **tutte le scritture di registro ai due chip** (così `Transpose` e `adlib_reg` sono provati byte per byte), la polifonia e i byte che mancano al prossimo tick |

I brani di prova sono sintetici (nessun dato originale di X-COM). Il test `Tests\DelphiDoom.Tests.Opl` esegue gli stessi script con le classi Pascal e confronta riga per riga: **0 differenze** in Win32 (Release e Debug) e in Win64. Le istruzioni per rifare i golden sono in `Tests\Data\README.md` ("Opl").

**Non verificato**: il suono con dati veri di UFO/TFTD (`ADLIB.CAT` non è sul PC) e l'ascolto (nessun dispositivo audio è aperto qui); la riproduzione di `Options::musicAlwaysLoop` e il fade del volume di SDL_mixer (sono di `AdlibMusic::player`, dipendono da `Options` e da SDL); il Y8950 e la parte ADPCM (`BUILD_Y8950`, non compilata in OpenXcom); le frequenze di campionamento diverse da quelle delle sette tabelle non hanno un tick (errore).

## Uso da Libs\Keen (non collegato)

Keen Dreams usa l'AdLib per la musica e gli effetti. `Libs\Keen` non ha ancora l'audio (fetta K10): per collegarlo basta creare il chip con la fabbrica e scrivergli i registri che il gioco scrive alle porte `0x388`/`0x389`:

```pascal
Chip := TOplFactory.CreateChip(3579545, 49716);   // clock della scheda, frequenza nativa
Chip.WriteRegister(Registro, Valore);             // ogni OUT sulle porte dell'AdLib
Chip.GenerateSamples(Buffer, Conteggio);          // mono, 16 bit, dal timer audio
```

Il chip non sa nulla del gioco: un `IAudioDevice` (o un filtro di `Libs\Audio`) chiede i campioni a blocchi (circa 140 al secondo per un tick di 140 Hz di Keen) e `Read(0)` dà il registro di stato che il rilevamento della scheda legge (la routine `SDL_DetectAdLib` scrive il timer e controlla i bit 0xC0). Per il rumore bianco del ritmo si può iniettare un `IOplNoiseSource` (Keen non usa il ritmo). Il player di X-COM (`XcomAdlib`) non serve a Keen: ha il suo formato dei brani.

## Test

`Tests\DelphiDoom.Tests.Opl` (44 test, copertura 95%: `Tools\Copertura.ps1 -Test Opl`): parità con il C (5 test), il chip (19 test: silenzio, key on, reset, volume, stripe, buffer, timer e interruzioni, listener, tabelle condivise, cache LFO, due chip, rumore) e il player (20 test: brano semplice, fine, stop, errori dei dati, scrittore con trasposizione, sorgente CAT). Compilare con `Tools\build.bat Tests\DelphiDoom.Tests.Opl`; in Win64 con `dcc64` (il progetto è Win32; sono passati tutti i test anche li).
