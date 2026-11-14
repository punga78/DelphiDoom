<#
  Issue #40 (sotto-issue #43): un salvataggio che esiste gia' (fatto da un programma a 32 bit di prima) si carica col
  programma a 32 bit e con quello a 64 bit di oggi, e la partita prosegue uguale.

  Copia la cartella -Source (una COPIA dei salvataggi: non si lavora mai sugli originali) in <cartella di
  lavoro>\<Target>, carica lo slot con ogni programma (-loadgame) e gioca -LoadTics tic col pilota automatico scrivendo
  l'impronta dello stato: le righe devono essere uguali per tutti i programmi.

  Uso (dalla radice del repository):
    powershell -NoProfile -File Tools\Verifica\40\Prova-Esistenti.ps1 -Game Hexen -Iwad HEXEN.WAD -Slot 9 `
       -Source C:\copia\HEXNDATA -Target HEXNDATA [-RefExe "Hexen=C:\rif\Hexen32.exe"] [-LoadTics 300] [-NoLock]

  Target: dove il gioco cerca i salvataggi nella cartella dei dati (Doom e Heretic: DATA\SAVES\<nome del gioco>;
  Hexen: HEXNDATA; Strife: strfsav<slot>.ssg). Codice di uscita: 0 se le righe sono uguali, 1 altrimenti.
#>
param(
  [Parameter(Mandatory = $true)][string]$Game,
  [Parameter(Mandatory = $true)][string]$Iwad,
  [Parameter(Mandatory = $true)][string]$Source,
  [Parameter(Mandatory = $true)][string]$Target,
  [int]$Slot = 0,
  $Exe32 = @{},
  $Exe64 = @{},
  $RefExe = @{},
  [string]$DataRoot = '',
  [string]$WorkRoot = 'C:\ddsave40\esistenti',
  [int]$LoadTics = 300,
  [int]$Seed = 1234,
  [switch]$NoLock
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\185\Parity-Common.ps1')
. (Join-Path $PSScriptRoot 'Salvataggi-Common.ps1')

$root = Get-ParityRoot
$Exe32 = ConvertTo-ParityMap $Exe32
$Exe64 = ConvertTo-ParityMap $Exe64
$RefExe = ConvertTo-ParityMap $RefExe
$info = (Get-ParityGames)[$Game]
if ($null -eq $info) { throw "Gioco sconosciuto: $Game" }
$programs = [ordered]@{}
$programs['n32'] = $Exe32[$Game]; if (-not $programs['n32']) { $programs['n32'] = Join-Path $root "bin\Win32\Release\$($info.Folder)\$($info.Exe)" }
$programs['n64'] = $Exe64[$Game]; if (-not $programs['n64']) { $programs['n64'] = Join-Path $root "bin\Win64\Release\$($info.Folder)\$($info.Exe)" }
if ($RefExe[$Game]) { $programs['r32'] = $RefExe[$Game] }
$copies = @{}
foreach ($key in $programs.Keys) { $copies["sv_${key}_$($info.Exe)"] = $programs[$key] }
$dir = Initialize-ParityRunDir -Game $Game -WorkRoot $WorkRoot -DataRoot $DataRoot -Executables $copies
$sourcePath = (Resolve-Path $Source).Path
$reference = ''
$failed = 0
foreach ($key in $programs.Keys) {
  # ogni programma parte dagli stessi file: il caricamento puo' riscriverli (Hexen copia lo slot, Strife la cartella)
  Clear-SaveDirs -WorkDir $dir -SaveDirs @($Target)
  foreach ($file in (Get-ChildItem $sourcePath -Recurse -File)) {
    $to = Join-Path (Join-Path $dir $Target) $file.FullName.Substring($sourcePath.Length).TrimStart('\')
    New-Item -ItemType Directory -Force (Split-Path -Parent $to) | Out-Null
    Copy-Item $file.FullName $to -Force
  }
  $state = Join-Path $dir 'ld.txt'
  Remove-Item $state -ErrorAction SilentlyContinue
  $arguments = "-iwad $Iwad -config p8.ini -dontsavedefaults -nomusic -nosound -noblit -singletics -loadgame $Slot -autodemo $Seed $LoadTics -statehash ld.txt"
  $null = Invoke-SaveRun -Exe (Join-Path $dir "sv_${key}_$($info.Exe)") -Arguments $arguments -WorkDir $dir -NoLock:$NoLock
  $kept = Join-Path $dir "esistente_$key.txt"
  Remove-Item $kept -ErrorAction SilentlyContinue
  if (Test-Path $state) { Move-Item $state $kept -Force }
  $lines = Get-StateLineCount $kept
  $first = ''
  if ($lines -gt 0) { $first = @([IO.File]::ReadLines($kept) | Where-Object { $_.StartsWith('T ') })[0] }
  $verdict = 'riferimento del confronto'
  if ($reference -eq '') { $reference = $kept }
  else {
    $difference = Compare-StateLogs $reference $kept
    if ($difference -eq '') { $verdict = 'uguale' } else { $verdict = "DIVERSO: $difference"; $failed++ }
  }
  if ($lines -lt $LoadTics) { $verdict += " (solo $lines tic: il salvataggio non si e' caricato?)"; $failed++ }
  Write-Output ("{0,-8} {1}: {2} tic, {3}" -f $Game, $key, $lines, $verdict)
  Write-Output ("         primo tic: {0}" -f $first)
}
if ($failed -gt 0) { exit 1 }
exit 0
