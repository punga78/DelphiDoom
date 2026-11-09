{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - a mission site on the globe           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.MissionSite;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomSave.Types,
  DelphiDoom.XcomSave.Rules.Intf, DelphiDoom.XcomSave.NodeWriter, DelphiDoom.XcomSave.Target;

type
  /// <summary>MissionSite: a place on the globe where aliens carry out a mission</summary>
  TXcomMissionSite = class(TXcomTarget)
  strict private
    FRules: IXcomMissionRule;
    FDeployment: IXcomDeploymentRule;
    FTexture: Integer;
    FSecondsRemaining: Cardinal;
    FRace: string;
    FCity: string;
    FInBattlescape: Boolean;
    FDetected: Boolean;
  public
    /// <param name="ARules">Required: nil is EXcomSaveException (a null pointer in the C++)</param>
    /// <param name="ADeployment">Required: nil is EXcomSaveException</param>
    constructor Create(const ARules: IXcomMissionRule; const ADeployment: IXcomDeploymentRule);
    procedure Load(const ANode: IYamlNode); override;
    function Save: IYamlNode; override;
    /// <summary>The marker name of the deployment</summary>
    function TargetType: string; override;
    function MarkerName: string; override;
    /// <summary>-1 while not detected, 5 without a marker icon, else the icon of the deployment</summary>
    function Marker: Integer; override;
    property Rules: IXcomMissionRule read FRules;
    property Deployment: IXcomDeploymentRule read FDeployment;
    property Texture: Integer read FTexture write FTexture;
    /// <summary>size_t of the C++: 32 bits like the golden</summary>
    property SecondsRemaining: Cardinal read FSecondsRemaining write FSecondsRemaining;
    property AlienRace: string read FRace write FRace;
    property City: string read FCity write FCity;
    property InBattlescape: Boolean read FInBattlescape write FInBattlescape;
    property Detected: Boolean read FDetected write FDetected;
  end;

implementation

const
  SNoRules = 'Xcom: a mission site needs its mission and deployment rules';

{ TXcomMissionSite }

constructor TXcomMissionSite.Create(const ARules: IXcomMissionRule; const ADeployment: IXcomDeploymentRule);
begin
  inherited Create;
  if not Assigned(ARules) or not Assigned(ADeployment) then
    raise EXcomSaveException.Create(SNoRules);
  FRules := ARules;
  FDeployment := ADeployment;
  FTexture := -1;
end;

procedure TXcomMissionSite.Load(const ANode: IYamlNode);
begin
  inherited Load(ANode);
  FTexture := TXcomNodeReader.ReadInteger(ANode, 'texture', FTexture);
  FSecondsRemaining := TXcomNodeReader.ReadSize(ANode, 'secondsRemaining', FSecondsRemaining);
  FRace := TXcomNodeReader.ReadString(ANode, 'race', FRace);
  FInBattlescape := TXcomNodeReader.ReadBoolean(ANode, 'inBattlescape', FInBattlescape);
  FDetected := TXcomNodeReader.ReadBoolean(ANode, 'detected', FDetected);
end;

function TXcomMissionSite.Save: IYamlNode;
begin
  Result := inherited Save;
  TXcomNodeWriter.SetString(Result, 'type', FRules.MissionType);
  TXcomNodeWriter.SetString(Result, 'deployment', FDeployment.DeploymentType);
  TXcomNodeWriter.SetInteger(Result, 'texture', FTexture);
  if FSecondsRemaining <> 0 then
    TXcomNodeWriter.SetString(Result, 'secondsRemaining', UIntToStr(FSecondsRemaining));
  TXcomNodeWriter.SetString(Result, 'race', FRace);
  if FInBattlescape then
    TXcomNodeWriter.SetBoolean(Result, 'inBattlescape', FInBattlescape);
  TXcomNodeWriter.SetBoolean(Result, 'detected', FDetected);
end;

function TXcomMissionSite.TargetType: string;
begin
  Result := FDeployment.MarkerName;
end;

function TXcomMissionSite.MarkerName: string;
begin
  Result := TargetType;
end;

function TXcomMissionSite.Marker: Integer;
begin
  if not FDetected then
    Exit(-1);
  if FDeployment.MarkerIcon = -1 then
    Exit(5);
  Result := FDeployment.MarkerIcon;
end;

end.
