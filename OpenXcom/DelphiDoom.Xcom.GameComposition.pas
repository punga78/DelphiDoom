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
  DelphiDoom.Clock.Intf,
  System.SysUtils, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.Game, DelphiDoom.XcomEngine.QueueEventSource,
  DelphiDoom.XcomEngine.Options, DelphiDoom.XcomEngine.TrueColor.Intf,
  DelphiDoom.XcomAudio.Intf, DelphiDoom.XcomGeoscape.MissionLauncher.Intf, DelphiDoom.GameHost.Win.Window,
  DelphiDoom.Xcom.LoggingBattleAudio, DelphiDoom.Yaml.Intf, DelphiDoom.XcomSurface.FontOverlay.Intf,
  DelphiDoom.XcomSurface.FontDetail.Intf, DelphiDoom.XcomSurface.Glyph.Types,
  DelphiDoom.XcomSurface.GlyphRasterizer.Intf, DelphiDoom.XcomEngine.FontSettingsSource.Intf,
  DelphiDoom.XcomEngine.FontReloader.Intf;

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
    /// <summary>Every sound the battle asks for is written here as a line (nil: no log)</summary>
    BattleSoundLog: TXcomSoundLogLine;
    /// <summary>The seed of the random numbers of a new game (-seed); 0 takes it from the clock</summary>
    Seed: UInt64;
    /// <summary>Starts the battle of a mission (the Battlescape's); nil: "Yes" of the landing confirmation does nothing</summary>
    MissionLauncher: IXcomMissionLauncher;
    /// <summary>
    ///   The frame is composed in true color (-truecolor, or "trueColor: true" in the options file; issue 183):
    ///   the game stays at 8 bits and the screen makes the final picture of colors. Off: the 8 bit path of OpenXcom
    /// </summary>
    TrueColor: Boolean;
    /// <summary>
    ///   The file with the fonts of Windows that replace the pictures of the characters (-fonts); empty: fonts.cfg
    ///   of the user folder, and without that file the fonts are the pictures of the game
    /// </summary>
    FontsFile: string;
    /// <summary>Folders laid over the data, as a mod with a Language\Font.dat of its own (-modfolder, repeatable)</summary>
    ModFolders: TArray<string>;
    /// <summary>Where the warnings of the start go (a font that is not used); nil for nowhere</summary>
    Log: IXcomLog;
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
      const AClock: IClock; AEvents: TXcomQueueEventSource): TXcomGame; static;
    /// <summary>
    ///   The display of the game in a window: GDI, or OpenGL when Options::useOpenGL asks for it and a context can
    ///   be made (the screen says which at every change of mode). The window is not owned: the caller frees it
    ///   after the last reference to the display is gone
    /// </summary>
    /// <param name="ASettings">The data folder: the shaders of the display filter are in its common\Shaders</param>
    /// <param name="ALog">Where the version of OpenGL and the reason of a fallback to GDI go; nil for nowhere</param>
    class function CreateWindowDevice(AWindow: TGameHostWinWindow; const ASettings: TXcomGameSettings;
      const ALog: IXcomLog): IXcomVideoDevice; static;
    /// <summary>The shaders that the video options list and the OpenGL display reads</summary>
    class function CreateShaderCatalog(const ASettings: TXcomGameSettings): IXcomShaderCatalog; static;
    /// <summary>CrossPlatform::getDosPath: the path of the program as a DOS prompt (names cut to 8 characters)</summary>
    class function DosPathOf(const AExecutable: string): string; static;
    /// <summary>
    ///   The strategy the screen flips with: a composer of frames in true color when the settings or the options
    ///   file ask for it and the display can show them, nil (the 8 bit path) otherwise
    /// </summary>
    class function CreateFrameComposer(const ASettings: TXcomGameSettings; AOptions: TXcomOptions;
      const ADevice: IXcomVideoDevice): IXcomFrameComposer; static;
    /// <summary>
    ///   The fonts of Windows of the options as a source of the characters (TXcomFontSettingsReader says the
    ///   format of the file), or nil when there is no file or it lists no font
    /// </summary>
    class function CreateFontOverlay(const ASettings: TXcomGameSettings; const AFiles: IXcomFileSystem;
      const AParser: IYamlParser; const AComposer: IXcomFrameComposer = nil): IXcomFontOverlay; static;
    /// <summary>
    ///   The choice of the fonts: the entries of fonts.cfg of the user folder (or of -fonts, which then cannot be
    ///   changed in the options), as the rows of the advanced options and as the source of the fonts
    /// </summary>
    class function CreateFontChoices(const ASettings: TXcomGameSettings; const AFiles: IXcomFileSystem;
      const AParser: IYamlParser): IXcomFontSettingsSource; static;
    /// <summary>
    ///   The overlay for some entries (nil for none); with a composer that composes in true color the fonts also
    ///   draw their text at the resolution of the display
    /// </summary>
    class function MakeFontOverlay(const ASettings: TArray<TXcomFontOverlaySettings>; const ALog: IXcomLog;
      const AFactory: IXcomGlyphRasterizerFactory; const AComposer: IXcomFrameComposer): IXcomFontOverlay; static;
    /// <summary>
    ///   Xcom32 -fontgrid: the characters of the fonts of the options written as the pictures and the Font.dat of a
    ///   mod, in AFolder\Language (to load with -modfolder, or to copy in a mod of OpenXcom). The number of pictures
    /// </summary>
    /// <exception cref="EXcomEngineException">The options list no font</exception>
    class function GenerateFontGrids(const ASettings: TXcomGameSettings; const AFolder: string): Integer; static;
  end;

