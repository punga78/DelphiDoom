# Libs\Flic

Decoder dei fotogrammi FLI/FLC (Autodesk Animator e Animator Pro) senza schermo, orologio né audio: dai byte del file i pixel a 8 bit di ogni fotogramma, la palette, i ritardi e i pezzi audio dei filmati di TFTD. Strato Formati del framework (issue #229, indice #227): nessuna dipendenza da altre librerie.

Il testo di riferimento (confronto con il decoder di Greed, difetti conservati, cosa non è spostato) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 2 (`DelphiDoom.Flic.Types`, `DelphiDoom.Flic.FrameDecoder`).
- Classe: `TFlicFrameDecoder` (port del decoder di `FlcPlayer` di OpenXcom, GPL v3 o successiva: licenza in `Libs\XcomFormats\README.md`).
- Chi la usa: `TXcomFlcDecoder` (`Libs\XcomFormats`, adattatore con la stessa API di prima) e `TFlicDecoder` (`Libs\Cinematic`).

## Prova

- `Tests\DelphiDoom.Tests.Flic` (`Tools\build.bat Tests\DelphiDoom.Tests.Flic`): parità con una copia fedele del vecchio decoder di XcomFormats su file costruiti, su ogni troncamento e su copie mutate; nessun dato di gioco.
- Altre prove che passano dal decoder: `DelphiDoom.Tests.XcomEngine`, `DelphiDoom.Tests.Cinematic`; il confronto con `TGreedFliDecoder` è in `DelphiDoom.Tests.Greed` (`FliVsFlic`).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
