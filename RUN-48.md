# RUN - issue #48 (prova dei percorsi PK3)

Tutto dalla radice di questo worktree. Prima compilare e provare le librerie, poi il motore, poi la prova.

## 1. Compilazione e test
```
build.bat tests          # oppure solo: build.bat Tests\DelphiDoom.Tests.Wad / .Texture / .Voxel
build.bat giochi         # Doom32, Heretic32, Hexen32, Strife32 (+ GL*32 per --Gl)
```
Eseguire poi `bin\Tests\DelphiDoom.Tests.Wad.exe`, `...Texture.exe`, `...Voxel.exe` (i test leggono `Tests\Data\Pk3`
risalendo da `bin\Tests`). Nuovi: 12 in `TTestWadPk3`, 10 in `TTestTexturePk3`, 10 in `TTestVoxelPk3` (se un `Assert` non torna,
guardare prima il file di dati: `Make-Pk3.ps1`).

## 2. Rigenerare i dati (solo se serve)
`powershell -NoProfile -ExecutionPolicy Bypass -File Tests\Data\Pk3\Make-Pk3.ps1`

## 3. Prova nel motore
Servono in `bin\<Gioco>` gli IWAD (`FREEDOOM2.WAD`, `HERETIC1.WAD`, `HEXEN.WAD`, `STRIFE0.WAD`) e gli `.ini`.
```
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\Verifica\48\Prova-Pk3.ps1            # software, 4 giochi
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\Verifica\48\Prova-Pk3.ps1 -Gl        # anche GL*32
```
Lancia ogni gioco due volte con `-iwad <IWAD> -file zpktest.pk3 zpkhires.wad <warp> -devparm -nomusic -nosound`, con
`usepk3textures=1` messo nell'`.ini` (copia e ripristino automatici). Per ogni gioco **deve risultare**:
- vivo dopo 25 s, nessun `crash.txt`, nessun `I_Error`/eccezione nei log;
- `DATA\WADS\pk3tex_*.wad` con `P_START, ZPKPNG, ZPKTGA, ZPKBMP, ZPKJPG, ZPKPCX, ZPKPAT, ZPKFLT, PNAMES0, TEXTURE0, P_END`;
- `DATA\WADS\pk3flat_*.wad` con gli stessi sette nomi piu' `ZPKFLAT` tra `F_START` e `F_END`;
- `DATA\TMP\voxelsprite_*.wad` con `SS_START, ZVKAA0, ZVDAA0, ZVSAA0, SS_END`;
- `DATA\TMP\pk3sounds_*.wad` con `DSZPKWAV, DSZPKOGG, DSZPKFLC`;
- seconda esecuzione: cache `pk3tex_` non riscritta e nessun "Create textures and flats from PK3".
Avvisi attesi: negli altri tre giochi `sprite treda/tblua/tgrna not found` (VOXELDEF e' di Doom).
Riepilogo anche in `logs\prova-pk3-48.txt`; codice di uscita = controlli falliti.

## Non coperto
Vedere le texture sui muri e i voxel in una mappa, sentire i suoni: servono una mappa che usi i nomi `ZPK*` e un
ascolto manuale. I lump `HI_START`/`TX_START` di `zpkhires.wad` sono controllati dai test, non caricati come texture.
