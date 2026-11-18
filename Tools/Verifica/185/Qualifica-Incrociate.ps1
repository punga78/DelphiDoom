<#
  Issue #185 (ondata 11b, voci A31/A32): dopo due passate di Converti-Regole.ps1 sulla stessa unit (la classe delle routine
  dell'interfaccia e la classe -ImplOnly delle routine solo-implementazione) i corpi di una classe chiamano ancora per nome
  semplice le routine dell'altra: qui si qualificano. Le routine della STESSA classe restano come sono (un metodo statico chiama
  il suo vicino senza prefisso). Non tocca i testi tra apici ne' i commenti di riga.

  Uso: Qualifica-Incrociate.ps1 -Unit IdTech1\Doom\d_main.pas -Classes TMainRoutines,TMainLocalRoutines
#>
param(
  [Parameter(Mandatory = $true)][string]$Unit,
  [Parameter(Mandatory = $true)][string[]]$Classes,
  [string]$Root = ''
)
$ErrorActionPreference = 'Stop'
$Classes = @($Classes | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne '' })
if ($Root -eq '') { $Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path }
$path = Join-Path $Root $Unit
$bytes = [IO.File]::ReadAllBytes($path)
$bom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
$text = (New-Object Text.UTF8Encoding($false)).GetString($bytes, $(if ($bom) { 3 } else { 0 }), $bytes.Length - $(if ($bom) { 3 } else { 0 }))
$nl = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
$lines = $text -split "`r?`n", -1

# i nomi di ogni classe, dalla sua dichiarazione
$names = @{}
foreach ($c in $Classes) { $names[$c] = New-Object System.Collections.Generic.List[string] }
$current = ''
foreach ($l in $lines) {
  if ($l -match '^\s*(T\w+)\s*=\s*class sealed') { $current = $Matches[1]; continue }
  if ($current -ne '' -and $l -match '^\s*end;') { $current = ''; continue }
  if ($current -ne '' -and $names.ContainsKey($current) -and $l -match '^\s*class\s+(?:procedure|function)\s+(\w+)') {
    if (-not $names[$current].Contains($Matches[1])) { $names[$current].Add($Matches[1]) }
  }
}

function Convert-Line([string]$Line, [System.Text.RegularExpressions.Regex]$Regex, [string]$Prefix) {
  $parts = [regex]::Split($Line, "('(?:[^']|'')*')")
  $sb = New-Object Text.StringBuilder
  $inComment = $false
  foreach ($p in $parts) {
    if ($inComment -or $p.StartsWith("'")) { [void]$sb.Append($p); continue }
    $cut = $p.IndexOf('//')
    if ($cut -ge 0) {
      [void]$sb.Append($Regex.Replace($p.Substring(0, $cut), $Prefix + '$1'))
      [void]$sb.Append($p.Substring($cut))
      $inComment = $true
    }
    else { [void]$sb.Append($Regex.Replace($p, $Prefix + '$1')) }
  }
  $sb.ToString()
}

$regexes = @{}
foreach ($c in $Classes) {
  if ($names[$c].Count -gt 0) {
    $regexes[$c] = New-Object Text.RegularExpressions.Regex(('(?<![\w.])(' + (($names[$c] | Sort-Object -Unique) -join '|') + ')\b'))
  }
}

$inBody = ''
$changed = 0
for ($i = 0; $i -lt $lines.Count; $i++) {
  $l = $lines[$i]
  if ($inBody -eq '' -and $l -match '^class\s+(?:procedure|function)\s+(T\w+)\.(\w+)') {
    if ($names.ContainsKey($Matches[1])) { $inBody = $Matches[1] }
    # i parametri e il tipo del risultato dell'intestazione non contengono chiamate
    continue
  }
  if ($inBody -ne '') {
    if ($l -match '^end;\s*(//.*)?$') { $inBody = ''; continue }
    if ($l -match '^\s*(//|\{\$I\b)') { continue }
    $new = $l
    foreach ($c in $Classes) {
      if ($c -eq $inBody -or -not $regexes.ContainsKey($c)) { continue }
      $new = Convert-Line $new $regexes[$c] ($c + '.')
    }
    if ($new -ne $l) { $lines[$i] = $new; $changed++ }
  }
}
$out = $lines -join $nl
[IO.File]::WriteAllBytes($path, (New-Object Text.UTF8Encoding($bom)).GetPreamble() + (New-Object Text.UTF8Encoding($false)).GetBytes($out))
Write-Output ('{0}: {1} righe qualificate' -f (Split-Path $Unit -Leaf), $changed)
