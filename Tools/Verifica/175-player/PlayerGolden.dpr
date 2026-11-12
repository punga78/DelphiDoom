program PlayerGolden;
// Issue #175: runs ControlMovement, ControlBobbing, CheckHere, chargeweapons, fireweapon, GetTargetAngle, newlights
// and ChangeScroll of raven.pas of xGreed AS THEY ARE (Reference\xGreed, read only; with TryDoor, TryMove, ClipMove
// and Thrust of raven.pas and SP_Thrust of sprites.pas) on the scenarios of
// Tests\Source\DelphiDoom.Tests.Greed.PlayerScenarios and writes one line for each scenario: the golden file that
// the test of TGreedPlayerControl compares with the library. See Compila.ps1.
// Use: PlayerGolden <golden file> [<file of the values of every tic> <scenario>]
{$APPTYPE CONSOLE}
{$Q-}
{$R-}
{$H+}

uses
  SysUtils,
  Classes,
  g_delphi,
  r_public_h,
  r_refdef,
  protos_h,
  constant,
  d_ints_h,
  d_ints,
  d_misc,
  d_video,
  event,
  modplay,
  net,
  raven,
  r_conten,
  r_render,
  r_public,
  sprites,
  utils,
  calllog,
  DelphiDoom.Tests.Greed.PlayerScenarios;

var
  Maps: array[1..PLAYER_MAP_COUNT] of TPlayerMap;
  SavedWeapons: array[0..SizeOf(weapons) - 1] of byte;
  LastWeaponX, LastWeaponY: integer;

procedure Prepare(const AScenario: TPlayerScenario);
var
  i: integer;
  d: Pdoorobj_t;
  e: Pelevobj_t;
  m: ^TPlayerMap;
begin
  m := @Maps[AScenario.MapSeed];
  RF_ClearWorld;
  FillChar(doorlist, SizeOf(doorlist), 0);
  Move(m.NorthWall, northwall, PLAYER_TILES);
  Move(m.NorthFlags, northflags, PLAYER_TILES);
  Move(m.WestWall, westwall, PLAYER_TILES);
  Move(m.WestFlags, westflags, PLAYER_TILES);
  Move(m.FloorPic, floorpic, PLAYER_TILES);
  Move(m.FloorFlags, floorflags, PLAYER_TILES);
  Move(m.CeilingPic, ceilingpic, PLAYER_TILES);
  Move(m.FloorHeight, floorheight, PLAYER_TILES);
  Move(m.CeilingHeight, ceilingheight, PLAYER_TILES);
  Move(m.MapFlags, mapflags, PLAYER_TILES);
  Move(m.MapSprites, mapsprites, PLAYER_TILES);
  Move(m.Switches, switches, PLAYER_TILES);
  for i := 0 to PLAYER_DOOR_COUNT - 1 do
  begin
    d := RF_GetDoor(m.Doors[i].TileX, m.Doors[i].TileY);
    d.orientation := orientation_t(m.Doors[i].Orientation);
    d.doorOpen := m.Doors[i].Open;
    d.doorBumpable := m.Doors[i].Bumpable;
  end;
  for i := 0 to PLAYER_ELEVATOR_COUNT - 1 do
  begin
    e := RF_GetElevator;
    e.mapspot := m.Elevators[i].MapSpot;
    e.typ := elevtype(m.Elevators[i].Kind);
    e.floor := m.Elevators[i].Floor;
    e.ceiling := m.Elevators[i].Ceiling;
    e.position := m.Elevators[i].Position;
  end;

  // the globals of raven.pas, as a new game leaves them
  player_angle64 := 0;
  weapdelay := 0;
  secretdelay := 0;
  inventorydelay := 0;
  usedelay := 0;
  jumpdelay := 0;
  keyboardDelay := 0;
  inventorytime := 0;
  changingweapons := false;
  weaponlowering := false;
  togglemapmode := false;
  toggleheatmode := false;
  togglemotionmode := false;
  activatemenu := false;
  doorsound := false;
  deadrestart := false;
  togglegoalitem := false;
  paused := false;
  QuickExit := false;
  autorun := false;
  ToggleRearView := false;
  checktrigger := false;
  activatehelp := false;
  useitem := false;
  toggleautorun := false;
  goiright := false;
  goileft := false;
  activatebrief := false;
  autotarget := true;
  toggleautotarget := false;
  resizeScreen := false;
  biggerScreen := false;
  adjustvrangle := 0;
  adjustvrdist := 0;
  weapmode := 0;
  newweapon := 0;
  weaponychange := 0;
  headbob := 0;
  weapbob := 0;
  moveforward := 0;
  changelight := 0;
  lighting := 1000;
  turnrate := 0;
  scrollview := 0;
  doorx := 0;
  doory := 0;
  MapZoom := 8;
  Warping := 0;
  falldamage := 0;
  netmsgindex := 0;
  netmsgstatus := 0;
  playerturnspeed := 8;
  turnunit := 2;
  moverate := 0;
  strafrate := 0;
  fallrate := 0;
  netmode := false;
  SwitchTime := 0;
  secretbuf := '';
  newsong := false;
  wpic := nil;
  weapbob1 := 0;
  wx := 0;
  wy := 0;
  LastWeaponX := 0;
  LastWeaponY := 0;
  // d_ints.pas
  timecount := 0;
  FillChar(keyboard, SizeOf(keyboard), 0);
  FillChar(in_button, SizeOf(in_button), 0);
  newascii := false;
  lastascii := #0;
  mousedx := 0;
  mousedy := 0;
  FillChar(mousebuttons, SizeOf(mousebuttons), 0);
  FillChar(mouse, SizeOf(mouse), 0);
  invertmouseturn := AScenario.InvertTurn;
  invertmouselook := AScenario.InvertLook;
  mousesensitivityx := 10;
  mousesensitivityy := 5;
  // the settings
  FillChar(SC, SizeOf(SC), 0);
  if AScenario.MouseEnabled then
    SC.mouse := 1;
  SC.mousesensitivity := AScenario.MouseSensitivity;
  SC.screensize := 2;
  SC.vrangle := 3;
  // sprites.pas and the lines of InitData for the probe
  playernum := 0;
  FillChar(probe, SizeOf(probe), 0);
  msprite := nil;
  spritehit := false;
  playerhit := false;
  hitx := 0;
  hity := 0;
  spriteloc := 0;
  probe.moveSpeed := MAXPROBE;
  probe.movesize := 16 * FRACUNIT; // half a tile
  probe.spawnid := playernum;
  actionflag := 0;
  Move(SavedWeapons, weapons, SizeOf(weapons));

  FillChar(player, SizeOf(player), 0);
  player.x := (m.StartTileX * 64 + 32) * FRACUNIT;
  player.y := (m.StartTileY * 64 + 32) * FRACUNIT;
  player.height := AScenario.Height;
  player.z := RF_GetFloorZ(player.x, player.y) + player.height;
  player.mapspot := m.StartTileY * MAPCOLS + m.StartTileX;
  player.angle := AScenario.Angle;
  player_angle64 := AScenario.Angle * 64;
  player.angst := 100;
  player.chartype := AScenario.CharType;
  for i := 0 to 4 do
    player.weapons[i] := AScenario.Weapons[i];
  for i := 0 to 2 do
    player.ammo[i] := AScenario.Ammo[i];
  player.walkmod := AScenario.WalkMod;
  player.runmod := AScenario.RunMod;
  player.jumpmod := AScenario.JumpMod;
  loadweapon(player.weapons[player.currentweapon]);
  Calls.Reset;
