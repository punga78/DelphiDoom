<#
  Ripete un -timedemo di un gioco N volte (con il lock globale di Esegui-gioco.ps1) e riepiloga:
  per ogni giro il codice di uscita, la presenza di crash.txt e la riga "timed N gametics in M realtics"
  trovata nei log. Serve per la #147/#148: demo1 di Doom32 andava in access violation all'uscita.

  Uso (dalla radice del worktree, dopo Tools\build.bat Doom32 Release):
    powershell -NoProfile -File Tools\Verifica\148\Ripeti-timedemo.ps1 -Giri 10 -Demo demo1
    powershell -NoProfile -File Tools\Verifica\148\Ripeti-timedemo.ps1 -Giri 3 -Demo demo2
    powershell -NoProfile -File Tools\Verifica\148\Ripeti-timedemo.ps1 -Giri 3 -Demo demo3

  Risultato atteso (demo1, 10 giri): nessuna riga con crash=True; "exit=" uguale in tutti i giri; i gametics
  uguali tra i giri (e uguali a quelli del vecchio eseguibile: demo3 = 2134 gametics); nessun access violation.
  Non cambia nessun file del repository (scrive solo i log del gioco e un riepilogo in logs\verifica148.txt).
#>
param(
  [int]$Giri = 10,
  [string]$Demo = 'demo1',
  [string]$Exe = 'bin\Win32\Release\Doom\Doom32.exe',
  [string]$Iwad = 'DOOM1.WAD',
  [string]$Argomenti = '',
  [int]$SecondiMassimi = 600
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
Set-Location $root
$exePath = (Resolve-Path -LiteralPath $Exe).Path
$workDir = Split-Path -Parent $exePath
$logDir = Join-Path $workDir 'DATA\LOGS'
$runner = Join-Path $root 'Tools\Esegui-gioco.ps1'
$summary = Join-Path $root 'logs\verifica148.txt'
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $summary) | Out-Null

$gameArgs = "-iwad $Iwad -timedemo $Demo -nosound -nomusic $Argomenti"
$lines = @()
for ($i = 1; $i -le $Giri; $i++) {
  $result = & powershell -NoProfile -File $runner -Exe $exePath -Arguments $gameArgs -WorkDir $workDir `
    -Seconds $SecondiMassimi -StopWhenExited
  $timed = ''
  if (Test-Path -LiteralPath $logDir) {
    $recent = Get-ChildItem -LiteralPath $logDir -Filter '*.txt' |
      Sort-Object LastWriteTime -Descending | Select-Object -First 4
    foreach ($file in $recent) {
      $hit = Select-String -LiteralPath $file.FullName -Pattern 'timed\s+\d+\s+gametics' | Select-Object -Last 1
      if ($hit) { $timed = $hit.Line.Trim(); break }
    }
  }
  $line = "giro $i/$Giri $Demo : $result | $timed"
  Write-Output $line
  $lines += $line
}
$lines | Set-Content -LiteralPath $summary -Encoding UTF8
$bad = ($lines | Where-Object { $_ -match 'crash=True' -or $_ -match 'alive=True' }).Count
Write-Output ("RIEPILOGO: {0} giri, {1} con crash o senza uscita" -f $Giri, $bad)
if ($bad -gt 0) { exit 1 }
