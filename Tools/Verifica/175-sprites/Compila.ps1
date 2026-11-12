# Compila ed esegue il confronto tra lo sprites.pas ORIGINALE di xGreed e TGreedSpriteLogic di Libs\Greed (issue #175).
# Il codice originale resta in Reference\xGreed (sola lettura) e si compila non modificato: qui si genera solo la copia
# di g_delphi.pas con i cambi che Delphi 11 richiede (FormatSettings), fuori dal repository. Gli stub del resto del
# gioco sono in stubs\ (spawn, utils, raven, modplay, net) e in ..\175-render\stubs (d_disk, d_misc, d_ints ...).
# Uso: .\Compila.ps1 [-Golden ..\..\..\Tests\Data\Greed\sprites.golden.txt] [-Primo 0] [-Ultimo 47]
param(
  [string]$Golden = '',
  [int]$Primo = 0,
  [int]$Ultimo = -1,
  [string]$Riferimento = 'C:\Progetti\DelphiDoom\Reference\xGreed'
)
$radice = Resolve-Path "$PSScriptRoot\..\..\.."
$uscita = Join-Path $env:TEMP 'SpritesParity'
New-Item -ItemType Directory -Force $uscita, "$uscita\src" | Out-Null
$g = Get-Content "$Riferimento\Base\g_delphi.pas" -Raw
$g = $g -replace '(?<![\.\w])ThousandSeparator', 'FormatSettings.ThousandSeparator' -replace '(?<![\.\w])DecimalSeparator', 'FormatSettings.DecimalSeparator'
Set-Content "$uscita\src\g_delphi.pas" $g
$dcc = 'C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\dcc32.exe'
$u = "$PSScriptRoot\stubs;$PSScriptRoot\..\175-render\stubs;$uscita\src;$Riferimento\Greed;$Riferimento\Base;$radice\Libs\Greed;$radice\Libs\Platform;$radice\Libs\MathCore;$radice\Libs\Logging;$radice\Libs\Clock;$radice\Tests\Source"
& $dcc -B -Q -H- -W- '-$O+' "-U$u" "-I$Riferimento" "-N0$uscita" "-E$uscita" "-NSSystem;Winapi" "$PSScriptRoot\SpritesParity.dpr" | Select-String 'Error|Fatal'
if ($LASTEXITCODE -ne 0) { exit 1 }
if ($Ultimo -lt 0) { & "$uscita\SpritesParity.exe" $Golden $Primo } else { & "$uscita\SpritesParity.exe" $Golden $Primo $Ultimo }
exit $LASTEXITCODE
