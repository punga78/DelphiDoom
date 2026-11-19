# Issue #185 (ondata 13): scansione del codice morto di tutto il repository. Un nome e' morto se compare solo nelle sue dichiarazioni (commenti esclusi, stringhe incluse) in nessun .pas, .dpr, .inc, .dfm, .rc.
# Uso: Scansiona-Morto.ps1 -Out elenco.txt   (righe: file|riga|tipo|nome|testo). Richiede git nel percorso; non compila nulla.
param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path, [string]$Out)
Add-Type -Path "$PSScriptRoot\ScansionaMorto.cs" -ReferencedAssemblies System.Core
Set-Location $Root
$files = git ls-files '*.pas' '*.inc' '*.dpr' '*.dfm' '*.rc' '*.lpr'
$counts = $null
$res = [DeadScan]::Run($Root, [string[]]$files, [ref]$counts)
$lines = $res | ForEach-Object { '{0}|{1}|{2}|{3}|{4}' -f $_.File, $_.Line, $_.Kind, $_.Name, $_.Extra }
[IO.File]::WriteAllLines($Out, $lines)
"{0} candidati" -f $res.Count
$res | Group-Object Kind | ForEach-Object { '{0}: {1}' -f $_.Name, $_.Count }


