{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGreedApplication, TGreedScreenView and the hosts of    }
{  the screens                                                                  }
{                                                                              }
{  The window, the clock and the keys are fakes, the game is made of the        }
{  stand-ins of its tests and the screens are drawn from a synthetic archive:   }
{  no data of the game, no window, no time                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.Application;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Greed.Types,
  DelphiDoom.Greed.Intf, DelphiDoom.Greed.Save.Intf, DelphiDoom.Greed.Settings.Intf, DelphiDoom.Greed.Frame.Intf,
  DelphiDoom.Greed.GameView.Intf, DelphiDoom.Greed.PlayerControl.Intf, DelphiDoom.Greed.Game,
  DelphiDoom.Greed.Screens, DelphiDoom.Greed.ScreenView, DelphiDoom.Greed.Application,
  DelphiDoom.Greed.Application.Intf, DelphiDoom.Clock.Intf, DelphiDoom.Tests.Greed.GameFakes,
  DelphiDoom.Greed.CommandState, DelphiDoom.Greed.Sound.Intf, DelphiDoom.Greed.Menu.Intf, DelphiDoom.Greed.Intro,
  DelphiDoom.Greed.Briefing, DelphiDoom.Greed.EndGame, DelphiDoom.Tests.Greed.IntroScenarios;

type
  /// <summary>The window: it pumps until the test says it is closed</summary>
  TFakeWindow = class(TInterfacedObject, IGreedInput)
  public
    PumpsLeft: Integer;
    constructor Create;
    function Pump: Boolean;
    function IsDown(AKey: TGreedKey): Boolean;
  end;

  /// <summary>Counts the pictures</summary>
  TFakeShower = class(TInterfacedObject, IGreedFramePresenter)
  public
    Count: Integer;
    LastColors: TGreedColors;
    LastFrame: TGreedFrame;
    procedure Present(const AFrame: TGreedFrame; const AColors: TGreedColors);
  end;

  /// <summary>A clock that nobody reads (the program runs without it) and counts the waits</summary>
  TFakeTimeClock = class(TInterfacedObject, IClock)
  public
    StepsNow: Integer;
    Waits: Integer;
    function Seconds: Double;
    function Steps(ARate: Integer): Integer;
    function ScaledSteps(ARate, AScale: Integer): Integer;
    procedure Sleep(AMilliseconds: Integer);
    procedure Wait(AMilliseconds: Integer);
  end;

  /// <summary>Keys that go down and up at the tics that the test says, and something to do at a tic</summary>
  TFakeKeys = class(TInterfacedObject, IGreedKeyboard, IGreedTicListener)
  strict private
    type
      TEvent = record
        Tic: Integer;
        ScanCode: Integer;
        Down: Boolean;
      end;
    var
      FDown: array[0..127] of Boolean;
      FEvents: TList<TEvent>;
  public
    Tics: Integer;
    OnTic: TProc<Integer>;
    constructor Create;
    destructor Destroy; override;
    /// <summary>The key goes down at that tic and up two tics later (a press)</summary>
    procedure Press(ATic, AScanCode: Integer);
    /// <summary>A press every ARepeat tics from AFrom to ATo</summary>
    procedure PressEvery(AFrom, ATo, ARepeat, AScanCode: Integer);
    function IsDown(AScanCode: Integer): Boolean;
    procedure TicStarting(ATic: Integer);
  end;

  TFakeSettingsStore = class(TInterfacedObject, IGreedSettingsStore)
  public
    Saves: Integer;
    function Load(const ASettings: IGreedSettings; ACommandLineGame: Integer): Boolean;
    procedure Save(const ASettings: IGreedSettings);
  end;

  /// <summary>What the view asked of the program, by name</summary>
  TFakeScreens = class(TInterfacedObject, IGreedScreens)
  public
    Calls: TStringList;
    QuitAnswer: Boolean;
    constructor Create;
    destructor Destroy; override;
    function ShowMenu: Boolean;
    procedure ShowHelp;
    procedure ShowPause;
    function ConfirmQuit: Boolean;
    procedure MissionBriefing(AMap: Integer);
    procedure EndGame(AEpisode: Integer);
    procedure PlayFli(AMovie: Integer);
    procedure StartWait;
    procedure UpdateWait;
    procedure EndWait;
    procedure FadeOutLevel;
    procedure ReleaseScreen;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedApplication = class(TObject)
  private
    FScreenArchive: IGreedArchive;
    FSettings: IGreedSettings;
    FHost: TIntroHostFake;
    FHostRef: IInterface;
    FScreens: TGreedScreens;
    FGameArchive: IGreedArchive;
    FMaps: IGreedMapLoader;
    FRenderer: TFakeGameRenderer;
    FRendererRef: IInterface;
    FCommands: TFakeCommandSource;
    FCommandsRef: IGreedCommandSource;
    FSound: TFakeGameSound;
    FSoundRef: IInterface;
    FView: TFakeGameView;
    FViewRef: IGreedGameView;
    FScreenView: TGreedScreenView;
    FScreenViewRef: IGreedGameView;
    FGame: TGreedGame;
    FWindow: TFakeWindow;
    FWindowRef: IGreedInput;
    FShower: TFakeShower;
    FShowerRef: IGreedFramePresenter;
    FClockRef: IClock;
    FKeys: TFakeKeys;
    FKeysRef: IInterface;
    FStore: TFakeSettingsStore;
    FStoreRef: IGreedSettingsStore;
    FApplication: TGreedApplication;
    function Options(AMaxTics: Integer; ASkipIntro, ANoBriefing: Boolean): TGreedApplicationOptions;
    procedure Build(const AOptions: TGreedApplicationOptions);
    function Line(const AName: string): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSollevareConDipendenzeNulle;
    [Test]
    procedure DovrebbeRifiutareUnQuadroCheNonEMultiploDelloSchermo;
    [Test]
    procedure DovrebbeFermarsiAiTicMassimiNellIntroduzione;
    [Test]
    procedure DovrebbeMostrareLeImmaginiConLaPalettedelloSchermo;
    [Test]
    procedure DovrebbeAvviareLaPartitaSenzaIntroduzione;
    [Test]
    procedure DovrebbeMostrareIlBriefingPrimaDellaPartita;
    [Test]
    procedure DovrebbeGiocareDopoIlBriefing;
    [Test]
    procedure DovrebbeAprireIlMenuDalGioco;
    [Test]
    procedure DovrebbeTornareAlGiocoQuandoIlMenuSiChiude;
    [Test]
    procedure DovrebbeFinireQuandoLaConfermaDiUscitaEAffermativa;
    [Test]
    procedure DovrebbeRiprendereIlGiocoDopoLaPausa;
    [Test]
    procedure DovrebbeFermarsiQuandoLaFinestraSiChiude;
    [Test]
    procedure DovrebbeSalvareLeImpostazioniAllaFineDellaPartita;
    [Test]
    procedure DovrebbeDissolvereLaPalettealNeroAllaFineDelLivello;
    [Test]
    procedure DovrebbeTenereLoSchermoDopoUnFilmato;
    [Test]
    procedure DovrebbeIgnorareUnFilmatoSconosciuto;
    [Test]
    procedure DovrebbeChiedereLIntroduzioneDopoUnFinale;
    [Test]
    procedure DovrebbeNonMostrareIlBriefingConNoBriefing;
    [Test]
    procedure DovrebbeDescrivereLoStatoDelProgramma;
    [Test]
    procedure DovrebbeContareITicDiOgniFase;
    [Test]
    procedure DovrebbeAspettareSeIlRelogioNonHaTic;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedScreenView = class(TObject)
  private
    FInner: TFakeGameView;
    FInnerRef: IGreedGameView;
    FView: TGreedScreenView;
    FViewRef: IGreedGameView;
    FScreens: TFakeScreens;
    FScreensRef: IGreedScreens;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeSollevareConLaVistaNulla;
    [Test]
    procedure DovrebbeInoltrareLaBarraDiStatoAllaVistaInterna;
    [Test]
    procedure DovrebbeInoltrareLeSchermateAlProgramma;
    [Test]
    procedure DovrebbeDareLeSchermateAllaVistaInternaSenzaProgramma;
    [Test]
    procedure DovrebbeRilasciareLoSchermoQuandoIlGiocoRipuliscelIlDisplay;
    [Test]
    procedure DovrebbeRipetereLaRispostaDelMenu;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedScreenHosts = class(TObject)
  private
    FSetup: TFakeGameSetup;
    FSettings: IGreedSettings;
    FStore: TFakeSettingsStore;
    FStoreRef: IGreedSettingsStore;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeFarPartireUnaNuovaPartitaDalMenu;
    [Test]
    procedure DovrebbeFermareIlGiocoQuandoIlMenuEsce;
    [Test]
    procedure DovrebbeSalvareLeImpostazioniEApplicarleAlGioco;
    [Test]
    procedure DovrebbeAzzerareLeVelocitaQuandoIlMenuSiChiude;
    [Test]
    procedure DovrebbeSuonareLaMusicaDellIntroduzioneEAzzerareLeBandiere;
    [Test]
    procedure DovrebbeDireSeIlGiocoEStatoCaricatoOSeEUscito;
    [Test]
    procedure DovrebbeRipartireDaUnNuovoCacciatoreAlSecondoEpisodio;
    [Test]
    procedure DovrebbeScegliereLaMusicaDelleSchermate;
    [Test]
    procedure DovrebbeSollevareConIlGiocoNullo;
  end;

implementation

uses
  DelphiDoom.Greed.SaveTypes, DelphiDoom.Greed.Settings, DelphiDoom.Greed.SaveGames, DelphiDoom.Greed.MenuHost,
  DelphiDoom.Greed.IntroHost, DelphiDoom.Greed.EpisodeHost, DelphiDoom.Greed.MenuInput,
  DelphiDoom.Greed.Random, DelphiDoom.Greed.Game.Intf, DelphiDoom.Tests.Greed.MenuScenarios;

// True if the procedure raises an exception of that class
function Raises(const AProc: TProc; AClass: ExceptClass): Boolean;
begin
  Result := False;
  try
    AProc();
  except
    on E: Exception do
      Result := E is AClass;
  end;
end;

// The lines of the list with a comma between them (CommaText quotes the ones with a space)
function Joined(const AList: TStrings): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to AList.Count - 1 do
  begin
    if LIndex > 0 then
      Result := Result + ',';
    Result := Result + AList[LIndex];
  end;
end;

{ TFakeWindow }

constructor TFakeWindow.Create;
begin
  inherited Create;
  PumpsLeft := MaxInt;
end;

function TFakeWindow.Pump: Boolean;
begin
  Result := PumpsLeft > 0;
  if Result then
    Dec(PumpsLeft);
end;

function TFakeWindow.IsDown(AKey: TGreedKey): Boolean;
begin
  Result := False;
end;

{ TFakeShower }

procedure TFakeShower.Present(const AFrame: TGreedFrame; const AColors: TGreedColors);
begin
  Inc(Count);
  LastColors := AColors;
  LastFrame := AFrame;
end;

{ TFakeTimeClock }

function TFakeTimeClock.Seconds: Double;
begin
  Result := StepsNow / 70;
end;

function TFakeTimeClock.Steps(ARate: Integer): Integer;
begin
  Result := StepsNow;
end;

function TFakeTimeClock.ScaledSteps(ARate, AScale: Integer): Integer;
begin
  Result := StepsNow * AScale;
end;

procedure TFakeTimeClock.Sleep(AMilliseconds: Integer);
begin
end;

procedure TFakeTimeClock.Wait(AMilliseconds: Integer);
begin
  Inc(Waits);
  // the time goes on while the program waits
  Inc(StepsNow);
end;

{ TFakeKeys }

constructor TFakeKeys.Create;
begin
  inherited Create;
  FEvents := TList<TEvent>.Create;
end;

destructor TFakeKeys.Destroy;
begin
  FEvents.Free;
  inherited Destroy;
end;

procedure TFakeKeys.Press(ATic, AScanCode: Integer);
var
  LEvent: TEvent;
begin
  LEvent.Tic := ATic;
  LEvent.ScanCode := AScanCode;
  LEvent.Down := True;
  FEvents.Add(LEvent);
  LEvent.Tic := ATic + 2;
  LEvent.Down := False;
  FEvents.Add(LEvent);
end;

procedure TFakeKeys.PressEvery(AFrom, ATo, ARepeat, AScanCode: Integer);
var
  LTic: Integer;
begin
  LTic := AFrom;
  while LTic <= ATo do
  begin
    Press(LTic, AScanCode);
    Inc(LTic, ARepeat);
  end;
end;

function TFakeKeys.IsDown(AScanCode: Integer): Boolean;
begin
  Result := (AScanCode >= 0) and (AScanCode < Length(FDown)) and FDown[AScanCode];
end;

procedure TFakeKeys.TicStarting(ATic: Integer);
var
  LEvent: TEvent;
begin
  Tics := ATic;
  for LEvent in FEvents do
    if LEvent.Tic = ATic then
      FDown[LEvent.ScanCode] := LEvent.Down;
  if Assigned(OnTic) then
    OnTic(ATic);
end;

{ TFakeSettingsStore }

function TFakeSettingsStore.Load(const ASettings: IGreedSettings; ACommandLineGame: Integer): Boolean;
begin
  Result := False;
end;

procedure TFakeSettingsStore.Save(const ASettings: IGreedSettings);
begin
  Inc(Saves);
end;

{ TFakeScreens }

constructor TFakeScreens.Create;
begin
  inherited Create;
  Calls := TStringList.Create;
end;

destructor TFakeScreens.Destroy;
begin
  Calls.Free;
  inherited Destroy;
end;

function TFakeScreens.ShowMenu: Boolean;
begin
  Calls.Add('ShowMenu');
  Result := QuitAnswer;
end;

procedure TFakeScreens.ShowHelp;
begin
  Calls.Add('ShowHelp');
end;

procedure TFakeScreens.ShowPause;
begin
  Calls.Add('ShowPause');
end;

function TFakeScreens.ConfirmQuit: Boolean;
begin
  Calls.Add('ConfirmQuit');
  Result := QuitAnswer;
end;

procedure TFakeScreens.MissionBriefing(AMap: Integer);
begin
  Calls.Add('MissionBriefing ' + IntToStr(AMap));
end;

procedure TFakeScreens.EndGame(AEpisode: Integer);
begin
  Calls.Add('EndGame ' + IntToStr(AEpisode));
end;

procedure TFakeScreens.PlayFli(AMovie: Integer);
begin
  Calls.Add('PlayFli ' + IntToStr(AMovie));
end;

procedure TFakeScreens.StartWait;
begin
  Calls.Add('StartWait');
end;

procedure TFakeScreens.UpdateWait;
begin
  Calls.Add('UpdateWait');
end;

procedure TFakeScreens.EndWait;
begin
  Calls.Add('EndWait');
end;

procedure TFakeScreens.FadeOutLevel;
begin
  Calls.Add('FadeOutLevel');
end;

procedure TFakeScreens.ReleaseScreen;
begin
  Calls.Add('ReleaseScreen');
end;

{ TTestGreedApplication }

procedure TTestGreedApplication.Setup;
begin
  FScreenArchive := TIntroScenarios.SyntheticArchive(False);
  FSettings := TGreedSettings.Create;
  FHost := TIntroHostFake.Create;
  FHostRef := FHost;
  FHost.Trace.Clear;
  FScreens := TGreedScreens.Create(FScreenArchive, FSettings, FHost,
    TGreedSaveGames.Create(TMenuSaveFilesFake.Create, ggvGame1), nil, FHost, FHost, FHost, FHost, False, ggvGame1);
  FGameArchive := TFakeGameArchive.Create;
  FMaps := TFakeGameMaps.Create;
  FRenderer := TFakeGameRenderer.Create;
  FRendererRef := FRenderer;
  FCommands := TFakeCommandSource.Create;
  FCommandsRef := FCommands;
  FSound := TFakeGameSound.Create;
  FSoundRef := FSound;
  FView := TFakeGameView.Create;
  FViewRef := FView;
  FScreenView := TGreedScreenView.Create(FViewRef);
  FScreenViewRef := FScreenView;
  FGame := TGreedGame.Create(FGameArchive, FMaps, FRenderer, TGreedCommandState.Create(FCommandsRef), FSound,
    FSound as IGreedMusic, TGreedRandomTable.Create, TFakeSaveGames.Create, TFakeSystemClock.Create,
    FScreenViewRef, FView as IGreedMessages);
  FWindow := TFakeWindow.Create;
  FWindowRef := FWindow;
  FShower := TFakeShower.Create;
  FShowerRef := FShower;
  FClockRef := TFakeTimeClock.Create;
  FKeys := TFakeKeys.Create;
  FKeysRef := FKeys;
  FStore := TFakeSettingsStore.Create;
  FStoreRef := FStore;
end;

procedure TTestGreedApplication.TearDown;
begin
  FScreenView.Screens := nil;
  FreeAndNil(FApplication);
  FreeAndNil(FScreens);
  FreeAndNil(FGame);
end;

function TTestGreedApplication.Options(AMaxTics: Integer; ASkipIntro, ANoBriefing: Boolean): TGreedApplicationOptions;
begin
  Result := TGreedApplicationOptions.Standard;
  Result.FreeRunning := True;
  Result.MaxTics := AMaxTics;
  Result.SkipIntro := ASkipIntro;
  Result.NoBriefing := ANoBriefing;
end;

procedure TTestGreedApplication.Build(const AOptions: TGreedApplicationOptions);
begin
  FreeAndNil(FApplication);
  FApplication := TGreedApplication.Create(FGame, FScreens, FSettings, FStoreRef, FShowerRef, FWindowRef,
    FClockRef, [FKeysRef as IGreedKeyboard], FKeysRef as IGreedTicListener, nil, 640, 400, AOptions);
  FScreenView.Screens := FApplication;
end;

function TTestGreedApplication.Line(const AName: string): string;
var
  LLines: TStringList;
  LIndex: Integer;
begin
  LLines := TStringList.Create;
  try
    FApplication.Describe(LLines);
    for LIndex := 0 to LLines.Count - 1 do
      if LLines.Names[LIndex] = AName then
        Exit(LLines.ValueFromIndex[LIndex]);
  finally
    LLines.Free;
  end;
  Result := '';
end;

procedure TTestGreedApplication.DovrebbeSollevareConDipendenzeNulle;
var
  LOptions: TGreedApplicationOptions;
begin
  LOptions := Options(10, True, True);
  Assert.IsTrue(Raises(
    procedure
    begin
      TGreedApplication.Create(nil, FScreens, FSettings, FStoreRef, FShowerRef, FWindowRef, FClockRef, [], nil, nil,
        640, 400, LOptions).Free;
    end, EArgumentNilException));
  Assert.IsTrue(Raises(
    procedure
    begin
      TGreedApplication.Create(FGame, nil, FSettings, FStoreRef, FShowerRef, FWindowRef, FClockRef, [], nil, nil,
        640, 400, LOptions).Free;
    end, EArgumentNilException));
  Assert.IsTrue(Raises(
    procedure
    begin
      TGreedApplication.Create(FGame, FScreens, nil, FStoreRef, FShowerRef, FWindowRef, FClockRef, [], nil, nil,
        640, 400, LOptions).Free;
    end, EArgumentNilException));
  Assert.IsTrue(Raises(
    procedure
    begin
      TGreedApplication.Create(FGame, FScreens, FSettings, nil, FShowerRef, FWindowRef, FClockRef, [], nil, nil,
        640, 400, LOptions).Free;
    end, EArgumentNilException));
  Assert.IsTrue(Raises(
    procedure
    begin
      TGreedApplication.Create(FGame, FScreens, FSettings, FStoreRef, nil, FWindowRef, FClockRef, [], nil, nil,
        640, 400, LOptions).Free;
    end, EArgumentNilException));
  Assert.IsTrue(Raises(
    procedure
    begin
      TGreedApplication.Create(FGame, FScreens, FSettings, FStoreRef, FShowerRef, nil, FClockRef, [], nil, nil,
        640, 400, LOptions).Free;
    end, EArgumentNilException));
  Assert.IsTrue(Raises(
    procedure
    begin
      TGreedApplication.Create(FGame, FScreens, FSettings, FStoreRef, FShowerRef, FWindowRef, nil, [], nil, nil,
        640, 400, LOptions).Free;
    end, EArgumentNilException));
end;

procedure TTestGreedApplication.DovrebbeRifiutareUnQuadroCheNonEMultiploDelloSchermo;
var
  LOptions: TGreedApplicationOptions;
begin
  LOptions := Options(10, True, True);
  Assert.IsTrue(Raises(
    procedure
    begin
      TGreedApplication.Create(FGame, FScreens, FSettings, FStoreRef, FShowerRef, FWindowRef, FClockRef, [], nil,
        nil, 500, 400, LOptions).Free;
    end, EGreedException));
end;

procedure TTestGreedApplication.DovrebbeFermarsiAiTicMassimiNellIntroduzione;
begin
  Build(Options(120, False, False));
  Assert.AreEqual(120, FApplication.Run);
  Assert.AreEqual('intro', Line('application.stoppedin'));
  Assert.AreEqual('ended', Line('application.mode'));
  Assert.AreEqual('1', Line('application.stopped'));
  Assert.IsTrue(FShower.Count > 0, 'the pictures');
end;

procedure TTestGreedApplication.DovrebbeMostrareLeImmaginiConLaPalettedelloSchermo;
begin
  Build(Options(40, False, False));
  FApplication.Run;
  // the titles fade in from black: the picture shown is a frame of the window with the palette of the display
  Assert.AreEqual(640, FShower.LastFrame.Width);
  Assert.AreEqual(400, FShower.LastFrame.Height);
  Assert.AreEqual(Length(FApplication.ScreenFrame.Pixels), Length(FShower.LastFrame.Pixels));
end;

procedure TTestGreedApplication.DovrebbeAvviareLaPartitaSenzaIntroduzione;
begin
  Build(Options(60, True, True));
  FApplication.Run;
  Assert.AreEqual('playing', Line('application.stoppedin'));
  Assert.IsTrue(FGame.State.GameLoaded, 'new player');
  Assert.AreEqual(0, FGame.Map);
  Assert.IsTrue(FRenderer.Views > 0, 'the view of the level');
  Assert.IsTrue(FGame.State.TimeCount > 0, 'the tics of the game');
end;

procedure TTestGreedApplication.DovrebbeMostrareIlBriefingPrimaDellaPartita;
begin
  Build(Options(40, True, False));
  FApplication.Run;
  Assert.AreEqual('briefing', Line('application.stoppedin'));
  Assert.AreEqual('1', Line('screens.briefing.active'));
  Assert.AreEqual(0, FGame.State.TimeCount, 'the game has not started');
end;

procedure TTestGreedApplication.DovrebbeGiocareDopoIlBriefing;
begin
  // a key now and then goes through the pages of the briefing, then the game runs
  FKeys.PressEvery(100, 3500, 25, GREED_SC_SPACE);
  Build(Options(4000, True, False));
  FApplication.Run;
  Assert.AreEqual('playing', Line('application.stoppedin'));
  Assert.AreEqual('0', Line('screens.briefing.active'));
  Assert.IsTrue(FGame.State.TimeCount > 0, 'the game runs after the briefing');
end;

procedure TTestGreedApplication.DovrebbeAprireIlMenuDalGioco;
begin
  FCommands.Pressed := [gcMenu];
  Build(Options(200, True, True));
  FApplication.Run;
  Assert.AreEqual('menu', Line('application.stoppedin'));
  Assert.AreEqual('1', Line('screens.menu.active'));
  Assert.IsFalse(FHost.QuitAsked, 'the menu does not quit');
end;

procedure TTestGreedApplication.DovrebbeTornareAlGiocoQuandoIlMenuSiChiude;
var
  LTime: Integer;
begin
  // the menu opens at the first picture; Escape closes it (the command is released once it is open)
  FCommands.Pressed := [gcMenu];
  FKeys.OnTic :=
    procedure(ATic: Integer)
    begin
      if ATic = 20 then
        FCommands.Pressed := [];
    end;
  FKeys.Press(300, GREED_SC_ESCAPE);
  FKeys.Press(305, GREED_SC_ESCAPE);
  Build(Options(900, True, True));
  FApplication.Run;
  LTime := FGame.State.TimeCount;
  Assert.IsTrue(LTime > 0, 'the game goes on after the menu');
  Assert.AreEqual('playing', Line('application.stoppedin'));
end;

procedure TTestGreedApplication.DovrebbeFinireQuandoLaConfermaDiUscitaEAffermativa;
var
  LTics: Integer;
begin
  FCommands.Pressed := [gcQuickExit];
  FKeys.OnTic :=
    procedure(ATic: Integer)
    begin
      if ATic = 30 then
        FCommands.Pressed := [];
    end;
  // the panel comes down and waits for Y
  FKeys.Press(400, GREED_SC_Y);
  Build(Options(2000, True, True));
  LTics := FApplication.Run;
  Assert.IsTrue(LTics < 2000, 'the program ended before the limit');
  Assert.AreEqual('0', Line('application.stopped'));
  Assert.AreEqual('1', Line('application.quitgame'));
end;

procedure TTestGreedApplication.DovrebbeRiprendereIlGiocoDopoLaPausa;
var
  LAtPause: Integer;
begin
  FCommands.Pressed := [gcPause];
  LAtPause := -1;
  FKeys.OnTic :=
    procedure(ATic: Integer)
    begin
      if ATic = 30 then
        FCommands.Pressed := [];
      if ATic = 200 then
        LAtPause := FGame.State.TimeCount;
    end;
  FKeys.Press(210, GREED_SC_SPACE);
  Build(Options(700, True, True));
  FApplication.Run;
  Assert.AreEqual('playing', Line('application.stoppedin'));
  Assert.IsTrue(FGame.State.TimeCount > LAtPause, 'the game ticks again after the key');
end;

procedure TTestGreedApplication.DovrebbeFermarsiQuandoLaFinestraSiChiude;
var
  LTics: Integer;
begin
  FWindow.PumpsLeft := 30;
  Build(Options(5000, True, True));
  LTics := FApplication.Run;
  Assert.IsTrue(LTics < 100, 'the window ended it');
  Assert.AreEqual('1', Line('application.stopped'));
  Assert.AreEqual('1', Line('application.quitgame'));
end;

procedure TTestGreedApplication.DovrebbeSalvareLeImpostazioniAllaFineDellaPartita;
begin
  Build(Options(50, True, True));
  FApplication.Run;
  Assert.IsTrue(FStore.Saves >= 1, 'M_SaveDefaults at the end of maingame');
end;

procedure TTestGreedApplication.DovrebbeDissolvereLaPalettealNeroAllaFineDelLivello;
var
  LCount: Integer;
begin
  Build(Options(0, True, True));
  FScreens.Display.SetPaletteFromLump('palette');
  LCount := FShower.Count;
  FApplication.FadeOutLevel;
  Assert.IsTrue(FShower.Count - LCount >= 30, 'the fade shows a picture every two tics');
  // the palette of the game is back and the picture of the level is cleared
  Assert.AreEqual(0, Integer(FApplication.GameFrame.Pixels[0]));
  Assert.IsTrue(FScreens.Display.Palette[3 * 20] <> 0, 'the palette of the game again');
end;

procedure TTestGreedApplication.DovrebbeTenereLoSchermoDopoUnFilmato;
begin
  Build(Options(0, True, True));
  FApplication.PlayFli(0);
  Assert.IsTrue(FApplication.ScreenHeld, 'the picture stays');
  FApplication.ReleaseScreen;
  Assert.IsFalse(FApplication.ScreenHeld, 'the level starts again');
end;

procedure TTestGreedApplication.DovrebbeIgnorareUnFilmatoSconosciuto;
begin
  Build(Options(0, True, True));
  FApplication.PlayFli(7);
  Assert.IsFalse(FApplication.ScreenHeld);
end;

procedure TTestGreedApplication.DovrebbeChiedereLIntroduzioneDopoUnFinale;
begin
  Build(Options(30, True, True));
  Assert.IsFalse(FApplication.Redo);
  FApplication.EndGame(1);
  Assert.IsTrue(FApplication.Redo, 'redo: the introduction comes back without its titles');
end;

procedure TTestGreedApplication.DovrebbeNonMostrareIlBriefingConNoBriefing;
begin
  Build(Options(20, True, True));
  FApplication.MissionBriefing(0);
  Assert.AreEqual('0', Line('screens.briefing.active'));
end;

procedure TTestGreedApplication.DovrebbeDescrivereLoStatoDelProgramma;
var
  LLines: TStringList;
begin
  Build(Options(10, False, False));
  FApplication.Run;
  LLines := TStringList.Create;
  try
    FApplication.Describe(LLines);
    Assert.IsTrue(LLines.IndexOfName('application.mode') >= 0);
    Assert.IsTrue(LLines.IndexOfName('application.tics') >= 0);
    Assert.IsTrue(LLines.IndexOfName('screens.menu.level') >= 0);
    Assert.IsTrue(LLines.IndexOfName('screens.display.paletteversion') >= 0);
    Assert.IsTrue(Raises(
      procedure
      begin
        FApplication.Describe(nil);
      end, EArgumentNilException));
  finally
    LLines.Free;
  end;
end;

procedure TTestGreedApplication.DovrebbeContareITicDiOgniFase;
begin
  Build(Options(77, True, True));
  Assert.AreEqual(77, FApplication.Run);
  Assert.AreEqual(77, FApplication.Tics);
  Assert.IsTrue(FApplication.Frames > 0);
end;

procedure TTestGreedApplication.DovrebbeAspettareSeIlRelogioNonHaTic;
var
  LOptions: TGreedApplicationOptions;
begin
  // with the clock the program runs the tics that the clock counts: when none is due it waits
  LOptions := Options(5, True, True);
  LOptions.FreeRunning := False;
  Build(LOptions);
  FApplication.Run;
  Assert.IsTrue((FClockRef as TFakeTimeClock).Waits > 0, 'it waited for the clock');
  Assert.AreEqual(5, FApplication.Tics);
end;

{ TTestGreedScreenView }

procedure TTestGreedScreenView.Setup;
begin
  FInner := TFakeGameView.Create;
  FInnerRef := FInner;
  FView := TGreedScreenView.Create(FInnerRef);
  FViewRef := FView;
  FScreens := TFakeScreens.Create;
  FScreensRef := FScreens;
end;

procedure TTestGreedScreenView.DovrebbeSollevareConLaVistaNulla;
begin
  Assert.IsTrue(Raises(
    procedure
    begin
      TGreedScreenView.Create(nil);
    end, EArgumentNilException));
end;

procedure TTestGreedScreenView.DovrebbeInoltrareLaBarraDiStatoAllaVistaInterna;
var
  LFrame: TGreedFrame;
  LOverlay: TGreedViewOverlay;
begin
  FView.Screens := FScreensRef;
  FView.RefreshAmmo;
  FView.RefreshGoalItem;
  FView.ResetMessages;
  FView.SetTotalEffectTime(9);
  FView.ChangeViewSize(True);
  FView.SetGameEpisode(2);
  LFrame := TGreedFrame.Make(320, 200);
  LOverlay := Default(TGreedViewOverlay);
  FView.DrawOverlay(LFrame, LOverlay);
  Assert.AreEqual(1, FInner.CountOf('RefreshAmmo'));
  Assert.AreEqual(1, FInner.CountOf('RefreshGoalItem'));
  Assert.AreEqual(1, FInner.CountOf('SetTotalEffectTime 9'));
  Assert.AreEqual(1, FInner.CountOf('ChangeViewSize 1'));
  Assert.AreEqual(1, FInner.CountOf('SetGameEpisode 2'));
  Assert.AreEqual(1, FInner.Overlays);
  Assert.AreEqual(0, FScreens.Calls.Count, 'the screens are not asked');
end;

procedure TTestGreedScreenView.DovrebbeInoltrareLeSchermateAlProgramma;
begin
  FView.Screens := FScreensRef;
  FView.MissionBriefing(3);
  FView.EndGame(1);
  FView.PlayFli(2);
  FView.StartWait;
  FView.UpdateWait;
  FView.EndWait;
  FView.FadeOutLevel;
  FView.ShowMenu;
  FView.ShowHelp;
  FView.ShowPause;
  FView.ConfirmQuit;
  Assert.AreEqual('MissionBriefing 3,EndGame 1,PlayFli 2,StartWait,UpdateWait,EndWait,FadeOutLevel,ShowMenu,' +
    'ShowHelp,ShowPause,ConfirmQuit', Joined(FScreens.Calls));
  Assert.AreEqual(0, FInner.Calls.Count, 'the inner view is not asked');
end;

procedure TTestGreedScreenView.DovrebbeDareLeSchermateAllaVistaInternaSenzaProgramma;
begin
  FView.MissionBriefing(3);
  FView.EndGame(1);
  FView.PlayFli(2);
  FView.StartWait;
  FView.EndWait;
  FView.FadeOutLevel;
  FView.ShowMenu;
  FView.ShowHelp;
  FView.ShowPause;
  FView.ConfirmQuit;
  Assert.AreEqual(1, FInner.CountOf('MissionBriefing 3'));
  Assert.AreEqual(1, FInner.CountOf('EndGame 1'));
  Assert.AreEqual(1, FInner.CountOf('PlayFli 2'));
  Assert.AreEqual(1, FInner.CountOf('StartWait'));
  Assert.AreEqual(1, FInner.CountOf('EndWait'));
  Assert.AreEqual(1, FInner.CountOf('FadeOutLevel'));
  Assert.AreEqual(1, FInner.CountOf('ShowMenu'));
  Assert.AreEqual(1, FInner.CountOf('ShowHelp'));
  Assert.AreEqual(1, FInner.CountOf('ShowPause'));
  Assert.AreEqual(1, FInner.CountOf('ConfirmQuit'));
end;

procedure TTestGreedScreenView.DovrebbeRilasciareLoSchermoQuandoIlGiocoRipuliscelIlDisplay;
begin
  FView.Screens := FScreensRef;
  FView.ResetDisplay;
  Assert.AreEqual(1, FInner.CountOf('ResetDisplay'), 'the status bar is drawn again');
  Assert.AreEqual('ReleaseScreen', Joined(FScreens.Calls), 'and what a movie left goes away');
end;

procedure TTestGreedScreenView.DovrebbeRipetereLaRispostaDelMenu;
begin
  FScreens.QuitAnswer := True;
  FView.Screens := FScreensRef;
  Assert.IsTrue(FView.ShowMenu);
  Assert.IsTrue(FView.ConfirmQuit);
  FScreens.QuitAnswer := False;
  Assert.IsFalse(FView.ShowMenu);
  FView.Screens := nil;
  FInner.QuitFromMenu := True;
  Assert.IsTrue(FView.ShowMenu, 'the inner view answers without the program');
end;

{ TTestGreedScreenHosts }

procedure TTestGreedScreenHosts.Setup;
begin
  FSetup := TFakeGameSetup.Create;
  FSetup.CreateGame;
  FSettings := TGreedSettings.Create;
  FStore := TFakeSettingsStore.Create;
  FStoreRef := FStore;
end;

procedure TTestGreedScreenHosts.TearDown;
begin
  FSetup.Free;
end;

procedure TTestGreedScreenHosts.DovrebbeFarPartireUnaNuovaPartitaDalMenu;
var
  LHost: IGreedMenuHost;
begin
  LHost := TGreedMenuHost.Create(FSetup.Game, FSettings, FStoreRef, nil);
  Assert.IsFalse(LHost.GameLoaded);
  LHost.NewGame(0, 2, 3);
  Assert.IsTrue(LHost.GameLoaded);
  Assert.AreEqual(2, Integer(FSetup.Game.State.Player.CharType));
  Assert.AreEqual(3, Integer(FSetup.Game.State.Player.Difficulty));
  Assert.AreEqual(0, FSetup.Game.Map);
end;

procedure TTestGreedScreenHosts.DovrebbeFermareIlGiocoQuandoIlMenuEsce;
var
  LHost: IGreedMenuHost;
begin
  LHost := TGreedMenuHost.Create(FSetup.Game, FSettings, FStoreRef, nil);
  LHost.NewGame(0, 0, 2);
  Assert.IsFalse(FSetup.Game.QuitGame);
  LHost.QuitGame;
  Assert.IsTrue(FSetup.Game.QuitGame);
end;

procedure TTestGreedScreenHosts.DovrebbeSalvareLeImpostazioniEApplicarleAlGioco;
var
  LHost: IGreedMenuHost;
begin
  LHost := TGreedMenuHost.Create(FSetup.Game, FSettings, FStoreRef, nil);
  FSettings.SetBoolean('violence', False);
  FSettings.SetInteger('camdelay', 35);
  LHost.SaveSettings;
  Assert.AreEqual(1, FStore.Saves);
  Assert.IsFalse(FSetup.Game.Violence);
  Assert.AreEqual(35, FSetup.Game.CameraDelay);
  FSettings.SetBoolean('violence', True);
  LHost.SaveSettings;
  Assert.IsTrue(FSetup.Game.Violence);
end;

procedure TTestGreedScreenHosts.DovrebbeAzzerareLeVelocitaQuandoIlMenuSiChiude;
var
  LHost: IGreedMenuHost;
begin
  LHost := TGreedMenuHost.Create(FSetup.Game, FSettings, FStoreRef, nil);
  FSetup.Game.State.TurnRate := 5;
  FSetup.Game.State.MoveRate := 6;
  FSetup.Game.State.FallRate := 7;
  FSetup.Game.State.StrafRate := 8;
  LHost.ResetControls;
  Assert.AreEqual(0, FSetup.Game.State.TurnRate);
  Assert.AreEqual(0, FSetup.Game.State.MoveRate);
  Assert.AreEqual(0, FSetup.Game.State.FallRate);
  Assert.AreEqual(0, FSetup.Game.State.StrafRate);
end;

procedure TTestGreedScreenHosts.DovrebbeSuonareLaMusicaDellIntroduzioneEAzzerareLeBandiere;
var
  LHost: IGreedIntroHost;
begin
  LHost := TGreedIntroHost.Create(FSetup.Game);
  FSetup.Game.State.QuitGame := True;
  FSetup.Game.State.GameLoaded := True;
  LHost.BeginIntro;
  Assert.AreEqual('INTRO.S3M', FSetup.Sound.Songs[FSetup.Sound.Songs.Count - 1]);
  Assert.IsFalse(LHost.QuitRequested);
  Assert.IsFalse(LHost.GameLoaded);
  LHost.UpdateSound;
end;

procedure TTestGreedScreenHosts.DovrebbeDireSeIlGiocoEStatoCaricatoOSeEUscito;
var
  LHost: IGreedIntroHost;
begin
  LHost := TGreedIntroHost.Create(FSetup.Game);
  FSetup.Game.State.GameLoaded := True;
  Assert.IsTrue(LHost.GameLoaded);
  FSetup.Game.State.QuitGame := True;
  Assert.IsTrue(LHost.QuitRequested);
end;

procedure TTestGreedScreenHosts.DovrebbeRipartireDaUnNuovoCacciatoreAlSecondoEpisodio;
var
  LHost: IGreedBriefingHost;
begin
  FSetup.Game.NewGame(8, 0, 2);
  FSetup.Game.State.Player.Weapons[3] := 4;
  FSetup.Game.State.Player.Ammo[1] := 3;
  FSetup.Game.State.Player.Shield := 10;
  FSetup.Game.State.Player.Inventory[0] := 9;
  LHost := TGreedEpisodeHost.Create(FSetup.Game);
  LHost.StartEpisode(8);
  Assert.AreEqual(-1, Integer(FSetup.Game.State.Player.Weapons[3]));
  Assert.AreEqual(0, Integer(FSetup.Game.State.Player.CurrentWeapon));
  Assert.AreEqual(100, Integer(FSetup.Game.State.Player.Ammo[1]));
  Assert.AreEqual(200, Integer(FSetup.Game.State.Player.Shield));
  Assert.AreEqual(0, Integer(FSetup.Game.State.Player.Inventory[0]));
  Assert.AreEqual(4, Integer(FSetup.Game.State.Player.Inventory[2]));
  Assert.AreEqual(Integer(FSetup.Game.State.Player.MaxAngst), Integer(FSetup.Game.State.Player.Angst));
end;

procedure TTestGreedScreenHosts.DovrebbeScegliereLaMusicaDelleSchermate;
var
  LHost: IGreedEndGameHost;
begin
  LHost := TGreedEpisodeHost.Create(FSetup.Game);
  FSetup.Sound.Songs.Clear;
  LHost.SelectSong(22);
  Assert.AreEqual(1, FSetup.Sound.Songs.Count, 'the song of the ending');
end;

procedure TTestGreedScreenHosts.DovrebbeSollevareConIlGiocoNullo;
begin
  Assert.IsTrue(Raises(
    procedure
    begin
      TGreedMenuHost.Create(nil, FSettings, FStoreRef, nil);
    end, EArgumentNilException));
  Assert.IsTrue(Raises(
    procedure
    begin
      TGreedMenuHost.Create(FSetup.Game, nil, FStoreRef, nil);
    end, EArgumentNilException));
  Assert.IsTrue(Raises(
    procedure
    begin
      TGreedMenuHost.Create(FSetup.Game, FSettings, nil, nil);
    end, EArgumentNilException));
  Assert.IsTrue(Raises(
    procedure
    begin
      TGreedIntroHost.Create(nil);
    end, EArgumentNilException));
  Assert.IsTrue(Raises(
    procedure
    begin
      TGreedEpisodeHost.Create(nil);
    end, EArgumentNilException));
end;

end.
