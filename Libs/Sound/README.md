# Libs\Sound

Sostituto in Pascal di libsndfile, libvorbis e libflac.

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 48 (nome a punti `DelphiDoom.Sound.*`).
- Interfacce dichiarate: `ISoundFormat`.
- Punto di creazione delle classi: `DelphiDoom.Sound.Factory`.

## Prova

- Nessuna cartella `Tests\DelphiDoom.Tests.Sound*` dedicata: vedi [CLAUDE.md](CLAUDE.md) per come è provata.

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).

- Direzione della dipendenza (issue #222): `Sound` usa `Libs\Sndfile` (contratto `ISndfile` e `ISndfileFactory`); `Sndfile` non usa `Sound`. `DelphiDoom.Sound.EngineFactory` registra il motore in Pascal come predefinito del provider.
