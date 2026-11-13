# Libs\Audio

Effetti sonori (canali, voci, dispositivo) e musica (backend e player) del motore.

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 26 (nome a punti `DelphiDoom.Audio.*`; 16 sono il suono di Quake III, `DelphiDoom.Audio.Q3.*`).
- Interfacce dichiarate: `IAudioVoice`, `IExternalMusicCache`, `IExternalMusicClip`, `IExternalMusicSource`, `IMusicBackend`, `IMusicPlayer`, `ISfxPlayer`, `ISfxSampleSource`; per Quake III `IQ3SoundClock`, `IQ3SoundDevice`, `IQ3SoundFileSource`.
- Punto di creazione delle classi: `DelphiDoom.Audio.Factory` (motore di Doom) e `DelphiDoom.Audio.Q3.Factory` (`TQ3SoundSystemFactory`, suono di Quake III).

## Suono di Quake III (issue #128, prima fetta)

Strategia di `snd_dma.c`, `snd_mix.c` e `snd_mem.c` a classi, senza chiamanti nel motore: canali e scelta del canale (`TQ3ChannelPool`), spazializzazione (`TQ3Listener`: volume e pan da posizione, distanza e attenuazione), suoni in loop con doppler (`TQ3LoopSounds`), flusso grezzo per musica e video RoQ (`TQ3RawStream`, `TQ3RoqAudioSink` verso `Libs\Cinematic`), mixaggio e trasferimento nel buffer del dispositivo (`TQ3Mixer`, `TQ3Scheduler`), ricampionamento (`TQ3Resampler`) e caricamento dei WAV con `Libs\Sound` (`TQ3SoundLoader`). Tempo, dispositivo e file sono iniettati (`IQ3SoundClock`, `IQ3SoundDevice`, `IQ3SoundFileSource`). Parita' sul C vero compilato con gcc (`Tools\Verifica\128`, `Tests\Data\Audio\Q3`); cosa e' portato, cosa no, difetti conservati e differenze volute: [CLAUDE.md](CLAUDE.md), sezione "Suono di Quake III".

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Audio` (222 test). Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
