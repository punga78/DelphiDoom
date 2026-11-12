{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - what a level does while the player is in it      }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): chargeweapons,              }
{  CheckSpawnAreas, CheckBonusItem, TimeUpdate, NewGoalItem, startover,         }
{  EndLevel, WarpAnim, PrepareNexus and JamWarps of raven.pas                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.LevelRules;

// the positions are 16.16 fixed point numbers and the clock is added to the random numbers as an unsigned
// 32 bit number: the arithmetic wraps as in the original
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.LinkedPool,
  DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.Random, DelphiDoom.Greed.Game.Constants,
  DelphiDoom.Greed.Game.Tables, DelphiDoom.Greed.Game.Intf, DelphiDoom.Greed.Game.State,
  DelphiDoom.Greed.Level.Intf;

type
  /// <summary>
  ///   The parts of raven.pas that make a level live around the player, line by line. TimeUpdate is one step of
  ///   the game (the original calls it four times for each frame and from the menus): the weapons charge, the
  ///   sprites think once every 8 tics (after the processes of the script), the spawn areas make items and
  ///   monsters, the elevators move, the bonus item changes place, the door that was bumped is heard. The other
  ///   methods are called by the loop of the game when their flag is set: JamWarps (the warp jammer of the
  ///   inventory), PrepareNexus (the goals are taken: the exit appears next to the player), EndLevel and StartOver
  ///   (the next map, or the same one again), WarpAnim (the lights go down, the player moves, the lights come
  ///   back) and NewGoalItem (the next goal shown by the status bar).
  ///   The globals of the original are the fields of TGreedGameState; drawing, lumps and the loading of a map are
  ///   asked of IGreedLevelHost, the other parts of the tic of IGreedTicParts. The net game is not ported: the
  ///   NetGetData, NetSendPlayerData, NetSendSpawn and NetBonusItem calls, the "if netmode" branches of
  ///   CheckSpawnAreas, NewGoalItem and startover (respawnplayer) and netwarpjammer are not here; neither are
  ///   I_PeekAndDisplatch and I_Sleep at the start of TimeUpdate (the loop of the program does that).
  ///   Kept defects: an area that is not ready yet has its time moved 7000 tics (and the low byte of the clock)
  ///   ahead at every call (the "else" of the original belongs to the test of the time), so an area makes only its
  ///   first thing until a warp jammer resets the times; CheckBonusItem loops until two random numbers give a free
  ///   tile; WarpAnim does not change the tile of the player (mapspot).
  ///   Differences: a spawn area of a kind that the original does not know (2..9, 25..99, over 101) does nothing
  ///   (the original used a variable without a value); a tile outside the map reads 0 and is not written; a bonus
  ///   item whose sprite was not made keeps GREED_POOL_NIL (the original used a nil pointer)
  /// </summary>
  TGreedLevelRules = class
  strict private
    FState: TGreedGameState;
    FSpawner: IGreedSpawner;
    FSound: IGreedGameSound;
    FMessages: IGreedMessages;
    FRandom: IGreedRandom;
    FClock: IGreedSystemClock;
    FParts: IGreedTicParts;
    FHost: IGreedLevelHost;
    function TileValue(APlane: TGreedPlane; ASpot: Integer): Integer;
    procedure ClearMapSprite(ASpot: Integer);
    function ClockRandom: Cardinal;
    function AmmoAreaKind(ANumber: Integer): Integer;
    function HealthAreaKind(ANumber: Integer): Integer;
    function AreaKind(var AArea: TGreedSpawnArea; out AKind: Integer): Boolean;
    function IsGenerator(AKind: Integer): Boolean;
    procedure FillSpawnArea(AIndex: Integer);
    procedure SkipGoalsWithoutItem;
  public
    /// <summary>
    ///   AState has the world, the pools and the globals; ASpawner is SpawnSprite, ASound SoundEffect, AMessages
    ///   writemsg, ARandom MS_RndT, AClock clock, AParts the other parts of a tic, AHost the screen and the maps.
    ///   EArgumentNilException if one is nil
    /// </summary>
    constructor Create(AState: TGreedGameState; const ASpawner: IGreedSpawner; const ASound: IGreedGameSound;
      const AMessages: IGreedMessages; const ARandom: IGreedRandom; const AClock: IGreedSystemClock;
      const AParts: IGreedTicParts; const AHost: IGreedLevelHost);
    /// <summary>chargeweapons: the weapons of the player gain 20 of charge at their rate, up to 100</summary>
    procedure ChargeWeapons;
    /// <summary>CheckSpawnAreas: nothing while a warp jammer is on</summary>
    procedure CheckSpawnAreas;
    /// <summary>CheckBonusItem: when its time is over the bonus item goes to another free tile</summary>
    procedure CheckBonusItem;
    /// <summary>TimeUpdate</summary>
    procedure TimeUpdate;
    /// <summary>NewGoalItem: GoalItem goes to the next goal that the level has (-1 if there is none)</summary>
    procedure NewGoalItem;
    /// <summary>startover(restartvalue): 1 keeps the player as it is (next level), another value starts it again</summary>
    procedure StartOver(ARestartValue: Integer);
    /// <summary>EndLevel: the screen fades, the map number goes up and the level starts</summary>
    procedure EndLevel;
    /// <summary>WarpAnim: one step of the warp that CheckWarps started (Warping 1, 2, 3, then 0)</summary>
    procedure WarpAnim;
    /// <summary>PrepareNexus: the exit on the first free tile around the player</summary>
    procedure PrepareNexus;
    /// <summary>JamWarps: for a minute the generators are gone and the spawn areas are still</summary>
    procedure JamWarps;
  end;

implementation

const
  TILE = GREED_FRACTILEUNIT;
  TIC_RATE = 70;
  LUMP_WARP_LIGHTS = 'WARPLIGHTS';
  LUMP_LIGHTS = 'LIGHTS';
  SNexusCreated = 'Translation Nexus Created!';
  SUsedWarpJammer = 'Used Warp Jammer';

{ TGreedLevelRules }

constructor TGreedLevelRules.Create(AState: TGreedGameState; const ASpawner: IGreedSpawner;
  const ASound: IGreedGameSound; const AMessages: IGreedMessages; const ARandom: IGreedRandom;
  const AClock: IGreedSystemClock; const AParts: IGreedTicParts; const AHost: IGreedLevelHost);
begin
  inherited Create;
  if not Assigned(AState) then
    raise EArgumentNilException.Create('AState');
  if not Assigned(ASpawner) then
    raise EArgumentNilException.Create('ASpawner');
  if not Assigned(ASound) then
    raise EArgumentNilException.Create('ASound');
  if not Assigned(AMessages) then
    raise EArgumentNilException.Create('AMessages');
  if not Assigned(ARandom) then
    raise EArgumentNilException.Create('ARandom');
  if not Assigned(AClock) then
    raise EArgumentNilException.Create('AClock');
  if not Assigned(AParts) then
    raise EArgumentNilException.Create('AParts');
  if not Assigned(AHost) then
    raise EArgumentNilException.Create('AHost');
  FState := AState;
  FSpawner := ASpawner;
  FSound := ASound;
  FMessages := AMessages;
  FRandom := ARandom;
  FClock := AClock;
  FParts := AParts;
  FHost := AHost;
end;

function TGreedLevelRules.TileValue(APlane: TGreedPlane; ASpot: Integer): Integer;
begin
  if (ASpot < 0) or (ASpot >= GREED_MAP_TILES) then
    Result := 0
  else
    Result := FState.World.GetValue(APlane, ASpot);
end;

procedure TGreedLevelRules.ClearMapSprite(ASpot: Integer);
begin
  if (ASpot >= 0) and (ASpot < GREED_MAP_TILES) then
    FState.World.SetValue(gpMapSprites, ASpot, 0);
end;

function TGreedLevelRules.ClockRandom: Cardinal;
begin
  // clock + MS_RndT
  Result := Cardinal(FClock.Clock + FRandom.Next);
end;

procedure TGreedLevelRules.ChargeWeapons;
var
  LSlot, LWeapon, LTime: Integer;
begin
  LTime := FState.TimeCount;
  for LSlot := 0 to 4 do
  begin
    LWeapon := FState.Player.Weapons[LSlot];
    if (LWeapon < Low(FState.Weapons)) or (LWeapon > High(FState.Weapons)) then
      Continue;
    while (FState.Weapons[LWeapon].Charge < 100) and (LTime >= FState.Weapons[LWeapon].ChargeTime) do
    begin
      if FState.Weapons[LWeapon].Charge = 0 then
        FState.Weapons[LWeapon].ChargeTime := FState.TimeCount;
      FState.Weapons[LWeapon].Charge := FState.Weapons[LWeapon].Charge + 20;
      FState.Weapons[LWeapon].ChargeTime := FState.Weapons[LWeapon].ChargeTime +
        FState.Weapons[LWeapon].ChargeRate;
    end;
  end;
end;

function TGreedLevelRules.AmmoAreaKind(ANumber: Integer): Integer;
begin
  if ANumber < 30 then
    Result := GREED_S_ENERGY
  else if ANumber < 60 then
    Result := GREED_S_BALLISTIC
  else if ANumber < 90 then
    Result := GREED_S_PLASMA
  else if ANumber < 96 then
    Result := GREED_S_IGRENADE
  else if ANumber < 98 then
    Result := GREED_S_IREVERSO
  else if ANumber < 102 then
    Result := GREED_S_IPROXMINE
  else if ANumber < 106 then
    Result := GREED_S_ITIMEMINE
  else if ANumber < 108 then
    Result := GREED_S_IINSTAWALL
  else if (ANumber < 110) and not FState.Demo then
    Result := GREED_S_ICLONE
  else if (ANumber < 112) and not FState.Demo then
    Result := GREED_S_IJAMMER
  else if FState.Demo then
    Result := GREED_S_ICLONE
  else
    Result := GREED_S_ISTEALER;
end;

function TGreedLevelRules.HealthAreaKind(ANumber: Integer): Integer;
begin
  if ANumber < 15 then
    Result := GREED_S_MEDPAK1
  else if ANumber < 22 then
    Result := GREED_S_MEDPAK2
  else if ANumber < 30 then
    Result := GREED_S_MEDPAK3
  else if ANumber < 45 then
    Result := GREED_S_MEDPAK4
  else if ANumber < 60 then
    Result := GREED_S_SHIELD4
  else if ANumber < 67 then
    Result := GREED_S_SHIELD3
  else if ANumber < 75 then
    Result := GREED_S_SHIELD2
  else if ANumber < 90 then
    Result := GREED_S_SHIELD1
  else
    // from here the list of the original is the one of the ammunition areas, for the demo and for the game
    Result := AmmoAreaKind(ANumber);
end;

function TGreedLevelRules.AreaKind(var AArea: TGreedSpawnArea; out AKind: Integer): Boolean;
var
  LNumber, LWait: Integer;
  LLow: Integer;
begin
  Result := True;
  AKind := 0;
  case AArea.Kind of
    0, 1:
      begin
        if FState.Demo then
          LNumber := Integer(ClockRandom mod 110)
        else
          LNumber := Integer(ClockRandom mod 114);
        if AArea.Kind = 0 then
          AKind := AmmoAreaKind(LNumber)
        else
          AKind := HealthAreaKind(LNumber);
        LLow := Integer(FClock.Clock and 255);
        AArea.Time := FState.TimeCount + LLow + 3500 - (350 * (FState.Player.Difficulty + 1));
        Exit;
      end;
    10:
      begin
        AKind := GREED_S_MONSTER1;
        LWait := 2100;
      end;
    11:
      begin
        AKind := GREED_S_MONSTER2;
        LWait := 4200;
      end;
    12:
      begin
        AKind := GREED_S_MONSTER3;
        LWait := 2100;
      end;
    13:
      begin
        AKind := GREED_S_MONSTER4;
        LWait := 10500;
      end;
    14:
      begin
        AKind := GREED_S_MONSTER5;
        LWait := 4200;
      end;
    15:
      begin
        AKind := GREED_S_MONSTER6;
        LWait := 4200;
      end;
    16:
      begin
        AKind := GREED_S_MONSTER7;
        LWait := 4200;
      end;
    17:
      begin
        AKind := GREED_S_MONSTER8;
        LWait := 4200;
      end;
    18:
      begin
        AKind := GREED_S_MONSTER9;
        LWait := 4200;
      end;
    19:
      begin
        AKind := GREED_S_MONSTER10;
        LWait := 1200;
      end;
    20:
      begin
        AKind := GREED_S_MONSTER11;
        LWait := 4200;
      end;
    21:
      begin
        AKind := GREED_S_MONSTER12;
        LWait := 4200;
      end;
    22:
      begin
        AKind := GREED_S_MONSTER13;
        LWait := 4200;
      end;
    23:
      begin
        AKind := GREED_S_MONSTER14;
        LWait := 4200;
      end;
    24:
      begin
        AKind := GREED_S_MONSTER15;
        LWait := 4200;
      end;
    100:
      begin
        AKind := GREED_S_MONSTER8_NS;
        LWait := 4200;
      end;
    101:
      begin
        AKind := GREED_S_MONSTER9_NS;
        LWait := 4200;
      end;
  else
    Exit(False);
  end;
  LLow := Integer(FClock.Clock and 255);
  AArea.Time := FState.TimeCount + LLow + (LWait * (FState.Player.Difficulty + 1));
end;

function TGreedLevelRules.IsGenerator(AKind: Integer): Boolean;
begin
  Result := (AKind = GREED_S_GENERATOR) or ((AKind >= GREED_S_GENSTART) and (AKind <= GREED_S_GENEND));
end;

procedure TGreedLevelRules.FillSpawnArea(AIndex: Integer);
var
  LArea: TGreedSpawnArea;
  LKind, LCount, LSprite, LNext: Integer;
  LItem: PGreedSprite;
  LKnown: Boolean;
begin
  LArea := FState.World.GetSpawnArea(AIndex);
  LKnown := AreaKind(LArea, LKind);
  FState.World.SetSpawnArea(AIndex, LArea);
  if not LKnown then
    Exit;

  LCount := 0;
  if LArea.Kind >= 10 then
  begin
    LSprite := FState.Sprites.First;
    while LSprite <> GREED_POOL_NIL do
    begin
      LItem := PGreedSprite(FState.Sprites.Item(LSprite));
      if (LItem^.Kind = LKind) and (LItem^.HitPoints <> 0) then
        Inc(LCount);
      LSprite := FState.Sprites.Next(LSprite);
    end;
  end;

  if LCount < GREED_MAXSPAWN then
  begin
    // the generator that marks the place goes away
    LSprite := FState.Sprites.First;
    while LSprite <> GREED_POOL_NIL do
    begin
      LNext := FState.Sprites.Next(LSprite);
      LItem := PGreedSprite(FState.Sprites.Item(LSprite));
      if IsGenerator(LItem^.Kind) and (LItem^.X = LArea.MapX) and (LItem^.Y = LArea.MapY) then
        FState.Sprites.Remove(LSprite);
      LSprite := LNext;
    end;

    // and one corpse of a monster of this kind
    if LArea.Kind >= 10 then
    begin
      LSprite := FState.Sprites.First;
      while LSprite <> GREED_POOL_NIL do
      begin
        LItem := PGreedSprite(FState.Sprites.Item(LSprite));
        if (LItem^.Kind = LKind) and (LItem^.HitPoints = 0) then
        begin
          FState.Sprites.Remove(LSprite);
          Break;
        end;
        LSprite := FState.Sprites.Next(LSprite);
      end;
    end;

    FSpawner.SpawnSprite(LKind, LArea.MapX, LArea.MapY, 0, 0, 0, 0, True, 0);
    FSpawner.SpawnSprite(GREED_S_WARP, LArea.MapX, LArea.MapY, 0, 0, 0, 0, True, 0);
  end;
end;

procedure TGreedLevelRules.CheckSpawnAreas;
var
  LIndex, LLow: Integer;
  LArea: TGreedSpawnArea;
begin
  if FState.SpecialEffect = GREED_SE_WARPJAMMER then
    Exit;

  for LIndex := 0 to FState.World.SpawnAreaCount - 1 do
  begin
    LArea := FState.World.GetSpawnArea(LIndex);
    if FState.TimeCount >= LArea.Time then
    begin
      if (TileValue(gpMapSprites, LArea.MapSpot) = 0) and (LArea.MapSpot <> FState.Player.MapSpot) then
        FillSpawnArea(LIndex);
    end
    else
    begin
      // as the original: an area that waits is moved further ahead at every call
      LLow := Integer(FClock.Clock and 255);
      LArea.Time := FState.TimeCount + LLow + 7000;
      FState.World.SetSpawnArea(LIndex, LArea);
    end;
  end;
end;

procedure TGreedLevelRules.CheckBonusItem;
var
  LSprite: Integer;
  LClock: Cardinal;
  LX, LY: TGreedFixed;
begin
  if FState.TimeCount > FState.BonusItem.Time then
  begin
    if FState.BonusItem.Score > 0 then
    begin
      LSprite := FState.Sprites.First;
      while LSprite <> GREED_POOL_NIL do
      begin
        if PGreedSprite(FState.Sprites.Item(LSprite))^.Kind = GREED_S_BONUSITEM then
        begin
          FState.Sprites.Remove(LSprite);
          ClearMapSprite(FState.BonusItem.MapSpot);
          Break;
        end;
        LSprite := FState.Sprites.Next(LSprite);
      end;

      FSpawner.SpawnSprite(GREED_S_WARP, (FState.BonusItem.TileX * GREED_MAP_SIZE + 32) * GREED_FRACUNIT,
        (FState.BonusItem.TileY * GREED_MAP_SIZE + 32) * GREED_FRACUNIT, 0, 0, 0, 0, False, 0);
    end;

    repeat
      FState.BonusItem.TileX := Integer(ClockRandom and 63);
      FState.BonusItem.TileY := Integer(ClockRandom and 63);
      FState.BonusItem.MapSpot := FState.BonusItem.TileY * GREED_MAP_SIZE + FState.BonusItem.TileX;
    until (TileValue(gpFloorPic, FState.BonusItem.MapSpot) <> 0) and
      (TileValue(gpMapSprites, FState.BonusItem.MapSpot) = 0) and
      (TileValue(gpMapEffects, FState.BonusItem.MapSpot) and GREED_FL_FLOOR = 0) and
      (TileValue(gpFloorHeight, FState.BonusItem.MapSpot) <> TileValue(gpCeilingHeight, FState.BonusItem.MapSpot));

    LClock := FClock.Clock;
    FState.BonusItem.Score := 2000 + Integer(LClock and 7) * 300;
    FState.BonusItem.Time := FState.TimeCount + FState.BonusTime + Integer(LClock and 1023);
    FState.BonusItem.Num := Integer(LClock mod GREED_MAXRANDOMITEMS);
    FState.BonusItem.Name := TGreedGameTables.RandomItemNames[FState.BonusItem.Num];
    LX := (FState.BonusItem.TileX * GREED_MAP_SIZE + 32) * GREED_FRACUNIT;
    LY := (FState.BonusItem.TileY * GREED_MAP_SIZE + 32) * GREED_FRACUNIT;
    FState.BonusItem.Sprite := FSpawner.SpawnSprite(GREED_S_BONUSITEM, LX, LY, 0, 0, 0, 0, False, 0);
    FSpawner.SpawnSprite(GREED_S_WARP, LX, LY, 0, 0, 0, 0, False, 0);
    if FState.BonusItem.Sprite <> GREED_POOL_NIL then
    begin
      LSprite := FState.BonusItem.Sprite;
      PGreedSprite(FState.Sprites.Item(LSprite))^.BasePic :=
        PGreedSprite(FState.Sprites.Item(LSprite))^.BasePic + FState.BonusItem.Num;
    end;
    FHost.RefreshGoalItem;
    FState.GoalItem := 0;
  end;
end;

procedure TGreedLevelRules.TimeUpdate;
var
  LTime: Integer;
begin
  ChargeWeapons;
  FParts.UpdateInput;
  LTime := FState.TimeCount;
  FParts.UpdateSound;
  while LTime >= FState.SpriteMoveTime do
  begin
    if FState.NumProcesses <> 0 then
      FParts.RunProcesses;
    FParts.ClearTileLights;
    FParts.MoveSprites;
    FState.SpriteMoveTime := FState.SpriteMoveTime + 8;
  end;
  FParts.UpdateInput;
  if FState.World.SpawnAreaCount <> 0 then
    CheckSpawnAreas;
  FParts.CheckElevators;
  CheckBonusItem;
  if FState.DoorSound then
  begin
    FState.DoorSound := False;
    FSound.SoundEffect(GREED_SN_DOOR, 15, FState.DoorX, FState.DoorY);
  end;
  FParts.UpdateInput;
end;

procedure TGreedLevelRules.SkipGoalsWithoutItem;
begin
  if (FState.GoalItem = 0) and (FState.BonusItem.Score = 0) then
    Inc(FState.GoalItem);
  while (FState.GoalItem >= 1) and (FState.GoalItem <= 2) and (FState.Primaries[(FState.GoalItem - 1) * 2] = -1) do
    Inc(FState.GoalItem);
  while (FState.GoalItem >= 3) and (FState.GoalItem <= 9) and
    (FState.Secondaries[(FState.GoalItem - 3) * 2] = -1) do
    Inc(FState.GoalItem);
end;

procedure TGreedLevelRules.NewGoalItem;
begin
  FState.ToggleGoalItem := False;
  Inc(FState.GoalItem);
  SkipGoalsWithoutItem;
  if FState.GoalItem >= 10 then
  begin
    FState.GoalItem := 0;
    SkipGoalsWithoutItem;
    if FState.GoalItem = 10 then
      FState.GoalItem := -1;
  end;
end;

procedure TGreedLevelRules.StartOver(ARestartValue: Integer);
var
  LIndex: Integer;
begin
  FHost.ResetDisplay;
  if ARestartValue <> 1 then
  begin
    FState.Player.Score := 0;
    FState.Player.LevelScore := FState.LevelScore;
    FState.Player.Weapons[2] := -1;
    FState.Player.Weapons[3] := -1;
    FState.Player.Weapons[4] := -1;
    FState.Player.CurrentWeapon := 0;
    FHost.LoadWeapon(FState.Player.Weapons[0]);

    for LIndex := Low(FState.Player.Inventory) to High(FState.Player.Inventory) do
      FState.Player.Inventory[LIndex] := 0;
    FState.Player.Inventory[7] := 2;
    FState.Player.Inventory[5] := 2;
    FState.Player.Inventory[4] := 2;
    FState.Player.Inventory[2] := 4;
    FState.Player.BodyCount := 0;
    FState.Player.Ammo[0] := 100;
    FState.Player.Ammo[1] := 100;
    FState.Player.Ammo[2] := 100;
    FState.Player.Angst := FState.Player.MaxAngst;
    FState.Player.Shield := 200;
  end;
  FState.Player.HoloPic := 0;

  FHost.NewMap(FState.Player.Map, ARestartValue);

  FState.ExitExists := False;
  FState.SpecialEffectTime := 0;
  FState.ExitLevel := False;
  FState.TurnRate := 0;
  FState.MoveRate := 0;
  FState.FallRate := 0;
  FState.StrafRate := 0;
  FState.DeadRestart := False;
  FState.Player.Primaries[0] := 0;
  FState.Player.Primaries[1] := 0;
  for LIndex := 0 to 6 do
    FState.Player.Secondaries[LIndex] := 0;
end;

procedure TGreedLevelRules.EndLevel;
begin
  FHost.FadeOutLevel;
  Inc(FState.Player.Map);
  StartOver(1);
end;

procedure TGreedLevelRules.WarpAnim;
begin
  if FState.Warping = 1 then
  begin
    FHost.LoadColorMaps(LUMP_WARP_LIGHTS);
    FState.Warping := 2;
  end
  else if FState.Warping = 2 then
  begin
    if FState.Lighting >= 128 then
      FState.ChangeLight := -128
    else
    begin
      FState.Warping := 3;
      FState.Player.X := FState.WarpX;
      FState.Player.Y := FState.WarpY;
    end;
  end
  else if FState.Warping = 3 then
  begin
    if FState.Lighting < FHost.GetAmbientLight then
      FState.ChangeLight := 128
    else
    begin
      FHost.LoadColorMaps(LUMP_LIGHTS);
      FState.Warping := 0;
    end;
  end;
end;

procedure TGreedLevelRules.PrepareNexus;
var
  LRow, LColumn, LMapSpot, LX, LY: Integer;
begin
  LRow := -GREED_MAP_SIZE;
  while LRow <= GREED_MAP_SIZE do
  begin
    for LColumn := -1 to 1 do
    begin
      LMapSpot := FState.Player.MapSpot + LRow + LColumn;
      if (LMapSpot <> FState.Player.MapSpot) and (TileValue(gpFloorPic, LMapSpot) <> 0) and
        (TileValue(gpMapSprites, LMapSpot) = 0) then
      begin
        LX := (LMapSpot and 63) * GREED_MAP_SIZE + 32;
        LY := (LMapSpot div 64) * GREED_MAP_SIZE + 32;
        FSpawner.SpawnSprite(GREED_S_EXIT, LX * GREED_FRACUNIT, LY * GREED_FRACUNIT, 0, 0, 0, 0, False, 0);
        FSound.SoundEffect(GREED_SN_NEXUS, 0, LX * GREED_FRACUNIT, LY * GREED_FRACUNIT);
        FSound.SoundEffect(GREED_SN_NEXUS, 0, LX * GREED_FRACUNIT, LY * GREED_FRACUNIT);
        FState.ExitExists := True;
        FMessages.WriteMessage(SNexusCreated);
        Exit;
      end;
    end;
    LRow := LRow + GREED_MAP_SIZE;
  end;
end;

procedure TGreedLevelRules.JamWarps;
var
  LSprite, LNext, LMapSpot, LIndex: Integer;
  LItem: PGreedSprite;
  LArea: TGreedSpawnArea;
begin
  if FState.SpecialEffect <> GREED_SE_WARPJAMMER then
  begin
    FState.SpecialEffect := GREED_SE_WARPJAMMER;
    FState.SpecialEffectTime := FState.TimeCount + TIC_RATE * 60;
    FHost.SetTotalEffectTime(TIC_RATE * 60);
    Dec(FState.Player.Inventory[11]);

    LSprite := FState.Sprites.First;
    while LSprite <> GREED_POOL_NIL do
    begin
      LNext := FState.Sprites.Next(LSprite);
      LItem := PGreedSprite(FState.Sprites.Item(LSprite));
      if IsGenerator(LItem^.Kind) then
      begin
        LMapSpot := (LItem^.Y div TILE) * GREED_MAP_SIZE + (LItem^.X div TILE);
        ClearMapSprite(LMapSpot);
        FState.Sprites.Remove(LSprite);
      end;
      LSprite := LNext;
    end;

    for LIndex := 0 to FState.World.SpawnAreaCount - 1 do
    begin
      LArea := FState.World.GetSpawnArea(LIndex);
      LArea.Time := FState.TimeCount;
      FState.World.SetSpawnArea(LIndex, LArea);
    end;

    FMessages.WriteMessage(SUsedWarpJammer);
  end;
  FState.WarpJammer := False;
end;

end.
