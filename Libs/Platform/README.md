# Libs\Platform

Servizi del sistema operativo: file, cartelle temporanee, informazioni su sistema, CPU ed eseguibile.

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 14 (nome a punti `DelphiDoom.Platform.*`).
- Interfacce dichiarate: `ICpuInfo`, `IDisplayDpi`, `IDriveInfo`, `IExecutableInfo`, `IFileStore`, `IOperatingSystemInfo`, `IOperatingSystemSource`, `IPlatformServices`.
- Punto di creazione delle classi: `DelphiDoom.Platform.Factory`.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Platform`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
