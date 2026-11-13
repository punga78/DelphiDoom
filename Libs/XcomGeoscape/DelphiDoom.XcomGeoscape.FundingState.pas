{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - FundingState of OpenXcom (the            }
{  international relations: the funding of every country)                       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.FundingState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomUi.TextList;

type
  /// <summary>The funding of every country, its change since last month and the total</summary>
  TXcomFundingState = class(TXcomState)
  strict private
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtCountry: TXcomText;
    FTxtFunding: TXcomText;
    FTxtChange: TXcomText;
    FLstCountries: TXcomTextList;
    procedure OkClick(AAction: TXcomAction);
  public
    constructor Create(AHost: TXcomStateHost);
    property List: TXcomTextList read FLstCountries;
  end;

implementation

uses
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Country, DelphiDoom.XcomGeoscape.Strategy,
  DelphiDoom.XcomGeoscape.Funding;

{ TXcomFundingState }

constructor TXcomFundingState.Create(AHost: TXcomStateHost);
var
  LSave: TXcomSavedGame;
  LCountry: TXcomCountry;
  LFunding, LChange: string;
  LDelta: Integer;
begin
  inherited Create(AHost);
  LSave := TXcomStrategy.SavedGame(AHost);
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0, wpBoth);
  FBtnOk := TXcomTextButton.Create(50, 12, 135, 180);
  FTxtTitle := TXcomText.Create(320, 17, 0, 8);
  FTxtCountry := TXcomText.Create(100, 9, 32, 30);
  FTxtFunding := TXcomText.Create(100, 9, 140, 30);
  FTxtChange := TXcomText.Create(72, 9, 240, 30);
  FLstCountries := TXcomTextList.Create(Host.Options, Host.Clock, 260, 136, 32, 40);
  SetInterface('fundingWindow');
  Add(FWindow, 'window', 'fundingWindow');
  Add(FBtnOk, 'button', 'fundingWindow');
  Add(FTxtTitle, 'text1', 'fundingWindow');
  Add(FTxtCountry, 'text2', 'fundingWindow');
  Add(FTxtFunding, 'text2', 'fundingWindow');
  Add(FTxtChange, 'text2', 'fundingWindow');
  Add(FLstCountries, 'list', 'fundingWindow');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK13.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.GetValue('keyGeoFunding'));
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetBig;
  FTxtTitle.SetText(Tr('STR_INTERNATIONAL_RELATIONS'));
  FTxtCountry.SetText(Tr('STR_COUNTRY'));
  FTxtFunding.SetText(Tr('STR_FUNDING'));
  FTxtChange.SetText(Tr('STR_CHANGE'));
  FLstCountries.SetColumns([108, 100, 52]);
  FLstCountries.SetDot(True);
  for LCountry in LSave.Countries do
  begin
    LFunding := Chr(XCOM_TOKEN_COLOR_FLIP) + TXcomFunding.Format(LCountry.Funding[High(LCountry.Funding)]) +
      Chr(XCOM_TOKEN_COLOR_FLIP);
    if Length(LCountry.Funding) > 1 then
    begin
      LChange := Chr(XCOM_TOKEN_COLOR_FLIP);
      LDelta := LCountry.Funding[High(LCountry.Funding)] - LCountry.Funding[High(LCountry.Funding) - 1];
      if LDelta > 0 then
        LChange := LChange + '+';
      LChange := LChange + TXcomFunding.Format(LDelta) + Chr(XCOM_TOKEN_COLOR_FLIP);
    end
    else
      LChange := TXcomFunding.Format(0);
    FLstCountries.AddRow([Tr(LCountry.Rules.CountryType).Text, LFunding, LChange]);
  end;
  FLstCountries.AddRow([Tr('STR_TOTAL_UC').Text, TXcomFunding.Format(LSave.CountryFunding)]);
  FLstCountries.SetRowColor(LSave.Countries.Count, FTxtCountry.GetColor);
end;

procedure TXcomFundingState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

end.
