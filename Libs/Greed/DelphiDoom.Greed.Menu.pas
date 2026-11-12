{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the menu, the "quit?" and "paused" panels, the   }
{  help screens and the "wait" panel                                            }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): menu.pas                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Menu;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Greed.Intf, DelphiDoom.Greed.SaveTypes,
  DelphiDoom.Greed.Save.Intf, DelphiDoom.Greed.Settings.Intf, DelphiDoom.Greed.Sound.Intf, DelphiDoom.Greed.Canvas,
  DelphiDoom.Greed.Font, DelphiDoom.Greed.TextPrinter, DelphiDoom.Greed.Display, DelphiDoom.Greed.MenuInput,
  DelphiDoom.Greed.Menu.Intf;

const
  /// <summary>MENUS: main, character, load, save, options, difficulty</summary>
  GREED_MENU_LEVELS = 6;
  GREED_MENU_MAIN = 0;
  GREED_MENU_CHARACTER = 1;
  GREED_MENU_LOAD = 2;
  GREED_MENU_SAVE = 3;
  GREED_MENU_OPTIONS = 4;
  GREED_MENU_DIFFICULTY = 5;
  /// <summary>KBDELAY2: the tics between two movements of the cursor</summary>
  GREED_MENU_KEY_DELAY = 10;

type
  /// <summary>Where the menu is: each state is one of the loops of the original that wait for a tic</summary>
  TGreedMenuState = (gmsClosed, gmsAnimate, gmsMain, gmsQuitDelay, gmsQuitDrop, gmsQuitLeave, gmsHelp,
    gmsSaveName, gmsPauseDelay, gmsPauseShow, gmsPauseLeave);

  /// <summary>
  ///   menu.pas without its loops: ShowMenu, ShowQuit, ShowPause and ShowHelp of the original return when the
  ///   player has finished; here OpenMenu, OpenQuit, OpenPause and OpenHelp do what the original does before its
  ///   first wait and return, and each Tick is one tic of the timer (the keys are read, MenuCommand runs as the
  ///   timer hook) followed by one turn of the loop of the original. Active is false when the original would have
  ///   returned. Everything is drawn on the canvas of the display at the moment the original draws it, so the
  ///   program only has to show the canvas after each Tick. What the menu decides goes to the host
  ///   (IGreedMenuHost); the options are read and written in the settings (musicvol, sfxvol, violence, animation,
  ///   ambientlight, screensize, camdelay) and the volumes go to IGreedSoundVolumes.
  ///   The text printer is the one of the game: as in the original the menu leaves its font, color and position
  ///   changed.
  ///   Not ported: the mouse (CheckMouse, the mouse part of MenuCommand and of ShowQuit), the net game (netmode is
  ///   always false) and the VR helmet (vrhelmet is always 0).
  ///   Differences from the original: what falls outside the buffer is not drawn; a missing lump is an exception
  ///   of the archive
  /// </summary>
  TGreedMenu = class
  strict private
    FDisplay: TGreedDisplay;
    FCanvas: TGreedCanvas;
    FArchive: IGreedArchive;
    FInput: TGreedMenuInput;
    FPrinter: TGreedTextPrinter;
    FFont: TGreedFont;
    FSettings: IGreedSettings;
    FVolumes: IGreedSoundVolumes;
    FSaveGames: IGreedSaveGames;
    FHost: IGreedMenuHost;
    FDemo: Boolean;
    FHelpData: TBytes;
    FLumps: TDictionary<Integer, TBytes>;
    FState: TGreedMenuState;
    // the globals of menu.pas
    FLevel: Integer;
    FCursor: Integer;
    FCursorLocation: Integer;
    FMainCursor: Integer;
    FIdentity: Integer;
    FSavePosition: Integer;
    FTimeDelay: Integer;
    FQuitMenu: Boolean;
    FExecute: Boolean;
    FDownLevel: Boolean;
    FGoRight: Boolean;
    FGoLeft: Boolean;
    FWaiting: Boolean;
    FWaitAnim: Integer;
    FSaveDir: TGreedSaveDirectory;
    FHook: Boolean;
    // the locals of the loops
    FEnterTime: Integer;
    FMenuScreen: TBytes;
    FAnimFrame: Integer;
    FAnimWait: Integer;
    FNested: Boolean;
    FBackup: TBytes;
    FWaitUntil: Integer;
    FPanelAnim: Integer;
    FPanelY: Integer;
    FDropTime: Integer;
    FAnimTime: Integer;
    FQuitChar: AnsiChar;
    FQuitAnswer: Boolean;
    FHelpScreen: TBytes;
    FHelpPage: Integer;
    FNameSlot: Integer;
    FNameCursor: Integer;
    FExecuteCursor: Integer;
    FOpenLevel: Integer;
    function Lump(const AName: string; AOffset: Integer = 0): TBytes;
    procedure FreeLumps(const AName: string; ACount: Integer);
    function Animation: Boolean;
    procedure DrawMaskedPic2(AX, AY: Integer; const APicture, ABackBuffer: TBytes);
    procedure RestoreRows(AY: Integer);
    procedure ShowMenuSliders(AValue, ARange: Integer);
    procedure ShowSaveDir;
    procedure MenuShowOptions;
    procedure MenuLeft;
    procedure MenuRight;
    procedure MenuCommand;
    procedure MenuShowCursor(ACursor: Integer);
    procedure ShowMenuLevel(ALevel: Integer);
    procedure Execute(ALevel, ACursor: Integer);
    procedure MainRest;
    procedure CloseMenu;
    procedure EnterQuit(ANested: Boolean);
    procedure QuitLeave;
    procedure QuitFinish;
    procedure EnterHelp(ANested: Boolean);
    procedure HelpShowPage;
    procedure HelpFinish;
    procedure EnterSaveName(ASlot: Integer);
    procedure PrintSaveName;
    procedure SaveNameKey;
    procedure PauseLeave;
    procedure PauseFinish;
    procedure StepAnimate;
    procedure StepMain;
    procedure StepQuitDrop;
    procedure StepQuitLeave;
    procedure StepHelp;
    procedure StepPauseShow;
    procedure StepPauseLeave;
    function GetSaveName(ASlot: Integer): string;
  public
    /// <summary>
    ///   EArgumentNilException for a missing dependency. ADemo is DEMO of constant.pas (the help has three pages).
    ///   The font is FONT1 (not owned, as the display, the input and the printer)
    /// </summary>
    constructor Create(ADisplay: TGreedDisplay; AInput: TGreedMenuInput; APrinter: TGreedTextPrinter;
      AFont1: TGreedFont; const ASettings: IGreedSettings; const AVolumes: IGreedSoundVolumes;
      const ASaveGames: IGreedSaveGames; const AHost: IGreedMenuHost; ADemo: Boolean = False);
    destructor Destroy; override;
    /// <summary>ShowMenu(n) up to its first wait: the level 0 is the main menu</summary>
    procedure OpenMenu(ALevel: Integer = GREED_MENU_MAIN);
    /// <summary>ShowQuit: when Active is false again QuitAnswer says if the answer was yes</summary>
    procedure OpenQuit;
    /// <summary>ShowPause: closes at the first key</summary>
    procedure OpenPause;
    /// <summary>ShowHelp: the screens INFO1 (and INFO2, INFO3 in the demo), a key for each</summary>
    procedure OpenHelp;
    /// <summary>One tic: the timer (Input.TimerTick), then Step. Nothing if the menu is closed</summary>
    procedure Tick;
    /// <summary>
    ///   The same without the timer, for who has already counted the tic (the intro, which shares the input):
    ///   the hook MenuCommand if it is set, then one turn of the loop
    /// </summary>
    procedure Step;
    /// <summary>StartWait: the "wait" panel over the screen; UpdateWait animates it when the clock has moved</summary>
    procedure StartWait;
    procedure UpdateWait;
    procedure EndWait;
    /// <summary>False when the original would have returned from ShowMenu, ShowQuit, ShowPause or ShowHelp</summary>
    function Active: Boolean;
    property State: TGreedMenuState read FState;
    /// <summary>The result of ShowQuit</summary>
    property QuitAnswer: Boolean read FQuitAnswer;
    /// <summary>menulevel, menucursor, identity, saveposition, waiting</summary>
    property Level: Integer read FLevel;
    property Cursor: Integer read FCursor;
    property Character: Integer read FIdentity;
    property SavePosition: Integer read FSavePosition;
    property Waiting: Boolean read FWaiting;
    /// <summary>savedir: the names as the menu has read or edited them</summary>
    property SaveNames[ASlot: Integer]: string read GetSaveName;
    /// <summary>
    ///   HELP.DAT of the Assassinator edition (64000 bytes of screen and 768 of palette): if it is given the help
    ///   shows it in place of INFO1
    /// </summary>
    property HelpData: TBytes read FHelpData write FHelpData;
  end;

