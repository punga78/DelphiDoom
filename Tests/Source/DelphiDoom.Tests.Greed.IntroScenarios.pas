{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the greed library - the scenarios of the intro, of the  }
{  mission briefings and of the endings                                         }
{                                                                              }
{  The same keys, tic by tic, go to TGreedIntro, TGreedBriefing and             }
{  TGreedEndGame (here) and to the original dointro of intro.pas and            }
{  MissionBriefing and EndGame1..3 of utils.pas (the harness                    }
{  Tools\Verifica\175-menu, IntroParity): screen, palette and calls to the game }
{  must be the same at every tic                                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.IntroScenarios;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf,
  DelphiDoom.Greed.Save.Intf, DelphiDoom.Greed.Settings.Intf, DelphiDoom.Greed.Sound.Intf,
  DelphiDoom.Greed.Canvas, DelphiDoom.Greed.Font, DelphiDoom.Greed.TextPrinter, DelphiDoom.Greed.Display,
  DelphiDoom.Greed.MenuInput, DelphiDoom.Greed.Menu.Intf, DelphiDoom.Greed.Menu, DelphiDoom.Greed.FliPlayer,
  DelphiDoom.Greed.Intro, DelphiDoom.Greed.Briefing, DelphiDoom.Greed.EndGame,
  DelphiDoom.Tests.Greed.MenuScenarios;

const
  INTRO_SEED = 20261115;
  INTRO_SCENARIOS = 44;
  /// <summary>The codes of the calls to the game in the trace (after those of the menu)</summary>
  INTRO_TRACE_SELECT_SONG = 20;
  INTRO_TRACE_START_EPISODE = 21;
  INTRO_TRACE_UPDATE_SOUND = 22;
  INTRO_TRACE_BEGIN_INTRO = 23;

type
  TIntroKind = (ikIntro, ikBriefing, ikEndGame);

  TIntroScenario = record
    Kind: TIntroKind;
    /// <summary>The settings, the keys, the clock and the length: as for the menu (the intro opens it)</summary>
    Base: TMenuScenario;
    /// <summary>ikIntro: the variable redo</summary>
    Redo: Boolean;
    Assassinator: Boolean;
    /// <summary>The archive without some of the screens</summary>
    Sparse: Boolean;
    /// <summary>ikBriefing: the map; ikEndGame: the ending 1..3</summary>
    Map: Integer;
    Stats: TGreedBriefingStats;
    /// <summary>The movies that exist, by name, and their bytes</summary>
    MovieNames: TArray<string>;
    MovieBytes: TArray<TBytes>;
  end;

  TIntroScenarios = class
  public
    /// <summary>The lumps of the menu and the screens of the intro, of the briefings and of the endings</summary>
    class function SyntheticArchive(ASparse: Boolean): IGreedArchive; static;
    class function Scenario(AIndex: Integer): TIntroScenario; static;
  end;

  TIntroMoviesFake = class(TInterfacedObject, IGreedExternalFiles)
  strict private
    FNames: TArray<string>;
    FBytes: TArray<TBytes>;
  public
    constructor Create(const ANames: TArray<string>; const ABytes: TArray<TBytes>);
    function Exists(const AName: string): Boolean;
    function ReadAll(const AName: string): TBytes;
  end;

  /// <summary>The game as the intro, the menu, the briefing and the endings see it</summary>
  TIntroHostFake = class(TInterfacedObject, IGreedMenuHost, IGreedSoundVolumes, IGreedIntroHost,
    IGreedBriefingHost, IGreedEndGameHost)
  public
    Trace: TMenuTrace;
    Loaded: Boolean;
    QuitAsked: Boolean;
    ViewSize: Integer;
    Music, Sfx: Integer;
    SoundUpdates: Integer;
    Songs: TArray<Integer>;
    EpisodesStarted: Integer;
    function GameLoaded: Boolean;
    procedure NewGame(AMap, ACharacter, ADifficulty: Integer);
    procedure LoadGame(ASlot: Integer);
    procedure SaveGame(ASlot: Integer);
    procedure QuitGame;
    procedure AmbientLightChanged(ALight: Integer);
    procedure ApplyViewSize(ASize: Integer);
    procedure SaveSettings;
    procedure ResetControls;
    function GetMusicVolume: Integer;
    function GetSfxVolume: Integer;
    procedure SetVolumes(AMusic, ASfx: Integer);
    procedure BeginIntro;
    procedure UpdateSound;
    function QuitRequested: Boolean;
    procedure StartEpisode(AMap: Integer);
    procedure SelectSong(ASong: Integer);
  end;

  TIntroLibraryRunner = class
  strict private
    FGiven: IGreedArchive;
    FFull: IGreedArchive;
    FSparse: IGreedArchive;
    FArchive: IGreedArchive;
    FCanvas: TGreedCanvas;
    FDisplay: TGreedDisplay;
    FInput: TGreedMenuInput;
    FPrinter: TGreedTextPrinter;
    FFont: TGreedFont;
    FPlayer: TGreedFliPlayer;
    FSettings: IGreedSettings;
    FSaveGames: IGreedSaveGames;
    FHost: TIntroHostFake;
    FHostRef: IGreedMenuHost;
    FMenu: TGreedMenu;
    FIntro: TGreedIntro;
    FBriefing: TGreedBriefing;
    FEndGame: TGreedEndGame;
    procedure Release;
  public
    /// <summary>AArchive nil: the synthetic archives (whole or sparse, as the scenario says)</summary>
    constructor Create(const AArchive: IGreedArchive);
    destructor Destroy; override;
    procedure Prepare(const AScenario: TIntroScenario);
    function Active: Boolean;
    procedure Tick;
    function Run(const AScenario: TIntroScenario; AFrames: TList<Cardinal> = nil): TMenuOutcome;
    property Intro: TGreedIntro read FIntro;
    property Briefing: TGreedBriefing read FBriefing;
    property EndGame: TGreedEndGame read FEndGame;
    property Menu: TGreedMenu read FMenu;
    property Host: TIntroHostFake read FHost;
    property Input: TGreedMenuInput read FInput;
    property Canvas: TGreedCanvas read FCanvas;
    property Display: TGreedDisplay read FDisplay;
    property Printer: TGreedTextPrinter read FPrinter;
  end;

/// <summary>The hash of what a scenario leaves at its end</summary>
function IntroFinishHash(AQuit, ALoaded, ATimeCount: Integer): Cardinal;
/// <summary>The lines of the golden file for an archive (nil: the synthetic ones), computed with the library</summary>
function IntroLibraryLines(const AArchive: IGreedArchive): TStringList;

implementation

uses
  DelphiDoom.Greed.Settings, DelphiDoom.Greed.SaveGames, DelphiDoom.Greed.TitleScreens,
  DelphiDoom.Tests.Greed.Builders, DelphiDoom.Tests.Greed.FliScenarios;

type
  TIntroRandom = record
    Seed: Cardinal;
    function Next(ARange: Integer): Integer;
    function Chance(APercent: Integer): Boolean;
  end;

function TIntroRandom.Next(ARange: Integer): Integer;
begin
  Seed := Seed * 1103515245 + 12345;
  if ARange <= 0 then
    Result := 0
  else
    Result := Integer((Seed shr 8) mod Cardinal(ARange));
end;

function TIntroRandom.Chance(APercent: Integer): Boolean;
begin
  Result := Next(100) < APercent;
end;

function IntroFinishHash(AQuit, ALoaded, ATimeCount: Integer): Cardinal;
var
  LTrace: TMenuTrace;
begin
  LTrace.Clear;
  LTrace.Add(AQuit);
  LTrace.Add(ALoaded);
  LTrace.Add(ATimeCount);
  Result := LTrace.Hash;
end;

{ TIntroScenarios }

class function TIntroScenarios.SyntheticArchive(ASparse: Boolean): IGreedArchive;
const
  SCREENS: array[0..31] of string = ('CHAR1', 'CHAR2', 'CHAR3', 'CHAR4', 'CHAR5', 'SOFTLOGO', 'C7LOGO', 'LOGO',
    'INTRO00', 'INTRO01', 'INTRO02', 'INTRO03', 'INTRO04', 'INTRO05', 'INTRO06', 'INTRO07', 'INTRO08', 'BRIEF1',
    'BRIEF2', 'BRIEF3', 'BRIEF4', 'BRIEF5', 'BRIEF6', 'BRIEF7', 'TRANS', 'TRANS2', 'TRANS3', 'REDCHARS',
    'CREDITS1', 'CREDITS2', 'CREDITS3', 'UNUSED');
var
  LBlo: TGreedBlo;
  LIndex: Integer;
  LName: string;
begin
  LBlo := TGreedBlo.Create;
  try
    TMenuScenarios.AddLumps(LBlo);
    for LIndex := 0 to High(SCREENS) do
    begin
      LName := SCREENS[LIndex];
      // the sparse archive: the title stops at INTRO02, two of the credits are skipped
      if ASparse and ((LName = 'INTRO02') or (LName = 'CREDITS1') or (LName = 'CREDITS3') or (LName = 'TRANS2')) then
        Continue;
      LBlo.Add(LName, TMenuScenarios.Picture(320, 200, 0, 0, 10, 700 + Cardinal(LIndex)));
      LBlo.Add('', TMenuScenarios.RandomBytes(768, 800 + Cardinal(LIndex), 256));
    end;
    Result := LBlo.Open;
  finally
    LBlo.Free;
  end;
end;

procedure AddKey(var AScenario: TIntroScenario; ATic, AScanCode, AHold: Integer);
var
  LCount: Integer;
begin
  LCount := Length(AScenario.Base.Keys);
  SetLength(AScenario.Base.Keys, LCount + 2);
  AScenario.Base.Keys[LCount].Tic := ATic;
  AScenario.Base.Keys[LCount].ScanCode := AScanCode;
  AScenario.Base.Keys[LCount].Down := True;
  AScenario.Base.Keys[LCount + 1].Tic := ATic + AHold;
  AScenario.Base.Keys[LCount + 1].ScanCode := AScanCode;
  AScenario.Base.Keys[LCount + 1].Down := False;
end;

procedure AddMovies(var AScenario: TIntroScenario; var ARandom: TIntroRandom; const ANames: array of string;
  AMissingPercent: Integer; AKeepFirst: Boolean);
var
  LIndex, LCount: Integer;
begin
  for LIndex := 0 to High(ANames) do
  begin
    if not (AKeepFirst and (LIndex = 0)) and ARandom.Chance(AMissingPercent) then
      Continue;
    LCount := Length(AScenario.MovieNames);
    SetLength(AScenario.MovieNames, LCount + 1);
    SetLength(AScenario.MovieBytes, LCount + 1);
    AScenario.MovieNames[LCount] := ANames[LIndex];
    // every movie sets all its colors: the palette of the movies is kept from the scenario before
    AScenario.MovieBytes[LCount] := TFliScenarios.SyntheticMovie(INTRO_SEED + ARandom.Seed mod 1000 +
      Cardinal(LIndex) * 13, True);
  end;
end;

class function TIntroScenarios.Scenario(AIndex: Integer): TIntroScenario;
const
  EPISODE_MOVIES: array[0..12] of string = ('PRISON1.FLI', 'TEMPLE1.FLI', 'TEMPLE2.FLI', 'JUMPBAS1.FLI',
    'JUMPBAS2.FLI', 'JUMPBAS3.FLI', 'JUMPBAS4.FLI', 'JUMPBAS5.FLI', 'JUMPBAS6.FLI', 'JUMPBS6B.FLI', 'JUMPBAS7.FLI',
    'JUMPBAS8.FLI', 'JUMPBAS9.FLI');
  MENU_KEYS: array[0..5] of Integer = (GREED_SC_ENTER, GREED_SC_DOWNARROW, GREED_SC_UPARROW, GREED_SC_ESCAPE,
    GREED_SC_Y, GREED_SC_SPACE);
var
  LRandom: TIntroRandom;
  LTic, LIndex: Integer;
begin
  LRandom.Seed := INTRO_SEED + Cardinal(AIndex) * 6151;
  LRandom.Next(1);
  Result := Default(TIntroScenario);
  Result.Base.Animation := LRandom.Chance(30);
  Result.Base.Violence := True;
  Result.Base.GameLoaded := False;
  Result.Base.Demo := LRandom.Chance(30);
  Result.Base.Episode := 1 + LRandom.Next(3);
  Result.Base.MusicVol := 100;
  Result.Base.SfxVol := 128;
  Result.Base.AmbientLight := 2048;
  Result.Base.ScreenSize := 2;
  Result.Base.CamDelay := 35;
  Result.Base.StartTime := LRandom.Next(4000);
  Result.Base.BackgroundSeed := 6000 + Cardinal(AIndex);
  Result.Base.HasDirectory := True;
  Result.Assassinator := LRandom.Chance(25);
  Result.Sparse := LRandom.Chance(25);
  Result.Stats.PrimariesTaken := LRandom.Next(3);
  Result.Stats.PrimariesTotal := 2;
  Result.Stats.SecondariesTaken := LRandom.Next(15);
  Result.Stats.SecondariesTotal := 14;
  Result.Stats.Score := LRandom.Next(2000000);
  Result.Stats.BodyCount := LRandom.Next(500);
  case AIndex of
    0:
      begin
        // the whole title sequence without movies, then the first portrait
        Result.Kind := ikIntro;
        Result.Sparse := False;
        Result.Base.MaxTics := 6400;
      end;
    1:
      begin
        // the sparse archive: the title stops at the missing screen
        Result.Kind := ikIntro;
        Result.Sparse := True;
        Result.Base.MaxTics := 3200;
      end;
    2..5:
      begin
        // the movies of the title, some missing; space skips a movie, enter leaves the title
        Result.Kind := ikIntro;
        AddMovies(Result, LRandom, TGreedTitleScreens.MovieNames, 30, True);
        Result.Base.MaxTics := 1500;
        if AIndex >= 4 then
        begin
          AddKey(Result, 20 + LRandom.Next(100), GREED_SC_SPACE, 3);
          AddKey(Result, 200 + LRandom.Next(300), GREED_SC_ENTER, 3);
        end;
      end;
    6..9:
      begin
        // the title left with escape or enter at some point
        Result.Kind := ikIntro;
        AddKey(Result, 30 + LRandom.Next(1500), GREED_SC_ESCAPE, 2 + LRandom.Next(30));
        Result.Base.MaxTics := 2400;
      end;
    10..23:
      begin
        // the portraits: space, and the menu with what one does there
        Result.Kind := ikIntro;
        Result.Redo := True;
        Result.Base.MaxTics := 1400 + LRandom.Next(1500);
        LTic := 20 + LRandom.Next(200);
        while LTic < Result.Base.MaxTics - 40 do
        begin
          if LRandom.Chance(25) then
            AddKey(Result, LTic, GREED_SC_SPACE, 2 + LRandom.Next(4))
          else
            AddKey(Result, LTic, MENU_KEYS[LRandom.Next(Length(MENU_KEYS))], 2 + LRandom.Next(4));
          LTic := LTic + 13 + LRandom.Next(140);
        end;
      end;
    24..35:
      begin
        Result.Kind := ikBriefing;
        case AIndex of
          24, 25: Result.Map := 0;
          26:
            begin
              Result.Map := 8;
              Result.Base.Episode := 2;
            end;
          27:
            begin
              Result.Map := 16;
              Result.Base.Episode := 3;
            end;
          28:
            begin
              Result.Map := 16;
              Result.Base.Episode := 2;
            end;
          29:
            begin
              // the first game ends at the map 8: no briefing
              Result.Map := 8;
              Result.Base.Episode := 1;
            end;
        else
          Result.Map := 1 + LRandom.Next(23);
        end;
        if AIndex = 24 then
          Result.Base.Demo := False;
        if AIndex = 25 then
          Result.Base.Demo := True;
        AddMovies(Result, LRandom, EPISODE_MOVIES, 20, False);
        Result.Base.MaxTics := 2600;
        LTic := 100 + LRandom.Next(150);
        while LTic < Result.Base.MaxTics do
        begin
          AddKey(Result, LTic, GREED_SC_SPACE, 3);
          LTic := LTic + 60 + LRandom.Next(160);
        end;
        if LRandom.Chance(35) then
          AddKey(Result, 150 + LRandom.Next(900), GREED_SC_ESCAPE, 3);
      end;
  else
    Result.Kind := ikEndGame;
    Result.Map := 1 + (AIndex mod 3);
    AddMovies(Result, LRandom, EPISODE_MOVIES, 20, False);
    Result.Base.MaxTics := 2600;
    LTic := 150 + LRandom.Next(250);
    while LTic < Result.Base.MaxTics do
    begin
      AddKey(Result, LTic, MENU_KEYS[LRandom.Next(Length(MENU_KEYS))], 3);
      LTic := LTic + 80 + LRandom.Next(200);
    end;
  end;
  // the keys in the order of their tics
  for LIndex := 1 to High(Result.Base.Keys) do
  begin
    LTic := LIndex;
    while (LTic > 0) and (Result.Base.Keys[LTic].Tic < Result.Base.Keys[LTic - 1].Tic) do
    begin
      var LSwap := Result.Base.Keys[LTic];
      Result.Base.Keys[LTic] := Result.Base.Keys[LTic - 1];
      Result.Base.Keys[LTic - 1] := LSwap;
      Dec(LTic);
    end;
  end;
end;

{ TIntroMoviesFake }

constructor TIntroMoviesFake.Create(const ANames: TArray<string>; const ABytes: TArray<TBytes>);
begin
  inherited Create;
  FNames := ANames;
  FBytes := ABytes;
end;

function TIntroMoviesFake.Exists(const AName: string): Boolean;
var
  LIndex: Integer;
begin
  Result := False;
  for LIndex := 0 to High(FNames) do
    if SameText(FNames[LIndex], AName) then
      Exit(True);
end;

function TIntroMoviesFake.ReadAll(const AName: string): TBytes;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FNames) do
    if SameText(FNames[LIndex], AName) then
      Exit(FBytes[LIndex]);
  raise EGreedNotFoundException.Create(AName);
