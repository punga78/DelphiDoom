unit harness_world;
// harness of the parity of the whole world (issue #175): what the stubs and the PlayLoop of the original call.
// - HarnessNextFrame is the head of the loop of PlayLoop ("while not quitgame" becomes "while HarnessNextFrame"):
//   it writes the fingerprint of the world after the turn that has just ended, then runs the tics of the timer
//   (INT_TimerISR) that come before the next turn, or says that the game is over
// - HarnessReadKeys gives the keys of the generated commands to INT_ReadControls
// - HarnessSound and HarnessSong record what the game asks of the sound
// The fingerprint is made by the same unit that the tests of the library use (DelphiDoom.Tests.Greed.WorldPrint):
// the globals of the original are copied in the records of the library
interface
uses
  SysUtils, Classes, d_ints_h, r_public_h;
type
  THarnessKeys = array[0..NUMCODES - 1] of boolean;
var
  // the plan of the game: how many turns, how many tics before each turn, a line every that many turns
  HarnessFrames: integer = 0;
  HarnessTicsPerFrame: integer = 2;
  HarnessEvery: integer = 35;
  // the turn whose values are all written (-1 for none), and where
  HarnessDumpFrame: integer = -1;
  HarnessDumpFile: string = '';
  // every turn gets its line
  HarnessAllFrames: boolean = false;
  HarnessOutput: TStringList;
  HarnessMap: integer = 0;
  HarnessSeed: integer = 0;
procedure HarnessStart(const seed: LongWord);
function HarnessNextFrame: boolean;
procedure HarnessReadKeys(var pressed: THarnessKeys);
procedure HarnessSound(const n, variation, x, y: integer);
procedure HarnessSong(const name: string);
procedure HarnessTraceNote(const where: string);
implementation
uses
  g_delphi, constant, d_ints, d_misc, display, event, i_windows, protos_h, raven, r_conten, r_public, r_render,
  utils,
  DelphiDoom.Greed.Types, DelphiDoom.Greed.SaveTypes, DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.World.Intf,
  DelphiDoom.Greed.Game.State, DelphiDoom.Tests.Greed.WorldCommands, DelphiDoom.Tests.Greed.WorldPrint;

var
  Print: TWorldPrint;
  Commands: TWorldCommands;
  Frame: integer = 0;
  TotalTics: integer = 0;
  History: LongWord = 2166136261;
  ClockBase: LongWord = 0;
  LastPrinted: integer = -1;

procedure HarnessStart(const seed: LongWord);
begin
  Print := TWorldPrint.Create;
  Commands := TWorldCommands.Create(seed);
  ClockBase := seed * 1000;
  HarnessClock := ClockBase;
end;

procedure HarnessReadKeys(var pressed: THarnessKeys);
var
  keys: TWorldKeys;
begin
  FillChar(pressed, SizeOf(pressed), 0);
  keys := Commands.Next;
  pressed[SC_UPARROW] := wkNorth in keys;
  pressed[SC_DOWNARROW] := wkSouth in keys;
  pressed[SC_RIGHTARROW] := wkEast in keys;
  pressed[SC_LEFTARROW] := wkWest in keys;
  pressed[SC_CONTROL] := wkFire in keys;
  pressed[SC_SPACE] := wkSpace in keys;
  pressed[SC_LSHIFT] := wkShift in keys;
  pressed[SC_COMMA] := wkSlideLeft in keys;
  pressed[SC_PERIOD] := wkSlideRight in keys;
  pressed[SC_Z] := wkJump in keys;
  pressed[SC_X] := wkUseItem in keys;
  pressed[SC_INSERT] := wkInventoryLeft in keys;
  pressed[SC_DELETE] := wkInventoryRight in keys;
  pressed[SC_PGUP] := wkLookUp in keys;
  pressed[SC_PGDN] := wkLookDown in keys;
  pressed[SC_HOME] := wkCenterView in keys;
  pressed[SC_1] := wkWeapon1 in keys;
  pressed[SC_2] := wkWeapon2 in keys;
