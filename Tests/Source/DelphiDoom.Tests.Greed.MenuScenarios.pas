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
  DelphiDoom.Greed.Display, DelphiDoom.Greed.MenuInput, DelphiDoom.Greed.Menu.Intf, DelphiDoom.Greed.Menu,
  DelphiDoom.Input.Types, DelphiDoom.Input.Intf, DelphiDoom.Greed.Mouse.Intf, DelphiDoom.Greed.Mouse,
  DelphiDoom.Greed.MouseCursor, DelphiDoom.Greed.Frame.Intf;

const
  MENU_SEED = 20261113;
  /// <summary>The scenarios driven by the keys alone (the mouse is not installed)</summary>
  MENU_KEY_SCENARIOS = 72;
  /// <summary>The scenarios with a mouse come after the ones of the keys, which are as they were</summary>
  MENU_MOUSE_SCENARIOS = 40;
  MENU_SCENARIOS = MENU_KEY_SCENARIOS + MENU_MOUSE_SCENARIOS;
  /// <summary>The screen on which the original draws the pointer, and the side of the block that is compared</summary>
  MENU_POINTER_SCREEN_WIDTH = 640;
  MENU_POINTER_SCREEN_HEIGHT = 400;
  MENU_POINTER_BLOCK = 2 * GREED_MOUSE_SIZE;
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

  TMenuMouseEvent = record
    /// <summary>The tic of the scenario (the first is 1) before which the mouse changes</summary>
    Tic: Integer;
    /// <summary>How far the cursor of the system moves: right and down are positive</summary>
    DeltaX, DeltaY: Integer;
    /// <summary>The buttons that are down from now on: 1 the left, 2 the right, 4 the middle</summary>
    Buttons: Integer;
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
    /// <summary>mouseinstalled: False for the scenarios of the keys (no mouse is read)</summary>
    UseMouse: Boolean;
    /// <summary>menuusemouse</summary>
    MenuMouse: Boolean;
    /// <summary>I_WindowWidth and I_WindowHeight</summary>
    WindowWidth, WindowHeight: Integer;
    /// <summary>Where the cursor of the system is when the scenario starts</summary>
    CursorX, CursorY: Integer;
    Mouse: TArray<TMenuMouseEvent>;
  end;

  /// <summary>
  ///   The mouse of a scenario for the library: a cursor that the scenario moves and the game puts back, the
  ///   buttons, the size of the window. The harness gives the same values to the original through its
  ///   getcursorposfunc, setcursorposfunc, lbuttondown, rbuttondown, mbuttondown and I_WindowWidth
  /// </summary>
  TMenuMouseFake = class(TInterfacedObject, IMouseDevice, IScreenSize)
  public
    X, Y: Integer;
    Buttons: Integer;
    Width, Height: Integer;
    /// <summary>How many times the game has put the cursor somewhere</summary>
    Positioned: Integer;
    procedure Initialize;
    procedure Shutdown;
    procedure GetPosition(out AX, AY: Integer);
    procedure SetPosition(AX, AY: Integer);
    function IsButtonDown(AButton: TMouseButton): Boolean;
    function GetWidth: Integer;
    function GetHeight: Integer;
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
    /// <summary>The lumps of SyntheticArchive, for an archive that has others as well</summary>
    class procedure AddLumps(ABlo: TObject); static;
    /// <summary>A generated picture and a generated lump of bytes</summary>
    class function Picture(AWidth, AHeight, AOriginX, AOriginY, AZeroPercent: Integer; ASeed: Cardinal): TBytes; static;
    class function RandomBytes(ASize: Integer; ASeed: Cardinal; ARange: Integer): TBytes; static;
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
    FMouseFake: TMenuMouseFake;
    FMouseDevice: IMouseDevice;
    FMouseObject: TGreedMouse;
    FMouse: IGreedMouse;
    FPointer: TGreedMouseCursor;
    FPointerFrame: TGreedFrame;
    procedure Release;
    function PointerHash(AHash: Cardinal): Cardinal;
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
    /// <summary>The mouse of the scenario in course; nil for a scenario of the keys</summary>
    property Mouse: IGreedMouse read FMouse;
    property MouseFake: TMenuMouseFake read FMouseFake;
  end;

