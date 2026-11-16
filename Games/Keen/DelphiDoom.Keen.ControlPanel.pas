{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the control panel                                 }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  US_ControlPanel and its USL_* routines of id_us.c (the items, the cursor,    }
{  the help reader, the load and save buttons, the keyboard and the joystick)   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.ControlPanel;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.InputTypes,
  DelphiDoom.Keen.UserTypes, DelphiDoom.Keen.Intf, DelphiDoom.Keen.UserIntf;

type
  /// <summary>
  ///   The control panel of the game: six buttons on the left (start, help, disk, controls, sound, music), a row
  ///   of buttons on the top for the one that is chosen and, under it, what the button of the row needs (the
  ///   difficulty, the saved games, the key caps...). A cursor moves with the mouse, the joystick or the arrow
  ///   keys (which jump to the nearest button); return or a button of the mouse hits the button under it.
  ///   The lists of the buttons are data, as in the C: each has a rectangle, two pictures, a help line, a hot
  ///   key, its state and the number of the routine that draws it or takes the hit
  /// </summary>
  TKeenControlPanel = class(TInterfacedObject, IKeenControlPanel)
  strict private
    type
      TUIType = (uiiButton, uiiRadioButton, uiiCheckBox, uiiKeyCap);
      TUserCall = (uicDraw, uicHit);
      TCustom = (ccNone, ccCtlButton, ccP, ccPS, ccPR, ccH, ccD, ccDE, ccDL, ccDS, ccS, ccC, ccCKbd, ccCJoy);
      TList = (plNone, plCtl, plP, plPS, plPR, plH, plD, plDLS, plDE, plC, plCKbd, plCJoy, plS, plSSS, plM);
      TUserItem = record
        R: TKeenRect;
        Kind: TUIType;
        PicUp: Integer;
        PicDown: Integer;
        Help: AnsiString;
        Key: Byte;
        Sel: Word;
        Custom: TCustom;
        Text: AnsiString;
        HasText: Boolean;
      end;
    const
      UI_NORMAL = 0;
      UI_SELECTED = 1;
      UI_DISABLED = 2;
      SC_C = $2E;
      SC_Q = $10;
      // CtlPanels2: the list of the top row for each button of the left column
      PANELS2: array[0..5] of TList = (plP, plH, plD, plC, plS, plM);
  strict private
    FWindows: IKeenUserWindows;
    FVideo: IKeenBufferedVideo;
    FInput: IKeenInput;
    FClock: IKeenClock;
    FSound: IKeenSoundManager;
    FState: IKeenUserState;
    FSlots: IKeenSaveSlots;
    FHelp: IKeenHelpTexts;
    FJoysticks: IKeenJoysticks;
    FHooks: IKeenGameHooks;
    FLists: array[TList] of TArray<TUserItem>;
    FTheItems: array[0..3] of TList;
    FCtlPanelButton: Integer;
    FGameIsDirty: Boolean;
    FQuitToDos: Boolean;
    FResumeGame: Boolean;
    FFlushHelp: Boolean;
    FHelpWindow: TKeenWindowRec;
    FBottomWindow: TKeenWindowRec;
    FButton0: Boolean;
    FButton1: Boolean;
    FCursorBad: Boolean;
    FCursorX: Integer;
    FCursorY: Integer;
    FTextBytes: TBytes;
    FLineOffsets: TArray<Integer>;
    procedure BuildLists;
    procedure Add(AList: TList; const ARect: TKeenRect; AKind: TUIType; APicUp, APicDown: Integer;
      const AHelp: AnsiString; AKey: Byte; ACustom: TCustom); overload;
    procedure Add(AList: TList; const ARect: TKeenRect; AKind: TUIType; APicUp, APicDown: Integer;
      const AHelp: AnsiString; const AText: AnsiString); overload;
    function Count(AList: TList): Integer;
    function GetKey(AIndex: Integer): Byte;
    procedure SetKey(AIndex: Integer; AScan: Byte);
    procedure StartCursor;
    function UpdateCursor: Boolean;
    procedure TurnOff(AList: TList);
    function FindDown(AList: TList): Integer;
    procedure ShowHelp(const AText: AnsiString);
    procedure HandleError(const AMessage: AnsiString);
    procedure DrawList(AGroup: Integer);
    procedure DrawItem(AGroup, ANumber: Integer);
    procedure DoHit(AGroup, ANumber: Integer);
    function IsInRect(AX, AY: Integer; out AGroup, ANumber: Integer): Boolean;
    function TrackItem(AGroup, ANumber: Integer): Boolean;
    procedure GlideCursor(ANewX, ANewY: Integer);
    procedure FindRect(const ARect: TKeenRect; AXDir, AYDir: Integer);
    function CallCustom(ACustom: TCustom; ACall: TUserCall; AGroup, ANumber: Integer): Boolean;
    function CtlButtonCustom(ACall: TUserCall; AGroup, ANumber: Integer): Boolean;
    function CtlCKbdButtonCustom(ACall: TUserCall; AGroup, ANumber: Integer): Boolean;
    function CtlCJoyButtonCustom(ACall: TUserCall): Boolean;
    procedure ClearBottom;
    function FormatHelp: Integer;
    function HelpLine(AOffset: Integer): AnsiString;
    procedure DrawHelp(AStart, AEnd, ALine, AHeight: Integer);
    procedure DoHelp(const AText: TBytes);
    function CtlHButtonCustom(ACall: TUserCall; AGroup, ANumber: Integer): Boolean;
    function CtlDButtonCustom(ACall: TUserCall; AGroup, ANumber: Integer): Boolean;
    function DLSRect(AList: TList; ANumber: Integer): TKeenRect;
    function CtlDLButtonCustom(ACall: TUserCall; AGroup, ANumber: Integer): Boolean;
    function CtlDSButtonCustom(ACall: TUserCall; AGroup, ANumber: Integer): Boolean;
    function CtlSButtonCustom(ACall: TUserCall; AGroup, ANumber: Integer): Boolean;
    function CtlPButtonCustom(ACall: TUserCall; AGroup, ANumber: Integer): Boolean;
    procedure GiveAbortWarning;
    function CtlPSButtonCustom(ACall: TUserCall; ANumber: Integer): Boolean;
    function CtlCButtonCustom(ACall: TUserCall; AGroup, ANumber: Integer): Boolean;
    procedure HitHotKey(AGroup: Integer);
    function CheckScan: Boolean;
    procedure SetUpCtlPanel;
    procedure TearDownCtlPanel;
    procedure WaitTics(AStart, ATics: Integer);
  public
    /// <param name="AWindows">The windows and the font</param>
    /// <param name="AInput">The keyboard, the mouse and the joysticks</param>
    /// <param name="AClock">TimeCount; a loop that waits calls its Idle</param>
    /// <param name="ASound">The sound mode that the sound buttons show and set</param>
    /// <param name="AState">ingame, loadedgame, abortgame, restartgame</param>
    /// <param name="ASlots">The saved games</param>
    /// <param name="AHelp">The texts of the help; nil if the game has none</param>
    /// <param name="AJoysticks">The joysticks for the calibration; nil if there are none</param>
    constructor Create(const AWindows: IKeenUserWindows; const AInput: IKeenInput; const AClock: IKeenClock;
      const ASound: IKeenSoundManager; const AState: IKeenUserState; const ASlots: IKeenSaveSlots;
      const AHelp: IKeenHelpTexts; const AJoysticks: IKeenJoysticks);
    procedure Run;
    procedure SetHooks(const AHooks: IKeenGameHooks);
  end;

implementation

uses
  DelphiDoom.Keen.GraphicsIds, DelphiDoom.Keen.ScanTables;

const
  CTL_PANEL_X = 8;
  CTL_PANEL_Y = 4;
  CTL_PANEL2_X = 8 * 8;
  CTL_PANEL2_Y = 2 * 8;
  CTL_PANEL3_X = 8 * 8;
  CTL_PANEL3_Y = 7 * 8;
  /// <summary>The bytes of a help text that the C copies (the texts are shorter and end with a tilde)</summary>
  HELP_TEXT_BYTES = 5600;

function CtlPanelR(ANumber: Integer): TKeenRect;
begin
  Result := TKeenRect.Make(CTL_PANEL_X, CTL_PANEL_Y + 32 * ANumber, CTL_PANEL_X + 40, CTL_PANEL_Y + 32 * ANumber + 32);
end;

function CtlPanel2R(AX, AY: Integer): TKeenRect;
begin
  Result := TKeenRect.Make(CTL_PANEL2_X + AX * 8, CTL_PANEL2_Y + AY * 8, CTL_PANEL2_X + 32 + AX * 8,
    CTL_PANEL2_Y + 24 + AY * 8);
end;

function CtlPanel3R(AX, AY, AWidth, AHeight: Integer): TKeenRect;
begin
  Result := TKeenRect.Make(CTL_PANEL3_X + AX * 8, CTL_PANEL3_Y + AY * 8, CTL_PANEL3_X + AWidth + AX * 8,
    CTL_PANEL3_Y + AHeight + AY * 8);
end;

{ TKeenControlPanel }

constructor TKeenControlPanel.Create(const AWindows: IKeenUserWindows; const AInput: IKeenInput;
  const AClock: IKeenClock; const ASound: IKeenSoundManager; const AState: IKeenUserState;
  const ASlots: IKeenSaveSlots; const AHelp: IKeenHelpTexts; const AJoysticks: IKeenJoysticks);
begin
  inherited Create;
  if not Assigned(AWindows) then
    raise EArgumentNilException.Create('AWindows');
  if not Assigned(AInput) then
    raise EArgumentNilException.Create('AInput');
  if not Assigned(AClock) then
    raise EArgumentNilException.Create('AClock');
  if not Assigned(ASound) then
    raise EArgumentNilException.Create('ASound');
  if not Assigned(AState) then
    raise EArgumentNilException.Create('AState');
  if not Assigned(ASlots) then
    raise EArgumentNilException.Create('ASlots');
  FWindows := AWindows;
  FVideo := AWindows.Video;
  FInput := AInput;
  FClock := AClock;
  FSound := ASound;
  FState := AState;
  FSlots := ASlots;
  FHelp := AHelp;
  FJoysticks := AJoysticks;
  FCtlPanelButton := -1;
  BuildLists;
end;

procedure TKeenControlPanel.SetHooks(const AHooks: IKeenGameHooks);
begin
  FHooks := AHooks;
end;

procedure TKeenControlPanel.Add(AList: TList; const ARect: TKeenRect; AKind: TUIType; APicUp, APicDown: Integer;
  const AHelp: AnsiString; AKey: Byte; ACustom: TCustom);
var
  LItem: TUserItem;
