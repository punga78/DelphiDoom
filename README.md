# DelphiDoom

Source port di Doom, Heretic, Hexen e Strife in Delphi (versione software e OpenGL).
Ultima versione: <https://sourceforge.net/projects/delphidoom/files/DelphiDoom%202.0.7/>
Sito: <https://sourceforge.net/projects/delphidoom/>

## Documentazione

Tutta la documentazione sta in `docs\`.

| Documento | Contenuto |
|---|---|
| `CLAUDE.md` (radice) | istruzioni del repository: build, librerie, stato di ogni area |
| `docs\FACCIATE.md` | le facciate storiche e cosa le sostituisce |
| `docs\PENDING_ISSUES.md` | cosa resta aperto e perche |
| `docs\INTEGRAZIONE_GIOCHI.md` | integrazione tra i quattro giochi |
| `docs\RUN.md`, `docs\RUN-*.md` | come compilare e provare le singole issue |
| `docs\Doom_what's new.txt`, `Heretic_`, `Hexen_`, `Strife_` | novita di ogni versione dei giochi |
| `docs\ACTORDEF.readme.txt`, `MODELDEF.readme.txt`, `VOXELDEF.readme.txt` | formati dei lump di definizione |
| `docs\udmf_delphidoom.txt` | estensioni UDMF |
| `docs\HI-RES.txt`, `docs\MP3.txt`, `docs\SCRIPT.txt` | texture hi-res, musica mp3, script |

## Struttura e comandi principali

- Progetti: `Doom\Doom32.dpr`, `Doom\GLDoom32.dpr`, `Heretic\`, `Hexen\`, `Strife\` (software e OpenGL, piu `ddc_<gioco>`), `Launcher\`, `DD_IDE\`, `DD_Tools\`, `Libs\Ddc\ddc.dpr`, `Keen\`, DLL in `Libs\<Lib>\DD*.dpr`, test in `Tests\`.
- Gruppo di progetti per l'IDE: `DelphiDoom.groupproj`.
- Costruzione senza IDE (da qualsiasi cartella):

```
Tools\build.bat                     # Doom32, Release
Tools\build.bat all                 # tutti i progetti
Tools\build.bat giochi | strumenti | librerie | tests
Tools\build.bat Heretic32 Debug     # un progetto
```

- Uscite in `bin\`, `.dcu` in `dcu\`, log in `logs\<progetto>.log`.

## Caratteristiche

- Renderer software a 32 bit
- OpenGL con modelli md2 e lightmap dinamiche
- Texture hi-res esterne, voxel
- Musica mp3, midi, mod, s3m, it, xm, xmi, cmf e sop
- Pavimenti 3D (uno per settore), pendenze
- Formato UDMF, UMAPINFO, MBF21
- Motore di script (PascalScript) per livelli e attori, ACS
- Definizione di attori (lump ACTORDEF)
- Console per variabili d'ambiente e comandi
- Automap con rotazione, overlay e texture
- Fino a 256 CPU logiche nel renderer software
- Effetti sonori wav, flac e ogg nei WAD
- Quasi tutte le funzioni BOOM, motore senza limiti, nodi GL v5
- Namespace HI_START/HI_END, nomi lunghi nei WAD
- Framerate libero, camera di inseguimento, schermi panoramici

Esempi di editing: <https://sourceforge.net/projects/delphidoom/files/Tools%2C%20maps%20and%20examples/>

## Requisiti

Windows con DirectX (renderer software) e scheda con OpenGL (renderer hardware). PC moderno con processore da 1,5 GHz; sfrutta i sistemi multiprocessore.

## Licenza e origini

GNU General Public License versione 2 o successiva.

- DelphiDoom: basato su Linux Doom di "id Software" (C) 1993-1996 id Software, Inc.; (C) 2004-2022 Jim Valavanis.
- DelphiHeretic e DelphiHexen: basati su Linux Doom, sul codice di Heretic e Hexen di Raven Software e su DelphiDoom.
- DelphiStrife: basato su Linux Doom, Chocolate Strife (Simon Howard, James Haley, Samuel Villarreal) e DelphiDoom.

## Ringraziamenti

idSoftware per Doom; Raven per i sorgenti di Heretic e Hexen; TeamTNT per BOOM; Entryway per PrBoom-Plus; Andrew J. Apted per glbsp; Randy Heit e Graf Zahl per zDoom; Fraggle, Quasar e Kaiser per Chocolate Strife; RemObjects per PascalScript; Angus Johnson per l'algoritmo di clipping di Bala Vatti; Gertjan Schouten per la libreria di immagini.
