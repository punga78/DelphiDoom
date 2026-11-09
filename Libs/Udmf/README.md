# Libs\Udmf

Conversione di una mappa UDMF (TEXTMAP) nei record del motore.

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 32 (nome a punti `DelphiDoom.Udmf.*`).
- Interfacce dichiarate: `IUdmfConvertedMap`, `IUdmfConverter`, `IUdmfFakeContrast`, `IUdmfLineFormat`, `IUdmfLineSpecialTranslator`, `IUdmfMapPartApplier`, `IUdmfProfile`, `IUdmfSectorFormat`.
- Punto di creazione delle classi: `DelphiDoom.Udmf.Apply.Factory`, `DelphiDoom.Udmf.Factory`.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Udmf`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
