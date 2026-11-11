{******************************************************************************}
{                                                                              }
{  DelphiDoom: Xcom32 - the composition root of the game                       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.GameComposition;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.Game, DelphiDoom.XcomEngine.QueueEventSource,
  DelphiDoom.XcomAudio.Intf, DelphiDoom.XcomGeoscape.MissionLauncher.Intf, DelphiDoom.Xcom.Win.Window;

type
  /// <summary>How the loading of the data runs</summary>
  TXcomLoadMode = (lmThread, lmImmediate, lmHeld);

  /// <summary>Receives the meter of the mixer once the audio is open</summary>
  TXcomAudioReady = reference to procedure(const AMeter: IXcomMixerMeter);

  /// <summary>What the program was asked to do (the command line of OpenXcom, reduced)</summary>
  TXcomGameSettings = record
    /// <summary>The video options list the modes of the display (-listmodes). The reference program (SDL 1.2 over SDL 2) reports none, so by default the arrows of the resolution are hidden as in the reference</summary>
    ListModes: Boolean;
    /// <summary>The game runs in a real window (not the screenshots without one)</summary>
    WindowMode: Boolean;
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
    /// <summary>The sound output of the machine; nil (the screenshot modes) gives a game without sound</summary>
    AudioOutput: IXcomPcmOutput;
    /// <summary>Called with what the mixer plays, once the audio is set up (nil for nothing)</summary>
    OnAudio: TXcomAudioReady;
    /// <summary>The seed of the random numbers of a new game (-seed); 0 takes it from the clock</summary>
    Seed: UInt64;
    /// <summary>Starts the battle of a mission (the Battlescape's); nil: "Yes" of the landing confirmation does nothing</summary>
    MissionLauncher: IXcomMissionLauncher;
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
    /// <summary>
    ///   The display of the game in a window: GDI, or OpenGL when Options::useOpenGL asks for it and a context can
    ///   be made (the screen says which at every change of mode). The window is not owned: the caller frees it
    ///   after the last reference to the display is gone
    /// </summary>
    /// <param name="ASettings">The data folder: the shaders of the display filter are in its common\Shaders</param>
    /// <param name="ALog">Where the version of OpenGL and the reason of a fallback to GDI go; nil for nowhere</param>
    class function CreateWindowDevice(AWindow: TXcomWinWindow; const ASettings: TXcomGameSettings;
      const ALog: IXcomLog): IXcomVideoDevice; static;
    /// <summary>The shaders that the video options list and the OpenGL display reads</summary>
    class function CreateShaderCatalog(const ASettings: TXcomGameSettings): IXcomShaderCatalog; static;
    /// <summary>CrossPlatform::getDosPath: the path of the program as a DOS prompt (names cut to 8 characters)</summary>
    class function DosPathOf(const AExecutable: string): string; static;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Factory, DelphiDoom.Png.Provider,
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Options, DelphiDoom.XcomEngine.Screen,
  DelphiDoom.XcomEngine.Language, DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomEngine.DiskFileSystem,
  DelphiDoom.XcomEngine.ModGameLoader, DelphiDoom.XcomEngine.GameLoader.Intf, DelphiDoom.XcomEngine.GameLoadTask, DelphiDoom.XcomEngine.ThreadLoadTask,
  DelphiDoom.XcomEngine.ImmediateLoadTask, DelphiDoom.XcomEngine.HeldLoadTask, DelphiDoom.XcomUi.Cursor,
  DelphiDoom.XcomUi.FpsCounter, DelphiDoom.XcomMenu.StartState, DelphiDoom.XcomEngine.FileOptionsStore,
  DelphiDoom.XcomEngine.FolderLanguageProvider, DelphiDoom.Xcom.Win.DisplayModes,
  DelphiDoom.Xcom.Win.FolderOpener, DelphiDoom.XcomEngine.DiskSaveCatalog, DelphiDoom.XcomEngine.Music.Intf, DelphiDoom.XcomAudio.Factory,
  DelphiDoom.XcomAudio.Types, DelphiDoom.XcomEngine.DiskModCatalog,
DelphiDoom.XcomGeoscape.NewGameStarter, DelphiDoom.XcomGeoscape.Navigator.Intf, DelphiDoom.Xcom.GeoscapeNavigator,
  DelphiDoom.XcomGeoscape.SavedGameLoader, DelphiDoom.XcomBattleStates.Launcher, DelphiDoom.XcomBattleStates.Factory,
  DelphiDoom.XcomBattleStates.Screens.Intf, DelphiDoom.XcomBattleStates.MixerAudio,
  DelphiDoom.XcomBattleStates.MissionLauncher, DelphiDoom.XcomMenu.PauseState, DelphiDoom.XcomMenu.MainMenuState, DelphiDoom.XcomMenu.OptionsTypes, DelphiDoom.XcomGeoscape.SavedGameSaver, DelphiDoom.XcomMenu.MenuOptionsNavigator, DelphiDoom.XcomGeoscape.Simulation.Intf, DelphiDoom.XcomMod.Random,
  DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.DefaultSettings,
  DelphiDoom.XcomStrategy.Factory, DelphiDoom.XcomStrategy.Events.Intf, DelphiDoom.XcomGeoscape.Control.Intf,
  DelphiDoom.XcomGeoscape.PopupEvents, DelphiDoom.XcomGeoscape.PopupSimulation, DelphiDoom.XcomStrategy.DefaultSettings,
  DelphiDoom.XcomEngine.State, DelphiDoom.Xcom.VideoDevice.Types, DelphiDoom.Xcom.VideoDeviceSelector,
  DelphiDoom.Xcom.Win.VideoDevice, DelphiDoom.Xcom.Win.OpenGlVideoDevice, DelphiDoom.XcomEngine.FolderShaderCatalog,
  DelphiDoom.XcomEngine.ShaderFileReader;

const
  KEY_FPS = 288;

class function TXcomGameComposition.CreateShaderCatalog(const ASettings: TXcomGameSettings): IXcomShaderCatalog;
begin
  Result := TXcomFolderShaderCatalog.Create(TPath.Combine(ASettings.DataFolder, 'common'),
    TXcomDiskFileSystem.Create);
end;

class function TXcomGameComposition.CreateWindowDevice(AWindow: TXcomWinWindow; const ASettings: TXcomGameSettings;
  const ALog: IXcomLog): IXcomVideoDevice;
var
  LShaders: IXcomShaderCatalog;
begin
  LShaders := CreateShaderCatalog(ASettings);
  Result := TXcomVideoDeviceSelector.Create(
    function: IXcomVideoDevice
    begin
      Result := TXcomWinVideoDevice.Create(AWindow);
    end,
    function: IXcomVideoDevice
    begin
      // the device owns its reader
      Result := TXcomWinOpenGlVideoDevice.Create(AWindow, LShaders,
        TXcomShaderFileReader.Create(TYamlFactory.CreateParser, ALog), ALog);
    end, ALog);
end;

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
  LBrief: TXcomSaveBriefInfo;
  LModLoader: TXcomModGameLoader;
  LOptionsFile: string;
  LOptionsDoc: IYamlNode;
  LModSettings: TArray<TXcomModSetting>;
  LMasterIndex: Integer;
  LModIndex: Integer;
  LDosPath: string;
  LAudio: IXcomAudioDevice;
  LMusic: IXcomMusicPlayer;
  LSavedGameLoader: TXcomSavedGameLoader;
  LBattleAudio: IXcomBattleAudio;
  LBattleScreens: IXcomBattleScreens;
  LMissionLauncher: IXcomMissionLauncher;
  LGame: TXcomGame;
begin
  LFiles := TXcomDiskFileSystem.Create;
  LParser := TYamlFactory.CreateParser;
  LOptions := TXcomOptions.Create;
  try
    LOptionsFile := TPath.Combine(ASettings.UserFolder, 'options.cfg');
    if (ASettings.UserFolder <> '') and LFiles.FileExists(LOptionsFile) then
    begin
      LOptionsDoc := LParser.Load(LFiles.ReadAll(LOptionsFile));
      // with the "mods" section of the file: a save that lists a mod asks for confirmation only when it is not active
      LOptions.Load(LOptionsDoc);
    end;
    // Options::refreshMods: the master the program runs is always in the list and active. Without it (no options.cfg
    // yet) a save was written with no mods, and the list of the saves takes such a file for one of xcom1
    LMasterIndex := -1;
    LModSettings := LOptions.Mods;
    for LModIndex := 0 to High(LModSettings) do
      if LModSettings[LModIndex].Id = ASettings.ModId then
        LMasterIndex := LModIndex;
    if LMasterIndex < 0 then
      LModSettings := [TXcomModSetting.Create(ASettings.ModId, True)] + LModSettings
    else
      LModSettings[LMasterIndex].Active := True;
    LOptions.Mods := LModSettings;
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
    // the display filters of the video options: listed as in OpenXcom also when the display cannot use them
    Result.SetShaderCatalog(CreateShaderCatalog(ASettings));
    // the mods of the data folder and of the user (Options::refreshMods); the game that is installed is the master
    Result.SetModCatalog(TXcomDiskModCatalog.Create(
      [TPath.Combine(ASettings.DataFolder, 'standard'), TPath.Combine(ASettings.UserFolder, 'mods')],
      [ASettings.ModId], LParser));
    if ASettings.AudioOutput <> nil then
    begin
      TXcomAudioFactory.CreateAudio(LOptions, ASettings.AudioOutput, 0, LAudio, LMusic);
      Result.SetAudioDevice(LAudio);
      Result.SetMusicPlayer(LMusic);
      if Assigned(ASettings.OnAudio) then
        ASettings.OnAudio(LAudio as IXcomMixerMeter);
    end;
    Result.SetSaveCatalog(TXcomDiskSaveCatalog.Create(LOptions.MasterUserFolder, ASettings.ModId, LParser));
    // the list of the modes of the monitor: always with the window (the screenshots of the tests ask for it)
    if ASettings.ListModes or ASettings.WindowMode then
      Result.SetDisplayModes(TXcomWinDisplayModes.Create);
    // the battle: its sounds on the channels of the mixer, its screens and the way into a mission
    LBattleAudio := nil;
    if LAudio <> nil then
      LBattleAudio := TXcomBattleMixerAudio.Create(Result, LAudio as IXcomChannelMixer);
    // an anonymous method cannot capture Result
    LGame := Result;
    LBattleScreens := TXcomBattleFactory.CreateScreens(Result,
      function(AParent: TXcomState): TXcomState
      begin
        Result := TXcomPauseState.Create(AParent.Host, ooBattlescape,
          TXcomMenuOptionsNavigator.Create(ASettings.VersionText));
      end,
      function: TXcomState
      begin
        // DebriefingState::btnOkClick of a battle outside a campaign: back to the main menu
        Result := TXcomMainMenuState.Create(LGame, ASettings.VersionText);
      end);
    LMissionLauncher := ASettings.MissionLauncher;
    if LMissionLauncher = nil then
      LMissionLauncher := TXcomMissionLauncher.Create(Result, LBattleScreens, LBattleAudio);
    LSimulationFactory :=
      function(AHost: TXcomStateHost; ASave: TXcomSavedGame; ARuleset: TXcomRuleset;
        const ARandom: IXcomRandom): IXcomGeoscapeSimulation
      var
        LListener: IXcomGeoscapeEvents;
      begin
        // the events are shown as the popups of the geoscape that receives the simulation
        LListener := TXcomPopupGeoscapeEvents.Create(AHost, LMissionLauncher);
        Result := TXcomPopupSimulation.Create(
          TXcomStrategyFactory.CreateSimulation(ASave, ARuleset, nil, ARandom, nil, LListener,
            TXcomDefaultStrategySettings.Create, TXcomDefaultSaveSettings.Create, True),
          LListener as IXcomGeoscapeAware);
      end;
    LNavigatorFactory :=
      function(AHost: TXcomStateHost): IXcomGeoscapeNavigator
      begin
        Result := TXcomGameNavigator.Create(AHost, TXcomMenuOptionsNavigator.Create(ASettings.VersionText));
      end;
    Result.SetNewGameStarter(TXcomNewGameStarter.Create(Result, ASettings.Seed, LSimulationFactory, LNavigatorFactory));
    LSavedGameLoader := TXcomSavedGameLoader.Create(Result, LSimulationFactory, LNavigatorFactory);
    // a saved game with a battle in progress goes on in the battlescape, over the geoscape
    LSavedGameLoader.BattleResumer :=
      procedure(AHost: TXcomStateHost)
      begin
        TXcomBattleLauncher.Resume(AHost, LBattleScreens, LBattleAudio);
      end;
    Result.SetSavedGameLoader(LSavedGameLoader);
    LBrief.Version := '1.0';
    LBrief.Engine := '';
    LBrief.Build := '';
    Result.SetSavedGameSaver(TXcomSavedGameSaver.Create(Result, LBrief, ASettings.VersionText));
    Result.SetState(TXcomStartState.Create(Result, LTask, LDosPath, ASettings.VersionText));
  except
    LOptions.Free;
    raise;
  end;
end;

end.
