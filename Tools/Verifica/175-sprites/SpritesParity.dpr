program SpritesParity;
{$APPTYPE CONSOLE}
{$Q-}
{$R-}
// Harness fuori dalla suite: fa girare sugli stessi scenari (Tests\Source\DelphiDoom.Tests.Greed.SpriteScenarios)
// lo sprites.pas ORIGINALE di xGreed, non modificato, e TGreedSpriteLogic di Libs\Greed, li confronta tic per tic
// e scrive il golden (le impronte dell'originale). Il resto del gioco e' negli stub di stubs\ (spawn, utils, raven,
// modplay, net) e in quelli di ..\175-render\stubs (d_disk, d_misc, d_ints ...).
// Uso: SpritesParity <golden.txt | nessuno> [primo scenario] [ultimo scenario]
uses
  SysUtils, Classes, Windows, MMSystem, Math, Generics.Collections,
  g_delphi, protos_h, r_public_h, r_refdef, r_render, r_conten, r_public, raven, d_ints, d_misc, net, sprites,
  harness_convert,
  DelphiDoom.Greed.Types, DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.World.Intf,
  DelphiDoom.Greed.TargetAngles, DelphiDoom.Tests.Greed.SpriteScenarios, DelphiDoom.Tests.Greed.SpriteRunner;

type
  TOriginalRunner = class(TSpriteScenarioRunner)
  protected
    procedure LoadScenario(const AScenario: TSpriteScenario); override;
    procedure AppendSprite(const ASprite: TGreedSprite); override;
    procedure RemoveSprites(AFilter: TSpriteFilter); override;
    function SpriteCount: Integer; override;
    procedure GetPlayer(out APlayer: TScenarioPlayer); override;
    procedure SetPlayer(const APlayer: TScenarioPlayer); override;
    procedure SetGame(ATimeCount, ASpecialEffect: Integer); override;
    procedure ProbeShot(const ASprite: TGreedSprite; ASteps: Integer); override;
    procedure Think; override;
    procedure TraceState; override;
  end;

// the trig tables of RF_Startup and RF_InitTargets of r_public.pas, copied: RF_Startup needs the lumps of the game
procedure InitOriginalTables;
var
  at, atf: double;
  j, angle, x1, y1, i: integer;
  x, y: fixed_t;
  a: double;
begin
  for i := 0 to ANGLES do
  begin
    a := (i * g_PI * 2) / (ANGLES + 1);
    sintable[i] := rint(sin(a) * FRACUNIT);
    costable[i] := rint(cos(a) * FRACUNIT);
  end;
  for i := 0 to MAXAUTO - 1 do
    for j := 0 to MAXAUTO - 1 do
      autoangle2[i, j] := -1;
  i := 0;
  repeat
    at := ArcTan(i / MAXAUTO);
    atf := at * ANGLES / (2 * g_PI);
    angle := rint(atf);
    for j := 0 to MAXAUTO * 2 - 1 do
    begin
      y := FIXEDMUL(sintable[angle], j * FRACUNIT);
      x := FIXEDMUL(costable[angle], j * FRACUNIT);
      x1 := x div FRACUNIT;
      y1 := y div FRACUNIT;
      if (x1 >= MAXAUTO) or (y1 >= MAXAUTO) or (autoangle2[x1][y1] <> -1) then
        continue;
      autoangle2[x1][y1] := angle;
    end;
    inc(i);
  until angle >= DEGREE45 + DEGREE45_2;

  for i := MAXAUTO - 1 downto 1 do
    for j := 0 to MAXAUTO - 1 do
      if autoangle2[j][i] = -1 then
        autoangle2[j][i] := autoangle2[j][i - 1];
  for i := MAXAUTO - 1 downto 1 do
    for j := 0 to MAXAUTO - 1 do
      if autoangle2[j][i] = -1 then
        autoangle2[j][i] := autoangle2[j][i - 1];
end;

// MoveSprites reads its local "killed" before giving it a value: the stack under it is cleared, so that what the
// original does there does not depend on the calls made before
procedure ScrubStack;
var
  buf: array[0..16383] of Byte;
begin
  FillChar(buf, SizeOf(buf), 0);
end;

{ TOriginalRunner }

