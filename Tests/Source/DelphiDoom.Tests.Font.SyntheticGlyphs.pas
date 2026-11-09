{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the font library - the characters that do not need GDI  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  This unit is compiled by the tests and by the harness that makes the golden  }
{  files from the old DD_FONT (outside of the repository): it must not use      }
{  anything of the libraries                                                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Font.SyntheticGlyphs;

{$OVERFLOWCHECKS OFF}
{$RANGECHECKS OFF}

interface

type
  /// <summary>
  ///   The "font" of the tests: a function of the code of the character, the position of the pixel, the size of
  ///   the cell, the size of the font and its style that says how much of the foreground color a pixel has, for
  ///   each channel (the channels differ a little, as with ClearType). The right side of the cell is empty (the
  ///   width of the character depends on the code), the space is empty, the style italic never gives full
  ///   white and the underline never above half: so the cutting and the stretching of the old tool are used
  /// </summary>
  TSyntheticGlyphs = class sealed
  public
    /// <summary>How much of the foreground color the channel of a pixel has, from 0 to 255</summary>
    class function Coverage(ACode, AX, AY, AChannel, ACellWidth, ACellHeight, AFontSize, AStyle: Integer): Integer; static;
    /// <summary>One channel of the pixel: the background plus the coverage of the difference with the foreground</summary>
    class function Mix(ABackground, AForeground, ACoverage: Integer): Integer; static;
    /// <summary>The width of the character, as the pixels that are not empty see it</summary>
    class function GlyphWidth(ACode, ACellWidth, AFontSize: Integer): Integer; static;
  end;

implementation

function Hash(ACode, AX, AY, AChannel: Integer): Cardinal;
begin
  Result := Cardinal(ACode) * 73856093;
  Result := Result xor (Cardinal(AX) * 19349663);
  Result := Result xor (Cardinal(AY) * 83492791);
  Result := Result xor (Cardinal(AChannel) * 2654435761);
  Result := Result xor (Result shr 15);
  Result := Result * 2246822519;
  Result := Result xor (Result shr 13);
end;

class function TSyntheticGlyphs.GlyphWidth(ACode, ACellWidth, AFontSize: Integer): Integer;
begin
  if (ACode = 32) or (ACellWidth < 2) then
    Exit(0);
  Result := 2 + (ACode * 5 + AFontSize * 3) mod (ACellWidth - 1);
  if Result > ACellWidth then
    Result := ACellWidth;
end;

class function TSyntheticGlyphs.Coverage(ACode, AX, AY, AChannel, ACellWidth, ACellHeight, AFontSize,
  AStyle: Integer): Integer;
var
  LHash: Cardinal;
  LCap: Integer;
begin
  Result := 0;
  if (AX < 0) or (AY < 0) or (AX >= GlyphWidth(ACode, ACellWidth, AFontSize)) or (AY >= ACellHeight) then
    Exit;
  // the first column is empty for some characters: the left side is not cut
  if (AX = 0) and (ACode mod 4 = 1) then
    Exit;
  LHash := Hash(ACode, AX, AY, 0);
  if (AX + AY + ACode) mod 3 = 0 then
    Result := 255 - Integer(LHash mod 40)
  else
    Result := Integer(LHash mod 256);
  // the channels differ a little at the odd columns, the even ones are gray
  if AX mod 2 = 1 then
    Result := Result + Integer(Hash(ACode, AX, AY, AChannel + 1) mod 25) - 12;
  LCap := 255;
  if AStyle and 2 <> 0 then
    LCap := 200;
  if AStyle and 4 <> 0 then
    LCap := 120;
  if Result > LCap then
    Result := LCap;
  if Result < 0 then
    Result := 0;
end;

class function TSyntheticGlyphs.Mix(ABackground, AForeground, ACoverage: Integer): Integer;
begin
  Result := ABackground + ((AForeground - ABackground) * ACoverage) div 255;
end;

end.
