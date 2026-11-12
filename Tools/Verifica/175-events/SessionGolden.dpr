program SessionGolden;
// Issue #175: runs newmap, LoadNewMap, ActivateSpritesFromMap, resetengine, respawnplayer, SaveGame and LoadGame of
// utils.pas of xGreed AS THEY ARE (cut out of Reference\xGreed, read only, by Compila.ps1), with event.pas as it is,
// on the scenarios of Tests\Source\DelphiDoom.Tests.Greed.SessionScenarios and writes one line for each case: the
// golden file that the test of TGreedMapSession compares with the library.
// Use: SessionGolden <golden file>      (the saved games are written in the folder of the program)
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
  d_font,
  i_windows,
  modplay,
  raven,
  r_conten,
  r_render,
  r_public,
  utils,
  spawn,
  event,
  calllog,
  DelphiDoom.Tests.Greed.EventScenarios,
  DelphiDoom.Tests.Greed.SessionScenarios;

var
  CurrentScript: TBytes;
  InitialWeapons: array of byte;

function ScenarioNumber(const name: string): integer;
begin
  Result := TSessionScenarios.LumpNumber(name);
end;

function ScenarioText(const lump: integer): AnsiString;
begin
  Calls.AddCall(EVENT_CALL_SCRIPT, [lump]);
  SetLength(Result, Length(CurrentScript));
  if Length(CurrentScript) > 0 then
    Move(CurrentScript[0], Result[1], Length(CurrentScript));
end;

procedure Feed(var h: TEventHash);
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
    h.Add(s.hitpoints);
    h.AddBoolean(s.nofalling);
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
  h.Mark('zones, sprites and elevators');
  h.Add(numdoors);
  for i := 0 to numdoors - 1 do
  begin
    h.Add(doorlist[i].tilex);
    h.Add(doorlist[i].tiley);
    h.Add(doorlist[i].pic);
    h.Add(Ord(doorlist[i].orientation));
  end;
  h.Add(numspawnareas);
  for i := 0 to numspawnareas - 1 do
  begin
    h.Add(spawnareas[i].mapspot);
    h.Add(spawnareas[i].typ);
  end;
  h.Mark('doors and areas');
  h.AddBytes(player, SizeOf(player));
  h.Mark('player');
  h.Add(player_angle64);
  h.Add(turnrate);
  h.Add(moverate);
  h.Add(fallrate);
  h.Add(strafrate);
  h.AddBoolean(exitexists);
  h.Add(BonusItem.time);
  h.Add(BonusItem.score);
  h.Add(timecount);
  h.Add(frames);
  h.Add(weapdelay);
  h.Add(secretdelay);
  h.Add(inventorydelay);
  h.Add(usedelay);
  h.Add(jumpdelay);
  h.Add(keyboardDelay);
  h.Add(spritemovetime);
  h.Add(wallanimationtime);
  h.Add(timemsg);
  h.Add(RearViewTime);
  h.Add(RearViewDelay);
  h.Add(SwitchTime);
  h.Add(inventorytime);
  h.AddBoolean(midgetmode);
  h.Add(fxtimecount);
  h.Add(Length(secretbuf));
  h.Add(goalitem);
  h.Add(oldgoalitem);
  h.AddBoolean(togglegoalitem);
  h.AddBoolean(gameloaded);
  h.AddBoolean(gameloading);
  h.AddBoolean(eventloading);
  h.Mark('globals');
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
  h.Mark('goals');
  for i := 0 to S_END - S_START do
    h.Add(slumps[i]);
  for i := 0 to 18 do
  begin
    h.Add(weapons[i].charge);
    h.Add(weapons[i].chargetime);
  end;
  h.Mark('lumps and weapons');
  h.Add(rndofs);
  for i := 0 to MAXSTARTLOCATIONS - 1 do
  begin
    h.Add(startlocations[i][0]);
    h.Add(startlocations[i][1]);
  end;
  h.Mark('random and starts');
  h.Add(Integer(Calls.Value));
  h.Add(Calls.Count);
  h.Mark('calls');
  h.AddBytes(triggers, EVENT_TILES);
  h.AddBytes(switches, EVENT_TILES);
  h.Mark('triggers and switches');
  // the planes in the order of the file of a map
  h.AddBytes(northwall, EVENT_TILES);
  h.AddBytes(northflags, EVENT_TILES);
  h.AddBytes(westwall, EVENT_TILES);
  h.AddBytes(westflags, EVENT_TILES);
  h.AddBytes(floorpic, EVENT_TILES);
  h.AddBytes(floorflags, EVENT_TILES);
  h.AddBytes(ceilingpic, EVENT_TILES);
  h.AddBytes(ceilingflags, EVENT_TILES);
  h.AddBytes(floorheight, EVENT_TILES);
  h.AddBytes(ceilingheight, EVENT_TILES);
  h.AddBytes(floordef, EVENT_TILES);
  h.AddBytes(floordefflags, EVENT_TILES);
  h.AddBytes(ceilingdef, EVENT_TILES);
  h.AddBytes(ceilingdefflags, EVENT_TILES);
  h.AddBytes(maplights, EVENT_TILES);
  h.AddBytes(mapeffects, EVENT_TILES);
  h.Mark('planes before the sprites');
  h.AddBytes(mapsprites, EVENT_TILES);
  h.Mark('mapsprites');
  h.AddBytes(mapslopes, EVENT_TILES);
  h.AddBytes(mapflags, EVENT_TILES);
  h.Mark('slopes and flags');
  h.AddBytes(backdrop, SizeOf(backdrop));
