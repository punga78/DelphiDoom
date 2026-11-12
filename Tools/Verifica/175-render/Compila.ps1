# Compila ed esegue il confronto tra il renderer ORIGINALE di xGreed e quello a classi di Libs\Greed (issue #175, G11).
# Il codice originale resta in Reference\xGreed (sola lettura): qui si compila una copia di g_delphi.pas con i soli
# cambi che Delphi 11 richiede (FormatSettings). Gli stub (d_disk, d_misc, raven...) sono in stubs\.
# Uso: .\Compila.ps1 -Dati <cartella con GREED.BLO> [-Mappe 0,1,2,3] [-Seme 20260109] [-Viste 12] [-Sprite 40] [-Golden file.txt]
param(
  [Parameter(Mandatory = $true)][string]$Dati,
  [string]$Mappe = '0,1,2,3',
  [uint32]$Seme = 20260109,
  [int]$Viste = 12,
  [int]$Sprite = 40,
  [string]$Golden = '',
  [string]$Riferimento = 'C:\Progetti\DelphiDoom\Reference\xGreed'
)
$radice = Resolve-Path "$PSScriptRoot\..\..\.."
$uscita = Join-Path $env:TEMP 'RenderParity'
New-Item -ItemType Directory -Force $uscita, "$uscita\src" | Out-Null
$g = Get-Content "$Riferimento\Base\g_delphi.pas" -Raw
$g = $g -replace '(?<![\.\w])ThousandSeparator', 'FormatSettings.ThousandSeparator' -replace '(?<![\.\w])DecimalSeparator', 'FormatSettings.DecimalSeparator'
Set-Content "$uscita\src\g_delphi.pas" $g
$dcc = 'C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\dcc32.exe'
$u = "$PSScriptRoot\stubs;$uscita\src;$Riferimento\Greed;$Riferimento\Base;$radice\Libs\Greed;$radice\Libs\Platform;$radice\Libs\MathCore;$radice\Libs\Logging;$radice\Libs\Clock;$radice\Tests\Source"
& $dcc -B -Q -H- -W- "-U$u" "-I$Riferimento" "-N0$uscita" "-E$uscita" "-NSSystem;Winapi" "$PSScriptRoot\RenderParity.dpr" | Select-String 'Error|Fatal'
if ($LASTEXITCODE -ne 0) { exit 1 }
& "$uscita\RenderParity.exe" $Dati $Golden $Mappe $Seme $Viste $Sprite
