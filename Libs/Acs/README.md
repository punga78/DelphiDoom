# Libs\Acs

Compilatore ACS (ACC 1.10 di Raven) e interprete del bytecode BEHAVIOR di Hexen, a classi.

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 22 (nome a punti `DelphiDoom.Acs.*`).
- Interfacce dichiarate: `IAcsCompiler`, `IAcsHost`, `IAcsMachine`, `IAcsSourcePosition`, `IAcsSourceProvider`.
- Punto di creazione delle classi: `DelphiDoom.Acs.Factory`, `DelphiDoom.Acs.MemorySourceProvider`.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Acs`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
