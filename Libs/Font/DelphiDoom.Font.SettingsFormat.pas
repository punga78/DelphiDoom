{******************************************************************************}
{                                                                              }
{  DelphiDoom: font library - the text of the settings of a font                }
{  Copyright (C) 2021-2022 by Jim Valavanis (original DD_FONT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Font.SettingsFormat;

interface

uses
  System.SysUtils, System.Classes,
  DelphiDoom.Font.Types,
  DelphiDoom.Font.Settings;

type
  /// <summary>
  ///   The text of TFontEngine.SaveToStream: twelve lines Name=Value (Height, Pitch, Style, Charset, FontName,
  ///   DrawWidth, DrawHeight, FontSize, FrontColor, BackColor, GridWidth, GridHeight), each ended by CR LF, in
  ///   the ANSI code page. It is a project file of the tool (.ddp) and the lump DDFONT of a WAD. Reading is
  ///   forgiving as it always was: a missing or wrong value leaves the setting as it is
  /// </summary>
  TFontSettingsFormat = class sealed
  strict private
    const
      NAME_HEIGHT = 'Height';
      NAME_PITCH = 'Pitch';
      NAME_STYLE = 'Style';
      NAME_CHARSET = 'Charset';
      NAME_FONT_NAME = 'FontName';
      NAME_DRAW_WIDTH = 'DrawWidth';
      NAME_DRAW_HEIGHT = 'DrawHeight';
      NAME_FONT_SIZE = 'FontSize';
      NAME_FRONT_COLOR = 'FrontColor';
      NAME_BACK_COLOR = 'BackColor';
      NAME_GRID_WIDTH = 'GridWidth';
      NAME_GRID_HEIGHT = 'GridHeight';
      CHARSET_MASK = $FF;
    class function ColorText(AColor: Integer): string; static;
    class function ReadInteger(const ALines: TStringList; const AName: string; ADefault: Integer): Integer; static;
  public
    class function Save(const ASettings: TFontSettings): TBytes; static;
    /// <summary>The settings that the text gives, starting from ASettings for what the text does not say</summary>
    class function Load(const ABytes: TBytes; const ASettings: TFontSettings): TFontSettings; static;
  end;

implementation

{ TFontSettingsFormat }

class function TFontSettingsFormat.ColorText(AColor: Integer): string;
begin
  // the old engine kept the colors in a LongWord: a color of the system (negative) was written unsigned
  Result := UIntToStr(Cardinal(AColor));
end;

class function TFontSettingsFormat.ReadInteger(const ALines: TStringList; const AName: string;
  ADefault: Integer): Integer;
var
  LValue: string;
begin
  LValue := ALines.Values[AName];
  if LValue = '' then
    Result := ADefault
  else
    Result := StrToIntDef(LValue, ADefault);
end;


class function TFontSettingsFormat.Save(const ASettings: TFontSettings): TBytes;
var
  LLines: TStringList;
  LStream: TBytesStream;
begin
  LLines := TStringList.Create;
  LStream := TBytesStream.Create;
  try
    LLines.Add(NAME_HEIGHT + '=' + IntToStr(ASettings.Height));
    LLines.Add(NAME_PITCH + '=' + IntToStr(Ord(ASettings.Pitch)));
    LLines.Add(NAME_STYLE + '=' + IntToStr(ASettings.Style and (FONT_STYLE_BOLD or FONT_STYLE_ITALIC or
      FONT_STYLE_UNDERLINE or FONT_STYLE_STRIKEOUT)));
    LLines.Add(NAME_CHARSET + '=' + IntToStr(ASettings.Charset));
    LLines.Add(NAME_FONT_NAME + '=' + ASettings.FontName);
    LLines.Add(NAME_DRAW_WIDTH + '=' + IntToStr(ASettings.DrawWidth));
    LLines.Add(NAME_DRAW_HEIGHT + '=' + IntToStr(ASettings.DrawHeight));
    LLines.Add(NAME_FONT_SIZE + '=' + IntToStr(ASettings.FontSize));
    LLines.Add(NAME_FRONT_COLOR + '=' + ColorText(ASettings.FrontColor));
    LLines.Add(NAME_BACK_COLOR + '=' + ColorText(ASettings.BackColor));
    LLines.Add(NAME_GRID_WIDTH + '=' + IntToStr(ASettings.GridWidth));
    LLines.Add(NAME_GRID_HEIGHT + '=' + IntToStr(ASettings.GridHeight));
    LLines.SaveToStream(LStream, TEncoding.ANSI);
    Result := Copy(LStream.Bytes, 0, LStream.Size);
  finally
    LStream.Free;
    LLines.Free;
  end;
end;

class function TFontSettingsFormat.Load(const ABytes: TBytes; const ASettings: TFontSettings): TFontSettings;
var
  LLines: TStringList;
  LStream: TBytesStream;
  LValue: string;
  LPitch: Integer;
begin
  Result := ASettings;
  LLines := TStringList.Create;
  LStream := TBytesStream.Create(ABytes);
  try
    LLines.LoadFromStream(LStream);
    Result.Height := ReadInteger(LLines, NAME_HEIGHT, Result.Height);
    LPitch := ReadInteger(LLines, NAME_PITCH, Ord(Result.Pitch));
    if (LPitch >= Ord(Low(TFontPitchMode))) and (LPitch <= Ord(High(TFontPitchMode))) then
      Result.Pitch := TFontPitchMode(LPitch);
    Result.Style := ReadInteger(LLines, NAME_STYLE, Result.Style) and (FONT_STYLE_BOLD or FONT_STYLE_ITALIC or
      FONT_STYLE_UNDERLINE or FONT_STYLE_STRIKEOUT);
    Result.Charset := ReadInteger(LLines, NAME_CHARSET, Result.Charset) and CHARSET_MASK;
    LValue := LLines.Values[NAME_FONT_NAME];
    if LValue <> '' then
      Result.FontName := LValue;
    Result.DrawWidth := ReadInteger(LLines, NAME_DRAW_WIDTH, Result.DrawWidth);
    Result.DrawHeight := ReadInteger(LLines, NAME_DRAW_HEIGHT, Result.DrawHeight);
    Result.FontSize := ReadInteger(LLines, NAME_FONT_SIZE, Result.FontSize);
    Result.FrontColor := ReadInteger(LLines, NAME_FRONT_COLOR, Result.FrontColor);
    Result.BackColor := ReadInteger(LLines, NAME_BACK_COLOR, Result.BackColor);
    Result.GridWidth := ReadInteger(LLines, NAME_GRID_WIDTH, Result.GridWidth);
    Result.GridHeight := ReadInteger(LLines, NAME_GRID_HEIGHT, Result.GridHeight);
  finally
    LStream.Free;
    LLines.Free;
  end;
end;

end.
