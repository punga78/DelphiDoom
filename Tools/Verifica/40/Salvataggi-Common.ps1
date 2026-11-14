<#
  Issue #40 (sotto-issue #43): funzioni comuni delle prove dei salvataggi (si caricano con . .\Salvataggi-Common.ps1
  dopo Tools\Verifica\185\Parity-Common.ps1).

  - Invoke-SaveRun      lancia un gioco fino alla sua uscita (col lock globale, o senza con -NoLock)
  - Select-SaveTics     sceglie dai tic di un log di stato quelli in cui salvare
  - Clear-SaveDirs, Copy-SaveDirs, Restore-SaveDirs   le cartelle dei salvataggi della cartella di lavoro
  - Compare-StateLogs   la prima riga diversa di due log di stato ('' se sono uguali)
  - Get-StateLineCount  le righe di tic di un log di stato
  - Test-LoadedWorld    il mondo dopo il caricamento e' quello del programma che ha salvato, un tic dopo?
  - Compare-SaveTrees   due cartelle di salvataggi byte per byte
#>

function Invoke-SaveRun {
  param(
    [Parameter(Mandatory = $true)][string]$Exe,
    [Parameter(Mandatory = $true)][string]$Arguments,
    [Parameter(Mandatory = $true)][string]$WorkDir,
    [int]$TimeoutSeconds = 300,
    # un programma che non esce da solo (il riferimento non ha -autoquit) si chiude quando il log ha queste righe
    [string]$StateFile = '',
    [int]$EnoughLines = 0,
    [switch]$NoLock
  )
  if (-not $NoLock) { return (Invoke-ParityGame -Exe $Exe -Arguments $Arguments -WorkDir $WorkDir -TimeoutSeconds $TimeoutSeconds) }
  $process = Start-Process -FilePath $Exe -ArgumentList $Arguments -WorkingDirectory $WorkDir -PassThru
  if ($StateFile -ne '' -and $EnoughLines -gt 0) {
    $watch = [Diagnostics.Stopwatch]::StartNew()
    while (-not $process.WaitForExit(2000) -and $watch.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
      if ((Test-Path $StateFile) -and ((Get-Item $StateFile).Length -gt 200 * $EnoughLines)) {
        $lines = 0
        try {
          $stream = New-Object IO.FileStream($StateFile, 'Open', 'Read', 'ReadWrite')
          $reader = New-Object IO.StreamReader($stream)
          while ($null -ne ($row = $reader.ReadLine())) { if ($row.StartsWith('T ')) { $lines++ } }
          $reader.Dispose()
        } catch { $lines = 0 }
        if ($lines -ge $EnoughLines + 2) { break }
      }
    }
    $alive = -not $process.HasExited
  }
  else { $alive = -not $process.WaitForExit($TimeoutSeconds * 1000) }
  if ($alive) {
    Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
    # i file del processo restano aperti finche' non e' finito davvero
    $null = $process.WaitForExit(15000)
  }
  [pscustomobject]@{ Alive = $alive; Crash = (Test-Path (Join-Path $WorkDir 'crash.txt')) }
}

# Le righe "T tic hash chiave=valore..." di un log di stato come oggetti (solo i numeri che servono).
function Read-StateTics {
  param([Parameter(Mandatory = $true)][string]$File)
  if (-not (Test-Path $File)) { return @() }
  foreach ($row in [IO.File]::ReadLines($File)) {
    if (-not $row.StartsWith('T ')) { continue }
    $f = $row.Split(' ')
    $item = @{ Tic = [int]$f[1]; th = 0; mo = 0; hp = 0; lt = 0 }
    foreach ($kv in $f) {
      $p = $kv.IndexOf('=')
      if ($p -le 0) { continue }
      $k = $kv.Substring(0, $p)
      if ($item.ContainsKey($k)) { $item[$k] = [int]$kv.Substring($p + 1) }
    }
    [pscustomobject]$item
  }
}

