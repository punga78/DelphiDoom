{******************************************************************************}
{                                                                              }
{  Warcraft32: the composition root of the program                             }
{                                                                              }
{  The only place that knows the classes of Libs\War that make the game, and   }
{  the adapters of this folder (window, sound device, file of the saved game): }
{  it opens DATA.WAR, makes the sound, the game of the scenes and the session  }
{  that saves it, and runs the loop                                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Composition;

interface

uses
  System.SysUtils, DelphiDoom.War.Intf, DelphiDoom.War.Graphics.Intf, DelphiDoom.War.Graphics.Types,
  DelphiDoom.War.Font.Intf, DelphiDoom.War.Campaign.Intf, DelphiDoom.War.Audio.Intf, DelphiDoom.War.Music.Intf,
  DelphiDoom.War.Ui.Intf, DelphiDoom.War.Ui.Game, DelphiDoom.War.App.Options, DelphiDoom.War.App.Settings,
  DelphiDoom.War.App.SceneAudio, DelphiDoom.War.App.SessionTypes;

type
  /// <summary>
  ///   One run of the program. Everything the game needs is made here from the options and handed down as interfaces;
  ///   nothing below this unit knows a concrete class of the others. The data are in a folder that the player gives
  ///   (-data): DATA.WAR is a commercial file and is not in the repository
  /// </summary>
  TWarComposition = class
  strict private
    FOptions: TWarAppOptions;
    FExecutableFolder: string;
    FWrite: TProc<string>;
    FCatalog: IWarCatalog;
    FArchive: IWarArchive;
    FGraphics: IWarGraphics;
    FMetrics: IWarFontMetrics;
    FImages: TArray<TWarImage>;
    FCampaigns: IWarCampaigns;
    FLibrary: IWarAudioLibrary;
    FMixer: IWarSoundMixer;
    FMusic: IWarMusicPlayer;
    FSceneAudio: IWarSceneAudio;
    FSceneAudioObject: TWarSceneAudio;
    FSettings: TWarAppSettings;
    FDataSize: Cardinal;
    constructor Create(const AOptions: TWarAppOptions; const AExecutableFolder: string; const AWrite: TProc<string>);
    procedure Say(const AText: string);
    function SettingsPath: string;
    function QuickSlotPath: string;
    procedure LoadData;
    procedure CreateAudio;
    procedure LoadSettings;
    procedure SaveSettings(const AGame: IWarGameSettings);
    function MakeUiGame(const AStart: TWarSessionStart; const ARequests: IWarSessionRequests): TWarUiGame;
    function MakeSessionGame(const AStart: TWarSessionStart; const ARequests: IWarSessionRequests): IWarSessionGame;
    procedure SaveShot(const APixels: TArray<Byte>; AWidth, AHeight: Integer);
    procedure WriteAudioStatistics(AHost: TObject);
    function RunScript: Integer;
    function RunSession: Integer;
    function Execute: Integer;
  public
    /// <summary>
    ///   Runs the program: returns the frames played (a script counts its own). Whatever cannot start (no DATA.WAR, no
    ///   fonts, a saved game that is not usable) is an exception with a message that says what to do
    /// </summary>
    class function Run(const AOptions: TWarAppOptions; const AExecutableFolder: string;
      const AWrite: TProc<string>): Integer; static;
  end;

implementation

uses
  System.Classes, System.IOUtils, DelphiDoom.Clock.Intf, DelphiDoom.Clock.Factory, DelphiDoom.Configuration.Factory,
  DelphiDoom.GameHost.Audio.Intf, DelphiDoom.GameHost.Video.Intf, DelphiDoom.GameHost.Factory, DelphiDoom.GameHost.Win.Window,
  DelphiDoom.GameHost.Types, DelphiDoom.GameHost.Events.Intf, DelphiDoom.Logging.Intf, DelphiDoom.Logging.Factory,
  DelphiDoom.Platform.DataFolder.Intf, DelphiDoom.Platform.DataFolder.Factory, DelphiDoom.Png.Provider,
  DelphiDoom.Png.Intf, DelphiDoom.War.Types, DelphiDoom.War.Factory, DelphiDoom.War.Campaign.Catalog,
  DelphiDoom.War.Level.Factory, DelphiDoom.War.Map.Factory, DelphiDoom.War.Sound.SeededRandom,
  DelphiDoom.War.Sound.Intf, DelphiDoom.War.Audio.Factory, DelphiDoom.War.Audio.Types,
  DelphiDoom.War.Music.Factory, DelphiDoom.War.Ui.Factory, DelphiDoom.War.Ui.FontImageLoader,
  DelphiDoom.War.Ui.ScriptRunner, DelphiDoom.War.MapUi.Launcher, DelphiDoom.War.App.DataLocator,
  DelphiDoom.War.App.Intf, DelphiDoom.War.App.Session, DelphiDoom.War.App.Runner,
  DelphiDoom.War.App.UiSessionGame, DelphiDoom.War.App.SessionEventSink, DelphiDoom.War.App.FrameConverter,
  DelphiDoom.War.HostWindow, DelphiDoom.War.HostAudio, DelphiDoom.War.FileSaveStorage;

resourcestring
  SWarNoDataWar = 'DATA.WAR of Warcraft: Orcs & Humans was not found. The game is not in this program: give the folder ' +
    'that has it (or its folder DATA) with -data <folder>. Looked in:' + sLineBreak + '%s';
  SWarNoFont = 'The font %s of the remake (the images war1_font_1.png and war1_font_2.png, in Reference\war1\assets) ' +
    'was not found: give their folder with -fonts <folder>, or put them in the data folder. Looked in:' + sLineBreak +
    '%s';
  SWarScriptWithSave = '-save and -load do not work with -script: a script moves the input of the game itself, ' +
    'and that is not in a saved game';

const
  PICTURE_WIDTH = 320;
  PICTURE_HEIGHT = 200;
  WINDOW_TITLE = 'Warcraft32';
  // 1/60 of a second of the sound of a run with no device, at 44100 samples a second
  HEADLESS_SAMPLES_PER_FRAME = 735;
  // a run with no window that is not told how long to go plays half a minute of the game
  HEADLESS_DEFAULT_FRAMES = 1800;

{ TWarComposition }

class function TWarComposition.Run(const AOptions: TWarAppOptions; const AExecutableFolder: string;
  const AWrite: TProc<string>): Integer;
var
  LProgram: TWarComposition;
begin
  LProgram := TWarComposition.Create(AOptions, AExecutableFolder, AWrite);
  try
    Result := LProgram.Execute;
  finally
    LProgram.Free;
  end;
end;

constructor TWarComposition.Create(const AOptions: TWarAppOptions; const AExecutableFolder: string;
  const AWrite: TProc<string>);
begin
  inherited Create;
  FOptions := AOptions;
  FExecutableFolder := AExecutableFolder;
  FWrite := AWrite;
  FSettings := TWarAppSettings.Standard;
end;

procedure TWarComposition.Say(const AText: string);
begin
  if Assigned(FWrite) then
    FWrite(AText);
end;

function TWarComposition.SettingsPath: string;
begin
  Result := TPath.Combine(FExecutableFolder, WAR_SETTINGS_FILE_NAME);
end;

function TWarComposition.QuickSlotPath: string;
begin
  Result := TPath.Combine(TPath.Combine(FExecutableFolder, 'SAVES'), 'quick.war1sav');
end;

procedure TWarComposition.LoadData;
var
  LLocator: IDataFolderLocator;
  LFolders: TArray<string>;
  LFontFolders: TArray<string>;
  LPath: string;
  LFont: Integer;
  LStream: TFileStream;
  LExists: TWarFileExists;
begin
  LExists := function(const APath: string): Boolean
    begin
      Result := TFile.Exists(APath);
    end;
  LLocator := TDataFolderFactory.CreateLocator;
  LFolders := [LLocator.Locate(FExecutableFolder, FOptions.DataFolder)];
  if FOptions.DataFolder = '' then
    LFolders := LFolders + [FExecutableFolder, GetCurrentDir];
  LPath := TWarDataLocator.FindDataWar(LFolders, LExists);
  if LPath = '' then
    raise EWarException.CreateFmt(SWarNoDataWar, [string.Join(sLineBreak, TWarDataLocator.DataWarCandidates(LFolders))]);
  LFontFolders := LFolders;
  if FOptions.FontFolder <> '' then
    LFontFolders := [FOptions.FontFolder] + LFolders;
  SetLength(FImages, 2);
  for LFont := 0 to 1 do
  begin
    LPath := TWarDataLocator.FindFont(LFont, LFontFolders, LExists);
    if LPath = '' then
      raise EWarException.CreateFmt(SWarNoFont, [Format('war1_font_%d.png', [LFont + 1]),
        string.Join(sLineBreak, LFontFolders)]);
    FImages[LFont] := TWarFontImageLoader.Load(LPath, TPngProvider.Client);
  end;
  LPath := TWarDataLocator.FindDataWar(LFolders, LExists);
  LStream := TFileStream.Create(LPath, fmOpenRead or fmShareDenyNone);
  try
    FDataSize := Cardinal(LStream.Size);
  finally
    LStream.Free;
  end;
  FCatalog := TWarFactory.CreateCatalog;
  FArchive := TWarFactory.OpenFile(LPath, FCatalog);
  FGraphics := TWarFactory.CreateGraphics(FArchive, FCatalog);
  FMetrics := TWarFactory.CreateFontMetrics;
  FCampaigns := TWarCampaigns.Create;
end;

procedure TWarComposition.CreateAudio;
var
  LLog: ILog;
begin
  LLog := TLogFactory.CreateLog(nil, nil);
  FLibrary := TWarAudioFactory.CreateLibrary(FArchive, FCatalog);
  FMixer := TWarAudioFactory.CreateMixer(FLibrary);
  // the songs are read and followed (the timeline of Libs\Midi); the synthesizer is the silent one: the SoundFont of the
  // remake has no declared license (see Libs\War\CLAUDE.md)
  FMusic := TWarMusicFactory.CreatePlayer(TWarMusicFactory.CreateSilentSynth, TWarMusicFactory.CreateTimeline(LLog));
  FSceneAudioObject := TWarSceneAudio.Create(FLibrary, FMixer, FMusic);
  FSceneAudio := FSceneAudioObject;
end;

procedure TWarComposition.LoadSettings;
var
  LLines: TArray<string>;
begin
  if TFile.Exists(SettingsPath) then
  begin
    LLines := TFile.ReadAllLines(SettingsPath);
    TWarAppSettings.TryFromLines(TConfigurationFactory.CreateFormat, LLines, FSettings);
  end;
end;

procedure TWarComposition.SaveSettings(const AGame: IWarGameSettings);
begin
  TFile.WriteAllLines(SettingsPath, TWarAppSettings.FromGame(AGame).ToLines(TConfigurationFactory.CreateFormat));
end;

function TWarComposition.MakeUiGame(const AStart: TWarSessionStart; const ARequests: IWarSessionRequests): TWarUiGame;
var
  LLauncher: IWarMapLauncher;
begin
  // one generator of random numbers for the whole game: the interface and the model draw from it in the order of the
  // original. The directions are the ones of the C built with gcc, which is where the golden files come from
  LLauncher := TWarMapLauncher.Create(TWarLevelFactory.CreateLevelLoader(FArchive, FCatalog), FGraphics,
    TWarMapFactory.CreateUnitCatalog, TWarLevelFactory.CreateObjectives, TWarSeededRandom.Create(AStart.Seed), True);
  Result := TWarUiFactory.CreateGame(FArchive, FCatalog, FGraphics, FMetrics, FImages, FCampaigns, FSceneAudio,
    LLauncher, PICTURE_WIDTH, PICTURE_HEIGHT, ARequests);
  FSettings.ApplyTo(Result.Settings);
end;

function TWarComposition.MakeSessionGame(const AStart: TWarSessionStart;
  const ARequests: IWarSessionRequests): IWarSessionGame;
begin
  Result := TWarUiSessionGame.Create(MakeUiGame(AStart, ARequests), AStart, FCampaigns, PICTURE_WIDTH, PICTURE_HEIGHT);
end;

procedure TWarComposition.SaveShot(const APixels: TArray<Byte>; AWidth, AHeight: Integer);
begin
  if FOptions.ShotPath = '' then
    Exit;
  TFile.WriteAllBytes(FOptions.ShotPath, TPngProvider.Client.Encode(TWarFrameConverter.ToBgra(APixels,
    AWidth * AHeight), AWidth, AHeight, DDPNG_FORMAT_BGRA));
  Say('Picture saved in ' + FOptions.ShotPath);
end;

procedure TWarComposition.WriteAudioStatistics(AHost: TObject);
begin
  Say(Format('Sounds started %d, songs started %d, songs stopped %d, sounds that could not be played %d, voices still ' +
    'sounding %d', [FSceneAudioObject.SoundsStarted, FSceneAudioObject.SongsStarted, FSceneAudioObject.SongsStopped,
    FSceneAudioObject.Failures, FMixer.ActiveVoices]));
  if AHost is TWarHostAudio then
    Say(Format('Buffers played by the sound device %d', [TWarHostAudio(AHost).CompletedBuffers]));
end;

function TWarComposition.RunScript: Integer;
var
  LGame: TWarUiGame;
  LOutput: TStringList;
  LRunner: TWarUiScriptRunner;
  LStart: TWarSessionStart;
  LLine: string;
begin
  if (FOptions.SavePath <> '') or (FOptions.LoadPath <> '') then
    raise EWarException.Create(SWarScriptWithSave);
  LStart := Default(TWarSessionStart);
  LStart.Seed := FOptions.Seed;
  LGame := MakeUiGame(LStart, nil);
  try
    LOutput := TStringList.Create;
    try
      LRunner := TWarUiScriptRunner.Create(LGame, LOutput, nil);
      try
        LRunner.RunFile(FOptions.ScriptPath);
      finally
        LRunner.Free;
      end;
      for LLine in LOutput do
        Say(LLine);
      Result := LGame.Manager.FrameCount;
    finally
      LOutput.Free;
    end;
    SaveShot(LGame.Canvas.Blitter.Pixels, PICTURE_WIDTH, PICTURE_HEIGHT);
  finally
    LGame.Free;
  end;
end;

function TWarComposition.RunSession: Integer;
var
  LStart: TWarSessionStart;
  LSession: TWarSession;
  LRunner: TWarRunner;
  LStorage: IWarSaveStorage;
  LSink: TWarSettingsSink;
  LBuffer: TArray<SmallInt>;
  LSessionSink: IGameHostEventSink;
  LWindow: TGameHostWinWindow;
  LDevice: IGameHostVideoDevice;
  LPresenter: IWarFramePresenter;
  LAudio: TWarHostAudio;
  LClock: IClock;
  LFrames: Integer;
  LCenter: TGameHostEvent;
  LTimer: ITimerResolutionLease;
begin
  LStart := Default(TWarSessionStart);
  LStart.Seed := FOptions.Seed;
  if FOptions.PlayMission > 0 then
  begin
    LStart.Race := Byte(Ord(FOptions.PlayRace));
    LStart.Mission := Byte(FOptions.PlayMission);
  end;
  LStorage := TWarFileSaveStorage.Create(QuickSlotPath);
  LSession := TWarSession.Create(
    function(const AStart: TWarSessionStart; const ARequests: IWarSessionRequests): IWarSessionGame
    begin
      Result := MakeSessionGame(AStart, ARequests);
    end, LStart, FDataSize,
    procedure
    begin
      FSceneAudioObject.Muted := True;
    end,
    procedure
    begin
      FSceneAudioObject.Muted := False;
    end);
  try
    if FOptions.LoadPath <> '' then
      LSession.Load(TFile.ReadAllBytes(FOptions.LoadPath));
    LAudio := nil;
    LWindow := nil;
    if FOptions.Headless then
    begin
      // no device: the mixer is driven by the frames, as a device would drive it, so that the voices end
      SetLength(LBuffer, HEADLESS_SAMPLES_PER_FRAME);
      if FOptions.LoadPath = '' then
      begin
        // the mouse of a run with no window is in the middle of the picture, not in a corner where the map would scroll
        LCenter := TGameHostEvent.Make(hekMouseMotion);
        LCenter.X := PICTURE_WIDTH div 2;
        LCenter.Y := PICTURE_HEIGHT div 2;
        LSession.Post(LCenter);
      end;
      LSink := procedure(const ASettings: IWarGameSettings)
        begin
          FSceneAudioObject.Synchronize(ASettings);
          FMixer.Mix(@LBuffer[0], Length(LBuffer));
        end;
      LRunner := TWarRunner.Create(LSession, nil, nil, nil, LStorage, LSink);
      try
        LFrames := FOptions.QuitAfterFrames;
        if LFrames = 0 then
          LFrames := HEADLESS_DEFAULT_FRAMES;
        Result := LRunner.Run(LFrames);
      finally
        LRunner.Free;
      end;
      if FOptions.AudioStatistics then
        WriteAudioStatistics(nil);
    end
    else
    begin
      LSessionSink := TWarSessionEventSink.Create(LSession, FOptions.Scale);
      LWindow := TGameHostFactory.CreateWindow(WINDOW_TITLE, LSessionSink, True);
      try
        // Alt and F10 are keys of the game: they must not open the menu of the window
        LWindow.Translator.SuppressKeyMenu := True;
        LDevice := TGameHostFactory.CreateGdiDevice(LWindow);
        LPresenter := TWarHostWindow.Create(LDevice, WINDOW_TITLE, PICTURE_WIDTH * FOptions.Scale,
          PICTURE_HEIGHT * FOptions.Scale);
        if not FOptions.NoSound then
        begin
          LAudio := TWarHostAudio.Create(TGameHostFactory.CreatePcmOutput, TWarAudioFactory.CreatePcmSource(FMixer,
            FMusic), WAR_PLAYBACK_RATE);
          if not LAudio.Open then
            Say('No sound device: the game is played without sound');
        end;
        // a wait of a millisecond lasts a millisecond, not the 15 of the default timer: the loop waits for 1/60 of a second
        LTimer := TClockFactory.AcquireTimerResolution(1);
        LClock := TClockFactory.CreateClock(TLogFactory.CreateLog(nil, nil));
        LRunner := TWarRunner.Create(LSession, LPresenter, LClock,
          function: Boolean
          begin
            Result := LWindow.Pump;
          end, LStorage,
          procedure(const ASettings: IWarGameSettings)
          begin
            FSceneAudioObject.Synchronize(ASettings);
          end);
        try
          Result := LRunner.Run(FOptions.QuitAfterFrames);
        finally
          LRunner.Free;
        end;
        SaveSettings(LSession.Game.Settings);
        if FOptions.AudioStatistics then
          WriteAudioStatistics(LAudio);
      finally
        LAudio.Free;
        LPresenter := nil;
        LDevice := nil;
        LWindow.Free;
      end;
    end;
    SaveShot(LSession.Game.Pixels, LSession.Game.Width, LSession.Game.Height);
    if FOptions.SavePath <> '' then
    begin
      ForceDirectories(ExtractFilePath(ExpandFileName(FOptions.SavePath)));
      TFile.WriteAllBytes(FOptions.SavePath, LSession.Save);
      Say(Format('Game saved in %s (%d frames)', [FOptions.SavePath, LSession.FrameCount]));
    end;
  finally
    LSession.Free;
  end;
end;

function TWarComposition.Execute: Integer;
begin
  LoadData;
  CreateAudio;
  LoadSettings;
  if FOptions.ScriptPath <> '' then
    Result := RunScript
  else
    Result := RunSession;
end;

end.
