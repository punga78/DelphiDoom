<#
  Riscrive i .dproj del repository nella struttura standard di un progetto Delphi 11 creato dall'IDE,
  cosi' che l'IDE mostri le configurazioni Base, Debug e Release e le piattaforme Win32 e Win64 e salvi
  le modifiche nel gruppo giusto (issue "Configurazioni Debug e Release standard nei .dproj").

  Struttura prodotta (i valori sono quelli che i file avevano gia', solo spostati):

    PropertyGroup di intestazione        ProjectGuid, MainSource, ProjectVersion, FrameworkType, Base, Config
                                         (predefinita Release), Platform (predefinita Win32), TargetedPlatforms, AppType
    gruppi "bandiera"                    Base, Base_Win32, Base_Win64, Cfg_1 (Debug), Cfg_1_Win32, Cfg_1_Win64,
                                         Cfg_2 (Release), Cfg_2_Win32, Cfg_2_Win64, ciascuno con CfgParent
    gruppi dei valori                    '$(Base)'!=''  (valori comuni)       '$(Base_Win32)'!=''  (DCC_Platform x86)
                                         '$(Base_Win64)'!=''  (DCC_Platform x64)
                                         '$(Cfg_1)'!=''  (DEBUG, informazioni di debug, nessuna ottimizzazione, stack frame)
                                         '$(Cfg_2)'!=''  (RELEASE, senza informazioni di debug)
    ItemGroup                            invariato (DelphiCompile, RcCompile, DCCReference, BuildConfiguration)
    Import di CodeGear.Delphi.Targets, ProjectExtensions (Delphi.Personality.12, Source, Platforms), UserTools.proj

  Un progetto senza gruppo Win64 (oggi solo Tests\DelphiDoom.Tests.War.dproj, TargetedPlatforms 1) resta
  con la sola piattaforma Win32 e DCC_Platform nel gruppo Base, cosi' la valutazione di MSBuild e' identica a prima.

  Lo script e' ripetibile (un .dproj gia' riscritto non cambia) e conserva BOM e fine riga di ogni file.
  Lo stato di equivalenza si prova con Tools\Confronta-Proprieta-Dproj.ps1.

  Uso:   powershell -NoProfile -File Tools\Aggiorna-Configurazioni-Dproj.ps1 [-Prova]
         -Prova  non scrive nulla, elenca soltanto cosa cambierebbe
#>
param([switch]$Prova)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)

$groupRegex = [regex]'(?s)[ \t]*<PropertyGroup(?<attr>[^>]*)>\r?\n(?<body>.*?)[ \t]*</PropertyGroup>\r?\n'
$platformRegex = [regex]'(?m)^[ \t]*<DCC_Platform>[^<]*</DCC_Platform>\r?\n'

$changed = 0
$unchanged = 0
$problems = @()

$files = Get-ChildItem -Path $root -Recurse -Filter *.dproj -File |
  Where-Object { $_.FullName.Substring($root.Length) -notmatch '^\\(bin|dcu|logs|Reference|\.claude)\\' }

function New-Group {
  param([string]$Condition, [string[]]$Lines, [string]$NewLine)
  $result = '    <PropertyGroup'
  if ($Condition -ne '') { $result += ' Condition="' + $Condition + '"' }
  $result += '>' + $NewLine
  foreach ($line in $Lines) { $result += '        ' + $line + $NewLine }
  $result += '    </PropertyGroup>' + $NewLine
  return $result
}

function New-FlagGroup {
  # gruppo "bandiera" come lo scrive l'IDE: $Name vero, il genitore e tutta la catena fino a Base
  param([string]$Condition, [string]$Name, [string[]]$Chain, [string]$NewLine)
  $lines = @(('<' + $Name + '>true</' + $Name + '>'), ('<CfgParent>' + $Chain[0] + '</CfgParent>'))
  foreach ($item in $Chain) { $lines += '<' + $item + '>true</' + $item + '>' }
  return New-Group $Condition $lines $NewLine
}

