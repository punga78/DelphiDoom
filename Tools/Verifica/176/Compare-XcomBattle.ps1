<#
  Carica un salvataggio con una battaglia in corso (Tests\Data\XcomBattle\bg\<scenario>\start.sav.gz, scritto dal vero
  OpenXcom con bgame) in Xcom32 e, con -Real, anche nel vero OpenXcom; esegue i passi e confronta pixel per pixel le
  schermate (Compare-Png.ps1).

  Uso: Compare-XcomBattle.ps1 -Root <worktree> -Data <Reference\_dati\xcom_tftd> -Out <cartella> -Scenario g01_2
         -Delphi 'wait:1500;move:2000,2000;shot:a.png' [-Real 'wait:3','shot:a' -Names a]

  -Delphi  i passi di Xcom32 dopo il caricamento (millisecondi; menu, Load Game e il salvataggio sono gia' fatti)
  -Real    i passi di Capture-OpenXcomScreen.ps1 dopo il caricamento (secondi); senza, gira solo Xcom32
  -Option  opzioni da cambiare in options.cfg per entrambi, 'chiave=valore' (per esempio 'battleNewPreviewPath=3')
  La cartella utente e' <Out>\user (mai quella dell'utente). Con -Real prende il lock globale dei giochi.
#>
param(
  [Parameter(Mandatory = $true)][string]$Root,
  [Parameter(Mandatory = $true)][string]$Data,
  [Parameter(Mandatory = $true)][string]$Out,
  [Parameter(Mandatory = $true)][string]$Delphi,
  [string]$Scenario = 'g01_2',
  [string[]]$Real = @(),
  [string[]]$Names = @(),
  [string[]]$Option = @(),
  # how many times the capture of the real program is tried when a file is missing (real mouse clicks)
  [int]$Tries = 1,
  # a saved game to load in place of the one of the scenario (plain text, for example one written by Xcom32)
  [string]$SaveFile = ''
)
$ErrorActionPreference = 'Stop'
if (Test-Path "$Out\user") { Remove-Item -Recurse -Force "$Out\user" }
New-Item -ItemType Directory -Force "$Out\real", "$Out\delphi", "$Out\user", "$Out\seed\xcom2" | Out-Null
if ($SaveFile -ne '') { $t = [IO.File]::ReadAllText($SaveFile) }
else {
  $gz = New-Object IO.Compression.GZipStream([IO.File]::OpenRead("$Root\Tests\Data\XcomBattle\bg\$Scenario\start.sav.gz"), [IO.Compression.CompressionMode]::Decompress)
  $reader = New-Object IO.StreamReader($gz)
  $t = $reader.ReadToEnd(); $reader.Close()
}
$t = $t.Replace("`r`n", "`n")
$t = [regex]::Replace($t, '(?m)^name: .*$', 'name: "Battle"', 1)
$t = $t.Replace('  - "xcom2 ver: 1.0"', '  - xcom2')
[IO.File]::WriteAllText("$Out\seed\xcom2\battle.sav", $t)
Copy-Item "$Out\seed\xcom2" "$Out\user" -Recurse -Force
$cfg = Get-Content "$Data\openxcom_user\options.cfg" -Raw
foreach ($o in $Option) {
  $kv = $o.Split('=', 2)
  $cfg = $cfg -replace ('(?m)^  ' + [regex]::Escape($kv[0]) + ': .*$'), ('  ' + $kv[0] + ': ' + $kv[1])
}
Set-Content -Path "$Out\user\options.cfg" -Value $cfg -Encoding ASCII
$script = 'wait:5000;move:220,256;click:220,256;wait:2000;move:80,92;click:80,92;wait:1000;' + $Delphi
Push-Location "$Out\delphi"
# a GUI program: Start-Process waits for it and keeps what it says
$p = Start-Process "$Root\bin\Win32\Release\OpenXcom\Xcom32.exe" -ArgumentList "-data `"$Data\openxcom`" -game `"$Data\TFTD`" -user `"$Out\user`" -script $script" -RedirectStandardError "$Out\delphi\stderr.txt" -RedirectStandardOutput "$Out\delphi\stdout.txt" -PassThru -Wait
Pop-Location
Get-Content "$Out\delphi\stderr.txt", "$Out\delphi\stdout.txt"
if ($Real.Count -eq 0) { return }
$realSteps = @('wait:3', 'click:220,256', 'wait:3', 'click:80,92') + $Real
$m = New-Object Threading.Mutex($false, 'Global\DelphiDoomEsecuzioneGioco')
$got = $m.WaitOne(300000)
try {
  for ($try = 0; $try -lt $Tries; $try++) {
    & "$Root\Tools\Verifica\176\Capture-OpenXcomScreen.ps1" -Root $Data -Out "$Out\real" -SeedFolder "$Out\seed" -UserRoot "$Out\realuser" -Steps $realSteps -Option $Option | Out-Null
    $missing = @($Names | Where-Object { -not (Test-Path "$Out\real\$_.png") })
    if ($missing.Count -eq 0) { break }
  }
}
finally { if ($got) { $m.ReleaseMutex() } }
foreach ($n in $Names) {
  Write-Output "== $n"
  & "$Root\Tools\Verifica\176\Compare-Png.ps1" -A "$Out\real\$n.png" -B "$Out\delphi\$n.png" 2>&1 | Select-Object -First 4
}
