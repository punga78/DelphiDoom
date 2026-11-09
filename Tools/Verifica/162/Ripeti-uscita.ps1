<#
  Issue #162/#147: avvia un gioco N volte, lo lascia giocare -Play secondi e lo chiude come I_Quit
  (PostMessage WM_DESTROY alla finestra principale: il gioco ignora WM_CLOSE). Stampa una riga per
  avvio: codice di uscita, "hung" (non e' uscito in 15 s), presenza di crash.txt (copiato accanto a -Out).
  Usa il lock globale di Esegui-gioco.ps1. Non chiudere prima che il gioco abbia creato la finestra di
  gioco (dopo il caricamento): la finestra di avvio ha un altro handle e il messaggio va perso.
  Uso: -Exe bin\Heretic\Heretic32.exe -Args2 '-iwad HERETIC1.WAD -warp 1 1' -N 30 -Play 5 -Out <prefisso>
#>
param([string]$Exe,[string]$Args2,[int]$N=20,[int]$Play=6,[string]$Out)
Add-Type 'using System;using System.Runtime.InteropServices;public class W{[DllImport("user32.dll")]public static extern bool PostMessage(IntPtr h,uint m,IntPtr w,IntPtr l);}' 
$dir = Split-Path -Parent $Exe
$mutex = New-Object System.Threading.Mutex($false,'Global\DelphiDoomEsecuzioneGioco')
$res=@()
try { try { $null=$mutex.WaitOne([TimeSpan]::FromSeconds(3600)) } catch [System.Threading.AbandonedMutexException] {} 
for($i=1;$i -le $N;$i++){
  Remove-Item "$dir\crash.txt" -ErrorAction SilentlyContinue
  $p = Start-Process $Exe -ArgumentList $Args2 -WorkingDirectory $dir -PassThru
  Start-Sleep -Seconds $Play
  $closed=$false
  if(-not $p.HasExited){ $p.Refresh(); $closed=[W]::PostMessage($p.MainWindowHandle,2,[IntPtr]::Zero,[IntPtr]::Zero) }
  $null=$p.WaitForExit(15000)
  $hung = -not $p.HasExited
  if($hung){ Stop-Process -Id $p.Id -Force; $null=$p.WaitForExit(5000) }
  $crash = Test-Path "$dir\crash.txt"
  $line = "run=$i closed=$closed exit=$($p.ExitCode) hung=$hung crash=$crash"
  $res += $line; $line
  if($crash){ Copy-Item "$dir\crash.txt" "$Out.crash$i.txt"; Copy-Item "$dir\*.map" (Split-Path $Out) -ErrorAction SilentlyContinue }
}
} finally { $mutex.ReleaseMutex(); $mutex.Dispose() }

