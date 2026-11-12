<#
  Issue #185, fase 0: funzioni comuni degli script di parita' (si caricano con . .\Parity-Common.ps1).

  - Get-ParityGames       i quattro giochi (cartella, eseguibile, file .swd, file .ini di partenza)
  - Get-ParityCorpus      il corpus di demo (Corpus.psd1)
  - Initialize-ParityRunDir  cartella di lavoro con WAD, .swd, due file di configurazione (8 e 32 bit) e gli eseguibili
  - Invoke-ParityGame     lancia un gioco con Tools\Esegui-gioco.ps1 (un solo gioco per volta nel computer)
  - Invoke-ParityEntry    una demo del corpus: riproduce con -timedemo e scrive i log di stato e di fotogramma
  - Get-ParityTool        ParityTool.exe (confronto e compressione dei log), compilato da Libs\Parity se manca

  I WAD non sono nel repository: si prendono da -DataRoot (predefinito: la cartella bin del repository
  principale, quella che ha i WAD).
#>
$ErrorActionPreference = 'Stop'

$script:ParityRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$script:ParityGames = [ordered]@{
  Doom   = @{ Folder = 'Doom';   Exe = 'Doom32.exe';   Swd = 'Doom32.swd';   Ini = 'Doom32.ini' }
  Heretic = @{ Folder = 'Heretic'; Exe = 'Heretic32.exe'; Swd = 'Heretic32.swd'; Ini = 'Heretic32.ini' }
  Hexen  = @{ Folder = 'Hexen';  Exe = 'Hexen32.exe';  Swd = 'Hexen32.swd';  Ini = 'Hexen32.ini' }
  Strife = @{ Folder = 'Strife'; Exe = 'Strife32.exe'; Swd = 'Strife32.swd'; Ini = 'Strife32.ini' }
}

function Get-ParityRoot { $script:ParityRoot }

# Una tabella gioco -> percorso: una hashtable, oppure (con powershell -File) una stringa 'Doom=C:\a.exe;Hexen=C:\b.exe'.
function ConvertTo-ParityMap {
  param($Value)
  if ($null -eq $Value) { return @{} }
  if ($Value -is [hashtable]) { return $Value }
  $map = @{}
  foreach ($pair in ([string]$Value -split ';')) {
    if ($pair -match '^\s*([^=]+)=(.+)$') { $map[$Matches[1].Trim()] = $Matches[2].Trim() }
  }
  $map
}

function Get-ParityGames { $script:ParityGames }

