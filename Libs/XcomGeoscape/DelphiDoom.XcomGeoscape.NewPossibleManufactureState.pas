{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - NewPossibleManufactureState of OpenXcom  }
{  (new items can be produced)                                                  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.NewPossibleManufactureState;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.TextList, DelphiDoom.XcomSave.Base,
  DelphiDoom.XcomGeoscape.Control.Intf;

type
  /// <summary>"We can now produce": the list of the items; the second button opens the manufacture screen</summary>
  TXcomNewPossibleManufactureState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FControl: IXcomGeoscapeControl;
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FBtnManufacture: TXcomTextButton;
    FTxtTitle: TXcomText;
    FLstPossibilities: TXcomTextList;
    procedure OkClick(AAction: TXcomAction);
    procedure ManufactureClick(AAction: TXcomAction);
  public
    /// <param name="ABase">The base (not owned)</param>
    /// <param name="ANames">The names (keys of the language) of the items that became possible</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase; const ANames: TArray<string>;
      const AControl: IXcomGeoscapeControl);
    property Possibilities: TXcomTextList read FLstPossibilities;
  end;

implementation

uses
  DelphiDoom.XcomGeoscape.BaseNavigator.Intf;

{ TXcomNewPossibleManufactureState }

constructor TXcomNewPossibleManufactureState.Create(AHost: TXcomStateHost; ABase: TXcomBase;
  const ANames: TArray<string>; const AControl: IXcomGeoscapeControl);
var
  LName: string;
begin
  inherited Create(AHost);
  FBase := ABase;
  FControl := AControl;
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 288, 180, 16, 10, wpNone);
  FBtnOk := TXcomTextButton.Create(160, 14, 80, 149);
  FBtnManufacture := TXcomTextButton.Create(160, 14, 80, 165);
  FTxtTitle := TXcomText.Create(288, 40, 16, 20);
  FLstPossibilities := TXcomTextList.Create(Host.Options, Host.Clock, 250, 80, 35, 50);
  SetInterface('geoManufacture');
  Add(FWindow, 'window', 'geoManufacture');
  Add(FBtnOk, 'button', 'geoManufacture');
  Add(FBtnManufacture, 'button', 'geoManufacture');
  Add(FTxtTitle, 'text1', 'geoManufacture');
  Add(FLstPossibilities, 'text2', 'geoManufacture');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK17.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FBtnManufacture.SetText(Tr('STR_ALLOCATE_MANUFACTURE'));
  FBtnManufacture.OnMouseClick(ManufactureClick);
  FBtnManufacture.OnKeyboardPress(ManufactureClick, Host.Options.KeyOk);
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetText(Tr('STR_WE_CAN_NOW_PRODUCE'));
  FLstPossibilities.SetColumns([250]);
  FLstPossibilities.SetBig;
  FLstPossibilities.SetAlign(haCenter);
  FLstPossibilities.SetScrolling(True, 0);
  for LName in ANames do
    FLstPossibilities.AddRow([Tr(LName).Text]);
end;

procedure TXcomNewPossibleManufactureState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomNewPossibleManufactureState.ManufactureClick(AAction: TXcomAction);
begin
  Host.PopState;
  FControl.OpenBaseScreen(bsManufacture, FBase);
end;

end.
