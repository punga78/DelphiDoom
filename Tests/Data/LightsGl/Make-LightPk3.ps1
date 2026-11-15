<#
  Genera i PK3 di prova delle luci dinamiche (GLDEFS) nel renderer OpenGL (issue #249, prerequisito).

  Dati sintetici scritti qui (dominio pubblico / CC0): nessun asset di un gioco.
  Uso:
    powershell -NoProfile -ExecutionPolicy Bypass -File Tests\Data\LightsGl\Make-LightPk3.ps1

  Scrive, accanto allo script, un PK3 per gioco (zlgt_d.pk3 Doom, zlgt_h Heretic, zlgt_x Hexen, zlgt_s Strife;
  il nome non supera 8 caratteri: lo vuole ExtractFileBase di -file) con il solo lump GLDEFS:
    - sei luci: due puntiformi (una con scostamento), due a sfarfallio (flickerlight), due a pulsazione (pulselight);
    - per ogni tipo di oggetto del gioco (mobjinfo di <Gioco>\info.pas, indicato col suo numero: il parser accetta
      "object <numero>") una riga "frame <SPRITE>" per ogni sprite dei suoi stati (partenza, visione, dolore, mischia,
      missile, morte, ...), con una delle sei luci a turno; un oggetto ogni quattro e' lasciato senza luce, cosi' il
      motore gli mette l'ombra (gl_drawshadows).
  Non si usa "object -1": il disegno OpenGL legge solo le luci legate al tipo dell'oggetto (il software accetta anche -1).
  Cosi' oggetti, mostri e proiettili visibili nei primi tic di un livello hanno una luce dinamica, e il flusso del
  registratore (Tools\Verifica\opengl) contiene gld_DrawDLights: glBegin(GL_TRIANGLE_FAN) con 18 vertici.
  Le luci si disegnano solo con uselightboost=1 (0 nel .ini dei giochi): lo accende Confronta.ps1 -Lights con una copia
  del .ini data con -config. L'uscita e' deterministica.
#>
param(
  [string]$OutDir = $PSScriptRoot
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path

# the names of the states in the order of the table (S_NULL first), from the enum of <Game>\info_h.pas
function Get-StateNames([string]$Game) {
  $lines = [System.IO.File]::ReadAllLines((Join-Path $root "$Game\info_h.pas"))
  $names = New-Object 'System.Collections.Generic.List[string]'
  $inside = $false
  foreach ($line in $lines) {
    $text = ($line -replace '//.*$', '') -replace '\{[^}]*\}', ''
    if (-not $inside) {
      if ($text -match '^\s*S_NULL\b') { $inside = $true } else { continue }
    }
    if ($text -match 'NUMSTATES') { break }
    foreach ($m in [regex]::Matches($text, '\bS_[A-Z0-9_]+\b')) { $names.Add($m.Value) }
  }
  return , $names.ToArray()
}

# the sprite of every state, in the order of the table, and the states of every object of <Game>\info.pas
function Get-GameTables([string]$Game) {
  $text = [System.IO.File]::ReadAllText((Join-Path $root "$Game\info.pas"))
  $sprites = New-Object 'System.Collections.Generic.List[string]'
  foreach ($m in [regex]::Matches($text, 'sprite:\s*Ord\(SPR_([A-Z0-9]{4})\)')) { $sprites.Add($m.Groups[1].Value) }
  $objects = New-Object 'System.Collections.Generic.List[object]'
  $blocks = [regex]::Split($text, '(?m)^\s*name:\s*''')
  for ($i = 1; $i -lt $blocks.Count; $i++) {
    $states = New-Object 'System.Collections.Generic.List[string]'
    # every "<name>state: Ord(S_xxx)" of the object (spawn, see, pain, melee, missile, death, xdeath, raise, crash...)
    foreach ($m in [regex]::Matches($blocks[$i], '(?m)^\s*[a-z]+state:\s*Ord\((S_[A-Z0-9_]+)\)')) {
      $states.Add($m.Groups[1].Value)
    }
    $objects.Add([string[]]$states.ToArray())
  }
  return @{ Sprites = $sprites.ToArray(); Objects = $objects.ToArray() }
}

$lightDefinitions = @(
  'pointlight ZLGT_P1', '{', '  color 1.0 0.7 0.3', '  size 48', '}',
  'pointlight ZLGT_P2', '{', '  color 0.3 0.6 1.0', '  size 32', '  offset 0 0 16', '}',
  'flickerlight ZLGT_F1', '{', '  color 1.0 0.4 0.1', '  color2 0.5 0.2 0.05', '  size 40', '  size2 56', '  interval 0.5', '  chance 0.3', '}',
  'flickerlight ZLGT_F2', '{', '  color 0.3 1.0 0.3', '  size 36', '  size2 44', '  interval 0.25', '  chance 0.5', '}',
  'pulselight ZLGT_U1', '{', '  color 1.0 0.1 0.1', '  color2 0.2 0.0 0.0', '  size 24', '  size2 64', '  interval 2', '}',
  'pulselight ZLGT_U2', '{', '  color 0.8 0.8 0.2', '  color2 0.2 0.2 0.8', '  size 30', '  size2 50', '  interval 1', '  colorinterval 2', '}'
)
$lightNames = @('ZLGT_P1', 'ZLGT_F1', 'ZLGT_U1', 'ZLGT_P2', 'ZLGT_F2', 'ZLGT_U2')

foreach ($variant in @(@('Doom', 'd'), @('Heretic', 'h'), @('Hexen', 'x'), @('Strife', 's'))) {
  $game = $variant[0]; $letter = $variant[1]
  $stateNames = Get-StateNames $game
  $tables = Get-GameTables $game
  if ($tables.Sprites.Count -ne $stateNames.Count) {
    throw "$game : $($tables.Sprites.Count) sprite di stati contro $($stateNames.Count) nomi di stati"
  }
  $stateIndex = @{}
  for ($i = 0; $i -lt $stateNames.Count; $i++) { $stateIndex[$stateNames[$i]] = $i }

  $text = New-Object System.Text.StringBuilder
  [void]$text.AppendLine("// GLDEFS di prova ($game): una luce per sprite di ogni oggetto, a turno; un oggetto ogni quattro senza luce")
  foreach ($line in $lightDefinitions) { [void]$text.AppendLine($line) }
  $lit = 0
  $litObjects = 0
  for ($o = 0; $o -lt $tables.Objects.Count; $o++) {
    if ($o % 4 -eq 3) { continue }
    $seen = New-Object 'System.Collections.Generic.List[string]'
    foreach ($stateName in $tables.Objects[$o]) {
      if ($stateIndex.ContainsKey($stateName)) {
        $sprite = $tables.Sprites[$stateIndex[$stateName]]
        if (-not $seen.Contains($sprite)) { $seen.Add($sprite) }
      }
    }
    if ($seen.Count -eq 0) { continue }
    [void]$text.AppendLine("object $o")
    [void]$text.AppendLine('{')
    foreach ($sprite in $seen) {
      [void]$text.AppendLine("  frame $sprite { light $($lightNames[$lit % $lightNames.Count]) }")
      $lit++
    }
    [void]$text.AppendLine('}')
    $litObjects++
  }

  $pk3 = Join-Path $OutDir ("zlgt_{0}.pk3" -f $letter)
  if (Test-Path -LiteralPath $pk3) { Remove-Item -LiteralPath $pk3 -Force }
  $zip = [System.IO.Compression.ZipFile]::Open($pk3, [System.IO.Compression.ZipArchiveMode]::Create)
  try {
    $entry = $zip.CreateEntry('GLDEFS', [System.IO.Compression.CompressionLevel]::Optimal)
    $entry.LastWriteTime = [DateTimeOffset]::new(2026, 11, 15, 0, 0, 0, [TimeSpan]::Zero)
    $stream = $entry.Open()
    try {
      $bytes = (New-Object System.Text.UTF8Encoding($false)).GetBytes($text.ToString())
      $stream.Write($bytes, 0, $bytes.Length)
    } finally { $stream.Dispose() }
  } finally { $zip.Dispose() }
  Write-Host ("{0}: {1} oggetti, {2} con luce, {3} luci legate, {4} byte" -f $pk3, $tables.Objects.Count, $litObjects, $lit, (Get-Item $pk3).Length)
}
