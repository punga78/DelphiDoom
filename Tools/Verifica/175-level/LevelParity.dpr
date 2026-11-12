program LevelParity;
{$APPTYPE CONSOLE}
{$Q-}
{$R-}
{$J+}
// Harness fuori dalla suite: fa girare sugli stessi scenari (Tests\Source\DelphiDoom.Tests.Greed.LevelScenarios)
// le routine ORIGINALI di raven.pas di xGreed (ritagliate dal file originale da Compila.ps1, non modificate) e
// TGreedItemRules, TGreedSwitchRules e TGreedLevelRules di Libs\Greed, li confronta fotogramma per fotogramma e
// scrive il golden (le impronte dell'originale). Il resto del gioco e' negli stub di stubs\.
// Uso: LevelParity <golden.txt | nessuno> [primo scenario] [ultimo scenario]
uses
  SysUtils, Classes, Windows, Generics.Collections,
  g_delphi, protos_h, r_public_h, r_refdef, r_render, r_conten, r_public, raven, d_ints, d_misc, net, constant,
  display, event, utils, modplay, harness_level,
  DelphiDoom.Greed.Types, DelphiDoom.Greed.SaveTypes, DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.World.Intf,
  DelphiDoom.Tests.Greed.LevelScenarios, DelphiDoom.Tests.Greed.LevelRunner;

type
  PGreedPlayerRecord = ^TGreedPlayerRecord;

  TOriginalLevelRunner = class(TLevelScenarioRunner)
  protected
    procedure LoadScenario(const AScenario: TLevelScenario); override;
    procedure GetGlobals(out AGlobals: TLevelGlobals); override;
    procedure SetGlobals(const AGlobals: TLevelGlobals); override;
    procedure GetPlayer(out APlayer: TGreedPlayerRecord); override;
    procedure SetPlayer(const APlayer: TGreedPlayerRecord); override;
    procedure SetClock(AValue: Cardinal); override;
    procedure GetBonus(out ABonus: TLevelBonus); override;
    procedure GetWeaponCharges(out ACharges: TLevelWeaponCharges); override;
    function GetWarpActive: Integer; override;
    function GetRandomOffset: Integer; override;
    procedure ListSprites(AList: TList<TGreedSprite>); override;
    procedure ListElevators(AList: TList<TGreedElevator>); override;
    function DoorCount: Integer; override;
    function DoorAt(AIndex: Integer): TGreedDoor; override;
    function AreaCount: Integer; override;
    function AreaAt(AIndex: Integer): TGreedSpawnArea; override;
    procedure CopyPlane(APlane: TGreedPlane; out ATiles: TLevelTiles); override;
    procedure CopyTriggers(out ATiles: TLevelTiles); override;
    procedure CopySwitches(out ATiles: TLevelTiles); override;
    procedure SetSpriteHitPoints(AOrdinal, AValue: Integer); override;
    procedure CheckWarps(AX, AY: Integer); override;
    procedure CheckItems(ATileX, ATileY: Integer; AUseIt: Boolean; ACharType: Integer); override;
    procedure CheckHere(AUseIt: Boolean; AX, AY, AAngle: Integer); override;
    procedure CheckDoors(AX, AY: Integer); override;
    procedure TimeUpdate; override;
    procedure WarpAnim; override;
    procedure JamWarps; override;
    procedure PrepareNexus; override;
    procedure EndLevel; override;
    procedure StartOver(ARestartValue: Integer); override;
    procedure NewGoalItem; override;
  end;

{ TOriginalLevelRunner }

