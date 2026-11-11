{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - DogfightErrorState of OpenXcom (a craft  }
{  cannot engage a UFO)                                                         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.DogfightErrorState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomSave.Craft;

type
  /// <summary>Continue the pursuit, or send the craft back to its base</summary>
  TXcomDogfightErrorState = class(TXcomState)
  strict private
    FCraft: TXcomCraft;
    FWindow: TXcomWindow;
    FBtnIntercept: TXcomTextButton;
    FBtnBase: TXcomTextButton;
    FTxtCraft: TXcomText;
    FTxtMessage: TXcomText;
    procedure InterceptClick(AAction: TXcomAction);
    procedure BaseClick(AAction: TXcomAction);
  public
    /// <param name="ACraft">The craft (not owned)</param>
    /// <param name="ACraftName">Its name in the language</param>
    /// <param name="AMessage">The reason, already in the language</param>
    constructor Create(AHost: TXcomStateHost; ACraft: TXcomCraft; const ACraftName, AMessage: string);
  end;

implementation

{ TXcomDogfightErrorState }

constructor TXcomDogfightErrorState.Create(AHost: TXcomStateHost; ACraft: TXcomCraft; const ACraftName,
  AMessage: string);
begin
  inherited Create(AHost);
  FCraft := ACraft;
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 208, 120, 24, 48, wpBoth);
  FBtnIntercept := TXcomTextButton.Create(180, 12, 38, 128);
  FBtnBase := TXcomTextButton.Create(180, 12, 38, 144);
  FTxtCraft := TXcomText.Create(198, 16, 29, 63);
  FTxtMessage := TXcomText.Create(198, 20, 29, 94);
  SetInterface('dogfightInfo');
  Add(FWindow, 'window', 'dogfightInfo');
  Add(FBtnIntercept, 'button', 'dogfightInfo');
  Add(FBtnBase, 'button', 'dogfightInfo');
  Add(FTxtCraft, 'text', 'dogfightInfo');
  Add(FTxtMessage, 'text', 'dogfightInfo');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK15.SCR'));
  FBtnIntercept.SetText(Tr('STR_CONTINUE_INTERCEPTION_PURSUIT'));
  FBtnIntercept.OnMouseClick(InterceptClick);
  FBtnIntercept.OnKeyboardPress(InterceptClick, Host.Options.KeyCancel);
  FBtnBase.SetText(Tr('STR_RETURN_TO_BASE'));
  FBtnBase.OnMouseClick(BaseClick);
  FBtnBase.OnKeyboardPress(BaseClick, Host.Options.KeyOk);
  FTxtCraft.SetAlign(haCenter);
  FTxtCraft.SetBig;
  FTxtCraft.SetText(ACraftName);
  FTxtMessage.SetAlign(haCenter);
  FTxtMessage.SetWordWrap(True);
  FTxtMessage.SetText(AMessage);
end;

procedure TXcomDogfightErrorState.InterceptClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomDogfightErrorState.BaseClick(AAction: TXcomAction);
begin
  FCraft.ReturnToBase;
  Host.PopState;
end;

end.
