# Writes Tests\Data\MapFile\aas_rooms.aas: three boxes in a row (64 units each), as a small
# but coherent AAS file (planes, vertices, edges, faces, areas with reachabilities, a tree, a
# portal and a cluster). The numbers are invented: no data of Doom 3 is used.
param([string]$Out = (Join-Path $PSScriptRoot '..\..\..\Tests\Data\MapFile\aas_rooms.aas'))

$nl = "`n"
$boxes = 3
$size = 64
$vertices = @(, [double[]](0, 0, 0))   # vertex 0 is a dummy
function VertexIndex($xi, $yi, $zi) { 1 + $xi * 4 + $yi * 2 + $zi }
for ($xi = 0; $xi -le $boxes; $xi++) { foreach ($yi in 0, 1) { foreach ($zi in 0, 1) {
  $vertices += , [double[]](($xi * $size), ($yi * $size), ($zi * $size)) } } }

$edges = @(, @(0, 0))                 # edge 0 is a dummy
$edgeKey = @{}
function EdgeEntry($a, $b) {
  if ($edgeKey.ContainsKey("$a,$b")) { return $edgeKey["$a,$b"] }
  if ($edgeKey.ContainsKey("$b,$a")) { return - $edgeKey["$b,$a"] }
  $script:edges += , @($a, $b)
  $n = $script:edges.Count - 1
  $edgeKey["$a,$b"] = $n
  return $n
}

# planes: dummy, x = 0, 64, 128, 192, y = 0, 64, z = 0, 64
$planes = @(, @(0, 0, 0, 0))
foreach ($k in 0..3) { $planes += , @(1, 0, 0, ($k * $size)) }
$planes += , @(0, 1, 0, 0); $planes += , @(0, 1, 0, $size)
$planes += , @(0, 0, 1, 0); $planes += , @(0, 0, 1, $size)
# plane numbers: x=k -> 1 + k, y=0 -> 5, y=64 -> 6, z=0 -> 7, z=64 -> 8

$faces = @(, @(0, 0, 0, 0, 0, 0))     # face 0 is a dummy: plane flags area0 area1 firstEdge numEdges
$edgeIndex = @(0)
$faceKey = @{}
function AddFace($key, $plane, $flags, $a0, $a1, $loop) {
  if ($faceKey.ContainsKey($key)) { return $faceKey[$key] }
  $first = $script:edgeIndex.Count
  for ($i = 0; $i -lt 4; $i++) { $script:edgeIndex += (EdgeEntry $loop[$i] $loop[($i + 1) % 4]) }
  $script:faces += , @($plane, $flags, $a0, $a1, $first, 4)
  $n = $script:faces.Count - 1
  $faceKey[$key] = $n
  return $n
}
$FACE_SOLID = 1; $FACE_FLOOR = 4
$faceIndex = @(0)
$areas = @()                          # area 0 is a dummy (solid)
$areaFirstFace = @(0); $areaNumFaces = @(0)
for ($b = 0; $b -lt $boxes; $b++) {
  $area = $b + 1
  $x0 = $b; $x1 = $b + 1
  $list = @()
  # x faces (left and right)
  foreach ($xi in $x0, $x1) {
    $loop = @((VertexIndex $xi 0 0), (VertexIndex $xi 1 0), (VertexIndex $xi 1 1), (VertexIndex $xi 0 1))
    $shared = ($xi -gt 0 -and $xi -lt $boxes)
    $f = AddFace "x$xi" (1 + $xi) $(if ($shared) { 0 } else { $FACE_SOLID }) $(if ($xi -eq $x1) { $area } else { $area - 1 }) $(if ($xi -eq $x1) { $area + 1 } else { $area }) $loop
    $list += $(if ($xi -eq $x1) { $f } else { - $f })
  }
  # y faces
  foreach ($yi in 0, 1) {
    $loop = @((VertexIndex $x0 $yi 0), (VertexIndex $x1 $yi 0), (VertexIndex $x1 $yi 1), (VertexIndex $x0 $yi 1))
    $f = AddFace "y$yi-$b" (5 + $yi) $FACE_SOLID 0 $area $loop
    $list += $(if ($yi -eq 1) { $f } else { - $f })
  }
  # z faces
  foreach ($zi in 0, 1) {
    $loop = @((VertexIndex $x0 0 $zi), (VertexIndex $x1 0 $zi), (VertexIndex $x1 1 $zi), (VertexIndex $x0 1 $zi))
    $flags = if ($zi -eq 0) { $FACE_FLOOR } else { $FACE_SOLID }
    $f = AddFace "z$zi-$b" (7 + $zi) $flags 0 $area $loop
    $list += $(if ($zi -eq 1) { $f } else { - $f })
  }
  $areaFirstFace += $faceIndex.Count
  $areaNumFaces += $list.Count
  $faceIndex += $list
}