implementation

uses
  DelphiDoom.Greed.Types, DelphiDoom.Greed.LittleEndian;

type
  TMenuCursorBox = record
    X, Y, W, H: Integer;
  end;

const
  MENU_DELAY_TICS = 30;
  MAX_VIEW_SIZE = 5;
  CURSOR_COLOR = 133;
  SAVE_NAME_COLOR = 93;
  SCREEN_BYTES = GREED_CANVAS_WIDTH * GREED_CANVAS_HEIGHT;

  MENU_MAX: array[0..GREED_MENU_LEVELS - 1] of Integer = (7, 7, 12, 12, 10, 8);

  CURSORS: array[0..GREED_MENU_LEVELS - 1, 0..11] of TMenuCursorBox = (
    // main menu: new, quit, load, save, options, info, resume
    ((X: 41; Y: 114; W: 55; H: 20), (X: 41; Y: 138; W: 55; H: 20), (X: 134; Y: 42; W: 127; H: 19),
     (X: 134; Y: 62; W: 127; H: 19), (X: 134; Y: 82; W: 127; H: 19), (X: 134; Y: 102; W: 127; H: 19),
     (X: 142; Y: 142; W: 62; H: 15), (X: 0; Y: 0; W: 0; H: 0), (X: 0; Y: 0; W: 0; H: 0), (X: 0; Y: 0; W: 0; H: 0),
     (X: 0; Y: 0; W: 0; H: 0), (X: 0; Y: 0; W: 0; H: 0)),
    // character: quit, cyborg, lizard, moo, specimen, dominatrix, back
    ((X: 41; Y: 138; W: 55; H: 20), (X: 134; Y: 32; W: 127; H: 18), (X: 134; Y: 51; W: 127; H: 18),
     (X: 134; Y: 70; W: 127; H: 18), (X: 134; Y: 89; W: 127; H: 18), (X: 134; Y: 108; W: 127; H: 18),
     (X: 142; Y: 142; W: 62; H: 15), (X: 0; Y: 0; W: 0; H: 0), (X: 0; Y: 0; W: 0; H: 0), (X: 0; Y: 0; W: 0; H: 0),
     (X: 0; Y: 0; W: 0; H: 0), (X: 0; Y: 0; W: 0; H: 0)),
    // load: quit, the ten games, back
    ((X: 41; Y: 138; W: 55; H: 20), (X: 137; Y: 34; W: 7; H: 5), (X: 137; Y: 44; W: 7; H: 5),
     (X: 137; Y: 54; W: 7; H: 5), (X: 137; Y: 64; W: 7; H: 5), (X: 137; Y: 74; W: 7; H: 5),
     (X: 137; Y: 84; W: 7; H: 5), (X: 137; Y: 94; W: 7; H: 5), (X: 137; Y: 104; W: 7; H: 5),
     (X: 137; Y: 114; W: 7; H: 5), (X: 137; Y: 124; W: 7; H: 5), (X: 142; Y: 142; W: 62; H: 15)),
    // save: the same
    ((X: 41; Y: 138; W: 55; H: 20), (X: 137; Y: 34; W: 7; H: 5), (X: 137; Y: 44; W: 7; H: 5),
     (X: 137; Y: 54; W: 7; H: 5), (X: 137; Y: 64; W: 7; H: 5), (X: 137; Y: 74; W: 7; H: 5),
     (X: 137; Y: 84; W: 7; H: 5), (X: 137; Y: 94; W: 7; H: 5), (X: 137; Y: 104; W: 7; H: 5),
     (X: 137; Y: 114; W: 7; H: 5), (X: 137; Y: 124; W: 7; H: 5), (X: 142; Y: 142; W: 62; H: 15)),
    // options: new, quit, music, sound, violence, animation, light, screen size, camera delay, back
    ((X: 41; Y: 114; W: 55; H: 20), (X: 41; Y: 138; W: 55; H: 20), (X: 134; Y: 32; W: 127; H: 15),
     (X: 134; Y: 46; W: 127; H: 15), (X: 134; Y: 60; W: 127; H: 15), (X: 134; Y: 74; W: 127; H: 15),
     (X: 134; Y: 88; W: 127; H: 15), (X: 134; Y: 101; W: 127; H: 15), (X: 134; Y: 115; W: 127; H: 15),
     (X: 142; Y: 142; W: 62; H: 15), (X: 0; Y: 0; W: 0; H: 0), (X: 0; Y: 0; W: 0; H: 0)),
    // difficulty: quit, the six levels, back
    ((X: 41; Y: 138; W: 55; H: 20), (X: 134; Y: 30; W: 127; H: 15), (X: 134; Y: 45; W: 127; H: 15),
     (X: 134; Y: 60; W: 127; H: 15), (X: 134; Y: 75; W: 127; H: 15), (X: 134; Y: 90; W: 127; H: 15),
     (X: 134; Y: 117; W: 127; H: 15), (X: 142; Y: 142; W: 62; H: 15), (X: 0; Y: 0; W: 0; H: 0),
     (X: 0; Y: 0; W: 0; H: 0), (X: 0; Y: 0; W: 0; H: 0), (X: 0; Y: 0; W: 0; H: 0))
  );

  SETTING_MUSIC = 'musicvol';
  SETTING_SFX = 'sfxvol';
  SETTING_VIOLENCE = 'violence';
  SETTING_ANIMATION = 'animation';
  SETTING_LIGHT = 'ambientlight';
  SETTING_SCREEN_SIZE = 'screensize';
  SETTING_CAMERA_DELAY = 'camdelay';

  SGreedMenuLevel = 'Greed: the menu has no level %d';
  SGreedMenuBusy = 'Greed: the menu is already open';
  SGreedHelpDataTooShort = 'Greed: HELP.DAT has %d bytes, it needs %d';