procedure TOriginalLevelRunner.LoadScenario(const AScenario: TLevelScenario);
var
  i: Integer;
  a: Pspawnarea_t;
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
  RF_ClearWorld;
  FillChar(doorlist, SizeOf(doorlist), 0);
  for i := 0 to High(AScenario.Doors) do
    DoorFromLibrary(AScenario.Doors[i], @doorlist[i]);
  numdoors := Length(AScenario.Doors);
  for i := 0 to High(AScenario.Areas) do
  begin
    a := RF_GetSpawnArea;
    a.mapspot := AScenario.Areas[i].MapSpot;
    a.mapx := AScenario.Areas[i].MapX;
    a.mapy := AScenario.Areas[i].MapY;
    a.typ := AScenario.Areas[i].Kind;
    a.time := AScenario.Areas[i].Time;
  end;
  for i := 0 to High(AScenario.Sprites) do
    FromLibrary(AScenario.Sprites[i], RF_GetSprite);
  for i := 0 to High(AScenario.Elevators) do
    ElevatorFromLibrary(AScenario.Elevators[i], RF_GetElevator);
  Move(AScenario.Triggers[0], triggers, 4096);
  Move(AScenario.Switches[0], switches, 4096);
  Move(AScenario.Player, player, SizeOf(player));
  for i := 0 to 3 do
    primaries[i] := AScenario.Primaries[i];
  for i := 0 to 13 do
    secondaries[i] := AScenario.Secondaries[i];
  for i := 0 to 1 do
    pcount[i] := AScenario.PCount[i];
  for i := 0 to 6 do
    scount[i] := AScenario.SCount[i];
  bonustime := AScenario.BonusTime;
  levelscore := AScenario.LevelScore;
  FillChar(BonusItem, SizeOf(BonusItem), 0);
  BonusItem.time := AScenario.BonusFirstTime;
  DEMO := AScenario.Demo;
  timecount := AScenario.TimeCount;
  spritemovetime := AScenario.TimeCount;
  numprocesses := AScenario.NumProcesses;
  fliplayed := 0;
  lighting := AScenario.AmbientLight;
  SC.ambientlight := AScenario.AmbientLight;
  HarnessClock := AScenario.ClockBase;
  rndofs := AScenario.RandomOffset;
  netmode := false;
  // the weapons of constant.pas as they are when the program starts
  for i := 0 to 18 do
  begin
    weapons[i].charge := 0;
    weapons[i].chargetime := 0;
  end;
  // the globals that the rules touch, as when the program starts
  SwitchTime := 0;
  specialeffect := 0;
  specialeffecttime := 0;
  Warping := 0;
  WarpX := 0;
  WarpY := 0;
  warpActive := 0;
  warpjammer := false;
  ExitLevel := false;
  exitexists := false;
  hurtborder := false;
  changingweapons := false;
  weaponlowering := false;
  newweapon := 0;
  weaponychange := 0;
  turnrate := 0;
  moverate := 0;
  strafrate := 0;
  fallrate := 0;
  doorsound := false;
  doorx := 0;
  doory := 0;
  goalitem := 0;
  togglegoalitem := false;
  changelight := 0;
  deadrestart := false;
  oldinventory := 0;
  oldshots := 0;
  oldgoalitem := 0;
  totaleffecttime := 0;
  weaponpic[0].height := 0;
end;

procedure TOriginalLevelRunner.GetGlobals(out AGlobals: TLevelGlobals);
begin
  AGlobals.TimeCount := timecount;
  AGlobals.SpriteMoveTime := spritemovetime;
  AGlobals.SwitchTime := SwitchTime;
  AGlobals.SpecialEffect := specialeffect;
  AGlobals.SpecialEffectTime := specialeffecttime;
  AGlobals.Warping := Warping;
  AGlobals.WarpX := WarpX;
  AGlobals.WarpY := WarpY;
  AGlobals.WarpActive := warpActive;
  AGlobals.WarpJammer := warpjammer;
  AGlobals.ExitLevel := ExitLevel;
  AGlobals.ExitExists := exitexists;
  AGlobals.HurtBorder := hurtborder;
  AGlobals.ChangingWeapons := changingweapons;
  AGlobals.WeaponLowering := weaponlowering;
  AGlobals.NewWeapon := newweapon;
  AGlobals.WeaponYChange := weaponychange;
  AGlobals.TurnRate := turnrate;
  AGlobals.MoveRate := moverate;
  AGlobals.StrafRate := strafrate;
  AGlobals.FallRate := fallrate;
  AGlobals.DoorSound := doorsound;
  AGlobals.DoorX := doorx;
  AGlobals.DoorY := doory;
  AGlobals.GoalItem := goalitem;
  AGlobals.ToggleGoalItem := togglegoalitem;
  AGlobals.Lighting := lighting;
  AGlobals.ChangeLight := changelight;
  AGlobals.DeadRestart := deadrestart;
  AGlobals.NumProcesses := numprocesses;
  AGlobals.OldInventory := oldinventory;
  AGlobals.OldShots := oldshots;
  AGlobals.OldGoalItem := oldgoalitem;
  AGlobals.TotalEffectTime := totaleffecttime;
