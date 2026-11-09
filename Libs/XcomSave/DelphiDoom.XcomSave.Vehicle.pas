{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - a vehicle (Vehicle)                    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.Vehicle;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomSave.Types,
  DelphiDoom.XcomSave.Rules.Intf, DelphiDoom.XcomSave.NodeWriter;

type
  /// <summary>Represents a vehicle (a large unit that is carried on a craft): its item, its ammo and size</summary>
  TXcomVehicle = class
  strict private
    FRules: IXcomItemRule;
    FAmmo: Integer;
    FSize: Integer;
  public
    /// <param name="ARules">Required: nil is EXcomSaveException (a null pointer in the C++)</param>
    constructor Create(const ARules: IXcomItemRule; AAmmo, ASize: Integer);
    procedure Load(const ANode: IYamlNode);
    function Save: IYamlNode;
    property Rules: IXcomItemRule read FRules;
    /// <summary>getAmmo: 255 when the ammo is -1 (unlimited)</summary>
    function Ammo: Integer;
    /// <summary>setAmmo: ignored while the ammo is unlimited (-1)</summary>
    procedure SetAmmo(AAmmo: Integer);
    property Size: Integer read FSize;
  end;

implementation

const
  SNoRules = 'Xcom: a vehicle needs its item rules';

{ TXcomVehicle }

constructor TXcomVehicle.Create(const ARules: IXcomItemRule; AAmmo, ASize: Integer);
begin
  inherited Create;
  if not Assigned(ARules) then
    raise EXcomSaveException.Create(SNoRules);
  FRules := ARules;
  FAmmo := AAmmo;
  FSize := ASize;
end;

procedure TXcomVehicle.Load(const ANode: IYamlNode);
begin
  FAmmo := TXcomNodeReader.ReadInteger(ANode, 'ammo', FAmmo);
  FSize := TXcomNodeReader.ReadInteger(ANode, 'size', FSize);
end;

function TXcomVehicle.Save: IYamlNode;
begin
  Result := TXcomNodeWriter.NewMap;
  TXcomNodeWriter.SetString(Result, 'type', FRules.ItemType);
  TXcomNodeWriter.SetInteger(Result, 'ammo', FAmmo);
  TXcomNodeWriter.SetInteger(Result, 'size', FSize);
end;

function TXcomVehicle.Ammo: Integer;
begin
  if FAmmo = -1 then
    Exit(255);
  Result := FAmmo;
end;

procedure TXcomVehicle.SetAmmo(AAmmo: Integer);
begin
  if FAmmo <> -1 then
    FAmmo := AAmmo;
end;

end.
