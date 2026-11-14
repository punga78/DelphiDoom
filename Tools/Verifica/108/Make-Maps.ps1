# Issue #108: writes the synthetic Doom 3 maps (and one .proc) that the parity harness and the tests read.
# Everything here is made up for the test: rooms, stairs, a slope, a pillar, clip, water and glass brushes, a patch,
# coplanar neighbours (to be merged), brushes inside brushes (to be chopped), a second entity, a proc BSP tree.
#
# Usage: Tools\Verifica\108\Make-Maps.ps1 [-Out <folder>]    (default: Tests\Data\Collision\Doom3)
param([string]$Out)

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $Out) { $Out = (Resolve-Path (Join-Path $here '..\..\..\Tests\Data')).Path + '\Collision\Doom3' }
New-Item -ItemType Directory -Force $Out | Out-Null
$inv = [Globalization.CultureInfo]::InvariantCulture
function N($v) { ([double]$v).ToString('0.######', $inv) }

# a brush from outward planes (normal, a point on the plane): ( a b c d ) with a*x + b*y + c*z + d = 0
function Side([double]$nx, [double]$ny, [double]$nz, [double]$px, [double]$py, [double]$pz, [string]$material) {
	$len = [Math]::Sqrt($nx * $nx + $ny * $ny + $nz * $nz)
	$nx /= $len; $ny /= $len; $nz /= $len
	$d = -($nx * $px + $ny * $py + $nz * $pz)
	"( $(N $nx) $(N $ny) $(N $nz) $(N $d) ) ( ( 0.0156 0 0 ) ( 0 0.0156 0 ) ) `"$material`" 0 0 0"
}
function Box([double]$x0, [double]$y0, [double]$z0, [double]$x1, [double]$y1, [double]$z1, [string]$material) {
	@(
		(Side 1 0 0 $x1 $y0 $z0 $material), (Side -1 0 0 $x0 $y0 $z0 $material),
		(Side 0 1 0 $x0 $y1 $z0 $material), (Side 0 -1 0 $x0 $y0 $z0 $material),
		(Side 0 0 1 $x0 $y0 $z1 $material), (Side 0 0 -1 $x0 $y0 $z0 $material)
	)
}
$script:prim = 0
function Brush($sides) {
	$s = "// primitive $($script:prim)`r`n{`r`nbrushDef3`r`n{`r`n"
	foreach ($x in $sides) { $s += $x + "`r`n" }
	$script:prim++
	$s + "}`r`n}`r`n"
}
function Patch2($material, $w, $h, $pts) {
	# pts: array of rows (height) of columns (width) of @(x y z s t); the file lists it by column
	$s = "// primitive $($script:prim)`r`n{`r`npatchDef2`r`n{`r`n`"$material`"`r`n( $w $h 0 0 0 )`r`n(`r`n"
	for ($j = 0; $j -lt $w; $j++) {
		$s += '( '
		for ($i = 0; $i -lt $h; $i++) { $p = $pts[$i][$j]; $s += "( $(N $p[0]) $(N $p[1]) $(N $p[2]) $(N $p[3]) $(N $p[4]) ) " }
		$s += ")`r`n"
	}
	$script:prim++
	$s + ")`r`n}`r`n}`r`n"
}
function Patch3($material, $w, $h, $hs, $vs, $pts) {
	$s = "// primitive $($script:prim)`r`n{`r`npatchDef3`r`n{`r`n`"$material`"`r`n( $w $h $hs $vs 0 0 0 )`r`n(`r`n"
	for ($j = 0; $j -lt $w; $j++) {
		$s += '( '
		for ($i = 0; $i -lt $h; $i++) { $p = $pts[$i][$j]; $s += "( $(N $p[0]) $(N $p[1]) $(N $p[2]) $(N $p[3]) $(N $p[4]) ) " }
		$s += ")`r`n"
	}
	$script:prim++
	$s + ")`r`n}`r`n}`r`n"
}
function Entity($num, $pairs, $body) {
	$script:prim = 0
	"// entity $num`r`n{`r`n" + (($pairs | ForEach-Object { "`"$($_[0])`" `"$($_[1])`"" }) -join "`r`n") + "`r`n" + $body + "}`r`n"
}
function Write-Map($name, $text) {
	[IO.File]::WriteAllText((Join-Path $Out $name), "Version 2`r`n" + $text, [Text.Encoding]::ASCII)
}
$solid = 'textures/solid'

# ------------------------------------------------------------------------------ room.map
$script:prim = 0
$b = ''
# the shell of a room 1024 x 1024 x 256
$b += Brush (Box -528 -528 -16 528 528 0 $solid)
$b += Brush (Box -528 -528 256 528 528 272 $solid)
$b += Brush (Box -528 -528 0 -512 528 256 $solid)
$b += Brush (Box 512 -528 0 528 528 256 $solid)
$b += Brush (Box -512 -528 0 512 -512 256 $solid)
$b += Brush (Box -512 512 0 512 528 256 $solid)
# stairs
for ($i = 0; $i -lt 5; $i++) { $b += Brush (Box (-400 + 32 * $i) 100 0 (-240) 164 (8 * ($i + 1)) $solid) }
# a slope: a wedge 100 long that rises 64
$b += Brush (@(
	(Side 0 0 -1 200 0 0 $solid), (Side 1 0 0 300 0 0 $solid), (Side 0 1 0 200 64 0 $solid), (Side 0 -1 0 200 -64 0 $solid),
	(Side -64 0 100 200 0 0 $solid)))