foreach ($file in $files) {
  $rel = $file.FullName.Substring($root.Length + 1)
  $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
  $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
  $skip = if ($hasBom) { 3 } else { 0 }
  $text = $utf8.GetString($bytes, $skip, $bytes.Length - $skip)
  $nl = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }

  if ($text.Contains('<Cfg_1>true</Cfg_1>')) { $unchanged++; continue }   # gia' riscritto

  $matches_ = $groupRegex.Matches($text)
  $header = $null; $base = $null; $win64 = $null; $debug = $null; $release = $null
  foreach ($m in $matches_) {
    $attr = $m.Groups['attr'].Value
    if ($attr.Trim() -eq '') { $header = $m }
    elseif ($attr -match "Config\)'=='Debug'") { $debug = $m }
    elseif ($attr -match "Config\)'=='Release'") { $release = $m }
    elseif ($attr -match "Platform\)'=='Win64'") { $win64 = $m }
    elseif ($attr -match "'\`$\(Base\)'!=''") { $base = $m }
  }
  if ($null -eq $header -or $null -eq $base -or $null -eq $debug -or $null -eq $release) {
    $problems += ($rel + ': gruppi di proprieta'' non riconosciuti'); continue
  }
  $itemStart = $text.IndexOf('<ItemGroup>')
  $lastGroupEnd = ($matches_ | Select-Object -Last 1).Index + ($matches_ | Select-Object -Last 1).Length
  if ($itemStart -lt 0 -or $itemStart -lt $lastGroupEnd) { $problems += ($rel + ': ItemGroup non trovato'); continue }
  $rest = $text.Substring($itemStart)
  $prefix = $text.Substring(0, $header.Index)   # <Project ...>
  $between = $text.Substring($lastGroupEnd, $itemStart - $lastGroupEnd).Trim()
  if ($between -ne '') { $problems += ($rel + ': testo inatteso tra i gruppi e ItemGroup'); continue }

  function Get-Lines([string]$body) {
    return @($body -split "\r?\n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
  }
  $headerLines = Get-Lines $header.Groups['body'].Value
  $baseLines = Get-Lines $base.Groups['body'].Value
  $debugLines = Get-Lines $debug.Groups['body'].Value
  $releaseLines = Get-Lines $release.Groups['body'].Value
  $win64Lines = if ($null -ne $win64) { Get-Lines $win64.Groups['body'].Value } else { @() }

  # la bandiera Base nell'intestazione resta (come nei progetti dell'IDE)
  if (-not ($headerLines -contains '<Base>True</Base>')) { $problems += ($rel + ': manca <Base>True</Base>'); continue }
  $targeted = ($headerLines | Where-Object { $_ -match '^<TargetedPlatforms>' }) -replace '<[^>]+>', ''
  $mainSource = ($headerLines | Where-Object { $_ -match '^<MainSource>' }) -replace '<[^>]+>', ''
  $win64Targeted = ($null -ne $win64)
  if ($win64Targeted -ne ($targeted -eq '3')) { $problems += ($rel + ': TargetedPlatforms e gruppo Win64 non coerenti'); continue }

  # DCC_Platform: con Win64 va per piattaforma, senza resta nel gruppo Base
  $platformLine = @($baseLines | Where-Object { $_ -match '^<DCC_Platform>' })
  if ($platformLine.Count -ne 1) { $problems += ($rel + ': DCC_Platform non unico in Base'); continue }
  if ($win64Targeted) {
    $baseLines = @($baseLines | Where-Object { $_ -notmatch '^<DCC_Platform>' })
    $base32Lines = $platformLine
  }

  $out = $prefix
  $out += New-Group '' $headerLines $nl
  $out += New-Group "'`$(Config)'=='Base' or '`$(Base)'!=''" @('<Base>true</Base>') $nl
  $platforms = @('Win32')
  if ($win64Targeted) { $platforms += 'Win64' }
  foreach ($p in $platforms) {
    $out += New-FlagGroup ("('`$(Platform)'=='$p' and '`$(Base)'=='true') or '`$(Base_$p)'!=''") "Base_$p" @('Base') $nl
  }
  foreach ($cfg in @(@('Cfg_1', 'Debug'), @('Cfg_2', 'Release'))) {
    $name = $cfg[0]
    $out += New-Group ("'`$(Config)'=='" + $cfg[1] + "' or '`$($name)'!=''") @("<$name>true</$name>", '<CfgParent>Base</CfgParent>', '<Base>true</Base>') $nl
    foreach ($p in $platforms) {
      $out += New-Group ("('`$(Platform)'=='$p' and '`$($name)'=='true') or '`$(${name}_$p)'!=''") `
        @("<${name}_$p>true</${name}_$p>", "<CfgParent>$name</CfgParent>", "<$name>true</$name>", '<Base>true</Base>') $nl
    }
  }
  # valori, nell'ordine in cui MSBuild li deve applicare: Base, piattaforme di Base, Debug, Release
  $out += New-Group "'`$(Base)'!=''" $baseLines $nl
  if ($win64Targeted) {
    $out += New-Group "'`$(Base_Win32)'!=''" $base32Lines $nl
    $out += New-Group "'`$(Base_Win64)'!=''" $win64Lines $nl
  }
  $out += New-Group "'`$(Cfg_1)'!=''" $debugLines $nl
  $out += New-Group "'`$(Cfg_2)'!=''" $releaseLines $nl

  # ItemGroup e Import dei Targets restano; poi ProjectExtensions e UserTools
  $closing = '</Project>'
  $restBody = $rest.Substring(0, $rest.LastIndexOf($closing))
  $restBody = '    ' + $restBody.TrimEnd() + $nl   # l'indentazione prima di <ItemGroup> e' fuori da $rest
  $tail = $rest.Substring($rest.LastIndexOf($closing))
  $ext = @(
    '    <ProjectExtensions>',
    '        <Borland.Personality>Delphi.Personality.12</Borland.Personality>',
    '        <Borland.ProjectType/>',
    '        <BorlandProject>',
    '            <Delphi.Personality>',
    '                <Source>',
    ('                    <Source Name="MainSource">' + $mainSource + '</Source>'),
    '                </Source>',
    '            </Delphi.Personality>',
    '            <Platforms>',
    '                <Platform value="Win32">True</Platform>',
    ('                <Platform value="Win64">' + $(if ($win64Targeted) { 'True' } else { 'False' }) + '</Platform>'),
    '            </Platforms>',
    '        </BorlandProject>',
    '        <ProjectFileVersion>12</ProjectFileVersion>',
    '    </ProjectExtensions>',
    '    <Import Project="$(APPDATA)\Embarcadero\$(BDSAPPDATABASEDIR)\$(PRODUCTVERSION)\UserTools.proj" Condition="Exists(''$(APPDATA)\Embarcadero\$(BDSAPPDATABASEDIR)\$(PRODUCTVERSION)\UserTools.proj'')"/>'
  ) -join $nl
  $out += $restBody + $ext + $nl + $tail

  try { (New-Object System.Xml.XmlDocument).LoadXml($out) } catch { $problems += ($rel + ': XML non valido: ' + $_.Exception.Message); continue }
  $changed++
  if (-not $Prova) {
    $data = $utf8.GetBytes($out)
    if ($hasBom) { $data = [byte[]](0xEF, 0xBB, 0xBF) + $data }
    [System.IO.File]::WriteAllBytes($file.FullName, $data)
  }
}

Write-Host ("dproj riscritti: {0}, gia' a posto: {1}" -f $changed, $unchanged)
if ($problems.Count -gt 0) {
  Write-Host 'Problemi:'
  $problems | ForEach-Object { Write-Host "  $_" }
  exit 1
}
