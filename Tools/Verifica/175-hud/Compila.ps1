# Compila ed esegue il confronto sui pixel tra l'HUD ORIGINALE di xGreed (display.pas, d_font.pas, d_video.pas e i
# pezzi di raven.pas, utils.pas e i_video.pas che servono) e le classi di Libs\Greed (TGreedCanvas,
# TGreedPaletteFader, TGreedFont, TGreedTextPrinter, TGreedMessageLine, TGreedInventory, TGreedHud,
# TGreedWeaponPainter, TGreedWeaponLight) sugli scenari di Tests\Source\DelphiDoom.Tests.Greed.HudScenarios
# (issue #175). Il codice originale resta in Reference\xGreed (sola lettura):
#   display.pas, d_font.pas, d_video.pas  copiati come sono in %TEMP%\HudParity\src (devono precedere gli stub
#                                         omonimi degli altri harness nel percorso di ricerca)
#   raven.pas     unit generata: le variabili dell'interfaccia, DrawHolo, e tre ritagli senza cambi di UpdateView e
#                 PlayLoop: il riquadro della vista posteriore (H_RearBox), "update displays" + barra di stato +
#                 updatedisplay + rewritemsg (H_Displays), la granata (H_Grenade)
#   utils.pas     loadweapon ritagliata in hud_loadweapon.inc (inclusa dallo stub utils)
#   i_video.pas   unit generata: I_SetPalette (rinominata I_SetPalette_Cut: l'involucro avvisa l'harness a ogni
#                 palette mostrata), I_GetPalette e I_TranslateBuffer ritagliate; niente DirectDraw
#   g_delphi.pas  copia con i soli cambi che Delphi 11 richiede (FormatSettings)
# Il resto sono gli stub di stubs\ e d_misc, menu, i_windows di ..\175-render\stubs; il renderer (r_*) si compila
# com'e'. Le copie generate e l'eseguibile stanno in %TEMP%\HudParity, fuori dal repository.
# Uso: .\Compila.ps1 [-Dati <cartella con GREED.BLO>] [-Golden <file>]
#   senza -Dati usa l'archivio sintetico degli scenari (font e immagini generati)
param(
  [string]$Dati = 'sintetico',
  [string]$Golden = 'nessuno',
  [string]$Riferimento = 'C:\Progetti\DelphiDoom\Reference\xGreed'
)
$radice = Resolve-Path "$PSScriptRoot\..\..\.."
$uscita = Join-Path $env:TEMP 'HudParity'
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
foreach ($f in 'display.pas', 'd_font.pas', 'd_video.pas') { Copy-Item "$Riferimento\Greed\$f" "$uscita\src\$f" -Force }

# i_video: la palette e la traduzione dello zero
$i = Get-Content "$Riferimento\Base\i_video.pas" -Raw
$impl = $i.IndexOf("`nimplementation")
$palette = Ritaglia $i 'procedure I_SetPalette(const palette: PByteArray);' "var`r`n  NATIVEWIDTH" $impl
$palette = $palette.Replace('procedure I_SetPalette(const palette: PByteArray);', 'procedure I_SetPalette_Cut(const palette: PByteArray);')
$traduci = Ritaglia $i 'procedure I_TranslateBuffer(const buf: PByteArray; const sz: integer);' "`r`nend." $impl
Set-Content "$uscita\src\i_video.pas" @"
unit i_video;
// GENERATA da Tools\Verifica\175-hud\Compila.ps1: I_SetPalette (qui I_SetPalette_Cut), I_GetPalette e
// I_TranslateBuffer sono ritagliate da Reference\xGreed\Base\i_video.pas. Non modificare, non mettere nel repository.
interface
uses g_delphi;
var
  approx_zero: byte = 0;
  curpal: array[0..255] of LongWord;
  PaletteHook: procedure = nil;
procedure I_SetPalette(const palette: PByteArray);
procedure I_GetPalette(const palette: PByteArray);
procedure I_TranslateBuffer(const buf: PByteArray; const sz: integer);
implementation
$palette
procedure I_SetPalette(const palette: PByteArray);
begin
  I_SetPalette_Cut(palette);
  if Assigned(PaletteHook) then
    PaletteHook;
