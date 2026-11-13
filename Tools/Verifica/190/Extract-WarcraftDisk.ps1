<#
  Issue #190: estrae i file dell'immagine disco di Warcraft: Orcs & Humans (MBR + partizione FAT12/16/32)
  in una cartella nuova, scrive SHA-256 di ogni file e controlla DATA.WAR e i filmati.

  Uso:
    powershell -NoProfile -File Extract-WarcraftDisk.ps1 `
      -Zip  <...\_download\warcraft.zip> `    (oppure -Image warcraft.img)
      -Out  <...\Reference\_dati\warcraft> `  (cartella NUOVA o vuota)
      -Cinematics <...\Reference\war1\cinematics.txt>

  Non esegue nulla dell'immagine: legge solo byte. Scrive file solo dentro -Out, che deve essere vuota o inesistente.
  Uscita: i file dell'immagine in -Out, SHA256SUMS.txt (sha256, byte, nome) e REPORT.txt (controlli).
  I dati sono commerciali (Blizzard 1994): uso locale, mai nel repository.
#>
param(
  [string]$Zip,
  [string]$Image,
  [Parameter(Mandatory)][string]$Out,
  [string]$Cinematics,
  [string]$ExpectedDataWarSha256
)
$ErrorActionPreference = 'Stop'

if ($Zip) {
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $z = [IO.Compression.ZipFile]::OpenRead($Zip)
  try {
    $e = $z.Entries | Where-Object { $_.FullName -like '*.img' -or $_.FullName -like '*.ima' } | Select-Object -First 1
    if (-not $e) { throw "Nessuna immagine .img nello zip $Zip" }
    $ms = New-Object IO.MemoryStream
    $s = $e.Open(); try { $s.CopyTo($ms) } finally { $s.Dispose() }
    $b = $ms.ToArray()
  } finally { $z.Dispose() }
}
elseif ($Image) { $b = [IO.File]::ReadAllBytes($Image) }
else { throw 'Serve -Zip o -Image' }

if ((Test-Path $Out) -and (Get-ChildItem $Out -Force | Select-Object -First 1)) { throw "La cartella $Out non e' vuota: scelgo di non toccarla." }
New-Item -ItemType Directory -Force $Out | Out-Null

# --- MBR: prima partizione utilizzabile; se il settore 0 e' gia' un BPB (floppy) l'inizio e' 0
function U16($a, $o) { [int][BitConverter]::ToUInt16($a, $o) }
function U32($a, $o) { [long][BitConverter]::ToUInt32($a, $o) }
$start = 0
if ($b[510] -eq 0x55 -and $b[511] -eq 0xAA -and $b[0] -ne 0xEB -and $b[0] -ne 0xE9) {
  for ($p = 0; $p -lt 4; $p++) {
    $o = 446 + 16 * $p
    if ($b[$o + 4] -ne 0) { $start = U32 $b ($o + 8); $ptype = $b[$o + 4]; break }
  }
  if ($start -eq 0) { throw 'Nessuna partizione nell''MBR' }
}
$base = $start * 512
$bps = U16 $b ($base + 11); $spc = $b[$base + 13]; $res = U16 $b ($base + 14); $nfat = $b[$base + 16]
$rootN = U16 $b ($base + 17); $tot = U16 $b ($base + 19); if ($tot -eq 0) { $tot = U32 $b ($base + 32) }
$spf = U16 $b ($base + 22); if ($spf -eq 0) { $spf = U32 $b ($base + 36) }
if ($bps -ne 512 -or $spc -eq 0 -or $nfat -eq 0) { throw "BPB non valido (bps=$bps spc=$spc nfat=$nfat) al settore $start" }
$fatOff = $base + $res * $bps
$rootSectors = [int][Math]::Ceiling($rootN * 32 / $bps)
$rootOff = $base + ($res + $nfat * $spf) * $bps
$dataOff = $rootOff + $rootSectors * $bps
$clusterBytes = $spc * $bps
$clusters = [int][Math]::Floor(($tot - $res - $nfat * $spf - $rootSectors) / $spc)
$fatType = if ($rootN -eq 0) { 32 } elseif ($clusters -lt 4085) { 12 } elseif ($clusters -lt 65525) { 16 } else { 32 }
$report = New-Object Collections.Generic.List[string]
$report.Add("Partizione: primo settore $start, tipo MBR 0x$('{0:X2}' -f $ptype), FAT$fatType, $clusters cluster da $clusterBytes byte, $tot settori")

function NextCluster([int]$c) {
  switch ($fatType) {
    12 { $o = $fatOff + [int][Math]::Floor($c * 3 / 2); $v = U16 $b $o; if ($c % 2) { $v -shr 4 } else { $v -band 0xFFF } }
    16 { U16 $b ($fatOff + 2 * $c) }
    32 { (U32 $b ($fatOff + 4 * $c)) -band 0x0FFFFFFF }
  }
}
$eoc = switch ($fatType) { 12 { 0xFF8 } 16 { 0xFFF8 } 32 { 0x0FFFFFF8 } }
function Chain([int]$c, [long]$size, [bool]$isDir) {
  $ms = New-Object IO.MemoryStream
  $guard = 0
  while ($c -ge 2 -and $c -lt $eoc) {
    $ms.Write($b, $dataOff + ($c - 2) * $clusterBytes, $clusterBytes); $c = NextCluster $c
    if (++$guard -gt $clusters + 2) { throw 'Catena di cluster ciclica' }
  }
  $a = $ms.ToArray(); if (-not $isDir -and $a.Length -gt $size) { $a = $a[0..($size - 1)] }
  , $a
}
$files = New-Object Collections.Generic.List[object]
function Walk([byte[]]$bytes, [string]$path, [string]$rel) {
  New-Item -ItemType Directory -Force $path | Out-Null
  $lfn = New-Object Collections.Generic.List[string]   # frammenti di nome lungo, dall'ultimo al primo
  for ($o = 0; $o + 32 -le $bytes.Length; $o += 32) {
    if ($bytes[$o] -eq 0) { break }
    if ($bytes[$o] -eq 0xE5) { $lfn.Clear(); continue }
    $attr = $bytes[$o + 11]
    if ($attr -eq 0x0F) {
      # voce di nome lungo (VFAT): 5 + 6 + 2 caratteri UTF-16
      $part = ''
      foreach ($r in @(@(1, 5), @(14, 6), @(28, 2))) {
        for ($k = 0; $k -lt $r[1]; $k++) {
          $ch = U16 $bytes ($o + $r[0] + 2 * $k)
          if ($ch -eq 0 -or $ch -eq 0xFFFF) { break }
          $part += [char]$ch
        }
      }
      $lfn.Insert(0, $part); continue
    }
    if ($attr -band 0x08) { $lfn.Clear(); continue }
    $long = if ($lfn.Count) { -join $lfn } else { $null }; $lfn.Clear()
    $n = ([Text.Encoding]::ASCII.GetString($bytes, $o, 8)).TrimEnd(); $x = ([Text.Encoding]::ASCII.GetString($bytes, $o + 8, 3)).TrimEnd()
    if ($n -eq '.' -or $n -eq '..') { continue }
    $name = if ($long) { $long } elseif ($x) { "$n.$x" } else { $n }
    $c = U16 $bytes ($o + 26); if ($fatType -eq 32) { $c = $c -bor ((U16 $bytes ($o + 20)) -shl 16) }
    $sz = U32 $bytes ($o + 28)
    if ($attr -band 0x10) { Walk (Chain $c 0 $true) (Join-Path $path $name) "$rel$name/" }
    else {
      $content = if ($sz -eq 0) { [byte[]]@() } else { Chain $c $sz $false }
      [IO.File]::WriteAllBytes((Join-Path $path $name), $content)
      $files.Add([pscustomobject]@{ Name = "$rel$name"; Length = $content.Length; Declared = $sz })
    }
  }
}
if ($fatType -eq 32) { throw 'FAT32 non previsto da questo script (l''immagine della issue e'' FAT12/16)' }
Walk ([byte[]]$b[$rootOff..($dataOff - 1)]) $Out ''

# --- SHA-256 e controlli
$sums = foreach ($f in ($files | Sort-Object Name)) {
  $h = (Get-FileHash (Join-Path $Out $f.Name) -Algorithm SHA256).Hash.ToLower()
  $f | Add-Member -NotePropertyName Sha256 -NotePropertyValue $h -PassThru
  if ($f.Length -ne $f.Declared) { $report.Add("ATTENZIONE: $($f.Name) lunghezza $($f.Length) diversa dalla dichiarata $($f.Declared)") }
}
$sums | ForEach-Object { '{0}  {1,10}  {2}' -f $_.Sha256, $_.Length, $_.Name } | Set-Content (Join-Path $Out 'SHA256SUMS.txt') -Encoding ASCII
$report.Add("File estratti: $($files.Count), byte totali: $(($files | Measure-Object Length -Sum).Sum)")

# DATA.WAR: 12852768 byte, archiveID 0x18/0x1A = retail, 0x19 = demo (come wfile_loadWarFile del remake)
$dw = Join-Path $Out 'DATA\DATA.WAR'
if (Test-Path $dw) {
  $d = [IO.File]::ReadAllBytes($dw)
  $id = U32 $d 0; $count = U32 $d 4
  $kind = switch ($id) { 0x18 { 'RETAIL (0x18)' } 0x1A { 'RETAIL (0x1A)' } 0x19 { 'DEMO (0x19)' } default { 'SCONOSCIUTO' } }
  $report.Add("DATA.WAR: $($d.Length) byte (attesi 12852768: $(if ($d.Length -eq 12852768) {'OK'} else {'DIVERSO'})); archiveID 0x$('{0:X}' -f $id) = $kind; $count voci")
  $placeholders = 0
  for ($i = 0; $i -lt $count; $i++) { $off = U32 $d (8 + 4 * $i); if ($off -eq 0 -or $off -eq 0xFFFFFFFF) { $placeholders++ } }
  $report.Add("DATA.WAR: voci segnaposto (offset 0 o FFFFFFFF): $placeholders")
  if ($ExpectedDataWarSha256) { $report.Add("DATA.WAR sha256 atteso: $(if (($sums | Where-Object Name -eq 'DATA/DATA.WAR').Sha256 -eq $ExpectedDataWarSha256.ToLower()) {'OK'} else {'DIVERSO'})") }
} else { $report.Add('ATTENZIONE: DATA/DATA.WAR assente') }

# Versione e lingua: stringhe leggibili di WAR.EXE (solo lettura dei byte) e intestazione del README
$exe = Join-Path $Out 'WAR.EXE'
if (Test-Path $exe) {
  $txt = [Text.Encoding]::GetEncoding(28591).GetString([IO.File]::ReadAllBytes($exe))
  $m = [regex]::Matches($txt, 'WARCRAFT[ -~]{0,20}VERSION[ -~]{1,12}')
  foreach ($v in $m) { $report.Add("WAR.EXE: stringa di versione '$($v.Value.Trim())'") }
}
$readme = Join-Path $Out 'README.TXT'
if (Test-Path $readme) {
  $rev = Get-Content $readme -TotalCount 6 | Where-Object { $_ -match 'Revision' } | Select-Object -First 1
  if ($rev) { $report.Add("README.TXT: '$($rev.Trim())' (testo inglese)") }
}

# Filmati: nomi della tabella di cinematics.txt contro i .WAR estratti
if ($Cinematics) {
  $listed = Get-Content $Cinematics | ForEach-Object { if ($_ -match '^([A-Z0-9]+)\s{2,}\S') { $Matches[1] } } | Where-Object { $_ -and $_ -ne 'File' }
  # i filmati stanno in DATA\<NOME>.WAR (DATA.WAR e' l'archivio, non un filmato)
  $movies = $files | Where-Object { $_.Name -like 'DATA/*.WAR' -and $_.Name -ne 'DATA/DATA.WAR' } | ForEach-Object { [IO.Path]::GetFileNameWithoutExtension($_.Name).ToUpper() }
  $missing = $listed | Where-Object { $movies -notcontains $_ }
  $report.Add("Filmati elencati in cinematics.txt: $($listed.Count); presenti come DATA\*.WAR: $(($listed | Where-Object { $movies -contains $_ }).Count); mancanti: $($missing.Count)")
  $report.Add("Mancanti: $($missing -join ', ')")
  $extra = $movies | Where-Object { $listed -notcontains $_ }
  $report.Add("File .WAR non nell'elenco dei filmati: $($extra -join ', ')")
}
$report | Set-Content (Join-Path $Out 'REPORT.txt') -Encoding UTF8
$report