implementation

uses
  System.IOUtils, System.Generics.Collections, DelphiDoom.XcomSave.Soldier, DelphiDoom.XcomMenu.CutsceneState,
  DelphiDoom.XcomBasescape.StatisticsState,
  DelphiDoom.XcomDebriefing.CommendationState, DelphiDoom.XcomUfopaedia.Intf, DelphiDoom.XcomUfopaedia.Factory, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Factory, DelphiDoom.Png.Provider,
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Screen, DelphiDoom.XcomEngine.TrueColorComposer,
  DelphiDoom.Xcom.TrueColorOption,
  DelphiDoom.XcomEngine.Language, DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomEngine.DiskFileSystem,
  DelphiDoom.XcomEngine.ModGameLoader, DelphiDoom.XcomEngine.GameLoader.Intf, DelphiDoom.XcomEngine.GameLoadTask, DelphiDoom.XcomEngine.ThreadLoadTask,
  DelphiDoom.XcomEngine.ImmediateLoadTask, DelphiDoom.XcomEngine.HeldLoadTask, DelphiDoom.XcomUi.Cursor,
  DelphiDoom.XcomUi.FpsCounter, DelphiDoom.XcomMenu.StartState, DelphiDoom.XcomEngine.FileOptionsStore,
  DelphiDoom.XcomEngine.FolderLanguageProvider, DelphiDoom.Xcom.Win.DisplayModes,
  DelphiDoom.Xcom.Win.FolderOpener, DelphiDoom.XcomEngine.DiskSaveCatalog, DelphiDoom.XcomEngine.Music.Intf, DelphiDoom.XcomAudio.Factory,
  DelphiDoom.XcomAudio.Types, DelphiDoom.XcomEngine.DiskModCatalog,
