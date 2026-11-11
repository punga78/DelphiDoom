# Writes a script of orders for Tools\Verifica\176\battle\bgame.cpp that shows the sprite of every kind of unit of a
# saved battle in the poses that UnitSprite tells apart: standing, turned, aiming, walking (two steps) and falling.
# The battle goes in debug mode (every unit is drawn), the camera centers on the unit and "dumpmap" writes the map.
# usage: Make-XcomPoseScript.ps1 -Save <file .sav with a battle> -Out <script.txt> [-PerType 2]
#        -Types <regex>: only the unit types that match (to keep the scenario small)
param([Parameter(Mandatory)][string]$Save, [Parameter(Mandatory)][string]$Out, [int]$PerType = 2, [string]$Types = '')
$lines = Get-Content $Save
$units = @()
for ($i = 0; $i -lt $lines.Count; $i++) {
  if ($lines[$i] -match '^\s+- id: \d+$' -and $i + 10 -lt $lines.Count -and $lines[$i + 1] -like '*genUnitType: *') {
    $id = [int]($lines[$i] -replace '\D', ''); $type = $lines[$i + 1] -replace '.*genUnitType: ', ''
    if ($Types -ne '' -and $type -notmatch $Types) { continue }
    if ($lines[$i + 4] -notmatch 'status: 0' -or $lines[$i + 5] -notmatch 'position:') { continue }
    $x = [int]($lines[$i + 6] -replace '\D', ''); $y = [int]($lines[$i + 7] -replace '\D', ''); $z = [int]($lines[$i + 8] -replace '\D', '')
    $d = [int]($lines[$i + 9] -replace '.*direction: ', '')
    $units += [pscustomobject]@{ Id = $id; Type = $type; X = $x; Y = $y; Z = $z; Dir = $d }
  }
}
$dx = 0, 1, 1, 1, 0, -1, -1, -1
$dy = -1, -1, 0, 1, 1, 1, 0, -1
$script = @('debug')
foreach ($group in ($units | Group-Object Type)) {
  $n = 0
  foreach ($u in ($group.Group | Select-Object -First $PerType)) {
    $script += "camera $($u.X) $($u.Y) $($u.Z)", "viewlevel $($u.Z)", 'dumpmap'
    $turned = ($u.Dir + 3 + $n) % 8
    $script += "pose $($u.Id) face $turned", 'dumpmap', "pose $($u.Id) aim", 'dumpmap'
    if ($n -eq 0) { $script += "pose $($u.Id) fall 1", 'dumpmap' }
    else { $script += "pose $($u.Id) walk 2 $($u.X + $dx[$turned]) $($u.Y + $dy[$turned]) $($u.Z)", 'dumpmap' }
    $n++
  }
}
[IO.File]::WriteAllLines($Out, $script)
"$($units.Count) units, $(($units | Group-Object Type).Count) types, $($script.Count) orders"
