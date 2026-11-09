{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - a manufacture project in a base       }
{  (Production)                                                                 }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.Production;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.RuleManufacture, DelphiDoom.XcomMod.NodeReader,
  DelphiDoom.XcomSave.Types, DelphiDoom.XcomSave.NodeWriter;

type
  /// <summary>
  ///   Represents the production of an item in a base: the engineers assigned, the time spent and the amount.
  ///   step, startItem and the materials check work on a Base, a SavedGame and the ruleset and are not ported
  ///   yet (they come with Base)
  /// </summary>
  TXcomProduction = class
  strict private
    FRules: TXcomRuleManufacture;
    FAmount: Integer;
    FInfinite: Boolean;
    FTimeSpent: Integer;
    FEngineers: Integer;
    FSell: Boolean;
  public
    /// <param name="ARules">Not owned; required (nil is EXcomSaveException)</param>
    constructor Create(const ARules: TXcomRuleManufacture; AAmount: Integer);
    /// <summary>Loads the project; an amount of INT_MAX (old saved games) becomes 999 infinite, sold</summary>
    procedure Load(const ANode: IYamlNode);
    function Save: IYamlNode;
    property Rules: TXcomRuleManufacture read FRules;
    property AmountTotal: Integer read FAmount write FAmount;
    property InfiniteAmount: Boolean read FInfinite write FInfinite;
    property TimeSpent: Integer read FTimeSpent write FTimeSpent;
    property AssignedEngineers: Integer read FEngineers write FEngineers;
    property SellItems: Boolean read FSell write FSell;
    /// <summary>getAmountProduced: the items done with the time spent (all of them when the time is zero)</summary>
    function AmountProduced: Integer;
    /// <summary>haveEnoughMoneyForOneMoreUnit, with the funds of the saved game given</summary>
    function HaveEnoughMoneyForOneMoreUnit(AFunds: Int64): Boolean;
  end;

implementation

const
  SNoRules = 'Xcom: a production needs its manufacture rules';

{ TXcomProduction }

constructor TXcomProduction.Create(const ARules: TXcomRuleManufacture; AAmount: Integer);
begin
  inherited Create;
  if not Assigned(ARules) then
    raise EXcomSaveException.Create(SNoRules);
  FRules := ARules;
  FAmount := AAmount;
end;

procedure TXcomProduction.Load(const ANode: IYamlNode);
begin
  FEngineers := TXcomNodeReader.ReadInteger(ANode, 'assigned', FEngineers);
  FTimeSpent := TXcomNodeReader.ReadInteger(ANode, 'spent', FTimeSpent);
  FAmount := TXcomNodeReader.ReadInteger(ANode, 'amount', FAmount);
  FInfinite := TXcomNodeReader.ReadBoolean(ANode, 'infinite', FInfinite);
  FSell := TXcomNodeReader.ReadBoolean(ANode, 'sell', FSell);
  // backwards compatibility
  if FAmount = High(Integer) then
  begin
    FAmount := 999;
    FInfinite := True;
    FSell := True;
  end;
end;

function TXcomProduction.Save: IYamlNode;
begin
  Result := TXcomNodeWriter.NewMap;
  TXcomNodeWriter.SetString(Result, 'item', FRules.Name);
  TXcomNodeWriter.SetInteger(Result, 'assigned', FEngineers);
  TXcomNodeWriter.SetInteger(Result, 'spent', FTimeSpent);
  TXcomNodeWriter.SetInteger(Result, 'amount', FAmount);
  TXcomNodeWriter.SetBoolean(Result, 'infinite', FInfinite);
  if FSell then
    TXcomNodeWriter.SetBoolean(Result, 'sell', FSell);
end;

function TXcomProduction.AmountProduced: Integer;
begin
  if FRules.ManufactureTime > 0 then
    Result := FTimeSpent div FRules.ManufactureTime
  else
    Result := FAmount;
end;

function TXcomProduction.HaveEnoughMoneyForOneMoreUnit(AFunds: Int64): Boolean;
begin
  // either there is enough money, or the production does not cost anything
  Result := (AFunds >= FRules.ManufactureCost) or (FRules.ManufactureCost <= 0);
end;

end.