DelphiDoom.XcomGeoscape.NewGameStarter, DelphiDoom.XcomGeoscape.Navigator.Intf, DelphiDoom.Xcom.GeoscapeNavigator,
  DelphiDoom.Xcom.NewBattleNavigator,
  DelphiDoom.XcomGeoscape.SavedGameLoader, DelphiDoom.XcomBattleStates.Launcher, DelphiDoom.XcomBattleStates.Factory,
  DelphiDoom.XcomBattleStates.Screens.Intf, DelphiDoom.XcomBattleStates.MixerAudio,
  DelphiDoom.XcomBattleStates.MissionLauncher, DelphiDoom.XcomMenu.PauseState, DelphiDoom.XcomMenu.MainMenuState, DelphiDoom.XcomMenu.OptionsTypes, DelphiDoom.XcomGeoscape.SavedGameSaver, DelphiDoom.XcomMenu.MenuOptionsNavigator, DelphiDoom.XcomGeoscape.Simulation.Intf, DelphiDoom.XcomMod.Random,
  DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.DefaultSettings,
  DelphiDoom.XcomStrategy.Factory, DelphiDoom.XcomStrategy.Events.Intf, DelphiDoom.XcomGeoscape.Control.Intf,
  DelphiDoom.XcomGeoscape.PopupEvents, DelphiDoom.XcomGeoscape.PopupSimulation, DelphiDoom.XcomStrategy.DefaultSettings,
  DelphiDoom.XcomEngine.State, DelphiDoom.Logging.Intf, DelphiDoom.GameHost.Video.Intf,
  DelphiDoom.GameHost.OpenGl.Factory,
  DelphiDoom.Xcom.HostVideoDevice, DelphiDoom.Xcom.HostShaderLoader, DelphiDoom.Xcom.HostLog,
  DelphiDoom.XcomEngine.FolderShaderCatalog,
  DelphiDoom.XcomEngine.ShaderFileReader, DelphiDoom.XcomEngine.RasterFontOverlay,
  DelphiDoom.Xcom.Win.GdiGlyphRasterizerFactory, DelphiDoom.XcomEngine.FileMap, DelphiDoom.XcomEngine.PngSurfaceLoader,
  DelphiDoom.XcomEngine.FontRuleReader, DelphiDoom.XcomEngine.FontGridGenerator, DelphiDoom.Png.PaletteEncoder,
  DelphiDoom.Zlib.Provider, DelphiDoom.XcomEngine.FontChoices, DelphiDoom.XcomEngine.FontReloader,
  DelphiDoom.XcomEngine.ExtraOptionSet, DelphiDoom.XcomEngine.ExtraOptions.Intf,
  DelphiDoom.Xcom.Win.GdiSystemFonts;

const
  KEY_FPS = 288;
  FONTS_FILE = 'fonts.cfg';
  SNoFontsToDraw = 'No font to draw: -fontgrid needs a fonts.cfg (in the user folder, or -fonts) that lists a font';

class function TXcomGameComposition.CreateFontOverlay(const ASettings: TXcomGameSettings;
  const AFiles: IXcomFileSystem; const AParser: IYamlParser;
  const AComposer: IXcomFrameComposer): IXcomFontOverlay;
var
  LChoices: IXcomFontSettingsSource;
begin
  LChoices := CreateFontChoices(ASettings, AFiles, AParser);
  Result := MakeFontOverlay(LChoices.Settings, ASettings.Log, TXcomGdiGlyphRasterizerFactory.Create, AComposer);
end;

class function TXcomGameComposition.CreateFontChoices(const ASettings: TXcomGameSettings;
  const AFiles: IXcomFileSystem; const AParser: IYamlParser): IXcomFontSettingsSource;
var
  LPath: string;
begin
  LPath := '';
  if ASettings.UserFolder <> '' then
    LPath := TPath.Combine(ASettings.UserFolder, FONTS_FILE);
  // a file that was asked for by name and is not there is said; the default one is simply optional
  if (ASettings.FontsFile <> '') and not AFiles.FileExists(ASettings.FontsFile) and Assigned(ASettings.Log) then
    ASettings.Log.Write('WARN', 'fonts: ' + ASettings.FontsFile + ' not found: the fonts are the pictures of the game');
  Result := TXcomFontChoices.Create(AFiles, AParser, LPath, ASettings.FontsFile, TXcomGdiSystemFonts.Create,
    ASettings.Log);
end;

class function TXcomGameComposition.MakeFontOverlay(const ASettings: TArray<TXcomFontOverlaySettings>;
  const ALog: IXcomLog; const AFactory: IXcomGlyphRasterizerFactory;
  const AComposer: IXcomFrameComposer): IXcomFontOverlay;
var
  LInk: IXcomInkLayers;
