<#
  X-COM: Terror from the Deep su floppy (TFTD.001..004): sono molti archivi ZIP uno dopo l'altro (non un solo
  ZIP suddiviso). Il programma di installazione li sdoppia con PKUNZJR; qui si fa lo stesso senza eseguire nulla:
  si concatenano i quattro file, si taglia dopo ogni "end of central directory" e si apre ogni pezzo con
  System.IO.Compression.
  Uso: powershell -NoProfile -File Extract-TftdZips.ps1 -Volumes a,b,c,d -Out <cartella nuova>
#>
param([Parameter(Mandatory)][string[]]$Volumes, [Parameter(Mandatory)][string]$Out)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
$ms = New-Object IO.MemoryStream
foreach ($v in $Volumes) { $x = [IO.File]::ReadAllBytes($v); $ms.Write($x, 0, $x.Length) }
$b = $ms.ToArray()
$start = 0; $n = 0; $files = 0; $firstOf = @{}
for ($i = 0; $i -lt $b.Length - 21; $i++) {
  if ($b[$i] -eq 0x50 -and $b[$i + 1] -eq 0x4B -and $b[$i + 2] -eq 5 -and $b[$i + 3] -eq 6) {
    $cl = [BitConverter]::ToUInt16($b, $i + 20)
    $end = $i + 22 + $cl
    if ($end -gt $b.Length) { continue }
    $seg = New-Object IO.MemoryStream (, [byte[]]$b[$start..($end - 1)])
    $zip = New-Object IO.Compression.ZipArchive $seg
    foreach ($e in $zip.Entries) {
      if ($e.FullName.EndsWith('/')) { continue }
      $rel = $e.FullName -replace '\\', '/'
      if ($rel.Contains('..') -or $rel.StartsWith('/')) { throw "nome sospetto: $rel" }
      $dest = Join-Path $Out $rel
      New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
      # Due archivi hanno un file con lo stesso nome e contenuto diverso (LOFTEMPS.DAT: 3648 byte per TERRAIN e
      # 3584 per GEODATA; SCANG.DAT): il primo non va perso, resta in _doppi\<archivio>_<nome> e
      # Make-TftdLayout.ps1 lo mette nella cartella giusta. Prima il secondo lo copriva e TERRAIN\LOFTEMPS.DAT era
      # quello corto: una battaglia sulla nave da carico finiva con "a voxel is outside the LOFT data".
      if (Test-Path $dest) {
        $ms2 = New-Object IO.MemoryStream; $s2 = $e.Open(); $s2.CopyTo($ms2); $s2.Close()
        $old = [IO.File]::ReadAllBytes($dest)
        if ([Convert]::ToBase64String($old) -ne [Convert]::ToBase64String($ms2.ToArray())) {
          $dup = Join-Path $Out '_doppi'; New-Item -ItemType Directory -Force $dup | Out-Null
          Move-Item $dest (Join-Path $dup ('{0:00}_{1}' -f $firstOf[$rel], (Split-Path $rel -Leaf))) -Force
          "doppio: $rel (archivio $($firstOf[$rel]): $($old.Length) byte, archivio ${n}: $($e.Length) byte)"
        }
      }
      if (-not $firstOf.ContainsKey($rel)) { $firstOf[$rel] = $n }
      $s = $e.Open(); $f = [IO.File]::Create($dest); $s.CopyTo($f); $f.Close(); $s.Close(); $files++
    }
    $zip.Dispose(); $n++; $start = $end; $i = $end - 1
  }
}
"archivi: $n, file: $files"