function MenuFnv(AHash: Cardinal; const AData; ASize: Integer): Cardinal;
/// <summary>
///   What a scenario with a mouse adds to the hash of the screen at each tic: whether the pointer is shown, where
///   its corner is on the screen of 640 x 400 and the block of 32 x 32 pixels drawn there over an empty screen (a
///   byte for each pixel: the index of the color, 0 where nothing was drawn or outside the screen)
/// </summary>
function MenuPointerHash(AHash: Cardinal; AVisible: Boolean; ABaseX, ABaseY: Integer; const ABlock: TBytes): Cardinal;
/// <summary>
///   What a scenario with a mouse adds to the hash of what is left at the end: mouse.flags, mouse.oldflags,
///   mouse.dx, mouse.dy, mousehx and mousehy (the bits of the two singles) and mousevisible
/// </summary>
function MenuMouseFinish(AHash: Cardinal; AFlags, AOldFlags, ADeltaX, ADeltaY: Integer; APointerX, APointerY: Single;
  AVisible: Boolean): Cardinal;
/// <summary>The same four bytes at a time (ASize is a multiple of 4): for the long scenarios</summary>
function MenuFnv4(AHash: Cardinal; const AData; ASize: Integer): Cardinal;
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
    Mouse: TArray<TMenuMouseEvent>;
    Tic: Integer;
    /// <summary>The pixels of the window for one of the screen of 320 x 200 (ClickAt and PointAt)</summary>
    Scale: Integer;
    procedure Tap(AScanCode: Integer; AHold: Integer = 3; AGap: Integer = 12);
    procedure Idle(ATics: Integer);
    procedure TypeText(const AText: string);
    /// <summary>The cursor moves and the buttons become AButtons, before the next tic</summary>
    procedure MouseEvent(ADeltaX, ADeltaY, AButtons: Integer);
    /// <summary>
    ///   The pointer of the menus goes to a pixel of the screen of 320 x 200: first as far as the corner, where
    ///   it stops, then to the pixel, two tics apart so that each movement has its own reading of the mouse
    /// </summary>
    procedure PointAt(AX, AY: Integer);
    /// <summary>PointAt, then the left button down for four tics</summary>
    procedure ClickAt(AX, AY: Integer; AGap: Integer = 12);
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

function MenuFnv4(AHash: Cardinal; const AData; ASize: Integer): Cardinal;
var
  LIndex: Integer;
  LWord: PCardinal;
begin
  Result := AHash;
  LWord := @AData;
  for LIndex := 0 to ASize div 4 - 1 do
  begin
    Result := (Result xor LWord^) * 16777619;
    Inc(LWord);
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

procedure TKeyScript.MouseEvent(ADeltaX, ADeltaY, AButtons: Integer);
var
  LCount: Integer;
begin
  LCount := Length(Mouse);
  SetLength(Mouse, LCount + 1);
  Mouse[LCount].Tic := Tic + 1;
  Mouse[LCount].DeltaX := ADeltaX;
  Mouse[LCount].DeltaY := ADeltaY;
  Mouse[LCount].Buttons := AButtons;
end;

procedure TKeyScript.PointAt(AX, AY: Integer);
begin
  MouseEvent(-4000, -4000, 0);
  Tic := Tic + 2;
  MouseEvent(AX * Scale, AY * Scale, 0);
  Tic := Tic + 2;
end;

procedure TKeyScript.ClickAt(AX, AY, AGap: Integer);
begin
  PointAt(AX, AY);
  MouseEvent(0, 0, 1);
  Tic := Tic + 4;
  MouseEvent(0, 0, 0);
  Tic := Tic + AGap;
end;

function MenuPointerHash(AHash: Cardinal; AVisible: Boolean; ABaseX, ABaseY: Integer; const ABlock: TBytes): Cardinal;
var
  LValue: Integer;
