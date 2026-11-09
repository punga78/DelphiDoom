param($Dpr, $Defs = '', $Extra = '')
# builds a harness of the old ENDEDIT code (dcc32, Delphi 11, Win32) in endedit164\h
$S = (Resolve-Path 'C:\Users\LUCA~1.ZAN\AppData\Local\Temp\claude\a3c76a9d4969dc27\d23e3d1a-cf0b-418e-9d58-bbf172d805f7\scratchpad').Path
$root = "$S\endedit164\h\src"; $out = "$S\endedit164\h\out"; $dcu = "$S\endedit164\h\dcu"
$bds = 'C:\Program Files (x86)\Embarcadero\Studio\22.0'
$ns = 'Vcl;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell;System;Xml;Data;Datasnap;Web;Soap;Winapi;System.Win;Bde'
$a = @('-B', '-Q', '-W+', '-H+', "-NS$ns", "-E$out", "-N0$dcu", "-U$root;$root\Graphics32;$Extra", "-I$root;$root\Graphics32", "-R$root")
if ($Defs) { $a += "-D$Defs" }
$a += $Dpr
Push-Location $root
& "$bds\bin\dcc32.exe" @a > "$S\endedit164\build-$Dpr.log" 2>&1
$rc = $LASTEXITCODE; Pop-Location
"rc=$rc"
Select-String -Path "$S\endedit164\build-$Dpr.log" -Pattern 'Error|Fatal' | Select-Object -First 15 | ForEach-Object Line
