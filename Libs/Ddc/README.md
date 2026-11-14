# Libs\Ddc

> Note per Claude e paragrafi di dettaglio (issue #178): [CLAUDE.md](CLAUDE.md).

Il **compilatore degli script da riga di comando e in DLL** (issue #172, spostato qui da `SCRIPT\`).

| File | Ruolo |
|---|---|
| `ddc.dpr`, `ddc.dproj`, `ddc_icon.res` | il programma `ddc.exe` (console; uscita in `bin\Win32\Release\Tools`) |
| `cmdline_compiler.pas` | lettura dei parametri e compilazione del file indicato |
| `ddc_base.pas` | trasporto verso la DLL `ddc_<gioco>.dll`: le usa anche DD_IDE (`DD_IDE\DelphiDoom.Ide.Win.DdcLibrary`) |
| *(`dd_compiler.pas`)* | spostato in `Libs\ScriptEngine` (issue #221): e' l'implementazione delle DLL `ddc_<gioco>` e usa `deh_*`, `info*` e `sc_*` dei giochi |

I progetti `ddc_doom`, `ddc_heretic`, `ddc_hexen` e `ddc_strife` (le DLL, una per gioco) restano nelle cartelle dei giochi e usano `..\Libs\Ddc\ddc_base.pas` e `..\Libs\ScriptEngine\dd_compiler.pas`: sono loro il composition root dei compilatori per gioco. Questa cartella non usa piu' `Base`, i giochi ne' `Common`.

Compilare: `Tools\build.bat ddc` (e `ddc_doom`, ...); i parametri sono in `cmdline_compiler.pas`.
