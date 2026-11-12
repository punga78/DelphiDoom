# Libs\Parity

Strumenti di parita' del motore (issue #185, fase 0 del piano `docs\PIANO_TUTTO_A_CLASSI.md`): dicono **dove** e **quando** il comportamento cambia, al bit.

Il testo di riferimento sta in [CLAUDE.md](CLAUDE.md); come si usano gli strumenti, con esempi, in [docs\PARITA_MOTORE.md](../../docs/PARITA_MOTORE.md).

## Contenuto

- Unit nella cartella: 15 (nome a punti `DelphiDoom.Parity.*`) e `ParityTool.dpr` (confronto e compressione dei log).
- Interfacce dichiarate: `IParityLog`, `IParityStateSink`, `IParitySwitch`, `IParityPilot`.
- Punto di creazione delle classi: `DelphiDoom.Parity.Factory`.
- Collegamento al motore: `Base\DelphiDoom.Engine.Parity.*` (adattatore sottile, un solo aggancio per hook).

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Parity`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).
- Script in `Tools\Verifica\185` (`Registra-Demo.ps1`, `Registra-Golden.ps1`, `Confronta-Golden.ps1`) e `Tools\Misura-Coppie.ps1`.

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
