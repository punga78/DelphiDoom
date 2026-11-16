# Writes a Doom 3 style .aas file made of boxes on a grid (64 units each, 64 high), as a coherent file for the
# routing tests of IdTech4\Aas (issue #109): planes in pairs (2k and 2k+1 are opposite), vertices, shared edges and
# faces, areas with reachabilities, a BSP tree, portals and clusters. The numbers are invented: no data of Doom 3
# is used. The same file is read by the Delphi tests and by the C++ harness (Tools\Verifica\109\LEGGIMI.md).
#
#   -Layout ring   : bottom row, top row and the two end columns of the grid (a loop: two routes between most areas)
#   -Layout full   : every cell
#   -PortalColumns : columns whose cells are cluster portals; the columns between two portals form a cluster
param(
  [string]$Out = (Join-Path $PSScriptRoot '..\..\..\Tests\Data\AasD3\aas_ring.aas'),
  [int]$Columns = 5,
  [int]$Rows = 3,
  [ValidateSet('ring', 'full')][string]$Layout = 'ring',
  [int[]]$PortalColumns = @(2),
  [string]$Crc = '2882400109'
)

$nl = "`n"
$size = 64
$ci = [System.Globalization.CultureInfo]::InvariantCulture
function Num($v) { ([double]$v).ToString('0.###', $ci) }

# --- the cells ---------------------------------------------------------------------------------------------------
$cells = @()
for ($j = 0; $j -lt $Rows; $j++) { for ($i = 0; $i -lt $Columns; $i++) {
  $keep = $true
  if ($Layout -eq 'ring') { $keep = ($j -eq 0) -or ($j -eq $Rows - 1) -or ($i -eq 0) -or ($i -eq $Columns - 1) }
  if ($keep) { $cells += , @($i, $j) }
} }
$areaOf = @{}
for ($k = 0; $k -lt $cells.Count; $k++) { $areaOf["$($cells[$k][0]),$($cells[$k][1])"] = $k + 1 }
function AreaAt($i, $j) { if ($areaOf.ContainsKey("$i,$j")) { return $areaOf["$i,$j"] } return 0 }

# --- planes in pairs ---------------------------------------------------------------------------------------------
$planes = @(, @(0, 0, 0, 0))                   # planes 0 and 1: dummies
$planes += , @(0, 0, 0, 0)
$planeKey = @{}
function PlaneNum($nx, $ny, $nz, $dist) {
  $key = "$nx,$ny,$nz,$dist"
  if ($planeKey.ContainsKey($key)) { return $planeKey[$key] }
  $n = $script:planes.Count
  $script:planes += , @($nx, $ny, $nz, $dist)
  $script:planes += , @(-$nx, -$ny, -$nz, -$dist)
  $planeKey[$key] = $n
  return $n
}

# --- vertices, edges, faces --------------------------------------------------------------------------------------
$vertices = @(, @(0, 0, 0))
$vertexKey = @{}
function VertexIndex($x, $y, $z) {
  $key = "$x,$y,$z"
  if ($vertexKey.ContainsKey($key)) { return $vertexKey[$key] }
  $script:vertices += , @(($x * $size), ($y * $size), ($z * $size))
  $n = $script:vertices.Count - 1
  $vertexKey[$key] = $n
  return $n
}
$edges = @(, @(0, 0))
$edgeKey = @{}
function EdgeEntry($a, $b) {
  if ($edgeKey.ContainsKey("$a,$b")) { return $edgeKey["$a,$b"] }
  if ($edgeKey.ContainsKey("$b,$a")) { return - $edgeKey["$b,$a"] }
  $script:edges += , @($a, $b)
  $n = $script:edges.Count - 1
  $edgeKey["$a,$b"] = $n
  return $n
}
$FACE_SOLID = 1; $FACE_FLOOR = 4
$faces = @(, @(0, 0, 0, 0, 0, 0))
$edgeIndex = @(0)
$faceKey = @{}
# a face of a cell: key names the face (shared by the two cells), plane normal points into area0 (the front area)
function AddFace($key, $plane, $flags, $a0, $a1, $loop) {
  if ($faceKey.ContainsKey($key)) { return $faceKey[$key] }
  $first = $script:edgeIndex.Count
  for ($q = 0; $q -lt 4; $q++) { $script:edgeIndex += (EdgeEntry $loop[$q] $loop[($q + 1) % 4]) }
  $script:faces += , @($plane, $flags, $a0, $a1, $first, 4)
  $n = $script:faces.Count - 1
  $faceKey[$key] = $n
  return $n
}

