# Issue #151 - cosa eseguire (codice scritto senza compilatore)

Nulla di questo lavoro e stato compilato ne eseguito. Ordine consigliato.

## 1. Build

```
build.bat Doom32 Release
build.bat Heretic32 Release
build.bat Hexen32 Release
build.bat Strife32 Release
build.bat GLDoom32 Release
build.bat all Release
```

Leggere `logs\<progetto>.log` (righe `error`). Errori attesi, se ce ne sono: firme dei costruttori (ordine dei parametri in
`Base\DelphiDoom.Engine.Composition.pas`), `uses` mancanti dopo aver tolto `w_wad`/`z_zone`, ambiguita di nomi con
`DelphiDoom.Zone.Types` o `DelphiDoom.Wad.Types` (quest'ultimo ora e nella `uses` di `DelphiDoom.Engine.Voxel.FileSource`
per `TYPE_VOXEL`).

## 2. Test

```
build.bat tests
```

Deve passare `Tests\DelphiDoom.Tests.Wad` con 109 + 16 test (8 in `DelphiDoom.Tests.Wad.LumpText`, 8 in
`DelphiDoom.Tests.Wad.FileBase`, nomi in italiano). Tutte le altre suite invariate.
Copertura: `powershell -NoProfile -File Tools\Copertura.ps1 -Test Wad`; le due unit nuove (`DelphiDoom.Wad.Text`,
`DelphiDoom.Wad.FileBase`) devono essere al 100%.
`Libs\Zone` non e cambiata. `TEngineZoneAllocator` e `TEngineLumps` stanno in `Base\` (dipendono da `i_system` e `w_wad`,
nessun test DUnitX possibile, come le altre classi del motore).

## 3. Parita del caricamento del livello (stessi lump, stessa memoria)

Harness in `Tools\Verifica\151\DelphiDoom.Verify151.pas` (non nei `.dpr`). Confronto tra il commit di partenza
`31ee71e3` e questo ramo, stessa procedura su entrambi:

1. Aggiungere temporaneamente l'unit ai `uses` di `Base\w_wad.pas` (implementation) e di `Doom\g_game.pas`
   (e degli altri `g_game`/`g_demo` dei giochi da provare; la unit non e nei `.dpr`: aggiungerla con `in 'Tools\Verifica\151\...'`).
2. In `W_ReadLump` (prima riga del corpo): `V151_TraceLump(lump);`
3. In `G_DoLoadLevel` dopo `P_SetupLevel`: `if M_CheckParm('-verify151') > 0 then begin V151_DumpLevel('doom'); Halt(0); end;`
4. Eseguire in una cartella di lavoro pulita (cancellare `verify151_*.txt` prima di ogni prova):
   `bin\Doom\Doom32.exe -iwad FREEDOOM2.WAD -warp 1 -verify151` e salvare i file; ripetere con `-warp 7`, Heretic
   (`-warp 1 1`), Hexen (`-warp 1`), Strife (`-warp 2`), GLDoom32 su Freedoom 2.
5. Sul ramo di partenza e su questo ramo.

Deve risultare: `verify151_<tag>.txt` identico riga per riga (count e fnv di vertexes, sectors, lines, sides, subsectors,
nodes, reject, blockmap) e `verify151_lumps.txt` identico (stessi lump letti nello stesso ordine). Con UDMF/`-buildnodes`
(mappa senza nodi) anche gli stessi file in `DATA\WADS`/`DATA\BSP`.
Se i nomi dei campi (`sectors[].tag`, `lines[].special`...) non compilano in un gioco, togliere la riga: e un harness.

Rimuovere poi tutte le modifiche temporanee (`git checkout` dei file toccati).

## 4. Gioco

- `-timedemo demo1`, `demo2`, `demo3` (Doom): `gametics` identici al ramo di partenza (2134 per demo3 con shareware) e
  tempi entro +5%.
- Smoke degli otto eseguibili con `Tools\Esegui-gioco.ps1`, 25 s, `-warp` su un livello: nessun `crash.txt`, nessun `I_Error`
  in `DATA\LOGS\*_stderr.txt`.
- Da provare a mano: console (`mem`, `zonemem`), autoexec, un PWAD con `ANIMDEFS`, `MAPINFO`/`UMAPINFO`, `GLDEFS`,
  `VOXELDEF`, `AUTOLOAD`, un TEXTMAP UDMF (convertito e caricato a runtime), schermata ENDOOM, salvataggio/caricamento di Hexen
  con script ACS (l'host alloca da `IZoneAllocator`), musica esterna `.MOD`.
- Uscita dal gioco: l'allocatore ora e tenuto vivo anche dalle classi (non solo da `z_zone`); la memoria della zona si libera alla
  finalizzazione delle unit invece che in `Z_ShutDown`. Controllare che la chiusura non dia errori (in Debug, perdite di memoria).
