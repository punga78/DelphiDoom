<#
  Issue #245, sesta tornata: lancia Confronta-Mappe.ps1 per i sei giochi software tra la base (cartella con le
  copie di exe e .map prima della modifica, per esempio C:\ddbase_245f\<Gioco>) e bin\Win32\Release.

  Uso:  powershell -NoProfile -File Tools\Verifica\245\Confronta-Giochi.ps1 -Base C:\ddbase_245f [-Games Doom,Hexen]
#>
param(
  [Parameter(Mandatory)][string]$Base,
  [string[]]$Games = @('Doom', 'Heretic', 'Hexen', 'Strife', 'Radix', 'Speed')
)
$Games = @($Games | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne '' })
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$names = @{ Doom = 'Doom32'; Heretic = 'Heretic32'; Hexen = 'Hexen32'; Strife = 'Strife32'; Radix = 'Radix32'; Speed = 'SpeedHaste32' }
$compare = Join-Path $PSScriptRoot 'Confronta-Mappe.ps1'
foreach ($game in $Games) {
  $file = $names[$game] + '.map'
  Write-Host "=== $game"
  & $compare -MapA (Join-Path (Join-Path $Base $game) $file) -MapB (Join-Path $root ('bin\Win32\Release\' + $game + '\' + $file))
}
