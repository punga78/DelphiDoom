program EventsGolden;
// Issue #175: runs event.pas of xGreed AS IT IS (Reference\xGreed, read only; scriptengine.pas with the 8 bit strings
// it had in Delphi 7) on the scenarios of Tests\Source\DelphiDoom.Tests.Greed.EventScenarios and writes one line for
// each case: the golden file that the test of TGreedEvents compares with the library. With the folder of the
// complete game it also loads the script of each of its maps and runs every event. See Compila.ps1.
// Use: EventsGolden <golden file> [<golden file of the complete game> <folder of GREED.BLO>]
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
  raven,
  r_conten,
  r_render,
  r_public,
  utils,
  spawn,
  event,
  calllog,
  DelphiDoom.Greed.Intf,
  DelphiDoom.Greed.Factory,
  DelphiDoom.Tests.Greed.EventScenarios;

var
  Maps: array[1..4] of TEventMap;
  CurrentScript: TBytes;
  Archive: IGreedArchive;
  LoadFailures: integer = 0;
  StepFailures: integer = 0;

function BytesToText(const ABytes: TBytes): AnsiString;
begin
  SetLength(Result, Length(ABytes));
  if Length(ABytes) > 0 then
    Move(ABytes[0], Result[1], Length(ABytes));
end;

function ScenarioNumber(const name: string): integer;
begin
  Result := TEventScenarios.LumpNumber(name);
end;

function ScenarioText(const lump: integer): AnsiString;
begin
  Calls.AddCall(EVENT_CALL_SCRIPT, [lump]);
  Result := BytesToText(CurrentScript);
end;

function ArchiveNumber(const name: string): integer;
begin
  Result := Archive.IndexOf(name);
end;

function ArchiveText(const lump: integer): AnsiString;
begin
  Result := BytesToText(Archive.ReadLumpRaw(lump));
end;

procedure Feed(var h: TEventHash; const full, sky: boolean);
var
  i: integer;
  s: Pscaleobj_t;
  e: Pelevobj_t;
begin
  h.Add(numzones);
  h.Add(numprocesses);
  h.Add(fliplayed);
  for i := 0 to MAXPROCESS - 1 do
    h.Add(processes[i]);
  for i := 0 to numzones - 1 do
  begin
    h.Add(zones[i].x1);
    h.Add(zones[i].y1);
    h.Add(zones[i].x2);
    h.Add(zones[i].y2);
    h.Add(zones[i].eval);
    h.Add(zones[i].endeval);
    h.Add(zones[i].rate);
    h.Add(zones[i].layer);
    h.Add(zones[i].newvalue);
    h.Add(zones[i].stype);
    h.Add(zones[i].removeable);
    h.Add(zones[i].typ);
  end;
  s := firstscaleobj.next;
  while s <> @lastscaleobj do
  begin
    h.Add((NativeInt(s) - NativeInt(@scaleobjlist[0])) div SizeOf(scaleobj_t));
    h.Add(s.typ);
    h.Add(s.x);
    h.Add(s.y);
    h.Add(s.z);
    h.Add(s.moveSpeed);
    h.AddBoolean(s.active);
    h.Add(s.actiontime);
    h.Add(s.deathevent);
    s := s.next;
  end;
  h.Add(-1);
  e := firstelevobj.next;
  while e <> @lastelevobj do
  begin
    h.Add((NativeInt(e) - NativeInt(@elevlist[0])) div SizeOf(elevobj_t));
    h.AddBoolean(e.elevUp);
    h.AddBoolean(e.elevDown);
    h.Add(e.position);
    h.Add(e.position64);
    h.Add(e.elevTimer);
    h.Add(e.floor);
    h.Add(e.ceiling);
    h.Add(e.mapspot);
    h.Add(e.speed);
    h.Add(e.eval);
    h.Add(e.endeval);
    h.Add(e.nosave);
    h.Add(Ord(e.typ));
    e := e.next;
  end;
  h.Add(-1);
  h.Add(player.x);
  h.Add(player.y);
  h.Add(player.z);
  h.Add(player.angst);
  h.Add(player.levelscore);
  h.Add(fallrate);
  h.AddBoolean(gameloading);
  h.AddBoolean(eventloading);
  for i := 0 to 3 do
    h.Add(primaries[i]);
  for i := 0 to 13 do
    h.Add(secondaries[i]);
  for i := 0 to 1 do
    h.Add(pcount[i]);
  for i := 0 to 6 do
    h.Add(scount[i]);
  h.Add(bonustime);
  h.Add(levelscore);
  h.Add(Integer(Calls.Value));
  h.Add(Calls.Count);
  if full then
  begin
    h.AddBytes(triggers, EVENT_TILES);
    h.AddBytes(switches, EVENT_TILES);
    h.AddBytes(player.events, 256);
    h.AddBytes(northwall, EVENT_TILES);
    h.AddBytes(westwall, EVENT_TILES);
    h.AddBytes(floorpic, EVENT_TILES);
    h.AddBytes(ceilingpic, EVENT_TILES);
    h.AddBytes(floorheight, EVENT_TILES);
    h.AddBytes(ceilingheight, EVENT_TILES);
    h.AddBytes(maplights, EVENT_TILES);
    h.AddBytes(mapeffects, EVENT_TILES);
    h.AddBytes(mapsprites, EVENT_TILES);
  end;
  if sky then
    h.AddBytes(backdrop, SizeOf(backdrop));
