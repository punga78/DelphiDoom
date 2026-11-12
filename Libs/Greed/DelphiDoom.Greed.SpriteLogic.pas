{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the thinking of the sprites at each tic          }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): MoveSprites, Int0, Int5 ..  }
{  Int10, HitSprite, ShowWallPuff, ActivateSprites, ActivationSound and         }
{  RecreateMapSprites of sprites.pas                                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.SpriteLogic;

// the positions are 16.16 fixed point numbers and the angles wrap: the arithmetic is the one of the original
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.World.Intf,
  DelphiDoom.Greed.Random, DelphiDoom.Greed.Game.Intf, DelphiDoom.Greed.Game.State,
  DelphiDoom.Greed.SpriteLogic.Intf, DelphiDoom.Greed.SpriteMovement, DelphiDoom.Greed.SpriteScan;

type
  /// <summary>
  ///   What every sprite of the level does in a tic of the game (MoveSprites), by its Intelligence: 0 bullets,
  ///   explosions and parts that fly a unit at a time and hit walls, sprites and the player; 5 priests and
  ///   viscount lords, 8 prisoners, 9 the big guards, 10 the other monsters (they turn to the player, look for
  ///   it along rows, columns and diagonals, shoot, walk and wake the others); 6 mines and instawalls; 7 the
  ///   clones of the player; 128 what has fallen and lies on the floor. A sprite that is not active wakes up when
  ///   the player is closer than 6 tiles and wakes the ones around it. At the end the tiles of the living
  ///   monsters are written in mapsprites (RecreateMapSprites).
  ///   The global msprite of the original is State.MSprite (the index in the pool) while a sprite thinks; the
  ///   pointers to sprites are indices of the pool, and the list is walked as the original does when a sprite is
  ///   removed or new ones are appended while it is walked. The net game is not ported: the branches of netmode
  ///   and the calls NetDeath and NetGetClosestPlayer are not here (State.NetMode stays false), the checks on the
  ///   tiles of the net players (SM_NETPLAYER) are.
  ///   The light of the tiles that hot sprites change (reallight) is RealLight: the logic has its own array, the
  ///   game can point it to the one of the renderer. A tile outside the map reads as 0 and is not written
  /// </summary>
  TGreedSpriteLogic = class
  strict private
    FState: TGreedGameState;
    FSpawner: IGreedSpawner;
    FRandom: IGreedRandom;
    FSound: IGreedGameSound;
    FHealth: IGreedPlayerHealth;
    FKiller: IGreedSpriteKiller;
    FHost: IGreedSpriteHost;
    FMovement: TGreedSpriteMovement;
    FScan: TGreedSpriteScan;
    FOwnLights: TGreedTileLights;
    FRealLight: PGreedTileLights;
    // msprite as a pointer; State.MSprite is its index
    FSprite: PGreedSprite;
    procedure Select(AIndex: Integer);
    procedure SetRealLight(AValue: PGreedTileLights);
    procedure PutMapSprite(ASpot: Integer; AValue: Byte);
    function Spawn(AKind: Integer; AX, AY, AZ, AZAdjust: TGreedFixed; AAngle, AAngle2: Integer; AActive: Boolean;
      ASpawnId: Integer): Integer;
    procedure SpawnBlood(ACount: Integer);
    procedure SpawnRing(AKind, ACount, AAngle2, AMaxMove: Integer);
    procedure Explode;
    procedure WakeSound(ASprite: PGreedSprite);
    procedure ShowWallPuff;
    procedure HitSprite(ASprite: PGreedSprite);
    procedure HitNetPlayers(var AKilled, ABlood: Boolean);
    procedure HitSprites(var AKilled, ABlood: Boolean);
    procedure HitPlayer(var AKilled: Boolean);
    function Int0: Boolean;
    procedure AcquireTarget;
    function CompassAngle(ATargetX, ATargetY, ASourceX, ASourceY: Integer): Integer;
    function SeesTarget(ALimit, ASourceX, ASourceY, APlayerX, APlayerY: Integer;
      out ATargetX, ATargetY: Integer): Boolean;
    function HasMoved: Boolean;
    procedure RememberPosition;
    procedure WalkAndSettle;
    procedure RingOfBullets;
    procedure Int5;
    function Int6: Boolean;
    procedure Int7;
    procedure Int8;
    procedure Int9;
    procedure Int10;
    procedure SaveOld;
    procedure SaveNew;
    procedure Heat(ACools: Boolean);
  public
    /// <summary>
    ///   The state gives the world, the pool of the sprites, the player and the clocks. EArgumentNilException if
    ///   an argument is nil
    /// </summary>
    constructor Create(const AState: TGreedGameState; const ASpawner: IGreedSpawner; const ARandom: IGreedRandom;
      const ASound: IGreedGameSound; const AHealth: IGreedPlayerHealth; const AKiller: IGreedSpriteKiller;
      const AHost: IGreedSpriteHost);
    destructor Destroy; override;
    /// <summary>MoveSprites: a tic of every sprite of the list, then RecreateMapSprites</summary>
    procedure MoveSprites;
    /// <summary>ActivationSound(sp): the voice of a monster that wakes up; ASprite is the index in the pool</summary>
    procedure ActivationSound(ASprite: Integer);
    /// <summary>
    ///   ActivateSprites(sx, sy): wakes the sleeping sprites that can move and are closer than 5 tiles, and from
    ///   each of them the ones around it (a chain reaction)
    /// </summary>
    procedure ActivateSprites(ATileX, ATileY: Integer);
    /// <summary>RecreateMapSprites: the tiles with 1 are cleared and the ones of the living monsters get 1</summary>
    procedure RecreateMapSprites;
    /// <summary>The SP_ functions; SP_Thrust on the probe of the state is what the weapons of the player use</summary>
    property Movement: TGreedSpriteMovement read FMovement;
    property Scan: TGreedSpriteScan read FScan;
    /// <summary>reallight; nil gives back the array of the logic</summary>
    property RealLight: PGreedTileLights read FRealLight write SetRealLight;
  end;

implementation

uses
  DelphiDoom.Greed.FixedMath, DelphiDoom.MathCore.FixedMath, DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.Terrain,
  DelphiDoom.Greed.Game.Constants, DelphiDoom.Greed.Game.Tables;

const
  // the angles of the compass
  ANGLE_EAST = 0;
  ANGLE_NORTH = 256;
  ANGLE_WEST = 512;
  ANGLE_SOUTH = 768;
  DEGREE45 = 128;
  // TICRATE
  TICS_PER_SECOND = 70;
  MAP_SPRITE_MONSTER = 1;
  // spawnid of what no player made
  SPAWN_ID_NOBODY = 255;
  WAKE_VARIATION = 7;
  EXPLODE_VARIATION = 15;
  // a sleeping sprite wakes when the player is closer than this, and wakes the others closer than the second
  WAKE_TILES = 6;
  CHAIN_TILES = 5;
  FALL_STEP = 16 * GREED_FRACUNIT;

{ TGreedSpriteLogic }

constructor TGreedSpriteLogic.Create(const AState: TGreedGameState; const ASpawner: IGreedSpawner;
  const ARandom: IGreedRandom; const ASound: IGreedGameSound; const AHealth: IGreedPlayerHealth;
  const AKiller: IGreedSpriteKiller; const AHost: IGreedSpriteHost);
begin
  inherited Create;
  if not Assigned(AState) then
    raise EArgumentNilException.Create('AState');
  if not Assigned(ASpawner) then
    raise EArgumentNilException.Create('ASpawner');
  if not Assigned(ARandom) then
    raise EArgumentNilException.Create('ARandom');
  if not Assigned(ASound) then
    raise EArgumentNilException.Create('ASound');
  if not Assigned(AHealth) then
    raise EArgumentNilException.Create('AHealth');
  if not Assigned(AKiller) then
    raise EArgumentNilException.Create('AKiller');
  if not Assigned(AHost) then
    raise EArgumentNilException.Create('AHost');
  FState := AState;
  FSpawner := ASpawner;
  FRandom := ARandom;
  FSound := ASound;
  FHealth := AHealth;
  FKiller := AKiller;
  FHost := AHost;
  FMovement := TGreedSpriteMovement.Create(AState, ASound);
  FScan := TGreedSpriteScan.Create(AState, ARandom);
  FRealLight := @FOwnLights;
end;

destructor TGreedSpriteLogic.Destroy;
begin
  FScan.Free;
  FMovement.Free;
  inherited Destroy;
end;

procedure TGreedSpriteLogic.SetRealLight(AValue: PGreedTileLights);
begin
  if Assigned(AValue) then
    FRealLight := AValue
  else
    FRealLight := @FOwnLights;
end;

procedure TGreedSpriteLogic.Select(AIndex: Integer);
begin
  FState.MSprite := AIndex;
  FSprite := PGreedSprite(FState.Sprites.Item(AIndex));
end;

procedure TGreedSpriteLogic.PutMapSprite(ASpot: Integer; AValue: Byte);
begin
  if (ASpot >= 0) and (ASpot < GREED_MAP_TILES) then
    FState.World.SetValue(gpMapSprites, ASpot, AValue);
end;

function TGreedSpriteLogic.Spawn(AKind: Integer; AX, AY, AZ, AZAdjust: TGreedFixed; AAngle, AAngle2: Integer;
  AActive: Boolean; ASpawnId: Integer): Integer;
begin
  Result := FSpawner.SpawnSprite(AKind, AX, AY, AZ, AZAdjust, AAngle, AAngle2, AActive, ASpawnId);
end;

procedure TGreedSpriteLogic.SpawnBlood(ACount: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 1 to ACount do
    Spawn(GREED_S_BLOODSPLAT, FSprite^.X, FSprite^.Y, FSprite^.Z, FSprite^.ZAdjust, 0, 0, False, 0);
end;

// ACount bullets of a kind all around the sprite, 20 units above it; AMaxMove 0 leaves the one of the spawner
procedure TGreedSpriteLogic.SpawnRing(AKind, ACount, AAngle2, AMaxMove: Integer);
var
  LIndex, LAngle, LStep, LNew: Integer;
  LBullet: PGreedSprite;
begin
  LStep := GREED_ANGLES div ACount;
  LAngle := 0;
  for LIndex := 0 to ACount - 1 do
  begin
    LNew := Spawn(AKind, FSprite^.X, FSprite^.Y, FSprite^.Z, 20 * GREED_FRACUNIT, LAngle, AAngle2, True,
      FSprite^.SpawnId);
    // the original would write through a nil pointer
    if (AMaxMove <> 0) and (LNew <> GREED_POOL_NIL) then
    begin
      LBullet := PGreedSprite(FState.Sprites.Item(LNew));
      LBullet^.MaxMove := AMaxMove;
      LBullet^.StartSpot := -1;
    end;
    LAngle := LAngle + LStep;
  end;
end;

procedure TGreedSpriteLogic.Explode;
begin
  Spawn(GREED_S_EXPLODE, FSprite^.X, FSprite^.Y, FSprite^.Z, 0, 0, 0, True, SPAWN_ID_NOBODY);
  FSound.SoundEffect(GREED_SN_EXPLODE1 + (FRandom.Next and 1), EXPLODE_VARIATION, FSprite^.X, FSprite^.Y);
end;

procedure TGreedSpriteLogic.WakeSound(ASprite: PGreedSprite);
var
  LSound: Integer;
begin
  case ASprite^.Kind of
    GREED_S_MONSTER1: LSound := GREED_SN_MON1_WAKE;
    GREED_S_MONSTER2: LSound := GREED_SN_MON2_WAKE;
    GREED_S_MONSTER3: LSound := GREED_SN_MON3_WAKE;
    GREED_S_MONSTER4: LSound := GREED_SN_MON4_WAKE;
    GREED_S_MONSTER5: LSound := GREED_SN_MON5_WAKE;
    GREED_S_MONSTER6: LSound := GREED_SN_MON6_WAKE;
    GREED_S_MONSTER7: LSound := GREED_SN_MON7_WAKE;
    GREED_S_MONSTER8: LSound := GREED_SN_MON8_WAKE;
    GREED_S_MONSTER9: LSound := GREED_SN_MON9_WAKE;
    GREED_S_MONSTER10: LSound := GREED_SN_MON10_WAKE;
    GREED_S_MONSTER11: LSound := GREED_SN_MON11_WAKE;
    GREED_S_MONSTER12: LSound := GREED_SN_MON12_WAKE;
    GREED_S_MONSTER13: LSound := GREED_SN_MON13_WAKE;
    GREED_S_MONSTER14: LSound := GREED_SN_MON14_WAKE;
    GREED_S_MONSTER15: LSound := GREED_SN_MON15_WAKE;
  else
    Exit;
  end;
  FSound.SoundEffect(LSound, WAKE_VARIATION, ASprite^.X, ASprite^.Y);
end;

procedure TGreedSpriteLogic.ActivationSound(ASprite: Integer);
begin
  WakeSound(PGreedSprite(FState.Sprites.Item(ASprite)));
end;

procedure TGreedSpriteLogic.ActivateSprites(ATileX, ATileY: Integer);
var
  LIndex, LX, LY: Integer;
  LSprite: PGreedSprite;
begin
  LIndex := FState.Sprites.First;
  while LIndex <> GREED_POOL_NIL do
  begin
    LSprite := PGreedSprite(FState.Sprites.Item(LIndex));
    if (not LSprite^.Active) and (LSprite^.MoveSpeed <> 0) then
    begin
      LX := LSprite^.X div GREED_FRACTILEUNIT;
      LY := LSprite^.Y div GREED_FRACTILEUNIT;
      if (Abs(LX - ATileX) < CHAIN_TILES) and (Abs(LY - ATileY) < CHAIN_TILES) then
      begin
        LSprite^.Active := True;
        LSprite^.ActionTime := FState.TimeCount + 40;
        // twice, as the original
        WakeSound(LSprite);
        WakeSound(LSprite);
        ActivateSprites(LX, LY);
      end;
    end;
    LIndex := FState.Sprites.Next(LIndex);
  end;
end;

procedure TGreedSpriteLogic.ShowWallPuff;
var
  LKind: Integer;
begin
  case FSprite^.Kind of
    GREED_S_BULLET3, GREED_S_BULLET12, GREED_S_BULLET17, GREED_S_MONSTERBULLET2, GREED_S_MONSTERBULLET4,
    GREED_S_MONSTERBULLET6, GREED_S_MONSTERBULLET8, GREED_S_GRENADEBULLET:
      LKind := GREED_S_SMALLEXPLODE;
    GREED_S_BULLET4, GREED_S_MONSTERBULLET5, GREED_S_MONSTERBULLET11:
      LKind := GREED_S_PLASMAWALLPUFF;
    GREED_S_HANDBULLET, GREED_S_BLOODSPLAT, GREED_S_BULLET7, GREED_S_MONSTERBULLET7, GREED_S_MONSTERBULLET10,
    GREED_S_MONSTERBULLET12, GREED_S_MONSTERBULLET15, GREED_S_SOULBULLET:
      Exit;
    GREED_S_BULLET9:
      LKind := GREED_S_ARROWPUFF;
    GREED_S_BULLET10, GREED_S_BULLET18:
      LKind := GREED_S_GREENPUFF;
    GREED_S_MINEBULLET:
      LKind := GREED_S_MINEPUFF;
  else
    LKind := GREED_S_WALLPUFF;
  end;
  Spawn(LKind, FSprite^.X, FSprite^.Y, FSprite^.Z, FSprite^.ZAdjust, 0, 0, False, 0);
  ActivateSprites(FSprite^.X div GREED_FRACTILEUNIT, FSprite^.Y div GREED_FRACTILEUNIT);
end;

// What a sprite that was hit shows: the picture of pain and the blood, or the puff of the machines
procedure TGreedSpriteLogic.HitSprite(ASprite: PGreedSprite);
var
  LPainPic: Integer;
begin
  case ASprite^.Kind of
    GREED_S_CLONE:
      LPainPic := 32;
    GREED_S_MONSTER1, GREED_S_MONSTER2, GREED_S_MONSTER7, GREED_S_MONSTER9, GREED_S_MONSTER10, GREED_S_MONSTER12,
    GREED_S_MONSTER13, GREED_S_MONSTER14, GREED_S_MONSTER15:
      LPainPic := 40;
    GREED_S_MONSTER3, GREED_S_MONSTER4, GREED_S_MONSTER5, GREED_S_MONSTER6, GREED_S_MONSTER8, GREED_S_MONSTER11:
      begin
        ShowWallPuff;
        Exit;
      end;
  else
    Exit;
  end;
  if not ASprite^.Active then
  begin
    ActivateSprites(ASprite^.X div GREED_FRACTILEUNIT, ASprite^.Y div GREED_FRACTILEUNIT);
    ASprite^.Active := True;
  end;
  ASprite^.ModeTime := FState.TimeCount + 8;
  ASprite^.BasePic := ASprite^.StartPic + LPainPic;
  if FSprite^.Kind <> GREED_S_BULLET17 then
    SpawnBlood(6)
  else
    SpawnBlood(1);
end;

// Int0, the tile that was hit is the one of a net player: the sprites of that tile
procedure TGreedSpriteLogic.HitNetPlayers(var AKilled, ABlood: Boolean);
var
  LIndex, LSpot: Integer;
  LOther: PGreedSprite;
begin
  LIndex := FState.Sprites.First;
  while LIndex <> GREED_POOL_NIL do
  begin
    LOther := PGreedSprite(FState.Sprites.Item(LIndex));
    if LOther <> FSprite then
    begin
      LSpot := (LOther^.Y div GREED_FRACTILEUNIT) * GREED_MAP_SIZE + (LOther^.X div GREED_FRACTILEUNIT);
      if LSpot = FState.SpriteLoc then
      begin
        if (FSprite^.Z < LOther^.Z) or (FSprite^.Z > LOther^.Z + LOther^.Height) or
          (LOther^.Kind <> GREED_S_NETPLAYER) then
          Break;
        SpawnBlood(4);
        ABlood := True;
        AKilled := True;
      end;
    end;
    LIndex := FState.Sprites.Next(LIndex);
  end;
end;

// Int0, a solid sprite is on the tile that was hit: the first one with hit points that the shot touches
procedure TGreedSpriteLogic.HitSprites(var AKilled, ABlood: Boolean);
var
  LIndex, LSpot, LOldAngle, LShooter: Integer;
  LOldSpeed: TGreedFixed;
  LOldFall: Boolean;
  LOther, LBullet: PGreedSprite;
begin
  LIndex := FState.Sprites.First;
  while LIndex <> GREED_POOL_NIL do
  begin
    LOther := PGreedSprite(FState.Sprites.Item(LIndex));
    if LOther <> FSprite then
    begin
      LSpot := (LOther^.Y div GREED_FRACTILEUNIT) * GREED_MAP_SIZE + (LOther^.X div GREED_FRACTILEUNIT);
      if (LSpot = FState.SpriteLoc) and (FSprite^.Z >= LOther^.Z) and
        (FSprite^.Z <= LOther^.Z + LOther^.Height) and (LOther^.HitPoints <> 0) then
      begin
        if LOther^.Kind <> GREED_S_MONSTER5 then
          LOther^.ActionTime := LOther^.ActionTime + 15
        else
          LOther^.ActionTime := LOther^.ActionTime + 5;
        LOther^.HitPoints := LOther^.HitPoints - FSprite^.Damage;
        if FSprite^.SpawnId = SPAWN_ID_NOBODY then
          Inc(LOther^.Enraged);
        if (FSprite^.Kind = GREED_S_SOULBULLET) and (FSprite^.SpawnId = FState.PlayerNum) then
        begin
          FHealth.Heal(FSprite^.Damage div 2);
          FHealth.MedPaks(FSprite^.Damage div 2);
        end;
        AKilled := True;
        if LOther^.HitPoints <= 0 then
        begin
          if (FSprite^.SpawnId = FState.PlayerNum) or (FSprite^.SpawnId - 200 = FState.PlayerNum) then
          begin
            Inc(FState.Player.BodyCount);
            FHealth.AddScore(LOther^.Score);
          end;
          PutMapSprite(FState.SpriteLoc, 0);
          ABlood := True;
          HitSprite(LOther);
          FKiller.KillSprite(LIndex, FSprite^.Kind);
        end
        else if FSprite^.Damage <> 0 then
        begin
          // the shot pushes the sprite back: for a moment msprite is the sprite that was hit
          LOldAngle := LOther^.Angle;
          LOldSpeed := LOther^.MoveSpeed;
          LOther^.Angle := FSprite^.Angle;
          LOther^.MoveSpeed := (FSprite^.Damage div 4) * GREED_FRACUNIT;
          LBullet := FSprite;
          LShooter := FState.MSprite;
          FSprite := LOther;
          FState.MSprite := LIndex;
          LOldFall := LOther^.NoFalling;
          LOther^.NoFalling := False;
          FMovement.Thrust2(LOther);
          LOther^.NoFalling := LOldFall;
          FSprite := LBullet;
          FState.MSprite := LShooter;
          LOther^.Angle := LOldAngle;
          LOther^.MoveSpeed := LOldSpeed;
          ABlood := True;
          HitSprite(LOther);
        end;
        Break;
      end;
    end;
    LIndex := FState.Sprites.Next(LIndex);
  end;
end;

procedure TGreedSpriteLogic.HitPlayer(var AKilled: Boolean);
begin
  // don't keep hitting
  if FState.Player.Angst <> 0 then
    FHealth.Hurt(FSprite^.Damage);
  FHost.ThrustPlayer(FSprite^.Angle, FSprite^.Damage shl (GREED_FRACBITS - 3));
  FState.PlayerHit := False;
  AKilled := True;
  if FSprite^.Damage > 50 then
  begin
    FState.Player.Angle := FState.Player.Angle - 15 + (FRandom.Next and 31);
    FState.Player.Angle := FState.Player.Angle and GREED_ANGLES;
    FState.PlayerAngle64 := FState.Player.Angle * 64;
  end;
end;

// control of bullets, explosions, and other objects (not monsters!!). True: the sprite is to be removed
function TGreedSpriteLogic.Int0: Boolean;
var
  LCounter, LHit: Integer;
  LKilled, LBlood: Boolean;
begin
  LCounter := 0;
  LKilled := False;
  if FSprite^.Kind = GREED_S_GRENADE then
    FSprite^.Angle2 := FSprite^.Angle2 - 4
  else if ((FSprite^.Kind = GREED_S_BLOODSPLAT) or (FSprite^.Kind = GREED_S_METALPARTS)) and
    ((FSprite^.Angle2 < ANGLE_NORTH) or (FSprite^.Angle2 > ANGLE_SOUTH)) then
    FSprite^.Angle2 := FSprite^.Angle2 - 32;
  if FSprite^.MaxMove <> 0 then
  begin
    Dec(FSprite^.MaxMove);
    if FSprite^.MaxMove <= 0 then
    begin
      ShowWallPuff;
      Exit(True);
    end;
  end;
  if (FSprite^.Kind = GREED_S_MONSTERBULLET4) or (FSprite^.Kind = GREED_S_MONSTERBULLET6) or
    (FSprite^.Kind = GREED_S_BULLET17) then
    Spawn(GREED_S_WALLPUFF, FSprite^.X, FSprite^.Y, FSprite^.Z, FSprite^.ZAdjust, 0, 0, False, 0);
  LBlood := False;
  // MoveSpeed of a bullet is the number of steps of a unit in a tic
  while LCounter < FSprite^.MoveSpeed do
  begin
    Inc(LCounter);
    LHit := FMovement.Thrust(FSprite);
    if FSprite^.Kind = GREED_S_BULLET3 then
      FSprite^.Z := TGreedTerrain.FloorZ(FState.World, FSprite^.X, FSprite^.Y) + (20 * GREED_FRACUNIT);
    if LHit <> 0 then
    begin
      if FSprite^.Kind = GREED_S_BLOODSPLAT then
      begin
        if LHit = 2 then
          Exit(True);
        FState.SpriteHit := False;
        FState.PlayerHit := False;
      end
      else if (FSprite^.Kind = GREED_S_METALPARTS) and (LHit = 2) then
      begin
        FState.PlayerHit := False;
        Exit(True);
      end;
      if FState.SpriteHit then
      begin
        if FState.World.GetValue(gpMapSprites, FState.SpriteLoc) = GREED_SM_NETPLAYER then
          HitNetPlayers(LKilled, LBlood)
        else
          HitSprites(LKilled, LBlood);
      end
      else if FState.PlayerHit and (FSprite^.Z > FState.Player.Z - FState.Player.Height) and
        (FSprite^.Z < FState.Player.Z) then
        HitPlayer(LKilled);
      if LHit = 2 then
        LKilled := True;
      if LKilled then
      begin
        if not LBlood then
          ShowWallPuff;
        Break;
      end;
    end;
  end;
  if LKilled and (FSprite^.Kind = GREED_S_GRENADE) then
  begin
    SpawnRing(GREED_S_GRENADEBULLET, 12, 0, 3);
    SpawnRing(GREED_S_GRENADEBULLET, 8, 64, 2);
    SpawnRing(GREED_S_GRENADEBULLET, 8, -64, 2);
    Explode;
  end
  else if LKilled and (FSprite^.Kind = GREED_S_BULLET17) then
  begin
    SpawnRing(GREED_S_GRENADEBULLET, 8, 0, 3);
    SpawnRing(GREED_S_GRENADEBULLET, 6, 64, 2);
    SpawnRing(GREED_S_GRENADEBULLET, 6, -64, 2);
    Explode;
  end;
  Result := LKilled;
end;

// The target of the monsters: the player, or the corner of the map when the player is invisible
procedure TGreedSpriteLogic.AcquireTarget;
begin
  if FState.SpecialEffect = GREED_SE_INVISIBILITY then
  begin
    FState.TargX := 0;
    FState.TargY := 0;
    FState.TargZ := 0;
  end
  else
  begin
    FState.TargX := FState.Player.X;
    FState.TargY := FState.Player.Y;
    FState.TargZ := FState.Player.Z;
  end;
end;

// One of the eight directions from a tile to another; -1 (which becomes 1023) when the tiles are the same
function TGreedSpriteLogic.CompassAngle(ATargetX, ATargetY, ASourceX, ASourceY: Integer): Integer;
begin
  if ATargetX > ASourceX then
    Result := ANGLE_EAST
  else if ATargetX < ASourceX then
    Result := ANGLE_WEST
  else
    Result := -1;
  if ATargetY < ASourceY then
  begin
    if Result = ANGLE_EAST then
      Result := Result + DEGREE45
    else if Result = ANGLE_WEST then
      Result := Result - DEGREE45
    else
      Result := ANGLE_NORTH;
  end
  else if ATargetY > ASourceY then
  begin
    if Result = ANGLE_EAST then
      Result := Result - DEGREE45
    else if Result = ANGLE_WEST then
      Result := Result + DEGREE45
    else
      Result := ANGLE_SOUTH;
  end;
end;

function TGreedSpriteLogic.SeesTarget(ALimit, ASourceX, ASourceY, APlayerX, APlayerY: Integer;
  out ATargetX, ATargetY: Integer): Boolean;
begin
  ATargetX := APlayerX;
  ATargetY := APlayerY;
  Result := (FScan.ScanX(FSprite, ALimit, ASourceX, ASourceY, APlayerX, APlayerY, ATargetX, ATargetY) > 1) or
    (FScan.ScanY(FSprite, ALimit, ASourceX, ASourceY, APlayerX, APlayerY, ATargetX, ATargetY) > 1) or
    (FScan.ScanAngle(FSprite, ALimit, ASourceX, ASourceY, APlayerX, APlayerY, ATargetX, ATargetY) > 1);
end;

function TGreedSpriteLogic.HasMoved: Boolean;
begin
  Result := (FSprite^.LastX <> FSprite^.X) or (FSprite^.LastY <> FSprite^.Y);
end;

procedure TGreedSpriteLogic.RememberPosition;
begin
  FSprite^.LastY := FSprite^.Y;
  FSprite^.LastX := FSprite^.X;
end;

// The end of the thinking of who walks: a step (a turn of 45 degrees if it did not go straight), then the floor
procedure TGreedSpriteLogic.WalkAndSettle;
var
  LAngle: Integer;
  LFloorZ: TGreedFixed;
begin
  if (FState.TimeCount > FSprite^.ActionTime) and (FMovement.Thrust2(FSprite) <> 1) then
  begin
    LAngle := FSprite^.Angle + DEGREE45;
    FSprite^.Angle := LAngle and GREED_ANGLES;
  end;
  LFloorZ := TGreedTerrain.FloorZ(FState.World, FSprite^.X, FSprite^.Y);
  if LFloorZ + FSprite^.ZAdjust < FSprite^.Z then
    FSprite^.Z := FSprite^.Z - FALL_STEP;
  if LFloorZ + FSprite^.ZAdjust > FSprite^.Z then
    FSprite^.Z := LFloorZ + FSprite^.ZAdjust;
end;

// priests / viscount lords
procedure TGreedSpriteLogic.Int5;
var
  LAngle, LSourceX, LSourceY, LPlayerX, LPlayerY, LTargetX, LTargetY, LFireAngle, LSpread: Integer;
  LOldSpeed, LFireHeight: TGreedFixed;
begin
  LSourceX := FSprite^.X div GREED_FRACTILEUNIT;
  LSourceY := FSprite^.Y div GREED_FRACTILEUNIT;
  AcquireTarget;
  LPlayerX := FState.TargX div GREED_FRACTILEUNIT;
  LPlayerY := FState.TargY div GREED_FRACTILEUNIT;
  LOldSpeed := FSprite^.MoveSpeed;
  if (Abs(LPlayerX - LSourceX) < 6) and (Abs(LPlayerY - LSourceY) < 6) then
    FSprite^.MoveSpeed := FSprite^.MoveSpeed * 2;
  if FState.TimeCount > FSprite^.MoveTime then
  begin
    LAngle := CompassAngle(LPlayerX, LPlayerY, LSourceX, LSourceY) - DEGREE45 + FRandom.Next;
    FSprite^.Angle := LAngle and GREED_ANGLES;
    FSprite^.MoveTime := FState.TimeCount + 2 * TICS_PER_SECOND;
  end;
  if (FState.TimeCount > FSprite^.FireTime) and (FState.TimeCount > FSprite^.ScanTime) then
  begin
    if SeesTarget(10, LSourceX, LSourceY, LPlayerX, LPlayerY, LTargetX, LTargetY) then
    begin
      FSprite^.Angle := CompassAngle(LTargetX, LTargetY, LSourceX, LSourceY) and GREED_ANGLES;
      FSprite^.BasePic := FSprite^.StartPic + 24;
      FSprite^.MoveMode := 4;
      FSprite^.FireTime := FState.TimeCount + (40 + 5 * FState.Player.Difficulty);
      FSprite^.ActionTime := FState.TimeCount + 30;
      FSprite^.ModeTime := FState.TimeCount + 15;
    end;
    FSprite^.ScanTime := FState.TimeCount + 30;
  end;
  if FState.TimeCount > FSprite^.ModeTime then
  begin
    FSprite^.ModeTime := FState.TimeCount + 10;
    case FSprite^.MoveMode of
      0, 1: // left, mid
        if HasMoved then
        begin
          Inc(FSprite^.MoveMode);
          FSprite^.BasePic := FSprite^.StartPic + FSprite^.MoveMode * 8;
          RememberPosition;
        end;
      2: // right
        if HasMoved then
        begin
          FSprite^.BasePic := FSprite^.StartPic + 8;
          Inc(FSprite^.MoveMode);
          RememberPosition;
        end;
      3: // mid #2
        if HasMoved then
        begin
          FSprite^.MoveMode := 0;
          FSprite^.BasePic := FSprite^.StartPic;
          RememberPosition;
        end;
      4: // fire #1
        if SeesTarget(10, LSourceX, LSourceY, LPlayerX, LPlayerY, LTargetX, LTargetY) then
        begin
          FSprite^.Angle := CompassAngle(LTargetX, LTargetY, LSourceX, LSourceY) and GREED_ANGLES;
          FSprite^.MoveMode := 5;
          FSprite^.BasePic := FSprite^.StartPic + 32;
          if FSprite^.Kind = GREED_S_MONSTER7 then
            LFireHeight := 15 * GREED_FRACUNIT
          else
            LFireHeight := 40 * GREED_FRACUNIT;
          LFireAngle := FScan.GetFireAngle(FSprite, LFireHeight, LTargetX, LTargetY, FState.TargX, FState.TargY,
            FState.TargZ) - 15 + (FRandom.Next and 31);
          LSpread := FSprite^.Angle - 15 + (FRandom.Next and 31);
          Spawn(FSprite^.Bullet, FSprite^.X, FSprite^.Y, FSprite^.Z, LFireHeight, LSpread, LFireAngle, True,
            SPAWN_ID_NOBODY);
          FSprite^.ModeTime := FSprite^.ModeTime + 8;
        end
        else
        begin
          FSprite^.MoveMode := 0;
          FSprite^.BasePic := FSprite^.StartPic;
        end;
      5: // fire #2
        begin
          FSprite^.MoveMode := 0;
          FSprite^.BasePic := FSprite^.StartPic;
        end;
    end;
  end;
  WalkAndSettle;
  FSprite^.MoveSpeed := LOldSpeed;
  if FRandom.Next >= 255 then
    WakeSound(FSprite);
end;

// intelligence for mines. True: the sprite is to be removed
function TGreedSpriteLogic.Int6: Boolean;
var
  LIndex, LRow, LColumn, LX, LY, LOtherX, LOtherY: Integer;
  LActivate: Boolean;
  LOther: PGreedSprite;
begin
  Result := False;
  // now active
  if FState.TimeCount <= FSprite^.ActionTime then
    Exit;
  if FSprite^.Kind = GREED_S_TIMEMINE then
  begin
    SpawnRing(GREED_S_MINEBULLET, 20, 0, 0);
    Explode;
    Result := True;
  end
  else if FSprite^.Kind = GREED_S_PROXMINE then
  begin
    if FRandom.Next and 1 <> 0 then
      FSprite^.Angle := FSprite^.Angle + 8
    else
      FSprite^.Angle := FSprite^.Angle - 8;
    FSprite^.Angle := FSprite^.Angle and GREED_ANGLES;
    LX := FSprite^.X div GREED_FRACTILEUNIT;
    LY := FSprite^.Y div GREED_FRACTILEUNIT;
    LActivate := (Abs(LX - (FState.Player.X div GREED_FRACTILEUNIT)) < 2) and
      (Abs(LY - (FState.Player.Y div GREED_FRACTILEUNIT)) < 2);
    if not LActivate then
    begin
      LIndex := FState.Sprites.First;
      while LIndex <> GREED_POOL_NIL do
      begin
        LOther := PGreedSprite(FState.Sprites.Item(LIndex));
        if LOther^.HitPoints <> 0 then
        begin
          LOtherX := LOther^.X div GREED_FRACTILEUNIT;
          LOtherY := LOther^.Y div GREED_FRACTILEUNIT;
          if (Abs(LX - LOtherX) < 2) and (Abs(LY - LOtherY) < 2) then
          begin
            LActivate := True;
            Break;
          end;
        end;
        LIndex := FState.Sprites.Next(LIndex);
      end;
    end;
    for LRow := -1 to 1 do
      for LColumn := -1 to 1 do
        if FState.World.GetValue(gpMapSprites, (LRow + LY) * GREED_MAP_SIZE + LColumn + LX) = GREED_SM_NETPLAYER then
          LActivate := True;
    if LActivate then
    begin
      SpawnRing(GREED_S_MINEBULLET, 16, 0, 0);
      Explode;
      Result := True;
    end;
  end
  else if FSprite^.Kind = GREED_S_INSTAWALL then
  begin
    PutMapSprite((FSprite^.Y div GREED_FRACTILEUNIT) * GREED_MAP_SIZE + (FSprite^.X div GREED_FRACTILEUNIT), 0);
    Result := True;
  end;
end;

// clone ai
procedure TGreedSpriteLogic.Int7;
var
  LAngle, LSourceX, LSourceY, LTargetX, LTargetY, LFireAngle, LChoice: Integer;
  LFireHeight: TGreedFixed;
  LFires: Boolean;
begin
  LSourceX := FSprite^.X div GREED_FRACTILEUNIT;
  LSourceY := FSprite^.Y div GREED_FRACTILEUNIT;
  if FState.TimeCount > FSprite^.MoveTime then
  begin
    LAngle := FSprite^.Angle - DEGREE45;
    LChoice := FRandom.Next mod 3;
    if LChoice = 1 then
      LAngle := LAngle + DEGREE45
    else if LChoice = 2 then
      LAngle := LAngle + ANGLE_NORTH;
    FSprite^.Angle := LAngle and GREED_ANGLES;
    FSprite^.MoveTime := FState.TimeCount + 250;
  end;
  if (FState.TimeCount > FSprite^.FireTime) and (FState.TimeCount > FSprite^.ScanTime) then
  begin
    LTargetX := LSourceX;
    LTargetY := LSourceY;
    LFires := False;
    // a scan that finds a target gives a tile that is not the one of the clone: the angle is always set
    LAngle := FSprite^.Angle;
    if FScan.CloneScanX(LSourceX, LSourceY, LTargetX) > 1 then
    begin
      if LTargetX > LSourceX then
        LAngle := ANGLE_EAST
      else if LTargetX < LSourceX then
        LAngle := ANGLE_WEST;
      LFires := True;
    end
    else if FScan.CloneScanY(LSourceX, LSourceY, LTargetY) > 1 then
    begin
      if LTargetY > LSourceY then
        LAngle := ANGLE_SOUTH
      else if LTargetY < LSourceY then
        LAngle := ANGLE_NORTH;
      LFires := True;
    end;
    if LFires then
    begin
      FSprite^.Angle := LAngle and GREED_ANGLES;
      FSprite^.MoveMode := 4;
      FSprite^.BasePic := FSprite^.StartPic + 24;
      LFireHeight := 40 * GREED_FRACUNIT;
      LFireAngle := FScan.GetFireAngle(FSprite, LFireHeight, LTargetX, LTargetY, 0, 0, 0);
      Spawn(FSprite^.Bullet, FSprite^.X, FSprite^.Y, FSprite^.Z, LFireHeight, FSprite^.Angle, LFireAngle, True,
        SPAWN_ID_NOBODY);
      FSprite^.ModeTime := FState.TimeCount + 8;
      FSprite^.ActionTime := FState.TimeCount + 30;
      FSprite^.FireTime := FState.TimeCount + 30;
    end;
    FSprite^.ScanTime := FState.TimeCount + 20;
  end;
  if FState.TimeCount > FSprite^.ModeTime then
  begin
    FSprite^.ModeTime := FState.TimeCount + 10;
    case FSprite^.MoveMode of
      0, 1: // left, mid
        if HasMoved then
        begin
          Inc(FSprite^.MoveMode);
          FSprite^.BasePic := FSprite^.StartPic + FSprite^.MoveMode * 8;
          RememberPosition;
        end;
      2: // right
        if HasMoved then
        begin
          FSprite^.BasePic := FSprite^.StartPic + 8;
          Inc(FSprite^.MoveMode);
          RememberPosition;
        end;
      3: // mid #2
        if HasMoved then
        begin
          FSprite^.MoveMode := 0;
          FSprite^.BasePic := FSprite^.StartPic;
          RememberPosition;
        end;
      4: // fire
        begin
          FSprite^.MoveMode := 0;
          FSprite^.BasePic := FSprite^.StartPic;
        end;
    end;
  end;
  WalkAndSettle;
end;

// prisoners
procedure TGreedSpriteLogic.Int8;
var
  LAngle, LSourceX, LSourceY, LPlayerX, LPlayerY, LTargetX, LTargetY, LFireAngle: Integer;
  LOldSpeed, LFireHeight: TGreedFixed;
begin
  LSourceX := FSprite^.X div GREED_FRACTILEUNIT;
  LSourceY := FSprite^.Y div GREED_FRACTILEUNIT;
  AcquireTarget;
  LPlayerX := FState.TargX div GREED_FRACTILEUNIT;
  LPlayerY := FState.TargY div GREED_FRACTILEUNIT;
  LOldSpeed := FSprite^.MoveSpeed;
  if (Abs(LPlayerX - LSourceX) < 6) and (Abs(LPlayerY - LSourceY) < 6) then
    FSprite^.MoveSpeed := FSprite^.MoveSpeed * 2;
  if FState.TimeCount > FSprite^.MoveTime then
  begin
    LAngle := CompassAngle(LPlayerX, LPlayerY, LSourceX, LSourceY) - DEGREE45 + FRandom.Next;
    FSprite^.Angle := LAngle and GREED_ANGLES;
    FSprite^.MoveTime := FState.TimeCount + 350;
  end;
  if (FState.TimeCount > FSprite^.FireTime) and (FState.TimeCount > FSprite^.ScanTime) then
  begin
    if SeesTarget(7, LSourceX, LSourceY, LPlayerX, LPlayerY, LTargetX, LTargetY) then
    begin
      FSprite^.Angle := CompassAngle(LTargetX, LTargetY, LSourceX, LSourceY) and GREED_ANGLES;
      // they hit only from close
      if (Abs(LTargetX - LSourceX) <= 2) and (Abs(LTargetY - LSourceY) <= 2) then
      begin
        FSprite^.BasePic := FSprite^.StartPic + 24;
        FSprite^.MoveMode := 4;
        FSprite^.FireTime := FState.TimeCount + (80 + 5 * FState.Player.Difficulty);
        FSprite^.ActionTime := FState.TimeCount + 30;
        FSprite^.ModeTime := FState.TimeCount + 15;
      end;
    end;
    FSprite^.ScanTime := FState.TimeCount + 45;
  end;
  if FState.TimeCount > FSprite^.ModeTime then
  begin
    FSprite^.ModeTime := FState.TimeCount + 10;
    case FSprite^.MoveMode of
      0, 1: // left, mid
        if HasMoved then
        begin
          Inc(FSprite^.MoveMode);
          FSprite^.BasePic := FSprite^.StartPic + FSprite^.MoveMode * 8;
          RememberPosition;
        end;
      2: // right
        if HasMoved then
        begin
          FSprite^.BasePic := FSprite^.StartPic + 8;
          Inc(FSprite^.MoveMode);
          RememberPosition;
        end;
      3: // mid #2
        if HasMoved then
        begin
          FSprite^.MoveMode := 0;
          FSprite^.BasePic := FSprite^.StartPic;
          RememberPosition;
        end;
      4: // fire #1
        if SeesTarget(7, LSourceX, LSourceY, LPlayerX, LPlayerY, LTargetX, LTargetY) then
        begin
          FSprite^.Angle := CompassAngle(LTargetX, LTargetY, LSourceX, LSourceY) and GREED_ANGLES;
          if (Abs(LTargetX - LSourceX) > 2) or (Abs(LTargetY - LSourceY) > 2) then
          begin
            FSprite^.MoveMode := 0;
            FSprite^.BasePic := FSprite^.StartPic;
          end
          else
          begin
            FSprite^.MoveMode := 5;
            FSprite^.BasePic := FSprite^.StartPic + 32;
            LFireHeight := 40 * GREED_FRACUNIT;
            LFireAngle := FScan.GetFireAngle(FSprite, LFireHeight, LTargetX, LTargetY, FState.TargX, FState.TargY,
              FState.TargZ);
            Spawn(FSprite^.Bullet, FSprite^.X, FSprite^.Y, FSprite^.Z, LFireHeight, FSprite^.Angle, LFireAngle,
              True, SPAWN_ID_NOBODY);
            FSprite^.ModeTime := FSprite^.ModeTime + 8;
          end;
        end
        else
        begin
          FSprite^.MoveMode := 0;
          FSprite^.BasePic := FSprite^.StartPic;
        end;
      5: // fire #2
        begin
          FSprite^.MoveMode := 0;
          FSprite^.BasePic := FSprite^.StartPic;
        end;
    end;
  end;
  WalkAndSettle;
  FSprite^.MoveSpeed := LOldSpeed;
  if FRandom.Next >= 255 then
    WakeSound(FSprite);
end;

// Int9: now and then the big guard shoots all around while it walks
procedure TGreedSpriteLogic.RingOfBullets;
var
  LIndex, LAngle, LStep: Integer;
begin
  if FRandom.Next >= 32 then
    Exit;
  LAngle := 0;
  LStep := GREED_ANGLES div 16;
  for LIndex := 0 to 15 do
  begin
    Spawn(FSprite^.Bullet, FSprite^.X, FSprite^.Y, FSprite^.Z, 32 * GREED_FRACUNIT, LAngle, 0, True,
      SPAWN_ID_NOBODY);
    LAngle := LAngle + LStep;
  end;
  FSound.SoundEffect(GREED_SN_MON11_FIRE, WAKE_VARIATION, FSprite^.X, FSprite^.Y);
end;

// big guards only
procedure TGreedSpriteLogic.Int9;
var
  LAngle, LSourceX, LSourceY, LPlayerX, LPlayerY, LTargetX, LTargetY, LFireAngle, LSpread: Integer;
  LOldSpeed, LFireHeight: TGreedFixed;
begin
  if FSprite^.HitPoints < 1000 then
    FSprite^.HitPoints := FSprite^.HitPoints + 10;
  FSprite^.Enraged := 0;
  LSourceX := FSprite^.X div GREED_FRACTILEUNIT;
  LSourceY := FSprite^.Y div GREED_FRACTILEUNIT;
  AcquireTarget;
  LPlayerX := FState.TargX div GREED_FRACTILEUNIT;
  LPlayerY := FState.TargY div GREED_FRACTILEUNIT;
  LOldSpeed := FSprite^.MoveSpeed;
  if (Abs(LPlayerX - LSourceX) < 6) and (Abs(LPlayerY - LSourceY) < 6) then
    FSprite^.MoveSpeed := FSprite^.MoveSpeed * 2;
  if FState.TimeCount > FSprite^.MoveTime then
  begin
    LAngle := CompassAngle(LPlayerX, LPlayerY, LSourceX, LSourceY) - DEGREE45 + FRandom.Next;
    FSprite^.Angle := LAngle and GREED_ANGLES;
    FSprite^.MoveTime := FState.TimeCount + 200;
  end;
  if (FState.TimeCount > FSprite^.FireTime) and (FState.TimeCount > FSprite^.ScanTime) then
  begin
    FSound.SoundEffect(GREED_SN_MON11_WAKE, WAKE_VARIATION, FSprite^.X, FSprite^.Y);
    if SeesTarget(8, LSourceX, LSourceY, LPlayerX, LPlayerY, LTargetX, LTargetY) then
    begin
      FSprite^.Angle := CompassAngle(LTargetX, LTargetY, LSourceX, LSourceY) and GREED_ANGLES;
      FSprite^.BasePic := FSprite^.StartPic + 24;
      FSprite^.MoveMode := 4;
      FSprite^.FireTime := FState.TimeCount + (120 + 5 * FState.Player.Difficulty);
      FSprite^.ActionTime := FState.TimeCount + 30;
      FSprite^.ModeTime := FState.TimeCount + 20;
    end;
    FSprite^.ScanTime := FState.TimeCount + 45;
  end;
  if FState.TimeCount > FSprite^.ModeTime then
  begin
    FSprite^.ModeTime := FState.TimeCount + 20;
    case FSprite^.MoveMode of
      0, 1: // left, mid
        begin
          if HasMoved then
          begin
            Inc(FSprite^.MoveMode);
            FSprite^.BasePic := FSprite^.StartPic + FSprite^.MoveMode * 8;
            RememberPosition;
          end;
          RingOfBullets;
        end;
      2: // right
        begin
          if HasMoved then
          begin
            FSprite^.BasePic := FSprite^.StartPic + 8;
            Inc(FSprite^.MoveMode);
            RememberPosition;
          end;
          RingOfBullets;
        end;
      3: // mid #2
        begin
          if HasMoved then
          begin
            FSprite^.MoveMode := 0;
            FSprite^.BasePic := FSprite^.StartPic;
            RememberPosition;
          end;
          RingOfBullets;
        end;
      4, 5, 6, 7: // firing bullets
        if SeesTarget(8, LSourceX, LSourceY, LPlayerX, LPlayerY, LTargetX, LTargetY) then
        begin
          FSprite^.Angle := CompassAngle(LTargetX, LTargetY, LSourceX, LSourceY) and GREED_ANGLES;
          Inc(FSprite^.MoveMode);
          FSprite^.BasePic := FSprite^.StartPic + 32;
          LFireHeight := 70 * GREED_FRACUNIT;
          if (FSprite^.MoveMode = 5) and (FRandom.Next < 32) then
          begin
            LSpread := FSprite^.Angle - 15 + (FRandom.Next and 31);
            Spawn(GREED_S_GRENADE, FSprite^.X, FSprite^.Y, FSprite^.Z, LFireHeight, LSpread, 0, True,
              SPAWN_ID_NOBODY);
            LSpread := FSprite^.Angle + 15 + (FRandom.Next and 31);
            Spawn(GREED_S_GRENADE, FSprite^.X, FSprite^.Y, FSprite^.Z, LFireHeight, LSpread, 0, True,
              SPAWN_ID_NOBODY);
            FSound.SoundEffect(GREED_SN_GRENADE, 0, FSprite^.X, FSprite^.Y);
            FSprite^.MoveMode := 0;
            FSprite^.BasePic := FSprite^.StartPic;
            FSprite^.FireTime := FState.TimeCount + (120 + 5 * FState.Player.Difficulty);
            FSprite^.ActionTime := FState.TimeCount + 30;
          end
          else
          begin
            LFireAngle := FScan.GetFireAngle(FSprite, LFireHeight, LTargetX, LTargetY, FState.TargX, FState.TargY,
              FState.TargZ) - 15 + (FRandom.Next and 31);
            LSpread := FSprite^.Angle - 15 + (FRandom.Next and 31);
            Spawn(FSprite^.Bullet, FSprite^.X, FSprite^.Y, FSprite^.Z, LFireHeight, LSpread, LFireAngle, True,
              SPAWN_ID_NOBODY);
            FSound.SoundEffect(GREED_SN_MON11_FIRE, WAKE_VARIATION, FSprite^.X, FSprite^.Y);
            FSprite^.ModeTime := FState.TimeCount + 15;
          end;
        end
        else
        begin
          FSprite^.MoveMode := 0;
          FSprite^.BasePic := FSprite^.StartPic;
          FSprite^.FireTime := FState.TimeCount + (120 + 5 * FState.Player.Difficulty);
          FSprite^.ActionTime := FState.TimeCount + 30;
        end;
      8: // fire #2
        begin
          FSprite^.MoveMode := 0;
          FSprite^.BasePic := FSprite^.StartPic;
          FSprite^.FireTime := FState.TimeCount + (120 + 5 * FState.Player.Difficulty);
          FSprite^.ActionTime := FState.TimeCount + 30;
        end;
    end;
  end;
  WalkAndSettle;
  FSprite^.MoveSpeed := LOldSpeed;
  if FRandom.Next >= 255 then
    WakeSound(FSprite);
end;

// the other monsters
procedure TGreedSpriteLogic.Int10;
var
  LAngle, LSourceX, LSourceY, LPlayerX, LPlayerY, LTargetX, LTargetY, LFireAngle, LSpread, LKind: Integer;
  LOldSpeed, LFireHeight: TGreedFixed;
  LTooFar: Boolean;
begin
  LKind := FSprite^.Kind;
  // they heal by themselves
  if (LKind = GREED_S_MONSTER5) and (FSprite^.HitPoints < 5000) then
    FSprite^.HitPoints := FSprite^.HitPoints + 4
  else if (LKind = GREED_S_MONSTER13) and (FSprite^.HitPoints < 300) then
  begin
    FSprite^.HitPoints := FSprite^.HitPoints + 25;
    FSprite^.Enraged := 0;
  end
  else if (LKind = GREED_S_MONSTER15) and (FSprite^.HitPoints < 2000) then
  begin
    FSprite^.HitPoints := FSprite^.HitPoints + 6;
    FSprite^.Enraged := 0;
  end
  else if (LKind = GREED_S_MONSTER14) and (FSprite^.HitPoints < 350) then
    FSprite^.HitPoints := FSprite^.HitPoints + 1;
  LSourceX := FSprite^.X div GREED_FRACTILEUNIT;
  LSourceY := FSprite^.Y div GREED_FRACTILEUNIT;
  AcquireTarget;
  LPlayerX := FState.TargX div GREED_FRACTILEUNIT;
  LPlayerY := FState.TargY div GREED_FRACTILEUNIT;
  LOldSpeed := FSprite^.MoveSpeed;
  if (Abs(LPlayerX - LSourceX) < 6) and (Abs(LPlayerY - LSourceY) < 6) then
    FSprite^.MoveSpeed := FSprite^.MoveSpeed * 2;
  if FState.TimeCount > FSprite^.MoveTime then
  begin
    LAngle := CompassAngle(LPlayerX, LPlayerY, LSourceX, LSourceY) - DEGREE45 + FRandom.Next;
    FSprite^.Angle := LAngle and GREED_ANGLES;
    FSprite^.MoveTime := FState.TimeCount + 350;
  end;
  if (FState.TimeCount > FSprite^.FireTime) and (FState.TimeCount > FSprite^.ScanTime) then
  begin
    if SeesTarget(10, LSourceX, LSourceY, LPlayerX, LPlayerY, LTargetX, LTargetY) then
    begin
      FSprite^.Angle := CompassAngle(LTargetX, LTargetY, LSourceX, LSourceY) and GREED_ANGLES;
      // two kinds shoot only from close
      LTooFar :=
        ((LKind = GREED_S_MONSTER7) and ((Abs(LTargetX - LSourceX) > 2) or (Abs(LTargetY - LSourceY) > 2))) or
        ((LKind = GREED_S_MONSTER15) and ((Abs(LTargetX - LSourceX) > 4) or (Abs(LTargetY - LSourceY) > 4)));
      if not LTooFar then
      begin
        FSprite^.BasePic := FSprite^.StartPic + 32;
        FSprite^.MoveMode := 6;
        if LKind = GREED_S_MONSTER5 then
          FSprite^.FireTime := FState.TimeCount + (10 + 3 * FState.Player.Difficulty)
        else
          FSprite^.FireTime := FState.TimeCount + (40 + 5 * FState.Player.Difficulty);
        FSprite^.ActionTime := FState.TimeCount + 30;
        FSprite^.ModeTime := FState.TimeCount + 15;
        if LKind = GREED_S_MONSTER3 then
          LFireHeight := 3 * GREED_FRACUNIT
        else if LKind = GREED_S_MONSTER6 then
          LFireHeight := 100 * GREED_FRACUNIT
        else
          LFireHeight := 40 * GREED_FRACUNIT;
        LFireAngle := FScan.GetFireAngle(FSprite, LFireHeight, LTargetX, LTargetY, FState.TargX, FState.TargY,
          FState.TargZ) - 15 + (FRandom.Next and 31);
        if (LKind = GREED_S_MONSTER13) or (LKind = GREED_S_MONSTER6) or (LKind = GREED_S_MONSTER15) or
          (LKind = GREED_S_MONSTER5) then
        begin
          LSpread := FSprite^.Angle - 15 + (FRandom.Next and 31) + 16;
          Spawn(FSprite^.Bullet, FSprite^.X, FSprite^.Y, FSprite^.Z, LFireHeight, LSpread, LFireAngle, True,
            SPAWN_ID_NOBODY);
          LSpread := FSprite^.Angle - 15 + (FRandom.Next and 31) - 16;
          Spawn(FSprite^.Bullet, FSprite^.X, FSprite^.Y, FSprite^.Z, LFireHeight, LSpread, LFireAngle, True,
            SPAWN_ID_NOBODY);
          LSpread := FSprite^.Angle - 15 + (FRandom.Next and 31);
          Spawn(FSprite^.Bullet, FSprite^.X, FSprite^.Y, FSprite^.Z, LFireHeight, LSpread, LFireAngle, True,
            SPAWN_ID_NOBODY);
        end
        else if LKind = GREED_S_MONSTER4 then
        begin
          LSpread := FSprite^.Angle - 15 + (FRandom.Next and 31) + 8;
          Spawn(FSprite^.Bullet, FSprite^.X, FSprite^.Y, FSprite^.Z, LFireHeight, LSpread, LFireAngle, True,
            SPAWN_ID_NOBODY);
          LSpread := FSprite^.Angle - 15 + (FRandom.Next and 31) - 8;
          Spawn(FSprite^.Bullet, FSprite^.X, FSprite^.Y, FSprite^.Z, LFireHeight, LSpread, LFireAngle, True,
            SPAWN_ID_NOBODY);
        end
        else
        begin
          LSpread := FSprite^.Angle - 15 + (FRandom.Next and 31);
          Spawn(FSprite^.Bullet, FSprite^.X, FSprite^.Y, FSprite^.Z, LFireHeight, LSpread, LFireAngle, True,
            SPAWN_ID_NOBODY);
        end;
      end;
    end;
    FSprite^.ScanTime := FState.TimeCount + 30;
  end;
  if FState.TimeCount > FSprite^.ModeTime then
  begin
    FSprite^.ModeTime := FState.TimeCount + 8;
    case FSprite^.MoveMode of
      0, 1, 2: // 1, 2, 3
        if HasMoved then
        begin
          Inc(FSprite^.MoveMode);
          FSprite^.BasePic := FSprite^.StartPic + FSprite^.MoveMode * 8;
          RememberPosition;
        end;
      3, 4: // 2, 1
        if HasMoved then
        begin
          Inc(FSprite^.MoveMode);
          FSprite^.BasePic := FSprite^.StartPic + (6 - FSprite^.MoveMode) * 8;
          RememberPosition;
        end;
      5:
        if HasMoved then
        begin
          FSprite^.MoveMode := 0;
          FSprite^.BasePic := FSprite^.StartPic;
          RememberPosition;
        end;
      6: // fire
        begin
          FSprite^.MoveMode := 0;
          FSprite^.BasePic := FSprite^.StartPic;
        end;
    end;
  end;
  WalkAndSettle;
  FSprite^.MoveSpeed := LOldSpeed;
  if FRandom.Next >= 255 then
    WakeSound(FSprite);
end;

procedure TGreedSpriteLogic.RecreateMapSprites;
var
  LTiles: array[0..GREED_MAP_TILES - 1] of Byte;
  LSpot, LIndex: Integer;
  LSprite: PGreedSprite;
begin
  // one call for the plane instead of one for each tile
  FState.World.CopyPlane(gpMapSprites, @LTiles[0]);
  for LSpot := 0 to GREED_MAP_TILES - 1 do
    if LTiles[LSpot] = MAP_SPRITE_MONSTER then
      FState.World.SetValue(gpMapSprites, LSpot, 0);
  LIndex := FState.Sprites.First;
  while LIndex <> GREED_POOL_NIL do
  begin
    LSprite := PGreedSprite(FState.Sprites.Item(LIndex));
    if TGreedGameTables.IsMonster(LSprite^.Kind) and (LSprite^.DeathEvent = 0) and (LSprite^.HitPoints <> 0) then
      PutMapSprite((LSprite^.Y div GREED_FRACTILEUNIT) * GREED_MAP_SIZE + (LSprite^.X div GREED_FRACTILEUNIT),
        MAP_SPRITE_MONSTER);
    LIndex := FState.Sprites.Next(LIndex);
  end;
end;

// what the renderer needs to draw the sprite between two tics: where it was
procedure TGreedSpriteLogic.SaveOld;
begin
  FSprite^.OldX := FSprite^.X;
  FSprite^.OldY := FSprite^.Y;
  FSprite^.OldZ := FSprite^.Z;
  FSprite^.OldAngle := FSprite^.Angle;
  FSprite^.OldAngle2 := FSprite^.Angle2;
  FSprite^.OldFloorZ := FSprite^.NewFloorZ;
  if not FSprite^.Grounded then
    FSprite^.Grounded := FSprite^.OldFloorZ >= FSprite^.OldZ;
end;

// ... and where it is now
procedure TGreedSpriteLogic.SaveNew;
begin
  FSprite^.NewX := FSprite^.X;
  FSprite^.NewY := FSprite^.Y;
  FSprite^.NewZ := FSprite^.Z;
  FSprite^.NewAngle := FSprite^.Angle;
  FSprite^.NewAngle2 := FSprite^.Angle2;
  FSprite^.NewFloorZ := TGreedTerrain.FloorZ(FState.World, FSprite^.X, FSprite^.Y);
end;

// A hot sprite takes light from its tile, a very hot one from the eight around too; a sleeping one cools down
procedure TGreedSpriteLogic.Heat(ACools: Boolean);
var
  LSpot, LOther, LRow, LColumn, LPart: Integer;
begin
  LSpot := (FSprite^.Y div GREED_FRACTILEUNIT) * GREED_MAP_SIZE + (FSprite^.X div GREED_FRACTILEUNIT);
  if FSprite^.Heat > 256 then
  begin
    LPart := FSprite^.Heat div 2;
    for LRow := -1 to 1 do
      for LColumn := -1 to 1 do
      begin
        LOther := LSpot + (LRow * GREED_MAP_SIZE) + LColumn;
        if (LOther >= 0) and (LOther < GREED_MAP_TILES) then
          FRealLight^[LOther] := FRealLight^[LOther] - LPart;
      end;
    if (LSpot >= 0) and (LSpot < GREED_MAP_TILES) then
      FRealLight^[LSpot] := FRealLight^[LSpot] - FSprite^.Heat div 4;
    if ACools then
      FSprite^.Heat := FSprite^.Heat - 64;
  end
  else if (LSpot >= 0) and (LSpot < GREED_MAP_TILES) then
    FRealLight^[LSpot] := FRealLight^[LSpot] - FSprite^.Heat;
end;

procedure TGreedSpriteLogic.MoveSprites;
var
  LIndex, LNext, LPlayerX, LPlayerY, LSourceX, LSourceY: Integer;
  LKilled: Boolean;
  LFloor: TGreedFixed;
begin
  FState.TargX := FState.Player.X;
  FState.TargY := FState.Player.Y;
  LPlayerX := FState.TargX div GREED_FRACTILEUNIT;
  LPlayerY := FState.TargY div GREED_FRACTILEUNIT;
  // the original does not give a value to this variable before the first sprite reads it
  LKilled := False;
  LIndex := FState.Sprites.First;
  while LIndex <> GREED_POOL_NIL do
  begin
    Select(LIndex);
    SaveOld;
    if FSprite^.Active then
    begin
      if FSprite^.MoveSpeed <> 0 then
        case FSprite^.Intelligence of
          0:
            begin
              LKilled := Int0;
              if LKilled then
              begin
                if FSprite^.Kind = GREED_S_BLOODSPLAT then
                  // the blood stays where it fell
                  FSprite^.Intelligence := 128
                else if (FSprite^.Kind = GREED_S_METALPARTS) and not FState.SpriteHit then
                begin
                  LKilled := False;
                  SaveNew;
                  LIndex := FState.Sprites.Next(LIndex);
                  Continue;
                end;
                if FSprite^.Kind <> GREED_S_BLOODSPLAT then
                begin
                  SaveNew;
                  // the sprites that Int0 made are after it in the list: the next one is read before the removal
                  LNext := FState.Sprites.Next(LIndex);
                  FState.Sprites.Remove(LIndex);
                  LKilled := False;
                  LIndex := LNext;
                  Continue;
                end;
              end;
            end;
          5:
            Int5;
          6:
            begin
              LKilled := Int6;
              if LKilled then
              begin
                SaveNew;
                LNext := FState.Sprites.Next(LIndex);
                FState.Sprites.Remove(LIndex);
                LKilled := False;
                LIndex := LNext;
                Continue;
              end;
            end;
          7:
            Int7;
          8:
            Int8;
          9:
            Int9;
          10:
            Int10;
          128:
            begin
              LFloor := TGreedTerrain.FloorZ(FState.World, FSprite^.X, FSprite^.Y);
              if FSprite^.Z > LFloor + GREED_FRACUNIT then
                FSprite^.Z := FSprite^.Z - GREED_FRACUNIT * 2;
              if FSprite^.Z < LFloor then
                FSprite^.Z := LFloor;
            end;
        end;
      if (not LKilled) and (FSprite^.Heat <> 0) then
        Heat(False);
      LKilled := False;
    end
    else if FSprite^.Intelligence <> 255 then
    begin
      if FSprite^.MoveSpeed <> 0 then
      begin
        LSourceX := FSprite^.X div GREED_FRACTILEUNIT;
        LSourceY := FSprite^.Y div GREED_FRACTILEUNIT;
        if (Abs(LPlayerX - LSourceX) < WAKE_TILES) and (Abs(LPlayerY - LSourceY) < WAKE_TILES) then
        begin
          FSprite^.Active := True;
          ActivateSprites(LSourceX, LSourceY);
        end;
      end;
      LFloor := TGreedTerrain.FloorZ(FState.World, FSprite^.X, FSprite^.Y) + FSprite^.ZAdjust;
      if FSprite^.Z > LFloor then
        FSprite^.Z := FSprite^.Z - FALL_STEP;
      if FSprite^.Z < LFloor then
        FSprite^.Z := LFloor;
      if FSprite^.Heat <> 0 then
        Heat(True);
    end;
    SaveNew;
    LIndex := FState.Sprites.Next(LIndex);
  end;
  FState.MSprite := GREED_POOL_NIL;
  RecreateMapSprites;
end;

end.
