# Libs\XcomAudio - musica ed effetti di OpenXcom

Issue #176. Il mixer (i canali di SDL_mixer), il player della musica (la parte musicale di `Mod`) e le tracce di OpenXcom a classi, senza SDL. **I decoder non sono qui**: i file di suono si leggono con `Libs\Sound` (WAV, OGG Vorbis, FLAC e gli altri), gli MP3 con `Libs\Mp3`, i moduli con il tracker di `Libs\Mikmod`, i MIDI con il lettore di `Libs\Midi`/`Libs\M2m`, l'Adlib con `Libs\Opl`; qui ci sono solo gli adattatori verso il mixer. Il dispositivo vero e' `TXcomWinPcmOutput` (waveOut) in `OpenXcom\`; in test si usa `TXcomManualPcmOutput`, che si fa chiedere i campioni da chi lo prova.

| Unit | Ruolo |
|---|---|
| `DelphiDoom.XcomAudio.Intf` | `IXcomMusicTrack`, `IXcomMusicSink`, `IXcomMusicSettings`, `IXcomAdlibSongs`, `IXcomMixerMeter`, `IXcomSampleDecoder`, `IXcomChannelMixer`, `IXcomMusicFormatLoader`, `IXcomMusicPreparation`, `IXcomMidiSynth` |
| `DelphiDoom.XcomAudio.Types` | formati di musica, costanti, eccezione |
| `DelphiDoom.XcomAudio.SndfileDecoder` | `IXcomSampleDecoder` su `ISndfile` (`Libs\Sound`): WAV, OGG, FLAC, AIFF... a 16 bit stereo |
| `DelphiDoom.XcomAudio.Mp3Decoder` | `IXcomSampleDecoder` su `IMp3` (`Libs\Mp3`) |
| `DelphiDoom.XcomAudio.Resampler` | cambio di rate (campione piu' vicino per i rapporti di potenza di due, come SDL 1.2; lineare per gli altri) |
| `DelphiDoom.XcomAudio.Mixer` | 16 canali, canali scelti, loop, posizione, volumi, musica agganciata, statistiche |
| `DelphiDoom.XcomAudio.AdlibTrack` | brano Adlib |
| `DelphiDoom.XcomAudio.DigitalTrack` | brano digitale (FLAC, OGG, MP3, WAV): decodificato a `Prepare`, liberato a `Stop` |
| `DelphiDoom.XcomAudio.TrackerTrack` | brano MOD/S3M/XM/IT sul sequencer di `Libs\Mikmod`, senza dispositivo |
| `DelphiDoom.XcomAudio.GmConverter` | una voce di `GM.CAT` come file MIDI (`GMCatFile::loadMIDI`) |
| `DelphiDoom.XcomAudio.MidiSynth` | sintetizzatore software semplice (32 voci, 4 forme d'onda, rumore per la batteria) |
| `DelphiDoom.XcomAudio.MidiTrack` | brano MIDI: `TMidiSequenceLoader` di `Libs\Midi` e il sintetizzatore |
| `DelphiDoom.XcomAudio.AdlibMusicLoader` / `.DigitalMusicLoader` / `.TrackerMusicLoader` / `.MidiMusicLoader` | un formato di musica ciascuno (`IXcomMusicFormatLoader`) |
| `DelphiDoom.XcomAudio.MusicPlayer` | regole `musics:`, ordine dei formati, `playMusic` |
| `DelphiDoom.XcomAudio.CatSongs` | `ADLIB.CAT` e `AINTRO.CAT` |
| `DelphiDoom.XcomAudio.OptionsSettings` | `Mute`, `musicAlwaysLoop`, `preferredMusic` dalle opzioni |
| `DelphiDoom.XcomAudio.ManualOutput` | uscita per i test |
| `DelphiDoom.XcomAudio.Factory` | unico punto che conosce le classi: `CreateAudio`, `CreateSoundDecoder`, `CreateMp3Decoder`, `CreateLoaders` |

Dettagli, trappole e cosa non e' portato: `CLAUDE.md`. Licenza: derivato da OpenXcom (GPL v3 o successiva), la decide l'utente.
