# Issue #185 (ondata 13): clausole uses che non nominano nulla dell'unit usata (nell'interface dell'unit usata; direttive {$IF} comprese). Le unit con initialization/finalization, operator, helper o {$R} non sono proposte.
# ATTENZIONE: togliere una unit puo' cambiare ordine di collegamento, espansione degli inline (H2443) e dimensione delle unit: va provato con Confronta-Unit.ps1 su una build pulita.
param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path, [string]$Out)
Add-Type -Path "$PSScriptRoot\ScansionaMorto.cs","$PSScriptRoot\UsesScansionaMorto.cs" -ReferencedAssemblies System.Core
Set-Location $Root
$all = git ls-files '*.pas' '*.inc' '*.dpr'
$targets = $all | Where-Object { $_ -match '\.pas$' -and $_ -match '^IdTech1/(Base|Common|Doom|Heretic|Hexen|Strife|Radix|Speed|OpenGl)/' -and $_ -notmatch 'r_clipper|dglOpenGL|d_fpc|d_delphi' }
$res = [UsesScan]::Run($Root, [string[]]$all, [string[]]$targets)
[IO.File]::WriteAllLines($Out, [string[]]$res)
"{0} voci; inutili {1}; con direttive {2}" -f $res.Count, @($res | Where-Object { $_ -like 'INUTILE*' }).Count, @($res | Where-Object { $_ -like 'CLAUSOLA*' }).Count



