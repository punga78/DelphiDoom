# Compila ed esegue il confronto tic per tic tra il menu ORIGINALE di xGreed (menu.pas, d_font.pas, d_video.pas e
# loadscreen di intro.pas) e TGreedMenu di Libs\Greed sugli scenari di
# Tests\Source\DelphiDoom.Tests.Greed.MenuScenarios (issue #175). Il codice originale resta in Reference\xGreed (sola
# lettura):
#   menu.pas (con un cast, vedi sotto), d_font.pas, d_video.pas  copiati come sono in %TEMP%\MenuParity\src (devono precedere gli stub
#                                      omonimi degli altri harness nel percorso di ricerca)
#   intro.pas     unit generata: loadscreen ritagliata senza cambi; Wait chiama HarnessTic (stubs\d_ints.pas) una volta
#                 per tic: e' il punto in cui l'originale, che blocca nei suoi cicli, viene pilotato e fotografato
#   raven.pas     unit generata: le variabili dell'interfaccia
#   i_video.pas   unit generata: I_SetPalette (rinominata I_SetPalette_Cut: l'involucro tiene l'ultima palette data),
#                 I_GetPalette e I_TranslateBuffer ritagliate; niente DirectDraw
#   g_delphi.pas  copia con i soli cambi che Delphi 11 richiede (FormatSettings)
# Il resto sono gli stub di stubs\, spawn e net di ..\175-hud\stubs, d_misc e i_windows di ..\175-render\stubs; il
# renderer (r_*) si compila com'e'. Le copie generate e l'eseguibile stanno in %TEMP%\MenuParity, fuori dal repository.
# Uso: .\Compila.ps1 [-Dati <cartella con GREED.BLO>] [-Golden <file>]
#   senza -Dati usa l'archivio sintetico degli scenari (font e immagini generati)
param(
  [string]$Dati = 'sintetico',
  [string]$Golden = 'nessuno',
  [string]$Riferimento = 'C:\Progetti\DelphiDoom\Reference\xGreed'
)
$radice = Resolve-Path "$PSScriptRoot\..\..\.."
$uscita = Join-Path $env:TEMP 'MenuParity'
New-Item -ItemType Directory -Force $uscita, "$uscita\src" | Out-Null

function Ritaglia([string]$testo, [string]$da, [string]$a, [int]$inizioRicerca) {
  $inizio = $testo.IndexOf($da, $inizioRicerca)
  if ($inizio -lt 0) { throw "non trovato: $da" }
  $fine = $testo.IndexOf($a, $inizio + $da.Length)
  if ($fine -lt 0) { throw "non trovato: $a" }
  return $testo.Substring($inizio, $fine - $inizio)
}

$g = Get-Content "$Riferimento\Base\g_delphi.pas" -Raw
$g = $g -replace '(?<![\.\w])ThousandSeparator', 'FormatSettings.ThousandSeparator' -replace '(?<![\.\w])DecimalSeparator', 'FormatSettings.DecimalSeparator'
Set-Content "$uscita\src\g_delphi.pas" $g
foreach ($f in 'd_font.pas', 'd_video.pas') { Copy-Item "$Riferimento\Greed\$f" "$uscita\src\$f" -Force }
# menu.pas: l'originale e' scritto per Delphi 7 (char a 8 bit); l'unico cambio e' il cast che Delphi 11 richiede dove
# un carattere va dentro una string[22]
$m = Get-Content "$Riferimento\Greed\menu.pas" -Raw
$cast = 'savedir[menucursor][Length(savedir[menucursor])] := lastascii'
if (-not $m.Contains($cast)) { throw 'menu.pas: riga del carattere non trovata' }
Set-Content "$uscita\src\menu.pas" $m.Replace($cast, 'savedir[menucursor][Length(savedir[menucursor])] := AnsiChar(lastascii)')

# i_video: la palette e la traduzione dello zero
$i = Get-Content "$Riferimento\Base\i_video.pas" -Raw
$impl = $i.IndexOf("`nimplementation")
$palette = Ritaglia $i 'procedure I_SetPalette(const palette: PByteArray);' "var`r`n  NATIVEWIDTH" $impl
$palette = $palette.Replace('procedure I_SetPalette(const palette: PByteArray);', 'procedure I_SetPalette_Cut(const palette: PByteArray);')
$traduci = Ritaglia $i 'procedure I_TranslateBuffer(const buf: PByteArray; const sz: integer);' "`r`nend." $impl
Set-Content "$uscita\src\i_video.pas" @"
unit i_video;
// GENERATA da Tools\Verifica\175-menu\Compila.ps1: I_SetPalette (qui I_SetPalette_Cut), I_GetPalette e
// I_TranslateBuffer sono ritagliate da Reference\xGreed\Base\i_video.pas. Non modificare, non mettere nel repository.
interface
uses g_delphi;
var
  approx_zero: byte = 0;
  curpal: array[0..255] of LongWord;
  // the bytes given to the last I_SetPalette
  LastPalette: packed array[0..767] of byte;
