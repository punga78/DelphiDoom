param(
  [Parameter(Mandatory = $true)][string]$Dpr,
  [Parameter(Mandatory = $true)][string]$Work,
  [string]$Defs = '',
  [string]$Extra = ''
)
# Compila un harness del vecchio ENDEDIT (dcc32, Delphi 11, Win32). Uso, dalla radice del repository:
#   powershell -NoProfile -File Tools\Verifica\164\b.ps1 -Dpr H2.dpr -Work <cartella> -Extra "<repo>\Libs\Endoom;<repo>\Tests\Source"
#   (H3.dpr vuole anche -Defs VER340 per il Graphics32 del vecchio ENDEDIT)
# <cartella>\src deve contenere: una copia di Reference\ENDEDIT (ee_*.pas, zlibpas.pas, obj\, Graphics32\; in
# pngimage.pas "pChar" diventa "PAnsiChar" se serve) e i .dpr/.pas di Tools\Verifica\164. Uscita: <cartella>\out,
# log in <cartella>\build-<Dpr>.log.
$root = Join-Path $Work 'src'
$out = Join-Path $Work 'out'
$dcu = Join-Path $Work 'dcu'
New-Item -ItemType Directory -Force $out, $dcu | Out-Null
$bds = 'C:\Program Files (x86)\Embarcadero\Studio\22.0'
$ns = 'Vcl;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell;System;Xml;Data;Datasnap;Web;Soap;Winapi;System.Win;Bde'
$a = @('-B', '-Q', '-W+', '-H+', "-NS$ns", "-E$out", "-N0$dcu", "-U$root;$root\Graphics32;$Extra", "-I$root;$root\Graphics32", "-R$root")
if ($Defs) { $a += "-D$Defs" }
$a += $Dpr
Push-Location $root
& "$bds\bin\dcc32.exe" @a > (Join-Path $Work "build-$Dpr.log") 2>&1
$rc = $LASTEXITCODE
Pop-Location
"rc=$rc"
Select-String -Path (Join-Path $Work "build-$Dpr.log") -Pattern 'Error|Fatal' | Select-Object -First 15 | ForEach-Object Line
