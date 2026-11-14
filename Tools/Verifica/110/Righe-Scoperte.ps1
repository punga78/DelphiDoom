<#
  Issue #110: elenca le righe non coperte di un'unit della libreria Doom script dal rapporto di
  Tools\Copertura.ps1 (logs\copertura\DoomScript).

  Uso:
    powershell -NoProfile -File Tools\Verifica\110\Righe-Scoperte.ps1 Interpreter [Thread ...]
    powershell -NoProfile -File Tools\Verifica\110\Righe-Scoperte.ps1            (riepilogo per unit)
#>
param([string[]]$Unit = @())

$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$dir = Join-Path $root 'logs\copertura\DoomScript'
if ($Unit.Count -eq 0) {
  [xml]$x = Get-Content (Join-Path $dir 'CodeCoverage_Summary.xml')
  $x.SelectNodes('//srcfile') | Sort-Object name | ForEach-Object {
    '{0,-45} {1}' -f $_.name, $_.SelectSingleNode("coverage[@type='line, %']").value
  }
  exit 0
}
foreach ($u in ($Unit -split ',')) {
  $file = Get-ChildItem $dir -Filter "DelphiDoom.DoomScript.$u(*.html" | Select-Object -First 1
  if (-not $file) { "nessun rapporto per $u"; continue }
  "== $u"
  $html = Get-Content $file.FullName -Raw
  foreach ($m in [regex]::Matches($html, '<tr class="notcovered"><td>(\d+)<td>(?:<pre[^>]*>)?([^\r\n]*)')) {
    '{0,5}: {1}' -f $m.Groups[1].Value, [System.Net.WebUtility]::HtmlDecode($m.Groups[2].Value).TrimEnd()
  }
}