// isalnum of g_delphi.pas as it is: of the lower case letters only the z
function IsAlphaNumeric(ACharacter: AnsiChar): Boolean;
begin
  Result := ((ACharacter >= 'A') and (ACharacter <= 'Z')) or ((ACharacter >= 'z') and (ACharacter <= 'z')) or
    ((ACharacter >= '0') and (ACharacter <= '9'));
end;

{ TGreedMenu }

constructor TGreedMenu.Create(ADisplay: TGreedDisplay; AInput: TGreedMenuInput; APrinter: TGreedTextPrinter;
  AFont1: TGreedFont; const ASettings: IGreedSettings; const AVolumes: IGreedSoundVolumes;
  const ASaveGames: IGreedSaveGames; const AHost: IGreedMenuHost; ADemo: Boolean);
begin
  inherited Create;
  if not Assigned(ADisplay) then
    raise EArgumentNilException.Create('ADisplay');
  if not Assigned(AInput) then
    raise EArgumentNilException.Create('AInput');
  if not Assigned(APrinter) then
    raise EArgumentNilException.Create('APrinter');
  if not Assigned(AFont1) then
    raise EArgumentNilException.Create('AFont1');
  if not Assigned(ASettings) then
    raise EArgumentNilException.Create('ASettings');
  if not Assigned(AVolumes) then
    raise EArgumentNilException.Create('AVolumes');
  if not Assigned(ASaveGames) then
    raise EArgumentNilException.Create('ASaveGames');
  if not Assigned(AHost) then
    raise EArgumentNilException.Create('AHost');
  FDisplay := ADisplay;
  FCanvas := ADisplay.Canvas;
  FArchive := ADisplay.Archive;
  FInput := AInput;
  FPrinter := APrinter;
  FFont := AFont1;
  FSettings := ASettings;
  FVolumes := AVolumes;
  FSaveGames := ASaveGames;
  FHost := AHost;
  FDemo := ADemo;
  FLumps := TDictionary<Integer, TBytes>.Create;
  FState := gmsClosed;
end;

destructor TGreedMenu.Destroy;
begin
  FLumps.Free;
  inherited;
end;

function TGreedMenu.Active: Boolean;
begin
  Result := FState <> gmsClosed;
end;

function TGreedMenu.GetSaveName(ASlot: Integer): string;
begin
  if (ASlot < 0) or (ASlot >= GREED_MAX_SAVE_GAMES) then
    Result := ''
  else
    Result := string(FSaveDir[ASlot]);
end;

function TGreedMenu.Lump(const AName: string; AOffset: Integer): TBytes;
var
  LIndex: Integer;
begin
  // the cache of the original: a picture drawn "solid" keeps its zeroes changed until it is freed
  LIndex := FArchive.RequireIndexOf(AName) + AOffset;
  if not FLumps.TryGetValue(LIndex, Result) then
  begin
    Result := FArchive.ReadLump(LIndex);
    FLumps.Add(LIndex, Result);
  end;
end;

procedure TGreedMenu.FreeLumps(const AName: string; ACount: Integer);
var
  LFirst: Integer;
  LIndex: Integer;
begin
  LFirst := FArchive.RequireIndexOf(AName);
  for LIndex := LFirst to LFirst + ACount - 1 do
    FLumps.Remove(LIndex);
end;

function TGreedMenu.Animation: Boolean;
begin
  Result := FSettings.GetBoolean(SETTING_ANIMATION);
end;

procedure TGreedMenu.DrawMaskedPic2(AX, AY: Integer; const APicture, ABackBuffer: TBytes);
var
  LWidth, LHeight: Integer;
  LRow, LColumn: Integer;
  LY, LX: Integer;
  LDest: Integer;
  LColor: Byte;
  LPixels: TBytes;
begin
  // VI_DrawMaskedPic2: where the picture has a 0, or outside the columns of the screen, the pixel of the back
  // buffer comes back (with no back buffer the screen itself: nothing changes)
  if Length(APicture) < GREED_PICTURE_HEADER_BYTES then
    raise EGreedDataException.CreateFmt(SGreedImageTooShort, ['picture', Length(APicture),
      GREED_PICTURE_HEADER_BYTES]);
  LWidth := TGreedLittleEndian.ReadSmallInt(APicture, 0);
  LHeight := TGreedLittleEndian.ReadSmallInt(APicture, 2);
  if (LWidth < 0) or (LHeight < 0) or
    (Length(APicture) < GREED_PICTURE_HEADER_BYTES + Int64(LWidth) * LHeight) then
    raise EGreedDataException.CreateFmt(SGreedImageTooShort, ['picture', Length(APicture),
      GREED_PICTURE_HEADER_BYTES + Int64(LWidth) * LHeight]);
  AX := AX - TGreedLittleEndian.ReadSmallInt(APicture, 4);
  AY := AY - TGreedLittleEndian.ReadSmallInt(APicture, 6);
  LPixels := FCanvas.Pixels;
  for LRow := 0 to LHeight - 1 do
  begin
    LY := AY + LRow;
    if (LY < 0) or (LY >= GREED_CANVAS_HEIGHT) then
      Continue;
    for LColumn := 0 to LWidth - 1 do
    begin
      LX := AX + LColumn;
      LDest := LY * GREED_CANVAS_WIDTH + LX;
      if (LDest < 0) or (LDest >= Length(LPixels)) then
        Continue;
      LColor := APicture[GREED_PICTURE_HEADER_BYTES + LRow * LWidth + LColumn];
      if (LX >= 0) and (LX <= GREED_CANVAS_WIDTH - 1) and (LColor <> 0) then
        LPixels[LDest] := LColor
      else if LDest < Length(ABackBuffer) then
        LPixels[LDest] := ABackBuffer[LDest];
    end;
  end;
