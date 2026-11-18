<#
  Issue #247 (ondata 12): passa le routine libere di una unit del renderer in metodi statici di una classe `sealed` DELLA
  STESSA UNIT, con lo stesso testo e gli stessi nomi (come Tools\Verifica\185\Converti-Regole.ps1, ma con le direttive
  di compilazione `{$IF ...}` dei renderer: ogni gruppo `{$IF}..{$ELSEIF}..{$ELSE}..{$ENDIF}` che racchiude una
  dichiarazione convertita viene riprodotto nella classe).

  Due modi, da lanciare uno dopo l'altro sulla stessa unit (due classi: la prima nell'interfaccia, la seconda
  nell'implementazione):
    -Mode Interface   le routine dichiarate nell'interfaccia: la dichiarazione va in una classe in fondo
                      all'interfaccia, l'intestazione dell'implementazione diventa "class procedure Classe.Nome",
                      gli usi nel resto della unit e nei file di -CallerDirs diventano Classe.Nome;
    -Mode Impl        le routine che esistono solo nell'implementazione: la classe sta nell'implementazione, prima della
                      prima routine; chiamate solo da questa unit.
  Uso:
    powershell -NoProfile -File Tools\Verifica\247\Converti-Renderer.ps1 -Unit IdTech1\Base\r_segs.pas -Mode Interface
      -Class TRendererSegs -CallerDirs IdTech1,Games,Tests [-Names a,b] [-Exclude c]
#>
param(
  [Parameter(Mandatory = $true)][string]$Unit,
  [Parameter(Mandatory = $true)][ValidateSet('Interface', 'Impl')][string]$Mode,
  [Parameter(Mandatory = $true)][string]$Class,
  [string[]]$Names = @(),
  [string[]]$Exclude = @(),
  [string[]]$CallerDirs = @(),
  [string]$Root = ''
)
$ErrorActionPreference = 'Stop'
if ($Root -eq '') { $Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path }
$Names = @($Names | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne '' })
$Exclude = @($Exclude | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne '' })
$CallerDirs = @($CallerDirs | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne '' })

function Read-Source([string]$Path) {
  $bytes = [IO.File]::ReadAllBytes($Path)
  $bom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
  $text = (New-Object Text.UTF8Encoding($false)).GetString($bytes, $(if ($bom) { 3 } else { 0 }), $bytes.Length - $(if ($bom) { 3 } else { 0 }))
  @{ Text = $text; Bom = $bom }
}
function Write-Source([string]$Path, [string]$Text, [bool]$Bom) {
  [IO.File]::WriteAllBytes($Path, (New-Object Text.UTF8Encoding($Bom)).GetPreamble() + (New-Object Text.UTF8Encoding($false)).GetBytes($Text))
}
function Get-DirectiveKind([string]$Line) {
  if ($Line -match '^\s*\{\$(IFDEF|IFNDEF|IF|IFOPT)\b') { return 'open' }
  if ($Line -match '^\s*\{\$(ELSE|ELSEIF)\b') { return 'branch' }
  if ($Line -match '^\s*\{\$(ENDIF|IFEND)\b') { return 'close' }
  return ''
}

