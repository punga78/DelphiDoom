<#
  Misura FINALE della Release 1 (issue #185 e figlie): vecchio contro nuovo a macchina scarica, con UN comando.

  Cosa fa, nell'ordine (ogni passo e' scritto nel log logs\MisuraFinale_<data>.log):
    1. Precondizioni (se una manca esce con 2 senza toccare nulla): master pulito e pubblicato (HEAD == origin/master),
       nessun processo di build, gioco o test (dcc32/dcc64/msbuild/bds, tutti gli eseguibili dei giochi, DelphiDoom.Tests*),
       nessun act_runner, nessun altro processo claude (salvo -IgnoraClaude), CPU libera, spazio libero su C:, WAD presenti,
       cartelle di lavoro assenti, lock dei giochi libero, commit "vecchi" esistenti.
    2. Crea con `git worktree add --detach` tre cartelle: il vecchio software (-VecchioSw in C:\ddold), il vecchio OpenGL
       (-VecchioGl in C:\ddoldgl) e una copia del NUOVO per le build OpenGL del registratore (C:\ddnewgl: cosi' master non
       viene toccato dalle patch di Tools\Verifica\opengl\Compila.ps1 e dai suoi eseguibili GLRECORD).
    3. Compila Doom32 Release Win32 e Win64 nel vecchio e nel nuovo (master, con "clean"), e con Compila.ps1 i GLDoom32 OLD e NEW.
    4. Pausa di -PausaMinuti senza altri processi (se ne compare uno il conto riparte).
    5. Tools\Misura-Giro.ps1 (4 combinazioni Win32/Win64 x modo 8/32, -Coppie coppie, -Demo) e poi
       Tools\Verifica\opengl\Misura-Gl.ps1 (-DemoGl, -SecondiGl, -CoppieGl coppie; varianti Base, Luci, Modelli, Voxel).
       Una combinazione rifiutata per dispersione o carico viene ripetuta UNA volta; il risultato resta "non affidabile" se
       viene rifiutata ancora, e il rapporto dice entrambi i tentativi.
    6. Scrive docs\MISURA_FINALE_<data>.md (tabelle, comandi, commit, Windows, carico, testi pronti per i commenti delle issue).
    7. Sempre, anche dopo un errore: rimuove i worktree creati (git worktree remove), gli eseguibili mis_* di prova in WorkRoot
       e i file temporanei (-ConservaCartelle li lascia).

  Non fa commit, non fa push, non scrive su GitHub. Il rapporto va committato da chi lo lancia.

  Uso (dal checkout principale, su master, nessun altro programma aperto che compili o giochi):
    powershell -NoProfile -ExecutionPolicy Bypass -File Tools\Misura-Finale.ps1 -DryRun       # solo il piano e le precondizioni
    powershell -NoProfile -ExecutionPolicy Bypass -File Tools\Misura-Finale.ps1                # la misura vera
    powershell -NoProfile -ExecutionPolicy Bypass -File Tools\Misura-Finale.ps1 -VecchioSw c6c8903c -VecchioGl 4282c434d `
      -Coppie 9 -Demo demo1 -DemoGl demo3 -SecondiGl 450 -CoppieGl 5

  Durata attesa: da 1,5 a 4 ore (build 4 x 5-15 min, pausa 5 min, 4 combinazioni software da 18 esecuzioni, 4 varianti OpenGL
  da 10 esecuzioni di al piu' -SecondiGl secondi). Lasciare la macchina ferma: niente browser, niente altri agenti.

  Codici di uscita: 0 tutte entro il 5%; 1 almeno una oltre il 5%; 3 almeno una non affidabile dopo il secondo tentativo;
  2 precondizione o passo fallito (rapporto parziale e marcato INCOMPLETO se si e' arrivati alla misura).

  Prova a secco: -DryRun controlla le precondizioni (sola lettura, nessun fetch) e stampa ogni comando che eseguirebbe; non crea
  cartelle, non compila, non avvia giochi.
#>
[CmdletBinding()]
param(
  [string]$VecchioSw = 'c6c8903c',
  [string]$VecchioGl = '4282c434d',
  [int]$Coppie = 9,
  [string]$Demo = 'demo1',
  [string]$DemoGl = 'demo3',
  [int]$CoppieGl = 5,
  [int]$SecondiGl = 450,
  [string[]]$VariantiGl = @('Base', 'Luci', 'Modelli', 'Voxel'),
  [string]$CartellaVecchioSw = 'C:\ddold',
  [string]$CartellaVecchioGl = 'C:\ddoldgl',
  [string]$CartellaNuovoGl = 'C:\ddnewgl',
  [string]$WorkRoot = 'C:\ddparity',
  [int]$PausaMinuti = 5,
  [double]$MinGbLiberi = 6,
  [switch]$DryRun,
  [switch]$SaltaSw,
  [switch]$SaltaGl,
  [switch]$SenzaClean,
  [switch]$ConservaCartelle,
  [switch]$IgnoraClaude
)

$ErrorActionPreference = 'Continue'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$adesso = Get-Date
$data = $adesso.ToString('yyyy-MM-dd')
$marca = $adesso.ToString('yyyyMMdd_HHmmss')
$VariantiGl = @($VariantiGl | ForEach-Object { $_ -split ',' } | Where-Object { $_ })
foreach ($variante in $VariantiGl) {
  if ('Base', 'Luci', 'Modelli', 'Voxel' -notcontains $variante) { throw "Variante OpenGL sconosciuta: $variante (Base, Luci, Modelli, Voxel)" }
}
$script:LogFile = ''
$script:Creati = New-Object System.Collections.Generic.List[string]
$script:Righe = New-Object System.Collections.Generic.List[object]
$script:Avvisi = New-Object System.Collections.Generic.List[string]
$script:Carico = New-Object System.Collections.Generic.List[string]
$script:Gametic = ''
$script:Mutex = $null
$script:Fase = 'precondizioni'
$tmp = Join-Path $env:TEMP "ddmisura_$marca"
$logs = Join-Path $root 'logs'
$report = Join-Path $root "docs\MISURA_FINALE_$data.md"
for ($n = 2; (Test-Path -LiteralPath $report) -and $n -lt 20; $n++) { $report = Join-Path $root "docs\MISURA_FINALE_${data}_$n.md" }
$script:ShaNuovo = ''
$script:OggettoNuovo = ''

function Write-Log {
  param([string]$Testo)
  $riga = '{0} {1}' -f (Get-Date).ToString('HH:mm:ss'), $Testo
  Write-Host $riga
  if ($script:LogFile -ne '') { Add-Content -LiteralPath $script:LogFile -Value $riga }
}

function Convert-Numero {
  param([string]$Testo)
  $t = $Testo.Trim().Replace(' ', '')
  if ($t.Contains(',') -and $t.Contains('.')) { $t = $t.Replace('.', '').Replace(',', '.') }
  elseif ($t.Contains(',')) { $t = $t.Replace(',', '.') }
  [double]::Parse($t.TrimStart('+'), [Globalization.CultureInfo]::InvariantCulture)
}

function Format-Percento {
  param($Valore)
  if ($null -eq $Valore) { return 'n.d.' }
  ([double]$Valore).ToString('+0.00;-0.00;+0.00', [Globalization.CultureInfo]::InvariantCulture) + '%'
}

function Format-Numero {
  param($Valore)
  if ($null -eq $Valore) { return 'n.d.' }
  ([double]$Valore).ToString('0.##', [Globalization.CultureInfo]::InvariantCulture)
}

function Get-Git {
  param([string[]]$Argomenti, [string]$Cartella = $root)
  $uscita = & git -C $Cartella @Argomenti 2>&1
  [pscustomobject]@{ Codice = $LASTEXITCODE; Testo = (($uscita | ForEach-Object { "$_" }) -join "`n").Trim() }
}