end;

procedure TGreedMenu.RestoreRows(AY: Integer);
var
  LOffset: Integer;
  LCount: Integer;
begin
  // memcpy(@viewbuffer[320 * y], @pscreen[320 * y], 640): the two rows that the panel leaves while it drops
  if AY < 0 then
    Exit;
  LOffset := GREED_CANVAS_WIDTH * AY;
  LCount := 2 * GREED_CANVAS_WIDTH;
  if LOffset + LCount > Length(FBackup) then
    LCount := Length(FBackup) - LOffset;
  if LCount > 0 then
    Move(FBackup[LOffset], FCanvas.Pixels[LOffset], LCount);
end;

procedure TGreedMenu.ShowMenuSliders(AValue, ARange: Integer);
var
  LFilled: Integer;
  LColumn: Integer;
  LRow: Integer;
  LColor: Integer;
begin
  LFilled := (AValue * 49) div ARange;
  for LColumn := 0 to LFilled - 1 do
  begin
    LColor := (LColumn * 32) div LFilled + 140;
    for LRow := 49 to 64 do
      FCanvas.PutPixel(LColumn + 42, LRow, LColor);
  end;
  if LFilled < 49 then
    for LColumn := LFilled to 48 do
      for LRow := 49 to 64 do
        FCanvas.PutPixel(LColumn + 42, LRow, FCanvas.ApproxZero);
end;

procedure TGreedMenu.ShowSaveDir;
var
  LIndex: Integer;
  LRow: Integer;
begin
  // the file is read again each time, and made empty if it is not there (InitSaveDir)
  FSaveDir := FSaveGames.ReadDirectory;
  FPrinter.BaseColor := SAVE_NAME_COLOR;
  FPrinter.Font := FFont;
  for LIndex := 0 to GREED_MAX_SAVE_GAMES - 1 do
  begin
    FPrinter.PrintX := 148;
    FPrinter.PrintY := 34 + LIndex * 10;
    for LRow := 0 to 5 do
      FCanvas.FillRow(FPrinter.PrintX, FPrinter.PrintY + LRow, 110, FCanvas.ApproxZero);
    FPrinter.Print(string(FSaveDir[LIndex]));
  end;
end;

procedure TGreedMenu.MenuShowOptions;
begin
  case FCursor of
    2:
      begin
        FCanvas.DrawPicSolid(35, 29, Lump('menumussli'));
        ShowMenuSliders(FSettings.GetInteger(SETTING_MUSIC), 256);
      end;
    3:
      begin
        FCanvas.DrawPicSolid(35, 29, Lump('menusousli'));
        ShowMenuSliders(FSettings.GetInteger(SETTING_SFX), 256);
      end;
    4:
      if FSettings.GetBoolean(SETTING_VIOLENCE) then
        FCanvas.DrawPicSolid(35, 29, Lump('menuvioon'))
      else
        FCanvas.DrawPicSolid(35, 29, Lump('menuviooff'));
    5:
      if FSettings.GetBoolean(SETTING_ANIMATION) then
        FCanvas.DrawPicSolid(35, 29, Lump('menuanion'))
      else
        FCanvas.DrawPicSolid(35, 29, Lump('menuanioff'));
    6:
      begin
        FCanvas.DrawPicSolid(35, 29, Lump('menuambsli'));
        ShowMenuSliders(FSettings.GetInteger(SETTING_LIGHT), 4096);
      end;
    7:
      begin
        FCanvas.DrawPicSolid(35, 29, Lump('menuscrsli'));
        ShowMenuSliders(MAX_VIEW_SIZE - FSettings.GetInteger(SETTING_SCREEN_SIZE) - 1, MAX_VIEW_SIZE - 1);
      end;
    8:
      begin
        FCanvas.DrawPicSolid(35, 29, Lump('menucamsli'));
        ShowMenuSliders(FSettings.GetInteger(SETTING_CAMERA_DELAY), 70);
      end;
  end;
end;

procedure TGreedMenu.MenuLeft;
var
  LValue: Integer;
begin
  if FLevel <> GREED_MENU_OPTIONS then
    Exit;
  case FCursor of
    2:
      begin
        LValue := FSettings.GetInteger(SETTING_MUSIC);
        if LValue <> 0 then
        begin
          LValue := LValue - 4;
          if LValue < 0 then
            LValue := 0;
          FSettings.SetInteger(SETTING_MUSIC, LValue);
          FVolumes.SetVolumes(LValue, FSettings.GetInteger(SETTING_SFX));
          ShowMenuSliders(LValue, 255);
        end;
      end;
    3:
      begin
        LValue := FSettings.GetInteger(SETTING_SFX);
        if LValue <> 0 then
        begin
          LValue := LValue - 4;
          if LValue < 0 then
            LValue := 0;
          FSettings.SetInteger(SETTING_SFX, LValue);
          FVolumes.SetVolumes(FSettings.GetInteger(SETTING_MUSIC), LValue);
          ShowMenuSliders(LValue, 255);
        end;
      end;
    4:
      begin
        FSettings.SetBoolean(SETTING_VIOLENCE, True);
        MenuShowOptions;
      end;
    5:
      begin
        FSettings.SetBoolean(SETTING_ANIMATION, True);
        MenuShowOptions;
      end;
    6:
      begin
        LValue := FSettings.GetInteger(SETTING_LIGHT);
        if LValue <> 0 then
        begin
          LValue := LValue - 64;
          if LValue < 0 then
            LValue := 0;
          FSettings.SetInteger(SETTING_LIGHT, LValue);
          ShowMenuSliders(LValue, 4096);
          FHost.AmbientLightChanged(LValue);
        end;
      end;
    7:
      begin
        LValue := FSettings.GetInteger(SETTING_SCREEN_SIZE);
        if LValue < MAX_VIEW_SIZE - 1 then
        begin
          Inc(LValue);
          FSettings.SetInteger(SETTING_SCREEN_SIZE, LValue);
          ShowMenuSliders(MAX_VIEW_SIZE - LValue - 1, MAX_VIEW_SIZE - 1);
          FTimeDelay := FInput.TimeCount + GREED_MENU_KEY_DELAY;
          FGoLeft := False;
        end;
      end;
    8:
      begin
        LValue := FSettings.GetInteger(SETTING_CAMERA_DELAY);
        if LValue <> 0 then
        begin
          Dec(LValue);
          FSettings.SetInteger(SETTING_CAMERA_DELAY, LValue);
          ShowMenuSliders(LValue, 70);
        end;
      end;
  end;
