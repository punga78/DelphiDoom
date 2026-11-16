<#
.SYNOPSIS
  Issue #226: cerca nei file tracciati i riferimenti rimasti ai VECCHI percorsi (Libs\..., Base\, Doom\, ...).

.DESCRIPTION
  Usa lo stesso criterio di Sposta-Fetta.ps1 (nome ancorato alla radice, non preceduto da una parola e
  da un separatore: bin\Doom, Tests\Data\Parity\Doom e simili non contano). Stampa file:riga:testo;
  uscita 1 se ne trova. Non guarda docs\FRAMEWORK_CENSIMENTO.md (analisi datata) ne' Tests\Data\Strati
  (alberi finti) ne' Tools\Verifica\226 (la mappa).
#>
param([string]$Radice = '', [string]$Elenco = '')
$ErrorActionPreference = 'Stop'
if ($Radice -eq '') { $Radice = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path }
Set-Location $Radice
$latin1 = [Text.Encoding]::GetEncoding(28591)
$vecchi = 'Libs', 'Base', 'Common', 'Doom', 'Heretic', 'Hexen', 'Strife', 'Radix', 'Speed', 'Keen', 'Greed', 'War', 'OpenXcom', 'DD_IDE', 'DD_Tools', 'Launcher', 'DoomBuilder'
# come Sposta-Fetta.ps1: Libs\ con qualunque separatore, gli altri nomi con \ oppure con / davanti a un nome di file
$rx = New-Object Text.RegularExpressions.Regex(('(?:(?<![A-Za-z0-9_$)}\]][\\/])|(?<=(?:\$radice|\$Radice|\$root|\$Root|%R%)[\\/])|(?<=(?:^|\s)[ab]/))(?<![A-Za-z0-9_])(?:Libs[\\/]|(?:' + (($vecchi | Where-Object { $_ -ne 'Libs' }) -join '|') + ')(?:\\|/(?=[A-Za-z0-9_\-]+\.[A-Za-z0-9])))'), 'CultureInvariant')
$estBinari = @('.gz', '.bmp', '.wad', '.lmp', '.sav', '.png', '.ico', '.exe', '.dll', '.res', '.zip', '.pk3', '.jpg', '.tga', '.pak', '.o', '.obj', '.bin', '.dat', '.lzh', '.mid', '.ogg', '.mp3', '.wav', '.scn', '.swd', '.dfm', '.ddp', '.cur', '.lib', '.a', '.dcu', '.map', '.drc', '.ttf', '.pcx', '.qvm', '.aas', '.bsp', '.roq', '.flc', '.fli', '.jcl', '.dcp', '.bpl')
$escludi = @('docs\FRAMEWORK_CENSIMENTO.md', 'Tests\Data\Strati', 'Tools\Verifica\226', 'Tools\Verifica\opengl\hook-gl.pre226.patch')
# i percorsi relativi che ora portano a una cosa che esiste (..\Base\x.inc tra cartelle vicine) non sono vecchi
$seg = '(?:\$\([A-Za-z0-9_]+\)|[A-Za-z0-9_\-]+(?:\.[A-Za-z0-9_\-]+)*)'
$rxRel = New-Object Text.RegularExpressions.Regex(('(?<![A-Za-z0-9_.$)\]\\/%~])((?:\.\.[\\/])+)(' + $seg + '(?:[\\/]' + $seg + ')*)[\\/]?'), 'CultureInvariant')
$esistenti = New-Object Collections.Generic.HashSet[string] ([StringComparer]::OrdinalIgnoreCase)
foreach ($p in @(& git -c core.quotepath=off ls-files)) {
  $p = $p.Replace('/', '\')
  [void]$esistenti.Add($p)
  $i = $p.LastIndexOf('\')
  while ($i -gt 0) { $p = $p.Substring(0, $i); [void]$esistenti.Add($p); $i = $p.LastIndexOf('\') }
}
$dirCorrente = ''
$trovati = 0
foreach ($rel in (@(& git -c core.quotepath=off ls-files) | ForEach-Object { $_.Replace('/', '\') })) {
  if ($estBinari -contains [IO.Path]::GetExtension($rel).ToLowerInvariant()) { continue }
  $skip = $false
  foreach ($x in $escludi) { if ($rel -ieq $x -or $rel.StartsWith($x + '\', [StringComparison]::OrdinalIgnoreCase)) { $skip = $true } }
  if ($skip) { continue }
  $p = Join-Path $Radice $rel
  if (-not [IO.File]::Exists($p)) { continue }
  $bytes = [IO.File]::ReadAllBytes($p)
  if ([Array]::IndexOf($bytes, [byte]0) -ge 0) { continue }
  $righe = $latin1.GetString($bytes) -split "`n"
  $dirSegs = @(); $dd = [IO.Path]::GetDirectoryName($rel); if ($dd) { $dirSegs = @($dd -split '\\') }
  for ($i = 0; $i -lt $righe.Count; $i++) {
    $r = $righe[$i]
    # prima il filtro grossolano: senza un nome vecchio seguito da separatore la riga non interessa
    if ($r.IndexOf('\') -lt 0 -and $r.IndexOf('/') -lt 0) { continue }
    # i test caricano le DLL da ..\Libs\ (cartella bin\<Piattaforma>\<Configurazione>\Libs, che non cambia nome)
    $r2 = $r.Replace("'..\Libs\'", '').Replace('bin\Libs\', '').Replace('bin/Libs/', '')
    $r2 = $rxRel.Replace($r2, {
      param($m)
      $ups = ([regex]::Matches($m.Groups[1].Value, '\.\.')).Count
      if ($ups -gt $dirSegs.Count) { return $m.Value }
      $base = @(); if ($dirSegs.Count - $ups -gt 0) { $base = @($dirSegs[0..($dirSegs.Count - $ups - 1)]) }
      $abs = (@($base) + @($m.Groups[2].Value -split '[\\/]')) -join '\'
      if ($esistenti.Contains($abs)) { return 'OK' }
      return $m.Value
    })
    if ($rx.IsMatch($r2)) {
      $trovati++
      $t = $r.Trim(); if ($t.Length -gt 200) { $t = $t.Substring(0, 200) }
      Write-Host ("{0}:{1}: {2}" -f $rel, ($i + 1), $t)
    }
  }
}
Write-Host ("Riferimenti ai vecchi percorsi rimasti: {0}" -f $trovati)
if ($trovati -gt 0) { exit 1 }
