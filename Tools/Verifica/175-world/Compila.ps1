# Compila ed esegue il gioco ORIGINALE di xGreed senza finestra e scrive le impronte del mondo intero (issue #175):
# i golden di Tests\Data\Greed\world.*.golden.txt, che il test DelphiDoom.Tests.Greed.WorldParity confronta con una
# partita uguale fatta da TGreedGame di Libs\Greed.
# Il codice originale resta in Reference\xGreed (sola lettura) e si compila com'e': raven.pas, utils.pas, spawn.pas,
# sprites.pas, event.pas, constant.pas, il renderer, display.pas, d_font.pas, d_video.pas, menu.pas, intro.pas,
# d_disk.pas, d_misc.pas, net.pas, m_defs.pas. In %TEMP%\WorldGolden\src si generano quattro copie con i soli
# cambi che servono:
#   g_delphi.pas  FormatSettings (Delphi 11), come negli altri harness
#   menu.pas      tre cast AnsiChar (Delphi 11), come in Reference\_dati\xgreed_build\correzioni.diff
#   raven.pas     la testa del ciclo di PlayLoop: "while not quitgame do" diventa "while HarnessNextFrame do" (il
#                 timer dell'originale e' un thread: qui i tic li fa l'harness tra un giro e l'altro), piu' la unit
#                 harness_world nella clausola uses
#   d_ints.pas    l'interfaccia dell'originale senza cambi e l'implementazione di d_ints.impl.txt (niente Windows:
#                 i tasti arrivano dal seme)
# Gli stub di stubs\ sono solo il fondo: i_video, i_windows, timer, modplay (il suono e' registrato), playfli.
# Uso: .\Compila.ps1 -Dati <cartella con GREED.BLO> [-Mappe 0,1,2] [-Semi 1,2] [-Giri 1500] [-Ogni 35]
#                    [-Golden file.txt] [-Libreria] [-Completo] [-Valori <giro>] [-SenzaCompilare]
# -Golden   il file dove si scrivono le righe dell'originale (si riscrive da capo); senza, le righe vanno a video
# -Libreria compila anche WorldLibrary.dpr (la stessa partita con TGreedGame), confronta le righe e dice la prima
#           diversa e in quali parti del mondo
# -Completo una riga per ogni giro (per trovare il primo giro diverso)
# -Valori   scrive tutti i valori del mondo dopo quel giro in %TEMP%\WorldGolden\valori.<mappa>.<seme>.txt (e, con
#           -Libreria, in valori.<mappa>.<seme>.libreria.txt): il confronto dei due file da' il campo diverso
param(
  [Parameter(Mandatory = $true)][string]$Dati,
  [string]$Mappe = '0',
  [string]$Semi = '1',
  [int]$Giri = 1500,
  [int]$Ogni = 35,
  [string]$Golden = '',
  [switch]$Libreria,
  [switch]$Completo,
  [int]$Valori = -1,
  [switch]$SenzaCompilare,
  [string]$Riferimento = 'C:\Progetti\DelphiDoom\Reference\xGreed'
)
$radice = Resolve-Path "$PSScriptRoot\..\..\.."
$uscita = Join-Path $env:TEMP 'WorldGolden'
New-Item -ItemType Directory -Force $uscita, "$uscita\src", "$uscita\lavoro", "$uscita\libreria" | Out-Null
if (-not $SenzaCompilare) {
  $g = Get-Content "$Riferimento\Base\g_delphi.pas" -Raw
  $g = $g -replace '(?<![\.\w])ThousandSeparator', 'FormatSettings.ThousandSeparator' -replace '(?<![\.\w])DecimalSeparator', 'FormatSettings.DecimalSeparator'
  Set-Content "$uscita\src\g_delphi.pas" $g

  $r = Get-Content "$Riferimento\Greed\raven.pas" -Raw
  $a = $r.IndexOf("`nprocedure PlayLoop;", $r.IndexOf("`nimplementation"))
  $testa = "  while not quitgame do"
  $b = $r.IndexOf($testa, $a)
  if ($a -lt 0 -or $b -lt 0 -or ($b - $a) -gt 400) { Write-Error 'raven.pas: la testa del ciclo di PlayLoop non e'' dove era'; exit 1 }
  $r = $r.Substring(0, $b) + "  while HarnessNextFrame do" + $r.Substring($b + $testa.Length)
  $u = $r.IndexOf("`n  utils;", $r.IndexOf("`nimplementation"))
  if ($u -lt 0) { Write-Error 'raven.pas: la clausola uses non e'' dove era'; exit 1 }
  $r = $r.Substring(0, $u) + "`n  utils, harness_world;" + $r.Substring($u + "`n  utils;".Length)
  Set-Content "$uscita\src\raven.pas" $r

  $m = Get-Content "$Riferimento\Greed\menu.pas" -Raw
  $m2 = $m.Replace("savedir[menucursor] := lastascii", "savedir[menucursor] := AnsiChar(lastascii)").Replace("savedir[menucursor][Length(savedir[menucursor])] := lastascii", "savedir[menucursor][Length(savedir[menucursor])] := AnsiChar(lastascii)").Replace("savedir[menucursor] := savedir[menucursor] + lastascii;", "savedir[menucursor] := savedir[menucursor] + AnsiChar(lastascii);")
  if ($m2 -eq $m) { Write-Error 'menu.pas: le righe da correggere non sono dove erano'; exit 1 }
  Set-Content "$uscita\src\menu.pas" $m2

  # d_disk.pas: CA_LumpAsText e CA_FileAsText leggono i byte del lump dentro una string, che con Delphi 11 e'
  # UTF-16: lo script della mappa ne esce illeggibile e il gioco parte senza. Le due funzioni (le ultime del file)
  # sono sostituite da quelle di d_disk.text.txt, che leggono in una AnsiString come faceva Delphi 7
  $k = Get-Content "$Riferimento\Greed\d_disk.pas" -Raw
  $t = $k.IndexOf("`nfunction CA_LumpAsText(const lump: integer): string;`r`nvar")
  if ($t -lt 0) { Write-Error 'd_disk.pas: CA_LumpAsText non e'' dove era'; exit 1 }
  Set-Content "$uscita\src\d_disk.pas" ($k.Substring(0, $t + 1) + (Get-Content "$PSScriptRoot\d_disk.text.txt" -Raw))

  # scriptengine.pas con le stringhe a 8 bit che aveva in Delphi 7 e con la stampa delle righe attorno a un errore
  # che non esce dalla lista: le stesse due cose, e per gli stessi motivi, di ..\175-events\Compila.ps1
  $s = Get-Content "$Riferimento\Base\scriptengine.pas" -Raw
  $s = $s -creplace '\bPChar\b', 'PAnsiChar' -creplace '\bchar\b', 'AnsiChar' -creplace '\bstring\b', 'AnsiString'
  if (-not $s.Contains('x2 := lst.Count;')) { Write-Error 'scriptengine.pas: ScriptPrintLineError non trovata'; exit 1 }
  $s = $s.Replace('x2 := lst.Count;', 'x2 := lst.Count - 1;')
  $s = $s -replace 's: AnsiString;(\s+begin\s+sprintf)', 's: string;$1'
  Set-Content "$uscita\src\scriptengine.pas" $s

  # r_render.pas: reallight is followed in memory by actionflag, and the light of a sprite on the last row writes past
  # the end of the array (sprites.pas: reallight[mapspot + 64 + j] with mapspot on the row 63): the original then has a
  # garbage actionflag, so the renderer runs fireweapon in a turn where the player did not shoot (map 29, seed 2, turn
  # 1029: actionflag = -512). The library does not write outside the map. Here the array gets room for the three
  # rows that the light can reach, so that the original does not depend on what follows it
  $q = Get-Content "$Riferimento\Greed\r_render.pas" -Raw
  $q2 = $q.Replace("reallight: array[0..MAPROWS * MAPCOLS - 1] of integer;", "reallight: array[0..MAPROWS * MAPCOLS - 1 + 3 * MAPCOLS] of integer;")
  if ($q2 -eq $q) { Write-Error 'r_render.pas: reallight non e'' dove era'; exit 1 }
  Set-Content "$uscita\src\r_render.pas" $q2

  $d = Get-Content "$Riferimento\Greed\d_ints.pas" -Raw
  $i = $d.IndexOf("`nimplementation")
  if ($i -lt 0) { Write-Error 'd_ints.pas: implementation non trovata'; exit 1 }
  Set-Content "$uscita\src\d_ints.pas" ($d.Substring(0, $i + 1) + (Get-Content "$PSScriptRoot\d_ints.impl.txt" -Raw))

  $dcc = 'C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\dcc32.exe'
  $u = "$PSScriptRoot\stubs;$uscita\src;$Riferimento\Greed;$Riferimento\Base;$radice\Libs\Greed;$radice\Libs\Platform;$radice\Libs\MathCore;$radice\Libs\Logging;$radice\Libs\Clock;$radice\Tests\Source"
  # -CC: xGreed.inc dichiara {$APPTYPE GUI}, l'harness e' un programma da console
  & $dcc -B -Q -CC -H- -W- '-$O+' "-U$u" "-I$Riferimento" "-N0$uscita" "-E$uscita" "-NSSystem;Winapi" "$PSScriptRoot\WorldGolden.dpr" | Select-String 'Error|Fatal'
  if ($LASTEXITCODE -ne 0) { exit 1 }
  if ($Libreria) {
    $u = "$radice\Libs\Greed;$radice\Libs\Platform;$radice\Libs\MathCore;$radice\Libs\Logging;$radice\Libs\Clock;$radice\Libs\Png;$radice\Libs\Video;$radice\Libs\Zlib;$radice\Tests\Source"
    & $dcc -B -Q '-$O+' "-U$u" "-N0$uscita\libreria" "-E$uscita" "-NSSystem;Winapi" "$PSScriptRoot\WorldLibrary.dpr" | Select-String 'Error|Fatal'
    if ($LASTEXITCODE -ne 0) { exit 1 }
  }
}
$sezioni = @('storia', 'totale', 'player', 'sprites', 'elevators', 'doors', 'areas', 'planes', 'events', 'globals', 'sounds')
$righe = Join-Path $uscita 'righe.txt'
$righeLibreria = Join-Path $uscita 'righe.libreria.txt'
Remove-Item $righe, $righeLibreria -ErrorAction SilentlyContinue
$falliti = 0
$diverse = 0
function Esegui([string]$programma, [string]$file, [string]$fileValori, [string]$mappa, [string]$seme) {
  $argomenti = @("`"$Dati`"", $mappa, $seme, $Giri, "`"$file`"", $Ogni)
  if ($Valori -ge 0) { $argomenti += @($Valori, "`"$fileValori`"") } elseif ($Completo) { $argomenti += @(-1, 'nessuno') }
  if ($Completo) { $argomenti += 'tutti' }
  # dalla cartella di lavoro (l'originale scrive dove si trova), aspettando l'uscita: il programma dell'originale
  # ha il sottosistema GUI di xGreed.inc e senza -Wait PowerShell non lo aspetterebbe
  $processo = Start-Process -FilePath $programma -ArgumentList $argomenti -WorkingDirectory "$uscita\lavoro" -Wait -PassThru -NoNewWindow
  return $processo.ExitCode
}
foreach ($mappa in $Mappe.Split(',')) {
  foreach ($seme in $Semi.Split(',')) {
    $una = Join-Path $uscita 'una.txt'
    $unaLibreria = Join-Path $uscita 'una.libreria.txt'
    Remove-Item $una, $unaLibreria -ErrorAction SilentlyContinue
    $codice = Esegui "$uscita\WorldGolden.exe" $una "$uscita\valori.$mappa.$seme.txt" $mappa $seme
    if ($codice -ne 0) { Write-Host "mappa $mappa seme ${seme}: l'originale e' uscito con $codice"; $falliti++ }
    $a = @(); if (Test-Path $una) { $a = @(Get-Content $una); Add-Content $righe $a }
    if ($Libreria) {
      $codice = Esegui "$uscita\WorldLibrary.exe" $unaLibreria "$uscita\valori.$mappa.$seme.libreria.txt" $mappa $seme
      if ($codice -ne 0) { Write-Host "mappa $mappa seme ${seme}: la libreria e' uscita con $codice"; $falliti++ }
      $b = @(); if (Test-Path $unaLibreria) { $b = @(Get-Content $unaLibreria); Add-Content $righeLibreria $b }
      $prima = -1
      for ($n = 0; $n -lt [Math]::Max($a.Count, $b.Count); $n++) {
        if ($n -ge $a.Count -or $n -ge $b.Count -or $a[$n] -ne $b[$n]) { $prima = $n; break }
      }
      if ($prima -lt 0) {
        Write-Host "mappa $mappa seme ${seme}: $($a.Count) righe uguali"
      } else {
        $diverse++
        $pa = @(); if ($prima -lt $a.Count) { $pa = $a[$prima].Split(' ') }
        $pb = @(); if ($prima -lt $b.Count) { $pb = $b[$prima].Split(' ') }
        $quali = @()
        for ($k = 5; $k -lt [Math]::Min($pa.Count, $pb.Count); $k++) { if ($pa[$k] -ne $pb[$k]) { $quali += $sezioni[$k - 5] } }
        $giro = '?'; if ($pa.Count -gt 3) { $giro = $pa[3] } elseif ($pb.Count -gt 3) { $giro = $pb[3] }
        Write-Host "mappa $mappa seme ${seme}: DIVERSA alla riga $prima (giro $giro), righe $($a.Count)/$($b.Count): $($quali -join ', ')"
      }
    }
  }
}
if (Test-Path $righe) {
  if ($Golden -ne '') {
    $testa = @(
      '# Impronte del mondo intero di una partita del gioco ORIGINALE di xGreed (Tools\Verifica\175-world\Compila.ps1).',
      '# W <mappa> <seme> <giro> <timecount> <storia> <totale> <player> <sprites> <elevators> <doors> <areas> <planes>',
      '#   <events> <globals> <sounds>: FNV-1a a 32 bit; <storia> e'' l''impronta dei totali di tutti i giri fino a quello.',
      "# Giri $Giri, una riga ogni $Ogni, due tic per giro, vista 320 x 200."
    )
    Set-Content $Golden ($testa + (Get-Content $righe))
    Write-Host "$((Get-Content $righe).Count) righe in $Golden"
  } elseif (-not $Libreria) {
    Get-Content $righe
  }
}
if ($Libreria) { Write-Host "partite diverse: $diverse; uscite con errore: $falliti" }
exit ($falliti + $diverse)