end;

// what LoadScript must clear is dirty before it
procedure Dirty;
var
  i: integer;
begin
  FillChar(triggers, SizeOf(triggers), EVENT_DIRTY_TRIGGER);
  FillChar(switches, SizeOf(switches), EVENT_DIRTY_SWITCH);
  FillChar(zones, SizeOf(zones), EVENT_DIRTY_ZONE_BYTE);
  for i := 0 to MAXPROCESS - 1 do
    processes[i] := EVENT_DIRTY_PROCESS;
  numzones := EVENT_DIRTY_COUNT;
  numprocesses := EVENT_DIRTY_COUNT;
  fliplayed := EVENT_DIRTY_COUNT;
  bonustime := EVENT_DIRTY_COUNT;
  levelscore := EVENT_DIRTY_COUNT;
  for i := 0 to 3 do
    primaries[i] := EVENT_DIRTY_COUNT;
  for i := 0 to 13 do
    secondaries[i] := EVENT_DIRTY_COUNT;
  for i := 0 to 1 do
    pcount[i] := EVENT_DIRTY_COUNT;
  for i := 0 to 6 do
    scount[i] := EVENT_DIRTY_COUNT;
  fallrate := EVENT_DIRTY_COUNT;
end;

procedure Prepare(const ACase: TEventCase);
var
  i: integer;
  s: Pscaleobj_t;
  e: Pelevobj_t;
begin
  RF_ClearWorld;
  Move(Maps[ACase.MapSeed].NorthWall, northwall, EVENT_TILES);
  Move(Maps[ACase.MapSeed].WestWall, westwall, EVENT_TILES);
  Move(Maps[ACase.MapSeed].FloorPic, floorpic, EVENT_TILES);
  Move(Maps[ACase.MapSeed].CeilingPic, ceilingpic, EVENT_TILES);
  Move(Maps[ACase.MapSeed].FloorHeight, floorheight, EVENT_TILES);
  Move(Maps[ACase.MapSeed].CeilingHeight, ceilingheight, EVENT_TILES);
  Move(Maps[ACase.MapSeed].MapLights, maplights, EVENT_TILES);
  Move(Maps[ACase.MapSeed].MapEffects, mapeffects, EVENT_TILES);
  Move(Maps[ACase.MapSeed].MapSprites, mapsprites, EVENT_TILES);
  Move(Maps[ACase.MapSeed].MapFlags, mapflags, EVENT_TILES);
  FillChar(player, SizeOf(player), 0);
  player.x := ACase.PlayerX;
  player.y := ACase.PlayerY;
  player.height := ACase.PlayerHeight;
  player.timecount := ACase.PlayerTime;
  player.difficulty := ACase.Difficulty;
  player.angst := 100;
  Move(ACase.Events, player.events, 256);
  timecount := ACase.TimeCount;
  netmode := false;
  gameloading := false;
  eventloading := false;
  SC.vrhelmet := 0;
  Dirty;
  for i := 0 to ACase.SpriteCount - 1 do
  begin
    s := RF_GetSprite;
    s.x := ACase.Sprites[i].X;
    s.y := ACase.Sprites[i].Y;
    s.z := ACase.Sprites[i].Z;
    s.moveSpeed := ACase.Sprites[i].MoveSpeed;
    s.typ := ACase.Sprites[i].Kind;
    s.active := ACase.Sprites[i].Active;
  end;
  for i := 0 to ACase.ElevatorCount - 1 do
  begin
    e := RF_GetElevator;
    e.mapspot := ACase.Elevators[i].MapSpot;
    e.floor := ACase.Elevators[i].Floor;
    e.ceiling := ACase.Elevators[i].Ceiling;
    e.position := ACase.Elevators[i].Position;
    e.position64 := e.position * FRACUNIT;
    e.eval := ACase.Elevators[i].Eval;
    e.typ := E_NORMAL;
  end;
  CurrentScript := ACase.Script;
  Calls.Reset;