end;

procedure TOriginalLevelRunner.SetGlobals(const AGlobals: TLevelGlobals);
begin
  timecount := AGlobals.TimeCount;
  spritemovetime := AGlobals.SpriteMoveTime;
  SwitchTime := AGlobals.SwitchTime;
  specialeffect := AGlobals.SpecialEffect;
  specialeffecttime := AGlobals.SpecialEffectTime;
  Warping := AGlobals.Warping;
  WarpX := AGlobals.WarpX;
  WarpY := AGlobals.WarpY;
  warpActive := AGlobals.WarpActive;
  warpjammer := AGlobals.WarpJammer;
  ExitLevel := AGlobals.ExitLevel;
  exitexists := AGlobals.ExitExists;
  hurtborder := AGlobals.HurtBorder;
  changingweapons := AGlobals.ChangingWeapons;
  weaponlowering := AGlobals.WeaponLowering;
  newweapon := AGlobals.NewWeapon;
  weaponychange := AGlobals.WeaponYChange;
  turnrate := AGlobals.TurnRate;
  moverate := AGlobals.MoveRate;
  strafrate := AGlobals.StrafRate;
  fallrate := AGlobals.FallRate;
  doorsound := AGlobals.DoorSound;
  doorx := AGlobals.DoorX;
  doory := AGlobals.DoorY;
  goalitem := AGlobals.GoalItem;
  togglegoalitem := AGlobals.ToggleGoalItem;
  lighting := AGlobals.Lighting;
  changelight := AGlobals.ChangeLight;
  deadrestart := AGlobals.DeadRestart;
  numprocesses := AGlobals.NumProcesses;
  oldinventory := AGlobals.OldInventory;
  oldshots := AGlobals.OldShots;
  oldgoalitem := AGlobals.OldGoalItem;
  totaleffecttime := AGlobals.TotalEffectTime;
end;

procedure TOriginalLevelRunner.GetPlayer(out APlayer: TGreedPlayerRecord);
begin
  APlayer := PGreedPlayerRecord(@player)^;
end;

procedure TOriginalLevelRunner.SetPlayer(const APlayer: TGreedPlayerRecord);
begin
  PGreedPlayerRecord(@player)^ := APlayer;
end;

procedure TOriginalLevelRunner.SetClock(AValue: Cardinal);
begin
  HarnessClock := AValue;
end;

procedure TOriginalLevelRunner.GetBonus(out ABonus: TLevelBonus);
var
  s: Pscaleobj_t;
  n: Integer;
begin
  ABonus.Time := BonusItem.time;
  ABonus.Score := BonusItem.score;
  ABonus.TileX := BonusItem.tilex;
  ABonus.TileY := BonusItem.tiley;
  ABonus.MapSpot := BonusItem.mapspot;
  ABonus.Num := BonusItem.num;
  ABonus.Name := string(BonusItem.name);
  ABonus.SpriteOrdinal := -1;
  n := 0;
  s := firstscaleobj.next;
  while s <> @lastscaleobj do
  begin
    if s = BonusItem.sprite then
    begin
      ABonus.SpriteOrdinal := n;
      Break;
    end;
    Inc(n);
    s := s.next;
  end;
end;

procedure TOriginalLevelRunner.GetWeaponCharges(out ACharges: TLevelWeaponCharges);
var
  i: Integer;
begin
  for i := 0 to High(ACharges) do
  begin
    ACharges[i].Charge := weapons[i].charge;
    ACharges[i].ChargeTime := weapons[i].chargetime;
  end;
end;

function TOriginalLevelRunner.GetWarpActive: Integer;
begin
  Result := warpActive;
end;

function TOriginalLevelRunner.GetRandomOffset: Integer;
begin
  Result := rndofs;
end;

procedure TOriginalLevelRunner.ListSprites(AList: TList<TGreedSprite>);
var
  s: Pscaleobj_t;
begin
  s := firstscaleobj.next;
  while s <> @lastscaleobj do
  begin
    AList.Add(ToLibrary(s^));
    s := s.next;
  end;
end;

procedure TOriginalLevelRunner.ListElevators(AList: TList<TGreedElevator>);
var
  e: Pelevobj_t;
