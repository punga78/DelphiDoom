# RUN-41 — issue #41 (assembler inline in Pascal)

Niente di questo è stato eseguito da chi ha scritto il codice (nessun compilatore a disposizione): le
verifiche vanno fatte nell'ordine qui sotto. Tutti i comandi dalla radice del repository (o del worktree).

## 1. Compilazione

```
Tools\build.bat Tests\DelphiDoom.Tests.AsmParity
Tools\build.bat Tests\DelphiDoom.Tests.MathCore
Tools\build.bat giochi
Tools\build.bat strumenti
```

Leggere `logs\DelphiDoom.Tests.AsmParity.log`, `logs\DelphiDoom.Tests.MathCore.log`, `logs\<progetto>.log`
(righe `error`, poi i warning nuovi). Attesi: 0 errori. Warning nuovi possibili: nessuno voluto.

## 2. Test di parità

```
bin\Tests\DelphiDoom.Tests.AsmParity.exe --exitbehavior:Continue
bin\Tests\DelphiDoom.Tests.MathCore.exe --exitbehavior:Continue
```

Attesi: `DelphiDoom.Tests.AsmParity` 36 test, tutti verdi (sono circa 30 s: ogni funzione di `m_fixed` gira su
un milione di coppie, quelle che sollevano eccezioni su centomila); `DelphiDoom.Tests.MathCore` 113
test (101 di prima più 12 nuovi), tutti verdi. `Tools\build.bat tests` li esegue entrambi (il progetto Asm è
nella variabile `TESTS`).

Se un test di parità fallisce il messaggio dice la prima differenza, per esempio
`FixedMul: a=$00010000 b=$7FFFFFFF old=$... new=$...` (a e b sono gli ingressi in esadecimale, old è
l'`asm`, new il Pascal; `exception` vuol dire che la funzione ha sollevato). Due funzioni sono uguali
se danno lo stesso numero o se sollevano tutte e due.

Test che non girano su certi processori (non è un errore):

- `DovrebbeDimezzareCometDreNowSeCeLIstruzione`: se il processore non ha 3DNow (AMD li ha tolti con Zen)
  il test passa dicendo che salta; resta la prova del Pascal contro la formula di `pavgusb`.
- Se il processore non ha MMX i test di `memset` e `r_mmx` confrontano comunque il ripiego della RTL.

Test che documentano le differenze volute dal vecchio:

- `DovrebbeScrivereAncheLUltimoValoreDiMemsetiConUnNumeroDispari` fallisce con il `d_delphi.pas` di
  prima della correzione (`while count > 4`), passa ora.
- `DovrebbeLasciareInvariatiICharSopraDuecentocinquantacinque` fallisce con il vecchio `asm` di
  `toupper`/`tolower` (guardava il byte basso: `$0161` diventava `$0141`).

## 3. Prestazioni a 32 bit (devono restare dentro il +5%)

A 32 bit il codice del motore è quello di prima (l'`asm` resta sotto `{$IFDEF CPUX86}`); i soli
cambiamenti sul percorso di esecuzione sono `toupper`/`tolower` (Pascal), `memseti` (`>= 4`) e
`StrLCopy` (mai chiamata). Prima di compilare il nuovo eseguibile copiare il vecchio:

```
Tools\build.bat Doom32 Release            # sul commit PRECEDENTE (master): produce bin\Doom\Doom32.exe vecchio
copy bin\Doom\Doom32.exe bin\Doom\Doom32.old.exe
git checkout <branch della #41>
Tools\build.bat Doom32 Release            # nuovo
powershell -NoProfile -File Tools\Verifica\41\Confronta-timedemo.ps1 `
  -OldExe bin\Doom\Doom32.old.exe -NewExe bin\Doom\Doom32.exe `
  -Arguments '-iwad DOOM1.WAD -timedemo demo1 -nomusic -nosound' -Runs 5
```

Ripetere con `demo2` e `demo3`, e con `GLDoom32` se serve. Atteso: `OK`, gametic uguali tra vecchio e
nuovo (se cambiano, la simulazione è cambiata: è un errore grave), differenza dei realtic mediana
entro +5%. Il confronto passa da `Tools\Esegui-gioco.ps1` (un'esecuzione per volta).

Micro benchmark asm contro Pascal (spiega perché a 32 bit l'`asm` resta):

```
C:\Strumenti\delphi-build.cmd Tools\Verifica\41\BenchAsm.dpr Release Win32
Tools\Verifica\41\BenchAsm.exe
```

Stampa i ns per operazione di `FixedMul`, `FixedMul88`, `_SHR14`, `FixedDiv2` e `FillDWord` in `asm` e in
Pascal. Se in `Release` un Pascal pareggia l'`asm` (differenza sotto il 5%) l'`{$IFDEF CPUX86}` di quella
funzione si può togliere; non è stato fatto senza la misura.

## 4. Avvio dei giochi

```
powershell -NoProfile -File Tools\Esegui-gioco.ps1 -Exe bin\Doom\Doom32.exe `
  -Arguments '-iwad FREEDOOM2.WAD -warp 1 -devparm -nomusic' -Seconds 25
```

Per i quattro giochi (software e OpenGL, 8 eseguibili): atteso vivo dopo 25 s, nessun `crash.txt`,
nessun `I_Error` in `DATA\LOGS\*_stderr.txt`.

## 5. Cosa NON è stato verificato

- Win64: nel repository non c'è ancora una configurazione a 64 bit (`TargetedPlatforms=1` in tutti i
  `.dproj`); i rami `{$ELSE}` (Pascal) di `m_fixed`, `p_local`, `r_softlights`, `r_mmx`, `d_delphi` sono
  compilati solo quando `CPUX86` non è definito, quindi **non sono mai stati compilati**: sono corpi di
  una riga che chiamano le classi di `Libs\MathCore` testate contro l'`asm` (vedi sopra). Per controllarne
  almeno la sintassi a 32 bit, in una copia di lavoro (da non committare) mettere `{$UNDEF CPUX86}`
  come prima riga di `Base\m_fixed.pas`, `Base\p_local.pas`, `Base\r_softlights.pas`, `Base\r_mmx.pas`
  e `Common\d_delphi.pas` (subito dopo `{$I Doom32.inc}` dove c'è) e fare `Tools\build.bat Doom32 Release`: se
  compila, i rami Pascal sono corretti per la sintassi (le prestazioni e la parità si provano come sopra).
- `SCRIPT\ps_runtime.pas` (`x86.inc`, `x64.inc`): lasciato com'è; vedi `PENDING_ISSUES.md`.
