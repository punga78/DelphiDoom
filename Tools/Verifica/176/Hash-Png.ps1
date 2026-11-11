<#
  Prints "name WxH hash" for each PNG: the FNV-1a-32 of the R,G,B bytes of every pixel (the format of
  Tests\Data\XcomEngine\frames.golden.txt). Uso: Hash-Png.ps1 <png> [<png>...]
#>
param([Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)][string[]]$Files)
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System; using System.Drawing; using System.Drawing.Imaging;
public static class PngFnv {
  public static string Hash(string path) {
    using (Bitmap b = new Bitmap(path)) {
      int w = b.Width, h = b.Height;
      BitmapData d = b.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadOnly, PixelFormat.Format24bppRgb);
      byte[] r = new byte[d.Stride * h];
      System.Runtime.InteropServices.Marshal.Copy(d.Scan0, r, 0, r.Length);
      int stride = d.Stride; b.UnlockBits(d);
      uint hash = 2166136261;
      for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) {
        int i = y * stride + x * 3;
        hash = (hash ^ r[i + 2]) * 16777619; hash = (hash ^ r[i + 1]) * 16777619; hash = (hash ^ r[i]) * 16777619;
      }
      return w + "x" + h + " " + hash.ToString("x8");
    }
  }
}
"@
foreach ($f in $Files) { "$([IO.Path]::GetFileNameWithoutExtension($f)) $([PngFnv]::Hash($f))" }
