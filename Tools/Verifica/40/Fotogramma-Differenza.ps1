<#
  Issue #40: scarica lo stesso fotogramma (-framedump) da due eseguibili (di solito Win32 e Win64) su una voce del
  corpus della parita' (Tools\Verifica\185\Corpus.psd1) e dice quanti pixel sono diversi e dove. Serve a trovare i
  punti in virgola mobile del renderer che a 64 bit (SSE) danno un numero diverso dall'x87.

  Uso:
    powershell -NoProfile -File Tools\Verifica\40\Fotogramma-Differenza.ps1 -Game Doom -Name d1_demo1 -Tic 685 -Mode 8 `
      -Exe <nuovo.exe> -RefExe <riferimento.exe> [-WorkRoot C:\ddpari40] [-DataRoot <bin con i WAD>]
#>
param(
  [Parameter(Mandatory = $true)][string]$Game,
  [Parameter(Mandatory = $true)][string]$Name,
  [Parameter(Mandatory = $true)][int]$Tic,
  [int]$Mode = 8,
  [Parameter(Mandatory = $true)][string]$Exe,
  [Parameter(Mandatory = $true)][string]$RefExe,
  [string]$WorkRoot = 'C:\ddpari40',
  [string]$DataRoot = ''
)
. (Join-Path $PSScriptRoot '..\185\Parity-Common.ps1')
$entry = @(Get-ParityCorpus -Game @($Game) -Name $Name)[0]
if ($null -eq $entry) { throw "Voce non trovata: $Game $Name" }
$dir = Initialize-ParityRunDir -Game $Game -WorkRoot $WorkRoot -DataRoot $DataRoot `
  -Executables @{ 'fd_new.exe' = (Resolve-Path $Exe).Path; 'fd_ref.exe' = (Resolve-Path $RefExe).Path }
$files = @{}
foreach ($tag in 'new', 'ref') {
  $bmp = "fd_$tag.bmp"
  Remove-Item (Join-Path $dir $bmp) -ErrorAction SilentlyContinue
  $null = Invoke-ParityEntry -Entry $entry -Mode $Mode -RunDir $dir -ExeName "fd_$tag.exe" `
    -StateFile (Join-Path $dir "fd_$tag.state.txt") -FrameFile (Join-Path $dir "fd_$tag.frame.txt") -Extra "-framedump $Tic $bmp"
  $files[$tag] = Join-Path $dir $bmp
  if (-not (Test-Path $files[$tag])) { throw "Fotogramma non scritto: $($files[$tag])" }
}
$a = [IO.File]::ReadAllBytes($files['ref'])
$b = [IO.File]::ReadAllBytes($files['new'])
$offset = [BitConverter]::ToInt32($a, 10)
$width = [BitConverter]::ToInt32($a, 18)
$height = [BitConverter]::ToInt32($a, 22)
$bottomUp = $height -gt 0
$rows = [Math]::Abs($height)
$count = 0
$list = New-Object System.Collections.Generic.List[string]
for ($i = $offset; $i -lt $a.Length - 3; $i += 4) {
  if ($a[$i] -ne $b[$i] -or $a[$i + 1] -ne $b[$i + 1] -or $a[$i + 2] -ne $b[$i + 2]) {
    $count++
    $pixel = ($i - $offset) / 4
    $x = $pixel % $width
    $y = [Math]::Floor($pixel / $width)
    if ($bottomUp) { $y = $rows - 1 - $y }
    if ($list.Count -lt 40) {
      $list.Add(("({0},{1}) rif {2:x2}{3:x2}{4:x2} nuovo {5:x2}{6:x2}{7:x2}" -f $x, $y, $a[$i + 2], $a[$i + 1], $a[$i], $b[$i + 2], $b[$i + 1], $b[$i]))
    }
  }
}
"{0} {1} modo {2} tic {3}: {4} pixel diversi ({5}x{6}); file: {7} e {8}" -f $Game, $Name, $Mode, $Tic, $count, $width, $rows, $files['ref'], $files['new']
$list