end;

{ TIntroHostFake }

function TIntroHostFake.GameLoaded: Boolean;
begin
  Result := Loaded;
end;

procedure TIntroHostFake.NewGame(AMap, ACharacter, ADifficulty: Integer);
begin
  Loaded := True;
  Trace.Add(MENU_TRACE_NEW_GAME);
  Trace.Add(AMap);
  Trace.Add(ACharacter);
  Trace.Add(ADifficulty);
end;

procedure TIntroHostFake.LoadGame(ASlot: Integer);
begin
  Loaded := True;
  Trace.Add(MENU_TRACE_LOAD_GAME);
  Trace.Add(ASlot);
end;

procedure TIntroHostFake.SaveGame(ASlot: Integer);
begin
  Trace.Add(MENU_TRACE_SAVE_GAME);
  Trace.Add(ASlot);
end;

procedure TIntroHostFake.QuitGame;
begin
  QuitAsked := True;
end;

procedure TIntroHostFake.AmbientLightChanged(ALight: Integer);
begin
end;

procedure TIntroHostFake.ApplyViewSize(ASize: Integer);
begin
  ViewSize := ASize;
end;

procedure TIntroHostFake.SaveSettings;
begin
  Trace.Add(MENU_TRACE_SAVE_SETTINGS);
end;