procedure I_SetPalette(const palette: PByteArray);
procedure I_GetPalette(const palette: PByteArray);
procedure I_TranslateBuffer(const buf: PByteArray; const sz: integer);
implementation
$palette
procedure I_SetPalette(const palette: PByteArray);
begin
  Move(palette^, LastPalette, 768);
  I_SetPalette_Cut(palette);
end;

$traduci
end.
"@

# intro: loadscreen com'e', Wait pilotata dall'harness
$n = Get-Content "$Riferimento\Greed\intro.pas" -Raw
$impl = $n.IndexOf("`nimplementation")
$schermo = Ritaglia $n 'function loadscreen(const s: string): boolean;' "`r`nprocedure Wait(" $impl
Set-Content "$uscita\src\intro.pas" @"
{`$I xGreed.inc}
unit intro;
// GENERATA da Tools\Verifica\175-menu\Compila.ps1: loadscreen e' ritagliata, senza cambi, da
// Reference\xGreed\Greed\intro.pas; Wait non aspetta: chiama HarnessTic una volta per tic. Non modificare, non mettere
// nel repository.
interface
var
  colors: array[0..767] of byte;
  nextchar: boolean;
  nointro, nobriefing: boolean;
function loadscreen(const s: string): boolean;
procedure Wait(time: integer; sleeptime: integer = 0);
implementation
uses
  g_delphi, d_video, d_disk, d_ints, r_render;

$schermo
procedure Wait(time: integer; sleeptime: integer = 0);
var
  i: integer;
begin
  for i := 1 to time do
    HarnessTic;
end;

end.
"@

# raven: le variabili
$r = Get-Content "$Riferimento\Greed\raven.pas" -Raw
$impl = $r.IndexOf("`nimplementation")
$v1 = $r.IndexOf("const`r`n  MOVEUNIT")
$v2 = $r.IndexOf('procedure TimeUpdate;', $v1)
if ($impl -lt 0 -or $v1 -lt 0 -or $v2 -lt 0 -or $v2 -gt $impl) { Write-Error 'raven.pas: interfaccia non trovata'; exit 1 }
$variabili = $r.Substring($v1, $v2 - $v1)
Set-Content "$uscita\src\raven.pas" @"
{`$I xGreed.inc}
unit raven;
// GENERATA da Tools\Verifica\175-menu\Compila.ps1: le variabili sono ritagliate, senza cambi, da
// Reference\xGreed\Greed\raven.pas. Non modificare, non mettere nel repository.
interface
uses
  g_delphi, d_ints_h, d_font, d_video, protos_h, r_public_h;

$variabili
procedure TimeUpdate;

implementation

procedure TimeUpdate;
begin
end;

end.
"@

$dcc = 'C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\dcc32.exe'
$libs = 'Greed', 'Platform', 'MathCore', 'Logging', 'Clock', 'Video', 'Png', 'Zlib' | ForEach-Object { "$radice\Libs\$_" }
$u = "$PSScriptRoot\stubs;$uscita\src;$PSScriptRoot\..\175-hud\stubs;$PSScriptRoot\..\175-render\stubs;$Riferimento\Greed;$Riferimento\Base;" + ($libs -join ';') + ";$radice\Tests\Source"
# -CC: xGreed.inc dichiara {$APPTYPE GUI}, l'harness e' un programma da console
& $dcc -B -Q -CC -H- -W- "-U$u" "-I$Riferimento;$uscita\src" "-N0$uscita" "-E$uscita" "-NSSystem;Winapi" "$PSScriptRoot\MenuParity.dpr" | Select-String 'Error|Fatal'
if ($LASTEXITCODE -ne 0) { exit 1 }
# attraverso cmd: l'eseguibile ha il sottosistema GUI di xGreed.inc e PowerShell non ne aspetta l'uscita
cmd /c "`"$uscita\MenuParity.exe`" `"$Dati`" `"$Golden`""
exit $LASTEXITCODE
