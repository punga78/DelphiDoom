<#
  Prova che la riscrittura dei .dproj non cambia nulla per MSBuild (issue "Configurazioni Debug e Release
  standard nei .dproj"): valuta ogni .dproj con le quattro combinazioni Config (Debug, Release) x Platform
  (Win32, Win64) e scrive tutte le proprieta' valutate (tranne quelle d'ambiente, globali, riservate e i
  soli flag di struttura: Base, Base_*, Cfg_*, CfgParent) e gli item BuildConfiguration/RcCompile/DelphiCompile.

    Tools\Confronta-Proprieta-Dproj.ps1 -Salva <file>        scrive la fotografia
    Tools\Confronta-Proprieta-Dproj.ps1 -Confronta <file>    confronta lo stato attuale con la fotografia

  Va lanciato da un prompt con l'ambiente di Delphi (rsvars.bat): i .dproj importano $(BDS)\Bin\CodeGear.Delphi.Targets.
  Uso tipico:
    cmd /c "call "%ProgramFiles(x86)%\Embarcadero\Studio\22.0\bin\rsvars.bat" && powershell -NoProfile -File Tools\Confronta-Proprieta-Dproj.ps1 -Salva prima.txt"
  Opzione -Elenco: solo i .dproj indicati (percorsi relativi alla radice, separati da virgola).
#>
param(
  [string]$Salva,
  [string]$Confronta,
  [string[]]$Elenco
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Add-Type -AssemblyName 'Microsoft.Build, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a'

$escluse = '^(Base|Base_.*|Cfg_.*|CfgParent)$'

function Get-Fotografia {
  $files = if ($Elenco) {
    $Elenco | ForEach-Object { Get-Item (Join-Path $root $_) }
  } else {
    Get-ChildItem -Path $root -Recurse -Filter *.dproj -File |
      Where-Object { $_.FullName.Substring($root.Length) -notmatch '^\\(bin|dcu|logs|Reference|\.claude)\\' }
  }
  $righe = New-Object System.Collections.Generic.List[string]
  foreach ($file in ($files | Sort-Object FullName)) {
    $rel = $file.FullName.Substring($root.Length + 1)
    foreach ($config in 'Debug', 'Release') {
      foreach ($platform in 'Win32', 'Win64') {
        $collection = New-Object Microsoft.Build.Evaluation.ProjectCollection
        $globals = New-Object 'System.Collections.Generic.Dictionary[string,string]'
        $globals['Config'] = $config
        $globals['Platform'] = $platform
        $project = New-Object Microsoft.Build.Evaluation.Project($file.FullName, $globals, '4.0', $collection)
        $prefisso = '{0}|{1}|{2}|' -f $rel, $config, $platform
        $props = @()
        foreach ($p in $project.AllEvaluatedProperties) {
          if ($p.IsEnvironmentProperty -or $p.IsGlobalProperty -or $p.IsReservedProperty -or $p.IsImported) { continue }
          if ($p.Name -match $escluse) { continue }
          $props += ('{0}={1}' -f $p.Name, $p.EvaluatedValue)
        }
        # l'ultimo valore valutato di ogni nome e' quello effettivo
        $ultimi = [ordered]@{}
        foreach ($riga in $props) {
          $i = $riga.IndexOf('=')
          $ultimi[$riga.Substring(0, $i)] = $riga.Substring($i + 1)
        }
        foreach ($nome in ($ultimi.Keys | Sort-Object)) {
          $righe.Add($prefisso + $nome + '=' + $ultimi[$nome].Replace($root, '<ROOT>'))
        }
        foreach ($tipo in 'DelphiCompile', 'RcCompile') {
          foreach ($item in $project.GetItems($tipo)) {
            $righe.Add($prefisso + 'item ' + $tipo + ' ' + $item.EvaluatedInclude)
          }
        }
        $collection.UnloadAllProjects()
        $collection.Dispose()
      }
    }
  }
  return $righe
}

$ora = Get-Fotografia
if ($Salva) {
  [System.IO.File]::WriteAllLines([System.IO.Path]::GetFullPath($Salva), $ora)
  Write-Host ("fotografia scritta: {0} righe in {1}" -f $ora.Count, $Salva)
  exit 0
}
if ($Confronta) {
  $prima = [System.IO.File]::ReadAllLines((Resolve-Path $Confronta).Path)
  $diff = Compare-Object -ReferenceObject $prima -DifferenceObject $ora
  if ($Elenco) {
    # solo le righe dei progetti richiesti
    $diff = $diff | Where-Object { $p = $_.InputObject.Split('|')[0]; $Elenco -contains $p }
  }
  if ($diff) {
    Write-Host ("DIVERSE: {0} righe" -f @($diff).Count)
    $diff | Select-Object -First 40 | ForEach-Object { Write-Host ('{0} {1}' -f $_.SideIndicator, $_.InputObject) }
    exit 1
  }
  Write-Host ("UGUALI: {0} righe prima, {1} dopo" -f $prima.Count, $ora.Count)
  exit 0
}
Write-Host 'Indicare -Salva <file> o -Confronta <file>'
exit 2
