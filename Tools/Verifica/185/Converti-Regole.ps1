<#
  Issue #185 (ondata 11, voci A14-A21 dell'inventario): passa le routine dell'INTERFACCIA di una unit delle regole di
  un gioco (le A_* di mostri e armi, P_DamageMobj ecc.) in metodi statici di una classe `sealed` DELLA STESSA UNIT, con lo
  stesso testo e gli stessi nomi (come Converti-InClasse.ps1, che fa solo le `procedure` e non guarda i testi tra apici):

    - la dichiarazione (procedure|function Nome...;) con il suo commento di intestazione va nella classe, in fondo
      all'interfaccia, con `; static;`;
    - l'intestazione nell'implementazione diventa "class procedure|function Classe.Nome...";
    - gli usi nel resto della stessa unit (fuori dai corpi convertiti) e nei file delle cartelle -CallerDirs diventano
      Classe.Nome, ma NON dentro i testi tra apici ('A_Punch()') ne' nei commenti di riga;
    - -Exclude: nomi che restano procedure libere (per esempio chiamati da IdTech1\Base).

  Uso:
    powershell -NoProfile -File Tools\Verifica\185\Converti-Regole.ps1 -Unit IdTech1\Doom\X.pas -Class TDoomWeaponActions
      -Exclude P_CheckAmmo,P_BringUpWeapon -CallerDirs IdTech1\Doom,IdTech1\Radix,IdTech1\Speed [-Names a,b | tutte]
#>
param(
  [Parameter(Mandatory = $true)][string]$Unit,
  [Parameter(Mandatory = $true)][string]$Class,
  [string[]]$Names = @(),
  [string[]]$Exclude = @(),
  [string[]]$CallerDirs = @(),
  [string]$Root = '',
  [switch]$CallersOnly,
  [switch]$ImplOnly
)
$ErrorActionPreference = 'Stop'
if ($Root -eq '') { $Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path }
$Names = @($Names | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne '' })
$Exclude = @($Exclude | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne '' })
$CallerDirs = @($CallerDirs | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne '' })
$utf8Bom = New-Object Text.UTF8Encoding($true)

function Read-Source([string]$Path) {
  $bytes = [IO.File]::ReadAllBytes($Path)
  $bom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
  $text = (New-Object Text.UTF8Encoding($false)).GetString($bytes, $(if ($bom) { 3 } else { 0 }), $bytes.Length - $(if ($bom) { 3 } else { 0 }))
  @{ Text = $text; Bom = $bom }
}
function Write-Source([string]$Path, [string]$Text, [bool]$Bom) {
  [IO.File]::WriteAllBytes($Path, (New-Object Text.UTF8Encoding($Bom)).GetPreamble() + (New-Object Text.UTF8Encoding($false)).GetBytes($Text))
}

# Sostituisce i nomi in una riga di codice senza toccare i testi tra apici e il commento di riga finale.
$script:NameRegex = $null
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
$script:ClassName = $Class

$path = Join-Path $Root $Unit
$src = Read-Source $path
$raw = $src.Text
$nl = if ($raw.Contains("`r`n")) { "`r`n" } else { "`n" }
$lines = [System.Collections.Generic.List[string]]($raw -split "`r?`n", -1)
$implementation = -1
for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^implementation\s*$') { $implementation = $i; break } }
if ($implementation -lt 0) { throw "implementation non trovata" }

