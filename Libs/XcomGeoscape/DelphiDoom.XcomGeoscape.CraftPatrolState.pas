{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - CraftPatrolState of OpenXcom (a craft    }
{  reached its waypoint)                                                        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.CraftPatrolState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomSave.Craft;

type
  /// <summary>"Triton-1 has reached Waypoint 1. Now patrolling": OK or redirect the craft</summary>
  TXcomCraftPatrolState = class(TXcomState)
  strict private
    FCraft: TXcomCraft;
    FOnRedirect: TProc<TXcomCraft>;
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FBtnRedirect: TXcomTextButton;
    FTxtDestination: TXcomText;
    FTxtPatrolling: TXcomText;
    procedure OkClick(AAction: TXcomAction);
    procedure RedirectClick(AAction: TXcomAction);
  public
    /// <param name="ACraft">The craft (not owned)</param>
    /// <param name="AOnRedirect">Pushes the screen of the craft (GeoscapeCraftState); called after the popup is closed</param>
    constructor Create(AHost: TXcomStateHost; ACraft: TXcomCraft; const AOnRedirect: TProc<TXcomCraft>);
    property Destination: TXcomText read FTxtDestination;
  end;

implementation

uses
  DelphiDoom.XcomGeoscape.TargetNames;

{ TXcomCraftPatrolState }

constructor TXcomCraftPatrolState.Create(AHost: TXcomStateHost; ACraft: TXcomCraft;
  const AOnRedirect: TProc<TXcomCraft>);
begin
  inherited Create(AHost);
  FCraft := ACraft;
  FOnRedirect := AOnRedirect;
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 224, 168, 16, 16, wpBoth);
  FBtnOk := TXcomTextButton.Create(140, 12, 58, 144);
  FBtnRedirect := TXcomTextButton.Create(140, 12, 58, 160);
  FTxtDestination := TXcomText.Create(224, 64, 16, 48);
  FTxtPatrolling := TXcomText.Create(224, 17, 16, 120);
  SetInterface('craftPatrol');
  Add(FWindow, 'window', 'craftPatrol');
  Add(FBtnOk, 'button', 'craftPatrol');
  Add(FBtnRedirect, 'button', 'craftPatrol');
  Add(FTxtDestination, 'text1', 'craftPatrol');
  Add(FTxtPatrolling, 'text1', 'craftPatrol');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK12.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FBtnRedirect.SetText(Tr('STR_REDIRECT_CRAFT'));
  FBtnRedirect.OnMouseClick(RedirectClick);
  FBtnRedirect.OnKeyboardPress(RedirectClick, Host.Options.KeyOk);
  FTxtDestination.SetBig;
  FTxtDestination.SetAlign(haCenter);
  FTxtDestination.SetWordWrap(True);
  FTxtDestination.SetText(Tr('STR_CRAFT_HAS_REACHED_DESTINATION')
    .Arg(TXcomTargetNames.Name(ACraft, Host.Language))
    .Arg(TXcomTargetNames.Name(ACraft.Destination, Host.Language)));
  FTxtPatrolling.SetBig;
  FTxtPatrolling.SetAlign(haCenter);
  FTxtPatrolling.SetText(Tr('STR_NOW_PATROLLING'));
end;

procedure TXcomCraftPatrolState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomCraftPatrolState.RedirectClick(AAction: TXcomAction);
begin
  Host.PopState;
  if Assigned(FOnRedirect) then
    FOnRedirect(FCraft);
end;

end.
