# Framework\AudioMix — note per Claude

`Framework\AudioMix` (issue #228, indice #227, strato Servizi) e' lo strato di **mixing software** comune a `XcomAudio`, `War` e `Greed`: nessuna dipendenza da `IdTech1\Base\`, dai giochi, da `GameHost` o da `Platform` (solo RTL). **Doom** (`Framework\Audio`, `TSfxMixer`) usa gia' la lista di voci e la saturazione (dopo la #189 il suo mixer e' software); le sue formule (guadagni in decibel) non sono quelle dei tre giochi e non si toccano qui. `Keen.AudioMixer` (sorgenti a pezzi di 1/140 di secondo) e `Tracker.Mixer` (voci interne al lettore di moduli) fanno un lavoro diverso e restano fuori.

**Regola della fetta: i campioni prodotti restano identici byte per byte.** I tre mixer di prima non fanno la stessa cosa nei dettagli (vedi la tabella): una formula unica avrebbe cambiato i campioni di almeno un gioco. La libreria offre quindi **strategie su un solo contratto** (le formule restano quelle di ogni gioco, copiate alla lettera) e mette in comune quello che e' davvero uguale: la lista di voci con il lucchetto, la saturazione a 16 bit e i due ricampionatori.

## Contratto scelto

| Tipo | Ruolo |
|---|---|
| `IPcmVoice` (`Intf`) | una voce: `Mix(ADestination: Pointer; ACount: Integer): Boolean` aggiunge il blocco successivo alla destinazione del chiamante e dice se e' finita. Il tipo del campione (mono 16 bit, stereo 16 bit, somma a 32 bit) e' una convenzione tra la voce e chi mixa: la lista non lo conosce |
| `TPcmVoiceList` | le voci che suonano, **nell'ordine di inserimento** (una somma che satura dipende dall'ordine), con `TCriticalSection` esposto come `Lock` (il chiamante lo puo' riprendere per proteggere il proprio stato con lo stesso lucchetto: e' ricorsivo). `Add` da' un handle 1, 2, 3...; `Remove`, `Clear`, `Count`; `MixAll(dest, count)` da' un blocco a ogni voce e toglie quelle che rispondono `True`, ritornando quante |
| `IPcmResampler` | `Resample(const ASource: TPcmBuffer; ATargetRate): TPcmBuffer`; due strategie |
| `TPcmBuffer` (`Types`) | canali, rate, bit, byte dei campioni (era `TWarPcmBuffer`, ora un alias) |
| `TPcmSaturation` | `Clamp` e `AddSaturated(dest, src, count)`: la somma a 16 bit che taglia |
| `IPcmMidiSynth` / `TPcmMidiSynth` | sintetizzatore MIDI software (seconda fetta): `Send`, `Reset`, `Render` che somma al buffer con saturazione |
| `TPcmLevelMeter` | picco, RMS e frame con suono di un buffer stereo a 16 bit (seconda fetta) |
| strategie di voce | `TPcmUnsignedMonoVoice` (War), `TPcmStereoChannelVoice` (Xcom), `TPcmNearestRateVoice` (Greed): ognuna con la sua formula, volume e pan come li dava il gioco |
| strategie di ricampionamento | `TPcmFixedPointResampler` (War), `TPcmFramePositionResampler` (Xcom) |

**Dove entra una chiamata a interfaccia**: `IPcmVoice.Mix` **per voce e per blocco** (War e Greed, dentro `TPcmVoiceList.MixAll`); `IPcmResampler.Resample` per suono, a caricamento. **Mai per campione**: il ciclo dei campioni e' dentro la voce, in codice di classe. Xcom chiama i suoi 16 canali direttamente (classi, non interfacce).

## Confronto riga per riga dei tre mixer (prima dello spostamento)

