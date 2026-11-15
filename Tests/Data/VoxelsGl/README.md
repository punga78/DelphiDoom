# PK3 di prova dei voxel nel renderer OpenGL (issue #177, fetta 12)

Dati sintetici scritti da `Make-VoxelPk3.ps1`: **dominio pubblico (CC0)**, nessun asset di un gioco.
Servono a far comparire il disegno dei voxel (`TEngineGlSceneVoxelPainter`, prima `gld_DrawVoxels` e `gld_DrawVoxel` di `gl_render.pas`) nel flusso
del registratore delle chiamate OpenGL (`Tools\Verifica\opengl\Confronta.ps1 -Voxels`).

| File | Contenuto |
|---|---|
| `zvox_d.pk3` | Doom: `voxels/ZVOXAA.DDVOX` (piramide a gradini 8x8x8, testo DDVOX) e un `VOXELDEF` che lega **ogni stato** di `Doom\info_h.pas` (1076) al voxel con `state <S_xxx> voxel "zvoxaa.ddvox"` |
| `zvox_h.pk3`, `zvox_x.pk3`, `zvox_s.pk3` | lo stesso per Heretic (1205 stati), Hexen (2845) e Strife (1566) |
| `zvox_p.pk3` | Doom con `AngleOffset 45`, `DroppedSpin 60` e `PlacedSpin 90` sul voxel (il ramo della rotazione di `gld_DrawVoxel`) |

Tutto cio' che il motore disegna come sprite (oggetti, mostri, proiettili) diventa il voxel; il voxel e' uno solo (il manager li riconosce per nome), quindi
la lista di visualizzazione si costruisce una volta sola. Il nome del file non supera 8 caratteri (`-file` lo passa a `ExtractFileBase`) e le versioni
shareware rifiutano i file esterni senza `-devparm`. **Il percorso del pacchetto non deve avere un punto**: `-file` prende l'estensione dal primo punto,
e un albero sotto `.claude\worktrees` fa vedere il PK3 come "WAD non valido" (`Confronta.ps1 -PackDir C:\cartella` lo copia fuori).

Rigenerare: `powershell -NoProfile -ExecutionPolicy Bypass -File Tests\Data\VoxelsGl\Make-VoxelPk3.ps1` (uscita deterministica).
Uso: `Tools\Verifica\opengl\Confronta.ps1 -Game GLDoom -Voxels [-VoxelVariant p] [-PackDir C:\ddgl_177v\packs]` e `Misura-Gl.ps1 -Voxels`.
Nel flusso il voxel e' una `glCallList` (la lista compilata da `TVoxelModel`) preceduta da `glTranslatef` e `glRotatef` della cosa.