end;

// INT_ReadControls of d_ints.pas, with the keys of the scenario in the place of the keyboard of Windows
procedure ReadControls(const APrevious: TPlayerKeys; const AInput: TPlayerTic);
var
  i, code: integer;
  c: AnsiChar;
begin
  lastascii := #0;
  for i := 0 to PLAYER_KEY_COUNT - 1 do
  begin
    code := PLAYER_SCAN_CODES[i];
    if AInput.Keys[i] then
    begin
      if keyboard[code] = 0 then
        keyboard[code] := 1;
    end
    else
      keyboard[code] := 0;
  end;
  c := TPlayerScenarios.TypedCharacter(APrevious, AInput.Keys);
  if c <> #0 then
  begin
    lastascii := Char(c);
    newascii := true;
  end;
  memset(@in_button, 0, SizeOf(in_button));
  for i := 0 to NUMBUTTONS - 1 do
    if keyboard[scanbuttons[i]] <> 0 then
      in_button[i] := 1;
  mouse.oldflags := mouse.flags;
  mouse.flags := AInput.MouseFlags;
  mouse.dx := AInput.MouseDX;
  mouse.dy := AInput.MouseDY;
end;

// the steps of PlayLoop, TimeUpdate and UpdateView that belong to the player, in their order; the flags that the
// other steps of PlayLoop serve are lowered as they do
procedure Frame;
begin
  if toggleautorun then
  begin
    autorun := not autorun;
    toggleautorun := false;
  end;
  if toggleautotarget then
  begin
    autotarget := not autotarget;
    toggleautotarget := false;
  end;
  goiright := false;
  goileft := false;
  useitem := false;
  if checktrigger then
  begin
    checktrigger := false;
    CheckHere(true, player.x, player.y, player.angle);
  end;
  falldamage := 0;
  chargeweapons;
  if doorsound then
  begin
    doorsound := false;
    SoundEffect(SN_DOOR, 15, doorx, doory);
  end;
  deadrestart := false;
  resizeScreen := false;
  if scrollview <> 0 then
    ChangeScroll;
  toggleheatmode := false;
  togglemotionmode := false;
  togglemapmode := false;
  togglegoalitem := false;
  ToggleRearView := false;
  // RF_CheckActionFlag of the renderer
  if actionflag <> 0 then
  begin
    actionhook;
    actionflag := 0;
  end;
  H_WeaponView(1, LastWeaponX, LastWeaponY);
  newsong := false;
  activatemenu := false;
  activatehelp := false;
  activatebrief := false;
  QuickExit := false;
  paused := false;
  if changelight <> 0 then
    newlights;
  H_WeaponMode;
