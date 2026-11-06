{******************************************************************************}
{                                                                              }
{  DelphiDoom: palette library - fix of the reserved colors of a strip          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Palette.BufferFixer;

interface

uses
  System.SysUtils, DelphiDoom.Palette.Types, DelphiDoom.Palette.Intf;

type
  /// <summary>
  ///   V_FixBufferPalette: in AFrom..ATo every color under 16 or over 239 (the ones the palette
  ///   of the screen keeps for the system) takes the color of the previous pixel. The first pixel
  ///   of the buffer is never changed
  /// </summary>
  TPaletteBufferFixer = class(TInterfacedObject, IPaletteBufferFixer)
  public
    procedure Fix(var ABuffer: TBytes; AFrom, ATo: Integer);
  end;

implementation

{ TPaletteBufferFixer }

procedure TPaletteBufferFixer.Fix(var ABuffer: TBytes; AFrom, ATo: Integer);
var
  LIndex: Integer;
  LStart: Integer;
begin
  LStart := AFrom;
  if LStart = 0 then
    LStart := 1;
  if (LStart < 1) or (ATo >= Length(ABuffer)) then
    raise EPaletteException.CreateFmt(SPaletteRangeInvalid, [AFrom, ATo]);
  for LIndex := LStart to ATo do
    if (ABuffer[LIndex] < 16) or (ABuffer[LIndex] > 239) then
      ABuffer[LIndex] := ABuffer[LIndex - 1];
end;

end.
