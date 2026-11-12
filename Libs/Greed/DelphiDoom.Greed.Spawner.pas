{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the birth of everything that is on a map         }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): SpawnSprite and             }
{  DemandLoadMonster of spawn.pas                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Spawner;

// the positions are 16.16 fixed point numbers: the arithmetic wraps as in the original
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf, DelphiDoom.Greed.Actor.Types,
  DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.Random,
  DelphiDoom.Greed.Game.Constants, DelphiDoom.Greed.Game.Tables, DelphiDoom.Greed.Game.Intf,
  DelphiDoom.Greed.Game.State, DelphiDoom.Greed.Spawner.Intf;

const
  /// <summary>MAXBLOODSPRITES of r_public.pas and MAXMETALPARTS of spawn.pas</summary>
  GREED_MAX_BLOOD_SPRITES = 200;
  GREED_MAX_METAL_PARTS = 100;
  /// <summary>The timer of an elevator that waits for a switch</summary>
  GREED_ELEVATOR_PAUSED = $70000000;

type
  /// <summary>The arguments of one SpawnSprite and the tile they fall on</summary>
  TGreedSpawnRequest = record
    Value: Integer;
    X, Y, Z, ZAdjust: TGreedFixed;
    Angle, Angle2: Integer;
    Active: Boolean;
    SpawnId: Integer;
    TileX, TileY, MapSpot: Integer;
  end;

  /// <summary>
  ///   SpawnSprite of spawn.pas, line by line: a value of the plane of the sprites of a map (or one of the values
  ///   that the game uses for what is born while playing) makes a sprite in the pool, an elevator, a door, a spawn
  ///   area, or only marks the tile. The globals of the original are the fields of TGreedGameState; the three that
  ///   are not there are properties of this class: BloodCount and MetalCount (r_public.pas, zeroed by RF_ClearWorld:
  ///   call ResetCounts when the world is cleared) and Violence (SC.violence). The net game is not ported: the
  ///   NetSendSpawn calls of the original are not here and the start places of the other players only fill
  ///   StartLocations. A value that the original does not know does nothing and gives GREED_POOL_NIL.
  ///   Kept defects of the original: MetalCount never goes down; S_ELEVATORHIGH leaves Position64 at zero; a
  ///   generator gives GREED_POOL_NIL although it makes the sprite of the generator; the picture of a door is
  ///   relative to the lump startwalls. Differences: a tile outside the map reads 0 and cannot be written
  ///   (EGreedDataException, the original used the memory near the arrays); a decoy or a clone of a character that
  ///   does not exist is EGreedException (the original read past charnames); a full pool or list is EGreedException
  ///   (MS_Error)
  /// </summary>
  TGreedSpawner = class(TInterfacedObject, IGreedSpawner)
  strict private
    FState: TGreedGameState;
    FArchive: IGreedArchive;
    FRandom: IGreedRandom;
    FSound: IGreedGameSound;
    FPictures: IGreedSpritePictures;
    FBloodCount: Integer;
    FMetalCount: Integer;
    FViolence: Boolean;
    function AddSprite(out ASprite: PGreedSprite): Integer;
    function SpriteLump(AValue: Integer): Integer;
    function FloorZ(AX, AY: TGreedFixed): TGreedFixed;
    function CeilingZ(AX, AY: TGreedFixed): TGreedFixed;
    function Floor(ASpot: Integer): Integer;
    function Ceiling(ASpot: Integer): Integer;
    procedure SetMapSprite(ASpot, AValue: Integer);
    function CharacterLump(ASpawnId: Integer): Integer;
    procedure RemoveFirstOfKind(AKind: Integer; var ACount: Integer; ADecrement: Boolean);
    function SpawnBlood(const ARequest: TGreedSpawnRequest): Integer;
    function SpawnPuff(const ARequest: TGreedSpawnRequest): Integer;
    function SpawnShot(const ARequest: TGreedSpawnRequest): Integer;
    function SpawnMonsterShot(const ARequest: TGreedSpawnRequest): Integer;
    function SpawnMetalParts(const ARequest: TGreedSpawnRequest): Integer;
    function SpawnDevice(const ARequest: TGreedSpawnRequest): Integer;
    function SpawnMonster(const ARequest: TGreedSpawnRequest; ANumber: Integer; ANoFalling: Boolean): Integer;
    function SpawnCorpse(const ARequest: TGreedSpawnRequest): Integer;
    function SpawnHangingItem(const ARequest: TGreedSpawnRequest; ADrop: Integer): Integer;
    function SpawnPickup(const ARequest: TGreedSpawnRequest): Integer;
    procedure SpawnPlayerStart(const ARequest: TGreedSpawnRequest);
    procedure SpawnDoor(const ARequest: TGreedSpawnRequest);
    procedure SpawnElevator(const ARequest: TGreedSpawnRequest);
    procedure SpawnArea(const ARequest: TGreedSpawnRequest; AKind: Integer);
    function SpawnExit(const ARequest: TGreedSpawnRequest): Integer;
    function SpawnByValue(const ARequest: TGreedSpawnRequest): Integer;
  public
    /// <summary>
    ///   AState has the world, the pools and the globals of the game; AArchive gives the numbers of the lumps
    ///   (CA_GetNamedNum), ARandom is MS_RndT, ASound is SoundEffect, APictures is told which pictures a monster
    ///   needs (DemandLoadMonster). EArgumentNilException if one is nil
    /// </summary>
    constructor Create(AState: TGreedGameState; const AArchive: IGreedArchive; const ARandom: IGreedRandom;
      const ASound: IGreedGameSound; const APictures: IGreedSpritePictures);
    function SpawnSprite(AValue: Integer; AX, AY, AZ, AZAdjust: TGreedFixed; AAngle, AAngle2: Integer;
      AActive: Boolean; ASpawnId: Integer): Integer;
    procedure DemandLoadMonster(ALump, ACount: Integer);
    /// <summary>bloodcount := 0 and metalcount := 0 of RF_ClearWorld</summary>
    procedure ResetCounts;
    /// <summary>bloodcount of r_public.pas: the blood splats that were made and not yet taken away here</summary>
    property BloodCount: Integer read FBloodCount write FBloodCount;
    /// <summary>metalcount of r_public.pas: the metal parts that were made (it never goes down)</summary>
    property MetalCount: Integer read FMetalCount write FMetalCount;
    /// <summary>SC.violence: without it there is no blood on the floor. True as the original starts</summary>
    property Violence: Boolean read FViolence write FViolence;
  end;

implementation

uses
  DelphiDoom.Greed.Terrain;

const
  SInvalidStart = 'Invalid start %d at %d,%d';
  SUnknownCharacter = 'SpawnSprite: the character %d does not exist';

  ANIM_SELF_DESTRUCT = 32768;
  TIC_RATE = 70;
  NORTH = 256;
  LUMP_START_WALLS = 'startwalls';

  /// the animation 1 + (0 shl 1) + (frames shl 5) + (delay shl 9) of the original
  ANIM_LOOP_3_5 = 1 + (3 shl 5) + (5 shl 9);
  ANIM_LOOP_4_10 = 1 + (4 shl 5) + (10 shl 9);

type
  TShotInfo = record
    Value: Integer;
    Speed: Integer;
    SizeUnits: Integer;
    Heat: Integer;
    Damage: Integer;
  end;

  TMonsterShotInfo = record
    Speed: Integer;
    Heat: Integer;
    Damage: Integer;
    Sound: Integer;
  end;

  TMonsterInfo = record
    Value: Integer;
    Speed: Integer;
    Name: string;
    Pictures: Integer;
    SizeUnits: Integer;
    Intelligence: Integer;
    Heat: Integer;
    HitPoints: Integer;
    HeightUnits: Integer;
    Score: Integer;
    Scale: Integer;
  end;

const
  PLAYER_SHOTS: array[0..15] of TShotInfo = (
    (Value: GREED_S_BULLET1; Speed: 500; SizeUnits: 1; Heat: 0; Damage: 35),
    (Value: GREED_S_BULLET2; Speed: 500; SizeUnits: 1; Heat: 40; Damage: 40),
    (Value: GREED_S_BULLET3; Speed: 90; SizeUnits: 1; Heat: 96; Damage: 30),
    (Value: GREED_S_BULLET4; Speed: 100; SizeUnits: 4; Heat: 112; Damage: 50),
    (Value: GREED_S_BULLET7; Speed: 72; SizeUnits: 1; Heat: 30; Damage: 50),
    (Value: GREED_S_BULLET9; Speed: 100; SizeUnits: 1; Heat: 0; Damage: 90),
    (Value: GREED_S_BULLET10; Speed: 50; SizeUnits: 3; Heat: 500; Damage: 35),
    (Value: GREED_S_BULLET11; Speed: 500; SizeUnits: 1; Heat: 10; Damage: 50),
    (Value: GREED_S_BULLET12; Speed: 100; SizeUnits: 2; Heat: 300; Damage: 45),
    (Value: GREED_S_BULLET16; Speed: 100; SizeUnits: 3; Heat: 30; Damage: 30),
    (Value: GREED_S_BULLET17; Speed: 64; SizeUnits: 1; Heat: 100; Damage: 75),
    (Value: GREED_S_BULLET18; Speed: 50; SizeUnits: 5; Heat: 300; Damage: 400),
    (Value: GREED_S_GRENADEBULLET; Speed: 64; SizeUnits: 1; Heat: 96; Damage: 50),
    (Value: GREED_S_MINEBULLET; Speed: 128; SizeUnits: 8; Heat: 112; Damage: 50),
    (Value: GREED_S_HANDBULLET; Speed: 72; SizeUnits: 1; Heat: 0; Damage: 100),
    (Value: GREED_S_SOULBULLET; Speed: 72; SizeUnits: 1; Heat: 0; Damage: 250));

  /// S_MONSTERBULLET1 .. S_MONSTERBULLET15
  MONSTER_SHOTS: array[1..15] of TMonsterShotInfo = (
    (Speed: 500; Heat: 40; Damage: 60; Sound: GREED_SN_MON1_FIRE),
    (Speed: 90; Heat: 96; Damage: 100; Sound: GREED_SN_MON2_FIRE),
    (Speed: 60; Heat: 40; Damage: 60; Sound: GREED_SN_MON3_FIRE),
    (Speed: 80; Heat: 40; Damage: 75; Sound: GREED_SN_MON4_FIRE),
    (Speed: 80; Heat: 40; Damage: 100; Sound: GREED_SN_MON5_FIRE),
    (Speed: 70; Heat: 100; Damage: 150; Sound: GREED_SN_MON6_FIRE),
    (Speed: 128; Heat: 0; Damage: 60; Sound: GREED_SN_MON7_FIRE),
    (Speed: 90; Heat: 96; Damage: 100; Sound: GREED_SN_MON8_FIRE),
    (Speed: 500; Heat: 40; Damage: 60; Sound: GREED_SN_MON9_FIRE),
    (Speed: 128; Heat: 0; Damage: 20; Sound: GREED_SN_MON10_FIRE),
    (Speed: 100; Heat: 0; Damage: 100; Sound: GREED_SN_MON11_FIRE),
    (Speed: 70; Heat: 40; Damage: 40; Sound: GREED_SN_MON12_FIRE),
    (Speed: 100; Heat: 40; Damage: 50; Sound: GREED_SN_MON13_FIRE),
    (Speed: 100; Heat: 40; Damage: 100; Sound: GREED_SN_MON14_FIRE),
    (Speed: 128; Heat: 0; Damage: 75; Sound: GREED_SN_MON15_FIRE));

  /// S_MONSTER1 .. S_MONSTER15 (the _NS value is the next one); the corpse of the monster n is the value 256 - n
  MONSTERS: array[1..15] of TMonsterInfo = (
    (Value: GREED_S_MONSTER1; Speed: 4; Name: 'kman'; Pictures: 56; SizeUnits: 26; Intelligence: 10; Heat: 8;
      HitPoints: 80; HeightUnits: 59; Score: 160; Scale: 1),
    (Value: GREED_S_MONSTER2; Speed: 4; Name: 'kfem'; Pictures: 56; SizeUnits: 26; Intelligence: 10; Heat: 8;
      HitPoints: 110; HeightUnits: 59; Score: 220; Scale: 1),
    (Value: GREED_S_MONSTER3; Speed: 7; Name: 'kprob'; Pictures: 56; SizeUnits: 26; Intelligence: 10; Heat: 0;
      HitPoints: 150; HeightUnits: 20; Score: 300; Scale: 1),
    (Value: GREED_S_MONSTER4; Speed: 4; Name: 'kbot'; Pictures: 48; SizeUnits: 26; Intelligence: 10; Heat: 0;
      HitPoints: 350; HeightUnits: 45; Score: 700; Scale: 1),
    (Value: GREED_S_MONSTER5; Speed: 6; Name: 'kboss'; Pictures: 48; SizeUnits: 49; Intelligence: 10; Heat: 0;
      HitPoints: 10000; HeightUnits: 59; Score: 30000; Scale: 1),
    (Value: GREED_S_MONSTER6; Speed: 7; Name: 'pboss'; Pictures: 56; SizeUnits: 26; Intelligence: 10; Heat: 8;
      HitPoints: 5000; HeightUnits: 120; Score: 15000; Scale: 0),
    (Value: GREED_S_MONSTER7; Speed: 4; Name: 'pst'; Pictures: 56; SizeUnits: 26; Intelligence: 10; Heat: 8;
      HitPoints: 150; HeightUnits: 59; Score: 300; Scale: 1),
    (Value: GREED_S_MONSTER8; Speed: 4; Name: 'guard'; Pictures: 56; SizeUnits: 26; Intelligence: 5; Heat: 0;
      HitPoints: 350; HeightUnits: 59; Score: 700; Scale: 1),
    (Value: GREED_S_MONSTER9; Speed: 4; Name: 'trooper'; Pictures: 56; SizeUnits: 26; Intelligence: 5; Heat: 24;
      HitPoints: 80; HeightUnits: 59; Score: 160; Scale: 1),
    (Value: GREED_S_MONSTER10; Speed: 4; Name: 'prisoner'; Pictures: 56; SizeUnits: 26; Intelligence: 8; Heat: 16;
      HitPoints: 20; HeightUnits: 59; Score: 40; Scale: 1),
    (Value: GREED_S_MONSTER11; Speed: 3; Name: 'bigguard'; Pictures: 48; SizeUnits: 31; Intelligence: 9; Heat: 300;
      HitPoints: 1200; HeightUnits: 128; Score: 10000; Scale: 0),
    (Value: GREED_S_MONSTER12; Speed: 4; Name: 'pss'; Pictures: 56; SizeUnits: 26; Intelligence: 10; Heat: 8;
      HitPoints: 90; HeightUnits: 59; Score: 180; Scale: 1),
    (Value: GREED_S_MONSTER13; Speed: 4; Name: 'wiz'; Pictures: 56; SizeUnits: 26; Intelligence: 10; Heat: 8;
      HitPoints: 300; HeightUnits: 59; Score: 600; Scale: 1),
    (Value: GREED_S_MONSTER14; Speed: 4; Name: 'veek'; Pictures: 56; SizeUnits: 26; Intelligence: 10; Heat: 8;
      HitPoints: 350; HeightUnits: 59; Score: 700; Scale: 1),
    (Value: GREED_S_MONSTER15; Speed: 7; Name: 'tboss'; Pictures: 56; SizeUnits: 26; Intelligence: 10; Heat: 8;
      HitPoints: 3000; HeightUnits: 59; Score: 15000; Scale: 0));

{ TGreedSpawner }

constructor TGreedSpawner.Create(AState: TGreedGameState; const AArchive: IGreedArchive;
  const ARandom: IGreedRandom; const ASound: IGreedGameSound; const APictures: IGreedSpritePictures);
begin
  inherited Create;
  if not Assigned(AState) then
    raise EArgumentNilException.Create('AState');
  if not Assigned(AArchive) then
    raise EArgumentNilException.Create('AArchive');
  if not Assigned(ARandom) then
    raise EArgumentNilException.Create('ARandom');
  if not Assigned(ASound) then
    raise EArgumentNilException.Create('ASound');
  if not Assigned(APictures) then
    raise EArgumentNilException.Create('APictures');
  FState := AState;
  FArchive := AArchive;
  FRandom := ARandom;
  FSound := ASound;
  FPictures := APictures;
  FViolence := True;
end;

procedure TGreedSpawner.ResetCounts;
begin
  FBloodCount := 0;
  FMetalCount := 0;
end;

procedure TGreedSpawner.DemandLoadMonster(ALump, ACount: Integer);
begin
  // the original loads the lumps here and clears their colour 255: the lumps belong to who draws them
  FPictures.DemandLoadMonster(ALump, ACount);
end;

function TGreedSpawner.AddSprite(out ASprite: PGreedSprite): Integer;
begin
  Result := FState.Sprites.Add;
  ASprite := PGreedSprite(FState.Sprites.Item(Result));
end;

function TGreedSpawner.SpriteLump(AValue: Integer): Integer;
begin
  Result := FState.SpriteLumps[AValue - GREED_S_START];
end;

function TGreedSpawner.FloorZ(AX, AY: TGreedFixed): TGreedFixed;
begin
  Result := TGreedTerrain.FloorZ(FState.World, AX, AY);
end;

function TGreedSpawner.CeilingZ(AX, AY: TGreedFixed): TGreedFixed;
begin
  Result := TGreedTerrain.CeilingZ(FState.World, AX, AY);
end;

function TGreedSpawner.Floor(ASpot: Integer): Integer;
begin
  Result := FState.World.GetValue(gpFloorHeight, ASpot);
end;

function TGreedSpawner.Ceiling(ASpot: Integer): Integer;
begin
  Result := FState.World.GetValue(gpCeilingHeight, ASpot);
end;

procedure TGreedSpawner.SetMapSprite(ASpot, AValue: Integer);
begin
  FState.World.SetValue(gpMapSprites, ASpot, Byte(AValue));
end;

function TGreedSpawner.CharacterLump(ASpawnId: Integer): Integer;
begin
  if (ASpawnId < Low(TGreedGameTables.CharacterNames)) or (ASpawnId > High(TGreedGameTables.CharacterNames)) then
    raise EGreedException.CreateFmt(SUnknownCharacter, [ASpawnId]);
  Result := FArchive.RequireIndexOf(TGreedGameTables.CharacterNames[ASpawnId]);
end;

procedure TGreedSpawner.RemoveFirstOfKind(AKind: Integer; var ACount: Integer; ADecrement: Boolean);
var
  LIndex: Integer;
begin
  LIndex := FState.Sprites.First;
  while LIndex <> GREED_POOL_NIL do
  begin
    if FState.Sprites.Item(LIndex)^.Kind = AKind then
    begin
      FState.Sprites.Remove(LIndex);
      if ADecrement then
        Dec(ACount);
      Break;
    end;
    LIndex := FState.Sprites.Next(LIndex);
  end;
end;

function TGreedSpawner.SpawnBlood(const ARequest: TGreedSpawnRequest): Integer;
var
  LSprite: PGreedSprite;
begin
  Result := GREED_POOL_NIL;
  if FRandom.Next > 220 then
  begin
    Result := AddSprite(LSprite);
    LSprite^.Animation := (5 shl 5) + ((2 + (FRandom.Next and 7)) shl 9) + ANIM_SELF_DESTRUCT;
    LSprite^.X := ARequest.X + ((-3 + (FRandom.Next and 7)) * GREED_FRACUNIT);
    LSprite^.Y := ARequest.Y + ((-3 + (FRandom.Next and 7)) * GREED_FRACUNIT);
    LSprite^.Z := ARequest.Z + ((-3 + (FRandom.Next and 7)) * GREED_FRACUNIT);
    LSprite^.BasePic := SpriteLump(GREED_S_WALLPUFF);
    LSprite^.Active := True;
    LSprite^.Heat := 100;
    LSprite^.Kind := GREED_S_WALLPUFF;
    LSprite^.SpecialType := gstTransparent;
  end
  else if FViolence then
  begin
    if FBloodCount > GREED_MAX_BLOOD_SPRITES then
      RemoveFirstOfKind(GREED_S_BLOODSPLAT, FBloodCount, True);
    Inc(FBloodCount);
    Result := AddSprite(LSprite);
    LSprite^.X := ARequest.X + ((-3 + (FRandom.Next and 7)) * GREED_FRACUNIT);
    LSprite^.Y := ARequest.Y + ((-3 + (FRandom.Next and 7)) * GREED_FRACUNIT);
    LSprite^.Z := ARequest.Z + ((7 + (FRandom.Next and 15)) * GREED_FRACUNIT);
    LSprite^.ZAdjust := ARequest.ZAdjust;
    LSprite^.Active := True;
    LSprite^.Angle := FRandom.Next * 4;
    LSprite^.MoveSpeed := 15 - (FRandom.Next and 7);
    LSprite^.Angle2 := (FRandom.Next and 63) + 32;
    LSprite^.BasePic := SpriteLump(ARequest.Value) + (FRandom.Next mod 10);
    LSprite^.Kind := GREED_S_BLOODSPLAT;
    LSprite^.StartSpot := ARequest.MapSpot;
    LSprite^.MoveSize := GREED_FRACUNIT;
    LSprite^.Scale := 1;
  end;
end;

function TGreedSpawner.SpawnPuff(const ARequest: TGreedSpawnRequest): Integer;
var
  LSprite: PGreedSprite;
  LFrames, LDelay: Integer;
begin
  Result := AddSprite(LSprite);
  LFrames := 4;
  LDelay := 2;
  case ARequest.Value of
    GREED_S_WALLPUFF:
      LFrames := 5;
    GREED_S_PLASMAWALLPUFF, GREED_S_MINEPUFF:
      LDelay := 5;
    GREED_S_ARROWPUFF:
      LDelay := 3;
  end;
  LSprite^.Animation := (LFrames shl 5) + ((LDelay + (FRandom.Next and 7)) shl 9) + ANIM_SELF_DESTRUCT;
  case ARequest.Value of
    GREED_S_EXPLODE, GREED_S_SMALLEXPLODE, GREED_S_ARROWPUFF:
      begin
        LSprite^.X := ARequest.X;
        LSprite^.Y := ARequest.Y;
        LSprite^.Z := ARequest.Z;
      end;
  else
    LSprite^.X := ARequest.X + (-3 + (FRandom.Next and 7)) * GREED_FRACUNIT;
    LSprite^.Y := ARequest.Y + (-3 + (FRandom.Next and 7)) * GREED_FRACUNIT;
    LSprite^.Z := ARequest.Z + (-3 + (FRandom.Next and 7)) * GREED_FRACUNIT;
  end;
  LSprite^.Active := True;
  case ARequest.Value of
    GREED_S_EXPLODE, GREED_S_SMALLEXPLODE:
      begin
        if FRandom.Next and 1 <> 0 then
          LSprite^.BasePic := SpriteLump(GREED_S_EXPLODE)
        else
          LSprite^.BasePic := SpriteLump(GREED_S_EXPLODE2);
        LSprite^.Heat := 512;
        LSprite^.Kind := GREED_S_EXPLODE;
        LSprite^.SpecialType := gstNoClip;
      end;
    GREED_S_WALLPUFF:
      begin
        LSprite^.BasePic := SpriteLump(ARequest.Value);
        LSprite^.Heat := 100;
        LSprite^.Kind := GREED_S_WALLPUFF;
        LSprite^.SpecialType := gstTransparent;
      end;
    GREED_S_GREENPUFF:
      begin
        LSprite^.BasePic := SpriteLump(ARequest.Value);
        LSprite^.Heat := 150;
        LSprite^.Kind := GREED_S_WALLPUFF;
        LSprite^.SpecialType := gstTransparent;
      end;
    GREED_S_PLASMAWALLPUFF:
      begin
        LSprite^.BasePic := SpriteLump(ARequest.Value);
        LSprite^.Heat := 600;
        LSprite^.Kind := GREED_S_PLASMAWALLPUFF;
        LSprite^.SpecialType := gstTransparent;
      end;
    GREED_S_MINEPUFF:
      begin
        LSprite^.BasePic := SpriteLump(ARequest.Value);
        LSprite^.Heat := 600;
        LSprite^.Kind := GREED_S_MINEPUFF;
        LSprite^.SpecialType := gstNoClip;
      end;
    GREED_S_ARROWPUFF:
      begin
        LSprite^.BasePic := SpriteLump(ARequest.Value);
        LSprite^.Heat := 512;
        LSprite^.Kind := GREED_S_EXPLODE;
        LSprite^.SpecialType := gstNoClip;
        FSound.SoundEffect(GREED_SN_EXPLODE1 + (FRandom.Next and 1), 15, ARequest.X, ARequest.Y);
      end;
  end;
end;

function TGreedSpawner.SpawnShot(const ARequest: TGreedSpawnRequest): Integer;
var
  LSprite: PGreedSprite;
  LIndex, LFound: Integer;
begin
  LFound := -1;
  for LIndex := Low(PLAYER_SHOTS) to High(PLAYER_SHOTS) do
    if PLAYER_SHOTS[LIndex].Value = ARequest.Value then
      LFound := LIndex;
  Result := AddSprite(LSprite);
  LSprite^.MoveSpeed := PLAYER_SHOTS[LFound].Speed;
  LSprite^.Angle := ARequest.Angle;
  LSprite^.X := ARequest.X;
  LSprite^.Y := ARequest.Y;
  LSprite^.ZAdjust := ARequest.ZAdjust;
  LSprite^.Z := ARequest.Z + ARequest.ZAdjust;
  LSprite^.BasePic := SpriteLump(ARequest.Value);
  LSprite^.MoveSize := PLAYER_SHOTS[LFound].SizeUnits * GREED_FRACUNIT;
  LSprite^.Active := True;
  LSprite^.Heat := PLAYER_SHOTS[LFound].Heat;
  LSprite^.StartSpot := ARequest.MapSpot;
  LSprite^.Damage := PLAYER_SHOTS[LFound].Damage;
  LSprite^.Kind := ARequest.Value;
  LSprite^.SpawnId := ARequest.SpawnId;
  LSprite^.Angle2 := ARequest.Angle2;
  case ARequest.Value of
    GREED_S_BULLET3:
      begin
        LSprite^.Rotate := grEight;
        LSprite^.SpecialType := gstNoClip;
      end;
    GREED_S_BULLET4:
      LSprite^.Rotate := grEight;
    GREED_S_BULLET7, GREED_S_HANDBULLET:
      LSprite^.MaxMove := 2;
    GREED_S_BULLET9:
      LSprite^.Rotate := grFour;
    GREED_S_BULLET10, GREED_S_BULLET16, GREED_S_BULLET18:
      LSprite^.Animation := ANIM_LOOP_3_5;
    GREED_S_BULLET17:
      begin
        LSprite^.Scale := 1;
        LSprite^.Rotate := grEight;
      end;
    GREED_S_GRENADEBULLET, GREED_S_MINEBULLET:
      begin
        if ARequest.Value = GREED_S_GRENADEBULLET then
          LSprite^.BasePic := SpriteLump(GREED_S_BULLET3)
        else
          LSprite^.MaxMove := 2;
        LSprite^.StartSpot := -1;
        if ARequest.SpawnId = FState.PlayerNum then
          LSprite^.SpawnId := 200 + ARequest.SpawnId;
      end;
    GREED_S_SOULBULLET:
      begin
        LSprite^.MaxMove := 4;
        LSprite^.StartSpot := -1;
      end;
  end;
end;

function TGreedSpawner.SpawnMonsterShot(const ARequest: TGreedSpawnRequest): Integer;
var
  LSprite: PGreedSprite;
  LNumber: Integer;
begin
  LNumber := ARequest.Value - GREED_S_MONSTERBULLET1 + 1;
  Result := AddSprite(LSprite);
  LSprite^.MoveSpeed := MONSTER_SHOTS[LNumber].Speed;
  LSprite^.Angle := ARequest.Angle;
  LSprite^.X := ARequest.X;
  LSprite^.Y := ARequest.Y;
  LSprite^.ZAdjust := ARequest.ZAdjust;
  LSprite^.Z := ARequest.Z + ARequest.ZAdjust;
  LSprite^.BasePic := SpriteLump(ARequest.Value);
  LSprite^.MoveSize := GREED_FRACUNIT;
  LSprite^.Active := True;
  LSprite^.Heat := MONSTER_SHOTS[LNumber].Heat;
  LSprite^.StartSpot := ARequest.MapSpot;
  LSprite^.Damage := MONSTER_SHOTS[LNumber].Damage;
  LSprite^.Kind := ARequest.Value;
  LSprite^.SpawnId := ARequest.SpawnId;
  LSprite^.Angle2 := ARequest.Angle2;
  case LNumber of
    2:
      LSprite^.Rotate := grEight;
    3:
      LSprite^.Animation := 1 + (3 shl 5) + (2 shl 9);
    4:
      begin
        LSprite^.Scale := 1;
        LSprite^.Rotate := grEight;
      end;
    6:
      begin
        LSprite^.Scale := 2;
        LSprite^.Rotate := grEight;
      end;
    7, 10:
      LSprite^.MaxMove := 2;
    8:
      begin
        LSprite^.Rotate := grEight;
        LSprite^.SpecialType := gstNoClip;
      end;
    15:
      LSprite^.MaxMove := 4;
  end;
  FSound.SoundEffect(MONSTER_SHOTS[LNumber].Sound, 7, ARequest.X, ARequest.Y);
end;

function TGreedSpawner.SpawnMetalParts(const ARequest: TGreedSpawnRequest): Integer;
var
  LSprite: PGreedSprite;
begin
  // the original does not count the part it takes away: after 101 parts every new one removes the oldest
  if FMetalCount > GREED_MAX_METAL_PARTS then
    RemoveFirstOfKind(GREED_S_METALPARTS, FMetalCount, False);
  Inc(FMetalCount);
  Result := AddSprite(LSprite);
  LSprite^.X := ARequest.X + (-15 + (FRandom.Next and 31)) * GREED_FRACUNIT;
  LSprite^.Y := ARequest.Y + (-15 + (FRandom.Next and 31)) * GREED_FRACUNIT;
  LSprite^.Z := ARequest.Z + (-32 + (FRandom.Next and 63)) * GREED_FRACUNIT;
  LSprite^.ZAdjust := ARequest.ZAdjust;
  LSprite^.Active := True;
  LSprite^.Angle := FRandom.Next * 4;
  LSprite^.MoveSpeed := 10 + (FRandom.Next and 15);
  LSprite^.Angle2 := (FRandom.Next and 63) + 32;
  LSprite^.BasePic := FArchive.RequireIndexOf('METALPARTS') + (FRandom.Next and 3);
  LSprite^.Kind := GREED_S_METALPARTS;
  LSprite^.StartSpot := ARequest.MapSpot;
  LSprite^.MoveSize := GREED_FRACUNIT;
  LSprite^.Damage := 100;
end;

function TGreedSpawner.SpawnDevice(const ARequest: TGreedSpawnRequest): Integer;
var
  LSprite: PGreedSprite;
begin
  Result := AddSprite(LSprite);
  case ARequest.Value of
    GREED_S_WARP:
      begin
        LSprite^.Animation := (8 shl 5) + (6 shl 9) + ANIM_SELF_DESTRUCT;
        LSprite^.X := ARequest.X;
        LSprite^.Y := ARequest.Y;
        LSprite^.Z := FloorZ(ARequest.X, ARequest.Y);
        LSprite^.BasePic := SpriteLump(ARequest.Value);
        LSprite^.Kind := ARequest.Value;
        LSprite^.SpecialType := gstMaxLight;
        FSound.SoundEffect(GREED_SN_WARP, 0, ARequest.X, ARequest.Y);
      end;
    GREED_S_PROXMINE, GREED_S_TIMEMINE, GREED_S_INSTAWALL, GREED_S_DECOY:
      begin
        LSprite^.MoveSpeed := 1;
        LSprite^.Active := True;
        LSprite^.X := ARequest.X;
        LSprite^.Y := ARequest.Y;
        LSprite^.Z := FloorZ(ARequest.X, ARequest.Y);
        LSprite^.Intelligence := 6;
        LSprite^.SpawnId := ARequest.SpawnId;
        case ARequest.Value of
          GREED_S_PROXMINE:
            begin
              LSprite^.BasePic := FArchive.RequireIndexOf('proxmine');
              LSprite^.Kind := GREED_S_PROXMINE;
              LSprite^.ActionTime := FState.TimeCount + 105;
            end;
          GREED_S_TIMEMINE:
            begin
              LSprite^.BasePic := FArchive.RequireIndexOf('timemine');
              LSprite^.Kind := GREED_S_TIMEMINE;
              LSprite^.ActionTime := FState.TimeCount + (2 * TIC_RATE);
            end;
          GREED_S_INSTAWALL:
            begin
              LSprite^.Animation := 1 + (4 shl 5) + (16 shl 9);
              LSprite^.BasePic := FArchive.RequireIndexOf('instaanim');
              LSprite^.Kind := ARequest.Value;
              LSprite^.ActionTime := FState.TimeCount + (45 * TIC_RATE);
              LSprite^.SpecialType := gstTransparent;
              SetMapSprite(ARequest.MapSpot, 64);
            end;
          GREED_S_DECOY:
            begin
              LSprite^.BasePic := CharacterLump(ARequest.SpawnId);
              LSprite^.Scale := 1;
              LSprite^.Rotate := grEight;
              LSprite^.Kind := GREED_S_PROXMINE;
              LSprite^.ActionTime := FState.TimeCount + (2 * TIC_RATE);
            end;
        end;
      end;
    GREED_S_CLONE:
      begin
        LSprite^.MoveSpeed := 10 * GREED_FRACUNIT;
        LSprite^.Angle := ARequest.Angle;
        LSprite^.Active := ARequest.Active;
        LSprite^.X := ARequest.X;
        LSprite^.Y := ARequest.Y;
        LSprite^.Z := FloorZ(ARequest.X, ARequest.Y);
        LSprite^.Rotate := grEight;
        LSprite^.BasePic := CharacterLump(ARequest.SpawnId);
        LSprite^.Scale := 1;
        LSprite^.StartPic := LSprite^.BasePic;
        LSprite^.MoveSize := 24 * GREED_FRACUNIT;
        LSprite^.Intelligence := 7;
        LSprite^.HitPoints := 700;
        LSprite^.Kind := GREED_S_CLONE;
        LSprite^.Height := 54 * GREED_FRACUNIT;
        LSprite^.Bullet := GREED_S_MONSTERBULLET8;
        SetMapSprite(ARequest.MapSpot, 1);
      end;
    GREED_S_GRENADE:
      begin
        LSprite^.MoveSpeed := 50;
        LSprite^.Angle := ARequest.Angle;
        LSprite^.X := ARequest.X;
        LSprite^.Y := ARequest.Y;
        LSprite^.ZAdjust := ARequest.ZAdjust;
        LSprite^.Z := ARequest.Z + ARequest.ZAdjust;
        LSprite^.BasePic := FArchive.RequireIndexOf('grenadeshot');
        LSprite^.MoveSize := 10 * GREED_FRACUNIT;
        LSprite^.HitPoints := 1;
        LSprite^.Active := True;
        LSprite^.StartSpot := ARequest.MapSpot;
        LSprite^.Kind := GREED_S_GRENADE;
        LSprite^.SpawnId := ARequest.SpawnId;
        LSprite^.Angle2 := ARequest.Angle2;
        LSprite^.Rotate := grFour;
      end;
    GREED_S_BONUSITEM:
      begin
        LSprite^.Angle := ARequest.Angle;
        LSprite^.Active := False;
        LSprite^.X := ARequest.X;
        LSprite^.Y := ARequest.Y;
        LSprite^.Z := FloorZ(ARequest.X, ARequest.Y);
        LSprite^.BasePic := FArchive.RequireIndexOf('randitem');
        LSprite^.Kind := GREED_S_BONUSITEM;
        SetMapSprite(ARequest.MapSpot, GREED_SM_BONUSITEM);
      end;
    GREED_S_GENERATOR:
      begin
        LSprite^.X := ARequest.X;
        LSprite^.Y := ARequest.Y;
        LSprite^.Z := FloorZ(ARequest.X, ARequest.Y);
        LSprite^.BasePic := SpriteLump(ARequest.Value);
        LSprite^.Kind := ARequest.Value;
        LSprite^.Animation := ANIM_LOOP_4_10;
      end;
  end;
end;

function TGreedSpawner.SpawnMonster(const ARequest: TGreedSpawnRequest; ANumber: Integer;
  ANoFalling: Boolean): Integer;
var
  LSprite: PGreedSprite;
begin
  Result := AddSprite(LSprite);
  if ANoFalling then
    LSprite^.NoFalling := True;
  LSprite^.MoveSpeed := MONSTERS[ANumber].Speed * GREED_FRACUNIT;
  LSprite^.Angle := ARequest.Angle;
  LSprite^.Active := ARequest.Active;
  LSprite^.X := ARequest.X;
  LSprite^.Y := ARequest.Y;
  // the probe (kprob) flies
  if ANumber = 3 then
    LSprite^.ZAdjust := 25 * GREED_FRACUNIT;
  LSprite^.Z := FloorZ(ARequest.X, ARequest.Y) + LSprite^.ZAdjust;
  LSprite^.Rotate := grEight;
  LSprite^.BasePic := FArchive.RequireIndexOf(MONSTERS[ANumber].Name);
  DemandLoadMonster(LSprite^.BasePic, MONSTERS[ANumber].Pictures);
  LSprite^.StartPic := LSprite^.BasePic;
  LSprite^.MoveSize := MONSTERS[ANumber].SizeUnits * GREED_FRACUNIT;
  LSprite^.Intelligence := MONSTERS[ANumber].Intelligence;
  LSprite^.Heat := MONSTERS[ANumber].Heat;
  LSprite^.HitPoints := MONSTERS[ANumber].HitPoints;
  LSprite^.Kind := MONSTERS[ANumber].Value;
  LSprite^.Height := MONSTERS[ANumber].HeightUnits * GREED_FRACUNIT;
  LSprite^.Score := MONSTERS[ANumber].Score;
  LSprite^.Bullet := GREED_S_MONSTERBULLET1 + ANumber - 1;
  LSprite^.Scale := MONSTERS[ANumber].Scale;
  if ANumber = 10 then
    LSprite^.Enraged := 10;
  if ANumber = 11 then
    LSprite^.DeathEvent := 255;
  SetMapSprite(ARequest.MapSpot, 1);
end;

function TGreedSpawner.SpawnCorpse(const ARequest: TGreedSpawnRequest): Integer;
var
  LSprite: PGreedSprite;
begin
  Result := AddSprite(LSprite);
  LSprite^.X := ARequest.X;
  LSprite^.Y := ARequest.Y;
  LSprite^.Z := FloorZ(ARequest.X, ARequest.Y);
  LSprite^.BasePic := FArchive.RequireIndexOf(MONSTERS[GREED_S_DEADMONSTER1 + 1 - ARequest.Value].Name) + 55;
  DemandLoadMonster(LSprite^.BasePic, 1);
  LSprite^.Kind := ARequest.Value;
  LSprite^.Scale := 1;
  SetMapSprite(ARequest.MapSpot, 0);
end;

function TGreedSpawner.SpawnHangingItem(const ARequest: TGreedSpawnRequest; ADrop: Integer): Integer;
var
  LSprite: PGreedSprite;
begin
  Result := AddSprite(LSprite);
  LSprite^.X := ARequest.X;
  LSprite^.Y := ARequest.Y;
  if ADrop > 0 then
  begin
    // it hangs from the ceiling: ADrop is how tall its picture is
    LSprite^.ZAdjust := CeilingZ(ARequest.X, ARequest.Y) - (ADrop * GREED_FRACUNIT) - FloorZ(ARequest.X, ARequest.Y);
    LSprite^.Z := FloorZ(ARequest.X, ARequest.Y) + LSprite^.ZAdjust;
  end
  else
    LSprite^.Z := FloorZ(ARequest.X, ARequest.Y);
  LSprite^.BasePic := FArchive.RequireIndexOf('miscobj') + (ARequest.Value - GREED_S_ITEM1);
  DemandLoadMonster(LSprite^.BasePic, 1);
  LSprite^.Kind := ARequest.Value;
  if ADrop > 0 then
    SetMapSprite(ARequest.MapSpot, 0)
  else
  begin
    LSprite^.Height := 48 * GREED_FRACUNIT;
    SetMapSprite(ARequest.MapSpot, 2);
  end;
end;

function TGreedSpawner.SpawnPickup(const ARequest: TGreedSpawnRequest): Integer;
var
  LSprite: PGreedSprite;
  LNumber: Integer;
begin
  Result := AddSprite(LSprite);
  LSprite^.X := ARequest.X;
  LSprite^.Y := ARequest.Y;
  LSprite^.Z := FloorZ(ARequest.X, ARequest.Y);
  LSprite^.Kind := ARequest.Value;
  case ARequest.Value of
    GREED_S_WEAPON0..GREED_S_WEAPON18:
      begin
        LSprite^.BasePic := FArchive.RequireIndexOf('weapons') + ARequest.Value - GREED_S_WEAPON0;
        SetMapSprite(ARequest.MapSpot, ARequest.Value - GREED_S_WEAPON0 + GREED_SM_WEAPON0);
      end;
    GREED_S_MEDPAK1..GREED_S_ISTEALER:
      begin
        LSprite^.BasePic := FArchive.RequireIndexOf('medtube1') + (ARequest.Value - GREED_S_MEDPAK1) * 4;
        LSprite^.Animation := ANIM_LOOP_4_10;
        SetMapSprite(ARequest.MapSpot, (ARequest.Value - GREED_S_MEDPAK1) + GREED_SM_MEDPAK1);
      end;
    GREED_S_AMMOBOX:
      begin
        LSprite^.BasePic := FArchive.RequireIndexOf('ammobox');
        SetMapSprite(ARequest.MapSpot, GREED_SM_AMMOBOX);
      end;
    GREED_S_MEDBOX:
      begin
        LSprite^.BasePic := FArchive.RequireIndexOf('autodoc');
        SetMapSprite(ARequest.MapSpot, GREED_SM_MEDBOX);
      end;
    GREED_S_GOODIEBOX:
      begin
        LSprite^.BasePic := FArchive.RequireIndexOf('toolchest');
        SetMapSprite(ARequest.MapSpot, GREED_SM_GOODIEBOX);
      end;
    GREED_S_PRIMARY1, GREED_S_PRIMARY2:
      begin
        LNumber := ARequest.Value - GREED_S_PRIMARY1;
        LSprite^.BasePic := FArchive.RequireIndexOf('primary') + FState.Primaries[LNumber * 2];
        SetMapSprite(ARequest.MapSpot, LNumber + GREED_SM_PRIMARY1);
        LSprite^.Score := FState.Primaries[LNumber * 2 + 1];
      end;
    GREED_S_SECONDARY1..GREED_S_SECONDARY7:
      begin
        LNumber := ARequest.Value - GREED_S_SECONDARY1;
        LSprite^.BasePic := FArchive.RequireIndexOf('secondary') + FState.Secondaries[LNumber * 2];
        SetMapSprite(ARequest.MapSpot, LNumber + GREED_SM_SECONDARY1);
        LSprite^.Score := FState.Secondaries[LNumber * 2 + 1];
      end;
  end;
end;

procedure TGreedSpawner.SpawnPlayerStart(const ARequest: TGreedSpawnRequest);
begin
  if ARequest.Value = GREED_S_PLAYER then
  begin
    FState.StartLocations[0][0] := ARequest.TileX;
    FState.StartLocations[0][1] := ARequest.TileY;
    // the net game is not ported: the player of the game is always the first one
    if FState.Player.X = -1 then
    begin
      FState.Player.X := ARequest.X;
      FState.Player.Y := ARequest.Y;
      FState.Player.Z := FloorZ(FState.Player.X, FState.Player.Y) + FState.Player.Height;
      FState.Player.MapSpot := ARequest.MapSpot;
      FState.Player.Angle := NORTH;
      FState.PlayerAngle64 := NORTH * 64;
    end;
  end
  else
  begin
    if (FState.World.GetValue(gpFloorPic, ARequest.MapSpot) = 0)
      or (FState.World.GetValue(gpCeilingPic, ARequest.MapSpot) = 0) then
      raise EGreedException.CreateFmt(SInvalidStart, [ARequest.Value, ARequest.TileX, ARequest.TileY]);
    FState.StartLocations[ARequest.Value - 1][0] := ARequest.TileX;
    FState.StartLocations[ARequest.Value - 1][1] := ARequest.TileY;
  end;
  SetMapSprite(ARequest.MapSpot, 0);
end;

procedure TGreedSpawner.SpawnDoor(const ARequest: TGreedSpawnRequest);
var
  LIndex, LBefore: Integer;
  LDoor: TGreedDoor;
  LVertical: Boolean;
begin
  LVertical := (ARequest.Value - GREED_S_VDOOR1) and 1 = 0;
  LIndex := FState.World.AddDoor(ARequest.TileX, ARequest.TileY);
  LDoor := FState.World.GetDoor(LIndex);
  // the second half of a double door: the tile before (above or on the left) is a door too
  if LVertical then
    LBefore := ARequest.MapSpot - GREED_MAP_SIZE
  else
    LBefore := ARequest.MapSpot - 1;
  if FState.World.GetMapFlags(LBefore) and GREED_FL_DOOR <> 0 then
  begin
    if LVertical then
      LDoor.Orientation := gdoVertical2
    else
      LDoor.Orientation := gdoHorizontal2;
  end
  else if LVertical then
    LDoor.Orientation := gdoVertical
  else
    LDoor.Orientation := gdoHorizontal;
  LDoor.Bumpable := True;
  LDoor.Size := 64 * GREED_FRACUNIT;
  LDoor.Position := LDoor.Size;
  LDoor.Pic := FArchive.RequireIndexOf('door_' + IntToStr((ARequest.Value - GREED_S_VDOOR1) div 2 + 1))
    - FArchive.RequireIndexOf(LUMP_START_WALLS);
  LDoor.Timer := FState.Player.TimeCount;
  FState.World.SetDoor(LIndex, LDoor);
  SetMapSprite(ARequest.MapSpot, 0);
end;

procedure TGreedSpawner.SpawnElevator(const ARequest: TGreedSpawnRequest);
var
  LElevator: ^TGreedElevator;
  LSpot, LMaxHeight, LRow, LColumn: Integer;
begin
  LSpot := ARequest.MapSpot;
  LElevator := Pointer(FState.Elevators.Item(FState.Elevators.Add));
  LElevator^.MapSpot := LSpot;
  LElevator^.Floor := Floor(LSpot);
  LElevator^.Speed := 8;
  case ARequest.Value of
    GREED_S_ELEVATOR, GREED_S_PAUSEDELEVATOR:
      begin
        if ARequest.Value = GREED_S_ELEVATOR then
        begin
          LElevator^.Up := True;
          LElevator^.Timer := FState.Player.TimeCount;
        end
        else
          LElevator^.Timer := GREED_ELEVATOR_PAUSED;
        SetMapSprite(LSpot, 0);
        // it goes up to the highest floor of the nine tiles around
        LMaxHeight := Floor(LSpot);
        for LRow := ARequest.TileY - 1 to ARequest.TileY + 1 do
          for LColumn := ARequest.TileX - 1 to ARequest.TileX + 1 do
            if Floor(LRow * GREED_MAP_SIZE + LColumn) > LMaxHeight then
              LMaxHeight := Floor(LRow * GREED_MAP_SIZE + LColumn);
        LElevator^.Ceiling := LMaxHeight;
        LElevator^.Position := LMaxHeight;
        LElevator^.Position64 := LElevator^.Position * GREED_FRACUNIT;
        LElevator^.Kind := getNormal;
        FState.World.SetValue(gpFloorHeight, LSpot, Byte(LMaxHeight));
      end;
    GREED_S_ELEVATORLOW:
      begin
        LElevator^.Position := Floor(LSpot);
        LElevator^.Position64 := LElevator^.Position * GREED_FRACUNIT;
        SetMapSprite(LSpot, 0);
        LElevator^.Ceiling := Ceiling(LSpot);
        LElevator^.Kind := getSwap;
        LElevator^.Timer := GREED_ELEVATOR_PAUSED;
      end;
    GREED_S_ELEVATORHIGH:
      begin
        SetMapSprite(LSpot, 0);
        LElevator^.Ceiling := Ceiling(LSpot);
        LElevator^.Position := Ceiling(LSpot);
        // Position64 stays zero, as in the original
        FState.World.SetValue(gpFloorHeight, LSpot, Byte(LElevator^.Position));
        LElevator^.Kind := getSwap;
        LElevator^.Timer := GREED_ELEVATOR_PAUSED;
      end;
    GREED_S_ELEVATOR3M, GREED_S_ELEVATOR6M, GREED_S_ELEVATOR15M:
      begin
        LElevator^.Down := True;
        LElevator^.Position := Ceiling(LSpot);
        LElevator^.Position64 := LElevator^.Position * GREED_FRACUNIT;
        LElevator^.Ceiling := Ceiling(LSpot);
        FState.World.SetValue(gpFloorHeight, LSpot, Byte(Ceiling(LSpot)));
        LElevator^.Kind := getTimed;
        case ARequest.Value of
          GREED_S_ELEVATOR3M:
            LElevator^.Timer := 12600;
          GREED_S_ELEVATOR6M:
            LElevator^.Timer := 25200;
        else
          LElevator^.Timer := 63000;
        end;
        SetMapSprite(LSpot, GREED_SM_ELEVATOR);
      end;
    GREED_S_TRIGGERD1, GREED_S_TRIGGERD2, GREED_S_SDOOR:
      begin
        LElevator^.Position := Ceiling(LSpot);
        LElevator^.Position64 := LElevator^.Position * GREED_FRACUNIT;
        LElevator^.Ceiling := Ceiling(LSpot);
        LElevator^.Timer := GREED_ELEVATOR_PAUSED;
        case ARequest.Value of
          GREED_S_TRIGGERD1:
            LElevator^.Kind := getSwitchDown;
          GREED_S_TRIGGERD2:
            LElevator^.Kind := getSwitchDown2;
        else
          LElevator^.Kind := getSecret;
        end;
        if ARequest.Value = GREED_S_SDOOR then
          SetMapSprite(LSpot, 0)
        else
          SetMapSprite(LSpot, GREED_SM_ELEVATOR);
        FState.World.SetValue(gpFloorHeight, LSpot, Byte(LElevator^.Position));
      end;
  end;
end;

procedure TGreedSpawner.SpawnArea(const ARequest: TGreedSpawnRequest; AKind: Integer);
var
  LIndex: Integer;
  LArea: TGreedSpawnArea;
begin
  LIndex := FState.World.AddSpawnArea;
  LArea := FState.World.GetSpawnArea(LIndex);
  LArea.MapX := (ARequest.TileX * GREED_FRACTILEUNIT) + (32 * GREED_FRACUNIT);
  LArea.MapY := (ARequest.TileY * GREED_FRACTILEUNIT) + (32 * GREED_FRACUNIT);
  LArea.MapSpot := ARequest.MapSpot;
  LArea.Time := FState.Player.TimeCount + ((FRandom.Next and 15) * 64);
  LArea.Kind := AKind;
  FState.World.SetSpawnArea(LIndex, LArea);
end;

function TGreedSpawner.SpawnExit(const ARequest: TGreedSpawnRequest): Integer;
var
  LSprite: PGreedSprite;
begin
  Result := AddSprite(LSprite);
  LSprite^.X := ARequest.X;
  LSprite^.Y := ARequest.Y;
  LSprite^.Z := FloorZ(ARequest.X, ARequest.Y);
  LSprite^.BasePic := FArchive.RequireIndexOf('exitwarp');
  LSprite^.Kind := GREED_S_EXIT;
  LSprite^.Animation := 1 + (8 shl 5) + (5 shl 9);
  SetMapSprite(ARequest.MapSpot, GREED_SM_EXIT);
  FState.ExitExists := True;
  FState.ExitX := ARequest.TileX;
  FState.ExitY := ARequest.TileY;
end;

function TGreedSpawner.SpawnByValue(const ARequest: TGreedSpawnRequest): Integer;
var
  LNumber, LAngle: Integer;
begin
  Result := GREED_POOL_NIL;
  // the monsters: fifteen kinds, each with the value that does not fall (_NS) after it
  for LNumber := Low(MONSTERS) to High(MONSTERS) do
    if (ARequest.Value = MONSTERS[LNumber].Value) or (ARequest.Value = MONSTERS[LNumber].Value + 1) then
      Exit(SpawnMonster(ARequest, LNumber, ARequest.Value <> MONSTERS[LNumber].Value));
  case ARequest.Value of
    GREED_S_BLOODSPLAT:
      Result := SpawnBlood(ARequest);
    GREED_S_BULLET1..GREED_S_BULLET18, GREED_S_GRENADEBULLET, GREED_S_MINEBULLET, GREED_S_HANDBULLET,
    GREED_S_SOULBULLET:
      Result := SpawnShot(ARequest);
    GREED_S_EXPLODE, GREED_S_SMALLEXPLODE, GREED_S_WALLPUFF, GREED_S_GREENPUFF, GREED_S_PLASMAWALLPUFF,
    GREED_S_ARROWPUFF, GREED_S_MINEPUFF:
      Result := SpawnPuff(ARequest);
    GREED_S_MONSTERBULLET1..GREED_S_MONSTERBULLET15:
      Result := SpawnMonsterShot(ARequest);
    GREED_S_METALPARTS:
      Result := SpawnMetalParts(ARequest);
    GREED_S_WARP, GREED_S_PROXMINE, GREED_S_TIMEMINE, GREED_S_INSTAWALL, GREED_S_DECOY, GREED_S_CLONE,
    GREED_S_GRENADE, GREED_S_BONUSITEM, GREED_S_GENERATOR:
      Result := SpawnDevice(ARequest);
    GREED_S_ITEM2, GREED_S_ITEM3:
      Result := SpawnHangingItem(ARequest, 20);
    GREED_S_ITEM8, GREED_S_ITEM31:
      Result := SpawnHangingItem(ARequest, 39);
    GREED_S_ITEM10:
      Result := SpawnHangingItem(ARequest, 33);
    GREED_S_ITEM11:
      Result := SpawnHangingItem(ARequest, 73);
    GREED_S_ITEM12:
      Result := SpawnHangingItem(ARequest, 35);
    GREED_S_ITEM13:
      Result := SpawnHangingItem(ARequest, 65);
    GREED_S_ITEM20:
      Result := SpawnHangingItem(ARequest, 91);
    GREED_S_ITEM23:
      Result := SpawnHangingItem(ARequest, 121);
    GREED_S_ITEM30:
      Result := SpawnHangingItem(ARequest, 40);
    GREED_S_ITEM32:
      Result := SpawnHangingItem(ARequest, 36);
    GREED_S_ITEM33:
      Result := SpawnHangingItem(ARequest, 51);
    GREED_S_ITEM34:
      Result := SpawnHangingItem(ARequest, 49);
    GREED_S_ITEM1, GREED_S_ITEM4..GREED_S_ITEM7, GREED_S_ITEM9, GREED_S_ITEM14..GREED_S_ITEM19, GREED_S_ITEM21,
    GREED_S_ITEM22, GREED_S_ITEM24..GREED_S_ITEM29:
      Result := SpawnHangingItem(ARequest, 0);
    GREED_S_WEAPON0..GREED_S_WEAPON18, GREED_S_MEDPAK1..GREED_S_ISTEALER, GREED_S_AMMOBOX, GREED_S_MEDBOX,
    GREED_S_GOODIEBOX, GREED_S_PRIMARY1, GREED_S_PRIMARY2, GREED_S_SECONDARY1..GREED_S_SECONDARY7:
      Result := SpawnPickup(ARequest);
    GREED_S_DEADMONSTER15..GREED_S_DEADMONSTER1:
      Result := SpawnCorpse(ARequest);
    GREED_S_PLAYER, GREED_S_NETPLAYER2..GREED_S_NETPLAYER8:
      SpawnPlayerStart(ARequest);
    GREED_S_VDOOR1..GREED_S_HDOOR7:
      SpawnDoor(ARequest);
    GREED_S_ELEVATOR, GREED_S_PAUSEDELEVATOR, GREED_S_ELEVATORLOW, GREED_S_ELEVATORHIGH, GREED_S_ELEVATOR3M,
    GREED_S_ELEVATOR6M, GREED_S_ELEVATOR15M, GREED_S_TRIGGERD1, GREED_S_TRIGGERD2, GREED_S_SDOOR:
      SpawnElevator(ARequest);
    GREED_S_SWAPSWITCH:
      SetMapSprite(ARequest.MapSpot, GREED_SM_SWAPSWITCH);
    GREED_S_TRIGGER1:
      SetMapSprite(ARequest.MapSpot, GREED_SM_SWITCHDOWN);
    GREED_S_TRIGGER2:
      SetMapSprite(ARequest.MapSpot, GREED_SM_SWITCHDOWN2);
    GREED_S_STRIGGER:
      SetMapSprite(ARequest.MapSpot, GREED_SM_STRIGGER);
    // a value of mapsprites above 128 does not stop who walks
    GREED_S_WARP1:
      SetMapSprite(ARequest.MapSpot, GREED_SM_WARP1);
    GREED_S_WARP2:
      SetMapSprite(ARequest.MapSpot, GREED_SM_WARP2);
    GREED_S_WARP3:
      SetMapSprite(ARequest.MapSpot, GREED_SM_WARP3);
    GREED_S_GENERATOR1, GREED_S_GENERATOR2:
      begin
        SpawnArea(ARequest, ARequest.Value - GREED_S_GENERATOR1);
        // the sprite of the generator is made, but the original does not give it back
        LAngle := FRandom.Next * 4;
        SpawnSprite(GREED_S_GENERATOR, (ARequest.TileX * GREED_MAP_SIZE + 32) * GREED_FRACUNIT,
          (ARequest.TileY * GREED_MAP_SIZE + 32) * GREED_FRACUNIT, 0, 0, LAngle, 0, False, 0);
        SetMapSprite(ARequest.MapSpot, 0);
      end;
    GREED_S_SPAWN1..GREED_S_SPAWN15:
      begin
        if not FState.NoSpawn then
          SpawnArea(ARequest, ARequest.Value - GREED_S_SPAWN1 + 10);
        SetMapSprite(ARequest.MapSpot, 0);
      end;
    GREED_S_SPAWN8_NS, GREED_S_SPAWN9_NS:
      begin
        if not FState.NoSpawn then
          SpawnArea(ARequest, ARequest.Value - GREED_S_SPAWN8_NS + 100);
        SetMapSprite(ARequest.MapSpot, 0);
      end;
    GREED_S_EXIT:
      Result := SpawnExit(ARequest);
  end;
end;

function TGreedSpawner.SpawnSprite(AValue: Integer; AX, AY, AZ, AZAdjust: TGreedFixed; AAngle, AAngle2: Integer;
  AActive: Boolean; ASpawnId: Integer): Integer;
var
  LRequest: TGreedSpawnRequest;
  LSprite: PGreedSprite;
begin
  LRequest.Value := AValue;
  LRequest.X := AX;
  LRequest.Y := AY;
  LRequest.Z := AZ;
  LRequest.ZAdjust := AZAdjust;
  LRequest.Angle := AAngle and GREED_ANGLES;
  LRequest.Angle2 := AAngle2;
  LRequest.Active := AActive;
  LRequest.SpawnId := ASpawnId;
  LRequest.TileX := AX div GREED_FRACTILEUNIT;
  LRequest.TileY := AY div GREED_FRACTILEUNIT;
  LRequest.MapSpot := LRequest.TileY * GREED_MAP_SIZE + LRequest.TileX;
  Result := SpawnByValue(LRequest);
  if Result = GREED_POOL_NIL then
    Exit;
  LSprite := PGreedSprite(FState.Sprites.Item(Result));
  if FState.MidgetMode then
    Inc(LSprite^.Scale);
  LSprite^.OldX := LSprite^.X;
  LSprite^.OldY := LSprite^.Y;
  LSprite^.OldZ := LSprite^.Z;
  LSprite^.OldAngle := LSprite^.Angle;
  LSprite^.OldAngle2 := LSprite^.Angle2;
  LSprite^.OldFloorZ := FloorZ(LSprite^.X, LSprite^.Y);
  LSprite^.NewX := LSprite^.X;
  LSprite^.NewY := LSprite^.Y;
  LSprite^.NewZ := LSprite^.Z;
  LSprite^.NewAngle := LSprite^.Angle;
  LSprite^.NewAngle2 := LSprite^.Angle2;
  LSprite^.NewFloorZ := LSprite^.OldFloorZ;
end;

end.
