<#
  Prepara un salvataggio di missione (Make-XcomMissionSave.ps1), lo carica in Xcom32 senza finestra (-script) ed
  esegue i passi dati dopo il caricamento (il geoscape e' sullo schermo). Le schermate vanno in <Out>\shots.

  Uso: Run-XcomMission.ps1 -Root <worktree> -Data <Reference\_dati\xcom_tftd> -Out <cartella tua> -Kind crash
         -Script 'wait:500;shot:a.png' [-Deployment ...] [-Race ...] [-Craft ...] [-Option chiave=valore] [-SaveFile x.sav]

  La cartella utente e' <Out>\user (mai quella di bin\OpenXcom). -SaveFile usa un salvataggio gia' pronto.
#>
param(
  [Parameter(Mandatory = $true)][string]$Root,
  [Parameter(Mandatory = $true)][string]$Data,
  [Parameter(Mandatory = $true)][string]$Out,
  [Parameter(Mandatory = $true)][string]$Script,
  [string]$Kind = 'crash',
  [string]$Deployment = 'STR_PORT_TERROR',
  [string]$Race = 'STR_AQUATOID',
  [string]$Craft = 'STR_TRITON',
  [string]$SaveFile = '',
  # passed on to Make-XcomMissionSave.ps1 (for example @{ Defenses = 2; Ufo = 'STR_SURVEY_SHIP' })
  [hashtable]$Make = @{},
  [string[]]$Option = @()
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force "$Out\shots", "$Out\user\xcom2" | Out-Null
# also the autosaves of a run before: the list of the saved games must have the mission alone
Get-ChildItem "$Out\user\xcom2" | Where-Object { $_.Extension -in '.sav', '.asav' } | Remove-Item -Force
if ($SaveFile -ne '') { Copy-Item $SaveFile "$Out\user\xcom2\mission.sav" -Force }
else { & "$PSScriptRoot\Make-XcomMissionSave.ps1" -Root $Root -Out "$Out\user\xcom2\mission.sav" -Kind $Kind -Deployment $Deployment -Race $Race -Craft $Craft @Make | Out-Null }
$cfg = Get-Content "$Data\openxcom_user\options.cfg" -Raw
foreach ($o in $Option) {
  $kv = $o.Split('=', 2)
  $cfg = $cfg -replace ('(?m)^  ' + [regex]::Escape($kv[0]) + ': .*$'), ('  ' + $kv[0] + ': ' + $kv[1])
}
Set-Content -Path "$Out\user\options.cfg" -Value $cfg -Encoding ASCII
# main menu -> Load Game -> the first save of the list
$full = 'wait:5000;move:220,256;click:220,256;wait:2000;move:80,92;click:80,92;wait:1000;' + $Script
Push-Location "$Out\shots"
try {
  $p = Start-Process "$Root\bin\OpenXcom\Xcom32.exe" -ArgumentList "-data `"$Data\openxcom`" -game `"$Data\TFTD`" -user `"$Out\user`" -script $full" -RedirectStandardError "$Out\stderr.txt" -RedirectStandardOutput "$Out\stdout.txt" -PassThru -Wait
  Write-Output "exit code $($p.ExitCode)"
}
finally { Pop-Location }
Get-Content "$Out\stderr.txt", "$Out\stdout.txt"
