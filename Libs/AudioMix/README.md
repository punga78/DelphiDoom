# Libs\AudioMix

Mixing audio software comune a `XcomAudio`, `War` e `Greed` (issue #228): lista di voci con lucchetto, strategie di voce e di ricampionamento su un solo contratto, somma con saturazione a 16 bit. Non e' per Doom (`Libs\Audio` usa DirectSound).

Il testo di riferimento (contratto, confronto riga per riga dei tre mixer, cosa e' migrato e cosa no) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 9 (nome a punti `DelphiDoom.AudioMix.*`): `Types`, `Intf`, `Saturation`, `VoiceList`, `FixedPointResampler`, `FramePositionResampler`, `UnsignedMonoVoice`, `StereoChannelVoice`, `NearestRateVoice`.
- Interfacce dichiarate: `IPcmVoice`, `IPcmResampler`.
- Nessuna dipendenza da `Base\`, dai giochi o da altre librerie: solo la RTL.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.AudioMix`. Si compila con `Tools\build.bat DelphiDoom.Tests.AudioMix` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)). La parita' dei tre mixer interi sta nei progetti di test di `War`, `Greed` e `XcomEngine`.

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
- Usata da: `Libs\XcomAudio`, `Libs\War`, `Libs\Greed`.
