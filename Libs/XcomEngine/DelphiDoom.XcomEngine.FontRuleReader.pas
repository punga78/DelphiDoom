{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - reads the fonts listed by Font.dat (the    }
{  part of Mod::loadExtraResources and Font::load that reads the YAML)          }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.FontRuleReader;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Yaml.Intf, DelphiDoom.XcomSurface.Font;

type
  /// <summary>One font of Font.dat: its id (FONT_BIG...) and what Font::load reads</summary>
  TXcomFontRule = record
    Id: string;
    /// <summary>The size of a cell and the spacing of the font, that an image without its own takes</summary>
    Width: Integer;
    Height: Integer;
    Spacing: Integer;
    Definition: TXcomFontDefinition;
  end;

  /// <summary>The "fonts" sequence of a Font.dat document, in the order of the file</summary>
  TXcomFontRuleReader = class sealed
  public
    class function Read(const ADocument: IYamlNode): TArray<TXcomFontRule>; static;
  end;

implementation

uses
  DelphiDoom.XcomEngine.YamlFields;

class function TXcomFontRuleReader.Read(const ADocument: IYamlNode): TArray<TXcomFontRule>;
var
  LRules: TList<TXcomFontRule>;
  LImages: TList<TXcomFontImageDefinition>;
  LItem: IYamlNode;
  LImage: IYamlNode;
  LRule: TXcomFontRule;
  LImageDefinition: TXcomFontImageDefinition;
begin
  LRules := TList<TXcomFontRule>.Create;
  try
    for LItem in TXcomYamlFields.Sequence(ADocument, 'fonts') do
    begin
      LRule.Id := TXcomYamlFields.ReadString(LItem, 'id', '');
      LRule.Width := TXcomYamlFields.ReadInteger(LItem, 'width', 0);
      LRule.Height := TXcomYamlFields.ReadInteger(LItem, 'height', 0);
      LRule.Spacing := TXcomYamlFields.ReadInteger(LItem, 'spacing', 0);
      LRule.Definition.Monospace := TXcomYamlFields.ReadBoolean(LItem, 'monospace', False);
      LImages := TList<TXcomFontImageDefinition>.Create;
      try
        for LImage in TXcomYamlFields.Sequence(LItem, 'images') do
        begin
          LImageDefinition.Width := TXcomYamlFields.ReadInteger(LImage, 'width', LRule.Width);
          LImageDefinition.Height := TXcomYamlFields.ReadInteger(LImage, 'height', LRule.Height);
          LImageDefinition.Spacing := TXcomYamlFields.ReadInteger(LImage, 'spacing', LRule.Spacing);
          LImageDefinition.FileName := TXcomYamlFields.ReadString(LImage, 'file', '');
          LImageDefinition.Chars := TXcomYamlFields.ReadString(LImage, 'chars', '');
          LImages.Add(LImageDefinition);
        end;
        LRule.Definition.Images := LImages.ToArray;
      finally
        LImages.Free;
      end;
      LRules.Add(LRule);
    end;
    Result := LRules.ToArray;
  finally
    LRules.Free;
  end;
end;

end.
