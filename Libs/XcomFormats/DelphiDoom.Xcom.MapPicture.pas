{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom formats library - a schematic picture of a block of map     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.MapPicture;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Image, DelphiDoom.Xcom.Map;

const
  /// <summary>Pixels of a side of a cell in the picture</summary>
  XCOM_MAP_PICTURE_CELL = 8;
  /// <summary>The palette indexes the picture uses: floor, west wall, north wall, object</summary>
  XCOM_MAP_PICTURE_FLOOR = 6;
  XCOM_MAP_PICTURE_WEST_WALL = 14;
  XCOM_MAP_PICTURE_NORTH_WALL = 15;
  XCOM_MAP_PICTURE_OBJECT = 9;

type
  /// <summary>
  ///   A look at a layer of a block, not the isometric view of the game: every cell is a square of 8 x 8 pixels, the
  ///   floor fills it, the west wall is its left column, the north wall its top row and an object the middle of it
  /// </summary>
  TXcomMapPicture = class
  public
    /// <summary>The layer AZ (0 is the lowest) of the block; EXcomException if the block does not have it</summary>
    class function Render(const AMap: TXcomMap; AZ: Integer): TXcomImage; static;
  end;

implementation

{ TXcomMapPicture }

class function TXcomMapPicture.Render(const AMap: TXcomMap; AZ: Integer): TXcomImage;
var
  LX: Integer;
  LY: Integer;
  LCell: TXcomMapCell;
  LInner: Integer;
  LOuter: Integer;
begin
  Result := TXcomImage.Create(AMap.SizeX * XCOM_MAP_PICTURE_CELL, AMap.SizeY * XCOM_MAP_PICTURE_CELL);
  for LY := 0 to AMap.SizeY - 1 do
    for LX := 0 to AMap.SizeX - 1 do
    begin
      LCell := AMap.CellAt(LX, LY, AZ);
      if LCell.Floor > 0 then
        for LInner := 0 to XCOM_MAP_PICTURE_CELL - 1 do
          for LOuter := 0 to XCOM_MAP_PICTURE_CELL - 1 do
            Result.SetPixel(LX * XCOM_MAP_PICTURE_CELL + LOuter, LY * XCOM_MAP_PICTURE_CELL + LInner,
              XCOM_MAP_PICTURE_FLOOR);
      if LCell.Obj > 0 then
        for LInner := 2 to XCOM_MAP_PICTURE_CELL - 3 do
          for LOuter := 2 to XCOM_MAP_PICTURE_CELL - 3 do
            Result.SetPixel(LX * XCOM_MAP_PICTURE_CELL + LOuter, LY * XCOM_MAP_PICTURE_CELL + LInner,
              XCOM_MAP_PICTURE_OBJECT);
      if LCell.WestWall > 0 then
        for LInner := 0 to XCOM_MAP_PICTURE_CELL - 1 do
          Result.SetPixel(LX * XCOM_MAP_PICTURE_CELL, LY * XCOM_MAP_PICTURE_CELL + LInner,
            XCOM_MAP_PICTURE_WEST_WALL);
      if LCell.NorthWall > 0 then
        for LInner := 0 to XCOM_MAP_PICTURE_CELL - 1 do
          Result.SetPixel(LX * XCOM_MAP_PICTURE_CELL + LInner, LY * XCOM_MAP_PICTURE_CELL,
            XCOM_MAP_PICTURE_NORTH_WALL);
    end;
end;

end.