begin
  e := firstelevobj.next;
  while e <> @lastelevobj do
  begin
    AList.Add(ElevatorToLibrary(e^));
    e := e.next;
  end;
end;

function TOriginalLevelRunner.DoorCount: Integer;
begin
  Result := numdoors;
end;

function TOriginalLevelRunner.DoorAt(AIndex: Integer): TGreedDoor;
begin
  Result := DoorToLibrary(doorlist[AIndex]);
end;

function TOriginalLevelRunner.AreaCount: Integer;
begin
  Result := numspawnareas;
end;

function TOriginalLevelRunner.AreaAt(AIndex: Integer): TGreedSpawnArea;
begin
  Result := AreaToLibrary(spawnareas[AIndex]);
end;

procedure TOriginalLevelRunner.CopyPlane(APlane: TGreedPlane; out ATiles: TLevelTiles);
begin
  case APlane of
    gpMapSprites:
      Move(mapsprites[0], ATiles[0], 4096);
    gpNorthWall:
      Move(northwall[0], ATiles[0], 4096);
    gpWestWall:
      Move(westwall[0], ATiles[0], 4096);
    gpFloorHeight:
      Move(floorheight[0], ATiles[0], 4096);
  else
    raise Exception.Create('CopyPlane');
  end;
end;

procedure TOriginalLevelRunner.CopyTriggers(out ATiles: TLevelTiles);
begin
  Move(triggers, ATiles[0], 4096);
end;

procedure TOriginalLevelRunner.CopySwitches(out ATiles: TLevelTiles);
begin
  Move(switches, ATiles[0], 4096);
end;

procedure TOriginalLevelRunner.SetSpriteHitPoints(AOrdinal, AValue: Integer);
var
  s: Pscaleobj_t;
begin
  s := firstscaleobj.next;
  while (s <> @lastscaleobj) and (AOrdinal > 0) do
  begin
    Dec(AOrdinal);
    s := s.next;
  end;
  if s <> @lastscaleobj then
    s.hitpoints := AValue;
end;

procedure TOriginalLevelRunner.CheckWarps(AX, AY: Integer);
begin
  raven.CheckWarps(AX, AY);
end;

procedure TOriginalLevelRunner.CheckItems(ATileX, ATileY: Integer; AUseIt: Boolean; ACharType: Integer);
begin
  raven.CheckItems(ATileX, ATileY, AUseIt, ACharType);
end;

procedure TOriginalLevelRunner.CheckHere(AUseIt: Boolean; AX, AY, AAngle: Integer);
begin
  raven.CheckHere(AUseIt, AX, AY, AAngle);
end;

procedure TOriginalLevelRunner.CheckDoors(AX, AY: Integer);
begin
  raven.CheckDoors(AX, AY);
end;

procedure TOriginalLevelRunner.TimeUpdate;
begin
  raven.TimeUpdate;
end;

procedure TOriginalLevelRunner.WarpAnim;
begin
  raven.WarpAnim;
end;

procedure TOriginalLevelRunner.JamWarps;
begin
  raven.JamWarps;
end;

procedure TOriginalLevelRunner.PrepareNexus;
begin
  raven.PrepareNexus;
end;

procedure TOriginalLevelRunner.EndLevel;
begin
  raven.EndLevel;
end;

procedure TOriginalLevelRunner.StartOver(ARestartValue: Integer);
begin
  raven.startover(ARestartValue);
end;

procedure TOriginalLevelRunner.NewGoalItem;
begin
  raven.NewGoalItem;
end;

var
  GoldenPath: string;
  First, Last, Index, Tic, Line, TotalTics, TotalDifferences, Skipped, Compared: Integer;
  Scenario: TLevelScenario;
  Original: TOriginalLevelRunner;
  Lib: TLibraryLevelRunner;
  OriginalHashes, LibHashes: TList<Cardinal>;
  OriginalDump, LibDump: TStringList;
  Golden: TStringList;
  Crashed: Boolean;
  Counts: TDictionary<string, Integer>;
  Keys: TStringList;
  Key: string;
