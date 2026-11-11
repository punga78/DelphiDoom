{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - ResearchRequiredState of OpenXcom (a     }
{  weapon was researched before its ammunition)                                 }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.ResearchRequiredState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton;

type
  /// <summary>"You need to research the clip to produce the weapon"</summary>
  TXcomResearchRequiredState = class(TXcomState)
  strict private
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FTxtTitle: TXcomText;
    procedure OkClick(AAction: TXcomAction);
  public
    /// <param name="AWeapon">The type of the weapon (key of the language)</param>
    /// <param name="AClip">The type of its first clip</param>
    constructor Create(AHost: TXcomStateHost; const AWeapon, AClip: string);
  end;

implementation

{ TXcomResearchRequiredState }

constructor TXcomResearchRequiredState.Create(AHost: TXcomStateHost; const AWeapon, AClip: string);
begin
  inherited Create(AHost);
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 288, 180, 16, 10, wpNone);
  FBtnOk := TXcomTextButton.Create(160, 18, 80, 150);
  FTxtTitle := TXcomText.Create(288, 80, 16, 50);
  SetInterface('geoResearchRequired');
  Add(FWindow, 'window', 'geoResearchRequired');
  Add(FBtnOk, 'button', 'geoResearchRequired');
  Add(FTxtTitle, 'text1', 'geoResearchRequired');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK05.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetVerticalAlign(vaMiddle);
  FTxtTitle.SetText(Tr('STR_YOU_NEED_TO_RESEARCH_ITEM_TO_PRODUCE_ITEM').Arg(Tr(AClip).Text).Arg(Tr(AWeapon).Text));
end;

procedure TXcomResearchRequiredState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

end.