begin
  Result := nil;
  if Length(ASettings) = 0 then
    Exit;
  // with a screen that composes in true color the fonts also draw the text at the resolution of the display
  if Assigned(AComposer) and Supports(AComposer, IXcomInkLayers, LInk) then
    Result := TXcomRasterFontOverlay.Create(ASettings, AFactory, ALog, AComposer.DetailLayers, LInk)
  else
    Result := TXcomRasterFontOverlay.Create(ASettings, AFactory, ALog);
end;

function CreateFontReloader(const ASettings: TXcomGameSettings; const AChoices: IXcomFontSettingsSource;
  const AFactory: IXcomGlyphRasterizerFactory; const AComposerSource: TXcomFrameComposerSource): IXcomFontReloader;
var
  LLog: IXcomLog;
begin
  // In a function of its own (see CreateBattleScreens). The overlay is made when the options are confirmed, with
  // the composer the screen has by then: turning "32-bit drawing" on and confirming gives the fonts their sharp text
  LLog := ASettings.Log;
  Result := TXcomFontReloader.Create(AChoices,
    function(const AFonts: TArray<TXcomFontOverlaySettings>): IXcomFontOverlay
    var
      LComposer: IXcomFrameComposer;
    begin
      LComposer := nil;
      if Assigned(AComposerSource) then
        LComposer := AComposerSource();
      Result := TXcomGameComposition.MakeFontOverlay(AFonts, LLog, AFactory, LComposer);
    end);
end;

class function TXcomGameComposition.GenerateFontGrids(const ASettings: TXcomGameSettings;
  const AFolder: string): Integer;
var
  LFiles: IXcomFileSystem;
  LParser: IYamlParser;
  LOverlay: IXcomFontOverlay;
  LMap: TXcomFileMap;
  LGenerator: TXcomFontGridGenerator;
begin
  LFiles := TXcomDiskFileSystem.Create;
  LParser := TYamlFactory.CreateParser;
  LOverlay := CreateFontOverlay(ASettings, LFiles, LParser);
  if LOverlay = nil then
    raise EXcomEngineException.Create(SNoFontsToDraw);
  // only the common data: the folders of -modfolder are not read, so a folder can be made again over itself
  LMap := TXcomFileMap.Create(LFiles);
  try
    LMap.AddRoot(TPath.Combine(ASettings.DataFolder, 'common'));
    LGenerator := TXcomFontGridGenerator.Create(LFiles, TXcomPngSurfaceLoader.Create(LMap, TPngProvider.Client),
      LOverlay, TPngPaletteEncoder.Create(TZlibProvider.Client));
    try
      Result := LGenerator.Generate(TXcomFontRuleReader.Read(LParser.Load(LMap.ReadAll(
        TXcomFontGridGenerator.LANGUAGE_FOLDER + '/' + TXcomFontGridGenerator.FONT_FILE))), AFolder);
    finally
      // the generator holds the loader, that reads from the map
      LGenerator.Free;
    end;
  finally
    LMap.Free;
  end;
end;

class function TXcomGameComposition.CreateShaderCatalog(const ASettings: TXcomGameSettings): IXcomShaderCatalog;
begin
  Result := TXcomFolderShaderCatalog.Create(TPath.Combine(ASettings.DataFolder, 'common'),
    TXcomDiskFileSystem.Create);
end;

class function TXcomGameComposition.CreateWindowDevice(AWindow: TGameHostWinWindow;
  const ASettings: TXcomGameSettings; const ALog: IXcomLog): IXcomVideoDevice;
var
  LHostLog: ILog;
  LShaders: IGameHostShaderLoader;
begin
  // the display of Libs\GameHost speaks to the log and reads the shaders of the game through two adapters
  LHostLog := nil;
  if Assigned(ALog) then
    LHostLog := TXcomHostLog.Create(ALog);
  LShaders := TXcomHostShaderLoader.Create(CreateShaderCatalog(ASettings),
    TXcomShaderFileReader.Create(TYamlFactory.CreateParser, ALog), ALog);
  Result := TXcomHostVideoDevice.Create(TGameHostOpenGlFactory.CreateSelector(AWindow, LShaders, LHostLog));
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

