{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape states library - MedikitState of OpenXcom (the  }
{  medi-kit: heal a wound, stimulant, pain killer)                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattleStates.MedikitState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.Widget,
  DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.Action, DelphiDoom.XcomBattleStates.Session.Intf,
  DelphiDoom.XcomBattleStates.MedikitView;

type
  /// <summary>
  ///   The medi-kit of an action used on a unit: the frame MEDIBORD.PCK, the body of the target, the three buttons
  ///   (pain killer, stimulant, heal) with the doses left. Every use costs the time units of the action; without
  ///   enough of them the screen closes and the action carries the warning. The action, its actor, its item and the
  ///   target belong to the battle. Not ported: Options::maximizeInfoScreens
  /// </summary>
  TXcomMedikitState = class(TXcomState)
  strict private
    FSession: IXcomBattleSession;
    FTargetUnit: TXcomBattleUnit;
    FAction: TXcomBattleAction;
    FUnit: TXcomBattleUnit;
    FItem: TXcomBattleItem;
    FTimeUnits: Integer;
    FRevivedTarget: Boolean;
    FBackground: TXcomWidget;
    FMedikitView: TXcomMedikitView;
    FPartText: TXcomText;
    FWoundText: TXcomText;
    FPainKillerText: TXcomText;
    FStimulantText: TXcomText;
    FHealText: TXcomText;
    FEndButton: TXcomInteractiveSurface;
    FHealButton: TXcomInteractiveSurface;
    FStimulantButton: TXcomInteractiveSurface;
    FPainKillerButton: TXcomInteractiveSurface;
    function NewTitle(AY: Integer; const ATitle: string): TXcomText;
    function NewValue(AY: Integer): TXcomText;
    procedure CountRevival;
    function TargetRevived: Boolean;
    procedure Update;
  public
    /// <param name="ASession">The battle: its pictures and its depth</param>
    /// <param name="ATargetUnit">The wounded unit</param>
    /// <param name="AAction">The healing action: actor, medi-kit and cost in time units</param>
    constructor Create(AHost: TXcomStateHost; const ASession: IXcomBattleSession; ATargetUnit: TXcomBattleUnit;
      AAction: TXcomBattleAction);
    procedure Init; override;
    /// <summary>handle: the right button closes the screen</summary>
    procedure Handle(AAction: TXcomAction); override;
    procedure EndClick(AAction: TXcomAction);
    procedure HealClick(AAction: TXcomAction);
    procedure StimulantClick(AAction: TXcomAction);
    procedure PainKillerClick(AAction: TXcomAction);
    property MedikitView: TXcomMedikitView read FMedikitView;
    property EndButton: TXcomInteractiveSurface read FEndButton;
    property HealButton: TXcomInteractiveSurface read FHealButton;
    property StimulantButton: TXcomInteractiveSurface read FStimulantButton;
    property PainKillerButton: TXcomInteractiveSurface read FPainKillerButton;
    property HealText: TXcomText read FHealText;
    property StimulantText: TXcomText read FStimulantText;
    property PainKillerText: TXcomText read FPainKillerText;
    property PartText: TXcomText read FPartText;
    property WoundText: TXcomText read FWoundText;
  end;

implementation

uses
  DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomEngine.RuleInterface, DelphiDoom.XcomUi.Types,
  DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomBattle.Types;

const
  INTERFACE_NAME = 'medikit';
  // the screen is taller than the medi-kit by more than this: the battlescape stays visible around it
  TALL_SCREEN = 50;
  // Palette::blockOffset(1)
  VALUE_COLOR = 16;
  // Palette::blockOffset(15) + 15
  BLACK = 255;

constructor TXcomMedikitState.Create(AHost: TXcomStateHost; const ASession: IXcomBattleSession;
  ATargetUnit: TXcomBattleUnit; AAction: TXcomBattleAction);
var
  LBorder: TXcomSurface;
  LInterface: TXcomRuleInterface;
  LBody: TXcomInterfaceElement;
begin
  inherited Create(AHost);
  FSession := ASession;
  FTargetUnit := ATargetUnit;
  FAction := AAction;
  FTimeUnits := AAction.TimeUnits;
  FUnit := AAction.Actor;
  FItem := AAction.Weapon;
  FBackground := TXcomWidget.Create(320, 200);
  // SavedBattleGame::setPaletteByDepth
  SetPalette('PAL_BATTLESCAPE', -1);
  SetPalette(ASession.Graphics.Palette(ASession.Battle.Depth), 0, 256);
  ASession.Graphics.SetPalette(@Palette^[0]);
  if Host.Screen.DY > TALL_SCREEN then
  begin
    ToggleScreen;
    FBackground.DrawRect(67, 44, 190, 100, BLACK);
  end;
  FPartText := TXcomText.Create(62, 9, 82, 120);
  FWoundText := TXcomText.Create(14, 9, 145, 120);
  FMedikitView := TXcomMedikitView.Create(52, 58, 95, 60, ASession.Graphics.SurfaceSet('MEDIBITS.DAT'), ATargetUnit,
    FPartText, FWoundText,
    function(const AId: string): string
    begin
      Result := Tr(AId).Text;
    end);
  LInterface := Host.Resources.GetInterface(INTERFACE_NAME);
  if Assigned(LInterface) and LInterface.TryGetElement('body', LBody) then
    FMedikitView.SetBodyColors(LBody.Color, LBody.Color2);
  FEndButton := TXcomInteractiveSurface.Create(20, 20, 220, 140);
  FStimulantButton := TXcomInteractiveSurface.Create(30, 20, 190, 84);
  FPainKillerButton := TXcomInteractiveSurface.Create(30, 20, 190, 48);
  FHealButton := TXcomInteractiveSurface.Create(30, 20, 190, 120);
  FPainKillerText := NewValue(52);
  FStimulantText := NewValue(88);
  FHealText := NewValue(124);
  Add(FBackground);
  Add(FMedikitView, 'body', INTERFACE_NAME, FBackground);
  Add(FEndButton, 'buttonEnd', INTERFACE_NAME, FBackground);
  Add(NewTitle(37, Tr('STR_PAIN_KILLER').Text), 'textPK', INTERFACE_NAME, FBackground);
  Add(NewTitle(73, Tr('STR_STIMULANT').Text), 'textStim', INTERFACE_NAME, FBackground);
  Add(NewTitle(109, Tr('STR_HEAL').Text), 'textHeal', INTERFACE_NAME, FBackground);
  Add(FHealButton, 'buttonHeal', INTERFACE_NAME, FBackground);
  Add(FStimulantButton, 'buttonStim', INTERFACE_NAME, FBackground);
  Add(FPainKillerButton, 'buttonPK', INTERFACE_NAME, FBackground);
  Add(FPainKillerText, 'numPK', INTERFACE_NAME, FBackground);
  Add(FStimulantText, 'numStim', INTERFACE_NAME, FBackground);
  Add(FHealText, 'numHeal', INTERFACE_NAME, FBackground);
  Add(FPartText, 'textPart', INTERFACE_NAME, FBackground);
  Add(FWoundText, 'numWounds', INTERFACE_NAME, FBackground);
  CenterAllSurfaces;
  LBorder := ASession.Graphics.Surface('MEDIBORD.PCK');
  if Assigned(LBorder) then
    LBorder.Blit(FBackground);
  FPainKillerText.SetBig;
  FStimulantText.SetBig;
  FHealText.SetBig;
  FPartText.SetHighContrast(True);
  FWoundText.SetHighContrast(True);
  FEndButton.OnMouseClick(EndClick);
  FEndButton.OnKeyboardPress(EndClick, Host.Options.KeyCancel);
  FHealButton.OnMouseClick(HealClick);
  FStimulantButton.OnMouseClick(StimulantClick);
  FPainKillerButton.OnMouseClick(PainKillerClick);
  Update;
end;

function TXcomMedikitState.NewTitle(AY: Integer; const ATitle: string): TXcomText;
begin
  // MedikitTitle; the text is set again when the state gives the fonts
  Result := TXcomText.Create(73, 9, 186, AY);
  Result.SetText(ATitle);
  Result.SetHighContrast(True);
  Result.SetAlign(haCenter);
end;

function TXcomMedikitState.NewValue(AY: Integer): TXcomText;
begin
  // MedikitTxt
  Result := TXcomText.Create(33, 17, 220, AY);
  Result.SetColor(VALUE_COLOR);
  Result.SetHighContrast(True);
  Result.SetAlign(haCenter);
end;

procedure TXcomMedikitState.Init;
begin
  inherited Init;
  // State::init, Mod::setPalette: the pictures of the battle follow the palette of the state on screen
  FSession.Graphics.SetPalette(@Palette^[0]);
end;

procedure TXcomMedikitState.Handle(AAction: TXcomAction);
begin
  inherited Handle(AAction);
  if (AAction.Details.Kind = ekMouseDown) and (AAction.Details.Button = XCOM_BUTTON_RIGHT) then
    EndClick(nil);
end;

procedure TXcomMedikitState.EndClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

function TXcomMedikitState.TargetRevived: Boolean;
begin
  Result := (FTargetUnit.Status = STATUS_UNCONSCIOUS) and (FTargetUnit.StunLevel < FTargetUnit.Health) and
    (FTargetUnit.Health > 0);
end;

procedure TXcomMedikitState.CountRevival;
begin
  FTargetUnit.SetTimeUnits(0);
  if FTargetUnit.OriginalFaction = FACTION_PLAYER then
    FAction.Actor.Statistics.RevivedSoldier := FAction.Actor.Statistics.RevivedSoldier + 1
  else if FTargetUnit.OriginalFaction = FACTION_HOSTILE then
    FAction.Actor.Statistics.RevivedHostile := FAction.Actor.Statistics.RevivedHostile + 1
  else
    FAction.Actor.Statistics.RevivedNeutral := FAction.Actor.Statistics.RevivedNeutral + 1;
end;

procedure TXcomMedikitState.HealClick(AAction: TXcomAction);
var
  LRule: TXcomRuleItem;
begin
  if FItem.HealQuantity = 0 then
    Exit;
  LRule := FItem.Rules;
  if not FUnit.SpendTimeUnits(FTimeUnits) then
  begin
    FAction.ResultText := 'STR_NOT_ENOUGH_TIME_UNITS';
    EndClick(nil);
    Exit;
  end;
  FTargetUnit.Heal(FMedikitView.SelectedPart, LRule.WoundRecovery, LRule.HealthRecovery);
  FItem.HealQuantity := FItem.HealQuantity - 1;
  FMedikitView.UpdateSelectedPart;
  FMedikitView.Invalidate;
  Update;
  if TargetRevived then
  begin
    if not FRevivedTarget then
    begin
      CountRevival;
      FRevivedTarget := True;
    end;
    // if the unit has revived and has no more wounds, we quit this screen automatically
    if FTargetUnit.GetFatalWounds = 0 then
      EndClick(nil);
  end;
  FUnit.Statistics.WoundsHealed := FUnit.Statistics.WoundsHealed + 1;
end;

procedure TXcomMedikitState.StimulantClick(AAction: TXcomAction);
var
  LRule: TXcomRuleItem;
begin
  if FItem.StimulantQuantity = 0 then
    Exit;
  LRule := FItem.Rules;
  if not FUnit.SpendTimeUnits(FTimeUnits) then
  begin
    FAction.ResultText := 'STR_NOT_ENOUGH_TIME_UNITS';
    EndClick(nil);
    Exit;
  end;
  FTargetUnit.Stimulant(LRule.EnergyRecovery, LRule.StunRecovery);
  FItem.StimulantQuantity := FItem.StimulantQuantity - 1;
  FAction.Actor.Statistics.AppliedStimulant := FAction.Actor.Statistics.AppliedStimulant + 1;
  Update;
  // if the unit has revived we quit this screen automatically
  if TargetRevived then
  begin
    CountRevival;
    EndClick(nil);
  end;
end;

procedure TXcomMedikitState.PainKillerClick(AAction: TXcomAction);
begin
  if FItem.PainKillerQuantity = 0 then
    Exit;
  if not FUnit.SpendTimeUnits(FTimeUnits) then
  begin
    FAction.ResultText := 'STR_NOT_ENOUGH_TIME_UNITS';
    EndClick(nil);
    Exit;
  end;
  FTargetUnit.PainKillers;
  FItem.PainKillerQuantity := FItem.PainKillerQuantity - 1;
  FAction.Actor.Statistics.AppliedPainKill := FAction.Actor.Statistics.AppliedPainKill + 1;
  Update;
end;

procedure TXcomMedikitState.Update;
begin
  FPainKillerText.SetText(IntToStr(FItem.PainKillerQuantity));
  FStimulantText.SetText(IntToStr(FItem.StimulantQuantity));
  FHealText.SetText(IntToStr(FItem.HealQuantity));
  FMedikitView.Invalidate;
end;

end.