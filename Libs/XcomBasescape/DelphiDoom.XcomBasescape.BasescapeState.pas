{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - BasescapeState of OpenXcom (the main    }
{  screen of a base)                                                            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.BasescapeState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.BaseFacility, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.TextEdit, DelphiDoom.XcomGeoscape.Globe,
  DelphiDoom.XcomBasescape.BaseView, DelphiDoom.XcomBasescape.MiniBaseView,
  DelphiDoom.XcomGeoscape.BaseNavigator.Intf;

type
  /// <summary>
  ///   A base: the grid of its facilities, the little maps of all the bases, the name that can be edited, the
  ///   region, the funds and the buttons of the screens of the base. The screens come from the navigator; the saved
  ///   game, the globe and the bases are not owned
  /// </summary>
  TXcomBasescapeState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FGlobe: TXcomGlobe;
    FSave: TXcomSavedGame;
    FRuleset: TXcomRuleset;
    FNavigator: IXcomBasescapeNavigator;
    FTxtFacility: TXcomText;
    FView: TXcomBaseView;
    FMini: TXcomMiniBaseView;
    FEdtBase: TXcomTextEdit;
    FTxtLocation: TXcomText;
    FTxtFunds: TXcomText;
    FBtnNewBase: TXcomTextButton;
    FBtnBaseInfo: TXcomTextButton;
    FBtnSoldiers: TXcomTextButton;
    FBtnCrafts: TXcomTextButton;
    FBtnFacilities: TXcomTextButton;
    FBtnResearch: TXcomTextButton;
    FBtnManufacture: TXcomTextButton;
    FBtnTransfer: TXcomTextButton;
    FBtnPurchase: TXcomTextButton;
    FBtnSell: TXcomTextButton;
    FBtnGeoscape: TXcomTextButton;
    procedure ConfigureButton(AButton: TXcomTextButton; const AText: string; AScreen: TXcomBaseScreen);
    procedure SetBase(ABase: TXcomBase);
    procedure Open(AScreen: TXcomBaseScreen; AFacility: TXcomBaseFacility = nil);
    procedure ViewLeftClick(AAction: TXcomAction);
    procedure ViewRightClick(AAction: TXcomAction);
    procedure ViewMouseOver(AAction: TXcomAction);
    procedure ViewMouseOut(AAction: TXcomAction);
    procedure MiniClick(AAction: TXcomAction);
    procedure GeoscapeClick(AAction: TXcomAction);
    procedure EditBaseChange(AAction: TXcomAction);
  public
    /// <param name="ABase">The base to show (the first one if it is not among the bases of the saved game)</param>
    /// <param name="ANavigator">nil: the buttons do nothing</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase; AGlobe: TXcomGlobe;
      const ANavigator: IXcomBasescapeNavigator);
    procedure Init; override;
    property Base: TXcomBase read FBase;
    /// <summary>The grid of the base (the screens that change it ask it to redraw)</summary>
    property View: TXcomBaseView read FView;
  end;

implementation

uses
  DelphiDoom.XcomMod.RuleBaseFacility, DelphiDoom.XcomMod.RuleRegion,
  DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Region, DelphiDoom.XcomGeoscape.Strategy,
  DelphiDoom.XcomEngine.Rules.Intf, DelphiDoom.XcomEngine.LocalizedText, DelphiDoom.XcomGeoscape.Funding;

constructor TXcomBasescapeState.Create(AHost: TXcomStateHost; ABase: TXcomBase; AGlobe: TXcomGlobe;
  const ANavigator: IXcomBasescapeNavigator);
