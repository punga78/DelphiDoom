program SpawnGolden;
// Issue #175: runs SpawnSprite of spawn.pas of xGreed AS IT IS (Reference\xGreed, read only) on the scenarios of
// Tests\Source\DelphiDoom.Tests.Greed.SpawnScenarios and writes one line for each case: the golden file that
// the test of TGreedSpawner compares with the library. See Compila.ps1.
// Use: SpawnGolden <golden file> [<file of the full descriptions>]
{$APPTYPE CONSOLE}
{$Q-}
{$R-}

uses
  SysUtils,
  Classes,
  g_delphi,
  r_public_h,
  r_refdef,
  protos_h,
  constant,
  d_disk,
  d_ints,
  d_misc,
  modplay,
  net,
  raven,
  r_conten,
  r_render,
  r_public,
  utils,
  spawn,
  DelphiDoom.Tests.Greed.SpawnScenarios;

var
  Maps: array[1..6] of TSpawnMap;
  Demands: TArray<TSpawnRow>;

// the lumps that DemandLoadMonster cached in the last call are one demand: the first lump and how many. The cache
// is emptied, so that the next call asks again (the library tells every demand to who keeps the pictures)
procedure CollectDemand;
var
  i, n: integer;
begin
  if numcachedlumps = 0 then
    exit;
  for i := 1 to numcachedlumps - 1 do
    if cachedlumps[i] <> cachedlumps[0] + i then
      raise Exception.Create('DemandLoadMonster: the lumps are not in a row');
  n := Length(Demands);
  SetLength(Demands, n + 1);
  Demands[n] := TSpawnRow.Create(SPAWN_CALL_DEMAND, cachedlumps[0], numcachedlumps, 0, 0);
  CA_ForgetLumps;
end;

procedure Prepare(const ACase: TSpawnCase);
var
  i: integer;
  s: Pscaleobj_t;
begin
  RF_ClearWorld;
  FillChar(doorlist, SizeOf(doorlist), 0);
  FillChar(spawnareas, SizeOf(spawnareas), 0);
  CA_ForgetLumps;
  Demands := nil;
  numsoundcalls := 0;
  Move(Maps[ACase.MapSeed].FloorHeight, floorheight, SPAWN_TILES);
  Move(Maps[ACase.MapSeed].CeilingHeight, ceilingheight, SPAWN_TILES);
  Move(Maps[ACase.MapSeed].FloorPic, floorpic, SPAWN_TILES);
  Move(Maps[ACase.MapSeed].CeilingPic, ceilingpic, SPAWN_TILES);
  Move(Maps[ACase.MapSeed].MapFlags, mapflags, SPAWN_TILES);
  Move(Maps[ACase.MapSeed].MapSprites, mapsprites, SPAWN_TILES);
  FillChar(player, SizeOf(player), 0);
  player.x := ACase.PlayerX;
  player.y := ACase.PlayerY;
  player.z := ACase.PlayerZ;
  player.height := ACase.PlayerHeight;
  player.timecount := ACase.PlayerTime;
  player_angle64 := 0;
  FillChar(startlocations, SizeOf(startlocations), 0);
  exitexists := false;
  exitx := 0;
  exity := 0;
  timecount := ACase.TimeCount;
  midgetmode := ACase.Midget;
  nospawn := ACase.NoSpawn;
  SC.violence := ACase.Violence;
  playernum := ACase.PlayerNum;
  netmode := false;
  gameloading := false;
  for i := 0 to 3 do
    primaries[i] := ACase.Primaries[i];
  for i := 0 to 13 do
    secondaries[i] := ACase.Secondaries[i];
  for i := 0 to ACase.Prefill - 1 do
  begin
    s := RF_GetSprite;
    s.typ := TSpawnScenarios.PrefillKind(i);
    s.x := i;
  end;
  if ACase.Prefill >= 3 then
    RF_RemoveSprite(@scaleobjlist[ACase.Prefill div 2]);
  bloodcount := ACase.BloodCount;
  metalcount := ACase.MetalCount;
  rndofs := ACase.RandomOffset;
end;