end;

function RunCase(const ACase: TEventCase): string;
var
  h: TEventHash;
  loadfailed, stepfailed: boolean;
  loadhash: Cardinal;
  t, steps, ev: integer;
begin
  Prepare(ACase);
  loadfailed := false;
  try
    LoadScript(EVENT_LUMP_MAP + ACase.Map + 1, ACase.NewGame);
  except
    on E: Exception do
    begin
      loadfailed := true;
      if FindCmdLineSwitch('errors') then
        Writeln('case ', ACase.Index, ': ', E.ClassName, ' ', E.Message);
    end;
  end;
  h.Reset;
  Feed(h, true, not loadfailed);
  loadhash := h.Value;
  steps := 0;
  stepfailed := false;
  if not loadfailed then
  begin
    eventloading := ACase.EventLoading;
    for t := 0 to EVENT_STEPS - 1 do
    begin
      inc(timecount);
      try
        ev := TEventScenarios.StepEvent(ACase.Index, t);
        if ev >= 0 then
          RunEvent(ev, false);
        if numprocesses > 0 then
          Process;
      except
        on E: Exception do
          stepfailed := true;
      end;
      Feed(h, (t mod EVENT_FULL_EVERY = 0) or stepfailed, false);
      inc(steps);
      if stepfailed then
        break;
    end;
  end;
  Feed(h, true, false);
  if loadfailed then
    inc(LoadFailures);
  if stepfailed then
    inc(StepFailures);
  Result := TEventScenarios.GoldenLine(ACase, loadfailed, numzones, numprocesses, steps, stepfailed, loadhash,
    h.Value);
end;

// the script of a map of the complete game on an empty world, then every event with some steps of its processes
function RunFull(const AMap, AVariant: integer): string;
var
  h: TEventHash;
  newgame, done, loadfailed, runfailed: boolean;
  difficulty, ev, k, events: integer;
  loadhash: Cardinal;
begin
  TEventScenarios.FullVariant(AVariant, newgame, difficulty, done);
  RF_ClearWorld;
  FillChar(northwall, EVENT_TILES, 0);
  FillChar(westwall, EVENT_TILES, 0);
  FillChar(floorpic, EVENT_TILES, 0);
  FillChar(ceilingpic, EVENT_TILES, 0);
  FillChar(floorheight, EVENT_TILES, 0);
  FillChar(ceilingheight, EVENT_TILES, 0);
  FillChar(maplights, EVENT_TILES, 0);
  FillChar(mapeffects, EVENT_TILES, 0);
  FillChar(mapsprites, EVENT_TILES, 0);
  // the map 10 has "sprite 6 81 86": a row past the map, that the original writes in the plane that follows the
  // one of the sprites. It is the plane of the slopes (not read after the script, not in the fingerprint): it is
  // used here so that the linker keeps it where the original has it
  FillChar(mapslopes, EVENT_TILES, 0);
  FillChar(mapflags, EVENT_TILES, 0);
  FillChar(player, SizeOf(player), 0);
  player.x := (5 shl 22) + (32 shl 16);
  player.y := (5 shl 22) + (32 shl 16);
  player.height := 40 shl 16;
  player.difficulty := difficulty;
  player.angst := 100;
  if done then
    FillChar(player.events, 256, 1);
  timecount := 1000;
  netmode := false;
  gameloading := false;
  eventloading := false;
  SC.vrhelmet := 0;
  Dirty;
  Calls.Reset;
  loadfailed := false;
  try
    LoadScript(CA_GetNamedNum('map') + AMap + 1, newgame);
  except
    on E: Exception do
    begin
      loadfailed := true;
      Writeln('map ', AMap, ' variant ', AVariant, ': ', E.Message);
    end;
  end;
  h.Reset;
  Feed(h, true, not loadfailed);
  loadhash := h.Value;
  runfailed := false;
  events := 0;
  if not loadfailed then
    for ev := 1 to 255 do
    begin
      inc(timecount);
      try
        RunEvent(ev, false);
        k := 0;
        while (numprocesses > 0) and (k < EVENT_FULL_PROCESS_STEPS) do
        begin
          Process;
          inc(k);
        end;
      except
        on E: Exception do
        begin
          runfailed := true;
          Writeln('map ', AMap, ' variant ', AVariant, ' event ', ev, ': ', E.Message);
        end;
      end;
      Feed(h, runfailed, false);
      inc(events);
      if runfailed then
        break;
    end;
  Feed(h, true, false);
  Result := TEventScenarios.FullLine(AMap, AVariant, loadfailed, numzones, numprocesses, events, runfailed,
    loadhash, h.Value);
