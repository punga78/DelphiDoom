# Verifica #198: parita' dell'audio di Libs\War con il C del remake

`war1` (acoto87/war1, zlib; i convertitori `shl/voc.h`, `wav.h`, `xmi2mid.h` sono MIT) e' in `Reference\war1` (sola lettura). Il codice ORIGINALE si compila con gcc
di `Reference\_dati\_strumenti\w64devkit` (non c'e' un compilatore C nel PATH).

```
powershell -NoProfile -File Compila-AudioRef.ps1 -Out <cartella nuova fuori dal repository>
war_audio_ref.exe - synth     > Tests\Data\War\audio.synth.golden.txt      (casi sintetici di VOC e WAV, senza DATA.WAR)
war_audio_ref.exe - mix       > Tests\Data\War\audio.mixer.golden.txt      (wa_playWave su un suono di 3000 byte)
war_audio_ref.exe - position  > Tests\Data\War\audio.position.golden.txt   (volume fuori dalla vista, bit dei float)
war_audio_ref.exe <DATA.WAR> list > Tests\Data\War\audio.records.golden.txt (111 suoni e 45 brani)
war_audio_ref.exe <DATA.WAR> dump N file   (i byte della risorsa N dopo il caricamento: MIDI o PCM a 44100)
```

`Compila-AudioRef.ps1` **non modifica** il remake: estrae alla lettera (cercando le righe per testo) `wres_loadXmi/Wave/Voc` di `war_resources.c`, `wa_playWave` di
`war_audio.c`, tre funzioni di `war_math.c`, le struct e le tabelle che servono, e usa i tre header MIT cosi' come sono. Gli stub sono solo SDL, Tracy, `wm_alloc` e il log.
Il volume posizionale di `audioDataCallback` non e' una funzione a se': `runPosition` ne ripete le righe (con le funzioni di `war_math.c` estratte).

Formato delle righe: `V|W nome tipo a b c lunghezza` (la specifica con cui si costruisce l'input) e poi `canali frequenza bit byte-letti crc-letti byte-a-44100 crc oob`, dove `oob` e'
il numero di byte in coda che il ricampionatore del C legge oltre il buffer (il CRC li esclude). `M` (brano): lunghezza e CRC dell'XMI, lunghezza e CRC del MIDI di
`x2m_transcode`, Note On, Note Off, altri eventi di canale, CRC del multiinsieme degli eventi, microsecondi dell'ultimo Note On. `W`/`V` di `DATA.WAR`: canali, frequenza,
bit, byte e CRC letti, byte e CRC a 44100 Hz, byte oltre il buffer.

## Seconda fetta: la musica e la scelta dei suoni

```
powershell -NoProfile -File Compila-MusicRef.ps1 -Out <cartella nuova> [-Run Tests\Data\War\music.golden.txt]
powershell -NoProfile -File Compila-SoundRef.ps1 -Out <cartella nuova> [-Tables Tests\Data\War\sounds.tables.golden.txt] [-Ranges Tests\Data\War\sounds.ranges.golden.txt]
```

`Compila-MusicRef.ps1` estrae `wa_playMidi` (`war_audio.c`), `struct _WarAudioComponent` (`war_audio.h`) e `WarAudioId`/`WarAudioType` (`war_enums.h`), li compila con `war_music_ref.c` (il generatore di 12 canzoni con seme fisso, gli stub di `tsf_*` che scrivono le chiamate, e `tml.h` di `deps\include\TinySoundFont` com'e'). Il formato delle righe e' in testa a `war_music_ref.c`. Gli scenari **evitano** i difetti del C che la libreria non conserva (commento sopra `makeSmf`). `Compila-SoundRef.ps1` estrae le quattro `wa_play*Sound` e le fa girare con `war_sound_ref.c` (stub di `wa_createAudio*` che scrivono la richiesta); gli intervalli `randomFromId`/`randomToId` di ogni `src\*.c` si leggono dal testo e i valori dal C (`war_ranges.exe`). Tutto si rifa e si confronta con `Tools\Verifica\201\Confronta-Golden.ps1`.
