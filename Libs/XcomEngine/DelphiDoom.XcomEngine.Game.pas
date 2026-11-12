{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - Game of OpenXcom (the main loop and the    }
{  stack of states)                                                             }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.Game;

interface

uses
  DelphiDoom.Clock.Intf, DelphiDoom.XcomEngine.Ticks,
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf,
  DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomEngine.Language,
  DelphiDoom.XcomEngine.Options, DelphiDoom.XcomEngine.Screen, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomEngine.Resources.Intf, DelphiDoom.XcomEngine.LanguageProvider.Intf,
  DelphiDoom.XcomEngine.OptionsStore.Intf, DelphiDoom.XcomEngine.FolderOpener.Intf, DelphiDoom.XcomEngine.SaveCatalog.Intf, DelphiDoom.XcomEngine.SoundConverter,
  DelphiDoom.XcomEngine.Session.Intf, DelphiDoom.XcomEngine.Music.Intf, DelphiDoom.XcomEngine.Volume,
  DelphiDoom.XcomEngine.ModCatalog.Intf, DelphiDoom.XcomEngine.SoundFormats.Intf,
  DelphiDoom.XcomEngine.UiSounds.Intf, DelphiDoom.XcomEngine.HostUiSounds,
  DelphiDoom.XcomEngine.ExtraOptions.Intf;

