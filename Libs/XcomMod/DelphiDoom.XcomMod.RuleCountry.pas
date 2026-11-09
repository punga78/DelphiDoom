{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - a country (RuleCountry)                   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.RuleCountry;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomMod.Areas,
  DelphiDoom.XcomMod.Random;

type
  /// <summary>
  ///   Represents a country that funds the player: funding, the position of its label on the globe and the
  ///   areas it covers (RuleCountry)
  /// </summary>
  TXcomRuleCountry = class
  strict private
    FType: string;
    FFundingBase: Integer;
    FFundingCap: Integer;
    FLabelLongitude: Double;
    FLabelLatitude: Double;
    FAreas: TXcomGlobeAreas;
  public
    constructor Create(const AType: string);
    procedure Load(const ANode: IYamlNode);
    property CountryType: string read FType;
    property FundingCap: Integer read FFundingCap;
    /// <summary>The longitude of the label, in radians</summary>
    property LabelLongitude: Double read FLabelLongitude;
    property LabelLatitude: Double read FLabelLatitude;
    /// <summary>
    ///   generateFunding: a random number between the base and twice the base, in thousands. A base of -1 makes
    ///   an empty range, undefined in the C++: EXcomModException
    /// </summary>
    function GenerateFunding(const ARandom: IXcomRandom): Integer;
    function IsInside(ALongitude, ALatitude: Double): Boolean;
    property FundingBase: Integer read FFundingBase;
  end;

implementation

{ TXcomRuleCountry }

constructor TXcomRuleCountry.Create(const AType: string);
begin
  inherited Create;
  FType := AType;
end;

procedure TXcomRuleCountry.Load(const ANode: IYamlNode);
begin
  FType := TXcomNodeReader.ReadString(ANode, 'type', FType);
  FFundingBase := TXcomNodeReader.ReadInteger(ANode, 'fundingBase', FFundingBase);
  FFundingCap := TXcomNodeReader.ReadInteger(ANode, 'fundingCap', FFundingCap);
  if TXcomNodeReader.Field(ANode, 'labelLon').IsDefined then
    FLabelLongitude := XcomDegToRad(TXcomNodeReader.Field(ANode, 'labelLon').AsDouble);
  if TXcomNodeReader.Field(ANode, 'labelLat').IsDefined then
    FLabelLatitude := XcomDegToRad(TXcomNodeReader.Field(ANode, 'labelLat').AsDouble);
  FAreas.Load(ANode);
end;

function TXcomRuleCountry.GenerateFunding(const ARandom: IXcomRandom): Integer;
begin
  Result := ARandom.Generate(FFundingBase, FFundingBase * 2) * 1000;
end;

function TXcomRuleCountry.IsInside(ALongitude, ALatitude: Double): Boolean;
begin
  Result := FAreas.Contains(ALongitude, ALatitude);
end;

end.