$script:GroupCounter = 0
# fine del corpo di una routine: `end;` a colonna 0, oppure un `{$I file.inc}` a colonna 0 seguito da riga vuota,
# banner o nuova routine (gli .inc dei cicli portano con se' il `begin` e l'`end;`)
function Test-BodyEnd($Lines, [int]$Index) {
  $l = $Lines[$Index]
  if ($l -match '^end;\s*(//.*)?$') { return $true }
  if ($l -match '^\{\$I\s+\S+\.inc\s*\}') {
    if ($Index + 1 -ge $Lines.Count) { return $true }
    $n = $Lines[$Index + 1]
    return ($n -eq '' -or $n -match '^(//|procedure|function|class\s|type|var|const|\{\$(IF|ENDIF|ELSE))')
  }
  return $false
}
# segue le direttive di una riga (anche a meta' riga, come `else {$ENDIF}`) e aggiunge una voce per ognuna
function Track-Directives([string]$Line, $Entries, $Stack) {
  foreach ($m in [regex]::Matches($Line, '\{\$(IFDEF|IFNDEF|IFOPT|IF|ELSEIF|ELSE|ENDIF|IFEND)\b[^}]*\}')) {
    $kw = $m.Groups[1].Value
    if ($kw -in @('IFDEF', 'IFNDEF', 'IFOPT', 'IF')) {
      $script:GroupCounter++
      $Stack.Add($script:GroupCounter)
      $Entries.Add(@{ Kind = 'dir'; Text = $m.Value; Group = $script:GroupCounter })
    }
    elseif ($Stack.Count -gt 0) {
      $Entries.Add(@{ Kind = 'dir'; Text = $m.Value; Group = $Stack[$Stack.Count - 1] })
      if ($kw -in @('ENDIF', 'IFEND')) { $Stack.RemoveAt($Stack.Count - 1) }
    }
  }
}
$script:NameRegex = $null
$script:NameProbe = ''
$script:ClassName = $Class
function Convert-CodeLine([string]$Line) {
  if ($Line -notmatch $script:NameProbe) { return $Line }
  $parts = [regex]::Split($Line, "('(?:[^']|'')*')")
  $sb = New-Object Text.StringBuilder
  $inComment = $false
  foreach ($p in $parts) {
    if ($inComment) { [void]$sb.Append($p); continue }
    if ($p.StartsWith("'")) { [void]$sb.Append($p); continue }
    $cut = $p.IndexOf('//')
    if ($cut -ge 0) {
      $code = $p.Substring(0, $cut)
      [void]$sb.Append($script:NameRegex.Replace($code, ('{0}.$1' -f $script:ClassName)))
      [void]$sb.Append($p.Substring($cut))
      $inComment = $true
    }
    else { [void]$sb.Append($script:NameRegex.Replace($p, ('{0}.$1' -f $script:ClassName))) }
  }
  $sb.ToString()
}
function Set-Names([string[]]$All) {
  $script:NameRegex = New-Object Text.RegularExpressions.Regex(('(?i)(?<![\w.])(' + ($All -join '|') + ')\b'))
  $script:NameProbe = '\b(' + ($All -join '|') + ')\b'
}
# la dichiarazione finisce al ';' fuori dalle parentesi
function Read-Declaration($Lines, [int]$Start) {
  $decl = New-Object System.Collections.Generic.List[string]
  $k = $Start
  $decl.Add($Lines[$k])
  while ($true) {
    $joined = ($decl -join ' ') -replace '//.*$', ''
    $balance = ($joined.ToCharArray() | Where-Object { $_ -eq '(' }).Count - ($joined.ToCharArray() | Where-Object { $_ -eq ')' }).Count
    if ($balance -le 0 -and $decl[$decl.Count - 1] -match ';\s*(//.*)?$') { break }
    $k++
    $decl.Add($Lines[$k])
  }
  @{ Lines = $decl; End = $k }
}
# il corpo della classe: le dichiarazioni e le sole direttive dei gruppi che ne racchiudono una
function Build-ClassBody($Entries) {
  $needed = @{}
  foreach ($e in $Entries) { if ($e.Kind -eq 'decl') { foreach ($g in $e.Groups) { $needed[$g] = $true } } }
  $body = New-Object System.Collections.Generic.List[string]
  foreach ($e in $Entries) {
    if ($e.Kind -eq 'decl') { foreach ($l in $e.Lines) { $body.Add($l) } }
    elseif ($needed.ContainsKey($e.Group)) { $body.Add($e.Text) }
  }
  $body
}