type
  /// <summary>ApplicationState of Game::run: what the pauseMode option makes of a game without the focus</summary>
  TXcomRunningState = (rsRunning, rsSlowed, rsPaused);

  /// <summary>The handler of the screenshot key: it receives the screen to save</summary>
  TXcomScreenshotHandler = reference to procedure(AScreen: TXcomScreen);

  /// <summary>
  ///   The main loop: it reads the events and gives them to the state on top, lets it think, and draws the states
  ///   that are visible (from the last full screen one) with the fps counter and the cursor, on the screen. The
  ///   window, the clock and the events are the devices that are given. The loop is one step at a time (RunFrame)
  ///   so that a test or a screenshot can drive it with a clock that it controls
  /// </summary>
  TXcomGame = class(TXcomStateHost)
  strict private
    FOptions: TXcomOptions;
    FScreen: TXcomScreen;
    FCursor: TXcomInteractiveSurface;
    FFpsCounter: TXcomInteractiveSurface;
    FLanguage: TXcomLanguage;
    FResources: IXcomResources;
    FClock: IClock;
    FEvents: IXcomEventSource;
    FStates: TObjectList<TXcomState>;
    FDeleted: TObjectList<TXcomState>;
    FQuit: Boolean;
    FInit: Boolean;
    FMouseActive: Boolean;
    FRunningState: TXcomRunningState;
    FTimeOfLastFrame: Cardinal;
    FFrames: Integer;
    FOnScreenshot: TXcomScreenshotHandler;
    FLanguageProvider: IXcomLanguageProvider;
    FDisplayModes: IXcomDisplayModes;
    FShaderCatalog: IXcomShaderCatalog;
    FExtraOptions: IXcomExtraOptions;
    FOptionsStore: IXcomOptionsStore;
    FAudio: IXcomAudioDevice;
    FMusic: IXcomMusicPlayer;
    FModCatalog: IXcomModCatalog;
    FFolderOpener: IXcomFolderOpener;
    FSaveCatalog: IXcomSaveCatalog;
    FNewGameStarter: IXcomNewGameStarter;
    FSavedGameLoader: IXcomSavedGameLoader;
    FSavedGameSaver: IXcomSavedGameSaver;
    FUiSounds: IXcomUiSounds;
    FNewBattleOpener: IXcomNewBattleOpener;
    FSession: IInterface;
    FBattlePalette: TXcomColors;
    FBattlePaletteOwner: TObject;
    procedure DispatchEvent(const AEvent: TXcomInputEvent);
  public
    /// <summary>
    ///   The game owns the options, the screen, the cursor and the fps counter that it receives, and the language
    ///   it is given (a first one, replaced when the data is loaded)
    /// </summary>
    constructor Create(AOptions: TXcomOptions; AScreen: TXcomScreen; ACursor, AFpsCounter: TXcomInteractiveSurface;
      ALanguage: TXcomLanguage; const AClock: IClock; const AEvents: IXcomEventSource);
    destructor Destroy; override;
    function Screen: TXcomScreen; override;
    function Cursor: TXcomInteractiveSurface; override;
    function FpsCounter: TXcomInteractiveSurface; override;
    function Language: TXcomLanguage; override;
    function Resources: IXcomResources; override;
    function Options: TXcomOptions; override;
    function Clock: IClock; override;
    procedure PushState(AState: TXcomState); override;
    procedure PopState; override;
    procedure SetState(AState: TXcomState); override;
    procedure Quit; override;
    function IsState(AState: TXcomState): Boolean; override;
    function StateCount: Integer; override;
    procedure AdoptData(const AResources: IXcomResources; ALanguage: TXcomLanguage); override;
    function LanguageProvider: IXcomLanguageProvider; override;
    function DisplayModes: IXcomDisplayModes; override;
    function ShaderCatalog: IXcomShaderCatalog; override;
    function ExtraOptions: IXcomExtraOptions; override;
    function OptionsStore: IXcomOptionsStore; override;
    procedure LoadLanguages; override;
    procedure SetVolume(ASound, AMusic, AUi: Integer); override;
    procedure SetLanguageProvider(const AProvider: IXcomLanguageProvider);
    procedure SetDisplayModes(const AModes: IXcomDisplayModes);
    procedure SetShaderCatalog(const ACatalog: IXcomShaderCatalog);
    procedure SetExtraOptions(const AOptions: IXcomExtraOptions);
    procedure SetOptionsStore(const AStore: IXcomOptionsStore);
    procedure SetAudioDevice(const AAudio: IXcomAudioDevice);
    /// <summary>The music of the game; it is reloaded each time the game adopts data</summary>
    procedure SetMusicPlayer(const AMusic: IXcomMusicPlayer);
    procedure PlayMusic(const AName: string; AId: Integer = 0); override;
    procedure StopMusic; override;
    function ModCatalog: IXcomModCatalog; override;
    procedure SetModCatalog(const ACatalog: IXcomModCatalog);
    function CurrentMusicFormat: string; override;
    procedure SetFolderOpener(const AOpener: IXcomFolderOpener);
    procedure SetSaveCatalog(const ACatalog: IXcomSaveCatalog);
    function SaveCatalog: IXcomSaveCatalog; override;
    procedure OpenFolder(const APath: string); override;
    procedure PlaySound(const ASet: string; AIndex: Integer; AInterface: Boolean = False); override;
    function PlaySoundAt(const ASet: string; AIndex, AVolume: Integer): Boolean; override;
    function NewGameStarter: IXcomNewGameStarter; override;
    function NewBattleOpener: IXcomNewBattleOpener; override;
    procedure SetNewBattleOpener(const AOpener: IXcomNewBattleOpener);
    procedure WarpMouse(AX, AY: Integer); override;
    procedure SetNewGameStarter(const AStarter: IXcomNewGameStarter);
    function SavedGameLoader: IXcomSavedGameLoader; override;
    procedure SetSavedGameLoader(const ALoader: IXcomSavedGameLoader);
    function SavedGameSaver: IXcomSavedGameSaver; override;
    procedure SetSavedGameSaver(const ASaver: IXcomSavedGameSaver);
    function Session: IInterface; override;
    function UiSounds: IXcomUiSounds; override;
    /// <summary>Replaces what plays the sounds of the widgets (nil: silent); the game starts with TXcomHostUiSounds</summary>
    procedure SetUiSounds(const ASounds: IXcomUiSounds);
    procedure SetSession(const ASession: IInterface); override;
    function BattlePalette: PXcomColor; override;
    procedure SetBattlePalette(AOwner: TObject; AColors: PXcomColor); override;
    /// <summary>One turn of the loop of Game::run: events, think and, when the frame rate allows, the drawing</summary>
    procedure RunFrame;
    /// <summary>Game::run on SDL_VIDEORESIZE: the display takes the size of the window, the states recenter</summary>
    procedure ResizeDisplay(AWidth, AHeight: Integer);
    /// <summary>Game::run: until quit; waits FrameDelay between the turns and saves the options at the end</summary>
    procedure Run;
    /// <summary>
    ///   Options::save at the end of Game::run: the options go to the store (the size of a window that the player
    ///   resized is among them). A game without a store does nothing. The program that runs its own loop of RunFrame
    ///   calls it when the loop ends
    /// </summary>
    procedure SaveOptions;
    /// <summary>The milliseconds to wait after a turn: 1 while running, 100 when slowed or paused (pauseMode)</summary>
    function FrameDelay: Integer;
    /// <summary>What pauseMode made of the game when the window lost the focus or was minimized</summary>
    property RunningState: TXcomRunningState read FRunningState;
    function IsQuitting: Boolean;
    /// <summary>The state on top (nil when there is none)</summary>
    function TopState: TXcomState;
    procedure SetMouseActive(AActive: Boolean);
    /// <summary>How many frames were drawn</summary>
    property Frames: Integer read FFrames;
    property OnScreenshot: TXcomScreenshotHandler read FOnScreenshot write FOnScreenshot;
  end;

