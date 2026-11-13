<#
  Issue #201: riscrive i golden di Tests\Data\War dal C del remake. SOLO quando il C o l'estrazione e' cambiata di
  proposito (un'altra versione di Reference\war1, un campo in piu' nell'uscita): altrimenti il golden e' la prova, non si
  riscrive per far passare un test. Dopo, si guarda il diff dei golden e si fanno girare i test (Confronta-Golden.ps1 -Test).

  Scrive LF e ASCII (i file con BOM, come catalog e datawar, si riscrivono con il BOM che avevano: si controlla nel diff).
  Senza il DATA.WAR vero NON riscrive i golden che lo vogliono (li lascia com'erano e lo dice).

  Uso:
    powershell -NoProfile -File Tools\Verifica\201\Registra-Golden.ps1 [-DataWar <...\DATA.WAR>] [-Solo 191|192|193|198|musica|suoni]
      [-Out <cartella nuova fuori dal repository>]
#>
param(
  [string]$DataWar = 'C:\Progetti\DelphiDoom\Reference\_dati\warcraft\DATA\DATA.WAR',
  [string]$Solo = '',
  [string]$Out = ''
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Golden-Common.ps1')

$ownsOut = $false
if ($Out -eq '') { $Out = Join-Path ([IO.Path]::GetTempPath()) ("war-golden-" + [guid]::NewGuid().ToString('N')); $ownsOut = $true }
try {
  foreach ($group in (Select-Groups $Solo)) {
    "== $($group.Name)"
    $dir = Build-Group $group $Out
    foreach ($job in $group.Jobs) {
      $lines = Invoke-Job $job $dir $DataWar
      if ($null -eq $lines) { "   non riscritto $($job.Golden)  (serve il DATA.WAR)"; continue }
      $path = Join-Path $script:GoldenDir $job.Golden
      $bom = $false
      if (Test-Path $path) {
        $head = [byte[]](Get-Content -Path $path -Encoding Byte -TotalCount 3)
        $bom = ($head.Count -ge 3 -and $head[0] -eq 0xEF -and $head[1] -eq 0xBB -and $head[2] -eq 0xBF)
      }
      $text = (($lines | ForEach-Object { $_.TrimEnd("`r") }) -join "`n") + "`n"
      $encoding = if ($bom) { New-Object System.Text.UTF8Encoding($true) } else { [Text.Encoding]::ASCII }
      [IO.File]::WriteAllText($path, $text, $encoding)
      "   scritto $($job.Golden): $($lines.Count) righe"
    }
  }
}
finally {
  if ($ownsOut -and (Test-Path $Out)) { Remove-Item -Recurse -Force $Out -ErrorAction SilentlyContinue }
}
