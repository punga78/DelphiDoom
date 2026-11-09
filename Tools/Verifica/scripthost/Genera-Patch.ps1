# TEMPORARY HARNESS (issue #173): writes the hook patches of this folder starting from a clean tree:
#
#   hook-scripthost.patch      Doom32/Heretic32/Hexen32/Strife32/GLDoom32 .dpr (HarnessScriptHost), ps_main (PS_Init),
#                              the level loader (end of SetupLevel): for the L2 battery
#   hook-save-<game>.patch     the .dpr of the game (HarnessScriptHost + harness_sweep), ps_main, and the g_game of the
#                              game (the savegame hook of Tools\Verifica\harness): for the comparison of the savegames,
#                              with the state of the scripts in them (-vsh save)
#
# The patches work on the layout of the repository after the reorganisation of the root (issue #170: the .dpr are
# in Doom\, Heretic\, ...). Files are read and written as ISO-8859-1 so that every byte (and every CRLF) stays.
#
#   .\Tools\Verifica\scripthost\Genera-Patch.ps1
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Set-Location $root
$latin1 = [System.Text.Encoding]::GetEncoding('ISO-8859-1')

function Read-Source([string]$Path) { return $latin1.GetString([System.IO.File]::ReadAllBytes((Join-Path $root $Path))) }
function Write-Source([string]$Path, [string]$Text) { [System.IO.File]::WriteAllBytes((Join-Path $root $Path), $latin1.GetBytes($Text)) }

function Add-ProjectUnit([string]$Path, [string[]]$Lines) {
  $text = Read-Source $Path
  $m = [regex]::Match($text, "(?m)^  i_system in '\.\.\\Base\\i_system\.pas',\r?\n")
  if (-not $m.Success) { throw "i_system non trovata in $Path" }
  $nl = if ($m.Value.EndsWith("`r`n")) { "`r`n" } else { "`n" }
  $insert = ($Lines | ForEach-Object { "  $_,$nl" }) -join ''
  Write-Source $Path ($text.Substring(0, $m.Index + $m.Length) + $insert + $text.Substring($m.Index + $m.Length))
}

# adds a unit at the head of the uses clause of the implementation section
function Add-ImplementationUses([string]$Path, [string]$UnitName) {
  $text = Read-Source $Path
  $at = $text.IndexOf("`nimplementation")
  if ($at -lt 0) { throw "no implementation in $Path" }
  $tail = $text.Substring($at)
  $m = [regex]::Match($tail, '(?m)^uses\r?\n')
  if (-not $m.Success) { throw "no uses in the implementation of $Path" }
  $nl = if ($m.Value.EndsWith("`r`n")) { "`r`n" } else { "`n" }
  $tail = $tail.Substring(0, $m.Index + $m.Length) + "  $UnitName,$nl" + $tail.Substring($m.Index + $m.Length)
  Write-Source $Path ($text.Substring(0, $at) + $tail)
}

function Edit-Once([string]$Path, [string]$Pattern, [string]$Replacement) {
  $text = Read-Source $Path
  $m = [regex]::Match($text, $Pattern)
  if (-not $m.Success) { throw "modello non trovato in ${Path}: $Pattern" }
  Write-Source $Path ($text.Substring(0, $m.Index) + $m.Result($Replacement) + $text.Substring($m.Index + $m.Length))
}

function Edit-Implementation([string]$Path, [string]$Pattern, [string]$Replacement) {
  $text = Read-Source $Path
  $at = $text.IndexOf("`nimplementation")
  if ($at -lt 0) { throw "no implementation in $Path" }
  $tail = $text.Substring($at)
  $m = [regex]::Match($tail, $Pattern)
  if (-not $m.Success) { throw "modello non trovato nella implementation di ${Path}: $Pattern" }
  $tail = $tail.Substring(0, $m.Index) + $m.Result($Replacement) + $tail.Substring($m.Index + $m.Length)
  Write-Source $Path ($text.Substring(0, $at) + $tail)
}

function Save-Patch([string[]]$Files, [string]$Name) {
  $out = Join-Path $PSScriptRoot $Name
  & git diff -- $Files | Out-File -FilePath $out -Encoding ascii
  & git checkout -- $Files
  Write-Host "$Name : $((Get-Item $out).Length) bytes"
}

function Hook-PsMain {
  Add-ImplementationUses 'Libs\ScriptHost\ps_main.pas' 'HarnessScriptHost'
  Edit-Once 'Libs\ScriptHost\ps_main.pas' '(  psmanager := TPSExecManager\.Create;(\r?\n)  C_AddCmd\(.compile, compilescript, pscomp., @CmdCompileScript\);(\r?\n))' '$1  VSH_AfterPSInit(psmanager.compiler, psmanager.importer);$2'
}

# ---- L2 ----
$dprs = 'Doom\Doom32.dpr', 'Heretic\Heretic32.dpr', 'Hexen\Hexen32.dpr', 'Strife\Strife32.dpr', 'Doom\GLDoom32.dpr'
foreach ($dpr in $dprs) { Add-ProjectUnit $dpr @("HarnessScriptHost in '..\Tools\Verifica\scripthost\HarnessScriptHost.pas'") }
Hook-PsMain
$loader = 'Base\DelphiDoom.Engine.Level.Loader.pas'
Add-ImplementationUses $loader 'HarnessScriptHost'
Edit-Once $loader '(\r?\n  FinishLevel;(\r?\n))(end;)' '$1  VSH_AfterLevel(LMapName);$2$3'
Save-Patch ($dprs + @('Libs\ScriptHost\ps_main.pas', $loader)) 'hook-scripthost.patch'

# ---- savegames ----
foreach ($game in 'Doom', 'Heretic', 'Strife', 'Hexen') {
  $dpr = "$game\${game}32.dpr"
  $gameFile = "$game\g_game.pas"
  Add-ProjectUnit $dpr @("HarnessScriptHost in '..\Tools\Verifica\scripthost\HarnessScriptHost.pas'", "harness_sweep in '..\Tools\Verifica\harness\harness_sweep.pas'")
  Hook-PsMain
  Add-ImplementationUses $gameFile 'harness_sweep'
  Edit-Implementation $gameFile '(?m)^procedure G_Ticker;' "procedure HarnessSaveCheck; forward;`r`n`r`nprocedure G_Ticker;"
  Edit-Implementation $gameFile '(procedure G_Ticker;[\s\S]*?\r?\nbegin(\r?\n))' '$1  HarnessSaveCheck;$2'
  if ($game -eq 'Doom' -or $game -eq 'Heretic') { $inc = 'harness_save_Doom.inc' } else { $inc = "harness_save_$game.inc" }
  Edit-Implementation $gameFile '(?m)^initialization' "{`$I ..\Tools\Verifica\harness\$inc}`r`n`r`ninitialization"
  Save-Patch @($dpr, 'Libs\ScriptHost\ps_main.pas', $gameFile) "hook-save-$($game.ToLower()).patch"
}
