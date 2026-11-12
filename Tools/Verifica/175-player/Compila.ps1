# Compila ed esegue il codice ORIGINALE di xGreed che comanda il giocatore e le sue armi (Reference\xGreed\Greed\raven.pas
# e sprites.pas, non modificati) sugli scenari di Tests\Source\DelphiDoom.Tests.Greed.PlayerScenarios e scrive il golden
# che il test di TGreedPlayerControl confronta con la libreria (issue #175). Il codice originale resta in
# Reference\xGreed (sola lettura): constant.pas, protos_h.pas, r_public_h.pas, r_refdef.pas e d_ints_h.pas si compilano
# come sono; di g_delphi.pas si genera una copia con i soli cambi che Delphi 11 richiede (FormatSettings); dai file
# originali si ritagliano, dentro unit generate:
#   raven.pas    le variabili dell'interfaccia; GetTargetAngle e fireweapon; TryDoor, TryMove, CheckHere, chargeweapons,
#                ClipMove, Thrust, ControlBobbing, ControlMovement, PlayerCommand, newlights, ChangeScroll; la parte
#                dell'arma di UpdateView (H_WeaponView) e il ciclo dell'arma in fondo a PlayLoop (H_WeaponMode)
#   sprites.pas  SP_TryDoor, SP_TryMove, SP_ClipMove, SP_Thrust
#   r_public.pas le funzioni del mondo (RF_ClearWorld .. RF_GetCeilingZ)
# Il resto sono gli stub di stubs\ (e r_conten, d_misc di ..\175-spawn\stubs): le variabili globali e le chiamate
# verso le parti non di questo pezzo (SpawnSprite, SoundEffect, RunEvent, CheckForSwitch, SwitchWall, RF_SetLights,
# loadweapon) annotate nel registro. Le copie generate e l'eseguibile stanno in %TEMP%\PlayerGolden, fuori dal
# repository.
# Uso: .\Compila.ps1 [-Golden <file>] [-Completo <file con i valori di ogni tic> -Scenario <n>]
param(
  [string]$Golden = '',
  [string]$Completo = '',
  [int]$Scenario = 0,
  [string]$Riferimento = 'C:\Progetti\DelphiDoom\Reference\xGreed'
)
$radice = Resolve-Path "$PSScriptRoot\..\..\.."
if ($Golden -eq '') { $Golden = Join-Path $radice 'Tests\Data\Greed\player.golden.txt' }
$uscita = Join-Path $env:TEMP 'PlayerGolden'
New-Item -ItemType Directory -Force $uscita, "$uscita\src" | Out-Null

function Ritaglia([string]$testo, [string]$da, [string]$a, [int]$inizioRicerca) {
  $inizio = $testo.IndexOf($da, $inizioRicerca)
  if ($inizio -lt 0) { throw "non trovato: $da" }
  $fine = $testo.IndexOf($a, $inizio)
  if ($fine -lt 0) { throw "non trovato: $a" }
  return $testo.Substring($inizio, $fine - $inizio)
}

$g = Get-Content "$Riferimento\Base\g_delphi.pas" -Raw
$g = $g -replace '(?<![\.\w])ThousandSeparator', 'FormatSettings.ThousandSeparator' -replace '(?<![\.\w])DecimalSeparator', 'FormatSettings.DecimalSeparator'
Set-Content "$uscita\src\g_delphi.pas" $g

# r_public: le funzioni del mondo
$r = Get-Content "$Riferimento\Greed\r_public.pas" -Raw
$mondo = Ritaglia $r 'procedure RF_ClearWorld;' 'procedure RF_SetActionHook' $r.IndexOf('implementation')
Set-Content "$uscita\src\r_public.pas" ((Get-Content "$PSScriptRoot\r_public.head.txt" -Raw) + $mondo + (Get-Content "$PSScriptRoot\r_public.tail.txt" -Raw))

# sprites: il passo della sonda
$s = Get-Content "$Riferimento\Greed\sprites.pas" -Raw
$sonda = Ritaglia $s 'function SP_TryDoor(' 'function SP_TryMove2(' $s.IndexOf('implementation')
Set-Content "$uscita\src\sprites.pas" ((Get-Content "$PSScriptRoot\sprites.head.txt" -Raw) + $sonda + "`r`nend.`r`n")

# raven: variabili, routine del giocatore, i due pezzi di UpdateView e PlayLoop
$v = Get-Content "$Riferimento\Greed\raven.pas" -Raw
$impl = $v.IndexOf('implementation')
$variabili = Ritaglia $v 'const' 'procedure TimeUpdate;' $v.IndexOf('interface')
$armi = Ritaglia $v 'function GetTargetAngle(' 'function FindWarpDestination(' $impl
$comandi = Ritaglia $v 'function TryDoor(' 'function Check_Secret(' $impl
$vista = $v.IndexOf('procedure UpdateView(', $impl)
$inizioArma = $v.IndexOf('  if weapbobon then', $vista)
$fineArma = $v.LastIndexOf('if netmode then', $v.IndexOf('if weapmode = 0 then', $inizioArma))
$ciclo = $v.IndexOf('procedure PlayLoop;', $impl)
$inizioModo = $v.IndexOf('while (weapmode <> 0) and (timecount >= weapdelay) do', $ciclo)
$fineModo = $v.LastIndexOf('if netmode then', $v.IndexOf('I_FinishUpdate;', $inizioModo))
if ($inizioArma -lt 0 -or $fineArma -lt $inizioArma -or $inizioModo -lt 0 -or $fineModo -lt $inizioModo) { Write-Error 'raven.pas: pezzi di UpdateView o PlayLoop non trovati'; exit 1 }
$arma = "procedure H_WeaponView(const update: integer; var weaponx, weapony: integer);`r`nvar`r`n  wbobx, wboby: integer;`r`nbegin`r`n  if update <> 0 then`r`n    weapbob1 := weapbob;`r`n  weaponx := wx;`r`n  weapony := wy;`r`n" +
  $v.Substring($inizioArma, $fineArma - $inizioArma) + "`r`n  end;`r`nend;`r`n`r`n"
$modo = "procedure H_WeaponMode;`r`nbegin`r`n    " + $v.Substring($inizioModo, $fineModo - $inizioModo) + "`r`nend;`r`n`r`n"
Set-Content "$uscita\src\raven.pas" ((Get-Content "$PSScriptRoot\raven.head.txt" -Raw) + $variabili + (Get-Content "$PSScriptRoot\raven.mid.txt" -Raw) + $armi + $comandi + $arma + $modo + "end.`r`n")

$dcc = 'C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\dcc32.exe'
$u = "$PSScriptRoot\stubs;$uscita\src;$PSScriptRoot\..\175-spawn\stubs;$Riferimento\Greed;$Riferimento\Base;$radice\Tests\Source"
& $dcc -B -Q -H- -W- "-U$u" "-I$Riferimento" "-N0$uscita" "-E$uscita" "-NSSystem;Winapi" "$PSScriptRoot\PlayerGolden.dpr" | Select-String 'Error|Fatal'
if ($LASTEXITCODE -ne 0) { exit 1 }
if ($Completo -eq '') { & "$uscita\PlayerGolden.exe" $Golden } else { & "$uscita\PlayerGolden.exe" $Golden $Completo $Scenario }
exit $LASTEXITCODE
