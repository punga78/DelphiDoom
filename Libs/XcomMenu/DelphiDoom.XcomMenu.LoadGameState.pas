{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - LoadGameState of OpenXcom (loading a saved game)
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}unit DelphiDoom.XcomMenu.LoadGameState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Types,
  DelphiDoom.XcomUi.Text, DelphiDoom.XcomMenu.OptionsTypes;

type
  /// <summary>
  ///   The "Loading game" screen. After ten turns (so that it is drawn) it closes itself and asks the host's loader to load
  ///   the file (the loader gives the saved game to the host and sets the geoscape as the state); a host with no loader,
  ///   or a file that cannot be loaded, gives the error window "Load unsuccessful"
  /// </summary>
  TXcomLoadGameState = class(TXcomState)
  strict private
    FOrigin: TXcomOptionsOrigin;
    FFileName: string;
    FFirstRun: Integer;
    FTxtStatus: TXcomText;
  public
    constructor Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin; const AFileName: string;
      AParentPalette: PXcomColors);
    procedure Think; override;
  end;

implementation

uses
  DelphiDoom.XcomMenu.ErrorMessageState;

constructor TXcomLoadGameState.Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin; const AFileName: string;
  AParentPalette: PXcomColors);
begin
  inherited Create(AHost);
  FOrigin := AOrigin;
  FFileName := AFileName;
  ToggleScreen;
  FTxtStatus := TXcomText.Create(320, 17, 0, 92);
  SetPalette(PXcomColor(AParentPalette), 0, 256);
  if FOrigin = ooBattlescape then
  begin
    Add(FTxtStatus, 'textLoad', 'battlescape');
    FTxtStatus.SetHighContrast(True);
  end
  else
    Add(FTxtStatus, 'textLoad', 'geoscape');
  CenterAllSurfaces;
  FTxtStatus.SetBig;
  FTxtStatus.SetAlign(haCenter);
  FTxtStatus.SetText(Tr('STR_LOADING_GAME'));
end;

procedure TXcomLoadGameState.Think;
begin
  inherited Think;
  // make sure it gets drawn properly
  if FFirstRun < 10 then
    Inc(FFirstRun)
  else
  begin
    Host.PopState;
    if Host.SavedGameLoader = nil then
      Host.PushState(TXcomErrorMessageState.ForOrigin(Host, FOrigin,
        Tr('STR_LOAD_UNSUCCESSFUL').Text + #2 + 'The geoscape is not ported', Palette))
    else
      try
        Host.SavedGameLoader.LoadGame(FFileName);
      except
        on E: Exception do
          Host.PushState(TXcomErrorMessageState.ForOrigin(Host, FOrigin,
            Tr('STR_LOAD_UNSUCCESSFUL').Text + #2 + E.Message, Palette));
      end;
  end;
end;

end.