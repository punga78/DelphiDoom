<#
  Confronta due PNG pixel per pixel (RGB, anche se uno e' a palette e l'altro a 24 bit): stampa dimensioni, numero di
  pixel diversi, riquadro che li contiene e i primi diversi. Esce con codice 0 se sono uguali, 1 altrimenti.
  Uso: Compare-Png.ps1 -A <png> -B <png> [-Ignore x,y,w,h]   (la zona da ignorare, ad esempio il cursore)
#>
param(
  [Parameter(Mandatory = $true)][string]$A,
  [Parameter(Mandatory = $true)][string]$B,
  [int[]]$Ignore = @()
)
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System; using System.Drawing; using System.Drawing.Imaging;
public static class PngRgb {
  public static byte[] Load(string path, out int w, out int h) {
    using (Bitmap b = new Bitmap(path)) {
      w = b.Width; h = b.Height;
      BitmapData d = b.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadOnly, PixelFormat.Format24bppRgb);
      byte[] r = new byte[d.Stride * h];
      System.Runtime.InteropServices.Marshal.Copy(d.Scan0, r, 0, r.Length);
      int stride = d.Stride; b.UnlockBits(d);
      byte[] o = new byte[w * h * 3];
      for (int y = 0; y < h; y++) Buffer.BlockCopy(r, y * stride, o, y * w * 3, w * 3);
      return o;
    }
  }
}
"@
$wa = 0; $ha = 0; $wb = 0; $hb = 0
$da = [PngRgb]::Load($A, [ref]$wa, [ref]$ha)
$db = [PngRgb]::Load($B, [ref]$wb, [ref]$hb)
if ($wa -ne $wb -or $ha -ne $hb) { Write-Output "DIMENSIONI DIVERSE: ${wa}x${ha} contro ${wb}x${hb}"; exit 1 }
$diff = 0; $minx = 99999; $miny = 99999; $maxx = -1; $maxy = -1; $first = @()
for ($y = 0; $y -lt $ha; $y++) {
  for ($x = 0; $x -lt $wa; $x++) {
    if ($Ignore.Count -eq 4 -and $x -ge $Ignore[0] -and $x -lt $Ignore[0] + $Ignore[2] -and $y -ge $Ignore[1] -and $y -lt $Ignore[1] + $Ignore[3]) { continue }
    $i = ($y * $wa + $x) * 3
    if ($da[$i] -ne $db[$i] -or $da[$i + 1] -ne $db[$i + 1] -or $da[$i + 2] -ne $db[$i + 2]) {
      $diff++
      if ($x -lt $minx) { $minx = $x }; if ($y -lt $miny) { $miny = $y }
      if ($x -gt $maxx) { $maxx = $x }; if ($y -gt $maxy) { $maxy = $y }
      if ($first.Count -lt 5) { $first += "($x,$y) $($da[$i+2]),$($da[$i+1]),$($da[$i]) / $($db[$i+2]),$($db[$i+1]),$($db[$i])" }
    }
  }
}
Write-Output "${wa}x${ha}: pixel diversi $diff su $($wa * $ha)"
if ($diff -gt 0) { Write-Output "riquadro: $minx,$miny - $maxx,$maxy"; $first | ForEach-Object { Write-Output "  $_" }; exit 1 }