begin
  try
    if SizeOf(player_t) <> SizeOf(TGreedPlayerRecord) then
      raise Exception.Create('player_t and TGreedPlayerRecord differ in size');
    GoldenPath := ParamStr(1);
    if GoldenPath = 'nessuno' then
      GoldenPath := '';
    First := StrToIntDef(ParamStr(2), 0);
    Last := StrToIntDef(ParamStr(3), LEVEL_SCENARIO_COUNT - 1);
    if Last > LEVEL_SCENARIO_COUNT - 1 then
      Last := LEVEL_SCENARIO_COUNT - 1;
    Golden := TStringList.Create;
    Golden.Add('# impronte FNV-1a, fotogramma per fotogramma, delle routine ORIGINALI di raven.pas di xGreed');
    Golden.Add('# (CheckItems, CheckWarps, CheckHere, TimeUpdate, CheckSpawnAreas, CheckBonusItem ...) sugli scenari di');
    Golden.Add('# DelphiDoom.Tests.Greed.LevelScenarios (harness Tools\Verifica\175-level).');
    Golden.Add('# S <scenario> <fotogrammi> seguito da una riga per fotogramma; X <scenario> = l''originale cade, saltato');
    Original := TOriginalLevelRunner.Create;
    Counts := TDictionary<string, Integer>.Create;
    if ParamStr(4) = 'conta' then
      Original.Trace.Counts := Counts;
    Lib := TLibraryLevelRunner.Create;
    OriginalHashes := TList<Cardinal>.Create;
    LibHashes := TList<Cardinal>.Create;
    OriginalDump := TStringList.Create;
    LibDump := TStringList.Create;
    TotalTics := 0;
    TotalDifferences := 0;
    Skipped := 0;
    Compared := 0;
    for Index := First to Last do
    begin
      Scenario := BuildLevelScenario(Index);
      OriginalHashes.Clear;
      LibHashes.Clear;
      Crashed := False;
      try
        Original.Run(Scenario, OriginalHashes);
      except
        on E: Exception do
        begin
          Writeln('scenario ', Index, ': l''originale cade al fotogramma ', OriginalHashes.Count, ': ', E.ClassName,
            ' ', E.Message);
          Crashed := True;
        end;
      end;
      if Crashed then
      begin
        Golden.Add('X ' + IntToStr(Index));
        Inc(Skipped);
        Continue;
      end;
      Golden.Add(Format('S %d %d', [Index, OriginalHashes.Count]));
      for Tic := 0 to OriginalHashes.Count - 1 do
        Golden.Add(IntToHex(OriginalHashes[Tic], 8));
      try
        Lib.Run(Scenario, LibHashes);
      except
        on E: Exception do
          Writeln('scenario ', Index, ': la libreria cade al fotogramma ', LibHashes.Count, ': ', E.ClassName, ' ',
            E.Message);
      end;
      Inc(Compared);
      TotalTics := TotalTics + OriginalHashes.Count;
      Tic := 0;
      while (Tic < OriginalHashes.Count) and (Tic < LibHashes.Count) and (OriginalHashes[Tic] = LibHashes[Tic]) do
        Inc(Tic);
      if (Tic < OriginalHashes.Count) or (LibHashes.Count <> OriginalHashes.Count) then
      begin
        Inc(TotalDifferences);
        Writeln('scenario ', Index, ': DIFFERENZA al fotogramma ', Tic, ' (fotogrammi originale ',
          OriginalHashes.Count, ', libreria ', LibHashes.Count, ')');
        OriginalDump.Clear;
        LibDump.Clear;
        OriginalHashes.Clear;
        LibHashes.Clear;
        try
          Original.Run(Scenario, OriginalHashes, Tic, OriginalDump);
          Lib.Run(Scenario, LibHashes, Tic, LibDump);
        except
          on E: Exception do
            Writeln('    ', E.ClassName, ' ', E.Message);
        end;
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
        Writeln('scenario ', Index, ': ', OriginalHashes.Count, ' fotogrammi, ', Length(Scenario.Sprites),
          ' sprite e ', Length(Scenario.Waypoints), ' posti, uguale');
    end;
    Writeln(Format('scenari %d, confrontati %d, saltati %d, fotogrammi %d, scenari con differenze %d',
      [Last - First + 1, Compared, Skipped, TotalTics, TotalDifferences]));
    if Counts.Count > 0 then
    begin
      // what the original was asked and said, summed on the scenarios: shows what they reach
      Keys := TStringList.Create;
      for Key in Counts.Keys do
        Keys.Add(Key);
      Keys.Sort;
      for Key in Keys do
        Writeln(Format('%8d  %s', [Counts[Key], Key]));
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
