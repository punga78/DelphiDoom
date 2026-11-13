# Verifica #191: parita' di Libs\War con il C del remake

`war1` (acoto87/war1, zlib) e' in `Reference\war1` (sola lettura). Il C originale che legge `DATA.WAR` si compila e si esegue
con gcc di `Reference\_dati\_strumenti\w64devkit` (a 32 bit; non c'e' un compilatore C nel PATH).

```
powershell -NoProfile -File Compila-WarRef.ps1 -Out <cartella nuova fuori dal repository>
war_ref.exe <DATA.WAR> list            > datawar.retail.golden.txt          (come wg_loadDataFile: salta le voci sconosciute)
war_ref.exe <DATA.WAR> list noskip     > datawar.retail.noskip.golden.txt
war_ref.exe - catalog                  > catalog.golden.txt
war_ref.exe <DATA.WAR> dump N file     (i byte espansi del record N)
powershell -NoProfile -File Make-WarCatalog.ps1 -Catalog catalog.golden.txt -Out Libs\War\DelphiDoom.War.Catalog.Data.pas
```

`Compila-WarRef.ps1` **non modifica** il remake: legge `war_file.c` (le due letture little endian, `wfile_loadWarFile`,
`wfile_freeWarFile`), `war_resources.h` (`WarRawResource`, `WarFile`), `war_enums.h` (`DatabaseEntryType`) e `war_database.h`
(`assets[]`), li scrive alla lettera in `-Out` (cercando le righe per testo) e li compila con `war_ref.c`, che ha soltanto gli
stub di SDL (`SDL_IOFromFile` ecc. su `stdio`), Tracy, `wm_alloc` (-> `calloc`) e `logError` (-> stdout, righe `E`). Su
`DATA.WAR` non esce nessuna riga `E`. `war_ref.c` e' una versione modificata del remake solo per far girare quel codice.

Risultato (2026-11-13, `DATA.WAR` DOS 12852768 byte): `H 24 583 2`; 542 voci compresse; 68 saltate col catalogo; `Tests\DelphiDoom.Tests.War`
da' le stesse 583 righe (offset, compresso, lunghezze, CRC-32 dei byte espansi).
Per compilare i test in un worktree serve `DCC_UnitSearchPath` con la cartella `DUnitX\Source` (vedi `Libs\War\CLAUDE.md`).
