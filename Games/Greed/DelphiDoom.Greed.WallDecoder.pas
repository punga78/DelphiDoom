{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - a wall texture                                   }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): LoadTextures of utils.pas   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.WallDecoder;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf;

type
  /// <summary>
  ///   A wall is 64 columns of height pixels each. The first byte of the lump is the height divided by 4;
  ///   the columns start after 65 words (LoadTextures: base = wall + 65 * 2, size = wall[0] * 4, column x at
  ///   base[size * x]) and each is stored from the top down. The image has the rows from the top
  /// </summary>
  TGreedWallDecoder = class(TInterfacedObject, IGreedImageDecoder)
  public
    function Decode(const ALump: TBytes): TGreedImage;
  end;

implementation

{ TGreedWallDecoder }

function TGreedWallDecoder.Decode(const ALump: TBytes): TGreedImage;
var
  LHeight: Integer;
  LNeeded: Integer;
  LX: Integer;
  LY: Integer;
begin
  if Length(ALump) < 1 then
    raise EGreedDataException.CreateFmt(SGreedImageTooShort, ['wall', 0, 1]);
  LHeight := ALump[0] * 4;
  if LHeight = 0 then
    raise EGreedDataException.CreateFmt(SGreedImageSize, [GREED_WALL_WIDTH, LHeight, 'wall']);
  LNeeded := GREED_WALL_HEADER_BYTES + GREED_WALL_WIDTH * LHeight;
  if Length(ALump) < LNeeded then
    raise EGreedDataException.CreateFmt(SGreedImageTooShort, ['wall', Length(ALump), LNeeded]);
  Result.Width := GREED_WALL_WIDTH;
  Result.Height := LHeight;
  Result.OriginX := 0;
  Result.OriginY := 0;
  SetLength(Result.Pixels, GREED_WALL_WIDTH * LHeight);
  for LY := 0 to LHeight - 1 do
    for LX := 0 to GREED_WALL_WIDTH - 1 do
      Result.Pixels[LY * GREED_WALL_WIDTH + LX] := ALump[GREED_WALL_HEADER_BYTES + LHeight * LX + LY];
end;

end.
