# TEMPORARY HARNESS (issue #172, fetta 2i): the screen with the overlay, old against new. <Game>_OLD.exe and <Game>_NEW.exe
# (harness_out\shot, from Compila-ScriptHost.ps1 -Variant L2) run a level with -vsh shot: the script of the map draws
# text, a rectangle, a line, a pixel, a patch and a stretched patch on the overlay (lasting 100000 tics); at tic 70 the
# harness takes a screenshot (G_ScreenShot) and ends at tic 80. The images (the new files of the folders of the game) are
# compared byte by byte (SHA-256).
#
#   .\Tools\Verifica\scripthost\Confronta-Screenshot.ps1 -Game Doom|GLDoom [-Keep <cartella>]
#
# -Keep   copies the two images there (<Game>_OLD.png, <Game>_NEW.png) to look at them
param(
  [Parameter(Mandatory = $true)][ValidateSet('Doom', 'Heretic', 'Hexen', 'Strife', 'GLDoom')][string]$Game,
  [string]$Keep = '',
  [int]$Seconds = 300
)
$ErrorActionPreference = 'Stop'
$here = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$common = 'C:\Progetti\DelphiDoom'
$runner = Join-Path $common 'Tools\Esegui-gioco.ps1'
if (-not (Test-Path $runner)) { $runner = Join-Path $here 'Tools\Esegui-gioco.ps1' }
if ($Game -eq 'GLDoom') { $folder = 'Doom' } else { $folder = $Game }
$binDir = Join-Path $common "bin\$folder"
switch ($Game) {
  'Doom'    { $iwad = '-iwad FREEDOOM2.WAD -warp 1' }
  'GLDoom'  { $iwad = '-iwad FREEDOOM2.WAD -warp 1' }
  'Heretic' { $iwad = '-iwad HERETIC1.WAD -warp 1 1' }
  'Hexen'   { $iwad = '-iwad HEXEN.WAD -warp 1' }
  'Strife'  { $iwad = '-iwad STRIFE0.WAD -warp 2' }
}
$hashes = @{}
foreach ($label in 'OLD', 'NEW') {
  $exe = Join-Path $here "harness_out\shot\${Game}_$label.exe"
  if (-not (Test-Path $exe)) { throw "Eseguibile non trovato: $exe" }
  $copy = Join-Path $binDir "${Game}32_SHOT$label.exe"
  Copy-Item $exe $copy -Force
  $start = Get-Date
  try {
    & powershell -NoProfile -File $runner -Exe $copy -Arguments "$iwad -nomonsters -nomusic -nosound -vsh shot" -WorkDir $binDir -Seconds $Seconds -StopWhenExited
  }
  finally {
    Remove-Item $copy -Force -ErrorAction SilentlyContinue
  }
  $images = @(Get-ChildItem $binDir -Recurse -File -Include *.png, *.jpg, *.tga -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -gt $start -and $_.FullName -notmatch '\\verify' })
  if ($images.Count -eq 0) { throw "[$label] nessuna immagine nuova in $binDir" }
  $image = $images | Sort-Object LastWriteTime | Select-Object -Last 1
  $hashes[$label] = (Get-FileHash $image.FullName -Algorithm SHA256).Hash
  Write-Host "[$label] $($image.FullName) ($($image.Length) byte) SHA-256 $($hashes[$label])"
  if ($Keep -ne '') {
    New-Item -ItemType Directory -Force $Keep | Out-Null
    Copy-Item $image.FullName (Join-Path $Keep "${Game}_$label$($image.Extension)") -Force
  }
  Remove-Item $image.FullName -Force -ErrorAction SilentlyContinue
}
if ($hashes['OLD'] -eq $hashes['NEW']) { Write-Host "== $Game : IMMAGINI UGUALI" } else { Write-Host "== $Game : IMMAGINI DIVERSE"; exit 1 }
