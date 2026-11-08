# TEMPORARY HARNESS (issues #149, #152, #153, #154): applies the parity hooks of lights, doors and
# platforms (variant H) or of the planes (variant P) to the tree of ONE game, so that the patch can
# be written with `git diff`. The patches in this folder were produced with it:
#
#   .\Tools\Verifica\harness\Prepara-Patch.ps1 -Game Heretic -Variant H     # then: git diff > hook-heretic-all.patch
#   git checkout -- .                                                       # (only files touched by the script)
#
# Files are read and written as ISO-8859-1 so that every byte (and every CRLF) stays as it was.
param(
  [Parameter(Mandatory = $true)][ValidateSet('Doom', 'Heretic', 'Strife', 'Hexen')][string]$Game,
  [Parameter(Mandatory = $true)][ValidateSet('H', 'P', 'S')][string]$Variant
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Set-Location $root
$latin1 = [System.Text.Encoding]::GetEncoding('ISO-8859-1')

function Read-Source([string]$Path) { return $latin1.GetString([System.IO.File]::ReadAllBytes((Join-Path $root $Path))) }
function Write-Source([string]$Path, [string]$Text) { [System.IO.File]::WriteAllBytes((Join-Path $root $Path), $latin1.GetBytes($Text)) }

# Adds a unit at the head of the uses clause of the implementation section
function Add-ImplementationUses([string]$Text, [string]$UnitName) {
  $at = $Text.IndexOf("`nimplementation")
  if ($at -lt 0) { throw "no implementation section" }
  $head = $Text.Substring(0, $at)
  $tail = $Text.Substring($at)
  $m = [regex]::Match($tail, '(?m)^uses\r?\n')
  if (-not $m.Success) { throw "no uses in implementation" }
  $nl = if ($m.Value.EndsWith("`r`n")) { "`r`n" } else { "`n" }
  $tail = $tail.Substring(0, $m.Index + $m.Length) + "  $UnitName,$nl" + $tail.Substring($m.Index + $m.Length)
  return $head + $tail
}

# procedure Name(arg: Type);  <body>  end;  ->  procedure NameNew(...) <body> end; + wrapper that calls Hook
function Wrap-Procedure([string]$Text, [string]$Name, [string]$HookCall) {
  $at = $Text.IndexOf("`nimplementation")
  $head = $Text.Substring(0, $at)
  $tail = $Text.Substring($at)
  $pattern = '(?ms)^procedure ' + [regex]::Escape($Name) + '\((\w+): (\w+)\);(\r?\n)((?:var.*?)?begin.*?\r?\nend;)'
  $m = [regex]::Match($tail, $pattern)
  if (-not $m.Success) { throw "procedure $Name not found" }
  $arg = $m.Groups[1].Value
  $type = $m.Groups[2].Value
  $nl = $m.Groups[3].Value
  $body = $m.Groups[4].Value
  $call = $HookCall.Replace('<arg>', $arg).Replace('<new>', $Name + 'New')
  $replacement = "procedure ${Name}New($arg`: $type);$nl$body$nl$nl" +
    "procedure $Name($arg`: $type);${nl}begin$nl  $call$nl" + "end;"
  return $head + $tail.Substring(0, $m.Index) + $replacement + $tail.Substring($m.Index + $m.Length)
}

function Edit-File([string]$Path, [scriptblock]$Edit) {
  $text = Read-Source $Path
  $text = & $Edit $text
  Write-Source $Path $text
}

$dpr = "${Game}32.dpr"

if ($Variant -eq 'H') {
  # --- platforms: the patches of the issue #154 (they also add plat_parity to the .dpr) ---
  & git apply "Tools\Verifica\154\hook-$($Game.ToLower())32.patch"
  if ($LASTEXITCODE -ne 0) { throw "git apply of the platform hook failed" }

  # --- lights and doors of the scripted flavour (Base\udmf_*.pas, every game): the hunks of Doom ---
  & git apply --include=Base/udmf_lights.pas "Tools\Verifica\149\hook-doom32.patch"
  if ($LASTEXITCODE -ne 0) { throw "git apply of udmf_lights failed" }
  & git apply --include=Base/udmf_doors.pas "Tools\Verifica\152\hook-doom32.patch"
  if ($LASTEXITCODE -ne 0) { throw "git apply of udmf_doors failed" }

  if ($Game -ne 'Hexen') {
    # --- classic lights ---
    Edit-File "$Game\p_lights.pas" {
      param($t)
      $t = Add-ImplementationUses $t 'light_parity'
      $t = Wrap-Procedure $t 'T_FireFlicker' 'LP_FireFlicker(<arg>, @<new>);'
      $t = Wrap-Procedure $t 'T_LightFlash' 'LP_LightFlash(<arg>, @<new>);'
      $t = Wrap-Procedure $t 'T_StrobeFlash' 'LP_StrobeFlash(<arg>, @<new>);'
      $t = Wrap-Procedure $t 'T_Glow' 'LP_Glow(<arg>, @<new>);'
      return $t
    }
    # --- classic doors ---
    Edit-File "$Game\p_doors.pas" {
      param($t)
      $t = Add-ImplementationUses $t 'door_parity'
      $t = Wrap-Procedure $t 'T_VerticalDoor' 'DP_Classic(<arg>, @<new>);'
      return $t
    }
  }

  # --- the .dpr: the units of the harness after plat_parity ---
  Edit-File $dpr {
    param($t)
    $m = [regex]::Match($t, "(?m)^  plat_parity in 'Tools\\Verifica\\154\\plat_parity.pas',\r?\n")
    if (-not $m.Success) { throw "plat_parity not found in $dpr" }
    $nl = if ($m.Value.EndsWith("`r`n")) { "`r`n" } else { "`n" }
    $add = "  light_parity in 'Tools\Verifica\149\light_parity.pas',$nl" +
      "  DelphiDoom.Tests.Thinkers.DoorFakes in 'Tests\Source\DelphiDoom.Tests.Thinkers.DoorFakes.pas',$nl" +
      "  DelphiDoom.Tests.Thinkers.OldDoors in 'Tests\Source\DelphiDoom.Tests.Thinkers.OldDoors.pas',$nl" +
      "  door_parity in 'Tools\Verifica\152\door_parity.pas',$nl" +
      "  harness_exit in 'Tools\Verifica\harness\harness_exit.pas',$nl"
    return $t.Substring(0, $m.Index + $m.Length) + $add + $t.Substring($m.Index + $m.Length)
  }

  # --- clean exit: G_Ticker asks harness_exit ---
  Edit-File "$Game\g_game.pas" {
    param($t)
    $t = Add-ImplementationUses $t 'harness_exit'
    $m = [regex]::Match($t, '(?ms)^procedure G_Ticker;\r?\nvar.*?^begin\r?\n')
    if (-not $m.Success) { throw "G_Ticker not found" }
    $nl = if ($m.Value.EndsWith("`r`n")) { "`r`n" } else { "`n" }
    return $t.Substring(0, $m.Index + $m.Length) + "  HarnessExitCheck(gametic);$nl" + $t.Substring($m.Index + $m.Length)
  }
}
elseif ($Variant -eq 'S') {
  # --- savegames: the hook of harness_sweep in G_Ticker (needs none of the new units: it also builds on 31ee71e3) ---
  Edit-File $dpr {
    param($t)
    $m = [regex]::Match($t, "(?m)^  i_system in 'Base\\i_system.pas',\r?\n")
    if (-not $m.Success) { throw "i_system not found in $dpr" }
    $nl = if ($m.Value.EndsWith("`r`n")) { "`r`n" } else { "`n" }
    return $t.Substring(0, $m.Index + $m.Length) +
      "  harness_sweep in 'Tools\Verifica\harness\harness_sweep.pas',$nl" + $t.Substring($m.Index + $m.Length)
  }
  if ($Game -eq 'Strife') { $inc = 'Strife' } elseif ($Game -eq 'Hexen') { $inc = 'Hexen' } else { $inc = 'Doom' }
  Edit-File "$Game\g_game.pas" {
    param($t)
    $t = Add-ImplementationUses $t 'harness_sweep'
    $m = [regex]::Match($t, '(?m)^procedure G_Ticker;\r?\nvar')
    if (-not $m.Success) { throw "G_Ticker not found" }
    $nl = if ($m.Value.Contains("`r`n")) { "`r`n" } else { "`n" }
    $t = $t.Substring(0, $m.Index) + "procedure HarnessSaveCheck; forward;" + $nl + $nl + $t.Substring($m.Index)
    $m = [regex]::Match($t, '(?ms)^procedure G_Ticker;\r?\nvar.*?^begin\r?\n')
    $t = $t.Substring(0, $m.Index + $m.Length) + "  HarnessSaveCheck;$nl" + $t.Substring($m.Index + $m.Length)
    # before the initialization section when there is one
    $m = [regex]::Match($t, '\r?\n(initialization|finalization)\r?\n')
    if (-not $m.Success) { $m = [regex]::Match($t, '\r?\nend\.\s*$') }
    if (-not $m.Success) { throw "end of unit not found" }
    return $t.Substring(0, $m.Index) + $nl + "{`$I ..\Tools\Verifica\harness\harness_save_$inc.inc}" + $nl + $t.Substring($m.Index)
  }
}
else {
  # --- planes: plane_parity in the .dpr, PP_Run after ComposeEngine ---
  Edit-File $dpr {
    param($t)
    $m = [regex]::Match($t, "(?m)^  DelphiDoom.Thinkers.Platform.Factory in '[^']+',\r?\n")
    if (-not $m.Success) { throw "anchor not found in $dpr" }
    $nl = if ($m.Value.EndsWith("`r`n")) { "`r`n" } else { "`n" }
    $t = $t.Substring(0, $m.Index + $m.Length) +
      "  plane_parity in 'Tools\Verifica\153\plane_parity.pas',$nl" + $t.Substring($m.Index + $m.Length)
    $m = [regex]::Match($t, '(?m)^  ComposeEngine;\r?\n')
    if (-not $m.Success) { throw "ComposeEngine not found in $dpr" }
    $nl = if ($m.Value.EndsWith("`r`n")) { "`r`n" } else { "`n" }
    return $t.Substring(0, $m.Index + $m.Length) + "  PP_Run;$nl" + $t.Substring($m.Index + $m.Length)
  }
}
Write-Host "Hook $Variant applied to $Game"
