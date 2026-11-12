{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the program: introduction, menu, briefings,      }
{  game, endings and movies in one loop of time                                 }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): startup of intro.pas,       }
{  maingame and PlayLoop of raven.pas                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Application;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Defaults, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf,
  DelphiDoom.Greed.Frame.Intf, DelphiDoom.Greed.Settings.Intf, DelphiDoom.Greed.Game, DelphiDoom.Greed.Screens,
  DelphiDoom.Greed.Application.Intf, DelphiDoom.Clock.Intf;

const
  /// <summary>TICRATE: every phase of the program runs at 70 tics a second</summary>
  GREED_APPLICATION_TIC_RATE = 70;
  /// <summary>Tics that the loop catches up at most in one picture (a slow window must not freeze the program)</summary>
  GREED_APPLICATION_MAX_CATCH_UP = 10;
  /// <summary>Tics between two pictures when the loop does not follow the clock</summary>
  GREED_APPLICATION_FREE_TICS = 2;

type
  /// <summary>
  ///   What the program is doing: the introduction (the titles, the portraits), the game, or one of the screens that
  ///   take the picture for a while (they are inside the introduction or the game, as in the original)
  /// </summary>
  TGreedApplicationMode = (gamIdle, gamIntro, gamPlaying, gamMenu, gamQuit, gamHelp, gamPause, gamBriefing,
    gamEndGame, gamMovie, gamFade, gamEnded);

  /// <summary>What the program is asked to do beyond the data it is given</summary>
  TGreedApplicationOptions = record
    /// <summary>The clock is not read: every picture comes after TicsPerFrame tics, so the same keys always give the same program</summary>
    FreeRunning: Boolean;
    /// <summary>With FreeRunning: the tics between two pictures</summary>
    TicsPerFrame: Integer;
    /// <summary>The program ends after that many tics (the first is 1); 0 is no limit</summary>
    MaxTics: Integer;
    /// <summary>nointro of the original: the game starts at once on the first map, without titles and menu</summary>
    SkipIntro: Boolean;
    /// <summary>nobriefing of the original: no screens before a map</summary>
    NoBriefing: Boolean;
    /// <summary>With SkipIntro: the map (0, 8 or 16 for an episode), the character (0..5) and the difficulty</summary>
    StartMap: Integer;
    Character: Integer;
    Difficulty: Integer;
    class function Standard: TGreedApplicationOptions; static;
  end;

  /// <summary>
  ///   The program of the game as a state machine in one loop of time: startup of the original (the introduction
  ///   and its menu, or at once a new game with SkipIntro), maingame and PlayLoop (the game), and after the end of
  ///   an episode the introduction again without its titles (redo). Every phase runs at 70 tics a second from the
  ///   same clock; the screens that the original shows from inside the game (menu, help, pause, quit, briefings,
  ///   endings, movies, the fade of the end of a level) run their own turns of the same loop, so the game does not
  ///   tic while they are up, as in the original.
  ///   The picture is always a frame of the window: the game draws a frame, a screen the canvas of 320 x 200 of the
  ///   display (scaled to the frame, over the last picture of the game for the menus, over black for the others);
  ///   the palette is always the one of the display, so the fades and the movies show their colors.
  ///   The keys of the screens come from the keyboards (the window and a script), the commands of the game from its
  ///   own source. Not ported: the mouse, the net game, the demos.
  ///   Differences from the original: a window that is closed ends the program from any phase; a movie that is not
  ///   found is skipped
  /// </summary>
  TGreedApplication = class(TSingletonImplementation, IGreedScreens)
  strict private
    FGame: TGreedGame;
    FScreens: TGreedScreens;
    FSettings: IGreedSettings;
    FStore: IGreedSettingsStore;
    FPresenter: IGreedFramePresenter;
    FWindow: IGreedInput;
    FClock: IClock;
    FKeyboards: TArray<IGreedKeyboard>;
    FTicListener: IGreedTicListener;
    FMovies: IGreedExternalFiles;
    FOptions: TGreedApplicationOptions;
    FFrame: TGreedFrame;
    FScreenFrame: TGreedFrame;
    FSnapshot: TBytes;
    FOverlay: Boolean;
    FScreenHold: Boolean;
    FRedo: Boolean;
    FStopped: Boolean;
    FMode: TGreedApplicationMode;
    FStoppedIn: TGreedApplicationMode;
    FTics: Integer;
    FFrames: Integer;
    function DueTics: Integer;
    procedure SampleKeys;
    procedure SyncInputWithGame;
    procedure PresentFrame(const AFrame: TGreedFrame);
    procedure ShowCanvas;
    procedure ShowGameFrame;
    procedure PlayFrame;
    procedure RunLoop(const ATick: TProc; const AActive: TFunc<Boolean>; const AShow: TProc);
    procedure RunModal(AMode: TGreedApplicationMode; ASolid: Boolean; const ATick: TProc;
      const AActive: TFunc<Boolean>; const AShow: TProc);
    procedure RunIntro(ARedo: Boolean);
    procedure RunGame;
    procedure StartNewGame;
    procedure BeginOverlay;
    procedure EndOverlay;
    procedure Stop;
    function LoadMovie(const AName: string): TBytes;
  public
    /// <summary>
    ///   AGame and AScreens are not owned. The window gives the pictures (APresenter) and says when to stop
    ///   (AWindow); AClock gives the time; the keyboards give the keys of the screens; ATicListener (may be nil) is
    ///   told of every tic; AMovies (may be nil) finds the movies by name. The pictures are AFrameWidth x
    ///   AFrameHeight, a whole number of times 320 x 200. EArgumentNilException if a dependency is nil
    /// </summary>
    constructor Create(AGame: TGreedGame; AScreens: TGreedScreens; const ASettings: IGreedSettings;
      const AStore: IGreedSettingsStore; const APresenter: IGreedFramePresenter; const AWindow: IGreedInput;
      const AClock: IClock; const AKeyboards: array of IGreedKeyboard; const ATicListener: IGreedTicListener;
      const AMovies: IGreedExternalFiles; AFrameWidth, AFrameHeight: Integer; const AOptions: TGreedApplicationOptions);
    /// <summary>Runs the program until the player quits, the window is closed or the tics are over; returns the tics played</summary>
    function Run: Integer;
    /// <summary>The state of the program as "name=value" lines: the mode, the clocks, the screens and the menu</summary>
    procedure Describe(ALines: TStrings);
    // IGreedScreens
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
    property Mode: TGreedApplicationMode read FMode;
    /// <summary>The tics and the pictures of every phase together</summary>
    property Tics: Integer read FTics;
    property Frames: Integer read FFrames;
    /// <summary>The last picture of the game (the frame)</summary>
    property GameFrame: TGreedFrame read FFrame;
    /// <summary>The last picture of a screen, over the game or over black</summary>
    property ScreenFrame: TGreedFrame read FScreenFrame;
    /// <summary>A movie left its last picture on the screen: it stays until the level starts again</summary>
    property ScreenHeld: Boolean read FScreenHold;
    /// <summary>The end of an episode was shown: the introduction comes back without its titles</summary>
    property Redo: Boolean read FRedo;
  end;

implementation

uses
  DelphiDoom.Greed.Display, DelphiDoom.Greed.MenuInput, DelphiDoom.Greed.PaletteFader, DelphiDoom.Greed.Briefing,
  DelphiDoom.Greed.Menu, DelphiDoom.Greed.Intro, DelphiDoom.Greed.Game.State;

const
  LUMP_PALETTE = 'palette';
  FLI_NAMES: array[0..2] of string = ('JETTISON.FLI', 'TMPL_DIE.FLI', 'KAAL_DIE.FLI');
  FLI_TEXTS: array[0..2] of string = ('Do not taunt happy fun airlock.', 'Original recipe or extra crispy?',
    'Thank you for recycling!');
  FLI_TEXT_COLOR = 8;
  FLI_TEXT_X = 160;
  FLI_TEXT_Y = 185;
  FADE_STEPS = 64;

{ TGreedApplicationOptions }

class function TGreedApplicationOptions.Standard: TGreedApplicationOptions;
begin
  Result := Default(TGreedApplicationOptions);
  Result.TicsPerFrame := GREED_APPLICATION_FREE_TICS;
  Result.Difficulty := 2;
end;

{ TGreedApplication }

constructor TGreedApplication.Create(AGame: TGreedGame; AScreens: TGreedScreens; const ASettings: IGreedSettings;
  const AStore: IGreedSettingsStore; const APresenter: IGreedFramePresenter; const AWindow: IGreedInput;
  const AClock: IClock; const AKeyboards: array of IGreedKeyboard; const ATicListener: IGreedTicListener;
  const AMovies: IGreedExternalFiles; AFrameWidth, AFrameHeight: Integer; const AOptions: TGreedApplicationOptions);
var
  LIndex: Integer;
begin
  inherited Create;
  if not Assigned(AGame) then
    raise EArgumentNilException.Create('AGame');
  if not Assigned(AScreens) then
    raise EArgumentNilException.Create('AScreens');
  if not Assigned(ASettings) then
    raise EArgumentNilException.Create('ASettings');
  if not Assigned(AStore) then
    raise EArgumentNilException.Create('AStore');
  if not Assigned(APresenter) then
    raise EArgumentNilException.Create('APresenter');
  if not Assigned(AWindow) then
    raise EArgumentNilException.Create('AWindow');
  if not Assigned(AClock) then
    raise EArgumentNilException.Create('AClock');
  FGame := AGame;
  FScreens := AScreens;
  FSettings := ASettings;
  FStore := AStore;
  FPresenter := APresenter;
  FWindow := AWindow;
  FClock := AClock;
  FTicListener := ATicListener;
  FMovies := AMovies;
  FOptions := AOptions;
  if FOptions.TicsPerFrame < 1 then
    FOptions.TicsPerFrame := GREED_APPLICATION_FREE_TICS;
  SetLength(FKeyboards, Length(AKeyboards));
  for LIndex := 0 to High(AKeyboards) do
    FKeyboards[LIndex] := AKeyboards[LIndex];
  if (AFrameWidth < 320) or (AFrameHeight < 200) or (AFrameWidth mod 320 <> 0) or (AFrameHeight mod 200 <> 0) then
    raise EGreedException.CreateFmt(SGreedImageSize, [AFrameWidth, AFrameHeight, 'application']);
  FFrame := TGreedFrame.Make(AFrameWidth, AFrameHeight);
  FScreenFrame := TGreedFrame.Make(AFrameWidth, AFrameHeight);
  FMode := gamIdle;
end;

procedure TGreedApplication.Stop;
begin
  if not FStopped then
    FStoppedIn := FMode;
  FStopped := True;
  FGame.State.QuitGame := True;
end;

function TGreedApplication.DueTics: Integer;
var
  LTarget: Integer;
begin
  if FOptions.FreeRunning then
    Exit(FOptions.TicsPerFrame);
  LTarget := FClock.Steps(GREED_APPLICATION_TIC_RATE);
  Result := LTarget - FTics;
  if Result > GREED_APPLICATION_MAX_CATCH_UP then
  begin
    // the window was too slow: the program does not run all the tics it lost
    FTics := LTarget - GREED_APPLICATION_MAX_CATCH_UP;
    Result := GREED_APPLICATION_MAX_CATCH_UP;
  end;
  if Result < 0 then
    Result := 0;
end;

procedure TGreedApplication.SampleKeys;
var
  LCode: Integer;
  LKeyboard: IGreedKeyboard;
  LDown: Boolean;
begin
  for LCode := 0 to GREED_MENU_SCAN_CODES - 1 do
  begin
    LDown := False;
    for LKeyboard in FKeyboards do
      if LKeyboard.IsDown(LCode) then
      begin
        LDown := True;
        Break;
      end;
    FScreens.Input.SetKey(LCode, LDown);
  end;
end;

procedure TGreedApplication.SyncInputWithGame;
var
  LCode: Integer;
begin
  // the keys that opened the screen are still down: they are not pressed again (eat_key)
  FScreens.Input.ReleaseAll;
  FScreens.Input.TimeCount := FGame.State.TimeCount;
  SampleKeys;
  FScreens.Input.ReadControls;
  for LCode := 0 to GREED_MENU_SCAN_CODES - 1 do
    FScreens.Input.EatKey(LCode);
  FScreens.Input.NewAscii := False;
  FScreens.Input.LastAscii := #0;
end;

procedure TGreedApplication.PresentFrame(const AFrame: TGreedFrame);
var
  LPalette: TBytes;
  LColors: TGreedColors;
  LIndex: Integer;
begin
  LPalette := FScreens.Display.Palette;
  for LIndex := 0 to 255 do
    LColors[LIndex] := (Cardinal(LPalette[LIndex * 3]) shl 16) or (Cardinal(LPalette[LIndex * 3 + 1]) shl 8) or
      Cardinal(LPalette[LIndex * 3 + 2]);
  FPresenter.Present(AFrame, LColors);
end;

procedure TGreedApplication.ShowCanvas;
begin
  if FOverlay and (Length(FSnapshot) = Length(FScreenFrame.Pixels)) then
    Move(FSnapshot[0], FScreenFrame.Pixels[0], Length(FSnapshot))
  else
    FillChar(FScreenFrame.Pixels[0], Length(FScreenFrame.Pixels), 0);
  // the color 0 of the canvas is "nothing here": what is under shows through
  FScreens.Canvas.ComposeOnto(FScreenFrame);
  PresentFrame(FScreenFrame);
  Inc(FFrames);
end;

procedure TGreedApplication.ShowGameFrame;
begin
  PresentFrame(FFrame);
  Inc(FFrames);
end;

procedure TGreedApplication.PlayFrame;
begin
  FGame.Frame(FFrame);
  if FScreenHold then
    ShowCanvas
  else
    ShowGameFrame;
end;

procedure TGreedApplication.RunLoop(const ATick: TProc; const AActive: TFunc<Boolean>; const AShow: TProc);
var
  LDue, LPlayed: Integer;
begin
  while (not FStopped) and AActive() do
  begin
    if not FWindow.Pump then
    begin
      Stop;
      Break;
    end;
    LDue := DueTics;
    LPlayed := 0;
    while (LPlayed < LDue) and (not FStopped) and AActive() do
    begin
      Inc(FTics);
      if Assigned(FTicListener) then
        FTicListener.TicStarting(FTics);
      ATick();
      Inc(LPlayed);
      if (FOptions.MaxTics > 0) and (FTics >= FOptions.MaxTics) then
        Stop;
    end;
    AShow();
    if (LPlayed = 0) and not FOptions.FreeRunning then
      FClock.Wait(1);
  end;
end;

procedure TGreedApplication.RunModal(AMode: TGreedApplicationMode; ASolid: Boolean; const ATick: TProc;
  const AActive: TFunc<Boolean>; const AShow: TProc);
var
  LMode: TGreedApplicationMode;
  LOverlay: Boolean;
begin
  LMode := FMode;
  LOverlay := FOverlay;
  FMode := AMode;
  if ASolid then
    FOverlay := False;
  try
    RunLoop(ATick, AActive, AShow);
  finally
    FMode := LMode;
    FOverlay := LOverlay;
  end;
end;

procedure TGreedApplication.BeginOverlay;
begin
  // the screen that opens over the game keeps the last picture under it; what it draws starts from nothing
  FSnapshot := Copy(FFrame.Pixels, 0, Length(FFrame.Pixels));
  FScreens.Canvas.Clear;
  SyncInputWithGame;
  FOverlay := True;
end;

procedure TGreedApplication.EndOverlay;
begin
  FOverlay := False;
  FSnapshot := nil;
end;

function TGreedApplication.ShowMenu: Boolean;
begin
  BeginOverlay;
  try
    FScreens.Menu.OpenMenu;
    RunModal(gamMenu, False,
      procedure
      begin
        SampleKeys;
        FScreens.Menu.Tick;
      end,
      function: Boolean
      begin
        Result := FScreens.Menu.Active;
      end,
      ShowCanvas);
  finally
    EndOverlay;
  end;
  Result := FGame.State.QuitGame;
end;

procedure TGreedApplication.ShowHelp;
begin
  BeginOverlay;
  try
    FScreens.Menu.OpenHelp;
    RunModal(gamHelp, False,
      procedure
      begin
        SampleKeys;
        FScreens.Menu.Tick;
      end,
      function: Boolean
      begin
        Result := FScreens.Menu.Active;
      end,
      ShowCanvas);
  finally
    EndOverlay;
  end;
end;

procedure TGreedApplication.ShowPause;
begin
  BeginOverlay;
  try
    FScreens.Menu.OpenPause;
    RunModal(gamPause, False,
      procedure
      begin
        SampleKeys;
        FScreens.Menu.Tick;
      end,
      function: Boolean
      begin
        Result := FScreens.Menu.Active;
      end,
      ShowCanvas);
  finally
    EndOverlay;
  end;
end;

function TGreedApplication.ConfirmQuit: Boolean;
begin
  BeginOverlay;
  try
    FScreens.Menu.OpenQuit;
    RunModal(gamQuit, False,
      procedure
      begin
        SampleKeys;
        FScreens.Menu.Tick;
      end,
      function: Boolean
      begin
        Result := FScreens.Menu.Active;
      end,
      ShowCanvas);
  finally
    EndOverlay;
  end;
  Result := FScreens.Menu.QuitAnswer;
end;

procedure TGreedApplication.MissionBriefing(AMap: Integer);
var
  LStats: TGreedBriefingStats;
  LIndex: Integer;
  S: TGreedGameState;
begin
  if FOptions.NoBriefing then
    Exit;
  S := FGame.State;
  LStats := Default(TGreedBriefingStats);
  LStats.PrimariesTaken := S.Player.Primaries[0] + S.Player.Primaries[1];
  LStats.PrimariesTotal := S.PCount[0] + S.PCount[1];
  for LIndex := 0 to 6 do
  begin
    Inc(LStats.SecondariesTaken, S.Player.Secondaries[LIndex]);
    Inc(LStats.SecondariesTotal, S.SCount[LIndex]);
  end;
  LStats.Score := S.Player.Score;
  LStats.BodyCount := S.Player.BodyCount;
  FScreens.Briefing.Start(AMap, LStats);
  RunModal(gamBriefing, True,
    procedure
    begin
      SampleKeys;
      FScreens.Briefing.Tick;
    end,
    function: Boolean
    begin
      Result := FScreens.Briefing.Active;
    end,
    ShowCanvas);
end;

procedure TGreedApplication.EndGame(AEpisode: Integer);
begin
  FRedo := True;
  FScreens.EndGame.Start(AEpisode);
  RunModal(gamEndGame, True,
    procedure
    begin
      SampleKeys;
      FScreens.EndGame.Tick;
    end,
    function: Boolean
    begin
      Result := FScreens.EndGame.Active;
    end,
    ShowCanvas);
end;

function TGreedApplication.LoadMovie(const AName: string): TBytes;
var
  LIndex: Integer;
begin
  Result := nil;
  if FGame.State.Demo then
  begin
    // the movies of the demo are lumps of the archive
    LIndex := FGame.Parts.Archive.IndexOf(AName);
    if LIndex >= 0 then
      Result := FGame.Parts.Archive.ReadLumpRaw(LIndex);
  end
  else if Assigned(FMovies) and FMovies.Exists(AName) then
    Result := FMovies.ReadAll(AName);
end;

procedure TGreedApplication.PlayFli(AMovie: Integer);
begin
  if (AMovie < Low(FLI_NAMES)) or (AMovie > High(FLI_NAMES)) then
    Exit;
  FScreens.Player.Open(LoadMovie(FLI_NAMES[AMovie]));
  RunModal(gamMovie, True,
    procedure
    begin
      SampleKeys;
      FScreens.Player.Tick;
    end,
    function: Boolean
    begin
      Result := FScreens.Player.Active;
    end,
    ShowCanvas);
  // the line of text goes over the last picture, and the picture stays until the player starts again
  FScreens.Printer.Font := FScreens.Font;
  FScreens.Printer.BaseColor := FLI_TEXT_COLOR;
  FScreens.Printer.PrintX := FLI_TEXT_X;
  FScreens.Printer.PrintY := FLI_TEXT_Y;
  FScreens.Printer.PrintCentered(FLI_TEXTS[AMovie]);
  FScreenHold := True;
  FOverlay := False;
end;

procedure TGreedApplication.StartWait;
begin
  FScreens.Menu.StartWait;
  ShowCanvas;
end;

procedure TGreedApplication.UpdateWait;
begin
  if FScreens.Menu.Waiting then
  begin
    FScreens.Menu.UpdateWait;
    ShowCanvas;
  end;
end;

procedure TGreedApplication.EndWait;
begin
  FScreens.Menu.EndWait;
end;

procedure TGreedApplication.FadeOutLevel;
var
  LFader: TGreedPaletteFader;
begin
  LFader := TGreedPaletteFader.Create;
  try
    LFader.StartFadeOut(FScreens.Display.Palette, 0, 256, 0, 0, 0, FADE_STEPS);
    RunModal(gamFade, False,
      procedure
      begin
        if LFader.Step then
          FScreens.Display.SetPalette(LFader.Current);
      end,
      function: Boolean
      begin
        Result := LFader.Active;
      end,
      ShowGameFrame);
  finally
    LFader.Free;
  end;
  // R_ClearRenderBuffer, memset(screen, 0) and the palette of the game again
  FillChar(FFrame.Pixels[0], Length(FFrame.Pixels), 0);
  FScreens.Canvas.Clear;
  FScreens.Display.SetPaletteFromLump(LUMP_PALETTE);
end;

procedure TGreedApplication.ReleaseScreen;
begin
  if FScreenHold then
  begin
    FScreenHold := False;
    FScreens.Display.SetPaletteFromLump(LUMP_PALETTE);
  end;
end;

procedure TGreedApplication.RunIntro(ARedo: Boolean);
begin
  FOverlay := False;
  FScreens.Canvas.Clear;
  FScreens.Intro.Start(ARedo);
  RunModal(gamIntro, True,
    procedure
    begin
      SampleKeys;
      FScreens.Intro.Tick;
    end,
    function: Boolean
    begin
      Result := FScreens.Intro.Active;
    end,
    ShowCanvas);
end;

procedure TGreedApplication.RunGame;
begin
  // maingame: the palette of the game, the data of the loop (a game loaded from the menu has not had them yet)
  FScreens.Display.SetPaletteFromLump(LUMP_PALETTE);
  FScreens.Canvas.Clear;
  if FGame.StartPending then
    FGame.StartPlay;
  FScreenHold := False;
  FMode := gamPlaying;
  RunLoop(
    procedure
    begin
      FGame.Tic;
    end,
    function: Boolean
    begin
      Result := not FGame.QuitGame;
    end,
    PlayFrame);
  // maingame ends with M_SaveDefaults
  FStore.Save(FSettings);
end;

procedure TGreedApplication.StartNewGame;
begin
  FScreens.Display.SetPaletteFromLump(LUMP_PALETTE);
  FGame.State.QuitGame := False;
  FGame.NewGame(FOptions.StartMap, FOptions.Character, FOptions.Difficulty);
end;

function TGreedApplication.Run: Integer;
begin
  FRedo := False;
  FStopped := False;
  if FOptions.SkipIntro then
    StartNewGame
  else
    RunIntro(False);
  while (not FStopped) and (not FGame.QuitGame) do
  begin
    RunGame;
    if FStopped or not FRedo then
      Break;
    // the end of an episode: the introduction again, without its titles
    FRedo := False;
    RunIntro(True);
  end;
  FMode := gamEnded;
  Result := FTics;
end;

procedure TGreedApplication.Describe(ALines: TStrings);
const
  MODE_NAMES: array[TGreedApplicationMode] of string = ('idle', 'intro', 'playing', 'menu', 'quit', 'help', 'pause',
    'briefing', 'endgame', 'movie', 'fade', 'ended');
begin
  if not Assigned(ALines) then
    raise EArgumentNilException.Create('ALines');
  ALines.Add(Format('application.mode=%s', [MODE_NAMES[FMode]]));
  ALines.Add(Format('application.tics=%d', [FTics]));
  ALines.Add(Format('application.frames=%d', [FFrames]));
  ALines.Add(Format('application.redo=%d', [Ord(FRedo)]));
  ALines.Add(Format('application.stopped=%d', [Ord(FStopped)]));
  ALines.Add(Format('application.stoppedin=%s', [MODE_NAMES[FStoppedIn]]));
  ALines.Add(Format('application.screenheld=%d', [Ord(FScreenHold)]));
  ALines.Add(Format('application.gameloaded=%d', [Ord(FGame.State.GameLoaded)]));
  ALines.Add(Format('application.quitgame=%d', [Ord(FGame.State.QuitGame)]));
  ALines.Add(Format('screens.menu.active=%d', [Ord(FScreens.Menu.Active)]));
  ALines.Add(Format('screens.menu.level=%d', [FScreens.Menu.Level]));
  ALines.Add(Format('screens.menu.cursor=%d', [FScreens.Menu.Cursor]));
  ALines.Add(Format('screens.menu.character=%d', [FScreens.Menu.Character]));
  ALines.Add(Format('screens.intro.active=%d', [Ord(FScreens.Intro.Active)]));
  ALines.Add(Format('screens.intro.character=%d', [FScreens.Intro.Character]));
  ALines.Add(Format('screens.briefing.active=%d', [Ord(FScreens.Briefing.Active)]));
  ALines.Add(Format('screens.endgame.active=%d', [Ord(FScreens.EndGame.Active)]));
  ALines.Add(Format('screens.movie.active=%d', [Ord(FScreens.Player.Active)]));
  ALines.Add(Format('screens.display.paletteversion=%d', [FScreens.Display.PaletteVersion]));
  ALines.Add(Format('screens.input.timecount=%d', [FScreens.Input.TimeCount]));
end;

end.