procedure TIntroHostFake.ResetControls;
begin
  Trace.Add(MENU_TRACE_RESET_CONTROLS);
end;

function TIntroHostFake.GetMusicVolume: Integer;
begin
  Result := Music;
end;

function TIntroHostFake.GetSfxVolume: Integer;
begin
  Result := Sfx;
end;

procedure TIntroHostFake.SetVolumes(AMusic, ASfx: Integer);
begin
  Music := AMusic;
  Sfx := ASfx;
  Trace.Add(MENU_TRACE_SET_VOLUMES);
  Trace.Add(AMusic);
  Trace.Add(ASfx);
end;

procedure TIntroHostFake.BeginIntro;
begin
  Trace.Add(INTRO_TRACE_BEGIN_INTRO);
  QuitAsked := False;
  Loaded := False;
end;

procedure TIntroHostFake.UpdateSound;
begin
  Inc(SoundUpdates);
  Trace.Add(INTRO_TRACE_UPDATE_SOUND);
end;

function TIntroHostFake.QuitRequested: Boolean;
begin
  Result := QuitAsked;
end;

procedure TIntroHostFake.StartEpisode(AMap: Integer);
begin
  Inc(EpisodesStarted);
  Trace.Add(INTRO_TRACE_START_EPISODE);
end;

