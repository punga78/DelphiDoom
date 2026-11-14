<#
  Riscrive le cartelle di uscita di tutti i .dproj del repository in modo uniforme (issue #230):

    eseguibili, DLL e test   bin\$(Platform)\$(Config)\<area>          (area: Doom, Libs, Tools, Tests, ...; vuota per il Launcher)
    .dcu                     dcu\$(Platform)\$(Config)\<progetto>

  Prima c'era una sola cartella per piattaforma (bin\Doom, bin\Win64\Doom, dcu\<progetto>\$(Config) e
  dcu\Win64\<progetto>\$(Config)): Debug e Release si sovrascrivevano. Ora le quattro combinazioni
  (Win32/Win64 x Debug/Release) hanno cartelle distinte e il gruppo Win64 non ripete piu' le uscite.

  Lo script e' ripetibile: un .dproj gia' riscritto non cambia. Conserva BOM e fine riga (CRLF) di ogni file.

  Uso:   powershell -NoProfile -File Tools\Aggiorna-Uscite-Dproj.ps1 [-Prova]
         -Prova  non scrive nulla, elenca soltanto cosa cambierebbe
#>
param([switch]$Prova)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)

$exeRegex = [regex]'<DCC_ExeOutput>((?:\.\.\\)+)bin(?:\\Win64)?(?:\\([^<]+))?</DCC_ExeOutput>'
$exeNew   = [regex]'<DCC_ExeOutput>(?:\.\.\\)+bin\\\$\(Platform\)\\\$\(Config\)'
$dcuRegex = [regex]'<DCC_DcuOutput>((?:\.\.\\)+)dcu\\(?:Win64\\)?([^<]+?)\\\$\(Config\)</DCC_DcuOutput>'
$dcuNew   = [regex]'<DCC_DcuOutput>(?:\.\.\\)+dcu\\\$\(Platform\)\\\$\(Config\)\\'
$groupRegex = [regex]'(?s)<PropertyGroup[^>]*>.*?</PropertyGroup>'
$dropLine = [regex]'(?m)^[ \t]*<DCC_(ExeOutput|DcuOutput)>[^<]*</DCC_(ExeOutput|DcuOutput)>\r?\n'

$changed = 0
$unchanged = 0
$problems = @()

$files = Get-ChildItem -Path $root -Recurse -Filter *.dproj -File |
  Where-Object { $_.FullName.Substring($root.Length) -notmatch '^\\(bin|dcu|logs|Reference|\.claude)\\' }

foreach ($file in $files) {
  $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
  $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
  $text = $utf8.GetString($bytes, $(if ($hasBom) { 3 } else { 0 }), $bytes.Length - $(if ($hasBom) { 3 } else { 0 }))
  $original = $text

  $text = $groupRegex.Replace($text, {
    param($m)
    $block = $m.Value
    $header = $block.Substring(0, $block.IndexOf('>') + 1)
    if ($header -match "==\s*'Win64'") {
      # il gruppo Win64 non ripete le uscite: le ha gia' il gruppo base con $(Platform)
      return $dropLine.Replace($block, '')
    }
    $block = $exeRegex.Replace($block, {
      param($e)
      if ($e.Value.Contains('$(Platform)')) { return $e.Value }   # gia' nella forma nuova
      $up = $e.Groups[1].Value
      $area = $e.Groups[2].Value
      $path = $up + 'bin\$(Platform)\$(Config)'
      if ($area -ne '') { $path += '\' + $area }
      return '<DCC_ExeOutput>' + $path + '</DCC_ExeOutput>'
    })
    $block = $dcuRegex.Replace($block, {
      param($d)
      return '<DCC_DcuOutput>' + $d.Groups[1].Value + 'dcu\$(Platform)\$(Config)\' + $d.Groups[2].Value + '</DCC_DcuOutput>'
    })
    return $block
  })

  # ogni uscita rimasta deve essere nella forma nuova
  foreach ($m in [regex]::Matches($text, '<DCC_(Exe|Dcu)Output>[^<]*</DCC_(Exe|Dcu)Output>')) {
    if (-not ($exeNew.IsMatch($m.Value) -or $dcuNew.IsMatch($m.Value))) {
      $problems += ('{0}: {1}' -f $file.FullName.Substring($root.Length + 1), $m.Value)
    }
  }

  if ($text -ceq $original) {
    $unchanged++
    continue
  }
  $changed++
  if (-not $Prova) {
    $out = $utf8.GetBytes($text)
    if ($hasBom) { $out = [byte[]](0xEF, 0xBB, 0xBF) + $out }
    [System.IO.File]::WriteAllBytes($file.FullName, $out)
  }
}

Write-Host ("dproj riscritti: {0}, gia' a posto: {1}" -f $changed, $unchanged)
if ($problems.Count -gt 0) {
  Write-Host 'Uscite in una forma non riconosciuta:'
  $problems | ForEach-Object { Write-Host "  $_" }
  exit 1
}
