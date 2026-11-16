<#
  Issue #247, fetta 5 della fase 3: R_SetRenderingFunctions come tabella di dati.

  Legge il testo storico della procedura (R_SetRenderingFunctions.historic.pas, copia alla lettera di
  IdTech1\Base\r_main.pas a prima della fetta: 1.054 righe, 707 assegnazioni con condizioni annidate) e, per ogni
  configurazione di gioco (Doom, Heretic, Hexen, Strife), lo ESEGUE in modo simbolico per ogni livello di dettaglio e
  per ogni combinazione dei flag che il testo legge (usemultithread, diher8bittransparency, use32bitfuzzeffect,
  useclassicfuzzeffect, LevelUseFog): il risultato e' per ogni combinazione la lista delle variabili assegnate e dei valori
  finali (l'ultima assegnazione vince, come nel testo). Poi scrive:

    IdTech1\Base\DelphiDoom.Engine.Renderer.FunctionTable.pas   la tabella (righe: dettaglio, maschera delle combinazioni,
                                                               variabile, valore) e la classe che la applica
    IdTech1\Base\DelphiDoom.Engine.Renderer.FunctionDump.pas   lo scarico di prova (le stesse variabili per nome, i valori per
                                                               nome): confronto dei puntatori dopo l'inizializzazione,
                                                               vecchio testo contro tabella (Confronta-Funzioni.ps1)

  Le condizioni {$IF} di gioco del testo sono valutate per configurazione (Doom e Heretic devono dare lo stesso
  risultato) e riscritte nei file generati come {$IF DEFINED(HEXEN)} ... {$ELSEIF DEFINED(STRIFE)} ... {$ELSE} ... {$ENDIF}.

  Uso:  powershell -NoProfile -File Tools\Verifica\247\Genera-TabellaFunzioni.ps1 [-Check]
  -Check: non scrive, esce con 1 se i file generati non sono quelli che il testo storico produrrebbe.
#>
param(
  [string]$Historic = '',
  [string]$Root = '',
  [switch]$Check
)
$ErrorActionPreference = 'Stop'
if ($Root -eq '') { $Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path }
if ($Historic -eq '') { $Historic = Join-Path $PSScriptRoot 'R_SetRenderingFunctions.historic.pas' }
$base = Join-Path $Root 'IdTech1\Base'
$tableFile = Join-Path $base 'DelphiDoom.Engine.Renderer.FunctionTable.pas'
$dumpFile = Join-Path $base 'DelphiDoom.Engine.Renderer.FunctionDump.pas'

# ---------------------------------------------------------------- preprocessore ----------------------------------------
function Test-Directive([string]$Expression, [hashtable]$Defines) {
  $e = [regex]::Replace($Expression, 'DEFINED\((\w+)\)', { param($m) if ($Defines.ContainsKey($m.Groups[1].Value)) { '$true' } else { '$false' } }, 'IgnoreCase')
  $e = $e -replace '(?i)\bOR\b', '-or' -replace '(?i)\bAND\b', '-and' -replace '(?i)\bNOT\b', '-not'
  [bool](Invoke-Expression $e)
}

function Invoke-Preprocess([string[]]$Lines, [hashtable]$Defines) {
  $stack = New-Object System.Collections.Stack
  $active = $true
  $out = New-Object System.Collections.Generic.List[string]
  foreach ($line in $Lines) {
    $trim = $line.Trim()
    if ($trim -match '^\{\$(IFDEF|IFNDEF|IF|ELSEIF|ELSE|ENDIF)\b\s*(.*?)\}\s*(//.*)?$') {
      $kind = $Matches[1].ToUpper()
      $arg = $Matches[2].Trim()
      switch ($kind) {
        'IFDEF'  { $stack.Push(@{ Parent = $active; Taken = $false; Cur = $false }); $c = $Defines.ContainsKey($arg); $top = $stack.Peek(); $top.Cur = $c; $top.Taken = $c; $active = $top.Parent -and $c }
        'IFNDEF' { $stack.Push(@{ Parent = $active; Taken = $false; Cur = $false }); $c = -not $Defines.ContainsKey($arg); $top = $stack.Peek(); $top.Cur = $c; $top.Taken = $c; $active = $top.Parent -and $c }
        'IF'     { $stack.Push(@{ Parent = $active; Taken = $false; Cur = $false }); $c = Test-Directive $arg $Defines; $top = $stack.Peek(); $top.Cur = $c; $top.Taken = $c; $active = $top.Parent -and $c }
        'ELSEIF' { $top = $stack.Peek(); if ($top.Taken) { $c = $false } else { $c = Test-Directive $arg $Defines }; if ($c) { $top.Taken = $true }; $top.Cur = $c; $active = $top.Parent -and $c }
        'ELSE'   { $top = $stack.Peek(); $c = -not $top.Taken; if ($c) { $top.Taken = $true }; $top.Cur = $c; $active = $top.Parent -and $c }
        'ENDIF'  { $top = $stack.Pop(); $active = $top.Parent }
      }
      continue
    }
    if ($trim.StartsWith('{$')) { throw "Direttiva non gestita: $trim" }
    if ($active) { $out.Add($line) }
  }
  if ($stack.Count -ne 0) { throw 'Direttive non chiuse' }
  $out
}

# ---------------------------------------------------------------- parser ----------------------------------------------
function Read-Tokens([string[]]$Lines) {
  $text = ($Lines | ForEach-Object { $_ -replace '//.*$', '' }) -join "`n"
  $text = [regex]::Replace($text, '\{[^}]*\}', ' ')
  $list = New-Object System.Collections.Generic.List[string]
  foreach ($m in [regex]::Matches($text, '[A-Za-z_][A-Za-z_0-9]*|:=|[:;,()]|\S')) { $list.Add($m.Value) }
  , $list
}

$script:tok = $null
$script:pos = 0
function Peek { if ($script:pos -lt $script:tok.Count) { $script:tok[$script:pos] } else { '<eof>' } }
function Take { $t = Peek; $script:pos++; $t }
function Expect([string]$Word) {
  $t = Take
  if ($t.ToLower() -ne $Word.ToLower()) { throw "Atteso '$Word', trovato '$t' (token $($script:pos))" }
}

function Parse-Primary {
  $t = Take
  if ($t -eq '(') { $e = Parse-Or; Expect ')'; return $e }
  if ($t.ToLower() -eq 'not') { return @{ K = 'not'; A = (Parse-Primary) } }
  if ($t -match '^[A-Za-z_]') { return @{ K = 'var'; N = $t } }
  throw "Condizione non gestita: '$t'"
}
function Parse-And {
  $e = Parse-Primary
  while ((Peek).ToLower() -eq 'and') { $null = Take; $e = @{ K = 'and'; A = $e; B = (Parse-Primary) } }
  $e
}
function Parse-Or {
  $e = Parse-And
  while ((Peek).ToLower() -eq 'or') { $null = Take; $e = @{ K = 'or'; A = $e; B = (Parse-And) } }
  $e
}

function Parse-Statement {
  $t = Peek
  switch ($t.ToLower()) {
    'begin' {
      $null = Take
      $items = New-Object System.Collections.Generic.List[object]
      while ((Peek).ToLower() -ne 'end') {
        if ((Peek) -eq ';') { $null = Take; continue }
        $items.Add((Parse-Statement))
      }
      Expect 'end'
      return @{ K = 'seq'; Items = $items }
    }
    'if' {
      $null = Take
      $cond = Parse-Or
      Expect 'then'
      $then = Parse-Statement
      $else = $null
      if ((Peek).ToLower() -eq 'else') { $null = Take; $else = Parse-Statement }
      return @{ K = 'if'; Cond = $cond; Then = $then; Else = $else }
    }
    'case' {
      $null = Take
      $selector = Take
      Expect 'of'
      $arms = New-Object System.Collections.Generic.List[object]
      while ((Peek).ToLower() -ne 'end') {
        $label = Take
        Expect ':'
        $stmt = Parse-Statement
        if ((Peek) -eq ';') { $null = Take }
        $arms.Add(@{ Label = $label; Stmt = $stmt })
      }
      Expect 'end'
      return @{ K = 'case'; Selector = $selector; Arms = $arms }
    }
    default {
      if ($t -notmatch '^[A-Za-z_]') { throw "Istruzione non gestita: '$t' (token $($script:pos))" }
      $lhs = Take
      Expect ':='
      $rhs = Take
      return @{ K = 'assign'; L = $lhs; R = $rhs }
    }
  }
}

function Eval-Condition($Node, [hashtable]$Flags) {
  switch ($Node.K) {
    'var' { if (-not $Flags.ContainsKey($Node.N)) { throw "Flag sconosciuto $($Node.N)" }; return [bool]$Flags[$Node.N] }
    'not' { return -not (Eval-Condition $Node.A $Flags) }
    'and' { return (Eval-Condition $Node.A $Flags) -and (Eval-Condition $Node.B $Flags) }
    'or'  { return (Eval-Condition $Node.A $Flags) -or (Eval-Condition $Node.B $Flags) }
  }
}

function Collect-Flags($Node, $List) {
  if ($null -eq $Node) { return }
  switch ($Node.K) {
    'var' { if (-not $List.Contains($Node.N)) { $List.Add($Node.N) } }
    'not' { Collect-Flags $Node.A $List }
    'and' { Collect-Flags $Node.A $List; Collect-Flags $Node.B $List }
    'or'  { Collect-Flags $Node.A $List; Collect-Flags $Node.B $List }
  }
}
function Collect-FlagsStmt($Node, $List) {
  switch ($Node.K) {
    'seq'  { foreach ($i in $Node.Items) { Collect-FlagsStmt $i $List } }
    'if'   { Collect-Flags $Node.Cond $List; Collect-FlagsStmt $Node.Then $List; if ($Node.Else) { Collect-FlagsStmt $Node.Else $List } }
    'case' { foreach ($a in $Node.Arms) { Collect-FlagsStmt $a.Stmt $List } }
  }
}

function Run-Statement($Node, [hashtable]$Flags, $Out) {
  switch ($Node.K) {
    'seq'    { foreach ($i in $Node.Items) { Run-Statement $i $Flags $Out } }
    'if'     { if (Eval-Condition $Node.Cond $Flags) { Run-Statement $Node.Then $Flags $Out } elseif ($Node.Else) { Run-Statement $Node.Else $Flags $Out } }
    'assign' { $Out.Add(@($Node.L, $Node.R)) }
    'case'   { throw 'case annidato non gestito' }
  }
}

# ---------------------------------------------------------------- una configurazione ----------------------------------
$configs = [ordered]@{
  Doom    = @{ DOOM = $true }
  Heretic = @{ HERETIC = $true }
  Hexen   = @{ HEXEN = $true }
  Strife  = @{ STRIFE = $true }
}

function Build-Config([string[]]$Lines, [hashtable]$Defines) {
  $pre = Invoke-Preprocess $Lines $Defines
  $script:tok = Read-Tokens $pre
  $script:pos = 0
  Expect 'procedure'; $null = Take; Expect ';'
  $body = Parse-Statement   # begin ... end
  Expect ';'
  if ($script:pos -ne $script:tok.Count) { throw "Testo dopo la procedura: $(Peek)" }
  if ($body.K -ne 'seq' -or $body.Items.Count -ne 1 -or $body.Items[0].K -ne 'case') { throw 'La procedura deve essere un solo case setdetail' }
  $case = $body.Items[0]
  $flags = New-Object System.Collections.Generic.List[string]
  Collect-FlagsStmt $case $flags
  $details = @($case.Arms | ForEach-Object { $_.Label })
  $rows = New-Object System.Collections.Generic.List[object]     # @{Detail; Slot; Value; Mask}
  $videoModes = [ordered]@{}
  $slotOrder = New-Object System.Collections.Generic.List[string]
  $comboCount = 1 -shl $flags.Count
  foreach ($arm in $case.Arms) {
    $byKey = [ordered]@{}
    $video = @{}
    for ($c = 0; $c -lt $comboCount; $c++) {
      $f = @{}
      for ($i = 0; $i -lt $flags.Count; $i++) { $f[$flags[$i]] = [bool](($c -shr $i) -band 1) }
      $assigned = New-Object System.Collections.Generic.List[object]
      Run-Statement $arm.Stmt $f $assigned
      $final = [ordered]@{}
      foreach ($a in $assigned) { $final[$a[0]] = $a[1] }
      foreach ($slot in $final.Keys) {
        if ($slot -eq 'videomode') { $video[$final[$slot]] = $true; continue }
        $key = "$slot`t$($final[$slot])"
        if (-not $byKey.Contains($key)) { $byKey[$key] = @{ Detail = $arm.Label; Slot = $slot; Value = $final[$slot]; Mask = [uint32]0 } }
        $byKey[$key].Mask = [uint32]($byKey[$key].Mask -bor ([uint32]1 -shl $c))
        if (-not $slotOrder.Contains($slot)) { $slotOrder.Add($slot) }
      }
    }
    if ($video.Count -ne 1) { throw "videomode non unico nel dettaglio $($arm.Label)" }
    $videoModes[$arm.Label] = @($video.Keys)[0]
    foreach ($k in $byKey.Keys) { $rows.Add($byKey[$k]) }
  }
  @{ Flags = $flags; Details = $details; Rows = $rows; Video = $videoModes; Slots = $slotOrder }
}

$historicLines = [IO.File]::ReadAllLines($Historic)
$result = [ordered]@{}
foreach ($name in $configs.Keys) { $result[$name] = Build-Config $historicLines $configs[$name] }

function Config-Signature($C) {
  $parts = @('F:' + ($C.Flags -join ','))
  foreach ($r in $C.Rows) { $parts += ('{0}|{1}|{2}|{3}' -f $r.Detail, $r.Slot, $r.Value, $r.Mask) }
  foreach ($k in $C.Video.Keys) { $parts += "V:$k=$($C.Video[$k])" }
  $parts -join "`n"
}
if ((Config-Signature $result.Doom) -ne (Config-Signature $result.Heretic)) { throw 'Doom e Heretic danno risultati diversi: serve una sezione propria' }
$sections = @(
  @{ Cond = 'DEFINED(HEXEN)'; Key = 'Hexen' },
  @{ Cond = 'DEFINED(STRIFE)'; Key = 'Strife' },
  @{ Cond = $null; Key = 'Doom' })

# ---------------------------------------------------------------- unit che definiscono i nomi --------------------------
$searchDirs = @{
  Doom = @('Doom'); Hexen = @('Hexen'); Strife = @('Strife')
}
$declIndex = @{}
$dirIndex = @{}
# Routine passate in una classe (Spostate.psd1): nome storico -> espressione dell'indirizzo e unit. Il golden resta con
# il nome storico: la tabella e lo scarico confrontano lo stesso nome.
$moved = @{}
$movedFile = Join-Path $PSScriptRoot 'Spostate.psd1'
if (Test-Path $movedFile) { $moved = Import-PowerShellDataFile $movedFile }
function Value-Expr([string]$Name) { if ($moved.ContainsKey($Name)) { $moved[$Name].Expression } else { $Name } }
function Find-Unit([string]$Config, [string]$Name) {
  if ($moved.ContainsKey($Name)) { return $moved[$Name].Unit }
  $key = "$Config|$Name"
  if ($declIndex.ContainsKey($key)) { return $declIndex[$key] }
  $found = $null
  foreach ($dir in @($searchDirs[$Config]) + @('Base')) {
    if (-not $dirIndex.ContainsKey($dir)) {
      # nome (minuscolo) -> prima unit che lo dichiara, una sola lettura di ogni file
      $map = @{}
      foreach ($file in (Get-ChildItem (Join-Path $Root "IdTech1\$dir") -Filter 'r_*.pas' -File)) {
        $text = [IO.File]::ReadAllText($file.FullName)
        foreach ($m in [regex]::Matches($text, '(?im)^\s*(?:procedure|function)\s+(\w+)')) {
          $n = $m.Groups[1].Value.ToLower()
          if (-not $map.ContainsKey($n)) { $map[$n] = [IO.Path]::GetFileNameWithoutExtension($file.Name) }
        }
      }
      $dirIndex[$dir] = $map
    }
    $hit = $dirIndex[$dir][$Name.ToLower()]
    if ($hit) { $found = $hit; break }
  }
  if (-not $found) { throw "Funzione $Name non trovata ($Config)" }
  $declIndex[$key] = $found
  $found
}
function Units-For([string]$Key) {
  $c = $result[$Key]
  $names = New-Object System.Collections.Generic.List[string]
  foreach ($r in $c.Rows) { if ($r.Value -ne 'nil' -and -not $names.Contains($r.Value)) { $names.Add($r.Value) } }
  $units = New-Object System.Collections.Generic.List[string]
  foreach ($n in $names) { $u = Find-Unit $(if ($Key -eq 'Doom') { 'Doom' } else { $Key }) $n; if (-not $units.Contains($u)) { $units.Add($u) } }
  $units
}
function Values-For([string]$Key) {
  $names = New-Object System.Collections.Generic.List[string]
  foreach ($r in $result[$Key].Rows) { if ($r.Value -ne 'nil' -and -not $names.Contains($r.Value)) { $names.Add($r.Value) } }
  $names
}

# ---------------------------------------------------------------- scrittura -------------------------------------------
$nl = "`r`n"
function Header([string]$Title) {
  @(
    '{******************************************************************************}',
    '{                                                                              }',
    "{  DelphiDoom: engine - $Title".PadRight(79) + '}',
    '{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }',
    '{                                                                              }',
    '{  Licensed under the GNU General Public License, version 2 or later           }',
    '{                                                                              }',
    '{******************************************************************************}',
    '{  GENERATED by Tools\Verifica\247\Genera-TabellaFunzioni.ps1 from the old      }',
    '{  text of R_SetRenderingFunctions (R_SetRenderingFunctions.historic.pas):       }',
    '{  do not edit, change the generator and run it again                            }',
    '{******************************************************************************}'
  ) -join $nl
}

function Section-Text([scriptblock]$Body) {
  $b = New-Object System.Text.StringBuilder
  $first = $true
  foreach ($s in $sections) {
    if ($s.Cond) { $line = if ($first) { "{`$IF $($s.Cond)}" } else { "{`$ELSEIF $($s.Cond)}" } } else { $line = '{$ELSE}' }
    $first = $false
    $null = $b.Append($line).Append($nl)
    $null = $b.Append((& $Body $s.Key)).Append($nl)
  }
  $null = $b.Append('{$ENDIF}').Append($nl)
  $b.ToString()
}


# ---- tabella
$rowsText = Section-Text {
  param($Key)
  $c = $result[$Key]
  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add("  RENDERER_FUNCTION_ROWS = $($c.Rows.Count);")
  $lines.Add('')
  $lines.Add("  RendererFunctionRows: array[0..RENDERER_FUNCTION_ROWS - 1] of TRendererFunctionRow = (")
  $i = 0
  foreach ($r in $c.Rows) {
    $i++
    if ($r.Value -eq 'nil') { $value = 'nil' } else { $value = '@' + (Value-Expr $r.Value) }
    $sep = if ($i -lt $c.Rows.Count) { ',' } else { ');' }
    $lines.Add(('    (Detail: {0}; Combos: ${1:X8}; Slot: @@{2}; Value: {3}){4}' -f $r.Detail, [uint32]$r.Mask, $r.Slot, $value, $sep))
  }
  $lines -join $nl
}
$flagText = Section-Text {
  param($Key)
  $c = $result[$Key]
  $lines = New-Object System.Collections.Generic.List[string]
  for ($i = 0; $i -lt $c.Flags.Count; $i++) {
    $lines.Add("  if $($c.Flags[$i]) then")
    $lines.Add("    LCombination := LCombination or `$$('{0:X}' -f (1 -shl $i));")
  }
  if ($c.Flags.Count -eq 0) { $lines.Add('  LCombination := 0;') }
  $lines -join $nl
}
$videoText = (($result.Doom.Video.Keys | ForEach-Object { "    $($_): videomode := $($result.Doom.Video[$_]);" }) -join $nl)
# i vm di ogni configurazione devono coincidere
foreach ($k in $result.Keys) { foreach ($d in $result.Doom.Video.Keys) { if ($result[$k].Video[$d] -ne $result.Doom.Video[$d]) { throw "videomode diverso in $k/$d" } } }

$usesText = Section-Text {
  param($Key)
  $u = Units-For $Key
  $extra = @('r_main', 'r_hires', 'i_system')
  if ($Key -eq 'Hexen') { $extra += 'r_data' }
  $all = @($extra) + @($u | Where-Object { $extra -notcontains $_ })
  '  ' + (($all | Sort-Object -Unique) -join ",$nl  ") + ','
}

$table = @(
  (Header 'table of drawing functions by detail level'),
  '{$I Doom32.inc}',
  'unit DelphiDoom.Engine.Renderer.FunctionTable;',
  '',
  'interface',
  '',
  'type',
  '  /// <summary>',
  '  ///   Gives the variables of the software renderer (colfunc, spanfunc, the batch, fuzz, light and multithread',
  '  ///   variants...) the drawing functions of a detail level. The rows are the old text of R_SetRenderingFunctions',
  '  ///   run for every detail level and every combination of the flags it reads (multithread, 8 bit transparency,',
  '  ///   fuzz, fog): a row tells the combinations (bit set) in which the variable gets the value',
  '  /// </summary>',
  '  TEngineRendererFunctionTable = class sealed',
  '  public',
  '    /// <summary>Assigns the variables of the detail level ADetail; a level that is not in the table changes nothing</summary>',
  '    class procedure Apply(ADetail: Integer); static;',
  '  end;',
  '',
  'implementation',
  '',
  'uses',
  $usesText.TrimEnd(),
  '  DelphiDoom.Renderer.FunctionRows;',
  '',
  'const',
  $rowsText.TrimEnd(),
  '',
  '{ TEngineRendererFunctionTable }',
  '',
  'class procedure TEngineRendererFunctionTable.Apply(ADetail: Integer);',
  'var',
  '  LCombination: Integer;',
  'begin',
  '  LCombination := 0;',
  $flagText.TrimEnd(),
  '  TRendererFunctionRows.Apply(RendererFunctionRows, ADetail, LCombination);',
  '  case ADetail of',
  $videoText,
  '  end;',
  'end;',
  '',
  'end.',
  ''
) -join $nl

# ---- scarico
$slotsText = Section-Text {
  param($Key)
  $c = $result[$Key]
  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add("  SlotCount = $($c.Slots.Count);")
  $lines.Add("  FlagCount = $($c.Flags.Count);")
  $lines.Add("  ValueCount = $((Values-For $Key).Count);")
  $lines.Add('')
  $lines.Add('  SlotNames: array[0..SlotCount - 1] of string = (')
  $i = 0
  foreach ($s in $c.Slots) { $i++; $lines.Add(("    '{0}'{1}" -f $s, $(if ($i -lt $c.Slots.Count) { ',' } else { ');' }))) }
  $lines -join $nl
}
$dumpBodyText = Section-Text {
  param($Key)
  $c = $result[$Key]
  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add('function SlotAddress(AIndex: Integer): PPointer;')
  $lines.Add('begin')
  $lines.Add('  case AIndex of')
  for ($i = 0; $i -lt $c.Slots.Count; $i++) { $lines.Add("    ${i}: Result := @@$($c.Slots[$i]);") }
  $lines.Add('  else')
  $lines.Add('    Result := nil;')
  $lines.Add('  end;')
  $lines.Add('end;')
  $lines.Add('')
  $lines.Add('function FlagAddress(AIndex: Integer): PBoolean;')
  $lines.Add('begin')
  $lines.Add('  case AIndex of')
  for ($i = 0; $i -lt $c.Flags.Count; $i++) { $lines.Add("    ${i}: Result := @$($c.Flags[$i]);") }
  $lines.Add('  else')
  $lines.Add('    Result := nil;')
  $lines.Add('  end;')
  $lines.Add('end;')
  $lines.Add('')
  $lines.Add('function FlagName(AIndex: Integer): string;')
  $lines.Add('begin')
  $lines.Add('  case AIndex of')
  for ($i = 0; $i -lt $c.Flags.Count; $i++) { $lines.Add("    ${i}: Result := '$($c.Flags[$i])';") }
  $lines.Add('  else')
  $lines.Add("    Result := '';")
  $lines.Add('  end;')
  $lines.Add('end;')
  $lines.Add('')
  $lines.Add('function ValueName(AValue: Pointer): string;')
  $lines.Add('begin')
  $lines.Add('  if AValue = nil then')
  $lines.Add('    Exit(''nil'');')
  foreach ($v in (Values-For $Key)) { $lines.Add("  if AValue = @$(Value-Expr $v) then"); $lines.Add("    Exit('$v');") }
  $lines.Add('  Result := ''?'' + IntToHex(NativeUInt(AValue), 8);')
  $lines.Add('end;')
  $lines -join $nl
}
$dumpUses = Section-Text {
  param($Key)
  $u = Units-For $Key
  $extra = @('r_main', 'r_hires', 'i_system')
  if ($Key -eq 'Hexen') { $extra += 'r_data' }
  $all = @($extra) + @($u | Where-Object { $extra -notcontains $_ })
  '  ' + (($all | Sort-Object -Unique) -join ",$nl  ") + ','
}
$videoNames = ($result.Doom.Video.Keys | ForEach-Object { "    $($_): Result := '$($result.Doom.Video[$_])';" }) -join $nl

$dump = @(
  (Header 'test dump of the drawing function table'),
  '{$I Doom32.inc}',
  'unit DelphiDoom.Engine.Renderer.FunctionDump;',
  '',
  'interface',
  '',
  'type',
  '  /// <summary>',
  '  ///   Test tool of the table of the drawing functions: for every detail level and every combination of the flags that',
  '  ///   R_SetRenderingFunctions reads it calls the procedure and writes the name of the function that every variable',
  '  ///   got (the variables that stay empty are not written). The old text and the table must write the same file',
  '  ///   (Tools\Verifica\247\Confronta-Funzioni.ps1). The variables of the renderer are the same when it ends',
  '  /// </summary>',
  '  TEngineRendererFunctionDump = class sealed',
  '  public',
  '    class procedure Write(const AFileName: string); static;',
  '  end;',
  '',
  'implementation',
  '',
  'uses',
  '  System.Classes,',
  '  System.SysUtils,',
  $dumpUses.TrimEnd(),
  '  doomdef;',
  '',
  'const',
  '  DETAIL_COUNT = 6;',
  $slotsText.TrimEnd(),
  '',
  $dumpBodyText.TrimEnd(),
  '',
  'function VideoModeName(ADetail: Integer): string;',
  'begin',
  '  case ADetail of',
  $videoNames,
  '  else',
  "    Result := '';",
  '  end;',
  'end;',
  '',
  'function DetailOfIndex(AIndex: Integer): Integer;',
  'begin',
  '  case AIndex of',
  (($result.Doom.Details | ForEach-Object -Begin { $n = 0 } -Process { "    ${n}: Result := $_;"; $n++ }) -join $nl),
  '  else',
  '    Result := -1;',
  '  end;',
  'end;',
  '',
  '{ TEngineRendererFunctionDump }',
  '',
  'class procedure TEngineRendererFunctionDump.Write(const AFileName: string);',
  'var',
  '  LSaved: array[0..SlotCount - 1] of Pointer;',
  '  LSavedFlags: array[0..FlagCount] of Boolean;',
  '  LSavedDetail: Integer;',
  '  LSavedVideoMode: videomode_t;',
  '  LDetail: Integer;',
  '  LCombination: Integer;',
  '  LSlot: Integer;',
  '  LFlag: Integer;',
  '  LText: TStringBuilder;',
  '  LLine: string;',
  '  LValue: Pointer;',
  'begin',
  '  LSavedDetail := setdetail;',
  '  LSavedVideoMode := videomode;',
  '  for LSlot := 0 to SlotCount - 1 do',
  '    LSaved[LSlot] := SlotAddress(LSlot)^;',
  '  for LFlag := 0 to FlagCount - 1 do',
  '    LSavedFlags[LFlag] := FlagAddress(LFlag)^;',
  '  LText := TStringBuilder.Create;',
  '  try',
  '    LLine := ''# renderfunctions v1; flags:'';',
  '    for LFlag := 0 to FlagCount - 1 do',
  '      LLine := LLine + '' '' + FlagName(LFlag);',
  '    LText.Append(LLine).Append(#10);',
  '    for LDetail := 0 to DETAIL_COUNT - 1 do',
  '      for LCombination := 0 to (1 shl FlagCount) - 1 do',
  '      begin',
  '        for LFlag := 0 to FlagCount - 1 do',
  '          FlagAddress(LFlag)^ := ((LCombination shr LFlag) and 1) <> 0;',
  '        for LSlot := 0 to SlotCount - 1 do',
  '          SlotAddress(LSlot)^ := nil;',
  '        setdetail := DetailOfIndex(LDetail);',
  '        R_SetRenderingFunctions;',
  '        LLine := Format(''d=%d c=%d videomode=%s'', [LDetail, LCombination, VideoModeName(LDetail)]);',
  '        for LSlot := 0 to SlotCount - 1 do',
  '        begin',
  '          LValue := SlotAddress(LSlot)^;',
  '          if LValue <> nil then',
  '            LLine := LLine + '' '' + SlotNames[LSlot] + ''='' + ValueName(LValue);',
  '        end;',
  '        LText.Append(LLine).Append(#10);',
  '      end;',
  '    // the file is ASCII with the line feed alone: the same bytes for the 32 and the 64 bit programs',
  '    with TFileStream.Create(AFileName, fmCreate) do',
  '      try',
  '        LLine := LText.ToString;',
  '        WriteBuffer(TEncoding.ASCII.GetBytes(LLine)[0], Length(LLine));',
  '      finally',
  '        Free;',
  '      end;',
  '  finally',
  '    LText.Free;',
  '    for LSlot := 0 to SlotCount - 1 do',
  '      SlotAddress(LSlot)^ := LSaved[LSlot];',
  '    for LFlag := 0 to FlagCount - 1 do',
  '      FlagAddress(LFlag)^ := LSavedFlags[LFlag];',
  '    setdetail := LSavedDetail;',
  '    videomode := LSavedVideoMode;',
  '  end;',
  'end;',
  '',
  'end.',
  ''
) -join $nl

if ($Check) {
  $bad = 0
  foreach ($pair in @(@($tableFile, $table), @($dumpFile, $dump))) {
    $current = if (Test-Path $pair[0]) { [IO.File]::ReadAllText($pair[0]) } else { '' }
    if ($current -ne $pair[1]) { Write-Output "DIVERSO: $($pair[0])"; $bad++ }
  }
  if ($bad -eq 0) { Write-Output 'File generati uguali al testo storico' }
  exit $bad
}
[IO.File]::WriteAllText($tableFile, $table, [Text.Encoding]::ASCII)
[IO.File]::WriteAllText($dumpFile, $dump, [Text.Encoding]::ASCII)
foreach ($k in $result.Keys) {
  $c = $result[$k]
  Write-Output ('{0,-8} flags: {1}; variabili: {2}; righe: {3}' -f $k, ($c.Flags -join ' '), $c.Slots.Count, $c.Rows.Count)
}
