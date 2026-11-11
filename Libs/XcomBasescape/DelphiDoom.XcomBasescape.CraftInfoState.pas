{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - CraftInfoState of OpenXcom (the damage, }
{  fuel, weapons, crew and equipment of a craft)                                }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.CraftInfoState;

interface

uses
  System.SysUtils, System.Math, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Widget, DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window,
  DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.TextEdit, DelphiDoom.XcomSave.Base,
  DelphiDoom.XcomSave.Craft;

type
  /// <summary>
  ///   A craft of a base: its name (editable), damage and fuel with the hours that repair and refuelling need, the
  ///   weapons with their ammunition (and the hours to rearm), the crew and the equipment as icons. The buttons
  ///   open the screens of the weapons, the crew, the equipment and the armor
  /// </summary>
  TXcomCraftInfoState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FCraftId: Integer;
    FCraft: TXcomCraft;
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FBtnW1: TXcomTextButton;
    FBtnW2: TXcomTextButton;
    FBtnCrew: TXcomTextButton;
    FBtnEquip: TXcomTextButton;
    FBtnArmor: TXcomTextButton;
    FEdtCraft: TXcomTextEdit;
    FTxtDamage: TXcomText;
    FTxtFuel: TXcomText;
    FTxtW1Name: TXcomText;
    FTxtW1Ammo: TXcomText;
    FTxtW2Name: TXcomText;
    FTxtW2Ammo: TXcomText;
    FSprite: TXcomWidget;
    FWeapon1: TXcomWidget;
    FWeapon2: TXcomWidget;
    FCrew: TXcomWidget;
    FEquip: TXcomWidget;
    function FormatTime(ATotal: Integer): string;
    procedure ShowWeapon(AIndex: Integer; AWeaponSprite: TXcomWidget; AName, AAmmo: TXcomText);
    procedure OkClick(AAction: TXcomAction);
    procedure Weapon1Click(AAction: TXcomAction);
    procedure Weapon2Click(AAction: TXcomAction);
    procedure CrewClick(AAction: TXcomAction);
    procedure EquipClick(AAction: TXcomAction);
    procedure ArmorClick(AAction: TXcomAction);
    procedure CraftChange(AAction: TXcomAction);
  public
    /// <param name="ABase">The base (not owned)</param>
    /// <param name="ACraftId">The index of the craft in the list of the base</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase; ACraftId: Integer);
    procedure Init; override;
    property Craft: TXcomCraft read FCraft;
  end;

implementation

uses
  DelphiDoom.XcomSave.CraftWeapon, DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomMod.RuleCraftWeapon,
  DelphiDoom.XcomMod.RuleCraft, DelphiDoom.XcomBasescape.Names, DelphiDoom.XcomBasescape.CraftWeaponsState,
  DelphiDoom.XcomBasescape.CraftSoldiersState, DelphiDoom.XcomBasescape.CraftArmorState, DelphiDoom.XcomBasescape.CraftEquipmentState;

{ TXcomCraftInfoState }

constructor TXcomCraftInfoState.Create(AHost: TXcomStateHost; ABase: TXcomBase; ACraftId: Integer);
begin
  inherited Create(AHost);
  FBase := ABase;
  FCraftId := ACraftId;
  if TXcomStrategy.SavedGame(AHost).MonthsPassed <> -1 then
    FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0, wpBoth)
  else
    FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0, wpNone);
  FBtnOk := TXcomTextButton.Create(64, 24, 128, 168);
  FBtnW1 := TXcomTextButton.Create(24, 32, 14, 48);
  FBtnW2 := TXcomTextButton.Create(24, 32, 282, 48);
  FBtnCrew := TXcomTextButton.Create(64, 16, 14, 96);
  FBtnEquip := TXcomTextButton.Create(64, 16, 14, 120);
  FBtnArmor := TXcomTextButton.Create(64, 16, 14, 144);
  FEdtCraft := TXcomTextEdit.Create(Self, 140, 16, 80, 8);
  FTxtDamage := TXcomText.Create(100, 17, 14, 24);
  FTxtFuel := TXcomText.Create(82, 17, 228, 24);
  FTxtW1Name := TXcomText.Create(95, 16, 46, 48);
  FTxtW1Ammo := TXcomText.Create(75, 24, 46, 64);
  FTxtW2Name := TXcomText.Create(95, 16, 184, 48);
  FTxtW2Ammo := TXcomText.Create(75, 24, 204, 64);
  FSprite := TXcomWidget.Create(32, 40, 144, 52);
  FWeapon1 := TXcomWidget.Create(15, 17, 121, 63);
  FWeapon2 := TXcomWidget.Create(15, 17, 184, 63);
  FCrew := TXcomWidget.Create(220, 18, 85, 96);
  FEquip := TXcomWidget.Create(220, 18, 85, 121);
  SetInterface('craftInfo');
  Add(FWindow, 'window', 'craftInfo');
  Add(FBtnOk, 'button', 'craftInfo');
  Add(FBtnW1, 'button', 'craftInfo');
  Add(FBtnW2, 'button', 'craftInfo');
  Add(FBtnCrew, 'button', 'craftInfo');
  Add(FBtnEquip, 'button', 'craftInfo');
  Add(FBtnArmor, 'button', 'craftInfo');
  Add(FEdtCraft, 'text1', 'craftInfo');
  Add(FTxtDamage, 'text1', 'craftInfo');
  Add(FTxtFuel, 'text1', 'craftInfo');
  Add(FTxtW1Name, 'text2', 'craftInfo');
  Add(FTxtW1Ammo, 'text3', 'craftInfo');
  Add(FTxtW2Name, 'text2', 'craftInfo');
  Add(FTxtW2Ammo, 'text3', 'craftInfo');
  Add(FSprite);
  Add(FWeapon1);
  Add(FWeapon2);
  Add(FCrew);
  Add(FEquip);
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK14.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FBtnW1.SetText('1');
  FBtnW1.OnMouseClick(Weapon1Click);
  FBtnW2.SetText('2');
  FBtnW2.OnMouseClick(Weapon2Click);
  FBtnCrew.SetText(Tr('STR_CREW'));
  FBtnCrew.OnMouseClick(CrewClick);
  FBtnEquip.SetText(Tr('STR_EQUIPMENT_UC'));
  FBtnEquip.OnMouseClick(EquipClick);
  FBtnArmor.SetText(Tr('STR_ARMOR'));
  FBtnArmor.OnMouseClick(ArmorClick);
  FEdtCraft.SetBig;
  FEdtCraft.SetAlign(haCenter);
  FEdtCraft.OnChange(CraftChange);
  FTxtW1Name.SetWordWrap(True);
  FTxtW2Name.SetWordWrap(True);
