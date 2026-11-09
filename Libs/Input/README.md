# Libs\Input

Tastiera, mouse e joystick: dispositivi, poller e mappa dei tasti.

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 8 (nome a punti `DelphiDoom.Input.*`).
- Interfacce dichiarate: `ICursorSystem`, `IInputEventSink`, `IInputGate`, `IInputPoller`, `IJoystickDevice`, `IJoystickSystem`, `IKeyMap`, `IKeyboardDevice`.
- Punto di creazione delle classi: `DelphiDoom.Input.Factory`.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Input`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
