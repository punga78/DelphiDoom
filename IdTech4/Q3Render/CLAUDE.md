# IdTech4\Q3Render — note per Claude

Issue #254 (Quake III: dalle librerie a un eseguibile), fase 5, **R0: il renderer senza OpenGL** (ondata 12a, 2026-11-18). Descrizione, mappa C -> Pascal, differenze volute e difetti conservati: [README.md](README.md); censimento del renderer e fasi R0/R1/R2: `docs\Q3RENDER_CENSIMENTO.md`; numeri sui `.qvm` di OpenArena: `docs\QUAKE3_CENSIMENTO.md` par. 9. **Nessun chiamante nel motore**; il renderer registratore di `IdTech4\Q3Host` non e' toccato.

## Unit (una classe per unit, `DelphiDoom.Q3Render.*`)

`Types` (`TQ3RenderImage` RGBA, `TQ3RenderVec3`, `EQ3RenderException`), `Intf` (`IQ3RenderFiles`, `IQ3ImageLoader`, `IQ3ImageCatalog`, `IQ3ShaderRegistry`, `IQ3RenderWorld`, `IQ3WorldLoader`, `IQ3ModelRegistry`, `IQ3RenderSystem`), `Files.GameFs`, `Image.TgaReader`, `Image.JpegReader`, `Image.Loader`, `Image.Catalog`, `Shader.Registry`, `Model.Registry`, `World.Data`, `World.Loader`, `System`, `Host.Adapter` (`TQ3HostRendererAdapter`: implementa `IQ3HostRenderer`), `Factory` (`TQ3RenderFactory`, composition root).

**Riuso, non duplicato**: parser delle shader e `FinishShader` (`IdTech4\Decl`, `TDeclFactory.CreateQuake3ShaderManager...`), caricatori del BSP (`IdTech4\MapFile`, `TBspFactory`), lettore md3 e `R_LerpTag` (`Framework\Models`: `TStaticModelFactory.CreateMd3Reader`, `TQ3PlayerFactory.CreateTagLerper`), decodifica JPEG (`Framework\Jpeg`, `TJpegDecoder.Decode` con `FastInverseDct` e `RgbOrder`), file system (`Framework\Wad`), registratore di `Q3Host` come renderer interno dell'adattatore. Nuovo: lettura TGA come `LoadTGA` di Quake III (il `TTgaIdReader` di `Framework\Texture` e' quello di Doom 3, che capovolge col bit di origine: non lo stesso), `R_LoadImage` e la ricerca di ioquake3, tabelle per nome, composizione del mondo.

## Come si rifanno i dati (`Tools\Verifica\254`, gcc di `Reference\_dati\_strumenti\w64devkit`, 32 bit con x87)

```
powershell Tools\Verifica\254\Make-Q3Tga.ps1                 # i TGA di Tests\Data\Q3Render\tga (deterministico)
powershell Tools\Verifica\254\Make-Image-Golden.ps1          # Tests\Data\Q3Render\image.golden.txt (build-image.sh + imagegen.c)
$env:DELPHIDOOM_Q3RENDER_REACH_OUT='<file>'; <exe dei test>  # riscrive reach.golden.txt (e <file>.details con i nomi)
$env:DELPHIDOOM_Q3RENDER_DUMP='<cartella>'; <exe dei test>   # i pixel dei JPEG che differiscono, da confrontare con IMAGEGEN_DUMP del C
```

- `imagegen.c` taglia `LoadTGA` e `LoadJPG` da `tr_image.c` per funzione (awk) e collega il `jpeg-6` vero di Quake III con un `tr_local.h` finto (la `ri`); `build-image.sh` lo copia in una cartella di lavoro (i file di jpeg includono `../renderer/tr_local.h`). Un JPEG in **scala di grigi** manda il C in un ciclo (il buffer e' da 1 byte per pixel, l'alfa lo scrive a 4): fuori dal corpus. Un TGA troncato legge oltre il buffer: fuori (`t2_trunc.tga`).
- **Il C non e' stabile sull'IDCT float**: `-O0` (variabili in memoria), `-O1/-O2` e Delphi (Extended a Win32, Double a Win64) danno risultati diversi di 1-2 livelli su pochi pixel di `bloodscreenmult.jpg`. Il golden e' di `-O0`; la tolleranza e' nel test (`SameWithinFloatDct`).
- **Dati di OpenArena**: il golden delle immagini e' dei file di `baseoa\pak0.pk3`; i pak successivi ne sostituiscono alcuni (il file system li prende per ultimi): il test legge `pak0.pk3` con `System.Zip`, non il file system.

## Trappole viste

