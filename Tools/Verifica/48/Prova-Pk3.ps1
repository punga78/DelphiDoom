<#
  Prova della issue #48: i percorsi PK3 del motore (texture, voxel, suoni) con il PK3 di prova
  Tests\Data\Pk3\zpktest.pk3 e il PWAD zpkhires.wad, nei quattro giochi (e nelle build OpenGL).

  Per ogni gioco: attiva usepk3textures nel suo .ini (con copia e ripristino), cancella i WAD
  temporanei di una prova precedente, avvia il gioco con Tools\Esegui-gioco.ps1 (lock globale),
  poi controlla log, crash.txt e i WAD generati (con i nomi dei lump). Una seconda esecuzione
  controlla che la cache pk3tex_/pk3flat_ venga riusata e non riscritta.

  Uso (dalla radice del worktree o del repository, DOPO una build dei giochi):
    powershell -NoProfile -ExecutionPolicy Bypass -File Tools\Verifica\48\Prova-Pk3.ps1
      [-Games Doom,Heretic,Hexen,Strife] [-Gl] [-Seconds 25] [-SkipCache] [-BinDir <cartella bin>]

  Esce con il numero di controlli falliti. Scrive il riepilogo anche in logs\prova-pk3-48.txt.
#>
param(
  [string[]]$Games = @('Doom', 'Heretic', 'Hexen', 'Strife'),
  [switch]$Gl,
  [int]$Seconds = 25,
  [switch]$SkipCache,
  [string]$BinDir = ''
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
if ($BinDir -eq '') { $BinDir = Join-Path $root 'bin' }
$runner = Join-Path $root 'Tools\Esegui-gioco.ps1'
$pk3 = Join-Path $root 'Tests\Data\Pk3\zpktest.pk3'
$hires = Join-Path $root 'Tests\Data\Pk3\zpkhires.wad'
foreach ($f in $runner, $pk3, $hires) { if (-not (Test-Path -LiteralPath $f)) { throw "File mancante: $f" } }

$table = @{
  'Doom'    = @{ Exe = 'Doom32';    Gl = 'GLDoom32';    Wad = 'FREEDOOM2.WAD'; Warp = '-warp 1' }
  'Heretic' = @{ Exe = 'Heretic32'; Gl = 'GLHeretic32'; Wad = 'HERETIC1.WAD';  Warp = '-warp 1 1' }
  'Hexen'   = @{ Exe = 'Hexen32';   Gl = 'GLHexen32';   Wad = 'HEXEN.WAD';     Warp = '-warp 1' }
  'Strife'  = @{ Exe = 'Strife32';  Gl = 'GLStrife32';  Wad = 'STRIFE0.WAD';   Warp = '-warp 2' }
}

$results = New-Object System.Collections.ArrayList
$failures = 0
function Add-Result([string]$Run, [string]$Check, [bool]$Ok, [string]$Detail = '') {
  $script:results.Add([pscustomobject]@{ Run = $Run; Check = $Check; Ok = $Ok; Detail = $Detail }) | Out-Null
  if (-not $Ok) { $script:failures++ }
}

function Get-WadNames([string]$Path) {
  $b = [IO.File]::ReadAllBytes($Path)
  $count = [BitConverter]::ToInt32($b, 4)
  $dir = [BitConverter]::ToInt32($b, 8)
  $names = New-Object System.Collections.Generic.List[string]
  for ($i = 0; $i -lt $count; $i++) {
    $o = $dir + 16 * $i + 8
    $n = ''
    for ($k = 0; $k -lt 8 -and $b[$o + $k] -ne 0; $k++) { $n += [char]$b[$o + $k] }
    $names.Add($n.ToUpper())
  }
  return , $names
}

function Test-Lumps([string]$Run, [string]$Label, [string]$Pattern, [string]$Dir, [string[]]$Expected, [datetime]$Since, [bool]$MustBeNew) {
  $files = @(Get-ChildItem -Path $Dir -Filter $Pattern -ErrorAction SilentlyContinue)
  if ($files.Count -eq 0) { Add-Result $Run "$Label esiste" $false "nessun $Pattern in $Dir"; return }
  $file = $files | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if ($MustBeNew) { Add-Result $Run "$Label scritto in questa esecuzione" ($file.LastWriteTime -ge $Since) $file.Name }
  $names = Get-WadNames $file.FullName
  $missing = @($Expected | Where-Object { $names -notcontains $_ })
  Add-Result $Run "$Label contiene i lump attesi" ($missing.Count -eq 0) ("{0}: {1} lump; mancano: {2}" -f $file.Name, $names.Count, ($missing -join ' '))
}

function Invoke-One([string]$Game, [bool]$GlBuild) {
  $e = $table[$Game]
  $exeBase = $e.Exe; if ($GlBuild) { $exeBase = $e.Gl }
  $dir = Join-Path $BinDir $Game
  $exe = Join-Path $dir ($exeBase + '.exe')
  $label = $exeBase
  if (-not (Test-Path -LiteralPath $exe)) { Add-Result $label 'eseguibile presente' $false $exe; return }
  if (-not (Test-Path -LiteralPath (Join-Path $dir $e.Wad))) { Add-Result $label 'IWAD presente' $false (Join-Path $dir $e.Wad); return }

  # .ini: usepk3textures non si cambia dalla console (DFS_NEVER)
  $ini = Join-Path $dir ($exeBase + '.ini')
  $softIni = Join-Path $dir ($e.Exe + '.ini')
  if (-not (Test-Path -LiteralPath $ini)) {
    if (Test-Path -LiteralPath $softIni) { Copy-Item -LiteralPath $softIni -Destination $ini }
    else { Add-Result $label '.ini presente' $false "avviare una volta il gioco per crearlo: $ini"; return }
  }
  $backup = $ini + '.prova48'
  Copy-Item -LiteralPath $ini -Destination $backup -Force
  try {
    $text = [IO.File]::ReadAllText($ini)
    if ($text -match '(?m)^usepk3textures=') { $text = [regex]::Replace($text, '(?m)^usepk3textures=.*$', 'usepk3textures=1') }
    else { $text = $text.TrimEnd() + "`r`n`r`n[PK3]`r`nusepk3textures=1`r`n" }
    [IO.File]::WriteAllText($ini, $text)

    foreach ($pattern in 'DATA\WADS\pk3tex_*', 'DATA\WADS\pk3flat_*', 'DATA\TMP\voxelsprite_*', 'DATA\TMP\pk3sounds_*') {
      Get-ChildItem -Path (Join-Path $dir $pattern) -ErrorAction SilentlyContinue | Remove-Item -Force
    }

    $gameArgs = "-iwad $($e.Wad) -file `"$pk3`" `"$hires`" $($e.Warp) -devparm -nomusic -nosound"
    $passes = @('1')
    if (-not $SkipCache) { $passes += '2' }
    $firstTexTime = $null
    foreach ($pass in $passes) {
      $run = "$label#$pass"
      $start = Get-Date
      $line = & powershell -NoProfile -ExecutionPolicy Bypass -File $runner -Exe $exe -Arguments $gameArgs -WorkDir $dir -Seconds $Seconds
      Write-Output "  $run : $line"
      Add-Result $run 'il gioco resta vivo' ("$line" -match 'alive=True') "$line"
      Add-Result $run 'nessun crash.txt' ("$line" -match 'crash=False') "$line"

      $logs = Join-Path $dir 'DATA\LOGS'
      $stdout = Join-Path $logs ($exeBase + '_stdout.txt')
      $stderr = Join-Path $logs ($exeBase + '_stderr.txt')
      $out = ''; $err = ''
      if (Test-Path $stdout) { $out = [IO.File]::ReadAllText($stdout) }
      if (Test-Path $stderr) { $err = [IO.File]::ReadAllText($stderr) }
      $bad = @(($err + "`n" + $out) -split "`r?`n" | Where-Object { $_ -match 'I_Error|Access violation|EAccessViolation|Exception' })
      $badText = (@($bad | Select-Object -First 3)) -join ' | '
      Add-Result $run 'nessun I_Error o eccezione nei log' ($bad.Count -eq 0) $badText
      Add-Result $run 'il PK3 e'' stato aggiunto' ($out -match 'adding .*zpktest\.pk3') ''
      Add-Result $run 'W_InitPK3Sounds e'' girato' ($out -match 'W_InitPK3Sounds') ''
      $info = @(($err + "`n" + $out) -split "`r?`n" | Where-Object { $_ -match 'ZPK|ZVK|ZVD|ZVS|ZWS|PK3|sprite .* not found' } | Select-Object -First 12)
      if ($info.Count -gt 0) { Write-Output ('    log: ' + ($info -join "`n         ")) }

      if ($pass -eq '1') {
        # lump attesi: le sette immagini di textures\ del PK3 (quelle di zpkhires.wad sono lump veri
        # e W_CheckNumForName le esclude), PNAMES0/TEXTURE0, e gli stessi sette flat piu' flats\ZPKFLAT
        $tex = 'P_START', 'ZPKPNG', 'ZPKTGA', 'ZPKBMP', 'ZPKJPG', 'ZPKPCX', 'ZPKPAT', 'ZPKFLT', 'PNAMES0', 'TEXTURE0', 'P_END'
        $flat = 'F_START', 'ZPKPNG', 'ZPKTGA', 'ZPKBMP', 'ZPKJPG', 'ZPKPCX', 'ZPKPAT', 'ZPKFLT', 'ZPKFLAT', 'F_END'
        Test-Lumps $run 'WAD delle texture (pk3tex_)' 'pk3tex_*.wad' (Join-Path $dir 'DATA\WADS') $tex $start $true
        Test-Lumps $run 'WAD dei flat (pk3flat_)' 'pk3flat_*.wad' (Join-Path $dir 'DATA\WADS') $flat $start $true
        Test-Lumps $run 'WAD dei voxel (voxelsprite_)' 'voxelsprite_*.wad' (Join-Path $dir 'DATA\TMP') @('SS_START', 'ZVKAA0', 'ZVDAA0', 'ZVSAA0', 'SS_END') $start $true
        Test-Lumps $run 'WAD dei suoni (pk3sounds_)' 'pk3sounds_*.wad' (Join-Path $dir 'DATA\TMP') @('DSZPKWAV', 'DSZPKOGG', 'DSZPKFLC') $start $true
        $t = Get-ChildItem -Path (Join-Path $dir 'DATA\WADS\pk3tex_*.wad') -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($t) { $firstTexTime = $t.LastWriteTime }
        Add-Result $run 'le texture sono state create (non lette dalla cache)' ($out -match 'Create textures and flats from PK3') ''
      } else {
        $t = Get-ChildItem -Path (Join-Path $dir 'DATA\WADS\pk3tex_*.wad') -ErrorAction SilentlyContinue | Select-Object -First 1
        Add-Result $run 'la cache pk3tex_ non e'' stata riscritta' ($t -and $firstTexTime -and $t.LastWriteTime -eq $firstTexTime) ''
        Add-Result $run 'le texture non sono state ricreate' (-not ($out -match 'Create textures and flats from PK3')) ''
      }
    }
  }
  finally {
    Move-Item -LiteralPath $backup -Destination $ini -Force
  }
}

foreach ($g in $Games) {
  Write-Output "== $g"
  Invoke-One $g $false
  if ($Gl) { Invoke-One $g $true }
}

$report = New-Object System.Collections.ArrayList
foreach ($r in $results) {
  $mark = 'OK  '; if (-not $r.Ok) { $mark = 'FAIL' }
  $report.Add(("{0} {1,-16} {2}  {3}" -f $mark, $r.Run, $r.Check, $r.Detail)) | Out-Null
}
$report.Add("Controlli falliti: $failures su $($results.Count)") | Out-Null
$null = New-Item -ItemType Directory -Force -Path (Join-Path $root 'logs')
[IO.File]::WriteAllLines((Join-Path $root 'logs\prova-pk3-48.txt'), [string[]]$report)
$report | ForEach-Object { Write-Output $_ }
exit $failures