begin
  inherited Create(AHost);
  FBase := ABase;
  FGlobe := AGlobe;
  FNavigator := ANavigator;
  FSave := TXcomStrategy.SavedGame(AHost);
  FRuleset := TXcomStrategy.Ruleset(AHost);
  FTxtFacility := TXcomText.Create(192, 9, 0, 0);
  FView := TXcomBaseView.Create(Host.Clock, FRuleset, 192, 192, 0, 8);
  FMini := TXcomMiniBaseView.Create(FRuleset, 128, 16, 192, 41);
  FEdtBase := TXcomTextEdit.Create(Self, 127, 17, 193, 0);
  FTxtLocation := TXcomText.Create(126, 9, 194, 16);
  FTxtFunds := TXcomText.Create(126, 9, 194, 24);
  FBtnNewBase := TXcomTextButton.Create(128, 12, 192, 58);
  FBtnBaseInfo := TXcomTextButton.Create(128, 12, 192, 71);
  FBtnSoldiers := TXcomTextButton.Create(128, 12, 192, 84);
  FBtnCrafts := TXcomTextButton.Create(128, 12, 192, 97);
  FBtnFacilities := TXcomTextButton.Create(128, 12, 192, 110);
  FBtnResearch := TXcomTextButton.Create(128, 12, 192, 123);
  FBtnManufacture := TXcomTextButton.Create(128, 12, 192, 136);
  FBtnTransfer := TXcomTextButton.Create(128, 12, 192, 149);
  FBtnPurchase := TXcomTextButton.Create(128, 12, 192, 162);
  FBtnSell := TXcomTextButton.Create(128, 12, 192, 175);
  FBtnGeoscape := TXcomTextButton.Create(128, 12, 192, 188);
  SetInterface('basescape');
  Add(FView, 'baseView', 'basescape');
  Add(FMini, 'miniBase', 'basescape');
  Add(FTxtFacility, 'textTooltip', 'basescape');
  Add(FEdtBase, 'text1', 'basescape');
  Add(FTxtLocation, 'text2', 'basescape');
  Add(FTxtFunds, 'text3', 'basescape');
  Add(FBtnNewBase, 'button', 'basescape');
  Add(FBtnBaseInfo, 'button', 'basescape');
  Add(FBtnSoldiers, 'button', 'basescape');
  Add(FBtnCrafts, 'button', 'basescape');
  Add(FBtnFacilities, 'button', 'basescape');
  Add(FBtnResearch, 'button', 'basescape');
  Add(FBtnManufacture, 'button', 'basescape');
  Add(FBtnTransfer, 'button', 'basescape');
  Add(FBtnPurchase, 'button', 'basescape');
  Add(FBtnSell, 'button', 'basescape');
  Add(FBtnGeoscape, 'button', 'basescape');
  CenterAllSurfaces;
  FView.SetTexture(TXcomStrategy.Rules(AHost).GetSurfaceSet('BASEBITS.PCK'));
  FView.OnMouseClick(ViewLeftClick, XCOM_BUTTON_LEFT);
  FView.OnMouseClick(ViewRightClick, XCOM_BUTTON_RIGHT);
  FView.OnMouseOver(ViewMouseOver);
  FView.OnMouseOut(ViewMouseOut);
  FMini.SetTexture(TXcomStrategy.Rules(AHost).GetSurfaceSet('BASEBITS.PCK'));
  FMini.SetBases(FSave.Bases);
  FMini.OnMouseClick(MiniClick);
  FEdtBase.SetBig;
  FEdtBase.OnChange(EditBaseChange);
  ConfigureButton(FBtnNewBase, 'STR_BUILD_NEW_BASE_UC', bsNewBase);
  ConfigureButton(FBtnBaseInfo, 'STR_BASE_INFORMATION', bsBaseInfo);
  ConfigureButton(FBtnSoldiers, 'STR_SOLDIERS_UC', bsSoldiers);
  ConfigureButton(FBtnCrafts, 'STR_EQUIP_CRAFT', bsCrafts);
  ConfigureButton(FBtnFacilities, 'STR_BUILD_FACILITIES', bsFacilities);
  ConfigureButton(FBtnResearch, 'STR_RESEARCH', bsResearch);
  ConfigureButton(FBtnManufacture, 'STR_MANUFACTURE', bsManufacture);
  ConfigureButton(FBtnTransfer, 'STR_TRANSFER_UC', bsTransfer);
  ConfigureButton(FBtnPurchase, 'STR_PURCHASE_RECRUIT', bsPurchase);
  ConfigureButton(FBtnSell, 'STR_SELL_SACK_UC', bsSell);
  FBtnGeoscape.SetText(Tr('STR_GEOSCAPE_UC'));
  FBtnGeoscape.OnMouseClick(GeoscapeClick);
  FBtnGeoscape.OnKeyboardPress(GeoscapeClick, Host.Options.KeyCancel);
end;

procedure TXcomBasescapeState.ConfigureButton(AButton: TXcomTextButton; const AText: string; AScreen: TXcomBaseScreen);
begin
  AButton.SetText(Tr(AText));
  AButton.OnMouseClick(
    procedure(AAction: TXcomAction)
    begin
      Open(AScreen);
    end);
end;

