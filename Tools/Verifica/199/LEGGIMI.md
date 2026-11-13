# Tools\Verifica\199 - parita' del decoder FLIC (issue #199)

Strumenti che producono le risposte di riferimento di `DelphiDoom.Cinematic.Flic.*` con il **codice di OpenXcom** (`Reference\OpenXcom\src\Engine\FlcPlayer.cpp`, sola lettura): il remake di Warcraft (`Reference\war1`) non ha codice FLIC. Il gcc e' quello di `Reference\_dati\_strumenti\w64devkit`.

- `build.sh [cartella]` (sh, da Git Bash, fine riga LF): costruisce `flc_original.inc` con intervalli di righe di `FlcPlayer.cpp`, compila `flcextract.exe` (g++, con `shim\SDL.h` al posto di SDL e il vero `FlcPlayer.h` con i membri privati aperti), `flcgen.exe` e `flcscan.exe`. `DELPHIDOOM_ROOT` cambia la radice (default `/c/Progetti/DelphiDoom`).
- `flcextract file.flc`: `header ...`, poi per ogni fotogramma `frame N pix <crc32 dell'immagine> pal <crc32 dei 768 byte della palette> delay <ms>`; con `FLCDUMP=1` anche `dump N <pixel in esadecimale>`.
- `flcgen basic|fli|wide|tall out.flc`: file di prova (semi fissi, nessun materiale commerciale).
- `flcscan file`: elenca fotogrammi e chunk.

Per rifare `Tests\Data\Cinematic\flic-*`: `flcgen.exe basic flic-basic.flc` (idem `fli`, `wide`, `tall`), `flcextract.exe flic-basic.flc > flic-basic.golden.txt`; per i filmati veri `flcextract.exe <DATA>\TITLE.WAR > flic-war-TITLE.golden.txt` (solo i CRC vanno nel repository).