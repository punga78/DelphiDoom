<#
  Issue #185: verifica ridotta di un passo, quando il lock globale dei giochi e' conteso (piu' agenti): una demo per
  gioco contro i golden (Doom d1_demo1, Heretic a_h_e1m1, Hexen a_x_map01_f, Strife a_s_map32) a 8 bit, e a 32 bit per
  Doom e Strife con -Con32 (passi che toccano cio' che disegna). Il corpus intero (Confronta-Golden.ps1 senza filtri)
  si fa una volta sola sul ramo con tutti i passi uniti.

  Uso:
    powershell -NoProfile -File Tools\Verifica\185\Verifica-Ridotta.ps1 [-ExeRoot <cartella con IdTech1\Doom\Doom32.exe ...>]
      [-Con32] [-Games Doom,Heretic] [-WorkRoot C:\ddparity_185]
  -ExeRoot: predefinita bin\Win32\Release del repository. Esce con 0 se tutto e' UGUALE.
#>
param(
  [string]$ExeRoot = '',
  [switch]$Con32,
  [string[]]$Games = @('Doom', 'Heretic', 'Hexen', 'Strife'),
  [string]$WorkRoot = 'C:\ddparity_185'
)
$Games = @($Games | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne '' })
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
if ($ExeRoot -eq '') { $ExeRoot = Join-Path $root 'bin\Win32\Release' }
$demos = [ordered]@{ Doom = 'd1_demo1'; Heretic = 'a_h_e1m1'; Hexen = 'a_x_map01_f'; Strife = 'a_s_map32' }
# a macchina carica il gioco a priorita' bassa non avanza: l'esito non dipende dalla priorita' (orologio virtuale)
if (-not $env:DD_GAME_PRIORITY) { $env:DD_GAME_PRIORITY = 'Normal' }
if (-not $env:DD_PARITY_TIMEOUT) { $env:DD_PARITY_TIMEOUT = '1800' }
$compare = Join-Path $PSScriptRoot 'Confronta-Golden.ps1'
$failed = 0
foreach ($game in $demos.Keys) {
  if ($Games -notcontains $game) { continue }
  $exe = '{0}={1}' -f $game, (Join-Path $ExeRoot "$game\${game}32.exe")
  $modes = @(8)
  if ($Con32 -and ($game -in 'Doom', 'Strife')) { $modes += 32 }
  foreach ($mode in $modes) {
    & powershell -NoProfile -File $compare -Game $game -Name $demos[$game] -Modes $mode -WorkRoot $WorkRoot -Exe $exe
    if ($LASTEXITCODE -ne 0) { $failed++ }
  }
}
if ($failed -eq 0) { Write-Output 'VERIFICA RIDOTTA: tutto UGUALE' } else { Write-Output "VERIFICA RIDOTTA: $failed confronti NON uguali o falliti" }
exit $failed
