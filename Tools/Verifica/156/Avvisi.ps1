<#
  Issue #156 - confronta gli avvisi di R_GenerateLookup (e gli I_Error) di due compilazioni: la vecchia
  (prima della fetta) e la nuova. I due eseguibili girano con -devparm sugli stessi WAD e la stessa
  mappa; dal log stderr piu recente si estraggono le righe "R_GenerateLookup" e "I_Error" e si
  confrontano (stesso numero, stesso testo, stesso ordine).

  Uso (dalla radice del worktree nuovo; gli eseguibili vecchi in una cartella bin di un'altra compilazione):
    powershell -NoProfile -File Tools\Verifica\156\Avvisi.ps1 -OldBin <cartella\bin> -NewBin <cartella\bin>

  Un avviso e stampato solo se il WAD ha texture con colonne senza patch: Freedoom 2 e Hexen ne hanno.
  Se in entrambi i log non c'e nessuna riga "R_GenerateLookup" il confronto e valido ma poco forte: lo
  dice l'ultima riga di ogni prova.
#>
param(
  [Parameter(Mandatory = $true)][string]$OldBin,
  [Parameter(Mandatory = $true)][string]$NewBin,
  [int]$Seconds = 30
)

$ErrorActionPreference = 'Stop'
$esegui = Join-Path $PSScriptRoot '..\..\Esegui-gioco.ps1'
$out = Join-Path $env:TEMP 'verifica156'
New-Item -ItemType Directory -Force -Path $out | Out-Null

$runs = @(
  @('Doom',    'Doom32.exe',      '-iwad DOOM1.WAD -warp 1 1 -devparm -nomusic'),
  @('Doom',    'Doom32.exe',      '-iwad FREEDOOM2.WAD -warp 1 -devparm -nomusic'),
  @('Doom',    'GLDoom32.exe',    '-iwad FREEDOOM2.WAD -warp 1 -devparm -nomusic'),
  @('Heretic', 'Heretic32.exe',   '-iwad HERETIC1.WAD -warp 1 1 -devparm -nomusic'),
  @('Heretic', 'GLHeretic32.exe', '-iwad HERETIC1.WAD -warp 1 1 -devparm -nomusic'),
  @('Hexen',   'Hexen32.exe',     '-iwad HEXEN.WAD -warp 1 -devparm -nomusic'),
  @('Hexen',   'GLHexen32.exe',   '-iwad HEXEN.WAD -warp 1 -devparm -nomusic'),
  @('Strife',  'Strife32.exe',    '-iwad STRIFE0.WAD -warp 2 -devparm -nomusic'),
  @('Strife',  'GLStrife32.exe',  '-iwad STRIFE0.WAD -warp 2 -devparm -nomusic')
)

function Get-Righe([string]$bin, $run, [string]$etichetta) {
  $dir = Join-Path $bin $run[0]
  $exe = Join-Path $dir $run[1]
  if (-not (Test-Path -LiteralPath $exe)) { return $null }
  $logs = Join-Path $dir 'DATA\LOGS'
  $prima = Get-Date
  & powershell -NoProfile -File $esegui -Exe $exe -Arguments $run[2] -Seconds $Seconds | Out-Null
  $log = Get-ChildItem (Join-Path $logs '*_stderr.txt') -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -ge $prima } | Sort-Object LastWriteTime | Select-Object -Last 1
  if (-not $log) { return @('NESSUN LOG STDERR') }
  $righe = Select-String -Path $log.FullName -Pattern 'R_GenerateLookup|I_Error' | ForEach-Object { $_.Line.Trim() }
  if (-not $righe) { return ,@() }
  return ,@($righe)
}

$diversi = 0
foreach ($run in $runs) {
  $nome = "$($run[1]) $($run[2])"
  $vecchio = Get-Righe $OldBin $run 'old'
  $nuovo = Get-Righe $NewBin $run 'new'
  if ($null -eq $vecchio -or $null -eq $nuovo) { Write-Output "SALTATO (eseguibile mancante): $nome"; continue }
  $safe = ($nome -replace '[^A-Za-z0-9]+', '_')
  Set-Content -LiteralPath (Join-Path $out "$safe.old.txt") -Value $vecchio
  Set-Content -LiteralPath (Join-Path $out "$safe.new.txt") -Value $nuovo
  $d = Compare-Object -ReferenceObject $vecchio -DifferenceObject $nuovo -SyncWindow 0
  if ($d) {
    $diversi++
    Write-Output "DIVERSO: $nome (vecchio $($vecchio.Count) righe, nuovo $($nuovo.Count))"
    $d | Select-Object -First 5 | ForEach-Object { Write-Output "    $($_.SideIndicator) $($_.InputObject)" }
  } else {
    Write-Output "UGUALE:  $nome ($($vecchio.Count) righe di avvisi)"
  }
}
Write-Output "Prove diverse: $diversi. File in $out"
if ($diversi -gt 0) { exit 1 }
