{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - decoding of an image record                       }
{                                                                              }
{  Port of war1 (acoto87/war1), wres_loadImageResource of war_resources.c,     }
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-      }
{  war1.txt). This is an altered version, not the original.                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Graphics.ImageDecoder;

interface

uses
  System.SysUtils, DelphiDoom.War.Graphics.Types;

type
  /// <summary>
  ///   An image record is width and height (16 bit each) and Width * Height palette indices, row by row. The
  ///   original read past the record when the pixels were not all there; here it is EWarException
  /// </summary>
  TWarImageDecoder = class
  public
    /// <param name="AIndex">The index of the record, for the messages</param>
    /// <param name="ARaw">The bytes of the record</param>
    /// <param name="ALookup">The colors of the palette (TWarColorLookupBuilder.Build)</param>
    class function Decode(AIndex: Integer; const ARaw: TBytes; const ALookup: TWarColorLookup): TWarImage; static;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.LittleEndian, DelphiDoom.War.Graphics.ColorLookup;

{ TWarImageDecoder }

class function TWarImageDecoder.Decode(AIndex: Integer; const ARaw: TBytes; const ALookup: TWarColorLookup): TWarImage;
var
  LNeeded: Int64;
  LCount: Integer;
  LPixel: Integer;
begin
  Result.Width := TWarLittleEndian.ReadWord(ARaw, 0);
  Result.Height := TWarLittleEndian.ReadWord(ARaw, 2);
  LNeeded := SizeOf(TWarImageHeader) + Int64(Result.Width) * Result.Height;
  if LNeeded > Length(ARaw) then
    raise EWarException.CreateFmt(SWarGraphicsTooShort, ['image', AIndex, Length(ARaw), LNeeded]);
  LCount := Integer(Result.Width) * Result.Height;
  SetLength(Result.Pixels, LCount * WAR_PIXEL_SIZE);
  for LPixel := 0 to LCount - 1 do
    TWarColorLookupBuilder.PutPixel(ALookup, ARaw[SizeOf(TWarImageHeader) + LPixel], Result.Pixels, LPixel * WAR_PIXEL_SIZE);
end;

end.