class function TXcomGameComposition.CreateFrameComposer(const ASettings: TXcomGameSettings;
  AOptions: TXcomOptions; const ADevice: IXcomVideoDevice): IXcomFrameComposer;
var
  LDisplay: IXcomTrueColorDisplay;
begin
  // the one place that chooses between the two ways to the display; the screen and the widgets only see whether
  // they were given a composer
  Result := nil;
  if not (ASettings.TrueColor or TXcomTrueColorOption.Wanted(AOptions)) then
    Exit;
  if Supports(ADevice, IXcomTrueColorDisplay, LDisplay) then
    Result := TXcomTrueColorComposer.Create(LDisplay);
end;

function ComposerSourceOf(const ASettings: TXcomGameSettings; AOptions: TXcomOptions;
  const ADevice: IXcomVideoDevice; const ASeed: IXcomFrameComposer): TXcomFrameComposerSource;
var
  LSettings: TXcomGameSettings;
  LDevice: IXcomVideoDevice;
  LComposer: IXcomFrameComposer;
begin
  // In a function of its own (see CreateBattleScreens). The screen asks at every reset of the display: the row
  // of the advanced options turns the composition on and off while the game runs, and a composer is kept as long
  // as it is wanted
  LSettings := ASettings;
  LDevice := ADevice;
  // the composer the fonts were loaded with is the first one: the ink layers of the fonts belong to it
  LComposer := ASeed;
  Result :=
    function: IXcomFrameComposer
    begin
      // the composer is kept when the setting goes off: turned on again it is the one the fonts know
      if not (LSettings.TrueColor or TXcomTrueColorOption.Wanted(AOptions)) then
        Result := nil
      else
      begin
        if not Assigned(LComposer) then
          LComposer := TXcomGameComposition.CreateFrameComposer(LSettings, AOptions, LDevice);
        Result := LComposer;
      end;
    end;
end;

function CreateBattleScreens(AGame: TXcomGame; const AVersionText: string;
  const ABattleAudio: IXcomBattleAudio): IXcomBattleScreens;
begin
  // In a function of its own: the anonymous methods of one routine share one frame, and in CreateGame that frame
  // also holds the screens that hold the methods (a cycle that was never released)
  Result := TXcomBattleFactory.CreateScreens(AGame,
    function(AParent: TXcomState): TXcomState
    begin
      Result := TXcomPauseState.Create(AParent.Host, ooBattlescape, TXcomMenuOptionsNavigator.Create(AVersionText));
    end,
    function: TXcomState
    begin
      // DebriefingState::btnOkClick of a battle outside a campaign: back to the main menu
      Result := TXcomMainMenuState.Create(AGame, AVersionText);
    end, ABattleAudio,
    function(ACutsceneId: string): TXcomState
    begin
      // the cutscene of a deployment over the debriefing; the ones of the end of the game leave the statistics
      // as the only state (as the lost game of the monthly report does)
      Result := TXcomCutsceneState.Create(AGame, ACutsceneId, nil,
        procedure
        begin
          AGame.SetState(TXcomStatisticsState.Create(AGame));
        end);
    end);
end;

