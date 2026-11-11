{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - ConfirmLandingState of OpenXcom (a craft }
{  is ready to land near its destination)                                       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.ConfirmLandingState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomSave.Craft;

type
  /// <summary>"Craft ready to land near Target. Begin mission?": Yes starts the mission, No sends the craft home</summary>
  TXcomConfirmLandingState = class(TXcomState)
  strict private
    FCraft: TXcomCraft;
    FOnBegin: TProc<TXcomCraft>;
    FWindow: TXcomWindow;
    FBtnYes: TXcomTextButton;
    FBtnNo: TXcomTextButton;
    FTxtMessage: TXcomText;
    FTxtBegin: TXcomText;
    procedure YesClick(AAction: TXcomAction);
    procedure NoClick(AAction: TXcomAction);
  public
    /// <param name="ACraft">The craft, with a destination (not owned)</param>
    /// <param name="AOnBegin">Starts the battle (the Battlescape is not part of this library; nil: nothing)</param>
    constructor Create(AHost: TXcomStateHost; ACraft: TXcomCraft; const AOnBegin: TProc<TXcomCraft>);
    /// <summary>ConfirmLandingState::init: a craft that goes back to its own base has nothing to confirm</summary>
    procedure Init; override;
  end;

implementation

uses
  DelphiDoom.XcomGeoscape.TargetNames;

{ TXcomConfirmLandingState }

constructor TXcomConfirmLandingState.Create(AHost: TXcomStateHost; ACraft: TXcomCraft;
  const AOnBegin: TProc<TXcomCraft>);
begin
  inherited Create(AHost);
  FCraft := ACraft;
  FOnBegin := AOnBegin;
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 216, 160, 20, 20, wpBoth);
  FBtnYes := TXcomTextButton.Create(80, 20, 40, 150);
  FBtnNo := TXcomTextButton.Create(80, 20, 136, 150);
  FTxtMessage := TXcomText.Create(206, 80, 25, 40);
  FTxtBegin := TXcomText.Create(206, 17, 25, 130);
  SetInterface('confirmLanding');
  Add(FWindow, 'window', 'confirmLanding');
  Add(FBtnYes, 'button', 'confirmLanding');
  Add(FBtnNo, 'button', 'confirmLanding');
  Add(FTxtMessage, 'text', 'confirmLanding');
  Add(FTxtBegin, 'text', 'confirmLanding');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK15.SCR'));
  FBtnYes.SetText(Tr('STR_YES'));
  FBtnYes.OnMouseClick(YesClick);
  FBtnYes.OnKeyboardPress(YesClick, Host.Options.KeyOk);
  FBtnNo.SetText(Tr('STR_NO'));
  FBtnNo.OnMouseClick(NoClick);
  FBtnNo.OnKeyboardPress(NoClick, Host.Options.KeyCancel);
  FTxtMessage.SetBig;
  FTxtMessage.SetAlign(haCenter);
  FTxtMessage.SetWordWrap(True);
  FTxtMessage.SetText(Tr('STR_CRAFT_READY_TO_LAND_NEAR_DESTINATION')
    .Arg(TXcomTargetNames.Name(ACraft, Host.Language))
    .Arg(TXcomTargetNames.Name(ACraft.Destination, Host.Language)));
  FTxtBegin.SetBig;
  FTxtBegin.SetAlign(haCenter);
  FTxtBegin.SetText(Chr(XCOM_TOKEN_COLOR_FLIP) + Tr('STR_BEGIN_MISSION').Text);
end;

procedure TXcomConfirmLandingState.Init;
begin
  inherited Init;
  if FCraft.Destination = FCraft.Base then
    Host.PopState;
end;

procedure TXcomConfirmLandingState.YesClick(AAction: TXcomAction);
begin
  Host.PopState;
  if Assigned(FOnBegin) then
    FOnBegin(FCraft);
end;

procedure TXcomConfirmLandingState.NoClick(AAction: TXcomAction);
begin
  FCraft.ReturnToBase;
  Host.PopState;
end;

end.
