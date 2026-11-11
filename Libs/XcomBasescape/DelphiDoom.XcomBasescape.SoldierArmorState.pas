{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - SoldierArmorState of OpenXcom (the      }
{  armors a soldier can wear)                                                   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.SoldierArmorState;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.TextList, DelphiDoom.XcomSave.Base, DelphiDoom.XcomMod.Armor;

type
  /// <summary>The armors that the soldier can wear (those in the stores, and the one that needs no item)</summary>
  TXcomSoldierArmorState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FSoldierId: Integer;
    FArmors: TList<TXcomArmor>;
    FWindow: TXcomWindow;
    FBtnCancel: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtType: TXcomText;
    FTxtQuantity: TXcomText;
    FLstArmor: TXcomTextList;
    procedure CancelClick(AAction: TXcomAction);
    procedure ArmorClick(AAction: TXcomAction);
  public
    /// <param name="ABase">The base (not owned)</param>
    /// <param name="ASoldierId">The index of the soldier in the list of the base</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase; ASoldierId: Integer);
    destructor Destroy; override;
    property List: TXcomTextList read FLstArmor;
  end;

implementation

uses
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Soldier, DelphiDoom.XcomMod.Ruleset,
  DelphiDoom.XcomGeoscape.Strategy;

{ TXcomSoldierArmorState }

constructor TXcomSoldierArmorState.Create(AHost: TXcomStateHost; ABase: TXcomBase; ASoldierId: Integer);
var
  LRuleset: TXcomRuleset;
  LSoldier: TXcomSoldier;
  LArmor: TXcomArmor;
  LName, LQuantity: string;
  LFound: Boolean;
  LUnit: string;
begin
  inherited Create(AHost);
  FBase := ABase;
  FSoldierId := ASoldierId;
  FArmors := TList<TXcomArmor>.Create;
  LRuleset := TXcomStrategy.Ruleset(AHost);
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 192, 160, 64, 20, wpBoth);
  FBtnCancel := TXcomTextButton.Create(140, 16, 90, 156);
  FTxtTitle := TXcomText.Create(182, 16, 69, 28);
  FTxtType := TXcomText.Create(90, 9, 80, 52);
  FTxtQuantity := TXcomText.Create(70, 9, 190, 52);
  FLstArmor := TXcomTextList.Create(Host.Options, Host.Clock, 160, 80, 73, 68);
  SetInterface('soldierArmor');
  Add(FWindow, 'window', 'soldierArmor');
  Add(FBtnCancel, 'button', 'soldierArmor');
  Add(FTxtTitle, 'text', 'soldierArmor');
  Add(FTxtType, 'text', 'soldierArmor');
  Add(FTxtQuantity, 'text', 'soldierArmor');
  Add(FLstArmor, 'list', 'soldierArmor');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK14.SCR'));
  FBtnCancel.SetText(Tr('STR_CANCEL_UC'));
  FBtnCancel.OnMouseClick(CancelClick);
  FBtnCancel.OnKeyboardPress(CancelClick, Host.Options.KeyCancel);
  LSoldier := FBase.Soldiers[FSoldierId];
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetText(Tr('STR_SELECT_ARMOR_FOR_SOLDIER').Arg(LSoldier.Name));
  FTxtType.SetText(Tr('STR_TYPE'));
  FTxtQuantity.SetText(Tr('STR_QUANTITY_UC'));
  FLstArmor.SetColumns([132, 21]);
  FLstArmor.SetSelectable(True);
  FLstArmor.SetBackground(FWindow);
  FLstArmor.SetMargin(8);
  for LName in LRuleset.Armors.Index do
  begin
    LArmor := LRuleset.Armors.Find(LName);
    // an armor with a list of units is for those soldiers only
    if Length(LArmor.Units) > 0 then
    begin
      LFound := False;
      for LUnit in LArmor.Units do
        if LUnit = LSoldier.Rules.SoldierType then
          LFound := True;
      if not LFound then
        Continue;
    end;
    if FBase.StorageItems.GetItem(LArmor.StoreItem) > 0 then
    begin
      FArmors.Add(LArmor);
      if TXcomStrategy.SavedGame(AHost).MonthsPassed > -1 then
        LQuantity := IntToStr(FBase.StorageItems.GetItem(LArmor.StoreItem))
      else
        LQuantity := '-';
      FLstArmor.AddRow([Tr(LArmor.ArmorType).Text, LQuantity]);
    end
    else if LArmor.StoreItem = TXcomArmor.NONE then
    begin
      FArmors.Add(LArmor);
      FLstArmor.AddRow([Tr(LArmor.ArmorType).Text]);
    end;
  end;
  FLstArmor.OnMouseClick(ArmorClick);
end;

destructor TXcomSoldierArmorState.Destroy;
begin
  inherited Destroy;
  FArmors.Free;
end;

procedure TXcomSoldierArmorState.CancelClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomSoldierArmorState.ArmorClick(AAction: TXcomAction);
var
  LSoldier: TXcomSoldier;
  LSelected: TXcomArmor;
  LSave: TXcomSavedGame;
begin
  LSoldier := FBase.Soldiers[FSoldierId];
  LSave := TXcomStrategy.SavedGame(Host);
  LSelected := FArmors[FLstArmor.GetSelectedRow];
  if LSave.MonthsPassed <> -1 then
  begin
    if LSoldier.Armor.StoreItem <> TXcomArmor.NONE then
      FBase.StorageItems.AddItem(LSoldier.Armor.StoreItem);
    if LSelected.StoreItem <> TXcomArmor.NONE then
      FBase.StorageItems.RemoveItem(LSelected.StoreItem);
  end;
  LSoldier.Armor := LSelected;
  LSave.LastSelectedArmor := LSelected.ArmorType;
  Host.PopState;
end;

end.
