{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the level seen from above                        }
{  Not a port: a stand-in for RF_RenderView (the renderer of Raven 3D is the    }
{  slice G11 and is not done) that shows the walls, doors and floors around the }
{  player, to see the map and the movement                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.TopDownRenderer;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.SaveTypes, DelphiDoom.Greed.World.Intf,
  DelphiDoom.Greed.Frame.Intf;

const
  /// <summary>Pixels of a tile in the picture</summary>
  GREED_TOP_DOWN_TILE_PIXELS = 8;
  /// <summary>Indexes in the palette of the game (WALL_COLOR and DOOR_COLOR of r_public_h.pas, and two more)</summary>
  GREED_TOP_DOWN_WALL = 127;
  GREED_TOP_DOWN_DOOR = 73;
  GREED_TOP_DOWN_FLOOR = 132;
  GREED_TOP_DOWN_PLAYER = 15;

type
  /// <summary>
  ///   The picture has the player at its center and 8 pixels for each tile (8 units a pixel): the floor, the north
  ///   and west walls on the first row and column of their tile, the door tiles, a square for the player and a line
  ///   for where it looks. What is outside the map or has no floor is index 0
  /// </summary>
  TGreedTopDownRenderer = class(TInterfacedObject, IGreedFrameRenderer)
  strict private
    FFloor: Byte;
    FWall: Byte;
    FDoor: Byte;
    FPlayer: Byte;
  public
    /// <summary>With the indexes of the constants above</summary>
    constructor Create; overload;
    /// <summary>With the indexes of the palette that the program found for the colors it wants</summary>
    constructor Create(AFloor, AWall, ADoor, APlayer: Byte); overload;
    procedure Render(const AWorld: IGreedWorld; const APlayer: TGreedPlayerRecord; var AFrame: TGreedFrame);
  end;

implementation

uses
  DelphiDoom.Greed.TrigTables;

const
  UNITS_PER_PIXEL = (64 * GREED_FRACUNIT) div GREED_TOP_DOWN_TILE_PIXELS;

{ TGreedTopDownRenderer }

constructor TGreedTopDownRenderer.Create;
begin
  Create(GREED_TOP_DOWN_FLOOR, GREED_TOP_DOWN_WALL, GREED_TOP_DOWN_DOOR, GREED_TOP_DOWN_PLAYER);
end;

constructor TGreedTopDownRenderer.Create(AFloor, AWall, ADoor, APlayer: Byte);
begin
  inherited Create;
  FFloor := AFloor;
  FWall := AWall;
  FDoor := ADoor;
  FPlayer := APlayer;
end;

procedure TGreedTopDownRenderer.Render(const AWorld: IGreedWorld; const APlayer: TGreedPlayerRecord;
  var AFrame: TGreedFrame);
var
  LX, LY, LCenterX, LCenterY, LSpot, LTileX, LTileY, LSubX, LSubY, LStep: Integer;
  LWorldX, LWorldY: Int64;
  LColor: Byte;
begin
  if (AFrame.Width < 24) or (AFrame.Height < 24) or (Length(AFrame.Pixels) < AFrame.Width * AFrame.Height) then
    raise EGreedException.CreateFmt(SGreedImageSize, [AFrame.Width, AFrame.Height, 'frame']);
  LCenterX := AFrame.Width div 2;
  LCenterY := AFrame.Height div 2;
  for LY := 0 to AFrame.Height - 1 do
    for LX := 0 to AFrame.Width - 1 do
    begin
      LWorldX := Int64(APlayer.X) + Int64(LX - LCenterX) * UNITS_PER_PIXEL;
      LWorldY := Int64(APlayer.Y) + Int64(LY - LCenterY) * UNITS_PER_PIXEL;
      LColor := 0;
      if (LWorldX >= 0) and (LWorldY >= 0) and (LWorldX < Int64(GREED_MAP_SIZE) * GREED_FRACTILEUNIT) and
        (LWorldY < Int64(GREED_MAP_SIZE) * GREED_FRACTILEUNIT) then
      begin
        LTileX := LWorldX div GREED_FRACTILEUNIT;
        LTileY := LWorldY div GREED_FRACTILEUNIT;
        LSubX := (LWorldX mod GREED_FRACTILEUNIT) div UNITS_PER_PIXEL;
        LSubY := (LWorldY mod GREED_FRACTILEUNIT) div UNITS_PER_PIXEL;
        LSpot := LTileY * GREED_MAP_SIZE + LTileX;
        if AWorld.GetMapFlags(LSpot) and GREED_FL_DOOR <> 0 then
          LColor := FDoor
        else if (LSubY = 0) and (AWorld.GetValue(gpNorthWall, LSpot) <> 0) then
          LColor := FWall
        else if (LSubX = 0) and (AWorld.GetValue(gpWestWall, LSpot) <> 0) then
          LColor := FWall
        else if AWorld.GetValue(gpFloorPic, LSpot) <> 0 then
          LColor := FFloor;
      end;
      AFrame.Pixels[LY * AFrame.Width + LX] := LColor;
    end;
  // the player: a square of 5 pixels and a line of 8 in the direction it looks
  for LY := -2 to 2 do
    for LX := -2 to 2 do
      AFrame.Pixels[(LCenterY + LY) * AFrame.Width + LCenterX + LX] := FPlayer;
  for LStep := 3 to 10 do
  begin
    LX := LCenterX + TGreedTrigTables.Cosine(APlayer.Angle and GREED_ANGLES) * LStep div GREED_FRACUNIT;
    LY := LCenterY - TGreedTrigTables.Sine(APlayer.Angle and GREED_ANGLES) * LStep div GREED_FRACUNIT;
    if (LX >= 0) and (LX < AFrame.Width) and (LY >= 0) and (LY < AFrame.Height) then
      AFrame.Pixels[LY * AFrame.Width + LX] := FPlayer;
  end;
end;

end.
