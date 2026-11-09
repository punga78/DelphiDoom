# Verifica della issue #167 (DD_VOXEL, modulo Voxel di DD_Tools)

`HarnessVoxel.dpr` esegue il **vecchio** codice di DD_VOXEL (le unit di `Reference\DD_VOXEL`, sola lettura) sugli scenari di
`Tests\Source\DelphiDoom.Tests.VoxelEditor.Scenarios.pas` e scrive `Tests\Data\VoxelEditor\voxel.golden.txt`; i test
`DelphiDoom.Tests.VoxelEditor.Parity` confrontano le risposte della libreria `Libs\VoxelEditor` con quel file.

## Rifare i golden

```
powershell -NoProfile -File Tools\Verifica\167\prepare.ps1
powershell -NoProfile -File Tools\Verifica\167\extract.ps1
Tools\Verifica\167\build.cmd
Tools\Verifica\167\build\HarnessVoxel.exe Tests\Data\VoxelEditor\voxel.golden.txt
```

`Reference\DD_VOXEL` sta nel checkout principale (cartella ignorata da git): se si lavora in un worktree, copiarla o
cambiare `$ref` negli script. L'esecuzione dura circa 80 secondi (il vecchio codice lavora su cubi di 256 celle).

## Cosa fanno gli script

- `prepare.ps1` copia in `build\` tre unit del vecchio codice con le sole modifiche seguenti (ogni modifica e dichiarata):
  1. `vxe_quantize.pas`: `node_free` azzera `nodeslen` (il vecchio non lo faceva: la seconda quantizzazione di una sessione
     scriveva nel vuoto e andava in access violation);
  2. `vxe_mesh.pas`: un contatore (`VoxelMeshLegacyHits`) dei passi che entrano nel compattamento difettoso, e un
     interruttore (`VoxelMeshFixCompaction`) che usa il compattamento corretto, cosi il test confronta sia il vecchio (dove
     non sbagliava) sia il vecchio con la sola correzione;
  3. `vxe_script.pas`: `SetText` copiava `Length(tx)` byte di una stringa UTF-16 (codice scritto per Delphi 7): il buffer
     ora e `Length(tx) * SizeOf(Char)`; senza questa modifica il lettore dei DDVOX leggeva solo meta del testo;
- `extract.ps1` ricava da `vxe_export.pas` (senza modificarle) `VXE_RotateVoxelBuffer`, `VXE_RotateVoxelBufferHQ` e
  `VXE_ExportVoxelToSlab6VOX` in `build\oldexport.pas`.
- `HarnessVoxel.dpr` contiene le funzioni di `main.pas` che servono (caricamento di KVX, VOX, DDMESH e DDVOX, scrittura del DDVOX,
  lettura e scrittura dei piani, specchi e rotazioni delle immagini con `vxe_rotate`, mappa delle altezze, texture del
  terreno, scala di grigi, conteggio dei colori, riduzione a una paletta) copiate alla lettera, senza i controlli della finestra.
- `progressfrm.pas` e una finestra di avanzamento finta.
