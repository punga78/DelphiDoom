# Warcraft32: l'audio (issue #200 / #203, ondata 7)

Diagnosi dell'audio mancante e musica sul MIDI di Windows. **Nessun gioco e nessun dispositivo audio o MIDI sono stati avviati**
per scrivere questo testo: la diagnosi e' fatta leggendo il codice, le correzioni sono provate con test e finti. L'ascolto lo fa
l'utente (comandi in fondo).

## Il percorso del suono

```
scena (Audio.Play id) -> TWarSceneAudio -> effetto: TWarSoundMixer (voci a 8 bit mono, 44100 Hz)
                                         -> brano: TWarMusicPlayer -> IWarMusicSynth
TWarPcmSource.Render (thread di waveOut, blocchi da 1024 fotogrammi) = musica + effetti, mono -> stereo 16 bit
TWarHostAudio.Open -> TGameHostWinPcmOutput (waveOut, 4 buffer da 1024 fotogrammi, un thread li riempie)
```

Il composition root (`DelphiDoom.War.Composition`) apre l'uscita **solo** nella strada con la finestra e senza `-nosound`.

## Cosa e' stato controllato (letto, non trovato difettoso)

- **Valori di partenza**: `-nosound` e' falso, `Warcraft32.ini` senza file da' volumi 100 e interruttori accesi, il mixer parte con
  volume 1 e `FEnabled` vero, `FSilenced` falso. `TWarGameSettings.AudioEnabled` parte **falso** ma la prima scena lo accende
  nello stesso `UpdateGame` (`TWarSceneManager`), e `TWarSceneAudio.Synchronize` gira dopo ogni fotogramma.
- **Ordine di apertura**: `CreateAudio` (libreria, mixer, player) prima della finestra, poi `TWarHostAudio.Open` con la sorgente
  gia' fatta; la sorgente e' tenuta da `TWarHostAudio` (l'uscita ha un riferimento debole) fino a `Close`.
- **Formato**: `TWarAudioLibrary.GetSound` ricampiona a 44100 Hz e la voce (`TPcmUnsignedMonoVoice`) vuole 8 bit senza segno, mono:
  e' quello che i decoder VOC e WAV danno (provato dai golden contro il C). waveOut e' aperto a 44100 Hz, 16 bit, stereo.
- **Rigioco del salvataggio**: `Muted` e `SetSilenced(True)` solo durante il rigioco e tolti in un `finally`
  (`TWarSession.Load`); il mixer e' silenziato di nuovo ogni fotogramma da `Synchronize` secondo `AudioEnabled`.
- **Cause che dall'esterno sembrano un difetto e non lo sono**: un `Warcraft32.ini` con `sound=false` o `music=false` (il file
  si **riscrive a ogni chiusura** con i valori dei trucchi `Sound`/`Music`), `-nosound`, `-headless`, nessuna scheda audio
  (messaggio `No sound device`), volumi a 0 nel menu F10.

## Difetti trovati e corretti

1. **La musica era muta per costruzione**: il sintetizzatore era `TWarSilentMusicSynth` (il SoundFont del remake non ha licenza
   dichiarata). Ora i brani vanno al MIDI di Windows (vedi sotto).
2. **Un gioco caricato non aveva musica**: il brano parte una volta all'ingresso della scena e durante il rigioco
   (`Muted`) la richiesta si buttava. Ora `TWarSceneAudio` ricorda l'**ultima** richiesta sul brano (suona o ferma) e la fa quando
   `Muted` torna falso (gli effetti restano scartati, come prima). Test `DovrebbeSuonareDopoIlRigiocoLUltimoBranoChiestoDaMuto`,
   `DovrebbeFermareDopoIlRigiocoSeLUltimaRichiestaEraUnArresto`, `DovrebbeDimenticareLeRichiesteDelRigiocoPrecedente`.
3. **Note appese**: con la musica spenta dal menu (o a volume 0) il player non avanzava ma **non spegneva le note che suonavano**;
   con un sintetizzatore a campioni non si sentiva (smetteva di produrne), con un dispositivo MIDI la nota restava accesa. Ora le
   note si spengono una volta sola (`FNotesSounding`). Test `DovrebbeFermareLeNoteCheSuonanoQuandoLaMusicaSiDisabilita`,
   `DovrebbeFermareLeNoteCheSuonanoUnaSolaVoltaConIlVolumeAZero`.
4. **La dissolvenza non arriva a un dispositivo**: `TWarMusicFade` scala i campioni, un dispositivo MIDI non ne produce.
   Nuova interfaccia `IWarMusicDevice` (`SetGain`, `ResetChannels`, in `Music.Intf`): il player dice il guadagno all'inizio di ogni
   blocco e il sintetizzatore lo applica al controller 7 dei canali. Test `DovrebbeDareAlDispositivoIlGuadagnoDellaDissolvenza`,
   `DovrebbeRimettereICanaliAPostoAOgniCanzone`.

Nota onesta: la lettura **non ha trovato una causa certa** per il silenzio degli *effetti* (nessun errore nella catena
mixer -> sorgente -> waveOut, e i campioni sono identici al C). Se all'ascolto gli effetti mancano, `-audiostats` dice dove si
ferma la catena: `Sounds started` = 0 (le scene non chiedono suoni), `sounds that could not be played` > 0 (decodifica), `Buffers
played by the sound device` = 0 (il dispositivo non consuma) oppure tutto positivo (allora volume, `.ini` o uscita di Windows).