end;

procedure TGreedMenu.MenuRight;
var
  LValue: Integer;
begin
  if FLevel <> GREED_MENU_OPTIONS then
    Exit;
  case FCursor of
    2:
      begin
        LValue := FSettings.GetInteger(SETTING_MUSIC);
        if LValue < 255 then
        begin
          LValue := LValue + 4;
          if LValue > 255 then
            LValue := 255;
          FSettings.SetInteger(SETTING_MUSIC, LValue);
          FVolumes.SetVolumes(LValue, FSettings.GetInteger(SETTING_SFX));
          ShowMenuSliders(LValue, 255);
        end;
      end;
    3:
      begin
        LValue := FSettings.GetInteger(SETTING_SFX);
        if LValue < 255 then
        begin
          LValue := LValue + 4;
          if LValue > 255 then
            LValue := 255;
          FSettings.SetInteger(SETTING_SFX, LValue);
          FVolumes.SetVolumes(FSettings.GetInteger(SETTING_MUSIC), LValue);
          ShowMenuSliders(LValue, 255);
        end;
      end;
    4:
      begin
        FSettings.SetBoolean(SETTING_VIOLENCE, False);
        MenuShowOptions;
      end;
    5:
      begin
        FSettings.SetBoolean(SETTING_ANIMATION, False);
        MenuShowOptions;
      end;
    6:
      begin
        LValue := FSettings.GetInteger(SETTING_LIGHT);
        if LValue < 4096 then
        begin
          LValue := LValue + 64;
          if LValue > 4096 then
            LValue := 4096;
          FSettings.SetInteger(SETTING_LIGHT, LValue);
          ShowMenuSliders(LValue, 4096);
          FHost.AmbientLightChanged(LValue);
        end;
      end;
    7:
      begin
        LValue := FSettings.GetInteger(SETTING_SCREEN_SIZE);
        if LValue <> 0 then
        begin
          Dec(LValue);
          FSettings.SetInteger(SETTING_SCREEN_SIZE, LValue);
          ShowMenuSliders(MAX_VIEW_SIZE - LValue - 1, MAX_VIEW_SIZE - 1);
          FTimeDelay := FInput.TimeCount + GREED_MENU_KEY_DELAY;
          FGoRight := False;
        end;
      end;
    8:
      begin
        LValue := FSettings.GetInteger(SETTING_CAMERA_DELAY);
        if LValue < 70 then
        begin
          Inc(LValue);
          FSettings.SetInteger(SETTING_CAMERA_DELAY, LValue);
          ShowMenuSliders(LValue, 70);
        end;
      end;
  end;
end;

procedure TGreedMenu.MenuCommand;
var
  LTime: Integer;
begin
  LTime := FInput.TimeCount;
  if (FInput.Keyboard[GREED_SC_ESCAPE] = 1) and (LTime > FTimeDelay) then
  begin
    FInput.EatKey(GREED_SC_ESCAPE);
    FDownLevel := True;
    FTimeDelay := LTime + GREED_MENU_KEY_DELAY;
  end;

  if (FInput.Keyboard[GREED_SC_UPARROW] <> 0) and (LTime > FTimeDelay) then
  begin
    Dec(FCursor);
    if FCursor < 0 then
      FCursor := MENU_MAX[FLevel] - 1;
    FTimeDelay := LTime + GREED_MENU_KEY_DELAY;
  end
  else if (FInput.Keyboard[GREED_SC_DOWNARROW] <> 0) and (LTime > FTimeDelay) then
  begin
    Inc(FCursor);
    if FCursor = MENU_MAX[FLevel] then
      FCursor := 0;
    FTimeDelay := LTime + GREED_MENU_KEY_DELAY;
  end;

  if (FInput.Keyboard[GREED_SC_RIGHTARROW] <> 0) and (LTime > FTimeDelay) then
    FGoRight := True
  else if (FInput.Keyboard[GREED_SC_LEFTARROW] <> 0) and (LTime > FTimeDelay) then
    FGoLeft := True;

  if (FInput.Keyboard[GREED_SC_ENTER] <> 0) and (LTime > FTimeDelay) then
  begin
    FExecute := True;
    FTimeDelay := LTime + GREED_MENU_KEY_DELAY;
  end;
end;

procedure TGreedMenu.MenuShowCursor(ACursor: Integer);
var
  LBox: TMenuCursorBox;
  LRow: Integer;
begin
  if (ACursor = -1) or (ACursor = FCursorLocation) then
    Exit;
  FCanvas.DrawMaskedPic(20, 15, Lump('menumain', FLevel));
  FCursorLocation := ACursor;
  if (ACursor >= Low(CURSORS[FLevel])) and (ACursor <= High(CURSORS[FLevel])) then
  begin
    LBox := CURSORS[FLevel][ACursor];
    FCanvas.FillRow(LBox.X, LBox.Y, LBox.W, CURSOR_COLOR);
    FCanvas.FillRow(LBox.X, LBox.Y + LBox.H - 1, LBox.W, CURSOR_COLOR);
    for LRow := LBox.Y to LBox.Y + LBox.H - 1 do
    begin
      FCanvas.PutPixel(LBox.X, LRow, CURSOR_COLOR);
      FCanvas.PutPixel(LBox.X + LBox.W - 1, LRow, CURSOR_COLOR);
    end;
  end;
  if (FLevel = GREED_MENU_LOAD) or (FLevel = GREED_MENU_SAVE) then
    ShowSaveDir;
  if FLevel = GREED_MENU_OPTIONS then
    MenuShowOptions;
end;

procedure TGreedMenu.ShowMenuLevel(ALevel: Integer);
begin
  if FLevel = GREED_MENU_MAIN then
    FMainCursor := FCursor;
  FLevel := ALevel;
  FCanvas.DrawMaskedPic(20, 15, Lump('menumain', ALevel));

  if FLevel = GREED_MENU_MAIN then
    FCursor := FMainCursor
  else if FLevel = GREED_MENU_CHARACTER then
    FCursor := 1
  else if (FLevel = GREED_MENU_LOAD) or (FLevel = GREED_MENU_SAVE) then
  begin
    if FSavePosition > 0 then
      FCursor := FSavePosition
    else
      FCursor := 1;
  end
  else
    FCursor := 2;

  FCursorLocation := -1;
  MenuShowCursor(FCursor);
end;

