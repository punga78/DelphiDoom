{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - an inventory section (RuleInventory)      }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.RuleInventory;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.Types,
  DelphiDoom.XcomMod.NodeReader;

const
  /// <summary>InventoryType: a section made of slots, a hand, or the ground</summary>
  INV_SLOT = 0;
  INV_HAND = 1;
  INV_GROUND = 2;
  INV_SLOT_WIDTH = 16;
  INV_SLOT_HEIGHT = 16;
  INV_HAND_WIDTH = 2;
  INV_HAND_HEIGHT = 3;

type
  /// <summary>RuleSlot: a cell of an inventory section</summary>
  TXcomRuleSlot = record
    X: Integer;
    Y: Integer;
  end;

  /// <summary>
  ///   Represents a specific section of the inventory, containing information like available slots and
  ///   screen position (RuleInventory)
  /// </summary>
  TXcomRuleInventory = class
  strict private
    FId: string;
    FX: Integer;
    FY: Integer;
    FType: Integer;
    FSlots: TArray<TXcomRuleSlot>;
    FCosts: TXcomStringMap<Integer>;
    FListOrder: Integer;
    class function ReadSlots(const ANode: IYamlNode; const AKey: string;
      const ADefault: TArray<TXcomRuleSlot>): TArray<TXcomRuleSlot>; static;
  public
    constructor Create(const AId: string);
    destructor Destroy; override;
    /// <summary>Loads the section from a node; AListOrder is the default of the field listOrder</summary>
    procedure Load(const ANode: IYamlNode; AListOrder: Integer);
    property Id: string read FId;
    property X: Integer read FX;
    property Y: Integer read FY;
    /// <summary>The type: any number given by the ruleset (INV_SLOT, INV_HAND, INV_GROUND or another one)</summary>
    property InventoryType: Integer read FType;
    property Slots: TArray<TXcomRuleSlot> read FSlots;
    property ListOrder: Integer read FListOrder;
    /// <summary>The cost, in time units, of moving an item to each other section (_costs)</summary>
    property Costs: TXcomStringMap<Integer> read FCosts;
    /// <summary>checkSlotInPosition: whether the point (screen coordinates) is over a slot of the section</summary>
    function IsSlotInPosition(AMouseX, AMouseY: Integer): Boolean;
    /// <summary>
    ///   fitItemInSlot: whether an item of AItemWidth x AItemHeight slots fits with its corner at slot (AX, AY) of
    ///   this section (the caller gives the size of the item: this unit does not know the item rules)
    /// </summary>
    function FitItemInSlot(AItemWidth, AItemHeight, AX, AY: Integer): Boolean;
    /// <summary>Whether the section has a cost for moving an item to the section with this id</summary>
    function HasCostFor(const AId: string): Boolean;
    /// <summary>getCost: the time units to move an item to another section (0 for the same one)</summary>
    function GetCost(const ASlot: TXcomRuleInventory): Integer;
  end;

implementation

{ TXcomRuleInventory }

constructor TXcomRuleInventory.Create(const AId: string);
begin
  inherited Create;
  FId := AId;
  FCosts := TXcomStringMap<Integer>.Create;
end;

destructor TXcomRuleInventory.Destroy;
begin
  FCosts.Free;
  inherited Destroy;
end;

class function TXcomRuleInventory.ReadSlots(const ANode: IYamlNode; const AKey: string;
  const ADefault: TArray<TXcomRuleSlot>): TArray<TXcomRuleSlot>;
var
  LField, LSlot: IYamlNode;
  LItems, LCells: TArray<IYamlNode>;
  LIndex: Integer;
begin
  LField := TXcomNodeReader.Field(ANode, AKey);
  if not LField.IsDefined or not LField.IsSequence then
    Exit(ADefault);
  LItems := LField.Items;
  SetLength(Result, Length(LItems));
  for LIndex := 0 to High(LItems) do
  begin
    LSlot := LItems[LIndex];
    // YAML::convert<RuleSlot>::decode needs a sequence of two numbers; as<RuleSlot>() fails otherwise
    if not LSlot.IsSequence or (LSlot.Size <> 2) then
      raise EYamlBadConversion.Create(LSlot.Mark, 'bad conversion');
    LCells := LSlot.Items;
    Result[LIndex].X := LCells[0].AsInteger;
    Result[LIndex].Y := LCells[1].AsInteger;
  end;