end;

function TXcomCraftInfoState.FormatTime(ATotal: Integer): string;
var
  LDays, LHours: Integer;
begin
  LDays := ATotal div 24;
  LHours := ATotal mod 24;
  Result := #10 + '(';
  if LDays > 0 then
    Result := Result + Tr('STR_DAY', LDays).Text + '/';
  if LHours > 0 then
    Result := Result + Tr('STR_HOUR', LHours).Text;
  Result := Result + ')';
end;

procedure TXcomCraftInfoState.ShowWeapon(AIndex: Integer; AWeaponSprite: TXcomWidget; AName, AAmmo: TXcomText);
var
  LWeapon: TXcomCraftWeapon;
  LRule: TXcomRuleCraftWeapon;
  LText: string;
  LHours: Integer;
begin
  LWeapon := FCraft.Weapons[AIndex];
  AWeaponSprite.Clear;
  if Assigned(LWeapon) then
  begin
    LRule := TXcomStrategy.Ruleset(Host).CraftWeapons.Find(LWeapon.Rules.WeaponType);
    TXcomStrategy.Rules(Host).GetSurfaceSet('BASEBITS.PCK').GetFrame(LRule.Sprite + 48).X := 0;
    TXcomStrategy.Rules(Host).GetSurfaceSet('BASEBITS.PCK').GetFrame(LRule.Sprite + 48).Y := 0;
    TXcomStrategy.Rules(Host).GetSurfaceSet('BASEBITS.PCK').GetFrame(LRule.Sprite + 48).Blit(AWeaponSprite);
    AName.SetText(Chr(XCOM_TOKEN_COLOR_FLIP) + Tr(LWeapon.Rules.WeaponType).Text);
    LText := Tr('STR_AMMO_').Arg(LWeapon.Ammo).Text + #10 + Chr(XCOM_TOKEN_COLOR_FLIP) +
      Tr('STR_MAX').Arg(LWeapon.Rules.AmmoMax).Text;
    if (FCraft.Status = 'STR_REARMING') and (LWeapon.Ammo < LWeapon.Rules.AmmoMax) then
    begin
      LHours := Ceil((LWeapon.Rules.AmmoMax - LWeapon.Ammo) / LWeapon.Rules.RearmRate);
      LText := LText + FormatTime(LHours);
    end;
    AAmmo.SetText(LText);
  end
  else
  begin
    AName.SetText('');
    AAmmo.SetText('');
  end;
end;

procedure TXcomCraftInfoState.Init;
var
  LRules: TXcomRuleCraft;
  LLine: string;
  LHours, LIndex, LX: Integer;