procedure TOriginalRunner.LoadScenario(const AScenario: TSpriteScenario);
var
  i: Integer;
  d: Pdoorobj_t;
begin
  HarnessTrace := Trace;
  Move(AScenario.Planes[gpNorthWall][0], northwall[0], 4096);
  Move(AScenario.Planes[gpNorthFlags][0], northflags[0], 4096);
  Move(AScenario.Planes[gpWestWall][0], westwall[0], 4096);
  Move(AScenario.Planes[gpWestFlags][0], westflags[0], 4096);
  Move(AScenario.Planes[gpFloorPic][0], floorpic[0], 4096);
  Move(AScenario.Planes[gpFloorFlags][0], floorflags[0], 4096);
  Move(AScenario.Planes[gpCeilingPic][0], ceilingpic[0], 4096);
  Move(AScenario.Planes[gpCeilingFlags][0], ceilingflags[0], 4096);
  Move(AScenario.Planes[gpFloorHeight][0], floorheight[0], 4096);
  Move(AScenario.Planes[gpCeilingHeight][0], ceilingheight[0], 4096);
  Move(AScenario.Planes[gpFloorDef][0], floordef[0], 4096);
  Move(AScenario.Planes[gpFloorDefFlags][0], floordefflags[0], 4096);
  Move(AScenario.Planes[gpCeilingDef][0], ceilingdef[0], 4096);
  Move(AScenario.Planes[gpCeilingDefFlags][0], ceilingdefflags[0], 4096);
  Move(AScenario.Planes[gpMapLights][0], maplights[0], 4096);
  Move(AScenario.Planes[gpMapEffects][0], mapeffects[0], 4096);
  Move(AScenario.Planes[gpMapSprites][0], mapsprites[0], 4096);
  Move(AScenario.Planes[gpMapSlopes][0], mapslopes[0], 4096);
  Move(AScenario.MapFlags[0], mapflags[0], 4096);
  FillChar(reallight, SizeOf(reallight), 0);
  FillChar(doorlist, SizeOf(doorlist), 0);
  for i := 0 to High(AScenario.Doors) do
  begin
    d := @doorlist[i];
    d.tilex := AScenario.Doors[i].TileX;
    d.tiley := AScenario.Doors[i].TileY;
    d.doorOpen := AScenario.Doors[i].Open;
    d.doorOpening := AScenario.Doors[i].Opening;
    d.doorClosing := AScenario.Doors[i].Closing;
    d.doorBlocked := AScenario.Doors[i].Blocked;
    d.doorBumpable := AScenario.Doors[i].Bumpable;
    d.doorTimer := AScenario.Doors[i].Timer;
    d.orientation := orientation_t(Ord(AScenario.Doors[i].Orientation));
    d.position := AScenario.Doors[i].Position;
  end;
  numdoors := Length(AScenario.Doors);
  // the list of the sprites, as RF_ClearWorld
  firstscaleobj.prev := nil;
  firstscaleobj.next := @lastscaleobj;
  lastscaleobj.prev := @firstscaleobj;
  lastscaleobj.next := nil;
  freescaleobj_p := @scaleobjlist[0];
  FillChar(scaleobjlist, SizeOf(scaleobjlist), 0);
  for i := 0 to MAXSPRITES - 2 do
    scaleobjlist[i].next := @scaleobjlist[i + 1];
  FillChar(player, SizeOf(player), 0);
  SetPlayer(AScenario.Player);
  playernum := AScenario.PlayerNum;
  specialeffect := AScenario.SpecialEffect;
  timecount := AScenario.TimeCount;
  rndofs := AScenario.RandomOffset;
  netmode := false;
  player_angle64 := 0;
  msprite := nil;
  FillChar(probe, SizeOf(probe), 0);
  spritehit := false;
  playerhit := false;
  hitx := 0;
  hity := 0;
  targx := 0;
  targy := 0;
  targz := 0;
  spriteloc := 0;
  for i := 0 to High(AScenario.Sprites) do
    AppendSprite(AScenario.Sprites[i]);
end;

procedure TOriginalRunner.AppendSprite(const ASprite: TGreedSprite);
begin
  FromLibrary(ASprite, RF_GetSprite);
end;