class function TXcomGameComposition.CreateGame(const ASettings: TXcomGameSettings; const ADevice: IXcomVideoDevice;
  const AClock: IClock; AEvents: TXcomQueueEventSource): TXcomGame;
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
  LComposer: IXcomFrameComposer;
  LComposerSource: TXcomFrameComposerSource;
  LScreen: TXcomScreen;
  LFontChoices: IXcomFontSettingsSource;
  LRasterizers: IXcomGlyphRasterizerFactory;
  LFontRows: IXcomExtraOptions;
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
    LLoaderSettings.ExtraFolders := ASettings.ModFolders;
    LModLoader := TXcomModGameLoader.Create(LLoaderSettings, LFiles, LParser, TPngProvider.Client);
    // the strategy screens need the ruleset of the mod
    LModLoader.LoadRules := True;
    // in a variable: an object made inside the argument of a const interface parameter is not counted
    LComposer := CreateFrameComposer(ASettings, LOptions, ADevice);
    LFontChoices := CreateFontChoices(ASettings, LFiles, LParser);
    LRasterizers := TXcomGdiGlyphRasterizerFactory.Create;
    LModLoader.FontOverlay := MakeFontOverlay(LFontChoices.Settings, ASettings.Log, LRasterizers, LComposer);
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
    LComposerSource := ComposerSourceOf(ASettings, LOptions, ADevice, LComposer);
    LScreen := TXcomScreen.Create(LOptions, ADevice, LComposer);
    LScreen.ComposerSource := LComposerSource;
    Result := TXcomGame.Create(LOptions, LScreen,
      TXcomCursor.Create(9, 13),
      TXcomFpsCounter.Create(AClock, 15, 5, 0, 0, LOptions.FpsCounter, KEY_FPS),
      TXcomLanguage.Create('', LOptions.Wordwrap, LFiles, LParser), AClock, AEvents);
    Result.SetOptionsStore(TXcomFileOptionsStore.Create(LFiles, LParser, ASettings.UserFolder));
    Result.SetLanguageProvider(TXcomFolderLanguageProvider.Create(ASettings.DataFolder,
      TPath.Combine(TPath.Combine(ASettings.DataFolder, 'standard'), ASettings.ModId), LFiles, LParser));
    Result.SetFolderOpener(TXcomWinFolderOpener.Create);
    // the display filters of the video options: listed as in OpenXcom also when the display cannot use them
    Result.SetShaderCatalog(CreateShaderCatalog(ASettings));
    // the settings OpenXcom does not have: rows at the end of the advanced options (32-bit drawing, the fonts)
    Supports(LFontChoices, IXcomExtraOptions, LFontRows);
    Result.SetExtraOptions(TXcomExtraOptionSet.Create([TXcomTrueColorOption.Create(LOptions), LFontRows]));
    Result.SetFontReloader(CreateFontReloader(ASettings, LFontChoices, LRasterizers, LComposerSource));
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
    if Assigned(ASettings.BattleSoundLog) then
      LBattleAudio := TXcomLoggingBattleAudio.Create(LBattleAudio, ASettings.BattleSoundLog);
    LBattleScreens := CreateBattleScreens(Result, ASettings.VersionText, LBattleAudio);
    LMissionLauncher := ASettings.MissionLauncher;
    if LMissionLauncher = nil then
      LMissionLauncher := TXcomMissionLauncher.Create(Result, LBattleScreens, LBattleAudio);
    // the New Battle button of the main menu
    Result.SetNewBattleOpener(TXcomNewBattleNavigator.Create(Result, LMissionLauncher));
    LSimulationFactory :=
      function(AHost: TXcomStateHost; ASave: TXcomSavedGame; ARuleset: TXcomRuleset;
        const ARandom: IXcomRandom): IXcomGeoscapeSimulation
      var
        LListener: IXcomGeoscapeEvents;
        LEvents: TXcomPopupGeoscapeEvents;
      begin
        // the events are shown as the popups of the geoscape that receives the simulation
        LEvents := TXcomPopupGeoscapeEvents.Create(AHost, LMissionLauncher,
          procedure(AArticleIds: TArray<string>)
          var
            LUfopaedia: IXcomUfopaediaNavigator;
            LId: string;
          begin
            // one navigator for the articles of one report (Ufopaedia::openArticle of each)
            LUfopaedia := TXcomUfopaediaFactory.CreateNavigator(AHost);
            for LId in AArticleIds do
              LUfopaedia.OpenArticle(LId);
          end);
        // MonthlyReportState::btnOkClick: the soldiers that the month of service gave a medal to
        LEvents.OnMedals :=
          procedure(ASoldiers: TList<TXcomSoldier>)
          begin
            AHost.PushState(TXcomCommendationState.Create(AHost, ASoldiers, ARuleset.Commendations));
          end;
        LListener := LEvents;
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
