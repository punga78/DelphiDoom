<#
  Issue #185 (ondata 12b, voce A5/A6 dell'inventario): come Converti-Regole.ps1, ma per una unit con dichiarazioni
  CONDIZIONATE da {$IF}/{$ELSEIF}/{$ELSE} anche nell'interfaccia (s_sound: tre forme di S_Init, S_GetChannelInfo solo
  per Heretic e Hexen, ...), che Converti-Regole.ps1 non sa seguire. Le routine dell'interfaccia vanno in una classe
  `sealed` in fondo all'interfaccia, quelle solo dell'implementazione in una seconda classe nell'implementazione;
  ogni dichiarazione nella classe e' circondata dalla condizione ATTIVA nel punto in cui stava (una {$IF ...} unica,
  ricavata da tutte le direttive aperte). Stesso testo dei corpi, stessi nomi, chiamanti qualificati.

    - le dichiarazioni `forward;` spariscono (in una classe i metodi si vedono tra loro);
    - `inline;` si sposta dall'intestazione dell'implementazione alla dichiarazione (`static; inline;`);
    - `overload;` si dichiara nella classe e si toglie dall'intestazione dell'implementazione;
    - i nomi nei testi tra apici e nei commenti di riga non si toccano.

  Uso: Converti-Regole-Condizionate.ps1 -Unit IdTech1\Base\s_sound.pas -Class TSoundRoutines -LocalClass TSoundLocalRoutines
         -CallerDirs 'Framework,IdTech1,...' -UsersOf s_sound [-Exclude a,b]
#>
param(
  [Parameter(Mandatory = $true)][string]$Unit,
  [Parameter(Mandatory = $true)][string]$Class,
  [Parameter(Mandatory = $true)][string]$LocalClass,
  [string[]]$Exclude = @(),
  [string[]]$CallerDirs = @(),
  [string]$UsersOf = '',
  [string]$Root = ''
)
$ErrorActionPreference = 'Stop'
if ($Root -eq '') { $Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path }
$Exclude = @($Exclude | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne '' })
$CallerDirs = @($CallerDirs | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne '' })

function Read-Source([string]$Path) {
  $bytes = [IO.File]::ReadAllBytes($Path)
  $bom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
  $off = if ($bom) { 3 } else { 0 }
  @{ Text = (New-Object Text.UTF8Encoding($false)).GetString($bytes, $off, $bytes.Length - $off); Bom = $bom }
}
function Write-Source([string]$Path, [string]$Text, [bool]$Bom) {
  [IO.File]::WriteAllBytes($Path, (New-Object Text.UTF8Encoding($Bom)).GetPreamble() + (New-Object Text.UTF8Encoding($false)).GetBytes($Text))
}

# --- condizioni -------------------------------------------------------------------------------------------------
# Una direttiva di apertura diventa una condizione booleana ({$IFDEF X} -> DEFINED(X)); {$ELSEIF c} e {$ELSE} aggiungono
# la negazione dei rami precedenti dello stesso livello.
function Get-Condition([string]$Directive) {
  if ($Directive -match '^\{\$IFDEF\s+(\w+)\s*\}') { return "DEFINED($($Matches[1]))" }
  if ($Directive -match '^\{\$IFNDEF\s+(\w+)\s*\}') { return "NOT DEFINED($($Matches[1]))" }
  if ($Directive -match '^\{\$(IF|ELSEIF)\s+(.*)\}\s*$') { return "($($Matches[2].Trim()))" }
  throw "direttiva non gestita: $Directive"
}
function Update-Stack($Stack, [string]$Line) {
  if ($Line -match '^\{\$(IFDEF|IFNDEF|IF)\b') { $Stack.Add((New-Object 'System.Collections.Generic.List[string]')); $Stack[$Stack.Count - 1].Add((Get-Condition $Line)); return $true }
  if ($Line -match '^\{\$ELSEIF\b') {
    $lvl = $Stack[$Stack.Count - 1]
    $prev = @($lvl | ForEach-Object { "NOT ($_)" }) -join ' AND '
    # i rami precedenti sono gia' condizioni "pure" (ognuna con le negazioni dei suoi): si accumulano le negazioni della prima soltanto
    $pure = $lvl[0]
    $lvl.Add("(NOT ($pure)) AND " + (Get-Condition $Line))
    return $true
  }
  if ($Line -match '^\{\$ELSE\s*\}') {
    $lvl = $Stack[$Stack.Count - 1]
    $lvl.Add(((@($lvl | ForEach-Object { "NOT ($_)" })) -join ' AND '))
    return $true
  }
  if ($Line -match '^\{\$(ENDIF|IFEND)\s*\}') { $Stack.RemoveAt($Stack.Count - 1); return $true }
  return $false
}
function Get-ActiveCondition($Stack) {
  $parts = New-Object System.Collections.Generic.List[string]
  foreach ($level in $Stack) { $parts.Add('(' + $level[$level.Count - 1] + ')') }
  if ($parts.Count -eq 0) { return '' }
  $parts -join ' AND '
}
function Read-Declaration($Lines, [int]$Index) {
  $decl = New-Object System.Collections.Generic.List[string]
  $k = $Index
  $decl.Add($Lines[$k])
  while ($true) {
    $joined = ($decl -join ' ') -replace '//.*$', ''
    $balance = ($joined.ToCharArray() | Where-Object { $_ -eq '(' }).Count - ($joined.ToCharArray() | Where-Object { $_ -eq ')' }).Count
    if ($balance -le 0 -and $decl[$decl.Count - 1] -match ';\s*(//.*)?$') { break }
    $k++
    $decl.Add($Lines[$k])
  }
  @{ Lines = $decl; Last = $k }
}
function ConvertTo-ClassDeclaration($DeclLines) {
  $res = New-Object System.Collections.Generic.List[string]
  foreach ($d in $DeclLines) { $res.Add('    ' + ($d -replace '^(procedure|function)\s+', 'class $1 ')) }
  $last = $res[$res.Count - 1]
  $inline = $false
  if ($last -match ';\s*inline;\s*$') { $inline = $true; $last = $last -replace ';\s*inline;\s*$', ';' }
  $last = $last -replace ';\s*(//.*)?$', '; static;'
  if ($inline) { $last += ' inline;' }
  $res[$res.Count - 1] = $last
  , $res
}

