<#
  Issue #185, fase 2: codice comune delle prove meccaniche delle unit portate in copia unica (Prova-PMap.ps1,
  Prova-PMobj.ps1). Si carica con il punto (". Prova-Common.ps1") e si chiama Invoke-Prova.

  Per ogni gioco e per ogni routine della vecchia <Gioco>\<unit>.pas (presa dal commit di partenza con git show)
  prende il testo della routine unificata (le unit di Base o la unit delle regole del gioco), sostituisce ogni
  chiamata alle regole con il corpo della regola di quel gioco (tabella Expansions, scritta a mano; i corpi lunghi
  si leggono dalla unit del gioco con <<B:Metodo>>) e confronta il risultato con la routine vecchia, tolti
  commenti, spazi e maiuscole.

    UGUALE        il testo ricostruito coincide con la routine vecchia
    DICHIARATA    coincide dopo una riscrittura dichiarata nella tabella (Note = perche' e' equivalente)
    NON TESTUALE  la routine unificata ha un'altra forma: l'equivalenza e' un ragionamento, scritto in NotTextual
    DIVERSA       errore: la prima differenza e' stampata
#>

# testo senza commenti, spazi e maiuscole, su una riga sola
function Get-Normalized {
  param([string[]]$Lines)
  $inBrace = $false
  $sb = New-Object System.Text.StringBuilder
  foreach ($line in $Lines) {
    $text = $line
    if ($inBrace) {
      $close = $text.IndexOf('}')
      if ($close -lt 0) { continue }
      $text = $text.Substring($close + 1)
      $inBrace = $false
    }
    while ($true) {
      $open = $text.IndexOf('{')
      if ($open -lt 0 -or ($open + 1 -lt $text.Length -and $text[$open + 1] -eq '$')) { break }
      $close = $text.IndexOf('}', $open)
      if ($close -lt 0) { $text = $text.Substring(0, $open); $inBrace = $true; break }
      $text = $text.Substring(0, $open) + $text.Substring($close + 1)
    }
    $slash = $text.IndexOf('//')
    if ($slash -ge 0) { $text = $text.Substring(0, $slash) }
    [void]$sb.Append(($text -replace '\s+', '').ToLowerInvariant())
  }
  $sb.ToString()
}
function N([string]$Text) { Get-Normalized ($Text -split "`n") }

# le routine di primo livello dopo "implementation": nome -> righe (la seconda con lo stesso nome e' "nome#2")
function Get-Routines {
  param([string[]]$Lines)
  $routines = @{}
  $start = 0
  for ($i = 0; $i -lt $Lines.Length; $i++) { if ($Lines[$i] -match '^implementation\b') { $start = $i + 1; break } }
  $name = ''
  $body = New-Object System.Collections.Generic.List[string]
  for ($i = $start; $i -lt $Lines.Length; $i++) {
    $line = $Lines[$i]
    if ($name -eq '') {
      if ($line -match '^(?:class\s+)?(?:procedure|function)\s+([A-Za-z_][A-Za-z_0-9\.]*)') {
        $name = $Matches[1]
        if ($routines.ContainsKey($name)) { $name = "$name#2" }
        $body.Clear(); $body.Add($line)
      }
    } else {
      $body.Add($line)
      if ($line -match '^end;') { $routines[$name] = $body.ToArray(); $name = '' }
    }
  }
  $routines
}
# le righe tra il primo "begin" a colonna 0 e l'ultimo "end;" (Body) e quelle delle variabili locali (Vars)
function Get-Part {
  param([string[]]$Lines, [string]$Part)
  $b = [Array]::IndexOf($Lines, 'begin')
  if ($b -lt 0) { throw 'routine senza begin a colonna 0' }
  if ($Part -eq 'Vars') {
    $v = [Array]::IndexOf($Lines, 'var')
    if ($v -lt 0 -or $v -gt $b) { return '' }
    return Get-Normalized $Lines[($v + 1)..($b - 1)]
  }
  # una regola con il corpo vuoto ("begin" e "end;" di fila): l'intervallo andrebbe all'indietro
  if ($b + 1 -gt $Lines.Length - 2) { return '' }
  Get-Normalized $Lines[($b + 1)..($Lines.Length - 2)]
}