end;

procedure HarnessSound(const n, variation, x, y: integer);
begin
  if Assigned(Print) then
    Print.Sound(n, variation, x, y);
end;

procedure HarnessSong(const name: string);
begin
  if Assigned(Print) then
    Print.Song(name);
end;

function SpriteToLibrary(const s: scaleobj_t): TGreedSprite;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Animation := s.animation;
  Result.AnimationTime := s.animationTime;
  Result.MoveSpeed := s.moveSpeed;
  Result.ZAdjust := s.zadj;
  Result.X := s.x; Result.Y := s.y; Result.Z := s.z;
  Result.LastX := s.lastx; Result.LastY := s.lasty;
  Result.BasePic := s.basepic;
  Result.Rotate := TGreedRotate(Ord(s.rotate));
  Result.Angle := s.angle; Result.Angle2 := s.angle2;
  Result.MoveSize := s.movesize;
  Result.Active := s.active;
  Result.NoFalling := s.nofalling;
  Result.Intelligence := s.intelligence;
  Result.Bullet := s.bullet;
  Result.Enraged := s.enraged;
  Result.MoveTime := s.movetime;
  Result.ModeTime := s.modetime;
  Result.ActionTime := s.actiontime;
  Result.ScanTime := s.scantime;
  Result.FireTime := s.firetime;
  Result.Heat := s.heat;
  Result.StartPic := s.startpic;
  Result.MoveMode := s.movemode;
  Result.StartSpot := s.startspot;
  Result.Damage := s.damage;
  Result.HitPoints := s.hitpoints;
  Result.Kind := s.typ;
  Result.SpawnId := s.spawnid;
  Result.Score := s.score;
  Result.MaxMove := s.maxmove;
  Result.Regen := s.regen;
  Result.DeathEvent := s.deathevent;
  Result.Height := s.height;
  Result.SpecialType := TGreedSpecialType(Ord(s.specialtype));
  Result.Scale := s.scale;
  Result.OldX := s.oldx; Result.OldY := s.oldy; Result.OldZ := s.oldz;
  Result.OldAngle := s.oldangle; Result.OldAngle2 := s.oldangle2; Result.OldFloorZ := s.oldfloorz;
  Result.NewX := s.newx; Result.NewY := s.newy; Result.NewZ := s.newz;
  Result.NewAngle := s.newangle; Result.NewAngle2 := s.newangle2; Result.NewFloorZ := s.newfloorz;
  Result.Grounded := s.grounded;
end;

function DoorToLibrary(const d: doorobj_t): TGreedDoor;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.TileX := d.tilex;
  Result.TileY := d.tiley;
  Result.Open := d.doorOpen;
  Result.Opening := d.doorOpening;
  Result.Closing := d.doorClosing;
  Result.Blocked := d.doorBlocked;
  Result.Bumpable := d.doorBumpable;
  Result.Size := d.doorSize;
  Result.Timer := d.doorTimer;
  Result.Locks := d.doorLocks;
  Result.Orientation := TGreedDoorOrientation(Ord(d.orientation));
  Result.Transparent := d.transparent;
  Result.Pic := d.pic;
  Result.Height := d.height;
  Result.Position := d.position;
end;

function ElevatorToLibrary(const e: elevobj_t): TGreedElevator;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Up := e.elevUp;
  Result.Down := e.elevDown;
  Result.Position := e.position;
  Result.Position64 := e.position64;
  Result.Timer := e.elevTimer;
  Result.Floor := e.floor;
  Result.Ceiling := e.ceiling;
  Result.MapSpot := e.mapspot;
  Result.Speed := e.speed;
  Result.Eval := e.eval;
  Result.EndEval := e.endeval;
  Result.NoSave := e.nosave;
  Result.Kind := TGreedElevatorType(Ord(e.typ));
