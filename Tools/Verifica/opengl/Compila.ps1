# TEMPORARY HARNESS (issue #177): builds the OpenGL games with the GL call recorder and the hooks of
# hook-gl.patch, and copies the executables to <this tree>\harness_out\<Game>_GL_OLD.exe / _GL_NEW.exe.
# Never starts a game. The executables are built with the environment variable DCC_Define=GLRECORD
# (the dproj of every game has  $(DCC_Define)  in its defines): the recorder exists only in them.
#
#   .\Tools\Verifica\opengl\Compila.ps1 -Which New [-Game GLDoom,GLHeretic,GLHexen,GLStrife]
#   .\Tools\Verifica\opengl\Compila.ps1 -Which Old -OldTree C:\Progetti\DelphiDoom\.claude\worktrees\gl-old
#
# New: this tree. Old: a tree of the commit to compare with (for issue #177: 33b284eb, made with
#   git worktree add <folder> 33b284eb ); the script copies the recorder and the harness into it.
# The patch is applied before the build and taken away after.
param(
  [Parameter(Mandatory = $true)][ValidateSet('Old', 'New')][string]$Which,
  [string]$OldTree = '',
  [string[]]$Game = @('GLDoom', 'GLHeretic', 'GLHexen', 'GLStrife')
)
$ErrorActionPreference = 'Stop'
$here = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$patch = Join-Path $PSScriptRoot 'hook-gl.patch'
$out = Join-Path $here 'harness_out'
New-Item -ItemType Directory -Force $out | Out-Null

if ($Which -eq 'Old') {
  if ($OldTree -eq '') { throw 'Serve -OldTree per il vecchio' }
  $tree = (Resolve-Path $OldTree).Path
  New-Item -ItemType Directory -Force (Join-Path $tree 'Libs\OpenGl\Recorder') | Out-Null
  New-Item -ItemType Directory -Force (Join-Path $tree 'Tools\Verifica\opengl') | Out-Null
  Copy-Item (Join-Path $here 'Libs\OpenGl\Recorder\*.pas') (Join-Path $tree 'Libs\OpenGl\Recorder') -Force
  Copy-Item (Join-Path $PSScriptRoot 'HarnessGl.pas') (Join-Path $tree 'Tools\Verifica\opengl') -Force
} else {
  $tree = $here
}
Set-Location $tree
New-Item -ItemType Directory -Force logs | Out-Null

git apply $patch
if ($LASTEXITCODE -ne 0) { throw "git apply $patch fallito in $tree" }
$savedDefine = $env:DCC_Define
$env:DCC_Define = 'GLRECORD'
try {
  foreach ($g in $Game) {
    $project = "${g}32"
    $folder = $g.Substring(2)
    & .\Tools\build.bat $project Release
    $log = "logs\$project.log"
    $errors = @(Select-String -Path $log -Pattern '\berror\b|\[Fatal Error\]|Fatal:' -CaseSensitive:$false)
    Write-Host "== $Which $project : $($errors.Count) error lines (see $tree\$log)"
    $errors | Select-Object -First 15 | ForEach-Object { Write-Host $_.Line }
    $exe = "bin\$folder\$project.exe"
    if ($errors.Count -eq 0 -and (Test-Path $exe)) {
      $target = Join-Path $out "${g}_GL_$($Which.ToUpper()).exe"
      Copy-Item $exe $target -Force
      Write-Host "   -> $target"
    }
  }
}
finally {
  $env:DCC_Define = $savedDefine
  git apply -R $patch
}