procedure TIntroHostFake.SelectSong(ASong: Integer);
begin
  SetLength(Songs, Length(Songs) + 1);
  Songs[High(Songs)] := ASong;
  Trace.Add(INTRO_TRACE_SELECT_SONG);
  Trace.Add(ASong);
end;

{ TIntroLibraryRunner }

constructor TIntroLibraryRunner.Create(const AArchive: IGreedArchive);
begin
  inherited Create;
  FGiven := AArchive;
end;

destructor TIntroLibraryRunner.Destroy;
begin
  Release;
  inherited;
end;

procedure TIntroLibraryRunner.Release;
begin
  FreeAndNil(FEndGame);
  FreeAndNil(FBriefing);
  FreeAndNil(FIntro);
  FreeAndNil(FMenu);
  FreeAndNil(FPlayer);
  FreeAndNil(FPrinter);
  FreeAndNil(FFont);
  FreeAndNil(FInput);
  FreeAndNil(FDisplay);
  FreeAndNil(FCanvas);
  FSaveGames := nil;
  FHostRef := nil;
  FHost := nil;
  FSettings := nil;
end;

procedure TIntroLibraryRunner.Prepare(const AScenario: TIntroScenario);
var
  LBackground: TBytes;
  LFiles: TMenuSaveFilesFake;
  LMovies: IGreedExternalFiles;
