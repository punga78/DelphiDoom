{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - a weapon of a craft (CraftWeapon)     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.CraftWeapon;

interface

uses
  System.SysUtils, System.Math, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomSave.Types,
  DelphiDoom.XcomSave.Rules.Intf, DelphiDoom.XcomSave.NodeWriter;

type
  /// <summary>Represents a craft weapon equipped on a craft: its ammo and whether it is rearming</summary>
  TXcomCraftWeapon = class
  strict private
    FRules: IXcomCraftWeaponRule;
    FAmmo: Integer;
    FRearming: Boolean;
  public
    /// <param name="ARules">Required: nil is EXcomSaveException (a null pointer in the C++)</param>
    constructor Create(const ARules: IXcomCraftWeaponRule; AAmmo: Integer);
    procedure Load(const ANode: IYamlNode);
    function Save: IYamlNode;
    property Rules: IXcomCraftWeaponRule read FRules;
    property Ammo: Integer read FAmmo;
    /// <summary>setAmmo: clamps to 0..the ammo capacity; False when the ammo went below zero</summary>
    function SetAmmo(AAmmo: Integer): Boolean;
    property Rearming: Boolean read FRearming write FRearming;
    /// <summary>
    ///   rearm: loads what the rate allows from the available clips and returns the clips used (0 without a clip
    ///   size)
    /// </summary>
    function Rearm(AAvailable, AClipSize: Integer): Integer;
  end;

implementation

const
  SNoRules = 'Xcom: a craft weapon needs its rules';

{ TXcomCraftWeapon }

constructor TXcomCraftWeapon.Create(const ARules: IXcomCraftWeaponRule; AAmmo: Integer);
begin
  inherited Create;
  if not Assigned(ARules) then
    raise EXcomSaveException.Create(SNoRules);
  FRules := ARules;
  FAmmo := AAmmo;
end;

procedure TXcomCraftWeapon.Load(const ANode: IYamlNode);
begin
  FAmmo := TXcomNodeReader.ReadInteger(ANode, 'ammo', FAmmo);
  FRearming := TXcomNodeReader.ReadBoolean(ANode, 'rearming', FRearming);
end;

function TXcomCraftWeapon.Save: IYamlNode;
begin
  Result := TXcomNodeWriter.NewMap;
  TXcomNodeWriter.SetString(Result, 'type', FRules.WeaponType);
  TXcomNodeWriter.SetInteger(Result, 'ammo', FAmmo);
  if FRearming then
    TXcomNodeWriter.SetBoolean(Result, 'rearming', FRearming);
end;

function TXcomCraftWeapon.SetAmmo(AAmmo: Integer): Boolean;
begin
  FAmmo := AAmmo;
  if FAmmo < 0 then
  begin
    FAmmo := 0;
    Exit(False);
  end;
  if FAmmo > FRules.AmmoMax then
    FAmmo := FRules.AmmoMax;
  Result := True;
end;

function TXcomCraftWeapon.Rearm(AAvailable, AClipSize: Integer): Integer;
var
  LAmmoUsed, LNeeded: Integer;
begin
  LAmmoUsed := FRules.RearmRate;
  if AClipSize > 0 then
  begin
    // +(clipSize - 1) corrects the rounding up
    LNeeded := Min(FRules.RearmRate, FRules.AmmoMax - FAmmo + AClipSize - 1) div AClipSize;
    if LNeeded > AAvailable then
      LNeeded := AAvailable;
    LAmmoUsed := LNeeded * AClipSize;
  end;
  SetAmmo(FAmmo + LAmmoUsed);
  FRearming := FAmmo < FRules.AmmoMax;
  if AClipSize <= 0 then
    Exit(0);
  Result := LAmmoUsed div AClipSize;
end;

end.