# Processi della catena che ci ha avviato: non sono "altri".
function Get-Antenati {
  $pidi = New-Object System.Collections.Generic.HashSet[int]
  $corrente = $PID
  for ($i = 0; $i -lt 12 -and $corrente -gt 0; $i++) {
    [void]$pidi.Add([int]$corrente)
    $p = Get-CimInstance Win32_Process -Filter "ProcessId=$corrente" -ErrorAction SilentlyContinue
    if ($null -eq $p) { break }
    $corrente = [int]$p.ParentProcessId
  }
  , $pidi
}

$script:PatternPesanti = '^(dcc32|dcc64|dccosx|msbuild|bds|cgrc|brcc32|rsvars|(GL)?(Doom|Heretic|Hexen|Strife)32.*|Radix32|SpeedHaste32|Xcom32|Keen32|Greed32|Speed32|Warcraft32|DelphiDoom\.Tests.*|mis_.*|ddc.*|act_runner.*)$'

function Get-Disturbo {
  param([switch]$ConClaude)
  $antenati = Get-Antenati
  $tutti = @(Get-Process -ErrorAction SilentlyContinue)
  $pesanti = @($tutti | Where-Object { $_.ProcessName -match $script:PatternPesanti -and -not $antenati.Contains([int]$_.Id) } |
    ForEach-Object { '{0}({1})' -f $_.ProcessName, $_.Id })
  $claude = @()
  if ($ConClaude) {
    $claude = @($tutti | Where-Object { $_.ProcessName -match '^claude' -and -not $antenati.Contains([int]$_.Id) } |
      ForEach-Object { '{0}({1})' -f $_.ProcessName, $_.Id })
  }
  $campioni = @()
  for ($i = 0; $i -lt 3; $i++) {
    $campioni += (Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'").PercentProcessorTime
    Start-Sleep -Milliseconds 700
  }
  [pscustomobject]@{ Pesanti = $pesanti; Claude = $claude; Cpu = [Math]::Round((($campioni | Measure-Object -Average).Average), 1) }
}

function Get-Precondizioni {
  $r = New-Object System.Collections.Generic.List[object]
  function Add-Controllo { param([string]$Nome, [bool]$Ok, [string]$Dettaglio) $r.Add([pscustomobject]@{ Nome = $Nome; Ok = $Ok; Dettaglio = $Dettaglio }) }

  $ramo = Get-Git @('rev-parse', '--abbrev-ref', 'HEAD')
  Add-Controllo 'checkout su master' ($ramo.Testo -eq 'master') ("ramo attuale: " + $ramo.Testo)
  $stato = Get-Git @('status', '--porcelain')
  Add-Controllo 'master pulito (nessuna modifica, nessun file non tracciato)' ($stato.Codice -eq 0 -and $stato.Testo -eq '') ($(if ($stato.Testo -eq '') { 'pulito' } else { (($stato.Testo -split "`n") | Select-Object -First 5) -join '; ' }))
  if (-not $DryRun) { [void](Get-Git @('fetch', 'origin', 'master', '--quiet')) }
  $contr = Get-Git @('rev-list', '--left-right', '--count', 'HEAD...origin/master')
  $ok = ($contr.Codice -eq 0 -and ($contr.Testo -split '\s+')[0] -eq '0' -and ($contr.Testo -split '\s+')[1] -eq '0')
  Add-Controllo 'master pubblicato (HEAD == origin/master)' $ok ("avanti/indietro: " + $contr.Testo + $(if ($DryRun) { ' (DryRun: nessun fetch, origin/master puo'' essere vecchio)' } else { '' }))
  foreach ($c in @(@('commit del vecchio software', $VecchioSw), @('commit del vecchio OpenGL', $VecchioGl))) {
    $e = Get-Git @('cat-file', '-e', ($c[1] + '^{commit}'))
    Add-Controllo $c[0] ($e.Codice -eq 0) $c[1]
  }
  foreach ($cartella in $CartellaVecchioSw, $CartellaVecchioGl, $CartellaNuovoGl) {
    Add-Controllo "cartella libera $cartella" (-not (Test-Path -LiteralPath $cartella)) ($(if (Test-Path -LiteralPath $cartella) { 'ESISTE: rimuoverla (git worktree remove) prima' } else { 'assente' }))
  }
  $drive = Get-PSDrive -Name ($root.Substring(0, 1)) -ErrorAction SilentlyContinue
  $libero = [Math]::Round($drive.Free / 1GB, 1)
  Add-Controllo ("spazio libero su {0}: almeno {1} GB" -f $root.Substring(0, 2), $MinGbLiberi) ($libero -ge $MinGbLiberi) ("{0} GB liberi (servono circa 3 worktree da 0,2 GB piu' dcu e bin: 3-5 GB)" -f $libero)
  foreach ($cartella in $CartellaVecchioSw, $CartellaVecchioGl, $CartellaNuovoGl, $WorkRoot) {
    $lettera = $cartella.Substring(0, 1)
    if ($lettera -ne $root.Substring(0, 1)) {
      $d = Get-PSDrive -Name $lettera -ErrorAction SilentlyContinue
      $g = if ($null -ne $d) { [Math]::Round($d.Free / 1GB, 1) } else { -1 }
      Add-Controllo ("spazio libero su ${lettera}: almeno $MinGbLiberi GB") ($g -ge $MinGbLiberi) "$g GB"
    }
  }
  $d = Get-Disturbo -ConClaude:(-not $IgnoraClaude)
  Add-Controllo 'nessun processo di build, gioco o test' ($d.Pesanti.Count -eq 0) ($(if ($d.Pesanti.Count -eq 0) { 'nessuno' } else { $d.Pesanti -join ', ' }))
  $runner = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match '^act_runner' })
  Add-Controllo 'nessun act_runner' ($runner.Count -eq 0) ($(if ($runner.Count -eq 0) { 'nessuno' } else { ($runner | ForEach-Object { $_.Id }) -join ', ' }))
  if ($IgnoraClaude) { Add-Controllo 'altri processi claude' $true 'controllo saltato con -IgnoraClaude (la misura e'' a rischio)' }
  else { Add-Controllo 'nessun altro processo claude' ($d.Claude.Count -eq 0) ($(if ($d.Claude.Count -eq 0) { 'nessuno' } else { $d.Claude -join ', ' })) }
  Add-Controllo 'CPU libera (media < 10%)' ($d.Cpu -lt 10) ("{0}%" -f $d.Cpu)
  foreach ($f in 'bin\Doom\DOOM1.WAD', 'Tools\build.bat', 'Tools\Misura-Giro.ps1', 'Tools\Misura-Coppie.ps1', 'Tools\Esegui-gioco.ps1', 'Tools\Verifica\opengl\Misura-Gl.ps1', 'Tools\Verifica\opengl\Compila.ps1') {
    Add-Controllo "presente $f" (Test-Path -LiteralPath (Join-Path $root $f)) ''
  }
  $bds = @('C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\rsvars.bat', 'C:\Program Files\Embarcadero\Studio\22.0\bin\rsvars.bat') | Where-Object { Test-Path $_ }
  Add-Controllo 'Delphi 11 (rsvars.bat)' (@($bds).Count -gt 0) (@($bds)[0])
  $lock = New-Object System.Threading.Mutex($false, 'Global\DelphiDoomEsecuzioneGioco')
  $libero = $false
  try { $libero = $lock.WaitOne(0) } catch [System.Threading.AbandonedMutexException] { $libero = $true }
  if ($libero) { $lock.ReleaseMutex() }
  $lock.Dispose()
  Add-Controllo 'lock globale dei giochi libero' $libero 'Global\DelphiDoomEsecuzioneGioco'
  $r
}

