{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - an alien base on the globe            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.AlienBase;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomSave.Types,
  DelphiDoom.XcomSave.Rules.Intf, DelphiDoom.XcomSave.NodeWriter, DelphiDoom.XcomSave.Target;

type
  /// <summary>AlienBase: a base of the aliens, found on the globe once discovered</summary>
  TXcomAlienBase = class(TXcomTarget)
  strict private
    FDeployment: IXcomDeploymentRule;
    FRace: string;
    FInBattlescape: Boolean;
    FDiscovered: Boolean;
  public
    /// <param name="ADeployment">Required (the C++ would use a null pointer): nil is EXcomSaveException</param>
    constructor Create(const ADeployment: IXcomDeploymentRule);
    procedure Load(const ANode: IYamlNode); override;
    function Save: IYamlNode; override;
    /// <summary>The marker name of the deployment</summary>
    function TargetType: string; override;
    /// <summary>-1 while not discovered, else the marker icon of the deployment</summary>
    function Marker: Integer; override;
    property Deployment: IXcomDeploymentRule read FDeployment;
    property AlienRace: string read FRace write FRace;
    property InBattlescape: Boolean read FInBattlescape write FInBattlescape;
    property Discovered: Boolean read FDiscovered write FDiscovered;
  end;

implementation

const
  SNoDeployment = 'Xcom: an alien base needs its deployment';

{ TXcomAlienBase }

constructor TXcomAlienBase.Create(const ADeployment: IXcomDeploymentRule);
begin
  inherited Create;
  if not Assigned(ADeployment) then
    raise EXcomSaveException.Create(SNoDeployment);
  FDeployment := ADeployment;
end;

procedure TXcomAlienBase.Load(const ANode: IYamlNode);
begin
  inherited Load(ANode);
  FRace := TXcomNodeReader.ReadString(ANode, 'race', FRace);
  FInBattlescape := TXcomNodeReader.ReadBoolean(ANode, 'inBattlescape', FInBattlescape);
  FDiscovered := TXcomNodeReader.ReadBoolean(ANode, 'discovered', FDiscovered);
end;

function TXcomAlienBase.Save: IYamlNode;
begin
  Result := inherited Save;
  TXcomNodeWriter.SetString(Result, 'race', FRace);
  if FInBattlescape then
    TXcomNodeWriter.SetBoolean(Result, 'inBattlescape', FInBattlescape);
  if FDiscovered then
    TXcomNodeWriter.SetBoolean(Result, 'discovered', FDiscovered);
  TXcomNodeWriter.SetString(Result, 'deployment', FDeployment.DeploymentType);
end;

function TXcomAlienBase.TargetType: string;
begin
  Result := FDeployment.MarkerName;
end;

function TXcomAlienBase.Marker: Integer;
begin
  if not FDiscovered then
    Exit(-1);
  Result := FDeployment.MarkerIcon;
end;

end.
