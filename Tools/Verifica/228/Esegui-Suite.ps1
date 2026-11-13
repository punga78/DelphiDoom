# Issue #228 (AudioMix): compila ed esegue le quattro suite che coprono il mixing e stampa trovati/passati.
# Prima/dopo lo spostamento dei tre mixer i numeri di War, Greed e XcomEngine erano
#   War 306/305 (1 ignorato), Greed 1003/1003, XcomEngine 1151/1151;
# dopo, le stesse suite hanno solo i test di parita' in piu' (War +2, Greed +2, XcomEngine +2) e AudioMix e' nuova.
# In un worktree sotto .claude\worktrees serve DCC_UnitSearchPath con la cartella DUnitX\Source (vedi Libs\War\CLAUDE.md).
param(
  [string[]]$Progetti = @('DelphiDoom.Tests.AudioMix', 'DelphiDoom.Tests.War', 'DelphiDoom.Tests.Greed', 'DelphiDoom.Tests.XcomEngine'),
  [string]$Configurazione = 'Release'
)

$radice = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
foreach ($progetto in $Progetti) {
  & cmd /c "`"$radice\Tools\build.bat`" $progetto $Configurazione" | Out-Null
  $log = Join-Path $radice "logs\$progetto.log"
  if (Select-String -Path $log -Pattern 'error [EF]\d+' -Quiet) {
    Write-Host "$progetto : COMPILAZIONE FALLITA (vedi $log)"
    continue
  }
  $esito = & (Join-Path $radice "bin\Tests\$progetto.exe") 2>&1 | Select-String -Pattern 'Tests (Found|Ignored|Passed|Failed|Errored)'
  Write-Host "$progetto : $($esito -join ' | ')"
}
