{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - AlienBaseState of OpenXcom (an alien     }
{  base was discovered)                                                         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.AlienBaseState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomSave.AlienBase, DelphiDoom.XcomGeoscape.Control.Intf;

type
  /// <summary>"X-COM agents have located an alien base in ..." with the country and region of the base</summary>
  TXcomAlienBaseState = class(TXcomState)
  strict private
    FBase: TXcomAlienBase;
    FControl: IXcomGeoscapeControl;
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FTxtTitle: TXcomText;
    procedure OkClick(AAction: TXcomAction);
  public
    /// <param name="ABase">The alien base (not owned)</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomAlienBase; const AControl: IXcomGeoscapeControl);
    property Title: TXcomText read FTxtTitle;
  end;

implementation

uses
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Country, DelphiDoom.XcomSave.Region,
  DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomStrategy.Geography;

{ TXcomAlienBaseState }

constructor TXcomAlienBaseState.Create(AHost: TXcomStateHost; ABase: TXcomAlienBase;
  const AControl: IXcomGeoscapeControl);
var
  LSave: TXcomSavedGame;
  LCountry: TXcomCountry;
  LRegion: TXcomRegion;
  LCountryText, LRegionText, LLocation: string;
begin
  inherited Create(AHost);
  FBase := ABase;
  FControl := AControl;
  FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0, wpNone);
  FBtnOk := TXcomTextButton.Create(50, 12, 135, 180);
  FTxtTitle := TXcomText.Create(308, 60, 6, 60);
  SetInterface('alienBase');
  Add(FWindow, 'window', 'alienBase');
  // the C++ passes the ids "text" and "button" swapped; the colors come from the ruleset by id
  Add(FBtnOk, 'text', 'alienBase');
  Add(FTxtTitle, 'button', 'alienBase');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK13.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetBig;
  FTxtTitle.SetWordWrap(True);
  LSave := TXcomStrategy.SavedGame(AHost);
  LCountryText := '';
  LRegionText := '';
  LCountry := TXcomGeography.LocateCountry(LSave, ABase.Longitude, ABase.Latitude);
  if Assigned(LCountry) then
    LCountryText := Tr(LCountry.Rules.CountryType).Text;
  LRegion := TXcomGeography.LocateRegion(LSave, ABase.Longitude, ABase.Latitude);
  if Assigned(LRegion) then
    LRegionText := Tr(LRegion.Rules.RegionType).Text;
  if LCountryText <> '' then
    LLocation := Tr('STR_COUNTRIES_COMMA').Arg(LCountryText).Arg(LRegionText).Text
  else if LRegionText <> '' then
    LLocation := LRegionText
  else
    LLocation := Tr('STR_UNKNOWN').Text;
  FTxtTitle.SetText(Tr('STR_XCOM_AGENTS_HAVE_LOCATED_AN_ALIEN_BASE_IN_REGION').Arg(LLocation));
end;

procedure TXcomAlienBaseState.OkClick(AAction: TXcomAction);
begin
  FControl.TimerReset;
  FControl.Globe.Center(FBase.Longitude, FBase.Latitude);
  Host.PopState;
end;

end.
