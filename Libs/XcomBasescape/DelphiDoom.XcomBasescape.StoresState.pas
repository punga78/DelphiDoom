{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - StoresState of OpenXcom (the items in  }
{  the stores of a base)                                                        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.StoresState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomUi.TextList, DelphiDoom.XcomSave.Base;

type
  /// <summary>
  ///   The items in the stores of a base, in the order of the items of the ruleset: name, quantity and the space
  ///   they use
  /// </summary>
  TXcomStoresState = class(TXcomState)
  strict private
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtItem: TXcomText;
    FTxtQuantity: TXcomText;
    FTxtSpaceUsed: TXcomText;
    FList: TXcomTextList;
    procedure OkClick(AAction: TXcomAction);
  public
    /// <param name="ABase">The base (not owned)</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase);
    property List: TXcomTextList read FList;
  end;

implementation

uses
  DelphiDoom.Yaml.Convert, DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomMod.RuleItem;

{ TXcomStoresState }

constructor TXcomStoresState.Create(AHost: TXcomStateHost; ABase: TXcomBase);
var
  LName: string;
  LQuantity: Integer;
  LRule: TXcomRuleItem;
begin
  inherited Create(AHost);
  FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0, wpBoth);
  FBtnOk := TXcomTextButton.Create(300, 16, 10, 176);
  FTxtTitle := TXcomText.Create(310, 17, 5, 8);
  FTxtItem := TXcomText.Create(142, 9, 10, 32);
  FTxtQuantity := TXcomText.Create(88, 9, 152, 32);
  FTxtSpaceUsed := TXcomText.Create(74, 9, 240, 32);
  FList := TXcomTextList.Create(Host.Options, Host.Clock, 288, 128, 8, 40);
  SetInterface('storesInfo');
  Add(FWindow, 'window', 'storesInfo');
  Add(FBtnOk, 'button', 'storesInfo');
  Add(FTxtTitle, 'text', 'storesInfo');
  Add(FTxtItem, 'text', 'storesInfo');
  Add(FTxtQuantity, 'text', 'storesInfo');
  Add(FTxtSpaceUsed, 'text', 'storesInfo');
  Add(FList, 'list', 'storesInfo');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK13.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetText(Tr('STR_STORES'));
  FTxtItem.SetText(Tr('STR_ITEM'));
  FTxtQuantity.SetText(Tr('STR_QUANTITY_UC'));
  FTxtSpaceUsed.SetText(Tr('STR_SPACE_USED_UC'));
  FList.SetColumns([162, 92, 32]);
  FList.SetSelectable(True);
  FList.SetBackground(FWindow);
  FList.SetMargin(2);
  for LName in TXcomStrategy.Ruleset(AHost).Items.Index do
  begin
    LQuantity := ABase.StorageItems.GetItem(LName);
    if LQuantity > 0 then
    begin
      LRule := TXcomStrategy.Ruleset(AHost).Items.Find(LName);
      // ostream << double: six significant digits
      FList.AddRow([Tr(LName).Text, IntToStr(LQuantity), string(TYamlConvert.FormatGeneral(LQuantity * LRule.Size, 6))]);
    end;
  end;
end;

procedure TXcomStoresState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

end.