procedure TOriginalRunner.RemoveSprites(AFilter: TSpriteFilter);
var
  s, n: Pscaleobj_t;
begin
  s := firstscaleobj.next;
  while s <> @lastscaleobj do
  begin
    n := s.next;
    if AFilter(ToLibrary(s^)) then
      RF_RemoveSprite(s);
    s := n;
  end;
end;

function TOriginalRunner.SpriteCount: Integer;
var
  s: Pscaleobj_t;
begin
  Result := 0;
  s := firstscaleobj.next;
  while s <> @lastscaleobj do
  begin
    Inc(Result);
    s := s.next;
  end;
end;

procedure TOriginalRunner.GetPlayer(out APlayer: TScenarioPlayer);
begin
  APlayer.X := player.x;
  APlayer.Y := player.y;
  APlayer.Z := player.z;
  APlayer.Height := player.height;
  APlayer.Angle := player.angle;
  APlayer.Angst := player.angst;
  APlayer.Difficulty := player.difficulty;
  APlayer.MapSpot := player.mapspot;
  APlayer.BodyCount := player.bodycount;
end;

procedure TOriginalRunner.SetPlayer(const APlayer: TScenarioPlayer);
begin
  player.x := APlayer.X;
  player.y := APlayer.Y;
  player.z := APlayer.Z;
  player.height := APlayer.Height;
  player.angle := APlayer.Angle;
  player.angst := APlayer.Angst;
  player.difficulty := APlayer.Difficulty;
  player.mapspot := APlayer.MapSpot;
  player.bodycount := APlayer.BodyCount;
end;

procedure TOriginalRunner.SetGame(ATimeCount, ASpecialEffect: Integer);
begin
  timecount := ATimeCount;
  specialeffect := ASpecialEffect;
end;

procedure TOriginalRunner.ProbeShot(const ASprite: TGreedSprite; ASteps: Integer);
var
  i, r: Integer;
begin
  FillChar(probe, SizeOf(probe), 0);
  FromLibrary(ASprite, @probe);
  msprite := @probe;
  r := 0;
  for i := 1 to ASteps do
  begin
    r := SP_Thrust;
    if r <> 0 then
      Break;
  end;
  Trace.Add(r, 'probe.result');
  Trace.Add(probe.x, 'probe.x');
  Trace.Add(probe.y, 'probe.y');
  Trace.Add(probe.z, 'probe.z');
end;

procedure TOriginalRunner.Think;
begin
  ScrubStack;
  MoveSprites;
end;

procedure TOriginalRunner.TraceState;
var
  s: Pscaleobj_t;
  i, n: Integer;
  p: TScenarioPlayer;
begin
  Trace.Add(SpriteCount, 'sprites');
  n := 0;
  s := firstscaleobj.next;
  while s <> @lastscaleobj do
  begin
    Trace.AddSprite(ToLibrary(s^), n);
    Inc(n);
    s := s.next;
  end;
  GetPlayer(p);
  Trace.AddPlayer(p);
  Trace.Add(player_angle64, 'player_angle64');
  Trace.Add(spritehit, 'spritehit');
  Trace.Add(playerhit, 'playerhit');
  Trace.Add(hitx, 'hitx');
  Trace.Add(hity, 'hity');
  Trace.Add(targx, 'targx');
  Trace.Add(targy, 'targy');
  Trace.Add(targz, 'targz');
  Trace.Add(spriteloc, 'spriteloc');
  Trace.Add(numdoors, 'doors');
  for i := 0 to numdoors - 1 do
    Trace.AddDoor(DoorToLibrary(doorlist[i]), i);
  Trace.AddBytes(@mapsprites[0], 4096, 'mapsprites');
  Trace.AddIntegers(@reallight[0], 4096, 'reallight');
  Trace.Add(rndofs, 'rndofs');
end;

function TargetAnglesHash(AOriginal: Boolean): Cardinal;
var
  t: TSpriteTrace;
  i, j: Integer;
begin
  t := TSpriteTrace.Create;
  try
    t.Reset(nil);
    for i := 0 to MAXAUTO - 1 do
      for j := 0 to MAXAUTO - 1 do
        if AOriginal then
          t.Add(autoangle2[i][j], '')
        else
          t.Add(TGreedTargetAngles.Angle(i, j), '');
    Result := t.Hash;
  finally
    t.Free;
  end;