begin
  LItem := Default(TUserItem);
  LItem.R := ARect;
  LItem.Kind := AKind;
  LItem.PicUp := APicUp;
  LItem.PicDown := APicDown;
  LItem.Help := AHelp;
  LItem.Key := AKey;
  LItem.Sel := UI_NORMAL;
  LItem.Custom := ACustom;
  SetLength(FLists[AList], Length(FLists[AList]) + 1);
  FLists[AList][High(FLists[AList])] := LItem;
end;

procedure TKeenControlPanel.Add(AList: TList; const ARect: TKeenRect; AKind: TUIType; APicUp, APicDown: Integer;
  const AHelp: AnsiString; const AText: AnsiString);
begin
  Add(AList, ARect, AKind, APicUp, APicDown, AHelp, KEEN_SC_NONE, ccNone);
  FLists[AList][High(FLists[AList])].Text := AText;
  FLists[AList][High(FLists[AList])].HasText := True;
end;

procedure TKeenControlPanel.BuildLists;
const
  KEY_HELPS: array[0..9] of AnsiString = ('Define Key for Jumping', 'Define Key for Throwing',
    'Define Key to move Up & Left', 'Define Key to move Up', 'Define Key to move Up & Right',
    'Define Key to move Left', 'Define Key to move Right', 'Define Key to move Down & Left',
    'Define Key to move Down', 'Define Key to move Down & Right');
  KEY_X: array[0..9] of Integer = (1, 1, 8, 15, 22, 8, 22, 8, 15, 22);
  KEY_Y: array[0..9] of Integer = (2, 6, 0, 0, 0, 4, 4, 8, 8, 8);
var
  LIndex: Integer;
begin
  Add(plCtl, CtlPanelR(0), uiiRadioButton, KEEN_GFX_CTL_STARTUPPIC, KEEN_GFX_CTL_STARTDNPIC,
    'Start or Resume a Game', KEEN_SC_NONE, ccCtlButton);
  Add(plCtl, CtlPanelR(1), uiiRadioButton, KEEN_GFX_CTL_HELPUPPIC, KEEN_GFX_CTL_HELPDNPIC,
    'Get Help With Commander Keen', KEEN_SC_NONE, ccCtlButton);
  Add(plCtl, CtlPanelR(2), uiiRadioButton, KEEN_GFX_CTL_DISKUPPIC, KEEN_GFX_CTL_DISKDNPIC,
    'Load / Save / Quit', KEEN_SC_NONE, ccCtlButton);
  Add(plCtl, CtlPanelR(3), uiiRadioButton, KEEN_GFX_CTL_CONTROLSUPPIC, KEEN_GFX_CTL_CONTROLSDNPIC,
    'Choose Controls', SC_C, ccCtlButton);
  Add(plCtl, CtlPanelR(4), uiiRadioButton, KEEN_GFX_CTL_SOUNDUPPIC, KEEN_GFX_CTL_SOUNDDNPIC,
    'Select Sound Device', KEEN_SC_F2, ccCtlButton);
  Add(plCtl, CtlPanelR(5), uiiRadioButton, KEEN_GFX_CTL_MUSICUPPIC, KEEN_GFX_CTL_MUSICDNPIC,
    'Turn Music On / Off', KEEN_SC_F7, ccCtlButton);

  Add(plP, CtlPanel2R(10, 0), uiiRadioButton, KEEN_GFX_CTL_P_NEWGAMEUPPIC, KEEN_GFX_CTL_P_NEWGAMEDNPIC,
    'Choose Difficulty for the New Game', KEEN_SC_F5, ccP);
  Add(plP, CtlPanel2R(15, 0), uiiRadioButton, KEEN_GFX_CTL_P_RESUMEUPPIC, KEEN_GFX_CTL_P_RESUMEDNPIC,
    'Go Back to Current Game', KEEN_SC_NONE, ccP);

  Add(plPS, CtlPanel3R(13, 5, 32, 24), uiiButton, KEEN_GFX_CTL_P_MEDUPPIC, KEEN_GFX_CTL_P_MEDDNPIC,
    'Start New Game in Normal Mode', KEEN_SC_NONE, ccPS);
  Add(plPS, CtlPanel3R(8, 5, 32, 24), uiiButton, KEEN_GFX_CTL_P_EASYUPPIC, KEEN_GFX_CTL_P_EASYDNPIC,
    'Start New Game in Easy Mode', KEEN_SC_NONE, ccPS);
  Add(plPS, CtlPanel3R(18, 5, 32, 24), uiiButton, KEEN_GFX_CTL_P_HARDUPPIC, KEEN_GFX_CTL_P_HARDDNPIC,
    'Start New Game in Hard Mode', KEEN_SC_NONE, ccPS);

  Add(plPR, CtlPanel3R(13, 5, 32, 24), uiiButton, KEEN_GFX_CTL_P_GORESUMEUPPIC, KEEN_GFX_CTL_P_GORESUMEDNPIC,
    'Resume Current Game', KEEN_SC_NONE, ccPR);

  Add(plH, CtlPanel2R(8, 0), uiiButton, KEEN_GFX_CTL_H_LOSTUPPIC, KEEN_GFX_CTL_H_LOSTDNPIC,
    'Help Me, I''m Lost!', KEEN_SC_F1, ccH);
  Add(plH, CtlPanel2R(13, 0), uiiButton, KEEN_GFX_CTL_H_CTRLUPPIC, KEEN_GFX_CTL_H_CTRLDNPIC,
    'Get Help with Controls', KEEN_SC_NONE, ccH);
  Add(plH, CtlPanel2R(18, 0), uiiButton, KEEN_GFX_CTL_H_STORYUPPIC, KEEN_GFX_CTL_H_STORYDNPIC,
    'Read Story & Game Tips', KEEN_SC_NONE, ccH);

  Add(plD, CtlPanel2R(9, 0), uiiRadioButton, KEEN_GFX_CTL_D_LSGAMEUPPIC, KEEN_GFX_CTL_D_LSGAMEDNPIC,
    'Load or Save a Game', KEEN_SC_F6, ccD);
  Add(plD, CtlPanel2R(15, 0), uiiRadioButton, KEEN_GFX_CTL_D_DOSUPPIC, KEEN_GFX_CTL_D_DOSDNPIC,
    'Exit to DOS', SC_Q, ccD);

  for LIndex := 0 to KEEN_MAX_SAVE_GAMES - 1 do
  begin
    Add(plDLS, CtlPanel3R(1, LIndex * 2, 32, 16), uiiButton, KEEN_GFX_CTL_D_LOADUPPIC, KEEN_GFX_CTL_D_LOADDNPIC,
      'Load This Game', KEEN_SC_NONE, ccDL);
    Add(plDLS, CtlPanel3R(6, LIndex * 2, 32, 16), uiiButton, KEEN_GFX_CTL_D_SAVEUPPIC, KEEN_GFX_CTL_D_SAVEDNPIC,
      'Save Current Game Here', KEEN_SC_NONE, ccDS);
  end;

  Add(plDE, CtlPanel3R(12, 5, 40, 24), uiiButton, KEEN_GFX_CTL_D_EXITUPPIC, KEEN_GFX_CTL_D_EXITDNPIC,
    'Really Exit to DOS', KEEN_SC_NONE, ccDE);

  Add(plC, CtlPanel2R(8, 0), uiiRadioButton, KEEN_GFX_CTL_C_KBDUPPIC, KEEN_GFX_CTL_C_KBDDNPIC,
    'Use / Configure Keyboard', KEEN_SC_F3, ccC);
  Add(plC, CtlPanel2R(13, 0), uiiRadioButton, KEEN_GFX_CTL_C_JOY1UPPIC, KEEN_GFX_CTL_C_JOY1DNPIC,
    'Use / Configure Joystick 1', KEEN_SC_NONE, ccC);
  Add(plC, CtlPanel2R(18, 0), uiiRadioButton, KEEN_GFX_CTL_C_JOY2UPPIC, KEEN_GFX_CTL_C_JOY2DNPIC,
    'Use / Configure Joystick 2', KEEN_SC_NONE, ccC);

  for LIndex := 0 to 9 do
    Add(plCKbd, CtlPanel3R(KEY_X[LIndex], KEY_Y[LIndex], 56, 32), uiiKeyCap, KEEN_GFX_CTL_KEYCAPPIC,
      KEEN_GFX_CTL_KEYCAPCURPIC, KEY_HELPS[LIndex], KEEN_SC_NONE, ccCKbd);

  Add(plCJoy, CtlPanel3R(13, 5, 32, 24), uiiButton, KEEN_GFX_CTL_C_CALIBRATEUPPIC, KEEN_GFX_CTL_C_CALIBRATEDNPIC,
    'Configure Joystick', KEEN_SC_NONE, ccCJoy);

  Add(plS, CtlPanel2R(3, 0), uiiRadioButton, KEEN_GFX_CTL_S_NOSNDUPPIC, KEEN_GFX_CTL_S_NOSNDDNPIC,
    'Turn Sound Off', KEEN_SC_NONE, ccS);
  Add(plS, CtlPanel2R(8, 0), uiiRadioButton, KEEN_GFX_CTL_S_PCSNDUPPIC, KEEN_GFX_CTL_S_PCSNDDNPIC,
    'Use PC Speaker', KEEN_SC_NONE, ccS);
  Add(plS, CtlPanel2R(13, 0), uiiRadioButton, KEEN_GFX_CTL_S_ADLIBUPPIC, KEEN_GFX_CTL_S_ADLIBDNPIC,
    'Use AdLib Sound Effects', KEEN_SC_NONE, ccS);
  Add(plS, CtlPanel2R(18, 0), uiiRadioButton, KEEN_GFX_CTL_S_SNDBLUPPIC, KEEN_GFX_CTL_S_SNDBLDNPIC,
    'Use SoundBlaster Sound Effects', KEEN_SC_NONE, ccS);
  Add(plS, CtlPanel2R(23, 0), uiiRadioButton, KEEN_GFX_CTL_S_SNDSRCUPPIC, KEEN_GFX_CTL_S_SNDSRCDNPIC,
    'Use Sound Source Sound Effects', KEEN_SC_NONE, ccS);

  Add(plSSS, CtlPanel3R(7, 2, 32, 24), uiiCheckBox, KEEN_GFX_CTL_CHECKUPPIC, KEEN_GFX_CTL_CHECKDNPIC,
    'Turn Tandy Mode On / Off', 'Tandy Mode');
  Add(plSSS, CtlPanel3R(7, 6, 32, 24), uiiCheckBox, KEEN_GFX_CTL_CHECKUPPIC, KEEN_GFX_CTL_CHECKDNPIC,
    'Switch between LPT1 & LPT2', 'Use LPT2');

  // the music buttons use the pictures of the AdLib sound button (CTL_M_ADLIB* are defined as CTL_S_ADLIB*)
  Add(plM, CtlPanel2R(9, 0), uiiRadioButton, KEEN_GFX_CTL_M_NOMUSUPPIC, KEEN_GFX_CTL_M_NOMUSDNPIC,
    'Background Music Off', KEEN_SC_NONE, ccNone);
  Add(plM, CtlPanel2R(15, 0), uiiRadioButton, KEEN_GFX_CTL_S_ADLIBUPPIC, KEEN_GFX_CTL_S_ADLIBDNPIC,
    'Use AdLib/SoundBlaster Music', KEEN_SC_NONE, ccNone);

  FTheItems[0] := plCtl;
  FTheItems[1] := plNone;
  FTheItems[2] := plNone;
  FTheItems[3] := plNone;