- `numImageAnimations` di uno stage di una shader resta 0 per una `map` semplice (solo `animMap` lo imposta): i nomi delle immagini sono `ImageNames[0..max(n,1)-1]`. Un primo giro caricava zero immagini per ogni shader.
- Le immagini che il renderer fa da se' hanno nome `$whiteimage`, `$lightmap` e `*white`, `*default` ...: non sono file.
- OpenArena scrive `clampmap menu/art/skill1` (senza estensione) e `gfx/2d/crosshair00` e' chiesto senza estensione: il `R_LoadImage` di 1.32 non li troverebbe, quello di ioquake3 si' (opzione `AExtensionSearch`).
- Il visibility lump del BSP di prova ha righe senza il bit del proprio cluster: un punto non vede se' stesso (e' coerente col C): i test pongono le righe a mano.
- Win64: `Assert.AreEqual(n, Length(x))` non compila (`AreEqual<Integer>`); la libreria non ha altro che sia diverso a 64 bit.

## R1 (ondata 13, 2026-11-19, tag `ondata13-254-1`..`-4`): lista di disegno e backend sul registratore

Cosa e' fatto e cosa no, per funzione C: README, sezione "R1". **Unit nuove** (`DelphiDoom.Q3Render.*`): `Scene.Types` (record, costanti, `TQ3RenderSettings` con i default delle cvar), `Scene.Reader`, `Scene.Buffers`, `Scene.FrontEnd` (`TQ3FrontEnd`: il fronte, con `OnDrawSurfs` = `R_AddDrawSurfCmd`), `View.Setup`, `View.Culler`, `Draw.Sorter`, `Draw.List`, `World.Surfaces`, `Shader.Table` (`IQ3ShaderTable`: R_FindShader per nome e indice di lightmap, ordine per `sort`), `Frame.Commands`, `Frame.Renderer` (`TQ3Renderer`: fronte + comandi + backend + frame del registratore), `Backend.Gl` (`IQ3GlSink`, `TQ3GlRecordingSink`), `Backend.State` (`GL_State` & c.), `Backend.Executor` (`TQ3Backend`). Cambiati: `IQ3RenderWorld` (tabella `msurface_t`, griglie, fog, numero di lightmap), `IQ3ModelRegistry.BrushIndex`, l'adattatore (`AttachRenderer`, `BeginFrame`, `EndFrame`, `HostShaderEntry`), `TQ3RenderFactory.CreateRenderingHostRenderer`. Il progetto di test cerca anche `Framework\OpenGlBinding\Recorder` (riga nel `.dproj`).

**Come si rifanno i dati (R1)**

```
# front.golden.txt (il C vero: tr_main.c e tr_world.c di Quake III + q_math.c, gcc 32 bit SSE)
# serve maps/oa_dm1.bsp estratto da Reference\openarena\...\baseoa\pak1-maps.pk3 (percorso con "/" o cygpath -m)
sh Tools/Verifica/254/build-front.sh <cartella di lavoro> <oa_dm1.bsp> <Tests/Data/Q3Render/front.views.txt, assoluto> > front.golden.txt
$env:DELPHIDOOM_Q3RENDER_FRONT_OUT='<file>';   <exe dei test>   # scrive la versione Delphi (confronto riga per riga)
$env:DELPHIDOOM_Q3RENDER_BACKEND_OUT='<file>'; <exe dei test>   # scrive il flusso intero e <file>.golden (= backend.golden.txt)
$env:DELPHIDOOM_Q3RENDER_RENDER_OUT='<file>';  <exe dei test>   # scrive reach.render.golden.txt
```

**Trappole viste in R1**: (1) **`M_PI` e' un `double` col math.h di mingw** (che ridefinisce la macro dopo `q_shared.h`) e un `float` in MSVC: senza `-D__STRICT_ANSI__` il frustum e la proiezione del "C vero" cambiano di un bit (`2 * zNear / height` dava `3faaaaac` invece di `3faaaaab`) e il confronto con Delphi non torna; il porting segue MSVC (float). (2) `sin`, `cos`, `tan` e `sqrt` del C lavorano in `double` e il risultato torna in `float`: in Pascal passano da una variabile `Double` (`TQ3ViewSetup.RoundedSin` & c.), altrimenti l'x87 arrotonda una volta sola. Ogni somma di prodotti passa da variabili `Single` (come `TQ3Math`). (3) `build-front.sh` va chiamato con percorsi assoluti (fa `cd` nella cartella di lavoro). (4) La shell del sandbox rifiuta i comandi con "Source" e "MapFile" nel percorso e i here-document: per quelle cartelle usare gli strumenti `Read`/`Edit`. (5) `Assert.AreEqual(n, Length(x))` non compila a 64 bit: `AreEqual<Integer>`. (6) `SetLength(a, n)` tiene i valori vecchi di un array che cresce: azzerare prima nei test. (7) Un `TQ3Orientation` e un `TQ3ViewParms` esistono anche in `IdTech4\Decl` (`Q3Shader.Calc.Types`): i tipi del fronte si chiamano `TQ3ViewOrientation` e `TQ3FrontViewParms`.

## R1b (ondata 14, 2026-11-19, tag `ondata14-254r-1`..`-7`): superfici, cielo e passi, con il C vero

