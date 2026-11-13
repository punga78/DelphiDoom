# Issue #222: Libs\Sndfile e Libs\Sound non devono avere un ciclo di dipendenze.
# Elenca i riferimenti (uses di interface e di implementation, e qualsiasi altra
# comparsa del nome di unit) tra le due librerie, per direzione, ed esce con
# codice 1 se Sndfile cita una unit di Sound.
#   Tools\Verifica\222\Controlla-Cicli.ps1
param()

$radice = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
$sndfile = Get-ChildItem (Join-Path $radice 'Libs\Sndfile') -Filter '*.pas'
$sound = Get-ChildItem (Join-Path $radice 'Libs\Sound') -Filter '*.pas'

function Cerca($files, $prefisso) {
  $trovati = @()
  foreach ($f in $files) {
    $righe = Get-Content $f.FullName
    for ($i = 0; $i -lt $righe.Count; $i++) {
      $r = $righe[$i]
      if ($r -match '^\s*(//|\{)') { continue }
      if ($r -match $prefisso) {
        $trovati += ('{0}:{1}: {2}' -f $f.Name, ($i + 1), $r.Trim())
      }
    }
  }
  return $trovati
}

$versoSound = Cerca $sndfile 'DelphiDoom\.Sound\.'
$versoSndfile = Cerca $sound 'DelphiDoom\.Sndfile\.'

"Sound -> Sndfile (ammesso): {0} riferimenti" -f $versoSndfile.Count
$versoSndfile | Select-Object -First 5 | ForEach-Object { '  ' + $_ }
$unitSndfile = $versoSndfile | ForEach-Object { [regex]::Matches($_, 'DelphiDoom\.Sndfile\.\w+(\.\w+)?') | ForEach-Object Value } | Sort-Object -Unique
"  unit di Sndfile usate da Sound: " + ($unitSndfile -join ', ')
"Sndfile -> Sound (vietato): {0} riferimenti" -f $versoSound.Count
$versoSound | ForEach-Object { '  ' + $_ }

if ($versoSound.Count -gt 0) { Write-Host 'CICLO PRESENTE' -ForegroundColor Red; exit 1 }
Write-Host 'Nessun ciclo: la dipendenza va solo da Sound a Sndfile.' -ForegroundColor Green
exit 0
