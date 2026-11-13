# Libs\Scanner

Scanner dei testi degli script, preprocessore, valutatore di espressioni, AUTOLOAD.

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 31 (nome a punti `DelphiDoom.Scanner.*`); le 9 di `DelphiDoom.Scanner.Id*` sono il port di `idParser`, `idDict` e `idLangDict` di Doom 3 (issue #97), sopra `TIdLexer` di `Libs\IdLib\Text`.
- Interfacce dichiarate: `IAutoLoadFileSink`, `IAutoLoadLumps`, `IAutoLoadReader`, `IContextExpressionEvaluator`, `IContextFunctionRegistry`, `ICvarSetter`, `IExpressionVariables`, `IIdTokenSource`, `IPaletteGenerator`.

## id Tech 4 (issue #97)

- `TIdParser` (preprocessore C: `#define` con parametri, `#`, `##`, `#if`/`#elif` con espressioni, `#include`, `#eval`, `$evalint`), `TIdParserEvaluator`, `TIdParserDefine`, `TIdParserGlobalDefines` (niente globali: la lista dei define globali si passa al costruttore), `TIdDict`, `TIdLangDict`, `TIdCNumbers`. Licenza GPL v3 con i termini di Doom 3 (intestazione di ogni unit). Non hanno chiamanti nel motore.
- Parita' col vero idLib: `Tests\Data\IdParser` (120 casi, 888 righe di risposte del C++ compilato con `bcc32c`), vedi il [README dei dati](../../Tests/Data/IdParser/README.md).
- Differenze dall'originale, difetti del C++ e cosa resta della issue: [CLAUDE.md](CLAUDE.md), paragrafo "Parser, Dict e LangDict di id Tech 4".

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Scanner`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
