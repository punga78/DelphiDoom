<#
.SYNOPSIS
  Issue #226: sposta una fetta di cartelle (git mv) e aggiorna ogni riferimento ai vecchi percorsi.

.DESCRIPTION
  La fetta si sceglie per nome in Tools\Verifica\226\Mappa.psd1 (vecchio>nuovo, cartelle e file).
  Per ogni file di testo tracciato da git:
    1. i percorsi RELATIVI (che iniziano con ..\ o ../) sono risolti dalla cartella vecchia del file,
       mappati sul nuovo posto del bersaglio e riscritti relativi alla cartella nuova del file
       (file .dpr, .dproj, .groupproj, .rc, .inc, .md, script, ...; nei .pas solo dentro
       {$I ...}, {$INCLUDE ...}, {$R ...}, {$L ...});
    2. i percorsi ancorati alla radice (Libs\Zlib, Doom\Doom32.dpr, ...) sono sostituiti nel testo,
       con \ o / secondo il testo, senza toccare bin\Doom (cartelle dei dati) ne' Tests\Data\...\Doom.
  Poi sposta con git mv. I nomi delle unit non cambiano. Non tocca i byte che non cambiano
  (lettura e scrittura Latin1, BOM e CRLF restano). Nei commenti a riquadro dei .pas ({ ... }) il
  riempimento prima di } compensa la differenza di lunghezza del percorso.

  -Prova: non scrive e non sposta, stampa il riepilogo. -SoloRiferimenti: non sposta (per ripetere).
#>
param(
  [Parameter(Mandatory = $true)][string]$Fetta,
  [switch]$Prova,
  [switch]$SoloRiferimenti,
  [string]$Radice = '',
  [string]$Mappa = '',
  # alberi finti, mappa, analisi datata e la patch per gli alberi di prima della #226 (hanno i percorsi vecchi)
  [string[]]$Escludi = @('Tests\Data\Strati', 'Tools\Verifica\226', 'docs\FRAMEWORK_CENSIMENTO.md', 'Tools\Verifica\opengl\hook-gl.pre226.patch')
)