end;

procedure SortValues(var AValues: TArray<Double>);
var
  i, j: Integer;
  v: Double;
begin
  for i := 1 to High(AValues) do
  begin
    v := AValues[i];
    j := i - 1;
    while (j >= 0) and (AValues[j] > v) do
    begin
      AValues[j + 1] := AValues[j];
      Dec(j);
    end;
    AValues[j + 1] := v;
  end;
end;

// minimum, median, quartiles and dispersion (max - min) / min of a series, as Tools\Misura-Coppie.ps1
procedure PrintSeries(const AName: string; const AValues: TArray<Double>; const AFormat: string;
  out AMin, AMedian, ADispersion: Double);
var
  v: TArray<Double>;
  n: Integer;
begin
  v := Copy(AValues);
  SortValues(v);
  n := Length(v);
  AMin := v[0];
  if Odd(n) then
    AMedian := v[n div 2]
  else
    AMedian := (v[n div 2 - 1] + v[n div 2]) / 2;
  ADispersion := (v[n - 1] - v[0]) / v[0] * 100;
  Writeln(Format('%s min ' + AFormat + '  q1 ' + AFormat + '  mediana ' + AFormat + '  q3 ' + AFormat + '  max ' +
    AFormat + '  dispersione %.2f%%', [AName, v[0], v[n div 4], AMedian, v[(3 * n) div 4], v[n - 1], ADispersion]));
end;

// Misura a coppie (il criterio di Tools\Misura-Coppie.ps1): a ogni ripetizione l'originale e la libreria fanno tutti gli
// scenari, in ordine invertito a ogni coppia; il tempo e' quello di MoveSprites da solo (Think), per tic. La misura
// e' rifiutata se la dispersione dell'originale supera AMaxDispersion
function Measure(ARepetitions, AFirst, ALast: Integer; AMaxDispersion, AThreshold: Double): Integer;
var
  Original: TOriginalRunner;
  Lib: TLibrarySpriteRunner;
  Hashes: TList<Cardinal>;
  Scenarios: TArray<TSpriteScenario>;
  Scenario: TSpriteScenario;
  OriginalTimes, LibTimes, Ratios, OriginalBest, LibBest: TArray<Double>;
  Index, Repetition, Side, Tics, Count: Integer;
  Frequency, Start, Stop: Int64;
  OriginalMin, OriginalMedian, OriginalDispersion, LibMin, LibMedian, LibDispersion, RatioMin, RatioMedian,
    RatioDispersion, Scrub, Elapsed, OriginalBestSum, LibBestSum: Double;