<#
  Invoke-Prova: il confronto. Parametri:
    Root        radice del repository
    Base        commit di partenza
    Games       giochi
    Unit        nome della vecchia unit (p_map, p_mobj)
    BaseFiles   le unit di Base con le routine unificate, in ordine di ricerca
    Extra       tabella lettera -> unit di Base i cui corpi si citano con <<lettera:Routine>> (p_map: S = p_secnodes)
    RulesUnit   nome del file della unit delle regole (uguale in ogni cartella di gioco)
    Class       nome della classe delle regole
    Expansions  le sostituzioni: F = il testo nella routine unificata; D = con che cosa si sostituisce in ogni
                gioco, salvo il gioco nominato; R = solo in queste routine (nome vecchio); All = tutte le
                occorrenze; Note = riscrittura dichiarata e perche' e' equivalente. Nel testo sostituito
                <<B:X>> = corpo del metodo X delle regole del gioco, <<V:X>> = le sue variabili locali, con
                "|strip=testo" (toglie un testo in coda), "|lead=testo" (in testa), "|exit=valore" (ogni
                "begin result := valore; exit; end;" torna "exit;"), "|ret=valore" (ogni "result := valore;"
                torna "exit;"), "|map=nome" (applica in ordine le coppie di sostituzioni di $Maps[nome], testo normalizzato)
    NotTextual  "Gioco|Routine" -> perche' e' equivalente
    Methods     "Gioco|Routine" o "Routine" -> metodo delle regole che e' quella routine del gioco (testo spostato
                con la sola intestazione cambiata)
    Alias       "Gioco|Routine" o "Routine" -> nome della routine unificata quando e' diverso
  Da' il numero delle routine DIVERSE.
