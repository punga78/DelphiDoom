<#
  Issue #219: controllo automatico degli strati delle librerie.

  Legge le clausole uses di ogni .pas (interface e implementation, commenti e stringhe tolti),
  attribuisce ogni unit usata alla sua cartella (area) e controlla il grafo tra aree contro il
  manifesto Libs\Strati.psd1 (leggibile: Libs\STRATI.md): uno strato puo' usare solo strati uguali
  o piu' bassi, un modulo puo' usare gli strati e i moduli che dichiara in Ammessi.

  Metodo (derivato dal censimento di docs\FRAMEWORK_CENSIMENTO.md, estendendolo):
   - nomi di unit duplicati: prima l'area del file (compresa la sua cartella Shim), poi i candidati;
     i candidati dello stesso gruppo (i quattro giochi id) contano come uno; se restano piu' aree
     e almeno una e' ammessa l'uso e' "ambiguo" (conteggiato, nessun arco); se nessuna lo e' e' una
     violazione. Le unit di una cartella Shim sono visibili solo alla libreria che la contiene.
   - {$IFDEF}: gli uses sotto una condizione contano come gli altri (composizione condizionale) ma
     sono marcati, elencati con la condizione e contati a parte nel riepilogo.
   - cicli: componenti fortemente connesse del grafo tra aree, senza gli archi dentro uno stesso
     modulo e senza gli archi gia' violazioni (che hanno un'eccezione o un errore a parte).
   - eccezioni: coppie (Da, A) con motivo, issue che le toglie e numero massimo di unit di arrivo,
     e cicli noti. Una violazione coperta e' "eccezione nota"; una non coperta (o oltre il massimo)
     e' nuova; un'eccezione senza piu' usi, o con meno unit del massimo, e' stantia.

  Uso:
    powershell -File Tools\Verifica\219\Controlla-Strati.ps1 [-Riepilogo] [-Dettaglio] [-Grafo]
                 [-Radice <cartella>] [-Manifesto <file.psd1>]

  Uscita: 0 nessuna violazione nuova (e nessuna eccezione stantia), 1 violazioni nuove, cicli nuovi
  o aree non assegnate, 2 solo eccezioni stantie (da togliere o da ridurre nel manifesto).
  -Riepilogo stampa i numeri per strato; -Dettaglio elenca anche ogni uso coperto da un'eccezione;
  -Grafo stampa gli archi tra aree. -Radice e -Manifesto servono alle prove (Tests\Data\Strati).
#>
param(
  [string]$Radice = '',
  [string]$Manifesto = '',
  [switch]$Riepilogo,
  [switch]$Dettaglio,
  [switch]$Grafo
)

