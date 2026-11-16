<#
  Issue #244: confronta le dimensioni delle routine di p_map e delle unit che ne leggono lo stato (p_maputl,
  p_secnodes, p_mobj, p_enemy, le regole dei giochi, FrictionPushers, radix_walls) tra la base (Dati\base-*.txt,
  presi dalle .map di master prima della migrazione) e le .map correnti in bin\Win32\Release.

  Uso:  powershell -NoProfile -File Tools\Verifica\244\Confronta-Dimensioni.ps1 [-Games Doom,Heretic,Hexen,Strife,Radix,Speed]
  Stampa, per ogni gioco e unit, IDENTICHE o le routine con la dimensione diversa; esce con il numero delle diverse.
#>
param(
  [string[]]$Games = @('Doom', 'Heretic', 'Hexen', 'Strife', 'Radix', 'Speed')
)
$Games = @($Games | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne '' })
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$maps = @{ Doom = 'Doom\Doom32.map'; Heretic = 'Heretic\Heretic32.map'; Hexen = 'Hexen\Hexen32.map';
  Strife = 'Strife\Strife32.map'; Radix = 'Radix\Radix32.map'; Speed = 'Speed\SpeedHaste32.map' }
$sizes = Join-Path $PSScriptRoot 'Dimensioni-Routine.ps1'
$bad = 0
foreach ($game in $Games) {
  $map = Join-Path $root ('bin\Win32\Release\' + $maps[$game])
  foreach ($baseFile in Get-ChildItem (Join-Path $PSScriptRoot 'Dati') -Filter "base-$game-*.txt") {
    $unit = $baseFile.BaseName.Substring("base-$game-".Length)
    $now = @(& $sizes -Map $map -Unit $unit)
    $old = @(Get-Content $baseFile.FullName)
    $diff = @(Compare-Object $old $now)
    if ($diff.Count -eq 0) { Write-Host ("IDENTICHE  {0,-7} {1} ({2} routine)" -f $game, $unit, $old.Count) }
    else {
      $bad += $diff.Count
      Write-Host ("DIVERSE    {0,-7} {1}" -f $game, $unit)
      $diff | ForEach-Object { Write-Host ('    {0} {1}' -f $_.SideIndicator, $_.InputObject) }
    }
  }
}
exit $bad
