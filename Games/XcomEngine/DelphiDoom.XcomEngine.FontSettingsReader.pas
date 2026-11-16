{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - reads the options of the fonts of the      }
{  system that replace the pictures of the characters (fonts.cfg)               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.FontSettingsReader;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Yaml.Intf, DelphiDoom.XcomEngine.Intf,
  DelphiDoom.XcomSurface.Glyph.Types;

type
  /// <summary>
  ///   The file is YAML, a sequence "fonts" with one entry for each font of the game to replace:
  ///   <code>
  ///   fonts:
  ///     - id: FONT_SMALL      # the id of Font.dat
  ///       name: Tahoma        # a font of Windows, or
  ///       file: C:\x\my.ttf   # a file (with "name" when the family is not the one written in the file)
  ///       index: 0            # a collection (.ttc) without "name": the font of the file whose family is used
  ///       size: 8             # height of the em square in pixels of the 320 x 200 screen
  ///       bold: false
  ///       antialias: true     # false: the pixels of the system, on or off (bitmap fonts, sizes the font is hinted for)
  ///       outline: true       # the dark outline; without the key: as the original font
  ///       spacing: -1         # pixels between two characters; without the key: from the original font
  ///       tolerance: 25       # percent the font may exceed the original cell before it is refused; without the
  ///                           # key: 25 percent or 2 pixels, whichever is more
  ///       shrink: false       # true: a font that does not fit is tried one pixel smaller until it does
  ///       offsetY: 0          # rows to move the characters down
  ///   </code>
  ///   A font of the game that is not listed keeps its pictures. An entry that cannot be used (no id, neither
  ///   name nor file, no size) is skipped with a warning
  /// </summary>
  TXcomFontSettingsReader = class sealed
  public
    /// <param name="ALog">Where the warnings go; nil for nowhere</param>
    class function Read(const ADocument: IYamlNode; const ALog: IXcomLog = nil): TArray<TXcomFontOverlaySettings>;
      static;
  end;

implementation

uses
  DelphiDoom.XcomEngine.YamlFields;

const
  SLevelWarning = 'WARN';
  SSkipped = 'fonts.cfg: entry %d skipped (%s)';
  SNoId = 'no id';
  SNoFace = 'neither name nor file';
  SNoSize = 'no size';

class function TXcomFontSettingsReader.Read(const ADocument: IYamlNode;
  const ALog: IXcomLog): TArray<TXcomFontOverlaySettings>;
var
  LList: TList<TXcomFontOverlaySettings>;
  LItems: TArray<IYamlNode>;
  LItem: IYamlNode;
  LIndex: Integer;
  LSettings: TXcomFontOverlaySettings;
  LReason: string;
begin
  LList := TList<TXcomFontOverlaySettings>.Create;
  try
    LItems := TXcomYamlFields.Sequence(ADocument, 'fonts');
    for LIndex := 0 to High(LItems) do
    begin
      LItem := LItems[LIndex];
      LSettings := TXcomFontOverlaySettings.Make(TXcomYamlFields.ReadString(LItem, 'id', ''),
        TXcomYamlFields.ReadString(LItem, 'name', ''), TXcomYamlFields.ReadInteger(LItem, 'size', 0));
      LSettings.Face.FileName := TXcomYamlFields.ReadString(LItem, 'file', '');
      LSettings.Face.FaceIndex := TXcomYamlFields.ReadInteger(LItem, 'index', 0);
      LSettings.Face.Bold := TXcomYamlFields.ReadBoolean(LItem, 'bold', False);
      LSettings.Face.Antialias := TXcomYamlFields.ReadBoolean(LItem, 'antialias', True);
      if TXcomYamlFields.Exists(LItem, 'outline') then
      begin
        if TXcomYamlFields.ReadBoolean(LItem, 'outline', True) then
          LSettings.Outline := goOn
        else
          LSettings.Outline := goOff;
      end;
      LSettings.HasSpacing := TXcomYamlFields.Exists(LItem, 'spacing');
      LSettings.Spacing := TXcomYamlFields.ReadInteger(LItem, 'spacing', 0);
      if TXcomYamlFields.Exists(LItem, 'tolerance') then
      begin
        LSettings.Tolerance := TXcomYamlFields.ReadInteger(LItem, 'tolerance', 0);
        if LSettings.Tolerance < 0 then
          LSettings.Tolerance := 0;
      end;
      LSettings.Shrink := TXcomYamlFields.ReadBoolean(LItem, 'shrink', False);
      LSettings.OffsetY := TXcomYamlFields.ReadInteger(LItem, 'offsetY', 0);
      LReason := '';
      if LSettings.FontId = '' then
        LReason := SNoId
      else if (LSettings.Face.Name = '') and (LSettings.Face.FileName = '') then
        LReason := SNoFace
      else if LSettings.Face.Size <= 0 then
        LReason := SNoSize;
      if LReason = '' then
        LList.Add(LSettings)
      else if Assigned(ALog) then
        ALog.Write(SLevelWarning, Format(SSkipped, [LIndex + 1, LReason]));
    end;
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

end.
