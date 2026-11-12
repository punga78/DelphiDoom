{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - how a monster looks for its target               }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): ScanX, ScanY, ScanAngle,    }
{  GetFireAngle, CloneScanX and CloneScanY of sprites.pas                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.SpriteScan;

// the positions are 16.16 fixed point numbers: the arithmetic wraps as in the original
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.World.Intf,
  DelphiDoom.Greed.Random, DelphiDoom.Greed.Game.State;

type
  /// <summary>
  ///   The sight of the monsters: they look along their row, their column and the four diagonals of the tiles,
  ///   up to a number of tiles, until a wall that stops bullets or a solid sprite. The answer 2 means that the
  ///   target is there (the tile of the player, a net player or a clone in mapsprites, and for an enraged monster
  ///   any other monster), with the tile to shoot at in ATargetX and ATargetY (the original writes only the
  ///   coordinate that it knows: the other keeps the value of the caller). GetFireAngle is the vertical angle of
  ///   the shot from the table TGreedTargetAngles. The clones look for monsters and other clones along the two
  ///   axes. A tile outside the map reads as 0
  /// </summary>
  TGreedSpriteScan = class
  strict private
    FState: TGreedGameState;
    FRandom: IGreedRandom;
    function StopsBullets(const AWorld: IGreedWorld; AWall, AFlags: TGreedPlane; ASpot: Integer): Boolean;
  public
    constructor Create(const AState: TGreedGameState; const ARandom: IGreedRandom);
    /// <summary>ScanX: along the row, east then west. 2 target, 1 a sprite in the way to the west, 0 nothing</summary>
    function ScanX(ASprite: PGreedSprite; ALimit, AX1, AY1, AX2, AY2: Integer;
      var ATargetX, ATargetY: Integer): Integer;
    /// <summary>
    ///   ScanY: along the column, south then north. The original counts the limit upwards while it goes south
    ///   (so there is no limit): kept, the scan stops at the end of the map
    /// </summary>
    function ScanY(ASprite: PGreedSprite; ALimit, AX1, AY1, AX2, AY2: Integer;
      var ATargetX, ATargetY: Integer): Integer;
    /// <summary>ScanAngle: along the four diagonals (approximate, as the original says)</summary>
    function ScanAngle(ASprite: PGreedSprite; ALimit, AX1, AY1, AX2, AY2: Integer;
      var ATargetX, ATargetY: Integer): Integer;
    /// <summary>
    ///   GetFireAngle(sz, x1, y1, px, py, pz): the vertical angle to hit, from the height AHeight above the
    ///   sprite, the tile (x1, y1): the first living sprite of that tile if it is not the tile of (px, py)
    /// </summary>
    function GetFireAngle(ASprite: PGreedSprite; AHeight: TGreedFixed; AX1, AY1: Integer;
      ATargetX, ATargetY, ATargetZ: TGreedFixed): Integer;
    /// <summary>CloneScanX: 2 (or 1, by chance) when a monster or a clone is on the row within 10 tiles</summary>
    function CloneScanX(AX, AY: Integer; var ATargetX: Integer): Integer;
    /// <summary>CloneScanY: the same along the column</summary>
    function CloneScanY(AX, AY: Integer; var ATargetY: Integer): Integer;
  end;

implementation

uses
  DelphiDoom.Greed.FixedMath, DelphiDoom.MathCore.FixedMath, DelphiDoom.Greed.LinkedPool,
  DelphiDoom.Greed.Game.Constants, DelphiDoom.Greed.TargetAngles;

const
  // F_NOCLIP and F_NOBULLETCLIP of r_refdef.pas
  WALL_NO_CLIP = 1 shl 5;
  WALL_NO_BULLET_CLIP = 1 shl 6;
  MAP_SPRITE_MONSTER = 1;
  CLONE_SCAN_LIMIT = 10;
  // an enraged monster shoots at the other monsters from 6 hits, less the difficulty
  ENRAGED_BASE = 6;
  // the table of the angles is in steps of 4 units
  TARGET_STEP_SHIFT = GREED_FRACBITS + 2;

{ TGreedSpriteScan }

constructor TGreedSpriteScan.Create(const AState: TGreedGameState; const ARandom: IGreedRandom);
begin
  inherited Create;
  if not Assigned(AState) then
    raise EArgumentNilException.Create('AState');
  if not Assigned(ARandom) then
    raise EArgumentNilException.Create('ARandom');
  FState := AState;
  FRandom := ARandom;
end;

function TGreedSpriteScan.StopsBullets(const AWorld: IGreedWorld; AWall, AFlags: TGreedPlane;
  ASpot: Integer): Boolean;
var
  LFlags: Byte;
begin
  if AWorld.GetValue(AWall, ASpot) = 0 then
    Exit(False);
  LFlags := AWorld.GetValue(AFlags, ASpot);
  Result := (LFlags and WALL_NO_CLIP = 0) and (LFlags and WALL_NO_BULLET_CLIP = 0);
end;

function TGreedSpriteScan.ScanX(ASprite: PGreedSprite; ALimit, AX1, AY1, AX2, AY2: Integer;
  var ATargetX, ATargetY: Integer): Integer;
var
  LSpot, LX, LLimit: Integer;
  LMapSprite: Byte;
  LEnraged: Boolean;
  LWorld: IGreedWorld;
begin
  LWorld := FState.World;
  LEnraged := ASprite^.Enraged >= ENRAGED_BASE - FState.Player.Difficulty;
  LSpot := AY1 * GREED_MAP_SIZE + AX1 + 1;
  LX := AX1;
  LLimit := ALimit;
  while True do
  begin
    LMapSprite := LWorld.GetValue(gpMapSprites, LSpot);
    if (LMapSprite = GREED_SM_NETPLAYER) or (LMapSprite = GREED_SM_CLONE) or ((LX = AX2) and (AY1 = AY2)) then
    begin
      ATargetX := LX + 1;
      Exit(2);
    end;
    if LEnraged and (LMapSprite = MAP_SPRITE_MONSTER) then
    begin
      ATargetX := LX + 1;
      ATargetY := AY1;
      Exit(2);
    end;
    if (LMapSprite > 0) and (LMapSprite < 128) then
      Break;
    if StopsBullets(LWorld, gpWestWall, gpWestFlags, LSpot) then
      Break;
    Inc(LSpot);
    Inc(LX);
    Dec(LLimit);
    if LLimit = 0 then
      Break;
  end;
  LLimit := ALimit;
  LSpot := AY1 * GREED_MAP_SIZE + AX1 - 1;
  LX := AX1;
  while True do
  begin
    LMapSprite := LWorld.GetValue(gpMapSprites, LSpot);
    if (LMapSprite = GREED_SM_NETPLAYER) or (LMapSprite = GREED_SM_CLONE) or ((LX = AX2) and (AY1 = AY2)) then
    begin
      ATargetX := LX - 1;
      Exit(2);
    end;
    if LEnraged and (LMapSprite = MAP_SPRITE_MONSTER) then
    begin
      ATargetX := LX - 1;
      ATargetY := AY1;
      Exit(2);
    end;
    if (LMapSprite > 0) and (LMapSprite < 128) then
      Exit(1);
    if StopsBullets(LWorld, gpWestWall, gpWestFlags, LSpot + 1) then
      Exit(0);
    Dec(LSpot);
    Dec(LX);
    Dec(LLimit);
    if LLimit = 0 then
      Break;
  end;
  Result := 0;
end;

function TGreedSpriteScan.ScanY(ASprite: PGreedSprite; ALimit, AX1, AY1, AX2, AY2: Integer;
  var ATargetX, ATargetY: Integer): Integer;
var
  LSpot, LY, LLimit: Integer;
  LMapSprite: Byte;
  LEnraged: Boolean;
  LWorld: IGreedWorld;
begin
  LWorld := FState.World;
  LEnraged := ASprite^.Enraged >= ENRAGED_BASE - FState.Player.Difficulty;
  LLimit := ALimit;
  LSpot := AY1 * GREED_MAP_SIZE + AX1 + GREED_MAP_SIZE;
  LY := AY1;
  while True do
  begin
    LMapSprite := LWorld.GetValue(gpMapSprites, LSpot);
    if (LMapSprite = GREED_SM_NETPLAYER) or (LMapSprite = GREED_SM_CLONE) or ((LY = AY2) and (AX1 = AX2)) then
    begin
      ATargetY := LY + 1;
      Exit(2);
    end;
    if LEnraged and (LMapSprite = MAP_SPRITE_MONSTER) then
    begin
      ATargetX := AX1;
      ATargetY := LY + 1;
      Exit(2);
    end;
    if (LMapSprite > 0) and (LMapSprite < 128) then
      Break;
    if StopsBullets(LWorld, gpNorthWall, gpNorthFlags, LSpot) then
      Break;
    LSpot := LSpot + GREED_MAP_SIZE;
    Inc(LY);
    // the original increments the limit here: it never gets to 0
    Inc(LLimit);
    if LLimit = 0 then
      Break;
    // the original goes on in the memory after the map
    if LSpot >= GREED_MAP_TILES then
      Break;
  end;
  LLimit := ALimit;
  LSpot := AY1 * GREED_MAP_SIZE + AX1 - GREED_MAP_SIZE;
  LY := AY1;
  while True do
  begin
    LMapSprite := LWorld.GetValue(gpMapSprites, LSpot);
    if (LMapSprite = GREED_SM_NETPLAYER) or (LMapSprite = GREED_SM_CLONE) or ((LY = AY2) and (AX1 = AX2)) then
    begin
      ATargetY := LY - 1;
      Exit(2);
    end;
    if LEnraged and (LMapSprite = MAP_SPRITE_MONSTER) then
    begin
      ATargetX := AX1;
      ATargetY := LY - 1;
      Exit(2);
    end;
    if (LMapSprite > 0) and (LMapSprite < 128) then
      Break;
    if StopsBullets(LWorld, gpNorthWall, gpNorthFlags, LSpot + GREED_MAP_SIZE) then
      Break;
    LSpot := LSpot - GREED_MAP_SIZE;
    Dec(LY);
    Dec(LLimit);
    if LLimit = 0 then
      Break;
  end;
  Result := 0;
end;

function TGreedSpriteScan.ScanAngle(ASprite: PGreedSprite; ALimit, AX1, AY1, AX2, AY2: Integer;
  var ATargetX, ATargetY: Integer): Integer;
type
  TDiagonal = record
    StepX, StepY: Integer;
    // the tile, from the current one, whose north wall ends the diagonal
    NorthOffset: Integer;
    // what the original adds to the tile at each step (the two diagonals to the north are swapped in it)
    SpotStep: Integer;
  end;
const
  DIAGONALS: array[0..3] of TDiagonal = (
    (StepX: 1; StepY: 1; NorthOffset: -1; SpotStep: GREED_MAP_SIZE + 1),
    (StepX: -1; StepY: 1; NorthOffset: 1; SpotStep: GREED_MAP_SIZE - 1),
    (StepX: 1; StepY: -1; NorthOffset: GREED_MAP_SIZE - 1; SpotStep: -(GREED_MAP_SIZE + 1)),
    (StepX: -1; StepY: -1; NorthOffset: GREED_MAP_SIZE + 1; SpotStep: -(GREED_MAP_SIZE - 1)));
var
  LSpot, LX, LY, LLimit, LIndex: Integer;
  LMapSprite: Byte;
  LEnraged: Boolean;
  LWorld: IGreedWorld;
begin
  LWorld := FState.World;
  LEnraged := ASprite^.Enraged >= ENRAGED_BASE - FState.Player.Difficulty;
  for LIndex := Low(DIAGONALS) to High(DIAGONALS) do
  begin
    LLimit := ALimit;
    LSpot := AY1 * GREED_MAP_SIZE + AX1 + DIAGONALS[LIndex].StepY * GREED_MAP_SIZE + DIAGONALS[LIndex].StepX;
    LY := AY1;
    LX := AX1;
    while True do
    begin
      if StopsBullets(LWorld, gpNorthWall, gpNorthFlags, LSpot + DIAGONALS[LIndex].NorthOffset) then
        Break;
      // a west wall ends the whole scan, not only this diagonal
      if StopsBullets(LWorld, gpWestWall, gpWestFlags, LSpot - GREED_MAP_SIZE) then
        Exit(0);
      LMapSprite := LWorld.GetValue(gpMapSprites, LSpot);
      if (LMapSprite = GREED_SM_NETPLAYER) or (LMapSprite = GREED_SM_CLONE) or ((LY = AY2) and (LX = AX2)) then
      begin
        ATargetX := LX + DIAGONALS[LIndex].StepX;
        ATargetY := LY + DIAGONALS[LIndex].StepY;
        Exit(2);
      end;
      if LEnraged and (LMapSprite = MAP_SPRITE_MONSTER) then
      begin
        ATargetX := LX + DIAGONALS[LIndex].StepX;
        ATargetY := LY + DIAGONALS[LIndex].StepY;
        Exit(2);
      end;
      if (LMapSprite > 0) and (LMapSprite < 128) then
        Break;
      LSpot := LSpot + DIAGONALS[LIndex].SpotStep;
      LY := LY + DIAGONALS[LIndex].StepY;
      LX := LX + DIAGONALS[LIndex].StepX;
      Dec(LLimit);
      if LLimit = 0 then
        Break;
    end;
  end;
  Result := 0;
end;

function TGreedSpriteScan.GetFireAngle(ASprite: PGreedSprite; AHeight: TGreedFixed; AX1, AY1: Integer;
  ATargetX, ATargetY, ATargetZ: TGreedFixed): Integer;
var
  LIndex, LX, LY, LZ, LDistance, LTile, LSpot: Integer;
  LOther: PGreedSprite;
  LAngle: Integer;
begin
  AHeight := AHeight + ASprite^.Z;
  if (AX1 <> ATargetX div GREED_FRACTILEUNIT) or (AY1 <> ATargetY div GREED_FRACTILEUNIT) then
  begin
    LTile := AY1 * GREED_MAP_SIZE + AX1;
    LIndex := FState.Sprites.First;
    while LIndex <> GREED_POOL_NIL do
    begin
      LOther := PGreedSprite(FState.Sprites.Item(LIndex));
      if LOther^.HitPoints <> 0 then
      begin
        LSpot := (LOther^.Y div GREED_FRACTILEUNIT) * GREED_MAP_SIZE + (LOther^.X div GREED_FRACTILEUNIT);
        if LSpot = LTile then
        begin
          ATargetX := LOther^.X;
          ATargetY := LOther^.Y;
          ATargetZ := LOther^.Z + (32 * GREED_FRACUNIT);
          Break;
        end;
      end;
      LIndex := FState.Sprites.Next(LIndex);
    end;
  end
  else
    ATargetZ := ATargetZ + 20 * GREED_FRACUNIT;
  if AHeight = ATargetZ then
    Exit(0);
  if AHeight > ATargetZ then
    LZ := TGreedFixedMath.ShiftRight(AHeight - ATargetZ, TARGET_STEP_SHIFT)
  else
    LZ := TGreedFixedMath.ShiftRight(ATargetZ - AHeight, TARGET_STEP_SHIFT);
  if LZ >= GREED_TARGET_ANGLE_SIZE then
    Exit(0);
  LX := TGreedFixedMath.ShiftRight(ASprite^.X - ATargetX, TARGET_STEP_SHIFT);
  LY := TGreedFixedMath.ShiftRight(ASprite^.Y - ATargetY, TARGET_STEP_SHIFT);
  LDistance := Trunc(Sqrt(LX * LX + LY * LY));
  // the original reads the table with a negative height when the subtraction wraps: nothing to aim at
  if (LDistance >= GREED_TARGET_ANGLE_SIZE) or (LZ < 0) then
    Exit(0);
  LAngle := TGreedTargetAngles.Angle(LDistance, LZ);
  if LAngle = -1 then
    Exit(0);
  if AHeight > ATargetZ then
    Result := -LAngle
  else
    Result := LAngle;
end;

function TGreedSpriteScan.CloneScanX(AX, AY: Integer; var ATargetX: Integer): Integer;
var
  LSpot, LX, LLimit: Integer;
  LMapSprite: Byte;
  LWorld: IGreedWorld;
begin
  LWorld := FState.World;
  LSpot := AY * GREED_MAP_SIZE + AX + 1;
  LX := AX;
  LLimit := CLONE_SCAN_LIMIT;
  while True do
  begin
    LMapSprite := LWorld.GetValue(gpMapSprites, LSpot);
    if (LMapSprite = GREED_SM_CLONE) or (LMapSprite = MAP_SPRITE_MONSTER) then
    begin
      ATargetX := LX + 1;
      Exit(1 + (FRandom.Next and 1));
    end;
    if (LMapSprite > 0) and (LMapSprite < 128) then
      Break;
    if StopsBullets(LWorld, gpWestWall, gpWestFlags, LSpot) then
      Break;
    Inc(LSpot);
    Inc(LX);
    Dec(LLimit);
    if LLimit = 0 then
      Break;
  end;
  LLimit := CLONE_SCAN_LIMIT;
  LSpot := AY * GREED_MAP_SIZE + AX - 1;
  LX := AX;
  while True do
  begin
    LMapSprite := LWorld.GetValue(gpMapSprites, LSpot);
    if (LMapSprite = GREED_SM_CLONE) or (LMapSprite = MAP_SPRITE_MONSTER) then
    begin
      ATargetX := LX - 1;
      Exit(1 + (FRandom.Next and 1));
    end;
    if (LMapSprite > 0) and (LMapSprite < 128) then
      Exit(1);
    if StopsBullets(LWorld, gpWestWall, gpWestFlags, LSpot + 1) then
      Exit(0);
    Dec(LSpot);
    Dec(LX);
    Dec(LLimit);
    if LLimit = 0 then
      Break;
  end;
  Result := 0;
end;

function TGreedSpriteScan.CloneScanY(AX, AY: Integer; var ATargetY: Integer): Integer;
var
  LSpot, LY, LLimit: Integer;
  LMapSprite: Byte;
  LWorld: IGreedWorld;
begin
  LWorld := FState.World;
  LLimit := CLONE_SCAN_LIMIT;
  LSpot := AY * GREED_MAP_SIZE + AX + GREED_MAP_SIZE;
  LY := AY;
  while True do
  begin
    LMapSprite := LWorld.GetValue(gpMapSprites, LSpot);
    if (LMapSprite = GREED_SM_CLONE) or (LMapSprite = MAP_SPRITE_MONSTER) then
    begin
      ATargetY := LY + 1;
      Exit(1 + (FRandom.Next and 1));
    end;
    if (LMapSprite > 0) and (LMapSprite < 128) then
      Break;
    if StopsBullets(LWorld, gpNorthWall, gpNorthFlags, LSpot) then
      Break;
    LSpot := LSpot + GREED_MAP_SIZE;
    Inc(LY);
    Dec(LLimit);
    if LLimit = 0 then
      Break;
  end;
  LLimit := CLONE_SCAN_LIMIT;
  LSpot := AY * GREED_MAP_SIZE + AX - GREED_MAP_SIZE;
  LY := AY;
  while True do
  begin
    LMapSprite := LWorld.GetValue(gpMapSprites, LSpot);
    if (LMapSprite = GREED_SM_CLONE) or (LMapSprite = MAP_SPRITE_MONSTER) then
    begin
      ATargetY := LY - 1;
      Exit(1 + (FRandom.Next and 1));
    end;
    if (LMapSprite > 0) and (LMapSprite < 128) then
      Break;
    if StopsBullets(LWorld, gpNorthWall, gpNorthFlags, LSpot + GREED_MAP_SIZE) then
      Break;
    LSpot := LSpot - GREED_MAP_SIZE;
    Dec(LY);
    Dec(LLimit);
    if LLimit = 0 then
      Break;
  end;
  Result := 0;
end;

end.
