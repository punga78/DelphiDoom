# TEMPORARY HARNESS: builds <Gioco>_SNEW.exe (this tree) and <Gioco>_SOLD.exe (a temporary worktree on
# the commit before the thinker waves, 31ee71e3) with the savegame hook, into harness_out\.
# Never starts a game.
#   .\Tools\Verifica\harness\Compila-Salvataggi.ps1 [-Game Doom,Heretic,Strife,Hexen] [-Which NEW,OLD]
param(
  [string[]]$Game = @('Doom', 'Heretic', 'Strife', 'Hexen'),
  [string[]]$Which = @('NEW', 'OLD'),
  [string]$OldCommit = '31ee71e3',
  [string]$OldTree = ''
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
if ($OldTree -eq '') { $OldTree = Join-Path (Split-Path $root -Parent) 'save-old' }
New-Item -ItemType Directory -Force (Join-Path $root 'harness_out') | Out-Null

function Build-One([string]$Tree, [string]$G, [string]$Label) {
  Set-Location $Tree
  New-Item -ItemType Directory -Force logs | Out-Null
  $patch = Join-Path $root "Tools\Verifica\harness\hook-$($G.ToLower())-save.patch"
  git apply $patch
  if ($LASTEXITCODE -ne 0) { throw "git apply $patch failed in $Tree" }
  try {
    & .\build.bat "${G}32" Release
    $log = "logs\${G}32.log"
    $errors = @(Select-String -Path $log -Pattern '\berror\b|\[Fatal Error\]|Fatal:' -CaseSensitive:$false)
    Write-Host "== $G $Label : $($errors.Count) error lines (see $Tree\$log)"
    $errors | Select-Object -First 15 | ForEach-Object { Write-Host $_.Line }
    $exe = "bin\$G\${G}32.exe"
    if ($errors.Count -eq 0 -and (Test-Path $exe)) {
      Copy-Item $exe (Join-Path $root "harness_out\${G}_$Label.exe") -Force
      Write-Host "   -> harness_out\${G}_$Label.exe"
    }
  }
  finally {
    git apply -R $patch
  }
}

if ($Which -contains 'OLD') {
  if (-not (Test-Path $OldTree)) {
    Set-Location $root
    git worktree add --detach $OldTree $OldCommit
  }
  # the harness folder is not in the old commit: only the unit and the includes are needed
  $dest = Join-Path $OldTree 'Tools\Verifica\harness'
  New-Item -ItemType Directory -Force $dest | Out-Null
  Copy-Item (Join-Path $root 'Tools\Verifica\harness\harness_sweep.pas') $dest -Force
  Copy-Item (Join-Path $root 'Tools\Verifica\harness\harness_save_*.inc') $dest -Force
}

foreach ($g in $Game) {
  if ($Which -contains 'NEW') { Build-One $root $g 'SNEW' }
  if ($Which -contains 'OLD') { Build-One $OldTree $g 'SOLD' }
}
Set-Location $root
