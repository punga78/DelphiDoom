{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - writes the options of the fonts of the     }
{  system (fonts.cfg), the file TXcomFontSettingsReader reads (issue 184)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.FontSettingsWriter;

interface

uses
  System.SysUtils, DelphiDoom.XcomSurface.Glyph.Types;

type
  /// <summary>
  ///   The text of fonts.cfg for a list of entries: every key that differs from what the reader assumes is
  ///   written, so reading the text gives the same entries. The names and the files are in single quotes
  /// </summary>
  TXcomFontSettingsWriter = class sealed
  strict private
    class function Quoted(const AText: string): string; static;
    class function YesNo(AValue: Boolean): string; static;
  public
    class function Write(const ASettings: TArray<TXcomFontOverlaySettings>): string; static;
  end;

implementation

class function TXcomFontSettingsWriter.Quoted(const AText: string): string;
begin
  Result := '''' + AText.Replace('''', '''''') + '''';
end;

class function TXcomFontSettingsWriter.YesNo(AValue: Boolean): string;
begin
  if AValue then
    Result := 'true'
  else
    Result := 'false';
end;

class function TXcomFontSettingsWriter.Write(const ASettings: TArray<TXcomFontOverlaySettings>): string;
var
  LBuilder: TStringBuilder;
  LSettings: TXcomFontOverlaySettings;
begin
  if Length(ASettings) = 0 then
    Exit('fonts: []'#10);
  LBuilder := TStringBuilder.Create;
  try
    LBuilder.Append('fonts:'#10);
    for LSettings in ASettings do
    begin
      LBuilder.Append('  - id: ').Append(LSettings.FontId).Append(#10);
      if LSettings.Face.Name <> '' then
        LBuilder.Append('    name: ').Append(Quoted(LSettings.Face.Name)).Append(#10);
      if LSettings.Face.FileName <> '' then
        LBuilder.Append('    file: ').Append(Quoted(LSettings.Face.FileName)).Append(#10);
      if LSettings.Face.FaceIndex <> 0 then
        LBuilder.Append('    index: ').Append(LSettings.Face.FaceIndex).Append(#10);
      LBuilder.Append('    size: ').Append(LSettings.Face.Size).Append(#10);
      LBuilder.Append('    bold: ').Append(YesNo(LSettings.Face.Bold)).Append(#10);
      LBuilder.Append('    antialias: ').Append(YesNo(LSettings.Face.Antialias)).Append(#10);
      if LSettings.Outline <> goAuto then
        LBuilder.Append('    outline: ').Append(YesNo(LSettings.Outline = goOn)).Append(#10);
      if LSettings.HasSpacing then
        LBuilder.Append('    spacing: ').Append(LSettings.Spacing).Append(#10);
      if LSettings.Tolerance <> XCOM_FONT_AUTO_TOLERANCE then
        LBuilder.Append('    tolerance: ').Append(LSettings.Tolerance).Append(#10);
      LBuilder.Append('    shrink: ').Append(YesNo(LSettings.Shrink)).Append(#10);
      if LSettings.OffsetY <> 0 then
        LBuilder.Append('    offsetY: ').Append(LSettings.OffsetY).Append(#10);
    end;
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

end.