end;

function TKeenControlPanel.Count(AList: TList): Integer;
begin
  Result := Length(FLists[AList]);
end;

function TKeenControlPanel.GetKey(AIndex: Integer): Byte;
var
  LDef: TKeenKeyboardDef;
begin
  LDef := FInput.KeyboardDefs[0];
  case AIndex of
    0: Result := LDef.Button0;
    1: Result := LDef.Button1;
    2: Result := LDef.UpLeft;
    3: Result := LDef.Up;
    4: Result := LDef.UpRight;
    5: Result := LDef.Left;
    6: Result := LDef.Right;
    7: Result := LDef.DownLeft;
    8: Result := LDef.Down;
  else
    Result := LDef.DownRight;
  end;
end;

procedure TKeenControlPanel.SetKey(AIndex: Integer; AScan: Byte);
var
  LDef: TKeenKeyboardDef;
begin
  LDef := FInput.KeyboardDefs[0];
  case AIndex of
    0: LDef.Button0 := AScan;
    1: LDef.Button1 := AScan;
    2: LDef.UpLeft := AScan;
    3: LDef.Up := AScan;
    4: LDef.UpRight := AScan;
    5: LDef.Left := AScan;
    6: LDef.Right := AScan;
    7: LDef.DownLeft := AScan;
    8: LDef.Down := AScan;
  else
    LDef.DownRight := AScan;
  end;
  FInput.KeyboardDefs[0] := LDef;
end;

procedure TKeenControlPanel.WaitTics(AStart, ATics: Integer);
begin
  while FClock.TimeCount - AStart < ATics do
    FClock.Idle;
end;

procedure TKeenControlPanel.StartCursor;
begin
  FVideo.SetCursor(KEEN_GFX_CURSORARROWSPR);
  FCursorX := KEEN_MAX_X div 2;
  FCursorY := KEEN_MAX_Y div 2;
  FVideo.MoveCursor(FCursorX, FCursorY);
  FVideo.ShowCursor;
  // dispose of any movement that the devices gathered
  FInput.ReadCursor;
end;

function TKeenControlPanel.UpdateCursor: Boolean;
var
  LInfo: TKeenControlInfo;
begin
  LInfo := FInput.ReadCursor;
  if (LInfo.X <> 0) or (LInfo.Y <> 0) or FCursorBad then
  begin
    Inc(FCursorX, LInfo.X);
    if FCursorX >= KEEN_MAX_X then
      FCursorX := KEEN_MAX_X - 1
    else if FCursorX < 0 then
      FCursorX := 0;
    Inc(FCursorY, LInfo.Y);
    if FCursorY >= KEEN_MAX_Y then
      FCursorY := KEEN_MAX_Y - 1
    else if FCursorY < 0 then
      FCursorY := 0;
    FVideo.MoveCursor(FCursorX, FCursorY);
    FCursorBad := False;
  end;
  FButton0 := LInfo.Button0;
  FButton1 := LInfo.Button1;
  Result := FButton0 or FButton1;
end;

procedure TKeenControlPanel.TurnOff(AList: TList);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FLists[AList]) do
    FLists[AList][LIndex].Sel := UI_NORMAL;
end;

function TKeenControlPanel.FindDown(AList: TList): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FLists[AList]) do
    if (FLists[AList][LIndex].Sel and UI_SELECTED) <> 0 then
      Exit(LIndex);
  Result := -1;
end;

procedure TKeenControlPanel.ShowHelp(const AText: AnsiString);
var
  LSaved: TKeenWindowRec;
begin
  LSaved := FWindows.SaveWindow;
  FWindows.RestoreWindow(FHelpWindow);
  FWindows.ClearWindow;
  FWindows.PrintCentered(AText);
  FWindows.RestoreWindow(LSaved);
end;

procedure TKeenControlPanel.HandleError(const AMessage: AnsiString);
begin
  FVideo.HideCursor;
  FVideo.FontColor := KEEN_F_SECONDCOLOR;
  ShowHelp('Error: ' + AMessage);
  FVideo.FontColor := KEEN_F_BLACK;
  FVideo.UpdateScreen;
  FInput.ClearKeysDown;
  FInput.Ack;
  FVideo.ShowCursor;
  FVideo.UpdateScreen;
end;

procedure TKeenControlPanel.DrawList(AGroup: Integer);
var
  LIndex: Integer;
begin
  if FTheItems[AGroup] = plNone then
    Exit;
  for LIndex := 0 to Count(FTheItems[AGroup]) - 1 do
    DrawItem(AGroup, LIndex);
end;

procedure TKeenControlPanel.DrawItem(AGroup, ANumber: Integer);
var
  LList: TList;
  LItem: TUserItem;
  LHandled: Boolean;
  LText: AnsiString;
  LHasText: Boolean;
  LCentered: Boolean;
  LWidth: Integer;
  LHeight: Integer;
  LPicture: Integer;
begin
  LList := FTheItems[AGroup];
  LItem := FLists[LList][ANumber];
  LHandled := CallCustom(LItem.Custom, uicDraw, AGroup, ANumber);
  if LHandled then
    Exit;
  LItem := FLists[LList][ANumber];
  LText := '';
  LHasText := False;
  LCentered := False;
  case LItem.Kind of
    uiiCheckBox:
      begin
        FVideo.Px := LItem.R.LR.X + 8;
        FVideo.Py := LItem.R.UL.Y + 8;
        LText := LItem.Text;
        LHasText := LItem.HasText;
      end;
    uiiKeyCap:
      if (LItem.Sel and UI_SELECTED) = 0 then
      begin
        LText := LItem.Text;
        LHasText := LItem.HasText;
        LCentered := LHasText;
      end;
  end;
  if (LItem.Sel and UI_SELECTED) <> 0 then
    LPicture := LItem.PicDown
  else
    LPicture := LItem.PicUp;
  FVideo.DrawPic(LItem.R.UL.X, LItem.R.UL.Y, LPicture);
  if LHasText then
  begin
    if LCentered then
      FWindows.PrintInCenter(LText, LItem.R)
    else
    begin
      FVideo.MeasureString(LText, LWidth, LHeight);
      FVideo.Bar(FVideo.Px, FVideo.Py, LWidth + 7, LHeight, KEEN_WHITE);
      FVideo.DrawString(LText);
    end;
  end;
  if (LItem.Sel and UI_DISABLED) <> 0 then
  begin
    if (LItem.PicUp = KEEN_GFX_CTL_D_LOADUPPIC) or (LItem.PicUp = KEEN_GFX_CTL_D_SAVEUPPIC) then
      FVideo.DrawMaskedPic(LItem.R.UL.X, LItem.R.UL.Y, KEEN_GFX_CTL_LSMASKPICM)
    else
      FVideo.DrawMaskedPic(LItem.R.UL.X, LItem.R.UL.Y, KEEN_GFX_CTL_LITTLEMASKPICM);
  end;
end;

procedure TKeenControlPanel.DoHit(AGroup, ANumber: Integer);
var
  LList: TList;
  LHandled: Boolean;
  LIndex: Integer;
begin
  LList := FTheItems[AGroup];
  LHandled := CallCustom(FLists[LList][ANumber].Custom, uicHit, AGroup, ANumber);
  if LHandled then
    Exit;
  // a custom routine can change the lists under this group, not the list of the group itself
  if (FLists[LList][ANumber].Sel and UI_DISABLED) <> 0 then
  begin
    FVideo.FontColor := KEEN_F_SECONDCOLOR;
    ShowHelp('This Item is Disabled');
    FVideo.FontColor := KEEN_F_BLACK;
    Exit;
  end;
  FFlushHelp := True;
  case FLists[LList][ANumber].Kind of
    uiiButton:
      begin
        // must have a custom routine to handle the hit: this only redraws, and the C falls through to the
        // check box, so the button is toggled and drawn twice
        FLists[LList][ANumber].Sel := FLists[LList][ANumber].Sel xor UI_SELECTED;
        DrawItem(AGroup, ANumber);
        FLists[LList][ANumber].Sel := FLists[LList][ANumber].Sel xor UI_SELECTED;
        DrawItem(AGroup, ANumber);
      end;
    uiiCheckBox:
      begin
        FLists[LList][ANumber].Sel := FLists[LList][ANumber].Sel xor UI_SELECTED;
        DrawItem(AGroup, ANumber);
      end;
    uiiRadioButton:
      begin
        for LIndex := 0 to High(FLists[LList]) do
          if (LIndex <> ANumber) and (FLists[LList][LIndex].Kind = uiiRadioButton) and
            ((FLists[LList][LIndex].Sel and UI_SELECTED) <> 0) then
          begin
            FLists[LList][LIndex].Sel := FLists[LList][LIndex].Sel and not UI_SELECTED;
            DrawItem(AGroup, LIndex);
          end;
        FLists[LList][ANumber].Sel := FLists[LList][ANumber].Sel or UI_SELECTED;
        DrawItem(AGroup, ANumber);
      end;
  end;
end;

function TKeenControlPanel.IsInRect(AX, AY: Integer; out AGroup, ANumber: Integer): Boolean;
var
  LGroup: Integer;
  LNumber: Integer;
  LItem: TUserItem;
begin
  // the C stops at the first group that is nil and leaves the number of the last item it looked at
  AGroup := 0;
  ANumber := 0;
  for LGroup := 0 to High(FTheItems) do
  begin
    if FTheItems[LGroup] = plNone then
      Break;
    AGroup := LGroup;
    ANumber := 0;
    for LNumber := 0 to Count(FTheItems[LGroup]) - 1 do
    begin
      LItem := FLists[FTheItems[LGroup]][LNumber];
      ANumber := LNumber;
      if (AX >= LItem.R.UL.X) and (AX < LItem.R.LR.X) and (AY >= LItem.R.UL.Y) and (AY < LItem.R.LR.Y) then
        Exit(True);
    end;
    ANumber := Count(FTheItems[LGroup]);
    AGroup := LGroup + 1;
  end;
  Result := False;