# Esegue un comando nativo, ne mostra e registra l'uscita; restituisce codice e righe. In DryRun stampa soltanto.
function Invoke-Comando {
  param([string]$Titolo, [string]$Eseguibile, [string[]]$Argomenti, [string]$Cartella = $root)
  Write-Log ("[{0}] {1} {2}   (cartella: {3})" -f $Titolo, $Eseguibile, ($Argomenti -join ' '), $Cartella)
  if ($DryRun) { return [pscustomobject]@{ Codice = 0; Righe = @() } }
  $righe = New-Object System.Collections.Generic.List[string]
  $prima = Get-Location
  try {
    Set-Location -LiteralPath $Cartella
    & $Eseguibile @Argomenti 2>&1 | ForEach-Object {
      $t = "$_"
      $righe.Add($t)
      Write-Host $t
      Add-Content -LiteralPath $script:LogFile -Value $t
    }
    $codice = $LASTEXITCODE
  }
  finally { Set-Location -LiteralPath $prima }
  [pscustomobject]@{ Codice = $codice; Righe = $righe.ToArray() }
}

function Invoke-Ps {
  param([string]$Titolo, [string[]]$Argomenti, [string]$Cartella = $root)
  Invoke-Comando -Titolo $Titolo -Eseguibile 'powershell' -Argomenti (@('-NoProfile', '-ExecutionPolicy', 'Bypass') + $Argomenti) -Cartella $Cartella
}

function New-Worktree {
  param([string]$Cartella, [string]$Commit)
  Write-Log "[worktree] git worktree add --detach $Cartella $Commit"
  if ($DryRun) { return }
  $g = Get-Git @('worktree', 'add', '--detach', $Cartella, $Commit)
  if ($g.Codice -ne 0) { throw "git worktree add fallito per ${Cartella}: $($g.Testo)" }
  $script:Creati.Add($Cartella)
}

function Remove-WorktreeCreati {
  if ($script:Creati.Count -eq 0) { return }
  if ($ConservaCartelle) { Write-Log ('Cartelle conservate (-ConservaCartelle): ' + ($script:Creati -join ', ')); return }
  foreach ($c in @($script:Creati)) {
    $fatto = $false
    for ($i = 0; $i -lt 3 -and -not $fatto; $i++) {
      $g = Get-Git @('worktree', 'remove', '--force', $c)
      if ($g.Codice -eq 0) { $fatto = $true } else { Start-Sleep -Seconds 5 }
    }
    if ($fatto) { Write-Log "worktree rimosso: $c" }
    else { Write-Log "ATTENZIONE: worktree NON rimosso: $c ($($g.Testo))"; $script:Avvisi.Add("worktree non rimosso: $c") }
  }
  [void](Get-Git @('worktree', 'prune'))
}

function Test-EseguibileNuovo {
  param([string]$Cartella, [string]$Piattaforma, [datetime]$Dopo)
  $exe = Join-Path $Cartella "bin\$Piattaforma\Release\Doom\Doom32.exe"
  $logBuild = if ($Piattaforma -eq 'Win64') { Join-Path $Cartella 'logs\Win64\Doom32.log' } else { Join-Path $Cartella 'logs\Doom32.log' }
  if (-not (Test-Path -LiteralPath $exe)) { return "manca $exe (vedere $logBuild)" }
  if ((Get-Item -LiteralPath $exe).LastWriteTime -lt $Dopo) { return "$exe non e' stato rifatto dalla build (vedere $logBuild)" }
  $errori = @()
  if (Test-Path -LiteralPath $logBuild) { $errori = @(Select-String -Path $logBuild -Pattern '\[(dcc32|dcc64) Error\]|\[Fatal Error\]|\bE\d{4}\b' | Select-Object -First 3) }
  if ($errori.Count -gt 0) { return "errori nel log $logBuild : " + (($errori | ForEach-Object { $_.Line.Trim() }) -join ' | ') }
  return ''
}

function Build-Doom {
  param([string]$Cartella, [string]$Etichetta)
  foreach ($piattaforma in 'Win32', 'Win64') {
    $inizio = Get-Date
    $argomenti = @('Doom32', 'Release', $piattaforma)
    if (-not $SenzaClean) { $argomenti += 'clean' }
    $r = Invoke-Comando -Titolo "build $Etichetta $piattaforma" -Eseguibile (Join-Path $Cartella 'Tools\build.bat') -Argomenti $argomenti -Cartella $Cartella
    if ($DryRun) { continue }
    $problema = Test-EseguibileNuovo -Cartella $Cartella -Piattaforma $piattaforma -Dopo $inizio
    if ($problema -ne '') { throw "build $Etichetta $piattaforma fallita: $problema" }
    if ($r.Codice -ne 0) { throw "build $Etichetta ${piattaforma}: codice di uscita $($r.Codice)" }
  }
}

