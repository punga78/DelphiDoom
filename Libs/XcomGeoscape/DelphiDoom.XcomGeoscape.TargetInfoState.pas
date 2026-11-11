{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - TargetInfoState of OpenXcom (the name    }
{  and the followers of a target of the globe)                                  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.TargetInfoState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomUi.TextEdit, DelphiDoom.XcomSave.Target;

type
  /// <summary>
  ///   The window of a waypoint, a mission site or an alien base: its name (that can be changed) and the crafts that
  ///   go to it, with the button to intercept it
  /// </summary>
  TXcomTargetInfoState = class(TXcomState)
  strict private
    FTarget: TXcomTarget;
    FOnIntercept: TProc<TXcomTarget>;
    FWindow: TXcomWindow;
    FBtnIntercept: TXcomTextButton;
    FBtnOk: TXcomTextButton;
    FEdtTitle: TXcomTextEdit;
    FTxtTargetted: TXcomText;
    FTxtFollowers: TXcomText;
    procedure InterceptClick(AAction: TXcomAction);
    procedure OkClick(AAction: TXcomAction);
    procedure TitleChange(AAction: TXcomAction);
  public
    /// <param name="ATarget">The target (not owned)</param>
    /// <param name="AOnIntercept">Pushes InterceptState for the target (nil: nothing)</param>
    constructor Create(AHost: TXcomStateHost; ATarget: TXcomTarget; const AOnIntercept: TProc<TXcomTarget>);
    property Title: TXcomTextEdit read FEdtTitle;
  end;

implementation

uses
  DelphiDoom.XcomGeoscape.TargetNames, DelphiDoom.XcomGeoscape.Keys;

{ TXcomTargetInfoState }

constructor TXcomTargetInfoState.Create(AHost: TXcomStateHost; ATarget: TXcomTarget;
  const AOnIntercept: TProc<TXcomTarget>);
var
  LText: string;
  LFollower: TXcomTarget;
begin
  inherited Create(AHost);
  FTarget := ATarget;
  FOnIntercept := AOnIntercept;
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 192, 120, 32, 40, wpBoth);
  FBtnIntercept := TXcomTextButton.Create(160, 12, 48, 124);
  FBtnOk := TXcomTextButton.Create(160, 12, 48, 140);
  FEdtTitle := TXcomTextEdit.Create(Self, 182, 32, 37, 46);
  FTxtTargetted := TXcomText.Create(182, 9, 37, 78);
  FTxtFollowers := TXcomText.Create(182, 40, 37, 88);
  SetInterface('targetInfo');
  Add(FWindow, 'window', 'targetInfo');
  Add(FBtnIntercept, 'button', 'targetInfo');
  Add(FBtnOk, 'button', 'targetInfo');
  Add(FEdtTitle, 'text2', 'targetInfo');
  Add(FTxtTargetted, 'text1', 'targetInfo');
  Add(FTxtFollowers, 'text1', 'targetInfo');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK01.SCR'));
  FBtnIntercept.SetText(Tr('STR_INTERCEPT'));
  FBtnIntercept.OnMouseClick(InterceptClick);
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FEdtTitle.SetBig;
  FEdtTitle.SetAlign(haCenter);
  FEdtTitle.SetVerticalAlign(vaMiddle);
  FEdtTitle.SetWordWrap(True);
  FEdtTitle.SetText(TXcomTargetNames.Name(FTarget, Host.Language));
  FEdtTitle.OnChange(TitleChange);
  FTxtTargetted.SetAlign(haCenter);
  FTxtTargetted.SetText(Tr('STR_TARGETTED_BY'));
  FTxtFollowers.SetAlign(haCenter);
  LText := '';
  for LFollower in FTarget.Followers do
    LText := LText + TXcomTargetNames.Name(LFollower, Host.Language) + #10;
  FTxtFollowers.SetText(LText);
end;

procedure TXcomTargetInfoState.InterceptClick(AAction: TXcomAction);
begin
  if Assigned(FOnIntercept) then
    FOnIntercept(FTarget);
end;

procedure TXcomTargetInfoState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomTargetInfoState.TitleChange(AAction: TXcomAction);
begin
  // a name equal to the default one is no custom name
  if FEdtTitle.GetText = TXcomTargetNames.DefaultName(FTarget, Host.Language) then
    FTarget.Name := ''
  else
    FTarget.Name := FEdtTitle.GetText;
  if (AAction.Details^.Key = XCOM_KEY_RETURN) or (AAction.Details^.Key = XCOM_KEY_KP_ENTER) then
    FEdtTitle.SetText(TXcomTargetNames.Name(FTarget, Host.Language));
end;

end.