begin
  LValue := Ord(AVisible);
  Result := MenuFnv(AHash, LValue, SizeOf(LValue));
  if not AVisible then
    Exit;
  Result := MenuFnv(Result, ABaseX, SizeOf(ABaseX));
  Result := MenuFnv(Result, ABaseY, SizeOf(ABaseY));
  Result := MenuFnv(Result, ABlock[0], Length(ABlock));
end;

function MenuMouseFinish(AHash: Cardinal; AFlags, AOldFlags, ADeltaX, ADeltaY: Integer; APointerX, APointerY: Single;
  AVisible: Boolean): Cardinal;
var
  LVisible: Integer;
begin
  Result := MenuFnv(AHash, AFlags, SizeOf(AFlags));
  Result := MenuFnv(Result, AOldFlags, SizeOf(AOldFlags));
  Result := MenuFnv(Result, ADeltaX, SizeOf(ADeltaX));
  Result := MenuFnv(Result, ADeltaY, SizeOf(ADeltaY));
  Result := MenuFnv(Result, APointerX, SizeOf(APointerX));
  Result := MenuFnv(Result, APointerY, SizeOf(APointerY));
  LVisible := Ord(AVisible);
  Result := MenuFnv(Result, LVisible, SizeOf(LVisible));
end;

{ TMenuMouseFake }

procedure TMenuMouseFake.Initialize;
begin
end;

procedure TMenuMouseFake.Shutdown;
begin
end;

procedure TMenuMouseFake.GetPosition(out AX, AY: Integer);
begin
  AX := X;
  AY := Y;
end;

procedure TMenuMouseFake.SetPosition(AX, AY: Integer);
begin
  Inc(Positioned);
  X := AX;
  Y := AY;
end;

function TMenuMouseFake.IsButtonDown(AButton: TMouseButton): Boolean;
begin
  Result := (Buttons and (1 shl Ord(AButton))) <> 0;
end;

function TMenuMouseFake.GetWidth: Integer;
begin
  Result := Width;
end;

function TMenuMouseFake.GetHeight: Integer;
begin
  Result := Height;
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

class function TMenuScenarios.Picture(AWidth, AHeight, AOriginX, AOriginY, AZeroPercent: Integer;
  ASeed: Cardinal): TBytes;
begin
  Result := SyntheticPicture(AWidth, AHeight, AOriginX, AOriginY, AZeroPercent, ASeed);
end;

class function TMenuScenarios.RandomBytes(ASize: Integer; ASeed: Cardinal; ARange: Integer): TBytes;
begin
  Result := SyntheticBytes(ASize, ASeed, ARange);
end;

class procedure TMenuScenarios.AddLumps(ABlo: TObject);
const
  OPTION_PICTURES: array[0..8] of string = ('menumussli', 'menusousli', 'menuvioon', 'menuviooff', 'menuanion',
    'menuanioff', 'menuambsli', 'menuscrsli', 'menucamsli');
var
  LBlo: TGreedBlo;
  LIndex: Integer;
  LPointer: TBytes;

  function Name(const ABase: string; ANumber: Integer): string;
  begin
    if ANumber = 0 then
      Result := ABase
    else
      Result := ABase + IntToStr(ANumber);
  end;

begin
  LBlo := ABlo as TGreedBlo;
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
  // the pointer of the mouse: a picture of 16 x 16 pixels, some of them of the two colors that are not drawn.
  // It is the last lump, so the others are where they were before the mouse
  LPointer := SyntheticPicture(GREED_MOUSE_SIZE, GREED_MOUSE_SIZE, 0, 0, 25, 230);
  for LIndex := 0 to 15 do
    LPointer[GREED_MOUSE_CURSOR_HEADER_BYTES + LIndex * 17] := 255 * (LIndex and 1);
  LBlo.Add(GREED_LUMP_MOUSE_CURSOR, LPointer);
end;

class function TMenuScenarios.SyntheticArchive: IGreedArchive;
var
  LBlo: TGreedBlo;
begin
  LBlo := TGreedBlo.Create;
  try
    AddLumps(LBlo);
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