end;

function TKeenControlPanel.TrackItem(AGroup, ANumber: Integer): Boolean;
var
  LList: TList;
  LInside: Boolean;
  LLast: Boolean;
  LInGroup: Integer;
  LInNumber: Integer;
  LOther: Integer;
  LSel: Word;
  LOtherSel: Word;
  LIndex: Integer;
begin
  LList := FTheItems[AGroup];
  LSel := FLists[LList][ANumber].Sel;
  LOther := -1;
  LOtherSel := 0;
  if FLists[LList][ANumber].Kind = uiiRadioButton then
  begin
    // the radio button of the list that is down now; if none, the item itself
    LOther := ANumber;
    for LIndex := 0 to High(FLists[LList]) do
      if (FLists[LList][LIndex].Sel and UI_SELECTED) <> 0 then
      begin
        LOther := LIndex;
        Break;
      end;
    LOtherSel := FLists[LList][LOther].Sel;
  end;
  if (FLists[LList][ANumber].Sel and UI_DISABLED) <> 0 then
  begin
    FVideo.FontColor := KEEN_F_SECONDCOLOR;
    ShowHelp('This item is disabled');
    FVideo.FontColor := KEEN_F_BLACK;
    while UpdateCursor do
      FVideo.UpdateScreen;
    FFlushHelp := True;
    Exit(False);
  end;
  LLast := False;
  repeat
    IsInRect(FCursorX, FCursorY, LInGroup, LInNumber);
    LInside := (LInGroup = AGroup) and (LInNumber = ANumber);
    if LInside <> LLast then
    begin
      if LInside then
      begin
        if LOther >= 0 then
        begin
          FLists[LList][LOther].Sel := FLists[LList][LOther].Sel and not UI_SELECTED;
          FLists[LList][ANumber].Sel := FLists[LList][ANumber].Sel or UI_SELECTED;
        end
        else
          FLists[LList][ANumber].Sel := LSel xor UI_SELECTED;
      end
      else
      begin
        if (LOther >= 0) and (LOther <> ANumber) then
        begin
          FLists[LList][LOther].Sel := FLists[LList][LOther].Sel or UI_SELECTED;
          FLists[LList][ANumber].Sel := FLists[LList][ANumber].Sel and not UI_SELECTED;
        end
        else
          FLists[LList][ANumber].Sel := LSel;
      end;
      DrawItem(AGroup, ANumber);
      if (LOther >= 0) and (LOther <> ANumber) then
        DrawItem(AGroup, LOther);
      LLast := LInside;
    end;
    FVideo.UpdateScreen;
  until not UpdateCursor;
  if LOther >= 0 then
    FLists[LList][LOther].Sel := LOtherSel;
  FLists[LList][ANumber].Sel := LSel;
  if not LInside then
  begin
    if (LOther >= 0) and (LOther <> ANumber) then
      DrawItem(AGroup, LOther);
    DrawItem(AGroup, ANumber);
    FVideo.UpdateScreen;
  end;
  Result := LInside;
end;

procedure TKeenControlPanel.GlideCursor(ANewX, ANewY: Integer);
const
  STEPS = 8;
var
  LX: Int64;
  LY: Int64;
  LDX: Int64;
  LDY: Int64;
  LStep: Integer;
begin
  // 16.16 fixed point, in 8 steps. The C goes on until the cursor is on the place and a division that is not
  // exact never gets there: after the steps the cursor is put on the place
  LX := Int64(FCursorX) shl 16;
  LDX := ((Int64(ANewX) shl 16) - LX) div STEPS;
  LY := Int64(FCursorY) shl 16;
  LDY := ((Int64(ANewY) shl 16) - LY) div STEPS;
  LStep := 0;
  while ((FCursorX <> ANewX) or (FCursorY <> ANewY)) and (LStep < STEPS) do
  begin
    Inc(LX, LDX);
    Inc(LY, LDY);
    FCursorX := Integer(LX shr 16);
    FCursorY := Integer(LY shr 16);
    Inc(LStep);
    if LStep = STEPS then
    begin
      FCursorX := ANewX;
      FCursorY := ANewY;
    end;
    FVideo.MoveCursor(FCursorX, FCursorY);
    FVideo.UpdateScreen;
  end;
  FCursorBad := True;
end;

procedure TKeenControlPanel.FindRect(const ARect: TKeenRect; AXDir, AYDir: Integer);
var
  LGoods: array[0..8] of Boolean;
  LGoodRects: array[0..8] of TKeenRect;
  LDiffs: array[0..8] of TKeenPoint;
  LDiff: TKeenPoint;
  LGroup: Integer;
  LNumber: Integer;
  LRect: TKeenRect;
  LIndex: Integer;
  LFirst: Integer;
  LSecond: Integer;
  LThird: Integer;
  LGood: TKeenRect;

  procedure Take(AOctant: Integer);
  begin
    LGoods[AOctant] := True;
    LGoodRects[AOctant] := LRect;
    LDiffs[AOctant] := LDiff;
  end;

begin
  // the nine octants around the rectangle: 0 1 2 / 3 4 5 / 6 7 8
  LIndex := 0;
  for LGroup := -1 to 1 do
    for LNumber := -1 to 1 do
    begin
      LDiffs[LIndex].X := LNumber * 1024;
      LDiffs[LIndex].Y := LGroup * 1024;
      LGoods[LIndex] := False;
      Inc(LIndex);
    end;
  // in which octant each of the other rectangles is
  for LGroup := 0 to High(FTheItems) do
  begin
    if FTheItems[LGroup] = plNone then
      Break;
    for LNumber := 0 to Count(FTheItems[LGroup]) - 1 do
    begin
      LRect := FLists[FTheItems[LGroup]][LNumber].R;
      LDiff.X := LRect.UL.X - ARect.UL.X;
      LDiff.Y := LRect.UL.Y - ARect.UL.Y;
      if (LDiff.X = 0) and (LDiff.Y = 0) then
        Continue;
      // 1, 4, 7
      if ((LRect.UL.X >= ARect.UL.X) and (LRect.UL.X < ARect.LR.X)) or
        ((LRect.LR.X > ARect.UL.X) and (LRect.LR.X <= ARect.LR.X)) then
      begin
        if LRect.LR.Y <= ARect.UL.Y then
        begin
          if not (LGoods[1] and (LDiff.Y < LDiffs[1].Y)) then
            Take(1);
        end
        else if LRect.UL.Y >= ARect.LR.Y then
        begin
          if not (LGoods[7] and (LDiff.Y > LDiffs[7].Y)) then
            Take(7);
        end;
      end;
      // 3, 4, 5
      if ((LRect.UL.Y >= ARect.UL.Y) and (LRect.UL.Y < ARect.LR.Y)) or
        ((LRect.LR.Y > ARect.UL.Y) and (LRect.LR.Y <= ARect.LR.Y)) then
      begin
        if LRect.LR.X <= ARect.UL.X then
        begin
          if not (LGoods[3] and (LDiff.X < LDiffs[3].X)) then
            Take(3);
        end
        else if LRect.UL.X >= ARect.LR.X then
        begin
          if not (LGoods[5] and (LDiff.X > LDiffs[5].X)) then
            Take(5);
        end;
      end;
      // 0, 6 (the C compares with diffs[6].x for the octant 0 too)
      if LRect.UL.X < ARect.UL.X then
      begin
        if LRect.LR.Y <= ARect.UL.Y then
        begin
          if (not LGoods[0]) or (LDiff.Y > LDiffs[0].Y) or (LDiff.X > LDiffs[6].X) then
            Take(0);
        end
        else if LRect.UL.Y >= ARect.LR.Y then
        begin
          if (not LGoods[6]) or (LDiff.Y < LDiffs[6].Y) or (LDiff.X > LDiffs[6].X) then
            Take(6);
        end;
      end;
      // 2, 8
      if LRect.LR.X > ARect.LR.X then
      begin
        if LRect.LR.Y <= ARect.UL.Y then
        begin
          if (not LGoods[2]) or (LDiff.Y > LDiffs[2].Y) or (LDiff.X < LDiffs[2].X) then
            Take(2);
        end
        else if LRect.UL.Y >= ARect.LR.Y then
        begin
          if (not LGoods[8]) or (LDiff.Y < LDiffs[8].Y) or (LDiff.X < LDiffs[8].X) then
            Take(8);
        end;
      end;
    end;
  end;
  LFirst := 5;
  LSecond := 8;
  LThird := 2;
  if AYDir < 0 then
  begin
    LFirst := 1;
    LSecond := 0;
    LThird := 2;
  end
  else if AYDir > 0 then
  begin
    LFirst := 7;
    LSecond := 8;
    LThird := 6;
  end
  else if AXDir < 0 then
  begin
    LFirst := 3;
    LSecond := 0;
    LThird := 6;
  end;
  if LGoods[LFirst] then
    LGood := LGoodRects[LFirst]
  else if LGoods[LSecond] then
    LGood := LGoodRects[LSecond]
  else if LGoods[LThird] then
    LGood := LGoodRects[LThird]
  else
    LGood := ARect;
  GlideCursor(LGood.LR.X - 8, LGood.LR.Y - 8);
end;

function TKeenControlPanel.CallCustom(ACustom: TCustom; ACall: TUserCall; AGroup, ANumber: Integer): Boolean;
begin
  case ACustom of
    ccCtlButton: Result := CtlButtonCustom(ACall, AGroup, ANumber);
    ccP: Result := CtlPButtonCustom(ACall, AGroup, ANumber);
    ccPS: Result := CtlPSButtonCustom(ACall, ANumber);
    ccPR:
      begin
        if ACall = uicHit then
          FResumeGame := True;
        Result := False;
      end;
    ccH: Result := CtlHButtonCustom(ACall, AGroup, ANumber);
    ccD: Result := CtlDButtonCustom(ACall, AGroup, ANumber);
    ccDE:
      begin
        // the C leaves the result of the hit without a value: it is taken as "not handled"
        if ACall = uicHit then
          FQuitToDos := True
        else
          GiveAbortWarning;
        Result := False;
      end;
    ccDL: Result := CtlDLButtonCustom(ACall, AGroup, ANumber);
    ccDS: Result := CtlDSButtonCustom(ACall, AGroup, ANumber);
    ccS: Result := CtlSButtonCustom(ACall, AGroup, ANumber);
    ccC: Result := CtlCButtonCustom(ACall, AGroup, ANumber);
    ccCKbd: Result := CtlCKbdButtonCustom(ACall, AGroup, ANumber);
    ccCJoy: Result := CtlCJoyButtonCustom(ACall);
  else
    Result := False;
  end;