# a hexagonal pillar (apothem 40)
$sides = @((Side 0 0 1 0 0 256 $solid), (Side 0 0 -1 0 0 0 $solid))
for ($k = 0; $k -lt 6; $k++) {
	$a = [Math]::PI * $k / 3
	$nx = [Math]::Cos($a); $ny = [Math]::Sin($a)
	$sides += Side $nx $ny 0 (-300 + 40 * $nx) (200 + 40 * $ny) 0 $solid
}
$b += Brush $sides
# clip, water, glass, nonsolid, a body brush
$b += Brush (Box 200 -300 0 264 -236 128 'textures/clip')
$b += Brush (Box -200 -400 0 -100 -300 40 'textures/water')
$b += Brush (Box 0 300 0 16 400 128 'textures/glass')
$b += Brush (Box 300 300 0 340 340 64 'textures/nonsolid')
$b += Brush (Box -50 -50 0 -10 -10 32 'textures/body')
# a curved wall made of a patch
$pts = @()
for ($i = 0; $i -lt 3; $i++) {
	$row = @()
	for ($j = 0; $j -lt 3; $j++) { $row += , @((380 + 40 * $j), (-200 + 100 * $i), (30 * [Math]::Sin($j * [Math]::PI / 2) * 3 + 20 * $i), ($j * 0.5), ($i * 0.5)) }
	$pts += , $row
}
$b += Patch2 $solid 3 3 $pts
Write-Map 'room.map' (Entity 0 @(, @('classname', 'worldspawn')) $b)

# ------------------------------------------------------------------------------ tiles.map
$script:prim = 0
$b = ''
# a floor of four coplanar tiles (their polygons are merged) and a box standing across two of them
$b += Brush (Box 0 0 -16 128 128 0 $solid)
$b += Brush (Box 128 0 -16 256 128 0 $solid)
$b += Brush (Box 0 128 -16 128 256 0 $solid)
$b += Brush (Box 128 128 -16 256 256 0 $solid)
$b += Brush (Box 96 96 0 160 160 48 $solid)
# a brush inside another brush (its polygons are removed)
$b += Brush (Box -256 -256 -16 -64 -64 128 $solid)
$b += Brush (Box -200 -200 0 -120 -120 100 $solid)
# a wall next to the floor and a roof
$b += Brush (Box 256 0 -16 272 256 128 $solid)
$b += Brush (Box 0 0 128 272 256 144 $solid)
# a sloped floor made of two non-axial brushes sharing a plane
$b += Brush (@((Side 0 0 -1 0 0 -16 $solid), (Side 1 0 0 400 0 0 $solid), (Side -1 0 0 300 0 0 $solid), (Side 0 1 0 0 128 0 $solid),
	(Side 0 -1 0 0 0 0 $solid), (Side -32 0 100 300 0 0 $solid)))
$b += Brush (@((Side 0 0 -1 0 0 -16 $solid), (Side 1 0 0 500 0 0 $solid), (Side -1 0 0 400 0 0 $solid), (Side 0 1 0 0 128 0 $solid),
	(Side 0 -1 0 0 0 0 $solid), (Side -32 0 100 400 0 0 $solid)))
# a patch bridge with explicit subdivisions
$pts = @()
for ($i = 0; $i -lt 3; $i++) {
	$row = @()
	for ($j = 0; $j -lt 3; $j++) { $row += , @((600 + 64 * $j), (20 * $i), (16 * [Math]::Sin($i * [Math]::PI / 2) * 2), $j, $i) }
	$pts += , $row
}
$b += Patch3 $solid 3 3 4 4 $pts
$e0 = Entity 0 @(, @('classname', 'worldspawn')) $b
# an inline model: a door
$d = Brush (Box 0 0 0 64 8 96 $solid)
$e1 = Entity 1 @(@('classname', 'func_static'), @('name', 'door1')) $d
# a model that uses a "model" key
$d = (Brush (Box -16 -16 0 16 16 64 $solid)) + (Brush (Box -16 -16 64 16 16 80 'textures/glass'))
$e2 = Entity 2 @(@('classname', 'func_static'), @('model', 'models/crate.ase')) $d
Write-Map 'tiles.map' ($e0 + $e1 + $e2)

# a proc BSP tree for tiles.map: everything with x > 540 is "solid" ground that the player never sees
$proc = "mapProcFile003`r`n`r`nnodes { 1`r`n`t( 1 0 0 -540 ) 0 -1`r`n}`r`n"
[IO.File]::WriteAllText((Join-Path $Out 'tiles.proc'), $proc, [Text.Encoding]::ASCII)
Write-Host "Maps written to $Out"