## Musica sul MIDI di Windows

I brani di `DATA.WAR` sono record **XMID** (XMI): `TWarAudioLibrary.GetMusic` li converte con `TXmiConverter` (`Framework\Xmi`) in un
file MIDI standard, `TWarMusicTimeline` li legge con il sequencer di `Framework\Midi` (senza dispositivo) e `TWarMusicPlayer`
(tempo, ciclo, dissolvenza, volume) manda ogni evento al sintetizzatore quando e' dovuto. Nessuna logica nuova di conversione o di
sequenza.

| Pezzo | Dove | Ruolo |
|---|---|---|
| `IMidiShortOutput` | `Framework\Midi\DelphiDoom.Midi.Output.Intf` | un messaggio MIDI per volta, subito (Open, Close, Send) |
| `TMidiWinShortOutput` | `Framework\Midi\DelphiDoom.Midi.Win.ShortOutput` | `midiOutOpen` con `MIDI_MAPPER` ("Microsoft GS Wavetable Synth" se non si e' scelto altro), `midiOutShortMsg`, `midiOutReset` in `Close` |
| `TWarMidiMusicSynth` | `Games\War\DelphiDoom.War.Music.MidiSynth` | `IWarMusicSynth` + `IWarMusicDevice`: eventi -> messaggi, dissolvenza sul controller 7, `AllNotesOff` = CC 123 e 120 su 16 canali |
| `TWarMusicFactory.CreateMidiSynth/CreateWindowsMidiOutput` | `DelphiDoom.War.Music.Factory` | unico punto che conosce le classi concrete |
| `-music midi\|none` | `TWarAppOptions.Music`, `TWarAppOptionsParser` | scelta nel composition root (`CreateMusicSynth`), predefinito `midi` |

**Perche' non `midiStream`** (quello che usa Doom, `TEngineMidiStreamPlayer`): sta in `IdTech1\Base` (strato del motore, un gioco
di `Games\` non puo' usarlo) e tiene il proprio tempo; qui il tempo lo tiene il player (dissolvenza, volume, pausa nel cambio di
scena, `Muted` nel rigioco) e il dispositivo riceve solo gli eventi. Il sequencer di `Framework\Midi` e' lo stesso.

Il dispositivo si apre **solo** con la finestra, senza `-nosound` e senza `-script` (un'esecuzione `-headless` o uno script, cioe'
i test e i golden, non toccano mai il MIDI). Se `midiOutOpen` fallisce il programma lo dice (`No MIDI device`) e suona senza musica.
Alla chiusura il brano si ferma (`Stop(0)` = tutte le note spente) prima di chiudere il dispositivo.

**Limiti dichiarati**
- Gli eventi partono quando l'uscita PCM chiede un blocco (1024 fotogrammi = 23 ms, 4 buffer in coda): il tempo musicale e' quantizzato
  a 23 ms. Per un brano XMI e' udibile solo come lieve sfarfallio ritmico; se disturba si riduce `FRAMES_PER_BUFFER` o si passa a
  `midiStream` con un ponte per strati (non fatto). Ne segue che **`-nosound` toglie anche la musica** (non c'e' chi la fa avanzare).
- Il suono e' quello del sintetizzatore General MIDI di Windows (nessun SoundFont nel repository, nessun dato commerciale), non quello
  del remake: i timbri sono diversi. I brani sono scritti per l'AdLib/Roland MT-32 e GM li rende a modo suo.
- Il volume della musica scala la velocita' delle note che iniziano (come il C); la dissolvenza va sul controller 7: un brano che
  usa il 7 per i suoi crescendo lo rimanda scalato.
- La rimessa a posto dei canali a inizio brano e' un *reset all controllers* + volume 100 (default GM) + pitch bend al centro:
  la scelta del programma di ogni canale la fa il brano.
- Non provato: ascolto, `midiOutOpen` su una macchina senza dispositivo, la stessa prova a Win64 (compila e i test passano).

## Provare ad orecchio

```
bin\Win32\Release\War\Warcraft32.exe -data <cartella con DATA.WAR> -audiostats
bin\Win32\Release\War\Warcraft32.exe -data <cartella con DATA.WAR> -music none          (solo effetti)
bin\Win32\Release\War\Warcraft32.exe -data <cartella con DATA.WAR> -play human 1        (musica della mappa, clic sulle unita')
```

1. Menu principale: musica del titolo (MIDI GM). Il volume della musica e degli effetti e' nel menu F10 della mappa.
2. Mappa: clic su un contadino e clic destro sulla mappa (voci di conferma), colpi e crolli (effetti con posto: piu' lontani, piu'
   piano).
3. Dissolvenza: il passaggio tra mappa e menu ferma il brano; F9 (carica) deve **riportare la musica** del livello.
4. Se non si sente nulla: cancellare `Warcraft32.ini` accanto all'eseguibile (puo' avere `sound`/`music` spenti), controllare il
   mixer di Windows (il programma e' una voce a parte) e leggere le righe di `-audiostats` al termine.