procedure TGreedMenu.Execute(ALevel, ACursor: Integer);
var
  LMap: Integer;
begin
  FExecuteCursor := ACursor;
  case ALevel of
    GREED_MENU_MAIN:
      case ACursor of
        0: ShowMenuLevel(GREED_MENU_CHARACTER);
        1: EnterQuit(True);
        2: ShowMenuLevel(GREED_MENU_LOAD);
        3:
          if FHost.GameLoaded then
            ShowMenuLevel(GREED_MENU_SAVE);
        4: ShowMenuLevel(GREED_MENU_OPTIONS);
        5:
          begin
            FHook := False;
            EnterHelp(True);
          end;
        6: FQuitMenu := True;
      end;
    GREED_MENU_CHARACTER:
      case ACursor of
        0: EnterQuit(True);
        1..5:
          begin
            FIdentity := ACursor - 1;
            ShowMenuLevel(GREED_MENU_DIFFICULTY);
          end;
        6: FDownLevel := True;
      end;
    GREED_MENU_LOAD:
      case ACursor of
        0: EnterQuit(True);
        11: FDownLevel := True;
      else
        FHost.LoadGame(FCursor - 1);
        FQuitMenu := True;
        FSavePosition := ACursor;
      end;
    GREED_MENU_SAVE:
      case ACursor of
        0: EnterQuit(True);
        11: FDownLevel := True;
      else
        EnterSaveName(FCursor - 1);
      end;
    GREED_MENU_OPTIONS:
      case ACursor of
        0: ShowMenuLevel(GREED_MENU_CHARACTER);
        1: EnterQuit(True);
        9: FDownLevel := True;
      end;
    GREED_MENU_DIFFICULTY:
      case ACursor of
        0: EnterQuit(True);
        1..6:
          begin
            // timecount := 0 (and frames := 0, which is of the game)
            FInput.TimeCount := 0;
            case FSettings.GetGameVariant of
              ggvGame2: LMap := 8;
              ggvGame3: LMap := 16;
            else
              LMap := 0;
            end;
            FHost.NewGame(LMap, FIdentity, 6 - ACursor);
            FQuitMenu := True;
          end;
        7: ShowMenuLevel(GREED_MENU_CHARACTER);
      end;
  end;
end;

procedure TGreedMenu.MainRest;
begin
  // the rest of a turn of the loop of ShowMenu, after Execute has returned
  FExecute := False;
  if FDownLevel then
  begin
    if FLevel = GREED_MENU_MAIN then
    begin
      if FInput.TimeCount > FEnterTime + MENU_DELAY_TICS then
        FQuitMenu := True;
    end
    else
      ShowMenuLevel(GREED_MENU_MAIN);
    FDownLevel := False;
  end;
  if FGoRight then
  begin
    MenuRight;
    FGoRight := False;
  end;
  if FGoLeft then
  begin
    MenuLeft;
    FGoLeft := False;
  end;
  if FQuitMenu then
    CloseMenu
  else
    FState := gmsMain;
end;

procedure TGreedMenu.CloseMenu;
var
  LSize: Integer;
begin
  Move(FMenuScreen[0], FCanvas.Pixels[0], SCREEN_BYTES);
  FMenuScreen := nil;
  if FHost.GameLoaded then
  begin
    LSize := FSettings.GetInteger(SETTING_SCREEN_SIZE);
    if LSize > MAX_VIEW_SIZE - 1 then
      LSize := MAX_VIEW_SIZE - 1
    else if LSize < 0 then
      LSize := 0;
    FSettings.SetInteger(SETTING_SCREEN_SIZE, LSize);
    FHost.ApplyViewSize(LSize);
  end;
  FHost.SaveSettings;
  FHost.ResetControls;
  // the caller of the original puts its own timer hook back
  FHook := False;
  FState := gmsClosed;
end;

procedure TGreedMenu.OpenMenu(ALevel: Integer);
begin
  if FState <> gmsClosed then
    raise EGreedException.Create(SGreedMenuBusy);
  if (ALevel < 0) or (ALevel >= GREED_MENU_LEVELS) then
    raise EGreedException.CreateFmt(SGreedMenuLevel, [ALevel]);
  FTimeDelay := FInput.TimeCount + GREED_MENU_KEY_DELAY;
  FEnterTime := FInput.TimeCount;
  FHook := True;
  FMenuScreen := Copy(FCanvas.Pixels, 0, SCREEN_BYTES);
  FNested := False;
  if Animation then
  begin
    // MenuAnimate
    FAnimFrame := -1;
    FAnimWait := FInput.TimeCount;
    FOpenLevel := ALevel;
    FState := gmsAnimate;
    Exit;
  end;
  ShowMenuLevel(ALevel);
  FQuitMenu := False;
  FState := gmsMain;
end;

procedure TGreedMenu.StepAnimate;
begin
  if FInput.TimeCount < FAnimWait then
    Exit;
  Inc(FAnimFrame);
  if FAnimFrame = 8 then
  begin
    FreeLumps('menuanim', 8);
    ShowMenuLevel(FOpenLevel);
    FQuitMenu := False;
    FState := gmsMain;
    Exit;
  end;
  DrawMaskedPic2(20, 15, Lump('menuanim', FAnimFrame), nil);
  FAnimWait := FAnimWait + 7;
end;

procedure TGreedMenu.StepMain;
begin
  MenuShowCursor(FCursor);
  if FExecute then
  begin
    Execute(FLevel, FCursor);
    // a panel, the help or the name of a saved game: the turn goes on when it ends
    if FState <> gmsMain then
      Exit;
  end;
  MainRest;
end;

// ---------------------------------------------------------------------------------------------------------
// ShowQuit
// ---------------------------------------------------------------------------------------------------------

procedure TGreedMenu.OpenQuit;
begin
  if FState <> gmsClosed then
    raise EGreedException.Create(SGreedMenuBusy);
  EnterQuit(False);
end;

procedure TGreedMenu.EnterQuit(ANested: Boolean);
begin
  FNested := ANested;
  FHook := False;
  FBackup := Copy(FCanvas.Pixels, 0, SCREEN_BYTES);
  FTimeDelay := FInput.TimeCount + GREED_MENU_KEY_DELAY;
  FWaitUntil := FInput.TimeCount + GREED_MENU_KEY_DELAY;
  FState := gmsQuitDelay;
end;

