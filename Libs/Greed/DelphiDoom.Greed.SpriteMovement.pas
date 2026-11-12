{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the movement of the sprites against the map      }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): SP_TryDoor, SP_TryMove,     }
{  SP_ClipMove, SP_Thrust and SP_TryMove2, SP_ClipMove2, SP_Thrust2 of          }
{  sprites.pas                                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.SpriteMovement;

// the positions are 16.16 fixed point numbers: the arithmetic wraps as in the original
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.World.Intf,
  DelphiDoom.Greed.Game.Intf, DelphiDoom.Greed.Game.State;

type
  /// <summary>
  ///   Where a sprite can go. The original works on the global msprite: here the sprite is the first argument (a
  ///   pointer into the pool, or the address of the Probe of the state, which is the copy of a sprite that looks
  ///   for what a shot would hit: the probe opens no door and does not look at floors and ceilings). The first
  ///   family (TryMove, ClipMove, Thrust) is the flight of bullets and parts: one unit a step, it says what was
  ///   hit in SpriteHit, SpriteLoc, PlayerHit, HitX and HitY of the state. The second (TryMove2, ClipMove2,
  ///   Thrust2) is the walk of monsters and clones: floors, ceilings, other sprites, sliding along one axis, and
  ///   the tile of the sprite in mapsprites. A tile outside the map reads as 0 and is not written (the original
  ///   read and wrote the memory next to its arrays)
  /// </summary>
  TGreedSpriteMovement = class
  strict private
    FState: TGreedGameState;
    FSound: IGreedGameSound;
    function BumpDoor(ASprite: PGreedSprite; AIndex: Integer; ACenterX, ACenterY: TGreedFixed;
      AHorizontal: Boolean): Boolean;
    procedure PutMapSprite(ASpot: Integer; AValue: Byte);
  public
    constructor Create(const AState: TGreedGameState; const ASound: IGreedGameSound);
    /// <summary>
    ///   SP_TryDoor: False when a door that is not open is on the way (it starts opening, with its sound, if it
    ///   can be bumped), True when the way is free
    /// </summary>
    function TryDoor(ASprite: PGreedSprite; ACenterX, ACenterY: TGreedFixed): Boolean;
    /// <summary>SP_TryMove: 0 free, 1 a sprite or the player is there, 2 a wall, a floor or a ceiling</summary>
    function TryMove(ASprite: PGreedSprite; ACenterX, ACenterY: TGreedFixed): Integer;
    /// <summary>SP_ClipMove: moves the sprite unless the result is 2 (wall or door)</summary>
    function ClipMove(ASprite: PGreedSprite; AMoveX, AMoveY, AMoveZ: TGreedFixed): Byte;
    /// <summary>SP_Thrust: one step of a unit along Angle and Angle2 (both are brought into 0..1023)</summary>
    function Thrust(ASprite: PGreedSprite): Byte;
    /// <summary>SP_TryMove2: True when a walking sprite fits at (x, y); ASourceSpot is its own tile</summary>
    function TryMove2(ASprite: PGreedSprite; AAngle: Integer; ACenterX, ACenterY: TGreedFixed;
      ASourceSpot: Integer): Boolean;
    /// <summary>SP_ClipMove2: 1 moved, 2 moved along x only, 3 along y only, 0 did not move</summary>
    function ClipMove2(ASprite: PGreedSprite; AMoveX, AMoveY: TGreedFixed): Byte;
    /// <summary>SP_Thrust2: a ClipMove2 of MoveSpeed along Angle</summary>
    function Thrust2(ASprite: PGreedSprite): Byte;
  end;

implementation

uses
  DelphiDoom.Greed.FixedMath, DelphiDoom.MathCore.FixedMath, DelphiDoom.Greed.TrigTables, DelphiDoom.Greed.Terrain,
  DelphiDoom.Greed.Game.Constants;

const
  HALF_TILE = 32 * GREED_FRACUNIT;
  // F_NOCLIP and F_NOBULLETCLIP of r_refdef.pas
  WALL_NO_CLIP = 1 shl 5;
  WALL_NO_BULLET_CLIP = 1 shl 6;
  // the angles of the compass
  ANGLE_EAST = 0;
  ANGLE_NORTH = 256;
  ANGLE_WEST = 512;
  ANGLE_SOUTH = 768;
  // the tile of an instawall in mapsprites
  MAP_SPRITE_INSTAWALL = 64;
  DOOR_SOUND_VARIATION = 15;
  DOOR_BUMP_TIME = 20;

{ TGreedSpriteMovement }

constructor TGreedSpriteMovement.Create(const AState: TGreedGameState; const ASound: IGreedGameSound);
begin
  inherited Create;
  if not Assigned(AState) then
    raise EArgumentNilException.Create('AState');
  if not Assigned(ASound) then
    raise EArgumentNilException.Create('ASound');
  FState := AState;
  FSound := ASound;
end;

procedure TGreedSpriteMovement.PutMapSprite(ASpot: Integer; AValue: Byte);
begin
  if (ASpot >= 0) and (ASpot < GREED_MAP_TILES) then
    FState.World.SetValue(gpMapSprites, ASpot, AValue);
end;

// The branches of SP_TryDoor for the first door of the tile that has the right orientation: the final answer
function TGreedSpriteMovement.BumpDoor(ASprite: PGreedSprite; AIndex: Integer; ACenterX, ACenterY: TGreedFixed;
  AHorizontal: Boolean): Boolean;
var
  LDoor: TGreedDoor;
begin
  LDoor := FState.World.GetDoor(AIndex);
  if LDoor.Open and not LDoor.Closing then
    Exit(True);
  // closed and still, or closing: both branches of the original turn the door to opening
  if (not LDoor.Open) and LDoor.Bumpable and ((not LDoor.Opening) or LDoor.Closing) then
  begin
    LDoor.Opening := True;
    LDoor.Closing := False;
    FSound.SoundEffect(GREED_SN_DOOR, DOOR_SOUND_VARIATION, LDoor.TileX * GREED_FRACTILEUNIT,
      LDoor.TileY * GREED_FRACTILEUNIT);
    LDoor.Timer := LDoor.Timer + DOOR_BUMP_TIME;
    FState.World.SetDoor(AIndex, LDoor);
    // the door of the tile beyond, for the doors made of two
    if AHorizontal then
    begin
      if LDoor.Orientation = gdoHorizontal then
        TryDoor(ASprite, ACenterX + 64 * GREED_FRACUNIT, ACenterY)
      else
        TryDoor(ASprite, ACenterX - 64 * GREED_FRACUNIT, ACenterY);
    end
    else
    begin
      if LDoor.Orientation = gdoVertical then
        TryDoor(ASprite, ACenterX, ACenterY + 64 * GREED_FRACUNIT)
      else
        TryDoor(ASprite, ACenterX, ACenterY - 64 * GREED_FRACUNIT);
    end;
  end;
  Result := False;
end;

function TGreedSpriteMovement.TryDoor(ASprite: PGreedSprite; ACenterX, ACenterY: TGreedFixed): Boolean;
var
  LXLow, LYLow, LXHigh, LYHigh, LX, LY, LIndex: Integer;
  LDoor: TGreedDoor;
begin
  if ASprite = @FState.Probe then
    Exit(True);
  LXLow := (ACenterX - ASprite^.MoveSize) div GREED_FRACTILEUNIT;
  LYLow := (ACenterY - ASprite^.MoveSize) div GREED_FRACTILEUNIT;
  LXHigh := (ACenterX + ASprite^.MoveSize) div GREED_FRACTILEUNIT;
  LYHigh := (ACenterY + ASprite^.MoveSize) div GREED_FRACTILEUNIT;
  // the doors on the north wall
  for LY := LYLow + 1 to LYHigh do
    for LX := LXLow to LXHigh do
    begin
      if FState.World.GetMapFlags(LY * GREED_MAP_SIZE + LX) and GREED_FL_DOOR <> 0 then
      begin
        for LIndex := 0 to FState.World.DoorCount - 1 do
        begin
          LDoor := FState.World.GetDoor(LIndex);
          if (LDoor.TileX = LX) and (LDoor.TileY = LY) and
            ((LDoor.Orientation = gdoHorizontal) or (LDoor.Orientation = gdoHorizontal2)) then
            Exit(BumpDoor(ASprite, LIndex, ACenterX, ACenterY, True));
        end;
      end;
    end;
  // the doors on the west wall
  for LY := LYLow to LYHigh do
    for LX := LXLow + 1 to LXHigh do
    begin
      if FState.World.GetMapFlags(LY * GREED_MAP_SIZE + LX) and GREED_FL_DOOR <> 0 then
      begin
        for LIndex := 0 to FState.World.DoorCount - 1 do
        begin
          LDoor := FState.World.GetDoor(LIndex);
          if (LDoor.TileX = LX) and (LDoor.TileY = LY) and
            ((LDoor.Orientation = gdoVertical) or (LDoor.Orientation = gdoVertical2)) then
            Exit(BumpDoor(ASprite, LIndex, ACenterX, ACenterY, False));
        end;
      end;
    end;
  Result := True;
end;

function TGreedSpriteMovement.TryMove(ASprite: PGreedSprite; ACenterX, ACenterY: TGreedFixed): Integer;
var
  LXLow, LYLow, LXHigh, LYHigh, LX, LY, LSpot: Integer;
  LNorthFlags, LWestFlags, LMapSprite: Byte;
begin
  LXLow := (ACenterX - ASprite^.MoveSize) div GREED_FRACTILEUNIT;
  LYLow := (ACenterY - ASprite^.MoveSize) div GREED_FRACTILEUNIT;
  LXHigh := (ACenterX + ASprite^.MoveSize) div GREED_FRACTILEUNIT;
  LYHigh := (ACenterY + ASprite^.MoveSize) div GREED_FRACTILEUNIT;
  for LY := LYLow to LYHigh do
    for LX := LXLow to LXHigh do
    begin
      LSpot := GREED_MAP_SIZE * LY + LX;
      if (LY > LYLow) and (FState.World.GetValue(gpNorthWall, LSpot) <> 0) then
      begin
        LNorthFlags := FState.World.GetValue(gpNorthFlags, LSpot);
        if (LNorthFlags and WALL_NO_CLIP = 0) and (LNorthFlags and WALL_NO_BULLET_CLIP = 0) then
          Exit(2);
      end;
      if (LX > LXLow) and (FState.World.GetValue(gpWestWall, LSpot) <> 0) then
      begin
        LWestFlags := FState.World.GetValue(gpWestFlags, LSpot);
        if (LWestFlags and WALL_NO_CLIP = 0) and (LWestFlags and WALL_NO_BULLET_CLIP = 0) then
          Exit(2);
      end;
      if ASprite <> @FState.Probe then
      begin
        // below the floor or above the ceiling
        if ASprite^.Z < TGreedTerrain.FloorZ(FState.World, (LX * GREED_FRACTILEUNIT) + HALF_TILE,
          (LY * GREED_FRACTILEUNIT) + HALF_TILE) then
          Exit(2);
        if ASprite^.Z > TGreedTerrain.CeilingZ(FState.World, (LX * GREED_FRACTILEUNIT) + HALF_TILE,
          (LY * GREED_FRACTILEUNIT) + HALF_TILE) then
          Exit(2);
      end;
      LMapSprite := FState.World.GetValue(gpMapSprites, LSpot);
      if LMapSprite = MAP_SPRITE_INSTAWALL then
        Exit(2);
      if (LMapSprite > 0) and (LMapSprite < 128) and (LSpot <> ASprite^.StartSpot) then
      begin
        FState.SpriteHit := True;
        FState.SpriteLoc := LSpot;
        Exit(1);
      end;
      // a shot does not hit who fired it
      if (LSpot = FState.Player.MapSpot) and (LSpot <> ASprite^.StartSpot) and
        (ASprite^.SpawnId <> FState.PlayerNum) then
      begin
        FState.PlayerHit := True;
        Exit(1);
      end;
    end;
  Result := 0;
end;

function TGreedSpriteMovement.ClipMove(ASprite: PGreedSprite; AMoveX, AMoveY, AMoveZ: TGreedFixed): Byte;
var
  LNewX, LNewY: TGreedFixed;
begin
  LNewX := ASprite^.X + AMoveX;
  LNewY := ASprite^.Y + AMoveY;
  FState.SpriteHit := False;
  Result := TryMove(ASprite, LNewX, LNewY);
  if Result <> 0 then
  begin
    FState.HitX := LNewX;
    FState.HitY := LNewY;
  end;
  if (Result <> 2) and not TryDoor(ASprite, LNewX, LNewY) then
    Result := 2;
  if Result <> 2 then
  begin
    ASprite^.X := ASprite^.X + AMoveX;
    ASprite^.Y := ASprite^.Y + AMoveY;
    ASprite^.Z := ASprite^.Z + AMoveZ;
  end;
end;

function TGreedSpriteMovement.Thrust(ASprite: PGreedSprite): Byte;
begin
  ASprite^.Angle := ASprite^.Angle and GREED_ANGLES;
  ASprite^.Angle2 := ASprite^.Angle2 and GREED_ANGLES;
  Result := ClipMove(ASprite, TGreedTrigTables.Cosine(ASprite^.Angle), -TGreedTrigTables.Sine(ASprite^.Angle),
    TGreedTrigTables.Sine(ASprite^.Angle2));
end;

function TGreedSpriteMovement.TryMove2(ASprite: PGreedSprite; AAngle: Integer; ACenterX, ACenterY: TGreedFixed;
  ASourceSpot: Integer): Boolean;
var
  LXLow, LYLow, LXHigh, LYHigh, LX, LY, LSpot: Integer;
  LStepZ, LFeetZ, LFloorZ, LCeilingZ: TGreedFixed;
begin
  if (AAngle < ANGLE_NORTH) or (AAngle > ANGLE_SOUTH) then
  begin
    LXLow := ACenterX div GREED_FRACTILEUNIT;
    LXHigh := (ACenterX + ASprite^.MoveSize) div GREED_FRACTILEUNIT;
  end
  else if (AAngle > ANGLE_NORTH) and (AAngle < ANGLE_SOUTH) then
  begin
    LXHigh := ACenterX div GREED_FRACTILEUNIT;
    LXLow := (ACenterX - ASprite^.MoveSize) div GREED_FRACTILEUNIT;
  end
  else
  begin
    LXLow := (ACenterX - ASprite^.MoveSize) div GREED_FRACTILEUNIT;
    LXHigh := (ACenterX + ASprite^.MoveSize) div GREED_FRACTILEUNIT;
  end;
  if AAngle > ANGLE_WEST then
  begin
    LYLow := ACenterY div GREED_FRACTILEUNIT;
    LYHigh := (ACenterY + ASprite^.MoveSize) div GREED_FRACTILEUNIT;
  end
  else if (AAngle < ANGLE_WEST) and (AAngle <> ANGLE_EAST) then
  begin
    LYLow := (ACenterY - ASprite^.MoveSize) div GREED_FRACTILEUNIT;
    LYHigh := ACenterY div GREED_FRACTILEUNIT;
  end
  else
  begin
    LYLow := (ACenterY - ASprite^.MoveSize) div GREED_FRACTILEUNIT;
    LYHigh := (ACenterY + ASprite^.MoveSize) div GREED_FRACTILEUNIT;
  end;
  LStepZ := ASprite^.Z - ASprite^.ZAdjust + (20 * GREED_FRACUNIT);
  LFeetZ := ASprite^.Z - ASprite^.ZAdjust;
  for LY := LYLow to LYHigh do
    for LX := LXLow to LXHigh do
    begin
      LSpot := GREED_MAP_SIZE * LY + LX;
      if LSpot = FState.Player.MapSpot then
        Exit(False);
      if (LY > LYLow) and (FState.World.GetValue(gpNorthWall, LSpot) <> 0) and
        (FState.World.GetValue(gpNorthFlags, LSpot) and WALL_NO_CLIP = 0) then
        Exit(False);
      if (LX > LXLow) and (FState.World.GetValue(gpWestWall, LSpot) <> 0) and
        (FState.World.GetValue(gpWestFlags, LSpot) and WALL_NO_CLIP = 0) then
        Exit(False);
      LFloorZ := TGreedTerrain.FloorZ(FState.World, (LX * GREED_FRACTILEUNIT) + HALF_TILE,
        (LY * GREED_FRACTILEUNIT) + HALF_TILE);
      if LFloorZ > LStepZ then
        Exit(False);
      if ASprite^.NoFalling and (LFloorZ + (5 * GREED_FRACUNIT) < LFeetZ) then
        Exit(False);
      LCeilingZ := TGreedTerrain.CeilingZ(FState.World, (LX * GREED_FRACTILEUNIT) + HALF_TILE,
        (LY * GREED_FRACTILEUNIT) + HALF_TILE);
      if LCeilingZ < ASprite^.Z + ASprite^.Height then
        Exit(False);
      if LCeilingZ - LFloorZ < ASprite^.Height then
        Exit(False);
      if (LSpot <> ASourceSpot) and (FState.World.GetValue(gpMapSprites, LSpot) <> 0) then
        Exit(False);
    end;
  Result := True;
end;

function TGreedSpriteMovement.ClipMove2(ASprite: PGreedSprite; AMoveX, AMoveY: TGreedFixed): Byte;
var
  LNewX, LNewY: TGreedFixed;
  LSourceSpot, LAngle: Integer;
  LMark: Byte;
begin
  if ASprite^.Kind = GREED_S_CLONE then
    LMark := GREED_SM_CLONE
  else
    LMark := 1;
  LNewX := ASprite^.X + AMoveX;
  LNewY := ASprite^.Y + AMoveY;
  LSourceSpot := (ASprite^.Y div GREED_FRACTILEUNIT) * GREED_MAP_SIZE + (ASprite^.X div GREED_FRACTILEUNIT);
  if TryMove2(ASprite, ASprite^.Angle, LNewX, LNewY, LSourceSpot) and TryDoor(ASprite, LNewX, LNewY) then
  begin
    if FState.World.GetValue(gpFloorPic, (LNewY div GREED_FRACTILEUNIT) * GREED_MAP_SIZE +
      (LNewX div GREED_FRACTILEUNIT)) = 0 then
      Exit(0);
    PutMapSprite(LSourceSpot, 0);
    ASprite^.X := ASprite^.X + AMoveX;
    ASprite^.Y := ASprite^.Y + AMoveY;
    PutMapSprite((ASprite^.Y div GREED_FRACTILEUNIT) * GREED_MAP_SIZE + (ASprite^.X div GREED_FRACTILEUNIT), LMark);
    Exit(1);
  end;
  // the move goes into a wall, so try and move along one axis
  if AMoveX > 0 then
  begin
    LAngle := ANGLE_EAST;
    LNewX := ASprite^.X + ASprite^.MoveSpeed;
  end
  else
  begin
    LAngle := ANGLE_WEST;
    LNewX := ASprite^.X - ASprite^.MoveSpeed;
  end;
  if TryMove2(ASprite, LAngle, LNewX, ASprite^.Y, LSourceSpot) and TryDoor(ASprite, LNewX, ASprite^.Y) then
  begin
    if FState.World.GetValue(gpFloorPic, (ASprite^.Y div GREED_FRACTILEUNIT) * GREED_MAP_SIZE +
      (LNewX div GREED_FRACTILEUNIT)) = 0 then
      Exit(0);
    PutMapSprite(LSourceSpot, 0);
    // the test was made a whole MoveSpeed away, the move is the x part of the first one (as the original)
    ASprite^.X := ASprite^.X + AMoveX;
    PutMapSprite((ASprite^.Y div GREED_FRACTILEUNIT) * GREED_MAP_SIZE + (ASprite^.X div GREED_FRACTILEUNIT), LMark);
    Exit(2);
  end;
  if AMoveY > 0 then
  begin
    LAngle := ANGLE_SOUTH;
    LNewY := ASprite^.Y + ASprite^.MoveSpeed;
  end
  else
  begin
    LAngle := ANGLE_NORTH;
    LNewY := ASprite^.Y - ASprite^.MoveSpeed;
  end;
  if TryMove2(ASprite, LAngle, ASprite^.X, LNewY, LSourceSpot) and TryDoor(ASprite, ASprite^.X, LNewY) then
  begin
    if FState.World.GetValue(gpFloorPic, (LNewY div GREED_FRACTILEUNIT) * GREED_MAP_SIZE +
      (ASprite^.X div GREED_FRACTILEUNIT)) = 0 then
      Exit(0);
    PutMapSprite(LSourceSpot, 0);
    ASprite^.Y := ASprite^.Y + AMoveY;
    PutMapSprite((ASprite^.Y div GREED_FRACTILEUNIT) * GREED_MAP_SIZE + (ASprite^.X div GREED_FRACTILEUNIT), LMark);
    Exit(3);
  end;
  Result := 0;
end;

function TGreedSpriteMovement.Thrust2(ASprite: PGreedSprite): Byte;
var
  LMoveX, LMoveY: TGreedFixed;
begin
  ASprite^.Angle := ASprite^.Angle and GREED_ANGLES;
  LMoveX := TGreedFixedMath.Mul(ASprite^.MoveSpeed, TGreedTrigTables.Cosine(ASprite^.Angle));
  LMoveY := -TGreedFixedMath.Mul(ASprite^.MoveSpeed, TGreedTrigTables.Sine(ASprite^.Angle));
  Result := ClipMove2(ASprite, LMoveX, LMoveY);
end;

end.