implementation

const
  /// <summary>kbFocusRun: the game has not the keyboard focus, by pauseMode</summary>
  NO_FOCUS_RUN: array[0..3] of TXcomRunningState = (rsRunning, rsRunning, rsSlowed, rsPaused);
  /// <summary>stateRun: the game is minimized, by pauseMode</summary>
  MINIMIZED_RUN: array[0..3] of TXcomRunningState = (rsSlowed, rsPaused, rsPaused, rsPaused);

constructor TXcomGame.Create(AOptions: TXcomOptions; AScreen: TXcomScreen; ACursor, AFpsCounter: TXcomInteractiveSurface;
  ALanguage: TXcomLanguage; const AClock: IClock; const AEvents: IXcomEventSource);
begin
  inherited Create;
  FOptions := AOptions;
  FScreen := AScreen;
  FCursor := ACursor;
  FFpsCounter := AFpsCounter;
  FLanguage := ALanguage;
  FClock := AClock;
  FEvents := AEvents;
  FStates := TObjectList<TXcomState>.Create(True);
  FDeleted := TObjectList<TXcomState>.Create(True);
  FMouseActive := True;
  FUiSounds := TXcomHostUiSounds.Create(Self);
end;

destructor TXcomGame.Destroy;
begin
  FDeleted.Free;
  FStates.Free;
  // the widgets are gone with the states: nothing asks for their sounds any more
  FUiSounds := nil;
  // the music reads the data of the game: it stops before the data goes
  if FMusic <> nil then
    FMusic.Stop;
  FMusic := nil;
  if FAudio <> nil then
    FAudio.Close;
  FAudio := nil;
  // the saved game uses the rules of the data: it goes before them
  FSession := nil;
  FLanguage.Free;
  // the states hold pieces of the data: the data goes after them
  FResources := nil;
  FCursor.Free;
  FFpsCounter.Free;
  FScreen.Free;
  FOptions.Free;
  inherited Destroy;
end;

function TXcomGame.Screen: TXcomScreen;
begin
  Result := FScreen;
end;

function TXcomGame.Cursor: TXcomInteractiveSurface;
begin
  Result := FCursor;
end;

function TXcomGame.FpsCounter: TXcomInteractiveSurface;
begin
  Result := FFpsCounter;
end;

function TXcomGame.Language: TXcomLanguage;
begin
  Result := FLanguage;
