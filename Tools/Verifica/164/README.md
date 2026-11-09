# Verifica della issue #164 (ENDEDIT nel sistema a classi)

I golden di `Tests\Data\ToolsCore`, `Tests\Data\Endoom\editor.golden.txt`, `Tests\Data\Endoom\textart.golden.txt` e
`Tests\Data\Imaging\lanczos.golden.txt` sono stati scritti dal **vecchio codice di ENDEDIT** (`Reference\ENDEDIT`, mai
modificato) compilato con Delphi 11 in un programma di prova. I programmi sono qui; non si compilano con `Tools\build.bat`.

| Programma | Cosa fa | Scrive |
|---|---|---|
| `H1\H1.dpr` | `TFileMenuHistory`, `MkShortName`, `ee_defs`, `TUndoRedoManager` su scenari fissi | `Tests\Data\ToolsCore\old.golden.txt` |
| `H2.dpr` + `H2Old.pas` | `TEndScreen` (`ee_screen`) e gli strumenti di `main.pas` (copiati in `H2Old`) sui casi di `Tests\Source\DelphiDoom.Tests.Endoom.EditorScenarios` | `Tests\Data\Endoom\editor.golden.txt` |
| `H3.dpr` | `BitmapToScreen` di `ee_textart` con il Graphics32 originale (`-DVER340`) e il suo `BitmapLanczosDraw`, sulle immagini di `Tests\Source\DelphiDoom.Tests.Imaging.ResampleCases` | le righe `RESAMPLE` (-> `lanczos.golden.txt`, `nome=impronta`) e `TEXTART` (-> `textart.golden.txt`) |

Come rifarli: copiare `Reference\ENDEDIT` in `<lavoro>\src` (con `Graphics32\` e `obj\`; in `pngimage.pas` `pChar` va in `PAnsiChar`),
aggiungervi i file di questa cartella, poi `b.ps1 -Dpr H2.dpr -Work <lavoro> -Extra "<repo>\Libs\Endoom;<repo>\Tests\Source"`
(`-Defs VER340` per H3) e lanciare l'eseguibile di `<lavoro>\out` con il file di uscita come argomento. Le impronte sono FNV-1a a 64 bit
(`DelphiDoom.Tests.Endoom.Digest`); i pixel si confrontano senza il byte alpha.

I casi sono generati da unit condivise tra programma e test (stessi ingressi); se si cambiano, vanno rifatti i golden.
