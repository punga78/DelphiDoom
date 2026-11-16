# IdTech1\OpenGl (issue #177)

> **Divisione (issue #220):** il binding (`dglOpenGL.pas`) e il registratore di chiamate stanno ora in [`Framework\OpenGlBinding`](../../Framework/OpenGlBinding/README.md) (strato L3, senza dipendenze dal motore); qui resta il renderer di id Tech 1 (`Legacy\`, modulo `IdTech1`). I nomi delle unit non sono cambiati.

> Note per Claude e paragrafi di dettaglio (issue #178): [CLAUDE.md](CLAUDE.md).

Qui sta tutto cio' che prima era nella cartella `OPENGL\` della radice (che non esiste piu). Il piano per svuotarla fetta per fetta e `docs\OPENGL_PIANO.md`.

| Cartella | Contenuto |
|---|---|
| `Legacy\` | le altre unit del renderer di Doom (vedi sotto). |
| (fuori da qui) | **`Framework\OpenGlBinding`** (issue #220): `dglOpenGL.pas`, il binding OpenGL di terzi (strato L3, usato anche da `Framework\GameHost`), e `Recorder\`, il registratore delle chiamate GL. Non dipendono dal motore di Doom. |
| `Legacy\` | le altre 26 unit (`gl_*.pas`, `mdl_*.pas`, `DelphiDoom.Engine.Models.Renderer.pas`): codice procedurale del renderer OpenGL, con stato globale. Il nome dice che si svuotera: ogni fetta del piano sposta le sue unit nella libreria nuova. |

Regole:

- Le unit (tranne gl_voxels.pas, fetta 2: l'ottimizzatore di mesh e in IdTech1\Voxel) non hanno cambiato nome ne contenuto: i quattro `GL*32.dpr` le citano con `..\IdTech1\OpenGl\Legacy\...` e `..\Framework\OpenGlBinding\dglOpenGL.pas`.
- Le chiamate GL restano chiamate dirette a `dglOpenGL`; le interfacce stanno a granularita di fotogramma, mai per vertice o per chiamata.
- Le unit di `Legacy` seguono la regola del codice storico (niente rinomina ne riformattazione in massa).

## Recorder: il registratore delle chiamate GL (fetta 1)

E il criterio di parita principale del piano (`docs\OPENGL_PIANO.md`, sezione 5): ogni fetta che sposta codice di disegno deve dare, con lo stesso stato di gioco, **lo stesso flusso di chiamate GL**. Sta in `Framework\OpenGlBinding\Recorder` (spostato da `IdTech1\OpenGl\Recorder` con la #220) e **non cambia nulla nelle build normali**: e compilato nei giochi solo con `GLRECORD` (lo fanno gli script di `Tools\Verifica\opengl`); `dglOpenGL.pas` e il motore non sono toccati.

| Unit | Ruolo |
|---|---|
| `Intf` | `IGlCallRecorder` (`BeginFrame`, `EndFrame(etichetta)`, `DiscardFrame`, `Call`, `Stream`, `FrameCount`, `InFrame`) e `IGlHookTable` (nome, indirizzo della variabile, thunk, originale) |
| `CallRecorder` | `TGlCallRecorder`: tiene in memoria le righe del fotogramma aperto e, alla chiusura, le scrive sullo stream seguite da `FRAME <etichetta> calls=<n> sum=<FNV-1a 64>` |
| `Encoder` | `TGlCallEncoder`: il testo di una chiamata (vedi sotto) |
| `ClientArrays`, `PixelFormats` | dimensioni di pixel e array client, per sapere quanti byte ha un puntatore |
| `Fnv` | FNV-1a a 64 bit |
| `HookTable`, `Installer` | `TGlHookInstaller` mette i thunk nelle variabili del binding (una che il driver non ha, cioe nil, e saltata ed elencata in `Missing`) e le rimette |
| `Thunks` | **generata** da `Genera-Thunks.ps1`: 81 thunk, uno per ogni funzione `gl*`/`glu*` che il renderer usa e che `dglOpenGL.pas` dichiara come variabile di procedura; si rigenera se il renderer ne usa di nuove. Le funzioni `wgl*` (contesto) non sono registrate |
| `Session`, `Hook` | l'unico globale (un thunk non puo ricevere un oggetto) e l'interruttore `GLRECORD` (`GlRecorderInstall`, `GlRecorderUninstall`) |

**Formato.** Una riga per chiamata: `nome(argomento,...)`. Interi in decimale, `GLenum` come `$XXXX`, `Single` come `#` e i suoi 32 bit, `Double` come `#` e i suoi 64 bit; un puntatore **non e mai scritto come indirizzo** (cambia a ogni esecuzione): `nil`, `ptr` (non nil, lunghezza non nota) o `h:<FNV-1a>/<byte>` (il contenuto, quando la lunghezza si ricava dagli altri argomenti). Il fotogramma si chiude con la riga `FRAME`.

**Cosa e coperto (contenuto con impronta):** `glColor4fv`, `glTexCoord2fv`, `glVertex3fv`, `glMultMatrixf/d`, `glFogfv` (4 float per `GL_FOG_COLOR`, 1 per gli altri), `glTexGenfv`, `glDeleteTextures`; i pixel di `glTexImage2D/3D`, `glTexSubImage2D/3D` e `gluBuild2DMipmaps` (righe senza padding, con l'allineamento di `glPixelStorei`; solo formati e tipi di OpenGL 1.1: RGB, RGBA, BGR, BGRA, luminanza, indice, con tipi byte, short, int, float, double); la palette di `glColorTableEXT`; gli elementi che `glDrawArrays` disegna dagli array di `glVertexPointer` e `glTexCoordPointer` (seguendo `glEnable/DisableClientState`). **Non coperto:** i puntatori di uscita (`glGet*`, `glGenTextures`, `glReadPixels`: solo `nil`/`ptr`), i pixel con tipi impacchettati o con `GL_UNPACK_ROW_LENGTH`/skip/altezza immagine diversi da 0 (solo `ptr`), i valori restituiti dalle funzioni, `glGetString`. **Limite:** i nomi delle texture e delle liste sono quelli del driver; se una fetta cambia l'ordine di creazione, il flusso cambia (e giusto che si veda).

**Harness** (`Tools\Verifica\opengl`): `HarnessGl.pas` con `-glrecord <n>` (n tic consecutivi, il primo fotogramma di ogni tic, a partire da `-glrecordstart` = 35) scrive `glrecord_<MAPPA>.txt` ed esce con `Halt(0)`; `hook-gl.patch` lo aggancia ai quattro `GL*32.dpr`; `Compila.ps1 -Which Old|New` costruisce gli eseguibili, `Confronta.ps1 -Game GLDoom|GLHeretic|GLHexen|GLStrife` li esegue (vecchio due volte per il rumore, poi il nuovo) e stampa UGUALE o DIVERSO. Test: `Tests\DelphiDoom.Tests.OpenGl` (185 con le fette del renderer).
## Librerie nate da `Legacy` (issue #177)

| Libreria | Fetta | Contenuto |
|---|---|---|
| `IdTech1\Voxel` (`DelphiDoom.Voxel.Mesh*`) | 2 | ottimizzatore di mesh dei voxel, senza OpenGL |
| `Framework\Models` (`DelphiDoom.Models.Definition.*`) | 3 | parser del lump MODELDEF (modelli, texture, stati) verso un sink |
| `IdTech1\GlTexture` | 5 | buffer delle texture: patch, flat, ripple, trasparenza, palette (classi statiche a freddo) |
| `IdTech1\GlLevel` | 4 (parte pura) | carving dei flat dal BSP (`IGlFlatCarver`) con mondo e sink iniettati |

Fetta 10: il disegno della scena (muri, flat, sprite e l'ordine delle serie) e' fatto da `Legacy\DelphiDoom.Engine.GlScene.WallPainter`, `...FlatPainter`, `...SpritePainter` e `...SceneDrawer`, classi chiamate direttamente (nessuna interfaccia per elemento) con le stesse chiamate GL di prima.

Fetta 11: il disegno dei modelli (`gld_DrawModels`) e' `Legacy\DelphiDoom.Engine.GlScene.ModelPainter`, classe chiamata direttamente dallo sprite painter. Si prova con `Tests\Data\ModelsGl` (PK3 sintetici con un cubo MD2 legato a ogni stato del gioco) e `Confronta.ps1 -Models`.
Fetta 12: il disegno dei voxel (`gld_DrawVoxels`) e' `Legacy\DelphiDoom.Engine.GlScene.VoxelPainter`, classe chiamata direttamente dallo sprite painter. Si prova con `Tests\Data\VoxelsGl` (PK3 sintetici con un voxel legato a ogni stato del gioco) e `Confronta.ps1 -Voxels`.
Fetta 13: la lightmap dinamica (la texture 3D delle luci, `gld_CalculateLightmapSTD`) e' `Legacy\DelphiDoom.Engine.GlLightmap.Calculator`; `gl_lightmaps` e' la facciata. Si prova con `Confronta.ps1 -Lights` (e `-Voxels` insieme).

Le unit del motore che le usano (`DelphiDoom.Engine.Models.Definition*`, `DelphiDoom.Engine.GlLevel.*`) stanno in `Legacy\` perche' leggono i globali del renderer. Dettagli e verifiche di ogni fetta in `CLAUDE.md`.