// keys and mouse together: movements of any length, buttons, clicks on the places where the menus have something
procedure RandomMouse(var ARandom: TMenuRandom; var AScript: TKeyScript; ACount: Integer);
const
  PLACES: array[0..11, 0..1] of Integer = ((60, 124), (60, 148), (190, 50), (190, 70), (190, 90), (190, 110),
    (170, 150), (60, 55), (140, 113), (170, 113), (140, 56), (77, 66));
var
  LIndex, LRoll, LPlace, LButtons, LHold, LDeltaX, LDeltaY: Integer;
begin
  LButtons := 0;
  for LIndex := 1 to ACount do
  begin
    LRoll := ARandom.Next(100);
    if LRoll < 30 then
    begin
      // two statements, in the order in which the 32 bit compiler evaluates them as arguments of one call (the
      // second first): the 64 bit compiler goes the other way and would make another scenario
      LDeltaY := ARandom.Next(161) - 80;
      LDeltaX := ARandom.Next(241) - 120;
      AScript.MouseEvent(LDeltaX, LDeltaY, LButtons);
      AScript.Idle(1 + ARandom.Next(8));
    end
    else if LRoll < 45 then
    begin
      if ARandom.Chance(70) then
        LButtons := LButtons xor 1
      else
        LButtons := ARandom.Next(8);
      AScript.MouseEvent(0, 0, LButtons);
      AScript.Idle(1 + ARandom.Next(6));
    end
    else if LRoll < 75 then
    begin
      LPlace := ARandom.Next(Length(PLACES));
      LHold := 1 + ARandom.Next(5);
      AScript.PointAt(PLACES[LPlace, 0], PLACES[LPlace, 1]);
      if ARandom.Chance(80) then
      begin
        AScript.MouseEvent(0, 0, 1);
        AScript.Idle(LHold);
        AScript.MouseEvent(0, 0, 0);
      end;
      LButtons := 0;
      AScript.Idle(ARandom.Next(14));
    end
    else
      RandomKeys(ARandom, AScript, 1, 25, 25, 15, 8, 12);
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

  procedure Window(AWidth, AHeight: Integer);
  begin
    Result.WindowWidth := AWidth;
    Result.WindowHeight := AHeight;
    LScript.Scale := AWidth div 320;
    if LScript.Scale < 1 then
      LScript.Scale := 1;
  end;

  // the scenarios with a mouse: the first ones walk through the menus with the pointer, the others are random
  procedure MouseScenario(ANumber: Integer);
  const
    WINDOWS: array[0..5, 0..1] of Integer = ((640, 400), (960, 600), (320, 200), (800, 600), (1024, 768), (500, 333));
  begin
    Result.UseMouse := True;
    Result.MenuMouse := True;
    Result.CursorX := 37;
    Result.CursorY := 21;
    Window(640, 400);
    case ANumber of
      0:
        begin
          // the pointer over an entry and nothing pressed: the cursor of the menu follows it
          Result.Animation := False;
          LScript.Idle(12);
          LScript.PointAt(190, 50);
          LScript.Idle(30);
          LScript.MouseEvent(6, 44, 0);
          LScript.Idle(20);
          LScript.MouseEvent(-300, 60, 0);
          LScript.Idle(40);
        end;
      1:
        begin
          // new game with three clicks: new, the character moo, the second row of the difficulty
          Result.Animation := False;
          LScript.Idle(12);
          LScript.ClickAt(60, 124);
          LScript.ClickAt(190, 78);
          LScript.ClickAt(190, 52);
        end;
      2, 14:
        begin
          // every option with the pointer: the sliders, the arrows of the two switches, then back
          Result.Animation := False;
          Result.GameLoaded := True;
          if ANumber = 14 then
            Window(320, 200);
          LScript.Idle(12);
          LScript.ClickAt(190, 90);
          LScript.PointAt(190, 39);
          LScript.ClickAt(60, 55);
          LScript.ClickAt(90, 64);
          LScript.ClickAt(42, 49);
          LScript.ClickAt(41, 55);
          LScript.PointAt(190, 53);
          LScript.ClickAt(75, 64);
          LScript.ClickAt(75, 65);
          LScript.PointAt(190, 67);
          LScript.ClickAt(55, 66);
          LScript.ClickAt(77, 66);
          LScript.ClickAt(66, 66);
          LScript.PointAt(190, 81);
          LScript.ClickAt(77, 62);
          LScript.ClickAt(50, 70);
          LScript.PointAt(190, 95);
          LScript.ClickAt(50, 50);
          LScript.ClickAt(90, 50);
          LScript.PointAt(190, 108);
          LScript.ClickAt(42, 60);
          LScript.ClickAt(66, 60);
          LScript.ClickAt(90, 60);
          LScript.PointAt(190, 122);
          LScript.ClickAt(70, 55);
          LScript.ClickAt(90, 55);
          LScript.ClickAt(170, 150);
          LScript.Idle(40);
          LScript.Tap(GREED_SC_ESCAPE);
        end;
      3:
        begin
          // quit from the menu with the animation: a click on YES when the panel has stopped
          Result.Animation := True;
          LScript.Idle(70);
          LScript.ClickAt(60, 148);
          LScript.Idle(90);
          LScript.ClickAt(140, 113);
        end;
      4:
        begin
          // quit, a click on NO, then out with escape
          Result.Animation := False;
          LScript.Idle(12);
          LScript.ClickAt(60, 148);
          LScript.Idle(20);
          LScript.ClickAt(170, 113);
          LScript.Idle(30);
          LScript.Tap(GREED_SC_ESCAPE);
        end;
      5:
        begin
          // clicks while the panel drops and clicks beside the two answers do nothing
          Result.Animation := True;
          LScript.Idle(70);
          LScript.ClickAt(60, 148);
          LScript.Idle(5);
          LScript.ClickAt(140, 113);
          LScript.ClickAt(100, 113);
          LScript.Idle(60);
          LScript.ClickAt(140, 100);
          LScript.ClickAt(158, 113);
          LScript.ClickAt(140, 118);
          LScript.ClickAt(170, 113);
          LScript.Idle(100);
          LScript.Tap(GREED_SC_ESCAPE);
        end;
      6:
        begin
          // load the third game with two clicks
          Result.Animation := False;
          LScript.Idle(12);
          LScript.ClickAt(190, 50);
          LScript.ClickAt(140, 56);
        end;
      7:
        begin
          // save: the game is chosen with a click, the name is typed while the mouse moves and clicks
          Result.Animation := False;
          Result.GameLoaded := True;
          LScript.Idle(12);
          LScript.ClickAt(190, 70);
          LScript.ClickAt(140, 76);
          LScript.TypeText('MOUSE 1');
          LScript.MouseEvent(30, 10, 0);
          LScript.Idle(4);
          LScript.MouseEvent(0, 0, 1);
          LScript.Idle(4);
          LScript.MouseEvent(0, 0, 0);
          LScript.TypeText('Z');
          LScript.Tap(GREED_SC_ENTER, 2, 14);
          LScript.Idle(45);
          LScript.ClickAt(170, 150);
          LScript.Idle(40);
          LScript.Tap(GREED_SC_ESCAPE);
        end;
      8:
        begin
          // the help with a click, a key for each page, then resume with a click
          Result.Animation := False;
          LScript.Idle(12);
          LScript.ClickAt(190, 110);
          LScript.Idle(30);
          LScript.Tap(GREED_SC_SPACE, 3, 25);
          LScript.Tap(GREED_SC_SPACE, 3, 25);
          LScript.Tap(GREED_SC_SPACE, 3, 25);
          LScript.ClickAt(170, 150);
        end;
      9, 10:
        begin
          // the panel alone (the quick exit): YES with the animation, NO without
          Result.Entry := meQuit;
          Result.Animation := ANumber = 9;
          LScript.Idle(100);
          if ANumber = 9 then
            LScript.ClickAt(140, 113)
          else
            LScript.ClickAt(170, 113);
        end;
      11:
        begin
          // the menus do not use the mouse: the click is not seen, the key is
          Result.Entry := meQuit;
          Result.MenuMouse := False;
          LScript.Idle(40);
          LScript.ClickAt(140, 113);
          LScript.Idle(20);
          LScript.Tap(GREED_SC_N);
        end;
      12:
        begin
          Result.MenuMouse := False;
          Result.Animation := False;
          LScript.Idle(12);
          LScript.PointAt(190, 50);
          LScript.ClickAt(60, 124);
          Downs(2);
          LScript.Tap(GREED_SC_ENTER);
          LScript.ClickAt(140, 56);
          Downs(2);
          LScript.Tap(GREED_SC_ENTER);
        end;
      13:
        begin
          // a larger window: the same pixels of the menu are three pixels of the window
          Window(960, 600);
          Result.Animation := False;
          LScript.Idle(12);
          LScript.ClickAt(60, 124);
          LScript.ClickAt(190, 116);
          LScript.ClickAt(190, 124);
        end;
      15:
        begin
          // the keys against the pointer: while it is over an entry the arrows do not move the cursor
          Result.Animation := False;
          LScript.Idle(12);
          LScript.PointAt(190, 50);
          Downs(2);
          LScript.Tap(GREED_SC_ENTER);
          LScript.MouseEvent(-4000, -4000, 0);
          LScript.Idle(4);
          Downs(3);
          LScript.Tap(GREED_SC_ENTER);
        end;
      16:
        begin
          // a window that is not a multiple of the screen: the pointer stops between two pixels
          Window(800, 500);
          Result.Animation := False;
          Result.CursorX := 611;
          Result.CursorY := 97;
          LScript.Idle(12);
          LScript.MouseEvent(-333, 41, 0);
          LScript.Idle(6);
          LScript.MouseEvent(77, -13, 0);
          LScript.Idle(6);
          LScript.MouseEvent(1, 1, 1);
          LScript.Idle(4);
          LScript.MouseEvent(-1, 0, 0);
          LScript.Idle(20);
          LScript.MouseEvent(-141, 163, 0);
          LScript.Idle(6);
          LScript.MouseEvent(0, 0, 1);
          LScript.Idle(3);
          LScript.MouseEvent(0, 0, 0);
          LScript.Idle(40);
          LScript.Tap(GREED_SC_ESCAPE);
          LScript.Idle(20);
          LScript.Tap(GREED_SC_N);
        end;
      17:
        begin
          Result.Entry := mePause;
          LScript.Idle(60);
          LScript.ClickAt(140, 113);
          LScript.Idle(60);
          LScript.Tap(GREED_SC_SPACE);
        end;
      18:
        begin
          Result.Entry := meHelp;
          LScript.Idle(25);
          LScript.ClickAt(160, 100);
          LScript.Tap(GREED_SC_ENTER, 3, 30);
          LScript.Tap(GREED_SC_ESCAPE, 3, 17);
          LScript.Tap(GREED_SC_Y, 3, 30);
        end;
      19:
        begin
          // the menu opened on the characters: forward, back, forward again
          Result.Level := GREED_MENU_CHARACTER;
          Result.Animation := False;
          LScript.Idle(12);
          LScript.ClickAt(190, 116);
          LScript.ClickAt(170, 150);
          LScript.ClickAt(190, 40);
          LScript.ClickAt(190, 124);
        end;
    else
      Result.Level := ANumber mod GREED_MENU_LEVELS;
      Result.MenuMouse := ANumber mod 7 <> 3;
      Window(WINDOWS[ANumber mod 6, 0], WINDOWS[ANumber mod 6, 1]);
      Result.CursorX := LRandom.Next(Result.WindowWidth);
      Result.CursorY := LRandom.Next(Result.WindowHeight);
      if ANumber mod 9 = 5 then
        Result.Entry := meQuit;
      RandomMouse(LRandom, LScript, 36);
    end;
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
    MENU_KEY_SCENARIOS..MENU_SCENARIOS - 1:
      MouseScenario(AIndex - MENU_KEY_SCENARIOS);
  else
    // anything
    RandomKeys(LRandom, LScript, 30, 30, 25, 10, 6, 10);
  end;
  Result.Keys := LScript.Keys;
  Result.Mouse := LScript.Mouse;
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
  FreeAndNil(FPointer);
  FMouse := nil;
  FMouseObject := nil;
  FMouseDevice := nil;
  FMouseFake := nil;
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
  if AScenario.UseMouse then
  begin
    FMouseFake := TMenuMouseFake.Create;
    FMouseDevice := FMouseFake;
    FMouseFake.X := AScenario.CursorX;
    FMouseFake.Y := AScenario.CursorY;
    FMouseFake.Width := AScenario.WindowWidth;
    FMouseFake.Height := AScenario.WindowHeight;
    FMouseObject := TGreedMouse.Create(FMouseDevice, FMouseFake, nil);
    FMouse := FMouseObject;
    FMouse.MenuEnabled := AScenario.MenuMouse;
    FPointer := TGreedMouseCursor.Create(FArchive.ReadLumpRaw(FArchive.RequireIndexOf(GREED_LUMP_MOUSE_CURSOR)));
    FPointerFrame := TGreedFrame.Make(MENU_POINTER_SCREEN_WIDTH, MENU_POINTER_SCREEN_HEIGHT);
  end;
  FInput := TGreedMenuInput.Create(FMouse);
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