function SpriteRow(const s: Pscaleobj_t): TSpawnRow;
begin
  Result := TSpawnRow.Create(
    (NativeInt(s) - NativeInt(@scaleobjlist[0])) div SizeOf(scaleobj_t),
    s.animation, s.animationTime, s.moveSpeed, s.zadj, s.x, s.y, s.z, s.lastx, s.lasty, s.basepic, Ord(s.rotate),
    s.angle, s.angle2, s.movesize, Ord(s.active), Ord(s.nofalling), s.intelligence, s.bullet, s.enraged,
    s.movetime, s.modetime, s.actiontime, s.scantime, s.firetime, s.heat, s.startpic, s.movemode, s.startspot,
    s.damage, s.hitpoints, s.typ, s.spawnid, s.score, s.maxmove, s.regen, s.deathevent, s.height,
    Ord(s.specialtype), s.scale, s.oldx, s.oldy, s.oldz, s.oldangle, s.oldangle2, s.oldfloorz, s.newx, s.newy,
    s.newz, s.newangle, s.newangle2, s.newfloorz, Ord(s.grounded));
end;

function Snapshot(const ACase: TSpawnCase; const AReturned: Pscaleobj_t; AFailed: boolean): TSpawnSnapshot;
var
  s: Pscaleobj_t;
  e: Pelevobj_t;
  d: Pdoorobj_t;
  a: Pspawnarea_t;
  i, n: integer;
  tiles: TSpawnTiles;
begin
  Result := Default(TSpawnSnapshot);
  Result.Failed := AFailed;
  if AReturned = nil then
    Result.Returned := -1
  else
    Result.Returned := (NativeInt(AReturned) - NativeInt(@scaleobjlist[0])) div SizeOf(scaleobj_t);
  s := firstscaleobj.next;
  while s <> @lastscaleobj do
  begin
    n := Length(Result.Sprites);
    SetLength(Result.Sprites, n + 1);
    Result.Sprites[n] := SpriteRow(s);
    s := s.next;
  end;
  e := firstelevobj.next;
  while e <> @lastelevobj do
  begin
    n := Length(Result.Elevators);
    SetLength(Result.Elevators, n + 1);
    Result.Elevators[n] := TSpawnRow.Create(
      (NativeInt(e) - NativeInt(@elevlist[0])) div SizeOf(elevobj_t),
      Ord(e.elevUp), Ord(e.elevDown), e.position, e.position64, e.elevTimer, e.floor, e.ceiling, e.mapspot,
      e.speed, e.eval, e.endeval, e.nosave, Ord(e.typ));
    e := e.next;
  end;
  SetLength(Result.Doors, numdoors);
  for i := 0 to numdoors - 1 do
  begin
    d := @doorlist[i];
    Result.Doors[i] := TSpawnRow.Create(d.tilex, d.tiley, Ord(d.doorOpen), Ord(d.doorOpening), Ord(d.doorClosing),
      Ord(d.doorBlocked), Ord(d.doorBumpable), d.doorSize, d.doorTimer, d.doorLocks, Ord(d.orientation),
      Ord(d.transparent), d.pic, d.height, d.position);
  end;
  SetLength(Result.Areas, numspawnareas);
  for i := 0 to numspawnareas - 1 do
  begin
    a := @spawnareas[i];
    Result.Areas[i] := TSpawnRow.Create(a.mapspot, a.mapx, a.mapy, a.typ, a.time);
  end;
  Move(floorheight, tiles, SPAWN_TILES);
  Result.FloorHeightHash := TSpawnScenarios.HashTiles(tiles);
  Move(mapsprites, tiles, SPAWN_TILES);
  Result.MapSpritesHash := TSpawnScenarios.HashTiles(tiles);
  Move(mapflags, tiles, SPAWN_TILES);
  Result.MapFlagsHash := TSpawnScenarios.HashTiles(tiles);
  Result.RandomUsed := rndofs - ACase.RandomOffset;
  Result.Calls := Copy(Demands);
  for i := 0 to numsoundcalls - 1 do
  begin
    n := Length(Result.Calls);
    SetLength(Result.Calls, n + 1);
    Result.Calls[n] := TSpawnRow.Create(SPAWN_CALL_SOUND, soundcalls[i].n, soundcalls[i].variation,
      soundcalls[i].x, soundcalls[i].y);
  end;
  SetLength(Result.Globals, 27);
  Result.Globals[0] := player.x;
  Result.Globals[1] := player.y;
  Result.Globals[2] := player.z;
  Result.Globals[3] := player.mapspot;
  Result.Globals[4] := player.angle;
  Result.Globals[5] := player_angle64;
  for i := 0 to MAXSTARTLOCATIONS - 1 do
  begin
    Result.Globals[6 + i * 2] := startlocations[i][0];
    Result.Globals[7 + i * 2] := startlocations[i][1];
  end;
  Result.Globals[22] := Ord(exitexists);
  Result.Globals[23] := exitx;
  Result.Globals[24] := exity;
  Result.Globals[25] := bloodcount;
  Result.Globals[26] := metalcount;
