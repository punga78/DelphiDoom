{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - BaseDefenseState of OpenXcom (the        }
{  defenses of a base fire at the UFO that attacks it)                          }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.BaseDefenseState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Timer,
  DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.TextList,
  DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.RuleBaseFacility, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Ufo;

type
  /// <summary>
  ///   "Base under attack": every defense facility of the base fires once at the UFO, one line of the list each
  ///   (name, FIRING, HIT or MISSED), and a grav shield makes them all fire again. OK appears at the end: a UFO that
  ///   survived attacks the base (AOnAttack: GeoscapeState::handleBaseDefense), a destroyed one does not. The base,
  ///   the UFO and the rules of the defenses are not owned
  /// </summary>
  TXcomBaseDefenseState = class(TXcomState)
  strict private
    type
      TAction = (bdaNone, bdaFire, bdaResolve, bdaDestroy, bdaEnd);
    var
      FBase: TXcomBase;
      FUfo: TXcomUfo;
      FRandom: IXcomRandom;
      FDefenses: TArray<TXcomRuleBaseFacility>;
      FOnAttack: TProc;
      FWindow: TXcomWindow;
      FTxtTitle: TXcomText;
      FTxtInit: TXcomText;
      FLstDefenses: TXcomTextList;
      FBtnOk: TXcomTextButton;
      FTimer: TXcomTimer;
      FAction: TAction;
      FRow: Integer;
      FPasses: Integer;
      FGravShields: Integer;
      FAttacks: Integer;
      FThinkCycles: Integer;
      FExplosionCount: Integer;
    procedure NextStep;
    procedure OkClick(AAction: TXcomAction);
  public
    /// <param name="ADefenses">The rules of the built defense facilities of the base, in the order of the base (Base::setupDefenses)</param>
    /// <param name="AGravShields">Base::getGravShields: how many more times the defenses fire</param>
    /// <param name="ARandom">The generator of the game: one percent roll for each shot, one number for the damage of a hit</param>
    /// <param name="AOnAttack">Called after the state was popped when the UFO was not destroyed; can be nil</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase; AUfo: TXcomUfo;
      const ADefenses: TArray<TXcomRuleBaseFacility>; AGravShields: Integer; const ARandom: IXcomRandom;
      const AOnAttack: TProc);
    destructor Destroy; override;
    procedure Think; override;
    property Defenses: TXcomTextList read FLstDefenses;
    property OkButton: TXcomTextButton read FBtnOk;
    property InitText: TXcomText read FTxtInit;
  end;

implementation

const
  STEP_MILLISECONDS = 250;
  FIRE_MILLISECONDS = 333;
  VISIBLE_ROWS = 14;
  GEO_SOUNDS = 'GEO.CAT';

{ TXcomBaseDefenseState }

constructor TXcomBaseDefenseState.Create(AHost: TXcomStateHost; ABase: TXcomBase; AUfo: TXcomUfo;
  const ADefenses: TArray<TXcomRuleBaseFacility>; AGravShields: Integer; const ARandom: IXcomRandom;
  const AOnAttack: TProc);
begin
  inherited Create(AHost);
  FBase := ABase;
  FUfo := AUfo;
  FRandom := ARandom;
  FDefenses := ADefenses;
  FGravShields := AGravShields;
  FOnAttack := AOnAttack;
  FAction := bdaNone;
  FRow := -1;
  FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0);
  FTxtTitle := TXcomText.Create(300, 17, 16, 6);
  FTxtInit := TXcomText.Create(300, 10, 16, 24);
  FLstDefenses := TXcomTextList.Create(Host.Options, Host.Clock, 300, 128, 16, 40);
  FBtnOk := TXcomTextButton.Create(120, 18, 100, 170);
  SetInterface('baseDefense');
  Add(FWindow, 'window', 'baseDefense');
  Add(FBtnOk, 'button', 'baseDefense');
  Add(FTxtTitle, 'text', 'baseDefense');
  Add(FTxtInit, 'text', 'baseDefense');
  Add(FLstDefenses, 'text', 'baseDefense');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK04.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FBtnOk.Visible := False;
  FTxtTitle.SetBig;
  FTxtTitle.SetText(Tr('STR_BASE_UNDER_ATTACK').Arg(FBase.Name));
  FTxtInit.Visible := False;
  FTxtInit.SetText(Tr('STR_BASE_DEFENSES_INITIATED'));
  FLstDefenses.SetColumns([134, 70, 50]);
  FTimer := TXcomTimer.Create(Host.Clock, STEP_MILLISECONDS);
  FTimer.OnTimerState(NextStep);
  FTimer.Start;
