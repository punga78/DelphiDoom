# TEMPORARY HARNESS: for each game and variant applies the patch, builds the game in Release,
# copies the executable to harness_out\<Gioco>_H.exe (lights, doors, platforms, clean exit) or
# harness_out\<Gioco>_P.exe (planes) and takes the patch away. Never starts a game.
#   .\Tools\Verifica\harness\Compila-Harness.ps1 [-Game Heretic,Strife,Hexen] [-Variant H,P]
param(
  [string[]]$Game = @('Heretic', 'Strife', 'Hexen'),
  [string[]]$Variant = @('H', 'P')
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Set-Location $root
New-Item -ItemType Directory -Force logs, harness_out | Out-Null

foreach ($g in $Game) {
  foreach ($v in $Variant) {
    if ($v -eq 'H') { $suffix = 'all' } else { $suffix = 'plane' }
    $patch = Join-Path $PSScriptRoot "hook-$($g.ToLower())-$suffix.patch"
    git apply $patch
    if ($LASTEXITCODE -ne 0) { throw "git apply $patch failed" }
    try {
      & .\Tools\build.bat "${g}32" Release
      $log = "logs\${g}32.log"
      $errors = @(Select-String -Path $log -Pattern '\berror\b|\[Fatal Error\]|Fatal:' -CaseSensitive:$false)
      Write-Host "== $g $v : $($errors.Count) error lines (see $log)"
      $errors | Select-Object -First 15 | ForEach-Object { Write-Host $_.Line }
      $exe = "bin\$g\${g}32.exe"
      if ($errors.Count -eq 0 -and (Test-Path $exe)) {
        Copy-Item $exe "harness_out\${g}_$v.exe" -Force
        Write-Host "   -> harness_out\${g}_$v.exe"
      }
    }
    finally {
      git apply -R $patch
    }
  }
}