end;

$traduci
end.
"@

# utils: loadweapon
$u = Get-Content "$Riferimento\Greed\utils.pas" -Raw
$arma = Ritaglia $u "var`r`n  weaponlump: integer = 0;" '// this must be updated if the scalepost' $u.IndexOf("`nimplementation")
Set-Content "$uscita\src\hud_loadweapon.inc" $arma

# raven: variabili, DrawHolo e i ritagli di UpdateView e PlayLoop
$r = Get-Content "$Riferimento\Greed\raven.pas" -Raw
$impl = $r.IndexOf("`nimplementation")
$v1 = $r.IndexOf("const`r`n  MOVEUNIT")
$v2 = $r.IndexOf('procedure TimeUpdate;', $v1)
if ($impl -lt 0 -or $v1 -lt 0 -or $v2 -lt 0 -or $v2 -gt $impl) { Write-Error 'raven.pas: interfaccia non trovata'; exit 1 }
$variabili = $r.Substring($v1, $v2 - $v1)
$holo = Ritaglia $r "`nprocedure DrawHolo;" "`nprocedure RunMenu;" $impl
$vista = $r.IndexOf("`nprocedure UpdateView(", $impl)
$retro = Ritaglia $r '  if timecount < RearViewTime then' '  // update sprite movement' $vista
$mostra = Ritaglia $r '  if mapmode = 1 then' '  if ticker then' $vista
$ciclo = $r.IndexOf("`nprocedure PlayLoop;", $impl)
$granata = Ritaglia $r '    if firegrenade then' "`r`n    if netmode then" $ciclo
Set-Content "$uscita\src\raven.pas" @"
{`$I xGreed.inc}
unit raven;
// GENERATA da Tools\Verifica\175-hud\Compila.ps1: le variabili, DrawHolo e i corpi di H_RearBox, H_Displays e
// H_Grenade sono ritagliati, senza cambi, da Reference\xGreed\Greed\raven.pas. Non modificare, non mettere nel
// repository.
interface
uses
  g_delphi, d_ints_h, d_font, d_video, protos_h, r_public_h;

$variabili
procedure TimeUpdate;
procedure DrawHolo;
procedure H_RearBox;
procedure H_Displays;
procedure H_Grenade;

implementation

uses
  constant, d_disk, d_ints, d_misc, display, i_video, modplay, net, r_conten, r_public, r_refdef, r_render,
  spawn, utils;

procedure TimeUpdate;
begin
end;
$holo
procedure H_RearBox;
var
  x, i, rtop: integer;
begin
$retro
end;

procedure H_Displays;
var
  pic: Ppic_t;
begin
$mostra
end;

procedure H_Grenade;
begin
$granata
end;

end.
"@

$dcc = 'C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\dcc32.exe'
$libs = 'Greed', 'Platform', 'MathCore', 'Logging', 'Clock', 'Video', 'Png', 'Zlib' | ForEach-Object { "$radice\Libs\$_" }
$u = "$PSScriptRoot\stubs;$uscita\src;$PSScriptRoot\..\175-render\stubs;$Riferimento\Greed;$Riferimento\Base;" + ($libs -join ';') + ";$radice\Tests\Source"
# -CC: xGreed.inc dichiara {$APPTYPE GUI}, l'harness e' un programma da console
& $dcc -B -Q -CC -H- -W- "-U$u" "-I$Riferimento;$uscita\src" "-N0$uscita" "-E$uscita" "-NSSystem;Winapi" "$PSScriptRoot\HudParity.dpr" | Select-String 'Error|Fatal'
if ($LASTEXITCODE -ne 0) { exit 1 }
# attraverso cmd: l'eseguibile ha il sottosistema GUI di xGreed.inc e PowerShell non ne aspetta l'uscita
cmd /c "`"$uscita\HudParity.exe`" `"$Dati`" `"$Golden`""
exit $LASTEXITCODE
