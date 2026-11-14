# Compila ed esegue il confronto tra lo sprites.pas ORIGINALE di xGreed e TGreedSpriteLogic di Libs\Greed (issue #175).
# Il codice originale resta in Reference\xGreed (sola lettura) e si compila non modificato: qui si genera solo la copia
# di g_delphi.pas con i cambi che Delphi 11 richiede (FormatSettings), fuori dal repository. Gli stub del resto del
# gioco sono in stubs\ (spawn, utils, raven, modplay, net) e in ..\175-render\stubs (d_disk, d_misc, d_ints ...).
# Uso: .\Compila.ps1 [-Golden ..\..\..\Tests\Data\Greed\sprites.golden.txt] [-Primo 0] [-Ultimo 47]
#      .\Compila.ps1 -Misura 31 [-Primo 0] [-Ultimo 63] [-MaxDispersione 3] [-Soglia 5]
# -Misura N: misura a coppie col criterio di Tools\Misura-Coppie.ps1 (MoveSprites dell'originale e della libreria
# alternati N volte invertendo l'ordine; minimo, mediana, dispersione, verdetto; esce con 3 se la misura non e' affidabile)
param(
  [string]$Golden = '',
  [int]$Primo = 0,
  [int]$Ultimo = -1,
  [int]$Misura = 0,
  [double]$MaxDispersione = 3,
  [double]$Soglia = 5,
  # una cartella di unit messa davanti alle altre: una versione precedente di Libs\Greed, per misurare il prima
  [string]$Davanti = '',
  # profilo a campioni di un lato ('o' originale, 'l' libreria) per -Giri giri di tutti gli scenari: le routine dove va il tempo
  [string]$Profilo = '',
  [int]$Giri = 20,
  [string]$Riferimento = 'C:\Progetti\DelphiDoom\Reference\xGreed'
)
$radice = Resolve-Path "$PSScriptRoot\..\..\.."
$uscita = Join-Path $env:TEMP 'SpritesParity'
New-Item -ItemType Directory -Force $uscita, "$uscita\src" | Out-Null
$g = Get-Content "$Riferimento\Base\g_delphi.pas" -Raw
$g = $g -replace '(?<![\.\w])ThousandSeparator', 'FormatSettings.ThousandSeparator' -replace '(?<![\.\w])DecimalSeparator', 'FormatSettings.DecimalSeparator'
Set-Content "$uscita\src\g_delphi.pas" $g
$dcc = 'C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\dcc32.exe'
if ($Davanti -ne '') { $Davanti = "$Davanti;" }
$u = "$Davanti$PSScriptRoot\stubs;$PSScriptRoot\..\175-render\stubs;$uscita\src;$Riferimento\Greed;$Riferimento\Base;$radice\Libs\Greed;$radice\Libs\Platform;$radice\Libs\MathCore;$radice\Libs\Logging;$radice\Libs\Clock;$radice\Tests\Source"
# -CC: xGreed.inc dichiara {$APPTYPE GUI}, l'harness e' un programma da console
& $dcc -B -Q -CC -GD -H- -W- '-$O+' "-U$u" "-I$Riferimento" "-N0$uscita" "-E$uscita" "-NSSystem;Winapi" "$PSScriptRoot\SpritesParity.dpr" | Select-String 'Error|Fatal'
if ($LASTEXITCODE -ne 0) { exit 1 }
if ($Golden -eq '') { $Golden = 'nessuno' }
if ($Ultimo -lt 0) { $Ultimo = 9999 }
# attraverso cmd: l'eseguibile ha il sottosistema GUI di xGreed.inc e PowerShell non ne aspetta l'uscita
if ($Profilo -ne '') {
  cmd /c "`"$uscita\SpritesParity.exe`" profilo $Profilo $Giri"
  exit $LASTEXITCODE
}
if ($Misura -gt 0) {
  cmd /c "`"$uscita\SpritesParity.exe`" misura $Misura $Primo $Ultimo $MaxDispersione $Soglia"
  exit $LASTEXITCODE
}
cmd /c "`"$uscita\SpritesParity.exe`" `"$Golden`" $Primo $Ultimo"
exit $LASTEXITCODE
