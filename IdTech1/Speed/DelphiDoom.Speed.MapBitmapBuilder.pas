{******************************************************************************}
{                                                                              }
{  DelphiDoom: speed library - TSpeedMapBitmapBuilder                          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Copyright (C) 1995 by Noriaworks (Speed Haste)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of GenerateMapBitmap (speed_xlat_wad.pas)                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Speed.MapBitmapBuilder;

interface

uses
  System.SysUtils,
  DelphiDoom.Speed.Types, DelphiDoom.Speed.Intf;

type
  /// <summary>
  ///   Makes the floor of a circuit: 64 x 64 tiles of 64 x 64 pixels, each turned by its angle,
  ///   as a picture of 4096 x 4096 pixels (the lump FMAPnn, a flat of 16 MB), upside down as the
  ///   engine wants it
  /// </summary>
  TSpeedMapBitmapBuilder = class(TInterfacedObject, ISpeedMapBitmapBuilder)
  strict private
    class procedure RotateTile(var ATile: array of Byte; AAngle: Integer); static;
  public
    function Build(const AMapData, ATiles: TBytes; out ABitmap: TBytes; out AFirstTile: Integer): Boolean;
  end;

implementation

{ TSpeedMapBitmapBuilder }

class procedure TSpeedMapBitmapBuilder.RotateTile(var ATile: array of Byte; AAngle: Integer);
var
  LCopy: array[0..SPEED_TILE_PIXELS - 1] of Byte;
  LRow: Integer;
  LColumn: Integer;
begin
  if (AAngle < 1) or (AAngle > 3) then
    Exit;
  Move(ATile[0], LCopy[0], SPEED_TILE_PIXELS);
  for LRow := 0 to SPEED_TILE_SIZE - 1 do
    for LColumn := 0 to SPEED_TILE_SIZE - 1 do
      case AAngle of
        1: ATile[LRow * SPEED_TILE_SIZE + LColumn] := LCopy[(SPEED_TILE_SIZE - 1 - LColumn) * SPEED_TILE_SIZE + LRow];
        2: ATile[LRow * SPEED_TILE_SIZE + LColumn] :=
             LCopy[(SPEED_TILE_SIZE - 1 - LRow) * SPEED_TILE_SIZE + SPEED_TILE_SIZE - 1 - LColumn];
        3: ATile[LRow * SPEED_TILE_SIZE + LColumn] := LCopy[LColumn * SPEED_TILE_SIZE + SPEED_TILE_SIZE - 1 - LRow];
      end;
end;

function TSpeedMapBitmapBuilder.Build(const AMapData, ATiles: TBytes; out ABitmap: TBytes;
  out AFirstTile: Integer): Boolean;
const
  // the version and a reserved word come first
  TILES_OFFSET = 4;
  ANGLES_OFFSET = TILES_OFFSET + SPEED_MAP_TILES * SizeOf(SmallInt);
var
  LTile: array[0..SPEED_TILE_PIXELS - 1] of Byte;
  LTileNumber: SmallInt;
  LMap: Integer;
  LBaseX: Integer;
  LBaseY: Integer;
  LRow: Integer;
  LColumn: Integer;
  LSource: Integer;
  LPixel: Integer;
  LSwap: Byte;
  LAbove: Integer;
  LBelow: Integer;
begin
  ABitmap := nil;
  AFirstTile := 0;
  Result := Length(AMapData) >= ANGLES_OFFSET + SPEED_MAP_TILES;
  if not Result then
    Exit;
  AFirstTile := PSmallInt(@AMapData[TILES_OFFSET])^;
  SetLength(ABitmap, SPEED_MAP_BITMAP_SIDE * SPEED_MAP_BITMAP_SIDE);
  for LMap := 0 to SPEED_MAP_TILES - 1 do
  begin
    LBaseX := (LMap div SPEED_TILE_SIZE) * SPEED_TILE_SIZE;
    LBaseY := (LMap mod SPEED_TILE_SIZE) * SPEED_TILE_SIZE;
    LTileNumber := PSmallInt(@AMapData[TILES_OFFSET + LMap * SizeOf(SmallInt)])^;
    LSource := Integer(LTileNumber) * SPEED_TILE_PIXELS;
    // a tile that the file of the tiles does not have is black
    if (LSource >= 0) and (LSource + SPEED_TILE_PIXELS <= Length(ATiles)) then
      Move(ATiles[LSource], LTile[0], SPEED_TILE_PIXELS)
    else
      FillChar(LTile[0], SPEED_TILE_PIXELS, 0);
    RotateTile(LTile, AMapData[ANGLES_OFFSET + LMap]);
    LPixel := 0;
    for LRow := LBaseY to LBaseY + SPEED_TILE_SIZE - 1 do
      for LColumn := LBaseX to LBaseX + SPEED_TILE_SIZE - 1 do
      begin
        ABitmap[LColumn * SPEED_MAP_BITMAP_SIDE + LRow] := LTile[LPixel];
        Inc(LPixel);
      end;
  end;

  // upside down
  for LRow := 0 to SPEED_MAP_BITMAP_SIDE div 2 - 1 do
    for LColumn := 0 to SPEED_MAP_BITMAP_SIDE - 1 do
    begin
      LAbove := LColumn * SPEED_MAP_BITMAP_SIDE + LRow;
      LBelow := LColumn * SPEED_MAP_BITMAP_SIDE + SPEED_MAP_BITMAP_SIDE - 1 - LRow;
      LSwap := ABitmap[LAbove];
      ABitmap[LAbove] := ABitmap[LBelow];
      ABitmap[LBelow] := LSwap;
    end;
end;

end.
