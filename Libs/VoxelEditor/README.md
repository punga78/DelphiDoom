# Libs\VoxelEditor

Editor di voxel (modulo Voxel di DD_Tools): il cubo, le sei viste, gli strumenti, i formati DDVOX, KVX, VOX e DDMESH, il quantizzatore, la mesh e il presenter, senza VCL.

Il testo di riferimento (parità con il vecchio DD_VOXEL, difetti corretti e conservati, cosa non è portato) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 19 (nome a punti `DelphiDoom.VoxelEditor.*`).
- Interfacce dichiarate: `IVoxelEditorClipboard`, `IVoxelEditorDialogs`, `IVoxelEditorImageExporter`, `IVoxelEditorImageLoader`, `IVoxelEditorView`.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.VoxelEditor`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)). Golden del vecchio codice: `Tests\Data\VoxelEditor`, si rifanno con `Tools\Verifica\167`.

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
- `Libs\ToolsCore` (annulla, file recenti, impostazioni), `Libs\Palette` (`TGamePalettes`), `Libs\Voxel` (lettura per il motore, non usata qui: l'editor ha il suo layout del cubo).
