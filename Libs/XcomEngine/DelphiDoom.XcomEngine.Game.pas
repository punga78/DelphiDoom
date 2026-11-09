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
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf,
  DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomEngine.Language,
  DelphiDoom.XcomEngine.Options, DelphiDoom.XcomEngine.Screen, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomEngine.Resources.Intf, DelphiDoom.XcomEngine.LanguageProvider.Intf,
  DelphiDoom.XcomEngine.OptionsStore.Intf, DelphiDoom.XcomEngine.Session.Intf;

type
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
    FClock: IXcomClock;
    FEvents: IXcomEventSource;
    FStates: TObjectList<TXcomState>;
    FDeleted: TObjectList<TXcomState>;
    FQuit: Boolean;
    FInit: Boolean;
    FMouseActive: Boolean;
    FTimeOfLastFrame: Cardinal;
    FFrames: Integer;
    FOnScreenshot: TXcomScreenshotHandler;
    FLanguageProvider: IXcomLanguageProvider;
    FDisplayModes: IXcomDisplayModes;
    FOptionsStore: IXcomOptionsStore;
    FAudio: IXcomAudioDevice;
    FNewGameStarter: IXcomNewGameStarter;
    FSession: IInterface;
    procedure Dispatch(const AEvent: TXcomInputEvent);
  public
    /// <summary>
    ///   The game owns the options, the screen, the cursor and the fps counter that it receives, and the language
    ///   it is given (a first one, replaced when the data is loaded)
    /// </summary>
    constructor Create(AOptions: TXcomOptions; AScreen: TXcomScreen; ACursor, AFpsCounter: TXcomInteractiveSurface;
      ALanguage: TXcomLanguage; const AClock: IXcomClock; const AEvents: IXcomEventSource);
    destructor Destroy; override;
    function Screen: TXcomScreen; override;
    function Cursor: TXcomInteractiveSurface; override;
    function FpsCounter: TXcomInteractiveSurface; override;
    function Language: TXcomLanguage; override;
    function Resources: IXcomResources; override;
    function Options: TXcomOptions; override;
    function Clock: IXcomClock; override;
    procedure PushState(AState: TXcomState); override;
    procedure PopState; override;
    procedure SetState(AState: TXcomState); override;
    procedure Quit; override;
    function IsState(AState: TXcomState): Boolean; override;
    procedure AdoptData(const AResources: IXcomResources; ALanguage: TXcomLanguage); override;
    function LanguageProvider: IXcomLanguageProvider; override;
    function DisplayModes: IXcomDisplayModes; override;
    function OptionsStore: IXcomOptionsStore; override;
    procedure LoadLanguages; override;
    procedure SetVolume(ASound, AMusic, AUi: Integer); override;
    procedure SetLanguageProvider(const AProvider: IXcomLanguageProvider);
    procedure SetDisplayModes(const AModes: IXcomDisplayModes);
    procedure SetOptionsStore(const AStore: IXcomOptionsStore);
    procedure SetAudioDevice(const AAudio: IXcomAudioDevice);
    function NewGameStarter: IXcomNewGameStarter; override;
    procedure SetNewGameStarter(const AStarter: IXcomNewGameStarter);
    function Session: IInterface; override;
    procedure SetSession(const ASession: IInterface); override;
    /// <summary>One turn of the loop of Game::run: events, think and, when the frame rate allows, the drawing</summary>
    procedure RunFrame;
    /// <summary>Game::run: until quit; waits 1 ms between the turns</summary>
    procedure Run;
    function IsQuitting: Boolean;
    /// <summary>The state on top (nil when there is none)</summary>
    function TopState: TXcomState;
    procedure SetMouseActive(AActive: Boolean);
    /// <summary>How many frames were drawn</summary>
    property Frames: Integer read FFrames;
    property OnScreenshot: TXcomScreenshotHandler read FOnScreenshot write FOnScreenshot;
  end;

implementation

constructor TXcomGame.Create(AOptions: TXcomOptions; AScreen: TXcomScreen; ACursor, AFpsCounter: TXcomInteractiveSurface;
  ALanguage: TXcomLanguage; const AClock: IXcomClock; const AEvents: IXcomEventSource);
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
end;

destructor TXcomGame.Destroy;
begin
  FDeleted.Free;
  FStates.Free;
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

function TXcomGame.Clock: IXcomClock;
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

procedure TXcomGame.AdoptData(const AResources: IXcomResources; ALanguage: TXcomLanguage);
begin
  if Assigned(ALanguage) and (ALanguage <> FLanguage) then
  begin
    FLanguage.Free;
    FLanguage := ALanguage;
    // Game::loadLanguages: Options::language = currentLang
    FOptions.Language := ALanguage.LanguageId;
  end;
  FResources := AResources;
end;

function TXcomGame.NewGameStarter: IXcomNewGameStarter;
begin
  Result := FNewGameStarter;
end;

procedure TXcomGame.SetNewGameStarter(const AStarter: IXcomNewGameStarter);
begin
  FNewGameStarter := AStarter;
end;

function TXcomGame.Session: IInterface;
begin
  Result := FSession;
end;

procedure TXcomGame.SetSession(const ASession: IInterface);
begin
  FSession := ASession;
end;

function TXcomGame.LanguageProvider: IXcomLanguageProvider;
begin
  Result := FLanguageProvider;
end;

function TXcomGame.DisplayModes: IXcomDisplayModes;
begin
  Result := FDisplayModes;
end;

function TXcomGame.OptionsStore: IXcomOptionsStore;
begin
  Result := FOptionsStore;
end;

procedure TXcomGame.SetLanguageProvider(const AProvider: IXcomLanguageProvider);
begin
  FLanguageProvider := AProvider;
end;

procedure TXcomGame.SetDisplayModes(const AModes: IXcomDisplayModes);
begin
  FDisplayModes := AModes;
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

procedure TXcomGame.Dispatch(const AEvent: TXcomInputEvent);
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

procedure TXcomGame.RunFrame;
var
  LEvent: TXcomInputEvent;
  LX: Integer;
  LY: Integer;
  LAction: TXcomAction;
  LIndex: Integer;
  LFirst: Integer;
  LTimeUntilNextFrame: Double;
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
          Dispatch(LEvent);
      ekActive, ekResize:
        ;
    else
      Dispatch(LEvent);
    end;
    if not FInit then
      Break;
  end;
  if FScreen.TakeScreenshotRequest and Assigned(FOnScreenshot) then
    FOnScreenshot(FScreen);
  if FStates.Count = 0 then
    Exit;
  FStates.Last.Think;
  FFpsCounter.Think;
  if FOptions.FPS > 0 then
    LTimeUntilNextFrame := (1000.0 / FOptions.FPS) - (FClock.Ticks - FTimeOfLastFrame)
  else
    LTimeUntilNextFrame := 0;
  if FInit and (LTimeUntilNextFrame <= 0) then
  begin
    FTimeOfLastFrame := FClock.Ticks;
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
    FClock.Delay(1);
  end;
end;

end.