end;

function TKeenControlPanel.CtlButtonCustom(ACall: TUserCall; AGroup, ANumber: Integer): Boolean;
var
  LColumn: Integer;
  LIndex: Integer;
  LList: TList;
begin
  if ACall <> uicHit then
    Exit(False);
  if ANumber = FCtlPanelButton then
    Exit(True);
  FWindows.ClearWindow;
  for LColumn := 8 to 37 do
  begin
    FVideo.DrawTile8Masked(LColumn * 8, 6 * 8, 10);
    FVideo.DrawTile8Masked(LColumn * 8, 21 * 8, 10);
  end;
  FVideo.DrawTile8Masked(7 * 8, 6 * 8, 9);
  FVideo.DrawTile8Masked(38 * 8, 6 * 8, 11);
  FVideo.DrawTile8Masked(7 * 8, 21 * 8, 9);
  FVideo.DrawTile8Masked(38 * 8, 21 * 8, 11);
  for LIndex := 1 to 3 do
    FTheItems[LIndex] := plNone;
  // set to the new button and draw its items
  FCtlPanelButton := ANumber;
  LList := PANELS2[FCtlPanelButton];
  FTheItems[1] := LList;
  for LIndex := 0 to Count(LList) - 1 do
  begin
    DrawItem(AGroup + 1, LIndex);
    if (FLists[LList][LIndex].Sel and UI_SELECTED) <> 0 then
      DoHit(AGroup + 1, LIndex);
  end;
  Result := False;
end;

function TKeenControlPanel.CtlCKbdButtonCustom(ACall: TUserCall; AGroup, ANumber: Integer): Boolean;
var
  LList: TList;
  LItem: TUserItem;
  LState: Boolean;
  LIndex: Integer;
  LScan: Byte;
  LTime: Integer;
  LPicture: Integer;
begin
  if ACall <> uicHit then
    Exit(False);
  LList := FTheItems[AGroup];
  LItem := FLists[LList][ANumber];
  FVideo.FontColor := KEEN_F_SECONDCOLOR;
  ShowHelp(LItem.Help);
  FVideo.FontColor := KEEN_F_BLACK;
  FVideo.HideCursor;
  FVideo.DrawPic(LItem.R.UL.X, LItem.R.UL.Y, LItem.PicDown);
  FVideo.UpdateScreen;
  FInput.LastScan := KEEN_SC_NONE;
  LTime := FClock.TimeCount;
  LState := True;
  repeat
    if FClock.TimeCount - LTime > 35 then
    begin
      // the key cap blinks every half second
      LState := not LState;
      if LState then
        LPicture := LItem.PicDown
      else
        LPicture := LItem.PicUp;
      FVideo.DrawPic(LItem.R.UL.X, LItem.R.UL.Y, LPicture);
      FVideo.UpdateScreen;
      LTime := FClock.TimeCount;
    end;
    if UpdateCursor then
    begin
      // a button of the mouse or of the joystick leaves, as escape does
      while UpdateCursor do
        FClock.Idle;
      LScan := KEEN_SC_ESCAPE;
      Break;
    end;
    if FInput.LastScan = KEEN_SC_LSHIFT then
      FInput.LastScan := KEEN_SC_NONE;
    LScan := FInput.LastScan;
    if LScan = KEEN_SC_NONE then
      FClock.Idle;
  until LScan <> KEEN_SC_NONE;
  FInput.ClearKey(LScan);
  if LScan <> KEEN_SC_ESCAPE then
  begin
    LState := False;
    for LIndex := 0 to 9 do
      if (LIndex <> ANumber) and (GetKey(LIndex) = LScan) then
      begin
        LState := True;
        Break;
      end;
    if LState then
    begin
      FVideo.FontColor := KEEN_F_SECONDCOLOR;
      ShowHelp('That Key is Already Used!');
      FVideo.FontColor := KEEN_F_BLACK;
    end
    else
    begin
      FLists[LList][ANumber].Text := TKeenScanTables.ScanName(LScan);
      FLists[LList][ANumber].HasText := True;
      SetKey(ANumber, LScan);
      FFlushHelp := True;
    end;
  end;
  DrawItem(AGroup, ANumber);
  FVideo.ShowCursor;
  FVideo.UpdateScreen;
  Result := True;
end;

function TKeenControlPanel.CtlCJoyButtonCustom(ACall: TUserCall): Boolean;
var
  LDone: Boolean;
  LJoy: Integer;
  LMinX: Word;
  LMaxX: Word;
  LMinY: Word;
  LMaxY: Word;

  procedure WaitButtonOrEscape;
  begin
    while (FInput.LastScan <> KEEN_SC_ESCAPE) and (FInput.GetJoystickButtonsDebounced(LJoy) = 0) do
      FClock.Idle;
  end;

  procedure WaitNoButton;
  begin
    while FInput.GetJoystickButtonsDebounced(LJoy) <> 0 do
      FClock.Idle;
  end;

begin
  if ACall <> uicHit then
    Exit(False);
  Result := False;
  LJoy := FindDown(plC) - 1;
  // without a joystick there is nothing to calibrate (the buttons of the joysticks are disabled then)
  if (LJoy < 0) or (LJoy >= KEEN_MAX_JOYSTICKS) or not Assigned(FJoysticks) or not FInput.JoystickPresent[LJoy] then
    Exit;
  FInput.ClearKeysDown;
  LDone := False;
  FVideo.HideCursor;
  FFlushHelp := True;
  FVideo.FontColor := KEEN_F_SECONDCOLOR;
  while not LDone do
  begin
    ShowHelp('Move Joystick to the Upper-Left');
    FVideo.UpdateScreen;
    WaitButtonOrEscape;
    if FInput.LastScan <> KEEN_SC_ESCAPE then
    begin
      FJoysticks.GetAbs(LJoy, LMinX, LMinY);
      WaitNoButton;
      ShowHelp('Move Joystick to the Lower-Right');
      FVideo.UpdateScreen;
      WaitButtonOrEscape;
      if FInput.LastScan <> KEEN_SC_ESCAPE then
      begin
        // the C reads the joystick 0 here whatever the one that is calibrated: the one asked for is read
        FJoysticks.GetAbs(LJoy, LMaxX, LMaxY);
        if (LMaxX <> LMinX) and (LMaxY <> LMinY) then
        begin
          LDone := True;
          FInput.SetupJoystick(LJoy, LMinX, LMaxX, LMinY, LMaxY);
        end
        else
          WaitNoButton;
      end
      else
        LDone := True;
    end
    else
      LDone := True;
  end;
  if FInput.LastScan <> KEEN_SC_ESCAPE then
    WaitNoButton;
  if FInput.LastScan <> KEEN_SC_NONE then
    FInput.ClearKeysDown;
  FVideo.FontColor := KEEN_F_BLACK;
  FVideo.ShowCursor;
end;

procedure TKeenControlPanel.ClearBottom;
var
  LSaved: TKeenWindowRec;
begin
  LSaved := FWindows.SaveWindow;
  FWindows.RestoreWindow(FBottomWindow);
  FWindows.ClearWindow;
  FWindows.RestoreWindow(LSaved);
end;

function TKeenControlPanel.HelpLine(AOffset: Integer): AnsiString;
var
  LEnd: Integer;
begin
  LEnd := AOffset;
  while (LEnd < Length(FTextBytes)) and (FTextBytes[LEnd] <> 0) do
    Inc(LEnd);
  SetString(Result, PAnsiChar(@FTextBytes[AOffset]), LEnd - AOffset);
end;

function TKeenControlPanel.FormatHelp: Integer;
var
  LWindow: TKeenWindowRec;
  LLine: Integer;
  LWidth: Integer;
  LHeight: Integer;
  LChar: Byte;
  LPosition: Integer;
  LLineStart: Integer;
  LLineEnd: Integer;
  LLength: Integer;

  function ByteAt(AIndex: Integer): Byte;
  begin
    if (AIndex >= 0) and (AIndex < LLength) then
      Result := FTextBytes[AIndex]
    else
      Result := 0;
  end;

  procedure AddLine;
  begin
    if LLine >= Length(FLineOffsets) then
      SetLength(FLineOffsets, (LLine + 64) * 2);
    FLineOffsets[LLine] := LLineStart;
    Inc(LLine);
  end;

begin
  // the text is cut in lines that fit the window, in place: the end of a line becomes a 0
  LWindow := FWindows.Window;
  Inc(LWindow.X, 4);
  Dec(LWindow.W, 4);
  LLength := Length(FTextBytes) - 1; // the last byte is the 0 that ends the buffer
  LLine := 0;
  LLineEnd := 0;
  LLineStart := 0;
  LPosition := 0;
  while (LPosition < LLength) and (FTextBytes[LPosition] <> Ord('~')) do
  begin
    LChar := FTextBytes[LPosition];
    if LChar = 10 then
    begin
      FTextBytes[LPosition] := 0;
      AddLine;
      LLineStart := LPosition + 1;
      LLineEnd := LLineStart;
    end;
    if LChar = 13 then
    begin
      LChar := Ord(' ');
      FTextBytes[LPosition] := LChar;
    end;
    // strip the space that a line break left alone at the start of a line
    if (LChar = Ord(' ')) and (LPosition = LLineStart) and (LPosition > 0) and (ByteAt(LPosition - 1) = 0) and
      (ByteAt(LPosition + 1) <> Ord(' ')) then
    begin
      LLineStart := LPosition + 1;
      LLineEnd := LLineStart;
    end
    else if LChar = Ord(' ') then
    begin
      FTextBytes[LPosition] := 0;
      FVideo.MeasureString(HelpLine(LLineStart), LWidth, LHeight);
      if LWidth >= LWindow.W then
      begin
        // too wide: the line ends at the last word that fitted
        FTextBytes[LPosition] := LChar;
        FTextBytes[LLineEnd] := 0;
        AddLine;
        LLineStart := LLineEnd + 1;
        LPosition := LLineStart;
        // a word that alone is wider than the window: the C would go back for ever, here the line is cut
        if LLineEnd >= LPosition then
          LLineEnd := LPosition;
      end
      else
      begin
        FTextBytes[LPosition] := LChar;
        LLineEnd := LPosition;
      end;
    end;
    Inc(LPosition);
  end;
  Result := LLine;
end;

procedure TKeenControlPanel.DrawHelp(AStart, AEnd, ALine, AHeight: Integer);
var
  LWindow: TKeenWindowRec;
  LIndex: Integer;
begin
  LWindow := FWindows.Window;
  FVideo.Px := LWindow.X + 4;
  FVideo.Py := LWindow.Y + ALine * AHeight;
  for LIndex := AStart to AEnd - 1 do
  begin
    FVideo.DrawString(HelpLine(FLineOffsets[LIndex]));
    FVideo.Px := LWindow.X + 4;
    FVideo.Py := FVideo.Py + AHeight;
  end;
