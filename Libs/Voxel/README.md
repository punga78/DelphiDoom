# Libs\Voxel

Lettura dei file dei voxel e del lump VOXELDEF.

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 17 (nome a punti `DelphiDoom.Voxel.*`).
- Interfacce dichiarate: `IVoxelColorMapper`, `IVoxelCube`, `IVoxelCubeBuilder`, `IVoxelDefinitionLookup`, `IVoxelDefinitionParser`, `IVoxelDefinitionSink`, `IVoxelFileSource`, `IVoxelFormat`.
- Punto di creazione delle classi: `DelphiDoom.Voxel.Factory`.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Voxel`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
