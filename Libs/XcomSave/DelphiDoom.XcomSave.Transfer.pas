{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - something that is on its way to a      }
{  base: a soldier, craft, items, scientists or engineers (Transfer)            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.Transfer;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomMod.Types,
  DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.RuleSoldier, DelphiDoom.XcomSave.NodeWriter, DelphiDoom.XcomSave.Target,
  DelphiDoom.XcomSave.RulesetRules, DelphiDoom.XcomSave.Soldier, DelphiDoom.XcomSave.Craft,
  DelphiDoom.XcomSave.Settings.Intf;

type
  /// <summary>
  ///   A transfer: what it carries is one of a soldier, a craft, items, scientists or engineers. It owns the
  ///   soldier and the craft until they are delivered (then the base owns them: Deliver takes them). The name
  ///   for the interface is not ported
  /// </summary>
  TXcomTransfer = class
  strict private
    FHours: Integer;
    FSoldier: TXcomSoldier;
    FCraft: TXcomCraft;
    FItemId: string;
    FItemQty: Integer;
    FScientists: Integer;
    FEngineers: Integer;
    FDelivered: Boolean;
  public
    constructor Create(AHours: Integer);
    destructor Destroy; override;
    /// <summary>
    ///   load: false (and the transfer is useless) if the soldier, craft or item type is not in the ruleset
    ///   (the C++ logs it and deletes the transfer). A soldier or craft with no type is EYamlBadConversion
    /// </summary>
    function Load(const ANode: IYamlNode; const ABase: TXcomTarget; const ARuleset: TXcomRuleset;
      const ARules: TXcomRulesetRules): Boolean;
    /// <summary>save: only the first of soldier, craft, items, scientists, engineers that is set</summary>
    function Save(const ASettings: IXcomSaveSettings): IYamlNode;
    property Hours: Integer read FHours write FHours;
    property Soldier: TXcomSoldier read FSoldier write FSoldier;
    property Craft: TXcomCraft read FCraft write FCraft;
    property ItemId: string read FItemId;
    property ItemQty: Integer read FItemQty;
    property Scientists: Integer read FScientists write FScientists;
    property Engineers: Integer read FEngineers write FEngineers;
    property Delivered: Boolean read FDelivered write FDelivered;
    /// <summary>setItems</summary>
    procedure SetItems(const AId: string; AQuantity: Integer);
    /// <summary>
    ///   Marks the transfer delivered and hands out the soldier and the craft: the receiver owns them from now
    ///   on (the C++ does not delete them in the destructor of a delivered transfer)
    /// </summary>
    procedure Deliver(out ASoldier: TXcomSoldier; out ACraft: TXcomCraft);
  end;

implementation

{ TXcomTransfer }

constructor TXcomTransfer.Create(AHours: Integer);
begin
  inherited Create;
  FHours := AHours;
end;

destructor TXcomTransfer.Destroy;
begin
  if not FDelivered then
  begin
    FSoldier.Free;
    FCraft.Free;
  end;
  inherited Destroy;
end;

function TXcomTransfer.Load(const ANode: IYamlNode; const ABase: TXcomTarget; const ARuleset: TXcomRuleset;
  const ARules: TXcomRulesetRules): Boolean;
var
  LField, LTypeNode: IYamlNode;
  LType: string;
  LSoldierRules: TXcomRuleSoldier;
begin
  Result := True;
  FHours := TXcomNodeReader.ReadInteger(ANode, 'hours', FHours);
  LField := TXcomNodeReader.Field(ANode, 'soldier');
  if LField.IsDefined then
  begin
    LTypeNode := TXcomNodeReader.Field(LField, 'type');
    if LTypeNode.IsDefined then
      LType := TXcomNodeReader.TextOf(LTypeNode)
    else
      LType := ARuleset.Soldiers.Index[0];
    LSoldierRules := ARuleset.Soldiers.Find(LType);
    if not Assigned(LSoldierRules) then
      Exit(False);
    FSoldier := TXcomSoldier.Create(LSoldierRules, nil, 0, nil);
    FSoldier.Load(LField, ARuleset);
  end;
  LField := TXcomNodeReader.Field(ANode, 'craft');
  if LField.IsDefined then
  begin
    LTypeNode := TXcomNodeReader.Field(LField, 'type');
    if not LTypeNode.IsDefined then
      raise TXcomNodeReader.BadConversion(LField);
    if not Assigned(ARuleset.Crafts.Find(TXcomNodeReader.TextOf(LTypeNode))) then
      Exit(False);
    FCraft := TXcomCraft.Create(ARuleset.Crafts.Find(TXcomNodeReader.TextOf(LTypeNode)), ABase, 0);
    FCraft.Load(LField, ARules, nil);
  end;
  LField := TXcomNodeReader.Field(ANode, 'itemId');
  if LField.IsDefined then
  begin
    FItemId := TXcomNodeReader.TextOf(LField);
    if not Assigned(ARules.Item(FItemId)) then
      Exit(False);
  end;
  FItemQty := TXcomNodeReader.ReadInteger(ANode, 'itemQty', FItemQty);
  FScientists := TXcomNodeReader.ReadInteger(ANode, 'scientists', FScientists);
  FEngineers := TXcomNodeReader.ReadInteger(ANode, 'engineers', FEngineers);
  FDelivered := TXcomNodeReader.ReadBoolean(ANode, 'delivered', FDelivered);
end;

function TXcomTransfer.Save(const ASettings: IXcomSaveSettings): IYamlNode;
begin
  Result := TXcomNodeWriter.NewMap;
  TXcomNodeWriter.SetInteger(Result, 'hours', FHours);
  if Assigned(FSoldier) then
    TXcomNodeWriter.SetNode(Result, 'soldier', FSoldier.Save(ASettings))
  else if Assigned(FCraft) then
    TXcomNodeWriter.SetNode(Result, 'craft', FCraft.Save)
  else if FItemQty <> 0 then
  begin
    TXcomNodeWriter.SetString(Result, 'itemId', FItemId);
    TXcomNodeWriter.SetInteger(Result, 'itemQty', FItemQty);
  end
  else if FScientists <> 0 then
    TXcomNodeWriter.SetInteger(Result, 'scientists', FScientists)
  else if FEngineers <> 0 then
    TXcomNodeWriter.SetInteger(Result, 'engineers', FEngineers);
  if FDelivered then
    TXcomNodeWriter.SetBoolean(Result, 'delivered', True);
end;

procedure TXcomTransfer.SetItems(const AId: string; AQuantity: Integer);
begin
  FItemId := AId;
  FItemQty := AQuantity;
end;

procedure TXcomTransfer.Deliver(out ASoldier: TXcomSoldier; out ACraft: TXcomCraft);
begin
  FDelivered := True;
  ASoldier := FSoldier;
  ACraft := FCraft;
end;

end.
