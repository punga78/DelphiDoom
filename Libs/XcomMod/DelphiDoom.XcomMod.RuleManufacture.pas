{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - a manufacturing project (RuleManufacture) }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.RuleManufacture;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.NodeReader;

type
  /// <summary>Represents a specific manufacture project: its cost, time, space and the items it needs and gives</summary>
  TXcomRuleManufacture = class
  strict private
    FName: string;
    FCategory: string;
    FRequires: TArray<string>;
    FSpace: Integer;
    FTime: Integer;
    FCost: Integer;
    FRequiredItems: TXcomStringMap<Integer>;
    FProducedItems: TXcomStringMap<Integer>;
    FListOrder: Integer;
  public
    /// <summary>By default the project makes one item with its own name</summary>
    constructor Create(const AName: string);
    destructor Destroy; override;
    procedure Load(const ANode: IYamlNode; AListOrder: Integer);
    property Name: string read FName;
    property Category: string read FCategory;
    property Requirements: TArray<string> read FRequires;
    property RequiredSpace: Integer read FSpace;
    property ManufactureTime: Integer read FTime;
    property ManufactureCost: Integer read FCost;
    property RequiredItems: TXcomStringMap<Integer> read FRequiredItems;
    property ProducedItems: TXcomStringMap<Integer> read FProducedItems;
    property ListOrder: Integer read FListOrder;
  end;

implementation

{ TXcomRuleManufacture }

constructor TXcomRuleManufacture.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
  FRequiredItems := TXcomStringMap<Integer>.Create;
  FProducedItems := TXcomStringMap<Integer>.Create;
  FProducedItems.SetValue(AName, 1);
end;

destructor TXcomRuleManufacture.Destroy;
begin
  FRequiredItems.Free;
  FProducedItems.Free;
  inherited Destroy;
end;

procedure TXcomRuleManufacture.Load(const ANode: IYamlNode; AListOrder: Integer);
var
  LSame: Boolean;
  LValue: Integer;
begin
  // while the project only makes one item named as itself, a new name renames the item too
  LSame := (FProducedItems.Count = 1) and (FName = FProducedItems.Key(0));
  FName := TXcomNodeReader.ReadString(ANode, 'name', FName);
  if LSame then
  begin
    LValue := FProducedItems.Value(0);
    FProducedItems.Clear;
    FProducedItems.SetValue(FName, LValue);
  end;
  FCategory := TXcomNodeReader.ReadString(ANode, 'category', FCategory);
  FRequires := TXcomNodeReader.ReadStrings(ANode, 'requires', FRequires);
  FSpace := TXcomNodeReader.ReadInteger(ANode, 'space', FSpace);
  FTime := TXcomNodeReader.ReadInteger(ANode, 'time', FTime);
  FCost := TXcomNodeReader.ReadInteger(ANode, 'cost', FCost);
  TXcomNodeReader.ReadStringIntMap(ANode, 'requiredItems', FRequiredItems);
  TXcomNodeReader.ReadStringIntMap(ANode, 'producedItems', FProducedItems);
  FListOrder := TXcomNodeReader.ReadInteger(ANode, 'listOrder', FListOrder);
  if FListOrder = 0 then
    FListOrder := AListOrder;
end;

end.
