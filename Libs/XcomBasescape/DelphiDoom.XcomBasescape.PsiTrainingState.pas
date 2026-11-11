{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - PsiTrainingState of OpenXcom (the       }
{  bases that have psionic laboratories, at the end of the month)               }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.PsiTrainingState;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomSave.Base;

type
  /// <summary>One button for every base with psionic laboratories (at most eight); each opens the allocation</summary>
  TXcomPsiTrainingState = class(TXcomState)
  strict private
    FWindow: TXcomWindow;
    FTxtTitle: TXcomText;
    FBtnOk: TXcomTextButton;
    FBases: TList<TXcomBase>;
    FBaseButtons: TList<TXcomTextButton>;
    procedure OkClick(AAction: TXcomAction);
    procedure BaseClick(AAction: TXcomAction);
  public
    constructor Create(AHost: TXcomStateHost);
    destructor Destroy; override;
    property BaseButtons: TList<TXcomTextButton> read FBaseButtons;
  end;

implementation

uses
  DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomSave.BaseCapacity, DelphiDoom.XcomBasescape.AllocatePsiTrainingState;

{ TXcomPsiTrainingState }

constructor TXcomPsiTrainingState.Create(AHost: TXcomStateHost);
var
  LCapacity: TXcomBaseCapacity;
  LBase: TXcomBase;
  LButton: TXcomTextButton;
begin
  inherited Create(AHost);
  FBases := TList<TXcomBase>.Create;
  FBaseButtons := TList<TXcomTextButton>.Create;
  FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0, wpBoth);
  FTxtTitle := TXcomText.Create(300, 17, 10, 16);
  FBtnOk := TXcomTextButton.Create(160, 14, 80, 174);
  SetInterface('psiTraining');
  Add(FWindow, 'window', 'psiTraining');
  Add(FBtnOk, 'button2', 'psiTraining');
  Add(FTxtTitle, 'text', 'psiTraining');
  FWindow.SetBackground(Host.Resources.GetSurface('BACK01.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetText(Tr('STR_PSIONIC_TRAINING'));
  LCapacity := TXcomBaseCapacity.Create(TXcomStrategy.Ruleset(AHost));
  try
    for LBase in TXcomStrategy.SavedGame(AHost).Bases do
      if LCapacity.AvailablePsiLabs(LBase) > 0 then
      begin
        LButton := TXcomTextButton.Create(160, 14, 80, 40 + 16 * FBaseButtons.Count);
        LButton.OnMouseClick(BaseClick);
        LButton.SetText(LBase.Name);
        Add(LButton, 'button1', 'psiTraining');
        FBases.Add(LBase);
        FBaseButtons.Add(LButton);
        if FBaseButtons.Count >= 8 then
          Break;
      end;
  finally
    LCapacity.Free;
  end;
  CenterAllSurfaces;
end;

destructor TXcomPsiTrainingState.Destroy;
begin
  // the buttons belong to the surfaces of the state
  FBaseButtons.Free;
  FBases.Free;
  inherited Destroy;
end;

procedure TXcomPsiTrainingState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomPsiTrainingState.BaseClick(AAction: TXcomAction);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FBaseButtons.Count - 1 do
    if AAction.Sender = FBaseButtons[LIndex] then
    begin
      Host.PushState(TXcomAllocatePsiTrainingState.Create(Host, FBases[LIndex]));
      Break;
    end;
end;

end.
