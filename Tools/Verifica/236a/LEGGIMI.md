# Verifica #236a: profilo Quake III del parser

Produce `Tests\Data\Scanner\Q3\q3.golden.txt` con il codice **vero** di `l_script.c` e `l_precomp.c` (copiati senza modifiche da `Reference\quake3\codeotlib`, con `COM_Compress` di `q_shared.c` e gli stub di `Tools\VerificaT\stub`).

```
sh Tools/Verifica/236a/build.sh <cartella di uscita>
cd Tests/Data/Scanner/Q3 && <cartella>/q3scan.exe . cases.txt > q3.golden.txt
```

Formato dei casi e delle opzioni: intestazione di `q3scan.c`. `TTestQ3Golden` (`Tests\Source\DelphiDoom.Tests.Scanner.Q3.Golden.pas`) rifa gli stessi casi con le classi Delphi: cambiando uno si cambia l altro. Compilatore: gcc a 64 bit di w64devkit (`-ffp-contract=off`, `long double` x87 a 80 bit, `unsigned long` a 32 bit).
