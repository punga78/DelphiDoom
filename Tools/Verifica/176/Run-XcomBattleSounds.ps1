<#
  Esegue uno script di passi su una battaglia in corso (come Compare-XcomBattle.ps1, solo Xcom32) e scrive il registro
  dei suoni della battaglia: Xcom32 -soundlog fa passare i suoni dal mixer vero su un'uscita senza dispositivo che chiede
  i campioni mentre il tempo dello script passa. Ogni riga e' "<ms> play <profondita'> <suono> <angolo> (canali che
  suonano, suoni partiti)", "loop", "stop"; l'ultima riga sono le statistiche del mixer (byte resi, RMS, picco, suoni
  partiti). Serve a controllare senza l'orecchio che passi, spari, esplosioni e grida partano al momento giusto.

  Uso: Run-XcomBattleSounds.ps1 -Root <worktree> -Data <Reference\_dati\xcom_tftd> -Out <cartella> -Scenario g01_2
         -Delphi 'wait:2000;click:150,190;wait:4000' [-Option soundVolume=100]
  I salvataggi di <Root>\Tests\Data\XcomBattle\bg\<scenario>\start.sav.gz; la cartella utente e' <Out>\user.
#>
param(
  [Parameter(Mandatory = $true)][string]$Root,
  [Parameter(Mandatory = $true)][string]$Data,
  [Parameter(Mandatory = $true)][string]$Out,
  [Parameter(Mandatory = $true)][string]$Delphi,
  [string]$Scenario = 'g01_2',
  [string]$SaveRoot = '',
  [string[]]$Option = @()
)
$ErrorActionPreference = 'Stop'
if ($SaveRoot -eq '') { $SaveRoot = $Root }
if (Test-Path "$Out\user") { Remove-Item -Recurse -Force "$Out\user" }
New-Item -ItemType Directory -Force "$Out\delphi", "$Out\user\xcom2" | Out-Null
$gz = New-Object IO.Compression.GZipStream([IO.File]::OpenRead("$SaveRoot\Tests\Data\XcomBattle\bg\$Scenario\start.sav.gz"), [IO.Compression.CompressionMode]::Decompress)
$reader = New-Object IO.StreamReader($gz)
$t = $reader.ReadToEnd(); $reader.Close()
$t = $t.Replace("`r`n", "`n")
$t = [regex]::Replace($t, '(?m)^name: .*$', 'name: "Battle"', 1)
$t = $t.Replace('  - "xcom2 ver: 1.0"', '  - xcom2')
[IO.File]::WriteAllText("$Out\user\xcom2\battle.sav", $t)
$cfg = Get-Content "$Data\openxcom_user\options.cfg" -Raw
foreach ($o in $Option) {
  $kv = $o.Split('=', 2)
  $cfg = $cfg -replace ('(?m)^  ' + [regex]::Escape($kv[0]) + ': .*$'), ('  ' + $kv[0] + ': ' + $kv[1])
}
Set-Content -Path "$Out\user\options.cfg" -Value $cfg -Encoding ASCII
$script = 'wait:5000;move:220,256;click:220,256;wait:2000;move:80,92;click:80,92;wait:1000;' + $Delphi
if (Test-Path "$Out\sounds.txt") { Remove-Item "$Out\sounds.txt" }
Push-Location "$Out\delphi"
$p = Start-Process "$Root\bin\Win32\Release\OpenXcom\Xcom32.exe" -ArgumentList "-data `"$Data\openxcom`" -game `"$Data\TFTD`" -user `"$Out\user`" -soundlog `"$Out\sounds.txt`" -script $script" -RedirectStandardError "$Out\delphi\stderr.txt" -RedirectStandardOutput "$Out\delphi\stdout.txt" -PassThru -Wait
Pop-Location
Get-Content "$Out\delphi\stderr.txt", "$Out\delphi\stdout.txt"
if (Test-Path "$Out\sounds.txt") { Get-Content "$Out\sounds.txt" }
