{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - SaveGameState of OpenXcom (saving a game)    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMenu.SaveGameState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Session.Intf, DelphiDoom.XcomUi.Types,
  DelphiDoom.XcomUi.Text, DelphiDoom.XcomMenu.OptionsTypes;

type
  /// <summary>SaveType: how the game is saved</summary>
  TXcomSaveType = (stDefault, stQuick, stAutoGeoscape, stAutoBattlescape, stIronman, stIronmanEnd);

  /// <summary>
  ///   The "Saving game" screen. After ten turns (so that it is drawn) it closes itself (and the save screen and the
  ///   pause menu under it for a manual save) and asks the saver of the host to write the file; a host with no saver,
  ///   or a file that cannot be written, gives the error window "Save unsuccessful"
  /// </summary>
  TXcomSaveGameState = class(TXcomState)
  strict private
    FOrigin: TXcomOptionsOrigin;
    FFileName: string;
    FType: TXcomSaveType;
    FFirstRun: Integer;
    FTxtStatus: TXcomText;
    procedure BuildUi(AParentPalette: PXcomColors);
    procedure Error(const AMessage: string);
  public
    /// <summary>A manual save into the file (with the extension)</summary>
    constructor Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin; const AFileName: string;
      AParentPalette: PXcomColors); overload;
    /// <summary>A quick save, an autosave or the save of the ironman game (the name is the one of the reserved files)</summary>
    constructor Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin; AType: TXcomSaveType;
      AParentPalette: PXcomColors); overload;
    procedure Think; override;
    property FileName: string read FFileName;
  end;

implementation

uses
  DelphiDoom.XcomMenu.ErrorMessageState, DelphiDoom.XcomMenu.SaveNames;

resourcestring
  SXcomNoSaver = 'The saved game cannot be saved';

constructor TXcomSaveGameState.Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin; const AFileName: string;
  AParentPalette: PXcomColors);
begin
  inherited Create(AHost);
  FOrigin := AOrigin;
  FFileName := AFileName;
  FType := stDefault;
  BuildUi(AParentPalette);
end;

constructor TXcomSaveGameState.Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin; AType: TXcomSaveType;
  AParentPalette: PXcomColors);
begin
  inherited Create(AHost);
  FOrigin := AOrigin;
  FType := AType;
  case AType of
    stQuick:
      FFileName := TXcomSaveNames.QUICKSAVE;
    stAutoGeoscape:
      FFileName := TXcomSaveNames.AUTOSAVE_GEOSCAPE;
    stAutoBattlescape:
      FFileName := TXcomSaveNames.AUTOSAVE_BATTLESCAPE;
    stIronman, stIronmanEnd:
      if Host.SavedGameSaver <> nil then
        FFileName := TXcomSaveNames.Sanitize(Host.SavedGameSaver.GetName) + '.sav';
  end;
  BuildUi(AParentPalette);
end;

procedure TXcomSaveGameState.BuildUi(AParentPalette: PXcomColors);
begin
  // _screen = false: the state under it stays visible
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
  FTxtStatus.SetText(Tr('STR_SAVING_GAME'));
end;

procedure TXcomSaveGameState.Think;
var
  LSaver: IXcomSavedGameSaver;
begin
  inherited Think;
  // make sure it gets drawn properly
  if FFirstRun < 10 then
  begin
    Inc(FFirstRun);
    Exit;
  end;
  LSaver := Host.SavedGameSaver;
  Host.PopState;
  case FType of
    stDefault:
      begin
        // manual save: closes the save screen and, unless ironman, the pause menu too
        Host.PopState;
        if (LSaver = nil) or not LSaver.IsIronman then
          Host.PopState;
      end;
    stQuick, stAutoGeoscape, stAutoBattlescape:
      if LSaver <> nil then
        LSaver.SetName(FFileName);
  end;
  if LSaver = nil then
  begin
    Error(SXcomNoSaver);
    Exit;
  end;
  try
    LSaver.SaveGame(FFileName);
    if FType = stIronmanEnd then
      LSaver.AbandonGame;
  except
    on E: Exception do
      Error(E.Message);
  end;
end;

procedure TXcomSaveGameState.Error(const AMessage: string);
begin
  Host.PushState(TXcomErrorMessageState.ForOrigin(Host, FOrigin,
    Tr('STR_SAVE_UNSUCCESSFUL').Text + #2 + AMessage, Palette));
end;

end.
