# Libs\Threading

Thread di lavoro e pool del motore.

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 7 (nome a punti `DelphiDoom.Threading.*`).
- Interfacce dichiarate: `IWorkerPool`, `IWorkerPoolFactory`, `IWorkerThread`, `IWorkerThreadFactory`.
- Punto di creazione delle classi: `DelphiDoom.Threading.Factory`, `DelphiDoom.Threading.PoolFactory`, `DelphiDoom.Threading.ThreadFactory`.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Threading`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
