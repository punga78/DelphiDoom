{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - ConfirmNewBaseState of OpenXcom (the     }
{  cost and the area of a new base)                                             }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.ConfirmNewBaseState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomSave.Base, DelphiDoom.XcomGeoscape.Globe, DelphiDoom.XcomGeoscape.Control.Intf;

type
  /// <summary>
  ///   "Cost: $X, Area: Y" with OK and Cancel: OK pays (when the funds are enough) and puts the base in the saved
  ///   game, then asks its name; without the money it shows an error. The base is not owned: it belongs to the
  ///   screen that builds it until the game takes it
  /// </summary>
  TXcomConfirmNewBaseState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FGlobe: TXcomGlobe;
    FControl: IXcomGeoscapeControl;
    FCost: Int64;
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FBtnCancel: TXcomTextButton;
    FTxtCost: TXcomText;
    FTxtArea: TXcomText;
    procedure OkClick(AAction: TXcomAction);
    procedure CancelClick(AAction: TXcomAction);
  public
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase; AGlobe: TXcomGlobe;
      const AControl: IXcomGeoscapeControl);
    property Cost: Int64 read FCost;
  end;

implementation

uses
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Region, DelphiDoom.XcomStrategy.Geography,
  DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomBasescape.Funding, DelphiDoom.XcomMenu.ErrorMessageState,
  DelphiDoom.XcomMenu.OptionsTypes, DelphiDoom.XcomGeoscape.BaseNameState;

{ TXcomConfirmNewBaseState }

constructor TXcomConfirmNewBaseState.Create(AHost: TXcomStateHost; ABase: TXcomBase; AGlobe: TXcomGlobe;
  const AControl: IXcomGeoscapeControl);
var
  LRegion: TXcomRegion;
  LArea: string;
begin
  inherited Create(AHost);
  FBase := ABase;
  FGlobe := AGlobe;
  FControl := AControl;
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 224, 72, 16, 64, wpNone);
  FBtnOk := TXcomTextButton.Create(54, 12, 68, 104);
  FBtnCancel := TXcomTextButton.Create(54, 12, 138, 104);
  FTxtCost := TXcomText.Create(120, 9, 68, 80);
  FTxtArea := TXcomText.Create(120, 9, 68, 90);
  SetInterface('geoscape');
  Add(FWindow, 'genericWindow', 'geoscape');
  Add(FBtnOk, 'genericButton2', 'geoscape');
  Add(FBtnCancel, 'genericButton2', 'geoscape');
  Add(FTxtCost, 'genericText', 'geoscape');
  Add(FTxtArea, 'genericText', 'geoscape');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK01.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FBtnCancel.SetText(Tr('STR_CANCEL_UC'));
  FBtnCancel.OnMouseClick(CancelClick);
  FBtnCancel.OnKeyboardPress(CancelClick, Host.Options.KeyCancel);
  FCost := 0;
  LArea := '';
  LRegion := TXcomGeography.LocateRegion(TXcomStrategy.SavedGame(AHost), ABase.Longitude, ABase.Latitude);
  if Assigned(LRegion) then
  begin
    FCost := LRegion.Rules.BaseCost;
    LArea := Tr(LRegion.Rules.RegionType).Text;
  end;
  FTxtCost.SetText(Tr('STR_COST_').Arg(TXcomFunding.Format(FCost)));
  FTxtArea.SetText(Tr('STR_AREA_').Arg(LArea));
end;

procedure TXcomConfirmNewBaseState.OkClick(AAction: TXcomAction);
var
  LSave: TXcomSavedGame;
begin
  LSave := TXcomStrategy.SavedGame(Host);
  if LSave.Funds >= FCost then
  begin
    LSave.SetFunds(LSave.Funds - FCost);
    LSave.Bases.Add(FBase);
    Host.PushState(TXcomBaseNameState.Create(Host, FBase, FGlobe, False));
  end
  else
    Host.PushState(TXcomErrorMessageState.ForOrigin(Host, ooGeoscape, Tr('STR_NOT_ENOUGH_MONEY'), Palette));
end;

procedure TXcomConfirmNewBaseState.CancelClick(AAction: TXcomAction);
begin
  FGlobe.OnMouseOver(nil);
  Host.PopState;
end;

end.