begin
  Release;
  if Assigned(FGiven) then
    FArchive := FGiven
  else if AScenario.Sparse then
  begin
    if not Assigned(FSparse) then
      FSparse := TIntroScenarios.SyntheticArchive(True);
    FArchive := FSparse;
  end
  else
  begin
    if not Assigned(FFull) then
      FFull := TIntroScenarios.SyntheticArchive(False);
    FArchive := FFull;
  end;
  FCanvas := TGreedCanvas.Create;
  FDisplay := TGreedDisplay.Create(FCanvas, FArchive);
  FInput := TGreedMenuInput.Create;
  FPrinter := TGreedTextPrinter.Create(FCanvas);
  FFont := TGreedFont.Create(FArchive.ReadLump(FArchive.RequireIndexOf('FONT1')));
  FPrinter.Font := FFont;
  FPlayer := TGreedFliPlayer.Create(FDisplay, FInput);
  FSettings := TGreedSettings.Create;
  FSettings.SetBoolean('animation', AScenario.Base.Animation);
  FSettings.SetBoolean('violence', AScenario.Base.Violence);
  FSettings.SetInteger('musicvol', AScenario.Base.MusicVol);
  FSettings.SetInteger('sfxvol', AScenario.Base.SfxVol);
  FSettings.SetInteger('ambientlight', AScenario.Base.AmbientLight);
  FSettings.SetInteger('screensize', AScenario.Base.ScreenSize);
  FSettings.SetInteger('camdelay', AScenario.Base.CamDelay);
  FSettings.Episode := AScenario.Base.Episode;
  LFiles := TMenuSaveFilesFake.Create;
  FSaveGames := TGreedSaveGames.Create(LFiles, FSettings.GetGameVariant);
  LFiles.Files.Add(FSaveGames.DirectoryFileName, TMenuScenarios.DirectoryBytes(AScenario.Base));
  FHost := TIntroHostFake.Create;
  FHostRef := FHost;
  FHost.Trace.Clear;
  FHost.ViewSize := AScenario.Base.ScreenSize;
  LMovies := TIntroMoviesFake.Create(AScenario.MovieNames, AScenario.MovieBytes);
  FMenu := TGreedMenu.Create(FDisplay, FInput, FPrinter, FFont, FSettings, FHost, FSaveGames, FHostRef,
    AScenario.Base.Demo);
  FIntro := TGreedIntro.Create(FDisplay, FInput, FPrinter, FFont, FPlayer, LMovies, FMenu, FHost,
    AScenario.Assassinator);
  FBriefing := TGreedBriefing.Create(FDisplay, FInput, FPrinter, FFont, FPlayer, LMovies, FHost,
    AScenario.Base.Demo, FSettings.GetGameVariant);
  FEndGame := TGreedEndGame.Create(FDisplay, FInput, FPrinter, FFont, FPlayer, LMovies, FHost,
    FSettings.GetGameVariant, AScenario.Assassinator);
  FDisplay.SetPaletteFromLump('palette');
  LBackground := TMenuScenarios.Background(AScenario.Base.BackgroundSeed);
  Move(LBackground[0], FCanvas.Pixels[0], Length(LBackground));
  FInput.TimeCount := AScenario.Base.StartTime;
