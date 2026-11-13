# Verifica #113: profilo Quake III della console

Produce `Tests\Data\Console\Q3\*.golden.txt` con il codice **vero** di Quake III (`cmd.c`, `cvar.c`), non riscritto: `build.sh` ritaglia per intervalli di righe `qcommon\cmd.c` e `cvar.c`, `Q_strncpyz`, `Q_stricmpn`, `Q_stricmp`, `Com_sprintf`, `va`, `COM_DefaultExtension` e `Info_*` di `game\q_shared.c`, `Com_StringContains` e `Com_Filter` di `qcommon\common.c`, e i tipi di `game\q_shared.h`; `stubs.h` e l'inizio di `driver.c` sostituiscono il resto del motore (`Com_Printf` e `Com_DPrintf` su buffer, file virtuali di `exec`, `CL_ForwardCommandToServer` che stampa `forward <testo>`); il resto di `driver.c` sono le operazioni degli scenari.

```
sh Tools/Verifica/113q3/build.sh <cartella di uscita>
<cartella>/q3console.exe Tests/Data/Console/Q3/commands.scn > Tests/Data/Console/Q3/commands.golden.txt
<cartella>/q3console.exe Tests/Data/Console/Q3/cvars.scn > Tests/Data/Console/Q3/cvars.golden.txt
```

- Compilatore: gcc a 64 bit di `Reference\_dati\_strumenti\w64devkit`, `-O0 -fwrapv`.
- Gli scenari (`*.scn`, un'operazione per riga, campi separati da tab, escape `\n \t \r \\ \xNN`) sono scritti per i test, senza testo di Quake III. Li suona anche `Tests\Source\DelphiDoom.Tests.Console.Q3.Scenario.pas`: se si cambia un'operazione vanno rifatti entrambi.
- `Cvar_Restart_f` del C azzera solo il primo puntatore della struttura (`sizeof(var)`): gli scenari non usano `vmupd` su una variabile tolta (in Delphi lo slot e' marcato `Removed`).
- `Cvar_Set_f` con un argomento vuoto legge oltre la stringa (comportamento indefinito): gli scenari non lo usano. `exec` con nome vuoto e valori float "a meta'" di `Cvar_SetValue` (`%f`) idem.