end;

var
  LGolden, LFull: TStringList;
  LCase: TSpawnCase;
  LSnapshot: TSpawnSnapshot;
  LReturned: Pscaleobj_t;
  LFailed: boolean;
  i, j, LFailures, LSprites, LSequenceFailures: integer;
begin
  try
    if ParamCount < 1 then
      raise Exception.Create('SpawnGolden <golden file> [<file of the full descriptions>]');
    for i := 1 to 6 do
      TSpawnScenarios.BuildMap(i, Maps[i]);
    for i := 0 to S_END - S_START do
      slumps[i] := CA_GetNamedNum(slumpnames[i]);
    walllump := CA_GetNamedNum('startwalls');
    LFailures := 0;
    LSprites := 0;
    LGolden := TStringList.Create;
    LFull := TStringList.Create;
    try
      LGolden.Add('# SpawnSprite of spawn.pas of xGreed (Tools\Verifica\175-spawn): case value failed returned sprites random fingerprint');
      for i := 0 to TSpawnScenarios.CaseCount - 1 do
      begin
        LCase := TSpawnScenarios.CaseAt(i);
        Prepare(LCase);
        LReturned := nil;
        LFailed := false;
        try
          LReturned := SpawnSprite(LCase.Value, LCase.X, LCase.Y, LCase.Z, LCase.ZAdjust, LCase.Angle, LCase.Angle2,
            LCase.Active, LCase.SpawnId);
        except
          on E: Exception do
          begin
            LFailed := true;
            inc(LFailures);
          end;
        end;
        CollectDemand;
        if LReturned <> nil then
          inc(LSprites);
        LSnapshot := Snapshot(LCase, LReturned, LFailed);
        LGolden.Add(TSpawnScenarios.GoldenLine(LCase, LSnapshot));
        if ParamCount >= 2 then
        begin
          LFull.Add('== ' + IntToStr(i) + ' value ' + IntToStr(LCase.Value));
          LFull.Add(TSpawnScenarios.Describe(LSnapshot));
        end;
      end;
      LGolden.Add('# sequences of calls in one world: S sequence failures sprites elevators doors areas random fingerprint');
      for i := 0 to SPAWN_SEQUENCES - 1 do
      begin
        Prepare(TSpawnScenarios.SequenceStart(i));
        LReturned := nil;
        LSequenceFailures := 0;
        for j := 0 to SPAWN_SEQUENCE_STEPS - 1 do
        begin
          LCase := TSpawnScenarios.SequenceStep(i, j);
          LReturned := nil;
          try
            LReturned := SpawnSprite(LCase.Value, LCase.X, LCase.Y, LCase.Z, LCase.ZAdjust, LCase.Angle,
              LCase.Angle2, LCase.Active, LCase.SpawnId);
          except
            on E: Exception do
              inc(LSequenceFailures);
          end;
          CollectDemand;
        end;
        LSnapshot := Snapshot(TSpawnScenarios.SequenceStart(i), LReturned, LSequenceFailures > 0);
        LGolden.Add(TSpawnScenarios.SequenceLine(i, LSequenceFailures, LSnapshot));
        if ParamCount >= 2 then
        begin
          LFull.Add('== sequence ' + IntToStr(i));
          LFull.Add(TSpawnScenarios.Describe(LSnapshot));
        end;
      end;
      LGolden.SaveToFile(ParamStr(1));
      if ParamCount >= 2 then
        LFull.SaveToFile(ParamStr(2));
      Writeln(Format('%d cases, %d returned a sprite, %d stopped with MS_Error; %d sequences of %d calls',
        [TSpawnScenarios.CaseCount, LSprites, LFailures, SPAWN_SEQUENCES, SPAWN_SEQUENCE_STEPS]));
    finally
      LFull.Free;
      LGolden.Free;
    end;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