end;

procedure Plane(const name: string; const data: pointer);
begin
  Print.Block(name, data, MAPROWS * MAPCOLS);
end;

procedure PrintWorld;
var
  rec: TGreedPlayerRecord;
  sp: Pscaleobj_t;
  el: Pelevobj_t;
  i, n: integer;
  area: TGreedSpawnArea;
  ev: TWorldEvents;
  g: TWorldGlobals;
begin
  Print.StartFrame;
  Move(player, rec, SizeOf(rec));
  Print.Player(rec);

  Print.Select(wsSprites);
  n := 0;
  sp := firstscaleobj.next;
  while sp <> @lastscaleobj do
  begin
    Print.Sprite(n, SpriteToLibrary(sp^));
    inc(n);
    sp := sp.next;
  end;
  Print.Select(wsSprites);
  Print.Int('count', n);

  Print.Select(wsElevators);
  n := 0;
  el := firstelevobj.next;
  while el <> @lastelevobj do
  begin
    Print.Elevator(n, ElevatorToLibrary(el^));
    inc(n);
    el := el.next;
  end;
  Print.Select(wsElevators);
  Print.Int('count', n);

  Print.Select(wsDoors);
  Print.Int('count', numdoors);
  for i := 0 to numdoors - 1 do
    Print.Door(i, DoorToLibrary(doorlist[i]));

  Print.Select(wsAreas);
  Print.Int('count', numspawnareas);
  for i := 0 to numspawnareas - 1 do
  begin
    area.MapSpot := spawnareas[i].mapspot;
    area.MapX := spawnareas[i].mapx;
    area.MapY := spawnareas[i].mapy;
    area.Kind := spawnareas[i].typ;
    area.Time := spawnareas[i].time;
    Print.Area(i, area);
  end;

  Print.Select(wsPlanes);
  Plane('northwall', @northwall);
  Plane('northflags', @northflags);
  Plane('westwall', @westwall);
  Plane('westflags', @westflags);
  Plane('floorpic', @floorpic);
  Plane('floorflags', @floorflags);
  Plane('ceilingpic', @ceilingpic);
  Plane('ceilingflags', @ceilingflags);
  Plane('floorheight', @floorheight);
  Plane('ceilingheight', @ceilingheight);
  Plane('floordef', @floordef);
  Plane('floordefflags', @floordefflags);
  Plane('ceilingdef', @ceilingdef);
  Plane('ceilingdefflags', @ceilingdefflags);
  Plane('maplights', @maplights);
  Plane('mapeffects', @mapeffects);
  Plane('mapsprites', @mapsprites);
  // mapslopes is not in the fingerprint: it is read only when the map is loaded (ActivateSlopes turns it into
  // mapflags, which is here), and the original writes in it when a sprite is put past the end of mapsprites
  // (the map 10: a sprite of the script outside the map); the library does not write outside the map
  // the last 320 bytes of mapflags are not printed: reallight, that follows it, is written at a negative index by the
  // light of a sprite on the first row (sprites.pas), which in the original lands on them
  Print.Block('mapflags', @mapflags, MAPROWS * MAPCOLS - 320);

  FillChar(ev, SizeOf(ev), 0);
  Move(triggers, ev.Triggers, SizeOf(ev.Triggers));
  Move(switches, ev.Switches, SizeOf(ev.Switches));
  Move(processes, ev.Processes, SizeOf(ev.Processes));
  ev.NumProcesses := numprocesses;
  ev.NumZones := numzones;
  ev.FliPlayed := fliplayed;
  for i := 0 to MAXZONES - 1 do
  begin
    ev.Zones[i].X1 := zones[i].x1;
    ev.Zones[i].Y1 := zones[i].y1;
    ev.Zones[i].X2 := zones[i].x2;
    ev.Zones[i].Y2 := zones[i].y2;
    ev.Zones[i].Eval := zones[i].eval;
    ev.Zones[i].EndEval := zones[i].endeval;
    ev.Zones[i].Rate := zones[i].rate;
    ev.Zones[i].Layer := zones[i].layer;
    ev.Zones[i].NewValue := zones[i].newvalue;
    ev.Zones[i].SType := zones[i].stype;
    ev.Zones[i].Removeable := zones[i].removeable;
    ev.Zones[i].Kind := zones[i].typ;
  end;
  for i := 0 to 3 do
    ev.Primaries[i] := primaries[i];
  for i := 0 to 13 do
    ev.Secondaries[i] := secondaries[i];
  for i := 0 to 1 do
    ev.PCount[i] := pcount[i];
  for i := 0 to 6 do
    ev.SCount[i] := scount[i];
  ev.BonusTime := bonustime;
  ev.LevelScore := levelscore;
  Print.Events(ev);

  FillChar(g, SizeOf(g), 0);
  g.RandomOffset := rndofs;
  g.TimeCount := timecount;
  g.Frames := frames;
  g.WeapDelay := weapdelay;
  g.SpriteMoveTime := spritemovetime;
  g.SecretDelay := secretdelay;
  g.InventoryDelay := inventorydelay;
  g.UseDelay := usedelay;
  g.JumpDelay := jumpdelay;
  g.KeyboardDelay := keyboardDelay;
  g.RearViewTime := RearViewTime;
  g.RearViewDelay := RearViewDelay;
  g.InventoryTime := inventorytime;
  g.ChangingWeapons := changingweapons;
  g.WeaponLowering := weaponlowering;
  g.QuitGame := quitgame;
  g.HeatMode := heatmode;
  g.GodMode := godmode;
  g.MotionMode := motionmode;
  g.HurtBorder := hurtborder;
  g.DoorSound := doorsound;
  g.DeadRestart := deadrestart;
  g.ExitLevel := ExitLevel;
  g.ExitExists := exitexists;
  g.WarpJammer := warpjammer;
  g.AutoRun := autorun;
  g.RearViewOn := RearViewOn;
  g.CheckTrigger := checktrigger;
  g.UseItem := useitem;
  g.GoIRight := goiright;
  g.GoILeft := goileft;
  g.MidgetMode := midgetmode;
  g.AutoTarget := autotarget;
  g.ToggleGoalItem := togglegoalitem;
  g.WeapMode := weapmode;
  g.NewWeapon := newweapon;
  g.WeaponYChange := weaponychange;
  g.HeadBob := headbob;
  g.WeapBob := weapbob;
  g.ChangeLight := changelight;
  g.Lighting := lighting;
  g.TurnRate := turnrate;
  g.MapMode := mapmode;
  g.ScrollView := scrollview;
  g.DoorX := doorx;
  g.DoorY := doory;
  g.Warping := Warping;
  g.GoalItem := goalitem;
  g.SpecialEffect := specialeffect;
  g.FallDamage := falldamage;
  g.WallAnimCount := wallanimcount;
  g.SongNum := songnum;
  g.MoveRate := moverate;
  g.StrafRate := strafrate;
  g.FallRate := fallrate;
  g.WarpX := WarpX;
  g.WarpY := WarpY;
  g.WallAnimationTime := wallanimationtime;
  g.SpecialEffectTime := specialeffecttime;
  g.SwitchTime := SwitchTime;
  g.PlayerAngle64 := player_angle64;
  g.BonusTime := BonusItem.time;
  g.BonusScore := BonusItem.score;
  g.BonusTileX := BonusItem.tilex;
  g.BonusTileY := BonusItem.tiley;
  g.BonusMapSpot := BonusItem.mapspot;
  g.BonusNum := BonusItem.num;
  g.BonusSprite := -1;
  n := 0;
  sp := firstscaleobj.next;
  while sp <> @lastscaleobj do
  begin
    if sp = BonusItem.sprite then
      g.BonusSprite := n;
    inc(n);
    sp := sp.next;
  end;
  g.InventoryCursor := inventorycursor;
  g.FireGrenade := firegrenade;
  g.FirePending := actionflag <> 0;
  g.WarpActive := warpActive;
  g.BloodCount := bloodcount;
  g.MetalCount := metalcount;
  g.MouseDX := mousedx;
  g.MouseDY := mousedy;
  for i := 0 to 18 do
  begin
    g.WeaponCharge[i] := weapons[i].charge;
    g.WeaponChargeTime[i] := weapons[i].chargetime;
  end;
  Print.Globals(g);
