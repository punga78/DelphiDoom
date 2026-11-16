{******************************************************************************}
{                                                                              }
{  DelphiDoom: palette library - the palettes of the games                      }
{  Copyright (C) 2021-2022 by Jim Valavanis (original DD_FONT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Palette.GamePalettes;

interface

uses
  System.SysUtils;

type
  /// <summary>The palettes that the tools offer: the games of the source ports and the two that DD_FONT knew</summary>
  TGamePalette = (gpDoom, gpHeretic, gpHexen, gpStrife, gpRadix, gpGLSpeed);

  /// <summary>
  ///   The palettes of the games as data (DD_FONT: ff_palettes), the range of colors that a tool may use and
  ///   the palette that a file gives. The functions do not keep any state
  /// </summary>
  TGamePalettes = class sealed
  public
    /// <summary>The name of a palette in a settings file: DOOM, HERETIC, HEXEN, STRIFE, RADIX or GLSPEED</summary>
    class function Name(APalette: TGamePalette): string; static;
    /// <summary>The palette of a name, written in upper case as Name gives it; false for any other text</summary>
    class function TryFromName(const AName: string; out APalette: TGamePalette): Boolean; static;
    /// <summary>768 bytes: R, G, B of the 256 colors</summary>
    class function Colors(APalette: TGamePalette): TBytes; static;
    /// <summary>The first color that a tool may use (the color 0 is the transparent one)</summary>
    class function FirstUsableIndex(APalette: TGamePalette): Integer; static;
    /// <summary>The last color that a tool may use: the engine of Radix keeps the last colors for itself, GLSpeed the first and the last</summary>
    class function LastUsableIndex(APalette: TGamePalette): Integer; static;
    /// <summary>The first and the last color of a palette that is not one of the games (a file, or the gray ramp)</summary>
    class function FirstUsableIndexOfOther: Integer; static;
    class function LastUsableIndexOfOther: Integer; static;
    /// <summary>The gray ramp: the color i is (i, i, i). What a missing or unreadable palette file gives</summary>
    class function GrayscaleColors: TBytes; static;
    /// <summary>
    ///   The palette of a file: a multiple of 768 bytes is R, G, B bytes (the first 768 count); a multiple of
    ///   1024 bytes is 256 pixels of 32 bits, 00RRGGBB; anything else is not a palette and gives the gray ramp.
    ///   As DD_FONT read it (a file of a size that is a multiple of both is read as 768 bytes)
    /// </summary>
    class function ParseExternal(const ABytes: TBytes): TBytes; static;
    /// <summary>The 256 colors as $00RRGGBB, for the nearest color search of IColorMatcher</summary>
    class function ToColors(const ARgbBytes: TBytes): TArray<Cardinal>; static;
  end;

implementation

uses
  DelphiDoom.Palette.Types, DelphiDoom.Palette.GamePaletteData;

const
  GAME_PALETTE_NAMES: array[TGamePalette] of string = ('DOOM', 'HERETIC', 'HEXEN', 'STRIFE', 'RADIX', 'GLSPEED');
  FIRST_USABLE: array[TGamePalette] of Integer = (1, 1, 1, 1, 1, 16);
  LAST_USABLE: array[TGamePalette] of Integer = (255, 255, 255, 255, 251, 239);
  OTHER_FIRST_USABLE = 1;
  OTHER_LAST_USABLE = 255;
  PIXEL_FILE_SIZE = PALETTE_COLOR_COUNT * SizeOf(Cardinal);

{ TGamePalettes }

class function TGamePalettes.Name(APalette: TGamePalette): string;
begin
  Result := GAME_PALETTE_NAMES[APalette];
end;

class function TGamePalettes.TryFromName(const AName: string; out APalette: TGamePalette): Boolean;
var
  LPalette: TGamePalette;
begin
  for LPalette := Low(TGamePalette) to High(TGamePalette) do
    if AName = GAME_PALETTE_NAMES[LPalette] then
    begin
      APalette := LPalette;
      Exit(True);
    end;
  APalette := gpDoom;
  Result := False;
end;

class function TGamePalettes.Colors(APalette: TGamePalette): TBytes;
begin
  SetLength(Result, PALETTE_BYTE_COUNT);
  case APalette of
    gpDoom:
      Move(GAME_PALETTE_DOOM, Result[0], PALETTE_BYTE_COUNT);
    gpHeretic:
      Move(GAME_PALETTE_HERETIC, Result[0], PALETTE_BYTE_COUNT);
    gpHexen:
      Move(GAME_PALETTE_HEXEN, Result[0], PALETTE_BYTE_COUNT);
    gpStrife:
      Move(GAME_PALETTE_STRIFE, Result[0], PALETTE_BYTE_COUNT);
    gpRadix:
      Move(GAME_PALETTE_RADIX, Result[0], PALETTE_BYTE_COUNT);
    gpGLSpeed:
      Move(GAME_PALETTE_GLSPEED, Result[0], PALETTE_BYTE_COUNT);
  end;
end;

class function TGamePalettes.FirstUsableIndex(APalette: TGamePalette): Integer;
begin
  Result := FIRST_USABLE[APalette];
end;

class function TGamePalettes.LastUsableIndex(APalette: TGamePalette): Integer;
begin
  Result := LAST_USABLE[APalette];
end;

class function TGamePalettes.FirstUsableIndexOfOther: Integer;
begin
  Result := OTHER_FIRST_USABLE;
end;

class function TGamePalettes.LastUsableIndexOfOther: Integer;
begin
  Result := OTHER_LAST_USABLE;
end;

class function TGamePalettes.GrayscaleColors: TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, PALETTE_BYTE_COUNT);
  for LIndex := 0 to PALETTE_COLOR_COUNT - 1 do
  begin
    Result[3 * LIndex] := Byte(LIndex);
    Result[3 * LIndex + 1] := Byte(LIndex);
    Result[3 * LIndex + 2] := Byte(LIndex);
  end;
end;

class function TGamePalettes.ParseExternal(const ABytes: TBytes): TBytes;
var
  LIndex: Integer;
  LPixel: Cardinal;
begin
  Result := GrayscaleColors;
  if Length(ABytes) < PALETTE_BYTE_COUNT then
    Exit;
  if Length(ABytes) mod PALETTE_BYTE_COUNT = 0 then
    Move(ABytes[0], Result[0], PALETTE_BYTE_COUNT)
  else if Length(ABytes) mod PIXEL_FILE_SIZE = 0 then
    for LIndex := 0 to PALETTE_COLOR_COUNT - 1 do
    begin
      LPixel := ABytes[4 * LIndex] or (Cardinal(ABytes[4 * LIndex + 1]) shl 8)
        or (Cardinal(ABytes[4 * LIndex + 2]) shl 16) or (Cardinal(ABytes[4 * LIndex + 3]) shl 24);
      Result[3 * LIndex] := Byte(LPixel shr 16);
      Result[3 * LIndex + 1] := Byte(LPixel shr 8);
      Result[3 * LIndex + 2] := Byte(LPixel);
    end;
end;

class function TGamePalettes.ToColors(const ARgbBytes: TBytes): TArray<Cardinal>;
var
  LIndex: Integer;
begin
  if Length(ARgbBytes) < PALETTE_BYTE_COUNT then
    raise EArgumentException.Create('ARgbBytes');
  SetLength(Result, PALETTE_COLOR_COUNT);
  for LIndex := 0 to PALETTE_COLOR_COUNT - 1 do
    Result[LIndex] := (Cardinal(ARgbBytes[3 * LIndex]) shl 16) or (Cardinal(ARgbBytes[3 * LIndex + 1]) shl 8)
      or ARgbBytes[3 * LIndex + 2];
end;

end.
