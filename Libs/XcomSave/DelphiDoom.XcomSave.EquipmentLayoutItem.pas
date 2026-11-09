{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - an item of a soldier's equipment      }
{  layout (EquipmentLayoutItem)                                                 }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.EquipmentLayoutItem;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomSave.NodeWriter;

type
  /// <summary>An item a soldier carries in a saved equipment layout: its type, slot, place and ammo</summary>
  TXcomEquipmentLayoutItem = class
  strict private
    FItemType: string;
    FSlot: string;
    FSlotX: Integer;
    FSlotY: Integer;
    FAmmoItem: string;
    FFuseTimer: Integer;
  public
    /// <summary>Makes the item from a YAML node (the missing fields are 0, 0, NONE and -1)</summary>
    constructor Create(const ANode: IYamlNode); overload;
    constructor Create(const AItemType, ASlot: string; ASlotX, ASlotY: Integer; const AAmmoItem: string;
      AFuseTimer: Integer); overload;
    procedure Load(const ANode: IYamlNode);
    /// <summary>Saves the item; the slot position, the ammo and the fuse are only saved when they say something</summary>
    function Save: IYamlNode;
    property ItemType: string read FItemType;
    property Slot: string read FSlot;
    property SlotX: Integer read FSlotX;
    property SlotY: Integer read FSlotY;
    property AmmoItem: string read FAmmoItem;
    property FuseTimer: Integer read FFuseTimer;
  end;

implementation

{ TXcomEquipmentLayoutItem }

constructor TXcomEquipmentLayoutItem.Create(const ANode: IYamlNode);
begin
  inherited Create;
  Load(ANode);
end;

constructor TXcomEquipmentLayoutItem.Create(const AItemType, ASlot: string; ASlotX, ASlotY: Integer;
  const AAmmoItem: string; AFuseTimer: Integer);
begin
  inherited Create;
  FItemType := AItemType;
  FSlot := ASlot;
  FSlotX := ASlotX;
  FSlotY := ASlotY;
  FAmmoItem := AAmmoItem;
  FFuseTimer := AFuseTimer;
end;

procedure TXcomEquipmentLayoutItem.Load(const ANode: IYamlNode);
begin
  FItemType := TXcomNodeReader.ReadString(ANode, 'itemType', FItemType);
  FSlot := TXcomNodeReader.ReadString(ANode, 'slot', FSlot);
  FSlotX := TXcomNodeReader.ReadInteger(ANode, 'slotX', 0);
  FSlotY := TXcomNodeReader.ReadInteger(ANode, 'slotY', 0);
  FAmmoItem := TXcomNodeReader.ReadString(ANode, 'ammoItem', 'NONE');
  FFuseTimer := TXcomNodeReader.ReadInteger(ANode, 'fuseTimer', -1);
end;

function TXcomEquipmentLayoutItem.Save: IYamlNode;
begin
  Result := TXcomNodeWriter.NewMap;
  TXcomNodeWriter.SetString(Result, 'itemType', FItemType);
  TXcomNodeWriter.SetString(Result, 'slot', FSlot);
  if FSlotX <> 0 then
    TXcomNodeWriter.SetInteger(Result, 'slotX', FSlotX);
  if FSlotY <> 0 then
    TXcomNodeWriter.SetInteger(Result, 'slotY', FSlotY);
  if FAmmoItem <> 'NONE' then
    TXcomNodeWriter.SetString(Result, 'ammoItem', FAmmoItem);
  if FFuseTimer >= 0 then
    TXcomNodeWriter.SetInteger(Result, 'fuseTimer', FFuseTimer);
end;

end.