$path = Join-Path $Root $Unit
$src = Read-Source $path
$raw = $src.Text
$nl = if ($raw.Contains("`r`n")) { "`r`n" } else { "`n" }
$lines = [System.Collections.Generic.List[string]]($raw -split "`r?`n", -1)
$implementation = -1
for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^implementation\s*$') { $implementation = $i; break } }
if ($implementation -lt 0) { throw "implementation non trovata" }

$summary = 'The routines of this unit'
if ($Mode -eq 'Impl') {
  $inInterface = @{}
  for ($i = 0; $i -lt $implementation; $i++) { if ($lines[$i] -match '^(procedure|function)\s+(\w+)\b') { $inInterface[$Matches[2]] = $true } }
  # routine gia' metodi di una classe dell'interfaccia: ``class procedure TX.Nome'' non combacia con ^(procedure|function)
  $all = New-Object System.Collections.Generic.List[string]
  for ($j = $implementation; $j -lt $lines.Count; $j++) {
    if ($lines[$j] -match '^(procedure|function)\s+(\w+)\b') {
      $n = $Matches[2]
      if (-not $inInterface.ContainsKey($n) -and ($Exclude -notcontains $n) -and ($Names.Count -eq 0 -or $Names -contains $n) -and -not $all.Contains($n)) { $all.Add($n) }
    }
  }
  if ($all.Count -eq 0) { throw "Nessuna routine solo-implementazione da convertire" }
  Set-Names $all
  $impl = New-Object System.Collections.Generic.List[string]
  $hoisted = New-Object System.Collections.Generic.List[string]
  $entries = New-Object System.Collections.Generic.List[object]
  $stack = New-Object System.Collections.Generic.List[int]
  $groupCounter = 0
  $firstHeader = -1
  $firstHeaderStack = @()
  $inConverted = $false
  $j = $implementation
  while ($j -lt $lines.Count) {
    $l = $lines[$j]
    if ($true) {
      $wasEmpty = ($stack.Count -eq 0)
      Track-Directives $l $entries $stack
      if ($wasEmpty -and $stack.Count -gt 0) { $outerStart = $impl.Count }
    }
    # i blocchi `type` tra le routine salgono sopra la classe: le firme dei metodi possono usare i loro tipi
    if (-not $inConverted -and $firstHeader -ge 0 -and $stack.Count -eq 0 -and $l -match '^(type|const)\s*$') {
      $hoisted.Add($l)
      $j++
      while ($j -lt $lines.Count -and ($lines[$j] -eq '' -or $lines[$j] -match '^\s')) { $hoisted.Add($lines[$j]); $j++ }
      $hoisted.Add('')
      continue
    }
    if (-not $inConverted -and $l -match '^(procedure|function)\s+\w+.*;\s*forward;') {
      $fn = ($l -split '\s+')[1] -replace '[^\w].*$', ''
      if ($all -contains $fn) { $j++; continue }
    }
    if (-not $inConverted -and $firstHeader -lt 0 -and $l -match '^(class\s+)?(procedure|function)\s') {
      $firstHeader = $impl.Count
      # dentro un gruppo di direttive la classe sale sopra l'apertura del gruppo piu' esterno (la riproduce lei)
      if ($stack.Count -gt 0) { $firstHeader = $outerStart }
      while ($firstHeader -gt 0 -and $impl[$firstHeader - 1] -match '^//') { $firstHeader-- }
    }
    if ($l -match '^(procedure|function)\s+(\w+)\b' -and ($all -contains $Matches[2])) {
      $inConverted = $true
      $d = Read-Declaration $lines $j
      $k = $d.End
      $declLines = New-Object System.Collections.Generic.List[string]
      foreach ($x in $d.Lines) { $declLines.Add('    ' + ($x -replace '^(procedure|function)\s+', 'class $1 ')) }
      $declLines[$declLines.Count - 1] = ($declLines[$declLines.Count - 1] -replace ';\s*(//.*)?$', '; static;')
      $declLines[$declLines.Count - 1] = ($declLines[$declLines.Count - 1] -replace '; assembler; static;$', '; static;')
      $entries.Add(@{ Kind = 'decl'; Lines = $declLines; Groups = @($stack) })
      # `overload;` si dichiara nella classe, non nell'intestazione dell'implementazione
      $impl.Add((($l -replace '^(procedure|function)\s+(\w+)', ('class $1 {0}.$2' -f $Class)) -replace ';\s*overload;\s*$', ';'))
      for ($m = $j + 1; $m -le $k; $m++) { $impl.Add($lines[$m]) }
      $j = $k + 1
      continue
    }
    if ($inConverted) {
      $impl.Add($l)
      if (Test-BodyEnd $lines $j) { $inConverted = $false }
      $j++
      continue
    }
    if ($l -match '^\s*(//|\{\$I\b|\{[^$])') { $impl.Add($l); $j++; continue }
    $impl.Add((Convert-CodeLine $l))
    $j++
  }
  $classBody = Build-ClassBody $entries
  $classText = New-Object System.Collections.Generic.List[string]
  $classText.Add('type')
  $classText.Add('  /// <summary>')
  $classText.Add('  ///   The routines that only this unit calls, as static methods with the text and the names of the old free routines')
  $classText.Add('  ///   (issue #247, wave 12): same unit, no virtual call and no interface, so the compiler produces the code it produced before')
  $classText.Add('  /// </summary>')
  $classText.Add("  $Class = class sealed")
  $classText.Add('  public')
  foreach ($c in $classBody) { $classText.Add($c) }
  $classText.Add('  end;')
  $classText.Add('')
  $classText.InsertRange(0, $hoisted)
  $impl.InsertRange($firstHeader, $classText)
  $head = (($lines[0..($implementation - 1)]) -join $nl)
  Write-Source $path ($head + $nl + ($impl -join $nl)) $src.Bom
  Write-Output ('{0}: {1} routine solo-implementazione in {2}' -f (Split-Path $Unit -Leaf), $all.Count, $Class)
  return
}

