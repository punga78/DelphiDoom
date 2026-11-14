<#
  Issue #40 (sotto-issue #43): i layout su disco dei record dei salvataggi.

  Lancia il programma a 32 bit e quello a 64 bit di ogni gioco con -savelayouts: ognuno scrive, per ogni record che
  un salvataggio tiene intero (giocatori, thinker dei settori, vecchi formati dei mobj...), la dimensione su disco,
  offset e dimensione di ogni campo e gli offset dei valori che in memoria sono puntatori. Le righe non dicono niente
  del layout in memoria, quindi i due programmi devono scrivere le stesse; e devono essere quelle dei golden
  Tests\Data\SaveLayout\<Gioco>.txt, che sono il formato dei salvataggi (a 32 bit il layout su disco e' quello che
  il compilatore da' al record: il programma lo controlla da solo e scrive ERROR se non lo capisce).

  Uso (dalla radice del repository):
    powershell -NoProfile -File Tools\Verifica\40\Prova-Layout.ps1 [-Game Doom,Hexen] [-Update] [-NoLock]
       [-Exe32 "Doom=...;..."] [-Exe64 "..."] [-DataRoot <bin coi WAD>] [-WorkRoot C:\ddsave40]

  -Update riscrive i golden con le righe del programma a 32 bit (solo quando il formato cambia di proposito).
  Codice di uscita: 0 se tutto e' uguale, 1 altrimenti.
#>
param(
  [string[]]$Game = @(),
  $Exe32 = @{},
  $Exe64 = @{},
  [string]$DataRoot = '',
  [string]$WorkRoot = 'C:\ddsave40',
  [switch]$Update,
  [switch]$NoLock
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\185\Parity-Common.ps1')
. (Join-Path $PSScriptRoot 'Salvataggi-Common.ps1')

$root = Get-ParityRoot
$Exe32 = ConvertTo-ParityMap $Exe32
$Exe64 = ConvertTo-ParityMap $Exe64
# un livello qualsiasi di ogni gioco: i layout non dipendono dal livello
$levels = [ordered]@{
  Doom    = @{ Iwad = 'DOOM1.WAD'; Warp = '1 1' }
  Heretic = @{ Iwad = 'HERETIC1.WAD'; Warp = '1 1' }
  Hexen   = @{ Iwad = 'HEXEN.WAD'; Warp = '1' }
  Strife  = @{ Iwad = 'STRIFE0.WAD'; Warp = '32' }
}
$games = Get-ParityGames
$goldenDir = Join-Path $root 'Tests\Data\SaveLayout'
$failed = 0
foreach ($gameName in $levels.Keys) {
  if ($Game.Count -gt 0 -and $Game -notcontains $gameName) { continue }
  $info = $games[$gameName]
  $source32 = $Exe32[$gameName]; if (-not $source32) { $source32 = Join-Path $root "bin\Win32\Release\$($info.Folder)\$($info.Exe)" }
  $source64 = $Exe64[$gameName]; if (-not $source64) { $source64 = Join-Path $root "bin\Win64\Release\$($info.Folder)\$($info.Exe)" }
  $dir = Initialize-ParityRunDir -Game $gameName -WorkRoot $WorkRoot -DataRoot $DataRoot -Executables @{
    "sv_n32_$($info.Exe)" = $source32; "sv_n64_$($info.Exe)" = $source64 }
  $lines = @{}
  foreach ($key in 'n32', 'n64') {
    $file = Join-Path $dir "lay_$key.txt"
    Remove-Item $file -ErrorAction SilentlyContinue
    $arguments = "-iwad $($levels[$gameName].Iwad) -config p8.ini -dontsavedefaults -nomusic -nosound -noblit -singletics " +
      "-warp $($levels[$gameName].Warp) -skill 2 -autodemo 3 5 -savelayouts lay_$key.txt"
    $null = Invoke-SaveRun -Exe (Join-Path $dir "sv_${key}_$($info.Exe)") -Arguments $arguments -WorkDir $dir -NoLock:$NoLock
    $lines[$key] = @()
    if (Test-Path $file) { $lines[$key] = @(Get-Content $file) }
  }
  $records = @($lines['n32'] | Where-Object { $_ -match '^\S' }).Count
  $errors = @($lines['n32'] + $lines['n64'] | Where-Object { $_ -like 'ERROR*' })
  $golden = Join-Path $goldenDir "$gameName.txt"
  if ($Update -and $lines['n32'].Count -gt 0 -and $errors.Count -eq 0) {
    New-Item -ItemType Directory -Force $goldenDir | Out-Null
    [IO.File]::WriteAllText($golden, ($lines['n32'] -join "`n") + "`n")
  }
  $verdict = @()
  if ($lines['n32'].Count -eq 0 -or $lines['n64'].Count -eq 0) { $verdict += 'LAYOUT NON SCRITTI' }
  if ($errors.Count -gt 0) { $verdict += "$($errors.Count) ERRORI: $($errors[0])" }
  if (Compare-Object $lines['n32'] $lines['n64'] -CaseSensitive) { $verdict += '32 E 64 BIT DIVERSI' }
  if (-not (Test-Path $golden)) { $verdict += 'golden mancante (-Update)' }
  elseif (Compare-Object @(Get-Content $golden) $lines['n32'] -CaseSensitive) { $verdict += 'DIVERSO DAL GOLDEN (il formato dei salvataggi e'' cambiato)' }
  if ($verdict.Count -eq 0) { Write-Output ("{0,-8}: {1} record, 32 e 64 bit uguali, uguali al golden" -f $gameName, $records) }
  else { $failed++; Write-Output ("{0,-8}: {1} record, {2}" -f $gameName, $records, ($verdict -join '; ')) }
}
if ($failed -gt 0) { exit 1 }
exit 0
