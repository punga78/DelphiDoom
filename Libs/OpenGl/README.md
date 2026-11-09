# Libs\OpenGl (issue #177)

Qui sta tutto cio' che prima era nella cartella `OPENGL\` della radice (che non esiste piu). Il piano per svuotarla fetta per fetta e `docs\OPENGL_PIANO.md`.

| Cartella | Contenuto |
|---|---|
| `Binding\` | `dglOpenGL.pas`: binding OpenGL di terzi (Mike Lischke, Dominique Louis e altri), con la sua licenza nell'intestazione. Non si riformatta e non si modifica. |
| `Legacy\` | le altre 26 unit (`gl_*.pas`, `mdl_*.pas`, `DelphiDoom.Engine.Models.Renderer.pas`): codice procedurale del renderer OpenGL, con stato globale. Il nome dice che si svuotera: ogni fetta del piano sposta le sue unit nella libreria nuova. |

Regole:

- Le unit non hanno cambiato nome ne contenuto: i quattro `GL*32.dpr` le citano con `..\Libs\OpenGl\Legacy\...` e `..\Libs\OpenGl\Binding\dglOpenGL.pas`.
- Le chiamate GL restano chiamate dirette a `dglOpenGL`; le interfacce stanno a granularita di fotogramma, mai per vertice o per chiamata.
- Le unit di `Legacy` seguono la regola del codice storico (niente rinomina ne riformattazione in massa).
