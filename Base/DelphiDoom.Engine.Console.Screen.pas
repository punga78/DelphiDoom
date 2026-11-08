{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the console on the screen over Libs\Console            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Console.Screen;

{$I Doom32.inc}

interface

uses
  System.SysUtils,
  d_delphi,
  d_event,
  DelphiDoom.CommandLine.Intf,
  DelphiDoom.Console.Intf,
  DelphiDoom.Console.AutoExec,
  DelphiDoom.Console.StandardCommands,
  DelphiDoom.Console.VariableCommands,
  DelphiDoom.Console.CommandQueue,
  DelphiDoom.Console.InputLine,
  DelphiDoom.Engine.Console.Intf;

const
  /// <summary>The lines of text that the console keeps on the screen (a power of 2)</summary>
  ENGINE_CONSOLE_LINES = 256;

type
  /// <summary>
  ///   C_Init, C_Responder, C_Ticker, C_Drawer and the text of the old c_con.pas: the commands,
  ///   the line of input, the queue and the autoexec are the objects of Libs\Console that the
  ///   console receives and owns; the drawing uses the screens and the fonts of the engine
  /// </summary>
  TEngineConsoleScreen = class(TInterfacedObject, IEngineConsole)
  strict private
    type
      TConsoleState = (csUp, csRaise, csLower, csDown);
    class var
      // outproc of d_delphi is a plain procedure: this is the console that it writes to
      FOutputConsole: TEngineConsoleScreen;
  strict private
    FRegistry: ICommandRegistry;
    FInterpreter: IConsoleInterpreter;
    FStandard: TConsoleStandardCommands;
    FAutoExec: TConsoleAutoExec;
    FVariables: TConsoleVariableCommands;
    FQueue: TConsoleCommandQueue;
    FInput: TConsoleInputLine;
    FCommandLine: IQueriedCommandLine;
    FText: array[0..ENGINE_CONSOLE_LINES - 1] of string;
    FHead: Integer;
    FWidth: Integer;
    FHeight: Integer;
    FPageUpDown: Integer;
    FPosition: Integer;
    FMaxPosition: Integer;
    FStep: Integer;
    FLineBuffer: string;
    FState: TConsoleState;
    FRaiseTicks: Integer;
    FLowerTicks: Integer;
    FInitialized: Boolean;
    FPaused: Boolean;
    FPausedText: string;
    FHistory: TDStringList;
    FShiftDown: Boolean;
    FFirstKey: Boolean;
    FCursorOn: Boolean;
    FCursorTicker: Integer;
    FCursorX: Integer;
    FCursorY: Integer;
    FCursorNeedsUpdate: Boolean;
    class procedure WriteOutput(const AText: string); static;
    class function IsDivideLine(const AText: string): Boolean; static;
    procedure RegisterCommands;
    procedure ShowCommandLineParameters(const AMask: string);
    procedure ShowCommandLine;
    procedure CloseConsole(const ATicks: string);
    procedure OpenConsole(const ATicks: string);
    procedure SetColormap(const AColormap: string);
    procedure Clear;
    procedure UseMnemonic(const AName, AParameter: string);
    procedure ToggleFreeze;
    procedure RestoreFromHistory;
    procedure AddLine(const ALine: string);
    procedure PageUp;
    procedure PageDown;
    procedure DrawBackground;
    procedure FreeOwned;
  public
    /// <param name="ARegistry">Where the console registers its own commands</param>
    /// <param name="AInterpreter">Runs the commands that the console calls by name (use)</param>
    /// <param name="ACommandLine">What the commands "cmdline" and "commandlineparams" show</param>
    /// <remarks>
    ///   The console owns the objects of Libs\Console and frees them in Shutdown (or when it is
    ///   destroyed). Raises EArgumentNilException if one of them is nil
    /// </remarks>
    constructor Create(const ARegistry: ICommandRegistry; const AInterpreter: IConsoleInterpreter;
      const AStandard: TConsoleStandardCommands; const AAutoExec: TConsoleAutoExec;
      const AVariables: TConsoleVariableCommands; const AQueue: TConsoleCommandQueue;
      const AInput: TConsoleInputLine; const ACommandLine: IQueriedCommandLine);
    destructor Destroy; override;
    procedure Initialize;
    procedure Shutdown;
    procedure AdjustScreenSize;
    procedure AddCommand(const ACommand: string);
    procedure AddText(const AText: string);
    procedure Draw;
    procedure Tick;
    function Respond(const AEvent: Pevent_t): Boolean;
    function IsActive: Boolean;
    function Position: Integer;
  end;

implementation

uses
{$IFDEF HEXEN}
  g_demo,
{$ENDIF}
{$IFDEF STRIFE}
  d_check,
{$ENDIF}
{$IFDEF DOOM}
  doomstat,
{$ENDIF}
  doomdef,
  DelphiDoom.Console.MaskMatcher,
  c_cmds,
  c_con,
  c_utils,
  d_main,
  g_game,
  hu_stuff,
  m_fixed,
  i_io,
  p_tick,
  r_defs,
  r_main,
  v_data,
  v_video,
  w_utils,
  w_wad,
  z_zone;

const
  CONSOLE_LINES_MASK = ENGINE_CONSOLE_LINES - 1;
  MAX_CONSOLE_HISTORY = 16384;
  BLINK_RATE = TICRATE * 3 div 4;
  FIXED_PITCH_CHARS = ['1'..'9', '0', '.', '=', '-'];
{$IFDEF STRIFE}
  FONT_WIDTH = 10;
  FONT_HEIGHT = 10;
{$ELSE}
  FONT_WIDTH = 8;
  FONT_HEIGHT = 8;
{$ENDIF}

  SRegistryIsNil = 'TEngineConsoleScreen: the registry of the commands is nil';
  SInterpreterIsNil = 'TEngineConsoleScreen: the interpreter is nil';
  SStandardIsNil = 'TEngineConsoleScreen: the standard commands are nil';
  SAutoExecIsNil = 'TEngineConsoleScreen: the autoexec is nil';
  SVariablesIsNil = 'TEngineConsoleScreen: the commands of the variables are nil';
  SQueueIsNil = 'TEngineConsoleScreen: the queue of the commands is nil';
  SInputIsNil = 'TEngineConsoleScreen: the line of input is nil';
  SCommandLineIsNil = 'TEngineConsoleScreen: the command line is nil';

{ TEngineConsoleScreen }

constructor TEngineConsoleScreen.Create(const ARegistry: ICommandRegistry;
  const AInterpreter: IConsoleInterpreter; const AStandard: TConsoleStandardCommands;
  const AAutoExec: TConsoleAutoExec; const AVariables: TConsoleVariableCommands;
  const AQueue: TConsoleCommandQueue; const AInput: TConsoleInputLine;
  const ACommandLine: IQueriedCommandLine);
begin
  inherited Create;
  if not Assigned(ARegistry) then
    raise EArgumentNilException.Create(SRegistryIsNil);
  if not Assigned(AInterpreter) then
    raise EArgumentNilException.Create(SInterpreterIsNil);
  if not Assigned(AStandard) then
    raise EArgumentNilException.Create(SStandardIsNil);
  if not Assigned(AAutoExec) then
    raise EArgumentNilException.Create(SAutoExecIsNil);
  if not Assigned(AVariables) then
    raise EArgumentNilException.Create(SVariablesIsNil);
  if not Assigned(AQueue) then
    raise EArgumentNilException.Create(SQueueIsNil);
  if not Assigned(AInput) then
    raise EArgumentNilException.Create(SInputIsNil);
  if not Assigned(ACommandLine) then
    raise EArgumentNilException.Create(SCommandLineIsNil);
  FCommandLine := ACommandLine;
  FRegistry := ARegistry;
  FInterpreter := AInterpreter;
  FStandard := AStandard;
  FAutoExec := AAutoExec;
  FVariables := AVariables;
  FQueue := AQueue;
  FInput := AInput;
  FPageUpDown := -1;
  FFirstKey := True;
  FCursorTicker := BLINK_RATE;
  FCursorNeedsUpdate := True;
end;

destructor TEngineConsoleScreen.Destroy;
begin
  if FOutputConsole = Self then
    FOutputConsole := nil;
  FreeOwned;
  inherited Destroy;
end;

procedure TEngineConsoleScreen.FreeOwned;
begin
  FreeAndNil(FAutoExec);
  FreeAndNil(FStandard);
  FreeAndNil(FVariables);
  FreeAndNil(FQueue);
  FreeAndNil(FInput);
  FreeAndNil(FHistory);
end;

class procedure TEngineConsoleScreen.WriteOutput(const AText: string);
begin
  if FOutputConsole <> nil then
    FOutputConsole.AddText(AText);
end;

class function TEngineConsoleScreen.IsDivideLine(const AText: string): Boolean;
var
  LIndex: Integer;
begin
  Result := Length(AText) > 3;
  if Result then
    for LIndex := 1 to Length(AText) do
      // in and not CharInSet: a character is reduced to a byte, as in the old code
      if not (AText[LIndex] in ['-', '=']) then
        Exit(False);
end;

// The parameters that the program asked for, as M_CmdShowCommandLineParams did
procedure TEngineConsoleScreen.ShowCommandLineParameters(const AMask: string);
var
  LMask: string;
  LNames: TArray<string>;
  LIndex: Integer;
begin
  if AMask = '' then
    LMask := '*'
  else
    LMask := AMask;
  LNames := TConsoleMaskMatcher.Filter(FCommandLine.QueriedNames, LMask);
  printf('Command line parameters: '#13#10);
  for LIndex := 0 to Length(LNames) - 1 do
    printf(' %s'#13#10, [LNames[LIndex]]);
end;

// The arguments without the name of the program, as M_CmdShowCmdline did
procedure TEngineConsoleScreen.ShowCommandLine;
var
  LIndex: Integer;
begin
  for LIndex := 1 to FCommandLine.Count - 1 do
    printf('%s ', [FCommandLine[LIndex]]);
  printf(#13#10);
end;

procedure TEngineConsoleScreen.CloseConsole(const ATicks: string);
var
  LTicks: Integer;
begin
  LTicks := atoi(ATicks);
  if LTicks <= 0 then
    FState := csRaise
  else
    FRaiseTicks := LTicks;
end;

procedure TEngineConsoleScreen.OpenConsole(const ATicks: string);
var
  LTicks: Integer;
begin
  LTicks := atoi(ATicks);
  if LTicks <= 0 then
    FState := csLower
  else
    FLowerTicks := LTicks;
end;

procedure TEngineConsoleScreen.SetColormap(const AColormap: string);
var
  LColormap: Integer;
begin
  LColormap := atoi(AColormap);
  if (AColormap = '') or (LColormap < 0) or (LColormap >= NUMCOLORMAPS) then
  begin
    printf('Please specify a parameter in range [0..%d]'#13#10, [NUMCOLORMAPS - 1]);
    printf('Current console colormap: %d'#13#10, [ConsoleColormap]);
  end
  else
    ConsoleColormap := LColormap;
end;

procedure TEngineConsoleScreen.Clear;
var
  LIndex: Integer;
begin
  for LIndex := 0 to ENGINE_CONSOLE_LINES - 1 do
    FText[LIndex] := '';
  FInput.Reset;
end;

procedure TEngineConsoleScreen.UseMnemonic(const AName, AParameter: string);
begin
  if AName = '' then
  begin
    FInterpreter.Execute('cmdlist', 'use*');
    Exit;
  end;

  // the old text, without arguments: the %s is printed as it is
  if not FInterpreter.Execute('use' + AName, AParameter) then
    printf('%s mnemonic not found!'#13#10);
end;

procedure TEngineConsoleScreen.ToggleFreeze;
begin
  if demoplayback or demorecording then
  begin
    printf('Can not freeze game while demo playback/recording'#13#10);
    Exit;
  end;

  isgamefreezed := not isgamefreezed;

  if isgamefreezed then
    printf('Game is freezed'#13#10)
  else
    printf('Game is not freezed'#13#10);
end;

procedure TEngineConsoleScreen.RegisterCommands;
begin
  FRegistry.Add('closeconsole',
    procedure(const AParam1, AParam2: string)
    begin
      CloseConsole(AParam1);
    end);
  // for the autoexec
  FRegistry.Add('openconsole',
    procedure(const AParam1, AParam2: string)
    begin
      OpenConsole(AParam1);
    end);
  FRegistry.Add('consolecolormap',
    procedure(const AParam1, AParam2: string)
    begin
      SetColormap(AParam1);
    end);
  FRegistry.Add('cls, clearscreen',
    procedure(const AParam1, AParam2: string)
    begin
      Clear;
    end);
  // the commands of the game keep the old way: they get both parameters, whatever their own declaration
  C_AddCmd('screenshot', @G_ScreenShot);
  C_AddCmd('playdemo', @G_CmdPlayDemo);
  C_AddCmd('start, playgame, engage, visit'{$IFDEF STRIFE} + ', rift'{$ENDIF}, @G_CmdNewGame);
{$IFDEF DOOM}
  C_AddCmd('testmap,test', @G_CmdTestMap);
{$ENDIF}
  C_AddCmd('load, loadgame', @G_LoadGame);
  C_AddCmd('save, savegame', @G_CmdSaveGame);
  FStandard.Register; // cmdlist, exec and printf
  FVariables.Register; // set, get and typeof
  FRegistry.Add('pause_console, pauseconsole',
    procedure(const AParam1, AParam2: string)
    begin
      FPaused := True;
    end);
  FRegistry.Add('commandlineparams',
    procedure(const AParam1, AParam2: string)
    begin
      ShowCommandLineParameters(AParam1);
    end);
  FRegistry.Add('cmdline',
    procedure(const AParam1, AParam2: string)
    begin
      ShowCommandLine;
    end);
  FRegistry.Add('use',
    procedure(const AParam1, AParam2: string)
    begin
      UseMnemonic(AParam1, AParam2);
    end);
  FRegistry.Add('freeze',
    procedure(const AParam1, AParam2: string)
    begin
      ToggleFreeze;
    end);
  C_RegisterUtilityCommands;
  W_RegisterUtilityCommands;
end;

procedure TEngineConsoleScreen.Initialize;
var
  LIndex: Integer;
begin
  FHistory := TDStringList.Create;
  FHead := 0;
  FState := csUp;
  for LIndex := 0 to ENGINE_CONSOLE_LINES - 1 do
    FText[LIndex] := '';
  FInput.Reset;
  AdjustScreenSize;
  FInitialized := True;
  FQueue.Enabled := True;

  AddText(stdoutbuffer.Text);
  FOutputConsole := Self;
  outproc := WriteOutput;

  RegisterCommands;
end;

procedure TEngineConsoleScreen.Shutdown;
begin
  FInitialized := False;
  if FQueue <> nil then
    FQueue.Enabled := False;
  FreeOwned;
end;

procedure TEngineConsoleScreen.AdjustScreenSize;
begin
  FStep := V_GetScreenHeight(SCN_CON) div 20;
  FMaxPosition := FStep * 11;
  FWidth := V_GetScreenWidth(SCN_CON) div FONT_WIDTH - 2;
  FPosition := 0;
end;

procedure TEngineConsoleScreen.AddCommand(const ACommand: string);
begin
  if not FInitialized then
    Exit;
  FQueue.Enqueue(ACommand);
end;

procedure TEngineConsoleScreen.RestoreFromHistory;
var
  LIndex: Integer;
begin
  if not FInitialized then
    Exit;
  for LIndex := FHistory.Count - ENGINE_CONSOLE_LINES to FHistory.Count - 1 do
  begin
    FHead := (FHead + CONSOLE_LINES_MASK) and CONSOLE_LINES_MASK;
    if LIndex >= 0 then
      FText[FHead] := FHistory.Strings[LIndex]
    else
      FText[FHead] := '';
  end;
  FText[(FHead + CONSOLE_LINES_MASK) and CONSOLE_LINES_MASK] := '';
end;

procedure TEngineConsoleScreen.AddLine(const ALine: string);
var
  LLine: string;
  LIndex: Integer;
begin
  if not FInitialized then
    Exit;

  if ALine = '' then
    LLine := ' '
  else
  begin
    LLine := '';
    for LIndex := 1 to Length(ALine) do
    begin
      if ALine[LIndex] = #8 then
      begin
        if LLine <> '' then
          SetLength(LLine, Length(LLine) - 1);
      end
      else
        LLine := LLine + ALine[LIndex];
    end;
  end;
  if FPaused then
    FPausedText := FPausedText + LLine + #13#10
  else
  begin
    if FPageUpDown <> -1 then
    begin
      RestoreFromHistory;
      FPageUpDown := -1;
    end;

    FHead := (FHead + CONSOLE_LINES_MASK) and CONSOLE_LINES_MASK;
    FText[FHead] := LLine;
    FHistory.Add(LLine);
    if FHistory.Count > MAX_CONSOLE_HISTORY then
      for LIndex := 0 to MAX_CONSOLE_HISTORY div 100 do
        FHistory.Delete(0);
    FText[(FHead + CONSOLE_LINES_MASK) and CONSOLE_LINES_MASK] := '';
    FInput.NeedsUpdate := True;
  end;
end;

procedure TEngineConsoleScreen.PageUp;
var
  LIndex: Integer;
begin
  if FHistory.Count < FHeight then
    Exit; // Too short output to page up

  if FPageUpDown = 0 then
    Exit; // At the top

  if FPageUpDown = -1 then
    FPageUpDown := FHistory.Count - 2 * FHeight
  else
    FPageUpDown := FPageUpDown - FHeight;
  if FPageUpDown < 0 then
    FPageUpDown := 0;

  for LIndex := FPageUpDown to FPageUpDown + FHeight - 1 do
  begin
    FHead := (FHead + CONSOLE_LINES_MASK) and CONSOLE_LINES_MASK;
    if LIndex < FHistory.Count then
      FText[FHead] := FHistory.Strings[LIndex]
    else
      FText[FHead] := '';
  end;
  FText[(FHead + CONSOLE_LINES_MASK) and CONSOLE_LINES_MASK] := '';
  FInput.NeedsUpdate := True;
end;

procedure TEngineConsoleScreen.PageDown;
var
  LIndex: Integer;
begin
  if FHistory.Count < FHeight then
    Exit; // Too short output to page up

  if FPageUpDown = -1 then
    Exit; // At the end

  if FPageUpDown >= FHistory.Count - FHeight then
    FPageUpDown := FPageUpDown - 2 * FHeight
  else
    FPageUpDown := FPageUpDown + FHeight;

  if FPageUpDown >= FHistory.Count - FHeight then
  begin
    RestoreFromHistory;
    FPageUpDown := -1;
    FInput.NeedsUpdate := True;
    Exit;
  end;

  for LIndex := FPageUpDown to FPageUpDown + FHeight - 1 do
  begin
    FHead := (FHead + CONSOLE_LINES_MASK) and CONSOLE_LINES_MASK;
    if LIndex >= 0 then
      FText[FHead] := FHistory.Strings[LIndex]
    else
      FText[FHead] := '';
  end;
  FText[(FHead + CONSOLE_LINES_MASK) and CONSOLE_LINES_MASK] := '';
  FInput.NeedsUpdate := True;
end;

procedure TEngineConsoleScreen.AddText(const AText: string);
var
  LIndex: Integer;
  LChar: Char;
begin
  if mirror_stdout then
    fprintf(stdout, AText);

  if not FInitialized then
    Exit;

  for LIndex := 1 to Length(AText) do
  begin
    LChar := AText[LIndex];
    if LChar = #13 then
      AddLine(FLineBuffer)
    else if LChar = #10 then
      FLineBuffer := ''
    else
      FLineBuffer := FLineBuffer + LChar;
  end;
end;

function TEngineConsoleScreen.Respond(const AEvent: Pevent_t): Boolean;
var
  LKey: Integer;
begin
  if not FInitialized then
    Exit(False);

  if FFirstKey then
  begin
    FAutoExec.Run;
    FFirstKey := False;
  end;

  FQueue.ExecutePending;

  if (AEvent._type <> ev_keyup) and (AEvent._type <> ev_keydown) then
    Exit(False);

  LKey := AEvent.data1;
  if LKey = KEY_RSHIFT then
    FShiftDown := AEvent._type = ev_keydown;

  case FState of
    csDown,
    csLower:
      begin
        if AEvent._type = ev_keydown then
        begin
          if FPaused then
          begin
            FPaused := False;
            AddText(FPausedText);
            FPausedText := '';
          end
          else
          case LKey of
            KEY_CON:
              FState := csRaise;
            KEY_ESCAPE:
              begin
                if not FInput.IsEmpty then
                  FInput.Reset
                else
                  FState := csRaise
              end;
            KEY_ENTER:
              FInput.Submit;
            KEY_UPARROW:
              FInput.HistoryPrevious;
            KEY_DOWNARROW:
              FInput.HistoryNext;
            KEY_TAB:
              FInput.Complete;
            KEY_BACKSPACE:
              FInput.Backspace;
            KEY_PAGEUP:
              PageUp;
            KEY_PAGEDOWN:
              PageDown;
          else
            begin
              LKey := Ord(toupper(Chr(LKey)));
              if ((LKey >= Ord(HU_FONTSTART)) and (LKey <= Ord({$IFDEF DOOM_OR_STRIFE}HU_FONTEND{$ELSE}HU_CFONTEND{$ENDIF}))) or
                 (Chr(LKey) in [' ', '.', '!', '-', '+', '=', '*', '/', '\']) then
              begin
                if FShiftDown then
                  LKey := Ord(shiftxform[LKey]);
                FInput.AppendChar(Chr(LKey));
              end;
            end;
          end;
          Exit(True);
        end;
      end;
    csUp,
    csRaise:
      begin
        if (LKey = Ord('~')) and (AEvent._type = ev_keydown) then
        begin
          FState := csLower;
          Exit(True);
        end;
      end;
  end;

  if (AEvent._type = ev_keydown) and ((devparm and (LKey = KEY_F1)) or (LKey = KEY_PRNT)) then
  begin
    G_ScreenShot;
    Exit(True);
  end;

  Result := False;
end;

procedure TEngineConsoleScreen.Tick;
begin
  if not FInitialized then
    Exit;

  if FRaiseTicks > 0 then
  begin
    Dec(FRaiseTicks);
    if FRaiseTicks = 0 then
      FState := csRaise;
  end;

  if FLowerTicks > 0 then
  begin
    Dec(FLowerTicks);
    if FLowerTicks = 0 then
      FState := csLower;
  end;

  case FState of
    csLower:
      begin
        Inc(FPosition, FStep);
        if FPosition >= FMaxPosition then
        begin
          FState := csDown;
          FMaxPosition := (1 + FHeight) * FONT_HEIGHT;
          FPosition := FMaxPosition; // Crop the maximum position
        end
        else
          FHeight := FPosition div FONT_HEIGHT;
        FInput.NeedsUpdate := True;
      end;
    csRaise:
      begin
        if FPosition < FMaxPosition div 5 then
          Dec(FPosition, FStep)
        else
          Dec(FPosition, 2 * FStep); // Raise console faster...
        if FPosition <= 0 then
        begin
          FState := csUp;
          FPosition := 0;
          FHeight := 0;
        end
        else
          FHeight := FPosition div FONT_HEIGHT;
        FInput.NeedsUpdate := True;
      end;
  end;

  // Decide of cursor visibility
  Dec(FCursorTicker);
  if FCursorTicker = 0 then
  begin
    FCursorOn := not FCursorOn;
    FCursorTicker := BLINK_RATE;
    if FCursorOn then
      FCursorNeedsUpdate := True
    else
      FInput.NeedsUpdate := True;
  end;
end;

procedure TEngineConsoleScreen.DrawBackground;
begin
{$IFDEF DOOM}
  V_DrawPatchFullScreenTMP320x200(decide(customgame = cg_bfg2, pg_DMENUPIC, pg_TITLE));
{$ENDIF}
{$IFDEF HERETIC_OR_HEXEN}
  V_CopyRawDataToScreen(SCN_TMP, 'TITLE');
{$ENDIF}
{$IFDEF STRIFE}
  V_DrawPatchFullScreenTMP320x200(char8tostring(W_GetNameForNum(D_Help0Lump)));
{$ENDIF}

  // A little bit darker background...
  R_ApplyColormap(0, 320 * 200, SCN_TMP, ConsoleColormap);

  V_CopyRect(0, 0, SCN_TMP, 320, 200, 0, 0, SCN_CON, true);
end;

procedure TEngineConsoleScreen.Draw;
var
  LLine: Integer;
  LY: Integer;
  LIndex: Integer;
  LChar: Char;
  LX: Integer;
  LLength: Integer;
  LLinesLeft: Integer;
  LXMax: Integer;
  LPatch: Ppatch_t;
begin
  if not FInitialized then
    Exit;

  if FHeight <= 0 then
    Exit;

  LXMax := (FWidth{$IFDEF DOOM} + 1{$ENDIF}) * FONT_WIDTH;

  if FInput.NeedsUpdate then
  begin
    DrawBackground;

    LLine := FHead;
    LLinesLeft := FHeight;
    while (FText[LLine] <> '') and (LLinesLeft > 0) do
    begin
      LX := FONT_WIDTH;
      LLength := Length(FText[LLine]);
      if FPageUpDown = -1 then
        LLinesLeft := LLinesLeft - (LLength - 1) div FWidth - 1
      else
        LLinesLeft := LLinesLeft - 1;
      LIndex := 1;
      if LLinesLeft < 0 then
      begin
        LIndex := LIndex - FWidth * LLinesLeft;
        LLinesLeft := 0;
      end;
      LY := V_GetScreenHeight(SCN_CON) - (FHeight - LLinesLeft + 1) * FONT_HEIGHT;
      if IsDivideLine(FText[LLine]) then
      begin
        LPatch := W_CacheLumpName({$IFDEF DOOM_OR_STRIFE}'brdr_t'{$ELSE}'BORDB'{$ENDIF}, PU_STATIC);
        if LLength > FWidth then
          LLength := FWidth;
        for LIndex := 1 to LLength do
        begin
          V_DrawPatch(LX, LY + 2{$IFDEF DOOM_OR_STRIFE} - 4{$ENDIF}, SCN_CON, LPatch, false);
          LX := LX + 8;
        end;
        Z_ChangeTag(LPatch, PU_CACHE);
      end
      else
      begin
        while LIndex <= LLength do
        begin
          LChar := toupper(FText[LLine][LIndex]);
          if (LChar >= HU_FONTSTART) and (LChar <= {$IFDEF DOOM_OR_STRIFE}HU_FONTEND{$ELSE}HU_CFONTEND{$ENDIF}) then
          begin
            LPatch := {$IFDEF DOOM_OR_STRIFE}hu_font{$ELSE}hu_font3{$ENDIF}[Ord(LChar) - Ord(HU_FONTSTART)];
            if LChar in FIXED_PITCH_CHARS then
            begin
              V_DrawPatch(LX + FONT_WIDTH - LPatch.width, LY, SCN_CON, LPatch, false);
              LX := LX + FONT_WIDTH;
            end
            else
            begin
              V_DrawPatch(LX, LY, SCN_CON, LPatch, false);
              LX := LX + LPatch.width + 1;
            end;
          end
          else
            LX := LX + FONT_WIDTH;
          if LX > LXMax then
          begin
            if FPageUpDown = -1 then
            begin
              LX := FONT_WIDTH;
              LY := LY + FONT_HEIGHT;
            end
            else
              Break;
          end;
          Inc(LIndex);
        end;
      end;
      LLine := (LLine + 1) and CONSOLE_LINES_MASK;
    end;

    LX := FONT_WIDTH;
    LY := V_GetScreenHeight(SCN_CON) - FONT_HEIGHT;
    for LIndex := 1 to Length(FInput.Buffer) do
    begin
      LChar := toupper(FInput.Buffer[LIndex]);
      if (LChar >= HU_FONTSTART) and (LChar <= {$IFDEF DOOM_OR_STRIFE}HU_FONTEND{$ELSE}HU_CFONTEND{$ENDIF}) and (LX < LXMax) then
      begin
        LPatch := {$IFDEF DOOM_OR_STRIFE}hu_font{$ELSE}hu_font3{$ENDIF}[Ord(LChar) - Ord(HU_FONTSTART)];
        if LChar in FIXED_PITCH_CHARS then
        begin
          V_DrawPatch(LX + FONT_WIDTH - LPatch.width, LY, SCN_CON, LPatch, false);
          LX := LX + FONT_WIDTH;
        end
        else
        begin
          V_DrawPatch(LX, LY, SCN_CON, LPatch, false);
          LX := LX + LPatch.width + 1;
        end;
      end
      else
        LX := LX + FONT_WIDTH;
    end;

    if FCursorOn and (LX < LXMax) then
    begin
      LPatch := {$IFDEF DOOM_OR_STRIFE}hu_font{$ELSE}hu_font3{$ENDIF}[Ord('_') - Ord(HU_FONTSTART)];
      V_DrawPatch(LX, LY, SCN_CON, LPatch, false);
    end;
    FCursorX := LX;
    FCursorY := LY;

    FInput.NeedsUpdate := False;
    FCursorNeedsUpdate := False;
  end
  else if FCursorNeedsUpdate then
  begin
    if FCursorOn and (FCursorX < LXMax) then
    begin
      LPatch := {$IFDEF DOOM_OR_STRIFE}hu_font{$ELSE}hu_font3{$ENDIF}[Ord('_') - Ord(HU_FONTSTART)];
      V_DrawPatch(FCursorX, FCursorY, SCN_CON, LPatch, false);
    end;
    FCursorNeedsUpdate := False;
  end;

  V_CopyAddRect(0, V_GetScreenHeight(SCN_CON) - FPosition, SCN_CON,
    V_GetScreenWidth(SCN_CON), FPosition, 0, 0, SCN_FG,
      false,
        (FMaxPosition - FPosition) * FRACUNIT div FMaxPosition);
end;

function TEngineConsoleScreen.IsActive: Boolean;
begin
  Result := FState <> csUp;
end;

function TEngineConsoleScreen.Position: Integer;
begin
  Result := FPosition;
end;

end.
