{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - ProductionCompleteState of OpenXcom (a   }
{  production ended, or a facility was built)                                   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.ProductionCompleteState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomSave.Base, DelphiDoom.XcomGeoscape.Control.Intf;

type
  /// <summary>productionProgress_e as ProductionCompleteState uses it, with the construction of a facility</summary>
  TXcomProductionEnd = (peConstruction, peComplete, peNotEnoughMoney, peNotEnoughMaterials);

  /// <summary>
  ///   "Production of X at base Y is complete" (or the facility, or the lack of money or materials); the second
  ///   button goes to the manufacture screen of the base, or to its basescape for a facility
  /// </summary>
  TXcomProductionCompleteState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FEnd: TXcomProductionEnd;
    FControl: IXcomGeoscapeControl;
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FBtnGotoBase: TXcomTextButton;
    FTxtMessage: TXcomText;
    procedure OkClick(AAction: TXcomAction);
    procedure GotoBaseClick(AAction: TXcomAction);
  public
    /// <param name="ABase">The base (not owned)</param>
    /// <param name="AItem">The name of the item or facility, already in the language</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase; const AItem: string;
      const AControl: IXcomGeoscapeControl; AEnd: TXcomProductionEnd);
    property Message: TXcomText read FTxtMessage;
  end;

implementation

uses
  DelphiDoom.XcomGeoscape.BaseNavigator.Intf;

{ TXcomProductionCompleteState }

constructor TXcomProductionCompleteState.Create(AHost: TXcomStateHost; ABase: TXcomBase; const AItem: string;
  const AControl: IXcomGeoscapeControl; AEnd: TXcomProductionEnd);
var
  LKey: string;
begin
  inherited Create(AHost);
  FBase := ABase;
  FControl := AControl;
  FEnd := AEnd;
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 256, 160, 32, 20, wpBoth);
  FBtnOk := TXcomTextButton.Create(118, 18, 40, 154);
  FBtnGotoBase := TXcomTextButton.Create(118, 18, 162, 154);
  FTxtMessage := TXcomText.Create(246, 110, 37, 35);
  SetInterface('geoManufactureComplete');
  Add(FWindow, 'window', 'geoManufactureComplete');
  Add(FBtnOk, 'button', 'geoManufactureComplete');
  Add(FBtnGotoBase, 'button', 'geoManufactureComplete');
  Add(FTxtMessage, 'text1', 'geoManufactureComplete');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK17.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  if AEnd <> peConstruction then
    FBtnGotoBase.SetText(Tr('STR_ALLOCATE_MANUFACTURE'))
  else
    FBtnGotoBase.SetText(Tr('STR_GO_TO_BASE'));
  FBtnGotoBase.OnMouseClick(GotoBaseClick);
  FTxtMessage.SetAlign(haCenter);
  FTxtMessage.SetVerticalAlign(vaMiddle);
  FTxtMessage.SetBig;
  FTxtMessage.SetWordWrap(True);
  case AEnd of
    peConstruction: LKey := 'STR_CONSTRUCTION_OF_FACILITY_AT_BASE_IS_COMPLETE';
    peComplete: LKey := 'STR_PRODUCTION_OF_ITEM_AT_BASE_IS_COMPLETE';
    peNotEnoughMoney: LKey := 'STR_NOT_ENOUGH_MONEY_TO_PRODUCE_ITEM_AT_BASE';
  else
    LKey := 'STR_NOT_ENOUGH_SPECIAL_MATERIALS_TO_PRODUCE_ITEM_AT_BASE';
  end;
  FTxtMessage.SetText(Tr(LKey).Arg(AItem).Arg(ABase.Name));
end;

procedure TXcomProductionCompleteState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomProductionCompleteState.GotoBaseClick(AAction: TXcomAction);
begin
  FControl.TimerReset;
  Host.PopState;
  if FEnd <> peConstruction then
    FControl.OpenBaseScreen(bsManufacture, FBase)
  else
    FControl.OpenBase(FBase);
end;

end.
