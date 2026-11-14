<#
  Esegue un gioco (o uno strumento) di DelphiDoom con un lock globale: una sola esecuzione per volta
  in tutto il computer, anche tra agenti e worktree diversi. Evita il sovraccarico della CPU e i
  conflitti sul video quando girano piu' giochi insieme (storico: DirectDraw, tolto con la #189).

  Uso:
    powershell -NoProfile -File C:\Progetti\DelphiDoom\Tools\Esegui-gioco.ps1 `
      -Exe <percorso\Doom32.exe> -Arguments '-iwad DOOM1.WAD -warp 1 1 -devparm -nomusic' `
      [-WorkDir <cartella>] [-Seconds 25] [-StopWhenExited] [-WaitLockSeconds 3600]

  Gli eseguibili stanno in bin\<Piattaforma>\<Configurazione>\<Gioco> (es. bin\Win32\Release\Doom\Doom32.exe): il gioco
  trova da solo i dati in bin\<Gioco> (o in -data <cartella> negli -Arguments); crash.txt resta accanto all'eseguibile.

  Cosa fa: aspetta il lock, cancella crash.txt nella cartella di lavoro, avvia il processo a priorita'
  bassa, lo lascia girare -Seconds secondi (o fino alla sua fine con -StopWhenExited), lo chiude per
  PID (mai per nome), rilascia il lock e stampa una riga: vivo/uscito, codice di uscita, presenza di
  crash.txt, tempo di attesa del lock.
#>
param(
  [Parameter(Mandatory = $true)][string]$Exe,
  [string]$Arguments = '',
  [string]$WorkDir = '',
  [int]$Seconds = 25,
  [switch]$StopWhenExited,
  [int]$WaitLockSeconds = 3600
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $Exe)) { throw "Eseguibile non trovato: $Exe" }
if ($WorkDir -eq '') { $WorkDir = Split-Path -Parent (Resolve-Path -LiteralPath $Exe).Path }

$mutex = New-Object System.Threading.Mutex($false, 'Global\DelphiDoomEsecuzioneGioco')
$waited = [Diagnostics.Stopwatch]::StartNew()
$acquired = $false
try {
  try {
    $acquired = $mutex.WaitOne([TimeSpan]::FromSeconds($WaitLockSeconds))
  } catch [System.Threading.AbandonedMutexException] {
    $acquired = $true   # un'esecuzione precedente e' stata interrotta: il lock e' nostro
  }
  if (-not $acquired) {
    Write-Output "LOCK-NON-OTTENUTO dopo $([int]$waited.Elapsed.TotalSeconds) s: un'altra esecuzione e' ancora in corso"
    exit 2
  }
  $lockWait = [int]$waited.Elapsed.TotalSeconds

  $crash = Join-Path $WorkDir 'crash.txt'
  Remove-Item -LiteralPath $crash -ErrorAction SilentlyContinue

  $process = Start-Process -FilePath $Exe -ArgumentList $Arguments -WorkingDirectory $WorkDir -PassThru
  try { $process.PriorityClass = 'BelowNormal' } catch { }

  $run = [Diagnostics.Stopwatch]::StartNew()
  if ($StopWhenExited) {
    $null = $process.WaitForExit($Seconds * 1000)
  } else {
    Start-Sleep -Seconds $Seconds
  }

  $alive = -not $process.HasExited
  $code = ''
  if ($alive) {
    Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
    $null = $process.WaitForExit(5000)
  } else {
    $code = $process.ExitCode
  }
  $crashed = Test-Path -LiteralPath $crash
  Write-Output ("{0} alive={1} exit={2} crash={3} secondi={4} attesa_lock={5}" -f
    (Split-Path -Leaf $Exe), $alive, $code, $crashed, [int]$run.Elapsed.TotalSeconds, $lockWait)
}
finally {
  if ($acquired) { $mutex.ReleaseMutex() }
  $mutex.Dispose()
}
