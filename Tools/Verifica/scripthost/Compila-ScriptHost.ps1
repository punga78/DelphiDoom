# TEMPORARY HARNESS (issue #173): builds the games with the hooks of this folder and copies the executables to
# <this tree>\harness_out\<Game>_<Variant>_<OLD|NEW>.exe. Never starts a game.
#
#   .\Tools\Verifica\scripthost\Compila-ScriptHost.ps1 -Variant L2|Save -Which New|Old [-Game Doom,Heretic,Hexen,Strife,GLDoom] [-OldTree <cartella>]
#
#   Variant L2    hook-scripthost.patch: the battery of scripts (Confronta.ps1); Game: Doom, Heretic, Hexen, Strife, GLDoom
#   Variant Save  hook-save-<game>.patch: savegames with the state of the scripts (Confronta-Salvataggi.ps1);
#                 Game: Doom, Heretic, Hexen, Strife
#   New           this tree.
#   Old           a tree of the commit before the change: git worktree add --detach <cartella> 919a19ef. The default
#                 folder is ..\scripthost-old next to this tree (it is made if it is missing). The script copies there
#                 the harness units, applies the patch before the build and takes it away after.
param(
  [Parameter(Mandatory = $true)][ValidateSet('L2', 'Save')][string]$Variant,
  [Parameter(Mandatory = $true)][ValidateSet('Old', 'New')][string]$Which,
  [string[]]$Game = @(),
  [string]$OldTree = '',
  [string]$OldCommit = '919a19ef'
)
$ErrorActionPreference = 'Stop'
$here = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
if ($Game.Count -eq 0) {
  if ($Variant -eq 'L2') { $Game = @('Doom', 'Heretic', 'Hexen', 'Strife', 'GLDoom') } else { $Game = @('Doom', 'Heretic', 'Hexen', 'Strife') }
}
$out = Join-Path $here 'harness_out'
New-Item -ItemType Directory -Force $out | Out-Null

if ($Which -eq 'Old') {
  if ($OldTree -eq '') { $OldTree = Join-Path (Split-Path $here -Parent) 'scripthost-old' }
  if (-not (Test-Path $OldTree)) {
    Set-Location $here
    git worktree add --detach $OldTree $OldCommit
    if ($LASTEXITCODE -ne 0) { throw "git worktree add fallito per $OldTree" }
  }
  $tree = (Resolve-Path $OldTree).Path
  foreach ($sub in 'scripthost', 'harness') {
    $dest = Join-Path $tree "Tools\Verifica\$sub"
    New-Item -ItemType Directory -Force $dest | Out-Null
    Copy-Item (Join-Path $here "Tools\Verifica\$sub\*.pas") $dest -Force
    Copy-Item (Join-Path $here "Tools\Verifica\$sub\*.inc") $dest -Force -ErrorAction SilentlyContinue
  }
} else {
  $tree = $here
}
Set-Location $tree
New-Item -ItemType Directory -Force logs | Out-Null

foreach ($g in $Game) {
  if ($Variant -eq 'L2') {
    $patch = Join-Path $here 'Tools\Verifica\scripthost\hook-scripthost.patch'
    $project = "${g}32"
    $folder = if ($g -eq 'GLDoom') { 'Doom' } else { $g }
  } else {
    $patch = Join-Path $here "Tools\Verifica\scripthost\hook-save-$($g.ToLower()).patch"
    $project = "${g}32"
    $folder = $g
  }
  if (($Which -eq 'New') -and (Test-Path ($patch -replace '\.patch$', '.new.patch'))) { $patch = $patch -replace '\.patch$', '.new.patch' }
  git apply $patch
  if ($LASTEXITCODE -ne 0) { throw "git apply $patch fallito in $tree" }
  try {
    & .\Tools\build.bat "$folder\$project" Release
    $log = "logs\$project.log"
    $errors = @(Select-String -Path $log -Pattern '\berror\b|\[Fatal Error\]|Fatal:' -CaseSensitive:$false)
    Write-Host "== $Which $Variant $project : $($errors.Count) righe di errore (vedi $tree\$log)"
    $errors | Select-Object -First 15 | ForEach-Object { Write-Host $_.Line }
    $exe = "bin\$folder\$project.exe"
    if ($errors.Count -eq 0 -and (Test-Path $exe)) {
      $target = Join-Path $out "${g}_${Variant}_$($Which.ToUpper()).exe"
      Copy-Item $exe $target -Force
      Write-Host "   -> $target"
    }
  }
  finally {
    git apply -R $patch
  }
}
Set-Location $here
