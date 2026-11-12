# Compila ed esegue il confronto tra le routine ORIGINALI di raven.pas di xGreed che fanno vivere il livello
# (CheckItems, CheckWarps, CheckHere, CheckForSwitch, SwitchWall, CheckSpawnAreas, CheckBonusItem, TimeUpdate,
# NewGoalItem, startover, EndLevel, WarpAnim, PrepareNexus, JamWarps, piu' CheckElevators, CheckDoors, TryDoor e
# chargeweapons) e TGreedItemRules, TGreedSwitchRules e TGreedLevelRules di Libs\Greed (issue #175).
# Il codice originale resta in Reference\xGreed (sola lettura): le routine si ritagliano dal file originale, senza
# cambiarle, dentro una unit "raven" generata in %TEMP%\LevelParity\src (variabili dell'interfaccia comprese); di
# g_delphi.pas si genera la copia con i cambi che Delphi 11 richiede (FormatSettings). Il resto del gioco sono gli
# stub di stubs\ (spawn, utils, event, display, d_font, modplay, net, sprites ...) e quelli di ..\175-render\stubs
# (d_misc, menu); r_public, r_render e gli altri del renderer si compilano come sono.
# Uso: .\Compila.ps1 [-Golden ..\..\..\Tests\Data\Greed\level.golden.txt] [-Primo 0] [-Ultimo 31] [-Conta]
# -Conta: alla fine elenca quante volte l'originale ha fatto ogni chiamata e detto ogni messaggio (cio' che gli
# scenari raggiungono)
param(
  [switch]$Conta,
  [string]$Golden = '',
  [int]$Primo = 0,
  [int]$Ultimo = -1,
  [string]$Riferimento = 'C:\Progetti\DelphiDoom\Reference\xGreed'
)
$radice = Resolve-Path "$PSScriptRoot\..\..\.."
$uscita = Join-Path $env:TEMP 'LevelParity'
New-Item -ItemType Directory -Force $uscita, "$uscita\src" | Out-Null
$g = Get-Content "$Riferimento\Base\g_delphi.pas" -Raw
$g = $g -replace '(?<![\.\w])ThousandSeparator', 'FormatSettings.ThousandSeparator' -replace '(?<![\.\w])DecimalSeparator', 'FormatSettings.DecimalSeparator'
Set-Content "$uscita\src\g_delphi.pas" $g

$r = Get-Content "$Riferimento\Greed\raven.pas" -Raw
$impl = $r.IndexOf("`nimplementation")
# le variabili dell'interfaccia: da "const MOVEUNIT" alla prima procedura
$v1 = $r.IndexOf("const`r`n  MOVEUNIT")
$v2 = $r.IndexOf('procedure TimeUpdate;', $v1)
if ($impl -lt 0 -or $v1 -lt 0 -or $v2 -lt 0 -or $v2 -gt $impl) { Write-Error 'raven.pas: interfaccia non trovata'; exit 1 }
$variabili = $r.Substring($v1, $v2 - $v1)
# i ritagli: dall'intestazione di una routine a quella della prima che non serve
$tagli = @(
  @('procedure CheckElevators;', 'function GetTargetAngle'),
  @('function FindWarpDestination', 'function TryMove'),
  @('procedure CheckHere', 'function ClipMove'),
  @('procedure CheckSpawnAreas;', 'procedure RearView;'),
  @('procedure NewGoalItem;', 'procedure DrawHolo;'),
  @('procedure PrepareNexus;', 'procedure RunBrief;'),
  @('procedure JamWarps;', 'procedure SelectNewSong;')
)
$corpo = ''
foreach ($t in $tagli) {
  $a = $r.IndexOf("`n" + $t[0], $impl)
  if ($a -lt 0) { Write-Error "raven.pas: non trovo $($t[0])"; exit 1 }
  $b = $r.IndexOf("`n" + $t[1], $a)
  if ($b -lt 0) { Write-Error "raven.pas: non trovo $($t[1])"; exit 1 }
  $corpo += $r.Substring($a + 1, $b - $a)
}
# le intestazioni delle routine ritagliate diventano le dichiarazioni dell'interfaccia
$dichiarazioni = ([regex]::Matches($corpo, '(?m)^(procedure|function) [^\r\n]*;\r?$') | ForEach-Object { $_.Value.Trim() }) -join "`r`n"
$unit = @"
{`$I xGreed.inc}
unit raven;
// GENERATA da Tools\Verifica\175-level\Compila.ps1: le variabili e le routine sono ritagliate, senza cambi,
// da Reference\xGreed\Greed\raven.pas. Non modificare e non mettere nel repository.
interface
uses
  g_delphi, d_ints_h, d_video, protos_h, r_public_h;

$variabili
$dichiarazioni

implementation

uses
  constant, d_disk, d_ints, d_misc, d_font, display, event, i_windows, modplay, net, r_conten, r_public,
  r_refdef, r_render, spawn, sprites, utils, harness_host;

procedure PlayerCommand;
begin
end;

$corpo
end.
"@
Set-Content "$uscita\src\raven.pas" $unit

$dcc = 'C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\dcc32.exe'
$u = "$PSScriptRoot\stubs;$uscita\src;$PSScriptRoot\..\175-render\stubs;$Riferimento\Greed;$Riferimento\Base;$radice\Libs\Greed;$radice\Libs\Platform;$radice\Libs\MathCore;$radice\Libs\Logging;$radice\Libs\Clock;$radice\Tests\Source"
# -CC: xGreed.inc dichiara {$APPTYPE GUI}, l'harness e' un programma da console
& $dcc -B -Q -CC -H- -W- '-$O+' "-U$u" "-I$Riferimento" "-N0$uscita" "-E$uscita" "-NSSystem;Winapi" "$PSScriptRoot\LevelParity.dpr" | Select-String 'Error|Fatal'
if ($LASTEXITCODE -ne 0) { exit 1 }
if ($Golden -eq '') { $Golden = 'nessuno' }
if ($Ultimo -lt 0) { $Ultimo = 9999 }
# attraverso cmd: l'eseguibile ha il sottosistema GUI di xGreed.inc e PowerShell non ne aspetta l'uscita
$conteggi = ''
if ($Conta) { $conteggi = 'conta' }
cmd /c "`"$uscita\LevelParity.exe`" `"$Golden`" $Primo $Ultimo $conteggi"
exit $LASTEXITCODE
