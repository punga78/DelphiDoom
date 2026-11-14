<#
  Avvia Xcom32, carica un salvataggio vero (Tests\Data\XcomSave\realsave\saveNN.sav) ed esegue uno script di passi
  (millisecondi, come -script di Xcom32: move:x,y; click:x,y; wait:ms; shot:nome.png) dopo il caricamento. Serve a
  provare i flussi (intercettare, costruire una base...) senza il confronto col vero programma.

  Uso: Run-XcomGameSave.ps1 -Root <worktree> -Data <Reference\_dati\xcom_tftd> -Out <cartella> -Save 2 -Script '...'
#>
param(
  [Parameter(Mandatory = $true)][string]$Root,
  [Parameter(Mandatory = $true)][string]$Data,
  [Parameter(Mandatory = $true)][string]$Out,
  [Parameter(Mandatory = $true)][string]$Script,
  [int]$Save = 2
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force "$Out\delphi", "$Out\user", "$Out\seed\xcom2" | Out-Null
$name = 'save{0:00}' -f $Save
$t = [IO.File]::ReadAllText("$Root\Tests\Data\XcomSave\realsave\$name.sav")
$t = $t.Replace('name: ""', 'name: "Save ' + ('{0:00}' -f $Save) + '"').Replace('  - "xcom2 ver: 1.0"', '  - xcom2').Replace("`r`n", "`n")
[IO.File]::WriteAllText("$Out\seed\xcom2\$name.sav", $t)
Copy-Item "$Out\seed\xcom2" "$Out\user" -Recurse -Force
Copy-Item "$Data\openxcom_user\options.cfg" "$Out\user\options.cfg" -Force
$full = 'wait:5000;move:220,256;click:220,256;wait:2000;move:80,92;click:80,92;wait:1000;' + $Script
Push-Location "$Out\delphi"
& "$Root\bin\Win32\Release\OpenXcom\Xcom32.exe" -data "$Data\openxcom" -game "$Data\TFTD" -user "$Out\user" -script $full | Out-Null
Pop-Location
