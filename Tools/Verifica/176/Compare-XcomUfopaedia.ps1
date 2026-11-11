<#
  Confronta l'Ufopaedia del vero OpenXcom con quella di Xcom32, pixel per pixel, su un salvataggio che ha tutte le
  ricerche fatte (Tests\Data\XcomSave\variants\save02_ufopaedia.sav per TFTD, ufo_save02_ufopaedia.sav per UFO).

  Uso: Compare-XcomUfopaedia.ps1 -Root <worktree> -Data <Reference\_dati\xcom_tftd> -Out <cartella> -Section 2 -Count 23
       Compare-XcomUfopaedia.ps1 -Root <worktree> -Data <Reference\_dati\xcom_ufo> -Out <cartella> -Section 0 -Count 11 -Ufo

  Dal geoscape: pulsante Ufopaedia (schermata "start"), il pulsante della sezione -Section (0 = il primo; "listN"),
  la riga -FirstRow della lista (sN_00 se e' la prima), poi -Count - 1 clic su ">>" (sN_01 ...). Usa Compare-XcomScreens.ps1 (che prende
  il lock dei giochi) e poi accoppia le schermate **per contenuto**: se un clic si perde in uno dei due programmi (la
  finestra di un altro processo prende il fuoco) la sequenza si sposta di uno, e il confronto per nome darebbe tutto
  diverso. Per ogni schermata del vero stampa quella di Xcom32 piu' simile, i pixel diversi e quelli diversi fuori
  dalla zona del cursore (-Cursor x,y,w,h: il puntatore sopra il pulsante ">>").
  La schermata iniziale e la lista stanno sopra il geoscape (orologio e rumore del globo cambiano): per quelle si
  confronta solo la finestra (64,20,512,360).
#>
param(
  [Parameter(Mandatory = $true)][string]$Root,
  [Parameter(Mandatory = $true)][string]$Data,
  [Parameter(Mandatory = $true)][string]$Out,
  [int]$Section = 0,
  [int]$Count = 1,
  # the row of the list to open first (0 to 12: the rows visible without scrolling), to start in the middle of a section
  [int]$FirstRow = 0,
  [switch]$Ufo,
  # seconds before the first click on the menu of the real program (see Compare-XcomScreens.ps1)
  [int]$StartWait = 12,
  [int[]]$Cursor = @()
)
$ErrorActionPreference = 'Stop'
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System; using System.Drawing; using System.Drawing.Imaging;
public static class UfopaediaPng {
  public static byte[] Load(string path) {
    using (Bitmap b = new Bitmap(path)) {
      int w = b.Width, h = b.Height;
      BitmapData d = b.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadOnly, PixelFormat.Format24bppRgb);
      byte[] r = new byte[d.Stride * h];
      System.Runtime.InteropServices.Marshal.Copy(d.Scan0, r, 0, r.Length);
      int stride = d.Stride; b.UnlockBits(d);
      byte[] o = new byte[w * h * 3];
      for (int y = 0; y < h; y++) Buffer.BlockCopy(r, y * stride, o, y * w * 3, w * 3);
      return o;
    }
  }
  // the different pixels; with inside = true only the ones in the zone, with inside = false only the ones out of it
  public static int Diff(byte[] a, byte[] b, int w, int zx, int zy, int zw, int zh, int mode) {
    if (a.Length != b.Length) return -1;
    int n = 0;
    for (int i = 0; i < a.Length; i += 3) {
      int p = i / 3; int x = p % w, y = p / w;
      bool inZone = x >= zx && x < zx + zw && y >= zy && y < zy + zh;
      if (mode == 1 && !inZone) continue;
      if (mode == 2 && inZone) continue;
      if (a[i] != b[i] || a[i + 1] != b[i + 1] || a[i + 2] != b[i + 2]) n++;
    }
    return n;
  }
}
"@
# the next button: 23 x 10 at (281, 179) in the TFTD articles, 30 x 14 at (75, 5) in the UFO ones (base 320 x 200)
$next = if ($Ufo) { '180,24' } else { '585,368' }
if ($Cursor.Count -ne 4) { $Cursor = if ($Ufo) { @(170, 14, 64, 44) } else { @(576, 360, 64, 40) } }
$save = if ($Ufo) { "$Root\Tests\Data\XcomSave\variants\ufo_save02_ufopaedia.sav" } else { "$Root\Tests\Data\XcomSave\variants\save02_ufopaedia.sav" }
$screens = @('start=576,82', ("+list{0}=320,{1}" -f $Section, (112 + 26 * $Section)), ("+s{0}_{1:00}=320,{2}" -f $Section, $FirstRow, (108 + 16 * $FirstRow)))
for ($i = 1; $i -lt $Count; $i++) { $screens += ("+s{0}_{1:00}=$next" -f $Section, ($FirstRow + $i)) }
if (Test-Path $Out) { Remove-Item -Recurse -Force $Out }
$common = @{ Root = $Root; Data = $Data; Out = $Out; Geoscape = $true; SaveFile = $save; Screens = $screens; StartWait = $StartWait }
if ($Ufo) { $common.Game = 'openxcom\UFO'; $common.ModId = 'xcom1' }
& "$Root\Tools\Verifica\176\Compare-XcomScreens.ps1" @common | Out-Null
foreach ($n in 'start', "list$Section") {
  if ((Test-Path "$Out\real\$n.png") -and (Test-Path "$Out\delphi\$n.png")) {
    $d = [UfopaediaPng]::Diff([UfopaediaPng]::Load("$Out\real\$n.png"), [UfopaediaPng]::Load("$Out\delphi\$n.png"), 640, 64, 20, 512, 360, 1)
    Write-Output ("{0}: {1} pixel diversi nella finestra" -f $n, $d)
  }
  else { Write-Output "${n}: MANCA" }
}
$delphi = @{}
Get-ChildItem "$Out\delphi" -Filter 's*_*.png' | ForEach-Object { $delphi[$_.BaseName] = [UfopaediaPng]::Load($_.FullName) }
$seen = @{}
foreach ($r in (Get-ChildItem "$Out\real" -Filter 's*_*.png' | Sort-Object Name)) {
  $a = [UfopaediaPng]::Load($r.FullName); $best = ''; $bestN = [int]::MaxValue
  foreach ($k in $delphi.Keys) { $d = [UfopaediaPng]::Diff($a, $delphi[$k], 640, 0, 0, 0, 0, 0); if ($d -ge 0 -and $d -lt $bestN) { $bestN = $d; $best = $k } }
  $outside = if ($bestN -gt 0) { [UfopaediaPng]::Diff($a, $delphi[$best], 640, $Cursor[0], $Cursor[1], $Cursor[2], $Cursor[3], 2) } else { 0 }
  $seen[$best] = $true
  Write-Output ("{0} -> {1}: {2} pixel diversi, {3} fuori dal cursore" -f $r.BaseName, $best, $bestN, $outside)
}
$missing = @($delphi.Keys | Where-Object { -not $seen.ContainsKey($_) } | Sort-Object)
if ($missing.Count -gt 0) { Write-Output ('articoli di Xcom32 senza una schermata del vero: ' + ($missing -join ', ')) }
