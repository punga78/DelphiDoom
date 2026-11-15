<#
  Issue #224: prova di ddc.exe prima e dopo. Compila 10 script (i 9 di Tests\Data\Ide\Compiler e uno con eventi,
  Format, Extended e TActor) con ddc.exe e le quattro DLL ddc_<gioco> della cartella -OldTools e della cartella
  -NewTools, per ognuno dei 4 giochi (40 confronti), e dice se il .ddout e l'uscita di testo sono uguali byte per byte.
  Uso:
    powershell -NoProfile -File Tools\Verifica\224\Confronta-Ddc.ps1 -OldTools <cartella> -NewTools <cartella> [-WorkRoot C:\ddparity_224]
  Ogni cartella ha ddc.exe e ddc_doom.dll, ddc_heretic.dll, ddc_hexen.dll, ddc_strife.dll (bin\Win32\Release\Tools).
#>
param(
  [Parameter(Mandatory = $true)][string]$OldTools,
  [Parameter(Mandatory = $true)][string]$NewTools,
  [string]$WorkRoot = 'C:\ddparity_224'
)

$root = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
$scripts = Join-Path $root 'Tests\Data\Ide\Compiler'
$games = 'doom', 'heretic', 'hexen', 'strife'

$work = Join-Path $WorkRoot 'ddc'
if (Test-Path $work) { Remove-Item $work -Recurse -Force }
New-Item -ItemType Directory -Force $work | Out-Null

$extra = @'
uses
  all;

var
  counter: Integer;
  total: Extended;

function Square(const x: Integer): Integer;
begin
  Result := x * x;
end;

event OnPlayerEnter(const playerNO: integer);
var
  k: LongWord;
begin
  k := GetPlayerActor(playerNO);
  WritelnFmt('PS: PLAYER %d health=%d', [playerNO, GetActorHealth(k)]);
  TActor(k).Health := 77;
  WritelnFmt('PS: square=%d sin=%s', [Square(12), FloatToStr(Sin360(30))]);
end;

event OnTick(const tick: Integer);
begin
  counter := counter + 1;
  total := total + 0.5;
end;
'@
$extraPath = Join-Path $work 'extra_events.ddscript'
Set-Content -Path $extraPath -Value $extra -Encoding ASCII

$inputs = @(Get-ChildItem $scripts -Filter *.ddscript | ForEach-Object { $_.FullName }) + $extraPath
$igual = 0; $diverso = 0
foreach ($tag in 'old', 'new') {
  $tools = if ($tag -eq 'old') { $OldTools } else { $NewTools }
  foreach ($game in $games) {
    foreach ($in in $inputs) {
      $name = [IO.Path]::GetFileNameWithoutExtension($in)
      New-Item -ItemType Directory -Force (Join-Path $work $tag) | Out-Null; $out = Join-Path $work "$tag\$game.$name.ddout"
      $txt = & (Join-Path $tools 'ddc.exe') -input $in -output $out "-$game" 2>&1 | Out-String
      Set-Content -Path "$out.txt" -Value $txt.Replace("\$tag\", "\X\") -Encoding ASCII
    }
  }
}
foreach ($game in $games) {
  foreach ($in in $inputs) {
    $name = [IO.Path]::GetFileNameWithoutExtension($in)
    $a = Join-Path $work "old\$game.$name.ddout"
    $b = Join-Path $work "new\$game.$name.ddout"
    $sameText = (Get-Content "$a.txt" -Raw) -eq (Get-Content "$b.txt" -Raw)
    $existA = Test-Path $a; $existB = Test-Path $b
    $sameBin = ($existA -eq $existB) -and ((-not $existA) -or ((Get-FileHash $a).Hash -eq (Get-FileHash $b).Hash))
    if ($sameText -and $sameBin) { $igual++ } else { $diverso++; Write-Host "DIVERSO: $game $name (testo=$sameText binario=$sameBin)" }
  }
}
Write-Host "Confronti: $($igual + $diverso); uguali: $igual; diversi: $diverso"
exit $(if ($diverso -eq 0) { 0 } else { 1 })
