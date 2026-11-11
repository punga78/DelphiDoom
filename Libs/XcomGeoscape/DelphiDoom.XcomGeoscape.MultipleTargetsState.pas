{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - MultipleTargetsState of OpenXcom (a      }
{  click on the globe that hit more than one target)                            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.MultipleTargetsState;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomSave.Target;

type
  /// <summary>
  ///   A list of buttons, one per target, to choose which one the click meant. With a single target there is no
  ///   window: the state closes itself when it starts and shows the popup of that target
  /// </summary>
  TXcomMultipleTargetsState = class(TXcomState)
  strict private
    const
      MARGIN = 10;
      SPACING = 4;
      BUTTON_HEIGHT = 16;
    var
    FTargets: TList<TXcomTarget>;
    FOnTarget: TProc<TXcomTarget>;
    FWindow: TXcomWindow;
    FButtons: TList<TXcomTextButton>;
    procedure CancelClick(AAction: TXcomAction);
    procedure TargetClick(AAction: TXcomAction);
    procedure PopupTarget(ATarget: TXcomTarget);
  public
    /// <param name="ATargets">The targets (the state takes the list, not the targets)</param>
    /// <param name="AOnTarget">Shows the popup of a target (after this state has been closed)</param>
    constructor Create(AHost: TXcomStateHost; const ATargets: TList<TXcomTarget>; const AOnTarget: TProc<TXcomTarget>);
    destructor Destroy; override;
    procedure Init; override;
    property Buttons: TList<TXcomTextButton> read FButtons;
  end;

implementation

uses
  DelphiDoom.XcomGeoscape.TargetNames;

{ TXcomMultipleTargetsState }

constructor TXcomMultipleTargetsState.Create(AHost: TXcomStateHost; const ATargets: TList<TXcomTarget>;
  const AOnTarget: TProc<TXcomTarget>);
var
  LWinHeight, LWinY, LY, LIndex: Integer;
  LButton: TXcomTextButton;
begin
  inherited Create(AHost);
  FTargets := ATargets;
  FOnTarget := AOnTarget;
  FButtons := TList<TXcomTextButton>.Create;
  ToggleScreen;
  if FTargets.Count > 1 then
  begin
    LWinHeight := BUTTON_HEIGHT * FTargets.Count + SPACING * (FTargets.Count - 1) + MARGIN * 2;
    LWinY := (200 - LWinHeight) div 2;
    FWindow := TXcomWindow.Create(Self, 136, LWinHeight, 60, LWinY, wpVertical);
    SetInterface('multipleTargets');
    Add(FWindow, 'window', 'multipleTargets');
    FWindow.SetBackground(Host.Resources.GetSurface('BACK15.SCR'));
    LY := LWinY + MARGIN;
    for LIndex := 0 to FTargets.Count - 1 do
    begin
      LButton := TXcomTextButton.Create(116, BUTTON_HEIGHT, 70, LY);
      LButton.SetText(TXcomTargetNames.Name(FTargets[LIndex], Host.Language));
      LButton.OnMouseClick(TargetClick);
      Add(LButton, 'button', 'multipleTargets');
      FButtons.Add(LButton);
      Inc(LY, LButton.Height + SPACING);
    end;
    FButtons[0].OnKeyboardPress(CancelClick, Host.Options.KeyCancel);
    CenterAllSurfaces;
  end;
end;

destructor TXcomMultipleTargetsState.Destroy;
begin
  inherited Destroy;
  FButtons.Free;
  FTargets.Free;
end;

procedure TXcomMultipleTargetsState.Init;
begin
  if FTargets.Count = 1 then
    PopupTarget(FTargets[0])
  else
    inherited Init;
end;

procedure TXcomMultipleTargetsState.PopupTarget(ATarget: TXcomTarget);
begin
  Host.PopState;
  if Assigned(FOnTarget) then
    FOnTarget(ATarget);
end;

procedure TXcomMultipleTargetsState.CancelClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomMultipleTargetsState.TargetClick(AAction: TXcomAction);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FButtons.Count - 1 do
    if AAction.Sender = FButtons[LIndex] then
    begin
      PopupTarget(FTargets[LIndex]);
      Break;
    end;
end;

end.
