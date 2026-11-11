# Libs\XcomAudio - musica ed effetti di OpenXcom

Issue #176. Il mixer (i canali di SDL_mixer), il player della musica (la parte musicale di `Mod`) e le tracce (Adlib di `Libs\Opl`, WAV) di OpenXcom a classi, senza SDL. Il dispositivo vero e' `TXcomWinPcmOutput` (waveOut) in `OpenXcom\`; in test si usa `TXcomManualPcmOutput`, che si fa chiedere i campioni da chi lo prova.

| Unit | Ruolo |
|---|---|
| `DelphiDoom.XcomAudio.Intf` | `IXcomMusicTrack`, `IXcomMusicSink`, `IXcomMusicSettings`, `IXcomAdlibSongs`, `IXcomMixerMeter` |
| `DelphiDoom.XcomAudio.Types` | formati di musica, costanti, eccezione |
| `DelphiDoom.XcomAudio.WaveDecoder` | WAV PCM a 16 bit stereo al rate del mixer |
| `DelphiDoom.XcomAudio.Mixer` | canali degli effetti, musica agganciata, volumi, statistiche |
| `DelphiDoom.XcomAudio.AdlibTrack` / `.WavTrack` | i brani |
| `DelphiDoom.XcomAudio.MusicPlayer` | regole `musics:`, scelta del formato, `playMusic` |
| `DelphiDoom.XcomAudio.CatSongs` | `ADLIB.CAT` e `AINTRO.CAT` |
| `DelphiDoom.XcomAudio.OptionsSettings` | `Mute`, `musicAlwaysLoop`, `preferredMusic` dalle opzioni |
| `DelphiDoom.XcomAudio.ManualOutput` | uscita per i test |
| `DelphiDoom.XcomAudio.Factory` | `CreateAudio`: mixer, player della musica, uscita aperta |

Dettagli, trappole e cosa non e' portato: `CLAUDE.md`. Licenza: derivato da OpenXcom (GPL v3 o successiva), la decide l'utente.
