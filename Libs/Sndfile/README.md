# Libs\Sndfile

Contratto `ISndfile` e provider che usa il motore di `LibsSound`.

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 4 (nome a punti `DelphiDoom.Sndfile.*`).
- Interfacce dichiarate: `ISndfile`, `ISoundFile`.
- Punto di creazione delle classi: `DelphiDoom.Sndfile.Provider`.
- Progetti nella cartella: `DDSndfile`.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Sndfile`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).

- Direzione della dipendenza (issue #222): `Libs\Sound` usa `Libs\Sndfile`, mai il contrario. L'engine predefinito del provider lo da' un `ISndfileFactory` (`DelphiDoom.Sndfile.Factory.Intf`) registrato da `DelphiDoom.Sound.EngineFactory`; senza fabbrica `TSndfileProvider.Client` solleva `ESndfileException` (se non si e' chiamato `Use`). Controllo: `Tools\Verifica\222\Controlla-Cicli.ps1`.