# I tic in cui salvare: quello con piu' thinker che non sono mobj (porte, piattaforme, luci, script: th - mo), quello
# con piu' mobj (proiettili in volo, oggetti nati) e uno avanti nella partita; solo tic col giocatore vivo.
function Select-SaveTics {
  param([Parameter(Mandatory = $true)][string]$StateFile, [int]$Count = 3, [int]$MinTic = 20, [int]$MinGap = 10)
  $tics = @(Read-StateTics $StateFile)
  if ($tics.Count -lt $MinTic + 5) { return @() }
  $last = $tics[$tics.Count - 1].Tic
  $alive = @($tics | Where-Object { $_.hp -gt 0 -and $_.Tic -ge $MinTic -and $_.Tic -le ($last - 3) })
  if ($alive.Count -eq 0) { return @() }
  $chosen = New-Object System.Collections.ArrayList
  $far = { param($t) foreach ($c in $chosen) { if ([Math]::Abs($c.Tic - $t.Tic) -lt $MinGap) { return $false } } return $true }
  # a parita' di numero, il tic piu' vicino al 40% (speciali) e al 60% (mobj) della partita: non l'inizio del livello
  $end = $alive[$alive.Count - 1].Tic
  $bySpecials = @($alive | Sort-Object @{ Expression = { $_.th - $_.mo }; Descending = $true }, @{ Expression = { [Math]::Abs($_.Tic - [int]($end * 0.4)) } })
  $null = $chosen.Add($bySpecials[0])
  if ($Count -ge 2) {
    $byMobjs = @($alive | Sort-Object @{ Expression = { $_.mo }; Descending = $true }, @{ Expression = { [Math]::Abs($_.Tic - [int]($end * 0.6)) } } | Where-Object { & $far $_ })
    if ($byMobjs.Count -gt 0) { $null = $chosen.Add($byMobjs[0]) }
  }
  if ($Count -ge 3) {
    $target = [int]($alive[$alive.Count - 1].Tic * 0.85)
    $late = @($alive | Sort-Object @{ Expression = { [Math]::Abs($_.Tic - $target) } }, Tic | Where-Object { & $far $_ })
    if ($late.Count -gt 0) { $null = $chosen.Add($late[0]) }
  }
  $chosen | Sort-Object Tic | ForEach-Object { [pscustomobject]@{ Tic = $_.Tic; Specials = $_.th - $_.mo; Mobjs = $_.mo } }
}

function Clear-SaveDirs {
  param([string]$WorkDir, [string[]]$SaveDirs)
  foreach ($name in $SaveDirs) {
    $path = Join-Path $WorkDir $name
    if (Test-Path $path) { Remove-Item $path -Recurse -Force }
  }
}

# Copia le cartelle dei salvataggi in Target\<cartella>; restituisce il numero di file.
function Copy-SaveDirs {
  param([string]$WorkDir, [string[]]$SaveDirs, [string]$Target)
  $count = 0
  foreach ($name in $SaveDirs) {
    $path = Join-Path $WorkDir $name
    if (-not (Test-Path $path)) { continue }
    $files = @(Get-ChildItem $path -Recurse -File)
    if ($files.Count -eq 0) { continue }
    $destination = Join-Path $Target $name
    New-Item -ItemType Directory -Force (Split-Path -Parent $destination) | Out-Null
    Copy-Item $path $destination -Recurse -Force
    $count += $files.Count
  }
  $count
}