end;

function TIntroLibraryRunner.Active: Boolean;
begin
  Result := FIntro.Active or FBriefing.Active or FEndGame.Active;
end;

procedure TIntroLibraryRunner.Tick;
begin
  if FIntro.Active then
    FIntro.Tick
  else if FBriefing.Active then
    FBriefing.Tick
  else
    FEndGame.Tick;
end;

function TIntroLibraryRunner.Run(const AScenario: TIntroScenario; AFrames: TList<Cardinal>): TMenuOutcome;
var
  LNextKey: Integer;

  procedure Capture;
  begin
    Result.Pixels := MenuFnv4(Result.Pixels, FCanvas.Pixels[0], Length(FCanvas.Pixels));
    Result.Palette := MenuFnv4(Result.Palette, FDisplay.Palette[0], GREED_DISPLAY_PALETTE_BYTES);
    if Assigned(AFrames) then
      AFrames.Add(MenuFnv4(MENU_FNV_START, FCanvas.Pixels[0], Length(FCanvas.Pixels)));
  end;

begin
  Prepare(AScenario);
  Result.Tics := 0;
  Result.Pixels := MENU_FNV_START;
  Result.Palette := MENU_FNV_START;
  case AScenario.Kind of
    ikIntro: FIntro.Start(AScenario.Redo);
    ikBriefing: FBriefing.Start(AScenario.Map, AScenario.Stats);
    ikEndGame: FEndGame.Start(AScenario.Map);
  end;
  LNextKey := 0;
  while True do
  begin
    if not Active then
    begin
      Capture;
      Break;
    end;
    if Result.Tics = AScenario.Base.MaxTics then
      Break;
    Capture;
    while (LNextKey < Length(AScenario.Base.Keys)) and (AScenario.Base.Keys[LNextKey].Tic <= Result.Tics + 1) do
    begin
      FInput.SetKey(AScenario.Base.Keys[LNextKey].ScanCode, AScenario.Base.Keys[LNextKey].Down);
      Inc(LNextKey);
    end;
    Tick;
    Inc(Result.Tics);
  end;
  Result.Trace := FHost.Trace.Hash;
  Result.Finish := IntroFinishHash(Ord(FHost.QuitAsked), Ord(FHost.Loaded), FInput.TimeCount);
end;

function IntroLibraryLines(const AArchive: IGreedArchive): TStringList;
var
  LRunner: TIntroLibraryRunner;
  LIndex: Integer;
begin
  Result := TStringList.Create;
  try
    LRunner := TIntroLibraryRunner.Create(AArchive);
    try
      for LIndex := 0 to INTRO_SCENARIOS - 1 do
        Result.Add(LRunner.Run(TIntroScenarios.Scenario(LIndex)).Line(LIndex));
    finally
      LRunner.Free;
    end;
  except
    Result.Free;
    raise;
  end;
end;

end.