end;

function TXcomGame.Resources: IXcomResources;
begin
  Result := FResources;
end;

function TXcomGame.Options: TXcomOptions;
begin
  Result := FOptions;
end;

function TXcomGame.Clock: IClock;
begin
  Result := FClock;
end;

procedure TXcomGame.PushState(AState: TXcomState);
begin
  FStates.Add(AState);
  FInit := False;
end;

procedure TXcomGame.PopState;
begin
  // the state may be the one that is running a handler: it is freed at the start of the next turn
  FDeleted.Add(FStates.Extract(FStates.Last));
  FInit := False;
end;

procedure TXcomGame.SetState(AState: TXcomState);
begin
  while FStates.Count > 0 do
    PopState;
  PushState(AState);
  FInit := False;
end;

procedure TXcomGame.Quit;
begin
  FQuit := True;
end;

function TXcomGame.IsState(AState: TXcomState): Boolean;
begin
  Result := (FStates.Count > 0) and (FStates.Last = AState);
end;

function TXcomGame.StateCount: Integer;
begin
  Result := FStates.Count;
end;

procedure TXcomGame.AdoptData(const AResources: IXcomResources; ALanguage: TXcomLanguage);
var
  LFormats: IXcomSoundFormats;
begin
  if Assigned(ALanguage) and (ALanguage <> FLanguage) then
  begin
    FLanguage.Free;
    FLanguage := ALanguage;
    // Game::loadLanguages: Options::language = currentLang
    FOptions.Language := ALanguage.LanguageId;
  end;
  FResources := AResources;
  // Mod::loadExtraResources: the sounds of a game without soundDefs follow the preferred format
  if Supports(AResources, IXcomSoundFormats, LFormats) then
  begin
    LFormats.SetPreferredSound(FOptions.PreferredSound);
    FOptions.CurrentSound := LFormats.CurrentSound;
  end;
  if (FMusic <> nil) and (AResources <> nil) then
    FMusic.Reload(AResources);
end;

function TXcomGame.ModCatalog: IXcomModCatalog;
begin
  Result := FModCatalog;
end;

procedure TXcomGame.SetModCatalog(const ACatalog: IXcomModCatalog);
begin
  FModCatalog := ACatalog;
end;

procedure TXcomGame.SetMusicPlayer(const AMusic: IXcomMusicPlayer);
begin
  FMusic := AMusic;
  if (FMusic <> nil) and (FResources <> nil) then
    FMusic.Reload(FResources);
end;

procedure TXcomGame.PlayMusic(const AName: string; AId: Integer);
begin
  if (FMusic <> nil) and not FOptions.Mute then
    FMusic.PlayMusic(AName, AId);
end;

procedure TXcomGame.StopMusic;
begin
  if FMusic <> nil then
    FMusic.Stop;
end;

function TXcomGame.CurrentMusicFormat: string;
begin
  if FMusic <> nil then
    Result := FMusic.CurrentFormat
  else
    Result := inherited CurrentMusicFormat;
end;

function TXcomGame.NewBattleOpener: IXcomNewBattleOpener;
begin
  Result := FNewBattleOpener;
end;

procedure TXcomGame.SetNewBattleOpener(const AOpener: IXcomNewBattleOpener);
begin
  FNewBattleOpener := AOpener;
end;

function TXcomGame.NewGameStarter: IXcomNewGameStarter;
begin
  Result := FNewGameStarter;
end;

procedure TXcomGame.WarpMouse(AX, AY: Integer);
begin
  if Assigned(FEvents) then
    FEvents.WarpMouse(AX, AY);
end;

procedure TXcomGame.SetNewGameStarter(const AStarter: IXcomNewGameStarter);
begin
  FNewGameStarter := AStarter;
end;

function TXcomGame.SavedGameLoader: IXcomSavedGameLoader;
begin
  Result := FSavedGameLoader;
end;

