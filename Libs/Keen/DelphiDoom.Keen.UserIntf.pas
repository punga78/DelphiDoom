{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the contracts of the user interface and of the    }
{  game around the levels                                                       }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.UserIntf;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.InputTypes,
  DelphiDoom.Keen.UserTypes, DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   The update array of the refresh manager as the double buffer of the menus uses it (updateptr of id_rf.c
  ///   that id_vw.c shares): a drawing marks the tiles that it touched, and the update copies them from the
  ///   buffer page to the page that is shown
  /// </summary>
  IKeenUpdateBlocks = interface
    ['{0A4E7C15-93B2-4D68-8F01-C6E5A2D7B349}']
    /// <summary>VW_MarkUpdateBlock: the tiles of a block of pixels; false if the whole block is off the screen</summary>
    function MarkUpdateBlock(AX1, AY1, AX2, AY2: Integer): Boolean;
    /// <summary>VWL_UpdateScreenBlocks: the marked tiles go from the buffer to the display and the marks are cleared</summary>
    procedure UpdateScreenBlocks;
  end;

  /// <summary>
  ///   "lasttimecount = TimeCount" of kd_play.c: the game tells the refresh manager not to count as tics of the
  ///   next frame the time that went by in a window or in a fade
  /// </summary>
  IKeenRefreshTiming = interface
    ['{D5E81C3A-4F70-4B26-9A1D-8C2B0E63F7A5}']
    procedure ResetTiming;
  end;

  /// <summary>
  ///   The double buffered drawing of id_vw.c (VWB_*), the proportional font and the cursor. The coordinates are
  ///   pixels of the port; a drawing goes to the buffer page and shows at the next UpdateScreen
  /// </summary>
  IKeenBufferedVideo = interface
    ['{5C91D3E7-2F04-4A86-B5D9-71E08C3A6F24}']
    function GetVideo: IKeenVideo;
    function GetPx: Integer;
    procedure SetPx(AValue: Integer);
    function GetPy: Integer;
    procedure SetPy(AValue: Integer);
    function GetFontColor: Integer;
    procedure SetFontColor(AValue: Integer);
    /// <summary>VW_MeasurePropString</summary>
    procedure MeasureString(const AText: AnsiString; out AWidth, AHeight: Integer);
    /// <summary>VWB_DrawPropString: the string at Px, Py, XORed in the planes of the font color</summary>
    procedure DrawString(const AText: AnsiString);
    procedure Bar(AX, AY, AWidth, AHeight, AColor: Integer);
    procedure Plot(AX, AY, AColor: Integer);
    procedure Hlin(AX1, AX2, AY, AColor: Integer);
    procedure Vlin(AY1, AY2, AX, AColor: Integer);
    procedure DrawTile8(AX, AY, ATile: Integer);
    procedure DrawTile8Masked(AX, AY, ATile: Integer);
    procedure DrawPic(AX, AY, AChunk: Integer);
    procedure DrawMaskedPic(AX, AY, AChunk: Integer);
    procedure DrawSprite(AX, AY, AChunk: Integer);
    /// <summary>VW_InitDoubleBuffer: the display starts at the page that is shown, without pel panning</summary>
    procedure InitDoubleBuffer;
    /// <summary>VW_FixRefreshBuffer: the page that is shown is copied to the buffer page</summary>
    procedure FixRefreshBuffer;
    /// <summary>VW_UpdateScreen: the cursor, the changed tiles to the display, the start of the display</summary>
    procedure UpdateScreen;
    /// <summary>VW_SetCursor: the sprite of the cursor</summary>
    procedure SetCursor(ASpriteChunk: Integer);
    procedure ShowCursor;
    procedure HideCursor;
    procedure MoveCursor(AX, AY: Integer);
    function MarkUpdateBlock(AX1, AY1, AX2, AY2: Integer): Boolean;
    /// <summary>VW_WaitVBL: waits ACount tics of the clock (a vertical blank of the EGA is a tic)</summary>
    procedure WaitVBL(ACount: Integer);
    /// <summary>What is called at the end of each UpdateScreen (the program shows the picture); nil for nothing</summary>
    procedure SetUpdateHook(const AHook: TProc);
    property Video: IKeenVideo read GetVideo;
    /// <summary>px and py: where the next string is drawn; a string moves Px on</summary>
    property Px: Integer read GetPx write SetPx;
    property Py: Integer read GetPy write SetPy;
    property FontColor: Integer read GetFontColor write SetFontColor;
  end;

  /// <summary>The palette registers of the EGA and the fades of id_vw.c</summary>
  IKeenFader = interface
    ['{B7203F6C-D418-4E95-A3C7-09F62E8B5D11}']
    /// <summary>The 16 palette registers as they are now (a color number of the EGA for each color of a pixel)</summary>
    function Registers: TKeenPaletteRegisters;
    function IsFaded: Boolean;
    procedure SetDefaultColors;
    procedure FadeOut;
    procedure FadeIn;
    procedure FadeUp;
    procedure FadeDown;
  end;

  /// <summary>The windows and the printing of the user manager (id_us.c)</summary>
  IKeenUserWindows = interface
    ['{E48A60D2-7B31-4C59-9F06-3D15C7A2E8B4}']
    function GetWindow: TKeenWindowRec;
    function GetPrintX: Integer;
    procedure SetPrintX(AValue: Integer);
    function GetPrintY: Integer;
    procedure SetPrintY(AValue: Integer);
    function GetVideo: IKeenBufferedVideo;
    /// <summary>US_Print: line feeds go to the left of the window, a line down</summary>
    procedure Print(const AText: AnsiString);
    procedure PrintUnsigned(AValue: Cardinal);
    procedure PrintSigned(AValue: Integer);
    /// <summary>USL_PrintInCenter</summary>
    procedure PrintInCenter(const AText: AnsiString; const ARect: TKeenRect);
    procedure PrintCentered(const AText: AnsiString);
    /// <summary>US_CPrintLine; a string wider than the window is an EKeenException (Quit in the C)</summary>
    procedure CPrintLine(const AText: AnsiString);
    procedure CPrint(const AText: AnsiString);
    procedure ClearWindow;
    /// <summary>US_DrawWindow: the place and the size are in characters of 8 pixels</summary>
    procedure DrawWindow(AX, AY, AWidth, AHeight: Integer);
    procedure CenterWindow(AWidth, AHeight: Integer);
    /// <summary>US_SaveWindow</summary>
    function SaveWindow: TKeenWindowRec;
    procedure RestoreWindow(const AWindow: TKeenWindowRec);
    /// <summary>Changes the window in place (the C code adds to WindowX and the like)</summary>
    procedure SetWindow(const AWindow: TKeenWindowRec);
    /// <summary>
    ///   US_LineInput: a line of text typed at (AX, AY). False if the player left with escape (ABuffer is then not
    ///   changed)
    /// </summary>
    function LineInput(AX, AY: Integer; var ABuffer: AnsiString; const ADefault: AnsiString; AEscapeOk: Boolean;
      AMaxChars, AMaxWidth: Integer): Boolean;
    property Window: TKeenWindowRec read GetWindow;
    property PrintX: Integer read GetPrintX write SetPrintX;
    property PrintY: Integer read GetPrintY write SetPrintY;
    property Video: IKeenBufferedVideo read GetVideo;
  end;

  /// <summary>The files that the game writes next to itself: the configuration and the saved games</summary>
  IKeenUserFiles = interface
    ['{2D6F1A93-C875-4B40-8E12-A9B3D047F65C}']
    /// <summary>False if the file is not there or cannot be read</summary>
    function TryRead(const AName: string; out ABytes: TBytes): Boolean;
    /// <summary>False if the file cannot be written</summary>
    function TryWrite(const AName: string; const ABytes: TBytes): Boolean;
    procedure Delete(const AName: string);
  end;

  /// <summary>ingame, abortgame, loadedgame and restartgame of id_us.c: what the game and the control panel tell each other</summary>
  IKeenUserState = interface
    ['{91C4E8B0-3A27-4D56-B60F-E7D2195C8A43}']
    function GetInGame: Boolean;
    procedure SetInGame(AValue: Boolean);
    function GetAbortGame: Boolean;
    procedure SetAbortGame(AValue: Boolean);
    function GetLoadedGame: Boolean;
    procedure SetLoadedGame(AValue: Boolean);
    function GetRestartGame: TKeenGameDiff;
    procedure SetRestartGame(AValue: TKeenGameDiff);
    property InGame: Boolean read GetInGame write SetInGame;
    property AbortGame: Boolean read GetAbortGame write SetAbortGame;
    property LoadedGame: Boolean read GetLoadedGame write SetLoadedGame;
    property RestartGame: TKeenGameDiff read GetRestartGame write SetRestartGame;
  end;

  /// <summary>US_SetLoadSaveHooks: what the game does when the control panel loads, saves or restarts</summary>
  IKeenGameHooks = interface
    ['{6E0B93D4-F15A-4C72-A8D6-40C7E2B1953F}']
    /// <summary>LoadGame of kd_demo.c: the game after the header of the file; false if the data are not good</summary>
    function LoadGame(AStream: TStream): Boolean;
    /// <summary>SaveGame of kd_demo.c</summary>
    function SaveGame(AStream: TStream): Boolean;
    /// <summary>ResetGame of kd_demo.c</summary>
    procedure ResetGame;
  end;

  /// <summary>SetupGameLevel of kd_play.c: the map of gamestate.mapon becomes the level that is played</summary>
  IKeenLevelSetup = interface
    ['{A9D3F7C1-2B64-4E08-B5A9-6F0E13C8D742}']
    function GetMap: IKeenWorkingMap;
    /// <summary>
    ///   Loads the map, gives it to the refresh manager and to the actors, patches the world map, spawns the
    ///   actors of the info plane. With ALoadNow it also fades the screen out, spawns the score box and puts the
    ///   view on the player (a saved game that is being loaded does that later)
    /// </summary>
    procedure SetupGameLevel(ALoadNow: Boolean);
    /// <summary>
    ///   fadecount = 0 and RF_SetRefreshHook(FadeAndUnhook): the screen fades in after two refreshes, when the
    ///   actors have drawn themselves on both pages
    /// </summary>
    procedure HookFadeIn;
    /// <summary>The view on the player (orgx, orgy of SetupGameLevel and GameLoop) and the limits of the sleep</summary>
    procedure CenterViewOnPlayer;
    /// <summary>The map that is played; nil before the first level</summary>
    property Map: IKeenWorkingMap read GetMap;
  end;

  /// <summary>The game of kd_demo.c and kd_play.c as the start screens see it</summary>
  IKeenGame = interface
    ['{38F6B2D5-C740-4A19-8E63-D1A57C09B4E6}']
    /// <summary>NewGame: three lives, the world map, no points</summary>
    procedure NewGame;
    /// <summary>GameLoop: the levels one after the other until the game is over, won or reset</summary>
    procedure GameLoop;
  end;

  /// <summary>The texts of the help of the control panel (GAMETEXT, CONTEXT and STORY, linked in the original program)</summary>
  IKeenHelpTexts = interface
    ['{C3A7D5F1-8E46-4B09-92D3-5F1B60E8A7C2}']
    /// <summary>The text AIndex (0 the game, 1 the controls, 2 the story); false if it is not there</summary>
    function TryGetText(AIndex: Integer; out AText: TBytes): Boolean;
  end;

  /// <summary>The scores (HighScore Scores[] of id_us.c) and their screen</summary>
  IKeenHighScores = interface
    ['{F8D21B64-0C93-4A75-B1E8-6A3F47D0C592}']
    function GetScore(AIndex: Integer): TKeenHighScore;
    procedure SetScore(AIndex: Integer; const AValue: TKeenHighScore);
    function GetDirty: Boolean;
    /// <summary>The place that a score takes in the table (the lower ones go down), -1 if it does not enter</summary>
    function Insert(AScore: Integer; ACompleted: Word): Integer;
    /// <summary>US_DisplayHighScores: AWhich -1 only shows; otherwise that line asks for a name</summary>
    procedure Display(AWhich: Integer);
    /// <summary>US_CheckHighScore</summary>
    procedure Check(AScore: Integer; ACompleted: Word);
    property Scores[AIndex: Integer]: TKeenHighScore read GetScore write SetScore;
    property Dirty: Boolean read GetDirty;
  end;

  /// <summary>The seven saved games of the control panel (Games[] of id_us.c and the files SAVEGMn.KDR)</summary>
  IKeenSaveSlots = interface
    ['{7F2C4A18-E6B0-4D93-A571-3C8E90D2B6F4}']
    function GetSlot(AIndex: Integer): TKeenSaveSlot;
    procedure SetSlot(AIndex: Integer; const AValue: TKeenSaveSlot);
    /// <summary>USL_CheckSavedGames: which files are there with a good header; the others are "Empty"</summary>
    procedure Check;
    /// <summary>
    ///   Writes the file of a slot: the header with the name of the slot and what AHooks.SaveGame writes. False,
    ///   and no file, if the disk or the game refuse
    /// </summary>
    function Save(AIndex: Integer; const AHooks: IKeenGameHooks): Boolean;
    /// <summary>
    ///   Reads the file of a slot: the header (the name of the slot becomes the one of the file) and then
    ///   AHooks.LoadGame. False, with the reason in AError, if the file is not there or not good
    /// </summary>
    function Load(AIndex: Integer; const AHooks: IKeenGameHooks; out AError: AnsiString): Boolean;
    property Slots[AIndex: Integer]: TKeenSaveSlot read GetSlot write SetSlot;
  end;

  /// <summary>US_ControlPanel</summary>
  IKeenControlPanel = interface
    ['{4B95E0A7-D362-4F18-8C5B-17A6D93E02F8}']
    /// <summary>
    ///   Runs the control panel until the player resumes, starts or loads a game. Leaving to the DOS is an
    ///   EKeenQuitException
    /// </summary>
    procedure Run;
    /// <summary>US_SetLoadSaveHooks</summary>
    procedure SetHooks(const AHooks: IKeenGameHooks);
  end;

implementation

end.
