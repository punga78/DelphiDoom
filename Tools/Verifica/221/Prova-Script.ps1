<#
  Issue #221: prova a runtime degli script dei giochi, da eseguire con l'eseguibile di prima e con quello di dopo
  e confrontare l'uscita (e le impronte dello stato).

  Costruisce un PWAD con un lump ACTORDEF che ha uno script di mappa (E1M1: eventi OnMapStart, OnPlayerEnter,
  OnTick, funzioni di SYSTEM e di PS_GAME, classe TActor in lettura e scrittura, array, Format, virgola mobile),
  avvia il gioco con il pilota automatico (-autodemo, 400 tic) e scrive in <Cartella>\<Tag>:
    script.txt   le righe dello script (quelle che iniziano con 'PS:'), nell'ordine in cui escono
    state.txt    l'impronta dello stato per tic (-statehash)
    stdout.txt   l'uscita completa del gioco
  Uso:
    powershell -NoProfile -File Tools\Verifica\221\Prova-Script.ps1 -Exe <Doom32.exe> -Tag dopo [-WorkRoot C:\ddparity_221]
#>
param(
  [Parameter(Mandatory = $true)][string]$Exe,
  [Parameter(Mandatory = $true)][string]$Tag,
  [string]$WorkRoot = 'C:\ddparity_221',
  [string]$DataRoot = '',
  [string]$Game = 'Doom',
  [string]$Iwad = 'DOOM1.WAD'
)
. (Join-Path $PSScriptRoot '..\185\Parity-Common.ps1')

$script = @'
SCRIPT E1M1
uses all;

var
  counter: Integer;
  total: Extended;

function Square(const x: Integer): Integer;
begin
  Result := x * x;
end;

event OnMapStart;
begin
  Writeln('PS: MAPSTART');
  WritelnFmt('PS: skill=%d map=%d', [GameSkill, GameMap]);
end;

event OnPlayerEnter(const playerNO: integer);
var
  k: LongWord;
begin
  k := GetPlayerActor(playerNO);
  WritelnFmt('PS: PLAYER %d health=%d', [playerNO, GetActorHealth(k)]);
  TActor(k).Health := 77;
  WritelnFmt('PS: after=%d', [GetActorHealth(k)]);
  WritelnFmt('PS: square=%d sin=%s', [Square(12), FloatToStr(Sin360(30))]);
  WritelnFmt('PS: tex=%d', [GetTextureWidth('STARTAN3')]);
end;

event OnTick(const tick: Integer);
begin
  counter := counter + 1;
  total := total + 0.5;
  if (counter mod 100) = 0 then
    WritelnFmt('PS: TICK %d counter=%d total=%s', [tick, counter, FloatToStr(total)]);
end;

event OnTimerEverySecond(const second: Integer);
begin
  WritelnFmt('PS: SECOND %d', [second]);
end;
ENDSCRIPT
'@

function New-TestWad([string]$Path, [string]$Text) {
  $data = [Text.Encoding]::ASCII.GetBytes($Text)
  $ms = New-Object IO.MemoryStream
  $w = New-Object IO.BinaryWriter($ms)
  $w.Write([Text.Encoding]::ASCII.GetBytes('PWAD'))
  $w.Write([int32]1)
  $w.Write([int32](12 + $data.Length))
  $w.Write($data)
  $w.Write([int32]12)
  $w.Write([int32]$data.Length)
  $name = [Text.Encoding]::ASCII.GetBytes('ACTORDEF')
  $w.Write($name)
  $w.Flush()
  [IO.File]::WriteAllBytes($Path, $ms.ToArray())
}

$dir = Initialize-ParityRunDir -Game $Game -WorkRoot (Join-Path $WorkRoot 'run') -DataRoot $DataRoot -Executables @{ 'script_test.exe' = $Exe }
New-TestWad (Join-Path $dir 'pstest.wad') $script
$out = Join-Path $WorkRoot $Tag
New-Item -ItemType Directory -Force $out | Out-Null
Remove-Item (Join-Path $dir 'ps.txt') -ErrorAction SilentlyContinue
Get-ChildItem (Join-Path $dir 'DATA\LOGS') -File -ErrorAction SilentlyContinue | Remove-Item -Force

$arguments = "-iwad $Iwad -file pstest.wad -config p8.ini -dontsavedefaults -nomusic -nosound -noblit -devparm " +
  "-warp 1 1 -skill 3 -autodemo 11 400 -statehash ps.txt"
$run = Invoke-ParityGame -Exe (Join-Path $dir 'script_test.exe') -Arguments $arguments -WorkDir $dir -TimeoutSeconds 300
Write-Output "exe=$Exe exit=$($run.ExitCode) crash=$($run.Crash) secondi=$($run.Seconds)"

Copy-Item (Join-Path $dir 'ps.txt') (Join-Path $out 'state.txt') -Force -ErrorAction SilentlyContinue
$stdout = Get-ChildItem (Join-Path $dir 'DATA\LOGS') -Filter '*_stdout.txt' -ErrorAction SilentlyContinue | Select-Object -First 1
if ($stdout) {
  Copy-Item $stdout.FullName (Join-Path $out 'stdout.txt') -Force
  Get-Content $stdout.FullName | Where-Object { $_.StartsWith('PS: ') } | ForEach-Object { $_.Trim() } |
    Set-Content (Join-Path $out 'script.txt')
}
$lines = @(Get-Content (Join-Path $out 'script.txt') -ErrorAction SilentlyContinue)
Write-Output "righe dello script: $($lines.Count)"
$lines | Select-Object -First 12
exit 0
