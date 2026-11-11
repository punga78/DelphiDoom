{******************************************************************************}
{                                                                              }
{  DelphiDoom: XcomGame - the composition root of the game                      }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.GameComposition;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.Game, DelphiDoom.XcomEngine.QueueEventSource;

type
  /// <summary>How the loading of the data runs</summary>
  TXcomLoadMode = (lmThread, lmImmediate, lmHeld);

  /// <summary>What the program was asked to do (the command line of OpenXcom, reduced)</summary>
  TXcomGameSettings = record
    /// <summary>The video options list the modes of the display (-listmodes). The reference program (SDL 1.2 over SDL 2) reports none, so by default the arrows of the resolution are hidden as in the reference</summary>
    ListModes: Boolean;
    /// <summary>The folder with common\ and standard\ (-data)</summary>
    DataFolder: string;
    /// <summary>The folder of the original game: UFO or TFTD (-game)</summary>
    GameFolder: string;
    /// <summary>The folder of the user, with options.cfg (-user)</summary>
    UserFolder: string;
    /// <summary>The master mod, xcom1 or xcom2 (-mod)</summary>
    ModId: string;
    /// <summary>First line of the start screen; empty: computed from the path of the program as CrossPlatform::getDosPath</summary>
    DosPath: string;
    /// <summary>OPENXCOM_VERSION_SHORT and OPENXCOM_VERSION_GIT written on the screens</summary>
    VersionText: string;
    LoadMode: TXcomLoadMode;
    /// <summary>The seed of the random numbers of a new game (-seed); 0 takes it from the clock</summary>
    Seed: UInt64;
  end;

  /// <summary>
  ///   The one place of the game that knows the concrete classes: it builds the options, the screen, the cursor, the
  ///   counter of frames, the loader of the data and the first state, around the devices it is given (the window,
  ///   the clock and the events of Windows, or the ones of a screenshot)
  /// </summary>
  TXcomGameComposition = class
  public
    /// <summary>The game, with the start state on top; the caller owns it. The devices are not freed by the game</summary>
    class function CreateGame(const ASettings: TXcomGameSettings; const ADevice: IXcomVideoDevice;
      const AClock: IXcomClock; AEvents: TXcomQueueEventSource): TXcomGame; static;
    /// <summary>CrossPlatform::getDosPath: the path of the program as a DOS prompt (names cut to 8 characters)</summary>
    class function DosPathOf(const AExecutable: string): string; static;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Factory, DelphiDoom.Png.Provider,
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Options, DelphiDoom.XcomEngine.Screen,
  DelphiDoom.XcomEngine.Language, DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomEngine.DiskFileSystem,
  DelphiDoom.XcomEngine.ModGameLoader, DelphiDoom.XcomEngine.GameLoader.Intf, DelphiDoom.XcomEngine.GameLoadTask, DelphiDoom.XcomEngine.ThreadLoadTask,
  DelphiDoom.XcomEngine.ImmediateLoadTask, DelphiDoom.XcomEngine.HeldLoadTask, DelphiDoom.XcomUi.Cursor,
  DelphiDoom.XcomUi.FpsCounter, DelphiDoom.XcomMenu.StartState, DelphiDoom.XcomEngine.FileOptionsStore,
  DelphiDoom.XcomEngine.FolderLanguageProvider, DelphiDoom.Xcom.Win.DisplayModes,
  DelphiDoom.Xcom.Win.FolderOpener, DelphiDoom.XcomEngine.DiskSaveCatalog, DelphiDoom.Xcom.Win.AudioDevice,
DelphiDoom.XcomGeoscape.NewGameStarter, DelphiDoom.XcomGeoscape.Navigator.Intf, DelphiDoom.Xcom.GeoscapeNavigator,
  DelphiDoom.XcomGeoscape.SavedGameLoader, DelphiDoom.XcomGeoscape.Simulation.Intf, DelphiDoom.XcomMod.Random,
  DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.DefaultSettings,
  DelphiDoom.XcomStrategy.Factory, DelphiDoom.XcomStrategy.NullEvents, DelphiDoom.XcomStrategy.DefaultSettings,
  DelphiDoom.XcomEngine.State;

const
  KEY_FPS = 288;

class function TXcomGameComposition.DosPathOf(const AExecutable: string): string;
var
  LFirst: Integer;
  LSecond: Integer;
  LName: string;
  LCut: Integer;