$faceIndex = @(0)
$areaFirstFace = @(0); $areaNumFaces = @(0)
$sharedEdge = @{}    # "a,b" -> the edge of the face between the areas a and b
foreach ($cell in $cells) {
  $i = $cell[0]; $j = $cell[1]; $area = AreaAt $i $j
  $list = @()
  $x0 = $i; $x1 = $i + 1; $y0 = $j; $y1 = $j + 1
  # side faces: -x, +x, -y, +y; the normal points into the area with the lower number when the face is shared
  $sides = @(
    @('x', $x0, -1, (AreaAt ($i - 1) $j)), @('x', $x1, 1, (AreaAt ($i + 1) $j)),
    @('y', $y0, -1, (AreaAt $i ($j - 1))), @('y', $y1, 1, (AreaAt $i ($j + 1))))
  foreach ($s in $sides) {
    $axis = $s[0]; $c = $s[1]; $dir = $s[2]; $other = $s[3]
    if ($axis -eq 'x') {
      $loop = @((VertexIndex $c $y0 0), (VertexIndex $c $y1 0), (VertexIndex $c $y1 1), (VertexIndex $c $y0 1))
      $key = if ($other -gt 0) { "x$c,$j" } else { "xs$c,$j" }
      $nx = -$dir; $ny = 0
      $pl = PlaneNum $nx 0 0 ($nx * $c * $size)
    } else {
      $loop = @((VertexIndex $x0 $c 0), (VertexIndex $x1 $c 0), (VertexIndex $x1 $c 1), (VertexIndex $x0 $c 1))
      $key = if ($other -gt 0) { "y$i,$c" } else { "ys$i,$c" }
      $ny = -$dir
      $pl = PlaneNum 0 $ny 0 ($ny * $c * $size)
    }
    # the normal points into this area: this area is the front area (areas[0]) of its solid faces; for a shared face
    # the first cell that adds it is the front area
    $fresh = -not $faceKey.ContainsKey($key)
    if ($other -gt 0) { $flags = 0 } else { $flags = $FACE_SOLID }
    $before = $faces.Count
    $f = AddFace $key $pl $flags $area $other $loop
    if ($fresh) { $list += $f } else { $list += (- $f) }
    $face = $faces[$f]
    $sharedEdge["$area,$other"] = [math]::Abs($edgeIndex[$face[4]])
  }
  # floor and ceiling
  $loopF = @((VertexIndex $x0 $y0 0), (VertexIndex $x1 $y0 0), (VertexIndex $x1 $y1 0), (VertexIndex $x0 $y1 0))
  $f = AddFace "z0-$area" (PlaneNum 0 0 1 0) ($FACE_FLOOR) $area 0 $loopF
  $list += $f
  $loopC = @((VertexIndex $x0 $y0 1), (VertexIndex $x1 $y0 1), (VertexIndex $x1 $y1 1), (VertexIndex $x0 $y1 1))
  $f = AddFace "z1-$area" (PlaneNum 0 0 -1 (-$size)) $FACE_SOLID $area 0 $loopC
  $list += $f
  $areaFirstFace += $faceIndex.Count
  $areaNumFaces += $list.Count
  $faceIndex += $list
}

