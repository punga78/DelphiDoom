<#
.SYNOPSIS
  Prova Warcraft32 con la finestra vera (issue #200): lo avvia, gli manda mouse e tastiera di Windows (SendInput) dal
  titolo alla mappa della prima missione degli umani, salva con F5, gioca ancora, carica con F9 e controlla il titolo
  della finestra e il file dello slot. Serve un desktop acceso e attivo (non funziona dietro un servizio o un
  desktop bloccato). Salva una fotografia dello schermo se si da' -Fotografia.

.PARAMETER Dati
  La cartella col DATA.WAR.
.PARAMETER Exe
  Warcraft32.exe da provare.
#>
param(
  [Parameter(Mandatory = $true)][string]$Dati,
  [Parameter(Mandatory = $true)][string]$Exe,
  [string]$Fotografia = ''
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class WarInput {
  [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X; public int Y; }
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint flags, int dx, int dy, uint data, UIntPtr extra);
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
  [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
}
'@

function Clic([IntPtr]$Finestra, [int]$X, [int]$Y, [int]$Scala) {
  $p = New-Object WarInput+POINT
  $p.X = $X * $Scala + [int]($Scala / 2); $p.Y = $Y * $Scala + [int]($Scala / 2)
  [void][WarInput]::ClientToScreen($Finestra, [ref]$p)
  [void][WarInput]::SetCursorPos($p.X, $p.Y)
  Start-Sleep -Milliseconds 150
  [WarInput]::mouse_event(2, 0, 0, 0, [UIntPtr]::Zero)
  Start-Sleep -Milliseconds 120
  [WarInput]::mouse_event(4, 0, 0, 0, [UIntPtr]::Zero)
}
function Tasto([byte]$Vk) {
  [WarInput]::keybd_event($Vk, 0, 0, [UIntPtr]::Zero)
  Start-Sleep -Milliseconds 120
  [WarInput]::keybd_event($Vk, 0, 2, [UIntPtr]::Zero)
}

$scala = 3
$cartella = Split-Path -Parent (Resolve-Path $Exe).Path
$slot = Join-Path $cartella 'SAVES\quick.war1sav'
if (Test-Path $slot) { Remove-Item -LiteralPath $slot }
$p = Start-Process -FilePath $Exe -ArgumentList @('-data', $Dati, '-scale', $scala, '-quitafter', 3600) -PassThru
try {
  Start-Sleep -Seconds 2
  $p.Refresh()
  $h = $p.MainWindowHandle
  if ($h -eq [IntPtr]::Zero) { throw 'la finestra non si e'' aperta' }
  [void][WarInput]::SetForegroundWindow($h)
  Start-Sleep -Seconds 4      # il logo, poi il menu
  Clic $h 150 90 $scala       # Start a new game
  Start-Sleep -Milliseconds 800
  Clic $h 150 111 $scala      # Human campaign
  Start-Sleep -Milliseconds 1800   # il secondo di nero e il briefing
  Tasto 0x0D                  # Invio: salta il briefing
  Start-Sleep -Milliseconds 1800   # il secondo di nero e la mappa
  Start-Sleep -Seconds 2
  Tasto 0x74                  # F5: salva
  Start-Sleep -Milliseconds 500
  $p.Refresh()
  $titolo1 = $p.MainWindowTitle
  $salvato = Test-Path $slot
  if ($Fotografia -ne '') {
    $s = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $b = New-Object System.Drawing.Bitmap $s.Width, $s.Height
    [System.Drawing.Graphics]::FromImage($b).CopyFromScreen(0, 0, 0, 0, $b.Size)
    $b.Save($Fotografia)
  }
  Start-Sleep -Seconds 2
  Tasto 0x78                  # F9: carica
  Start-Sleep -Seconds 2
  $p.Refresh()
  $titolo2 = $p.MainWindowTitle
  "dopo F5: '$titolo1', file dello slot: $salvato ($((Get-Item $slot -ErrorAction SilentlyContinue).Length) byte)"
  "dopo F9: '$titolo2'"
  $ok = $salvato -and $titolo1 -like '*Game saved*' -and $titolo2 -like '*Game loaded*'
  if ($ok) { 'PROVA SUPERATA' } else { 'PROVA FALLITA'; $global:LASTEXITCODE = 1 }
}
finally {
  if (-not $p.HasExited) { [void]$p.CloseMainWindow(); if (-not $p.WaitForExit(5000)) { $p.Kill() } }
}
