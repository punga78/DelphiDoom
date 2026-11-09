# Tools\Verifica\169 - il vecchio traduttore di Radix

`RadixXlatDump.dpr` e `build.sh` producono i golden di `Tests\Data\Radix` (vedi il `README.md` di quella cartella).

1. `SRC` in `build.sh` e' la copia `Reference\_dati\radix_indagine\src` (non e' nel repository: cartella ignorata, creata dalla fetta 0 e dall'indagine sul crash di Rad-X).
2. `bash build.sh RadixXlatDump.dpr` dalla cartella che contiene il `.dpr` (le uscite vanno in `out\` e `dcu\` accanto): compila con `dcc32` (Win32).
3. `out\RadixXlatDump.exe <RADIX.DAT> <wad> <golden.txt>`.

Il programma non e' parte delle build del repository.
