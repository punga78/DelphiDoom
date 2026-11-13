<#
  Issue #223: controlla che tra XcomStrategy, XcomGeoscape e XcomBasescape non ci siano cicli
  (clausole uses di interface e implementation, commenti e stringhe tolti) e stampa l'ordine
  totale. Uscita 0 se non ci sono cicli, 1 altrimenti.
  Uso: powershell -File Tools\Verifica\223\Controlla-Cicli.ps1 [-Dettaglio]
#>
param([switch]$Dettaglio)
$root = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
$libs = 'XcomBasescape', 'XcomGeoscape', 'XcomStrategy'
$units = @{}
foreach ($l in $libs) {
  Get-ChildItem (Join-Path $root "Libs\$l") -Filter *.pas | ForEach-Object { $units[$_.BaseName.ToLower()] = @{ Lib = $l; File = $_.FullName } }
}
$edges = @{}
foreach ($u in $units.Keys) {
  $t = [IO.File]::ReadAllText($units[$u].File)
  $t = [regex]::Replace($t, '\{[^}]*\}', '', 'Singleline')
  $t = [regex]::Replace($t, '\(\*.*?\*\)', '', 'Singleline')
  $t = [regex]::Replace($t, '//[^\r\n]*', '')
  $t = [regex]::Replace($t, "'[^'\r\n]*'", '')
  foreach ($m in [regex]::Matches($t, '(?is)\buses\b(.*?);')) {
    foreach ($n in ($m.Groups[1].Value -split '[,\s]+')) {
      $n = $n.Trim().ToLower()
      if ($units.ContainsKey($n) -and $units[$n].Lib -ne $units[$u].Lib) {
        $k = "$($units[$u].Lib) -> $($units[$n].Lib)"
        if (-not $edges.ContainsKey($k)) { $edges[$k] = New-Object Collections.Generic.List[string] }
        $edges[$k].Add("$u usa $n")
      }
    }
  }
}
foreach ($k in ($edges.Keys | Sort-Object)) {
  Write-Host ("{0}: {1} uses" -f $k, $edges[$k].Count)
  if ($Dettaglio) { $edges[$k] | Sort-Object -Unique | ForEach-Object { Write-Host "    $_" } }
}
# ordinamento topologico
$dep = @{}
foreach ($l in $libs) { $dep[$l] = @() }
foreach ($k in $edges.Keys) { $a, $b = $k -split ' -> '; $dep[$a] += $b }
$order = @()
$left = New-Object Collections.Generic.List[string]
$left.AddRange([string[]]$libs)
while ($left.Count -gt 0) {
  $pick = $left | Where-Object { -not ($dep[$_] | Where-Object { $left -contains $_ }) } | Select-Object -First 1
  if (-not $pick) { Write-Host "CICLO tra: $($left -join ', ')"; exit 1 }
  $order += $pick
  [void]$left.Remove($pick)
}
Write-Host "Ordine totale (dal piu' basso): $($order -join ' < ')"
exit 0