end;

procedure AddHistory(const value: LongWord);
var
  i: integer;
begin
  for i := 0 to 3 do
    History := (History xor ((value shr (8 * i)) and $FF)) * 16777619;
end;

// per-tic trace of the fields of the weapon: GREED_TRACE = "<first turn>-<last turn>", GREED_TRACE_FILE = the file
procedure Trace(const where: string);
var
  w, a, b: integer;
  s: string;
  f: TextFile;
begin
  s := GetEnvironmentVariable('GREED_TRACE');
  if s = '' then
    exit;
  a := StrToInt(Copy(s, 1, Pos('-', s) - 1));
  b := StrToInt(Copy(s, Pos('-', s) + 1, 20));
  if (Frame < a) or (Frame > b) then
    exit;
  w := player.weapons[player.currentweapon];
  AssignFile(f, GetEnvironmentVariable('GREED_TRACE_FILE'));
  if FileExists(GetEnvironmentVariable('GREED_TRACE_FILE')) then
    Append(f)
  else
    Rewrite(f);
  Writeln(f, where, ' w=', w, ' charge=', weapons[w].charge, '/', weapons[w].chargetime, ' mode=', weapmode, ' delay=',
    weapdelay, ' action=', actionflag, ' ammo1=', player.ammo[1], ' cur=', player.currentweapon, ' chg=',
    Ord(changingweapons), ' fire=', in_button[bt_fire], ' status=', player.status);
  CloseFile(f);
