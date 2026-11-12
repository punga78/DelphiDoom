# Compila ed esegue il codice ORIGINALE di xGreed degli script e della vita di una mappa e scrive i golden che i test
# di TGreedEvents e di TGreedMapSession confrontano con la libreria (issue #175). Due programmi:
#   EventsGolden   event.pas (Reference\xGreed\Greed\event.pas, non modificato) sugli scenari di
#                  Tests\Source\DelphiDoom.Tests.Greed.EventScenarios -> events.golden.txt e, con i dati del gioco
#                  completo, events.full.golden.txt
#   SessionGolden  newmap, LoadNewMap, ActivateSpritesFromMap, resetengine, respawnplayer, SaveGame e LoadGame di
#                  utils.pas (ritagliati dall'originale) con event.pas, sugli scenari di
#                  Tests\Source\DelphiDoom.Tests.Greed.SessionScenarios -> mapsession.golden.txt; e loadweapon
#                  (ritagliata, con il nome H_loadweapon) per una sequenza di armi -> weaponpictures.golden.txt
# Il codice originale resta in Reference\xGreed (sola lettura): event.pas, constant.pas, protos_h.pas, r_public_h.pas,
# r_refdef.pas e d_ints_h.pas si compilano come sono. Copie generate, fuori dal repository:
#   g_delphi.pas      con i soli cambi che Delphi 11 richiede (FormatSettings)
#   scriptengine.pas  con le stringhe a 8 bit che aveva in Delphi 7 (string -> AnsiString, PChar -> PAnsiChar,
#                     char -> AnsiChar): compilato com'e' con Delphi 11 copia meta' del testo (Move di Length
#                     caratteri da una stringa UTF-16) e non legge nessuno script; e con la stampa delle righe
#                     attorno a un errore che non esce dalla lista (vedi sotto)
#   r_public.pas      le funzioni del mondo (RF_ClearWorld .. RF_GetCeilingZ) ritagliate dall'originale
#   session\raven.pas le variabili dell'interfaccia di raven.pas, ritagliate (solo per SessionGolden)
#   session\utils.pas le variabili dell'interfaccia e le routine di utils.pas elencate sopra, ritagliate (solo per
#                     SessionGolden); selectsong, MissionBriefing, EndGame1..3, LoadTextures, loadweapon e ResetMouse
#                     sono chiamate annotate nel registro (utils.mid.txt)
# Il resto sono gli stub di stubs\ (e d_ints, d_misc, r_conten di ..\175-spawn\stubs): le variabili globali e le
# chiamate verso le parti che non sono di questo pezzo (SpawnSprite, DemandLoadMonster, SoundEffect, ActivationSound,
# DoPlayFLI, FN_PrintCentered, StartWait, UpdateWait, EndWait, StopMusic) annotate nel registro; d_disk da' i nomi e i
# testi dei lump degli scenari oppure, con -Dati, quelli del GREED.BLO del gioco completo letto con la libreria.
# Le copie generate, gli eseguibili e i salvataggi di prova stanno in %TEMP%\EventsGolden.
# Uso: .\Compila.ps1 [-Golden <file>] [-GoldenSessione <file>] [-GoldenArmi <file>] [-Dati <cartella di GREED.BLO> [-GoldenCompleto <file>]]
param(
  [string]$Golden = '',
  [string]$GoldenCompleto = '',
  [string]$GoldenSessione = '',
  [string]$GoldenArmi = '',
  [string]$Dati = 'C:\Progetti\DelphiDoom\Reference\_dati\greed\full',
  [string]$Riferimento = 'C:\Progetti\DelphiDoom\Reference\xGreed'
)
$radice = Resolve-Path "$PSScriptRoot\..\..\.."
if ($Golden -eq '') { $Golden = Join-Path $radice 'Tests\Data\Greed\events.golden.txt' }
if ($GoldenCompleto -eq '') { $GoldenCompleto = Join-Path $radice 'Tests\Data\Greed\events.full.golden.txt' }
if ($GoldenSessione -eq '') { $GoldenSessione = Join-Path $radice 'Tests\Data\Greed\mapsession.golden.txt' }
if ($GoldenArmi -eq '') { $GoldenArmi = Join-Path $radice 'Tests\Data\Greed\weaponpictures.golden.txt' }
$uscita = Join-Path $env:TEMP 'EventsGolden'
New-Item -ItemType Directory -Force $uscita, "$uscita\src", "$uscita\session", "$uscita\dcu_e", "$uscita\dcu_s" | Out-Null

