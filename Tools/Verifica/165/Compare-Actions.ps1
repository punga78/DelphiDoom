<#
  Compares the text of the C harness (OUT.TXT) with the one of the port (PORT.TXT, written by the test
  ScriviIlRisultatoDelPorting) scenario by scenario and shows the first different line of the first scenarios that
  differ for each function. Usage: Compare-Actions.ps1 -C <OUT.TXT> -Port <PORT.TXT> [-PerFunction 2]
#>
param([string]$C, [string]$Port, [int]$PerFunction = 2)
$a = [IO.File]::ReadAllText($C, [Text.Encoding]::ASCII).Replace("`r`n", "`n")
$b = [IO.File]::ReadAllText($Port, [Text.Encoding]::ASCII).Replace("`r`n", "`n")
$sa = [regex]::Split($a, "(?m)^(?=S )") | Where-Object { $_ -ne '' }
$sb = [regex]::Split($b, "(?m)^(?=S )") | Where-Object { $_ -ne '' }
"scenarios: C $($sa.Count), port $($sb.Count)"
$shown = @{}
$different = 0
for ($i = 0; $i -lt [Math]::Min($sa.Count, $sb.Count); $i++) {
  if ($sa[$i] -ne $sb[$i]) {
    $different++
    $head = ($sa[$i] -split "`n")[0]
    if (-not $shown.ContainsKey($head)) { $shown[$head] = 0 }
    if ($shown[$head] -lt $PerFunction) {
      $shown[$head]++
      $la = $sa[$i] -split "`n"; $lb = $sb[$i] -split "`n"
      "---- #$i $head"
      $max = [Math]::Max($la.Count, $lb.Count)
      $count = 0
      for ($k = 0; $k -lt $max; $k++) {
        $x = if ($k -lt $la.Count) { $la[$k] } else { '<none>' }
        $y = if ($k -lt $lb.Count) { $lb[$k] } else { '<none>' }
        if ($x -ne $y -and $count -lt 3) { "  C   : $x"; "  port: $y"; $count++ }
      }
    }
  }
}
"different: $different"
