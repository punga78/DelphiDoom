# Framework\GameMath

Matematica di id Tech 1 separata da `Framework\MathCore` (issue #225, prima fetta): aritmetica in virgola fissa 16.16 (`TFixedMath`), angoli BAM e tabelle trigonometriche (`TTrigonometry`, `finesine`, `finetangent`, `tantoangle`, `fixedsine`), generatore casuale di Doom (`TGameRandom`, `IGameRandom`, `IEntropySource`), tabella hash dei nomi (`IStringHashTable`), vettori e bbox (`TVectorMath`, `TBoundingBoxMath`) e i pezzi del renderer (`TX87Double`, `TPixelBatch`).

Il testo di riferimento sta in [CLAUDE.md](CLAUDE.md). Le unit hanno ancora il nome `DelphiDoom.MathCore.*`: sono state spostate con `git mv`, non rinominate.

## Contenuto

- Unit nella cartella: 19. Punto di creazione delle classi: `DelphiDoom.MathCore.Factory` (`TMathCoreFactory`).
- Strato **L0** in `docs\Strati.psd1`; dipende da `Framework\MathCore` (`IntegerStack`, `SoftExtended`), non il contrario.

## Prova

- Progetto di test: `Tests\DelphiDoom.Tests.MathCore` (condiviso con `Framework\MathCore`, ha `..\Framework\GameMath` nel percorso). Si compila con `Tools\build.bat`.

## Legami

- [Framework\MathCore](../MathCore/README.md) per la parte generica; indice e regole generali nel [CLAUDE.md di radice](../../CLAUDE.md).
