<#
  Issue #185, fase 2 (protocollo del par. 10.7 di docs\PIANO_TUTTO_A_CLASSI.md): tabella di confronto delle copie di una
  unit nei giochi, routine per routine. Per ogni routine della sezione implementation dice in quali giochi esiste, quante
  righe ha e quali copie sono UGUALI tra loro (stesso testo tolti commenti, spazi e maiuscole): le copie con la stessa
  lettera sono uguali.

    uguale       stessa lettera in tutti i giochi che hanno la unit
    parametrica  copie diverse ma vicine (il numero di righe diverse dalla prima copia e' nella colonna Diff)
    propria      esiste in un solo gioco

  Uso:
    powershell -NoProfile -File Tools\Verifica\185\Confronta-Copie.ps1 -Unit p_map [-Games Doom,Heretic,Hexen,Strife] [-Csv file]
#>
param(
  [Parameter(Mandatory = $true)][string]$Unit,
  [string[]]$Games = @('Doom', 'Heretic', 'Hexen', 'Strife'),
  [string]$Csv = ''
)
$ErrorActionPreference = 'Stop'
$Games = @($Games | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne '' })
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))

# testo senza commenti, spazi e maiuscole: due routine sono "uguali" se questo coincide
function Get-NormalizedLines {
  param([string[]]$Lines)
  $inBrace = $false
  foreach ($line in $Lines) {
    $text = $line
    if ($inBrace) {
      $close = $text.IndexOf('}')
      if ($close -lt 0) { continue }
      $text = $text.Substring($close + 1)
      $inBrace = $false
    }
    # i commenti { } che non sono direttive
    while ($true) {
      $open = $text.IndexOf('{')
      if ($open -lt 0 -or ($open + 1 -lt $text.Length -and $text[$open + 1] -eq '$')) { break }
      $close = $text.IndexOf('}', $open)
      if ($close -lt 0) { $text = $text.Substring(0, $open); $inBrace = $true; break }
      $text = $text.Substring(0, $open) + $text.Substring($close + 1)
    }
    $slash = $text.IndexOf('//')
    if ($slash -ge 0) { $text = $text.Substring(0, $slash) }
    $text = ($text -replace '\s+', '').ToLowerInvariant()
    if ($text -ne '') { $text }
  }
}

# le routine di primo livello dopo "implementation": nome -> righe (dalla riga di intestazione al suo "end;" a colonna 0)
function Get-Routines {
  param([string]$Path)
  $lines = [IO.File]::ReadAllLines($Path)
  $routines = [ordered]@{}
  $start = 0
  for ($i = 0; $i -lt $lines.Length; $i++) {
    if ($lines[$i] -match '^implementation\b') { $start = $i + 1; break }
  }
  $name = ''
  $body = New-Object System.Collections.Generic.List[string]
  for ($i = $start; $i -lt $lines.Length; $i++) {
    $line = $lines[$i]
    if ($name -eq '') {
      if ($line -match '^(?:class\s+)?(?:procedure|function|constructor|destructor)\s+([A-Za-z_][A-Za-z_0-9\.]*)') {
        $name = $Matches[1]
        $body.Clear()
        $body.Add($line)
      }
    } else {
      $body.Add($line)
      if ($line -match '^end;') {
        $key = $name
        $n = 2
        while ($routines.Contains($key)) { $key = "$name#$n"; $n++ }
        $routines[$key] = $body.ToArray()
        $name = ''
      }
    }
  }
  $routines
}

$perGame = [ordered]@{}
foreach ($game in $Games) {
  $path = Join-Path $root "$game\$Unit.pas"
  if (Test-Path $path) { $perGame[$game] = Get-Routines $path }
}
if ($perGame.Count -eq 0) { throw "Nessuna copia di $Unit.pas in: $($Games -join ', ')" }

$names = New-Object System.Collections.Generic.List[string]
foreach ($game in $perGame.Keys) {
  foreach ($name in $perGame[$game].Keys) { if (-not $names.Contains($name)) { $names.Add($name) } }
}

$rows = foreach ($name in $names) {
  $letters = @{}
  $firstNorm = $null
  $row = [ordered]@{ Routine = $name }
  $classes = New-Object System.Collections.Generic.List[string]
  $diff = 0
  foreach ($game in $perGame.Keys) {
    if ($perGame[$game].Contains($name)) {
      $norm = @(Get-NormalizedLines $perGame[$game][$name])
      $key = $norm -join "`n"
      if (-not $letters.ContainsKey($key)) { $letters[$key] = [char](65 + $letters.Count) }
      $row[$game] = '{0}{1}' -f $letters[$key], $perGame[$game][$name].Length
      $classes.Add([string]$letters[$key])
      if ($null -eq $firstNorm) { $firstNorm = $norm }
      elseif ($letters[$key] -ne 'A') {
        $d = @(Compare-Object $firstNorm $norm).Count
        if ($d -gt $diff) { $diff = $d }
      }
    } else {
      $row[$game] = '-'
    }
  }
  $kind = 'parametrica'
  if ($classes.Count -eq 1 -and $perGame.Count -gt 1) { $kind = 'propria' }
  elseif ($letters.Count -eq 1) { $kind = 'uguale' }
  $row['Diff'] = $diff
  $row['Tipo'] = $kind
  [pscustomobject]$row
}

$rows | Format-Table -AutoSize | Out-String -Width 200 | Write-Output
$summary = $rows | Group-Object Tipo | ForEach-Object { '{0}: {1}' -f $_.Name, $_.Count }
Write-Output ("{0}: {1} routine ({2})" -f $Unit, @($rows).Count, ($summary -join ', '))
if ($Csv -ne '') { $rows | Export-Csv -NoTypeInformation -Encoding UTF8 $Csv }