procedure TXcomBasescapeState.Open(AScreen: TXcomBaseScreen; AFacility: TXcomBaseFacility);
begin
  if Assigned(FNavigator) then
    FNavigator.Open(AScreen, FBase, AFacility, Self);
end;

procedure TXcomBasescapeState.SetBase(ABase: TXcomBase);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FSave.Bases.Count - 1 do
    if FSave.Bases[LIndex] = ABase then
    begin
      FBase := ABase;
      FMini.SetSelectedBase(LIndex);
      Exit;
    end;
  if FSave.Bases.Count > 0 then
  begin
    FBase := FSave.Bases.First;
    FMini.SetSelectedBase(0);
  end;
end;

procedure TXcomBasescapeState.Init;
var
  LRegion: TXcomRegion;
  LText: TXcomLocalizedText;
begin
  inherited Init;
  SetBase(FBase);
  FView.SetBase(FBase);
  FMini.Draw;
  FEdtBase.SetText(FBase.Name);
  for LRegion in FSave.Regions do
    if LRegion.Rules.IsInside(FBase.Longitude, FBase.Latitude) then
    begin
      FTxtLocation.SetText(Tr(LRegion.Rules.RegionType));
      Break;
    end;
  LText := Tr('STR_FUNDS');
  LText := LText.Arg(TXcomFunding.Format(FSave.Funds));
  FTxtFunds.SetText(LText);
  FBtnNewBase.Visible := FSave.Bases.Count < TXcomMiniBaseView.MAX_BASES;
end;

procedure TXcomBasescapeState.ViewLeftClick(AAction: TXcomAction);
begin
  if FView.SelectedFacility <> nil then
    Open(bsDismantle, FView.SelectedFacility);
end;

procedure TXcomBasescapeState.ViewRightClick(AAction: TXcomAction);
var
  LFacility: TXcomBaseFacility;
  LRule: TXcomRuleBaseFacility;
begin
  LFacility := FView.SelectedFacility;
  if not Assigned(LFacility) then
  begin
    Open(bsBaseInfo);
    Exit;
  end;
  LRule := FRuleset.Facilities.Find(LFacility.Rules.FacilityType);
  if LRule.Crafts > 0 then
  begin
    if FView.CraftOf(LFacility) = nil then
      Open(bsCrafts)
    else
      Open(bsCraftInfo, LFacility);
  end
  else if LRule.Storage > 0 then
    Open(bsSell)
  else if LRule.Personnel > 0 then
    Open(bsSoldiers)
  else if LRule.Laboratories > 0 then
    Open(bsResearch)
  else if LRule.Workshops > 0 then
    Open(bsManufacture)
  else if LRule.Aliens > 0 then
    Open(bsAlienContainment)
  else if LRule.IsLift or (LRule.RadarRange > 0) then
    Host.PopState;
  // the psi laboratories (Options::anytimePsiTraining, off by default) are not ported
end;

procedure TXcomBasescapeState.ViewMouseOver(AAction: TXcomAction);
var
  LFacility: TXcomBaseFacility;
  LRule: TXcomRuleBaseFacility;
  LText: string;
  LCraftText: TXcomLocalizedText;
begin
  LFacility := FView.SelectedFacility;
  LText := '';
  if Assigned(LFacility) then
  begin
    LRule := FRuleset.Facilities.Find(LFacility.Rules.FacilityType);
    LText := Tr(LRule.FacilityType);
    if (LRule.Crafts <> 0) and (LFacility.BuildTime = 0) and (FView.CraftOf(LFacility) <> nil) then
    begin
      LCraftText := Tr('STR_CRAFT_');
      LCraftText := LCraftText.Arg(FView.CraftOf(LFacility).Name);
      LText := LText + ' ' + LCraftText.Text;
    end;
  end;
  FTxtFacility.SetText(LText);
end;

procedure TXcomBasescapeState.ViewMouseOut(AAction: TXcomAction);
begin
  FTxtFacility.SetText('');
end;

procedure TXcomBasescapeState.MiniClick(AAction: TXcomAction);
var
  LBase: Integer;
begin
  LBase := FMini.HoveredBase;
  if (LBase >= 0) and (LBase < FSave.Bases.Count) then
  begin
    FBase := FSave.Bases[LBase];
    Init;
  end;
end;

procedure TXcomBasescapeState.GeoscapeClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomBasescapeState.EditBaseChange(AAction: TXcomAction);
begin
  FBase.Name := FEdtBase.GetText;
end;

end.
