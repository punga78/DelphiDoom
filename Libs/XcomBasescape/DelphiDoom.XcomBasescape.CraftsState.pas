{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - CraftsState of OpenXcom (the crafts of }
{  a base)                                                                      }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.CraftsState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomUi.TextList, DelphiDoom.XcomSave.Base;

type
  /// <summary>
  ///   The crafts of a base: name, status, weapons, crew and vehicles. The craft info screen and the sale of the
  ///   stores that are over their limit (SellState) are not ported: a click on a craft and the OK button only
  ///   close the window
  /// </summary>
  TXcomCraftsState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtBase: TXcomText;
    FTxtName: TXcomText;
    FTxtStatus: TXcomText;
    FTxtWeapon: TXcomText;
    FTxtCrew: TXcomText;
    FTxtHwp: TXcomText;
    FList: TXcomTextList;
    procedure OkClick(AAction: TXcomAction);
  public
    /// <param name="ABase">The base (not owned)</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase);
    procedure Init; override;
    property List: TXcomTextList read FList;
  end;

implementation

uses
  DelphiDoom.XcomSave.Craft, DelphiDoom.XcomBasescape.Names;

{ TXcomCraftsState }

constructor TXcomCraftsState.Create(AHost: TXcomStateHost; ABase: TXcomBase);
begin
  inherited Create(AHost);
  FBase := ABase;
  FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0, wpBoth);
  FBtnOk := TXcomTextButton.Create(288, 16, 16, 176);
  FTxtTitle := TXcomText.Create(298, 17, 16, 8);
  FTxtBase := TXcomText.Create(298, 17, 16, 24);
  FTxtName := TXcomText.Create(94, 9, 16, 40);
  FTxtStatus := TXcomText.Create(50, 9, 110, 40);
  FTxtWeapon := TXcomText.Create(50, 17, 160, 40);
  FTxtCrew := TXcomText.Create(58, 9, 210, 40);
  FTxtHwp := TXcomText.Create(46, 9, 268, 40);
  FList := TXcomTextList.Create(Host.Options, Host.Clock, 288, 118, 8, 58);
  SetInterface('craftSelect');
  Add(FWindow, 'window', 'craftSelect');
  Add(FBtnOk, 'button', 'craftSelect');
  Add(FTxtTitle, 'text', 'craftSelect');
  Add(FTxtBase, 'text', 'craftSelect');
  Add(FTxtName, 'text', 'craftSelect');
  Add(FTxtStatus, 'text', 'craftSelect');
  Add(FTxtWeapon, 'text', 'craftSelect');
  Add(FTxtCrew, 'text', 'craftSelect');
  Add(FTxtHwp, 'text', 'craftSelect');
  Add(FList, 'list', 'craftSelect');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK14.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FTxtTitle.SetBig;
  FTxtTitle.SetText(Tr('STR_INTERCEPTION_CRAFT'));
  FTxtBase.SetBig;
  FTxtBase.SetText(Tr('STR_BASE_').Arg(FBase.Name));
  FTxtName.SetText(Tr('STR_NAME_UC'));
  FTxtStatus.SetText(Tr('STR_STATUS'));
  FTxtWeapon.SetText(Tr('STR_WEAPON_SYSTEMS'));
  FTxtWeapon.SetWordWrap(True);
  FTxtCrew.SetText(Tr('STR_CREW'));
  FTxtHwp.SetText(Tr('STR_HWPS'));
  FList.SetColumns([94, 68, 44, 46, 28]);
  FList.SetSelectable(True);
  FList.SetBackground(FWindow);
  FList.SetMargin(8);
end;

procedure TXcomCraftsState.Init;
var
  LCraft: TXcomCraft;
begin
  inherited Init;
  FList.ClearList;
  for LCraft in FBase.Crafts do
    FList.AddRow([TXcomBaseNames.CraftName(LCraft, Host.Language), Tr(LCraft.Status).Text,
      Format('%d/%d', [LCraft.NumWeapons, LCraft.Rules.Weapons]),
      IntToStr(LCraft.NumSoldiers(FBase.Soldiers)), IntToStr(LCraft.NumVehicles)]);
end;

procedure TXcomCraftsState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

end.