function Wait-Pausa {
  Write-Log ("Pausa di {0} minuti senza altri processi (il conto riparte se ne compare uno)" -f $PausaMinuti)
  if ($DryRun) { return }
  $fine = (Get-Date).AddMinutes($PausaMinuti)
  $ripartenze = 0
  while ((Get-Date) -lt $fine) {
    Start-Sleep -Seconds 20
    $d = Get-Disturbo -ConClaude:(-not $IgnoraClaude)
    $altri = @($d.Pesanti) + @($d.Claude)
    if ($altri.Count -gt 0 -or $d.Cpu -ge 25) {
      $ripartenze++
      Write-Log ("durante la pausa: processi [{0}], CPU {1}%: il conto riparte ({2}/4)" -f ($altri -join ','), $d.Cpu, $ripartenze)
      if ($ripartenze -gt 4) { throw 'la macchina non e'' mai stata scarica: misura non possibile' }
      $fine = (Get-Date).AddMinutes($PausaMinuti)
    }
  }
  $d = Get-Disturbo -ConClaude:(-not $IgnoraClaude)
  $script:Carico.Add(("fine pausa {0}: CPU {1}%" -f (Get-Date).ToString('HH:mm'), $d.Cpu))
  Write-Log ("Pausa finita: CPU {0}%" -f $d.Cpu)
}

# --- lettura delle uscite degli strumenti di misura ---------------------------------------------------------------------

function Read-StatCoppie {
  param([string[]]$Righe)
  $v = $null; $n = $null; $dm = $null
  foreach ($r in $Righe) {
    if ($r -match 'vecchio:\s+min\s+([\d.,]+)\s+mediana\s+([\d.,]+)\s+media\s+([\d.,]+)\s+dispersione\s+([\d.,]+)%') { $v = @{ Min = (Convert-Numero $Matches[1]); Med = (Convert-Numero $Matches[2]); Disp = (Convert-Numero $Matches[4]) } }
    elseif ($r -match 'nuovo\s*:\s+min\s+([\d.,]+)\s+mediana\s+([\d.,]+)\s+media\s+([\d.,]+)\s+dispersione\s+([\d.,]+)%') { $n = @{ Min = (Convert-Numero $Matches[1]); Med = (Convert-Numero $Matches[2]); Disp = (Convert-Numero $Matches[4]) } }
    elseif ($r -match 'differenza:\s+mediane\s+([+-]?[\d.,]+)%\s+minimi\s+([+-]?[\d.,]+)%') { $dm = @{ Med = (Convert-Numero $Matches[1]); Min = (Convert-Numero $Matches[2]) } }
    elseif ($r -match 'differenza.*minimi\s+([+-]?[\d.,]+)%,\s+mediane\s+([+-]?[\d.,]+)%') { $dm = @{ Min = (Convert-Numero $Matches[1]); Med = (Convert-Numero $Matches[2]) } }
    if ($script:Gametic -eq '' -and $r -match '\((\d+) gametic\)') { $script:Gametic = $Matches[1] }
  }
  [pscustomobject]@{ Vecchio = $v; Nuovo = $n; Delta = $dm }
}

function Add-Riga {
  param([string]$Famiglia, [string]$Piattaforma, [string]$Modo, [string]$Variante, [int]$Tentativo, [string]$Esito, $Stat, [string]$Nota, [string]$Comando, [int]$NCoppie)
  $script:Righe.Add([pscustomobject]@{
      Famiglia = $Famiglia; Piattaforma = $Piattaforma; Modo = $Modo; Variante = $Variante; Tentativo = $Tentativo; Esito = $Esito
      VMin = $(if ($Stat -and $Stat.Vecchio) { $Stat.Vecchio.Min } else { $null }); VMed = $(if ($Stat -and $Stat.Vecchio) { $Stat.Vecchio.Med } else { $null })
      VDisp = $(if ($Stat -and $Stat.Vecchio) { $Stat.Vecchio.Disp } else { $null })
      NMin = $(if ($Stat -and $Stat.Nuovo) { $Stat.Nuovo.Min } else { $null }); NMed = $(if ($Stat -and $Stat.Nuovo) { $Stat.Nuovo.Med } else { $null })
      NDisp = $(if ($Stat -and $Stat.Nuovo) { $Stat.Nuovo.Disp } else { $null })
      DMin = $(if ($Stat -and $Stat.Delta) { $Stat.Delta.Min } else { $null }); DMed = $(if ($Stat -and $Stat.Delta) { $Stat.Delta.Med } else { $null })
      Nota = $Nota; Comando = $Comando; Coppie = $NCoppie
    })
}

function ConvertTo-Esito {
  param([string]$Verdetto)
  if ($Verdetto -match 'entro') { return 'entro il 5%' }
  if ($Verdetto -match '(?i)oltre') { return 'oltre il 5%' }
  if ($Verdetto -match 'non affidabile') { return 'non affidabile' }
  return 'errore'
}

function Read-BlocchiGiro {
  param([string]$File)
  $blocchi = New-Object System.Collections.Generic.List[object]
  $corrente = $null
  foreach ($r in (Get-Content -LiteralPath $File)) {
    if ($r -match '^=== (Win32|Win64) modo (8|32) : (.*)$') {
      $corrente = @{ P = $Matches[1]; M = $Matches[2]; V = $Matches[3]; Righe = (New-Object System.Collections.Generic.List[string]) }
      $blocchi.Add($corrente)
    }
    elseif ($null -ne $corrente) { $corrente.Righe.Add($r) }
  }
  , $blocchi.ToArray()
}

function Register-Giro {
  param([string]$File, [int]$Tentativo, [string]$Comando)
  $registrate = @()
  foreach ($b in (Read-BlocchiGiro $File)) {
    $righe = $b.Righe.ToArray()
    $stat = Read-StatCoppie $righe
    $esito = ConvertTo-Esito $b.V
    $nota = (($righe | Where-Object { $_ -match '^(Prima|Dopo):|misura non affidabile:|ATTENZIONE' }) -join ' / ')
    foreach ($c in ($righe | Where-Object { $_ -match '^(Prima|Dopo):' })) { $script:Carico.Add(('SW {0} modo {1}: {2}' -f $b.P, $b.M, $c)) }
    Add-Riga 'Software' $b.P $b.M 'Doom32' $Tentativo $esito $stat $nota $Comando $Coppie
    $registrate += [pscustomobject]@{ P = $b.P; M = $b.M; Esito = $esito }
  }
  $registrate
}

