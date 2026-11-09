{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - a facility of a base (BaseFacility)   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.BaseFacility;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomSave.Types,
  DelphiDoom.XcomSave.Rules.Intf, DelphiDoom.XcomSave.NodeWriter;

type
  /// <summary>
  ///   Represents a facility built on a base: its place in the base grid and the days left to build it.
  ///   inUse (needs the base's totals) and the craft drawn in the hangar are not ported
  /// </summary>
  TXcomBaseFacility = class
  strict private
    FRules: IXcomFacilityRule;
    FX: Integer;
    FY: Integer;
    FBuildTime: Integer;
  public
    /// <param name="ARules">Required: nil is EXcomSaveException (a null pointer in the C++)</param>
    constructor Create(const ARules: IXcomFacilityRule);
    procedure Load(const ANode: IYamlNode);
    function Save: IYamlNode;
    property Rules: IXcomFacilityRule read FRules;
    property X: Integer read FX write FX;
    property Y: Integer read FY write FY;
    property BuildTime: Integer read FBuildTime write FBuildTime;
    /// <summary>build: one day less to build</summary>
    procedure Build;
  end;

implementation

const
  SNoRules = 'Xcom: a base facility needs its rules';

{ TXcomBaseFacility }

constructor TXcomBaseFacility.Create(const ARules: IXcomFacilityRule);
begin
  inherited Create;
  if not Assigned(ARules) then
    raise EXcomSaveException.Create(SNoRules);
  FRules := ARules;
  FX := -1;
  FY := -1;
end;

procedure TXcomBaseFacility.Load(const ANode: IYamlNode);
begin
  FX := TXcomNodeReader.ReadInteger(ANode, 'x', FX);
  FY := TXcomNodeReader.ReadInteger(ANode, 'y', FY);
  FBuildTime := TXcomNodeReader.ReadInteger(ANode, 'buildTime', FBuildTime);
end;

function TXcomBaseFacility.Save: IYamlNode;
begin
  Result := TXcomNodeWriter.NewMap;
  TXcomNodeWriter.SetString(Result, 'type', FRules.FacilityType);
  TXcomNodeWriter.SetInteger(Result, 'x', FX);
  TXcomNodeWriter.SetInteger(Result, 'y', FY);
  if FBuildTime <> 0 then
    TXcomNodeWriter.SetInteger(Result, 'buildTime', FBuildTime);
end;

procedure TXcomBaseFacility.Build;
begin
  Dec(FBuildTime);
end;

end.
