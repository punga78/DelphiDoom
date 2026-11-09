{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - extra strings of a language (ExtraStrings)}
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.ExtraStrings;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.NodeReader;

type
  /// <summary>The strings that a mod adds to a language (ExtraStrings)</summary>
  TXcomExtraStrings = class
  strict private
    FStrings: TXcomStringMap<string>;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>
    ///   Loads "strings": a scalar is a string; a map is a string with plural forms, one per key named
    ///   "id_key"; anything else is ignored
    /// </summary>
    procedure Load(const ANode: IYamlNode);
    property Strings: TXcomStringMap<string> read FStrings;
  end;

implementation

uses
  DelphiDoom.Yaml.Types;

{ TXcomExtraStrings }

constructor TXcomExtraStrings.Create;
begin
  inherited Create;
  FStrings := TXcomStringMap<string>.Create;
end;

destructor TXcomExtraStrings.Destroy;
begin
  FStrings.Free;
  inherited Destroy;
end;

procedure TXcomExtraStrings.Load(const ANode: IYamlNode);
var
  LPair, LForm: TYamlPair;
begin
  for LPair in TXcomNodeReader.Field(ANode, 'strings').Pairs do
  begin
    if LPair.Value.IsScalar then
      FStrings.SetValue(TXcomNodeReader.TextOf(LPair.Key), TXcomNodeReader.TextOf(LPair.Value))
    else if LPair.Value.IsMap then
      for LForm in LPair.Value.Pairs do
        FStrings.SetValue(TXcomNodeReader.TextOf(LPair.Key) + '_' + TXcomNodeReader.TextOf(LForm.Key),
          TXcomNodeReader.TextOf(LForm.Value));
  end;
end;

end.
