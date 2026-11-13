<#
  Issue #201: parte comune di Confronta-Golden.ps1 e Registra-Golden.ps1 (si include con ". .\Golden-Common.ps1").

  Il criterio di parita' di Libs\War: ogni golden di Tests\Data\War e' l'uscita di un programma in C che contiene il
  codice ORIGINALE del remake (acoto87/war1) estratto alla lettera e compilato con gcc (w64devkit); questa tabella
  dice quale programma fa quale golden. Niente e' modificato in Reference\.
#>

$script:Here = $PSScriptRoot
$script:Verifica = Split-Path $PSScriptRoot
$script:Repo = Split-Path (Split-Path (Split-Path $PSScriptRoot))
$script:GoldenDir = Join-Path $script:Repo 'Tests\Data\War'

# Gruppo = una cartella di Tools\Verifica con il suo Compila-*.ps1; Jobs = una riga di comando del programma e il golden che scrive.
# {DATA} si sostituisce con il DATA.WAR vero; un job con NeedsData si salta se il DATA.WAR non c'e'.
$script:Groups = @(
  @{ Name = '191 archivio'; Dir = '191'; Script = 'Compila-WarRef.ps1'; Jobs = @(
      @{ Exe = 'war_ref.exe'; Args = @('{DATA}', 'list'); Golden = 'datawar.retail.golden.txt'; NeedsData = $true },
      @{ Exe = 'war_ref.exe'; Args = @('{DATA}', 'list', 'noskip'); Golden = 'datawar.retail.noskip.golden.txt'; NeedsData = $true },
      @{ Exe = 'war_ref.exe'; Args = @('-', 'catalog'); Golden = 'catalog.golden.txt'; NeedsData = $false }) },
  @{ Name = '192 grafica'; Dir = '192'; Script = 'Compila-GfxRef.ps1'; Jobs = @(
      @{ Exe = 'war_gfx_ref.exe'; Args = @('{DATA}', 'gfx'); Golden = 'graphics.golden.txt'; NeedsData = $true },
      @{ Exe = 'war_gfx_ref.exe'; Args = @('-', 'fonts'); Golden = 'fonts.golden.txt'; NeedsData = $false }) },
  @{ Name = '193 livelli'; Dir = '193'; Script = 'Compila-LevelRef.ps1'; Jobs = @(
      @{ Exe = 'war_lvl_ref.exe'; Args = @('{DATA}', 'levels'); Golden = 'levels.golden.txt'; NeedsData = $true },
      @{ Exe = 'war_lvl_ref.exe'; Args = @('-', 'campaigns'); Golden = 'campaigns.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_lvl_ref.exe'; Args = @('-', 'objectives'); Golden = 'objectives.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_lvl_ref.exe'; Args = @('-', 'tables'); Golden = 'autotile.tables.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_lvl_ref.exe'; Args = @('-', 'autotile'); Golden = 'autotile.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_lvl_ref.exe'; Args = @('-', 'grid'); Golden = 'grid.golden.txt'; NeedsData = $false }) },
  @{ Name = '198 suoni'; Dir = '198'; Script = 'Compila-AudioRef.ps1'; Jobs = @(
      @{ Exe = 'war_audio_ref.exe'; Args = @('-', 'synth'); Golden = 'audio.synth.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_audio_ref.exe'; Args = @('-', 'mix'); Golden = 'audio.mixer.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_audio_ref.exe'; Args = @('-', 'position'); Golden = 'audio.position.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_audio_ref.exe'; Args = @('{DATA}', 'list'); Golden = 'audio.records.golden.txt'; NeedsData = $true }) },
  @{ Name = '198 musica'; Dir = '198'; Script = 'Compila-MusicRef.ps1'; Jobs = @(
      @{ Exe = 'war_music_ref.exe'; Args = @('scenarios'); Golden = 'music.golden.txt'; NeedsData = $false }) },
  @{ Name = '198 scelta dei suoni'; Dir = '198'; Script = 'Compila-SoundRef.ps1'; Jobs = @(
      @{ Exe = 'war_sound_ref.exe'; Args = @('tables'); Golden = 'sounds.tables.golden.txt'; NeedsData = $false },
      @{ Exe = 'war_ranges.exe'; Args = @(); Golden = 'sounds.ranges.golden.txt'; NeedsData = $false }) }
)

# Il testo di un golden senza le differenze che non contano: BOM, fine riga (CRLF o LF), righe vuote in coda.
function Get-NormalizedText([string[]]$Lines) {
  $list = New-Object System.Collections.Generic.List[string]
  foreach ($line in $Lines) { $list.Add($line.TrimStart([char]0xFEFF).TrimEnd("`r")) }
  while ($list.Count -gt 0 -and $list[$list.Count - 1] -eq '') { $list.RemoveAt($list.Count - 1) }
  , $list.ToArray()
}

function Read-GoldenFile([string]$Path) {
  Get-NormalizedText ([IO.File]::ReadAllLines($Path))
}

# Compila il gruppo in una cartella nuova di $Root (un sottocartella per gruppo) e dice dove sta.
function Build-Group($Group, [string]$Root) {
  $out = Join-Path $Root ($Group.Name -replace '[^0-9A-Za-z]+', '_')
  $script = Join-Path (Join-Path $script:Verifica $Group.Dir) $Group.Script
  $built = & $script -Out $out
  if (-not (Test-Path $out)) { throw "Il gruppo $($Group.Name) non ha compilato." }
  $out
}

# Esegue un job e da' le righe che il programma scrive; $null se serve il DATA.WAR e non c'e'.
function Invoke-Job($Job, [string]$BuildDir, [string]$DataWar) {
  if ($Job.NeedsData -and (-not $DataWar -or -not (Test-Path $DataWar))) { return $null }
  $arguments = @($Job.Args | ForEach-Object { if ($_ -eq '{DATA}') { $DataWar } else { $_ } })
  $lines = & (Join-Path $BuildDir $Job.Exe) @arguments
  if ($LASTEXITCODE -ne 0) { throw "$($Job.Exe) $($arguments -join ' ') e' uscito con $LASTEXITCODE" }
  , @($lines)
}

function Select-Groups([string]$Only) {
  if ($Only -eq '') { return $script:Groups }
  $script:Groups | Where-Object { $_.Name -like "*$Only*" -or $_.Dir -eq $Only }
}