# --- the BSP tree ------------------------------------------------------------------------------------------------
# node: plane, child front, child back (child 0 is solid, a negative child is -(area number))
$nodes = @(, @(0, 0, 0))
function NewNode() { $script:nodes += , @(0, 0, 0); return $script:nodes.Count - 1 }
# a leaf cell: the box of the cell is cut out by six planes, outside is solid
function BoxChain($cell) {
  $i = $cell[0]; $j = $cell[1]; $area = AreaAt $i $j
  $planesOf = @(
    (PlaneNum 1 0 0 ($i * $size)), (PlaneNum -1 0 0 (-($i + 1) * $size)),
    (PlaneNum 0 1 0 ($j * $size)), (PlaneNum 0 -1 0 (-($j + 1) * $size)),
    (PlaneNum 0 0 1 0), (PlaneNum 0 0 -1 (-$size)))
  $first = 0; $prev = 0
  foreach ($p in $planesOf) {
    $n = NewNode
    $script:nodes[$n] = @($p, 0, 0)
    if ($prev -gt 0) { $script:nodes[$prev][1] = $n } else { $first = $n }
    $prev = $n
  }
  $script:nodes[$prev][1] = - $area
  return $first
}
function BuildTree($list, $axis) {
  if ($list.Count -eq 1) { return BoxChain $list[0] }
  $lo = ($list | ForEach-Object { $_[$axis] } | Measure-Object -Minimum).Minimum
  $hi = ($list | ForEach-Object { $_[$axis] } | Measure-Object -Maximum).Maximum
  if ($lo -eq $hi) { return BuildTree $list (1 - $axis) }
  $split = $lo + 1 + [int][math]::Floor(($hi - $lo - 1) / 2)
  $front = @($list | Where-Object { $_[$axis] -ge $split })
  $back = @($list | Where-Object { $_[$axis] -lt $split })
  $n = NewNode
  $nx = if ($axis -eq 0) { 1 } else { 0 }; $ny = 1 - $nx
  $p = PlaneNum $nx $ny 0 ($split * $size)
  $a = BuildTree $front (1 - $axis)
  $b = BuildTree $back (1 - $axis)
  $script:nodes[$n] = @($p, $a, $b)
  return $n
}
$root = BuildTree $cells 0
# the tree is read from node 1: the root must be node 1
if ($root -ne 1) {
  # nodes were created depth first; move the root to index 1 by swapping with node 1 and fixing the references
  $tmp = $nodes[1]; $nodes[1] = $nodes[$root]; $nodes[$root] = $tmp
  for ($n = 1; $n -lt $nodes.Count; $n++) { for ($c = 1; $c -le 2; $c++) {
    if ($nodes[$n][$c] -eq 1) { $nodes[$n][$c] = $root } elseif ($nodes[$n][$c] -eq $root) { $nodes[$n][$c] = 1 } } }
}

# --- clusters and portals ----------------------------------------------------------------------------------------
$clusterOfColumn = @{}
$cluster = 1
for ($i = 0; $i -lt $Columns; $i++) {
  if ($PortalColumns -contains $i) { $clusterOfColumn[$i] = 0; $cluster++ } else { $clusterOfColumn[$i] = $cluster }
}
$numClusters = $cluster
# areas of each cluster (normal areas first, then the portals on its sides)
$clusterAreas = @{}
for ($c = 1; $c -le $numClusters; $c++) { $clusterAreas[$c] = @() }
$portalAreas = @()
foreach ($cell in $cells) {
  $i = $cell[0]; $j = $cell[1]; $area = AreaAt $i $j
  if ($clusterOfColumn[$i] -gt 0) { $clusterAreas[$clusterOfColumn[$i]] += $area } else { $portalAreas += $area }
}
$areaCluster = @{}; $areaClusterNum = @{}
foreach ($c in 1..$numClusters) {
  $n = 0
  foreach ($a in $clusterAreas[$c]) { $areaCluster[$a] = $c; $areaClusterNum[$a] = $n; $n++ }
}
$portals = @(, @(0, 0, 0, 0, 0))   # areaNum cluster0 cluster1 clusterAreaNum0 clusterAreaNum1
$clusterPortals = @{}
foreach ($c in 1..$numClusters) { $clusterPortals[$c] = @() }
$clusterCount = @{}
foreach ($c in 1..$numClusters) { $clusterCount[$c] = $clusterAreas[$c].Count }
foreach ($a in $portalAreas) {
  $cell = $cells[$a - 1]; $i = $cell[0]
  $left = $clusterOfColumn[$i - 1]; $right = $clusterOfColumn[$i + 1]
  if ($i -eq 0 -or $i -eq $Columns - 1 -or $left -eq 0 -or $right -eq 0) { throw "portal column $i is not between two clusters" }
  $p = $portals.Count
  $portals += , @($a, $left, $right, $clusterCount[$left], $clusterCount[$right])
  $clusterCount[$left]++; $clusterCount[$right]++
  $areaCluster[$a] = - $p; $areaClusterNum[$a] = 0
  $clusterPortals[$left] += $p; $clusterPortals[$right] += $p
}
$portalIndex = @(0); $clusterFirst = @{}
foreach ($c in 1..$numClusters) { $clusterFirst[$c] = $portalIndex.Count; $portalIndex += $clusterPortals[$c] }