# --- Mode Interface ---
$entries = New-Object System.Collections.Generic.List[object]
$stack = New-Object System.Collections.Generic.List[int]
$groupCounter = 0
$selected = New-Object System.Collections.Generic.List[string]
$out = New-Object System.Collections.Generic.List[string]
$i = 0
while ($i -lt $implementation) {
  $line = $lines[$i]
  Track-Directives $line $entries $stack
  if ($line -match '^(procedure|function)\s+(\w+)\b') {
    $name = $Matches[2]
    $take = ($Exclude -notcontains $name) -and ($Names.Count -eq 0 -or $Names -contains $name)
    if ($take) {
      $d = Read-Declaration $lines $i
      $i = $d.End
      $header = New-Object System.Collections.Generic.List[string]
      while ($out.Count -gt 0 -and $out[$out.Count - 1] -match '^//') { $header.Insert(0, $out[$out.Count - 1]); $out.RemoveAt($out.Count - 1) }
      $declLines = New-Object System.Collections.Generic.List[string]
      foreach ($h in $header) { $declLines.Add('    ' + $h) }
      foreach ($x in $d.Lines) { $declLines.Add('    ' + ($x -replace '^(procedure|function)\s+', 'class $1 ')) }
      $declLines[$declLines.Count - 1] = ($declLines[$declLines.Count - 1] -replace ';\s*(//.*)?$', '; static;')
      $declLines[$declLines.Count - 1] = ($declLines[$declLines.Count - 1] -replace '; assembler; static;$', '; static;')
      $entries.Add(@{ Kind = 'decl'; Lines = $declLines; Groups = @($stack) })
      if (-not $selected.Contains($name)) { $selected.Add($name) }
      $i++
      continue
    }
  }
  $out.Add($line)
  $i++
}
if ($selected.Count -eq 0) { throw "Nessuna routine da convertire" }
$tidy = New-Object System.Collections.Generic.List[string]
foreach ($l in $out) {
  if ($l -eq '' -and $tidy.Count -gt 0 -and $tidy[$tidy.Count - 1] -eq '') { continue }
  $tidy.Add($l)
}
while ($tidy.Count -gt 0 -and $tidy[$tidy.Count - 1] -eq '') { $tidy.RemoveAt($tidy.Count - 1) }
$classBody = Build-ClassBody $entries
$classText = New-Object System.Collections.Generic.List[string]
$classText.Add('')
$classText.Add('type')
$classText.Add('  /// <summary>')
$classText.Add('  ///   The routines of this unit as static methods with the text and the names of the old free routines (issue #247,')
$classText.Add('  ///   wave 12): same unit, no virtual call and no interface, so the compiler produces the code it produced before')
$classText.Add('  /// </summary>')
$classText.Add("  $Class = class sealed")
$classText.Add('  public')
foreach ($c in $classBody) { $classText.Add($c) }
$classText.Add('  end;')
$classText.Add('')
$all = @($selected | Sort-Object -Unique)
Set-Names $all
$impl = New-Object System.Collections.Generic.List[string]
$inConverted = $false
for ($j = $implementation; $j -lt $lines.Count; $j++) {
  $l = $lines[$j]
  if ($l -match '^(procedure|function)\s+(\w+)\b' -and ($all -contains $Matches[2])) {
    $inConverted = $true
    $impl.Add((($l -replace '^(procedure|function)\s+(\w+)', ('class $1 {0}.$2' -f $Class)) -replace ';\s*overload;\s*$', ';'))
    continue
  }
  if ($inConverted) {
    $impl.Add($l)
    if (Test-BodyEnd $lines $j) { $inConverted = $false }
    continue
  }
  if ($l -match '^\s*(//|\{\$I\b|\{[^$])') { $impl.Add($l); continue }
  $impl.Add((Convert-CodeLine $l))
}
Write-Source $path (($tidy -join $nl) + $nl + ($classText -join $nl) + $nl + $nl + ($impl -join $nl)) $src.Bom

