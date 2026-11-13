# Tools\Verifica\128 - parita' del suono di Quake III (issue #128)

Strumenti che producono le risposte di riferimento di `Libs\Audio\DelphiDoom.Audio.Q3.*` con il **codice di Quake III Arena** (`Reference\quake3\code\client\snd_dma.c`, `snd_mix.c`, `snd_mem.c`, `code\game\q_math.c`, sola lettura). Non c'e' un compilatore C nel PATH: si usa il gcc di `Reference\_dati\_strumenti\w64devkit` (x64, SSE).

- `build.sh [cartella]` (sh, da Git Bash): costruisce `snd_original.inc` con **funzioni intere** dei sorgenti originali (estratte per nome con awk, mai riscritte) e compila `q3snd.exe`. `DELPHIDOOM_ROOT` (radice del repository principale, dove sta `Reference\`) cambia il percorso di default `/c/Progetti/DelphiDoom`. Funzioni incluse: `S_SpatializeOrigin`, `S_ChannelFree/Malloc/Setup`, `S_StartSound`, `S_StartLocalSound`, `S_ClearSoundBuffer`, `S_StopAllSounds`, `S_StopLoopingSound`, `S_ClearLoopingSounds`, `S_AddLoopingSound`, `S_AddRealLoopingSound`, `S_AddLoopSounds`, `S_RawSamples`, `S_UpdateEntityPosition`, `S_Respatialize`, `S_ScanChannelStarts`, `S_GetSoundtime`, `S_Update_`, `S_WriteLinearBlastStereo16` (la versione C), `S_TransferStereo16`, `S_TransferPaintBuffer`, `S_PaintChannelFrom16`, `S_PaintChannels`, `ResampleSfx`, `VectorNormalize`, `VectorRotate`, `DistanceSquared`, `VectorLengthSquared`.
- **Due difetti di `S_StartSound` sono corretti con `sed`** (build.sh controlla che le sostituzioni siano avvenute), perche' leggono fuori dall'array e il risultato dipenderebbe da cio' che sta dopo `s_channels`: `ch[i]` su un puntatore che avanza insieme a `i` (legge il canale 2i), e il test `ch->entnum == listener_number` dopo i cicli (un elemento oltre la fine; qui tutti i canali si guardano da capo). Sono due "differenze volute" della libreria.
- `stubs.h`: i tipi e i globali di `snd_local.h` e `snd_dma.c`, le macro dei vettori, i cvar, l'orologio e il dispositivo DMA come variabili.
- `q3snd.c`: il pilota. `q3snd gen <scenario 0..4> <seme>` scrive uno script di operazioni (casuale con seme fisso: LCG `x * 1103515245 + 12345`, nessun materiale commerciale); `q3snd run <script>` lo esegue sul codice di Quake III e stampa, dopo ogni operazione, l'impronta FNV-1a a 64 bit dei canali attivi, dei canali dei loop e del buffer DMA, i tempi (`painted`, `soundtime`, `rawend`) e i volumi di `S_SpatializeOrigin`. I float dello script sono i bit esadecimali del `float`. `Q3SND_VERBOSE=1` stampa anche i campi dei canali dei loop.
- Scenari: 0 stereo a 16 bit, 22050 Hz, blocco 1024; 1 mono a 8 bit, 11025 Hz, blocco 256, volume 0.5; 2 stereo a 16 bit con blocco 128 (anticipo da `s_mixPreStep`), 3 entita' e 4 suoni; 3 stereo a 8 bit con 32768 campioni, volume 1.0 e velocita' alte; 4 pressione sui canali (12 entita', tutti i 96 occupati, canali presi al piu' vecchio). Ogni script ha ~500 operazioni (900 il 4): tempo, posizione DMA, ascoltatore, partenze, suoni locali, loop (veri e non), raw stream, `S_SpatializeOrigin`, pulizia del buffer, `S_Update_` e `S_PaintChannels` diretto. Un `paint` diretto e' emesso solo quando nessun canale e' in attesa di partire (il C leggerebbe prima dell'inizio del suono).

Per rifare i dati di `Tests\Data\Audio\Q3`:

```
sh Tools/Verifica/128/build.sh <cartella nuova>
for s in 0 1 2 3 4; do
  q3snd.exe gen $s $((1000 + s)) > scenario$s.script.txt
  q3snd.exe run scenario$s.script.txt > scenario$s.golden.txt
done
```

Il `.sh` deve restare con le fine riga LF. Il test `DelphiDoom.Tests.Audio.Q3.Parity` esegue gli script sulle classi Pascal e confronta ogni riga (con `Q3SND_DUMP=<cartella>` scrive anche cio' che hanno fatto le classi, con `Q3SND_VERBOSE=1` i dettagli dei loop, per un `diff` con `q3snd run`).
