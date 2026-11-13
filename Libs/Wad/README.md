# Libs\Wad

Lettura e scrittura di WAD, PAK, ZIP e cartelle; directory dei lump del motore.

Il testo di riferimento (paragrafi spostati dal CLAUDE.md di radice, issue #178) sta in [CLAUDE.md](CLAUDE.md).

## Contenuto

- Unit nella cartella: 37 (nome a punti `DelphiDoom.Wad.*`).
- Interfacce dichiarate: `ILumpCache`, `ILumpReader`, `IPakIndex`, `IPakPathResolver`, `IWadBuilder`, `IWadDirectory`, `IWadDll`, `IWadDllBuilder`.
- Punto di creazione delle classi: `DelphiDoom.Wad.Factory`.
- Progetti nella cartella: `DDWad`.

## Prova

- Progetto di test in `Tests\`: `DelphiDoom.Tests.Wad`. Si compila con `Tools\build.bat` (vedi "Build e prove" nel [CLAUDE.md di radice](../../CLAUDE.md)).

## File system di id Tech 4 (issue #99, prima fetta)

Ricerca di file per **percorso relativo** nella lista di cartelle e pak di Doom 3 (`framework\FileSystem.cpp`), a parte dalla directory dei lump. Codice derivato da Doom 3 (GPL v3 con i termini aggiuntivi di Doom 3, intestazione "Based on the Doom 3 GPL Source Code (id Software)" nelle unit `DelphiDoom.Wad.Fs.*`, come in `Libs\IdLib`).

- `IGameFileSystem` / `TGameFileSystem` (creato da `TGameFileSystemFactory`): `Startup` costruisce la lista da `fs_cdpath`, `fs_basepath`, `fs_devpath`, `fs_savepath`, `fs_game_base`, `fs_game` (`TGameFsSettings`); `OpenFileRead`, `ReadFile`, `FileLength`, `FileIsInPak`, `ListFiles`, `ListFilesTree`, `SearchPaths`, `PackChecksums`.
- Ordine di ricerca come l'originale: l'ultimo aggiunto per primo (save sopra dev sopra base sopra cd; `fs_game` sopra `fs_game_base` sopra `base`); dopo ogni cartella i suoi `*.pk4` dall'ultimo in ordine alfabetico senza maiuscole (`pak001` prima di `pak000`); un file in cartella batte i pak della stessa cartella; nomi senza maiuscole e con `\`, `/` e `:` uguali; `..` e `::` rifiutati.
- Disco e pak: `IGameDisk` (`TGameDisk` sul disco vero; nei test un disco in memoria), `IGamePackLoader` (`TZipPackLoader`), `IGamePack` (`TGamePack`: nomi in minuscolo, tabella hash a 1024 secchi, l'ultima voce doppia vince, checksum MD4 dei CRC come `pack_t.checksum` con `TIdMd4` di `Libs\IdLib`). **Lo ZIP lo legge `TZipFileSource`**, esteso con `IZipArchive` (voci come memorizzate, CRC, dimensione) e un costruttore da stream.
- Non portato: scrittura (`OpenFileWrite`, `WriteFile`, `fs_copyfiles`), server "pure" (checksum, riavvio, `serverPaks`), lettura di `addon.conf` (un pak addon e' riconosciuto e tenuto fuori dalla lista, ma dipendenze e `mapDef` non si leggono: serve il lexer), `binary.conf`, `ListMods`, journal, chiavi, `FindDLL`, download dei pak, `fs_caseSensitiveOS`. `idFile` e' ridotto a `IGameFile` (lettura intera, niente `Seek`/`Read` a pezzi).

Prova: 68 test in `Tests\Source\DelphiDoom.Tests.Wad.GameFileSystem.pas`, con i valori di parita' prodotti dal C++ di Doom 3 (cicli copiati alla lettera, compilati con `bcc32c`: `Tests\Data\Wad\GameFs\fsparity.cpp`).

## Legami

- Indice delle librerie e regole generali: [CLAUDE.md di radice](../../CLAUDE.md).
