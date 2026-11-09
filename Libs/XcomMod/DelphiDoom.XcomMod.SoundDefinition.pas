{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - a list of sounds of a CAT file            }
{  (SoundDefinition)                                                            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.SoundDefinition;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader;

type
  /// <summary>The sounds of a CAT file that the mod uses: ranges and single numbers (SoundDefinition)</summary>
  TXcomSoundDefinition = class
  strict private
    FType: string;
    FCatFile: string;
    FSoundList: TArray<Integer>;
  public
    constructor Create(const AType: string);
    /// <summary>Loads from a node: "soundRanges" (pairs first, last: all the numbers between) then "sounds"</summary>
    procedure Load(const ANode: IYamlNode);
    property DefinitionType: string read FType;
    property CatFile: string read FCatFile;
    property SoundList: TArray<Integer> read FSoundList;
  end;

implementation

{ TXcomSoundDefinition }

constructor TXcomSoundDefinition.Create(const AType: string);
begin
  inherited Create;
  FType := AType;
end;

procedure TXcomSoundDefinition.Load(const ANode: IYamlNode);
var
  LItem: IYamlNode;
  LFirst, LLast, LSound: Integer;
begin
  for LItem in TXcomNodeReader.Field(ANode, 'soundRanges').Items do
  begin
    TXcomNodeReader.DecodeIntPair(LItem, 0, 0, LFirst, LLast);
    for LSound := LFirst to LLast do
    begin
      SetLength(FSoundList, Length(FSoundList) + 1);
      FSoundList[High(FSoundList)] := LSound;
    end;
  end;
  for LItem in TXcomNodeReader.Field(ANode, 'sounds').Items do
  begin
    SetLength(FSoundList, Length(FSoundList) + 1);
    FSoundList[High(FSoundList)] := LItem.AsInteger(-1);
  end;
  FCatFile := TXcomNodeReader.ReadString(ANode, 'file', FCatFile);
end;

end.