end;

procedure TKeenControlPanel.DoHelp(const AText: TBytes);
var
  LDone: Boolean;
  LMoved: Boolean;
  LScroll: Integer;
  LWidth: Integer;
  LHeight: Integer;
  LLines: Integer;
  LCurrent: Integer;
  LPage: Integer;
  LTop: Integer;
  LNumber: Integer;
  LLocation: Integer;
  LBase: Integer;
  LSourceBase: Integer;
  LDestBase: Integer;
  LRow: Integer;
  LWaitKey: Byte;
  LLastTime: Integer;
  LSaved: TKeenWindowRec;
  LWindow: TKeenWindowRec;
  LInfo: TKeenControlInfo;
  LRaw: IKeenVideo;
begin
  ShowHelp('Arrow Keys Move / Escape Exits');
  FVideo.FontColor := KEEN_F_BLACK;
  LSaved := FWindows.SaveWindow;
  FWindows.RestoreWindow(FBottomWindow);
  FWindows.ClearWindow;
  FVideo.HideCursor;
  FVideo.UpdateScreen;
  // a copy that the formatting can change, with a 0 after it
  SetLength(FTextBytes, Length(AText) + 1);
  if Length(AText) > 0 then
    Move(AText[0], FTextBytes[0], Length(AText));
  FTextBytes[Length(AText)] := 0;
  LLines := FormatHelp;
  FVideo.MeasureString('', LWidth, LHeight);
  LWindow := FWindows.Window;
  LRaw := FVideo.Video;
  if LHeight <= 0 then
    LHeight := 1;
  LPage := LWindow.H div LHeight;
  LCurrent := 0;
  FInput.ClearKeysDown;
  LMoved := True;
  LLastTime := 0;
  LScroll := 0;
  LDone := False;
  LWaitKey := KEEN_SC_NONE;
  while not LDone do
  begin
    if LMoved then
    begin
      WaitTics(LLastTime, 5);
      LLastTime := FClock.TimeCount;
      if LScroll = -1 then
      begin
        LTop := LCurrent;
        LNumber := 1;
        LLocation := 0;
      end
      else if LScroll = 1 then
      begin
        LNumber := 1;
        LLocation := LPage - 1;
        LTop := LCurrent + LLocation;
      end
      else
      begin
        LTop := LCurrent;
        if LPage < LLines then
          LNumber := LPage
        else
          LNumber := LLines;
        LLocation := 0;
      end;
      if LScroll <> 0 then
      begin
        // the new line is drawn in the buffer, the page that is shown is moved by a line with a screen copy
        // and the new line is copied to it
        FVideo.Bar(LWindow.X, LWindow.Y + LLocation * LHeight, LWindow.W, LNumber * LHeight, KEEN_WHITE);
        DrawHelp(LTop, LTop + LNumber, LLocation, LHeight);
        LBase := LRaw.DisplayOfs + LRaw.PanAdjust + (LWindow.X div 8);
        if LScroll = 1 then
        begin
          LSourceBase := LBase + LRaw.YLookup(LWindow.Y + LHeight);
          LDestBase := LBase + LRaw.YLookup(LWindow.Y);
          FVideo.WaitVBL(1);
          LRaw.ScreenToScreen(LSourceBase, LDestBase, LWindow.W div 8, LWindow.H - LHeight);
        end
        else
        begin
          LRow := LWindow.Y + LHeight * (LPage - 1);
          LSourceBase := LBase + LRaw.YLookup(LRow - LHeight);
          LDestBase := LBase + LRaw.YLookup(LRow);
          LBase := LRaw.YLookup(LHeight);
          for LRow := LPage - 1 downto 1 do
          begin
            LRaw.ScreenToScreen(LSourceBase, LDestBase, LWindow.W div 8, LHeight);
            Dec(LSourceBase, LBase);
            Dec(LDestBase, LBase);
          end;
        end;
        LBase := LRaw.PanAdjust + (LWindow.X div 8) + LRaw.YLookup(LWindow.Y + LLocation * LHeight);
        LRaw.ScreenToScreen(LBase + LRaw.BufferOfs, LBase + LRaw.DisplayOfs, LWindow.W div 8, LHeight);
      end
      else
      begin
        FWindows.ClearWindow;
        DrawHelp(LTop, LTop + LNumber, LLocation, LHeight);
        FVideo.UpdateScreen;
      end;
      LMoved := False;
      LScroll := 0;
    end;
    if LWaitKey <> KEEN_SC_NONE then
      while FInput.IsKeyDown(LWaitKey) do
        FClock.Idle;
    LWaitKey := KEEN_SC_NONE;
    LInfo := FInput.ReadCursor;
    if LInfo.Y < 0 then
    begin
      if LCurrent > 0 then
      begin
        LScroll := -1;
        Dec(LCurrent);
        LMoved := True;
      end;
    end
    else if LInfo.Y > 0 then
    begin
      if LCurrent + LPage < LLines then
      begin
        LScroll := 1;
        Inc(LCurrent);
        LMoved := True;
      end;
    end
    else if LInfo.Button0 or LInfo.Button1 then
      LDone := True
    else if FInput.IsKeyDown(FInput.LastScan) then
    begin
      case FInput.LastScan of
        KEEN_SC_ESCAPE:
          LDone := True;
        KEEN_SC_UPARROW:
          if LCurrent > 0 then
          begin
            LScroll := -1;
            Dec(LCurrent);
            LMoved := True;
          end;
        KEEN_SC_DOWNARROW:
          if LCurrent + LPage < LLines then
          begin
            LScroll := 1;
            Inc(LCurrent);
            LMoved := True;
          end;
        KEEN_SC_PGUP:
          begin
            if LCurrent > LPage then
              Dec(LCurrent, LPage)
            else
              LCurrent := 0;
            LMoved := True;
            LWaitKey := KEEN_SC_PGUP;
          end;
        KEEN_SC_PGDN:
          begin
            if LCurrent + LPage < LLines then
            begin
              Inc(LCurrent, LPage);
              if LCurrent + LPage >= LLines then
                LCurrent := LLines - LPage;
              LMoved := True;
            end;
            LWaitKey := KEEN_SC_PGDN;
          end;
      end;
    end;
    if not (LMoved or LDone) then
      FClock.Idle;
  end;
  FInput.ClearKeysDown;
  repeat
    LInfo := FInput.ReadCursor;
    if LInfo.Button0 or LInfo.Button1 then
      FClock.Idle;
  until not (LInfo.Button0 or LInfo.Button1);
  FVideo.ShowCursor;
  FWindows.ClearWindow;
  FVideo.UpdateScreen;
  FWindows.RestoreWindow(LSaved);
end;

function TKeenControlPanel.CtlHButtonCustom(ACall: TUserCall; AGroup, ANumber: Integer): Boolean;
var
  LList: TList;
  LText: TBytes;
begin
  if ACall <> uicHit then
    Exit(False);
  Result := False;
  LList := FTheItems[AGroup];
  if (FLists[LList][ANumber].Sel and UI_DISABLED) <> 0 then
    Exit;
  FLists[LList][ANumber].Sel := FLists[LList][ANumber].Sel or UI_SELECTED;
  DrawItem(AGroup, ANumber);
  ClearBottom;
  FVideo.FontColor := KEEN_F_SECONDCOLOR;
  ShowHelp('Loading & Formatting Text...');
  FVideo.UpdateScreen;
  // the texts are linked in the original program; here a program that has none says so
  if Assigned(FHelp) and FHelp.TryGetText(ANumber, LText) then
  begin
    if Length(LText) > HELP_TEXT_BYTES then
      SetLength(LText, HELP_TEXT_BYTES);
    DoHelp(LText);
  end
  else
    HandleError('No such file or directory');
  FVideo.FontColor := KEEN_F_BLACK;
  FLists[LList][ANumber].Sel := FLists[LList][ANumber].Sel and not UI_SELECTED;
  DrawItem(AGroup, ANumber);
end;

function TKeenControlPanel.CtlDButtonCustom(ACall: TUserCall; AGroup, ANumber: Integer): Boolean;
begin
  if ACall <> uicHit then
    Exit(False);
  Result := False;
  if (FLists[FTheItems[AGroup]][ANumber].Sel and UI_DISABLED) <> 0 then
    Exit;
  ClearBottom;
  if ANumber <> 0 then
    FTheItems[AGroup + 1] := plDE
  else
    FTheItems[AGroup + 1] := plDLS;
  DrawList(AGroup + 1);
end;

function TKeenControlPanel.DLSRect(AList: TList; ANumber: Integer): TKeenRect;
var
  LItem: TUserItem;
  LWindow: TKeenWindowRec;
begin
  // the rectangle of the name of a saved game, at the right of its two buttons
  LItem := FLists[AList][ANumber];
  LWindow := FWindows.Window;
  Result.UL.X := LItem.R.LR.X + 40 + 2;
  Result.UL.Y := LItem.R.UL.Y + 2;
  Result.LR.X := LWindow.X + LWindow.W - 8 - 2;
  Result.LR.Y := LItem.R.LR.Y - 2;
  FVideo.Bar(Result.UL.X, Result.UL.Y, Result.LR.X - Result.UL.X, Result.LR.Y - Result.UL.Y, KEEN_WHITE);
  FVideo.Hlin(Result.UL.X, Result.LR.X, Result.UL.Y, KEEN_BLACK);
  FVideo.Hlin(Result.UL.X, Result.LR.X, Result.LR.Y, KEEN_BLACK);
  FVideo.Vlin(Result.UL.Y, Result.LR.Y, Result.UL.X, KEEN_BLACK);
  FVideo.Vlin(Result.UL.Y, Result.LR.Y, Result.LR.X, KEEN_BLACK);
  FVideo.Px := Result.UL.X + 2;
  FVideo.Py := Result.UL.Y + 2;
end;

function TKeenControlPanel.CtlDLButtonCustom(ACall: TUserCall; AGroup, ANumber: Integer): Boolean;
var
  LList: TList;
  LSlot: TKeenSaveSlot;
  LSaved: TKeenWindowRec;
  LError: AnsiString;
