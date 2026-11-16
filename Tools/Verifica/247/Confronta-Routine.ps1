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
# Confronta le due liste. Dopo un `jmp dword ptr [tabella + reg*4]` (switch) il compilatore mette la tabella dei salti: sono
# indirizzi assoluti, che il disassemblatore legge come istruzioni (e che cambiano con la posizione del codice, anche a
# parita' di codice). Una differenza che cade entro 8 righe da un tale `jmp` e che poi si riallinea (16 righe uguali, scarto
# di lunghezza fino a 8) e' una tabella dei salti: si salta e si conta in Gaps. Ogni altra differenza resta tale.
function Compare-Instructions($A, $B) {
  $i = 0
  $j = 0
  $gaps = 0
  while ($i -lt $A.Count -and $j -lt $B.Count) {
    if ($A[$i] -ceq $B[$j]) { $i++; $j++; continue }
    $nearTable = $false
    for ($k = [Math]::Max(0, $i - 8); $k -le $i; $k++) { if ($A[$k] -match '^jmp dword ptr ADDR\[') { $nearTable = $true; break } }
    for ($k = [Math]::Max(0, $j - 8); $k -le $j -and -not $nearTable; $k++) { if ($B[$k] -match '^jmp dword ptr ADDR\[') { $nearTable = $true; break } }
    if (-not $nearTable) { return @{ Same = $false; First = $i; Gaps = $gaps } }
    $resync = $false
    for ($k = 1; $k -le 120 -and -not $resync; $k++) {
      for ($d = -8; $d -le 8 -and -not $resync; $d++) {
        $ii = $i + $k
        $jj = $j + $k + $d
        if ($jj -lt 0 -or $ii + 16 -gt $A.Count -or $jj + 16 -gt $B.Count) { continue }
        $ok = $true
        for ($m = 0; $m -lt 16; $m++) { if ($A[$ii + $m] -cne $B[$jj + $m]) { $ok = $false; break } }
        if ($ok) { $i = $ii; $j = $jj; $resync = $true }
      }
    }
    if (-not $resync) { return @{ Same = $false; First = $i; Gaps = $gaps } }
    $gaps++
  }
  # un riempimento finale (tabella in coda) di al piu' 3 righe di scarto
  $rest = [Math]::Max($A.Count - $i, $B.Count - $j)
  if ($rest -gt 0) { return @{ Same = $false; First = $i; Gaps = $gaps } }
  @{ Same = $true; First = -1; Gaps = $gaps }
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
  $cmp = Compare-Instructions $a $b
  $same = $cmp.Same
  $first = $cmp.First
  if ($same) {
    $gapNote = ''
    if ($cmp.Gaps -gt 0) { $gapNote = ", {0} tabella/e dei salti esclusa/e" -f $cmp.Gaps }
    Write-Output ("{0}{1} : UGUALE ({2} istruzioni{3})" -f $Label, $names[0], $a.Count, $gapNote)
  } else {
    $different++
    Write-Output ("{0}{1} : DIVERSO ({2} istruzioni -> {3})" -f $Label, $names[0], $a.Count, $b.Count)
    if ($first -ge 0) { Write-Output ("      riga {0}: '{1}' -> '{2}'" -f $first, $a[$first], $b[$first]) }
  }
}
Remove-Item -Recurse -Force $tmp
exit $different