begin
  Original := TOriginalRunner.Create;
  Lib := TLibrarySpriteRunner.Create;
  Hashes := TList<Cardinal>.Create;
  Tics := 0;
  Count := 0;
  SetLength(Scenarios, ALast - AFirst + 1);
  // the scenarios on which the original does not crash; this pass also warms both sides up
  for Index := AFirst to ALast do
  begin
    Scenario := BuildSpriteScenario(Index);
    Hashes.Clear;
    try
      Original.Run(Scenario, Hashes);
    except
      Continue;
    end;
    Tics := Tics + Hashes.Count;
    Hashes.Clear;
    Lib.Run(Scenario, Hashes);
    Scenarios[Count] := Scenario;
    Inc(Count);
  end;
  SetLength(Scenarios, Count);
  SetLength(OriginalTimes, ARepetitions);
  SetLength(LibTimes, ARepetitions);
  SetLength(Ratios, ARepetitions);
  SetLength(OriginalBest, Count);
  SetLength(LibBest, Count);
  for Index := 0 to Count - 1 do
  begin
    OriginalBest[Index] := MaxDouble;
    LibBest[Index] := MaxDouble;
  end;
  // the other programs of the machine (compilers, other tests) should not take the processor away
  SetPriorityClass(GetCurrentProcess, HIGH_PRIORITY_CLASS);
  for Repetition := 0 to ARepetitions - 1 do
  begin
    OriginalTimes[Repetition] := 0;
    LibTimes[Repetition] := 0;
    for Side := 0 to 1 do
      for Index := 0 to Count - 1 do
      begin
        Hashes.Clear;
        if (Side = 0) <> Odd(Repetition) then
        begin
          Original.ResetThinkTime;
          Original.Run(Scenarios[Index], Hashes);
          Elapsed := Original.ThinkMicroseconds;
          OriginalTimes[Repetition] := OriginalTimes[Repetition] + Elapsed / Tics;
          if Elapsed < OriginalBest[Index] then
            OriginalBest[Index] := Elapsed;
        end
        else
        begin
          Lib.ResetThinkTime;
          Lib.Run(Scenarios[Index], Hashes);
          Elapsed := Lib.ThinkMicroseconds;
          LibTimes[Repetition] := LibTimes[Repetition] + Elapsed / Tics;
          if Elapsed < LibBest[Index] then
            LibBest[Index] := Elapsed;
        end;
      end;
    Ratios[Repetition] := LibTimes[Repetition] / OriginalTimes[Repetition];
  end;
  // the best time of each scenario over all the repetitions: what the noise of the machine touches least
  OriginalBestSum := 0;
  LibBestSum := 0;
  for Index := 0 to Count - 1 do
  begin
    OriginalBestSum := OriginalBestSum + OriginalBest[Index] / Tics;
    LibBestSum := LibBestSum + LibBest[Index] / Tics;
  end;
  // the Think of the original also clears 16 KB of stack (ScrubStack): how much of its time that is
  QueryPerformanceFrequency(Frequency);
  QueryPerformanceCounter(Start);
  for Index := 1 to 100000 do
    ScrubStack;
  QueryPerformanceCounter(Stop);
  Scrub := (Stop - Start) * 1000000 / Frequency / 100000;
  Writeln(Format('misura a coppie: %d scenari, %d tic, %d coppie; MoveSprites da solo, microsecondi per tic',
    [Count, Tics, ARepetitions]));
  PrintSeries('originale:', OriginalTimes, '%.2f', OriginalMin, OriginalMedian, OriginalDispersion);
  PrintSeries('libreria: ', LibTimes, '%.2f', LibMin, LibMedian, LibDispersion);
  PrintSeries('rapporto per coppia (libreria/originale):', Ratios, '%.3f', RatioMin, RatioMedian, RatioDispersion);
  Writeln(Format('somma dei tempi migliori di ogni scenario: originale %.2f, libreria %.2f, rapporto %.3f',
    [OriginalBestSum, LibBestSum, LibBestSum / OriginalBestSum]));
  // where the difference is: the six kinds of scenario (0 mixed, 1 bullets, 2 monsters, 3 doors, 4 mines and clones)
  for Side := 0 to 5 do
  begin
    OriginalBestSum := 0;
    LibBestSum := 0;
    for Index := 0 to Count - 1 do
      if Scenarios[Index].Index mod 6 = Side then
      begin
        OriginalBestSum := OriginalBestSum + OriginalBest[Index] / Tics;
        LibBestSum := LibBestSum + LibBest[Index] / Tics;
      end;
    if OriginalBestSum > 0 then
      Writeln(Format('  scenari del tipo %d: originale %.2f, libreria %.2f, rapporto %.3f',
        [Side, OriginalBestSum, LibBestSum, LibBestSum / OriginalBestSum]));
  end;
  Writeln(Format('rapporto delle mediane %.3f, dei minimi %.3f; ScrubStack (solo nell''originale) %.2f us per tic: ' +
    'senza, mediane %.3f, minimi %.3f', [LibMedian / OriginalMedian, LibMin / OriginalMin, Scrub,
    LibMedian / (OriginalMedian - Scrub), LibMin / (OriginalMin - Scrub)]));
  if OriginalDispersion > AMaxDispersion then
  begin
    Writeln(Format('verdetto: misura non affidabile (la dispersione dell''originale, %.2f%%, supera %.1f%%)',
      [OriginalDispersion, AMaxDispersion]));
    Exit(3);
  end;
  if (LibMedian / OriginalMedian <= 1 + AThreshold / 100) and (LibMin / OriginalMin <= 1 + AThreshold / 100) then
  begin
    Writeln(Format('verdetto: entro il %.0f%%', [AThreshold]));
    Exit(0);
  end;
  Writeln(Format('verdetto: oltre il %.0f%%', [AThreshold]));
  Result := 1;
