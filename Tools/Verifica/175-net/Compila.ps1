# Compila ed esegue i due harness della rete di xGreed (issue #175).
#
# 1. NetOriginale: net.pas ORIGINALE cosi' com'e' (Reference\xGreed\Greed\net.pas) con un greedcom finto. Prova che
#    in xGreed le routine di rete sono vuote: nessun pacchetto, nessuna variabile cambiata, greedcom resta nil.
# 2. NetGolden: una unit "net" generata in %TEMP%\NetGolden\src = l'interfaccia ORIGINALE di net.pas (ritagliata
#    dal file, senza cambi) + cinque dichiarazioni per l'harness + il corpo RIPRISTINATO dal commento che in
#    net.pas segue "end." (net_body.inc: il testo del commento completato riga per riga, perche' cosi' com'e' non
#    compila). greedcom_t, pevent_t, player_t, scaleobj_t e le costanti sono quelli veri di protos_h.pas,
#    r_public_h.pas e constant.pas; il resto del gioco e' stubs\harness_net_game.pas. Gli scenari sono quelli del
#    test (Tests\Source\DelphiDoom.Tests.Greed.NetScenarios); l'uscita e' il golden Tests\Data\Greed\net.golden.txt.
#
# Il codice originale resta in Reference\xGreed (sola lettura). Altri harness scrivono in %TEMP%: se piu' agenti
# lavorano insieme, impostare prima $env:TEMP su una cartella propria.
# Uso: .\Compila.ps1 [-Golden ..\..\..\Tests\Data\Greed\net.golden.txt] [-Verbose1]
param(
  [string]$Golden = '',
  [switch]$Verbose1,
  [string]$Riferimento = 'C:\Progetti\DelphiDoom\Reference\xGreed'
)
$radice = Resolve-Path "$PSScriptRoot\..\..\.."
$uscita = Join-Path $env:TEMP 'NetGolden'
New-Item -ItemType Directory -Force $uscita, "$uscita\src", "$uscita\orig" | Out-Null
$dcc = 'C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\dcc32.exe'

# ---- 1. net.pas originale, nessuna riga cambiata ----
$u = "$Riferimento\Greed"
& $dcc -B -Q -CC "-U$u" "-I$Riferimento" "-N0$uscita\orig" "-E$uscita\orig" "-NSSystem;Winapi" "$PSScriptRoot\NetOriginale.dpr" | Select-String 'Error|Fatal'
if ($LASTEXITCODE -ne 0) { Write-Error 'NetOriginale non compila'; exit 1 }
cmd /c "`"$uscita\orig\NetOriginale.exe`""
if ($LASTEXITCODE -ne 0) { exit 1 }

# ---- 2. l'interfaccia originale con il corpo ripristinato dal commento ----
$n = Get-Content "$Riferimento\Greed\net.pas" -Raw
$impl = $n.IndexOf("`nimplementation")
$fine = $n.IndexOf("`nend.")
$commento = $n.IndexOf('(**** TYPES ****)')
if ($impl -lt 0 -or $fine -lt $impl -or $commento -lt $fine) { Write-Error 'net.pas: struttura non riconosciuta'; exit 1 }
# le routine vere dell'originale devono essere vuote: tra "implementation" e "end." solo "begin end;"
$vere = $n.Substring($impl, $fine - $impl)
$corpi = [regex]::Matches($vere, '(?s)\bbegin\b(.*?)\bend;')
foreach ($c in $corpi) { if ($c.Groups[1].Value.Trim() -ne '') { Write-Error 'net.pas: una routine non e'' vuota'; exit 1 } }
$interfaccia = $n.Substring(0, $impl)
$unit = @"
$interfaccia
// ---- GENERATA da Tools\Verifica\175-net\Compila.ps1: fin qui l'interfaccia di Reference\xGreed\Greed\net.pas,
// senza cambi. Seguono le dichiarazioni per l'harness (NetWarpJam e NetEvent sono nel commento dell'originale ma
// non nella sua interfaccia) e il corpo ripristinato dal commento. Non modificare e non mettere nel repository.
procedure NetWarpJam;

procedure NetEvent(const n: integer);

function HarnessPlayerSprite(const n: integer): Pscaleobj_t;

function HarnessPlayerMapSpot(const n: integer): integer;

procedure HarnessClearNet;

implementation

uses
  SysUtils, constant, harness_net_game;

{`$I net_body.inc}

end.
"@
Set-Content "$uscita\src\net.pas" $unit
Write-Host ("net.pas originale: {0} routine vuote; il corpo viene da net_body.inc" -f $corpi.Count)

$u = "$PSScriptRoot\stubs;$uscita\src;$Riferimento\Greed;$radice\Tests\Source"
& $dcc -B -Q -CC "-U$u" "-I$Riferimento;$PSScriptRoot" "-N0$uscita" "-E$uscita" "-NSSystem;Winapi" "$PSScriptRoot\NetGolden.dpr" | Select-String 'Error|Fatal|Warning'
if ($LASTEXITCODE -ne 0) { Write-Error 'NetGolden non compila'; exit 1 }
if ($Golden -eq '') { $Golden = 'nessuno' }
$v = ''
if ($Verbose1) { $v = 'verbose' }
# attraverso cmd: xGreed.inc dichiara {$APPTYPE GUI}
cmd /c "`"$uscita\NetGolden.exe`" `"$Golden`" $v"
exit $LASTEXITCODE