#>
function Invoke-Prova {
  param(
    [string]$Root, [string]$Base, [string[]]$Games, [string]$Unit, [string[]]$BaseFiles, [hashtable]$Extra = @{},
    [string]$RulesUnit, [string]$Class, [object[]]$Expansions, [hashtable]$NotTextual = @{},
    [hashtable]$Methods = @{}, [hashtable]$Alias = @{}, [hashtable]$Maps = @{},
    [hashtable]$OldPaths = @{}   # gioco -> percorso (nel commit Base) della vecchia unit, quando non e' IdTech1/<Gioco>/<unit>.pas
  )
  $baseSets = foreach ($f in $BaseFiles) { [pscustomobject]@{ Name = ($f -replace '\.pas$', ''); Routines = (Get-Routines ([IO.File]::ReadAllLines((Join-Path $Root $f)))) } }
  $extraSets = @{}
  foreach ($k in $Extra.Keys) { $extraSets[$k] = Get-Routines ([IO.File]::ReadAllLines((Join-Path $Root $Extra[$k]))) }
  $bad = 0
  foreach ($game in $Games) {
    $oldPath = "IdTech1/$game/$Unit.pas"
    if ($OldPaths.ContainsKey($game)) { $oldPath = $OldPaths[$game] }
    $oldLines = @(& git -C $Root show "${Base}:$oldPath")
    if ($LASTEXITCODE -ne 0) { throw "git show ${Base}:$oldPath" }
    $oldRoutines = Get-Routines $oldLines
    $gameRoutines = Get-Routines ([IO.File]::ReadAllLines((Join-Path $Root "IdTech1\$game\$RulesUnit")))

    $expand = {
      param([string]$text)
      [regex]::Replace($text, '<<([A-Z]):([A-Za-z_0-9\.]+)((?:\|(?:strip|lead|exit|ret|map)=[^|]*?)*)>>', {
          param($m)
          $kind = $m.Groups[1].Value; $name = $m.Groups[2].Value
          if ($kind -eq 'B' -or $kind -eq 'V') { $lines = $gameRoutines["$Class.$name"] } else { $lines = $extraSets[$kind][$name] }
          if ($null -eq $lines) { throw "$game`: manca $name" }
          $part = 'Body'; if ($kind -eq 'V') { $part = 'Vars' }
          $r = Get-Part $lines $part
          foreach ($opt in ($m.Groups[3].Value -split '\|' | Where-Object { $_ -ne '' })) {
            $key, $value = $opt -split '=', 2
            $norm = N $value
            switch ($key) {
              'strip' { if (-not $r.EndsWith($norm)) { throw "$game $name`: non finisce con $value" }; $r = $r.Substring(0, $r.Length - $norm.Length) }
              'lead' { if (-not $r.StartsWith($norm)) { throw "$game $name`: non comincia con $value" }; $r = $r.Substring($norm.Length) }
              'exit' { $r = $r.Replace("beginresult:=$norm;exit;end;", 'exit;') }
              'ret' { $r = $r.Replace("result:=$norm;", 'exit;') }
              'map' { foreach ($pair in $Maps[$value]) { $r = $r.Replace((N $pair[0]), (N $pair[1])) } }
            }
          }
          $r
        })
    }

    $rows = foreach ($name in ($oldRoutines.Keys | Sort-Object)) {
      $old = Get-Normalized $oldRoutines[$name]
      $where = '-'; $new = $null
      $notes = New-Object System.Collections.Generic.List[string]
      $unified = $name
      if ($Alias.ContainsKey("$game|$name")) { $unified = $Alias["$game|$name"] } elseif ($Alias.ContainsKey($name)) { $unified = $Alias[$name] }
      $method = $null
      if ($Methods.ContainsKey("$game|$name")) { $method = $Methods["$game|$name"] } elseif ($Methods.ContainsKey($name)) { $method = $Methods[$name] }
      if ($null -ne $method -and $gameRoutines.ContainsKey("$Class.$method")) {
        # la routine e' un metodo delle regole del gioco: il testo vecchio con l'intestazione del metodo
        $new = Get-Normalized $gameRoutines["$Class.$method"]
        $where = "$game (metodo $method)"
        $head = ("class" + ($oldRoutines[$name][0] -replace '^(procedure|function)\s+[A-Za-z_0-9]+.*$', '$1') + "$Class.$method").ToLowerInvariant()
        $oldHead = (($oldRoutines[$name][0] -replace '^(procedure|function)\s+([A-Za-z_0-9]+).*$', '$1$2')).ToLowerInvariant()
        if ($new.StartsWith($head)) { $new = $oldHead + $new.Substring($head.Length) }
      } else {
        foreach ($set in $baseSets) { if ($null -eq $new -and $set.Routines.ContainsKey($unified)) { $new = Get-Normalized $set.Routines[$unified]; $where = $set.Name } }
        if ($null -eq $new -and $gameRoutines.ContainsKey($name)) { $new = Get-Normalized $gameRoutines[$name]; $where = "$game (propria)" }
      }
      $status = ''
      if ($NotTextual.ContainsKey("$game|$name")) { $status = 'NON TESTUALE'; $notes.Add($NotTextual["$game|$name"]) }
      elseif ($null -eq $new) { $status = 'DIVERSA'; $notes.Add('la routine non esiste piu''') }
      else {
        foreach ($e in $Expansions) {
          if ($e.ContainsKey('R') -and ($e.R -notcontains $name)) { continue }
          if ($e.ContainsKey($game)) { $with = $e[$game] } elseif ($e.ContainsKey('D')) { $with = $e.D } else { continue }
          if ($null -eq $with) { continue }
          $find = N $e.F
          $at = $new.IndexOf($find)
          if ($at -lt 0) { continue }
          $with = N (& $expand $with)
          if ($e.ContainsKey('All')) { $new = $new.Replace($find, $with) }
          else {
            if ($new.IndexOf($find, $at + 1) -ge 0) { throw "$game $name`: '$($e.F)' compare piu' volte" }
            $new = $new.Substring(0, $at) + $with + $new.Substring($at + $find.Length)
          }
          if ($e.ContainsKey('Note') -and -not $notes.Contains($e.Note)) { $notes.Add($e.Note) }
        }
        if ($new -eq $old) { if ($notes.Count -gt 0) { $status = 'DICHIARATA' } else { $status = 'UGUALE' } }
        else {
          $status = 'DIVERSA'
          $i = 0; while ($i -lt $new.Length -and $i -lt $old.Length -and $new[$i] -eq $old[$i]) { $i++ }
          $from = [Math]::Max(0, $i - 60)
          $notes.Clear()
          $notes.Add('vecchia: ...' + $old.Substring($from, [Math]::Min(160, $old.Length - $from)))
          $notes.Add('nuova:   ...' + $new.Substring($from, [Math]::Min(160, $new.Length - $from)))
        }
      }
      if ($status -eq 'DIVERSA') { $bad++ }
      [pscustomobject]@{ Routine = $name; Dove = $where; Esito = $status; Note = ($notes -join ' | ') }
    }
    Write-Host "==== $game"
    $rows | Sort-Object Esito, Routine | ForEach-Object {
      if ($_.Note -ne '') { Write-Host ('{0,-26} {1,-30} {2,-12} {3}' -f $_.Routine, $_.Dove, $_.Esito, $_.Note) } else { Write-Host ('{0,-26} {1,-30} {2}' -f $_.Routine, $_.Dove, $_.Esito) }
    }
    $summary = $rows | Group-Object Esito | ForEach-Object { '{0}: {1}' -f $_.Name, $_.Count }
    Write-Host ("---- {0}: {1} routine ({2})" -f $game, @($rows).Count, ($summary -join ', '))
  }
  $bad
}
