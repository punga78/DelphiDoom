{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the greed library - the scenarios of the renderer       }
{                                                                              }
{  The same scenarios are given to the ORIGINAL renderer of xGreed (the harness }
{  Tools\Verifica\175-render) and to the library: doors, sprites, lights and    }
{  views made from a map with a generator that does not change, so that the     }
{  CRC of the pictures of the original can be a golden file                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.RenderScenarios;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.World.Intf;

type
  /// <summary>A place to look from, with the size of the picture and the time of the game</summary>
  TRenderView = record
    X, Y, Z, Angle, ScrollMin: Integer;
    Width, Height: Integer;
    TimeCount, SpriteMoveTime: Integer;
  end;

  TRenderLight = record
    Spot, Value: Integer;
  end;

  /// <summary>The things of a map for the pictures: some doors, sprites and lights, and the views</summary>
  TRenderScenario = record
    Doors: TArray<TGreedDoor>;
    Sprites: TArray<TGreedSprite>;
    Lights: TArray<TRenderLight>;
    Views: TArray<TRenderView>;
  end;

  /// <summary>A generator of numbers that does not depend on the compiler (xorshift32)</summary>
  TRenderRandom = class
  strict private
    FState: Cardinal;
  public
    constructor Create(ASeed: Cardinal);
    function Next: Cardinal;
    /// <summary>0 .. ACount - 1</summary>
    function Below(ACount: Integer): Integer;
  end;

  TRenderScenarios = class
  public
    /// <summary>For the harness: no doors in the scenarios</summary>
    class var NoDoors: Boolean;
    /// <summary>
    ///   AWallNumbers are the numbers of the walls that can be door pictures, ASpriteRuns[lump] the sprite lumps that
    ///   follow one another from the lump (0 if the lump is not a sprite)
    /// </summary>
    class function Build(const AWorld: IGreedWorld; ASeed: Cardinal; AViewCount, ASpriteCount: Integer;
      const AWallNumbers: TArray<Integer>; const ASpriteRuns: TArray<Integer>): TRenderScenario; static;
  end;

implementation

uses
  DelphiDoom.Greed.Terrain;

{ TRenderRandom }

constructor TRenderRandom.Create(ASeed: Cardinal);
begin
  inherited Create;
  FState := ASeed;
  if FState = 0 then
    FState := 2463534242;
end;

function TRenderRandom.Next: Cardinal;
begin
  FState := FState xor (FState shl 13);
  FState := FState xor (FState shr 17);
  FState := FState xor (FState shl 5);
  Result := FState;
end;

function TRenderRandom.Below(ACount: Integer): Integer;
begin
  Result := Integer(Next mod Cardinal(ACount));
end;

{ TRenderScenarios }

class function TRenderScenarios.Build(const AWorld: IGreedWorld; ASeed: Cardinal; AViewCount, ASpriteCount: Integer;
  const AWallNumbers: TArray<Integer>; const ASpriteRuns: TArray<Integer>): TRenderScenario;
const
  KINDS: array[0..6] of Integer = (75, 76, 34, 532, 20, 100, 605);
  POSITIONS: array[0..5] of Integer = (0, 8, 32, 63, 64, -1);
var
  LRandom: TRenderRandom;
  LSpot, LIndex, LCount, LTileX, LTileY, LRun, LMax, LExtra: Integer;
  LDoorSpots: TArray<Integer>;
  LDoor: TGreedDoor;
  LSprite: TGreedSprite;
  LView: TRenderView;
  LSpriteLumps: TArray<Integer>;
  LFloorZ: Integer;
begin
  LRandom := TRenderRandom.Create(ASeed);
  try
    // the doors: some of the tiles with a door in the map (the sprites 60 .. 73 of the map are doors)
    for LSpot := 0 to GREED_MAP_TILES - 1 do
      if (AWorld.GetValue(gpMapSprites, LSpot) >= 60) and (AWorld.GetValue(gpMapSprites, LSpot) <= 73) then
      begin
        SetLength(LDoorSpots, Length(LDoorSpots) + 1);
        LDoorSpots[High(LDoorSpots)] := LSpot;
      end;
    LCount := Length(LDoorSpots);
    if LCount > 6 then
      LCount := 6;
    if NoDoors then
      LCount := 0;
    for LIndex := 0 to LCount - 1 do
    begin
      LSpot := LDoorSpots[LRandom.Below(Length(LDoorSpots))];
      LDoor := Default(TGreedDoor);
      LDoor.TileX := LSpot mod GREED_MAP_SIZE;
      LDoor.TileY := LSpot div GREED_MAP_SIZE;
      if AWorld.GetValue(gpMapSprites, LSpot) and 1 = 0 then
        LDoor.Orientation := gdoVertical
      else
        LDoor.Orientation := gdoHorizontal;
      if LRandom.Below(3) = 0 then
        Inc(LDoor.Orientation, 2);
      LDoor.Pic := AWallNumbers[LRandom.Below(Length(AWallNumbers))];
      LDoor.Position := POSITIONS[LRandom.Below(Length(POSITIONS))] * GREED_FRACUNIT;
      if LDoor.Position < 0 then
        LDoor.Position := LRandom.Below(64 * GREED_FRACUNIT);
      // a door of the same tile twice would be one door in the original
      for LExtra := 0 to High(Result.Doors) do
        if (Result.Doors[LExtra].TileX = LDoor.TileX) and (Result.Doors[LExtra].TileY = LDoor.TileY) then
          LDoor.TileX := -1;
      if LDoor.TileX >= 0 then
      begin
        SetLength(Result.Doors, Length(Result.Doors) + 1);
        Result.Doors[High(Result.Doors)] := LDoor;
      end;
    end;

    // the sprites
    for LIndex := 0 to High(ASpriteRuns) do
      if ASpriteRuns[LIndex] > 0 then
      begin
        SetLength(LSpriteLumps, Length(LSpriteLumps) + 1);
        LSpriteLumps[High(LSpriteLumps)] := LIndex;
      end;
    if Length(LSpriteLumps) > 0 then
      for LIndex := 0 to ASpriteCount - 1 do
      begin
        LSprite := Default(TGreedSprite);
        LSprite.BasePic := LSpriteLumps[LRandom.Below(Length(LSpriteLumps))];
        LRun := ASpriteRuns[LSprite.BasePic];
        LSprite.Rotate := grOne;
        LExtra := 0;
        if (LRun >= 8) and (LRandom.Below(3) = 0) then
        begin
          if LRandom.Below(2) = 0 then
            LSprite.Rotate := grEight
          else
            LSprite.Rotate := grFour;
          LExtra := 8;
        end;
        LSprite.Angle := LRandom.Below(1024);
        LSprite.NewAngle := LRandom.Below(1024);
        LSprite.OldAngle := LRandom.Below(1024);
        if LRandom.Below(4) = 0 then
        begin
          // the old and new angle across the north: the way round the circle
          LSprite.OldAngle := LRandom.Below(200);
          LSprite.NewAngle := 1023 - LRandom.Below(200);
        end;
        if (LRun - LExtra >= 2) and (LRandom.Below(2) = 0) then
        begin
          LMax := LRun - LExtra;
          if LMax > 15 then
            LMax := 15;
          LSprite.Animation := LRandom.Below(2) + (LRandom.Below(LMax) * 2) + (LMax * 32) +
            ((LRandom.Below(8) + 1) shl 9);
          if LRandom.Below(4) = 0 then
            LSprite.Animation := LSprite.Animation or 32768;
          LSprite.AnimationTime := LRandom.Below(2000);
        end;
        LTileX := 1 + LRandom.Below(62);
        LTileY := 1 + LRandom.Below(62);
        LSprite.X := (LTileX * 64 + LRandom.Below(64)) * GREED_FRACUNIT;
        LSprite.Y := (LTileY * 64 + LRandom.Below(64)) * GREED_FRACUNIT;
        LFloorZ := TGreedTerrain.FloorZ(AWorld, LSprite.X, LSprite.Y);
        LSprite.Z := LFloorZ + LRandom.Below(40) * GREED_FRACUNIT;
        LSprite.Scale := LRandom.Below(4) div 3;
        LSprite.SpecialType := TGreedSpecialType(LRandom.Below(4));
        LSprite.Kind := KINDS[LRandom.Below(Length(KINDS))];
        LSprite.OldX := LSprite.X - LRandom.Below(20 * GREED_FRACUNIT);
        LSprite.OldY := LSprite.Y - LRandom.Below(20 * GREED_FRACUNIT);
        LSprite.NewX := LSprite.X;
        LSprite.NewY := LSprite.Y;
        LSprite.OldZ := LSprite.Z - LRandom.Below(8 * GREED_FRACUNIT);
        LSprite.NewZ := LSprite.Z;
        LSprite.OldFloorZ := LFloorZ - LRandom.Below(3) * GREED_FRACUNIT;
        LSprite.NewFloorZ := LFloorZ + LRandom.Below(3) * GREED_FRACUNIT;
        LSprite.Grounded := LRandom.Below(2) = 0;
        SetLength(Result.Sprites, Length(Result.Sprites) + 1);
        Result.Sprites[High(Result.Sprites)] := LSprite;
      end;

    // the lights that the sprites add to the tiles
    for LIndex := 0 to 19 do
    begin
      SetLength(Result.Lights, Length(Result.Lights) + 1);
      Result.Lights[High(Result.Lights)].Spot := LRandom.Below(GREED_MAP_TILES);
      Result.Lights[High(Result.Lights)].Value := LRandom.Below(40) - 10;
    end;

    // the views: tiles that are not solid, looking at random angles
    for LIndex := 0 to AViewCount - 1 do
    begin
      repeat
        LTileX := 2 + LRandom.Below(60);
        LTileY := 2 + LRandom.Below(60);
        LSpot := LTileY * GREED_MAP_SIZE + LTileX;
      until (AWorld.GetValue(gpCeilingHeight, LSpot) > AWorld.GetValue(gpFloorHeight, LSpot) + 40) and
        (AWorld.GetMapFlags(LSpot) and GREED_FL_DOOR = 0);
      LView := Default(TRenderView);
      LView.X := (LTileX * 64 + 16 + LRandom.Below(32)) * GREED_FRACUNIT;
      LView.Y := (LTileY * 64 + 16 + LRandom.Below(32)) * GREED_FRACUNIT;
      LView.Z := TGreedTerrain.FloorZ(AWorld, LView.X, LView.Y) + 41 * GREED_FRACUNIT;
      LView.Angle := LRandom.Below(1024);
      case LRandom.Below(5) of
        0: LView.ScrollMin := -20;
        1: LView.ScrollMin := 25;
      else
        LView.ScrollMin := 0;
      end;
      if LIndex mod 3 = 2 then
      begin
        LView.Width := 320;
        LView.Height := 200;
        if LView.ScrollMin <> 0 then
          LView.ScrollMin := LView.ScrollMin div 2;
      end
      else
      begin
        LView.Width := 640;
        LView.Height := 400;
      end;
      LView.TimeCount := LRandom.Below(2000);
      LView.SpriteMoveTime := LView.TimeCount + LRandom.Below(13) - 2;
      SetLength(Result.Views, Length(Result.Views) + 1);
      Result.Views[High(Result.Views)] := LView;
    end;
  finally
    LRandom.Free;
  end;
end;

end.
