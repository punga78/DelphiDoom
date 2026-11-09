{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - a piece of music (RuleMusic)              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.RuleMusic;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader;

type
  /// <summary>
  ///   Represents a piece of music of the ruleset: its name, its place in the original CAT file and the volume
  ///   it is normalized to (RuleMusic)
  /// </summary>
  TXcomRuleMusic = class
  strict private
    FType: string;
    FName: string;
    FCatPos: Integer;
    FNormalization: Single;
  public
    constructor Create(const AType: string);
    procedure Load(const ANode: IYamlNode);
    property MusicType: string read FType;
    /// <summary>getName: the name of the music, or its type when it has no name of its own</summary>
    function Name: string;
    /// <summary>The position in the CAT file; MaxInt when the music is not in the original files</summary>
    property CatPos: Integer read FCatPos;
    property Normalization: Single read FNormalization;
  end;

implementation

{ TXcomRuleMusic }

constructor TXcomRuleMusic.Create(const AType: string);
begin
  inherited Create;
  FType := AType;
  FCatPos := MaxInt;
  FNormalization := 0.76;
end;

function TXcomRuleMusic.Name: string;
begin
  if FName = '' then
    Exit(FType);
  Result := FName;
end;

procedure TXcomRuleMusic.Load(const ANode: IYamlNode);
begin
  FName := TXcomNodeReader.ReadString(ANode, 'name', FName);
  FCatPos := TXcomNodeReader.ReadInteger(ANode, 'catPos', FCatPos);
  FNormalization := TXcomNodeReader.Field(ANode, 'normalization').AsSingle(FNormalization);
end;

end.
