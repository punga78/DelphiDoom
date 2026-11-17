{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 host library - the console                               }
{                                                                              }
{  Port of Doom 3 (id Software): framework\Console.cpp (idConsoleLocal) and    }
{  Console.h, without the drawing (DrawInput, DrawNotify, DrawSolidConsole,    }
{  the SCR_Draw* statistics and LoadGraphics need the renderer).               }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version, with the additional terms of the Doom 3 Source   }
{  Code License (Reference\doom3\COPYING.txt: preservation of legal notices    }
{  and trademarks, no use of the licensors' names for publicity, warranty      }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.D3Host.Console;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Text.CmdArgs, DelphiDoom.Console.CmdSystem.Types,
  DelphiDoom.Console.CmdSystem.Intf, DelphiDoom.D3Host.Types, DelphiDoom.D3Host.Intf, DelphiDoom.D3Host.Input.Intf,
  DelphiDoom.D3Host.EditField, DelphiDoom.D3Host.Lifecycle.Intf;

const
  /// <summary>LINE_WIDTH of Console.cpp</summary>
  D3_CON_LINE_WIDTH = 78;
  /// <summary>NUM_CON_TIMES</summary>
  D3_CON_NUM_TIMES = 4;
  /// <summary>CON_TEXTSIZE</summary>
  D3_CON_TEXTSIZE = $30000;
  /// <summary>TOTAL_LINES</summary>
  D3_CON_TOTAL_LINES = D3_CON_TEXTSIZE div D3_CON_LINE_WIDTH;
  /// <summary>COMMAND_HISTORY</summary>
  D3_CON_COMMAND_HISTORY = 64;

type
  /// <summary>
  ///   The console without the screen: the text of the last 2520 lines (a cell is the character and a color index
  ///   in the high byte), the printing with word wrap, the line being edited and its history of 64 lines, the
  ///   scroll, the key that opens it and the fraction of the screen it takes. It is also the console that Printf
  ///   prints to (ID3CommonConsole). The text starts as zeros, like the static buffer of the original.
  /// </summary>
  TD3Console = class(TInterfacedObject, ID3CommonConsole, ID3ConsoleControl)
  strict private
    FCommands: ICmdCommands;
    FBuffer: ICmdBuffer;
    FPrinter: ID3Printer;
    FWarnings: ID3WarningSink;
    FKeys: ID3KeyStates;
    FBindings: ID3KeyBindingExecutor;
    FCVars: ID3CommonCVars;
    FCVarValues: ID3CVarValues;
    FPlatform: ID3ConsolePlatform;
    FClock: ID3EventClock;
    FScreen: ID3ScreenUpdater;
    FFiles: ID3CommonFileSystem;
    FState: TD3CommonState;
    FKeyCatching: Boolean;
    FText: TArray<SmallInt>;
    FCurrent: Integer;
    FX: Integer;
    FDisplay: Integer;
    FLastKeyEvent: Integer;
    FNextKeyEvent: Integer;
    FDisplayFrac: Single;
    FFinalFrac: Single;
    FFracTime: Integer;
    FTimes: array[0..D3_CON_NUM_TIMES - 1] of Integer;
    FHistoryEditLines: array[0..D3_CON_COMMAND_HISTORY - 1] of TD3EditField;
    FNextHistoryLine: Integer;
    FHistoryLine: Integer;
    FConsoleField: TD3EditField;
    procedure ClearCommand(const AArgs: TIdCmdArgs);
    procedure DumpCommand(const AArgs: TIdCmdArgs);
    procedure KeyDownEvent(const AKey: Integer);
    procedure Linefeed;
    procedure PageUp;
    procedure PageDown;
    procedure Top;
    procedure Bottom;
    procedure SetDisplayFraction(const AFraction: Single);
    function ColorCell(const AColor: Integer; const AChar: Integer): SmallInt;
  public
    constructor Create(const AState: TD3CommonState; const ACommands: ICmdCommands; const ABuffer: ICmdBuffer;
      const APrinter: ID3Printer; const AWarnings: ID3WarningSink; const AKeys: ID3KeyStates;
      const ABindings: ID3KeyBindingExecutor; const ACVars: ID3CommonCVars; const ACVarValues: ID3CVarValues;
      const APlatform: ID3ConsolePlatform; const AClock: ID3EventClock; const AScreen: ID3ScreenUpdater;
      const AFiles: ID3CommonFileSystem; const AFieldEnvironment: TD3EditFieldEnvironment);
    destructor Destroy; override;
    /// <summary>idConsoleLocal::Init: the key catching off, the fields cleared (78 wide), the commands clear and conDump</summary>
    procedure Init;
    procedure Shutdown;
    /// <summary>
    ///   idConsoleLocal::ProcessEvent: the console key opens and closes it; while it is open characters and keys
    ///   edit the line; true if the event was used
    /// </summary>
    function ProcessEvent(const AEvent: TD3SysEvent; const AForceAccept: Boolean): Boolean;
    function Active: Boolean;
    procedure ClearNotifyLines;
    procedure Close;
    /// <summary>idConsoleLocal::Print: color codes, word wrap at 78 columns, tabs to a multiple of 4, carriage return</summary>
    procedure Print(const AText: AnsiString);
    /// <summary>idConsoleLocal::Clear: the whole text to blanks in cyan, and the display to the last line</summary>
    procedure Clear;
    /// <summary>idConsoleLocal::Dump: the lines to a file, without the empty ones at the start and the blanks at the end</summary>
    procedure Dump(const AFileName: AnsiString);
    /// <summary>idConsoleLocal::Scroll: the repeat of PgUp and PgDn while they are held</summary>
    procedure Scroll;
    /// <summary>idConsoleLocal::UpdateDisplayFraction: moves the fraction towards its target at con_speed</summary>
    procedure UpdateDisplayFraction;
    function Cell(const ALine, AColumn: Integer): Integer;
    function CurrentLine: Integer;
    function Column: Integer;
    function DisplayLine: Integer;
    function KeyCatching: Boolean;
    function LastKeyEvent: Integer;
    function NextKeyEvent: Integer;
    function DisplayFraction: Single;
    function FinalFraction: Single;
    function FractionTime: Integer;
    function NotifyTime(const AIndex: Integer): Integer;
    function NextHistory: Integer;
    function HistoryLine: Integer;
    function HistoryText(const AIndex: Integer): AnsiString;
    property Field: TD3EditField read FConsoleField;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Str, DelphiDoom.D3Host.Input.Types;

const
  CONSOLE_FIRSTREPEAT = 200;
  CONSOLE_REPEAT = 100;
  C_COLOR_CYAN_INDEX = 5;
  CMD_FL_SYSTEM_FLAG = 2;
  SDumpUsage = 'usage: conDump <filename>' + #10;
  SUiChat = 'ui_chat';

function SignedChar(const AValue: Integer): Integer;
begin
  // the char of the compiler of the original is signed
  Result := ShortInt(Byte(AValue));
end;

constructor TD3Console.Create(const AState: TD3CommonState; const ACommands: ICmdCommands; const ABuffer: ICmdBuffer;
  const APrinter: ID3Printer; const AWarnings: ID3WarningSink; const AKeys: ID3KeyStates;
  const ABindings: ID3KeyBindingExecutor; const ACVars: ID3CommonCVars; const ACVarValues: ID3CVarValues;
  const APlatform: ID3ConsolePlatform; const AClock: ID3EventClock; const AScreen: ID3ScreenUpdater;
  const AFiles: ID3CommonFileSystem; const AFieldEnvironment: TD3EditFieldEnvironment);
var
  LIndex: Integer;
begin
  inherited Create;
  FState := AState;
  FCommands := ACommands;
  FBuffer := ABuffer;
  FPrinter := APrinter;
  FWarnings := AWarnings;
  FKeys := AKeys;
  FBindings := ABindings;
  FCVars := ACVars;
  FCVarValues := ACVarValues;
  FPlatform := APlatform;
  FClock := AClock;
  FScreen := AScreen;
  FFiles := AFiles;
  SetLength(FText, D3_CON_TEXTSIZE);
  FConsoleField := TD3EditField.Create(AFieldEnvironment);
  for LIndex := 0 to D3_CON_COMMAND_HISTORY - 1 do
    FHistoryEditLines[LIndex] := TD3EditField.Create(AFieldEnvironment);
end;

destructor TD3Console.Destroy;
var
  LIndex: Integer;
begin
  for LIndex := 0 to D3_CON_COMMAND_HISTORY - 1 do
    FHistoryEditLines[LIndex].Free;
  FConsoleField.Free;
  inherited Destroy;
end;

function TD3Console.ColorCell(const AColor: Integer; const AChar: Integer): SmallInt;
begin
  Result := SmallInt((AColor shl 8) or AChar);
end;

procedure TD3Console.ClearCommand(const AArgs: TIdCmdArgs);
begin
  Clear;
end;

procedure TD3Console.DumpCommand(const AArgs: TIdCmdArgs);
var
  LName: TIdStr;
begin
  if AArgs.Argc <> 2 then
  begin
    FPrinter.Printf(SDumpUsage);
    Exit;
  end;
  LName := TIdStr.Create(AArgs.Argv(1));
  LName.DefaultFileExtension('.txt');
  FPrinter.Printf('Dumped console text to ' + LName.Text + '.' + #10);
  Dump(LName.Text);
end;

procedure TD3Console.Init;
var
  LIndex: Integer;
begin
  FKeyCatching := False;
  FLastKeyEvent := -1;
  FNextKeyEvent := CONSOLE_FIRSTREPEAT;
  FConsoleField.Clear;
  FConsoleField.SetWidthInChars(D3_CON_LINE_WIDTH);
  for LIndex := 0 to D3_CON_COMMAND_HISTORY - 1 do
  begin
    FHistoryEditLines[LIndex].Clear;
    FHistoryEditLines[LIndex].SetWidthInChars(D3_CON_LINE_WIDTH);
  end;
  FCommands.AddCommand('clear', ClearCommand, CMD_FL_SYSTEM_FLAG, 'clears the console');
  FCommands.AddCommand('conDump', DumpCommand, CMD_FL_SYSTEM_FLAG, 'dumps the console text to a file');
end;

procedure TD3Console.Shutdown;
begin
  FCommands.RemoveCommand('clear');
  FCommands.RemoveCommand('conDump');
end;

function TD3Console.Active: Boolean;
begin
  Result := FKeyCatching;
end;

procedure TD3Console.ClearNotifyLines;
var
  LIndex: Integer;
begin
  for LIndex := 0 to D3_CON_NUM_TIMES - 1 do
    FTimes[LIndex] := 0;
end;

procedure TD3Console.Close;
begin
  FKeyCatching := False;
  SetDisplayFraction(0);
  FDisplayFrac := 0; // don't scroll to that point, go immediately
  ClearNotifyLines;
end;

procedure TD3Console.Clear;
var
  LIndex: Integer;
begin
  for LIndex := 0 to D3_CON_TEXTSIZE - 1 do
    FText[LIndex] := ColorCell(C_COLOR_CYAN_INDEX, Ord(' '));
  Bottom; // go to end
end;

procedure TD3Console.Dump(const AFileName: AnsiString);
var
  LFile: ID3CommonFile;
  LLine: Integer;
  LColumn: Integer;
  LBase: Integer;
  LBuffer: array[0..D3_CON_LINE_WIDTH + 2] of Byte;
  LText: AnsiString;
  LLength: Integer;
  LBlank: Boolean;
begin
  LFile := FFiles.OpenFileWrite(AFileName, 'fs_savepath');
  if not Assigned(LFile) then
  begin
    FWarnings.Warning('couldn''t open ' + AFileName);
    Exit;
  end;
  // skip empty lines
  LLine := FCurrent - D3_CON_TOTAL_LINES + 1;
  if LLine < 0 then
    LLine := 0;
  while LLine <= FCurrent do
  begin
    LBase := (LLine mod D3_CON_TOTAL_LINES) * D3_CON_LINE_WIDTH;
    LBlank := True;
    for LColumn := 0 to D3_CON_LINE_WIDTH - 1 do
      if (FText[LBase + LColumn] and $FF) > Ord(' ') then
      begin
        LBlank := False;
        Break;
      end;
    if not LBlank then
      Break;
    Inc(LLine);
  end;
  // write the remaining lines
  while LLine <= FCurrent do
  begin
    LBase := (LLine mod D3_CON_TOTAL_LINES) * D3_CON_LINE_WIDTH;
    for LColumn := 0 to D3_CON_LINE_WIDTH - 1 do
      LBuffer[LColumn] := Byte(FText[LBase + LColumn] and $FF);
    LColumn := D3_CON_LINE_WIDTH - 1;
    while LColumn >= 0 do
    begin
      if SignedChar(LBuffer[LColumn]) <= Ord(' ') then
        LBuffer[LColumn] := 0
      else
        Break;
      Dec(LColumn);
    end;
    LBuffer[LColumn + 1] := 13;
    LBuffer[LColumn + 2] := 10;
    LBuffer[LColumn + 3] := 0;
    LLength := 0;
    while LBuffer[LLength] <> 0 do
      Inc(LLength);
    SetLength(LText, LLength);
    Move(LBuffer[0], LText[1], LLength);
    LFile.Write(LText[1], LLength);
    Inc(LLine);
  end;
  FFiles.CloseFile(LFile);
end;

procedure TD3Console.PageUp;
begin
  Dec(FDisplay, 2);
  if FCurrent - FDisplay >= D3_CON_TOTAL_LINES then
    FDisplay := FCurrent - D3_CON_TOTAL_LINES + 1;
end;

procedure TD3Console.PageDown;
begin
  Inc(FDisplay, 2);
  if FDisplay > FCurrent then
    FDisplay := FCurrent;
end;

procedure TD3Console.Top;
begin
  FDisplay := 0;
end;

procedure TD3Console.Bottom;
begin
  FDisplay := FCurrent;
end;

procedure TD3Console.KeyDownEvent(const AKey: Integer);
var
  LCtrl: Boolean;
  LLower: Integer;
begin
  // execute F key bindings
  if (AKey >= K_F1) and (AKey <= K_F12) then
  begin
    FBindings.ExecKeyBinding(AKey);
    Exit;
  end;
  LCtrl := FKeys.IsDown(K_CTRL);
  LLower := AKey;
  if (LLower >= Ord('A')) and (LLower <= Ord('Z')) then
    Inc(LLower, 32);
  // ctrl-L clears screen
  if (AKey = Ord('l')) and LCtrl then
  begin
    Clear;
    Exit;
  end;
  // enter finishes the line
  if (AKey = K_ENTER) or (AKey = K_KP_ENTER) then
  begin
    FPrinter.Printf(']' + FConsoleField.Text + #10);
    FBuffer.BufferCommandText(ceAppend, FConsoleField.Text); // valid command
    FBuffer.BufferCommandText(ceAppend, #10);
    // copy line to history buffer
    FHistoryEditLines[FNextHistoryLine mod D3_CON_COMMAND_HISTORY].Assign(FConsoleField);
    Inc(FNextHistoryLine);
    FHistoryLine := FNextHistoryLine;
    FConsoleField.Clear;
    FConsoleField.SetWidthInChars(D3_CON_LINE_WIDTH);
    FScreen.UpdateScreen(True); // force an update, because the command may take some time
    Exit;
  end;
  // command completion
  if AKey = K_TAB then
  begin
    FConsoleField.AutoComplete;
    Exit;
  end;
  // command history (ctrl-p ctrl-n for unix style)
  if (AKey = K_UPARROW) or ((LLower = Ord('p')) and LCtrl) then
  begin
    if (FNextHistoryLine - FHistoryLine < D3_CON_COMMAND_HISTORY) and (FHistoryLine > 0) then
      Dec(FHistoryLine);
    FConsoleField.Assign(FHistoryEditLines[FHistoryLine mod D3_CON_COMMAND_HISTORY]);
    Exit;
  end;
  if (AKey = K_DOWNARROW) or ((LLower = Ord('n')) and LCtrl) then
  begin
    if FHistoryLine = FNextHistoryLine then
      Exit;
    Inc(FHistoryLine);
    FConsoleField.Assign(FHistoryEditLines[FHistoryLine mod D3_CON_COMMAND_HISTORY]);
    Exit;
  end;
  // console scrolling
  if AKey = K_PGUP then
  begin
    PageUp;
    FLastKeyEvent := FClock.EventMilliseconds;
    FNextKeyEvent := CONSOLE_FIRSTREPEAT;
    Exit;
  end;
  if AKey = K_PGDN then
  begin
    PageDown;
    FLastKeyEvent := FClock.EventMilliseconds;
    FNextKeyEvent := CONSOLE_FIRSTREPEAT;
    Exit;
  end;
  if AKey = K_MWHEELUP then
  begin
    PageUp;
    Exit;
  end;
  if AKey = K_MWHEELDOWN then
  begin
    PageDown;
    Exit;
  end;
  // ctrl-home = top of console
  if (AKey = K_HOME) and LCtrl then
  begin
    Top;
    Exit;
  end;
  // ctrl-end = bottom of console
  if (AKey = K_END) and LCtrl then
  begin
    Bottom;
    Exit;
  end;
  // pass to the normal editline routine
  FConsoleField.KeyDownEvent(AKey);
end;

procedure TD3Console.Scroll;
begin
  if (FLastKeyEvent = -1) or ((FLastKeyEvent + 200) > FClock.EventMilliseconds) then
    Exit;
  // console scrolling
  if FKeys.IsDown(K_PGUP) then
  begin
    PageUp;
    FNextKeyEvent := CONSOLE_REPEAT;
    Exit;
  end;
  if FKeys.IsDown(K_PGDN) then
  begin
    PageDown;
    FNextKeyEvent := CONSOLE_REPEAT;
  end;
end;

procedure TD3Console.SetDisplayFraction(const AFraction: Single);
begin
  FFinalFrac := AFraction;
  FFracTime := FState.FrameTime;
end;

procedure TD3Console.UpdateDisplayFraction;
var
  LSpeed: Single;
begin
  LSpeed := FCVarValues.GetFloat('con_speed');
  if LSpeed <= 0.1 then
  begin
    FFracTime := FState.FrameTime;
    FDisplayFrac := FFinalFrac;
    Exit;
  end;
  // scroll towards the destination height
  if FFinalFrac < FDisplayFrac then
  begin
    FDisplayFrac := FDisplayFrac - LSpeed * (FState.FrameTime - FFracTime) * 0.001;
    if FFinalFrac > FDisplayFrac then
      FDisplayFrac := FFinalFrac;
    FFracTime := FState.FrameTime;
  end
  else if FFinalFrac > FDisplayFrac then
  begin
    FDisplayFrac := FDisplayFrac + LSpeed * (FState.FrameTime - FFracTime) * 0.001;
    if FFinalFrac < FDisplayFrac then
      FDisplayFrac := FFinalFrac;
    FFracTime := FState.FrameTime;
  end;
end;

function TD3Console.ProcessEvent(const AEvent: TD3SysEvent; const AForceAccept: Boolean): Boolean;
var
  LConsoleKey: Boolean;
begin
  LConsoleKey := (AEvent.EvType = SE_KEY) and ((AEvent.EvValue = FPlatform.GetConsoleKey(False)) or
    (AEvent.EvValue = FPlatform.GetConsoleKey(True)));
  // we always catch the console key event
  if (not AForceAccept) and LConsoleKey then
  begin
    // ignore up events
    if AEvent.EvValue2 = 0 then
      Exit(True);
    FConsoleField.ClearAutoComplete;
    // a down event will toggle the destination lines
    if FKeyCatching then
    begin
      Close;
      FPlatform.GrabMouseCursor(True);
      FCVars.SetCVarBool(SUiChat, False);
    end
    else
    begin
      FConsoleField.Clear;
      FKeyCatching := True;
      // if the shift key is down, don't open the console as much
      if FKeys.IsDown(K_SHIFT) then
        SetDisplayFraction(0.2)
      else
        SetDisplayFraction(0.5);
      FCVars.SetCVarBool(SUiChat, True);
    end;
    Exit(True);
  end;
  // if we aren't key catching, dump all the other events
  if (not AForceAccept) and (not FKeyCatching) then
    Exit(False);
  // handle key and character events
  if AEvent.EvType = SE_CHAR then
  begin
    // never send the console key as a character
    if (AEvent.EvValue <> FPlatform.GetConsoleKey(False)) and (AEvent.EvValue <> FPlatform.GetConsoleKey(True)) then
      FConsoleField.CharEvent(AEvent.EvValue);
    Exit(True);
  end;
  if AEvent.EvType = SE_KEY then
  begin
    // ignore up key events
    if AEvent.EvValue2 = 0 then
      Exit(True);
    KeyDownEvent(AEvent.EvValue);
    Exit(True);
  end;
  // we don't handle things like mouse, joystick, and network packets
  Result := False;
end;

procedure TD3Console.Linefeed;
var
  LIndex: Integer;
begin
  // mark time for transparent overlay
  if FCurrent >= 0 then
    FTimes[FCurrent mod D3_CON_NUM_TIMES] := FState.FrameTime;
  FX := 0;
  if FDisplay = FCurrent then
    Inc(FDisplay);
  Inc(FCurrent);
  for LIndex := 0 to D3_CON_LINE_WIDTH - 1 do
    FText[(FCurrent mod D3_CON_TOTAL_LINES) * D3_CON_LINE_WIDTH + LIndex] := ColorCell(C_COLOR_CYAN_INDEX, Ord(' '));
end;

procedure TD3Console.Print(const AText: AnsiString);
var
  LPosition: Integer;
  LLimit: Integer;
  LY: Integer;
  LChar: Integer;
  LWord: Integer;
  LColor: Integer;

  function CharAt(const AOffset: Integer): Integer;
  begin
    if LPosition + AOffset <= LLimit then
      Result := Byte(AText[LPosition + AOffset])
    else
      Result := 0;
  end;

begin
  LLimit := Length(AText);
  // the text ends at the first NUL, like a C string
  LPosition := Pos(#0, string(AText));
  if LPosition > 0 then
    LLimit := LPosition - 1;
  LColor := C_COLOR_CYAN_INDEX;
  LPosition := 1;
  while LPosition <= LLimit do
  begin
    LChar := CharAt(0);
    // idStr::IsColor
    if (LChar = Ord('^')) and (CharAt(1) <> 0) and (CharAt(1) <> Ord(' ')) then
    begin
      if CharAt(1) = Ord('0') then
        LColor := C_COLOR_CYAN_INDEX
      else
        LColor := CharAt(1) and 15;
      Inc(LPosition, 2);
      Continue;
    end;
    LY := FCurrent mod D3_CON_TOTAL_LINES;
    // if we are about to print a new word, check to see if we should wrap to the new line
    if (LChar > Ord(' ')) and ((FX = 0) or (FText[LY * D3_CON_LINE_WIDTH + FX - 1] <= Ord(' '))) then
    begin
      // count word length
      LWord := 0;
      while LWord < D3_CON_LINE_WIDTH do
      begin
        if SignedChar(CharAt(LWord)) <= Ord(' ') then
          Break;
        Inc(LWord);
      end;
      // word wrap
      if (LWord <> D3_CON_LINE_WIDTH) and (FX + LWord >= D3_CON_LINE_WIDTH) then
        Linefeed;
    end;
    Inc(LPosition);
    case LChar of
      10:
        Linefeed;
      9:
        repeat
          FText[LY * D3_CON_LINE_WIDTH + FX] := ColorCell(LColor, Ord(' '));
          Inc(FX);
          if FX >= D3_CON_LINE_WIDTH then
          begin
            Linefeed;
            FX := 0;
          end;
        until (FX and 3) = 0;
      13:
        FX := 0;
    else
      // display character and advance
      FText[LY * D3_CON_LINE_WIDTH + FX] := ColorCell(LColor, LChar);
      Inc(FX);
      if FX >= D3_CON_LINE_WIDTH then
      begin
        Linefeed;
        FX := 0;
      end;
    end;
  end;
  // mark time for transparent overlay
  if FCurrent >= 0 then
    FTimes[FCurrent mod D3_CON_NUM_TIMES] := FState.FrameTime;
end;

function TD3Console.Cell(const ALine, AColumn: Integer): Integer;
begin
  Result := FText[(ALine mod D3_CON_TOTAL_LINES) * D3_CON_LINE_WIDTH + AColumn];
end;

function TD3Console.CurrentLine: Integer;
begin
  Result := FCurrent;
end;

function TD3Console.Column: Integer;
begin
  Result := FX;
end;

function TD3Console.DisplayLine: Integer;
begin
  Result := FDisplay;
end;

function TD3Console.KeyCatching: Boolean;
begin
  Result := FKeyCatching;
end;

function TD3Console.LastKeyEvent: Integer;
begin
  Result := FLastKeyEvent;
end;

function TD3Console.NextKeyEvent: Integer;
begin
  Result := FNextKeyEvent;
end;

function TD3Console.DisplayFraction: Single;
begin
  Result := FDisplayFrac;
end;

function TD3Console.FinalFraction: Single;
begin
  Result := FFinalFrac;
end;

function TD3Console.FractionTime: Integer;
begin
  Result := FFracTime;
end;

function TD3Console.NotifyTime(const AIndex: Integer): Integer;
begin
  Result := FTimes[AIndex];
end;

function TD3Console.NextHistory: Integer;
begin
  Result := FNextHistoryLine;
end;

function TD3Console.HistoryLine: Integer;
begin
  Result := FHistoryLine;
end;

function TD3Console.HistoryText(const AIndex: Integer): AnsiString;
begin
  Result := FHistoryEditLines[AIndex].Text;
end;

end.