end;

type
  // Profilo a campioni: ogni millisecondo ferma il thread principale e ne prende l'indirizzo dell'istruzione
  TSampler = class(TThread)
  public
    Target: THandle;
    Samples: TArray<Cardinal>;
    Count: Integer;
    procedure Execute; override;
  end;

procedure TSampler.Execute;
var
  Context: TContext;
begin
  while not Terminated do
  begin
    Sleep(1);
    if (Count < Length(Samples)) and (SuspendThread(Target) <> Cardinal(-1)) then
    begin
      Context.ContextFlags := CONTEXT_CONTROL;
      if GetThreadContext(Target, Context) then
      begin
        Samples[Count] := Context.Eip;
        Inc(Count);
      end;
      ResumeThread(Target);
    end;
  end;
end;

// Dove va il tempo di un lato ('o' originale, 'l' libreria): APasses giri di tutti gli scenari con il campionatore, poi
// i campioni sono attribuiti alle routine con il file .map dell'eseguibile (dcc32 -GD) e si stampano le prime ATop.
// I campioni caduti nel driver degli scenari e nella traccia ci sono per entrambi i lati: si leggono le righe di
// sprites.pas / r_public.pas da una parte e di DelphiDoom.Greed.* dall'altra
procedure Profile(ASide: Char; APasses, ATop: Integer);
var
  Runner: TSpriteScenarioRunner;
  Hashes: TList<Cardinal>;
  Scenarios: TArray<TSpriteScenario>;
  Sampler: TSampler;
  Map: TStringList;
  Addresses: TArray<Cardinal>;
  Names: TArray<string>;
  Hits: TArray<Integer>;
  Order: TArray<Integer>;
  Index, Pass, SymbolCount, Lower, Upper, Middle, Position, Swap, Total: Integer;
  Line, Address: string;
  Main: THandle;
  InPublics: Boolean;
begin
  if ASide = 'o' then
    Runner := TOriginalRunner.Create
  else
    Runner := TLibrarySpriteRunner.Create;
  Hashes := TList<Cardinal>.Create;
  SetLength(Scenarios, SPRITE_SCENARIO_COUNT);
  for Index := 0 to SPRITE_SCENARIO_COUNT - 1 do
    Scenarios[Index] := BuildSpriteScenario(Index);
  DuplicateHandle(GetCurrentProcess, GetCurrentThread, GetCurrentProcess, @Main, 0, False, DUPLICATE_SAME_ACCESS);
  Sampler := TSampler.Create(True);
  Sampler.Target := Main;
  SetLength(Sampler.Samples, 4000000);
  timeBeginPeriod(1);
  Sampler.Priority := tpTimeCritical;
  Sampler.Start;
  for Pass := 1 to APasses do
    for Index := 0 to SPRITE_SCENARIO_COUNT - 1 do
    begin
      Hashes.Clear;
      Runner.Run(Scenarios[Index], Hashes);
    end;
  Sampler.Terminate;
  Sampler.WaitFor;
  timeEndPeriod(1);
  // the publics by value of the map file: " 0001:000A1234       Unit.Symbol", the code segment starts at $401000
  Map := TStringList.Create;
  Map.LoadFromFile(ChangeFileExt(ParamStr(0), '.map'));
  SetLength(Addresses, Map.Count);
  SetLength(Names, Map.Count);
  SymbolCount := 0;
  InPublics := False;
  for Index := 0 to Map.Count - 1 do
  begin
    Line := Map[Index];
    if Pos('Publics by Value', Line) > 0 then
      InPublics := True
    else if InPublics and (Pos('Line numbers for', Line) > 0) then
      Break
    else if InPublics and (Copy(Line, 1, 6) = ' 0001:') then
    begin
      Address := Copy(Line, 7, 8);
      Addresses[SymbolCount] := Cardinal(StrToInt('$' + Address)) + $401000;
      Names[SymbolCount] := Trim(Copy(Line, 15, MaxInt));
      Inc(SymbolCount);
    end;
  end;
  SetLength(Hits, SymbolCount);
  Total := 0;
  for Index := 0 to Sampler.Count - 1 do
  begin
    // the last symbol that does not start after the sample
    Lower := 0;
    Upper := SymbolCount - 1;
    Position := -1;
    while Lower <= Upper do
    begin
      Middle := (Lower + Upper) div 2;
      if Addresses[Middle] <= Sampler.Samples[Index] then
      begin
        Position := Middle;
        Lower := Middle + 1;
      end
      else
        Upper := Middle - 1;
    end;
    if Position >= 0 then
    begin
      Inc(Hits[Position]);
      Inc(Total);
    end;
  end;
  SetLength(Order, SymbolCount);
  for Index := 0 to SymbolCount - 1 do
    Order[Index] := Index;
  Writeln(Format('profilo del lato %s: %d giri, %d campioni', [ASide, APasses, Sampler.Count]));
  for Index := 0 to ATop - 1 do
  begin
    if Index >= SymbolCount then
      Break;
    for Pass := Index + 1 to SymbolCount - 1 do
      if Hits[Order[Pass]] > Hits[Order[Index]] then
      begin
        Swap := Order[Index];
        Order[Index] := Order[Pass];
        Order[Pass] := Swap;
      end;
    if Hits[Order[Index]] = 0 then
      Break;
    Writeln(Format('%7d %5.1f%%  %s', [Hits[Order[Index]], Hits[Order[Index]] * 100 / Total, Names[Order[Index]]]));
  end;
