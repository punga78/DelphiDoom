# IdTech4\Q3Render

Renderer di Quake III Arena **senza OpenGL**, fase R0 (issue #254; piano e censimento: `docs\Q3RENDER_CENSIMENTO.md`, numeri sui `.qvm` di OpenArena: `docs\QUAKE3_CENSIMENTO.md` par. 9). Quello che cgame e ui chiedono al renderer (`re.RegisterShader`, `re.RegisterModel`, `re.LoadWorld`, `re.ModelBounds`, `re.LerpTag`, `re.inPVS`) si serve da dati veri: immagini decodificate, script `.shader` letti, md3 letti, BSP in liste di superfici. Non disegna e non apre nessun contesto. Una classe per unit, `DelphiDoom.Q3Render.*`, dipendenze iniettate, `TQ3RenderFactory` come composition root. **Nessun chiamante nel motore.**

```pascal
LSystem := TQ3RenderFactory.CreateSystem(LFileSystem);                       // IGameFileSystem di Framework\Wad
LRenderer := TQ3RenderFactory.CreateHostRenderer(LRecordingRenderer, LSystem); // IQ3HostRenderer per IQ3HostClientServices
// dopo CG_INIT:
LSystem.Shaders.RegisteredCount; LSystem.Images.MissingNames; LSystem.Models.LoadedCount;
```

## Mappa C -> Pascal

| C (`renderer\`) | Pascal | Note |
|---|---|---|
| `LoadTGA` (`tr_image.c`) | `TQ3TgaReader` (`Image.TgaReader`) | tipi 2, 3, 10; zero differenze dal C vero (23 file, tutti gli errori) |
| `LoadJPG` (`tr_image.c`) | `TQ3JpegReader` (`Image.JpegReader`) sopra `Framework\Jpeg` | IDCT float, filtro triangolare, RGB, alfa 255; tolleranza sotto |
| `R_LoadImage` | `TQ3ImageLoader` (`Image.Loader`) | `.tga` poi `.jpg`; con `AExtensionSearch` la ricerca di ioquake3 (OpenArena) |
| `R_FindImageFile` (senza GL) | `TQ3ImageCatalog` (`Image.Catalog`) | nome -> handle, mancanti ricordati |
| `R_FindShader`, `RE_RegisterShader` | `TQ3ShaderRegistry` (`Shader.Registry`) sopra `IdTech4\Decl` | le immagini degli stage; difettosa = handle 0 |
| `RE_RegisterModel`, `R_LoadMD3` (parte dei dati), `R_ModelBounds`, `R_LerpTag` | `TQ3ModelRegistry` (`Model.Registry`) sopra `Framework\Models` | LOD, shader delle superfici, modelli `*N` del mondo |
| `RE_LoadWorldMap`, `R_LoadSurfaces` e le altre `R_Load*` | `TQ3WorldLoader` (`World.Loader`) sopra `IdTech4\MapFile` | ordine del C; superfici per tipo |
| `world_t`, `R_PointInLeaf`, `R_inPVS` | `TQ3RenderWorld` (`World.Data`) | |
| `re.*` di `cl_cgame.c` e `cl_ui.c` | `TQ3HostRendererAdapter` (`Host.Adapter`), decora un `IQ3HostRenderer` | il registratore di `Q3Host` resta sotto |
| `ri.FS_ReadFile` | `IQ3RenderFiles`, `TQ3RenderGameFiles` (`Files.GameFs`) | |

## Parita'

- **TGA e JPEG col C vero**: `Tools\Verifica\254\imagegen.c` include senza modifiche `LoadTGA` e `LoadJPG` ritagliate da `tr_image.c` e il `jpeg-6` di Quake III; `Make-Image-Golden.ps1` scrive `Tests\Data\Q3Render\image.golden.txt` (23 file del repository in `Tests\Data\IdImages\tga`, `Tests\Data\Q3Render\tga` e `Tests\Data\Jpeg`, piu' 34 JPEG e 35 TGA di `pak0.pk3` di OpenArena letti da `Reference`, il test relativo e' ignorato se manca). TGA: **zero differenze**. JPEG dei file del repository (4:4:4): zero. JPEG di OpenArena: 33 su 34 uguali; uno ha 36 byte su 262 144 che differiscono di 1-2: l'IDCT float del C non e' stabile tra compilazioni (tre compilazioni del C danno due risultati diversi per quel file), la tolleranza del test e' dichiarata (`SameWithinFloatDct`: al piu' 3 JPEG, somma dei byte entro 128).
- **Il resto** non ha una risposta del C compilabile da solo e si prova con test sul comportamento letto dal C: shader (la lettura ha la sua parita' in `Tests.Decl`), md3 (letto da `Framework\Models`, parita' sul C in `Tests.Models`), BSP (parita' in `Tests.MapFile`). `TQ3WorldLoader` e' provato sui BSP di `Tests\Source\DelphiDoom.Tests.MapFile.BspSample` (nessun BSP nel repository) e su `oa_dm1` di OpenArena.
- **Prova sui dati veri** (`TTestQ3RenderReach`, saltata senza OpenArena): `qagame` fa `GAME_INIT`, `cgame` fa `CG_INIT` e un fotogramma, `ui` il menu, con l'adattatore al posto del registratore (stessi 12 `.qvm`, stesse chiamate): `reach.golden.txt`, Win32 = Win64.

## Differenze volute dal C

1. **Ricerca delle immagini di ioquake3** (opzione `AExtensionSearch`, attiva in `CreateSystem`): OpenArena scrive `clampmap menu/art/skill1` senza estensione e il suo motore (ioquake3) prova `.png`, `.tga`, `.jpg`, `.pcx`, `.bmp`; il `R_LoadImage` di Quake III 1.32 dice "nessuna immagine". Con `False` il comportamento e' quello di 1.32 (test).
2. PNG, PCX e BMP non si decodificano (contati in `TQ3ImageLoader.UnsupportedFound`); MD4 non portato.
3. Un file TGA che finisce prima dell'immagine, una larghezza o altezza negativa (il C la legge `short` con segno) o sopra 8192 sono `EQ3RenderException` (il C legge oltre il buffer o alloca gigabyte). Un JPEG in scala di grigi e' R = G = B (il C scrive 4 byte per pixel in un buffer da 1: testato sul C vero, un file del repository lo manda in un ciclo), un JPEG rovinato o troncato e' `False` (il C chiama `exit`).
4. Un'immagine che non carica (o che solleva) e' **mancante** e ricordata: non si rilegge (il C la cerca a ogni richiesta). I pixel si tengono solo con `AKeepPixels` (le immagini di un gioco sono centinaia di megabyte).
5. **`R_inPVS` con un punto in una foglia solida** (cluster -1): il C legge il byte prima della riga di visibilita'; qui "non visibile". Un cluster fuori tabella o senza dati di visibilita' vede tutto, come `CM_ClusterPVS`.
6. Una superficie che i caricatori rifiutano (vertici o indici oltre i lump) e' contata in `RefusedCount` e lasciata fuori (il C legge fuori dal lump): `IdTech4\MapFile` le segnala.
7. Le shader di un md3 si registrano per ogni LOD letto, anche se solo il LOD 0 si tiene. Il modello che non carica non e' un modello difettoso nella tabella (il C tiene una voce `MOD_BAD`): qui e' ricordato come mancante e `Register` da' 0.
8. Le numerazioni dei handle sono quelle della libreria (1, 2, ...), **non** quelle del registratore di `Q3Host`: l'adattatore tiene la corrispondenza e ai moduli da' sempre i numeri del registratore.

## Difetti del C conservati

- Il confronto `LoadTGA` accetta il tipo 3 con 24 o 32 bit (lo `switch` e' sulla profondita'), un'esecuzione RLE puo' passare da una riga all'altra e finisce all'ultima riga, il bit "origine in alto" e' solo un avviso (non capovolge): tutto conservato e nel golden.
- `LoadJPG` termina con `jpeg_destroy_compress` su un decompressore, e legge un blocco intero di 4096 byte oltre la fine del file.
- `R_ModelBounds` di un modello a maglia dice i limiti del **primo** fotogramma.

## Cosa non c'e' (R1 e R2)

Lista di disegno (`tr_scene`, `R_RenderView`, `R_MarkLeaves`, `R_AddMD3Surfaces`), tassellazione in `tess`, `R_LightForPoint` (i dati del light grid ci sono: `IQ3RenderWorld.GetLightGrid`), `RE_MarkFragments`, `RE_RegisterFont`, cielo, flare, ombre, backend, texture. Il piano e' in `docs\Q3RENDER_CENSIMENTO.md`.

## Licenza

GPL v2 o successiva (intestazione "Based on the Quake III Arena GPL Source Code (id Software)" nelle unit portate). **Dipendenza da codice di Doom 3**: il lettore md3 che la libreria usa (`Framework\Models`, `Models.Static.Md3.*`, #105) deriva da `Model_md3.cpp` di Doom 3 (GPL v3 o successiva con termini aggiuntivi, `docs\LICENZE.md`): un eseguibile che include `Q3Render` e quel lettore e' GPL v3 o successiva. Non e' stato riscritto (`R_LoadMD3` e' un'altra rappresentazione dei stessi byte): se serve un eseguibile solo v2, il lettore md3 va riscritto dal C di Quake III (un'unit).
