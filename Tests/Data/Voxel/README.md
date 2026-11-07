# Dati di prova di Libs\Voxel (issue #78)

`voxel.golden.txt` e' l'uscita del **vecchio codice del motore** (i quattro caricatori di `Base\r_voxels.pas` per il renderer software,
la classe `TVoxelImageLoader` di `Base\vx_voxelsprite.pas` per gli sprite, i quattro caricatori di `OPENGL\gl_voxels.pas` fino ai buffer da
cui nasce la mesh, `SC_DoParseVoxelDefinition` di `Base\vx_base.pas`), compilato con Delphi 11 Win32 in un programma di prova **fuori dal
repository** (l'harness non si committa). Nell'harness i file arrivano da memoria (`TPakStream` e' un flusso di memoria), i buffer sono
di lato 64 invece di 256, il parser di VOXELDEF scrive su un registratore (variante OpenGL: offset e scala sono float) e il colore piu' vicino
della palette e' una funzione fissa (`TVoxelSamples.PaletteIndexOf`); il resto e' la copia del vecchio testo. Ogni riga e'
`chiave=impronta/conteggio` (FNV-1a a 64 bit, `DelphiDoom.Tests.Voxel.Fingerprint`). Nello stesso eseguibile il vecchio codice e le classi
nuove hanno dato le stesse impronte (zero differenze, e i tre vecchi lettori di DDVOX, DDMESH e VOX danno lo stesso cubo tra loro); i test
confrontano le classi nuove con queste righe.

I file di prova sono costruiti in memoria (`DelphiDoom.Tests.Voxel.Samples`, xorshift32 con semi fissi).

| Chiave | Contenuto |
|---|---|
| `ddvox.cubes` | 30 file DDVOX (lati da 2 a 12, salti e colori, commenti, separatori diversi): lato e celle del cubo |
| `ddmesh.cubes`, `ddmesh.quads` | 24 file DDMESH (lati da 2 a 16, da 0 a 8 facce): celle del cubo e facce (colore e vertici) |
| `kvx.cubes.renderer`, `kvx.cubes.sprite` | 40 file KVX (da 1 a 14 voxel per lato, palette di sei tipi, pivot vicino al centro): il cubo dei caricatori software e degli sprite (il lato e la posizione sono diversi) |
| `kvx.grids` | gli stessi 40 KVX come li legge OpenGL: dimensioni, pivot e colore di ogni voxel nel sistema di assi del file |
| `kvx.extreme.cubes.renderer`, `kvx.extreme.grids` | 24 KVX con pivot qualsiasi (anche negativo o fuori dal modello): il renderer software li rimette nel cubo |
| `slab6.cubes` | 30 file VOX di Slab6 |
| `rejects` | sei file che il vecchio codice rifiuta senza errori (KVX e VOX corti, VOX con un lato di 0 o 257, DDMESH con magia o versione sbagliata) |
| `patches.ddvox/ddmesh/kvx/slab6` | i byte della patch dello sprite (`CreateDoomPatch`) per gli stessi file, con la palette di prova |
| `definitions` | 16 testi di VOXELDEF: ogni chiamata al registro dei voxel (voxel con offset, scala, spin, flag; stato; sprite sostituito) e ogni avviso, in ordine |

Il sorgente non ha casi con pivot fuori dal cubo per gli sprite, dimensioni di 256 o salti oltre la colonna di un DDVOX: il vecchio codice li
scriveva fuori dai limiti della memoria (vedi `CLAUDE.md`, `Libs\Voxel`).