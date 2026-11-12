# Compila ed esegue SpawnSprite ORIGINALE di xGreed (Reference\xGreed\Greed\spawn.pas, non modificato) sugli scenari di
# Tests\Source\DelphiDoom.Tests.Greed.SpawnScenarios e scrive il golden che il test di TGreedSpawner confronta con la
# libreria (issue #175). Il codice originale resta in Reference\xGreed (sola lettura): spawn.pas, constant.pas,
# protos_h.pas, r_public_h.pas e r_refdef.pas si compilano come sono; di g_delphi.pas si genera una copia con i soli
# cambi che Delphi 11 richiede (FormatSettings); di r_public.pas si ritagliano dal file originale le funzioni del
# mondo (RF_ClearWorld .. RF_GetCeilingZ) dentro una unit generata. Il resto (d_disk, d_misc, modplay, net, raven,
# r_conten, r_render, utils) sono gli stub di stubs\: solo le variabili globali e le chiamate annotate.
# Le copie generate e l'eseguibile stanno in %TEMP%\SpawnGolden, fuori dal repository.
# Uso: .\Compila.ps1 [-Golden <file>] [-Completo <file con le descrizioni intere, per cercare una differenza>]
param(
  [string]$Golden = '',
  [string]$Completo = '',
  [string]$Riferimento = 'C:\Progetti\DelphiDoom\Reference\xGreed'
)
$radice = Resolve-Path "$PSScriptRoot\..\..\.."
if ($Golden -eq '') { $Golden = Join-Path $radice 'Tests\Data\Greed\spawn.golden.txt' }
$uscita = Join-Path $env:TEMP 'SpawnGolden'
New-Item -ItemType Directory -Force $uscita, "$uscita\src" | Out-Null
$g = Get-Content "$Riferimento\Base\g_delphi.pas" -Raw
$g = $g -replace '(?<![\.\w])ThousandSeparator', 'FormatSettings.ThousandSeparator' -replace '(?<![\.\w])DecimalSeparator', 'FormatSettings.DecimalSeparator'
Set-Content "$uscita\src\g_delphi.pas" $g
$r = Get-Content "$Riferimento\Greed\r_public.pas" -Raw
$inizio = $r.IndexOf('procedure RF_ClearWorld;', $r.IndexOf('implementation'))
$fine = $r.IndexOf('procedure RF_SetActionHook', $inizio)
if ($inizio -lt 0 -or $fine -lt 0) { Write-Error 'r_public.pas: funzioni non trovate'; exit 1 }
$testa = Get-Content "$PSScriptRoot\r_public.head.txt" -Raw
Set-Content "$uscita\src\r_public.pas" ($testa + $r.Substring($inizio, $fine - $inizio) + "`r`nend.`r`n")
$dcc = 'C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\dcc32.exe'
$u = "$PSScriptRoot\stubs;$uscita\src;$Riferimento\Greed;$Riferimento\Base;$radice\Tests\Source"
& $dcc -B -Q -H- -W- "-U$u" "-I$Riferimento" "-N0$uscita" "-E$uscita" "-NSSystem;Winapi" "$PSScriptRoot\SpawnGolden.dpr" | Select-String 'Error|Fatal'
if ($LASTEXITCODE -ne 0) { exit 1 }
if ($Completo -eq '') { & "$uscita\SpawnGolden.exe" $Golden } else { & "$uscita\SpawnGolden.exe" $Golden $Completo }
exit $LASTEXITCODE
