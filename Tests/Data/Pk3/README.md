# PK3 di prova (issue #48)

Dati sintetici scritti da `Make-Pk3.ps1`: **dominio pubblico (CC0)**, nessun asset di un gioco.
Servono ai test (`Tests\DelphiDoom.Tests.Wad`, `.Texture`, `.Voxel`: unit `*.Pk3`) e alla prova nel motore
(`Tools\Verifica\48\Prova-Pk3.ps1`, `RUN-48.md` alla radice).

| File | Contenuto |
|---|---|
| `zpktest.pk3` | ZIP con i file di `src\` (nomi con `/`) |
| `zpkhires.wad` | PWAD: `HI_START` con TGA, PNG, BMP, JPEG, PCX, patch e flat (`ZWTGA`...`ZWFLT`), `HI_END`, `TX_START` con PNG e TGA, `TX_END`, un WAV (`ZWSND`) e `PK3ENTRY` (`ZWSND=sounds/zwsnd.wav`) |
| `src\textures\` | `ZPKPNG.png`, `ZPKJPG.jpg`, `ZPKBMP.bmp`, `ZPKTGA.tga`, `ZPKPCX.pcx`, `ZPKPAT.patch`, `ZPKFLT.flat` (tutti 64x64) |
| `src\flats\ZPKFLAT.png` | un flat 64x64 |
| `src\voxels\` | `ZVKAA.KVX`, `ZVDAA.DDVOX`, `ZVSAA.VOX` (8x8x8: piramide a gradini, la stessa, e una sfera) |
| `src\VOXELDEF` | i tre voxel sostituiscono gli sprite `treda`, `tblua`, `tgrna` (solo Doom: negli altri giochi il parser avvisa "sprite not found") |
| `src\sounds\` | `zpkwav.wav` (PCM 16 bit 11025 Hz, 440 Hz), `zpkflc.flac` (un frame verbatim, 8000 Hz), `zpkogg.ogg` (Vorbis mono con intestazioni fatte a mano: rumore, come i file dei test di `Libs\Sound`) |

Pixel noti (formati senza perdita): `(x, y)` = RGB `(32 + 3x, 32 + 3y, 32 + 3 (x xor y))` per BMP e TGA; PCX, patch e flat usano indici di
palette (formule in `Make-Pk3.ps1` e nei test). La patch ha il quadrato 8x8 in alto a sinistra trasparente e offset (32, 60).

Rigenerare: `powershell -NoProfile -ExecutionPolicy Bypass -File Tests\Data\Pk3\Make-Pk3.ps1`. L'uscita e' deterministica tranne PNG e
JPEG (encoder di System.Drawing); se cambiano, i test che guardano i pixel restano validi perche' PNG e JPEG sono controllati solo
nell'intestazione (la decodifica e' coperta da `Libs\Png` e `Libs\Jpeg`).

I nomi dei suoni (`zpkwav`...) non esistono negli IWAD: `s_pk3sounds` salta i nomi che un lump ha gia' (e` voluto: il campione
esterno vince comunque), quindi un file di prova con il nome di un suono vero non genera il WAD `pk3sounds_*`.