begin
  Result := False;
  LList := FTheItems[AGroup];
  LSlot := FSlots.Slots[ANumber div 2];
  case ACall of
    uicDraw:
      if not FState.LoadedGame then
      begin
        DLSRect(LList, ANumber);
        if LSlot.Present then
        begin
          FVideo.FontColor := KEEN_F_BLACK;
          FVideo.DrawString(LSlot.Name);
        end
        else
        begin
          FVideo.FontColor := KEEN_F_FIRSTCOLOR;
          FVideo.DrawString('Empty');
        end;
        FVideo.FontColor := KEEN_F_BLACK;
      end;
    uicHit:
      begin
        if (FLists[LList][ANumber].Sel and UI_DISABLED) <> 0 then
          Exit;
        LSaved := FWindows.SaveWindow;
        FWindows.CenterWindow(30, 3);
        FWindows.PrintCentered('Loading `' + LSlot.Name + '''');
        FVideo.HideCursor;
        FVideo.UpdateScreen;
        if FSlots.Load(ANumber div 2, FHooks, LError) then
          FState.LoadedGame := True
        else
        begin
          HandleError(LError);
          FState.AbortGame := True;
        end;
        LSlot := FSlots.Slots[ANumber div 2];
        LSlot.Present := True;
        FSlots.Slots[ANumber div 2] := LSlot;
        if FState.LoadedGame then
          FInput.Paused := True;
        FVideo.ShowCursor;
        FWindows.RestoreWindow(LSaved);
      end;
  end;
end;

function TKeenControlPanel.CtlDSButtonCustom(ACall: TUserCall; AGroup, ANumber: Integer): Boolean;
var
  LList: TList;
  LSlot: TKeenSaveSlot;
  LSaved: TKeenWindowRec;
  LRect: TKeenRect;
  LOk: Boolean;
  LName: AnsiString;
  LDefault: AnsiString;
begin
  if ACall <> uicHit then
    Exit(False);
  LList := FTheItems[AGroup];
  if (FLists[LList][ANumber].Sel and UI_DISABLED) <> 0 then
    Exit(False);
  LSlot := FSlots.Slots[ANumber div 2];
  FFlushHelp := True;
  FVideo.FontColor := KEEN_F_SECONDCOLOR;
  ShowHelp('Enter Game Name / Escape Aborts');
  FVideo.FontColor := KEEN_F_BLACK;
  LRect := DLSRect(LList, ANumber - 1);
  if LSlot.Present then
    LDefault := LSlot.Name
  else
    LDefault := '';
  LName := LSlot.Name;
  LOk := FWindows.LineInput(FVideo.Px, FVideo.Py, LName, LDefault, True, KEEN_MAX_GAME_NAME,
    LRect.LR.X - LRect.UL.X - 8);
  if Length(LName) = 0 then
    LName := 'Untitled';
  LSlot.Name := LName;
  FSlots.Slots[ANumber div 2] := LSlot;
  if LOk then
  begin
    LSaved := FWindows.SaveWindow;
    FWindows.CenterWindow(10, 3);
    FWindows.PrintCentered('Saving');
    FVideo.HideCursor;
    FVideo.UpdateScreen;
    LOk := FSlots.Save(ANumber div 2, FHooks);
    if not LOk then
      HandleError('Disk is Full');
    FVideo.ShowCursor;
    FWindows.RestoreWindow(LSaved);
    DoHit(AGroup - 1, 0);
    FVideo.UpdateScreen;
  end;
  LSlot := FSlots.Slots[ANumber div 2];
  if not LSlot.Present then
  begin
    LSlot.Present := LOk;
    FSlots.Slots[ANumber div 2] := LSlot;
  end;
  if LOk then
  begin
    FGameIsDirty := False;
    FLists[LList][ANumber - 1].Sel := FLists[LList][ANumber - 1].Sel and not UI_DISABLED;
  end;
  DrawItem(AGroup, ANumber - 1);
  Result := True;
end;

function TKeenControlPanel.CtlSButtonCustom(ACall: TUserCall; AGroup, ANumber: Integer): Boolean;
begin
  if ACall <> uicHit then
    Exit(False);
  Result := False;
  if (FLists[FTheItems[AGroup]][ANumber].Sel and UI_DISABLED) <> 0 then
    Exit;
  ClearBottom;
  // sdm_SoundSource is the fifth sound button
  if ANumber = 4 then
  begin
    FTheItems[AGroup + 1] := plSSS;
    DrawList(AGroup + 1);
  end
  else
    FTheItems[AGroup + 1] := plNone;
end;

function TKeenControlPanel.CtlPButtonCustom(ACall: TUserCall; AGroup, ANumber: Integer): Boolean;
begin
  if ACall <> uicHit then
    Exit(False);
  Result := False;
  if (FLists[FTheItems[AGroup]][ANumber].Sel and UI_DISABLED) <> 0 then
    Exit;
  ClearBottom;
  if ANumber <> 0 then
    FTheItems[AGroup + 1] := plPR
  else
    FTheItems[AGroup + 1] := plPS;
  DrawList(AGroup + 1);
end;

procedure TKeenControlPanel.GiveAbortWarning;
var
  LSaved: TKeenWindowRec;
  LWindow: TKeenWindowRec;
begin
  if not FGameIsDirty then
    Exit;
  LSaved := FWindows.SaveWindow;
  FWindows.RestoreWindow(FBottomWindow);
  LWindow := FWindows.Window;
  // US_HomeWindow and five pixels down
  FWindows.PrintX := LWindow.X;
  FWindows.PrintY := LWindow.Y + 5;
  FVideo.Bar(LWindow.X, LWindow.Y, LWindow.W, 30, KEEN_WHITE);
  FVideo.FontColor := KEEN_F_SECONDCOLOR;
  FWindows.CPrint('Warning! If you do this, you''ll');
  FWindows.CPrint('abort the current game.');
  FVideo.FontColor := KEEN_F_BLACK;
  FWindows.RestoreWindow(LSaved);
end;

function TKeenControlPanel.CtlPSButtonCustom(ACall: TUserCall; ANumber: Integer): Boolean;
begin
  Result := False;
  case ACall of
    uicHit:
      begin
        case ANumber of
          0: FState.RestartGame := kgdNormal;
          1: FState.RestartGame := kgdEasy;
          2: FState.RestartGame := kgdHard;
        end;
        if (FState.RestartGame <> kgdContinue) and FState.InGame and Assigned(FHooks) then
          FHooks.ResetGame;
      end;
    uicDraw:
      GiveAbortWarning;
  end;
end;

function TKeenControlPanel.CtlCButtonCustom(ACall: TUserCall; AGroup, ANumber: Integer): Boolean;
var
  LPoint: TKeenPoint;
begin
  if ACall <> uicHit then
    Exit(False);
  Result := False;
  if (FLists[FTheItems[AGroup]][ANumber].Sel and UI_DISABLED) <> 0 then
    Exit;
  ClearBottom;
  if ANumber = 0 then
  begin
    // the keyboard: the picture of the directions in the middle of the key caps
    FTheItems[AGroup + 1] := plCKbd;
    LPoint := FLists[plCKbd][2].R.LR;
    FVideo.DrawPic(LPoint.X, LPoint.Y, KEEN_GFX_CTL_DIRSPIC);
  end
  else
    FTheItems[AGroup + 1] := plCJoy;
  DrawList(AGroup + 1);
end;

procedure TKeenControlPanel.HitHotKey(AGroup: Integer);
var
  LList: TList;
  LNumber: Integer;
begin
  // the cursor goes to the selected item of the group after the one of the hot key
  if AGroup + 1 > High(FTheItems) then
    Exit;
  LList := FTheItems[AGroup + 1];
  if LList = plNone then
    Exit;
  LNumber := FindDown(LList);
  if LNumber = -1 then
    LNumber := 0;
  FCursorX := FLists[LList][LNumber].R.LR.X - 8;
  FCursorY := FLists[LList][LNumber].R.LR.Y - 8;
  FCursorBad := True;
end;

function TKeenControlPanel.CheckScan: Boolean;
var
  LCount: Integer;
  LNumber: Integer;
  LIndex: Integer;
  LScan: Integer;
  LList: TList;
begin
  LScan := FInput.LastScan;
  if LScan = KEEN_SC_NONE then
    Exit(False);
  // 1..9 for the items of the top row
  if (FTheItems[1] <> plNone) and not FInput.IsKeyDown(KEEN_SC_RSHIFT) then
  begin
    LCount := Count(FTheItems[1]);
    if LCount > 9 then
      LCount := 9;
    for LNumber := 0 to LCount - 1 do
      if (LScan = 2 + LNumber) and ((FLists[FTheItems[1]][LNumber].Sel and UI_DISABLED) = 0) then
      begin
        FInput.LastScan := KEEN_SC_NONE;
        DoHit(1, LNumber);
        Exit(True);
      end;
  end;
  // right shift and 1..6 for the items of the left column
  if FInput.IsKeyDown(KEEN_SC_RSHIFT) then
  begin
    LNumber := LScan - 2;
    if (LNumber >= 0) and (LNumber < 6) then
    begin
      DoHit(0, LNumber);
      FInput.LastScan := KEEN_SC_NONE;
      Exit(True);
    end;
  end;
  // the hot keys of the left column
  for LIndex := 0 to Count(plCtl) - 1 do
    if FLists[plCtl][LIndex].Key = LScan then
    begin
      FInput.LastScan := KEEN_SC_NONE;
      DoHit(0, LIndex);
      HitHotKey(0);
      Exit(True);
    end;
  // the hot keys of the top rows
  for LIndex := 0 to 5 do
  begin
    LList := PANELS2[LIndex];
    for LNumber := 0 to Count(LList) - 1 do
      if (FLists[LList][LNumber].Key = LScan) and ((FLists[LList][LNumber].Sel and UI_DISABLED) = 0) then
      begin
        FInput.LastScan := KEEN_SC_NONE;
        DoHit(0, LIndex);
        DoHit(1, LNumber);
        HitHotKey(1);
        Exit(True);
      end;
  end;
  Result := False;
end;

procedure TKeenControlPanel.SetUpCtlPanel;
var
  LIndex: Integer;
  LInGame: Boolean;
begin
  LInGame := FState.InGame;
  FGameIsDirty := LInGame;
  // restart game
  TurnOff(plP);
  if LInGame then
  begin
    FLists[plP][0].Sel := UI_NORMAL;
    FLists[plP][1].Sel := UI_SELECTED;
  end
  else
  begin
    FLists[plP][0].Sel := UI_SELECTED;
    FLists[plP][1].Sel := UI_DISABLED;
  end;
  // disk: load and save by default
  TurnOff(plD);
  FLists[plD][0].Sel := UI_SELECTED;
  TurnOff(plDLS);
  for LIndex := 0 to KEEN_MAX_SAVE_GAMES - 1 do
  begin
    if not FSlots.Slots[LIndex].Present then
      FLists[plDLS][LIndex * 2].Sel := UI_DISABLED;
    if not LInGame then
      FLists[plDLS][LIndex * 2 + 1].Sel := UI_DISABLED;
  end;
  // controls
  TurnOff(plC);
  if FInput.JoystickPresent[0] then
    FLists[plC][1].Sel := UI_NORMAL
  else
    FLists[plC][1].Sel := UI_DISABLED;
  if FInput.JoystickPresent[1] then
    FLists[plC][2].Sel := UI_NORMAL
  else
    FLists[plC][2].Sel := UI_DISABLED;
  case FInput.Controls[0] of
    kctJoystick1: LIndex := 1;
    kctJoystick2: LIndex := 2;
  else
    LIndex := 0;
  end;
  FLists[plC][LIndex].Sel := FLists[plC][LIndex].Sel or UI_SELECTED;
  if FInput.JoystickPresent[1] and not FInput.JoystickPresent[0] then
    FLists[plC][2].Key := KEEN_SC_F4
  else
    FLists[plC][1].Key := KEEN_SC_F4;
  // keyboard
  for LIndex := 0 to 9 do
  begin
    FLists[plCKbd][LIndex].Text := TKeenScanTables.ScanName(GetKey(LIndex));
    FLists[plCKbd][LIndex].HasText := True;
  end;
  // sounds: the digitized ones are disabled in Keen Dreams ("no space for digitized sounds")
  TurnOff(plS);
  if FSound.AdLibPresent then
    FLists[plS][2].Sel := UI_NORMAL
  else
    FLists[plS][2].Sel := UI_DISABLED;
  FLists[plS][3].Sel := UI_DISABLED;
  FLists[plS][4].Sel := UI_DISABLED;
  FLists[plS][Ord(FSound.Mode)].Sel := FLists[plS][Ord(FSound.Mode)].Sel or UI_SELECTED;
  // the Sound Source: not a Tandy, the second printer port
  TurnOff(plSSS);
  FLists[plSSS][0].Sel := UI_NORMAL;
  FLists[plSSS][1].Sel := UI_SELECTED;
  // music: there is none, the mode is off
  TurnOff(plM);
  if FSound.AdLibPresent then
    FLists[plM][1].Sel := UI_NORMAL
  else
    FLists[plM][1].Sel := UI_DISABLED;
  FLists[plM][0].Sel := FLists[plM][0].Sel or UI_SELECTED;
end;

procedure TKeenControlPanel.TearDownCtlPanel;
var
  LIndex: Integer;
begin
  LIndex := FindDown(plC);
  if LIndex <> -1 then
    case LIndex of
      0: FInput.SetControlType(0, kctKeyboard1);
      1: FInput.SetControlType(0, kctJoystick1);
    else
      FInput.SetControlType(0, kctJoystick2);
    end;
  FLists[plC][1].Key := KEEN_SC_NONE;
  FLists[plC][2].Key := KEEN_SC_NONE;
  LIndex := FindDown(plS);
  if (LIndex >= 0) and (LIndex <= Ord(High(TKeenSoundMode))) then
    FSound.TrySetMode(TKeenSoundMode(LIndex));
  // SD_SetMusicMode: Keen Dreams has no music, the choice of the music buttons is not kept
end;

procedure TKeenControlPanel.Run;
var
  LScan: Byte;
  LDone: Boolean;
  LButtonDown: Boolean;
  LInRect: Boolean;
  LHitGroup: Integer;
  LHitNumber: Integer;
  LGroup: Integer;
  LNumber: Integer;
  LLastGroup: Integer;
  LLastNumber: Integer;
  LLastX: Integer;
  LLastY: Integer;
  LLastTime: Integer;
  LUseRect: TKeenRect;
  LIndex: Integer;
  LList: TList;
  LKeys: TKeenKeyboardDef;
begin
  LScan := FInput.LastScan;
  // escape from the game is "exit to DOS"
  if LScan = KEEN_SC_ESCAPE then
    LScan := SC_Q;
  FQuitToDos := False;
  SetUpCtlPanel;
  FVideo.FontColor := KEEN_F_BLACK;
  FVideo.InitDoubleBuffer;
  FVideo.Bar(0, 0, KEEN_MAX_X, KEEN_MAX_Y, KEEN_FIRSTCOLOR);
  FWindows.DrawWindow(8, 22, 30, 2);
  FHelpWindow := FWindows.SaveWindow;
  FWindows.DrawWindow(8, 7, 30, 14);
  FBottomWindow := FWindows.SaveWindow;
  FWindows.DrawWindow(8, 1, 30, 20);
  for LIndex := 0 to Count(plCtl) - 1 do
    FVideo.DrawPic(FLists[plCtl][LIndex].R.UL.X, FLists[plCtl][LIndex].R.UL.Y, FLists[plCtl][LIndex].PicUp);
  FTheItems[0] := plCtl;
  FTheItems[1] := plNone;
  FTheItems[2] := plNone;
  FTheItems[3] := plNone;
  StartCursor;
  FCursorX := (8 * 8) + ((KEEN_MAX_X - (8 * 8)) div 2);
  FCursorBad := True;
  FCtlPanelButton := -1;
  FInput.LastScan := LScan;
  CheckScan;
  if FCtlPanelButton = -1 then
    DoHit(0, 0);
  FResumeGame := False;
  LDone := False;
  FFlushHelp := True;
  LLastX := -1;
  LLastY := -1;
  LLastGroup := -2;
  LLastNumber := -1;
  LLastTime := FClock.TimeCount;
  while (FState.RestartGame = kgdContinue) and not (LDone or FState.LoadedGame or FResumeGame) do
  begin
    FVideo.UpdateScreen;
    LButtonDown := UpdateCursor;
    LInRect := IsInRect(FCursorX, FCursorY, LGroup, LNumber);
    if FFlushHelp then
    begin
      LLastGroup := -2;
      LLastTime := FClock.TimeCount;
      FFlushHelp := False;
    end;
    if LInRect then
    begin
      if (LLastGroup <> LGroup) or (LLastNumber <> LNumber) then
      begin
        // over a load button: the name of the game
        if (FCtlPanelButton = 2) and (LGroup = 2) and ((FLists[FTheItems[1]][0].Sel and UI_SELECTED) <> 0) and
          FSlots.Slots[LNumber div 2].Present and ((LNumber and 1) = 0) then
          ShowHelp('Load `' + FSlots.Slots[LNumber div 2].Name + '''')
        else
          ShowHelp(FLists[FTheItems[LGroup]][LNumber].Help);
        LLastGroup := LGroup;
        LLastNumber := LNumber;
      end;
    end
    else if LLastGroup <> -1 then
    begin
      ShowHelp('Select a Button');
      LLastGroup := -1;
    end;
    LHitGroup := LGroup;
    LHitNumber := LNumber;
    if LInRect then
      LUseRect := FLists[FTheItems[LGroup]][LNumber].R
    else
      LUseRect := TKeenRect.Make(FCursorX, FCursorY, FCursorX, FCursorY);
    LKeys := FInput.KeyboardDefs[0];
    if FInput.IsKeyDown(KEEN_SC_UPARROW) then
    begin
      FindRect(LUseRect, 0, -1);
      FInput.ClearKey(KEEN_SC_UPARROW);
    end
    else if FInput.IsKeyDown(KEEN_SC_DOWNARROW) then
    begin
      FindRect(LUseRect, 0, 1);
      FInput.ClearKey(KEEN_SC_DOWNARROW);
    end
    else if FInput.IsKeyDown(KEEN_SC_LEFTARROW) then
    begin
      FindRect(LUseRect, -1, 0);
      FInput.ClearKey(KEEN_SC_LEFTARROW);
    end
    else if FInput.IsKeyDown(KEEN_SC_RIGHTARROW) then
    begin
      FindRect(LUseRect, 1, 0);
      FInput.ClearKey(KEEN_SC_RIGHTARROW);
    end
    else if FInput.IsKeyDown(KEEN_SC_RETURN) or FInput.IsKeyDown(LKeys.Button0) or FInput.IsKeyDown(LKeys.Button1) then
    begin
      if FInput.IsKeyDown(KEEN_SC_RETURN) then
        FInput.ClearKey(KEEN_SC_RETURN)
      else if FInput.IsKeyDown(LKeys.Button0) then
        FInput.ClearKey(LKeys.Button0)
      else
        FInput.ClearKey(LKeys.Button1);
      if LInRect then
      begin
        LList := FTheItems[LHitGroup];
        if (FLists[LList][LHitNumber].Kind = uiiButton) and ((FLists[LList][LHitNumber].Sel and UI_DISABLED) = 0) then
        begin
          // the button goes down and up, a quarter of a second each
          LLastTime := FClock.TimeCount;
          FLists[LList][LHitNumber].Sel := FLists[LList][LHitNumber].Sel or UI_SELECTED;
          DrawItem(LHitGroup, LHitNumber);
          FVideo.UpdateScreen;
          WaitTics(LLastTime, KEEN_TICKBASE div 4);
          LLastTime := FClock.TimeCount;
          FLists[LList][LHitNumber].Sel := FLists[LList][LHitNumber].Sel and not UI_SELECTED;
          DrawItem(LHitGroup, LHitNumber);
          FVideo.UpdateScreen;
          WaitTics(LLastTime, KEEN_TICKBASE div 4);
        end;
        DoHit(LHitGroup, LHitNumber);
      end;
    end
    else if CheckScan then
    begin
      // a hot key did its hit
    end
    else if LButtonDown and LInRect and TrackItem(LHitGroup, LHitNumber) then
      DoHit(LHitGroup, LHitNumber);
    if FInput.LastScan = KEEN_SC_ESCAPE then
    begin
      FInput.ClearKey(KEEN_SC_ESCAPE);
      LDone := True;
    end;
    if FQuitToDos then
      LDone := True;
    if (LLastX <> FCursorX) or (LLastY <> FCursorY) then
    begin
      LLastX := FCursorX;
      LLastY := FCursorY;
      LLastTime := FClock.TimeCount;
    end;
    if FClock.TimeCount - LLastTime > KEEN_TICKBASE * 10 then
    begin
      if (((FClock.TimeCount - LLastTime) div KEEN_TICKBASE) and 2) <> 0 then
        FVideo.FontColor := KEEN_F_SECONDCOLOR;
      ShowHelp('Press F1 for Help');
      FVideo.FontColor := KEEN_F_BLACK;
    end;
  end;
  FVideo.HideCursor;
  TearDownCtlPanel;
  if FQuitToDos then
  begin
    FWindows.CenterWindow(20, 3);
    FVideo.FontColor := KEEN_F_SECONDCOLOR;
    FWindows.PrintCentered('Now Exiting to DOS...');
    FVideo.FontColor := KEEN_F_BLACK;
    FVideo.UpdateScreen;
    raise EKeenQuitException.Create(SKeenQuit);
  end;
end;

end.
