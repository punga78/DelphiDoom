# Libs\Nodes

Lettura dei nodi di una mappa (nodi GL, GWA di glBSP, nodi originali) e WAD per glBSP.

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 16 (nome a punti `DelphiDoom.Nodes.*`).
- Interfacce dichiarate: `INodesGlDetector`, `INodesGlMapFinder`, `INodesGlbspInputBuilder`, `INodesGwa`, `INodesLumpSource`.
- Punto di creazione delle classi: `DelphiDoom.Nodes.Factory`.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Nodes`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