| | `TWarSoundMixer` + `TWarWaveVoice` (`Games\War`) | `TXcomMixer` (`Games\XcomAudio`) | `TGreedPcmMixer` (`Games\Greed`) |
|---|---|---|---|
| Campioni in ingresso | byte `Byte` senza segno mono, gia' a 44100 Hz (il decoder ricampiona) | `TArray<SmallInt>` stereo interlacciato, gia' al rate del mixer (il decoder ricampiona) | i byte del WAV letti sul posto: 8 bit senza segno o 16 con segno, 1 o 2 canali, qualunque rate |
| Uscita | 16 bit **mono**; `TWarPcmSource` mette lo stesso campione a sinistra e a destra | 16 bit stereo | 16 bit stereo |
| Accumulatore | il buffer di uscita (`SmallInt`) **che ha gia' qualcosa dentro** (si somma, non si azzera) | il buffer di uscita, azzerato a ogni `Render` | array di `Integer` azzerato a ogni `Render` |
| Saturazione | **a ogni voce**, campione per campione: `Inc(v, out^)` e taglio a 32767/-32768 (la somma dipende dall'ordine) | **a ogni voce** e alla musica (che va prima): `Mix` e `EnsureRange` per campione | **una volta sola**, alla fine, sulla somma a 32 bit (ordine delle voci ininfluente); conta `ClippedSamples` |
| Ordine delle voci | di avvio | musica, poi canali 0..15 | qualunque (somma larga); l'originale scorreva dalla fine |
| Formula del volume | `Single`: `v := (b - 128) shl 8; Trunc(v * volume)`; ogni passo in `Single` (`LScaled`) | non-"baked": `Trunc(campione * gain)` con `gain = GainLato * (volumeCanale / 128)`, tutto `Single`; "baked" (`PlayWave`): nessun volume (e' gia' nei campioni) e zittito da `SetVolume(0,.,0)` | intero: `gain = Round(vol * Min(1, 1 -/+ pan) * 256)`, `(campione * gain) div 256` (taglia verso zero) |
| Pan | nessuno; la voce "posizionale" ha un fattore di attenuazione (`TWarSoundAttenuation`) per il volume | `GainLeft = (1 - Max(0, sin(angolo))) * distanza`, `GainRight = (1 + Min(0, sin)) * distanza`, `Single` (distanza `(255 - d) / 255`) | lineare -1..1 come BASS: il lato lontano scende, l'altro resta |
| Arrotondamento | `Trunc` | `Trunc` | `Round` del guadagno a 1/256, poi `div` |
| Loop | flag: rifa' il giro **dentro lo stesso blocco** (`repeat ... until`); se chiamata dopo la fine riparte da 0 | `Plays`: -1 per sempre, n significa n+1 passate; riparte dentro il blocco | nessuno per gli effetti (la musica e' in ciclo nel decoder) |
| Fine voce | `SampleIndex >= Length` senza ciclo: tolta nello stesso `Mix`; un suono vuoto finisce subito (l'originale girava per sempre) | `Plays = 1` a fine passata (anche se coincide con la fine del blocco); un suono vuoto spegne il canale | un frame oltre l'ultimo: `Ended` nel blocco **dopo** l'ultimo frame; una voce fermata (`Stop`) si toglie senza essere mixata |
| Contenitore | lista con handle 1, 2, 3...; `Stop(handle)`, `StopAll` | 16 posti fissi, 0..3 riservati, `PlayWave` prende il primo libero da 4; il numero del canale e' del chiamante | lista; il "handle" e' la voce stessa (`IGreedEffectChannel`: `SetPan`, `SetVolume`, `Stop`) |
| Lucchetto | un `TCriticalSection` su ogni metodo e su `Mix` | un `TCriticalSection` su ogni metodo e su `Render` | un `TCriticalSection` su avvio, `Render`, statistiche; volume, pan e `Stop` di una voce **non** hanno lucchetto (una lettura per blocco) |
| Statistiche | solo `ActiveVoices` | byte, RMS, picco, suoni partiti | frame, frame con suono/musica, picco, tagli, effetti avviati/rifiutati/finiti/attivi, canzoni |
| Musica | no (e' fuori dal mixer) | `IXcomMusicTrack.Render` in un buffer temporaneo, poi somma saturata (prima dei canali) | `IGreedSongRenderer` scalato con `Round(vol*256)` e `div 256` nella somma larga |
| Virgola mobile | `Single` ovunque, come il `float` del C (golden sui bit) | `Single` per i guadagni, espressione in precisione del compilatore | `Single` solo per volume e pan (una volta per blocco) |

**Perche' tre strategie e non una formula**: la somma saturata per voce (War, Xcom) e quella larga con un taglio solo (Greed) danno risultati diversi appena due voci superano il limite; il volume in `Single` con `Trunc` (War, Xcom) e quello a 1/256 con `Round` e `div` (Greed) differiscono di un'unita' su molti campioni; Xcom ha il "baked" e il silenziamento di `backgroundMute`. Ognuna e' un'implementazione di `IPcmVoice` o una classe con la sua firma, scelta dal gioco. Nessun gioco e' stato cambiato di un bit.

**Il caso a virgola mobile di War** (domanda della #228): `War` non ha un formato di campione in virgola mobile; usa `Single` solo per il volume e lo scambio e' dentro `TPcmUnsignedMonoVoice`. Non serve un tipo di campione `Single` nel contratto.

## Ricampionatori

| | `TPcmFixedPointResampler` (War) | `TPcmFramePositionResampler` (Xcom) |
|---|---|---|
| Formati | 8 o 16 bit, qualunque numero di canali | solo 16 bit stereo (`ConvertStereo16` su `TArray<SmallInt>`; `Resample` su `TPcmBuffer` la rifiuta con `EAudioMixException`) |
| Posizione | `Cardinal` 16.16, passo `Trunc(rapporto * 65536 + 0.5)` | `Double`: `indice * rateOrigine / rateDestinazione` |
| Interpolazione | lineare intera `a + Sar((b - a) * frazione, 16)` | lineare in `Double` con `Round`; **rapporto potenza di due = campione piu' vicino** (parita' con SDL 1.2) |
| Lunghezza | `Trunc(campioni / rapporto)` | `frame * dst div src` |
| Casi veloci | 8 bit mono x2, x4 (interpolazione) e /2, /4 (media) | nessuno |
| Stesso rate | copia | lo stesso array |
| Errori | `EAudioMixException` per dati vuoti, rate 0, formato non interpolabile (War li rilancia come `EWarException` con lo stesso messaggio) | nessuno: rate non validi danno l'array com'e' |

`Greed` non ha un ricampionatore: la voce prende il campione piu' vicino mentre legge (posizione 32.32), quindi il rate e' dentro `TPcmNearestRateVoice`.

## Cosa e' stato migrato (e cosa no)

- **War**: `TWarWaveVoice` e' un alias di `TPcmUnsignedMonoVoice`; `TWarPcmResampler` chiama `TPcmFixedPointResampler.Convert` e traduce l'errore; `TWarSoundMixer` tiene viewport, volume, attenuazione e silenzio, e le voci in un `TPcmVoiceList` (il suo lucchetto e' quello della lista). `TWarPcmBuffer` e' un alias di `TPcmBuffer`.
- **Greed**: `TGreedPcmMixer` usa `TPcmVoiceList` e `TPcmNearestRateVoice` (`TEffectVoice` ci aggiunge `IGreedEffectChannel`); restano suo il riconoscimento del WAV, la musica, le statistiche e il taglio finale.
- **Xcom**: i 16 canali sono `TPcmStereoChannelVoice`; la somma saturata della musica e dei suoni gia' mixati e' `TPcmSaturation.AddSaturated`; `TXcomResampler` chiama `TPcmFramePositionResampler`. **Non migrato**: la tabella dei 16 posti (riservati, ambiente, `FreeInterfaceChannel`), il gancio della musica, le statistiche RMS/picco e `SetVolume` (regole di OpenXcom): non sono una lista di voci con handle, e metterli in `AudioMix` avrebbe portato dentro `Game::setVolume`.
- Tutte e tre le suite danno gli **stessi numeri di prima** e nessun golden e' stato rigenerato (vedi sotto).

## Seconda fetta (#228, 2026-11-15): sintetizzatore MIDI e misuratore di livello

- **`IPcmMidiSynth`** (`Intf`: `Send`, `Reset`, `Render`, stesso GUID di prima) e **`TPcmMidiSynth`** (`DelphiDoom.AudioMix.MidiSynth`, spostata con `git mv` da `Games\XcomAudio\DelphiDoom.XcomAudio.MidiSynth.pas`; 32 voci, forme d'onda per famiglia di patch, rumore per la batteria): e' l'unico sintetizzatore MIDI software del repository (Doom usa il dispositivo MIDI di Windows). **Non c'era codice comune da unificare**: `War` non ha un sintetizzatore (`IWarMusicSynth` ha solo `TWarSilentMusicSynth`: il SoundFont di TinySoundFont non si porta, licenza di `GMGeneric.SF2` non dichiarata) e `Greed` suona moduli tracker (`Framework\Mikmod`), non MIDI. E' quindi uno **spostamento** nella casa generica, senza una riga di logica cambiata: `IXcomMidiSynth` e' sparita (Xcom usa `IPcmMidiSynth`), l'errore di `Render` con un buffer non multiplo di 4 e' ora `EAudioMixException` (era `EXcomAudioException`: nessun chiamante la catturava) e la somma saturata usa `TPcmSaturation.Clamp` (stessa formula di `EnsureRange` a 16 bit). Dare un sintetizzatore a War sarebbe un suono nuovo, non una convergenza: non fatto.
- **`TPcmLevelMeter`** (`DelphiDoom.AudioMix.LevelMeter`): picco, RMS e frame con suono su un buffer stereo a 16 bit, senza lucchetto (lo tiene il mixer che lo possiede). Prima c'erano due copie dello stesso ciclo, in `TXcomMixer.Render` (picco e somma dei quadrati) e in `TGreedPcmMixer.Render` (picco e frame con suono). Il picco di -32768 e' 32768 (come Xcom); Greed lo taglia a 32767 quando legge (`Min(Peak, High(SmallInt))`, equivalente al taglio per campione di prima perche' `Min` e' monotona). I frame con suono di Greed sono ora contati sull'uscita tagliata invece che sulle somme larghe: uguali, perche' una somma diversa da zero resta diversa da zero dopo il taglio a 16 bit. Il conteggio dei campioni tagliati resta di Greed (serve alle somme larghe, prima del taglio).
- **`TXcomMixer` e `TGreedPcmMixer`**: invariati nel comportamento (stessi byte e stesse statistiche: `MixerParity` e `PcmMixerParity` passano senza ritocchi ai test).
- **`Framework\Audio` (Doom) usa gia' AudioMix**: `TSfxMixer` tiene un `TPcmVoiceList`, `TSfxMixerVoice` e' un `IPcmVoice` e il taglio finale e' `TPcmSaturation.Clamp` (fatto altrove, non in questo giro: non toccato). Resta suo il calcolo del guadagno in decibel, che non e' una formula dei tre giochi.
- **Non fatto, con il motivo**: la tabella a posti di Xcom (`TPcmVoiceSlots`: 16 canali con 4 riservati, canale scelto dal chiamante, ambiente, `FreeInterfaceChannel`) e' regola di `Mix_ReserveChannels`/`Mix_PlayChannel` di OpenXcom, ne' War ne' Greed hanno posti numerati: un solo utilizzatore, e portarla qui avrebbe messo `Game::setVolume` in una libreria generica. Le uscite PCM (`GameHost.Win.PcmOutput`, `Tracker.WaveOut`) fanno un lavoro diverso (waveOut e thread, non mixing) e non hanno copie tra Xcom, War e Greed (tutti e tre usano quella di `GameHost`). Un resampler "unico" e' impossibile senza cambiare i campioni (vedi la tabella dei ricampionatori); sorgenti PCM/WAV: il parser WAV condiviso e' `DelphiDoom.Audio.WaveParser` (usato da Greed e da `Framework\Audio`), il decoder di War (`TWarWavDecoder`, porto del C con golden) differisce e resta suo.

## Verifica

- **Test**: `Tests\DelphiDoom.Tests.AudioMix` (87 a Win32 e a Win64: 62 della prima fetta, 17 del sintetizzatore, 8 del misuratore): sintetizzatore con la sua impronta del vecchio codice (vedi sopra), misuratore con un confronto bit per bit sulla somma dei quadrati; saturazione, lista di voci (anche con due thread), ricampionatori e voce senza segno **contro una copia fedele del vecchio codice** (`Tests\Source\DelphiDoom.Tests.AudioMix.Legacy*.pas`, estratta dal commit `b6fedafb`, scenari a seme fisso), canale stereo e voce a posizione vicina con valori calcolati a mano.
- **Parita' dei tre mixer interi** contro la copia del vecchio mixer, nei progetti di test di ogni gioco: `DelphiDoom.Tests.War.AudioMixParity` (60 semi x 80 passi: avvii, `PlayAt`, stop, viewport, volume, silenzio, buffer con campioni gia' dentro vicini ai limiti), `DelphiDoom.Tests.Greed.PcmMixerParity` (40 semi x 60 passi: WAV a 8/16 bit, 1/2 canali, 5 rate, tre rate del mixer, effetti, pan, volume, stop, musica; campioni e **tutte** le statistiche), `DelphiDoom.Tests.XcomEngine.MixerParity` (40 semi x 70 passi: `PlayWave`, `PlayChannel`, posizione, volumi, ambiente, tracce, pausa; byte, RMS, picco, canali). Le copie del vecchio codice sono `Tests\Source\DelphiDoom.Tests.{War,Greed,XcomEngine}.Legacy*.pas`: non si ritoccano.
- Nessun avvio dei giochi, nessun ascolto: la verifica a orecchio e' da fare.