function Ritaglia([string]$testo, [string]$da, [string]$a, [int]$inizioRicerca) {
  $inizio = $testo.IndexOf($da, $inizioRicerca)
  if ($inizio -lt 0) { throw "non trovato: $da" }
  $fine = $testo.IndexOf($a, $inizio)
  if ($fine -lt 0) { throw "non trovato: $a" }
  return $testo.Substring($inizio, $fine - $inizio)
}

$g = Get-Content "$Riferimento\Base\g_delphi.pas" -Raw
$g = $g -replace '(?<![\.\w])ThousandSeparator', 'FormatSettings.ThousandSeparator' -replace '(?<![\.\w])DecimalSeparator', 'FormatSettings.DecimalSeparator'
Set-Content "$uscita\src\g_delphi.pas" $g
$s = Get-Content "$Riferimento\Base\scriptengine.pas" -Raw
$s = $s -creplace '\bPChar\b', 'PAnsiChar' -creplace '\bchar\b', 'AnsiChar' -creplace '\bstring\b', 'AnsiString'
# ScriptPrintLineError (stampa le righe attorno a un errore dello script) legge una riga oltre la lista quando l'errore
# e' nelle ultime righe ("x2 := lst.Count") e l'originale muore con EStringListError dentro la stampa; dove finisce
# la lista dipende dalla memoria dopo il testo (il buffer non ha terminatore). Qui la stampa si ferma all'ultima
# riga: la libreria non stampa e non muore (differenza dichiarata), il resto della lettura si confronta
if (-not $s.Contains('x2 := lst.Count;')) { Write-Error 'scriptengine.pas: ScriptPrintLineError non trovata'; exit 1 }
$s = $s.Replace('x2 := lst.Count;', 'x2 := lst.Count - 1;')
# la variabile che ScriptError passa a sprintf (var s: string) resta una string
$s = $s -replace 's: AnsiString;(\s+begin\s+sprintf)', 's: string;$1'
Set-Content "$uscita\src\scriptengine.pas" $s
$r = Get-Content "$Riferimento\Greed\r_public.pas" -Raw
$mondo = Ritaglia $r 'procedure RF_ClearWorld;' 'procedure RF_SetActionHook' $r.IndexOf('implementation')
Set-Content "$uscita\src\r_public.pas" ((Get-Content "$PSScriptRoot\..\175-spawn\r_public.head.txt" -Raw) + $mondo + "`r`nend.`r`n")

# raven: le variabili dell'interfaccia
$v = Get-Content "$Riferimento\Greed\raven.pas" -Raw
$variabili = Ritaglia $v 'const' 'procedure TimeUpdate;' $v.IndexOf('interface')
Set-Content "$uscita\session\raven.pas" ((Get-Content "$PSScriptRoot\raven.head.txt" -Raw) + $variabili + "implementation`r`nend.`r`n")

