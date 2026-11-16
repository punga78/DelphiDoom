<#
  Issue #247: passa le routine di disegno di una unit in metodi statici di una classe `sealed` DELLA STESSA UNIT, con lo
  stesso testo (nome storico conservato). Perche' nella stessa unit: una routine in un'altra unit di quella dei registri
  che legge (dc_*, ds_*) viene compilata peggio (le letture dei globali non restano nei registri: +2 istruzioni ogni
  3 pixel nella colonna piu' semplice), una routine che resta nella sua unit ha lo stesso codice (Confronta-Routine.ps1).

  Per ogni nome:
    - la dichiarazione dell'interfaccia (procedure Nome[(parametri)];) sparisce e va nella classe, che sta alla fine
      dell'interfaccia con le stesse direttive condizionali ({$IF...}) che le circondavano;
    - l'intestazione nell'implementazione diventa "class procedure Classe.Nome...";
    - ogni uso del nome nelle altre unit e .inc diventa Classe.Nome;
    - Spostate.psd1 riceve il nome, per la tabella (Genera-TabellaFunzioni.ps1).

  Uso:
    powershell -NoProfile -File Tools\Verifica\247\Converti-InClasse.ps1 -Unit IdTech1\Base\r_col_l.pas
      -Class TRendererColLDrawers -Names R_DrawColumnLow_X,R_DrawColumnMed_X [-Root <radice>] [-Callers IdTech1]
#>
param(
  [Parameter(Mandatory = $true)][string[]]$Unit,
  [Parameter(Mandatory = $true)][string]$Class,
  [Parameter(Mandatory = $true)][string[]]$Names,
  [string]$Root = '',
  [string]$CallersDir = 'IdTech1',
  [switch]$Quiet
)
$ErrorActionPreference = 'Stop'
if ($Root -eq '') { $Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path }
$Names = @($Names | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne '' })
$Unit = @($Unit | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne '' })
$unitName = [IO.Path]::GetFileNameWithoutExtension($Unit[0])
$utf8 = New-Object Text.UTF8Encoding($false)

function Convert-OneUnit([string]$Path) {
  $raw = [IO.File]::ReadAllText($Path)
  $crlf = $raw.Contains("`r`n")
  $nl = if ($crlf) { "`r`n" } else { "`n" }
  $lines = [System.Collections.Generic.List[string]]($raw -split "`r?`n", -1)
  $implementation = -1
  for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^implementation\s*$') { $implementation = $i; break } }
  if ($implementation -lt 0) { throw "implementation non trovata in $Path" }
  $found = @{}
  $classBody = New-Object System.Collections.Generic.List[string]
  $out = New-Object System.Collections.Generic.List[string]
  $depth = 0
  $emitted = 0   # direttive condizionali emesse nel corpo della classe (stack aperto)
  $stack = New-Object System.Collections.Generic.List[string]
  $i = 0
  while ($i -lt $implementation) {
    $line = $lines[$i]
    $trim = $line.Trim()
    $isDirective = $trim -match '^\{\$(IFDEF|IFNDEF|IF|ELSEIF|ELSE|ENDIF)\b'
    if ($isDirective) {
      $classBody.Add($line)
      $out.Add($line)
      $i++
      continue
    }
    if ($line -match '^procedure\s+(\w+)\b') {
      $name = $Matches[1]
      if ($Names -contains $name) {
        # tutta la dichiarazione fino al ';' che chiude (puo' occupare piu' righe)
        $decl = New-Object System.Collections.Generic.List[string]
        $decl.Add($line)
        while ($decl[$decl.Count - 1] -notmatch ';\s*(//.*)?$') { $i++; $decl.Add($lines[$i]) }
        foreach ($d in $decl) { $classBody.Add('    ' + ($d -replace '^procedure\s+', 'class procedure ')) }
        $classBody[$classBody.Count - 1] = ($classBody[$classBody.Count - 1] -replace ';\s*(//.*)?$', '; static;')
        $found[$name] = $true
        $i++
        continue
      }
    }
    $out.Add($line)
    $i++
  }
  if ($found.Count -eq 0) { throw "Nessuna delle routine in $Path" }
  # banner "// Nome" vuoti restano: sono commenti. Le direttive che non racchiudono piu' nulla restano pari.
  $classText = New-Object System.Collections.Generic.List[string]
  $classText.Add('type')
  $classText.Add('  /// <summary>')
  $classText.Add("  ///   The drawing routines of this unit as static methods with the text and the names of the old procedures. They")
  $classText.Add("  ///   stay in the unit of the registers they read: a routine in another unit is compiled worse (Tools\Verifica\247)")
  $classText.Add('  /// </summary>')
  $classText.Add("  $Class = class sealed")
  $classText.Add('  public')
  foreach ($c in $classBody) { $classText.Add($c) }
  $classText.Add('  end;')
  $classText.Add('')
  $rest = New-Object System.Collections.Generic.List[string]
  for ($j = $implementation; $j -lt $lines.Count; $j++) { $rest.Add($lines[$j]) }
  $restText = ($rest -join $nl)
  foreach ($name in $found.Keys) {
    $restText = [regex]::Replace($restText, "(?m)^procedure\s+$name\b", "class procedure $Class.$name")
  }
  $head = ($out -join $nl)
  $text = $head + $nl + ($classText -join $nl) + $nl + $restText
  [IO.File]::WriteAllText($Path, $text, $utf8)
  $found.Keys
}

