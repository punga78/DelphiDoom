# TEMPORARY HARNESS (issues #151 and #156): builds the games with the hook of hook151.patch and copies the
# executables to <this tree>\harness_out\<Game>_V_OLD.exe / <Game>_V_NEW.exe. Never starts a game.
#
#   .\Tools\Verifica\harness151\Compila-151.ps1 -Which New [-OldTree <folder>] [-Game Doom,Heretic,Hexen,Strife,GLDoom]
#   .\Tools\Verifica\harness151\Compila-151.ps1 -Which Old -OldTree C:\Progetti\DelphiDoom\.claude\worktrees\h151-old
#
# New: this tree. Old: a tree of commit 31ee71e3, made with  git worktree add <folder> 31ee71e3  (the script
# copies Harness151.pas into it). The patch is applied before the build and taken away after.
param(
  [Parameter(Mandatory = $true)][ValidateSet('Old', 'New')][string]$Which,
  [string]$OldTree = '',
  [string[]]$Game = @('Doom', 'Heretic', 'Hexen', 'Strife', 'GLDoom')
)
$ErrorActionPreference = 'Stop'
$here = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$patch = Join-Path $PSScriptRoot 'hook151.patch'
$out = Join-Path $here 'harness_out'
New-Item -ItemType Directory -Force $out | Out-Null

if ($Which -eq 'Old') {
  if ($OldTree -eq '') { throw 'Serve -OldTree per il vecchio' }
  $tree = (Resolve-Path $OldTree).Path
  $dest = Join-Path $tree 'Tools\Verifica\harness151'
  New-Item -ItemType Directory -Force $dest | Out-Null
  Copy-Item (Join-Path $PSScriptRoot 'Harness151.pas') $dest -Force
} else {
  $tree = $here
}
Set-Location $tree
New-Item -ItemType Directory -Force logs | Out-Null

git apply $patch
if ($LASTEXITCODE -ne 0) { throw "git apply $patch fallito in $tree" }
try {
  foreach ($g in $Game) {
    $project = "${g}32"
    & .\build.bat $project Release
    $log = "logs\$project.log"
    $errors = @(Select-String -Path $log -Pattern '\berror\b|\[Fatal Error\]|Fatal:' -CaseSensitive:$false)
    Write-Host "== $Which $project : $($errors.Count) error lines (see $tree\$log)"
    $errors | Select-Object -First 15 | ForEach-Object { Write-Host $_.Line }
    if ($g -eq 'GLDoom') { $folder = 'Doom' } else { $folder = $g }
    $exe = "bin\$folder\$project.exe"
    if ($errors.Count -eq 0 -and (Test-Path $exe)) {
      $target = Join-Path $out "${g}_V_$($Which.ToUpper()).exe"
      Copy-Item $exe $target -Force
      Write-Host "   -> $target"
    }
  }
}
finally {
  git apply -R $patch
}