# --- qualificazione dei nomi ----------------------------------------------------------------------------------------
$script:NameRegex = $null
$script:NameProbe = $null
$script:ClassName = ''
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
      [void]$sb.Append($script:NameRegex.Replace($p.Substring(0, $cut), ('{0}.$1' -f $script:ClassName)))
      [void]$sb.Append($p.Substring($cut))
      $inComment = $true
    }
    else { [void]$sb.Append($script:NameRegex.Replace($p, ('{0}.$1' -f $script:ClassName))) }
  }
  $sb.ToString()
}
function Set-NameScope([string[]]$Names, [string]$ClassName) {
  $script:NameRegex = New-Object Text.RegularExpressions.Regex(('(?<![\w.])(' + ($Names -join '|') + ')\b'))
  $script:NameProbe = '\b(' + ($Names -join '|') + ')\b'
  $script:ClassName = $ClassName
}

# --- lettura ------------------------------------------------------------------------------------------------------------
$path = Join-Path $Root $Unit
$src = Read-Source $path
$raw = $src.Text
$nl = if ($raw.Contains("`r`n")) { "`r`n" } else { "`n" }
$lines = New-Object 'System.Collections.Generic.List[string]'
$lines.AddRange([string[]]($raw -split "`r?`n", -1))
$implementation = -1
for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^implementation\s*$') { $implementation = $i; break } }
if ($implementation -lt 0) { throw 'implementation non trovata' }

# 1) interfaccia: toglie le dichiarazioni e le mette nella classe, ognuna con la sua condizione
$stack = New-Object 'System.Collections.Generic.List[System.Collections.Generic.List[string]]'
$out = New-Object System.Collections.Generic.List[string]
$bodyItems = New-Object System.Collections.Generic.List[object]
$interfaceNames = New-Object System.Collections.Generic.List[string]
$i = 0
while ($i -lt $implementation) {
  $line = $lines[$i]
  if (Update-Stack $stack $line) { $out.Add($line); $i++; continue }
  if ($line -match '^(procedure|function)\s+(\w+)\b' -and ($Exclude -notcontains $Matches[2])) {
    $name = $Matches[2]
    $d = Read-Declaration $lines $i
    $header = New-Object System.Collections.Generic.List[string]
    while ($out.Count -gt 0 -and $out[$out.Count - 1] -match '^//') { $header.Insert(0, $out[$out.Count - 1]); $out.RemoveAt($out.Count - 1) }
    $bodyItems.Add(@{ Cond = (Get-ActiveCondition $stack); Header = $header; Decl = (ConvertTo-ClassDeclaration $d.Lines) })
    if (-not $interfaceNames.Contains($name)) { $interfaceNames.Add($name) }
    $i = $d.Last + 1
    continue
  }
  $out.Add($line)
  $i++
}
if ($bodyItems.Count -eq 0) { throw 'Nessuna routine da convertire' }