function Restore-SaveDirs {
  param([string]$WorkDir, [string]$Source)
  if (-not (Test-Path $Source)) { return }
  # file per file: Copy-Item di una cartella dentro una che esiste gia' la annida
  foreach ($file in (Get-ChildItem $Source -Recurse -File)) {
    $target = Join-Path $WorkDir $file.FullName.Substring($Source.Length).TrimStart('\')
    New-Item -ItemType Directory -Force (Split-Path -Parent $target) | Out-Null
    Copy-Item $file.FullName $target -Force
  }
}

function Get-StateLineCount {
  param([string]$File)
  if (-not (Test-Path $File)) { return 0 }
  $count = 0
  foreach ($row in [IO.File]::ReadLines($File)) { if ($row.StartsWith('T ')) { $count++ } }
  $count
}

# '' se le righe di tic sono uguali (fino al tic MaxTic se dato), altrimenti il tic e le impronte diverse.
function Compare-StateLogs {
  param([string]$Expected, [string]$Actual, [int]$MaxTic = -1)
  if (-not (Test-Path $Expected) -or -not (Test-Path $Actual)) { return 'log mancante' }
  $a = @([IO.File]::ReadLines($Expected) | Where-Object { $_.StartsWith('T ') })
  $b = @([IO.File]::ReadLines($Actual) | Where-Object { $_.StartsWith('T ') })
  if ($MaxTic -ge 0) {
    $a = @($a | Where-Object { [int]$_.Split(' ')[1] -le $MaxTic })
    $b = @($b | Where-Object { [int]$_.Split(' ')[1] -le $MaxTic })
  }
  $n = [Math]::Min($a.Count, $b.Count)
  for ($i = 0; $i -lt $n; $i++) {
    if ($a[$i] -ceq $b[$i]) { continue }
    $x = $a[$i].Split(' '); $y = $b[$i].Split(' ')
    $names = @()
    for ($k = 2; $k -lt [Math]::Min($x.Count, $y.Count); $k++) {
      if ($x[$k] -cne $y[$k]) { $p = $x[$k].IndexOf('='); if ($p -gt 0) { $names += $x[$k].Substring(0, $p) } else { $names += 'totale' } }
    }
    return ("tic {0}: {1}" -f $x[1], ($names -join ','))
  }
  if ($a.Count -ne $b.Count) { return ("lunghezza diversa: {0} e {1} tic" -f $a.Count, $b.Count) }
  ''
}

# Il programma che ha salvato ha giocato ancora un tic dopo il salvataggio; chi carica gioca il suo primo tic dallo
# stesso stato: i comandi del giocatore sono diversi (cambiano mobj e giocatore) ma settori, lati e linee, che in
# un tic cambiano solo per i loro thinker, devono avere le stesse impronte, e il tempo del livello deve seguire.
function Test-LoadedWorld {
  param([string]$SaverLog, [string]$LoaderLog, [int]$SaveTic)
  $saver = @(Read-StateRow $SaverLog ($SaveTic + 1))
  $loader = @(Read-StateRow $LoaderLog -1)
  if ($saver.Count -eq 0 -or $loader.Count -eq 0) { return 'n/d' }
  $different = @()
  foreach ($key in 'lt', 'sector', 'side', 'line', 'th', 'mo') {
    if ($saver[0][$key] -cne $loader[0][$key]) { $different += $key }
  }
  if ($different.Count -eq 0) { return 'uguale' }
  'diverso (' + ($different -join ',') + ')'
}

# La riga di un tic (o la prima, con Tic = -1) come tabella chiave -> testo.
function Read-StateRow {
  param([string]$File, [int]$Tic)
  if (-not (Test-Path $File)) { return @() }
  foreach ($row in [IO.File]::ReadLines($File)) {
    if (-not $row.StartsWith('T ')) { continue }
    $f = $row.Split(' ')
    if ($Tic -ge 0 -and [int]$f[1] -ne $Tic) { continue }
    $table = @{}
    foreach ($kv in $f) { $p = $kv.IndexOf('='); if ($p -gt 0) { $table[$kv.Substring(0, $p)] = $kv.Substring($p + 1) } }
    return @($table)
  }
  @()
}

if (-not ('SaveFileCompare' -as [type])) { Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Text;
public static class SaveFileCompare {
  // number of different bytes (-1: different sizes) and the first ranges of offsets that differ
  public static string Compare(string a, string b, out long count) {
    byte[] x = File.ReadAllBytes(a); byte[] y = File.ReadAllBytes(b);
    count = 0;
    if (x.Length != y.Length) { count = -1; return "dimensioni " + x.Length + " e " + y.Length; }
    StringBuilder ranges = new StringBuilder();
    int shown = 0; int start = -1;
    for (int i = 0; i <= x.Length; i++) {
      bool diff = i < x.Length && x[i] != y[i];
      if (diff) { count++; if (start < 0) start = i; }
      else if (start >= 0) {
        if (shown < 24) { ranges.Append(start == i - 1 ? (" " + start) : (" " + start + "-" + (i - 1))); shown++; }
        else if (shown == 24) { ranges.Append(" ..."); shown++; }
        start = -1;
      }
    }
    return ranges.ToString().Trim();
  }
  // true when every byte that differs between a and b also differs between c and d (files of the same size)
  public static bool DifferencesInside(string a, string b, string c, string d) {
    byte[] x = File.ReadAllBytes(a); byte[] y = File.ReadAllBytes(b);
    byte[] z = File.ReadAllBytes(c); byte[] w = File.ReadAllBytes(d);
    if (x.Length != y.Length || z.Length != w.Length || x.Length != z.Length) return false;
    // an address is 4 bytes and two addresses may share some of them: a byte counts as inside when one of the
    // bytes of its 4 byte slot differs in the other pair
    for (int i = 0; i < x.Length; i++) {
      if (x[i] == y[i]) continue;
      bool near = false;
      for (int k = Math.Max(0, i - 3); k <= Math.Min(x.Length - 1, i + 3); k++) if (z[k] != w[k]) near = true;
      if (!near) return false;
    }
    return true;
  }
}
'@ }

# I byte che cambiano tra il riferimento a 32 bit e il programma nuovo a 32 bit sono tutti tra quelli che cambiano
# anche tra 32 e 64 bit? (sono gli indirizzi di memoria che il salvataggio contiene e che il caricamento ignora:
# cambiano da un eseguibile all'altro). 'si', 'NO' oppure '' se manca una delle cartelle.
function Test-SaveDifferencesInside {
  param([string]$Reference, [string]$New32, [string]$New64)
  if (-not (Test-Path $Reference) -or -not (Test-Path $New32) -or -not (Test-Path $New64)) { return '' }
  foreach ($file in (Get-ChildItem $New32 -Recurse -File)) {
    $name = $file.FullName.Substring($New32.Length).TrimStart('\')
    $r = Join-Path $Reference $name; $w = Join-Path $New64 $name
    if (-not (Test-Path $r) -or -not (Test-Path $w)) { return 'NO' }
    if (-not [SaveFileCompare]::DifferencesInside($r, $file.FullName, $file.FullName, $w)) { return 'NO' }
  }
  'si'
}

# Due cartelle di salvataggi: 'uguali (n file, m byte)' oppure quanti byte cambiano; i dettagli vanno in ReportFile.
function Compare-SaveTrees {
  param([string]$Left, [string]$Right, [string]$ReportFile, [string]$Label)
  $relative = { param($base) @(Get-ChildItem $base -Recurse -File | ForEach-Object { $_.FullName.Substring($base.Length).TrimStart('\') }) }
  $all = @(@(& $relative $Left) + @(& $relative $Right) | Sort-Object -Unique)
  $files = 0; $bytes = [long]0; $differentFiles = 0; $differentBytes = [long]0; $notes = @()
  foreach ($name in $all) {
    $x = Join-Path $Left $name; $y = Join-Path $Right $name
    if (-not (Test-Path $x) -or -not (Test-Path $y)) { $differentFiles++; $notes += "$name manca da una parte"; continue }
    $files++
    $bytes += (Get-Item $x).Length
    $count = [long]0
    $ranges = [SaveFileCompare]::Compare($x, $y, [ref]$count)
    if ($count -eq 0) { continue }
    $differentFiles++
    if ($count -lt 0) { $notes += "${name}: $ranges" } else { $differentBytes += $count; $notes += "${name}: $count byte diversi agli offset $ranges" }
  }
  if ($ReportFile -ne '') {
    Add-Content -Path $ReportFile -Value ("== {0}: {1} file, {2} byte" -f $Label, $files, $bytes)
    if ($notes.Count -eq 0) { Add-Content -Path $ReportFile -Value 'uguali byte per byte' } else { Add-Content -Path $ReportFile -Value $notes }
  }
  if ($differentFiles -eq 0) { return ("uguali ({0} file, {1} byte)" -f $files, $bytes) }
  ("DIVERSI: {0} byte in {1} file su {2}" -f $differentBytes, $differentFiles, $files)
}