# Il giro OpenGL puo' bloccare Windows (visto con il driver grafico della VM): il rapporto parziale e' scritto dopo ogni passo.
function Save-Parziale {
  if ($DryRun -or $script:Righe.Count -eq 0) { return }
  try { Write-Rapporto -Stato 'IN CORSO (parziale: salvato durante la misura, la fine non e'' stata raggiunta)' -ShaNuovo $script:ShaNuovo -OggettoNuovo $script:OggettoNuovo }
  catch { Write-Log "rapporto parziale non scritto: $($_.Exception.Message)" }
}

function Invoke-MisuraSoftware {
  $comandoBase = '-File Tools\Misura-Giro.ps1 -RadiceVecchia {0} -Coppie {1} -Demo {2} -WorkRoot {3}' -f $CartellaVecchioSw, $Coppie, $Demo, $WorkRoot
  $file = Join-Path $tmp 'giro1.txt'
  $argomenti = @('-File', (Join-Path $root 'Tools\Misura-Giro.ps1'), '-RadiceVecchia', $CartellaVecchioSw, '-Coppie', "$Coppie", '-Demo', $Demo, '-WorkRoot', $WorkRoot, '-Riepilogo', $file)
  $r = Invoke-Ps -Titolo 'misura software (Misura-Giro)' -Argomenti $argomenti
  if ($DryRun) {
    Write-Log '[misura software] se una combinazione e'' rifiutata: pausa di 1 minuto e UNA ripetizione con -Piattaforme <p> -Modi <m>'
    return
  }
  if (-not (Test-Path -LiteralPath $file)) { throw 'Misura-Giro non ha scritto il riepilogo' }
  $primo = Register-Giro -File $file -Tentativo 1 -Comando $comandoBase
  foreach ($x in @($primo | Where-Object { $_.Esito -eq 'non affidabile' -or $_.Esito -eq 'errore' })) {
    Write-Log ("RIFIUTATA {0} modo {1} ({2}): pausa di 1 minuto e secondo tentativo" -f $x.P, $x.M, $x.Esito)
    Start-Sleep -Seconds 60
    $file2 = Join-Path $tmp ("giro2_{0}_{1}.txt" -f $x.P, $x.M)
    $arg2 = @('-File', (Join-Path $root 'Tools\Misura-Giro.ps1'), '-RadiceVecchia', $CartellaVecchioSw, '-Coppie', "$Coppie", '-Demo', $Demo, '-WorkRoot', $WorkRoot, '-Riepilogo', $file2, '-Piattaforme', $x.P, '-Modi', $x.M)
    [void](Invoke-Ps -Titolo ("misura software, secondo tentativo {0} modo {1}" -f $x.P, $x.M) -Argomenti $arg2)
    if (Test-Path -LiteralPath $file2) { [void](Register-Giro -File $file2 -Tentativo 2 -Comando ($comandoBase + " -Piattaforme $($x.P) -Modi $($x.M)")) }
  }
  Save-Parziale
}

function Register-Gl {
  param([string]$Variante, [int]$Tentativo, $Risultato, [string]$Comando)
  $stat = Read-StatCoppie $Risultato.Righe
  $esito = switch ($Risultato.Codice) { 0 { 'entro il 5%' } 1 { 'oltre il 5%' } 3 { 'non affidabile' } default { 'errore' } }
  $nota = (($Risultato.Righe | Where-Object { $_ -match 'MISURA NON AFFIDABILE|^coppia' }) -join ' / ')
  Add-Riga 'OpenGL' 'Win32' 'GL software della VM' $Variante $Tentativo $esito $stat $nota $Comando $CoppieGl
  $esito
}

function Invoke-MisuraGl {
  $script = Join-Path $CartellaNuovoGl 'Tools\Verifica\opengl\Misura-Gl.ps1'
  foreach ($variante in $VariantiGl) {
    $extra = switch ($variante) { 'Luci' { @('-Lights') } 'Modelli' { @('-Models') } 'Voxel' { @('-Voxels') } default { @() } }
    $argomenti = @('-File', $script, '-Game', 'GLDoom', '-Demo', $DemoGl, '-Pairs', "$CoppieGl", '-Seconds', "$SecondiGl") + $extra
    $comando = 'Tools\Verifica\opengl\Misura-Gl.ps1 -Game GLDoom -Demo {0} -Pairs {1} -Seconds {2} {3}' -f $DemoGl, $CoppieGl, $SecondiGl, ($extra -join ' ')
    $d = Get-Disturbo -ConClaude:(-not $IgnoraClaude)
    $script:Carico.Add(('GL {0}: prima CPU {1}%, processi [{2}]' -f $variante, $d.Cpu, (@($d.Pesanti) + @($d.Claude) -join ',')))
    $r = Invoke-Ps -Titolo "misura OpenGL $variante" -Argomenti $argomenti -Cartella $CartellaNuovoGl
    if ($DryRun) { continue }
    $esito = Register-Gl -Variante $variante -Tentativo 1 -Risultato $r -Comando $comando
    if ($esito -eq 'non affidabile' -or $esito -eq 'errore') {
      Write-Log "RIFIUTATA OpenGL $variante ($esito): pausa di 1 minuto e secondo tentativo"
      Start-Sleep -Seconds 60
      $r2 = Invoke-Ps -Titolo "misura OpenGL $variante (secondo tentativo)" -Argomenti $argomenti -Cartella $CartellaNuovoGl
      [void](Register-Gl -Variante $variante -Tentativo 2 -Risultato $r2 -Comando $comando)
    }
    Save-Parziale
  }
}

# --- rapporto -----------------------------------------------------------------------------------------------------------

function Get-RigheFinali {
  # per ogni combinazione l'ultimo tentativo
  $chiavi = $script:Righe | ForEach-Object { '{0}|{1}|{2}|{3}' -f $_.Famiglia, $_.Piattaforma, $_.Modo, $_.Variante } | Select-Object -Unique
  foreach ($k in $chiavi) {
    $p = $k -split '\|'
    $script:Righe | Where-Object { $_.Famiglia -eq $p[0] -and $_.Piattaforma -eq $p[1] -and $_.Modo -eq $p[2] -and $_.Variante -eq $p[3] } | Sort-Object Tentativo | Select-Object -Last 1
  }
}

