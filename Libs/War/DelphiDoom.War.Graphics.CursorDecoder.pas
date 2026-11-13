{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - decoding of a cursor record                       }
{                                                                              }
{  Port of war1 (acoto87/war1), wres_loadCursor of war_resources.c,            }
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-      }
{  war1.txt). This is an altered version, not the original.                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Graphics.CursorDecoder;

interface

uses
  System.SysUtils, DelphiDoom.War.Graphics.Types;

type
  /// <summary>
  ///   A cursor record is the hot spot, the width and the height (16 bit each) and Width * Height palette
  ///   indices. As for an image, a record without all its pixels is EWarException (the original read past it)
  /// </summary>
  TWarCursorDecoder = class
  public
    class function Decode(AIndex: Integer; const ARaw: TBytes; const ALookup: TWarColorLookup): TWarCursor; static;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.LittleEndian, DelphiDoom.War.Graphics.ColorLookup;

{ TWarCursorDecoder }

class function TWarCursorDecoder.Decode(AIndex: Integer; const ARaw: TBytes; const ALookup: TWarColorLookup): TWarCursor;
var
  LNeeded: Int64;
  LCount: Integer;
  LPixel: Integer;
begin
  Result.HotX := TWarLittleEndian.ReadWord(ARaw, 0);
  Result.HotY := TWarLittleEndian.ReadWord(ARaw, 2);
  Result.Width := TWarLittleEndian.ReadWord(ARaw, 4);
  Result.Height := TWarLittleEndian.ReadWord(ARaw, 6);
  LNeeded := SizeOf(TWarCursorHeader) + Int64(Result.Width) * Result.Height;
  if LNeeded > Length(ARaw) then
    raise EWarException.CreateFmt(SWarGraphicsTooShort, ['cursor', AIndex, Length(ARaw), LNeeded]);
  LCount := Integer(Result.Width) * Result.Height;
  SetLength(Result.Pixels, LCount * WAR_PIXEL_SIZE);
  for LPixel := 0 to LCount - 1 do
    TWarColorLookupBuilder.PutPixel(ALookup, ARaw[SizeOf(TWarCursorHeader) + LPixel], Result.Pixels, LPixel * WAR_PIXEL_SIZE);
end;

end.
