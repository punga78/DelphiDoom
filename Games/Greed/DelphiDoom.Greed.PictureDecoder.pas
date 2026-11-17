{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - a picture (pic_t)                                }
{  Port of xGreed (Jim Valavanis): d_video.pas                                  }
{                                                                              }
{  xGreed (Jim Valavanis) and Raven 3D engine (c) 1996 Softdisk Publishing:    }
{  the user declares this port GPL v2 or later; the right on the parts         }
{  derived from the Softdisk code is not verified (docs\LICENZE.md)            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.PictureDecoder;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf;

type
  /// <summary>
  ///   The lump of a picture: width, height, origin x and y (4 words) and the pixels, a row after the other
  ///   (VI_DrawPicSolid copies rows of width bytes; VI_DrawMaskedPic skips the color 0 and puts the point
  ///   (origin x, origin y) of the picture on the position)
  /// </summary>
  TGreedPictureDecoder = class(TInterfacedObject, IGreedImageDecoder)
  public
    function Decode(const ALump: TBytes): TGreedImage;
  end;

implementation

uses
  DelphiDoom.Greed.LittleEndian;

{ TGreedPictureDecoder }

function TGreedPictureDecoder.Decode(const ALump: TBytes): TGreedImage;
var
  LWidth: Integer;
  LHeight: Integer;
begin
  if Length(ALump) < GREED_PICTURE_HEADER_BYTES then
    raise EGreedDataException.CreateFmt(SGreedImageTooShort, ['picture', Length(ALump), GREED_PICTURE_HEADER_BYTES]);
  LWidth := TGreedLittleEndian.ReadSmallInt(ALump, 0);
  LHeight := TGreedLittleEndian.ReadSmallInt(ALump, 2);
  if (LWidth <= 0) or (LHeight <= 0) then
    raise EGreedDataException.CreateFmt(SGreedImageSize, [LWidth, LHeight, 'picture']);
  if Length(ALump) < GREED_PICTURE_HEADER_BYTES + LWidth * LHeight then
    raise EGreedDataException.CreateFmt(SGreedImageTooShort,
      ['picture', Length(ALump), GREED_PICTURE_HEADER_BYTES + LWidth * LHeight]);
  Result.Width := LWidth;
  Result.Height := LHeight;
  Result.OriginX := TGreedLittleEndian.ReadSmallInt(ALump, 4);
  Result.OriginY := TGreedLittleEndian.ReadSmallInt(ALump, 6);
  Result.Pixels := Copy(ALump, GREED_PICTURE_HEADER_BYTES, LWidth * LHeight);
end;

end.
