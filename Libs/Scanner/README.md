# Libs\Scanner

Scanner dei testi degli script, preprocessore, valutatore di espressioni, AUTOLOAD.

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 20 (nome a punti `DelphiDoom.Scanner.*`).
- Interfacce dichiarate: `IAutoLoadFileSink`, `IAutoLoadLumps`, `IAutoLoadReader`, `IContextExpressionEvaluator`, `IContextFunctionRegistry`, `ICvarSetter`, `IExpressionVariables`, `IPaletteGenerator`.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Scanner`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