procedure TXcomGame.SetSavedGameLoader(const ALoader: IXcomSavedGameLoader);
begin
  FSavedGameLoader := ALoader;
end;

function TXcomGame.SavedGameSaver: IXcomSavedGameSaver;
begin
  Result := FSavedGameSaver;
end;

procedure TXcomGame.SetSavedGameSaver(const ASaver: IXcomSavedGameSaver);
begin
  FSavedGameSaver := ASaver;
end;

function TXcomGame.UiSounds: IXcomUiSounds;
begin
  Result := FUiSounds;
end;

procedure TXcomGame.SetUiSounds(const ASounds: IXcomUiSounds);
begin
  FUiSounds := ASounds;
end;

function TXcomGame.Session: IInterface;
begin
  Result := FSession;
end;

procedure TXcomGame.SetSession(const ASession: IInterface);
begin
  FSession := ASession;
end;

function TXcomGame.BattlePalette: PXcomColor;
begin
  if Assigned(FBattlePaletteOwner) then
    Result := @FBattlePalette[0]
  else
    Result := nil;
end;

procedure TXcomGame.SetBattlePalette(AOwner: TObject; AColors: PXcomColor);
begin
  if Assigned(AColors) then
  begin
    Move(AColors^, FBattlePalette[0], SizeOf(FBattlePalette));
    FBattlePaletteOwner := AOwner;
  end
  else if FBattlePaletteOwner = AOwner then
    FBattlePaletteOwner := nil;
end;

function TXcomGame.LanguageProvider: IXcomLanguageProvider;
begin
  Result := FLanguageProvider;
end;

function TXcomGame.DisplayModes: IXcomDisplayModes;
begin
  Result := FDisplayModes;
end;

function TXcomGame.ShaderCatalog: IXcomShaderCatalog;
begin
  Result := FShaderCatalog;
end;

function TXcomGame.ExtraOptions: IXcomExtraOptions;
begin
  Result := FExtraOptions;
end;

function TXcomGame.OptionsStore: IXcomOptionsStore;
begin
  Result := FOptionsStore;
end;

procedure TXcomGame.SetLanguageProvider(const AProvider: IXcomLanguageProvider);
begin
  FLanguageProvider := AProvider;
end;

procedure TXcomGame.SetFolderOpener(const AOpener: IXcomFolderOpener);
begin
  FFolderOpener := AOpener;
end;

procedure TXcomGame.SetSaveCatalog(const ACatalog: IXcomSaveCatalog);
begin
  FSaveCatalog := ACatalog;
end;

function TXcomGame.SaveCatalog: IXcomSaveCatalog;
begin
  Result := FSaveCatalog;
end;

procedure TXcomGame.PlaySound(const ASet: string; AIndex: Integer; AInterface: Boolean);
var
  LWave: TBytes;
begin
  if (FAudio = nil) or (not FAudio.IsAvailable) or (Resources = nil) then
    Exit;
  LWave := Resources.SoundWave(ASet, AIndex);
  if Length(LWave) = 0 then
    Exit;
  if AInterface then
    FAudio.PlayWave(TXcomSoundConverter.WithVolume(LWave, TXcomVolume.Mixer(Options.UiVolume)))
  else
    FAudio.PlayWave(TXcomSoundConverter.WithVolume(LWave, TXcomVolume.Mixer(Options.SoundVolume)));
end;

function TXcomGame.PlaySoundAt(const ASet: string; AIndex, AVolume: Integer): Boolean;
var
  LWave: TBytes;
begin
  if Resources = nil then
    Exit(False);
  LWave := Resources.SoundWave(ASet, AIndex);
  Result := Length(LWave) > 0;
  if Result and (FAudio <> nil) and FAudio.IsAvailable then
    FAudio.PlayWave(TXcomSoundConverter.WithVolume(LWave, AVolume));
end;

procedure TXcomGame.OpenFolder(const APath: string);
begin
  if FFolderOpener <> nil then
    FFolderOpener.Open(APath);