end;

procedure Prepare(const ACase: TSessionCase);
var
  i: integer;
begin
  RF_ClearWorld;
  FillChar(northwall, EVENT_TILES, 0);
  FillChar(northflags, EVENT_TILES, 0);
  FillChar(westwall, EVENT_TILES, 0);
  FillChar(westflags, EVENT_TILES, 0);
  FillChar(floorpic, EVENT_TILES, 0);
  FillChar(floorflags, EVENT_TILES, 0);
  FillChar(ceilingpic, EVENT_TILES, 0);
  FillChar(ceilingflags, EVENT_TILES, 0);
  FillChar(floorheight, EVENT_TILES, 0);
  FillChar(ceilingheight, EVENT_TILES, 0);
  FillChar(floordef, EVENT_TILES, 0);
  FillChar(floordefflags, EVENT_TILES, 0);
  FillChar(ceilingdef, EVENT_TILES, 0);
  FillChar(ceilingdefflags, EVENT_TILES, 0);
  FillChar(maplights, EVENT_TILES, 0);
  FillChar(mapeffects, EVENT_TILES, 0);
  FillChar(mapsprites, EVENT_TILES, 0);
  FillChar(mapslopes, EVENT_TILES, 0);
  FillChar(mapflags, EVENT_TILES, 0);
  FillChar(backdrop, SizeOf(backdrop), 0);
  FillChar(triggers, SizeOf(triggers), 0);
  FillChar(switches, SizeOf(switches), 0);
  FillChar(zones, SizeOf(zones), 0);
  FillChar(processes, SizeOf(processes), 0);
  numzones := 0;
  numprocesses := 0;
  fliplayed := 0;
  FillChar(primaries, SizeOf(primaries), 0);
  FillChar(secondaries, SizeOf(secondaries), 0);
  FillChar(pcount, SizeOf(pcount), 0);
  FillChar(scount, SizeOf(scount), 0);
  bonustime := 0;
  levelscore := 0;
  FillChar(slumps, SizeOf(slumps), 0);
  FillChar(startlocations, SizeOf(startlocations), 0);
  Move(InitialWeapons[0], weapons, SizeOf(weapons));
  for i := 0 to 18 do
    weapons[i].charge := 5;
  // what resetengine and LoadNewMap must set is dirty
  turnrate := SESSION_DIRTY;
  moverate := SESSION_DIRTY;
  fallrate := SESSION_DIRTY;
  strafrate := SESSION_DIRTY;
  exitexists := true;
  BonusItem.time := SESSION_DIRTY;
  BonusItem.score := SESSION_DIRTY;
  timecount := SESSION_DIRTY;
  frames := SESSION_DIRTY;
  weapdelay := SESSION_DIRTY;
  secretdelay := SESSION_DIRTY;
  inventorydelay := SESSION_DIRTY;
  usedelay := SESSION_DIRTY;
  jumpdelay := SESSION_DIRTY;
  keyboardDelay := SESSION_DIRTY;
  spritemovetime := SESSION_DIRTY;
  wallanimationtime := SESSION_DIRTY;
  timemsg := SESSION_DIRTY;
  RearViewTime := SESSION_DIRTY;
  RearViewDelay := SESSION_DIRTY;
  SwitchTime := SESSION_DIRTY;
  inventorytime := SESSION_DIRTY;
  midgetmode := true;
  fxtimecount := SESSION_DIRTY;
  secretbuf := 'abc';
  goalitem := SESSION_DIRTY;
  oldgoalitem := SESSION_DIRTY;
  togglegoalitem := false;
  gameloaded := false;
  gameloading := false;
  eventloading := false;
  netmode := false;
  SC.vrhelmet := 0;
  DEMO := ACase.Demo;
  GAME1 := ACase.Game1;
  GAME2 := ACase.Game2;
  GAME3 := ACase.Game3;
  FillChar(player, SizeOf(player), 0);
  player.x := 5 shl 22;
  player.y := 5 shl 22;
  player.height := ACase.PlayerHeight;
  player.difficulty := ACase.Difficulty;
  for i := 0 to 4 do
    player.weapons[i] := ACase.Weapons[i];
  player.currentweapon := ACase.CurrentWeapon;
  player.scrollmin := ACase.ScrollMin;
  player.scrollmax := ACase.ScrollMax;
  player.angst := 100;
  player.levelscore := 4242;
  player.timecount := 777;
  FillChar(player.westmap, SizeOf(player.westmap), 1);
  FillChar(player.northmap, SizeOf(player.northmap), 2);
  FillChar(player.events, SizeOf(player.events), 1);
  player_angle64 := 3;
  rndofs := ACase.RandomOffset;
  ClockValue := ACase.Clock;
  lowresolution := ACase.LowResolution;
  CurrentScript := ACase.Script;
  Calls.Reset;
