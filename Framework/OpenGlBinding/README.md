# Framework\OpenGlBinding

Binding OpenGL e registratore delle chiamate GL, senza alcuna dipendenza dal motore di Doom (issue #220: separati da `IdTech1\OpenGl`, che resta il renderer di id Tech 1). Strato `L3` (piattaforma) in `docs\Strati.psd1`.

| Contenuto | Ruolo |
|---|---|
| `dglOpenGL.pas` | binding OpenGL di terzi (Mike Lischke, Dominique Louis e altri), con la sua licenza nell'intestazione. Non si riformatta e non si modifica. Lo usano `Framework\GameHost` (finestra e dispositivi video GL dei giochi fuori da Doom, OpenXcom) e il renderer `IdTech1\OpenGl\Legacy`. |
| `Recorder\` | il registratore delle chiamate GL (criterio di parita' del renderer OpenGL): [README](Recorder/README.md), [CLAUDE.md](Recorder/CLAUDE.md). Dipende solo da `dglOpenGL`. |

Regole: le unit non hanno cambiato nome (`dglOpenGL`, `DelphiDoom.OpenGl.Recorder.*`), cambia solo la cartella; chi le usa le cita con `..\Framework\OpenGlBinding\dglOpenGL.pas` (i `GL*32.dpr`, `Tests\DelphiDoom.Tests.OpenGl.dpr`) o la ha nel `DCC_UnitSearchPath` (`Xcom32`, `Tests\DelphiDoom.Tests.XcomTour`). Uno strato `L3` non puo' usare unit di `Base`, dei giochi o di `IdTech1\OpenGl`: `Tools\build.bat strati` lo controlla.