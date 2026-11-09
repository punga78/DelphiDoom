# Libs\Endoom

Schermo di testo di fine gioco (ENDOOM/ENDTEXT/ENDSTRF) e modello modificabile dell'editor.

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 21 (nome a punti `DelphiDoom.Endoom.*`).
- Interfacce dichiarate: `IEndoomFontSource`, `IEndoomRenderer`, `IEndoomScreen`, `IEndoomScreenImage`, `IEndoomSession`, `IEndoomTextArtConverter`, `IEndoomTextArtMethod`.
- Punto di creazione delle classi: `DelphiDoom.Endoom.EditorFactory`, `DelphiDoom.Endoom.Factory`, `DelphiDoom.Endoom.TextArt.Factory`.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Endoom`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
