# Compila ed esegue event.pas ORIGINALE di xGreed (Reference\xGreed\Greed\event.pas, non modificato) sugli scenari di
# Tests\Source\DelphiDoom.Tests.Greed.EventScenarios e scrive i golden che il test di TGreedEvents confronta con la
# libreria (issue #175). Il codice originale resta in Reference\xGreed (sola lettura): event.pas, constant.pas,
# protos_h.pas, r_public_h.pas e r_refdef.pas si compilano come sono. Copie generate, fuori dal repository:
#   g_delphi.pas      con i soli cambi che Delphi 11 richiede (FormatSettings)
#   scriptengine.pas  con le stringhe a 8 bit che aveva in Delphi 7 (string -> AnsiString, PChar -> PAnsiChar,
#                     char -> AnsiChar): compilato com'e' con Delphi 11 copia meta' del testo (Move di Length
#                     caratteri da una stringa UTF-16) e non legge nessuno script
#   r_public.pas      le funzioni del mondo (RF_ClearWorld .. RF_GetCeilingZ) ritagliate dall'originale
# Il resto sono gli stub di stubs\ (e d_ints, d_misc, net, r_conten di ..\175-spawn\stubs): le variabili globali e le
# chiamate verso le parti che non sono di questo pezzo (SpawnSprite, DemandLoadMonster, SoundEffect, ActivationSound,
# DoPlayFLI, FN_PrintCentered, UpdateWait) annotate nel registro; d_disk da' i nomi e i testi dei lump degli scenari
# oppure, con -Dati, quelli del GREED.BLO del gioco completo letto con la libreria.
# Le copie generate e l'eseguibile stanno in %TEMP%\EventsGolden.
# Uso: .\Compila.ps1 [-Golden <file>] [-Dati <cartella di GREED.BLO> [-GoldenCompleto <file>]]
param(
  [string]$Golden = '',
  [string]$GoldenCompleto = '',
  [string]$Dati = 'C:\Progetti\DelphiDoom\Reference\_dati\greed\full',
  [string]$Riferimento = 'C:\Progetti\DelphiDoom\Reference\xGreed'
)
$radice = Resolve-Path "$PSScriptRoot\..\..\.."
if ($Golden -eq '') { $Golden = Join-Path $radice 'Tests\Data\Greed\events.golden.txt' }
if ($GoldenCompleto -eq '') { $GoldenCompleto = Join-Path $radice 'Tests\Data\Greed\events.full.golden.txt' }
$uscita = Join-Path $env:TEMP 'EventsGolden'
New-Item -ItemType Directory -Force $uscita, "$uscita\src" | Out-Null
$g = Get-Content "$Riferimento\Base\g_delphi.pas" -Raw
$g = $g -replace '(?<![\.\w])ThousandSeparator', 'FormatSettings.ThousandSeparator' -replace '(?<![\.\w])DecimalSeparator', 'FormatSettings.DecimalSeparator'
Set-Content "$uscita\src\g_delphi.pas" $g
$s = Get-Content "$Riferimento\Base\scriptengine.pas" -Raw
$s = $s -creplace '\bPChar\b', 'PAnsiChar' -creplace '\bchar\b', 'AnsiChar' -creplace '\bstring\b', 'AnsiString'
# ScriptPrintLineError (stampa le righe attorno a un errore dello script) legge una riga oltre la lista quando l'errore
# e' nelle ultime righe ("x2 := lst.Count") e l'originale muore con EStringListError dentro la stampa; dove finisce
# la lista dipende dalla memoria dopo il testo (il buffer non ha terminatore). Qui la stampa si ferma all'ultima
# riga: la libreria non stampa e non muore (differenza dichiarata), il resto della lettura si confronta
if (-not $s.Contains('x2 := lst.Count;')) { Write-Error 'scriptengine.pas: ScriptPrintLineError non trovata'; exit 1 }
$s = $s.Replace('x2 := lst.Count;', 'x2 := lst.Count - 1;')
# la variabile che ScriptError passa a sprintf (var s: string) resta una string
$s = $s -replace 's: AnsiString;(\s+begin\s+sprintf)', 's: string;$1'
Set-Content "$uscita\src\scriptengine.pas" $s
$r = Get-Content "$Riferimento\Greed\r_public.pas" -Raw
$inizio = $r.IndexOf('procedure RF_ClearWorld;', $r.IndexOf('implementation'))
$fine = $r.IndexOf('procedure RF_SetActionHook', $inizio)
if ($inizio -lt 0 -or $fine -lt 0) { Write-Error 'r_public.pas: funzioni non trovate'; exit 1 }
$testa = Get-Content "$PSScriptRoot\..\175-spawn\r_public.head.txt" -Raw
Set-Content "$uscita\src\r_public.pas" ($testa + $r.Substring($inizio, $fine - $inizio) + "`r`nend.`r`n")
$dcc = 'C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\dcc32.exe'
$u = "$PSScriptRoot\stubs;$uscita\src;$PSScriptRoot\..\175-spawn\stubs;$Riferimento\Greed;$Riferimento\Base;$radice\Libs\Greed;$radice\Libs\Platform;$radice\Libs\MathCore;$radice\Libs\Logging;$radice\Libs\Clock;$radice\Tests\Source"
# -CC: xGreed.inc dichiara {$APPTYPE GUI}, l'harness e' un programma da console
& $dcc -B -Q -CC -H- -W- "-U$u" "-I$Riferimento" "-N0$uscita" "-E$uscita" "-NSSystem;Winapi" "$PSScriptRoot\EventsGolden.dpr" | Select-String 'Error|Fatal'
if ($LASTEXITCODE -ne 0) { exit 1 }
# attraverso cmd: l'eseguibile ha il sottosistema GUI di xGreed.inc e PowerShell non ne aspetta l'uscita
if (Test-Path (Join-Path $Dati 'GREED.BLO')) {
  cmd /c "`"$uscita\EventsGolden.exe`" `"$Golden`" `"$GoldenCompleto`" `"$Dati`""
} else {
  Write-Host "senza $Dati\GREED.BLO: solo gli scenari sintetici"
  cmd /c "`"$uscita\EventsGolden.exe`" `"$Golden`""
}
exit $LASTEXITCODE