end;

procedure HarnessTraceNote(const where: string);
begin
  Trace('N ' + IntToStr(Frame) + ' ' + where + ' tc ' + IntToStr(timecount) + ' actionflag-reallight=' +
    IntToStr(NativeInt(@actionflag) - NativeInt(@reallight)) + ' size=' + IntToStr(SizeOf(reallight)));
end;

function HarnessNextFrame: boolean;
var
  i: integer;
  lines: TStringList;
begin
  // a game that ended inside a turn is asked twice for its last state
  if Frame = LastPrinted then
  begin
    Result := false;
    exit;
  end;
  LastPrinted := Frame;
  Trace(Format('E %d end tc %d', [Frame, timecount]));
  // the state after the turn that has just ended (the turn 0 is the state before the first one)
  if Frame = HarnessDumpFrame then
  begin
    lines := TStringList.Create;
    Print.Lines := lines;
    PrintWorld;
    Print.Lines := nil;
    lines.SaveToFile(HarnessDumpFile);
    lines.Free;
  end
  else
    PrintWorld;
  AddHistory(Print.Total);
  if HarnessAllFrames or (Frame mod HarnessEvery = 0) or (Frame = HarnessFrames) or quitgame then
    HarnessOutput.Add(Format('W %d %d %d %d %s %s', [HarnessMap, HarnessSeed, Frame, timecount,
      IntToHex(History, 8), Print.Line]));
  if (Frame >= HarnessFrames) or quitgame then
  begin
    Result := false;
    exit;
  end;
  inc(Frame);
  for i := 1 to HarnessTicsPerFrame do
  begin
    inc(TotalTics);
    HarnessClock := ClockBase + LongWord(TotalTics) * 14;
    INT_TimerISR;
    Trace(Format('T %d tic %d tc %d', [Frame, i, timecount]));
  end;
  Result := true;
end;

end.