end;

procedure OpenSkyFile(const AFolder: string);
var
  LStream: TFileStream;
  LBytes: TBytes;
  i: integer;
  LName: string;
begin
  LName := AFolder + 'sky.bin';
  LStream := TFileStream.Create(LName, fmCreate);
  try
    for i := EVENT_LUMP_FIRST_SKY to EVENT_LUMP_LAST_SKY do
    begin
      infotable[i].filepos := LStream.Position;
      infotable[i].size := EVENT_SKY_LUMP_BYTES;
      LBytes := TEventScenarios.SkyLump(i);
      LStream.WriteBuffer(LBytes[0], Length(LBytes));
    end;
  finally
    LStream.Free;
  end;
  FileMode := 0;
  AssignFile(cachehandle, LName);
  Reset(cachehandle, 1);
end;

procedure OpenArchive(const AFolder: string);
var
  i: integer;
begin
  Archive := TGreedFactory.OpenArchiveFile(IncludeTrailingPathDelimiter(AFolder) + 'GREED.BLO');
  for i := 0 to Archive.LumpCount - 1 do
  begin
    infotable[i].filepos := Archive.GetLumpInfo(i).FilePosition;
    infotable[i].size := Archive.GetLumpInfo(i).Size;
  end;
  FileMode := 0;
  AssignFile(cachehandle, IncludeTrailingPathDelimiter(AFolder) + 'GREED.BLO');
  Reset(cachehandle, 1);
end;

var
  LGolden: TStringList;
  i, j: integer;
begin
  try
    if ParamCount < 1 then
      raise Exception.Create('EventsGolden <golden file> [<golden file of the complete game> <folder of GREED.BLO>]');
    for i := 1 to 4 do
      TEventScenarios.BuildMap(i, Maps[i]);
    DiskNumber := ScenarioNumber;
    DiskText := ScenarioText;
    OpenSkyFile(ExtractFilePath(ParamStr(0)));
    LGolden := TStringList.Create;
    try
      LGolden.Add('# event.pas of xGreed (Tools\Verifica\175-events): E case loadfailed zones processes steps stepfailed fingerprint-after-load fingerprint');
      for i := 0 to EVENT_CASES - 1 do
        LGolden.Add(RunCase(TEventScenarios.CaseAt(i)));
      LGolden.SaveToFile(ParamStr(1));
      Writeln(Format('%d cases of %d tics: %d scripts stopped with MS_Error, %d stopped while running',
        [EVENT_CASES, EVENT_STEPS, LoadFailures, StepFailures]));
      CloseFile(cachehandle);
      if ParamCount >= 3 then
      begin
        DiskNumber := ArchiveNumber;
        DiskText := ArchiveText;
        OpenArchive(ParamStr(3));
        LGolden.Clear;
        LGolden.Add('# event.pas of xGreed on the scripts of the complete game: F map variant loadfailed zones processes events runfailed fingerprint-after-load fingerprint');
        for i := 0 to EVENT_FULL_MAPS - 1 do
          for j := 0 to EVENT_FULL_VARIANTS - 1 do
            LGolden.Add(RunFull(i, j));
        LGolden.SaveToFile(ParamStr(2));
        Writeln(Format('%d maps of the complete game, %d ways each', [EVENT_FULL_MAPS, EVENT_FULL_VARIANTS]));
        CloseFile(cachehandle);
      end;
    finally
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