# --- areas and reachabilities ------------------------------------------------------------------------------------
# flags: AREA_FLOOR 1, AREA_LEDGE 4, AREA_LIQUID 16, AREA_CROUCH 32, AREA_REACHABLE_WALK 64, AREA_REACHABLE_FLY 128
# contents: 1 solid, 2 water, 4 cluster portal
# reach types: 2 walk, 8 walk off ledge, 16 barrier jump, 32 jump, 128 swim, 2048 fly
function Special($area) {
  $flags = 1 + 64
  $contents = 0
  $cell = $cells[$area - 1]; $i = $cell[0]; $j = $cell[1]
  if ($clusterOfColumn[$i] -eq 0) { $contents = 4 }
  if (($i + 2 * $j) % 7 -eq 3) { $flags += 4 }                   # ledge
  if (($i * 3 + $j) % 11 -eq 5) { $flags += 16; $contents = $contents -bor 2 }  # water
  if (($i + $j * 5) % 9 -eq 4) { $flags += 32 }                  # crouch
  if (($i + $j) % 8 -eq 6) { $flags += 128 }                     # fly
  return @($flags, $contents)
}
$sb = New-Object System.Text.StringBuilder
function Line($s) { [void]$sb.Append($s + $nl) }
function ReachLine($type, $to, $sx, $sy, $ex, $ey, $edge, $time) {
  return "`t`t$type $to ($(Num $sx) $(Num $sy) 0) ($(Num $ex) $(Num $ey) 0) $edge $time"
}
$areaLines = @()
foreach ($cell in $cells) {
  $i = $cell[0]; $j = $cell[1]; $area = AreaAt $i $j
  $mine = Special $area
  $reach = @()
  $neighbours = @(@(1, 0), @(-1, 0), @(0, 1), @(0, -1))
  $n = 0
  foreach ($d in $neighbours) {
    $ni = $i + $d[0]; $nj = $j + $d[1]
    $other = AreaAt $ni $nj
    if ($other -eq 0) { continue }
    $theirs = Special $other
    # centre of the shared face, 4 units inside each area
    $fx = ($i + 0.5 + $d[0] * 0.5) * $size; $fy = ($j + 0.5 + $d[1] * 0.5) * $size
    $sx = $fx - $d[0] * 4; $sy = $fy - $d[1] * 4; $ex = $fx + $d[0] * 4; $ey = $fy + $d[1] * 4
    $type = 2
    $time = 20 + 7 * (($i + $j + $n) % 5)
    if (($mine[0] -band 4) -ne 0) { $type = 8; $time += 130 }                       # leaving a ledge area: walk off ledge
    elseif ((($i * 5 + $j * 3 + $n) % 9) -eq 4) { $type = 16; $time += 100 }        # barrier jump
    elseif ((($i * 7 + $j + $n) % 11) -eq 6) { $type = 32; $time += 60 }            # jump
    if (($mine[0] -band 16) -ne 0 -and ($theirs[0] -band 16) -ne 0) { $type = 128 }  # swim between two liquid areas
    if (($mine[0] -band 128) -ne 0 -and ($theirs[0] -band 128) -ne 0) { $type = 2048 } # fly
    $reach += (ReachLine $type $other $sx $sy $ex $ey $sharedEdge["$area,$other"] $time)
    $n++
  }
  # one jump over the next area of the row, now and then, to give the routing a shortcut
  $skip = AreaAt ($i + 2) $j
  if ($skip -gt 0 -and (($i + $j) % 3 -eq 0)) {
    $reach += (ReachLine 32 $skip (($i + 1) * $size - 4) ($j * $size + 32) (($i + 2) * $size + 4) ($j * $size + 32) 0 90)
  }
  $areaLines += , @($area, $mine, $reach)
}

