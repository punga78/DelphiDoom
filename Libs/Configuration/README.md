# Libs\Configuration

Formato del file `.ini` del motore (lettura e scrittura) e tabella delle impostazioni a classi (righe, tabella, lettura, scrittura, forzatura, reset; issue #185 fetta 1c).

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 10 (nome a punti `DelphiDoom.Configuration.*`).
- Interfacce dichiarate: `IConfigurationDocument`, `IConfigurationFormat`, `IConfigurationWriter`, `IConfigurationValueAccess`, `IConfigurationItem`, `IConfigurationTable`, `IConfigurationResetSink`, `IConfigurationTableStore`.
- Punto di creazione delle classi: `DelphiDoom.Configuration.Factory`.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Configuration`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