function TMenuLibraryRunner.PointerHash(AHash: Cardinal): Cardinal;
var
  LBlock: TBytes;
  LBaseX, LBaseY, LRow, LColumn, LX, LY: Integer;
begin
  if not FMouse.IsVisible then
    Exit(MenuPointerHash(AHash, False, 0, 0, nil));
  // the pointer drawn over an empty screen of 640 x 400, as I_DrawMouse draws it over the picture of the game
  FPointer.Draw(FPointerFrame, FMouse.PointerX, FMouse.PointerY);
  LBaseX := Round(2 * FMouse.PointerX);
  LBaseY := Round(2 * FMouse.PointerY);
  SetLength(LBlock, MENU_POINTER_BLOCK * MENU_POINTER_BLOCK);
  for LRow := 0 to MENU_POINTER_BLOCK - 1 do
    for LColumn := 0 to MENU_POINTER_BLOCK - 1 do
    begin
      LX := LBaseX + LColumn;
      LY := LBaseY + LRow;
      if (LX >= 0) and (LX < FPointerFrame.Width) and (LY >= 0) and (LY < FPointerFrame.Height) then
      begin
        LBlock[LRow * MENU_POINTER_BLOCK + LColumn] := FPointerFrame.Pixels[LY * FPointerFrame.Width + LX];
        FPointerFrame.Pixels[LY * FPointerFrame.Width + LX] := 0;
      end;
    end;
  Result := MenuPointerHash(AHash, True, LBaseX, LBaseY, LBlock);
end;

function TMenuLibraryRunner.Run(const AScenario: TMenuScenario; AFrames: TList<Cardinal>): TMenuOutcome;
var
  LNextKey: Integer;
  LNextMouse: Integer;
  LIndex: Integer;
  LDirectory: TBytes;

  procedure Capture;
  begin
    if AScenario.UseMouse then
      Result.Pixels := PointerHash(Result.Pixels);
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
    LNextMouse := 0;
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
      while (LNextMouse < Length(AScenario.Mouse)) and (AScenario.Mouse[LNextMouse].Tic <= Result.Tics + 1) do
      begin
        FMouseFake.X := FMouseFake.X + AScenario.Mouse[LNextMouse].DeltaX;
        FMouseFake.Y := FMouseFake.Y + AScenario.Mouse[LNextMouse].DeltaY;
        FMouseFake.Buttons := AScenario.Mouse[LNextMouse].Buttons;
        Inc(LNextMouse);
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
  if AScenario.UseMouse then
    Result.Finish := MenuMouseFinish(Result.Finish, FMouseObject.Flags, FMouseObject.OldFlags, FMouse.DeltaX,
      FMouse.DeltaY, FMouse.PointerX, FMouse.PointerY, FMouse.IsVisible);
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