end;

// what is on the map when the game is saved: every kind of sprite, door, spawn area and elevator
procedure Populate(const ACase: TSessionCase);
var
  i: integer;
  s: Pscaleobj_t;
  d: Pdoorobj_t;
  a: Pspawnarea_t;
  e: Pelevobj_t;
begin
  for i := 0 to ACase.SpriteCount - 1 do
  begin
    s := RF_GetSprite;
    s.typ := ACase.Sprites[i].Kind;
    s.x := ACase.Sprites[i].X;
    s.y := ACase.Sprites[i].Y;
    s.hitpoints := ACase.Sprites[i].HitPoints;
    s.deathevent := ACase.Sprites[i].DeathEvent;
    s.nofalling := ACase.Sprites[i].NoFalling;
  end;
  for i := 0 to ACase.DoorCount - 1 do
  begin
    d := RF_GetDoor(ACase.Doors[i].TileX, ACase.Doors[i].TileY);
    d.pic := ACase.Doors[i].Pic;
    d.orientation := orientation_t(ACase.Doors[i].Orientation);
  end;
  for i := 0 to ACase.AreaCount - 1 do
  begin
    a := RF_GetSpawnArea;
    a.mapspot := ACase.Areas[i].MapSpot;
    a.typ := ACase.Areas[i].Kind;
  end;
  for i := 0 to ACase.ElevatorCount - 1 do
  begin
    e := RF_GetElevator;
    e.typ := elevtype(ACase.Elevators[i].Kind);
    e.elevTimer := ACase.Elevators[i].Timer;
    e.mapspot := ACase.Elevators[i].MapSpot;
    e.position := ACase.Elevators[i].Position;
    e.floor := ACase.Elevators[i].Floor;
    e.ceiling := ACase.Elevators[i].Ceiling;
    e.nosave := ACase.Elevators[i].NoSave;
    e.elevUp := ACase.Elevators[i].Up;
    e.elevDown := ACase.Elevators[i].Down;
  end;
  Move(ACase.Events, player.events, 256);
  for i := 0 to MAXSTARTLOCATIONS - 1 do
  begin
    startlocations[i][0] := ACase.StartLocations[i][0];
    startlocations[i][1] := ACase.StartLocations[i][1];
  end;
  mapsprites[ACase.StartLocations[ACase.FreeStart][1] * 64 + ACase.StartLocations[ACase.FreeStart][0]] := 0;
end;

function CountSprites: integer;
var
  s: Pscaleobj_t;
begin
  Result := 0;
  s := firstscaleobj.next;
  while s <> @lastscaleobj do
  begin
    inc(Result);
    s := s.next;
  end;
end;

function CountElevators: integer;
var
  e: Pelevobj_t;
