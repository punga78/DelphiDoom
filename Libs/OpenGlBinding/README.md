# Libs\OpenGlBinding

Binding OpenGL e registratore delle chiamate GL, senza alcuna dipendenza dal motore di Doom (issue #220: separati da `Libs\OpenGl`, che resta il renderer di id Tech 1). Strato `L3` (piattaforma) in `Libs\Strati.psd1`.

| Contenuto | Ruolo |
|---|---|
| `dglOpenGL.pas` | binding OpenGL di terzi (Mike Lischke, Dominique Louis e altri), con la sua licenza nell'intestazione. Non si riformatta e non si modifica. Lo usano `Libs\GameHost` (finestra e dispositivi video GL dei giochi fuori da Doom, OpenXcom) e il renderer `Libs\OpenGl\Legacy`. |
| `Recorder\` | il registratore delle chiamate GL (criterio di parita' del renderer OpenGL): [README](Recorder/README.md), [CLAUDE.md](Recorder/CLAUDE.md). Dipende solo da `dglOpenGL`. |

Regole: le unit non hanno cambiato nome (`dglOpenGL`, `DelphiDoom.OpenGl.Recorder.*`), cambia solo la cartella; chi le usa le cita con `..\Libs\OpenGlBinding\dglOpenGL.pas` (i `GL*32.dpr`, `Tests\DelphiDoom.Tests.OpenGl.dpr`) o la ha nel `DCC_UnitSearchPath` (`Xcom32`, `Tests\DelphiDoom.Tests.XcomTour`). Uno strato `L3` non puo' usare unit di `Base`, dei giochi o di `Libs\OpenGl`: `Tools\build.bat strati` lo controlla.