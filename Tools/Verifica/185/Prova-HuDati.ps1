<#
  Issue #185 (ondata 12b, voce A4): prova che le tabelle di dati di hu_stuff (nomi delle mappe, macro della chat, tasti
  dei giocatori di Strife), passate da assegnazioni nella sezione initialization a variabili inizializzate nelle
  dichiarazioni, hanno gli stessi elementi nello stesso ordine. Non avvia nulla: legge il testo del vecchio
  hu_stuff.pas (git show <Revisione>:IdTech1/Base/hu_stuff.pas) e quello nuovo, ricava per ogni tabella la lista dei
  valori e le confronta; `mapnames[36]` del vecchio testo (riempimento dei nove livelli senza nome di Doom) vale
  'NEWLEVEL', come nel nuovo.
  Uso: Prova-HuDati.ps1 [-Revisione ed08fe876]
#>
param([string]$Revisione = 'ed08fe876')
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$old = (git -C $root show "${Revisione}:IdTech1/Base/hu_stuff.pas") -join "`n"
$new = [IO.File]::ReadAllText((Join-Path $root 'IdTech1\Base\hu_stuff.pas')) -replace "`r", ''

# vecchio: serie di assegnazioni NOME[i] := valore; con indici consecutivi da 0
$runs = New-Object System.Collections.Generic.List[object]
$cur = $null
$inInit = $false
foreach ($line in ($old -split "`n")) {
  if ($line -eq 'initialization') { $inInit = $true; continue }
  if (-not $inInit) { continue }
  if ($line -match '^\s*(\w+)\[(\d+)\]\s*:=\s*(.+);\s*$') {
    $name = $Matches[1]; $ix = [int]$Matches[2]
    $value = $Matches[3] -replace '^mapnames\[36\]$', "'NEWLEVEL'"
    if ($cur -and $cur.Name -eq $name -and $ix -eq $cur.Items.Count) { $cur.Items.Add($value) }
    else { $cur = @{ Name = $name; Items = (New-Object System.Collections.Generic.List[string]) }; $cur.Items.Add($value); $runs.Add($cur) }
  }
}
$tables = @('mapnames', 'mapnames2', 'mapnamesp', 'mapnamest', 'chat_macros', 'key_multi_msgplayer')
$oldRuns = @($runs | Where-Object { $tables -contains $_.Name })

# nuovo: NOME: array[...] of string = ( ... );
$newRuns = New-Object System.Collections.Generic.List[object]
foreach ($m in [regex]::Matches($new, '(?ms)^  (\w+): array\[[^\]]*\] of string = \((.*?)\);')) {
  $items = @($m.Groups[2].Value -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
  $newRuns.Add(@{ Name = $m.Groups[1].Value; Items = $items })
}

$bad = 0
if ($oldRuns.Count -ne $newRuns.Count) { Write-Output ('NUMERO DI TABELLE DIVERSO: vecchio {0}, nuovo {1}' -f $oldRuns.Count, $newRuns.Count); $bad++ }
# le tabelle con lo stesso nome (mapnames: Heretic, Strife, Doom) hanno lo stesso ordine nei due testi
$seen = @{}
foreach ($o in $oldRuns) {
  $occurrence = if ($seen.ContainsKey($o.Name)) { $seen[$o.Name] + 1 } else { 0 }
  $seen[$o.Name] = $occurrence
  $n = @($newRuns | Where-Object { $_.Name -eq $o.Name })[$occurrence]
  if (-not $n) { Write-Output ('{0}: manca nel nuovo' -f $o.Name); $bad++; continue }
  $same = ($o.Name -eq $n.Name) -and ($o.Items.Count -eq $n.Items.Count)
  if ($same) { for ($k = 0; $k -lt $o.Items.Count; $k++) { if ($o.Items[$k] -ne $n.Items[$k]) { $same = $false; Write-Output ('  {0}[{1}]: vecchio {2}, nuovo {3}' -f $o.Name, $k, $o.Items[$k], $n.Items[$k]); break } } }
  Write-Output ('{0,-20} {1,3} voci  {2}' -f $o.Name, $o.Items.Count, $(if ($same) { 'UGUALE' } else { 'DIVERSA' }))
  if (-not $same) { $bad++ }
}
Write-Output ('Tabelle controllate {0}, diverse {1}' -f $oldRuns.Count, $bad)
exit $(if ($bad -eq 0) { 0 } else { 1 })