function Format-Tabella {
  param($Righe)
  $s = New-Object System.Text.StringBuilder
  [void]$s.AppendLine('| Piattaforma / modo | Variante | Tent. | Minimo vecchio | Minimo nuovo | Mediana vecchia | Mediana nuova | Delta minimi | Delta mediane | Dispersione vecchio / nuovo | Verdetto |')
  [void]$s.AppendLine('|---|---|---|---|---|---|---|---|---|---|---|')
  foreach ($r in $Righe) {
    [void]$s.AppendLine(('| {0} {1} | {2} | {3} | {4} | {5} | {6} | {7} | {8} | {9} | {10}% / {11}% | {12} |' -f $r.Piattaforma, $r.Modo, $r.Variante, $r.Tentativo,
        (Format-Numero $r.VMin), (Format-Numero $r.NMin), (Format-Numero $r.VMed), (Format-Numero $r.NMed),
        (Format-Percento $r.DMin), (Format-Percento $r.DMed), (Format-Numero $r.VDisp), (Format-Numero $r.NDisp), $r.Esito))
  }
  $s.ToString()
}

function New-TestoCommento {
  param([string]$Famiglia, $Finali, [string]$ShaNuovo, [string]$Pausa)
  $righe = @($Finali | Where-Object { $_.Famiglia -eq $Famiglia })
  if ($righe.Count -eq 0) { return '(nessuna misura di questa famiglia)' }
  $tutteOk = (@($righe | Where-Object { $_.Esito -ne 'entro il 5%' }).Count -eq 0)
  $dispMax = ($righe | ForEach-Object { $_.VDisp } | Measure-Object -Maximum).Maximum
  if ($Famiglia -eq 'Software') {
    $t = "Misura a coppie a macchina scarica (CPU {0}%, nessun altro processo; il {1}, dopo una pausa di {2} minuti) di Doom32 Release: vecchio {3} contro master {4}, {5} coppie alternate, {6} ({7} gametic). " -f $script:CpuInizio, $data, $PausaMinuti, $VecchioSw, $ShaNuovo, $Coppie, $Demo, $script:Gametic
    $parti = foreach ($r in $righe) { '{0} modo {1}: minimi {2}, mediane {3}, dispersione del vecchio {4}%{5}' -f $r.Piattaforma, $r.Modo, (Format-Percento $r.DMin), (Format-Percento $r.DMed), (Format-Numero $r.VDisp), $(if ($r.Esito -ne 'entro il 5%') { " ($($r.Esito))" } else { '' }) }
    $t += ($parti -join '. ') + '. '
  }
  else {
    $t = "Misura a coppie dell'OpenGL (GLDoom32 Release Win32, vecchio {0} contro master {1}, {2}, realtic, {3}, macchina scarica, pausa di {4} minuti): " -f $VecchioGl, $ShaNuovo, $DemoGl, $script:TipoMacchina, $PausaMinuti
    $parti = foreach ($r in $righe) { '{0} ({1} coppie) minimi {2}, mediane {3}, dispersione {4}% / {5}%{6}' -f $r.Variante, $r.Coppie, (Format-Percento $r.DMin), (Format-Percento $r.DMed), (Format-Numero $r.VDisp), (Format-Numero $r.NDisp), $(if ($r.Esito -ne 'entro il 5%') { " ($($r.Esito))" } else { '' }) }
    $t += ($parti -join '; ') + '. '
  }
  if ($tutteOk) { $t += 'Tutte entro il 5% con dispersione sotto il 3%. ' } else { $t += 'ATTENZIONE: almeno una combinazione non e'' entro il 5% o non e'' affidabile (vedi il rapporto docs\MISURA_FINALE_' + $data + '.md). ' }
  $t + "Positivo = il nuovo e' piu' lento."
}

