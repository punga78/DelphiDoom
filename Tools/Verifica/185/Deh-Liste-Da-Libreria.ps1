<#
  Issue #185 (ondata 11b, voce A32): DEH_Init dei quattro deh_main.pas aggiungeva una per una (list.Add('...')) le liste dei
  nomi delle patch DEHACKED; la libreria IdTech1\Dehacked ha gli stessi nomi (TDehackedGames.DataOf, uguali per
  conteggio e testo, provato dal golden Tests\Data\Dehacked\tokens.golden.txt). Qui le Add delle 18 liste spariscono da
  deh_main e dopo ogni `lista := TDTextList.Create;` entra TEngineDehackedTokenLists.Fill(lista, deh_tokens.Campo);
  i dati arrivano da DEH_ConfigureTokens (dato da ComposeDehacked). Restano in deh_main le liste che la libreria non ha
  (renderstyle, weapontype, ammotype, playerclass, i tre gruppi MBF21) e i testi (deh_strings).

  Uso: Deh-Liste-Da-Libreria.ps1 -Unit IdTech1\Doom\deh_main.pas
#>
param([Parameter(Mandatory = $true)][string]$Unit, [string]$Root = '')
$ErrorActionPreference = 'Stop'
if ($Root -eq '') { $Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path }
$path = Join-Path $Root $Unit
$bytes = [IO.File]::ReadAllBytes($path)
$bom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
$text = (New-Object Text.UTF8Encoding($false)).GetString($bytes, $(if ($bom) { 3 } else { 0 }), $bytes.Length - $(if ($bom) { 3 } else { 0 }))
$nl = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
$lines = [System.Collections.Generic.List[string]]($text -split "`r?`n", -1)

$map = [ordered]@{ mobj_tokens = 'ThingFields'; state_tokens = 'FrameFields'; ammo_tokens = 'AmmoFields'; weapon_tokens = 'WeaponFields';
  sound_tokens = 'SoundFields'; misc_tokens = 'MiscFields'; mobj_flags = 'MobjFlags'; mobj_flags2 = 'MobjFlags2'; mobj_flags_ex = 'MobjFlagsEx';
  mobj_flags2_ex = 'MobjFlags2Ex'; mobj_flags3_ex = 'MobjFlags3Ex'; mobj_flags4_ex = 'MobjFlags4Ex'; mobj_flags5_ex = 'MobjFlags5Ex';
  mobj_flags6_ex = 'MobjFlags6Ex'; mobj_flags_mbf21 = 'MobjFlagsMbf21'; state_flags_ex = 'StateFlagsEx'; state_flags_mbf21 = 'StateFlagsMbf21';
  weapon_flags_mbf21 = 'WeaponFlagsMbf21' }
$alt = ($map.Keys -join '|')
$out = New-Object System.Collections.Generic.List[string]
$removed = 0; $filled = 0
foreach ($l in $lines) {
  if ($l -match "^\s*($alt)\.Add\('(?:[^']|'')*'\)\s*;\s*(//.*)?$") { $removed++; continue }
  $out.Add($l)
  if ($l -match "^\s*($alt)\s*:=\s*TDTextList\.Create;") {
    $out.Add(('  TEngineDehackedTokenLists.Fill({0}, deh_tokens.{1});' -f $Matches[1], $map[$Matches[1]]))
    $filled++
  }
}
# qualsiasi Add rimasta sulle 18 liste e' un'aggiunta che la libreria non ha: ferma
$left = @($out | Where-Object { $_ -match "^\s*($alt)\.Add\(" })
if ($left.Count -gt 0) { throw ('Add rimaste: ' + ($left -join ' | ')) }

$joined = $out -join $nl
# interface: la unit dei dati e il metodo che li riceve (nella classe, prima di DEH_Init)
$joined = $joined.Replace("uses$nl  d_delphi,$nl  info_h;", "uses$nl  d_delphi,$nl  DelphiDoom.Dehacked.GameData,$nl  info_h;")
$declAnchor = "    //==============================================================================$nl    //$nl    // DEH_Init$nl"
if (-not $joined.Contains($declAnchor)) { throw 'ancora della dichiarazione non trovata' }
$decl = @(
  '    //==============================================================================',
  '    //',
  '    // DEH_ConfigureTokens',
  '    // Gives the names of the fields and of the flags of the game (TDehackedGames.DataOf: ComposeEngine);',
  '    // DEH_Init fills the lists of names from them',
  '    //',
  '    //==============================================================================',
  '    class procedure DEH_ConfigureTokens(const AData: TDehackedGameData); static;',
  '') -join $nl
$joined = $joined.Replace($declAnchor, $decl + $nl + $declAnchor)
# implementazione: variabili e metodo prima di DEH_Init
$implAnchor = "var$nl  deh_initialized: boolean = false;$nl"
if (-not $joined.Contains($implAnchor)) { throw 'ancora della implementazione non trovata' }
$impl = @(
  'var',
  '  // given by the composition root (DEH_ConfigureTokens)',
  '  deh_tokens: TDehackedGameData;',
  '  deh_tokens_given: boolean = false;',
  '',
  '//==============================================================================',
  '//',
  '// DEH_ConfigureTokens',
  '//',
  '//==============================================================================',
  'class procedure TDehMainRoutines.DEH_ConfigureTokens(const AData: TDehackedGameData);',
  'begin',
  '  deh_tokens := AData;',
  '  deh_tokens_given := true;',
  'end;',
  '') -join $nl
$joined = $joined.Replace($implAnchor, $impl + $nl + $implAnchor)
# la guardia in DEH_Init
$guardAnchor = "  deh_initialized := true;$nl"
if (-not $joined.Contains($guardAnchor)) { throw 'ancora della guardia non trovata' }
$guard = "  if not deh_tokens_given then$nl    I_Error('DEH_Init(): the names of the tables were not given (DEH_ConfigureTokens was not called)');$nl$nl"
$joined = $joined.Replace($guardAnchor, $guard + $guardAnchor)
# uses dell'implementazione
$usesAnchor = "implementation$nl$nl" + 'uses' + "$nl  TypInfo,$nl"
if (-not $joined.Contains($usesAnchor)) { throw 'ancora uses non trovata' }
$joined = $joined.Replace($usesAnchor, $usesAnchor.Replace("  TypInfo,$nl", "  TypInfo,$nl  DelphiDoom.Engine.Dehacked.TokenLists,$nl  i_system,$nl"))
[IO.File]::WriteAllBytes($path, (New-Object Text.UTF8Encoding($bom)).GetPreamble() + (New-Object Text.UTF8Encoding($false)).GetBytes($joined))
Write-Output ('{0}: {1} Add tolte, {2} liste riempite dalla libreria' -f (Split-Path $Unit -Leaf), $removed, $filled)