end;

var
  GoldenPath: string;
  First, Last, Index, Tic, Line, TotalTics, TotalDifferences, Skipped, Compared: Integer;
  Scenario: TSpriteScenario;
  Original: TOriginalRunner;
  Lib: TLibrarySpriteRunner;
  OriginalHashes, LibHashes: TList<Cardinal>;
  OriginalDump, LibDump: TStringList;
  Golden: TStringList;
  Frequency, Start, Stop, OriginalTime, LibTime: Int64;
  Crashed: Boolean;
begin
  try
    GoldenPath := ParamStr(1);
    if GoldenPath = 'nessuno' then
      GoldenPath := '';
    First := StrToIntDef(ParamStr(2), 0);
    Last := StrToIntDef(ParamStr(3), SPRITE_SCENARIO_COUNT - 1);
    if Last > SPRITE_SCENARIO_COUNT - 1 then
      Last := SPRITE_SCENARIO_COUNT - 1;
    InitOriginalTables;
    // SpritesParity misura <coppie> [primo] [ultimo] [dispersione massima %] [soglia %]
    if GoldenPath = 'misura' then
    begin
      FormatSettings := TFormatSettings.Invariant;
      First := StrToIntDef(ParamStr(3), 0);
      Last := StrToIntDef(ParamStr(4), SPRITE_SCENARIO_COUNT - 1);
      if Last > SPRITE_SCENARIO_COUNT - 1 then
        Last := SPRITE_SCENARIO_COUNT - 1;
      ExitCode := Measure(StrToIntDef(ParamStr(2), 21), First, Last, StrToFloatDef(ParamStr(5), 3),
        StrToFloatDef(ParamStr(6), 5));
      Exit;
    end;
    // SpritesParity profilo <o|l> [giri] [righe]
    if GoldenPath = 'profilo' then
    begin
      FormatSettings := TFormatSettings.Invariant;
      Profile((ParamStr(2) + 'l')[1], StrToIntDef(ParamStr(3), 20), StrToIntDef(ParamStr(4), 45));
      Exit;
    end;
    Golden := TStringList.Create;
    Golden.Add('# impronte FNV-1a, tic per tic, di sprites.pas ORIGINALE di xGreed sugli scenari di');
    Golden.Add('# DelphiDoom.Tests.Greed.SpriteScenarios (harness Tools\Verifica\175-sprites). A = autoangle2;');
    Golden.Add('# S <scenario> <tic> seguito da una riga per tic; X <scenario> = l''originale cade, saltato');
    Golden.Add('A ' + IntToHex(TargetAnglesHash(True), 8));
    if TargetAnglesHash(True) <> TargetAnglesHash(False) then
      Writeln('DIFFERENZA: autoangle2')
    else
      Writeln('autoangle2: uguale (', IntToHex(TargetAnglesHash(True), 8), ')');
    Original := TOriginalRunner.Create;
    Lib := TLibrarySpriteRunner.Create;
    OriginalHashes := TList<Cardinal>.Create;
    LibHashes := TList<Cardinal>.Create;
    OriginalDump := TStringList.Create;
    LibDump := TStringList.Create;
    TotalTics := 0;
    TotalDifferences := 0;
    Skipped := 0;
    Compared := 0;
    OriginalTime := 0;
    LibTime := 0;
    QueryPerformanceFrequency(Frequency);
    for Index := First to Last do
    begin
      Scenario := BuildSpriteScenario(Index);
      OriginalHashes.Clear;
      LibHashes.Clear;
      Crashed := False;
      QueryPerformanceCounter(Start);
      try
        Original.Run(Scenario, OriginalHashes);
      except
        on E: Exception do
        begin
          Writeln('scenario ', Index, ': l''originale cade al tic ', OriginalHashes.Count, ': ', E.ClassName, ' ',
            E.Message);
          Crashed := True;
        end;
      end;
      QueryPerformanceCounter(Stop);
      if Crashed then
      begin
        Golden.Add('X ' + IntToStr(Index));
        Inc(Skipped);
        Continue;
      end;
      OriginalTime := OriginalTime + (Stop - Start);
      Golden.Add(Format('S %d %d', [Index, OriginalHashes.Count]));
      for Tic := 0 to OriginalHashes.Count - 1 do
        Golden.Add(IntToHex(OriginalHashes[Tic], 8));
      QueryPerformanceCounter(Start);
      Lib.Run(Scenario, LibHashes);
      QueryPerformanceCounter(Stop);
      LibTime := LibTime + (Stop - Start);
      Inc(Compared);
      TotalTics := TotalTics + OriginalHashes.Count;
      Tic := 0;
      while (Tic < OriginalHashes.Count) and (Tic < LibHashes.Count) and (OriginalHashes[Tic] = LibHashes[Tic]) do
        Inc(Tic);
      if (Tic < OriginalHashes.Count) or (LibHashes.Count <> OriginalHashes.Count) then
      begin
        Inc(TotalDifferences);
        Writeln('scenario ', Index, ': DIFFERENZA al tic ', Tic, ' (tic originale ', OriginalHashes.Count,
          ', libreria ', LibHashes.Count, ')');
        OriginalDump.Clear;
        LibDump.Clear;
        OriginalHashes.Clear;
        LibHashes.Clear;
        Original.Run(Scenario, OriginalHashes, Tic, OriginalDump);
        Lib.Run(Scenario, LibHashes, Tic, LibDump);
        Line := 0;
        while (Line < OriginalDump.Count) and (Line < LibDump.Count) and (OriginalDump[Line] = LibDump[Line]) do
          Inc(Line);
        if Line > 0 then
          Writeln('    prima: ', OriginalDump[Line - 1]);
        if Line < OriginalDump.Count then
          Writeln('    originale: ', OriginalDump[Line]);
        if Line < LibDump.Count then
          Writeln('    libreria:  ', LibDump[Line]);
      end
      else
        Writeln('scenario ', Index, ': ', OriginalHashes.Count, ' tic, ', Length(Scenario.Sprites),
          ' sprite all''inizio, uguale');
    end;
    Writeln(Format('scenari %d, confrontati %d, saltati %d, tic %d, scenari con differenze %d',
      [Last - First + 1, Compared, Skipped, TotalTics, TotalDifferences]));
    if TotalTics > 0 then
    begin
      Writeln(Format('tempo per tic (traccia compresa): originale %.1f us, libreria %.1f us',
        [OriginalTime * 1000000 / Frequency / TotalTics, LibTime * 1000000 / Frequency / TotalTics]));
      Writeln(Format('MoveSprites da solo, per tic: originale %.1f us, libreria %.1f us',
        [Original.ThinkMicroseconds / TotalTics, Lib.ThinkMicroseconds / TotalTics]));
    end;
    if GoldenPath <> '' then
    begin
      Golden.SaveToFile(GoldenPath);
      Writeln('golden: ', GoldenPath);
    end;
    if TotalDifferences <> 0 then
      ExitCode := 1;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ExitCode := 2;
    end;
  end;
end.
