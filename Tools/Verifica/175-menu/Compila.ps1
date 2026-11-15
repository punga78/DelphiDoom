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
# -Parte fli: FliParity.dpr, i filmati (playfli.pas ORIGINALE copiato com'e') contro TGreedFliPlayer; -Dati e' allora
# la cartella dei *.FLI del gioco.
# -Parte intro: IntroParity.dpr, dointro (intro.pas), MissionBriefing e EndGame1..3 (utils.pas) ORIGINALI ritagliati
# contro TGreedIntro, TGreedBriefing e TGreedEndGame sugli scenari di Tests\Source\DelphiDoom.Tests.Greed.IntroScenarios;
# -Dati e' la cartella di GREED.BLO (golden intro.full / intro.demo20), -Golden va dato con percorso assoluto.
# Uso: .\Compila.ps1 [-Parte menu|fli|intro] [-Dati <cartella con GREED.BLO>] [-Golden <file>]
#   senza -Dati usa l'archivio sintetico degli scenari (font e immagini generati)
param(
  [ValidateSet('menu', 'fli', 'intro')][string]$Parte = 'menu',
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
foreach ($f in 'd_font.pas', 'd_video.pas', 'playfli.pas') { Copy-Item "$Riferimento\Greed\$f" "$uscita\src\$f" -Force }
# menu.pas: l'originale e' scritto per Delphi 7 (char a 8 bit); l'unico cambio e' il cast che Delphi 11 richiede dove
# un carattere va dentro una string[22]
$m = Get-Content "$Riferimento\Greed\menu.pas" -Raw
$cast = 'savedir[menucursor][Length(savedir[menucursor])] := lastascii'
if (-not $m.Contains($cast)) { throw 'menu.pas: riga del carattere non trovata' }
Set-Content "$uscita\src\menu.pas" $m.Replace($cast, 'savedir[menucursor][Length(savedir[menucursor])] := AnsiChar(lastascii)')

# d_ints: il mouse ORIGINALE (MouseGetClick, ResetMouse, INT_ReadMouse, MouseHide, MouseShow e le variabili mlastx,
# mlasty, mflags) ritagliato in un file incluso dallo stub stubs\d_ints.pas. Due soli cambi di nome: ResetMouse
# diventa ResetMouse_Cut (lo stub tiene il nome ResetMouse per annotare nel registro le chiamate del menu, come
# prima), e la chiamata dentro INT_ReadMouse va a ResetMouse_Cut (non e' una chiamata del menu). Cio' che il mouse
# chiede a Windows (getcursorposfunc, setcursorposfunc, i tre bottoni, I_WindowWidth) lo da' lo scenario
$d = Get-Content "$Riferimento\Greed\d_ints.pas" -Raw
$dimpl = $d.IndexOf("`nimplementation")
$click = Ritaglia $d 'function MouseGetClick(var x, y: smallint): boolean;' "type`r`n  setcursorposfunc_t" $dimpl
$reset = Ritaglia $d "var`r`n// Mouse support" 'procedure M_InitMouse;' $dimpl
$leggi = Ritaglia $d 'procedure INT_ReadMouse;' 'procedure INT_Setup;' $dimpl
$mostra = Ritaglia $d 'procedure MouseHide;' "`r`nend." ($d.IndexOf('procedure INT_Shutdown;', $dimpl))
if (-not $reset.Contains('procedure ResetMouse;')) { throw 'd_ints.pas: ResetMouse non trovata' }
if (-not $leggi.Contains("  ResetMouse;`r`n")) { throw 'd_ints.pas: la chiamata a ResetMouse in INT_ReadMouse non trovata' }
$reset = $reset.Replace('procedure ResetMouse;', 'procedure ResetMouse_Cut;')
$leggi = $leggi.Replace("  ResetMouse;`r`n", "  ResetMouse_Cut;`r`n")
Set-Content "$uscita\src\d_ints_mouse.inc" @"
// GENERATO da Tools\Verifica\175-menu\Compila.ps1: ritagliato da Reference\xGreed\Greed\d_ints.pas, con ResetMouse
// rinominata ResetMouse_Cut. Non modificare, non mettere nel repository.
$click
$reset
$leggi
$mostra
"@

# i_video: la palette, la traduzione dello zero e il disegno del puntatore del mouse
$i = Get-Content "$Riferimento\Base\i_video.pas" -Raw
$impl = $i.IndexOf("`nimplementation")
$palette = Ritaglia $i 'procedure I_SetPalette(const palette: PByteArray);' "var`r`n  NATIVEWIDTH" $impl
$palette = $palette.Replace('procedure I_SetPalette(const palette: PByteArray);', 'procedure I_SetPalette_Cut(const palette: PByteArray);')
$traduci = Ritaglia $i 'procedure I_TranslateBuffer(const buf: PByteArray; const sz: integer);' "`r`nend." $impl
$puntatore = Ritaglia $i 'procedure I_DrawMouse;' "var`r`n  old_pillarbox_pct" $impl
Set-Content "$uscita\src\i_video.pas" @"
unit i_video;
// GENERATA da Tools\Verifica\175-menu\Compila.ps1: I_SetPalette (qui I_SetPalette_Cut), I_GetPalette,
// I_TranslateBuffer e I_DrawMouse sono ritagliate da Reference\xGreed\Base\i_video.pas. Non modificare, non mettere
// nel repository.
interface
uses g_delphi;
var
  approx_zero: byte = 0;
  curpal: array[0..255] of LongWord;
  // the bytes given to the last I_SetPalette
  LastPalette: packed array[0..767] of byte;
  // the screen that I_FinishUpdate fills and I_DrawMouse draws the pointer on (640 x 400, 32 bits)
  bpp: integer = 32;
  screen16: PWordArray = nil;
  screen32: PLongWordArray = nil;
procedure I_SetPalette(const palette: PByteArray);
procedure I_GetPalette(const palette: PByteArray);
procedure I_TranslateBuffer(const buf: PByteArray; const sz: integer);
procedure I_DrawMouse;
// the size of the window is the one of the scenario
function I_WindowWidth: integer;
function I_WindowHeight: integer;
implementation
uses d_ints, r_public_h, harness_menu;

function I_WindowWidth: integer;
begin
  result := HWindowWidth;
end;

function I_WindowHeight: integer;
begin
  result := HWindowHeight;
end;

$palette
procedure I_SetPalette(const palette: PByteArray);
begin
  Move(palette^, LastPalette, 768);
  I_SetPalette_Cut(palette);
end;

$puntatore
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

# -Parte intro: dointro con la sua schermata di avvio (MainIntro, DemoIntro, ShowPortrait, IntroCommand, DoIntroMenu,
# CheckDemoExit, charinfo) e le routine di utils.pas MissionBriefing, EndGame1..3 ritagliate com'e' (IntroParity.dpr).
# Le copie stanno in $uscita\intro, che precede gli stub: la unit intro sostituisce quella di sola loadscreen e la unit
# utils e' lo stub di stubs\utils.pas con i tre punti //...-EXTRA riempiti. Wait resta quella dello stub (HarnessTic);
# selectsong e loadweapon annotano la chiamata nel registro (22 e 23 li annota modplay)
if ($Parte -eq 'intro') {
  New-Item -ItemType Directory -Force "$uscita\intro" | Out-Null
  $tabella = Ritaglia $n "const`r`n  charinfo:" '(**** VARIABLES ****)' 0
  $portrait = Ritaglia $n 'procedure ShowPortrait(' 'procedure LoadMiscData;' $impl
  Set-Content "$uscita\intro\intro.pas" @"
{`$I xGreed.inc}
unit intro;
// GENERATA da Tools\Verifica\175-menu\Compila.ps1 (-Parte intro): charinfo, loadscreen, ShowPortrait, IntroCommand,
// DoIntroMenu, CheckDemoExit, DemoIntroFlis, DemoIntro, MainIntro e dointro sono ritagliate, senza cambi, da
// Reference\xGreed\Greed\intro.pas; Wait non aspetta: chiama HarnessTic una volta per tic. Non modificare, non mettere
// nel repository.
interface
$tabella
var
  colors: array[0..767] of byte;
  nextchar: boolean;
  nointro, nobriefing: boolean;
function loadscreen(const s: string): boolean;
procedure DoIntroMenu;
procedure Wait(time: integer; sleeptime: integer = 0);
procedure dointro;
implementation
uses
  g_delphi, i_windows, i_video, constant, d_font, d_ints_h, d_misc, d_video, d_disk, d_ints, menu, modplay, protos_h,
  playfli, raven, r_public_h, r_render, utils;

$schermo
procedure Wait(time: integer; sleeptime: integer = 0);
var
  i: integer;
begin
  for i := 1 to time do
    HarnessTic;
end;

$portrait
end.
"@
  $u = Get-Content "$Riferimento\Greed\utils.pas" -Raw
  $uimpl = $u.IndexOf("`nimplementation")
  $fine = Ritaglia $u 'procedure EndGame1;' 'procedure newmap(' $uimpl
  $briefing = Ritaglia $u 'procedure MissionBriefing(const map: integer);' "`r`nend." $uimpl
  $stub = Get-Content "$PSScriptRoot\stubs\utils.pas" -Raw
  $stub = $stub.Replace('//INTERFACE-EXTRA', @"
var
  levelscore: integer = 0;
procedure MissionBriefing(const map: integer);
procedure EndGame1;
procedure EndGame2;
procedure EndGame3;
procedure selectsong(const asongmap: integer);
procedure loadweapon(const n: integer);
"@)
  $stub = $stub.Replace('//USES-EXTRA', ', intro, playfli, i_windows, timer, constant, d_font, d_video, d_ints, d_ints_h, d_misc, d_disk, i_video, modplay, protos_h, r_render, DelphiDoom.Tests.Greed.IntroScenarios')
  $stub = $stub.Replace('//IMPLEMENTATION-EXTRA', @"
procedure selectsong(const asongmap: integer);
begin
  HTrace.Add(INTRO_TRACE_SELECT_SONG); HTrace.Add(asongmap);
end;
// the original loadweapon is not of this piece: the start of an episode (the library: StartEpisode) in the trace
procedure loadweapon(const n: integer);
begin
  HTrace.Add(INTRO_TRACE_START_EPISODE);
end;
$fine
$briefing
"@)
  Set-Content "$uscita\intro\utils.pas" $stub
}

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

$programma = @{ menu = 'MenuParity'; fli = 'FliParity'; intro = 'IntroParity' }[$Parte]
$dcc = 'C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\dcc32.exe'
$libs = 'Greed', 'Input', 'Platform', 'MathCore', 'GameMath', 'Logging', 'Clock', 'Video', 'Png', 'Zlib' | ForEach-Object { "$radice\Libs\$_" }
$primo = ''
if ($Parte -eq 'intro') { $primo = "$uscita\intro;" }
$u = "$primo$PSScriptRoot\stubs;$uscita\src;$PSScriptRoot\..\175-hud\stubs;$PSScriptRoot\..\175-render\stubs;$Riferimento\Greed;$Riferimento\Base;" + ($libs -join ';') + ";$radice\Tests\Source"
# -CC: xGreed.inc dichiara {$APPTYPE GUI}, l'harness e' un programma da console
& $dcc -B -Q -CC -GD -H- -W- "-U$u" "-I$Riferimento;$uscita\src" "-N0$uscita" "-E$uscita" "-NSSystem;Winapi" "$PSScriptRoot\$programma.dpr" | Select-String 'Error|Fatal'
if ($LASTEXITCODE -ne 0) { exit 1 }
# attraverso cmd: l'eseguibile ha il sottosistema GUI di xGreed.inc e PowerShell non ne aspetta l'uscita
cmd /c "`"$uscita\$programma.exe`" `"$Dati`" `"$Golden`""
exit $LASTEXITCODE