begin
  Result := '';
  LFirst := Pos('\', AExecutable);
  if LFirst = 0 then
    Exit('C:\GAMES\OPENXCOM');
  Result := Copy(AExecutable, 1, LFirst);
  LSecond := Pos('\', AExecutable, LFirst + 1);
  while LSecond > 0 do
  begin
    LName := Copy(AExecutable, LFirst + 1, LSecond - LFirst - 1);
    if LName = '..' then
    begin
      LCut := Length(Result) - 1;
      while (LCut > 0) and (Result[LCut] <> '\') do
        Dec(LCut);
      Result := Copy(Result, 1, LCut - 1);
    end
    else
    begin
      if Length(LName) > 8 then
        LName := Copy(LName, 1, 6) + '~1';
      Result := Result + UpperCase(LName);
    end;
    LFirst := LSecond;
    LSecond := Pos('\', AExecutable, LFirst + 1);
    if LSecond > 0 then
      Result := Result + '\';
  end;
end;

class function TXcomGameComposition.CreateGame(const ASettings: TXcomGameSettings; const ADevice: IXcomVideoDevice;
  const AClock: IXcomClock; AEvents: TXcomQueueEventSource): TXcomGame;
var
  LOptions: TXcomOptions;
  LFiles: IXcomFileSystem;
  LParser: IYamlParser;
  LLoaderSettings: TXcomLoaderSettings;
  LTask: TXcomGameLoadTask;
  LLoader: IXcomGameLoader;
  LSimulationFactory: TXcomSimulationFactory;
  LNavigatorFactory: TXcomNavigatorFactory;
  LModLoader: TXcomModGameLoader;
  LOptionsFile: string;
  LDosPath: string;
begin
  LFiles := TXcomDiskFileSystem.Create;
  LParser := TYamlFactory.CreateParser;
  LOptions := TXcomOptions.Create;
  try
    LOptionsFile := TPath.Combine(ASettings.UserFolder, 'options.cfg');
    if (ASettings.UserFolder <> '') and LFiles.FileExists(LOptionsFile) then
      LOptions.Load(LParser.Load(LFiles.ReadAll(LOptionsFile)));
    // the folders that the options screen shows (in the program of OpenXcom: the user, master user and config folders)
    LOptions.OriginalDataFolder := IncludeTrailingPathDelimiter(ASettings.GameFolder);
    LOptions.ModDataFolder := IncludeTrailingPathDelimiter(TPath.Combine(ASettings.DataFolder, 'common'));
    LOptions.UserFolder := IncludeTrailingPathDelimiter(ASettings.UserFolder);
    LOptions.MasterUserFolder := IncludeTrailingPathDelimiter(TPath.Combine(ASettings.UserFolder, ASettings.ModId));
    LOptions.ConfigFolder := LOptions.UserFolder;
    LOptions.BaseXResolution := LOptions.DisplayWidth;
    LOptions.BaseYResolution := LOptions.DisplayHeight;
    LLoaderSettings.DataFolder := ASettings.DataFolder;
    LLoaderSettings.GameFolder := ASettings.GameFolder;
    LLoaderSettings.ModId := ASettings.ModId;
    LLoaderSettings.LanguageId := LOptions.Language;
    LLoaderSettings.Wordwrap := LOptions.Wordwrap;
    LModLoader := TXcomModGameLoader.Create(LLoaderSettings, LFiles, LParser, TPngProvider.Client);
    // the strategy screens need the ruleset of the mod
    LModLoader.LoadRules := True;
    LLoader := LModLoader;
    case ASettings.LoadMode of
      lmImmediate:
        LTask := TXcomImmediateLoadTask.Create(LLoader);
      lmHeld:
        LTask := TXcomHeldLoadTask.Create(LLoader);
    else
      LTask := TXcomThreadLoadTask.Create(LLoader);
    end;
    LDosPath := ASettings.DosPath;
    if LDosPath = '' then
      LDosPath := DosPathOf(ParamStr(0));
    Result := TXcomGame.Create(LOptions, TXcomScreen.Create(LOptions, ADevice),
      TXcomCursor.Create(9, 13),
      TXcomFpsCounter.Create(AClock, 15, 5, 0, 0, LOptions.FpsCounter, KEY_FPS),
      TXcomLanguage.Create('', LOptions.Wordwrap, LFiles, LParser), AClock, AEvents);
    Result.SetOptionsStore(TXcomFileOptionsStore.Create(LFiles, LParser, ASettings.UserFolder));
    Result.SetLanguageProvider(TXcomFolderLanguageProvider.Create(ASettings.DataFolder,
      TPath.Combine(TPath.Combine(ASettings.DataFolder, 'standard'), ASettings.ModId), LFiles, LParser));
    Result.SetFolderOpener(TXcomWinFolderOpener.Create);
    Result.SetAudioDevice(TXcomWinAudioDevice.Create);
    Result.SetSaveCatalog(TXcomDiskSaveCatalog.Create(LOptions.MasterUserFolder, ASettings.ModId, LParser));
    if ASettings.ListModes then
      Result.SetDisplayModes(TXcomWinDisplayModes.Create);
    LSimulationFactory :=
      function(AHost: TXcomStateHost; ASave: TXcomSavedGame; ARuleset: TXcomRuleset;
        const ARandom: IXcomRandom): IXcomGeoscapeSimulation
      begin
        // the screens that the popups open are not ported: the events go nowhere
        Result := TXcomStrategyFactory.CreateSimulation(ASave, ARuleset, nil, ARandom, nil,
          TXcomNullGeoscapeEvents.Create, TXcomDefaultStrategySettings.Create, TXcomDefaultSaveSettings.Create);
      end;
    LNavigatorFactory :=
      function(AHost: TXcomStateHost): IXcomGeoscapeNavigator
      begin
        Result := TXcomGameNavigator.Create(AHost);
      end;
    Result.SetNewGameStarter(TXcomNewGameStarter.Create(Result, ASettings.Seed, LSimulationFactory, LNavigatorFactory));
    Result.SetSavedGameLoader(TXcomSavedGameLoader.Create(Result, LSimulationFactory, LNavigatorFactory));
    Result.SetState(TXcomStartState.Create(Result, LTask, LDosPath, ASettings.VersionText));
  except
    LOptions.Free;
    raise;
  end;
end;

end.
