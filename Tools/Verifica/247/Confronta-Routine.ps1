<#
  Issue #247: prova del costo zero di una routine calda passata da procedura a metodo statico (o altra forma) con lo
  stesso testo. Per ogni coppia "nome vecchio=nome nuovo" disassembla le due routine (Disassembla-Routine.ps1: cdb e
  .map, indirizzi mascherati), toglie il riempimento (int 3, nop) e dice se la lista di istruzioni e' UGUALE
  (stesso numero e stesse istruzioni: stesso costo per pixel, colonna e span) oppure la prima differenza e i numeri.

  Uso:
    powershell -NoProfile -File Tools\Verifica\247\Confronta-Routine.ps1 -OldExe a\Doom32.exe -OldMap a\Doom32.map
      -NewExe b\Doom32.exe -NewMap b\Doom32.map -Pairs 'r_column.R_DrawColumnLow=Unit.Classe.Metodo','...' [-Win64]
  Esce con il numero di coppie diverse.
#>
param(
  [Parameter(Mandatory = $true)][string]$OldExe,
  [Parameter(Mandatory = $true)][string]$OldMap,
  [Parameter(Mandatory = $true)][string]$NewExe,
  [Parameter(Mandatory = $true)][string]$NewMap,
  [Parameter(Mandatory = $true)][string[]]$Pairs,
  [switch]$Win64,
  [string]$Label = ''
)
$tool = Join-Path $PSScriptRoot 'Disassembla-Routine.ps1'
$tmp = Join-Path $env:TEMP ('confrontarout_' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force $tmp | Out-Null
function Get-Instructions([string]$Exe, [string]$Map, [string]$Name, [string]$File) {
  $args2 = @('-NoProfile', '-File', $tool, '-Exe', $Exe, '-Map', $Map, '-Routine', $Name, '-Out', $File, '-Quiet')
  if ($Win64) { $args2 += '-Win64' }
  $null = & powershell @args2
  $list = New-Object System.Collections.Generic.List[string]
  foreach ($l in [IO.File]::ReadAllLines($File)) { $list.Add($l) }
  while ($list.Count -gt 0 -and $list[0] -match '^(int 3|nop)$') { $list.RemoveAt(0) }
  while ($list.Count -gt 0 -and $list[$list.Count - 1] -match '^(int 3|nop|add byte ptr \[eax\],al|add byte ptr \[rax\],al)') { $list.RemoveAt($list.Count - 1) }
  , $list
}
$different = 0
foreach ($pair in @($Pairs | ForEach-Object { $_ -split ';' } | Where-Object { $_ -ne '' })) {
  $names = $pair -split '=', 2
  # una routine che esiste solo in alcuni giochi manca dal .map degli altri: se manca in tutti e due non si confronta
  $inOld = Select-String -Path $OldMap -SimpleMatch -Pattern (' ' + $names[0]) | Where-Object { $_.Line -match ('\s' + [regex]::Escape($names[0]) + '\s*$') } | Select-Object -First 1
  $inNew = Select-String -Path $NewMap -SimpleMatch -Pattern (' ' + $names[1]) | Where-Object { $_.Line -match ('\s' + [regex]::Escape($names[1]) + '\s*$') } | Select-Object -First 1
  if (-not $inOld -and -not $inNew) { continue }
  if ((-not $inOld) -or (-not $inNew)) { $different++; Write-Output ("{0}{1} : DIVERSO (presente solo in uno)" -f $Label, $names[0]); continue }
  $a = Get-Instructions $OldExe $OldMap $names[0] (Join-Path $tmp 'a.txt')
  $b = Get-Instructions $NewExe $NewMap $names[1] (Join-Path $tmp 'b.txt')
  $same = ($a.Count -eq $b.Count)
  $first = -1
  if ($same) { for ($i = 0; $i -lt $a.Count; $i++) { if ($a[$i] -cne $b[$i]) { $same = $false; $first = $i; break } } }
  if ($same) {
    Write-Output ("{0}{1} : UGUALE ({2} istruzioni)" -f $Label, $names[0], $a.Count)
  } else {
    $different++
    Write-Output ("{0}{1} : DIVERSO ({2} istruzioni -> {3})" -f $Label, $names[0], $a.Count, $b.Count)
    if ($first -ge 0) { Write-Output ("      riga {0}: '{1}' -> '{2}'" -f $first, $a[$first], $b[$first]) }
  }
}
Remove-Item -Recurse -Force $tmp
exit $different
