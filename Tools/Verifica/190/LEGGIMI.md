# Verifica #190: i dati veri di Warcraft: Orcs & Humans

Dati forniti dall'utente in `Reference\_dati\_download\warcraft.zip` (non fidati: non si esegue nulla da li, **nemmeno `WAR.EXE`**;
si leggono solo byte). Gioco commerciale Blizzard 1994: **uso locale, non ridistribuibile, nessun dato nel repository**
(nel repository entrano solo questo script e i numeri dei golden). Voce in `Reference\_dati\MANIFEST.md`.

## Estrazione

```
powershell -NoProfile -File Extract-WarcraftDisk.ps1 `
  -Zip D:\...\Reference\_dati\_download\warcraft.zip `
  -Out D:\...\Reference\_dati\warcraft `
  -Cinematics D:\...\Reference\war1\cinematics.txt `
  [-ExpectedDataWarSha256 b3ecc379...]
```

`warcraft.zip` contiene `warcraft.img` (20971520 byte): **MBR** con una partizione FAT16 (tipo 0x06) che comincia al
**settore 32**, 512 byte per settore, 40575 cluster da 512 byte. Lo script (variante di `..\176\Extract-Fat12.ps1`) legge il
primo settore, trova la partizione, deduce FAT12/16 dal numero di cluster, legge anche i **nomi lunghi VFAT** (le voci
8.3 da sole darebbero `DOCUME~1`) e scrive i file in `-Out`, che deve essere vuota o inesistente (altrimenti si ferma).
Con `-Image` si passa direttamente un `.img`; floppy senza MBR (BPB al settore 0) funzionano uguale. FAT32 non e' previsto.

Uscite in `-Out`: i file (con le sottocartelle `DATA`, `DRIVERS`, `Documentation`, `Video Codec`), `SHA256SUMS.txt`
(sha256, byte, nome) e `REPORT.txt` con i controlli.

## Controlli e risultati (2026-11-13)

- 62 file, 17024766 byte; lunghezza estratta = lunghezza dichiarata per ogni file.
- `DATA\DATA.WAR`: 12852768 byte (come dice la issue), SHA-256 `b3ecc3794d4aa0ab09e83054ce9f47deb0fffeec929777e66bc47bfe9a435b64`,
  `archiveID` 0x18 = RETAIL (0x18 e 0x1A sono "retail", 0x19 "demo", come in `wfile_loadWarFile`), 583 voci, nessun segnaposto:
  **e' il gioco completo DOS**.
- Versione: `WAR.EXE` contiene `WARCRAFT CD VERSION 1.22h`; `README.TXT` "Revision 1.2" (storico fino a 1.21); testo **inglese**.
  Il pacchetto e' una distribuzione con DOSBox 0.74 (file `.bat`, `SDL.DLL`, `uninstall.exe`).
- Filmati (`Reference\war1\cinematics.txt`, 39 nomi): 13 presenti come `DATA\*.WAR`; **mancano** HMAP01-12, OMAP01-12, LOSE1, WIN1.
  Il remake non li legge da file.
