<#
  Issue #247: disassembla una routine di un eseguibile Delphi (Win32 o Win64) con cdb dei Debugging Tools di Windows, per
  la prova del costo del codice caldo (istruzioni per ciclo). L'indirizzo viene dal file .map (Publics by Value: la
  routine va dal suo indirizzo al successivo). Gli indirizzi assoluti (spostati dall'ASLR e dalla riallocazione) e le
  costanti grandi sono mascherati con ADDR: due versioni dello stesso codice danno la stessa lista anche se i dati
  stanno in altri posti.

  Uso:
    powershell -NoProfile -File Tools\Verifica\247\Disassembla-Routine.ps1 -Exe bin\Win32\Release\Doom\Doom32.exe
      -Map bin\Win32\Release\Doom\Doom32.map -Routine r_column.R_DrawColumnLowest [-Out file.txt] [-Win64]
  Scrive le istruzioni (una per riga, normalizzate) e il loro numero; con -Out le salva nel file.
#>
param(
  [Parameter(Mandatory = $true)][string]$Exe,
  [Parameter(Mandatory = $true)][string]$Map,
  [Parameter(Mandatory = $true)][string]$Routine,
  [string]$Out = '',
  [switch]$Win64,
  [switch]$Quiet
)
$ErrorActionPreference = 'Stop'
$Exe = (Resolve-Path $Exe).Path
$cdb = if ($Win64) { 'C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe' } else { 'C:\Program Files (x86)\Windows Kits\10\Debuggers\x86\cdb.exe' }
$starts = New-Object System.Collections.Generic.List[object]
$section = ''
foreach ($line in [IO.File]::ReadLines($Map)) {
  if ($line -match 'Publics by Value') { $section = 'value'; continue }
  if ($section -eq 'value' -and $line -match '^\s*0001:([0-9A-F]{8})\s+(\S+)') { $starts.Add(@([Convert]::ToInt64($Matches[1], 16), $Matches[2])) }
}
$index = -1
for ($i = 0; $i -lt $starts.Count; $i++) { if ($starts[$i][1] -eq $Routine) { $index = $i; break } }
if ($index -lt 0) { throw "Routine $Routine non trovata in $Map" }
$begin = $starts[$index][0]
$end = $starts[$index + 1][0]
$module = [IO.Path]::GetFileNameWithoutExtension($Exe)
$from = '{0}+0x{1:X}' -f $module, (0x1000 + $begin)
$to = '{0}+0x{1:X}' -f $module, (0x1000 + $end)
$raw = & $cdb -c "u $from $to; q" $Exe 2>&1
$list = New-Object System.Collections.Generic.List[string]
foreach ($row in $raw) {
  # 00ba87d0 8b0d1c4e0f01    mov     ecx,dword ptr [Doom32+0x...]  oppure con indirizzi assoluti
  if ($row -match '^[0-9a-f`]{8,17}\s+(?:[0-9a-f]{2,32})\s{2,}(\S.*)$') {
    $text = $Matches[1]
    $text = [regex]::Replace($text, '[A-Za-z0-9_]+![A-Za-z0-9_.+]+( \([0-9a-f`]+\))?', 'ADDR')   # simbolo+offset (indirizzo)
    # una costante che coincide con la base del modulo viene scritta come "offset Modulo (indirizzo)": come le altre
    # costanti di 5 o piu' cifre esadecimali e' mascherata (due compilazioni con lo stesso testo la danno uguale)
    $text = [regex]::Replace($text, 'offset [A-Za-z0-9_.]+( \([0-9a-f`]+\))?', 'ADDR')
    $text = [regex]::Replace($text, '\b[0-9A-F]{5,8}h\b', 'ADDR')
    $text = [regex]::Replace($text, '\b[0-9a-f]{6,16}\b', 'ADDR')       # indirizzi assoluti o relativi
    $text = [regex]::Replace($text, '\[[A-Za-z0-9_]+(\+0x[0-9a-f]+)?\]', '[ADDR]')   # [modulo+offset]
    $list.Add(($text -replace '\s+', ' ').Trim())
  }
}
if (-not $Quiet) { $list }
Write-Output ("# {0}: {1} istruzioni, {2} byte" -f $Routine, $list.Count, ($end - $begin))
if ($Out -ne '') { [IO.File]::WriteAllLines($Out, $list) }