procedure TGreedMenu.StepQuitDrop;
begin
  if FInput.NewAscii and (FPanelY >= 67) and (FInput.LastAscii <> #0) then
  begin
    FQuitChar := FInput.LastAscii;
    QuitLeave;
    Exit;
  end;
  if FInput.NewAscii and ((FInput.LastAscii = 'y') or (FInput.LastAscii = 'Y')) then
    FQuitChar := 'y';
  if (FInput.TimeCount >= FDropTime) and (FPanelY < 67) then
  begin
    RestoreRows(FPanelY);
    FPanelY := FPanelY + 2;
    FDropTime := FInput.TimeCount + 1;
    DrawMaskedPic2(111, FPanelY, Lump('quit', FPanelAnim), FBackup);
  end;
  if FInput.TimeCount >= FAnimTime then
  begin
    FPanelAnim := (FPanelAnim + 1) mod 3;
    FAnimTime := FAnimTime + 10;
    DrawMaskedPic2(111, FPanelY, Lump('quit', FPanelAnim), FBackup);
  end;
end;

procedure TGreedMenu.QuitLeave;
begin
  FQuitAnswer := (FQuitChar = 'y') or (FQuitChar = 'Y');
  FDropTime := FInput.TimeCount;
  FAnimTime := FInput.TimeCount;
  if not Animation then
    FPanelY := 200;
  if FPanelY < 199 then
    FState := gmsQuitLeave
  else
    QuitFinish;
end;

procedure TGreedMenu.StepQuitLeave;
begin
  if FInput.TimeCount >= FDropTime then
  begin
    RestoreRows(FPanelY);
    FPanelY := FPanelY + 2;
    FDropTime := FInput.TimeCount + 1;
    DrawMaskedPic2(111, FPanelY, Lump('quit', FPanelAnim), FBackup);
  end;
  if FInput.TimeCount >= FAnimTime then
  begin
    FPanelAnim := (FPanelAnim + 1) mod 3;
    FAnimTime := FAnimTime + 10;
    DrawMaskedPic2(111, FPanelY, Lump('quit', FPanelAnim), FBackup);
  end;
  if FPanelY >= 199 then
    QuitFinish;
end;

procedure TGreedMenu.QuitFinish;
begin
  Move(FBackup[0], FCanvas.Pixels[0], SCREEN_BYTES);
  FBackup := nil;
  FreeLumps('quit', 3);
  FTimeDelay := FInput.TimeCount + GREED_MENU_KEY_DELAY;
  FHost.ResetControls;
  if not FNested then
  begin
    FState := gmsClosed;
    Exit;
  end;
  FHook := True;
  if FQuitAnswer then
  begin
    FHost.QuitGame;
    FQuitMenu := True;
  end;
  MainRest;
end;

// ---------------------------------------------------------------------------------------------------------
// ShowHelp
// ---------------------------------------------------------------------------------------------------------

procedure TGreedMenu.OpenHelp;
begin
  if FState <> gmsClosed then
    raise EGreedException.Create(SGreedMenuBusy);
  FHook := False;
  EnterHelp(False);
end;

procedure TGreedMenu.EnterHelp(ANested: Boolean);
var
  LColors: TBytes;
begin
  FNested := ANested;
  FHelpScreen := Copy(FCanvas.Pixels, 0, SCREEN_BYTES);
  FDisplay.FillPalette(0, 0, 0);
  FDisplay.FillScreen(0);
  if Length(FHelpData) > 0 then
  begin
    if Length(FHelpData) < SCREEN_BYTES + GREED_DISPLAY_PALETTE_BYTES then
      raise EGreedDataException.CreateFmt(SGreedHelpDataTooShort, [Length(FHelpData),
        SCREEN_BYTES + GREED_DISPLAY_PALETTE_BYTES]);
    Move(FHelpData[0], FCanvas.Pixels[0], SCREEN_BYTES);
    LColors := Copy(FHelpData, SCREEN_BYTES, GREED_DISPLAY_PALETTE_BYTES);
    FDisplay.Colors := LColors;
  end
  else
    FDisplay.LoadScreen('INFO1');
  FHelpPage := 1;
  HelpShowPage;
end;

procedure TGreedMenu.HelpShowPage;
begin
  FDisplay.ShowColors;
  FInput.NewAscii := False;
  FWaitUntil := FInput.TimeCount + 10;
  FState := gmsHelp;
end;

procedure TGreedMenu.StepHelp;
begin
  if FInput.TimeCount < FWaitUntil then
    Exit;
  if not FInput.NewAscii then
  begin
    FWaitUntil := FInput.TimeCount + 10;
    Exit;
  end;
  FDisplay.FillPalette(0, 0, 0);
  FDisplay.FillScreen(0);
  if FDemo and (FHelpPage < 3) then
  begin
    Inc(FHelpPage);
    FDisplay.LoadScreen('INFO' + IntToStr(FHelpPage));
    HelpShowPage;
    Exit;
  end;
  HelpFinish;
end;

procedure TGreedMenu.HelpFinish;
begin
  FDisplay.SetPaletteFromLump('palette');
  Move(FHelpScreen[0], FCanvas.Pixels[0], SCREEN_BYTES);
  FHelpScreen := nil;
  if not FNested then
  begin
    FState := gmsClosed;
    Exit;
  end;
  FHook := True;
  MainRest;
end;

// ---------------------------------------------------------------------------------------------------------
// GetSavedName
// ---------------------------------------------------------------------------------------------------------

procedure TGreedMenu.EnterSaveName(ASlot: Integer);
begin
  FNameSlot := ASlot;
  FNameCursor := Length(FSaveDir[ASlot]);
  if FNameCursor > 20 then
    FNameCursor := 20;
  FSaveDir[ASlot] := FSaveDir[ASlot] + '_';
  FHook := False;
  FInput.LastAscii := #0;
  FInput.NewAscii := False;
  PrintSaveName;
  FState := gmsSaveName;
end;

procedure TGreedMenu.PrintSaveName;
var
  LRow: Integer;
begin
  FPrinter.PrintX := 148;
  FPrinter.PrintY := 34 + FNameSlot * 10;
  for LRow := 0 to 5 do
    FCanvas.FillRow(FPrinter.PrintX, FPrinter.PrintY + LRow, 100, FCanvas.ApproxZero);
  FPrinter.Print(string(FSaveDir[FNameSlot]));
end;

procedure TGreedMenu.SaveNameKey;
var
  LKey: AnsiChar;
  LDone: Boolean;
  LLength: Integer;
begin
  MenuShowCursor(FNameSlot + 1);
  if not FInput.NewAscii then
    Exit;
  LKey := FInput.LastAscii;
  LDone := False;
  case Ord(LKey) of
    13, 27:
      LDone := True;
    8:
      begin
        if Length(FSaveDir[FNameSlot]) > 0 then
          SetLength(FSaveDir[FNameSlot], Length(FSaveDir[FNameSlot]) - 1);
        if Length(FSaveDir[FNameSlot]) > 0 then
          SetLength(FSaveDir[FNameSlot], Length(FSaveDir[FNameSlot]) - 1);
        FSaveDir[FNameSlot] := FSaveDir[FNameSlot] + '_';
        Dec(FNameCursor);
      end;
  else
    if IsAlphaNumeric(LKey) or (LKey in [' ', '.', '-', '!', ',', '?', '''']) then
    begin
      LLength := Length(FSaveDir[FNameSlot]);
      if LLength = 0 then
        FSaveDir[FNameSlot] := LKey
      else if FSaveDir[FNameSlot][LLength] = '_' then
        FSaveDir[FNameSlot][LLength] := LKey
      else
        FSaveDir[FNameSlot] := FSaveDir[FNameSlot] + LKey;
      if FNameCursor < 19 then
        Inc(FNameCursor);
      FSaveDir[FNameSlot] := FSaveDir[FNameSlot] + '_';
    end;
  end;
  FInput.NewAscii := False;
  if not LDone then
  begin
    PrintSaveName;
    Exit;
  end;

  LLength := Length(FSaveDir[FNameSlot]);
  if (LLength > 0) and (FSaveDir[FNameSlot][LLength] = '_') then
    SetLength(FSaveDir[FNameSlot], LLength - 1);
  if LKey = #27 then
    ShowSaveDir
  else
  begin
    FDownLevel := True;
    FSaveGames.WriteDirectory(FSaveDir);
    FHost.SaveGame(FNameSlot);
  end;
  FTimeDelay := FInput.TimeCount + GREED_MENU_KEY_DELAY;
  FHook := True;
  FSavePosition := FExecuteCursor;
  MainRest;
end;

// ---------------------------------------------------------------------------------------------------------
// ShowPause
// ---------------------------------------------------------------------------------------------------------

procedure TGreedMenu.OpenPause;
begin
  if FState <> gmsClosed then
    raise EGreedException.Create(SGreedMenuBusy);
  FNested := False;
  FHook := False;
  FBackup := Copy(FCanvas.Pixels, 0, SCREEN_BYTES);
  FTimeDelay := FInput.TimeCount + GREED_MENU_KEY_DELAY;
  FWaitUntil := FInput.TimeCount + GREED_MENU_KEY_DELAY;
  FState := gmsPauseDelay;
end;

procedure TGreedMenu.StepPauseShow;
begin
  if (FInput.TimeCount >= FDropTime) and (FPanelY < 72) then
  begin
    RestoreRows(FPanelY);
    FPanelY := FPanelY + 2;
    FDropTime := FInput.TimeCount + 1;
  end;
  if FInput.TimeCount >= FAnimTime then
  begin
    FPanelAnim := (FPanelAnim + 1) and 3;
    FAnimTime := FAnimTime + 10;
  end;
  DrawMaskedPic2(106, FPanelY, Lump('pause', FPanelAnim), FBackup);
  if FInput.NewAscii then
    PauseLeave;
end;

procedure TGreedMenu.PauseLeave;
begin
  if not Animation then
    FPanelY := 200;
  FDropTime := FInput.TimeCount;
  FAnimTime := FInput.TimeCount;
  if FPanelY < 199 then
    FState := gmsPauseLeave
  else
    PauseFinish;
end;

procedure TGreedMenu.StepPauseLeave;
begin
  if FInput.TimeCount >= FDropTime then
  begin
    RestoreRows(FPanelY);
    FPanelY := FPanelY + 2;
    FDropTime := FInput.TimeCount + 1;
  end;
  if FInput.TimeCount >= FAnimTime then
  begin
    FPanelAnim := (FPanelAnim + 1) and 3;
    FAnimTime := FAnimTime + 10;
  end;
  DrawMaskedPic2(106, FPanelY, Lump('pause', FPanelAnim), FBackup);
  if FPanelY >= 199 then
    PauseFinish;
end;

procedure TGreedMenu.PauseFinish;
begin
  Move(FBackup[0], FCanvas.Pixels[0], SCREEN_BYTES);
  FBackup := nil;
  FreeLumps('pause', 4);
  FState := gmsClosed;
end;

// ---------------------------------------------------------------------------------------------------------
// the timer
// ---------------------------------------------------------------------------------------------------------

procedure TGreedMenu.Tick;
begin
  if FState = gmsClosed then
    Exit;
  FInput.TimerTick;
  Step;
end;

procedure TGreedMenu.Step;
begin
  if FState = gmsClosed then
    Exit;
  if FHook then
    MenuCommand;
  case FState of
    gmsAnimate:
      StepAnimate;
    gmsMain:
      StepMain;
    gmsQuitDelay:
      if FInput.TimeCount >= FWaitUntil then
      begin
        FInput.NewAscii := False;
        FPanelAnim := 0;
        if Animation then
          FPanelY := -66
        else
          FPanelY := 68;
        FDropTime := FInput.TimeCount;
        FAnimTime := FInput.TimeCount;
        FQuitChar := #0;
        FState := gmsQuitDrop;
      end;
    gmsQuitDrop:
      StepQuitDrop;
    gmsQuitLeave:
      StepQuitLeave;
    gmsHelp:
      StepHelp;
    gmsSaveName:
      SaveNameKey;
    gmsPauseDelay:
      if FInput.TimeCount >= FWaitUntil then
      begin
        FPanelAnim := 0;
        if Animation then
          FPanelY := -56
        else
          FPanelY := 72;
        FDropTime := FInput.TimeCount;
        FAnimTime := FInput.TimeCount;
        FInput.NewAscii := False;
        FState := gmsPauseShow;
      end;
    gmsPauseShow:
      StepPauseShow;
    gmsPauseLeave:
      StepPauseLeave;
  end;
end;

// ---------------------------------------------------------------------------------------------------------
// StartWait, UpdateWait, EndWait
// ---------------------------------------------------------------------------------------------------------

procedure TGreedMenu.StartWait;
begin
  FWaitAnim := 0;
  DrawMaskedPic2(106, 72, Lump('wait', 0), nil);
  FTimeDelay := FInput.TimeCount + GREED_MENU_KEY_DELAY;
  FWaiting := True;
end;

procedure TGreedMenu.UpdateWait;
begin
  if FInput.TimeCount > FTimeDelay then
  begin
    FWaitAnim := (FWaitAnim + 1) and 3;
    DrawMaskedPic2(106, 72, Lump('wait', FWaitAnim), nil);
    FTimeDelay := FInput.TimeCount + GREED_MENU_KEY_DELAY;
  end;
end;

procedure TGreedMenu.EndWait;
begin
  FreeLumps('wait', 4);
  FWaiting := False;
end;

end.