begin
  Result := 0;
  e := firstelevobj.next;
  while e <> @lastelevobj do
  begin
    inc(Result);
    e := e.next;
  end;
end;

var
  Failures: integer = 0;

function RunCase(const ACase: TSessionCase): string;
var
  h: TEventHash;
  failed: array[0..3] of boolean;
  hashes: array[0..3] of Cardinal;
  step: integer;
begin
  Prepare(ACase);
  h.Reset;
  for step := 0 to 3 do
  begin
    failed[step] := false;
    try
      case step of
        0:
          newmap(ACase.Map, ACase.Activate);
        1:
          begin
            Populate(ACase);
            respawnplayer;
          end;
        2:
          SaveGame(ACase.SaveNumber);
        3:
          begin
            timecount := 999;
            LoadGame(ACase.SaveNumber);
          end;
      end;
    except
      on E: Exception do
      begin
        failed[step] := true;
        inc(Failures);
        Writeln('case ', ACase.Index, ' step ', step, ': ', E.ClassName, ' ', E.Message);
      end;
    end;
    Feed(h);
    hashes[step] := h.Value;
  end;
  Result := TSessionScenarios.GoldenLine(ACase, failed[0], failed[1], failed[2], failed[3], CountSprites,
    CountElevators, hashes[0], hashes[1], hashes[2], hashes[3]);
end;

procedure OpenDataFile(const AFolder: string);
var
  LStream: TFileStream;
  LBytes: TBytes;
  i, LFirstMap: integer;
  LName: string;
begin
  LName := AFolder + 'session.bin';
  LStream := TFileStream.Create(LName, fmCreate);
  try
    for i := EVENT_LUMP_FIRST_SKY to EVENT_LUMP_LAST_SKY do
    begin
      infotable[i].filepos := LStream.Position;
      infotable[i].size := EVENT_SKY_LUMP_BYTES;
      LBytes := TEventScenarios.SkyLump(i);
      LStream.WriteBuffer(LBytes[0], Length(LBytes));
    end;
    LFirstMap := LStream.Position;
    for i := 1 to SESSION_MAP_SEEDS do
    begin
      LBytes := TSessionScenarios.MapBytes(i);
      LStream.WriteBuffer(LBytes[0], Length(LBytes));
    end;
    // the lump of the map m is the lump "map" + m + 1
    for i := 0 to 31 do
    begin
      infotable[EVENT_LUMP_MAP + 1 + i].filepos := LFirstMap + (TSessionScenarios.SeedOfMap(i) - 1) * SESSION_MAP_BYTES;
      infotable[EVENT_LUMP_MAP + 1 + i].size := SESSION_MAP_BYTES;
    end;
  finally
    LStream.Free;
  end;
  FileMode := 0;
  AssignFile(cachehandle, LName);
  Reset(cachehandle, 1);
end;

var
  LGolden: TStringList;
  i: integer;
begin
  try
    if ParamCount < 1 then
      raise Exception.Create('SessionGolden <golden file>');
    SetCurrentDir(ExtractFilePath(ParamStr(0)));
    SetLength(InitialWeapons, SizeOf(weapons));
    Move(weapons, InitialWeapons[0], SizeOf(weapons));
    DiskNumber := ScenarioNumber;
    DiskText := ScenarioText;
    walllump := CA_GetNamedNum('startwalls');
    OpenDataFile(ExtractFilePath(ParamStr(0)));
    LGolden := TStringList.Create;
    try
      LGolden.Add('# utils.pas of xGreed (Tools\Verifica\175-events, SessionGolden): S case map activate newmapfailed respawnfailed savefailed loadfailed sprites elevators fingerprint-after-newmap -respawn -save -load');
      // with a case number and a file: only that case, with the fingerprint after each part of the state
      if ParamCount >= 3 then
      begin
        EventHashTrace := TStringList.Create;
        RunCase(TSessionScenarios.CaseAt(StrToInt(ParamStr(2))));
        EventHashTrace.SaveToFile(ParamStr(3));
        Halt(0);
      end;
      for i := 0 to SESSION_CASES - 1 do
        LGolden.Add(RunCase(TSessionScenarios.CaseAt(i)));
      LGolden.SaveToFile(ParamStr(1));
      Writeln(Format('%d cases (new map, respawn, save, load): %d steps stopped with an error',
        [SESSION_CASES, Failures]));
    finally
      LGolden.Free;
    end;
    CloseFile(cachehandle);
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
