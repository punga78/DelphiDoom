{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - a sprite (scalepic_t)                            }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): DrawSprite, ScaleMaskedPost }
{  of r_spans.pas                                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.SpriteDecoder;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf;

type
  /// <summary>
  ///   A sprite has the left offset and the width (2 words), then one word for each column with the place of
  ///   its post in the lump (0: nothing in that column). A post has the top and the bottom height (2 bytes) and,
  ///   from the top down, the top - bottom pixels of the color index; the color 0 is not drawn. The heights are
  ///   counted from the base of the sprite up. The image is as high as the highest top, with the base on its last
  ///   row; OriginX is the left offset and OriginY the height of the image. With a scale of 1:1 it is what
  ///   DrawSprite puts on the screen
  /// </summary>
  TGreedSpriteDecoder = class(TInterfacedObject, IGreedImageDecoder)
  public
    function Decode(const ALump: TBytes): TGreedImage;
  end;

implementation

uses
  DelphiDoom.Greed.LittleEndian;

{ TGreedSpriteDecoder }

function TGreedSpriteDecoder.Decode(const ALump: TBytes): TGreedImage;
var
  LWidth: Integer;
  LColumn: Integer;
  LOffset: Integer;
  LTop: Integer;
  LBottom: Integer;
  LHeight: Integer;
  LRow: Integer;
  LIndex: Integer;
begin
  if Length(ALump) < GREED_SPRITE_HEADER_BYTES then
    raise EGreedDataException.CreateFmt(SGreedImageTooShort, ['sprite', Length(ALump), GREED_SPRITE_HEADER_BYTES]);
  LWidth := TGreedLittleEndian.ReadSmallInt(ALump, 2);
  if LWidth <= 0 then
    raise EGreedDataException.CreateFmt(SGreedImageSize, [LWidth, 0, 'sprite']);
  if Length(ALump) < GREED_SPRITE_HEADER_BYTES + 2 * LWidth then
    raise EGreedDataException.CreateFmt(SGreedImageTooShort,
      ['sprite', Length(ALump), GREED_SPRITE_HEADER_BYTES + 2 * LWidth]);
  // first pass: the columns must be inside the lump, and the highest top says the height
  LHeight := 0;
  for LColumn := 0 to LWidth - 1 do
  begin
    LOffset := TGreedLittleEndian.ReadSmallInt(ALump, GREED_SPRITE_HEADER_BYTES + 2 * LColumn);
    if LOffset = 0 then
      Continue;
    if (LOffset < 0) or (LOffset + 2 > Length(ALump)) then
      raise EGreedDataException.CreateFmt(SGreedImageColumn, [LColumn, LOffset, 0, 0, Length(ALump)]);
    LTop := ALump[LOffset];
    LBottom := ALump[LOffset + 1];
    if (LTop < LBottom) or (LOffset + 2 + (LTop - LBottom) > Length(ALump)) then
      raise EGreedDataException.CreateFmt(SGreedImageColumn, [LColumn, LOffset, LTop, LBottom, Length(ALump)]);
    if LTop > LHeight then
      LHeight := LTop;
  end;
  Result.Width := LWidth;
  Result.Height := LHeight;
  Result.OriginX := TGreedLittleEndian.ReadSmallInt(ALump, 0);
  Result.OriginY := LHeight;
  SetLength(Result.Pixels, LWidth * LHeight);
  // SetLength does not clear a byte array: what no post covers is color 0, transparent
  if LHeight > 0 then
    FillChar(Result.Pixels[0], Length(Result.Pixels), 0);
  for LColumn := 0 to LWidth - 1 do
  begin
    LOffset := TGreedLittleEndian.ReadSmallInt(ALump, GREED_SPRITE_HEADER_BYTES + 2 * LColumn);
    if LOffset = 0 then
      Continue;
    LTop := ALump[LOffset];
    LBottom := ALump[LOffset + 1];
    // the pixel k of the post is at the height top - 1 - k, that is the row (image height - top + k)
    for LIndex := 0 to LTop - LBottom - 1 do
    begin
      LRow := LHeight - LTop + LIndex;
      Result.Pixels[LRow * LWidth + LColumn] := ALump[LOffset + 2 + LIndex];
    end;
  end;
end;

end.
