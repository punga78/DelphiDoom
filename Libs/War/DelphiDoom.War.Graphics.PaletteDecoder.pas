{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - decoding of a palette record                      }
{                                                                              }
{  Port of war1 (acoto87/war1), wres_loadPaletteResource of war_resources.c,   }
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-      }
{  war1.txt). This is an altered version, not the original.                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Graphics.PaletteDecoder;

{$Q-                                                                           }
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.War.Graphics.Types;

type
  /// <summary>
  ///   The file has 6 bit components: the original multiplies each by 4 into a byte (the product wraps at 8
  ///   bits, {$Q-}), pads a short record with zeros and corrects a few colors of the palettes 255 and 217 by hand
  /// </summary>
  TWarPaletteDecoder = class
  strict private
    class procedure SetColor(var APalette: TBytes; AColor, ARed, AGreen, ABlue: Byte); static;
  public
    /// <param name="AIndex">The index of the record: 255 and 217 get the corrections of the original</param>
    /// <param name="ARaw">The bytes of the record; fewer than 768 are padded with zeros, more are ignored</param>
    /// <returns>768 bytes, R G B of the 256 colors</returns>
    class function Decode(AIndex: Integer; const ARaw: TBytes): TBytes; static;
  end;

implementation

{ TWarPaletteDecoder }

class procedure TWarPaletteDecoder.SetColor(var APalette: TBytes; AColor, ARed, AGreen, ABlue: Byte);
begin
  APalette[AColor * 3] := ARed;
  APalette[AColor * 3 + 1] := AGreen;
  APalette[AColor * 3 + 2] := ABlue;
end;

class function TWarPaletteDecoder.Decode(AIndex: Integer; const ARaw: TBytes): TBytes;
var
  LByte: Integer;
begin
  SetLength(Result, WAR_PALETTE_LENGTH);
  for LByte := 0 to WAR_PALETTE_LENGTH - 1 do
    if LByte < Length(ARaw) then
      Result[LByte] := Byte(ARaw[LByte] * 4);

  // this is a hack in palette 255 of the original: the UI graphics of the unit info are wrong with the
  // palette as it came from the file
  if AIndex = WAR_PALETTE_UNIT_INFO then
  begin
    SetColor(Result, 0, 0, 0, 0);
    SetColor(Result, 190, 176, 184, 208);
    SetColor(Result, 191, 208, 208, 236);
    SetColor(Result, 214, 204, 212, 180);
    SetColor(Result, 208, 32, 32, 44);
    SetColor(Result, 211, 80, 104, 104);
    SetColor(Result, 184, 12, 20, 12);
    SetColor(Result, 185, 28, 32, 32);
    SetColor(Result, 186, 56, 64, 68);
    SetColor(Result, 189, 144, 156, 176);
  end
  // palette 217 has an ugly pink color that showed in the unit portraits
  else if AIndex = WAR_PALETTE_PORTRAITS then
  begin
    SetColor(Result, 96, 108, 72, 40);
    SetColor(Result, 150, 46, 54, 54);
    SetColor(Result, 158, 40, 64, 112);
    SetColor(Result, 215, 32, 20, 24);
  end;
end;

end.