$sb = New-Object System.Text.StringBuilder
function Line($s) { [void]$sb.Append($s + $nl) }
function Num($v) { ([string][double]$v).Replace(',', '.') }

Line 'DewmAAS "1.07"'
Line ''
Line '2882400001'
Line ''
Line 'settings'
Line '{'
Line "`tbboxes"
Line "`t{"
Line "`t`t(-16 -16 0)-(16 16 72)"
Line "`t`t(-24 -24 0)-(24 24 96)"
Line "`t}"
Line "`tusePatches = 0"
Line "`twriteBrushMap = 0"
Line "`tplayerFlood = 1"
Line "`tallowSwimReachabilities = 0"
Line "`tallowFlyReachabilities = 1"
Line "`tfileExtension = `"aas48`""
Line "`tgravity = (0 0 -1066)"
Line "`tmaxStepHeight = 18.0"
Line "`tmaxBarrierHeight = 32.5"
Line "`tmaxWaterJumpHeight = 20"
Line "`tmaxFallHeight = 64"
Line "`tminFloorCos = 0.7"
Line "`ttt_barrierJump = 100"
Line "`ttt_startCrouching = 110"
Line "`ttt_waterJump = 120"
Line "`ttt_startWalkOffLedge = 130"
Line '}'
Line "planes $($planes.Count) {"
for ($i = 0; $i -lt $planes.Count; $i++) { $p = $planes[$i]; Line "`t$i ( $(Num $p[0]) $(Num $p[1]) $(Num $p[2]) $(Num $p[3]) )" }
Line '}'
Line "vertices $($vertices.Count) {"
for ($i = 0; $i -lt $vertices.Count; $i++) { $v = $vertices[$i]; Line "`t$i ( $(Num $v[0]) $(Num $v[1]) $(Num $v[2]) )" }
Line '}'
Line "edges $($edges.Count) {"
for ($i = 0; $i -lt $edges.Count; $i++) { Line "`t$i ( $($edges[$i][0]) $($edges[$i][1]) )" }
Line '}'
Line "edgeIndex $($edgeIndex.Count) {"
for ($i = 0; $i -lt $edgeIndex.Count; $i++) { Line "`t$i ( $($edgeIndex[$i]) )" }
Line '}'
Line "faces $($faces.Count) {"
for ($i = 0; $i -lt $faces.Count; $i++) { $f = $faces[$i]; Line "`t$i ( $($f[0]) $($f[1]) $($f[2]) $($f[3]) $($f[4]) $($f[5]) )" }
Line '}'
Line "faceIndex $($faceIndex.Count) {"
for ($i = 0; $i -lt $faceIndex.Count; $i++) { Line "`t$i ( $($faceIndex[$i]) )" }
Line '}'
# areas: flags AREA_FLOOR (1), contents 0 (solid dummy: 1); cluster 1, area number in the cluster
Line "areas $($boxes + 1) {"
Line "`t0 ( 0 1 0 0 0 0 ) 0 {"
Line "`t}"
for ($b = 0; $b -lt $boxes; $b++) {
  $area = $b + 1
  $reach = @()
  if ($b -gt 0) { $reach += "`t`t2 $($area - 1) ($(Num ($b * $size + 4)) 32 0) ($(Num ($b * $size - 4)) 32 0) 0 25" }
  if ($b -lt $boxes - 1) { $reach += "`t`t2 $($area + 1) ($(Num (($b + 1) * $size - 4)) 32 0) ($(Num (($b + 1) * $size + 4)) 32 0) 0 25" }
  if ($b -eq 1) {
    $reach += "`t`t4096 3 (96 32 0) (150.5 32 0) 7 100" + $nl + "`t`t{" + $nl + "`t`t`t`"type`" `"jump`"" + $nl + "`t`t`t`"Model`" `"a b`"" + $nl + "`t`t}"
  }
  $contents = if ($b -eq 2) { 2 } else { 0 }
  Line "`t$area ( 1 $contents $($areaFirstFace[$area]) $($areaNumFaces[$area]) 1 $area ) $($reach.Count) {"
  foreach ($r in $reach) { Line $r }
  Line "`t}"
}
Line '}'
Line 'nodes 3 {'
Line "`t0 ( 0 0 0 )"
Line "`t1 ( 3 2 -1 )"
Line "`t2 ( 2 -3 -2 )"
Line '}'
Line 'portals 2 {'
Line "`t0 ( 0 0 0 0 0 )"
Line "`t1 ( 2 1 1 0 0 )"
Line '}'
Line 'portalIndex 2 {'
Line "`t0 ( 0 )"
Line "`t1 ( 1 )"
Line '}'
Line 'clusters 2 {'
Line "`t0 ( 0 0 0 0 )"
Line "`t1 ( 3 3 1 1 )"
Line '}'

[IO.File]::WriteAllText($Out, $sb.ToString().Replace("`n", "`r`n"), (New-Object Text.UTF8Encoding($false)))
Write-Host "written $Out ($($sb.Length) characters)"