$ErrorActionPreference = 'Stop'
if ($Radice -eq '') { $Radice = Join-Path $PSScriptRoot '..\..\..' }
$Radice = (Resolve-Path $Radice).Path.TrimEnd('\')
if ($Manifesto -eq '') { $Manifesto = Join-Path $Radice 'Libs\Strati.psd1' }
$manifest = Import-PowerShellDataFile -Path $Manifesto

# --- Manifesto ---------------------------------------------------------------------------------
$strati = @{}
foreach ($s in $manifest.Strati) { $strati[$s.Nome] = $s }
$gruppi = @{}
if ($manifest.Gruppi) { foreach ($k in $manifest.Gruppi.Keys) { $gruppi[$k] = $manifest.Gruppi[$k] } }
$escluse = @{}
foreach ($e in $manifest.Escluse) { $escluse[$e.ToLower()] = $true }
$aree = @{}
foreach ($k in $manifest.Aree.Keys) {
  $strato = $manifest.Aree[$k]
  if (-not $strati.ContainsKey($strato)) { throw "Manifesto: l'area '$k' usa lo strato sconosciuto '$strato'" }
  $aree[$k.TrimEnd('\')] = $strato
}
$radici = @{}
foreach ($k in $aree.Keys) { $radici[$k.Split('\')[0]] = $true }
$radici['Libs'] = $true
$areeOrdinate = @($aree.Keys | Sort-Object { $_.Length } -Descending)

function Get-Nodo([string]$Area) {
  if ($gruppi.ContainsKey($Area)) { return $gruppi[$Area] }
  return $Area
}

function Test-Ammesso([string]$DaStrato, [string]$AStrato) {
  if ($DaStrato -eq $AStrato) { return $true }
  $da = $strati[$DaStrato]
  $a = $strati[$AStrato]
  if ($da.Ammessi -and ($da.Ammessi -contains $AStrato)) { return $true }
  if ($a.Tipo -eq 'Strato') {
    if ($da.Tipo -eq 'Modulo') { return $true }
    return ($a.Livello -le $da.Livello)
  }
  return $false
}

function Get-AreaDelFile([string]$Relativo) {
  foreach ($k in $areeOrdinate) {
    if ($Relativo.StartsWith($k + '\', [StringComparison]::OrdinalIgnoreCase)) { return $k }
  }
  return $null
}

# --- Elenco dei file ---------------------------------------------------------------------------
$files = New-Object Collections.Generic.List[object]
$nonAssegnati = @{}
foreach ($r in ($radici.Keys | Sort-Object)) {
  $cartella = Join-Path $Radice $r
  if (-not (Test-Path $cartella)) { continue }
  foreach ($f in [IO.Directory]::EnumerateFiles($cartella, '*.pas', [IO.SearchOption]::AllDirectories)) {
    $rel = $f.Substring($Radice.Length + 1)
    $segmenti = $rel.Split('\')
    $saltare = $false
    $shim = $false
    for ($i = 1; $i -lt $segmenti.Length - 1; $i++) {
      if ($escluse.ContainsKey($segmenti[$i].ToLower())) { $saltare = $true }
      if ($segmenti[$i] -eq 'Shim') { $shim = $true }
    }
    if ($saltare) { continue }
    $area = Get-AreaDelFile $rel
    if ($null -eq $area) {
      $dirRel = $segmenti[0]
      if ($segmenti.Length -gt 2) { $dirRel = $segmenti[0] + '\' + $segmenti[1] }
      $nonAssegnati[$dirRel] = 1 + [int]$nonAssegnati[$dirRel]
      continue
    }
    $files.Add([pscustomobject]@{ Path = $f; Rel = $rel; Area = $area; Shim = $shim; Unit = [IO.Path]::GetFileNameWithoutExtension($f).ToLower() })
  }
}

# unit -> aree che la contengono (le unit degli Shim solo per l'area proprietaria)
$unitAree = @{}
$unitShim = @{}
foreach ($f in $files) {
  if ($f.Shim) {
    $k = $f.Area + '|' + $f.Unit
    $unitShim[$k] = $true
    continue
  }
  if (-not $unitAree.ContainsKey($f.Unit)) { $unitAree[$f.Unit] = New-Object Collections.Generic.List[string] }
  if (-not $unitAree[$f.Unit].Contains($f.Area)) { $unitAree[$f.Unit].Add($f.Area) }
}
$unitInArea = @{}
foreach ($f in $files) { $unitInArea[$f.Area + '|' + $f.Unit] = $true }

# --- Lettura delle clausole uses ---------------------------------------------------------------
$S1 = [string][char]1
$S2 = [string][char]2
$reDirettiva = New-Object Text.RegularExpressions.Regex('\{\$([^}]*)\}', 'Compiled')
$reSostituzione = $S1 + '${1}' + $S2
$reCommenti = New-Object Text.RegularExpressions.Regex("\{[^}]*\}|\(\*.*?\*\)|//[^\r\n]*|'(?:[^'\r\n]|'')*'", 'Singleline, Compiled')
$reTokenFile = New-Object Text.RegularExpressions.Regex('\u0001(?<d>[^\u0002]*)\u0002|\b(?<u>uses)\b(?<l>[^;]*);', 'IgnoreCase, Singleline, Compiled')
$reTokenLista = New-Object Text.RegularExpressions.Regex('\u0001(?<d>[^\u0002]*)\u0002|(?<n>[A-Za-z_][A-Za-z0-9_.]*)', 'Compiled')

function Update-Condizioni($Pila, [string]$Direttiva) {
  $d = $Direttiva.Trim()
  $parole = $d.Split(@(' ', "`t"), 2, [StringSplitOptions]::RemoveEmptyEntries)
  if ($parole.Count -eq 0) { return }
  $nome = $parole[0].ToUpper()
  $resto = ''
  if ($parole.Count -gt 1) { $resto = $parole[1].Trim() }
  switch ($nome) {
    'IFDEF' { $Pila.Add($resto) }
    'IFNDEF' { $Pila.Add('not ' + $resto) }
    'IF' { $Pila.Add($resto) }
    'IFOPT' { $Pila.Add($resto) }
    'ELSE' { if ($Pila.Count -gt 0) { $Pila[$Pila.Count - 1] = 'else(' + $Pila[$Pila.Count - 1] + ')' } }
    'ELSEIF' { if ($Pila.Count -gt 0) { $Pila[$Pila.Count - 1] = $resto } }
    'ENDIF' { if ($Pila.Count -gt 0) { $Pila.RemoveAt($Pila.Count - 1) } }
    'IFEND' { if ($Pila.Count -gt 0) { $Pila.RemoveAt($Pila.Count - 1) } }
  }
}

function Get-Uses([string]$Percorso) {
  $t = [IO.File]::ReadAllText($Percorso)
  $t = $reDirettiva.Replace($t, $reSostituzione)
  $t = $reCommenti.Replace($t, '')
  $pila = New-Object Collections.Generic.List[string]
  $risultato = New-Object Collections.Generic.List[object]
  foreach ($m in $reTokenFile.Matches($t)) {
    if ($m.Groups['d'].Success) { Update-Condizioni $pila $m.Groups['d'].Value; continue }
    foreach ($n in $reTokenLista.Matches($m.Groups['l'].Value)) {
      if ($n.Groups['d'].Success) { Update-Condizioni $pila $n.Groups['d'].Value; continue }
      $nome = $n.Groups['n'].Value
      if ($nome -eq 'in') { continue }
      $cond = $null
      if ($pila.Count -gt 0) { $cond = $pila -join ' & ' }
      $risultato.Add([pscustomobject]@{ Nome = $nome; Cond = $cond })
    }
  }
  return $risultato
}

# --- Archi -------------------------------------------------------------------------------------
# Ogni uso verso un'altra area: Da (area), File, Unit, A (nodo), Cond, DaStrato, AStrato, Ammesso
$usi = New-Object Collections.Generic.List[object]
$ambigui = New-Object Collections.Generic.List[object]
$violazioniAmbigue = New-Object Collections.Generic.List[object]
$shimUsi = @{}
$totaleUses = 0
$usiCondizionali = 0
foreach ($f in $files) {
  $daStrato = $aree[$f.Area]
  $visti = @{}
  foreach ($u in (Get-Uses $f.Path)) {
    $nome = $u.Nome.ToLower()
    $chiave = $nome + '|' + $u.Cond
    if ($visti.ContainsKey($chiave)) { continue }
    $visti[$chiave] = $true
    if (-not $unitAree.ContainsKey($nome)) { continue }
    if ($unitShim.ContainsKey($f.Area + '|' + $nome)) {
      # lo Shim della libreria nasconde una unit di un'altra area: dichiarato a parte, non e' un arco
      $shimUsi[$f.Area] = 1 + [int]$shimUsi[$f.Area]
      continue
    }
    if ($unitInArea.ContainsKey($f.Area + '|' + $nome)) { continue }
    $totaleUses++
    if ($u.Cond) { $usiCondizionali++ }
    $nodi = @($unitAree[$nome] | ForEach-Object { Get-Nodo $_ } | Select-Object -Unique)
    if ($nodi.Count -eq 1) {
      $areaA = $unitAree[$nome][0]
      $aStrato = $aree[$areaA]
      $usi.Add([pscustomobject]@{ Da = $f.Area; File = $f.Rel; Unit = $u.Nome; A = $nodi[0]; Cond = $u.Cond; DaStrato = $daStrato; AStrato = $aStrato; Ammesso = (Test-Ammesso $daStrato $aStrato) })
    }
    else {
      $ammessa = $false
      foreach ($a in $unitAree[$nome]) { if (Test-Ammesso $daStrato $aree[$a]) { $ammessa = $true } }
      $rec = [pscustomobject]@{ Da = $f.Area; File = $f.Rel; Unit = $u.Nome; Candidati = ($nodi -join ', '); Cond = $u.Cond; DaStrato = $daStrato }
      if ($ammessa) { $ambigui.Add($rec) } else { $violazioniAmbigue.Add($rec) }
    }
  }
}

# --- Violazioni ed eccezioni -------------------------------------------------------------------
$violazioni = @($usi | Where-Object { -not $_.Ammesso })
$eccezioni = @()
if ($manifest.Eccezioni) { $eccezioni = @($manifest.Eccezioni) }
$eccPar = @($eccezioni | Where-Object { $_.Da })
$eccCicli = @($eccezioni | Where-Object { $_.Ciclo })

$nuove = New-Object Collections.Generic.List[string]
$note = New-Object Collections.Generic.List[string]
$stantie = New-Object Collections.Generic.List[string]
$coperti = @{}

foreach ($e in $eccPar) {
  $mie = @($violazioni | Where-Object { $_.Da -eq $e.Da -and $_.A -eq $e.A })
  foreach ($v in $mie) { $coperti[$v.File + '|' + $v.Unit + '|' + $v.A] = $true }
  $unita = @($mie | ForEach-Object { $_.Unit.ToLower() } | Select-Object -Unique)
  $titolo = "{0} -> {1} (#{2})" -f $e.Da, $e.A, $e.Issue
  if ($mie.Count -eq 0) {
    $stantie.Add("ECCEZIONE STANTIA: $titolo non ha piu' usi fuori regola: toglierla da Libs\Strati.psd1. Motivo dichiarato: $($e.Motivo)")
    continue
  }
  $note.Add(("  eccezione nota: {0}: {1} unit, {2} usi - {3}" -f $titolo, $unita.Count, $mie.Count, $e.Motivo))
  if ($Dettaglio) { foreach ($v in $mie) { $note.Add(("      {0}: usa {1}" -f $v.File, $v.Unit)) } }
  if ($e.Massimo -and $unita.Count -gt [int]$e.Massimo) {
    $nuove.Add(("ECCEZIONE SUPERATA: {0}: {1} unit di arrivo invece di al piu' {2} (nuove dipendenze fuori regola): {3}" -f $titolo, $unita.Count, $e.Massimo, ($unita -join ', ')))
  }
  elseif ($e.Massimo -and $unita.Count -lt [int]$e.Massimo) {
    $stantie.Add(("ECCEZIONE RIDOTTA: {0}: {1} unit di arrivo invece di {2}: abbassare Massimo a {1} in Libs\Strati.psd1" -f $titolo, $unita.Count, $e.Massimo))
  }
}

foreach ($v in $violazioni) {
  if ($coperti.ContainsKey($v.File + '|' + $v.Unit + '|' + $v.A)) { continue }
  $c = ''
  if ($v.Cond) { $c = " [sotto {`$IFDEF $($v.Cond)}]" }
  $nuove.Add(("VIOLAZIONE: {0}: usa '{1}' ({2}, strato {3}) da {4} (strato {5}){6}" -f $v.File, $v.Unit, $v.A, $v.AStrato, $v.Da, $v.DaStrato, $c))
}
foreach ($v in $violazioniAmbigue) {
  $nuove.Add(("VIOLAZIONE AMBIGUA: {0}: usa '{1}' che sta solo in aree non ammesse a {2} (strato {3}): {4}" -f $v.File, $v.Unit, $v.Da, $v.DaStrato, $v.Candidati))
}
foreach ($k in ($nonAssegnati.Keys | Sort-Object)) {
  $nuove.Add(("AREA NON ASSEGNATA: {0} ({1} file .pas) non e' in Libs\Strati.psd1: assegnarla a uno strato o a un modulo" -f $k, $nonAssegnati[$k]))
}

# --- Cicli tra aree ----------------------------------------------------------------------------
$archi = @{}
foreach ($u in $usi) {
  if (-not $u.Ammesso) { continue }
  $nodoDa = Get-Nodo $u.Da
  if ($nodoDa -eq $u.A) { continue }
  if ($strati[$u.DaStrato].Tipo -eq 'Modulo' -and $u.DaStrato -eq $u.AStrato) { continue }
  if (-not $archi.ContainsKey($nodoDa)) { $archi[$nodoDa] = @{} }
  $archi[$nodoDa][$u.A] = $true
}
$script:indice = 0
$script:pilaT = New-Object Collections.Generic.Stack[string]
$script:idx = @{}
$script:low = @{}
$script:suPila = @{}
$script:sccs = New-Object Collections.Generic.List[object]
function Visit-Nodo([string]$N) {
  $script:idx[$N] = $script:indice
  $script:low[$N] = $script:indice
  $script:indice++
  $script:pilaT.Push($N)
  $script:suPila[$N] = $true
  if ($archi.ContainsKey($N)) {
    foreach ($w in @($archi[$N].Keys)) {
      if (-not $script:idx.ContainsKey($w)) {
        Visit-Nodo $w
        if ($script:low[$w] -lt $script:low[$N]) { $script:low[$N] = $script:low[$w] }
      }
      elseif ($script:suPila[$w]) {
        if ($script:idx[$w] -lt $script:low[$N]) { $script:low[$N] = $script:idx[$w] }
      }
    }
  }
  if ($script:low[$N] -eq $script:idx[$N]) {
    $comp = New-Object Collections.Generic.List[string]
    do {
      $w = $script:pilaT.Pop()
      $script:suPila[$w] = $false
      $comp.Add($w)
    } while ($w -ne $N)
    if ($comp.Count -gt 1) { $script:sccs.Add(@($comp | Sort-Object)) }
  }
}
foreach ($n in @($archi.Keys | Sort-Object)) { if (-not $script:idx.ContainsKey($n)) { Visit-Nodo $n } }

$cicliTrovati = @{}
foreach ($c in $script:sccs) { $cicliTrovati[($c -join ' < > ')] = $c }
$cicliCoperti = @{}
foreach ($e in $eccCicli) {
  $chiave = (@($e.Ciclo | Sort-Object) -join ' < > ')
  $titolo = "ciclo {0} (#{1})" -f ($e.Ciclo -join ' <-> '), $e.Issue
  if ($cicliTrovati.ContainsKey($chiave)) {
    $cicliCoperti[$chiave] = $true
    $note.Add("  eccezione nota: $titolo - $($e.Motivo)")
  }
  else {
    $stantie.Add("ECCEZIONE STANTIA: $titolo non esiste piu': toglierla da Libs\Strati.psd1. Motivo dichiarato: $($e.Motivo)")
  }
}
foreach ($k in ($cicliTrovati.Keys | Sort-Object)) {
  if (-not $cicliCoperti.ContainsKey($k)) {
    $nuove.Add("CICLO NUOVO tra le aree: " + ($cicliTrovati[$k] -join ' <-> '))
  }
}

# --- Uscita ------------------------------------------------------------------------------------
if ($Grafo) {
  Write-Host 'Archi tra aree (Da -> A: usi, unit distinte):'
  $gruppiArchi = $usi | Where-Object { $_.Da -ne $_.A } | Group-Object { (Get-Nodo $_.Da) + ' -> ' + $_.A }
  foreach ($g in ($gruppiArchi | Sort-Object Name)) {
    $un = @($g.Group | ForEach-Object { $_.Unit.ToLower() } | Select-Object -Unique).Count
    $marca = ''
    if (@($g.Group | Where-Object { -not $_.Ammesso }).Count -gt 0) { $marca = '  [FUORI REGOLA]' }
    Write-Host ("  {0}: {1} usi, {2} unit{3}" -f $g.Name, $g.Count, $un, $marca)
  }
}

if ($Riepilogo) {
  Write-Host 'Riepilogo per strato:'
  foreach ($s in $manifest.Strati) {
    $areeS = @($aree.Keys | Where-Object { $aree[$_] -eq $s.Nome } | Sort-Object)
    $nf = @($files | Where-Object { $aree[$_.Area] -eq $s.Nome }).Count
    Write-Host ("  {0,-10} {1,-7} {2,3} aree, {3,5} file: {4}" -f $s.Nome, $s.Tipo, $areeS.Count, $nf, (($areeS | ForEach-Object { if ($_ -like 'Libs\*') { $_.Substring(5) } else { $_ + '\' } }) -join ' '))
  }
  $nodiConArchi = @($usi | Where-Object { $_.Da -ne $_.A } | ForEach-Object { (Get-Nodo $_.Da) + '>' + $_.A } | Select-Object -Unique).Count
  Write-Host ("File letti: {0}; aree: {1}; uses verso unit del repository: {2} (di cui sotto IFDEF: {3}); archi tra aree: {4}" -f $files.Count, $aree.Count, $totaleUses, $usiCondizionali, $nodiConArchi)
  Write-Host ("Usi ambigui ma ammessi: {0}; usi ambigui non ammessi: {1}" -f $ambigui.Count, $violazioniAmbigue.Count)
  $shimTot = 0
  foreach ($v in $shimUsi.Values) { $shimTot += $v }
  $shimElenco = ($shimUsi.Keys | Sort-Object | ForEach-Object { "{0}: {1}" -f $_, $shimUsi[$_] }) -join '; '
  Write-Host ("Usi risolti da una cartella Shim (nascondono unit di altre aree): {0} ({1})" -f $shimTot, $shimElenco)
  Write-Host ("Usi fuori regola: {0} (coperti da eccezione: {1}); eccezioni dichiarate: {2} ({3} coppie, {4} cicli)" -f $violazioni.Count, $coperti.Count, $eccezioni.Count, $eccPar.Count, $eccCicli.Count)
  Write-Host ("Violazioni nuove: {0}; eccezioni stantie: {1}" -f $nuove.Count, $stantie.Count)
}

foreach ($n in $note) { Write-Host $n }
foreach ($s in $stantie) { Write-Host $s -ForegroundColor Yellow }
foreach ($n in $nuove) { Write-Host $n -ForegroundColor Red }

if ($nuove.Count -gt 0) {
  Write-Host ("FALLITO: {0} violazioni nuove" -f $nuove.Count) -ForegroundColor Red
  exit 1
}
if ($stantie.Count -gt 0) {
  Write-Host ("ECCEZIONI DA AGGIORNARE: {0}" -f $stantie.Count) -ForegroundColor Yellow
  exit 2
}
Write-Host ("OK: 0 violazioni nuove, {0} eccezioni dichiarate" -f $eccezioni.Count) -ForegroundColor Green
exit 0
