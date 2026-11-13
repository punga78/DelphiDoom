<#
  Fetta 1b (issue #185): costruisce un PWAD di prova con il lump ACTORDEF (e, a richiesta, DEHACKED) da usare
  con -file nel confronto vecchio contro nuovo (Fetta-1b.txt). Nessun dato di gioco: il testo sta in
  Tests\Data\Info1b\.

  Uso:
    powershell -NoProfile -File Tools\Verifica\185\Fetta-1b-Pwad.ps1 -Out C:\ddparity_1b\info1b.wad [-Dehacked Tests\Data\Info1b\info1b_patch.deh]
#>
param(
  [Parameter(Mandatory = $true)][string]$Out,
  [string]$Actordef = '',
  [string]$Dehacked = ''
)
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
if ($Actordef -eq '') { $Actordef = Join-Path $root 'Tests\Data\Info1b\info1b_actordef.txt' }

$lumps = New-Object System.Collections.ArrayList
[void]$lumps.Add(@{ Name = 'ACTORDEF'; Bytes = [IO.File]::ReadAllBytes($Actordef) })
if ($Dehacked -ne '') { [void]$lumps.Add(@{ Name = 'DEHACKED'; Bytes = [IO.File]::ReadAllBytes($Dehacked) }) }

$ms = New-Object IO.MemoryStream
$w = New-Object IO.BinaryWriter($ms)
$w.Write([Text.Encoding]::ASCII.GetBytes('PWAD'))
$w.Write([int]$lumps.Count)
$w.Write([int]0)
$positions = @()
foreach ($l in $lumps) { $positions += [int]$ms.Position; $w.Write([byte[]]$l.Bytes) }
$dir = [int]$ms.Position
for ($i = 0; $i -lt $lumps.Count; $i++) {
  $w.Write([int]$positions[$i])
  $w.Write([int]$lumps[$i].Bytes.Length)
  $name = [byte[]]::new(8)
  [Text.Encoding]::ASCII.GetBytes($lumps[$i].Name).CopyTo($name, 0)
  $w.Write($name)
}
$ms.Position = 8
$w.Write($dir)
$w.Flush()
[IO.File]::WriteAllBytes($Out, $ms.ToArray())
"scritto $Out ($($ms.Length) byte, $($lumps.Count) lump)"
