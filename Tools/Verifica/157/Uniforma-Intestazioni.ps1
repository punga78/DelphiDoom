<#
.SYNOPSIS
  Uniforma le intestazioni di licenza delle unit derivate da Doom 3 e da OpenXcom (issue #157, decisioni
  dell'utente del 2026-11-17: GPL v3 o successive; Doom 3 con gli "Additional Terms" di COPYING.txt).

.DESCRIPTION
  Cambia SOLO il paragrafo di licenza nel blocco di intestazione `{****}` in testa a ogni .pas/.dpr/.inc:
  corpo, BOM e fine riga restano identici (la lettura e la scrittura passano per Latin-1, byte per byte).
  Riconosce soltanto le formule note; ogni altra unit che parla di Doom 3 o di OpenXcom e non e' gia' uniforme
  viene elencata nel report (colonna "Motivo") e NON viene toccata.
  Ripetibile: una unit gia' uniforme non cambia.

  Senza -Apply non scrive nulla (prova a secco). Con -Verify controlla che il corpo (tutto cio' che segue
  l'intestazione) e il BOM siano identici a quelli di git HEAD per ogni file modificato.

.PARAMETER Apply   scrive i file
.PARAMETER Report  file TSV con una riga per unit non uniformata (Percorso, Categoria, Motivo)
#>
[CmdletBinding()]
param(
  [string]$Root = '',
  [switch]$Apply,
  [string]$Report = '',
  [switch]$Verify
)

$ErrorActionPreference = 'Stop'
if ($Root -eq '') {
  $ScriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
  $Root = (Resolve-Path (Join-Path $ScriptDirectory '..\..\..')).Path
}
$Latin1 = [Text.Encoding]::GetEncoding(28591)

$D3Terms = "with the additional terms of the Doom 3 Source Code License (Reference\doom3\COPYING.txt: " +
  "preservation of legal notices and trademarks, no use of the licensors' names for publicity, warranty disclaimer). " +
  "The repository as a whole is GPL v2 or later."
$D3Version = 'GNU General Public License, version 3 or (at your option) any later version'
$OxcVersion = 'GNU General Public License, version 3 or (at your option) any later version'

function Get-Header {
  param([string]$Text)
  # Blocco iniziale  {****}  ...  {****}  (dopo un eventuale BOM, letto come tre caratteri Latin-1)
  $m = [regex]::Match($Text, '\A(?<bom>\u00EF\u00BB\u00BF)?(?<pre>\s*)(?<top>\{\*+\*\}\r?\n)(?<body>.*?)(?<bottom>\{\*+\*\})', 'Singleline')
  if (-not $m.Success) { return $null }
  return $m
}

function Split-Paragraphs {
  # Restituisce l'elenco di paragrafi, ognuno con le righe interne (testo senza { }).
  param([string[]]$Inner)
  $result = New-Object System.Collections.Generic.List[object]
  $current = New-Object System.Collections.Generic.List[string]
  foreach ($line in $Inner) {
    if ($line.Trim().Length -eq 0) {
      if ($current.Count -gt 0) { $result.Add(@{ Blank = $false; Lines = $current.ToArray() }); $current = New-Object System.Collections.Generic.List[string] }
      $result.Add(@{ Blank = $true; Lines = @($line) })
    } else { $current.Add($line) }
  }
  if ($current.Count -gt 0) { $result.Add(@{ Blank = $false; Lines = $current.ToArray() }) }
  return $result
}

function Format-Wrapped {
  param([string]$Text)
  $words = $Text -split ' '
  $lines = New-Object System.Collections.Generic.List[string]
  $cur = ''
  foreach ($w in $words) {
    if ($cur.Length -eq 0) { $cur = $w }
    elseif (($cur.Length + 1 + $w.Length) -le 74) { $cur = $cur + ' ' + $w }
    else { $lines.Add($cur); $cur = $w }
  }
  if ($cur.Length -gt 0) { $lines.Add($cur) }
  return $lines
}

function Convert-D3Paragraph {
  # Torna il testo nuovo del paragrafo, o $null se non e' una formula nota.
  param([string]$P)
  $subject = 'This unit is'
  $from = 'the Doom 3 GPL source code'
  $copula = 'is'
  # (1) "...Doom 3 Source Code: GNU General Public License version 3 with additional terms[ (see ...)]. This unit is a derived work[ (GPL v3)]."
  $a = '(?:Doom 3 Source Code: GNU General Public License version 3 with additional terms(?: \(see Reference\\doom3\\COPYING\.txt\))?\. )?This unit is a derived work(?: \(GPL v3\))?\.(?: Delphi port: GNU General Public License, version 3 \(the combined work falls under the GPL v3 of the Doom 3 code\)\.)?'
  if ($P -match $a) {
    return [regex]::Replace($P, $a, "This unit is derived from the Doom 3 GPL source code and is therefore available under the $D3Version, $D3Terms")
  }
  # (2) "This unit is derived from ... and is therefore available under the GNU GPL, version 3[ or later], with the additional terms ...(see ...); the repository as a whole is GPL v2 or later."
  $b = '(?<subj>This unit is|The header records are) derived from (?<from>it|the Doom 3 GPL source code) and (?:is|are) therefore available under the GNU General Public License, version 3(?: or later)?, with the additional terms of the Doom 3 Source Code License \(see [^)]*\); the repository as a whole is GPL v2 or later\.'
  if ($P -match $b) {
    return [regex]::Replace($P, $b, {
      param($m)
      $cop = if ($m.Groups['subj'].Value -eq 'This unit is') { 'is' } else { 'are' }
      return ($m.Groups['subj'].Value + ' derived from ' + $m.Groups['from'].Value + ' and ' + $cop +
        " therefore available under the $D3Version, $D3Terms")
    })
  }
  return $null
}

function Convert-OxcParagraph {
  param([string]$P)
  $new = $P
  $new = [regex]::Replace($new, 'GPL v3 or later: see ', "available under the $OxcVersion; see ")
  $new = [regex]::Replace($new, 'GPL v3 or later', $OxcVersion)
  if ($new -eq $P) { return $null }
  return $new
}

if ($Verify) {
  # Prova: per ogni file diverso da HEAD, BOM, corpo (dopo l'intestazione) e fine riga uguali; solo il blocco {****} cambia.
  $bad = 0; $n = 0
  Push-Location $Root
  try {
    $names = git diff --name-only HEAD
    foreach ($name in $names) {
      if ($name -notmatch '\.(pas|dpr|inc)$') { continue }
      $n++
      $tmp = [IO.Path]::GetTempFileName()
      cmd /c "git show HEAD:$name > `"$tmp`"" | Out-Null
      $old = $Latin1.GetString([IO.File]::ReadAllBytes($tmp)); Remove-Item $tmp
      $new = $Latin1.GetString([IO.File]::ReadAllBytes((Join-Path $Root $name)))
      $ho = Get-Header $old; $hn = Get-Header $new
      $okBom = ($ho.Groups['bom'].Value -eq $hn.Groups['bom'].Value)
      $okPre = (($ho.Groups['pre'].Value -replace "\r", '') -eq ($hn.Groups['pre'].Value -replace "\r", '') -and ($ho.Groups['top'].Value -replace "\r", '') -eq ($hn.Groups['top'].Value -replace "\r", ''))
      # autocrlf: l'indice ha LF e la cartella di lavoro CRLF; si confronta in forma normalizzata e si controlla che non ci siano LF nudi
      $tailOld = $old.Substring($ho.Groups['bottom'].Index) -replace "\r\n", "`n"
      $tailNew = $new.Substring($hn.Groups['bottom'].Index) -replace "\r\n", "`n"
      $crlfOld = 0; $crlfNew = 0
      $okEol = ([regex]::Matches($new, "(?<!\r)\n")).Count -eq ([regex]::Matches($old, "(?<!\r)\n")).Count -or ([regex]::Matches($new, "(?<!\r)\n")).Count -eq 0
      if (-not ($okBom -and $okPre -and ($tailOld -ceq $tailNew) -and ($crlfOld -eq $crlfNew) -and $okEol)) { $bad++; Write-Host "DIVERSO oltre l'intestazione: $name" }
    }
  } finally { Pop-Location }
  Write-Host "Verifica: $n file controllati, $bad con differenze fuori dall'intestazione."
  if ($bad -gt 0) { exit 1 }
  return
}

$exclude ='\\(bin|dcu|Reference|\.claude|\.git|__history|Win32|Win64)\\'
$files = Get-ChildItem -Path $Root -Recurse -File -Include *.pas, *.dpr, *.inc | Where-Object { ($_.FullName.Substring($Root.Length)) -notmatch $exclude }

$changed = New-Object System.Collections.Generic.List[string]
$already = 0
$notes = New-Object System.Collections.Generic.List[object]
$byArea = @{}

foreach ($f in $files) {
  $rel = $f.FullName.Substring($Root.Length).TrimStart('\')
  $bytes = [IO.File]::ReadAllBytes($f.FullName)
  $text = $Latin1.GetString($bytes)
  $hm = Get-Header $text
  if (-not $hm) { continue }
  $headerFull = $hm.Groups['body'].Value
  $flat = ($headerFull -replace '[{}*]', ' ') -replace '\s+', ' '
  $isD3 = ($flat -match 'Doom 3|Doom3|id Tech 4') -and ($flat -match '(?i)additional terms')
  $mentionsD3 = $flat -match 'Doom 3|Doom3'
  $inXcom = $rel -match '^Games\\(Xcom[^\\]*|OpenXcom)\\'
  $isOxc = $inXcom -and ($flat -match 'OpenXcom')
  $mentionsOxc = $flat -match 'OpenXcom'
  if (-not ($mentionsD3 -or $mentionsOxc -or $inXcom)) { continue }

  $eol = if ($hm.Groups['top'].Value.EndsWith("`r`n")) { "`r`n" } else { "`n" }
  $bodyLines = $headerFull -split '\r?\n'
  # l'ultima parte e' la riga del bordo inferiore senza le graffe finali: la togliamo
  if ($bodyLines[-1].Trim().Length -eq 0) { $bodyLines = $bodyLines[0..($bodyLines.Count - 2)] }
  $inner = @()
  $parseOk = $true
  foreach ($l in $bodyLines) {
    $lm = [regex]::Match($l, '^\{(?<t>.*)\}\s*$')
    if (-not $lm.Success) { $parseOk = $false; break }
    $inner += $lm.Groups['t'].Value
  }
  if (-not $parseOk) {
    $notes.Add([pscustomobject]@{ Path = $rel; Category = 'intestazione non standard'; Reason = 'blocco di intestazione con righe senza graffe' })
    continue
  }

  $paras = Split-Paragraphs $inner
  $modified = $false
  $out = New-Object System.Collections.Generic.List[string]
  $sawCanonical = $false
  foreach ($p in $paras) {
    if ($p.Blank) { $out.Add('O' + $p.Lines[0]); continue }
    $ptext = (($p.Lines | ForEach-Object { $_.Trim() }) -join ' ')
    $new = $null
    if ($isD3) {
      if ($ptext -match [regex]::Escape($D3Version)) { $sawCanonical = $true }
      else { $new = Convert-D3Paragraph $ptext }
    } elseif ($isOxc -and $flat -notmatch 'additional terms' -and $flat -notmatch 'version 2') {
      if ($ptext -match [regex]::Escape($OxcVersion)) { $sawCanonical = $true }
      else { $new = Convert-OxcParagraph $ptext }
    }
    if ($null -ne $new) {
      $modified = $true
      foreach ($w in (Format-Wrapped $new)) { $out.Add('N  ' + $w) }
    } else {
      foreach ($l in $p.Lines) { $out.Add('O' + $l) }
    }
  }

  if ($modified) {
    # le righe non toccate restano com'erano; le nuove sono larghe 78 come le altre
    $rebuilt = ($out | ForEach-Object { if ($_[0] -eq 'N') { '{' + $_.Substring(1).PadRight(78) + '}' } else { '{' + $_.Substring(1) + '}' } }) -join $eol
    $newHeaderBody = $rebuilt + $eol
    $newText = $text.Substring(0, $hm.Groups['body'].Index) + $newHeaderBody + $text.Substring($hm.Groups['bottom'].Index)
    $changed.Add($rel)
    $area = ($rel -split '\\')[0..1] -join '\'
    if (-not $byArea.ContainsKey($area)) { $byArea[$area] = 0 }
    $byArea[$area]++
    if ($Apply) { [IO.File]::WriteAllBytes($f.FullName, $Latin1.GetBytes($newText)) }
    continue
  }
  if ($sawCanonical) { $already++; continue }

  # Non toccata: dire perche'
  if ($isD3) {
    $cat = 'Doom 3: formula non standard'
    $reason = 'cita i termini aggiuntivi di Doom 3 con parole diverse (unit mista o con piu'' origini): non classificabile con certezza'
    if ($flat -match 'Quake III' ) { $reason = 'mista Quake III (GPL v2 o successive) e Doom 3 (GPL v3): la formula non e'' quella standard' }
    elseif ($flat -match 'Licensed under the GNU General Public License, version 2 or later; the parts derived') { $reason = 'dice v2 o successive per la unit e v3 solo per le parti derivate da Doom 3: da decidere quali parti' }
    $notes.Add([pscustomobject]@{ Path = $rel; Category = $cat; Reason = $reason })
  } elseif ($mentionsD3 -and ($flat -match 'GPL|General Public')) {
    $reason = if ($flat -match 'Quake III') { 'cita Doom 3 e Quake III e dichiara v2 o successive' } else { 'cita Doom 3 ma dichiara v2 o successive, senza i termini aggiuntivi' }
    $notes.Add([pscustomobject]@{ Path = $rel; Category = 'Doom 3: dichiara v2'; Reason = $reason })
  } elseif ($inXcom) {
    if ($flat -match 'Licensed under the GNU General Public License, version 2 or later' -or $flat -match 'version 2 of the License') {
      $reason = if ($mentionsOxc) { 'cita OpenXcom e dichiara v2 o successive: unit mista' } else { 'non dice di derivare da OpenXcom e dichiara v2 o successive: codice scritto per il repository? da decidere' }
      $notes.Add([pscustomobject]@{ Path = $rel; Category = 'OpenXcom: dichiara v2'; Reason = $reason })
    } elseif ($flat -match 'zlib|LGPL') {
      $notes.Add([pscustomobject]@{ Path = $rel; Category = 'OpenXcom: terza parte'; Reason = 'cita zlib o LGPL (SDL_gfx, lodepng, fmopl): licenza propria da conservare' })
    } elseif ($flat -match 'version 3 or later|v3 or later') {
      $notes.Add([pscustomobject]@{ Path = $rel; Category = 'OpenXcom: formula non standard'; Reason = 'dice v3 o successive in forma non prevista dallo script' })
    } else {
      $notes.Add([pscustomobject]@{ Path = $rel; Category = 'OpenXcom: nessuna licenza'; Reason = 'intestazione senza testo di licenza' })
    }
  }
}

Write-Host ("Unit modificate: {0} (gia' uniformi: {1}, non toccate e da verificare: {2})" -f $changed.Count, $already, $notes.Count)
$byArea.GetEnumerator() | Sort-Object Name | ForEach-Object { Write-Host ("  {0,-34} {1,4}" -f $_.Name, $_.Value) }
if (-not $Apply) { Write-Host 'Prova a secco: nessun file scritto (usa -Apply).' }

if ($Report) {
  $notes | Sort-Object Category, Path | ForEach-Object { '{0}	{1}	{2}' -f $_.Path, $_.Category, $_.Reason } | Set-Content -Path $Report -Encoding UTF8
}
$changed | Set-Content -Path (Join-Path $env:TEMP 'uniforma-157-changed.txt') -Encoding UTF8
