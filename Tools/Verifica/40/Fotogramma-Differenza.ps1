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
  # nomi con cui i due eseguibili sono copiati nella cartella di lavoro: il nome fa parte della riga di comando,
  # e la sua lunghezza sposta i blocchi di memoria (i golden sono fatti con parity_<Gioco>32.exe)
  [string]$NewName = 'fd_new.exe',
  [string]$RefName = 'fd_ref.exe',
  [string]$WorkRoot = 'C:\ddpari40',
  [string]$DataRoot = ''
)
. (Join-Path $PSScriptRoot '..\185\Parity-Common.ps1')
$entry = @(Get-ParityCorpus -Game @($Game) -Name $Name)[0]
if ($null -eq $entry) { throw "Voce non trovata: $Game $Name" }
$dir = Initialize-ParityRunDir -Game $Game -WorkRoot $WorkRoot -DataRoot $DataRoot `
  -Executables @{ $NewName = (Resolve-Path $Exe).Path; $RefName = (Resolve-Path $RefExe).Path }
$names = @{ 'new' = $NewName; 'ref' = $RefName }
$files = @{}
foreach ($tag in 'new', 'ref') {
  $bmp = "fd_$tag.bmp"
  Remove-Item (Join-Path $dir $bmp) -ErrorAction SilentlyContinue
  # Il fotogramma si chiede con la variabile d'ambiente e non con -framedump: la riga di comando resta quella
  # dei golden (la sua lunghezza sposta i blocchi di memoria, e il renderer legge a volte un byte fuori da un
  # buffer: con un'altra riga di comando il fotogramma puo' cambiare)
  $env:DDPARITY_FRAMEDUMP = "$Tic;$bmp"
  Remove-Item (Join-Path $dir "$bmp.raw") -ErrorAction SilentlyContinue
  $null = Invoke-ParityEntry -Entry $entry -Mode $Mode -RunDir $dir -ExeName $names[$tag] `
    -StateFile (Join-Path $dir "fd_$tag.state.txt") -FrameFile (Join-Path $dir "fd_$tag.frame.txt")
  $env:DDPARITY_FRAMEDUMP = $null
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
# Il buffer che l'impronta legge (indici della tavolozza nei modi a 8 bit): due indici diversi possono avere lo
# stesso colore, e allora il BMP e' uguale ma l'impronta no. Lo scrive il motore accanto al BMP (nome + .raw).
$rawRef = $files['ref'] + '.raw'
$rawNew = $files['new'] + '.raw'
if ((Test-Path $rawRef) -and (Test-Path $rawNew)) {
  $ra = [IO.File]::ReadAllBytes($rawRef)
  $rb = [IO.File]::ReadAllBytes($rawNew)
  $bpp = [int]($ra.Length / ($width * $rows))
  $rawCount = 0
  $rawList = New-Object System.Collections.Generic.List[string]
  for ($i = 0; $i -lt $ra.Length; $i++) {
    if ($ra[$i] -ne $rb[$i]) {
      $rawCount++
      $pixel = [Math]::Floor($i / $bpp)
      if ($rawList.Count -lt 40) { $rawList.Add(("({0},{1}) byte {2}: rif {3} nuovo {4}" -f ($pixel % $width), [Math]::Floor($pixel / $width), ($i % $bpp), $ra[$i], $rb[$i])) }
    }
  }
  "buffer dell'impronta ({0} byte per pixel): {1} byte diversi" -f $bpp, $rawCount
  $rawList
}