function Write-Rapporto {
  param([string]$Stato, [string]$ShaNuovo, [string]$OggettoNuovo)
  $os = Get-CimInstance Win32_OperatingSystem
  $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
  $sis = Get-CimInstance Win32_ComputerSystem
  $finali = @(Get-RigheFinali)
  $oltre = @($finali | Where-Object { $_.Esito -eq 'oltre il 5%' }).Count
  $non = @($finali | Where-Object { $_.Esito -ne 'oltre il 5%' -and $_.Esito -ne 'entro il 5%' }).Count
  $entro = @($finali | Where-Object { $_.Esito -eq 'entro il 5%' }).Count
  $s = New-Object System.Text.StringBuilder
  [void]$s.AppendLine("# Misura finale della Release 1 ($data)")
  [void]$s.AppendLine('')
  [void]$s.AppendLine(('Prodotto da `Tools\Misura-Finale.ps1` (issue #185 e figlie #40, #244, #245, #246, #247, #177, #249). Stato del rapporto: **{0}**.' -f $Stato))
  [void]$s.AppendLine('')
  [void]$s.AppendLine('## Esito')
  [void]$s.AppendLine('')
  [void]$s.AppendLine("- Combinazioni: $($finali.Count) (entro il 5%: $entro, oltre il 5%: $oltre, non affidabili o in errore: $non).")
  [void]$s.AppendLine('- Regola: il nuovo e'' "entro il 5%" se minimo E mediana del nuovo non superano di piu'' del 5% quelli del vecchio e la dispersione ((max-min)/min) del vecchio e'' al massimo il 3%; con CPU occupata o altri processi pesanti lo strumento rifiuta il verdetto ("non affidabile"). Positivo = il nuovo e'' piu'' lento.')
  [void]$s.AppendLine('- Dove un tentativo e'' stato rifiutato si e'' ripetuto UNA volta (colonna Tent.): sono riportati entrambi.')
  [void]$s.AppendLine('')
  [void]$s.AppendLine('## Chi e cosa')
  [void]$s.AppendLine('')
  [void]$s.AppendLine('| Voce | Valore |')
  [void]$s.AppendLine('|---|---|')
  [void]$s.AppendLine("| Nuovo (master) | $ShaNuovo $OggettoNuovo |")
  [void]$s.AppendLine("| Vecchio software (Doom32) | $VecchioSw |")
  [void]$s.AppendLine("| Vecchio OpenGL (GLDoom32) | $VecchioGl |")
  [void]$s.AppendLine("| Windows | $($os.Caption) $($os.Version) (build $($os.BuildNumber)) |")
  [void]$s.AppendLine("| Macchina | $($sis.Manufacturer) $($sis.Model); $($cpu.Name.Trim()), $($cpu.NumberOfLogicalProcessors) processori logici; RAM $([Math]::Round($sis.TotalPhysicalMemory / 1GB, 1)) GB |")
  [void]$s.AppendLine("| Carico a inizio misura | CPU $($script:CpuInizio)%, nessun processo pesante, nessun altro claude, nessun act_runner (precondizioni controllate) |")
  [void]$s.AppendLine("| Pausa prima della misura | $PausaMinuti minuti |")
  [void]$s.AppendLine("| Avvio / fine | $($adesso.ToString('yyyy-MM-dd HH:mm')) / $((Get-Date).ToString('yyyy-MM-dd HH:mm')) |")
  [void]$s.AppendLine('')
  [void]$s.AppendLine('## Software: Doom32 Release, vecchio contro nuovo (realtic della demo, piu'' basso = piu'' veloce)')
  [void]$s.AppendLine('')
  [void]$s.AppendLine(('Demo `{0}` ({1} gametic), {2} coppie alternate per combinazione.' -f $Demo, $script:Gametic, $Coppie))
  [void]$s.AppendLine('')
  [void]$s.AppendLine('Riga di comando di ogni esecuzione (`Tools\Misura-Coppie.ps1`, cartella di lavoro `' + $WorkRoot + '\Doom`, configurazione fissa `p8.ini`/`p32.ini` 640x480):')
  [void]$s.AppendLine('')
  [void]$s.AppendLine('```')
  [void]$s.AppendLine("Doom32.exe -iwad DOOM1.WAD -config p<8|32>.ini -dontsavedefaults -nomusic -nosound -noblit -timedemo $Demo")
  [void]$s.AppendLine('powershell -NoProfile -File Tools\Misura-Giro.ps1 -RadiceVecchia ' + $CartellaVecchioSw + " -Coppie $Coppie -Demo $Demo")
  [void]$s.AppendLine('```')
  [void]$s.AppendLine('')
  $sw = @($script:Righe | Where-Object { $_.Famiglia -eq 'Software' } | Sort-Object Piattaforma, Modo, Tentativo)
  if ($sw.Count -gt 0) { [void]$s.AppendLine((Format-Tabella $sw)) } else { [void]$s.AppendLine('_Nessuna misura software in questo rapporto._') }
  [void]$s.AppendLine('')
  [void]$s.AppendLine('## OpenGL: GLDoom32 Release Win32 con registratore dormiente (`GLRECORD`, senza `-glrecord`)')
  [void]$s.AppendLine('')
  [void]$s.AppendLine(('Demo `{0}`, realtic scritti dal gioco, {1} coppie per variante, al piu'' {2} secondi per esecuzione, {3}.' -f $DemoGl, $CoppieGl, $SecondiGl, $script:TipoMacchina))
  [void]$s.AppendLine('')
  [void]$s.AppendLine('```')
  [void]$s.AppendLine("GLDoom32_G<OLD|NEW>.exe -iwad DOOM1.WAD -timedemo $DemoGl -windowed -nosound -nomusic -nomouse -nojoystick -nointerpolate [-devparm -file <PK3 della variante>]")
  [void]$s.AppendLine("Tools\Verifica\opengl\Misura-Gl.ps1 -Game GLDoom -Demo $DemoGl -Pairs $CoppieGl -Seconds $SecondiGl [-Lights|-Models|-Voxels]")
  [void]$s.AppendLine('```')
  [void]$s.AppendLine('')
  $gl = @($script:Righe | Where-Object { $_.Famiglia -eq 'OpenGL' } | Sort-Object Variante, Tentativo)
  if ($gl.Count -gt 0) { [void]$s.AppendLine((Format-Tabella $gl)) } else { [void]$s.AppendLine('_Nessuna misura OpenGL in questo rapporto._') }
  [void]$s.AppendLine('')
  [void]$s.AppendLine('Varianti: Base = nessun pacchetto; Luci = `Tests\Data\LightsGl`; Modelli = `Tests\Data\ModelsGl`; Voxel = `Tests\Data\VoxelsGl`.')
  [void]$s.AppendLine('')
  [void]$s.AppendLine('## Carico osservato')
  [void]$s.AppendLine('')
  foreach ($c in $script:Carico) { [void]$s.AppendLine('- ' + $c) }
  if ($script:Carico.Count -eq 0) { [void]$s.AppendLine('- (nessuna riga)') }
  [void]$s.AppendLine('')
  if ($script:Avvisi.Count -gt 0) {
    [void]$s.AppendLine('## Avvisi')
    [void]$s.AppendLine('')
    foreach ($a in $script:Avvisi) { [void]$s.AppendLine('- ' + $a) }
    [void]$s.AppendLine('')
  }
  [void]$s.AppendLine('## Testi pronti per i commenti delle issue')
  [void]$s.AppendLine('')
  [void]$s.AppendLine('Sono i valori da mettere al posto di `<NUMERO MISURA SW>` e `<NUMERO MISURA GL>` di `docs\CHIUSURA_RELEASE1.md`.')
  [void]$s.AppendLine('')
  [void]$s.AppendLine('**Software** (issue #40, #185, #244, #245, #246, #247):')
  [void]$s.AppendLine('')
  [void]$s.AppendLine('> ' + (New-TestoCommento -Famiglia 'Software' -Finali $finali -ShaNuovo $ShaNuovo))
  [void]$s.AppendLine('')
  [void]$s.AppendLine('**OpenGL** (issue #177, #248, #249, #250):')
  [void]$s.AppendLine('')
  [void]$s.AppendLine('> ' + (New-TestoCommento -Famiglia 'OpenGL' -Finali $finali -ShaNuovo $ShaNuovo))
  [void]$s.AppendLine('')
  [void]$s.AppendLine('## Non coperto da questa misura')
  [void]$s.AppendLine('')
  [void]$s.AppendLine('- Heretic, Hexen e Strife (software e GL), Radix32 e SpeedHaste32: non misurati (stessa regola, `-Game` di `Tools\Misura-Coppie.ps1` e `-Game` di `Misura-Gl.ps1`).')
  [void]$s.AppendLine('- OpenGL a Win64 (il registratore e'' solo Win32) e con una scheda grafica vera: il GL e'' quello software della VM, se la macchina e'' una VM.')
  [void]$s.AppendLine('- Un solo demo per famiglia: un percorso che la demo non esercita (3D floor, poliobj, flat ruotati) non e'' misurato.')
  $testo = ($s.ToString() -replace "`r?`n", "`r`n")
  [IO.File]::WriteAllText($report, $testo, (New-Object System.Text.UTF8Encoding($false)))
  Write-Log "Rapporto scritto: $report"
}