end;

procedure TXcomRuleInventory.Load(const ANode: IYamlNode; AListOrder: Integer);
begin
  FId := TXcomNodeReader.ReadString(ANode, 'id', FId);
  FX := TXcomNodeReader.ReadInteger(ANode, 'x', FX);
  FY := TXcomNodeReader.ReadInteger(ANode, 'y', FY);
  FType := TXcomNodeReader.ReadInteger(ANode, 'type', FType);
  FSlots := ReadSlots(ANode, 'slots', FSlots);
  TXcomNodeReader.ReadStringIntMap(ANode, 'costs', FCosts);
  FListOrder := TXcomNodeReader.ReadInteger(ANode, 'listOrder', AListOrder);
end;

function TXcomRuleInventory.FitItemInSlot(AItemWidth, AItemHeight, AX, AY: Integer): Boolean;
var
  LWidth: Integer;
  LHeight: Integer;
  LOffset: Integer;
  LColumn: Integer;
  LRow: Integer;
  LTotal: Integer;
  LFound: Integer;
  LIndex: Integer;
begin
  if FType = INV_HAND then
    Exit(True);
  if FType = INV_GROUND then
  begin
    LWidth := (320 - FX) div INV_SLOT_WIDTH;
    LHeight := (200 - FY) div INV_SLOT_HEIGHT;
    LOffset := 0;
    while AX >= LOffset + LWidth do
      Inc(LOffset, LWidth);
    for LColumn := AX to AX + AItemWidth - 1 do
      for LRow := AY to AY + AItemHeight - 1 do
        if not ((LColumn >= LOffset) and (LColumn < LOffset + LWidth) and (LRow >= 0) and (LRow < LHeight)) then
          Exit(False);
    Exit(True);
  end;
  LTotal := AItemWidth * AItemHeight;
  LFound := 0;
  LIndex := 0;
  while (LIndex < Length(FSlots)) and (LFound < LTotal) do
  begin
    if (FSlots[LIndex].X >= AX) and (FSlots[LIndex].X < AX + AItemWidth) and (FSlots[LIndex].Y >= AY) and
      (FSlots[LIndex].Y < AY + AItemHeight) then
      Inc(LFound);
    Inc(LIndex);
  end;
  Result := LFound = LTotal;
end;

function TXcomRuleInventory.IsSlotInPosition(AMouseX, AMouseY: Integer): Boolean;
var
  LColumn, LRow, LIndex: Integer;
begin
  Result := False;
  if FType = INV_HAND then
  begin
    for LColumn := 0 to INV_HAND_WIDTH - 1 do
      for LRow := 0 to INV_HAND_HEIGHT - 1 do
        if (AMouseX >= FX + LColumn * INV_SLOT_WIDTH) and (AMouseX < FX + (LColumn + 1) * INV_SLOT_WIDTH) and
          (AMouseY >= FY + LRow * INV_SLOT_HEIGHT) and (AMouseY < FY + (LRow + 1) * INV_SLOT_HEIGHT) then
          Exit(True);
  end
  else if FType = INV_GROUND then
    Result := (AMouseX >= FX) and (AMouseX < 320) and (AMouseY >= FY) and (AMouseY < 200)
  else
    for LIndex := 0 to High(FSlots) do
      if (AMouseX >= FX + FSlots[LIndex].X * INV_SLOT_WIDTH) and
        (AMouseX < FX + (FSlots[LIndex].X + 1) * INV_SLOT_WIDTH) and
        (AMouseY >= FY + FSlots[LIndex].Y * INV_SLOT_HEIGHT) and
        (AMouseY < FY + (FSlots[LIndex].Y + 1) * INV_SLOT_HEIGHT) then
        Exit(True);
end;

function TXcomRuleInventory.HasCostFor(const AId: string): Boolean;
begin
  Result := FCosts.ContainsKey(AId);
end;

function TXcomRuleInventory.GetCost(const ASlot: TXcomRuleInventory): Integer;
begin
  if ASlot = Self then
    Exit(0);
  // the C++ dereferences end() when the section has no cost for the other one: an error here
  if not FCosts.TryGetValue(ASlot.Id, Result) then
    raise EXcomModException.CreateFmt('Xcom: the inventory %s has no cost for %s', [FId, ASlot.Id]);
end;

end.