begin
  inherited Init;
  FCraft := FBase.Crafts[FCraftId];
  LRules := FCraft.Rules;
  FEdtCraft.SetText(TXcomBaseNames.CraftName(FCraft, Host.Language));
  FSprite.Clear;
  TXcomStrategy.Rules(Host).GetSurfaceSet('BASEBITS.PCK').GetFrame(LRules.Sprite + 33).X := 0;
  TXcomStrategy.Rules(Host).GetSurfaceSet('BASEBITS.PCK').GetFrame(LRules.Sprite + 33).Y := 0;
  TXcomStrategy.Rules(Host).GetSurfaceSet('BASEBITS.PCK').GetFrame(LRules.Sprite + 33).Blit(FSprite);
  LLine := Tr('STR_DAMAGE_UC_').Arg(IntToStr(FCraft.DamagePercentage) + '%').Text;
  if (FCraft.Status = 'STR_REPAIRS') and (FCraft.Damage > 0) then
  begin
    LHours := Ceil(FCraft.Damage / LRules.RepairRate);
    LLine := LLine + FormatTime(LHours);
  end;
  FTxtDamage.SetText(LLine);
  LLine := Tr('STR_FUEL').Arg(IntToStr(FCraft.FuelPercentage) + '%').Text;
  if (FCraft.Status = 'STR_REFUELLING') and (LRules.MaxFuel - FCraft.Fuel > 0) then
  begin
    LHours := Ceil((LRules.MaxFuel - FCraft.Fuel) / LRules.RefuelRate / 2.0);
    LLine := LLine + FormatTime(LHours);
  end;
  FTxtFuel.SetText(LLine);
  if LRules.Soldiers > 0 then
  begin
    FCrew.Clear;
    FEquip.Clear;
    LX := 0;
    for LIndex := 0 to FCraft.NumSoldiers(FBase.Soldiers) - 1 do
    begin
      TXcomStrategy.Rules(Host).GetSurfaceSet('BASEBITS.PCK').GetFrame(38).Y := 0;
      TXcomStrategy.Rules(Host).GetSurfaceSet('BASEBITS.PCK').GetFrame(38).X := LX;
      TXcomStrategy.Rules(Host).GetSurfaceSet('BASEBITS.PCK').GetFrame(38).Blit(FCrew);
      Inc(LX, 10);
    end;
    LX := 0;
    for LIndex := 0 to FCraft.NumVehicles - 1 do
    begin
      TXcomStrategy.Rules(Host).GetSurfaceSet('BASEBITS.PCK').GetFrame(40).Y := 0;
      TXcomStrategy.Rules(Host).GetSurfaceSet('BASEBITS.PCK').GetFrame(40).X := LX;
      TXcomStrategy.Rules(Host).GetSurfaceSet('BASEBITS.PCK').GetFrame(40).Blit(FEquip);
      Inc(LX, 10);
    end;
    LIndex := 0;
    while LIndex < FCraft.NumEquipment do
    begin
      TXcomStrategy.Rules(Host).GetSurfaceSet('BASEBITS.PCK').GetFrame(39).X := LX;
      TXcomStrategy.Rules(Host).GetSurfaceSet('BASEBITS.PCK').GetFrame(39).Blit(FEquip);
      Inc(LIndex, 4);
      Inc(LX, 10);
    end;
  end
  else
  begin
    FCrew.Visible := False;
    FEquip.Visible := False;
    FBtnCrew.Visible := False;
    FBtnEquip.Visible := False;
    FBtnArmor.Visible := False;
  end;
  if LRules.Weapons > 0 then
    ShowWeapon(0, FWeapon1, FTxtW1Name, FTxtW1Ammo)
  else
  begin
    FWeapon1.Visible := False;
    FBtnW1.Visible := False;
    FTxtW1Name.Visible := False;
    FTxtW1Ammo.Visible := False;
  end;
  if LRules.Weapons > 1 then
    ShowWeapon(1, FWeapon2, FTxtW2Name, FTxtW2Ammo)
  else
  begin
    FWeapon2.Visible := False;
    FBtnW2.Visible := False;
    FTxtW2Name.Visible := False;
    FTxtW2Ammo.Visible := False;
  end;
end;

procedure TXcomCraftInfoState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomCraftInfoState.Weapon1Click(AAction: TXcomAction);
begin
  Host.PushState(TXcomCraftWeaponsState.Create(Host, FBase, FCraftId, 0));
end;

procedure TXcomCraftInfoState.Weapon2Click(AAction: TXcomAction);
begin
  Host.PushState(TXcomCraftWeaponsState.Create(Host, FBase, FCraftId, 1));
end;

procedure TXcomCraftInfoState.CrewClick(AAction: TXcomAction);
begin
  Host.PushState(TXcomCraftSoldiersState.Create(Host, FBase, FCraftId));
end;

procedure TXcomCraftInfoState.EquipClick(AAction: TXcomAction);
begin
  Host.PushState(TXcomCraftEquipmentState.Create(Host, FBase, FCraftId));
end;

procedure TXcomCraftInfoState.ArmorClick(AAction: TXcomAction);
begin
  Host.PushState(TXcomCraftArmorState.Create(Host, FBase, FCraftId));
end;

procedure TXcomCraftInfoState.CraftChange(AAction: TXcomAction);
var
  LDefault: string;
begin
  LDefault := Host.Language.GetString('STR_CRAFTNAME').Arg(Host.Language.GetString(FCraft.TargetType).Text)
    .Arg(FCraft.Id).Text;
  if FEdtCraft.GetText = LDefault then
    FCraft.Name := ''
  else
    FCraft.Name := FEdtCraft.GetText;
  if (AAction.Details^.Key = XCOM_KEY_RETURN) or (AAction.Details^.Key = 271) then
    FEdtCraft.SetText(TXcomBaseNames.CraftName(FCraft, Host.Language));
end;

end.