end;

procedure TXcomGame.SetDisplayModes(const AModes: IXcomDisplayModes);
begin
  FDisplayModes := AModes;
end;

procedure TXcomGame.SetShaderCatalog(const ACatalog: IXcomShaderCatalog);
begin
  FShaderCatalog := ACatalog;
end;

procedure TXcomGame.SetExtraOptions(const AOptions: IXcomExtraOptions);
begin
  FExtraOptions := AOptions;
end;

procedure TXcomGame.SetOptionsStore(const AStore: IXcomOptionsStore);
begin
  FOptionsStore := AStore;
end;

procedure TXcomGame.SetAudioDevice(const AAudio: IXcomAudioDevice);
begin
  FAudio := AAudio;
end;

procedure TXcomGame.LoadLanguages;
begin
  if Assigned(FLanguageProvider) then
    AdoptData(FResources, FLanguageProvider.Load(FOptions.Language, FOptions.Wordwrap, FResources));
end;

procedure TXcomGame.SetVolume(ASound, AMusic, AUi: Integer);
begin
  if Assigned(FAudio) then
    FAudio.SetVolume(ASound, AMusic, AUi);
end;

function TXcomGame.TopState: TXcomState;
begin
  if FStates.Count > 0 then
    Result := FStates.Last
  else
    Result := nil;
end;

function TXcomGame.IsQuitting: Boolean;
begin
  Result := FQuit;
end;

procedure TXcomGame.SetMouseActive(AActive: Boolean);
begin
  FMouseActive := AActive;
  FCursor.Visible := AActive;
end;

procedure TXcomGame.DispatchEvent(const AEvent: TXcomInputEvent);
var
  LAction: TXcomAction;
  LX: Integer;
  LY: Integer;
begin
  LAction := TXcomAction.Create(AEvent, FScreen.XScale, FScreen.YScale, FScreen.CursorTopBlackBand,
    FScreen.CursorLeftBlackBand);
  try
    FEvents.MouseState(LX, LY);
    LAction.ButtonMask := FEvents.MouseState(LX, LY);
    FScreen.Handle(LAction);
    FCursor.Handle(LAction);
    FFpsCounter.Handle(LAction);
    if (FStates.Count > 0) then
      FStates.Last.Handle(LAction);
  finally
    LAction.Free;
  end;
end;

procedure TXcomGame.ResizeDisplay(AWidth, AHeight: Integer);
var
  LDX: Integer;
  LDY: Integer;
  LState: TXcomState;
begin
  if AWidth < XCOM_ORIGINAL_WIDTH then
    AWidth := XCOM_ORIGINAL_WIDTH;
  if AHeight < XCOM_ORIGINAL_HEIGHT then
    AHeight := XCOM_ORIGINAL_HEIGHT;
  FOptions.DisplayWidth := AWidth;
  FOptions.NewDisplayWidth := AWidth;
  FOptions.DisplayHeight := AHeight;
  FOptions.NewDisplayHeight := AHeight;
  LDX := 0;
  LDY := 0;
  TXcomScreen.UpdateScale(FOptions, FOptions.BattlescapeScale, FOptions.BaseXBattlescape, FOptions.BaseYBattlescape,
    False);
  TXcomScreen.UpdateScale(FOptions, FOptions.GeoscapeScale, FOptions.BaseXGeoscape, FOptions.BaseYGeoscape, False);
  for LState in FStates do
    LState.Resize(LDX, LDY);
  FScreen.ResetDisplay;
end;

procedure TXcomGame.RunFrame;
var
  LEvent: TXcomInputEvent;
  LX: Integer;
  LY: Integer;
  LAction: TXcomAction;
  LIndex: Integer;
  LFirst: Integer;
  LTimeUntilNextFrame: Double;
  LPauseMode: Integer;
