<#
  Misura a coppie del vecchio contro il nuovo Doom32 per le quattro combinazioni (Win32 e Win64, modi 8 e 32) con
  Tools\Misura-Coppie.ps1 e riassume i verdetti. Il "vecchio" e' una copia di lavoro del commit di partenza con
  Doom32 gia' compilato (Release, Win32 e Win64): per esempio un worktree
  `git worktree add --detach <cartella> <commit>` e `Tools\build.bat Doom32 Release [Win64]`.

  Uso:
    powershell -NoProfile -File Tools\Misura-Giro.ps1 -RadiceVecchia <cartella> [-Coppie 7] [-Demo demo1]
      [-WorkRoot C:\ddparity] [-Riepilogo <file>] [-Piattaforme Win32,Win64] [-Modi 8,32]

  -Piattaforme e -Modi limitano il giro (per ripetere solo una combinazione rifiutata, come fa Tools\Misura-Finale.ps1).
  Il -Riepilogo contiene l'uscita COMPLETA di ogni combinazione (non solo le ultime righe), cosi' si puo' rileggere.
#>
param(
  [Parameter(Mandatory = $true)][string]$RadiceVecchia,
  [int]$Coppie = 7,
  [string]$Demo = 'demo1',
  [string]$WorkRoot = 'C:\ddparity',
  [string]$Riepilogo = '',
  [string[]]$Piattaforme = @('Win32', 'Win64'),
  [int[]]$Modi = @(8, 32)
)
$root = Split-Path -Parent $PSScriptRoot
$env:DD_GAME_PRIORITY = 'Normal'
$righe = @()
$completo = @()
foreach ($piattaforma in $Piattaforme) {
  foreach ($modo in $Modi) {
    $vecchio = Join-Path $RadiceVecchia "bin\$piattaforma\Release\Doom\Doom32.exe"
    $nuovo = Join-Path $root "bin\$piattaforma\Release\Doom\Doom32.exe"
    $uscita = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'Misura-Coppie.ps1') `
      -Vecchio $vecchio -Nuovo $nuovo -Demo $Demo -Coppie $Coppie -Modo $modo `
      -DataRoot (Join-Path $root 'bin') -WorkRoot $WorkRoot 2>&1 | Out-String
    $codice = $LASTEXITCODE
    $verdetto = switch ($codice) { 0 { 'entro il 5%' } 1 { 'OLTRE il 5%' } 3 { 'misura non affidabile' } default { "errore ($codice)" } }
    $righe += "=== $piattaforma modo $modo : $verdetto"
    $righe += ($uscita -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -Last 12)
    $completo += "=== $piattaforma modo $modo : $verdetto"
    $completo += ($uscita -split "`r?`n" | Where-Object { $_.Trim() })
    $righe | Select-Object -Last 14 | ForEach-Object { $_ }
  }
}
if ($Riepilogo -ne '') { $completo | Set-Content -LiteralPath $Riepilogo -Encoding UTF8 }
