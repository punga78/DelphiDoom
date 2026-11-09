{******************************************************************************}
{                                                                              }
{  DelphiDoom: font library - the settings of a font                            }
{  Copyright (C) 2021-2022 by Jim Valavanis (original DD_FONT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Font.Settings;

interface

uses
  System.SysUtils,
  DelphiDoom.Font.Types;

type
  /// <summary>
  ///   What TFontEngine of DD_FONT kept: the font to draw with (name, size, style, pitch, charset), the size of
  ///   the cell of a character, the size of the grid of characters and the two colors. The colors are those of
  ///   Windows ($00BBGGRR: the red one is the low byte), as the settings file has always held them. It is the
  ///   content of the lump DDFONT of a WAD and of a file of a project of the tool
  /// </summary>
  TFontSettings = record
    Height: Integer;
    Pitch: TFontPitchMode;
    /// <summary>The sum of FONT_STYLE_BOLD, FONT_STYLE_ITALIC, FONT_STYLE_UNDERLINE and FONT_STYLE_STRIKEOUT</summary>
    Style: Integer;
    Charset: Integer;
    FontName: string;
    DrawWidth: Integer;
    DrawHeight: Integer;
    FontSize: Integer;
    FrontColor: Integer;
    BackColor: Integer;
    GridWidth: Integer;
    GridHeight: Integer;
    /// <summary>The settings of a new project: the font Doom, size 8, cells of 16x16, white on black</summary>
    class function Initial: TFontSettings; static;
    function IsBold: Boolean;
    function IsItalic: Boolean;
    function IsUnderline: Boolean;
    function IsStrikeOut: Boolean;
    /// <summary>The same settings with a style bit turned on or off</summary>
    function WithStyle(AStyleBit: Integer; AEnabled: Boolean): TFontSettings;
    /// <summary>The red, green and blue bytes of a color of Windows, and the same color as $00RRGGBB</summary>
    class function RedOf(AColor: Integer): Byte; static;
    class function GreenOf(AColor: Integer): Byte; static;
    class function BlueOf(AColor: Integer): Byte; static;
    class function ToRgb(AColor: Integer): Cardinal; static;
    function Equals(const AOther: TFontSettings): Boolean;
  end;

implementation

{ TFontSettings }

class function TFontSettings.Initial: TFontSettings;
begin
  Result.Height := FONT_DEFAULT_HEIGHT;
  Result.Pitch := fpmDefault;
  Result.Style := 0;
  Result.Charset := FONT_CHARSET_DEFAULT;
  Result.FontName := FONT_DEFAULT_NAME;
  Result.DrawWidth := FONT_DEFAULT_CELL;
  Result.DrawHeight := FONT_DEFAULT_CELL;
  Result.FontSize := FONT_DEFAULT_SIZE;
  Result.FrontColor := FONT_COLOR_WHITE;
  Result.BackColor := FONT_COLOR_BLACK;
  Result.GridWidth := FONT_DEFAULT_GRID;
  Result.GridHeight := FONT_DEFAULT_GRID;
end;

function TFontSettings.IsBold: Boolean;
begin
  Result := (Style and FONT_STYLE_BOLD) <> 0;
end;

function TFontSettings.IsItalic: Boolean;
begin
  Result := (Style and FONT_STYLE_ITALIC) <> 0;
end;

function TFontSettings.IsUnderline: Boolean;
begin
  Result := (Style and FONT_STYLE_UNDERLINE) <> 0;
end;

function TFontSettings.IsStrikeOut: Boolean;
begin
  Result := (Style and FONT_STYLE_STRIKEOUT) <> 0;
end;

function TFontSettings.WithStyle(AStyleBit: Integer; AEnabled: Boolean): TFontSettings;
begin
  Result := Self;
  if AEnabled then
    Result.Style := Result.Style or AStyleBit
  else
    Result.Style := Result.Style and not AStyleBit;
end;

class function TFontSettings.RedOf(AColor: Integer): Byte;
begin
  Result := Byte(AColor);
end;

class function TFontSettings.GreenOf(AColor: Integer): Byte;
begin
  Result := Byte(AColor shr 8);
end;

class function TFontSettings.BlueOf(AColor: Integer): Byte;
begin
  Result := Byte(AColor shr 16);
end;

class function TFontSettings.ToRgb(AColor: Integer): Cardinal;
begin
  Result := (Cardinal(RedOf(AColor)) shl 16) or (Cardinal(GreenOf(AColor)) shl 8) or BlueOf(AColor);
end;

function TFontSettings.Equals(const AOther: TFontSettings): Boolean;
begin
  Result := (Height = AOther.Height) and (Pitch = AOther.Pitch) and (Style = AOther.Style)
    and (Charset = AOther.Charset) and (FontName = AOther.FontName) and (DrawWidth = AOther.DrawWidth)
    and (DrawHeight = AOther.DrawHeight) and (FontSize = AOther.FontSize) and (FrontColor = AOther.FrontColor)
    and (BackColor = AOther.BackColor) and (GridWidth = AOther.GridWidth) and (GridHeight = AOther.GridHeight);
end;

end.
