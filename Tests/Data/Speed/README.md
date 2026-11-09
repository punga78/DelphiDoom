# Tests\Data\Speed

Golden del vecchio traduttore di Speed Haste (`Reference\Speed\Speed\speed_xlat_wad.pas`, fork di DelphiDoom 2.05). Un file per gioco:

| File | Dati | Righe |
|---|---|---|
| `translation.shareware.golden.txt` | `SPEEDH.JCL` dello shareware di Speed Haste (6425960 byte, SHA-256 `95f65355...`, vedi `Reference\_dati\MANIFEST.md`) | 1664 |
| `translation.synthetic.golden.txt` | `TJclBuilder.SyntheticGame` (`Tests\Source\DelphiDoom.Tests.Speed.JclBuilder.pas`, 363236 byte) | 1154 |

Formato: `lumps N`, poi per ogni lump `indice nome dimensione impronta` (FNV-1a a 32 bit dei byte, 8 cifre esadecimali; `0 00000000` per un lump vuoto), poi le voci
`pak posizione dimensione nome` che il vecchio codice aggiungeva al file system PAK (`PAK_AddEntry`: i modelli `MODELS\x.I3D`).

## Come sono stati fatti (harness fuori dal repository)

1. Una copia di `Reference\Speed` con le correzioni minime per compilare con Delphi 11 (`Reference\_analisi\fetta0.md`: direttive del `.dpr`, `FormatSettings`,
   PascalScript, `PAnsiChar`, `char8_t`...) più le correzioni dei difetti Unicode che cambiano **il dato letto** (non il risultato dei calcoli):
   `speedlump_t.filename` in `AnsiChar`, `CIRCUITS.LST` letto con un `PAnsiChar`, `TWadWriter.AddString` con un byte per carattere, `TDStrings.GetTextStr` con `L * SizeOf(Char)`
   byte e `sc_engine` (dopo circa 90 token dava caratteri a caso) sostituito da un dividitesto che separa sugli spazi e rispetta le virgolette.
2. `PAK_AddEntry` registra le chiamate; un programma console chiama `Speed2WAD_Game(jcl, wad)`, rilegge il WAD scritto e stampa le righe.
3. Il gioco sintetico lo scrive `TJclBuilder` (la stessa unit dei test); le immagini dei patch (`Tests\Data\GameData`) le fa `TGameDataScenarios`.

Il vecchio codice dà gli stessi byte in Win32 con `Double` (rumore di Perlin dei font): la libreria è confrontata in Win32.
