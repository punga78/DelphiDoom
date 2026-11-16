# Prova della rete di Greed32 su UDP (issue #175): due processi senza finestra sulla stessa macchina giocano la
# stessa mappa come giocatore 0 e giocatore 1, sul trasporto UDP di IdTech1\Net (porte locali), per un numero di tic;
# alla fine ognuno scrive il suo stato (-dump) e lo script controlla che ciascuno sappia dov'e' l'altro:
# la posizione che A ha ricevuto di B (net.1.x, net.1.y) e' quella che B dice di se' (player.x, player.y) entro
# la distanza che un giocatore fa nei tic tra due pacchetti, e viceversa; i nomi sono arrivati.
# Non e' un test della suite: usa la rete vera (127.0.0.1), l'orologio vero e i dati del gioco.
# Uso: .\Prova-Udp.ps1 [-Dati <cartella con GREED.BLO>] [-Mappa 0] [-Tic 700] [-Exe <Greed32.exe>]
param(
  [string]$Dati = 'C:\Progetti\DelphiDoom\Reference\_dati\greed\full',
  [int]$Mappa = 0,
  [int]$Tic = 700,
  [string]$Exe = '',
  [int]$PortaA = 47101,
  [int]$PortaB = 47102
)
$radice = Resolve-Path "$PSScriptRoot\..\..\.."
if ($Exe -eq '') { $Exe = "$radice\bin\Win32\Release\Greed\Greed32.exe" }
if (-not (Test-Path $Exe)) { Write-Error "manca $Exe (Tools\build.bat Greed32)"; exit 1 }
if (-not (Test-Path "$Dati\GREED.BLO")) { Write-Error "manca $Dati\GREED.BLO"; exit 1 }
$uscita = Join-Path $env:TEMP 'GreedUdp'
New-Item -ItemType Directory -Force $uscita | Out-Null
Remove-Item "$uscita\*.txt" -ErrorAction SilentlyContinue
# il giocatore 0 gira, cammina e spara; il giocatore 1 cammina all'indietro, gira e cammina
Set-Content "$uscita\a.script.txt" @('10 east down', '60 east up', '70 north down', '260 north up', '270 weapon2 down', '280 weapon2 up', '300 fire down', '600 fire up')
Set-Content "$uscita\b.script.txt" @('10 south down', '150 south up', '160 west down', '220 west up', '230 north down', '400 north up')
$comuni = @('-data', $Dati, '-play', $Mappa, '-headless', '-ticks', $Tic)
$a = Start-Process $Exe -ArgumentList ($comuni + @('-net', 0, 2, '-netport', $PortaA, '-netpeer', ".127.0.0.1:$PortaB", '-netname', 'Ann',
  '-script', "$uscita\a.script.txt", '-dump', "$uscita\a.txt")) -PassThru -WindowStyle Hidden -RedirectStandardOutput "$uscita\a.out.txt"
$b = Start-Process $Exe -ArgumentList ($comuni + @('-net', 1, 2, '-netport', $PortaB, '-netpeer', ".127.0.0.1:$PortaA", '-netname', 'Bob',
  '-character', 1, '-script', "$uscita\b.script.txt", '-dump', "$uscita\b.txt")) -PassThru -WindowStyle Hidden -RedirectStandardOutput "$uscita\b.out.txt"
# senza leggere l'handle adesso, ExitCode resta vuoto dopo l'uscita
$null = $a.Handle; $null = $b.Handle
$limite = [int](($Tic / 70) + 60) * 1000
if (-not $a.WaitForExit($limite)) { $a.Kill(); Write-Error 'il giocatore 0 non finisce'; }
if (-not $b.WaitForExit($limite)) { $b.Kill(); Write-Error 'il giocatore 1 non finisce'; }
"uscita: A=$($a.ExitCode) B=$($b.ExitCode)"
Get-Content "$uscita\a.out.txt", "$uscita\b.out.txt"
if (-not (Test-Path "$uscita\a.txt") -or -not (Test-Path "$uscita\b.txt")) { Write-Error 'manca un dump'; exit 1 }
function Leggi($file) { $h = @{}; foreach ($r in Get-Content $file) { $i = $r.IndexOf('='); if ($i -gt 0) { $h[$r.Substring(0, $i)] = $r.Substring($i + 1) } }; $h }
$da = Leggi "$uscita\a.txt"; $db = Leggi "$uscita\b.txt"
$errori = 0
function Controlla($cond, $testo) { if ($cond) { "  ok   $testo" } else { "  NO   $testo"; $script:errori++ } }
# un giocatore fa al massimo qualche unita' per tic e dice dov'e' ogni 5 tic: 64 unita' (una casella) di margine
$margine = 64 * 65536
Controlla ($da['net.1.name'] -eq 'Bob') "A conosce il nome di B ($($da['net.1.name']))"
Controlla ($db['net.0.name'] -eq 'Ann') "B conosce il nome di A ($($db['net.0.name']))"
Controlla ([Math]::Abs([long]$da['net.1.x'] - [long]$db['player.x']) -le $margine -and [Math]::Abs([long]$da['net.1.y'] - [long]$db['player.y']) -le $margine) "A sa dov'e' B: $($da['net.1.x']),$($da['net.1.y']) contro $($db['player.x']),$($db['player.y'])"
Controlla ([Math]::Abs([long]$db['net.0.x'] - [long]$da['player.x']) -le $margine -and [Math]::Abs([long]$db['net.0.y'] - [long]$da['player.y']) -le $margine) "B sa dov'e' A: $($db['net.0.x']),$($db['net.0.y']) contro $($da['player.x']),$($da['player.y'])"
Controlla ($da['net.1.chartype'] -eq '1') "A sa che B e' il personaggio 1"
Controlla ([int]$da['tics'] -ge $Tic -and [int]$db['tics'] -ge $Tic) "tutti e due hanno giocato $Tic tic (A $($da['tics']), B $($db['tics']))"
"dump in $uscita"
exit $errori