end;

destructor TXcomBaseDefenseState.Destroy;
begin
  FTimer.Free;
  inherited Destroy;
end;

procedure TXcomBaseDefenseState.Think;
begin
  inherited Think;
  FTimer.Think(True, False);
end;

procedure TXcomBaseDefenseState.NextStep;
var
  LDefense: TXcomRuleBaseFacility;
  LDamage: Integer;
begin
  if FThinkCycles = -1 then
    Exit;
  Inc(FThinkCycles);
  if FThinkCycles = 1 then
  begin
    FTxtInit.Visible := True;
    Exit;
  end;
  case FAction of
    bdaDestroy:
      begin
        if FExplosionCount = 0 then
        begin
          FLstDefenses.AddRow([Tr('STR_UFO_DESTROYED').Text, ' ', ' ']);
          Inc(FRow);
          if FRow > VISIBLE_ROWS then
            FLstDefenses.ScrollDown(True);
        end;
        Host.PlaySound(GEO_SOUNDS, Host.Resources.Constant('ufoExplode', 11));
        Inc(FExplosionCount);
        if FExplosionCount = 3 then
          FAction := bdaEnd;
        Exit;
      end;
    bdaEnd:
      begin
        FBtnOk.Visible := True;
        FThinkCycles := -1;
        Exit;
      end;
  end;
  if (FAttacks = Length(FDefenses)) and (FPasses = FGravShields) then
  begin
    FAction := bdaEnd;
    Exit;
  end;
  if (FAttacks = Length(FDefenses)) and (FPasses < FGravShields) then
  begin
    FLstDefenses.AddRow([Tr('STR_GRAV_SHIELD_REPELS_UFO').Text, ' ', ' ']);
    if FRow > VISIBLE_ROWS then
      FLstDefenses.ScrollDown(True);
    Inc(FRow);
    Inc(FPasses);
    FAttacks := 0;
    Exit;
  end;
  LDefense := FDefenses[FAttacks];
  case FAction of
    bdaNone:
      begin
        FLstDefenses.AddRow([Tr(LDefense.FacilityType).Text, ' ', ' ']);
        Inc(FRow);
        FAction := bdaFire;
        if FRow > VISIBLE_ROWS then
          FLstDefenses.ScrollDown(True);
      end;
    bdaFire:
      begin
        FLstDefenses.SetCellText(FRow, 1, Tr('STR_FIRING').Text);
        Host.PlaySound(GEO_SOUNDS, LDefense.FireSound);
        FTimer.SetInterval(FIRE_MILLISECONDS);
        FAction := bdaResolve;
      end;
    bdaResolve:
      begin
        // RNG::percent
        if not (FRandom.Generate(0, 99) < LDefense.HitRatio) then
          FLstDefenses.SetCellText(FRow, 2, Tr('STR_MISSED').Text)
        else
        begin
          FLstDefenses.SetCellText(FRow, 2, Tr('STR_HIT').Text);
          Host.PlaySound(GEO_SOUNDS, LDefense.HitSound);
          LDamage := LDefense.DefenseValue;
          FUfo.SetDamage(FUfo.Damage + (LDamage div 2 + FRandom.Generate(0, LDamage)));
        end;
        if FUfo.Status = TXcomUfo.STATUS_DESTROYED then
          FAction := bdaDestroy
        else
          FAction := bdaNone;
        Inc(FAttacks);
        FTimer.SetInterval(STEP_MILLISECONDS);
      end;
  end;
end;

procedure TXcomBaseDefenseState.OkClick(AAction: TXcomAction);
var
  LOnAttack: TProc;
  LDestroyed: Boolean;
begin
  FTimer.Stop;
  // the game frees the state after the pop: what is needed afterwards is kept in locals
  LOnAttack := FOnAttack;
  LDestroyed := FUfo.Status = TXcomUfo.STATUS_DESTROYED;
  Host.PopState;
  if (not LDestroyed) and Assigned(LOnAttack) then
    LOnAttack();
end;

end.