$classText = New-Object System.Collections.Generic.List[string]
$classText.Add('type')
$classText.Add('  /// <summary>')
$classText.Add('  ///   The routines of this unit as static methods with the text and the names of the old free routines (issue #185,')
$classText.Add('  ///   wave 12): same unit, no virtual call and no interface, so the compiler produces the code it produced before')
$classText.Add('  /// </summary>')
$classText.Add("  $Class = class sealed")
$classText.Add('  public')
$openCond = ''
foreach ($it in $bodyItems) {
  if ($it.Cond -ne $openCond) {
    if ($openCond -ne '') { $classText.Add('{$ENDIF}') }
    if ($it.Cond -ne '') { $classText.Add('{$IF ' + $it.Cond + '}') }
    $openCond = $it.Cond
  }
  foreach ($h in $it.Header) { $classText.Add('    ' + $h) }
  foreach ($d in $it.Decl) { $classText.Add($d) }
  $classText.Add('')
}
if ($openCond -ne '') { $classText.Add('{$ENDIF}') }
while ($classText[$classText.Count - 1] -eq '') { $classText.RemoveAt($classText.Count - 1) }
$classText.Add('  end;')

# i blocchi di direttive rimasti senza contenuto (la dichiarazione e' andata nella classe) spariscono; righe vuote di fila -> una
do {
  $again = $false
  for ($a = 0; $a -lt $out.Count; $a++) {
    if ($out[$a] -notmatch '^\{\$(IF|IFDEF|IFNDEF)\b') { continue }
    $b = $a + 1
    $empty = $true
    while ($b -lt $out.Count) {
      $x = $out[$b]
      if ($x -match '^\{\$(IF|IFDEF|IFNDEF)\b') { $empty = $false; break }
      if ($x -match '^\{\$(ENDIF|IFEND)') { break }
      if ($x -notmatch '^\s*$' -and $x -notmatch '^\{\$(ELSE|ELSEIF)\b') { $empty = $false; break }
      $b++
    }
    if ($empty -and $b -lt $out.Count) { $out.RemoveRange($a, $b - $a + 1); $again = $true; break }
  }
} while ($again)
$tidy = New-Object System.Collections.Generic.List[string]
foreach ($x in $out) { if ($x -eq '' -and $tidy.Count -gt 0 -and $tidy[$tidy.Count - 1] -eq '') { continue }; $tidy.Add($x) }
$out = $tidy
while ($out.Count -gt 0 -and $out[$out.Count - 1] -eq '') { $out.RemoveAt($out.Count - 1) }
$out.Add('')
foreach ($c in $classText) { $out.Add($c) }
$out.Add('')

# 2) implementazione, primo passo: le routine dell'interfaccia
$impl = New-Object System.Collections.Generic.List[string]
Set-NameScope @($interfaceNames) $Class
$inBody = $false
$begun = $false
$j = $implementation
while ($j -lt $lines.Count) {
  $l = $lines[$j]
  if (-not $begun -and $l -match '^(procedure|function)\s+(\w+)\b') {
    $hname = $Matches[2]
    $d = Read-Declaration $lines $j
    $joined = ($d.Lines -join ' ')
    if ($joined -match ';\s*forward;') { $j = $d.Last + 1; continue }
    if ($interfaceNames -contains $hname) {
      $inBody = $true
      # una intestazione puo' avere piu' forme sotto {$IFDEF}: le forme condividono il corpo
      $first = ($d.Lines[0] -replace '^(procedure|function)\s+(\w+)', ('class $1 {0}.$2' -f $Class))
      $d.Lines[0] = $first
      $d.Lines[$d.Lines.Count - 1] = ($d.Lines[$d.Lines.Count - 1] -replace ';\s*overload;\s*$', ';')
      foreach ($x in $d.Lines) { $impl.Add($x) }
      $j = $d.Last + 1
      continue
    }
  }
  if ($inBody) {
    $impl.Add($l)
    if ($l -match '^begin\b') { $begun = $true }
    elseif ($begun -and $l -match '^(\{\$ENDIF\s*\})?end;\s*(//.*)?$') { $inBody = $false; $begun = $false }
    $j++
    continue
  }
  if ($l -match '^\s*(//|\{\$I\b)') { $impl.Add($l); $j++; continue }
  $impl.Add((Convert-CodeLine $l))
  $j++
}

