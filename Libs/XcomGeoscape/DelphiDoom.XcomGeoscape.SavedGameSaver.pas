{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - saving and abandoning the saved game     }
{  (SavedGame::save, SaveGameState and AbandonGameState of OpenXcom)            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.SavedGameSaver;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Session.Intf, DelphiDoom.XcomSave.SavedGame;

type
  /// <summary>
  ///   IXcomSavedGameSaver on the saved game of the host: SavedGame::save writes the file in the master user folder
  ///   (a temporary file first, then moved over the real one, with the line ends of Windows as the C++ does in text
  ///   mode); the brief header has the version, engine and build given, and the active mods with their versions
  /// </summary>
  TXcomSavedGameSaver = class(TInterfacedObject, IXcomSavedGameSaver)
  strict private
    FHost: TXcomStateHost;
    FBrief: TXcomSaveBriefInfo;
    FVersionText: string;
    function ActiveMods: TArray<string>;
  public
    /// <param name="AHost">Not owned: the game</param>
    /// <param name="ABrief">The version, engine and build of the header (the mods are the active ones of the options)</param>
    /// <param name="AVersionText">The version text of the main menu that abandoning goes back to</param>
    constructor Create(AHost: TXcomStateHost; const ABrief: TXcomSaveBriefInfo; const AVersionText: string);
    function IsIronman: Boolean;
    procedure SetName(const AName: string);
    function GetName: string;
    procedure SaveGame(const AFileName: string);
    procedure AbandonGame;
  end;

  /// <summary>An error that the save error window shows</summary>
  EXcomSaveGameException = class(Exception);

implementation

uses
  System.IOUtils, System.AnsiStrings, DelphiDoom.Yaml.Types, DelphiDoom.XcomEngine.ModCatalog.Intf, DelphiDoom.XcomEngine.ModInfo,
  DelphiDoom.XcomEngine.Options, DelphiDoom.XcomSave.DefaultSettings, DelphiDoom.XcomSave.Settings.Intf, DelphiDoom.XcomGeoscape.Strategy,
  DelphiDoom.XcomMenu.GoToMainMenuState;

resourcestring
  SXcomFailedToSave = 'Failed to save %s';

constructor TXcomSavedGameSaver.Create(AHost: TXcomStateHost; const ABrief: TXcomSaveBriefInfo;
  const AVersionText: string);
begin
  inherited Create;
  FHost := AHost;
  FBrief := ABrief;
  FVersionText := AVersionText;
end;

function TXcomSavedGameSaver.IsIronman: Boolean;
begin
  Result := TXcomStrategy.SavedGame(FHost).Ironman;
end;

procedure TXcomSavedGameSaver.SetName(const AName: string);
begin
  TXcomStrategy.SavedGame(FHost).Name := AName;
end;

function TXcomSavedGameSaver.GetName: string;
begin
  Result := TXcomStrategy.SavedGame(FHost).Name;
end;

function TXcomSavedGameSaver.ActiveMods: TArray<string>;
var
  LMod: TXcomModSetting;
  LInfo: TXcomModInfo;
  LVersion: string;
begin
  Result := nil;
  for LMod in FHost.Options.Mods do
    if LMod.Active then
    begin
      LVersion := '1.0';
      if (FHost.ModCatalog <> nil) and FHost.ModCatalog.TryGetInfo(LMod.Id, LInfo) then
        LVersion := LInfo.Version;
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := LMod.Id + ' ver: ' + LVersion;
    end;
end;

procedure TXcomSavedGameSaver.SaveGame(const AFileName: string);
var
  LInfo: TXcomSaveBriefInfo;
  LSettings: IXcomSaveSettings;
  LText: TYamlText;
  LBytes: TBytes;
  LPath, LTemp: string;
begin
  LInfo := FBrief;
  LInfo.Mods := ActiveMods;
  // held in a variable: an object made in the call of a const interface parameter is never released
  LSettings := TXcomDefaultSaveSettings.Create;
  LText := TXcomStrategy.SavedGame(FHost).Save(LInfo, LSettings,
    TXcomStrategy.Random(FHost));
  // the C++ writes the file in text mode: CRLF on Windows
  LText := System.AnsiStrings.StringReplace(LText, #10, #13#10, [rfReplaceAll]);
  SetLength(LBytes, Length(LText));
  if Length(LText) > 0 then
    Move(LText[1], LBytes[0], Length(LText));
  LPath := TPath.Combine(FHost.Options.MasterUserFolder, AFileName);
  LTemp := LPath + '.tmp';
  try
    TDirectory.CreateDirectory(FHost.Options.MasterUserFolder);
    TFile.WriteAllBytes(LTemp, LBytes);
    if TFile.Exists(LPath) then
      TFile.Delete(LPath);
    TFile.Move(LTemp, LPath);
  except
    on E: Exception do
      raise EXcomSaveGameException.CreateFmt(SXcomFailedToSave, [AFileName]);
  end;
end;

procedure TXcomSavedGameSaver.AbandonGame;
begin
  FHost.SetSession(nil);
  FHost.SetState(TXcomGoToMainMenuState.Create(FHost, FVersionText));
end;

end.
