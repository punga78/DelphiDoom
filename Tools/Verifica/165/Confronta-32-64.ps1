<#
  Runs the same script of Keen32 at 32 and at 64 bit (no window, a tic of the game for each wait, no random seed)
  and compares the pictures byte by byte (issue #165, Win64). Exit code 1 on the first difference.

    powershell -NoProfile -File Tools\Verifica\165\Confronta-32-64.ps1 -Exe32 bin\Win32\Release\Keen\Keen32.exe `
      -Exe64 bin\Win64\Release\Keen\Keen32.exe -DataFolders <folder>,<folder> -Script Tools\Verifica\165\Prove\camminata.script
#>
param(
  [Parameter(Mandatory = $true)][string]$Exe32,
  [Parameter(Mandatory = $true)][string]$Exe64,
  [Parameter(Mandatory = $true)][string[]]$DataFolders,
  [Parameter(Mandatory = $true)][string]$Script,
  [int]$Level = 1,
  [string[]]$ExtraArguments = @()
)
$ErrorActionPreference = 'Stop'
$DataFolders = @($DataFolders | ForEach-Object { $_.Split(',') } | Where-Object { $_ -ne '' })
$ExtraArguments = @($ExtraArguments | ForEach-Object { $_.Split(',') } | Where-Object { $_ -ne '' })
$data = @()
foreach ($folder in $DataFolders) { $data += '-data'; $data += $folder }
$root = Join-Path $env:TEMP 'keen_32_64'
if (Test-Path $root) { Remove-Item -Recurse -Force $root }
$results = @{}
foreach ($bits in '32', '64') {
  $exe = if ($bits -eq '32') { $Exe32 } else { $Exe64 }
  $shots = Join-Path $root "shots$bits"
  $save = Join-Path $root "save$bits"
  New-Item -ItemType Directory -Force $shots, $save | Out-Null
  $arguments = $data + @('-save', $save, '-script', $Script, '-shots', $shots, '-report', '-nodevice') + $ExtraArguments
  if ($Level -ge 0) { $arguments += @('-warp', "$Level") }
  $text = (& $exe @arguments 2>&1 | Out-String)
  $results[$bits] = $text
  "[$bits bit] " + $text.Trim()
}
$failed = $false
foreach ($file in Get-ChildItem (Join-Path $root 'shots32') -Filter *.png) {
  $other = Join-Path (Join-Path $root 'shots64') $file.Name
  if (-not (Test-Path $other)) { "MISSING at 64 bit: $($file.Name)"; $failed = $true; continue }
  $a = (Get-FileHash $file.FullName -Algorithm SHA256).Hash
  $b = (Get-FileHash $other -Algorithm SHA256).Hash
  if ($a -ne $b) { "DIFFERENT: $($file.Name)"; $failed = $true } else { "same: $($file.Name)" }
}
# the saved game and the configuration must be the same bytes too
foreach ($file in Get-ChildItem (Join-Path $root 'save32') -File) {
  $other = Join-Path (Join-Path $root 'save64') $file.Name
  if (-not (Test-Path $other)) { "MISSING at 64 bit: $($file.Name)"; $failed = $true; continue }
  if ((Get-FileHash $file.FullName).Hash -ne (Get-FileHash $other).Hash) { "DIFFERENT: $($file.Name)"; $failed = $true } else { "same: $($file.Name)" }
}
if ($failed) { exit 1 }
'OK'
