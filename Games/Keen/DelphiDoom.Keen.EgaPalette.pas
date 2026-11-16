{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the 16 colors of the EGA                          }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.EgaPalette;

interface

uses
  System.SysUtils;

const
  /// <summary>Colors the game uses (an EGA picture has 4 bits for each pixel)</summary>
  KEEN_EGA_COLORS = 16;

type
  /// <summary>
  ///   The colors of the EGA screen of the game (mode 0Dh, 320x200, 16 colors): black, blue, green, cyan, red,
  ///   magenta, brown, light gray, dark gray, light blue, light green, light cyan, light red, light magenta,
  ///   yellow, white. The game loads the 16 palette registers with 0..7 and $18..$1F (id_vw.c) and
  ///   the colors that come out on a VGA and on DOSBox are these, the ones of the EGA monitor
  /// </summary>
  TKeenEgaPalette = class
  public
    /// <summary>The color AIndex (0..15) as $00RRGGBB</summary>
    class function Color(AIndex: Integer): Cardinal; static;
    /// <summary>
    ///   The palette as the library of the palettes wants it: 256 colors of R, G, B (8 bits each); the 16
    ///   colors of the EGA come first and the rest is black
    /// </summary>
    class function GamePalette: TBytes; static;
  end;

implementation

uses
  DelphiDoom.Keen.Types;

const
  EGA_COLORS: array[0..KEEN_EGA_COLORS - 1] of Cardinal = (
    $000000, $0000AA, $00AA00, $00AAAA, $AA0000, $AA00AA, $AA5500, $AAAAAA,
    $555555, $5555FF, $55FF55, $55FFFF, $FF5555, $FF55FF, $FFFF55, $FFFFFF
  );

{ TKeenEgaPalette }

class function TKeenEgaPalette.Color(AIndex: Integer): Cardinal;
begin
  if (AIndex < 0) or (AIndex >= KEEN_EGA_COLORS) then
    raise EKeenException.CreateFmt(SKeenColorInvalid, [AIndex]);
  Result := EGA_COLORS[AIndex];
end;

class function TKeenEgaPalette.GamePalette: TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, 256 * 3);
  FillChar(Result[0], Length(Result), 0);
  for LIndex := 0 to KEEN_EGA_COLORS - 1 do
  begin
    Result[LIndex * 3] := Byte(EGA_COLORS[LIndex] shr 16);
    Result[LIndex * 3 + 1] := Byte(EGA_COLORS[LIndex] shr 8);
    Result[LIndex * 3 + 2] := Byte(EGA_COLORS[LIndex]);
  end;
end;

end.
