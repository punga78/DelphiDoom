<#
  Issue #157: elenco di sola lettura dei progetti di Reference\ (cartella non tracciata).
  Per ogni cartella di primo livello: dimensione, file di licenza (nome, prima riga non vuota, byte),
  numero di file .pas/.c/.cpp e quanti hanno il testo "GNU General Public License" nelle prime 40 righe.
  Non scrive nulla in Reference\, non avvia nessun programma.
  Su tutta Reference\ (300 MB) impiega minuti.

  Uso:
    powershell -NoProfile -File Tools\Verifica\157\Elenca-Reference.ps1 [-Reference C:\Progetti\DelphiDoom\Reference]
#>
param(
  [string]$Reference = 'C:\Progetti\DelphiDoom\Reference'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Reference)) {
  throw "Cartella non trovata: $Reference"
}

$licenseNames = 'LICENSE', 'LICENSE.txt', 'LICENSE.md', 'COPYING', 'COPYING.txt'

foreach ($dir in Get-ChildItem -LiteralPath $Reference -Directory | Sort-Object Name) {
  $bytes = (Get-ChildItem -LiteralPath $dir.FullName -Recurse -File -ErrorAction SilentlyContinue |
    Measure-Object -Property Length -Sum).Sum
  Write-Output ('=== {0}  ({1:N1} MB)' -f $dir.Name, ($bytes / 1MB))

  $found = $false
  foreach ($name in $licenseNames) {
    $path = Join-Path $dir.FullName $name
    if (Test-Path -LiteralPath $path) {
      $found = $true
      $first = (Get-Content -LiteralPath $path -TotalCount 5 | Where-Object { $_.Trim() } | Select-Object -First 1)
      Write-Output ('  licenza: {0}  ({1} byte)  "{2}"' -f $name, (Get-Item -LiteralPath $path).Length, $first.Trim())
    }
  }
  if (-not $found) {
    Write-Output '  licenza: nessun file LICENSE/COPYING al primo livello'
  }

  $sources = @(Get-ChildItem -LiteralPath $dir.FullName -Recurse -File -Include *.pas, *.c, *.cpp -ErrorAction SilentlyContinue)
  $withGpl = 0
  foreach ($file in $sources) {
    $head = Get-Content -LiteralPath $file.FullName -TotalCount 40 -ErrorAction SilentlyContinue
    if ($head -match 'GNU General Public License') {
      $withGpl++
    }
  }
  Write-Output ('  sorgenti: {0}  con testo GPL nell''intestazione: {1}' -f $sources.Count, $withGpl)
}
