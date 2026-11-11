{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - CraftArmorState of OpenXcom (the       }
{  armor of the soldiers, from the craft screen)                                }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.CraftArmorState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomUi.TextList, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Craft;

type
  /// <summary>
  ///   The soldiers of a base with their craft and armor: a left click opens the choice of the armor
  ///   (SoldierArmorState), a right click gives the soldier the armor that was chosen last
  /// </summary>
  TXcomCraftArmorState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FCraft: TXcomCraft;
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtName: TXcomText;
    FTxtCraft: TXcomText;
    FTxtArmor: TXcomText;
    FList: TXcomTextList;
    procedure OkClick(AAction: TXcomAction);
    procedure SoldiersPress(AAction: TXcomAction);
  public
    /// <param name="ABase">The base (not owned)</param>
    /// <param name="ACraft">The index of the craft in the base</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase; ACraft: Integer);
    /// <summary>The soldier armors can change after going into other screens</summary>
    procedure Init; override;
    property List: TXcomTextList read FList;
  end;

implementation

uses
  DelphiDoom.XcomEngine.RuleInterface, DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomMod.Armor,
  DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomSave.Soldier, DelphiDoom.XcomSave.SavedGame,
  DelphiDoom.XcomBasescape.Names, DelphiDoom.XcomBasescape.SoldierArmorState;

{ TXcomCraftArmorState }

constructor TXcomCraftArmorState.Create(AHost: TXcomStateHost; ABase: TXcomBase; ACraft: Integer);
var
  LElement: TXcomInterfaceElement;
  LInterface: TXcomRuleInterface;
  LOtherCraftColor, LColor: Byte;
  LSoldier: TXcomSoldier;
  LRow: Integer;
begin
  inherited Create(AHost);
  FBase := ABase;
  FCraft := FBase.Crafts[ACraft];
  FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0, wpBoth);
  FBtnOk := TXcomTextButton.Create(288, 16, 16, 176);
  FTxtTitle := TXcomText.Create(300, 17, 16, 7);
  FTxtName := TXcomText.Create(114, 9, 16, 32);
  FTxtCraft := TXcomText.Create(76, 9, 130, 32);
  FTxtArmor := TXcomText.Create(100, 9, 199, 32);
  FList := TXcomTextList.Create(Host.Options, Host.Clock, 292, 128, 8, 40);
  SetInterface('craftArmor');
  Add(FWindow, 'window', 'craftArmor');
  Add(FBtnOk, 'button', 'craftArmor');
  Add(FTxtTitle, 'text', 'craftArmor');
  Add(FTxtName, 'text', 'craftArmor');
  Add(FTxtCraft, 'text', 'craftArmor');
  Add(FTxtArmor, 'text', 'craftArmor');
  Add(FList, 'list', 'craftArmor');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK14.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FTxtTitle.SetBig;
  FTxtTitle.SetText(Tr('STR_SELECT_ARMOR'));
  FTxtName.SetText(Tr('STR_NAME_UC'));
  FTxtCraft.SetText(Tr('STR_CRAFT'));
  FTxtArmor.SetText(Tr('STR_ARMOR'));
  FList.SetColumns([114, 69, 101]);
  FList.SetSelectable(True);
  FList.SetBackground(FWindow);
  FList.SetMargin(8);
  FList.SetScrolling(True, 0);
  FList.OnMousePress(SoldiersPress);
  LElement := Default(TXcomInterfaceElement);
  LInterface := Host.Resources.GetInterface('craftArmor');
  if LInterface <> nil then
    LInterface.TryGetElement('otherCraft', LElement);
  LOtherCraftColor := Byte(LElement.Color);
  LRow := 0;
  for LSoldier in FBase.Soldiers do
  begin
    FList.AddRow([LSoldier.Name, TXcomBaseNames.CraftText(LSoldier, Host.Language),
      Tr(LSoldier.Armor.ArmorType).Text]);
    if LSoldier.Craft = FCraft then
      LColor := FList.GetSecondaryColor
    else if Assigned(LSoldier.Craft) then
      LColor := LOtherCraftColor
    else
      LColor := FList.GetColor;
    FList.SetRowColor(LRow, LColor);
    Inc(LRow);
  end;
end;

procedure TXcomCraftArmorState.Init;
var
  LRow: Integer;
  LSoldier: TXcomSoldier;
begin
  inherited Init;
  LRow := 0;
  for LSoldier in FBase.Soldiers do
  begin
    FList.SetCellText(LRow, 2, Tr(LSoldier.Armor.ArmorType).Text);
    Inc(LRow);
  end;
end;

procedure TXcomCraftArmorState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomCraftArmorState.SoldiersPress(AAction: TXcomAction);
var
  LSoldier: TXcomSoldier;
  LSave: TXcomSavedGame;
  LArmor: TXcomArmor;
  LUnit: string;
  LAllowed: Boolean;
  LRow: Integer;
begin
  LRow := FList.GetSelectedRow;
  LSoldier := FBase.Soldiers[LRow];
  if Assigned(LSoldier.Craft) and (TXcomCraft(LSoldier.Craft).Status = 'STR_OUT') then
    Exit;
  if AAction.Details^.Button = XCOM_BUTTON_LEFT then
    Host.PushState(TXcomSoldierArmorState.Create(Host, FBase, LRow))
  else if AAction.Details^.Button = XCOM_BUTTON_RIGHT then
  begin
    LSave := TXcomStrategy.SavedGame(Host);
    LArmor := TXcomStrategy.Ruleset(Host).Armors.Find(LSave.LastSelectedArmor);
    if LArmor = nil then
      Exit;
    LAllowed := Length(LArmor.Units) = 0;
    for LUnit in LArmor.Units do
      if LUnit = LSoldier.Rules.SoldierType then
        LAllowed := True;
    if not LAllowed then
      Exit;
    if LSave.MonthsPassed <> -1 then
    begin
      if (FBase.StorageItems.GetItem(LArmor.StoreItem) > 0) or (LArmor.StoreItem = TXcomArmor.NONE) then
      begin
        if LSoldier.Armor.StoreItem <> TXcomArmor.NONE then
          FBase.StorageItems.AddItem(LSoldier.Armor.StoreItem);
        if LArmor.StoreItem <> TXcomArmor.NONE then
          FBase.StorageItems.RemoveItem(LArmor.StoreItem);
        LSoldier.Armor := LArmor;
        FList.SetCellText(LRow, 2, Tr(LArmor.ArmorType).Text);
      end;
    end
    else
    begin
      LSoldier.Armor := LArmor;
      FList.SetCellText(LRow, 2, Tr(LArmor.ArmorType).Text);
    end;
  end;
end;

end.