# =========================================================================================================================
$codiceUscita = 0
$shaNuovo = ''
$oggettoNuovo = ''
$script:CpuInizio = 0
$script:TipoMacchina = 'GL software della VM'
try {
  $sis0 = Get-CimInstance Win32_ComputerSystem
  if ("$($sis0.Manufacturer) $($sis0.Model)" -notmatch '(?i)vmware|virtual|qemu|kvm|xen') { $script:TipoMacchina = 'macchina fisica' }

  if (-not $DryRun) {
    New-Item -ItemType Directory -Force $logs | Out-Null
    New-Item -ItemType Directory -Force $tmp | Out-Null
    $script:LogFile = Join-Path $logs "MisuraFinale_$marca.log"
    $script:Mutex = New-Object System.Threading.Mutex($false, 'Global\DelphiDoomMisuraFinale')
    if (-not $script:Mutex.WaitOne(0)) { throw 'un''altra Misura-Finale e'' in corso' }
  }
  Write-Log ("Misura finale della Release 1 - {0}{1}" -f $adesso.ToString('yyyy-MM-dd HH:mm'), $(if ($DryRun) { ' (PROVA A SECCO: nessuna azione)' } else { '' }))
  Write-Log ("Radice: {0}; vecchio software {1}; vecchio OpenGL {2}; coppie {3} ({4}); OpenGL {5} coppie di {6}, {7} s; varianti: {8}" -f $root, $VecchioSw, $VecchioGl, $Coppie, $Demo, $CoppieGl, $DemoGl, $SecondiGl, ($VariantiGl -join ','))

  Write-Log '--- 1. Precondizioni'
  $pre = @(Get-Precondizioni)
  foreach ($p in $pre) { Write-Log ('  [{0}] {1}: {2}' -f $(if ($p.Ok) { 'OK ' } else { 'NO ' }), $p.Nome, $p.Dettaglio) }
  $falliti = @($pre | Where-Object { -not $_.Ok })
  if ($falliti.Count -gt 0 -and -not $DryRun) {
    Write-Log ("PRECONDIZIONI NON SODDISFATTE ({0}): nessuna azione eseguita." -f $falliti.Count)
    throw 'precondizioni non soddisfatte'
  }
  if ($falliti.Count -gt 0) { Write-Log ("(prova a secco: {0} precondizioni non soddisfatte; in una esecuzione vera il programma si fermerebbe qui)" -f $falliti.Count); $codiceUscita = 2 }
  $d0 = Get-Disturbo
  $script:CpuInizio = $d0.Cpu
  if ($IgnoraClaude) { $script:Avvisi.Add('Lanciata con -IgnoraClaude: il controllo "nessun altro processo claude" e'' stato saltato.') }
  $head = Get-Git @('log', '-1', '--format=%h|%s')
  $shaNuovo = ($head.Testo -split '\|')[0]
  $oggettoNuovo = ($head.Testo -split '\|', 2)[1]
  $script:ShaNuovo = $shaNuovo
  $script:OggettoNuovo = $oggettoNuovo
  Write-Log "Nuovo = $shaNuovo $oggettoNuovo"

  Write-Log '--- 2. Worktree'
  if (-not $DryRun) { [void](Get-Git @('worktree', 'prune')) }
  if (-not $SaltaSw) { $script:Fase = 'worktree'; New-Worktree $CartellaVecchioSw $VecchioSw }
  if (-not $SaltaGl) { New-Worktree $CartellaVecchioGl $VecchioGl; New-Worktree $CartellaNuovoGl 'HEAD' }

  Write-Log '--- 3. Build'
  $script:Fase = 'build'
  if (-not $SaltaSw) {
    Build-Doom -Cartella $root -Etichetta 'nuovo (master)'
    Build-Doom -Cartella $CartellaVecchioSw -Etichetta "vecchio ($VecchioSw)"
  }
  if (-not $SaltaGl) {
    $compila = Join-Path $CartellaNuovoGl 'Tools\Verifica\opengl\Compila.ps1'
    foreach ($v in @(@('Old', @('-OldTree', $CartellaVecchioGl)), @('New', @()))) {
      $r = Invoke-Ps -Titolo ("Compila.ps1 -Which {0} (GLDoom32 con registratore)" -f $v[0]) -Argomenti (@('-File', $compila, '-Which', $v[0], '-Game', 'GLDoom') + $v[1]) -Cartella $CartellaNuovoGl
      if (-not $DryRun) {
        $exe = Join-Path $CartellaNuovoGl ("harness_out\GLDoom_GL_{0}.exe" -f $v[0].ToUpper())
        if (-not (Test-Path -LiteralPath $exe)) { throw "Compila.ps1 -Which $($v[0]) non ha prodotto $exe" }
      }
    }
  }

  Write-Log '--- 4. Pausa'
  $script:Fase = 'pausa'
  Wait-Pausa

  Write-Log '--- 5. Misura software'
  $script:Fase = 'misura software'
  if (-not $SaltaSw) { Invoke-MisuraSoftware }
  Write-Log '--- 6. Misura OpenGL'
  $script:Fase = 'misura OpenGL'
  if (-not $SaltaGl) {
    if (-not $DryRun -and -not $SaltaSw) { Start-Sleep -Seconds 60 }
    Invoke-MisuraGl
  }
  $script:Fase = 'fine'
}
catch {
  Write-Log ("ERRORE nella fase '{0}': {1}" -f $script:Fase, $_.Exception.Message)
  $script:Avvisi.Add(("ERRORE nella fase '{0}': {1}" -f $script:Fase, $_.Exception.Message))
  $codiceUscita = 2
}
finally {
  if (-not $DryRun) {
    Write-Log '--- 7. Rapporto e pulizia'
    if ($script:Righe.Count -gt 0) {
      try {
        $stato = if ($script:Fase -eq 'fine') { 'COMPLETO' } else { "INCOMPLETO (fermato nella fase '$($script:Fase)')" }
        Write-Rapporto -Stato $stato -ShaNuovo $shaNuovo -OggettoNuovo $oggettoNuovo
      }
      catch { Write-Log "ERRORE scrivendo il rapporto: $($_.Exception.Message)" }
    }
    Remove-WorktreeCreati
    Get-ChildItem -LiteralPath (Join-Path $WorkRoot 'Doom') -Filter 'mis_*' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    if ($null -ne $script:Mutex) { try { $script:Mutex.ReleaseMutex() } catch { } $script:Mutex.Dispose() }
  }
}

if ($codiceUscita -eq 0 -and -not $DryRun) {
  $finali = @(Get-RigheFinali)
  if (@($finali | Where-Object { $_.Esito -eq 'oltre il 5%' }).Count -gt 0) { $codiceUscita = 1 }
  elseif (@($finali | Where-Object { $_.Esito -ne 'entro il 5%' }).Count -gt 0) { $codiceUscita = 3 }
  if ($script:Righe.Count -eq 0) { $codiceUscita = 2 }
}
Write-Log ("Uscita {0}" -f $codiceUscita)
exit $codiceUscita
