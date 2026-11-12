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
  SysUtils, Classes, Windows, Generics.Collections,
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
