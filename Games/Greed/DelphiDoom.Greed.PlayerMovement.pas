{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the movement of the player against the map       }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): TryDoor, TryMove, ClipMove  }
{  and Thrust of raven.pas                                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.PlayerMovement;

// the positions are 16.16 fixed point numbers: the arithmetic wraps as in the original
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.SaveTypes, DelphiDoom.Greed.World.Intf;

const
  /// <summary>PLAYERSIZE: the half width of the player, 16 units</summary>
  GREED_PLAYER_SIZE = 16 * GREED_FRACUNIT;
  /// <summary>The angles of the compass (EAST, NORTH, WEST, SOUTH)</summary>
  GREED_EAST = 0;
  GREED_NORTH = 256;
  GREED_WEST = 512;
  GREED_SOUTH = 768;
  /// <summary>F_NOCLIP: a wall that does not stop the movement</summary>
  GREED_F_NOCLIP = 1 shl 5;

type
  /// <summary>What the movement asks to the rest of the game</summary>
  IGreedMovementHost = interface
    ['{3F90B1D7-A4C2-4E58-9B16-D07E5A2C8F31}']
    function GetNetMode: Boolean;
    /// <summary>NetOpenDoor(x, y): the other players are told that a door is opening</summary>
    procedure NetOpenDoor(AX, AY: TGreedFixed);
    property NetMode: Boolean read GetNetMode;
  end;

  /// <summary>
  ///   doorsound, doorx and doory of raven.pas are globals of the game that TimeUpdate reads: who keeps them is told
  ///   when the player bumps a door open
  /// </summary>
  IGreedDoorSoundSink = interface
    ['{2D7F4A16-8B3C-4E59-A0D1-95C6E3B7F248}']
    procedure DoorBumped(ADoorX, ADoorY: Integer);
  end;

  /// <summary>
  ///   Where the player can go: TryMove looks at the tiles under its square (walls that are not no-clip, solid
  ///   sprites, floors above the feet and ceilings under the head), TryDoor opens the doors that it bumps into
  ///   (and says so: DoorSound, DoorX and DoorY are doorsound, doorx and doory, for the sound of the door), ClipMove
  ///   slides along one axis when the move goes into a wall, and Thrust turns an angle and a speed into a move.
  ///   The player reads and writes its own record; the map and the doors are the world
  /// </summary>
  TGreedPlayerMovement = class
  strict private
    FWorld: IGreedWorld;
    FHost: IGreedMovementHost;
    FDoorSound: Boolean;
    FDoorX: Integer;
    FDoorY: Integer;
    FDoorSoundSink: IGreedDoorSoundSink;
    function OpenDoor(AIndex: Integer; ACenterX, ACenterY: TGreedFixed; AHorizontal: Boolean): Boolean;
  public
    constructor Create(const AWorld: IGreedWorld; const AHost: IGreedMovementHost);
    /// <summary>
    ///   TryDoor: False when a closed door is on the way (it starts opening if it can be bumped), True when the
    ///   way is free. ANorth and the west check use the doors of the world
    /// </summary>
    function TryDoor(ACenterX, ACenterY: TGreedFixed): Boolean;
    /// <summary>TryMove: True when the square of the player at (x, y), moving at the angle, is free</summary>
    function TryMove(const APlayer: TGreedPlayerRecord; AAngle: Integer; ACenterX, ACenterY: TGreedFixed): Boolean;
    /// <summary>ClipMove: moves the player by (xmove, ymove) or along one axis; False if it could not move on both</summary>
    function ClipMove(var APlayer: TGreedPlayerRecord; AAngle: Integer; AMoveX, AMoveY: TGreedFixed): Boolean;
    /// <summary>Thrust: a ClipMove along an angle, then the tile of the player (mapspot) is updated</summary>
    function Thrust(var APlayer: TGreedPlayerRecord; AAngle: Integer; ASpeed: TGreedFixed): Boolean;
    property DoorSound: Boolean read FDoorSound write FDoorSound;
    property DoorX: Integer read FDoorX;
    property DoorY: Integer read FDoorY;
    /// <summary>nil (the default): the sound of the door stays in DoorSound, DoorX and DoorY only</summary>
    property DoorSoundSink: IGreedDoorSoundSink read FDoorSoundSink write FDoorSoundSink;
  end;

implementation

uses
  DelphiDoom.Greed.FixedMath, DelphiDoom.MathCore.FixedMath, DelphiDoom.Greed.TrigTables, DelphiDoom.Greed.Terrain;

const
  TILE_UNIT = 64 * GREED_FRACUNIT;
  HALF_TILE_UNIT = 32 * GREED_FRACUNIT;

{ TGreedPlayerMovement }

constructor TGreedPlayerMovement.Create(const AWorld: IGreedWorld; const AHost: IGreedMovementHost);
begin
  inherited Create;
  if not Assigned(AWorld) then
    raise EArgumentNilException.Create('AWorld');
  if not Assigned(AHost) then
    raise EArgumentNilException.Create('AHost');
  FWorld := AWorld;
  FHost := AHost;
end;

// The branches of TryDoor for a door that is on the way and has the right orientation. Result: the final answer
function TGreedPlayerMovement.OpenDoor(AIndex: Integer; ACenterX, ACenterY: TGreedFixed;
  AHorizontal: Boolean): Boolean;
var
  LDoor: TGreedDoor;
begin
  LDoor := FWorld.GetDoor(AIndex);
  if LDoor.Open and not LDoor.Closing then
    Exit(True);
  if (not LDoor.Open) and LDoor.Bumpable then
  begin
    // not opening yet, or closing: the door turns to opening
    if not LDoor.Opening then
      LDoor.Closing := False
    else if LDoor.Closing then
      LDoor.Closing := False
    else
      Exit(False);
    LDoor.Opening := True;
    FWorld.SetDoor(AIndex, LDoor);
    FDoorSound := True;
    FDoorX := LDoor.TileX * GREED_FRACTILEUNIT;
    FDoorY := LDoor.TileY * GREED_FRACTILEUNIT;
    if Assigned(FDoorSoundSink) then
      FDoorSoundSink.DoorBumped(FDoorX, FDoorY);
    if AHorizontal then
    begin
      if LDoor.Orientation = gdoHorizontal then
        TryDoor(ACenterX + 64 * GREED_FRACUNIT, ACenterY)
      else
        TryDoor(ACenterX - 64 * GREED_FRACUNIT, ACenterY);
    end
    else
    begin
      if LDoor.Orientation = gdoVertical then
        TryDoor(ACenterX, ACenterY + 64 * GREED_FRACUNIT)
      else
        TryDoor(ACenterX, ACenterY - 64 * GREED_FRACUNIT);
    end;
    if FHost.NetMode then
      FHost.NetOpenDoor(ACenterX, ACenterY);
  end;
  Result := False;
end;

function TGreedPlayerMovement.TryDoor(ACenterX, ACenterY: TGreedFixed): Boolean;
var
  LXLow, LYLow, LXHigh, LYHigh, LX, LY, LIndex: Integer;
  LDoor: TGreedDoor;
begin
  // the doors on the north wall
  LXLow := (ACenterX - GREED_PLAYER_SIZE) div GREED_FRACTILEUNIT;
  LYLow := (ACenterY - GREED_PLAYER_SIZE - (TILE_UNIT div 2)) div GREED_FRACTILEUNIT;
  LXHigh := (ACenterX + GREED_PLAYER_SIZE) div GREED_FRACTILEUNIT;
  LYHigh := (ACenterY + GREED_PLAYER_SIZE - (TILE_UNIT div 2)) div GREED_FRACTILEUNIT;
  for LY := LYLow + 1 to LYHigh do
    for LX := LXLow to LXHigh do
    begin
      if FWorld.GetMapFlags(LY * GREED_MAP_SIZE + LX) and GREED_FL_DOOR <> 0 then
      begin
        for LIndex := 0 to FWorld.DoorCount - 1 do
        begin
          LDoor := FWorld.GetDoor(LIndex);
          if (LDoor.TileX = LX) and (LDoor.TileY = LY) and
            ((LDoor.Orientation = gdoHorizontal) or (LDoor.Orientation = gdoHorizontal2)) then
            Exit(OpenDoor(LIndex, ACenterX, ACenterY, True));
        end;
      end;
    end;
  // the doors on the west wall
  LXLow := (ACenterX - GREED_PLAYER_SIZE - (TILE_UNIT div 2)) div GREED_FRACTILEUNIT;
  LYLow := (ACenterY - GREED_PLAYER_SIZE) div GREED_FRACTILEUNIT;
  LXHigh := (ACenterX + GREED_PLAYER_SIZE - (TILE_UNIT div 2)) div GREED_FRACTILEUNIT;
  LYHigh := (ACenterY + GREED_PLAYER_SIZE) div GREED_FRACTILEUNIT;
  for LY := LYLow to LYHigh do
    for LX := LXLow + 1 to LXHigh do
    begin
      if FWorld.GetMapFlags(LY * GREED_MAP_SIZE + LX) and GREED_FL_DOOR <> 0 then
      begin
        for LIndex := 0 to FWorld.DoorCount - 1 do
        begin
          LDoor := FWorld.GetDoor(LIndex);
          if (LDoor.TileX = LX) and (LDoor.TileY = LY) and
            ((LDoor.Orientation = gdoVertical) or (LDoor.Orientation = gdoVertical2)) then
            Exit(OpenDoor(LIndex, ACenterX, ACenterY, False));
        end;
      end;
    end;
  Result := True;
end;

function TGreedPlayerMovement.TryMove(const APlayer: TGreedPlayerRecord; AAngle: Integer;
  ACenterX, ACenterY: TGreedFixed): Boolean;
var
  LXLow, LYLow, LXHigh, LYHigh, LX, LY, LSpot: Integer;
  LFeet: TGreedFixed;
  LSprite: Byte;
begin
  if (AAngle < GREED_NORTH) or (AAngle > GREED_SOUTH) then
  begin
    LXLow := ACenterX div GREED_FRACTILEUNIT;
    LXHigh := (ACenterX + GREED_PLAYER_SIZE) div GREED_FRACTILEUNIT;
  end
  else if (AAngle > GREED_NORTH) and (AAngle < GREED_SOUTH) then
  begin
    LXHigh := ACenterX div GREED_FRACTILEUNIT;
    LXLow := (ACenterX - GREED_PLAYER_SIZE) div GREED_FRACTILEUNIT;
  end
  else
  begin
    LXHigh := (ACenterX + GREED_PLAYER_SIZE) div GREED_FRACTILEUNIT;
    LXLow := (ACenterX - GREED_PLAYER_SIZE) div GREED_FRACTILEUNIT;
  end;
  if AAngle > GREED_WEST then
  begin
    LYLow := ACenterY div GREED_FRACTILEUNIT;
    LYHigh := (ACenterY + GREED_PLAYER_SIZE) div GREED_FRACTILEUNIT;
  end
  else if (AAngle < GREED_WEST) and (AAngle <> GREED_EAST) then
  begin
    LYLow := (ACenterY - GREED_PLAYER_SIZE) div GREED_FRACTILEUNIT;
    LYHigh := ACenterY div GREED_FRACTILEUNIT;
  end
  else
  begin
    LYLow := (ACenterY - GREED_PLAYER_SIZE) div GREED_FRACTILEUNIT;
    LYHigh := (ACenterY + GREED_PLAYER_SIZE) div GREED_FRACTILEUNIT;
  end;
  LFeet := APlayer.Z - APlayer.Height + (26 * GREED_FRACUNIT);
  for LY := LYLow to LYHigh do
    for LX := LXLow to LXHigh do
    begin
      LSpot := GREED_MAP_SIZE * LY + LX;
      if (LY > LYLow) and (FWorld.GetValue(gpNorthWall, LSpot) <> 0) and
        (FWorld.GetValue(gpNorthFlags, LSpot) and GREED_F_NOCLIP = 0) then
        Exit(False);
      if (LX > LXLow) and (FWorld.GetValue(gpWestWall, LSpot) <> 0) and
        (FWorld.GetValue(gpWestFlags, LSpot) and GREED_F_NOCLIP = 0) then
        Exit(False);
      if LSpot <> APlayer.MapSpot then
      begin
        LSprite := FWorld.GetValue(gpMapSprites, LSpot);
        if (LSprite > 0) and (LSprite < 128) then
          Exit(False);
        if TGreedTerrain.FloorZ(FWorld, (LX * GREED_FRACTILEUNIT) + (32 * GREED_FRACUNIT),
          (LY * GREED_FRACTILEUNIT) + (32 * GREED_FRACUNIT)) > LFeet then
          Exit(False);
        if TGreedTerrain.CeilingZ(FWorld, (LX * GREED_FRACTILEUNIT) + (32 * GREED_FRACUNIT),
          (LY * GREED_FRACTILEUNIT) + (32 * GREED_FRACUNIT)) < APlayer.Z + (10 * GREED_FRACUNIT) then
          Exit(False);
      end;
    end;
  Result := True;
end;

function TGreedPlayerMovement.ClipMove(var APlayer: TGreedPlayerRecord; AAngle: Integer;
  AMoveX, AMoveY: TGreedFixed): Boolean;
var
  LNewX, LNewY, LAngle: Integer;
begin
  LNewX := APlayer.X + AMoveX;
  LNewY := APlayer.Y + AMoveY;
  if TryMove(APlayer, AAngle, LNewX, LNewY) and TryDoor(LNewX, LNewY) then
  begin
    if FWorld.GetValue(gpFloorPic, (LNewY div GREED_FRACTILEUNIT) * GREED_MAP_SIZE +
      (LNewX div GREED_FRACTILEUNIT)) = 0 then
      Exit(False);
    APlayer.X := APlayer.X + AMoveX;
    APlayer.Y := APlayer.Y + AMoveY;
    Exit(True);
  end;
  // the move goes into a wall, so try and move along one axis
  if AMoveX > 0 then
    LAngle := GREED_EAST
  else
    LAngle := GREED_WEST;
  if TryMove(APlayer, LAngle, LNewX, APlayer.Y) and TryDoor(LNewX, APlayer.Y) then
  begin
    if FWorld.GetValue(gpFloorPic, (APlayer.Y div GREED_FRACTILEUNIT) * GREED_MAP_SIZE +
      (LNewX div GREED_FRACTILEUNIT)) = 0 then
      Exit(False);
    APlayer.X := APlayer.X + AMoveX;
    Exit(True);
  end;
  if AMoveY > 0 then
    LAngle := GREED_SOUTH
  else
    LAngle := GREED_NORTH;
  if TryMove(APlayer, LAngle, APlayer.X, LNewY) and TryDoor(APlayer.X, LNewY) then
  begin
    if FWorld.GetValue(gpFloorPic, (LNewY div GREED_FRACTILEUNIT) * GREED_MAP_SIZE +
      (APlayer.X div GREED_FRACTILEUNIT)) = 0 then
      Exit(False);
    APlayer.Y := APlayer.Y + AMoveY;
    Exit(True);
  end;
  Result := False;
end;

function TGreedPlayerMovement.Thrust(var APlayer: TGreedPlayerRecord; AAngle: Integer;
  ASpeed: TGreedFixed): Boolean;
var
  LAngle: Integer;
  LMoveX, LMoveY: TGreedFixed;
begin
  LAngle := AAngle and GREED_ANGLES;
  LMoveX := TGreedFixedMath.Mul(ASpeed, TGreedTrigTables.Cosine(LAngle));
  LMoveY := -TGreedFixedMath.Mul(ASpeed, TGreedTrigTables.Sine(LAngle));
  Result := ClipMove(APlayer, LAngle, LMoveX, LMoveY);
  APlayer.MapSpot := (APlayer.Y div GREED_FRACTILEUNIT) * GREED_MAP_SIZE + (APlayer.X div GREED_FRACTILEUNIT);
end;

end.