Mappa C -> Delphi, parita' e differenze: README, sezione "R1b"; censimento: `docs\Q3RENDER_CENSIMENTO.md` par. 4b. **Unit nuove**: `Backend.Surfaces` (`TQ3SurfaceTessellator`: griglia, poligono, sprite, raggi, mesh md3, striscia del raggio), `Backend.Sky` (`TQ3SkyBox`: cielo e sole), `Backend.Passes` (`TQ3ShadingPasses`: dlight e nebbia come draw). Cambiati: `Backend.Executor` (collega tutto, `BuildFogs`, `SetSettings`, il cielo come iteratore, le maschere dei dlight, `TransformDlights`, maschera della FPU in `Execute`), `Scene.Types` (`TQ3SurfaceRef.DlightMask` e `.Lod`, nuove cvar in `TQ3RenderSettings`), `Frame.Commands` (poligoni e luci nel comando), `Scene.FrontEnd` (`ComputeLod`, `ProjectRadius`, i frame validi scritti nell'entita'), `Model.Registry` (i livelli di detail), `IdTech4\Collision\DelphiDoom.Collision.Q3.VectorMath` (`Dot`, `ProjectPointOnPlane`, `PerpendicularVector`, `RotatePointAroundVector`, `MakeNormalVectors` come `q_math.c`, in float: `TVectorMath` di `GameMath` ha le somme in precisione estesa e da' differenze di qualche ULP).

**Come si rifanno i dati (R1b)**

```
# surf.golden.txt e surf.map.golden.txt (il C vero, gcc 32 bit SSE: tr_surface.c, tr_curve.c, tr_shade_calc.c, tr_noise.c + tr_bsp.c, tr_sky.c, tr_shade.c inclusi)
# serve maps/oa_ctf2.bsp estratto da pak1-maps.pk3 (NON da pak6-patch088, che ne ha un'altra versione)
sh Tools/Verifica/254/build-surf.sh <cartella di lavoro> <Tests/Data/Q3Render/surf.cases.txt, assoluto> > surf.golden.txt
sh Tools/Verifica/254/build-surf.sh <cartella di lavoro> <Tests/Data/Q3Render/surf.map.cases.txt, assoluto> <oa_ctf2.bsp> > surf.map.golden.txt
$env:DELPHIDOOM_Q3RENDER_SURF_OUT='<file>'; <exe dei test>   # scrive le righe della libreria (e <file>.map)
$env:SURFGEN_DUMP='<n>'   # C e test: i vertici della griglia della superficie n (stderr del C, righe "v" nel file .map della libreria)
```

**Trappole viste in R1b**: (1) la shell del sandbox rifiuta i here-document e i comandi composti: i `.c` e i dati si scrivono con `Write`/`Edit`, i comandi sono semplici; `sed -i` con `\n` nel testo li trasforma in a-capo (usare `Edit`). (2) `pak6-patch088.pk3` ha un'altra `oa_ctf2.bsp`: il file system prende l'ultimo pak, quindi il test legge `pak1-maps.pk3` con `System.Zip`. (3) Il payload di un NaN dipende dall'istruzione (x87 contro SSE): i NaN delle coordinate della lightmap di alcune patch di `oa_ctf2` sono lo stesso valore nel confronto (`7fc00000`). (4) Una eccezione `Invalid floating point operation` nel caricamento di una mappa o nel disegno: il C non si ferma, la libreria maschera la FPU (`TQ3FloatMask`) in `Execute` e nel test. (5) `AS` e' una parola riservata di Delphi: non e' un nome di parametro valido. (6) `RotatePointAroundVector` di `TVectorMath` non e' esatta al bit con il C (somme senza temporanee): usare `TQ3VectorMath`. (7) `RB_DrawSun` e `RB_SurfaceFlare` nel C non fanno nulla di raggiungibile (`#if 0`).

## Numeri (2026-11-19)

`Tests\DelphiDoom.Tests.Q3Render` (`Tools\build.bat Tests\DelphiDoom.Tests.Q3Render Release [Win64]`): **79 test**, tutti verdi a Win32 e a Win64 (44 della R0, 28 della R1: `TTestQ3Front` col C vero, `TTestQ3Backend` e `TTestQ3GlState`, `TTestQ3RenderReach` con la modalita' di disegno, e i pezzi in `FrontPieces`; 7 della R1b: `TTestQ3Surfaces` 3 (2 col C vero, 1 sulle eccezioni), `TTestQ3Entities` 4); i test su OpenArena sono saltati senza `Reference\openarena`. `Tests.Q3Host` 210 su 210 a Win32; Doom32 Release Win32 compila; `Tools\build.bat strati`: 0 violazioni nuove. Primo fotogramma di cgame su `oa_dm1`: **57 drawSurf** (una scena, solo mondo), 37 batch, 53 `StretchPic`; i 6 fotogrammi del golden del backend (con le luci delle viste): 230 batch, 18 draw dei dlight, 6 della nebbia, 48 texture.
