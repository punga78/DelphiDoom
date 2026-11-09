# TEMPORARY HARNESS (issue #173), level L1 of the plan docs\SCRIPTHOST_PIANO.md: the registration of the host
# functions, classes, types and constants of the scripts, for one game, as text.
#
#   .\Tools\Verifica\scripthost\Dump-L1.ps1 -Game Doom|Heretic|Hexen|Strife [-Update] [-Config Release|Debug]
#
# From Doom\ddc_doom.dpr (or the one of the game) it makes a CONSOLE program VshDump_<Game> (same units, same
# defines, ComposeEngine + DD_InitDoomEngine as the DLL does, then ScriptHostDump writes the file), builds it
# with Tools\build.bat, runs it (no game is started: it is a tool, it needs no WAD) and compares the file with
# Tests\Data\ScriptHost\<Game>.registration.golden.txt. With -Update the golden is overwritten (to be done only on
# the OLD code, before the change that the golden has to protect). The generated project is removed at the end.
param(
  [Parameter(Mandatory = $true)][ValidateSet('Doom', 'Heretic', 'Hexen', 'Strife')][string]$Game,
  [switch]$Update,
  [ValidateSet('Release', 'Debug')][string]$Config = 'Release',
  [int]$Seconds = 120
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Set-Location $root
New-Item -ItemType Directory -Force logs | Out-Null
$latin1 = [System.Text.Encoding]::GetEncoding('ISO-8859-1')
$lower = $Game.ToLower()
$name = "VshDump_$Game"
$dprSource = Join-Path $root "$Game\ddc_$lower.dpr"
$dprojSource = Join-Path $root "$Game\ddc_$lower.dproj"
$dprTarget = Join-Path $root "$Game\$name.dpr"
$dprojTarget = Join-Path $root "$Game\$name.dproj"
$golden = Join-Path $root "Tests\Data\ScriptHost\$Game.registration.golden.txt"
$exe = Join-Path $root "bin\Tools\$name.exe"
$produced = Join-Path $root "logs\$name.registration.txt"

function Read-Source([string]$Path) { return $latin1.GetString([System.IO.File]::ReadAllBytes($Path)) }
function Write-Source([string]$Path, [string]$Text) { [System.IO.File]::WriteAllBytes($Path, $latin1.GetBytes($Text)) }

try {
  $dpr = Read-Source $dprSource
  $dpr = $dpr -replace "(?m)^library ddc_$lower;", "program $name;`r`n`r`n{`$APPTYPE CONSOLE}"
  $dpr = [regex]::Replace($dpr, '(?s)\r?\nexports\s+[^;]*;\r?\n', "`r`n")
  $dpr = [regex]::Replace($dpr, "(  i_system in '\.\.\\Base\\i_system\.pas',\r?\n)",
    "`$1  ScriptHostDump in '..\Tools\Verifica\scripthost\ScriptHostDump.pas',`r`n")
  $body = "begin`r`n  ComposeEngine;`r`n  DD_InitDoomEngine;`r`n  VSH_WriteRegistrationDump(ParamStr(1));`r`nend.`r`n"
  $dpr = [regex]::Replace($dpr, '(?s)begin\s+ComposeEngine;\s+DD_InitDoomEngine;\s+end\.\s*$', $body)
  if ($dpr -notmatch 'ScriptHostDump in' -or $dpr -notmatch 'VSH_WriteRegistrationDump' -or $dpr -match '(?m)^exports') {
    throw "trasformazione di $dprSource non riuscita"
  }
  Write-Source $dprTarget $dpr

  $dproj = Read-Source $dprojSource
  $dproj = $dproj.Replace("ddc_$lower", $name).Replace('<AppType>Library</AppType>', '<AppType>Console</AppType>')
  $dproj = $dproj.Replace('<DCC_AdditionalSwitches>-TX.dll $(DCC_AdditionalSwitches)</DCC_AdditionalSwitches>', '')
  Write-Source $dprojTarget $dproj

  Remove-Item $exe -Force -ErrorAction SilentlyContinue
  & .\Tools\build.bat "$Game\$name" $Config
  $log = "logs\$name.log"
  $errors = @(Select-String -Path $log -Pattern '\berror\b|\[Fatal Error\]|Fatal:' -CaseSensitive:$false)
  Write-Host "== build $name : $($errors.Count) righe di errore (vedi $log)"
  $errors | Select-Object -First 15 | ForEach-Object { Write-Host $_.Line }
  if ($errors.Count -gt 0 -or -not (Test-Path $exe)) { throw 'build fallita' }

  Remove-Item $produced -Force -ErrorAction SilentlyContinue
  $process = Start-Process -FilePath $exe -ArgumentList "`"$produced`"" -WorkingDirectory (Join-Path $root 'bin\Tools') -PassThru -WindowStyle Hidden
  if (-not $process.WaitForExit($Seconds * 1000)) {
    $process.Kill()
    throw "il programma non e' terminato in $Seconds secondi"
  }
  if ($process.ExitCode -ne 0 -or -not (Test-Path $produced)) { throw "il programma ha dato codice $($process.ExitCode) e il file esiste: $(Test-Path $produced)" }
  $lines = @(Get-Content $produced)
  Write-Host "== $Game : $($lines.Count) righe scritte in $produced"
  $failures = @($lines | Where-Object { $_ -like 'COMPILE ERROR*' })
  if ($failures.Count -gt 0) { $failures | ForEach-Object { Write-Host $_ }; throw 'una delle compilazioni dell''elenco e'' fallita' }

  if ($Update) {
    New-Item -ItemType Directory -Force (Split-Path $golden -Parent) | Out-Null
    Copy-Item $produced $golden -Force
    Write-Host "== golden scritto: $golden"
  } else {
    if (-not (Test-Path $golden)) { throw "golden mancante: $golden" }
    $expected = @(Get-Content $golden)
    $diff = @(Compare-Object $expected $lines -SyncWindow 0)
    if ($expected.Count -eq $lines.Count -and $diff.Count -eq 0) {
      Write-Host "== $Game : UGUALE al golden ($($lines.Count) righe)"
    } else {
      Write-Host "== $Game : DIVERSO dal golden (golden $($expected.Count) righe, prodotto $($lines.Count))"
      $diff | Select-Object -First 20 | ForEach-Object {
        if ($_.SideIndicator -eq '<=') { $side = 'golden  ' } else { $side = 'prodotto' }
        Write-Host "    $side $($_.InputObject)"
      }
      exit 1
    }
  }
}
finally {
  Remove-Item $dprTarget, $dprojTarget -Force -ErrorAction SilentlyContinue
}