begin
  FDeleted.Clear;
  if FStates.Count = 0 then
  begin
    FQuit := True;
    Exit;
  end;
  if not FInit then
  begin
    FInit := True;
    FStates.Last.Init;
    FStates.Last.ResetAll;
    // a fake mouse motion tells the surfaces where the mouse already is
    LEvent := TXcomInputEvent.Make(ekMouseMotion);
    FEvents.MouseState(LX, LY);
    LEvent.X := LX;
    LEvent.Y := LY;
    LAction := TXcomAction.Create(LEvent, FScreen.XScale, FScreen.YScale, FScreen.CursorTopBlackBand,
      FScreen.CursorLeftBlackBand);
    try
      FStates.Last.Handle(LAction);
    finally
      LAction.Free;
    end;
  end;
  while FEvents.Poll(LEvent) do
  begin
    case LEvent.Kind of
      ekQuit:
        Quit;
      ekMouseMotion, ekMouseDown, ekMouseUp:
        if FMouseActive then
          DispatchEvent(LEvent);
      ekActive:
        begin
          // SDL_ACTIVEEVENT: pauseMode slows or stops a game that is minimized (Button 1) or without the focus
          LPauseMode := FOptions.GetValue('pauseMode');
          if (LPauseMode < 0) or (LPauseMode > 3) then
            LPauseMode := 0;
          if LEvent.Key <> 0 then
            FRunningState := rsRunning
          else if LEvent.Button <> 0 then
            FRunningState := MINIMIZED_RUN[LPauseMode]
          else
            FRunningState := NO_FOCUS_RUN[LPauseMode];
          // with backgroundMute the game is silent while the window has not the focus
          if FOptions.BackgroundMute then
            if LEvent.Key <> 0 then
              SetVolume(FOptions.SoundVolume, FOptions.MusicVolume, FOptions.UiVolume)
            else
              SetVolume(0, 0, 0);
        end;
      ekResize:
        begin
          FRunningState := rsRunning;
          // SDL_VIDEORESIZE: the player has dragged the border of a resizable window (X and Y are the new size)
          if FOptions.AllowResize then
            ResizeDisplay(LEvent.X, LEvent.Y);
        end;
    else
      DispatchEvent(LEvent);
    end;
    if not FInit then
      Break;
  end;
  if FScreen.TakeScreenshotRequest and Assigned(FOnScreenshot) then
    FOnScreenshot(FScreen);
  if (FStates.Count = 0) or (FRunningState = rsPaused) then
    Exit;
  FStates.Last.Think;
  FFpsCounter.Think;
  if FOptions.FPS > 0 then
    LTimeUntilNextFrame := (1000.0 / FOptions.FPS) - (TXcomTicks.Now(FClock) - FTimeOfLastFrame)
  else
    LTimeUntilNextFrame := 0;
  if FInit and (LTimeUntilNextFrame <= 0) then
  begin
    FTimeOfLastFrame := TXcomTicks.Now(FClock);
    FFpsCounter.FrameAdded;
    Inc(FFrames);
    FScreen.Clear;
    LFirst := FStates.Count - 1;
    while (LFirst > 0) and (not FStates[LFirst].IsScreen) do
      Dec(LFirst);
    for LIndex := LFirst to FStates.Count - 1 do
      FStates[LIndex].Blit;
    FFpsCounter.Blit(FScreen.GetSurface);
    FCursor.Blit(FScreen.GetSurface);
    FScreen.Flip;
  end;
end;

procedure TXcomGame.Run;
begin
  while not FQuit do
  begin
    RunFrame;
    TXcomTicks.Delay(FClock, FrameDelay);
  end;
  SaveOptions;
end;

procedure TXcomGame.SaveOptions;
begin
  if Assigned(FOptionsStore) then
    FOptionsStore.Save(FOptions);
end;

function TXcomGame.FrameDelay: Integer;
begin
  if FRunningState = rsRunning then
    Result := 1
  else
    Result := 100;
end;

end.
