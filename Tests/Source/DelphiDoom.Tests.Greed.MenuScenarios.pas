{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the greed library - the scenarios of the menu           }
{                                                                              }
{  The same keys, tic by tic, are given to TGreedMenu (here) and to the         }
{  original menu.pas of xGreed (the harness Tools\Verifica\175-menu, where the  }
{  wait of the original is a stub that counts the tics and reads the keys of    }
{  the scenario): screen, palette and calls to the game must be the same at     }
{  every tic                                                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.MenuScenarios;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf,
  DelphiDoom.Greed.SaveTypes, DelphiDoom.Greed.Save.Intf, DelphiDoom.Greed.Settings.Intf,
  DelphiDoom.Greed.Sound.Intf, DelphiDoom.Greed.Canvas, DelphiDoom.Greed.Font, DelphiDoom.Greed.TextPrinter,
  DelphiDoom.Greed.Display, DelphiDoom.Greed.MenuInput, DelphiDoom.Greed.Menu.Intf, DelphiDoom.Greed.Menu;

const
  MENU_SEED = 20261113;
  MENU_SCENARIOS = 72;
  MENU_FNV_START = 2166136261;
  /// <summary>The codes of the calls to the game in the trace</summary>
  MENU_TRACE_NEW_GAME = 1;
  MENU_TRACE_LOAD_GAME = 2;
  MENU_TRACE_SAVE_GAME = 3;
  MENU_TRACE_SAVE_SETTINGS = 7;
  MENU_TRACE_RESET_CONTROLS = 8;
  MENU_TRACE_SET_VOLUMES = 9;

type
  TMenuEntry = (meMenu, meQuit, mePause, meHelp, meWait);

  TMenuKeyEvent = record
    /// <summary>The tic of the scenario (the first is 1) before which the key changes</summary>
    Tic: Integer;
    ScanCode: Integer;
    Down: Boolean;
  end;

  TMenuScenario = record
    Entry: TMenuEntry;
    Level: Integer;
    Animation: Boolean;
    Violence: Boolean;
    GameLoaded: Boolean;
    Demo: Boolean;
    Episode: Integer;
    MusicVol, SfxVol, AmbientLight, ScreenSize, CamDelay: Integer;
    StartTime: Integer;
    BackgroundSeed: Cardinal;
    /// <summary>False: there is no file of the names of the saved games</summary>
    HasDirectory: Boolean;
    SaveNames: array[0..GREED_MAX_SAVE_GAMES - 1] of string;
    Keys: TArray<TMenuKeyEvent>;
    MaxTics: Integer;
    /// <summary>meWait: how much the clock moves before each UpdateWait</summary>
    WaitSteps: TArray<Integer>;
  end;

  /// <summary>What a scenario leaves: the lines of the golden file are made of these</summary>
  TMenuOutcome = record
    Tics: Integer;
    Pixels: Cardinal;
    Palette: Cardinal;
    Trace: Cardinal;
    Finish: Cardinal;
    function Line(AIndex: Integer): string;
  end;

  TMenuTrace = record
    Hash: Cardinal;
    procedure Clear;
    procedure Add(AValue: Integer);
  end;

  TMenuScenarios = class
  public
    /// <summary>An archive with the lumps that menu.pas reads, made of generated pictures</summary>
    class function SyntheticArchive: IGreedArchive; static;
    class function Scenario(AIndex: Integer): TMenuScenario; static;
    /// <summary>The screen before the menu opens</summary>
    class function Background(ASeed: Cardinal): TBytes; static;
    /// <summary>The bytes of the file of the names (230), as the original writes it</summary>
    class function DirectoryBytes(const AScenario: TMenuScenario): TBytes; static;
    /// <summary>The hash of what is left at the end: the same fields in the same order on the two sides</summary>
    class function FinishHash(ALevel, ACursor, AIdentity, ASavePosition, AMusic, ASfx, AViolence, AAnimation,
      ALight, AScreenSize, ACamDelay, AViewSize, AChangeLight, ALighting, AQuitGame, AQuitAnswer, ATimeCount: Integer;
      const ADirectoryFile: TBytes): Cardinal; static;
  end;

  TMenuSaveFilesFake = class(TInterfacedObject, IGreedSaveFiles)
  public
    Files: TDictionary<string, TBytes>;
    constructor Create;
    destructor Destroy; override;
    function Exists(const AName: string): Boolean;
    function ReadAll(const AName: string): TBytes;
    procedure WriteAll(const AName: string; const ABytes: TBytes);
  end;

  TMenuHostFake = class(TInterfacedObject, IGreedMenuHost, IGreedSoundVolumes)
  public
    Trace: TMenuTrace;
    Loaded: Boolean;
    ViewSize: Integer;
    ChangeLight: Integer;
    Lighting: Integer;
    QuitAsked: Boolean;
    Music, Sfx: Integer;
    NewGames, LoadedGames, SavedGames: Integer;
    LastMap, LastCharacter, LastDifficulty, LastSlot: Integer;
    SettingsSaved, ControlsReset: Integer;
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
  end;

  /// <summary>The menu of the library with stand-ins around it, driven by a scenario</summary>
  TMenuLibraryRunner = class
  strict private
    FArchive: IGreedArchive;
    FCanvas: TGreedCanvas;
    FDisplay: TGreedDisplay;
    FInput: TGreedMenuInput;
    FPrinter: TGreedTextPrinter;
    FFont: TGreedFont;
    FSettings: IGreedSettings;
    FFiles: TMenuSaveFilesFake;
    FFilesRef: IGreedSaveFiles;
    FSaveGames: IGreedSaveGames;
    FHost: TMenuHostFake;
    FHostRef: IGreedMenuHost;
    FMenu: TGreedMenu;
    procedure Release;
  public
    constructor Create(const AArchive: IGreedArchive);
    destructor Destroy; override;
    /// <summary>A new menu, closed, with the settings, the screen, the clock and the saved names of the scenario</summary>
    procedure Prepare(const AScenario: TMenuScenario);
    /// <summary>
    ///   Runs the scenario; AFrames, if given, receives the hash of the screen at each tic (to find the first tic
    ///   that differs from the original)
    /// </summary>
    function Run(const AScenario: TMenuScenario; AFrames: TList<Cardinal> = nil): TMenuOutcome;
    /// <summary>The states of the menu met by the scenarios run so far, and the levels shown</summary>
    var StatesSeen: set of TGreedMenuState;
    var LevelsSeen: set of 0..GREED_MENU_LEVELS - 1;
    property Menu: TGreedMenu read FMenu;
    property Canvas: TGreedCanvas read FCanvas;
    property Display: TGreedDisplay read FDisplay;
    property Input: TGreedMenuInput read FInput;
    property Host: TMenuHostFake read FHost;
    property Settings: IGreedSettings read FSettings;
    property Files: TMenuSaveFilesFake read FFiles;
  end;

function MenuFnv(AHash: Cardinal; const AData; ASize: Integer): Cardinal;
/// <summary>The lines of the golden file for an archive, computed with the library</summary>
function MenuLibraryLines(const AArchive: IGreedArchive): TStringList;

implementation

uses
  DelphiDoom.Greed.Settings, DelphiDoom.Greed.SaveGames, DelphiDoom.Tests.Greed.Builders;

type
  TMenuRandom = record
    Seed: Cardinal;
    function Next(ARange: Integer): Integer;
    function Chance(APercent: Integer): Boolean;
  end;

  TKeyScript = record
    Keys: TArray<TMenuKeyEvent>;
    Tic: Integer;
    procedure Tap(AScanCode: Integer; AHold: Integer = 3; AGap: Integer = 12);
    procedure Idle(ATics: Integer);
    procedure TypeText(const AText: string);
  end;

function MenuFnv(AHash: Cardinal; const AData; ASize: Integer): Cardinal;
var
  LIndex: Integer;
  LByte: PByte;
begin
  Result := AHash;
  LByte := @AData;
  for LIndex := 0 to ASize - 1 do
  begin
    Result := (Result xor LByte^) * 16777619;
    Inc(LByte);
  end;
end;

{ TMenuRandom }

function TMenuRandom.Next(ARange: Integer): Integer;
begin
  Seed := Seed * 1103515245 + 12345;
  if ARange <= 0 then
    Result := 0
  else
    Result := Integer((Seed shr 8) mod Cardinal(ARange));
end;

function TMenuRandom.Chance(APercent: Integer): Boolean;
begin
  Result := Next(100) < APercent;
end;

{ TMenuTrace }

procedure TMenuTrace.Clear;
begin
  Hash := MENU_FNV_START;
end;

procedure TMenuTrace.Add(AValue: Integer);
begin
  Hash := MenuFnv(Hash, AValue, SizeOf(AValue));
end;

{ TMenuOutcome }

function TMenuOutcome.Line(AIndex: Integer): string;
begin
  Result := Format('M %d tics=%d pixels=%.8x palette=%.8x trace=%.8x end=%.8x', [AIndex, Tics, Pixels, Palette,
    Trace, Finish]);
end;

{ TKeyScript }

procedure TKeyScript.Tap(AScanCode, AHold, AGap: Integer);
var
  LCount: Integer;
begin
  LCount := Length(Keys);
  SetLength(Keys, LCount + 2);
  Keys[LCount].Tic := Tic + 1;
  Keys[LCount].ScanCode := AScanCode;
  Keys[LCount].Down := True;
  Keys[LCount + 1].Tic := Tic + 1 + AHold;
  Keys[LCount + 1].ScanCode := AScanCode;
  Keys[LCount + 1].Down := False;
  Tic := Tic + AHold + AGap;
end;

procedure TKeyScript.Idle(ATics: Integer);
begin
  Tic := Tic + ATics;
end;

procedure TKeyScript.TypeText(const AText: string);
var
  LIndex: Integer;
begin
  for LIndex := 1 to Length(AText) do
    Tap(TGreedMenuInput.ScanCodeOfChar(AText[LIndex]), 2, 3);
end;

// ---------------------------------------------------------------------------------------------------------
// the synthetic data
// ---------------------------------------------------------------------------------------------------------

function SyntheticFont(AHeight: Integer; ASeed: Cardinal): TBytes;
var
  LRandom: TMenuRandom;
  LCharacter, LWidth, LOffset, LIndex: Integer;
begin
  LRandom.Seed := ASeed;
  SetLength(Result, GREED_FONT_HEADER_BYTES);
  FillChar(Result[0], Length(Result), 0);
  TGreedLumps.PutWord(Result, 0, AHeight);
  for LCharacter := 32 to 126 do
  begin
    if LCharacter = 32 then
      LWidth := 3
    else
      LWidth := 2 + LRandom.Next(4);
    LOffset := Length(Result);
    Result[2 + LCharacter] := LWidth;
    TGreedLumps.PutWord(Result, 2 + 256 + 2 * LCharacter, LOffset);
    SetLength(Result, LOffset + LWidth * AHeight);
    for LIndex := 0 to LWidth * AHeight - 1 do
      if (LCharacter = 32) or LRandom.Chance(45) then
        Result[LOffset + LIndex] := 0
      else
        Result[LOffset + LIndex] := 1 + LRandom.Next(6);
  end;
end;

function SyntheticPicture(AWidth, AHeight, AOriginX, AOriginY, AZeroPercent: Integer; ASeed: Cardinal): TBytes;
var
  LRandom: TMenuRandom;
  LIndex: Integer;
begin
  LRandom.Seed := ASeed;
  SetLength(Result, GREED_PICTURE_HEADER_BYTES + AWidth * AHeight);
  TGreedLumps.PutWord(Result, 0, AWidth);
  TGreedLumps.PutWord(Result, 2, AHeight);
  TGreedLumps.PutWord(Result, 4, AOriginX);
  TGreedLumps.PutWord(Result, 6, AOriginY);
  for LIndex := 0 to AWidth * AHeight - 1 do
    if LRandom.Next(100) < AZeroPercent then
      Result[GREED_PICTURE_HEADER_BYTES + LIndex] := 0
    else
      Result[GREED_PICTURE_HEADER_BYTES + LIndex] := 1 + LRandom.Next(255);
end;

function SyntheticBytes(ASize: Integer; ASeed: Cardinal; ARange: Integer): TBytes;
var
  LRandom: TMenuRandom;
  LIndex: Integer;
begin
  LRandom.Seed := ASeed;
  SetLength(Result, ASize);
  for LIndex := 0 to ASize - 1 do
    Result[LIndex] := LRandom.Next(ARange);
end;

class function TMenuScenarios.SyntheticArchive: IGreedArchive;
const
  OPTION_PICTURES: array[0..8] of string = ('menumussli', 'menusousli', 'menuvioon', 'menuviooff', 'menuanion',
    'menuanioff', 'menuambsli', 'menuscrsli', 'menucamsli');
var
  LBlo: TGreedBlo;
  LIndex: Integer;

  function Name(const ABase: string; ANumber: Integer): string;
  begin
    if ANumber = 0 then
      Result := ABase
    else
      Result := ABase + IntToStr(ANumber);
  end;

begin
  LBlo := TGreedBlo.Create;
  try
    LBlo.Add('palette', SyntheticBytes(768, 11, 64));
    LBlo.Add('FONT1', SyntheticFont(5, 21));
    // VI_Init of the original reads it
    LBlo.Add('TRANSPARENCY', SyntheticBytes(GREED_TRANSPARENCY_BYTES, 501, 256));
    for LIndex := 0 to GREED_MENU_LEVELS - 1 do
      LBlo.Add(Name('menumain', LIndex), SyntheticPicture(276, 164, 0, 0, 20, 100 + LIndex));
    for LIndex := 0 to 7 do
      LBlo.Add(Name('menuanim', LIndex), SyntheticPicture(276, 164, 0, 0, 80 - LIndex * 8, 120 + LIndex));
    for LIndex := 0 to 2 do
      LBlo.Add(Name('quit', LIndex), SyntheticPicture(98, 64, 0, 0, 25, 140 + LIndex));
    for LIndex := 0 to 3 do
      LBlo.Add(Name('pause', LIndex), SyntheticPicture(108, 56, 0, 0, 25, 150 + LIndex));
    for LIndex := 0 to 3 do
      LBlo.Add(Name('wait', LIndex), SyntheticPicture(108, 56, 2, 1, 25, 160 + LIndex));
    for LIndex := 0 to High(OPTION_PICTURES) do
      LBlo.Add(OPTION_PICTURES[LIndex], SyntheticPicture(72, 84, 0, 0, 30, 170 + LIndex));
    for LIndex := 1 to 3 do
    begin
      LBlo.Add('INFO' + IntToStr(LIndex), SyntheticPicture(320, 200, 0, 0, 10, 190 + LIndex));
      LBlo.Add('', SyntheticBytes(768, 200 + LIndex, 256));
    end;
    Result := LBlo.Open;
  finally
    LBlo.Free;
  end;
end;

class function TMenuScenarios.Background(ASeed: Cardinal): TBytes;
var
  LRandom: TMenuRandom;
  LIndex: Integer;
begin
  LRandom.Seed := ASeed;
  SetLength(Result, GREED_CANVAS_WIDTH * GREED_CANVAS_HEIGHT);
  for LIndex := 0 to High(Result) do
    if (LIndex div 37) mod 3 = 0 then
      Result[LIndex] := 0
    else
      Result[LIndex] := LRandom.Next(256);
end;

class function TMenuScenarios.DirectoryBytes(const AScenario: TMenuScenario): TBytes;
var
  LDirectory: TGreedSaveDirectory;
  LIndex: Integer;
begin
  FillChar(LDirectory, SizeOf(LDirectory), 0);
  for LIndex := 0 to GREED_MAX_SAVE_GAMES - 1 do
    LDirectory[LIndex] := TGreedSaveName(AnsiString(AScenario.SaveNames[LIndex]));
  SetLength(Result, SizeOf(LDirectory));
  Move(LDirectory, Result[0], SizeOf(LDirectory));
end;

class function TMenuScenarios.FinishHash(ALevel, ACursor, AIdentity, ASavePosition, AMusic, ASfx, AViolence,
  AAnimation, ALight, AScreenSize, ACamDelay, AViewSize, AChangeLight, ALighting, AQuitGame, AQuitAnswer,
  ATimeCount: Integer; const ADirectoryFile: TBytes): Cardinal;
var
  LTrace: TMenuTrace;
  LIndex: Integer;
  LLength: Integer;
begin
  LTrace.Clear;
  LTrace.Add(ALevel);
  LTrace.Add(ACursor);
  LTrace.Add(AIdentity);
  LTrace.Add(ASavePosition);
  LTrace.Add(AMusic);
  LTrace.Add(ASfx);
  LTrace.Add(AViolence);
  LTrace.Add(AAnimation);
  LTrace.Add(ALight);
  LTrace.Add(AScreenSize);
  LTrace.Add(ACamDelay);
  LTrace.Add(AViewSize);
  LTrace.Add(AChangeLight);
  LTrace.Add(ALighting);
  LTrace.Add(AQuitGame);
  LTrace.Add(AQuitAnswer);
  LTrace.Add(ATimeCount);
  LTrace.Add(Length(ADirectoryFile));
  // the names and not the bytes of the file: after a name the file has what the memory had
  for LIndex := 0 to GREED_MAX_SAVE_GAMES - 1 do
    if Length(ADirectoryFile) >= (LIndex + 1) * (GREED_SAVE_NAME_LENGTH + 1) then
    begin
      LLength := ADirectoryFile[LIndex * (GREED_SAVE_NAME_LENGTH + 1)];
      if LLength > GREED_SAVE_NAME_LENGTH then
        LLength := GREED_SAVE_NAME_LENGTH;
      LTrace.Add(LLength);
      if LLength > 0 then
        LTrace.Hash := MenuFnv(LTrace.Hash, ADirectoryFile[LIndex * (GREED_SAVE_NAME_LENGTH + 1) + 1], LLength);
    end;
  Result := LTrace.Hash;
end;

// ---------------------------------------------------------------------------------------------------------
// the scenarios
// ---------------------------------------------------------------------------------------------------------

procedure RandomKeys(var ARandom: TMenuRandom; var AScript: TKeyScript; ACount: Integer; AEnter, ADown, ASide,
  AEscape, ALetters: Integer);
const
  LETTERS = 'YNABZ019 .-,';
var
  LIndex, LRoll, LTotal, LHold, LGap: Integer;
begin
  LTotal := AEnter + ADown + ASide + AEscape + ALetters + 10;
  for LIndex := 1 to ACount do
  begin
    LRoll := ARandom.Next(LTotal);
    LHold := 2 + ARandom.Next(5);
    if ARandom.Chance(15) then
      LHold := 12 + ARandom.Next(30);
    LGap := ARandom.Next(16);
    if ARandom.Chance(70) then
      LGap := LGap + 9;
    if LRoll < AEnter then
      AScript.Tap(GREED_SC_ENTER, LHold, LGap)
    else if LRoll < AEnter + ADown then
      AScript.Tap(GREED_SC_DOWNARROW, LHold, LGap)
    else if LRoll < AEnter + ADown + ASide then
    begin
      if ARandom.Chance(50) then
        AScript.Tap(GREED_SC_LEFTARROW, LHold, LGap)
      else
        AScript.Tap(GREED_SC_RIGHTARROW, LHold, LGap);
    end
    else if LRoll < AEnter + ADown + ASide + AEscape then
      AScript.Tap(GREED_SC_ESCAPE, LHold, LGap)
    else if LRoll < AEnter + ADown + ASide + AEscape + ALetters then
    begin
      if ARandom.Chance(15) then
        AScript.Tap(GREED_SC_BACKSPACE, LHold, LGap)
      else
        AScript.Tap(TGreedMenuInput.ScanCodeOfChar(LETTERS[1 + ARandom.Next(Length(LETTERS))]), LHold, LGap);
    end
    else
      AScript.Tap(GREED_SC_UPARROW, LHold, LGap);
  end;
end;

class function TMenuScenarios.Scenario(AIndex: Integer): TMenuScenario;
var
  LRandom: TMenuRandom;
  LScript: TKeyScript;
  LIndex: Integer;

  procedure Downs(ACount: Integer);
  var
    LStep: Integer;
  begin
    for LStep := 1 to ACount do
      LScript.Tap(GREED_SC_DOWNARROW);
  end;

  procedure Ups(ACount: Integer);
  var
    LStep: Integer;
  begin
    for LStep := 1 to ACount do
      LScript.Tap(GREED_SC_UPARROW);
  end;

begin
  LRandom.Seed := MENU_SEED + Cardinal(AIndex) * 7919;
  LRandom.Next(1);
  Result := Default(TMenuScenario);
  Result.Entry := meMenu;
  Result.Level := 0;
  Result.Animation := LRandom.Chance(40);
  Result.Violence := LRandom.Chance(50);
  Result.GameLoaded := LRandom.Chance(60);
  Result.Demo := LRandom.Chance(30);
  Result.Episode := 1 + LRandom.Next(3);
  Result.MusicVol := LRandom.Next(256);
  Result.SfxVol := LRandom.Next(256);
  Result.AmbientLight := LRandom.Next(4097);
  Result.ScreenSize := LRandom.Next(5);
  Result.CamDelay := LRandom.Next(71);
  Result.StartTime := LRandom.Next(5000);
  Result.BackgroundSeed := 5000 + Cardinal(AIndex);
  Result.HasDirectory := LRandom.Chance(75);
  if Result.HasDirectory then
    for LIndex := 0 to GREED_MAX_SAVE_GAMES - 1 do
      if LRandom.Chance(50) then
        Result.SaveNames[LIndex] := Copy('GAME ' + IntToStr(LIndex) + ' OF THE HUNTER X', 1, 3 + LRandom.Next(20));
  LScript := Default(TKeyScript);
  LScript.Tic := 2 + LRandom.Next(8);
  case AIndex of
    0:
      begin
        // nothing pressed: the menu stays open
        Result.Animation := True;
        LScript.Idle(90);
      end;
    1:
      begin
        // new game: character 3, difficulty row 2
        Result.Animation := False;
        LScript.Idle(12);
        Ups(1);
        LScript.Tap(GREED_SC_ENTER);
        Downs(2);
        LScript.Tap(GREED_SC_ENTER);
        Downs(1);
        LScript.Tap(GREED_SC_ENTER);
      end;
    2:
      begin
        // save with a typed name, in a game
        Result.Animation := False;
        Result.GameLoaded := True;
        LScript.Idle(12);
        Downs(2);
        LScript.Tap(GREED_SC_ENTER);
        Downs(3);
        LScript.Tap(GREED_SC_ENTER);
        LScript.TypeText('AB 12.Z');
        LScript.Tap(GREED_SC_BACKSPACE, 2, 3);
        LScript.TypeText('Y-,');
        LScript.Tap(GREED_SC_ENTER, 2, 14);
        LScript.Idle(45);
        LScript.Tap(GREED_SC_ESCAPE);
      end;
    3:
      begin
        // save, name abandoned with escape, then back
        Result.GameLoaded := True;
        Result.HasDirectory := False;
        LScript.Idle(70);
        Downs(2);
        LScript.Tap(GREED_SC_ENTER);
        LScript.Tap(GREED_SC_ENTER);
        LScript.TypeText('NONAME');
        LScript.Tap(GREED_SC_ESCAPE, 2, 14);
        Downs(10);
        LScript.Tap(GREED_SC_ENTER);
        LScript.Idle(40);
        LScript.Tap(GREED_SC_ESCAPE);
      end;
    4:
      begin
        // a name longer than the 22 characters, with many backspaces
        Result.Animation := False;
        Result.GameLoaded := True;
        LScript.Idle(12);
        Downs(2);
        LScript.Tap(GREED_SC_ENTER);
        Downs(8);
        LScript.Tap(GREED_SC_ENTER);
        LScript.TypeText('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123');
        for LIndex := 1 to 30 do
          LScript.Tap(GREED_SC_BACKSPACE, 2, 3);
        LScript.TypeText('Z');
        LScript.Tap(GREED_SC_ENTER, 2, 14);
      end;
    5:
      begin
        // load the game 4
        Result.Animation := False;
        LScript.Idle(12);
        Downs(1);
        LScript.Tap(GREED_SC_ENTER);
        Downs(4);
        LScript.Tap(GREED_SC_ENTER);
      end;
    6:
      begin
        // every option, left and right
        Result.Animation := False;
        Result.GameLoaded := True;
        LScript.Idle(12);
        Downs(3);
        LScript.Tap(GREED_SC_ENTER);
        for LIndex := 2 to 8 do
        begin
          LScript.Tap(GREED_SC_LEFTARROW, 9, 12);
          LScript.Tap(GREED_SC_RIGHTARROW, 30, 12);
          LScript.Tap(GREED_SC_LEFTARROW, 3, 12);
          Downs(1);
        end;
        LScript.Tap(GREED_SC_ENTER);
        LScript.Idle(40);
        LScript.Tap(GREED_SC_ESCAPE);
      end;
    7:
      begin
        // quit from the menu: yes, with the animation
        Result.Animation := True;
        LScript.Idle(70);
        LScript.Tap(GREED_SC_ENTER);
        LScript.Idle(90);
        LScript.Tap(GREED_SC_Y);
      end;
    8:
      begin
        // quit from the menu: Y while the panel drops, then another key
        Result.Animation := True;
        LScript.Idle(70);
        LScript.Tap(GREED_SC_ENTER);
        LScript.Idle(25);
        LScript.Tap(GREED_SC_Y, 3, 5);
        LScript.Idle(70);
        LScript.Tap(GREED_SC_N);
        LScript.Idle(140);
        LScript.Tap(GREED_SC_ESCAPE);
      end;
    9:
      begin
        // quit from the menu: no, without the animation, then leave with escape
        Result.Animation := False;
        LScript.Idle(12);
        LScript.Tap(GREED_SC_ENTER);
        LScript.Idle(30);
        LScript.Tap(GREED_SC_N);
        LScript.Idle(40);
        LScript.Tap(GREED_SC_ESCAPE);
      end;
    10:
      begin
        // the help from the menu
        Result.Animation := False;
        LScript.Idle(12);
        Downs(4);
        LScript.Tap(GREED_SC_ENTER);
        LScript.Idle(30);
        LScript.Tap(GREED_SC_SPACE, 3, 25);
        LScript.Tap(GREED_SC_SPACE, 3, 25);
        LScript.Tap(GREED_SC_SPACE, 3, 25);
        Downs(1);
        LScript.Tap(GREED_SC_ENTER);
      end;
    11, 12:
      begin
        Result.Entry := meQuit;
        Result.Animation := AIndex = 11;
        LScript.Idle(100);
        LScript.Tap(GREED_SC_Y);
      end;
    13, 14:
      begin
        Result.Entry := meQuit;
        Result.Animation := AIndex = 13;
        LScript.Idle(30);
        LScript.Tap(GREED_SC_N, 20, 5);
      end;
    15, 16:
      begin
        Result.Entry := mePause;
        Result.Animation := AIndex = 15;
        LScript.Idle(130);
        LScript.Tap(GREED_SC_SPACE);
      end;
    17:
      begin
        // a key while the panel is still dropping
        Result.Entry := mePause;
        Result.Animation := True;
        LScript.Idle(30);
        LScript.Tap(GREED_SC_ENTER);
      end;
    18, 19:
      begin
        Result.Entry := meHelp;
        Result.Demo := AIndex = 19;
        LScript.Idle(25);
        LScript.Tap(GREED_SC_ENTER, 3, 30);
        LScript.Tap(GREED_SC_ESCAPE, 3, 17);
        LScript.Tap(GREED_SC_Y, 3, 30);
      end;
    20, 21:
      begin
        Result.Entry := meWait;
        SetLength(Result.WaitSteps, 40);
        for LIndex := 0 to High(Result.WaitSteps) do
          Result.WaitSteps[LIndex] := LRandom.Next(16);
      end;
    22..27:
      begin
        // the menu opened on each level
        Result.Level := AIndex - 22;
        RandomKeys(LRandom, LScript, 18, 20, 25, 15, 5, 15);
      end;
    28..39:
      begin
        // mostly the options
        Result.Level := GREED_MENU_OPTIONS;
        Result.Animation := False;
        RandomKeys(LRandom, LScript, 30, 3, 25, 50, 2, 0);
      end;
    40..49:
      begin
        // mostly the names of the saved games
        Result.Level := GREED_MENU_SAVE;
        Result.Animation := False;
        Result.GameLoaded := True;
        RandomKeys(LRandom, LScript, 40, 20, 15, 2, 6, 50);
      end;
    50..53:
      begin
        Result.Entry := meQuit;
        RandomKeys(LRandom, LScript, 6, 5, 5, 5, 5, 30);
      end;
    54..56:
      begin
        Result.Entry := mePause;
        LScript.Idle(LRandom.Next(160));
        RandomKeys(LRandom, LScript, 2, 5, 5, 5, 5, 30);
      end;
    57..59:
      begin
        Result.Entry := meHelp;
        LScript.Idle(LRandom.Next(40));
        RandomKeys(LRandom, LScript, 5, 5, 5, 5, 5, 30);
      end;
  else
    // anything
    RandomKeys(LRandom, LScript, 30, 30, 25, 10, 6, 10);
  end;
  Result.Keys := LScript.Keys;
  Result.MaxTics := LScript.Tic + 60;
  if Result.MaxTics > 700 then
    Result.MaxTics := 700;
end;

{ TMenuSaveFilesFake }

constructor TMenuSaveFilesFake.Create;
begin
  inherited Create;
  Files := TDictionary<string, TBytes>.Create;
end;

destructor TMenuSaveFilesFake.Destroy;
begin
  Files.Free;
  inherited;
end;

function TMenuSaveFilesFake.Exists(const AName: string): Boolean;
begin
  Result := Files.ContainsKey(AName);
end;

function TMenuSaveFilesFake.ReadAll(const AName: string): TBytes;
begin
  if not Files.TryGetValue(AName, Result) then
    raise EGreedNotFoundException.Create(AName);
end;

procedure TMenuSaveFilesFake.WriteAll(const AName: string; const ABytes: TBytes);
begin
  Files.AddOrSetValue(AName, Copy(ABytes));
end;

{ TMenuHostFake }

function TMenuHostFake.GameLoaded: Boolean;
begin
  Result := Loaded;
end;

procedure TMenuHostFake.NewGame(AMap, ACharacter, ADifficulty: Integer);
begin
  Inc(NewGames);
  LastMap := AMap;
  LastCharacter := ACharacter;
  LastDifficulty := ADifficulty;
  Trace.Add(MENU_TRACE_NEW_GAME);
  Trace.Add(AMap);
  Trace.Add(ACharacter);
  Trace.Add(ADifficulty);
end;

procedure TMenuHostFake.LoadGame(ASlot: Integer);
begin
  Inc(LoadedGames);
  LastSlot := ASlot;
  Trace.Add(MENU_TRACE_LOAD_GAME);
  Trace.Add(ASlot);
end;

procedure TMenuHostFake.SaveGame(ASlot: Integer);
begin
  Inc(SavedGames);
  LastSlot := ASlot;
  Trace.Add(MENU_TRACE_SAVE_GAME);
  Trace.Add(ASlot);
end;

procedure TMenuHostFake.QuitGame;
begin
  QuitAsked := True;
end;

procedure TMenuHostFake.AmbientLightChanged(ALight: Integer);
begin
  ChangeLight := ALight;
  Lighting := 1;
end;

procedure TMenuHostFake.ApplyViewSize(ASize: Integer);
begin
  ViewSize := ASize;
end;

procedure TMenuHostFake.SaveSettings;
begin
  Inc(SettingsSaved);
  Trace.Add(MENU_TRACE_SAVE_SETTINGS);
end;

procedure TMenuHostFake.ResetControls;
begin
  Inc(ControlsReset);
  Trace.Add(MENU_TRACE_RESET_CONTROLS);
end;

function TMenuHostFake.GetMusicVolume: Integer;
begin
  Result := Music;
end;

function TMenuHostFake.GetSfxVolume: Integer;
begin
  Result := Sfx;
end;

procedure TMenuHostFake.SetVolumes(AMusic, ASfx: Integer);
begin
  Music := AMusic;
  Sfx := ASfx;
  Trace.Add(MENU_TRACE_SET_VOLUMES);
  Trace.Add(AMusic);
  Trace.Add(ASfx);
end;

{ TMenuLibraryRunner }

constructor TMenuLibraryRunner.Create(const AArchive: IGreedArchive);
begin
  inherited Create;
  FArchive := AArchive;
end;

destructor TMenuLibraryRunner.Destroy;
begin
  Release;
  inherited;
end;

procedure TMenuLibraryRunner.Release;
begin
  FreeAndNil(FMenu);
  FreeAndNil(FPrinter);
  FreeAndNil(FFont);
  FreeAndNil(FInput);
  FreeAndNil(FDisplay);
  FreeAndNil(FCanvas);
  FSaveGames := nil;
  FFilesRef := nil;
  FFiles := nil;
  FHostRef := nil;
  FHost := nil;
  FSettings := nil;
end;

procedure TMenuLibraryRunner.Prepare(const AScenario: TMenuScenario);
var
  LBackground: TBytes;
begin
  Release;
  FCanvas := TGreedCanvas.Create;
  FDisplay := TGreedDisplay.Create(FCanvas, FArchive);
  FInput := TGreedMenuInput.Create;
  FPrinter := TGreedTextPrinter.Create(FCanvas);
  FFont := TGreedFont.Create(FArchive.ReadLump(FArchive.RequireIndexOf('FONT1')));
  FSettings := TGreedSettings.Create;
  FSettings.SetBoolean('animation', AScenario.Animation);
  FSettings.SetBoolean('violence', AScenario.Violence);
  FSettings.SetInteger('musicvol', AScenario.MusicVol);
  FSettings.SetInteger('sfxvol', AScenario.SfxVol);
  FSettings.SetInteger('ambientlight', AScenario.AmbientLight);
  FSettings.SetInteger('screensize', AScenario.ScreenSize);
  FSettings.SetInteger('camdelay', AScenario.CamDelay);
  FSettings.Episode := AScenario.Episode;
  FFiles := TMenuSaveFilesFake.Create;
  FFilesRef := FFiles;
  FSaveGames := TGreedSaveGames.Create(FFilesRef, FSettings.GetGameVariant);
  if AScenario.HasDirectory then
    FFiles.Files.Add(FSaveGames.DirectoryFileName, TMenuScenarios.DirectoryBytes(AScenario));
  FHost := TMenuHostFake.Create;
  FHostRef := FHost;
  FHost.Trace.Clear;
  FHost.Loaded := AScenario.GameLoaded;
  FHost.ViewSize := AScenario.ScreenSize;
  FMenu := TGreedMenu.Create(FDisplay, FInput, FPrinter, FFont, FSettings, FHost, FSaveGames, FHostRef,
    AScenario.Demo);
  FDisplay.SetPaletteFromLump('palette');
  LBackground := TMenuScenarios.Background(AScenario.BackgroundSeed);
  Move(LBackground[0], FCanvas.Pixels[0], Length(LBackground));
  FInput.TimeCount := AScenario.StartTime;
end;

function TMenuLibraryRunner.Run(const AScenario: TMenuScenario; AFrames: TList<Cardinal>): TMenuOutcome;
var
  LNextKey: Integer;
  LIndex: Integer;
  LDirectory: TBytes;

  procedure Capture;
  begin
    Result.Pixels := MenuFnv(Result.Pixels, FCanvas.Pixels[0], Length(FCanvas.Pixels));
    Result.Palette := MenuFnv(Result.Palette, FDisplay.Palette[0], GREED_DISPLAY_PALETTE_BYTES);
    if Assigned(AFrames) then
      AFrames.Add(MenuFnv(MENU_FNV_START, FCanvas.Pixels[0], Length(FCanvas.Pixels)));
  end;

begin
  Prepare(AScenario);
  Result.Tics := 0;
  Result.Pixels := MENU_FNV_START;
  Result.Palette := MENU_FNV_START;
  if AScenario.Entry = meWait then
  begin
    FMenu.StartWait;
    Capture;
    for LIndex := 0 to High(AScenario.WaitSteps) do
    begin
      FInput.TimeCount := FInput.TimeCount + AScenario.WaitSteps[LIndex];
      FMenu.UpdateWait;
      Capture;
      Inc(Result.Tics);
    end;
    FMenu.EndWait;
    Capture;
  end
  else
  begin
    case AScenario.Entry of
      meMenu: FMenu.OpenMenu(AScenario.Level);
      meQuit: FMenu.OpenQuit;
      mePause: FMenu.OpenPause;
      meHelp: FMenu.OpenHelp;
    end;
    LNextKey := 0;
    while True do
    begin
      if not FMenu.Active then
      begin
        Capture;
        Break;
      end;
      if Result.Tics = AScenario.MaxTics then
        Break;
      Capture;
      while (LNextKey < Length(AScenario.Keys)) and (AScenario.Keys[LNextKey].Tic <= Result.Tics + 1) do
      begin
        FInput.SetKey(AScenario.Keys[LNextKey].ScanCode, AScenario.Keys[LNextKey].Down);
        Inc(LNextKey);
      end;
      FMenu.Tick;
      Include(StatesSeen, FMenu.State);
      if FMenu.State = gmsMain then
        Include(LevelsSeen, FMenu.Level);
      Inc(Result.Tics);
    end;
  end;
  Result.Trace := FHost.Trace.Hash;
  if not FFiles.Files.TryGetValue(FSaveGames.DirectoryFileName, LDirectory) then
    LDirectory := nil;
  Result.Finish := TMenuScenarios.FinishHash(FMenu.Level, FMenu.Cursor, FMenu.Character, FMenu.SavePosition,
    FSettings.GetInteger('musicvol'), FSettings.GetInteger('sfxvol'), Ord(FSettings.GetBoolean('violence')),
    Ord(FSettings.GetBoolean('animation')), FSettings.GetInteger('ambientlight'),
    FSettings.GetInteger('screensize'), FSettings.GetInteger('camdelay'), FHost.ViewSize, FHost.ChangeLight,
    FHost.Lighting, Ord(FHost.QuitAsked), Ord(FMenu.QuitAnswer and (AScenario.Entry = meQuit)), FInput.TimeCount,
    LDirectory);
end;

function MenuLibraryLines(const AArchive: IGreedArchive): TStringList;
var
  LRunner: TMenuLibraryRunner;
  LIndex: Integer;
begin
  Result := TStringList.Create;
  try
    LRunner := TMenuLibraryRunner.Create(AArchive);
    try
      for LIndex := 0 to MENU_SCENARIOS - 1 do
        Result.Add(LRunner.Run(TMenuScenarios.Scenario(LIndex)).Line(LIndex));
    finally
      LRunner.Free;
    end;
  except
    Result.Free;
    raise;
  end;
end;

end.