if ($ImplOnly) {
  # le routine libere che esistono SOLO nell'implementazione (nessuna dichiarazione nell'interfaccia): la classe sta
  # nell'implementazione, prima della prima routine convertita, e le chiama solo questa unit
  $inInterface = @{}
  for ($i = 0; $i -lt $implementation; $i++) { if ($lines[$i] -match '^(procedure|function)\s+(\w+)\b') { $inInterface[$Matches[2]] = $true } }
  $all = New-Object System.Collections.Generic.List[string]
  for ($j = $implementation; $j -lt $lines.Count; $j++) {
    if ($lines[$j] -match '^(procedure|function)\s+(\w+)\b') {
      $n = $Matches[2]
      if (-not $inInterface.ContainsKey($n) -and ($Exclude -notcontains $n) -and ($Names.Count -eq 0 -or $Names -contains $n) -and -not $all.Contains($n)) { $all.Add($n) }
    }
  }
  if ($all.Count -eq 0) { throw "Nessuna routine solo-implementazione da convertire" }
  $script:NameRegex = New-Object Text.RegularExpressions.Regex(('(?<![\w.])(' + ($all -join '|') + ')\b'))
  $script:NameProbe = '\b(' + ($all -join '|') + ')\b'
  $impl = New-Object System.Collections.Generic.List[string]
  $classBody = New-Object System.Collections.Generic.List[string]
  $firstHeader = -1
  $inConverted = $false
  $j = $implementation
  while ($j -lt $lines.Count) {
    $l = $lines[$j]
    # una dichiarazione `forward;` non serve a una classe (i metodi si vedono tra loro): sparisce
    if (-not $inConverted -and $l -match '^(procedure|function)\s+\w+.*;\s*forward;') { $j++; continue }
    # la classe va prima della PRIMA routine dell'implementazione (anche una gia' metodo di un'altra classe)
    if (-not $inConverted -and $firstHeader -lt 0 -and $l -match '^(class\s+)?(procedure|function)\s') {
      $firstHeader = $impl.Count
      while ($firstHeader -gt 0 -and $impl[$firstHeader - 1] -match '^//') { $firstHeader-- }
    }
    if (-not $inConverted -and $l -match '^(procedure|function)\s+(\w+)\b' -and ($all -contains $Matches[2])) {
      $inConverted = $true
      if ($firstHeader -lt 0) {
        # il commento di intestazione che precede resta sopra la classe? No: la classe va prima del banner della routine
        $firstHeader = $impl.Count
        while ($firstHeader -gt 0 -and $impl[$firstHeader - 1] -match '^//') { $firstHeader-- }
      }
      $decl = New-Object System.Collections.Generic.List[string]
      $k = $j
      $decl.Add($lines[$k])
      while ($true) {
        $joined = ($decl -join ' ') -replace '//.*$', ''
        $balance = ($joined.ToCharArray() | Where-Object { $_ -eq '(' }).Count - ($joined.ToCharArray() | Where-Object { $_ -eq ')' }).Count
        if ($balance -le 0 -and $decl[$decl.Count - 1] -match ';\s*(//.*)?$') { break }
        $k++
        $decl.Add($lines[$k])
      }
      foreach ($d in $decl) { $classBody.Add('    ' + ($d -replace '^(procedure|function)\s+', 'class $1 ')) }
      $classBody[$classBody.Count - 1] = ($classBody[$classBody.Count - 1] -replace ';\s*(//.*)?$', '; static;')
      # `overload;` si dichiara nella classe, non nell'intestazione dell'implementazione (E1030)
      $impl.Add(($l -replace '^(procedure|function)\s+(\w+)', ('class $1 {0}.$2' -f $Class)) -replace ';\s*overload;\s*$', ';')
      for ($m = $j + 1; $m -le $k; $m++) { $impl.Add($lines[$m]) }
      $j = $k + 1
      continue
    }
    if ($inConverted) {
      $impl.Add($l)
      if ($l -match '^end;\s*(//.*)?$') { $inConverted = $false }
      $j++
      continue
    }
    if ($l -match '^\s*(//|\{\$I\b)') { $impl.Add($l); $j++; continue }
    $impl.Add((Convert-CodeLine $l))
    $j++
  }
  $classText = New-Object System.Collections.Generic.List[string]
  $classText.Add('type')
  $classText.Add('  /// <summary>')
  $classText.Add('  ///   The routines that only this unit calls, as static methods with the text and the names of the old free routines')
  $classText.Add('  ///   (issue #185, wave 11): same unit, no virtual call and no interface, so the compiler produces the code it produced before')
  $classText.Add('  /// </summary>')
  $classText.Add("  $Class = class sealed")
  $classText.Add('  public')
  foreach ($c in $classBody) { $classText.Add($c) }
  $classText.Add('  end;')
  $classText.Add('')
  $impl.InsertRange($firstHeader, $classText)
  $head = (($lines[0..($implementation - 1)]) -join $nl)
  $text = $head + $nl + ($impl -join $nl)
  Write-Source $path $text $src.Bom
}
elseif (-not $CallersOnly) {
# 1) le dichiarazioni dell'interfaccia
$selected = New-Object System.Collections.Generic.List[string]
$classBody = New-Object System.Collections.Generic.List[string]
$out = New-Object System.Collections.Generic.List[string]
$i = 0
while ($i -lt $implementation) {
  $line = $lines[$i]
  if ($line -match '^(procedure|function)\s+(\w+)\b') {
    $kind = $Matches[1]
    $name = $Matches[2]
    $take = ($Exclude -notcontains $name) -and ($Names.Count -eq 0 -or $Names -contains $name)
    if ($take) {
      $decl = New-Object System.Collections.Generic.List[string]
      $decl.Add($line)
      # la dichiarazione finisce al ';' fuori dalle parentesi (i ';' tra i parametri non la chiudono)
      while ($true) {
        $joined = ($decl -join ' ') -replace '//.*$', ''
        $balance = ($joined.ToCharArray() | Where-Object { $_ -eq '(' }).Count - ($joined.ToCharArray() | Where-Object { $_ -eq ')' }).Count
        if ($balance -le 0 -and $decl[$decl.Count - 1] -match ';\s*(//.*)?$') { break }
        $i++
        $decl.Add($lines[$i])
      }
      # il commento di intestazione che precede (righe // consecutive) viene con la dichiarazione
      $header = New-Object System.Collections.Generic.List[string]
      while ($out.Count -gt 0 -and $out[$out.Count - 1] -match '^//') { $header.Insert(0, $out[$out.Count - 1]); $out.RemoveAt($out.Count - 1) }
      foreach ($h in $header) { $classBody.Add('    ' + $h) }
      foreach ($d in $decl) { $classBody.Add('    ' + ($d -replace '^(procedure|function)\s+', 'class $1 ')) }
      $classBody[$classBody.Count - 1] = ($classBody[$classBody.Count - 1] -replace ';\s*(//.*)?$', '; static;')
      $classBody.Add('')
      $selected.Add($name)
      $i++
      continue
    }
  }
  $out.Add($line)
  $i++
}
if ($selected.Count -eq 0) { throw "Nessuna routine da convertire" }

# due o piu' righe vuote di fila diventano una
$tidy = New-Object System.Collections.Generic.List[string]
foreach ($l in $out) {
  if ($l -eq '' -and $tidy.Count -gt 0 -and $tidy[$tidy.Count - 1] -eq '') { continue }
  $tidy.Add($l)
}
while ($tidy.Count -gt 0 -and $tidy[$tidy.Count - 1] -eq '') { $tidy.RemoveAt($tidy.Count - 1) }

$kindLabel = $Class
$classText = New-Object System.Collections.Generic.List[string]
$classText.Add('')
$classText.Add('type')
$classText.Add('  /// <summary>')
$classText.Add('  ///   The routines of this unit as static methods with the text and the names of the old free routines (issue #185,')
$classText.Add('  ///   wave 11): same unit, no virtual call and no interface, so the compiler produces the code it produced before')
$classText.Add('  /// </summary>')
$classText.Add("  $Class = class sealed")
$classText.Add('  public')
for ($k = 0; $k -lt $classBody.Count; $k++) { $classText.Add($classBody[$k]) }
while ($classText[$classText.Count - 1] -eq '') { $classText.RemoveAt($classText.Count - 1) }
$classText.Add('  end;')
$classText.Add('')

# 2) l'implementazione
$all = @($selected | Sort-Object -Unique)
$script:NameRegex = New-Object Text.RegularExpressions.Regex(('(?<![\w.])(' + ($all -join '|') + ')\b'))
$script:NameProbe = '\b(' + ($all -join '|') + ')\b'
$impl = New-Object System.Collections.Generic.List[string]
$inConverted = $false
for ($j = $implementation; $j -lt $lines.Count; $j++) {
  $l = $lines[$j]
  if (-not $inConverted -and $l -match '^(procedure|function)\s+(\w+)\b' -and ($all -contains $Matches[2])) {
    $inConverted = $true
    $impl.Add(($l -replace '^(procedure|function)\s+(\w+)', ('class $1 {0}.$2' -f $Class)) -replace ';\s*overload;\s*$', ';')
    # intestazione su piu' righe: il resto non cambia
    continue
  }
  if ($inConverted) {
    $impl.Add($l)
    if ($l -match '^end;\s*(//.*)?$') { $inConverted = $false }
    continue
  }
  if ($l -match '^\s*(//|\{\$I\b)') { $impl.Add($l); continue }
  $impl.Add((Convert-CodeLine $l))
}
$head = ($tidy -join $nl)
$text = $head + $nl + ($classText -join $nl) + $nl + $nl + ($impl -join $nl)
Write-Source $path $text $src.Bom
}
else {
  $all = @($Names)
  $script:NameRegex = New-Object Text.RegularExpressions.Regex(('(?<![\w.])(' + ($all -join '|') + ')\b'))
  $script:NameProbe = '\b(' + ($all -join '|') + ')\b'
}

# 3) i chiamanti
$changed = 0
foreach ($dir in $CallerDirs) {
  foreach ($file in (Get-ChildItem (Join-Path $Root $dir) -Recurse -Include *.pas, *.inc, *.dpr -File)) {
    if ($file.FullName -eq $path) { continue }
    $s = Read-Source $file.FullName
    # un nome che il file stesso definisce (intestazione a colonna 0) e' una routine sua, non quella della unit
    $own = @([regex]::Matches($s.Text, '(?m)^(?:procedure|function)\s+(\w+)') | ForEach-Object { $_.Groups[1].Value } | Where-Object { $all -contains $_ })
    $useNames = @($all | Where-Object { $own -notcontains $_ })
    if ($useNames.Count -eq 0) { continue }
    $script:NameRegex = New-Object Text.RegularExpressions.Regex(('(?<![\w.])(' + ($useNames -join '|') + ')\b'))
    $script:NameProbe = '\b(' + ($useNames -join '|') + ')\b'
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
Write-Output ('{0}: {1} routine in {2}, usi aggiornati in {3} file' -f (Split-Path $Unit -Leaf), $all.Count, $Class, $changed)