end;

procedure Collect(out v: TPlayerValues);
var
  h: TPlayerHash;
  i: integer;
  e: Pelevobj_t;
begin
  h.Reset;
  h.AddBytes(player, SizeOf(player));
  v[0] := integer(h.Value);
  v[1] := player_angle64;
  v[2] := moverate;
  v[3] := strafrate;
  v[4] := fallrate;
  v[5] := turnrate;
  v[6] := scrollview;
  v[7] := headbob;
  v[8] := weapbob;
  v[9] := weapmode;
  v[10] := weaponychange;
  v[11] := newweapon;
  v[12] := Ord(changingweapons);
  v[13] := Ord(weaponlowering);
  v[14] := weapdelay;
  v[15] := moveforward;
  v[16] := falldamage;
  v[17] := keyboardDelay;
  v[18] := secretdelay;
  v[19] := inventorydelay;
  v[20] := usedelay;
  v[21] := jumpdelay;
  v[22] := inventorytime;
  v[23] := Ord(activatemenu);
  v[24] := Ord(activatehelp);
  v[25] := Ord(QuickExit);
  v[26] := Ord(activatebrief);
  v[27] := Ord(paused);
  v[28] := Ord(resizeScreen);
  v[29] := Ord(biggerScreen);
  v[30] := Ord(togglemapmode);
  v[31] := Ord(toggleheatmode);
  v[32] := Ord(togglemotionmode);
  v[33] := Ord(ToggleRearView);
  v[34] := Ord(togglegoalitem);
  v[35] := Ord(toggleautorun);
  v[36] := Ord(toggleautotarget);
  v[37] := Ord(newsong);
  v[38] := Ord(goiright);
  v[39] := Ord(goileft);
  v[40] := Ord(deadrestart);
  v[41] := Ord(useitem);
  v[42] := Ord(checktrigger);
  v[43] := Ord(autorun);
  v[44] := Ord(autotarget);
  v[45] := MapZoom;
  v[46] := SC.screensize;
  v[47] := adjustvrangle;
  v[48] := Trunc(adjustvrdist);
  v[49] := mousedx;
  v[50] := mousedy;
  v[51] := Ord(mousebuttons[mbt_fire]) + 2 * Ord(mousebuttons[mbt_use]) + 4 * Ord(mousebuttons[mbt_north]);
  h.Reset;
  h.Add(Length(secretbuf));
  for i := 1 to Length(secretbuf) do
    h.Add(Ord(secretbuf[i]));
  v[52] := integer(h.Value);
  v[53] := lighting;
  v[54] := changelight;
  v[55] := SwitchTime;
  h.Reset;
  for i := 0 to 18 do
    h.Add(weapons[i].charge);
  v[56] := integer(h.Value);
  h.Reset;
  for i := 0 to 18 do
    h.Add(weapons[i].chargetime);
  v[57] := integer(h.Value);
  v[58] := probe.x;
  v[59] := probe.y;
  v[60] := probe.z;
  v[61] := probe.angle;
  v[62] := probe.angle2;
  v[63] := probe.zadj;
  v[64] := probe.startspot;
  v[65] := Ord(spritehit);
  v[66] := Ord(playerhit);
  v[67] := spriteloc;
  v[68] := hitx;
  v[69] := hity;
  v[70] := Ord(doorsound);
  v[71] := doorx;
  v[72] := doory;
  h.Reset;
  for i := 0 to numdoors - 1 do
  begin
    h.Add(Ord(doorlist[i].doorOpen));
    h.Add(Ord(doorlist[i].doorOpening));
    h.Add(Ord(doorlist[i].doorClosing));
    h.Add(doorlist[i].doorTimer);
  end;
  v[73] := integer(h.Value);
  h.Reset;
  e := firstelevobj.next;
  while e <> @lastelevobj do
  begin
    h.Add(Ord(e.elevUp));
    h.Add(Ord(e.elevDown));
    h.Add(e.elevTimer);
    h.Add(e.position);
    e := e.next;
  end;
  v[74] := integer(h.Value);
  v[75] := weapbob1;
  v[76] := wx;
  v[77] := wy;
  v[78] := LastWeaponX;
  v[79] := LastWeaponY;
  v[80] := actionflag;
  v[81] := Calls.Count;
  v[82] := integer(Calls.Value);
  v[83] := netmsgstatus;
  v[84] := timecount;
  v[85] := player.x;
  v[86] := player.y;
  v[87] := player.z;
  v[88] := player.angle;
  v[89] := player.mapspot;
  v[90] := player.currentweapon;
  v[91] := player.ammo[0];
  v[92] := player.ammo[1];
  v[93] := player.ammo[2];
  v[94] := player.scrollmin;
  v[95] := player.scrollmax;
  v[96] := player.status;
  v[97] := player.angst;
  v[98] := Warping;
