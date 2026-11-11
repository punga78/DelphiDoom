{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - CraftWeaponsState of OpenXcom (the      }
{  armament that can be fitted to a craft)                                      }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.CraftWeaponsState;

interface

uses
  System.SysUtils, System.Math, System.Generics.Collections, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window,
  DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.TextList, DelphiDoom.XcomSave.Base,
  DelphiDoom.XcomMod.RuleCraftWeapon;

type
  /// <summary>
  ///   Picks the weapon of one of the slots of a craft among those whose launcher is in the stores (or none): the
  ///   weapon that is on the craft goes back to the stores with its clips, the new one is fitted without ammunition
  ///   and the craft goes to rearming
  /// </summary>
  TXcomCraftWeaponsState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FCraftId: Integer;
    FWeaponId: Integer;
    /// <summary>The weapons of the rows; nil for the row of none</summary>
    FWeapons: TList<TXcomRuleCraftWeapon>;
    FWindow: TXcomWindow;
    FBtnCancel: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtArmament: TXcomText;
    FTxtQuantity: TXcomText;
    FTxtAmmunition: TXcomText;
    FLstWeapons: TXcomTextList;
    procedure CancelClick(AAction: TXcomAction);
    procedure WeaponsClick(AAction: TXcomAction);
  public
    /// <param name="ABase">The base (not owned)</param>
    /// <param name="ACraftId">The index of the craft in the list of the base</param>
    /// <param name="AWeaponId">The slot of the weapon on the craft</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase; ACraftId, AWeaponId: Integer);
    destructor Destroy; override;
    property List: TXcomTextList read FLstWeapons;
  end;

implementation

uses
  DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.CraftWeapon, DelphiDoom.XcomSave.RuleAdapters,
  DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.RuleItem;

{ TXcomCraftWeaponsState }

constructor TXcomCraftWeaponsState.Create(AHost: TXcomStateHost; ABase: TXcomBase; ACraftId, AWeaponId: Integer);
var
  LRuleset: TXcomRuleset;
  LName, LAmmunition: string;
  LWeapon: TXcomRuleCraftWeapon;
begin
  inherited Create(AHost);
  FBase := ABase;
  FCraftId := ACraftId;
  FWeaponId := AWeaponId;
  FWeapons := TList<TXcomRuleCraftWeapon>.Create;
  LRuleset := TXcomStrategy.Ruleset(AHost);
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 220, 160, 50, 20, wpBoth);
  FBtnCancel := TXcomTextButton.Create(140, 16, 90, 156);
  FTxtTitle := TXcomText.Create(208, 17, 56, 28);
  FTxtArmament := TXcomText.Create(76, 9, 66, 52);
  FTxtQuantity := TXcomText.Create(50, 9, 140, 52);
  FTxtAmmunition := TXcomText.Create(68, 17, 200, 44);
  FLstWeapons := TXcomTextList.Create(Host.Options, Host.Clock, 188, 80, 58, 68);
  SetInterface('craftWeapons');
  Add(FWindow, 'window', 'craftWeapons');
  Add(FBtnCancel, 'button', 'craftWeapons');
  Add(FTxtTitle, 'text', 'craftWeapons');
  Add(FTxtArmament, 'text', 'craftWeapons');
  Add(FTxtQuantity, 'text', 'craftWeapons');
  Add(FTxtAmmunition, 'text', 'craftWeapons');
  Add(FLstWeapons, 'list', 'craftWeapons');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK14.SCR'));
  FBtnCancel.SetText(Tr('STR_CANCEL_UC'));
  FBtnCancel.OnMouseClick(CancelClick);
  FBtnCancel.OnKeyboardPress(CancelClick, Host.Options.KeyCancel);
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetText(Tr('STR_SELECT_ARMAMENT'));
  FTxtArmament.SetText(Tr('STR_ARMAMENT'));
  FTxtQuantity.SetText(Tr('STR_QUANTITY_UC'));
  FTxtAmmunition.SetText(Tr('STR_AMMUNITION_AVAILABLE'));
  FTxtAmmunition.SetWordWrap(True);
  FTxtAmmunition.SetVerticalAlign(vaBottom);
  FLstWeapons.SetColumns([94, 50, 36]);
  FLstWeapons.SetSelectable(True);
  FLstWeapons.SetBackground(FWindow);
  FLstWeapons.SetMargin(8);
  FLstWeapons.AddRow([Tr('STR_NONE_UC').Text]);
  FWeapons.Add(nil);
  for LName in LRuleset.CraftWeapons.Index do
  begin
    LWeapon := LRuleset.CraftWeapons.Find(LName);
    if FBase.StorageItems.GetItem(LWeapon.LauncherItem) > 0 then
    begin
      FWeapons.Add(LWeapon);
      if LWeapon.ClipItem <> '' then
        LAmmunition := IntToStr(FBase.StorageItems.GetItem(LWeapon.ClipItem))
      else
        LAmmunition := Tr('STR_NOT_AVAILABLE').Text;
      FLstWeapons.AddRow([Tr(LWeapon.WeaponType).Text, IntToStr(FBase.StorageItems.GetItem(LWeapon.LauncherItem)),
        LAmmunition]);
    end;
  end;
  FLstWeapons.OnMouseClick(WeaponsClick);
end;

destructor TXcomCraftWeaponsState.Destroy;
begin
  inherited Destroy;
  FWeapons.Free;
end;

procedure TXcomCraftWeaponsState.CancelClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomCraftWeaponsState.WeaponsClick(AAction: TXcomAction);
var
  LRuleset: TXcomRuleset;
  LCraft: TXcomCraft;
  LCurrent, LNew: TXcomCraftWeapon;
  LCurrentRule: TXcomRuleCraftWeapon;
  LClip: TXcomRuleItem;
  LClips: Integer;
  LSelected: TXcomRuleCraftWeapon;
begin
  LRuleset := TXcomStrategy.Ruleset(Host);
  LCraft := FBase.Crafts[FCraftId];
  LCurrent := LCraft.Weapons[FWeaponId];
  // the weapon that is on the craft goes back to the stores
  if Assigned(LCurrent) then
  begin
    LCurrentRule := LRuleset.CraftWeapons.Find(LCurrent.Rules.WeaponType);
    FBase.StorageItems.AddItem(LCurrentRule.LauncherItem);
    // getClipsLoaded
    LClip := LRuleset.Items.Find(LCurrentRule.ClipItem);
    if Assigned(LClip) and (LClip.ClipSize > 0) then
      LClips := Floor(LCurrent.Ammo / LClip.ClipSize)
    else
      LClips := Floor(LCurrent.Ammo / LCurrent.Rules.RearmRate);
    FBase.StorageItems.AddItem(LCurrentRule.ClipItem, LClips);
    // the list owns the weapons: a nil frees it
    LCraft.Weapons[FWeaponId] := nil;
  end;
  LSelected := FWeapons[FLstWeapons.GetSelectedRow];
  if Assigned(LSelected) then
  begin
    LNew := TXcomCraftWeapon.Create(TXcomCraftWeaponRuleAdapter.Create(LSelected), 0);
    LNew.Rearming := True;
    FBase.StorageItems.RemoveItem(LSelected.LauncherItem);
    LCraft.Weapons[FWeaponId] := LNew;
    if LCraft.Status = 'STR_READY' then
      LCraft.Status := 'STR_REARMING';
  end;
  Host.PopState;
end;

end.