# 3) implementazione, secondo passo: le routine solo dell'implementazione (a colonna 0, non ancora metodi)
$localNames = New-Object System.Collections.Generic.List[string]
foreach ($l in $impl) { if ($l -match '^(procedure|function)\s+(\w+)\b' -and ($Exclude -notcontains $Matches[2]) -and -not $localNames.Contains($Matches[2])) { $localNames.Add($Matches[2]) } }
if ($localNames.Count -gt 0) {
  Set-NameScope @($localNames) $LocalClass
  $impl2 = New-Object System.Collections.Generic.List[string]
  $localItems = New-Object System.Collections.Generic.List[object]
  $inBody = $false
  $begun = $false
  $firstHeader = -1
  $stackL = New-Object 'System.Collections.Generic.List[System.Collections.Generic.List[string]]'
  $j = 0
  while ($j -lt $impl.Count) {
    $l = $impl[$j]
    if (-not $begun) { [void](Update-Stack $stackL $l) }
    if (-not $begun -and $firstHeader -lt 0 -and $l -match '^(class\s+)?(procedure|function)\s') {
      $firstHeader = $impl2.Count
      while ($firstHeader -gt 0 -and $impl2[$firstHeader - 1] -match '^//') { $firstHeader-- }
    }
    if (-not $begun -and $l -match '^(procedure|function)\s+(\w+)\b' -and ($localNames -contains $Matches[2])) {
      $inBody = $true
      $d = Read-Declaration $impl $j
      $localItems.Add(@{ Cond = (Get-ActiveCondition $stackL); Decl = (ConvertTo-ClassDeclaration $d.Lines) })
      $d.Lines[0] = ($d.Lines[0] -replace '^(procedure|function)\s+(\w+)', ('class $1 {0}.$2' -f $LocalClass))
      $d.Lines[$d.Lines.Count - 1] = ($d.Lines[$d.Lines.Count - 1] -replace ';\s*inline;\s*$', ';' -replace ';\s*overload;\s*$', ';')
      foreach ($x in $d.Lines) { $impl2.Add($x) }
      $j = $d.Last + 1
      continue
    }
    if ($inBody) {
      $impl2.Add($l)
      if ($l -match '^begin\b') { $begun = $true }
      elseif ($begun -and $l -match '^(\{\$ENDIF\s*\})?end;\s*(//.*)?$') { $inBody = $false; $begun = $false }
      $j++
      continue
    }
    if ($l -match '^\s*(//|\{\$I\b)') { $impl2.Add($l); $j++; continue }
    $impl2.Add((Convert-CodeLine $l))
    $j++
  }
  $lt = New-Object System.Collections.Generic.List[string]
  $lt.Add('type')
  $lt.Add('  /// <summary>')
  $lt.Add('  ///   The routines that only this unit calls, as static methods with the text and the names of the old free routines')
  $lt.Add('  ///   (issue #185, wave 12): same unit, no virtual call and no interface, so the compiler produces the code it produced before')
  $lt.Add('  /// </summary>')
  $lt.Add("  $LocalClass = class sealed")
  $lt.Add('  public')
  $openCond = ''
  foreach ($it in $localItems) {
    if ($it.Cond -ne $openCond) {
      if ($openCond -ne '') { $lt.Add('{$ENDIF}') }
      if ($it.Cond -ne '') { $lt.Add('{$IF ' + $it.Cond + '}') }
      $openCond = $it.Cond
    }
    foreach ($d in $it.Decl) { $lt.Add($d) }
  }
  if ($openCond -ne '') { $lt.Add('{$ENDIF}') }
  $lt.Add('  end;')
  $lt.Add('')
  $impl2.InsertRange($firstHeader, $lt)
  $impl = $impl2
}

$text = ($out -join $nl) + $nl + ($impl -join $nl)
Write-Source $path $text $src.Bom

# 4) chiamanti
$all = @($interfaceNames)
$changed = 0
foreach ($dir in $CallerDirs) {
  foreach ($file in (Get-ChildItem (Join-Path $Root $dir) -Recurse -Include *.pas, *.inc, *.dpr -File)) {
    if ($file.FullName -eq $path) { continue }
    $s = Read-Source $file.FullName
    if ($UsersOf -ne '' -and $s.Text -notmatch ('\b' + $UsersOf + '\b')) { continue }
    $own = @([regex]::Matches($s.Text, '(?m)^\s*(?:class\s+)?(?:procedure|function)\s+(?:\w+\.)?(\w+)') | ForEach-Object { $_.Groups[1].Value } | Where-Object { $all -contains $_ })
    $useNames = @($all | Where-Object { $own -notcontains $_ })
    if ($useNames.Count -eq 0) { continue }
    Set-NameScope $useNames $Class
    if ($s.Text -notmatch $script:NameProbe) { continue }
    $eol = if ($s.Text.Contains("`r`n")) { "`r`n" } else { "`n" }
    $fl = $s.Text -split "`r?`n", -1
    for ($k = 0; $k -lt $fl.Count; $k++) {
      if ($fl[$k] -match '^\s*(//|\{\$I\b)') { continue }
      $fl[$k] = Convert-CodeLine $fl[$k]
    }
    $new = $fl -join $eol
    if ($new -ne $s.Text) { Write-Source $file.FullName $new $s.Bom; $changed++; Write-Output ('usi: ' + $file.FullName.Substring($Root.Length + 1)) }
  }
}
Write-Output ('{0}: {1} routine in {2}, {3} in {4}, usi aggiornati in {5} file' -f (Split-Path $Unit -Leaf), $interfaceNames.Count, $Class, $localNames.Count, $LocalClass, $changed)
