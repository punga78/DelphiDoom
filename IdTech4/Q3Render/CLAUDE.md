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

## Numeri (2026-11-18)

`Tests\DelphiDoom.Tests.Q3Render` (`Tools\build.bat Tests\DelphiDoom.Tests.Q3Render Release [Win64]`): **44 test**, tutti verdi a Win32 e a Win64, 0 avvisi dalle unit della libreria; 2 dei test (immagini di OpenArena e portata sui `.qvm`) sono saltati senza `Reference\openarena`. `Tests.Q3Host` 210 su 210 a Win32. `Tools\build.bat strati`: 0 violazioni nuove.
