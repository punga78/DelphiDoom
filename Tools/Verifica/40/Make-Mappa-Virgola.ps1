<#
  Issue #40: genera la mappa di prova che esercita i punti in virgola mobile del renderer software che le demo del
  corpus non toccano: pavimenti e soffitti in pendenza (r_slopes), un pavimento 3D (r_3dfloors), cose con un voxel
  (r_voxels, con il PK3 di Tests\Data\Pk3) e, con lo script e le chiavi del .ini, la correzione di prospettiva
  (r_fake3d) e l'interpolazione (r_intrpl).

  Dati sintetici scritti qui (dominio pubblico): un PWAD con una sola mappa UDMF (MAP01) che non contiene nessun
  asset di un gioco; usa le texture, i flat e gli sprite di un IWAD di Doom 2 (FREEDOOM2.WAD: i dati dei giochi
  commerciali non sono nel repository). Il motore costruisce i nodi da solo (mappa senza nodi).

  Uso: powershell -NoProfile -File Tools\Verifica\40\Make-Mappa-Virgola.ps1
  Scrive Tests\Data\Fp40\fp40.wad e fp40.textmap.txt (il testo della mappa, per leggerla). L'uscita e' deterministica.

  Pianta (unita' di mappa):
    stanza S (x 0..512, y 0..1024): pavimento e soffitto in pendenza su due assi; il giocatore parte in (128, 256)
    stanza T (x 512..1024, y 0..1024): piatta, ha un pavimento 3D (la sbarra tra le quote 64 e 128, dal settore di
      controllo C fuori mappa, linea speciale 281 con id 2) e tre torce con un voxel (tipi 44, 45, 46)
    le due stanze sono unite da una linea a doppia faccia lunga come tutta la parete
#>
param(
  [switch]$NoSlopes,
  [switch]$No3dFloor,
  [switch]$NoControl,
  [string]$Name = 'fp40',
  [string]$OutDir = (Join-Path $PSScriptRoot '..\..\..\Tests\Data\Fp40')
)
$ErrorActionPreference = 'Stop'
$inv = [Globalization.CultureInfo]::InvariantCulture
function F([double]$v) { $v.ToString('0.#########', $inv) }

# piani nella forma di ZDoom: a x + b y + c z + d = 0 (la normale del pavimento sale, quella del soffitto scende)
function Get-Plane([double]$dzdx, [double]$dzdy, [double]$z0, [bool]$floor) {
  $n = [Math]::Sqrt(1 + $dzdx * $dzdx + $dzdy * $dzdy)
  $sign = if ($floor) { 1 } else { -1 }
  $a = -$dzdx / $n * $sign; $b = -$dzdy / $n * $sign; $c = 1 / $n * $sign
  $d = -$z0 / $n * $sign
  @($a, $b, $c, $d)
}
$floorPlane = Get-Plane 0.2 0.07 0 $true
$ceilingPlane = Get-Plane -0.1 0.03 256 $false
$controlFloorPlane = Get-Plane 0.05 0.02 64 $true
$controlCeilingPlane = Get-Plane 0.05 0.02 128 $false

$text = New-Object System.Text.StringBuilder
[void]$text.AppendLine('namespace = "doom";')
function Add-Thing([double]$x, [double]$y, [int]$angle, [int]$type) {
  [void]$text.AppendLine("thing`n{`nx = $(F $x);`ny = $(F $y);`nangle = $angle;`ntype = $type;`nskill1 = true;`nskill2 = true;`nskill3 = true;`nskill4 = true;`nskill5 = true;`nsingle = true;`ncoop = true;`ndm = true;`n}")
}
function Add-Vertex([double]$x, [double]$y) {
  [void]$text.AppendLine("vertex`n{`nx = $(F $x);`ny = $(F $y);`n}")
}
$sideIndex = 0
function Add-Side([int]$sector, [string]$middle, [string]$top, [string]$bottom) {
  [void]$text.AppendLine("sidedef`n{`nsector = $sector;`ntexturemiddle = `"$middle`";`ntexturetop = `"$top`";`ntexturebottom = `"$bottom`";`n}")
  $script:sideIndex++
  $script:sideIndex - 1
}
function Add-Line([int]$v1, [int]$v2, [int]$front, [int]$back, [int]$special, [int]$id) {
  $extra = ''
  if ($back -ge 0) { $extra += "sideback = $back;`ntwosided = true;`n" } else { $extra += "blocking = true;`n" }
  if ($special -ne 0) { $extra += "special = $special;`nid = $id;`n" }
  [void]$text.AppendLine("linedef`n{`nv1 = $v1;`nv2 = $v2;`nsidefront = $front;`n$extra}")
}

# --- cose -------------------------------------------------------------------------------------------------------
Add-Thing 128 256 0 1
# torce con un voxel nel PK3 di prova (VOXELDEF: treda, tblua, tgrna) e qualche cosa senza voxel
Add-Thing 700 256 180 44
Add-Thing 700 512 180 45
Add-Thing 700 768 180 46
Add-Thing 900 384 0 2028
Add-Thing 900 640 0 2035
Add-Thing 300 700 0 2028
Add-Thing 380 300 0 2035

# --- vertici ----------------------------------------------------------------------------------------------------
Add-Vertex 0 0        # 0
Add-Vertex 512 0      # 1
Add-Vertex 1024 0     # 2
Add-Vertex 1024 1024  # 3
Add-Vertex 512 1024   # 4
Add-Vertex 0 1024     # 5
Add-Vertex 2000 0     # 6
Add-Vertex 2000 64    # 7
Add-Vertex 2064 64    # 8
Add-Vertex 2064 0     # 9

# --- lati e linee (la faccia anteriore e' a destra del verso della linea) ----------------------------------------
$wall = 'BROWN1'
$s0 = Add-Side 0 $wall $wall $wall   # S, pareti
$s1 = Add-Side 0 $wall $wall $wall
$s2 = Add-Side 0 $wall $wall $wall
$sPortalS = Add-Side 0 '-' $wall $wall
$sPortalT = Add-Side 1 '-' $wall $wall
$t0 = Add-Side 1 $wall $wall $wall   # T, pareti
$t1 = Add-Side 1 $wall $wall $wall
$t2 = Add-Side 1 $wall $wall $wall
$c0 = Add-Side 2 $wall $wall $wall   # C, il settore del pavimento 3D
$c1 = Add-Side 2 $wall $wall $wall
$c2 = Add-Side 2 $wall $wall $wall
$c3 = Add-Side 2 $wall $wall $wall
Add-Line 0 5 $s0 -1 0 0
Add-Line 5 4 $s1 -1 0 0
Add-Line 1 0 $s2 -1 0 0
Add-Line 4 1 $sPortalS $sPortalT 0 0
Add-Line 4 3 $t0 -1 0 0
Add-Line 3 2 $t1 -1 0 0
Add-Line 2 1 $t2 -1 0 0
$special3d = 281; if ($No3dFloor) { $special3d = 0 }
if (-not $NoControl) {
  Add-Line 6 7 $c0 -1 $special3d 2
  Add-Line 7 8 $c1 -1 0 0
  Add-Line 8 9 $c2 -1 0 0
  Add-Line 9 6 $c3 -1 0 0
}

# --- settori ----------------------------------------------------------------------------------------------------
$planes = "floorplane_a = $(F $floorPlane[0]);`nfloorplane_b = $(F $floorPlane[1]);`nfloorplane_c = $(F $floorPlane[2]);`nfloorplane_d = $(F $floorPlane[3]);`n" +
  "ceilingplane_a = $(F $ceilingPlane[0]);`nceilingplane_b = $(F $ceilingPlane[1]);`nceilingplane_c = $(F $ceilingPlane[2]);`nceilingplane_d = $(F $ceilingPlane[3]);`n" +
  "rotationfloor = 35;`nrotationceiling = 50;`n"
if ($NoSlopes) { $planes = '' }
$controlPlanes = "floorplane_a = $(F $controlFloorPlane[0]);`nfloorplane_b = $(F $controlFloorPlane[1]);`nfloorplane_c = $(F $controlFloorPlane[2]);`nfloorplane_d = $(F $controlFloorPlane[3]);`n" +
  "ceilingplane_a = $(F $controlCeilingPlane[0]);`nceilingplane_b = $(F $controlCeilingPlane[1]);`nceilingplane_c = $(F $controlCeilingPlane[2]);`nceilingplane_d = $(F $controlCeilingPlane[3]);`n"
if ($NoSlopes) { $controlPlanes = '' }
[void]$text.AppendLine("sector`n{`nheightfloor = 0;`nheightceiling = 256;`ntexturefloor = `"FLOOR4_8`";`ntextureceiling = `"CEIL3_5`";`nlightlevel = 200;`n$planes}")
[void]$text.AppendLine("sector`n{`nheightfloor = 0;`nheightceiling = 256;`ntexturefloor = `"FLOOR0_1`";`ntextureceiling = `"CEIL3_5`";`nlightlevel = 200;`nid = 2;`nrotationfloor = 20;`n}")
[void]$text.AppendLine("sector`n{`nheightfloor = 64;`nheightceiling = 128;`ntexturefloor = `"FLAT1`";`ntextureceiling = `"FLAT1`";`nlightlevel = 220;`n$controlPlanes}")


$map = [Text.Encoding]::ASCII.GetBytes($text.ToString())

# --- il PWAD: MAP01 (vuoto), TEXTMAP, ENDMAP ---------------------------------------------------------------------
function New-Wad($lumps) {
  $ms = New-Object IO.MemoryStream
  $bw = New-Object IO.BinaryWriter($ms)
  $bw.Write([Text.Encoding]::ASCII.GetBytes('PWAD')); $bw.Write([int]$lumps.Count); $bw.Write([int]0)
  $offsets = @()
  foreach ($l in $lumps) { $offsets += [int]$ms.Position; $bw.Write([byte[]]$l.Data) }
  $dir = [int]$ms.Position
  for ($i = 0; $i -lt $lumps.Count; $i++) {
    $bw.Write([int]$offsets[$i]); $bw.Write([int]$lumps[$i].Data.Length)
    $name = [Text.Encoding]::ASCII.GetBytes($lumps[$i].Name.PadRight(8, [char]0))
    $bw.Write($name, 0, 8)
  }
  $ms.Position = 8; $bw.Write([int]$dir)
  $bw.Flush(); $ms.ToArray()
}
$wad = New-Wad @(
  @{ Name = 'MAP01'; Data = [byte[]]@() },
  @{ Name = 'TEXTMAP'; Data = $map },
  @{ Name = 'ENDMAP'; Data = [byte[]]@() })
New-Item -ItemType Directory -Force $OutDir | Out-Null
[IO.File]::WriteAllBytes((Join-Path $OutDir "$Name.wad"), $wad)
[IO.File]::WriteAllBytes((Join-Path $OutDir "$Name.textmap.txt"), $map)
"scritto {0} ({1} byte)" -f (Join-Path $OutDir "$Name.wad"), $wad.Length
