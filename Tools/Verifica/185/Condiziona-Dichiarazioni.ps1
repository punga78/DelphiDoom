<#
  Issue #185 (ondata 11b, voci A31/A32): Converti-Regole.ps1 mette nella classe la dichiarazione di ogni routine anche quando
  il corpo sta dentro un `{$IFDEF}` (per esempio D_ConfigureGlbsp, solo OpenGL): negli altri progetti la dichiarazione resta
  senza corpo (E2065). Qui ogni dichiarazione di metodo prende le stesse condizioni del suo corpo: se il corpo compare una
  volta sola, le condizioni in cui sta (pila di `{$IFDEF}`, `{$IFNDEF}` e `{$ELSE}`); se compare piu' volte (per esempio una
  per ramo) la dichiarazione resta senza condizione.

  Uso: Condiziona-Dichiarazioni.ps1 -Unit IdTech1\Doom\d_main.pas -Classes TMainRoutines,TMainLocalRoutines
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
$lines = [System.Collections.Generic.List[string]]($text -split "`r?`n", -1)

# 1) la pila delle condizioni nel punto di ogni intestazione di corpo
$stack = New-Object System.Collections.Generic.List[object]
$occ = @{}
for ($i = 0; $i -lt $lines.Count; $i++) {
  $l = $lines[$i]
  if ($l -match '^\{\$(IFDEF|IFNDEF)\s+(\w+)\s*\}') {
    $stack.Add(@{ Kind = $Matches[1]; Name = $Matches[2] })
    continue
  }
  if ($l -match '^\{\$IF\s') { $stack.Add(@{ Kind = 'IF'; Name = $l }); continue }
  if ($l -match '^\{\$ELSE\s*\}') {
    $top = $stack[$stack.Count - 1]
    if ($top.Kind -eq 'IFDEF') { $top.Kind = 'IFNDEF' } elseif ($top.Kind -eq 'IFNDEF') { $top.Kind = 'IFDEF' }
    continue
  }
  if ($l -match '^\{\$(ENDIF|IFEND)\s*\}') { $stack.RemoveAt($stack.Count - 1); continue }
  if ($l -match '^class\s+(?:procedure|function)\s+(T\w+)\.(\w+)') {
    $key = $Matches[1] + '.' + $Matches[2]
    $cond = @($stack | ForEach-Object { if ($_.Kind -eq 'IF') { 'RAW:' + $_.Name } else { $_.Kind + ' ' + $_.Name } })
    if (-not $occ.ContainsKey($key)) { $occ[$key] = New-Object System.Collections.Generic.List[object] }
    $occ[$key].Add($cond)
  }
}

# 2) le dichiarazioni nelle classi
$wrapped = 0
$current = ''
$i = 0
while ($i -lt $lines.Count) {
  $l = $lines[$i]
  if ($l -match '^\s*(T\w+)\s*=\s*class sealed') { $current = $Matches[1]; $i++; continue }
  if ($current -ne '' -and $l -match '^\s*end;') { $current = ''; $i++; continue }
  if ($current -ne '' -and $Classes -contains $current -and $l -match '^\s*class\s+(?:procedure|function)\s+(\w+)') {
    $name = $Matches[1]
    $start = $i
    while ($lines[$i] -notmatch 'static;\s*(//.*)?$') { $i++ }
    $end = $i
    # il commento di intestazione che precede la dichiarazione
    while ($start -gt 0 -and $lines[$start - 1] -match '^\s*//') { $start-- }
    $key = $current + '.' + $name
    if ($occ.ContainsKey($key) -and $occ[$key].Count -eq 1 -and $occ[$key][0].Count -gt 0) {
      $cond = $occ[$key][0]
      $open = @($cond | ForEach-Object {
        if ($_ -like 'RAW:*') { $_.Substring(4) }
        else { $p = $_ -split ' ', 2; '{$' + $p[0] + ' ' + $p[1] + '}' } })
      $close = @($cond | ForEach-Object { '{$ENDIF}' })
      $lines.InsertRange($end + 1, [string[]]$close)
      $lines.InsertRange($start, [string[]]$open)
      $i = $end + 1 + $open.Count + $close.Count
      $wrapped++
      continue
    }
    $i = $end + 1
    continue
  }
  $i++
}
[IO.File]::WriteAllBytes($path, (New-Object Text.UTF8Encoding($bom)).GetPreamble() + (New-Object Text.UTF8Encoding($false)).GetBytes(($lines -join $nl)))
Write-Output ('{0}: {1} dichiarazioni condizionate' -f (Split-Path $Unit -Leaf), $wrapped)