$all = New-Object System.Collections.Generic.List[string]
foreach ($u in $Unit) {
  $path = Join-Path $Root $u
  foreach ($n in (Convert-OneUnit $path)) { if (-not $all.Contains($n)) { $all.Add($n) } }
}
if ($all.Count -ne $Names.Count) {
  $missing = @($Names | Where-Object { $all -notcontains $_ })
  Write-Warning ("Non trovate: {0}" -f ($missing -join ', '))
}

# gli usi nelle altre unit e nei .inc
$unitPaths = @($Unit | ForEach-Object { (Join-Path $Root $_) })
$changedFiles = 0
foreach ($file in (Get-ChildItem (Join-Path $Root $CallersDir) -Recurse -Include *.pas, *.inc -File)) {
  if ($unitPaths -contains $file.FullName) { continue }
  if ($file.Name -like 'DelphiDoom.Engine.Renderer.Function*') { continue }
  $text = [IO.File]::ReadAllText($file.FullName)
  $new = $text
  $hit = $false
  foreach ($name in $all) { if ($new -match "\b$name\b") { $hit = $true; break } }
  if (-not $hit) { continue }
  $eol = if ($new.Contains("`r`n")) { "`r`n" } else { "`n" }
  $fileLines = $new -split "`r?`n", -1
  for ($k = 0; $k -lt $fileLines.Count; $k++) {
    # le righe che sono commenti di riga non cambiano
    if ($fileLines[$k] -match '^\s*(//|\{\$I)') { continue }
    foreach ($name in $all) {
      if ($fileLines[$k] -match "\b$name\b") { $fileLines[$k] = [regex]::Replace($fileLines[$k], "(?<![\w.])$name\b", "$Class.$name") }
    }
  }
  $new = $fileLines -join $eol
  if ($new -ne $text) { [IO.File]::WriteAllText($file.FullName, $new, $utf8); $changedFiles++; if (-not $Quiet) { Write-Output "usi aggiornati: $($file.FullName.Substring($Root.Length + 1))" } }
}

# Spostate.psd1
$movedFile = Join-Path $PSScriptRoot 'Spostate.psd1'
$text = [IO.File]::ReadAllText($movedFile)
foreach ($name in $all) {
  if ($text -notmatch "(?m)^\s*$name\s*=") {
    $entry = "  $name = @{ Expression = '$Class.$name'; Unit = '$unitName' }"
    $text = $text -replace '\}\s*$', ($entry + "`r`n}`r`n")
  }
}
[IO.File]::WriteAllText($movedFile, $text, $utf8)
Write-Output ("{0}: {1} routine in {2}, usi aggiornati in {3} file" -f $unitName, $all.Count, $Class, $changedFiles)
