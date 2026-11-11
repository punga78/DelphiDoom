{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - ModConfirmExtendedState of OpenXcom (a mod   }
{  that asks for an extended engine: switch it on anyway?)                      }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMenu.ModConfirmExtendedState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Types,
  DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton;

type
  /// <summary>
  ///   A popup over the list of the mods: the mod (or the master) that was chosen needs the engine AEngine.
  ///   Yes closes the popup and calls AYes (ModListState::changeMasterMod or toggleMod), No closes it and calls
  ///   ANo (revertMasterMod for a master, nothing for a mod). The C++ keeps a pointer to the list; here two
  ///   callbacks
  /// </summary>
  TXcomModConfirmExtendedState = class(TXcomState)
  strict private
    FYes: TProc;
    FNo: TProc;
    FWindow: TXcomWindow;
    FBtnYes: TXcomTextButton;
    FBtnNo: TXcomTextButton;
    FTxtTitle: TXcomText;
    procedure YesClick(AAction: TXcomAction);
    procedure NoClick(AAction: TXcomAction);
  public
    constructor Create(AHost: TXcomStateHost; const AEngine: string; const AYes: TProc; const ANo: TProc = nil);
    property YesButton: TXcomTextButton read FBtnYes;
    property NoButton: TXcomTextButton read FBtnNo;
    property Title: TXcomText read FTxtTitle;
  end;

implementation

uses
  DelphiDoom.XcomEngine.LocalizedText;

constructor TXcomModConfirmExtendedState.Create(AHost: TXcomStateHost; const AEngine: string; const AYes, ANo: TProc);
var
  LQuestion: TXcomLocalizedText;
begin
  inherited Create(AHost);
  FYes := AYes;
  FNo := ANo;
  // _screen = false
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 256, 100, 32, 50, wpBoth);
  FBtnYes := TXcomTextButton.Create(60, 18, 60, 122);
  FBtnNo := TXcomTextButton.Create(60, 18, 200, 122);
  FTxtTitle := TXcomText.Create(246, 50, 37, 64);
  SetInterface('optionsMenu');
  Add(FWindow, 'confirmDefaults', 'optionsMenu');
  Add(FBtnYes, 'confirmDefaults', 'optionsMenu');
  Add(FBtnNo, 'confirmDefaults', 'optionsMenu');
  Add(FTxtTitle, 'confirmDefaults', 'optionsMenu');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK01.SCR'));
  FBtnYes.SetText(Tr('STR_YES'));
  FBtnYes.OnMouseClick(YesClick);
  FBtnNo.SetText(Tr('STR_NO'));
  FBtnNo.OnMouseClick(NoClick);
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetBig;
  FTxtTitle.SetWordWrap(True);
  LQuestion := Tr('STR_OXCE_REQUIRED_QUESTION');
  FTxtTitle.SetText(LQuestion.Arg(AEngine).Text);
end;

procedure TXcomModConfirmExtendedState.YesClick(AAction: TXcomAction);
var
  LYes: TProc;
begin
  LYes := FYes;
  Host.PopState;
  if Assigned(LYes) then
    LYes();
end;

procedure TXcomModConfirmExtendedState.NoClick(AAction: TXcomAction);
var
  LNo: TProc;
begin
  LNo := FNo;
  Host.PopState;
  if Assigned(LNo) then
    LNo();
end;

end.