# i chiamanti
$changed = 0
foreach ($dir in $CallerDirs) {
  foreach ($file in (Get-ChildItem (Join-Path $Root $dir) -Recurse -Include *.pas, *.inc, *.dpr -File)) {
    if ($file.FullName -eq $path) { continue }
    $s = Read-Source $file.FullName
    if ($s.Text -notmatch ('\b(' + ($all -join '|') + ')\b')) { continue }
    $own = @([regex]::Matches($s.Text, '(?m)^\s*(?:class\s+)?(?:procedure|function)\s+(?:\w+\.)?(\w+)') | ForEach-Object { $_.Groups[1].Value } | Where-Object { $all -contains $_ })
    $useNames = @($all | Where-Object { $own -notcontains $_ })
    if ($useNames.Count -eq 0) { continue }
    Set-Names $useNames
    if ($s.Text -notmatch $script:NameProbe) { continue }
    $eol = if ($s.Text.Contains("`r`n")) { "`r`n" } else { "`n" }
    $fl = $s.Text -split "`r?`n", -1
    for ($k = 0; $k -lt $fl.Count; $k++) {
      if ($fl[$k] -match '^\s*(//|\{\$I\b|\{[^$])') { continue }
      $fl[$k] = Convert-CodeLine $fl[$k]
    }
    $new = $fl -join $eol
    if ($new -ne $s.Text) { Write-Source $file.FullName $new $s.Bom; $changed++; Write-Output ('usi: ' + $file.FullName.Substring($Root.Length + 1)) }
  }
}
Write-Output ('{0}: {1} routine in {2}, usi aggiornati in {3} file' -f (Split-Path $Unit -Leaf), $all.Count, $Class, $changed)