end;

var
  LGolden, LFull: TStringList;
  LScenario: TPlayerScenario;
  LInput: TPlayerInput;
  LTic: TPlayerTic;
  LPrevious: TPlayerKeys;
  LValues: TPlayerValues;
  LRoll: TPlayerHash;
  LCheckpoints: TArray<Cardinal>;
  LAngle: double;
  i, j, t, LDump, LTics, LCalls: integer;
begin
  try
    if ParamCount < 1 then
      raise Exception.Create('PlayerGolden <golden file> [<file of the values of every tic> <scenario>]');
    LDump := -1;
    if ParamCount >= 3 then
      LDump := StrToInt(ParamStr(3));
    // the trig tables, as RF_Startup of r_public.pas
    for i := 0 to ANGLES do
    begin
      LAngle := (i * g_PI * 2) / (ANGLES + 1);
      sintable[i] := rint(sin(LAngle) * FRACUNIT);
      costable[i] := rint(cos(LAngle) * FRACUNIT);
    end;
    for i := 1 to PLAYER_MAP_COUNT do
      TPlayerScenarios.BuildMap(i, Maps[i]);
    Move(weapons, SavedWeapons, SizeOf(weapons));
    LTics := 0;
    LCalls := 0;
    LGolden := TStringList.Create;
    LFull := TStringList.Create;
    try
      LGolden.Add('# the control of the player of raven.pas of xGreed (Tools\Verifica\175-player): scenario tics calls and the FNV-1a of the tics so far every ' +
        IntToStr(PLAYER_CHECKPOINT) + ' tics');
      for i := 0 to PLAYER_SCENARIO_COUNT - 1 do
      begin
        LScenario := TPlayerScenarios.Scenario(i);
        Prepare(LScenario);
        LInput.Start(LScenario);
        FillChar(LPrevious, SizeOf(LPrevious), 0);
        LRoll.Reset;
        LCheckpoints := nil;
        for t := 1 to LScenario.Tics do
        begin
          inc(timecount);
          LInput.Next(t, LTic);
          if LTic.Angst >= 0 then
            player.angst := LTic.Angst;
          if LTic.Warping >= 0 then
            Warping := LTic.Warping;
          if LTic.ChangeLight <> 0 then
            changelight := LTic.ChangeLight;
          if timecount and 1 <> 0 then
          begin
            ReadControls(LPrevious, LTic);
            LPrevious := LTic.Keys;
          end;
          PlayerCommand;
          Collect(LValues);
          for j := 0 to High(LValues) do
            LRoll.Add(LValues[j]);
          if i = LDump then
            LFull.Add(TPlayerScenarios.Describe(t, LValues));
          if t mod LScenario.FrameEvery = 0 then
            Frame;
          Collect(LValues);
          for j := 0 to High(LValues) do
            LRoll.Add(LValues[j]);
          if i = LDump then
            LFull.Add(TPlayerScenarios.Describe(-t, LValues));
          if (t mod PLAYER_CHECKPOINT = 0) or (t = LScenario.Tics) then
          begin
            SetLength(LCheckpoints, Length(LCheckpoints) + 1);
            LCheckpoints[High(LCheckpoints)] := LRoll.Value;
          end;
        end;
        LGolden.Add(TPlayerScenarios.GoldenLine(LScenario, Calls.Count, LCheckpoints));
        inc(LTics, LScenario.Tics);
        inc(LCalls, Calls.Count);
      end;
      LGolden.SaveToFile(ParamStr(1));
      if LDump >= 0 then
        LFull.SaveToFile(ParamStr(2));
      Writeln(Format('%d scenarios, %d tics, %d calls to the rest of the game', [PLAYER_SCENARIO_COUNT, LTics, LCalls]));
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