function Get-ParityDataRoot {
  param([string]$DataRoot = '')
  if ($DataRoot -ne '') { return (Resolve-Path $DataRoot).Path }
  # la cartella bin del repository principale (un worktree non ha i WAD, che non sono nel repository)
  $common = (& git -C $script:ParityRoot rev-parse --path-format=absolute --git-common-dir) 2>$null
  if ($common) {
    $main = Split-Path -Parent ($common -replace '/', '\')
    $bin = Join-Path $main 'bin'
    if (Test-Path (Join-Path $bin 'Doom\DOOM1.WAD')) { return $bin }
  }
  $bin = Join-Path $script:ParityRoot 'bin'
  if (Test-Path (Join-Path $bin 'Doom\DOOM1.WAD')) { return $bin }
  throw 'WAD non trovati: passare -DataRoot (la cartella bin che ha Doom\DOOM1.WAD, Heretic\HERETIC1.WAD...)'
}

function Get-ParityCorpus {
  param([string[]]$Game = @(), [string]$Name = '*')
  $all = Import-PowerShellDataFile (Join-Path $PSScriptRoot 'Corpus.psd1')
  # il nome di una demo nel motore e' un nome di lump (8 caratteri): le demo registrate hanno un nome corto fisso
  $index = 0
  foreach ($entry in $all.Entries) { $index++; $entry.Short = ('pd{0:d3}' -f $index) }
  $list = @($all.Entries | Where-Object { $_.Name -like $Name })
  if ($Game.Count -gt 0) { $list = @($list | Where-Object { $Game -contains $_.Game }) }
  $list
}

function Get-ParityTool {
  $tool = Join-Path $script:ParityRoot 'bin\Tools\ParityTool.exe'
  if (-not (Test-Path $tool)) {
    & (Join-Path $script:ParityRoot 'Tools\build.bat') ParityTool Release | Out-Null
  }
  if (-not (Test-Path $tool)) { throw "ParityTool.exe non trovato: Tools\build.bat ParityTool" }
  $tool
}

# Il contenuto di un file di configurazione: solo cio' che serve a un'esecuzione ripetibile. Ogni altra chiave
# ha il suo valore di partenza. detaillevel 2 = modo a 8 bit, 3 = modo a 32 bit; niente fili (usemultithread=0),
# niente interpolazione, finestra 640x480 (dimensione fissa, non dipende dal monitor).
function New-ParityConfigText {
  param([string]$Header, [int]$Mode)
  $detail = 2
  if ($Mode -eq 32) { $detail = 3 }
  @(
    $Header, '', '[Display]',
    'soft_screenwidth=640', 'soft_screenheight=480', 'soft_fullscreen=0', 'soft_windowxpos=0', 'soft_windowypos=0',
    'interpolate=0', 'interpolateoncapped=0', 'screenblocks=10', "detaillevel=$detail", 'displaydiskbusyicon=0',
    'drawfps=0', 'usemultithread=0', 'r_bltasync=0'
  ) -join "`r`n"
}

# Cartella di lavoro di un gioco: WAD e .swd dei dati, p8.ini e p32.ini, e gli eseguibili (nome di destinazione =
# nome di origine, altrimenti il nome dato nella tabella $Executables @{ 'nome.exe' = 'percorso\origine.exe' }).
function Initialize-ParityRunDir {
  param(
    [Parameter(Mandatory = $true)][string]$Game,
    [Parameter(Mandatory = $true)][string]$WorkRoot,
    [string]$DataRoot = '',
    [hashtable]$Executables = @{}
  )
  $info = $script:ParityGames[$Game]
  if ($null -eq $info) { throw "Gioco sconosciuto: $Game" }
  $data = Get-ParityDataRoot $DataRoot
  $dir = Join-Path $WorkRoot $Game
  New-Item -ItemType Directory -Force $dir | Out-Null
  $source = Join-Path $data $info.Folder
  foreach ($file in (Get-ChildItem $source -File | Where-Object { $_.Extension -in '.WAD', '.wad', '.swd' })) {
    $target = Join-Path $dir $file.Name
    if (-not (Test-Path $target) -or ((Get-Item $target).Length -ne $file.Length)) { Copy-Item $file.FullName $target -Force }
  }
  $header = (Get-Content (Join-Path $source $info.Ini) -TotalCount 1)
  foreach ($mode in 8, 32) {
    [IO.File]::WriteAllText((Join-Path $dir "p$mode.ini"), (New-ParityConfigText $header $mode) + "`r`n")
  }
  foreach ($name in $Executables.Keys) {
    Copy-Item $Executables[$name] (Join-Path $dir $name) -Force
  }
  $dir
}

# Lancia un gioco con il lock globale di Esegui-gioco.ps1; restituisce un oggetto con vivo, codice di uscita, secondi.
function Invoke-ParityGame {
  param(
    [Parameter(Mandatory = $true)][string]$Exe,
    [Parameter(Mandatory = $true)][string]$Arguments,
    [string]$WorkDir = '',
    [int]$TimeoutSeconds = 600
  )
  $runner = Join-Path $script:ParityRoot 'Tools\Esegui-gioco.ps1'
  # gli argomenti del gioco non hanno virgolette (i percorsi dei file sono nomi relativi alla cartella di lavoro)
  $call = @('-NoProfile', '-File', $runner, '-Exe', $Exe, '-Arguments', $Arguments, '-Seconds', "$TimeoutSeconds", '-StopWhenExited')
  if ($WorkDir -ne '') { $call += @('-WorkDir', $WorkDir) }
  $line = & powershell @call
  $text = ($line | Out-String).Trim()
  $alive = $text -match 'alive=True'
  $exit = ''
  if ($text -match 'exit=(\S*)') { $exit = $Matches[1] }
  $crash = $text -match 'crash=True'
  $seconds = 0
  if ($text -match 'secondi=(\d+)') { $seconds = [int]$Matches[1] }
  [pscustomobject]@{ Alive = $alive; ExitCode = $exit; Crash = $crash; Seconds = $seconds; Text = $text }
}

# Una voce del corpus in un modo (8 o 32): -timedemo con -statehash e -framehash. Il nome della demo e' quello
# di una demo del WAD (demo1) o di un file .lmp copiato nella cartella di lavoro (Tests\Data\Parity\<Gioco>\nome.lmp).
function Invoke-ParityEntry {
  param(
    [Parameter(Mandatory = $true)]$Entry,
    [Parameter(Mandatory = $true)][int]$Mode,
    [Parameter(Mandatory = $true)][string]$RunDir,
    [Parameter(Mandatory = $true)][string]$ExeName,
    [Parameter(Mandatory = $true)][string]$StateFile,
    [Parameter(Mandatory = $true)][string]$FrameFile,
    [string]$Extra = '',
    [int]$TimeoutSeconds = 300
  )
  $demo = $Entry.Demo
  if ($Entry.ContainsKey('Auto')) {
    $demo = $Entry.Short
    # la demo del shareware di Hexen rifiuta file esterni: -devparm lascia passare l'errore ("D_DoomMain(): You cannot
    # use external files with the shareware version"); non cambia lo stato del gioco
    if ($Entry.Game -eq 'Hexen') { $Extra = ($Extra + ' -devparm').Trim() }
    $lmp = Join-Path $script:ParityRoot ("Tests\Data\Parity\{0}\{1}.lmp" -f $Entry.Game, $Entry.Name)
    if (-not (Test-Path $lmp)) { throw "Demo non registrata: $lmp (Registra-Demo.ps1)" }
    Copy-Item $lmp (Join-Path $RunDir ($demo + '.lmp')) -Force
  }
  Remove-Item $StateFile, $FrameFile -ErrorAction SilentlyContinue
  # i file dei log stanno nella cartella di lavoro e si passano per nome
  $arguments = "-iwad $($Entry.Iwad) -config p$Mode.ini -dontsavedefaults -nomusic -nosound -noblit -timedemo $demo " +
    "-statehash $(Split-Path -Leaf $StateFile) -framehash $(Split-Path -Leaf $FrameFile) $Extra"
  Invoke-ParityGame -Exe (Join-Path $RunDir $ExeName) -Arguments $arguments -WorkDir $RunDir -TimeoutSeconds $TimeoutSeconds
}

# Che cosa ha visitato una demo (dal log dello stato): tic, celle di 128x128 unita' attraversate dal primo giocatore,
# salute minima, tic con il giocatore morto, mobj al massimo, tic in cui cambia l'impronta dei settori (porte, ascensori,
# luci), tic in cui cambiano le linee (interruttori, scorrimenti) e il numero di livelli (la durata del livello riparte da 1).
function Get-ParityStateStats {
  param([Parameter(Mandatory = $true)][string]$Tool, [Parameter(Mandatory = $true)][string]$File)
  $tmp = $File
  if ($File.EndsWith('.gz')) { $tmp = Join-Path $env:TEMP ('paritystats_' + [guid]::NewGuid().ToString('N') + '.txt'); & $Tool unpack $File $tmp }
  $cells = New-Object 'System.Collections.Generic.HashSet[string]'
  $tics = 0; $minHp = 100000; $dead = 0; $maxMo = 0; $sectorChanges = 0; $lineChanges = 0; $levels = 0
  $prevSector = ''; $prevLine = ''; $prevLt = 0
  foreach ($row in [IO.File]::ReadLines($tmp)) {
    if (-not $row.StartsWith('T ')) { continue }
    $tics++
    $f = $row.Split(' ')
    $sector = ''; $line = ''; $px = 0; $py = 0; $hp = 0; $mo = 0; $lt = 0
    foreach ($kv in $f) {
      if ($kv.StartsWith('sector=')) { $sector = $kv } elseif ($kv.StartsWith('line=')) { $line = $kv }
      elseif ($kv.StartsWith('px=')) { $px = [int]$kv.Substring(3) } elseif ($kv.StartsWith('py=')) { $py = [int]$kv.Substring(3) }
      elseif ($kv.StartsWith('hp=')) { $hp = [int]$kv.Substring(3) } elseif ($kv.StartsWith('mo=')) { $mo = [int]$kv.Substring(3) }
      elseif ($kv.StartsWith('lt=')) { $lt = [int]$kv.Substring(3) }
    }
    [void]$cells.Add(('{0},{1}' -f ($px -shr 7), ($py -shr 7)))
    if ($hp -lt $minHp) { $minHp = $hp }
    if ($hp -le 0) { $dead++ }
    if ($mo -gt $maxMo) { $maxMo = $mo }
    if ($prevSector -ne '' -and $sector -ne $prevSector) { $sectorChanges++ }
    if ($prevLine -ne '' -and $line -ne $prevLine) { $lineChanges++ }
    if ($lt -lt $prevLt -or $tics -eq 1) { $levels++ }
    $prevSector = $sector; $prevLine = $line; $prevLt = $lt
  }
  if ($tmp -ne $File) { Remove-Item $tmp -ErrorAction SilentlyContinue }
  [pscustomobject]@{ Tics = $tics; Cells = $cells.Count; MinHealth = $minHp; DeadTics = $dead; MaxMobjs = $maxMo; SectorChangeTics = $sectorChanges; LineChangeTics = $lineChanges; Levels = $levels }
}

# Confronto di due BMP a 32 bit (quelli di -framedump): numero di pixel diversi e rettangolo che li contiene.
if (-not ('ParityBitmapCompare' -as [type])) { Add-Type -TypeDefinition @'
using System;
using System.IO;
public static class ParityBitmapCompare {
  public static string Compare(string a, string b) {
    byte[] x = File.ReadAllBytes(a); byte[] y = File.ReadAllBytes(b);
    if (x.Length != y.Length) return "dimensioni diverse (" + x.Length + " e " + y.Length + " byte)";
    int width = BitConverter.ToInt32(x, 18);
    int count = 0, minX = int.MaxValue, minY = int.MaxValue, maxX = -1, maxY = -1, fx = -1, fy = -1;
    for (int i = 54; i + 3 < x.Length; i += 4) {
      if (x[i] != y[i] || x[i + 1] != y[i + 1] || x[i + 2] != y[i + 2]) {
        int p = (i - 54) / 4; int px = p % width; int py = p / width;
        if (count == 0) { fx = px; fy = py; }
        count++;
        if (px < minX) minX = px; if (py < minY) minY = py; if (px > maxX) maxX = px; if (py > maxY) maxY = py;
      }
    }
    if (count == 0) return "uguali";
    return count + " pixel diversi, il primo in (" + fx + "," + fy + "), contenuti in x " + minX + ".." + maxX + " y " + minY + ".." + maxY;
  }
}
'@ }

function Get-ParityLineCount {
  param([string]$Tool, [string]$File)
  [int](& $Tool count $File)
}