# utils: le variabili dell'interfaccia e le routine della vita di una mappa
$t = Get-Content "$Riferimento\Greed\utils.pas" -Raw
$impl = $t.IndexOf('implementation')
$globali = Ritaglia $t '(**** VARIABLES ****)' 'procedure KillSprite(' $t.IndexOf('interface')
$nome = Ritaglia $t 'function SAVENAME: string;' '(**** FUNCTIONS ****)' $impl
$sprite = Ritaglia $t 'procedure ActivateSpritesFromMap;' 'procedure FreeWallPosts;' $impl
$inizioArmi = $t.IndexOf('  weaponlump: integer = 0;', $impl)
if ($inizioArmi -lt 0) { Write-Error 'utils.pas: weaponlump non trovata'; exit 1 }
$inizioMappa = $t.IndexOf('procedure DoLoadMapData(', $impl)
$mappa = $t.Substring($inizioMappa, $t.LastIndexOf('var', $inizioArmi) - $inizioMappa)
$salva = Ritaglia $t 'procedure SaveGame(' 'procedure selectsong(' $impl
$nuova = Ritaglia $t 'procedure newmap(' 'procedure heal(' $impl
$rinasce = Ritaglia $t 'procedure respawnplayer;' 'procedure MissionBriefing(' $impl
# loadweapon con un altro nome (le routine sopra chiamano quella che annota la chiamata) e le sue due variabili,
# dichiarate come nell'originale
$arma = Ritaglia $t 'procedure loadweapon(const n: integer);' '// this must be updated' $impl
$arma = "var`r`n  weaponlump: integer = 0;`r`n  numweaponlumps: integer = 0;`r`n`r`n" + $arma.Replace('procedure loadweapon(const n: integer);', 'procedure H_loadweapon(const n: integer);') + "function H_weaponlump: integer;`r`nbegin`r`n  Result := weaponlump;`r`nend;`r`n`r`nfunction H_numweaponlumps: integer;`r`nbegin`r`n  Result := numweaponlumps;`r`nend;`r`n`r`n"
Set-Content "$uscita\session\utils.pas" ((Get-Content "$PSScriptRoot\utils.head.txt" -Raw) + $globali + (Get-Content "$PSScriptRoot\utils.mid.txt" -Raw) + $nome + $sprite + $mappa + $salva + $nuova + $rinasce + $arma + "end.`r`n")

$dcc = 'C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\dcc32.exe'
$comuni = "$PSScriptRoot\stubs;$uscita\src;$PSScriptRoot\..\175-spawn\stubs;$Riferimento\Greed;$Riferimento\Base;$radice\Libs\Greed;$radice\Libs\Platform;$radice\Libs\MathCore;$radice\Libs\Logging;$radice\Libs\Clock;$radice\Tests\Source"
# -CC: xGreed.inc dichiara {$APPTYPE GUI}, gli harness sono programmi da console
& $dcc -B -Q -CC -H- -W- "-U$comuni" "-I$Riferimento" "-N0$uscita\dcu_e" "-E$uscita" "-NSSystem;Winapi" "$PSScriptRoot\EventsGolden.dpr" | Select-String 'Error|Fatal'
if ($LASTEXITCODE -ne 0) { exit 1 }
& $dcc -B -Q -CC -H- -W- "-U$uscita\session;$comuni" "-I$Riferimento" "-N0$uscita\dcu_s" "-E$uscita" "-NSSystem;Winapi" "$PSScriptRoot\SessionGolden.dpr" | Select-String 'Error|Fatal'
if ($LASTEXITCODE -ne 0) { exit 1 }
# attraverso cmd: gli eseguibili hanno il sottosistema GUI di xGreed.inc e PowerShell non ne aspetta l'uscita
if (Test-Path (Join-Path $Dati 'GREED.BLO')) {
  cmd /c "`"$uscita\EventsGolden.exe`" `"$Golden`" `"$GoldenCompleto`" `"$Dati`""
} else {
  Write-Host "senza $Dati\GREED.BLO: solo gli scenari sintetici"
  cmd /c "`"$uscita\EventsGolden.exe`" `"$Golden`""
}
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
cmd /c "`"$uscita\SessionGolden.exe`" `"$GoldenSessione`" `"$GoldenArmi`""
exit $LASTEXITCODE