# --- the text ----------------------------------------------------------------------------------------------------
Line 'DewmAAS "1.07"'
Line ''
Line $Crc
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
Line "`tallowSwimReachabilities = 1"
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
for ($k = 0; $k -lt $planes.Count; $k++) { $p = $planes[$k]; Line "`t$k ( $(Num $p[0]) $(Num $p[1]) $(Num $p[2]) $(Num $p[3]) )" }
Line '}'
Line "vertices $($vertices.Count) {"
for ($k = 0; $k -lt $vertices.Count; $k++) { $v = $vertices[$k]; Line "`t$k ( $(Num $v[0]) $(Num $v[1]) $(Num $v[2]) )" }
Line '}'
Line "edges $($edges.Count) {"
for ($k = 0; $k -lt $edges.Count; $k++) { Line "`t$k ( $($edges[$k][0]) $($edges[$k][1]) )" }
Line '}'
Line "edgeIndex $($edgeIndex.Count) {"
for ($k = 0; $k -lt $edgeIndex.Count; $k++) { Line "`t$k ( $($edgeIndex[$k]) )" }
Line '}'
Line "faces $($faces.Count) {"
for ($k = 0; $k -lt $faces.Count; $k++) { $f = $faces[$k]; Line "`t$k ( $($f[0]) $($f[1]) $($f[2]) $($f[3]) $($f[4]) $($f[5]) )" }
Line '}'
Line "faceIndex $($faceIndex.Count) {"
for ($k = 0; $k -lt $faceIndex.Count; $k++) { Line "`t$k ( $($faceIndex[$k]) )" }
Line '}'
Line "areas $($cells.Count + 1) {"
Line "`t0 ( 0 1 0 0 0 0 ) 0 {"
Line "`t}"
foreach ($al in $areaLines) {
  $area = $al[0]
  Line "`t$area ( $($al[1][0]) $($al[1][1]) $($areaFirstFace[$area]) $($areaNumFaces[$area]) $($areaCluster[$area]) $($areaClusterNum[$area]) ) $($al[2].Count) {"
  foreach ($r in $al[2]) { Line $r }
  Line "`t}"
}
Line '}'
Line "nodes $($nodes.Count) {"
for ($k = 0; $k -lt $nodes.Count; $k++) { $n = $nodes[$k]; Line "`t$k ( $($n[0]) $($n[1]) $($n[2]) )" }
Line '}'
Line "portals $($portals.Count) {"
for ($k = 0; $k -lt $portals.Count; $k++) { $p = $portals[$k]; Line "`t$k ( $($p[0]) $($p[1]) $($p[2]) $($p[3]) $($p[4]) )" }
Line '}'
Line "portalIndex $($portalIndex.Count) {"
for ($k = 0; $k -lt $portalIndex.Count; $k++) { Line "`t$k ( $($portalIndex[$k]) )" }
Line '}'
Line "clusters $($numClusters + 1) {"
Line "`t0 ( 0 0 0 0 )"
foreach ($c in 1..$numClusters) {
  Line "`t$c ( $($clusterCount[$c]) $($clusterCount[$c]) $($clusterFirst[$c]) $($clusterPortals[$c].Count) )"
}
Line '}'
New-Item -ItemType Directory -Force (Split-Path $Out) | Out-Null
[System.IO.File]::WriteAllText($Out, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))
"$Out : $($cells.Count) areas, $($portals.Count - 1) portals, $numClusters clusters"