$ErrorActionPreference = 'Stop'
if ($Radice -eq '') { $Radice = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path }
$Radice = $Radice.TrimEnd('\')
if ($Mappa -eq '') { $Mappa = Join-Path $PSScriptRoot 'Mappa.psd1' }
Set-Location $Radice
$latin1 = [Text.Encoding]::GetEncoding(28591)

# --- Mappa della fetta -----------------------------------------------------------------------
$datiMappa = Import-PowerShellDataFile -Path $Mappa
$voceFetta = @($datiMappa.Fette | Where-Object { $_.Nome -eq $Fetta })
if ($voceFetta.Count -ne 1) { throw "Fetta '$Fetta' non trovata in $Mappa (nomi: $(($datiMappa.Fette | ForEach-Object { $_.Nome }) -join ', '))" }
$voceFetta = $voceFetta[0]
$dirs = New-Object Collections.Generic.List[object]
foreach ($e in $voceFetta.Dir) { $p = $e -split '>'; $dirs.Add([pscustomobject]@{ Da = $p[0]; A = $p[1]; Tipo = 'Dir' }) }
$filesMap = New-Object Collections.Generic.List[object]
foreach ($e in $voceFetta.File) { $p = $e -split '>'; $filesMap.Add([pscustomobject]@{ Da = $p[0]; A = $p[1]; Tipo = 'File' }) }

function Get-NuovoPercorso([string]$Rel) {
  # Rel: percorso dalla radice con \ ; usa la voce piu' specifica (file, poi cartella piu' lunga)
  foreach ($f in $filesMap) { if ($Rel -ieq $f.Da) { return $f.A } }
  $best = $null
  foreach ($d in $dirs) {
    if ($Rel -ieq $d.Da -or $Rel.StartsWith($d.Da + '\', [StringComparison]::OrdinalIgnoreCase)) {
      if ($null -eq $best -or $d.Da.Length -gt $best.Da.Length) { $best = $d }
    }
  }
  if ($null -eq $best) { return $Rel }
  return $best.A + $Rel.Substring($best.Da.Length)
}

# --- Regole di testo (percorsi ancorati alla radice) ------------------------------------------------
$prima = '(?:(?<![A-Za-z0-9_$)}\]][\\/])|(?<=(?:\$radice|\$Radice|\$root|\$Root|%R%)[\\/])|(?<=(?:^|\s)[ab]/))(?<![A-Za-z0-9_])'
$regole = New-Object Collections.Generic.List[object]
function Add-Regola($voce) {
  $parti = $voce.Da -split '\\'
  $nome = ($parti | ForEach-Object { [regex]::Escape($_) }) -join '[\\/]'
  if ($voce.Tipo -eq 'File') {
    $coda = '(?![A-Za-z0-9_])'
  }
  elseif ($parti.Count -ge 2) {
    $coda = '(?![A-Za-z0-9_])'
  }
  else {
    # nome da solo (Doom, Base, ...): serve un separatore; con / solo davanti a un nome di file
    $coda = '(?=\\|/[A-Za-z0-9_\-]+\.[A-Za-z0-9]+)'
  }
  $rx = New-Object Text.RegularExpressions.Regex(($prima + $nome + $coda), 'CultureInvariant')
  $regole.Add([pscustomobject]@{ Rx = $rx; A = $voce.A; Da = $voce.Da; Lung = $voce.Da.Length; Tipo = $voce.Tipo })
}
foreach ($f in $filesMap) { Add-Regola $f }
foreach ($d in ($dirs | Sort-Object { $_.Da.Length } -Descending)) { Add-Regola $d }
$regole = @($regole | Sort-Object @{ Expression = { if ($_.Tipo -eq 'File') { 0 } else { 1 } } }, @{ Expression = { $_.Lung }; Descending = $true })

$contaRegole = @{}
# filtro veloce: il testo ha qualche possibile primo segmento seguito da un separatore?
$primi = @($regole | ForEach-Object { ($_.Da -split '\\')[0] } | Select-Object -Unique | ForEach-Object { [regex]::Escape($_) })
$rxFiltro = New-Object Text.RegularExpressions.Regex(('(?:' + ($primi -join '|') + ')[\\/]'), 'CultureInvariant')
$letterali = New-Object Collections.Generic.List[string]
function Convert-Testo([string]$Testo, [bool]$Pas = $false, [string]$Nome = '') {
  if (-not $rxFiltro.IsMatch($Testo)) { return $Testo }
  # in un .pas la riga che inizia con // o { o (* o * e' un commento; il resto e' codice e le stringhe tra apici si saltano
  $riga = $Testo.TrimStart()
  $commento = ($riga.StartsWith('//') -or $riga.StartsWith('{') -or $riga.StartsWith('(*') -or $riga.StartsWith('*'))
  foreach ($r in $regole) {
    $Testo = $r.Rx.Replace($Testo, {
      param($m)
      if ($Pas -and -not $commento) {
        $davanti = $Testo.Substring(0, $m.Index)
        $apici = ($davanti.ToCharArray() | Where-Object { $_ -eq [char]39 }).Count
        if ($davanti.Contains('//') -eq $false -and ($apici % 2) -eq 1) {
          $script:letterali.Add(("{0}: {1}" -f $Nome, $Testo.Trim()))
          return $m.Value
        }
      }
      $sep = '\'
      if ($m.Value.Contains('/') -and -not $m.Value.Contains('\')) { $sep = '/' }
      $contaRegole[$r.Da] = 1 + [int]$contaRegole[$r.Da]
      return $r.A.Replace('\', $sep)
    })
  }
  return $Testo
}

# --- Percorsi relativi -------------------------------------------------------------------------------
$seg = '(?:\$\([A-Za-z0-9_]+\)|[A-Za-z0-9_\-]+(?:\.[A-Za-z0-9_\-]+)*)'
$rxRel = New-Object Text.RegularExpressions.Regex(('(?<![A-Za-z0-9_.$)\]\\/%~])((?:\.\.[\\/])+)(' + $seg + '(?:[\\/]' + $seg + ')*[\\/]?)?'), 'CultureInvariant')
$inesistenti = New-Object Collections.Generic.List[string]
$esistenti = New-Object Collections.Generic.HashSet[string] ([StringComparer]::OrdinalIgnoreCase)
foreach ($p in @(& git -c core.quotepath=off ls-files)) {
  $p = $p.Replace('/', '\')
  [void]$esistenti.Add($p)
  $i = $p.LastIndexOf('\')
  while ($i -gt 0) { $p = $p.Substring(0, $i); [void]$esistenti.Add($p); $i = $p.LastIndexOf('\') }
}
[void]$esistenti.Add('')
function Test-Esiste([string]$Rel) {
  if ($esistenti.Contains($Rel)) { return $true }
  $primo = ($Rel -split '\\')[0]
  return (@('bin', 'dcu', 'logs', 'Reference') -contains $primo)
}
$contaRel = 0
$esempi = New-Object Collections.Generic.List[string]

# Un percorso relativo gia' risolto (bersaglio esistente) e' una forma completa: le regole di testo non lo
# devono toccare (..\Base\x.inc tra due cartelle che si spostano insieme resta ..\Base\x.inc). Si sostituisce
# con un segnaposto (\x01 n \x02) fino alla fine del file.
$protetti = New-Object Collections.Generic.List[string]
function Proteggi([string]$Valore) {
  $protetti.Add($Valore)
  return ([string][char]1) + ($protetti.Count - 1) + ([string][char]2)
}
function Ripristina([string]$Testo) {
  if ($Testo.IndexOf([char]1) -lt 0) { return $Testo }
  return [regex]::Replace($Testo, '\x01(\d+)\x02', { param($m) $protetti[[int]$m.Groups[1].Value] })
}

function Convert-Relativi([string]$Testo, [string]$VecchiaDir, [string]$NuovaDir, [string]$Nome) {
  $vecchiaSegs = @(); if ($VecchiaDir -ne '') { $vecchiaSegs = @($VecchiaDir -split '\\') }
  $nuovaSegs = @(); if ($NuovaDir -ne '') { $nuovaSegs = @($NuovaDir -split '\\') }
  return $rxRel.Replace($Testo, {
    param($m)
    $ups = ([regex]::Matches($m.Groups[1].Value, '\.\.')).Count
    if ($ups -gt $vecchiaSegs.Count) { return $m.Value }   # sopra la radice: non e' un percorso del repository
    $sepc = '\'
    if ($m.Groups[1].Value.Contains('/') -and -not $m.Groups[1].Value.Contains('\')) { $sepc = '/' }
    $base = @(); if ($vecchiaSegs.Count - $ups -gt 0) { $base = @($vecchiaSegs[0..($vecchiaSegs.Count - $ups - 1)]) }
    $resto = $m.Groups[2].Value
    $fineSep = ($resto -ne '' -and ($resto.EndsWith('\') -or $resto.EndsWith('/')))
    $restoSegs = @(); if ($resto -ne '') { $restoSegs = @($resto.TrimEnd('\', '/') -split '[\\/]') }
    $vecchiaAbs = (@($base) + @($restoSegs)) -join '\'
    if (-not (Test-Esiste $vecchiaAbs)) { $script:inesistenti.Add(("{0}: {1}" -f $Nome, $m.Value)); return $m.Value }
    $nuovaAbs = Get-NuovoPercorso $vecchiaAbs
    # ne' il file ne' il bersaglio si spostano: il testo resta com'e' (anche se non e' la forma piu' breve)
    if ($nuovaAbs -ieq $vecchiaAbs -and $VecchiaDir -ieq $NuovaDir) { return (Proteggi $m.Value) }
    $nuovaAbsSegs = @(); if ($nuovaAbs -ne '') { $nuovaAbsSegs = @($nuovaAbs -split '\\') }
    $c = 0
    while ($c -lt $nuovaSegs.Count -and $c -lt $nuovaAbsSegs.Count -and $nuovaSegs[$c] -ieq $nuovaAbsSegs[$c]) { $c++ }
    $nuoviUp = $nuovaSegs.Count - $c
    $parti = @(); for ($i = 0; $i -lt $nuoviUp; $i++) { $parti += '..' }
    if ($c -lt $nuovaAbsSegs.Count) { $parti += $nuovaAbsSegs[$c..($nuovaAbsSegs.Count - 1)] }
    if ($parti.Count -eq 0) { $parti = @('.') }
    $nuovo = $parti -join $sepc
    if ($fineSep -or $resto -eq '') { $nuovo += $sepc }
    if ($nuovo -ne $m.Value) {
      $script:contaRel++
      if ($script:esempi.Count -lt 25) { $script:esempi.Add(("{0}: {1} -> {2}" -f $Nome, $m.Value, $nuovo)) }
    }
    return (Proteggi $nuovo)
  })
}

# --- File tracciati ---------------------------------------------------------------------------------
$tracciati = @(& git -c core.quotepath=off ls-files) | ForEach-Object { $_.Replace('/', '\') }
$estBinari = @('.gz', '.bmp', '.wad', '.lmp', '.sav', '.png', '.ico', '.exe', '.dll', '.res', '.zip', '.pk3', '.jpg', '.tga', '.pak', '.o', '.obj', '.bin', '.dat', '.lzh', '.mid', '.ogg', '.mp3', '.wav', '.scn', '.swd', '.dfm', '.ddp', '.cur', '.lib', '.a', '.dcu', '.map', '.drc', '.ttf', '.pcx', '.qvm', '.aas', '.bsp', '.roq', '.flc', '.fli', '.jcl', '.dcp', '.bpl')
$cambiati = 0
$esaminati = 0
$elencoCambiati = New-Object Collections.Generic.List[string]

foreach ($rel in $tracciati) {
  $ext = [IO.Path]::GetExtension($rel).ToLowerInvariant()
  if ($estBinari -contains $ext) { continue }
  $saltare = $false
  foreach ($x in $Escludi) { if ($rel -ieq $x -or $rel.StartsWith($x + '\', [StringComparison]::OrdinalIgnoreCase)) { $saltare = $true } }
  if ($saltare) { continue }
  $percorso = Join-Path $Radice $rel
  if (-not [IO.File]::Exists($percorso)) { continue }
  $bytes = [IO.File]::ReadAllBytes($percorso)
  if ([Array]::IndexOf($bytes, [byte]0) -ge 0) { continue }
  $esaminati++
  $testo = $latin1.GetString($bytes)
  $orig = $testo
  $protetti.Clear()

  $vecchiaDir = [IO.Path]::GetDirectoryName($rel); if ($null -eq $vecchiaDir) { $vecchiaDir = '' }
  $nuovoRel = Get-NuovoPercorso $rel
  $nuovaDir = [IO.Path]::GetDirectoryName($nuovoRel); if ($null -eq $nuovaDir) { $nuovaDir = '' }

  if ($ext -eq '.pas') {
    # solo le direttive di inclusione; poi le regole di testo riga per riga con riempimento
    $testo = [regex]::Replace($testo, '(?i)\{\$(?:I|INCLUDE|R|RESOURCE|L|LINK)\s[^}\r\n]*\}', {
      param($m) Convert-Relativi $m.Value $vecchiaDir $nuovaDir $rel
    })
    if ($rxFiltro.IsMatch($testo)) {
      $righe = $testo -split "`n", -1
      for ($i = 0; $i -lt $righe.Count; $i++) {
        $riga = $righe[$i]
        $nuova = Convert-Testo $riga $true $rel
        if ($nuova -ne $riga) {
          $cr = ''
          if ($nuova.EndsWith("`r")) { $cr = "`r"; $nuova = $nuova.Substring(0, $nuova.Length - 1); $riga = $riga.TrimEnd("`r") }
          if ($riga.StartsWith('{') -and $riga.EndsWith('}') -and $nuova.EndsWith('}')) {
            $delta = $nuova.Length - $riga.Length
            $corpo = $nuova.Substring(0, $nuova.Length - 1)
            if ($delta -gt 0) {
              $spazi = $corpo.Length - $corpo.TrimEnd(' ').Length
              $togli = [Math]::Min($delta, [Math]::Max(0, $spazi - 1))
              $corpo = $corpo.Substring(0, $corpo.Length - $togli)
            }
            elseif ($delta -lt 0) {
              $corpo = $corpo + (' ' * (-$delta))
            }
            $nuova = $corpo + '}'
          }
          $righe[$i] = $nuova + $cr
        }
      }
      $testo = $righe -join "`n"
    }
  }
  else {
    # nelle .patch i percorsi relativi sono quelli dei file modificati, non della patch
    if ($ext -ne '.patch') { $testo = Convert-Relativi $testo $vecchiaDir $nuovaDir $rel }
    $testo = Convert-Testo $testo
  }

  $testo = Ripristina $testo

  if ($nuovoRel -ieq 'docs\Strati.psd1') {
    # le chiavi del manifesto senza separatore ('Doom' = ..., Da = 'Speed') e le chiavi doppie dei programmi
    # che finiscono nella cartella della loro libreria (Libs\Keen e Keen -> Games\Keen)
    foreach ($d in $dirs) {
      if (($d.Da -split '\\').Count -eq 1) { $testo = $testo.Replace("'" + $d.Da + "'", "'" + $d.A + "'") }
    }
    $visti = @{}
    $uscita = New-Object Collections.Generic.List[string]
    foreach ($riga in ($testo -split "`n", -1)) {
      if ($riga -match "^\s*'[^']+'\s*=\s*'[^']+'\s*\r?$") {
        $chiave = $riga.Trim()
        if ($visti.ContainsKey($chiave)) { continue }
        $visti[$chiave] = 1
      }
      $uscita.Add($riga)
    }
    $testo = $uscita -join "`n"
  }

  if ($testo -cne $orig) {
    $cambiati++
    $elencoCambiati.Add($rel)
    if (-not $Prova) { [IO.File]::WriteAllBytes($percorso, $latin1.GetBytes($testo)) }
  }
}

Write-Host ("Fetta '{0}': {1} file di testo esaminati, {2} riscritti, {3} percorsi relativi cambiati" -f $Fetta, $esaminati, $cambiati, $contaRel)
foreach ($k in ($contaRegole.Keys | Sort-Object)) { Write-Host ("  {0,5}  {1}" -f $contaRegole[$k], $k) }
Write-Host ("Letterali di stringa nei .pas saltati: {0}; percorsi relativi verso cose che non esistono (lasciati): {1}" -f $letterali.Count, $inesistenti.Count)
if ($letterali.Count -gt 0) { $letterali | Sort-Object -Unique | ForEach-Object { Write-Host "  LETTERALE $_" } }
if ($inesistenti.Count -gt 0 -and $env:SPOSTA_VERBOSO) { $inesistenti | Sort-Object -Unique | Select-Object -First 60 | ForEach-Object { Write-Host "  INESISTENTE $_" } }
if ($Prova -or $env:SPOSTA_ESEMPI) { $esempi | ForEach-Object { Write-Host "  es: $_" } }
if ($Prova) { Write-Host 'Prova: niente scritto, niente spostato.'; return }
if ($SoloRiferimenti) { return }

# --- git mv -----------------------------------------------------------------------------------------
function Move-Albero([string]$Da, [string]$A, [string[]]$FileTracciati) {
  # FileTracciati: percorsi (dalla radice) dei file tracciati sotto $Da
  $dest = Join-Path $Radice $A
  $src = Join-Path $Radice $Da
  if (-not (Test-Path -LiteralPath $dest)) {
    $padre = Split-Path $dest
    if (-not (Test-Path -LiteralPath $padre)) { New-Item -ItemType Directory -Force -Path $padre | Out-Null }
    & git mv -- $Da $A
    if ($LASTEXITCODE -ne 0) { throw "git mv $Da $A fallito" }
    return
  }
  # la destinazione esiste (cartella condivisa da piu' vecchie cartelle): un file alla volta
  foreach ($f in $FileTracciati) {
    $nuovo = $A + $f.Substring($Da.Length)
    $padre = Split-Path (Join-Path $Radice $nuovo)
    if (-not (Test-Path -LiteralPath $padre)) { New-Item -ItemType Directory -Force -Path $padre | Out-Null }
    if (Test-Path -LiteralPath (Join-Path $Radice $nuovo)) { throw "Collisione: $nuovo esiste gia'" }
    & git mv -- $f $nuovo
    if ($LASTEXITCODE -ne 0) { throw "git mv $f $nuovo fallito" }
  }
}

# prima i file singoli (hanno la precedenza), poi le cartelle
foreach ($f in $filesMap) {
  $padre = Split-Path (Join-Path $Radice $f.A)
  if (-not (Test-Path -LiteralPath $padre)) { New-Item -ItemType Directory -Force -Path $padre | Out-Null }
  & git mv -- $f.Da $f.A
  if ($LASTEXITCODE -ne 0) { throw "git mv $($f.Da) $($f.A) fallito" }
}
$tracciatiOra = @(& git -c core.quotepath=off ls-files) | ForEach-Object { $_.Replace('/', '\') }
foreach ($d in $dirs) {
  $sotto = @($tracciatiOra | Where-Object { $_.StartsWith($d.Da + '\', [StringComparison]::OrdinalIgnoreCase) })
  if ($sotto.Count -eq 0 -and -not (Test-Path -LiteralPath (Join-Path $Radice $d.Da))) { Write-Host "  (niente da spostare: $($d.Da))"; continue }
  Move-Albero $d.Da $d.A $sotto
  Write-Host ("  spostata {0} -> {1} ({2} file tracciati)" -f $d.Da, $d.A, $sotto.Count)
}
foreach ($d in $dirs) {
  $resta = Join-Path $Radice $d.Da
  if (Test-Path -LiteralPath $resta) {
    $avanzi = @(Get-ChildItem -LiteralPath $resta -Recurse -File -Force | ForEach-Object { $_.FullName.Substring($Radice.Length + 1) })
    Write-Host ("  RIMASTA {0}: {1} file non tracciati (generati o ignorati): {2}" -f $d.Da, $avanzi.Count, (($avanzi | Select-Object -First 6) -join ', '))
  }
}
Write-Host 'Fatto. Controllare: git status, Tools\build.bat strati, build.'
