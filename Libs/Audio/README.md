# Libs\Audio

Effetti sonori (canali, voci, dispositivo) e musica (backend e player) del motore.

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 13 (nome a punti `DelphiDoom.Audio.*`).
- Interfacce dichiarate: `IAudioVoice`, `IExternalMusicCache`, `IExternalMusicClip`, `IExternalMusicSource`, `IMusicBackend`, `IMusicPlayer`, `ISfxPlayer`, `ISfxSampleSource`.
- Punto di creazione delle classi: `DelphiDoom.Audio.Factory`.
- Preset di riverbero EFX (`DelphiDoom.Audio.Efx.*`: `TEfxEffectsFile`, `TEfxReverbProperties`) e intestazione WAVE come la legge la cache dei suoni di Doom 3 (`TWaveHeaderReader`): issue #112, senza chiamanti nel motore, parita' col vero C++ (`Tests\Data\Audio`). Vedi CLAUDE.md.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Audio`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
