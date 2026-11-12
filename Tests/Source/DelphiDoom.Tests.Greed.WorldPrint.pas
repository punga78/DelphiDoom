{******************************************************************************}
{                                                                              }
{  DelphiDoom: the fingerprint of the whole world of a game of Greed            }
{                                                                              }
{  The same unit is compiled in the harness of the original (Tools\Verifica\    }
{  175-world) and in the tests of the library: each side copies its state in    }
{  the records of the library and this unit turns them into numbers, always     }
{  in the same order. With a list of lines it writes every value by name, to    }
{  find the field of a difference                                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.WorldPrint;

// FNV-1a wraps on purpose
{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Greed.Types, DelphiDoom.Greed.SaveTypes,
  DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.Game.State,
  DelphiDoom.Greed.Game.Tables;

type
  /// <summary>The parts of the world, each with its own fingerprint</summary>
  TWorldSection = (wsPlayer, wsSprites, wsElevators, wsDoors, wsAreas, wsPlanes, wsEvents, wsGlobals, wsSounds);
  TWorldHashes = array[TWorldSection] of Cardinal;

  /// <summary>The globals of the game that are not in a record of the library, by name</summary>
  TWorldGlobals = record
    RandomOffset: Integer;
    TimeCount, Frames, WeapDelay, SpriteMoveTime, SecretDelay, InventoryDelay, UseDelay, JumpDelay: Integer;
    KeyboardDelay, RearViewTime, RearViewDelay, InventoryTime: Integer;
    ChangingWeapons, WeaponLowering, QuitGame, HeatMode, GodMode, MotionMode, HurtBorder, DoorSound: Boolean;
    DeadRestart, ExitLevel, ExitExists, WarpJammer, AutoRun, RearViewOn, CheckTrigger, UseItem: Boolean;
    GoIRight, GoILeft, MidgetMode, AutoTarget, ToggleGoalItem: Boolean;
    WeapMode, NewWeapon, WeaponYChange, HeadBob, WeapBob, ChangeLight, Lighting, TurnRate, MapMode: Integer;
    ScrollView, DoorX, DoorY, Warping, GoalItem, SpecialEffect, FallDamage, WallAnimCount, SongNum: Integer;
    MoveRate, StrafRate, FallRate, WarpX, WarpY: Integer;
    WallAnimationTime, SpecialEffectTime, SwitchTime, PlayerAngle64: Integer;
    BonusTime, BonusScore, BonusTileX, BonusTileY, BonusMapSpot, BonusNum: Integer;
    /// <summary>The place of the sprite of the bonus item in the list of the sprites; -1 if it has none</summary>
    BonusSprite: Integer;
    InventoryCursor: Integer;
    FireGrenade: Boolean;
    WarpActive: Integer;
    BloodCount, MetalCount: Integer;
    MouseDX, MouseDY: Integer;
    WeaponCharge, WeaponChargeTime: array[0..18] of Integer;
  end;

  /// <summary>The script of the map as the game keeps it (event.pas and the goals of utils.pas)</summary>
  TWorldEvents = record
    Triggers, Switches: TGreedTileBytes;
    Processes: array[0..GREED_MAX_PROCESSES - 1] of Integer;
    NumProcesses, NumZones, FliPlayed: Integer;
    Zones: array[0..GREED_MAX_ZONES - 1] of TGreedZone;
    Primaries: array[0..3] of Integer;
    Secondaries: array[0..13] of Integer;
    PCount: array[0..1] of Integer;
    SCount: array[0..6] of Integer;
    BonusTime, LevelScore: Integer;
  end;

  /// <summary>
  ///   FNV-1a of 32 bits over the values that it is given, a part of the world at a time. Sounds is not a state:
  ///   every sound of the game is added to it and it is never started again
  /// </summary>
  TWorldPrint = class
  strict private
    FHashes: TWorldHashes;
    FSection: TWorldSection;
    FLines: TStrings;
    FPrefix: string;
    procedure AddByte(AValue: Byte);
  public
    constructor Create;
    /// <summary>The sections that are a state start again; the sounds go on</summary>
    procedure StartFrame;
    procedure Select(ASection: TWorldSection);
    procedure Int(const AName: string; AValue: Integer);
    procedure Bool(const AName: string; AValue: Boolean);
    /// <summary>A block of bytes: in the lines its own fingerprint</summary>
    procedure Block(const AName: string; AData: Pointer; ACount: Integer);
    procedure Text(const AName, AValue: string);
    // ---- the records of the library ----
    procedure Player(const APlayer: TGreedPlayerRecord);
    procedure Sprite(AIndex: Integer; const ASprite: TGreedSprite);
    procedure Elevator(AIndex: Integer; const AElevator: TGreedElevator);
    procedure Door(AIndex: Integer; const ADoor: TGreedDoor);
    procedure Area(AIndex: Integer; const AArea: TGreedSpawnArea);
    procedure Events(const AEvents: TWorldEvents);
    procedure Globals(const AGlobals: TWorldGlobals);
    /// <summary>SoundEffect(n, variation, x, y)</summary>
    procedure Sound(ASound, AVariation, AX, AY: Integer);
    /// <summary>PlaySong(name) and StopMusic (an empty name)</summary>
    procedure Song(const AName: string);
    /// <summary>The fingerprint of all the sections together</summary>
    function Total: Cardinal;
    /// <summary>The nine fingerprints as text: total, then a section each</summary>
    function Line: string;
    property Hashes: TWorldHashes read FHashes;
    /// <summary>nil (the default): only the fingerprints. With a list every value is also written as name=value</summary>
    property Lines: TStrings read FLines write FLines;
  end;

const
  WORLD_SECTION_NAMES: array[TWorldSection] of string = ('player', 'sprites', 'elevators', 'doors', 'areas',
    'planes', 'events', 'globals', 'sounds');

implementation

const
  FNV_OFFSET = 2166136261;
  FNV_PRIME = 16777619;

function FnvOf(AData: PByte; ACount: Integer): Cardinal;
var
  LIndex: Integer;
begin
  Result := FNV_OFFSET;
  for LIndex := 0 to ACount - 1 do
  begin
    Result := (Result xor AData^) * FNV_PRIME;
    Inc(AData);
  end;
end;

{ TWorldPrint }

constructor TWorldPrint.Create;
var
  LSection: TWorldSection;
begin
  inherited Create;
  for LSection := Low(TWorldSection) to High(TWorldSection) do
    FHashes[LSection] := FNV_OFFSET;
end;

procedure TWorldPrint.StartFrame;
var
  LSection: TWorldSection;
begin
  for LSection := Low(TWorldSection) to High(TWorldSection) do
    if LSection <> wsSounds then
      FHashes[LSection] := FNV_OFFSET;
end;

procedure TWorldPrint.Select(ASection: TWorldSection);
begin
  FSection := ASection;
  FPrefix := WORLD_SECTION_NAMES[ASection] + '.';
end;

procedure TWorldPrint.AddByte(AValue: Byte);
begin
  FHashes[FSection] := (FHashes[FSection] xor AValue) * FNV_PRIME;
end;

procedure TWorldPrint.Int(const AName: string; AValue: Integer);
begin
  AddByte(Byte(AValue));
  AddByte(Byte(AValue shr 8));
  AddByte(Byte(AValue shr 16));
  AddByte(Byte(AValue shr 24));
  if Assigned(FLines) then
    FLines.Add(FPrefix + AName + '=' + IntToStr(AValue));
end;

procedure TWorldPrint.Bool(const AName: string; AValue: Boolean);
begin
  // any value that is not zero is true (bool of the original is a 4 byte integer)
  if AValue then
    Int(AName, 1)
  else
    Int(AName, 0);
end;

procedure TWorldPrint.Block(const AName: string; AData: Pointer; ACount: Integer);
var
  LIndex: Integer;
  LByte: PByte;
  LRow: string;
begin
  LByte := AData;
  for LIndex := 0 to ACount - 1 do
  begin
    AddByte(LByte^);
    Inc(LByte);
  end;
  if Assigned(FLines) then
  begin
    FLines.Add(FPrefix + AName + '=#' + IntToHex(FnvOf(AData, ACount), 8));
    // and the bytes that are not zero, a row of 64 at a time, to see which tile differs
    LByte := AData;
    LRow := '';
    for LIndex := 0 to ACount - 1 do
    begin
      if LByte^ <> 0 then
        LRow := LRow + ' ' + IntToStr(LIndex mod 64) + ':' + IntToStr(LByte^);
      Inc(LByte);
      if (LIndex mod 64 = 63) or (LIndex = ACount - 1) then
      begin
        if LRow <> '' then
          FLines.Add(FPrefix + AName + '.row' + IntToStr(LIndex div 64) + '=' + LRow);
        LRow := '';
      end;
    end;
  end;
end;

procedure TWorldPrint.Text(const AName, AValue: string);
var
  LIndex: Integer;
begin
  for LIndex := 1 to Length(AValue) do
    AddByte(Byte(Ord(AValue[LIndex])));
  AddByte(0);
  if Assigned(FLines) then
    FLines.Add(FPrefix + AName + '=' + AValue);
end;

procedure TWorldPrint.Player(const APlayer: TGreedPlayerRecord);
var
  LIndex: Integer;
begin
  Select(wsPlayer);
  Int('x', APlayer.X);
  Int('y', APlayer.Y);
  Int('z', APlayer.Z);
  Int('mapspot', APlayer.MapSpot);
  Int('angle', APlayer.Angle);
  Int('height', APlayer.Height);
  Int('currentweapon', APlayer.CurrentWeapon);
  Int('shield', APlayer.Shield);
  Int('angst', APlayer.Angst);
  Int('maxshield', APlayer.MaxShield);
  Int('maxangst', APlayer.MaxAngst);
  Int('map', APlayer.Map);
  Int('mission', APlayer.Mission);
  Int('chartype', APlayer.CharType);
  Int('levelscore', APlayer.LevelScore);
  Int('difficulty', APlayer.Difficulty);
  for LIndex := Low(APlayer.Weapons) to High(APlayer.Weapons) do
    Int('weapons' + IntToStr(LIndex), APlayer.Weapons[LIndex]);
  for LIndex := Low(APlayer.Ammo) to High(APlayer.Ammo) do
    Int('ammo' + IntToStr(LIndex), APlayer.Ammo[LIndex]);
  Int('bodycount', APlayer.BodyCount);
  Int('timecount', APlayer.TimeCount);
  Int('score', APlayer.Score);
  Block('northmap', @APlayer.NorthMap[0], SizeOf(APlayer.NorthMap));
  Block('westmap', @APlayer.WestMap[0], SizeOf(APlayer.WestMap));
  Block('northwall', @APlayer.NorthWall[0], SizeOf(APlayer.NorthWall));
  Block('westwall', @APlayer.WestWall[0], SizeOf(APlayer.WestWall));
  Block('savesprites', @APlayer.SaveSprites[0], SizeOf(APlayer.SaveSprites));
  Int('scrollmin', APlayer.ScrollMin);
  Int('scrollmax', APlayer.ScrollMax);
  for LIndex := Low(APlayer.Primaries) to High(APlayer.Primaries) do
    Int('primaries' + IntToStr(LIndex), APlayer.Primaries[LIndex]);
  for LIndex := Low(APlayer.Secondaries) to High(APlayer.Secondaries) do
    Int('secondaries' + IntToStr(LIndex), APlayer.Secondaries[LIndex]);
  for LIndex := Low(APlayer.Frags) to High(APlayer.Frags) do
    Int('frags' + IntToStr(LIndex), APlayer.Frags[LIndex]);
  Int('runmod', APlayer.RunMod);
  Int('walkmod', APlayer.WalkMod);
  for LIndex := Low(APlayer.Inventory) to High(APlayer.Inventory) do
    Int('inventory' + IntToStr(LIndex), APlayer.Inventory[LIndex]);
  Int('status', APlayer.Status);
  Int('holopic', APlayer.HoloPic);
  Int('holoscale', APlayer.HoloScale);
  Int('jumpmod', APlayer.JumpMod);
  Block('events', @APlayer.Events[0], SizeOf(APlayer.Events));
end;

procedure TWorldPrint.Sprite(AIndex: Integer; const ASprite: TGreedSprite);
begin
  FSection := wsSprites;
  FPrefix := 'sprite' + IntToStr(AIndex) + '.';
  Int('typ', ASprite.Kind);
  Int('x', ASprite.X);
  Int('y', ASprite.Y);
  Int('z', ASprite.Z);
  Int('animation', ASprite.Animation);
  Int('animationtime', ASprite.AnimationTime);
  Int('movespeed', ASprite.MoveSpeed);
  Int('zadj', ASprite.ZAdjust);
  Int('lastx', ASprite.LastX);
  Int('lasty', ASprite.LastY);
  Int('basepic', ASprite.BasePic);
  Int('rotate', Ord(ASprite.Rotate));
  Int('angle', ASprite.Angle);
  Int('angle2', ASprite.Angle2);
  Int('movesize', ASprite.MoveSize);
  Bool('active', ASprite.Active);
  Bool('nofalling', ASprite.NoFalling);
  Int('intelligence', ASprite.Intelligence);
  Int('bullet', ASprite.Bullet);
  Int('enraged', ASprite.Enraged);
  Int('movetime', ASprite.MoveTime);
  Int('modetime', ASprite.ModeTime);
  Int('actiontime', ASprite.ActionTime);
  Int('scantime', ASprite.ScanTime);
  Int('firetime', ASprite.FireTime);
  Int('heat', ASprite.Heat);
  Int('startpic', ASprite.StartPic);
  Int('movemode', ASprite.MoveMode);
  Int('startspot', ASprite.StartSpot);
  Int('damage', ASprite.Damage);
  Int('hitpoints', ASprite.HitPoints);
  Int('spawnid', ASprite.SpawnId);
  Int('score', ASprite.Score);
  Int('maxmove', ASprite.MaxMove);
  Int('regen', ASprite.Regen);
  Int('deathevent', ASprite.DeathEvent);
  Int('height', ASprite.Height);
  Int('specialtype', Ord(ASprite.SpecialType));
  Int('scale', ASprite.Scale);
  Int('oldx', ASprite.OldX);
  Int('oldy', ASprite.OldY);
  Int('oldz', ASprite.OldZ);
  Int('oldangle', ASprite.OldAngle);
  Int('oldangle2', ASprite.OldAngle2);
  Int('oldfloorz', ASprite.OldFloorZ);
  Int('newx', ASprite.NewX);
  Int('newy', ASprite.NewY);
  Int('newz', ASprite.NewZ);
  Int('newangle', ASprite.NewAngle);
  Int('newangle2', ASprite.NewAngle2);
  Int('newfloorz', ASprite.NewFloorZ);
  Bool('grounded', ASprite.Grounded);
end;

procedure TWorldPrint.Elevator(AIndex: Integer; const AElevator: TGreedElevator);
begin
  FSection := wsElevators;
  FPrefix := 'elevator' + IntToStr(AIndex) + '.';
  Bool('up', AElevator.Up);
  Bool('down', AElevator.Down);
  Int('position', AElevator.Position);
  Int('position64', AElevator.Position64);
  Int('timer', AElevator.Timer);
  Int('floor', AElevator.Floor);
  Int('ceiling', AElevator.Ceiling);
  Int('mapspot', AElevator.MapSpot);
  Int('speed', AElevator.Speed);
  Int('eval', AElevator.Eval);
  Int('endeval', AElevator.EndEval);
  Int('nosave', AElevator.NoSave);
  Int('typ', Ord(AElevator.Kind));
end;

procedure TWorldPrint.Door(AIndex: Integer; const ADoor: TGreedDoor);
begin
  FSection := wsDoors;
  FPrefix := 'door' + IntToStr(AIndex) + '.';
  Int('tilex', ADoor.TileX);
  Int('tiley', ADoor.TileY);
  Bool('open', ADoor.Open);
  Bool('opening', ADoor.Opening);
  Bool('closing', ADoor.Closing);
  Bool('blocked', ADoor.Blocked);
  Bool('bumpable', ADoor.Bumpable);
  Int('size', ADoor.Size);
  Int('timer', ADoor.Timer);
  Int('locks', ADoor.Locks);
  Int('orientation', Ord(ADoor.Orientation));
  Bool('transparent', ADoor.Transparent);
  Int('pic', ADoor.Pic);
  Int('height', ADoor.Height);
  Int('position', ADoor.Position);
end;

procedure TWorldPrint.Area(AIndex: Integer; const AArea: TGreedSpawnArea);
begin
  FSection := wsAreas;
  FPrefix := 'area' + IntToStr(AIndex) + '.';
  Int('mapspot', AArea.MapSpot);
  Int('mapx', AArea.MapX);
  Int('mapy', AArea.MapY);
  Int('typ', AArea.Kind);
  Int('time', AArea.Time);
end;

procedure TWorldPrint.Events(const AEvents: TWorldEvents);
var
  LIndex: Integer;
begin
  Select(wsEvents);
  Block('triggers', @AEvents.Triggers[0], SizeOf(AEvents.Triggers));
  Block('switches', @AEvents.Switches[0], SizeOf(AEvents.Switches));
  Int('numprocesses', AEvents.NumProcesses);
  for LIndex := 0 to AEvents.NumProcesses - 1 do
    if LIndex <= High(AEvents.Processes) then
      Int('process' + IntToStr(LIndex), AEvents.Processes[LIndex]);
  Int('numzones', AEvents.NumZones);
  Int('fliplayed', AEvents.FliPlayed);
  for LIndex := 0 to AEvents.NumZones - 1 do
    if LIndex <= High(AEvents.Zones) then
    begin
      FPrefix := 'zone' + IntToStr(LIndex) + '.';
      Int('x1', AEvents.Zones[LIndex].X1);
      Int('y1', AEvents.Zones[LIndex].Y1);
      Int('x2', AEvents.Zones[LIndex].X2);
      Int('y2', AEvents.Zones[LIndex].Y2);
      Int('eval', AEvents.Zones[LIndex].Eval);
      Int('endeval', AEvents.Zones[LIndex].EndEval);
      Int('rate', AEvents.Zones[LIndex].Rate);
      Int('layer', AEvents.Zones[LIndex].Layer);
      Int('newvalue', AEvents.Zones[LIndex].NewValue);
      Int('stype', AEvents.Zones[LIndex].SType);
      Int('removeable', AEvents.Zones[LIndex].Removeable);
      Int('typ', AEvents.Zones[LIndex].Kind);
    end;
  FPrefix := 'events.';
  for LIndex := Low(AEvents.Primaries) to High(AEvents.Primaries) do
    Int('primaries' + IntToStr(LIndex), AEvents.Primaries[LIndex]);
  for LIndex := Low(AEvents.Secondaries) to High(AEvents.Secondaries) do
    Int('secondaries' + IntToStr(LIndex), AEvents.Secondaries[LIndex]);
  for LIndex := Low(AEvents.PCount) to High(AEvents.PCount) do
    Int('pcount' + IntToStr(LIndex), AEvents.PCount[LIndex]);
  for LIndex := Low(AEvents.SCount) to High(AEvents.SCount) do
    Int('scount' + IntToStr(LIndex), AEvents.SCount[LIndex]);
  Int('bonustime', AEvents.BonusTime);
  Int('levelscore', AEvents.LevelScore);
end;

procedure TWorldPrint.Globals(const AGlobals: TWorldGlobals);
var
  LIndex: Integer;
begin
  Select(wsGlobals);
  Int('rndofs', AGlobals.RandomOffset);
  Int('timecount', AGlobals.TimeCount);
  Int('frames', AGlobals.Frames);
  Int('weapdelay', AGlobals.WeapDelay);
  Int('spritemovetime', AGlobals.SpriteMoveTime);
  Int('secretdelay', AGlobals.SecretDelay);
  Int('inventorydelay', AGlobals.InventoryDelay);
  Int('usedelay', AGlobals.UseDelay);
  Int('jumpdelay', AGlobals.JumpDelay);
  Int('keyboarddelay', AGlobals.KeyboardDelay);
  Int('rearviewtime', AGlobals.RearViewTime);
  Int('rearviewdelay', AGlobals.RearViewDelay);
  Int('inventorytime', AGlobals.InventoryTime);
  Bool('changingweapons', AGlobals.ChangingWeapons);
  Bool('weaponlowering', AGlobals.WeaponLowering);
  Bool('quitgame', AGlobals.QuitGame);
  Bool('heatmode', AGlobals.HeatMode);
  Bool('godmode', AGlobals.GodMode);
  Bool('motionmode', AGlobals.MotionMode);
  Bool('hurtborder', AGlobals.HurtBorder);
  Bool('doorsound', AGlobals.DoorSound);
  Bool('deadrestart', AGlobals.DeadRestart);
  Bool('exitlevel', AGlobals.ExitLevel);
  Bool('exitexists', AGlobals.ExitExists);
  Bool('warpjammer', AGlobals.WarpJammer);
  Bool('autorun', AGlobals.AutoRun);
  Bool('rearviewon', AGlobals.RearViewOn);
  Bool('checktrigger', AGlobals.CheckTrigger);
  Bool('useitem', AGlobals.UseItem);
  Bool('goiright', AGlobals.GoIRight);
  Bool('goileft', AGlobals.GoILeft);
  Bool('midgetmode', AGlobals.MidgetMode);
  Bool('autotarget', AGlobals.AutoTarget);
  Bool('togglegoalitem', AGlobals.ToggleGoalItem);
  Int('weapmode', AGlobals.WeapMode);
  Int('newweapon', AGlobals.NewWeapon);
  Int('weaponychange', AGlobals.WeaponYChange);
  Int('headbob', AGlobals.HeadBob);
  Int('weapbob', AGlobals.WeapBob);
  Int('changelight', AGlobals.ChangeLight);
  Int('lighting', AGlobals.Lighting);
  Int('turnrate', AGlobals.TurnRate);
  Int('mapmode', AGlobals.MapMode);
  Int('scrollview', AGlobals.ScrollView);
  Int('doorx', AGlobals.DoorX);
  Int('doory', AGlobals.DoorY);
  Int('warping', AGlobals.Warping);
  Int('goalitem', AGlobals.GoalItem);
  Int('specialeffect', AGlobals.SpecialEffect);
  Int('falldamage', AGlobals.FallDamage);
  Int('wallanimcount', AGlobals.WallAnimCount);
  Int('songnum', AGlobals.SongNum);
  Int('moverate', AGlobals.MoveRate);
  Int('strafrate', AGlobals.StrafRate);
  Int('fallrate', AGlobals.FallRate);
  Int('warpx', AGlobals.WarpX);
  Int('warpy', AGlobals.WarpY);
  Int('wallanimationtime', AGlobals.WallAnimationTime);
  Int('specialeffecttime', AGlobals.SpecialEffectTime);
  Int('switchtime', AGlobals.SwitchTime);
  Int('playerangle64', AGlobals.PlayerAngle64);
  Int('bonus.time', AGlobals.BonusTime);
  Int('bonus.score', AGlobals.BonusScore);
  Int('bonus.tilex', AGlobals.BonusTileX);
  Int('bonus.tiley', AGlobals.BonusTileY);
  Int('bonus.mapspot', AGlobals.BonusMapSpot);
  Int('bonus.num', AGlobals.BonusNum);
  Int('bonus.sprite', AGlobals.BonusSprite);
  Int('inventorycursor', AGlobals.InventoryCursor);
  Bool('firegrenade', AGlobals.FireGrenade);
  Int('warpactive', AGlobals.WarpActive);
  Int('bloodcount', AGlobals.BloodCount);
  Int('metalcount', AGlobals.MetalCount);
  Int('mousedx', AGlobals.MouseDX);
  Int('mousedy', AGlobals.MouseDY);
  for LIndex := Low(AGlobals.WeaponCharge) to High(AGlobals.WeaponCharge) do
  begin
    Int('weapon' + IntToStr(LIndex) + '.charge', AGlobals.WeaponCharge[LIndex]);
    Int('weapon' + IntToStr(LIndex) + '.chargetime', AGlobals.WeaponChargeTime[LIndex]);
  end;
end;

procedure TWorldPrint.Sound(ASound, AVariation, AX, AY: Integer);
var
  LLines: TStrings;
begin
  // the sounds are counted as they happen, not when the state is written
  LLines := FLines;
  FLines := nil;
  FSection := wsSounds;
  Int('n', ASound);
  Int('variation', AVariation);
  Int('x', AX);
  Int('y', AY);
  FLines := LLines;
end;

procedure TWorldPrint.Song(const AName: string);
var
  LLines: TStrings;
begin
  LLines := FLines;
  FLines := nil;
  FSection := wsSounds;
  Text('song', UpperCase(AName));
  FLines := LLines;
end;

function TWorldPrint.Total: Cardinal;
var
  LSection: TWorldSection;
begin
  Result := FNV_OFFSET;
  for LSection := Low(TWorldSection) to High(TWorldSection) do
  begin
    Result := (Result xor (FHashes[LSection] and $FF)) * FNV_PRIME;
    Result := (Result xor ((FHashes[LSection] shr 8) and $FF)) * FNV_PRIME;
    Result := (Result xor ((FHashes[LSection] shr 16) and $FF)) * FNV_PRIME;
    Result := (Result xor (FHashes[LSection] shr 24)) * FNV_PRIME;
  end;
end;

function TWorldPrint.Line: string;
var
  LSection: TWorldSection;
begin
  Result := IntToHex(Total, 8);
  for LSection := Low(TWorldSection) to High(TWorldSection) do
    Result := Result + ' ' + IntToHex(FHashes[LSection], 8);
end;

end.
