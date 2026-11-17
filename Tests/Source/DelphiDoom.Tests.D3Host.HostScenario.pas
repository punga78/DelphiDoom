{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Doom 3 host library - the scenarios of the second  }
{  parity harness (keys, edit field, usercmd, console, life cycle)             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.D3Host.HostScenario;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.IdLib.Text.CmdArgs, DelphiDoom.D3Host.Types,
  DelphiDoom.D3Host.Intf, DelphiDoom.D3Host.Input.Types, DelphiDoom.D3Host.Input.Intf,
  DelphiDoom.D3Host.Lifecycle.Intf, DelphiDoom.D3Host.KeyInput, DelphiDoom.D3Host.KeyNames,
  DelphiDoom.D3Host.EditField, DelphiDoom.D3Host.UsercmdGen, DelphiDoom.D3Host.Console, DelphiDoom.D3Host.Lifecycle,
  DelphiDoom.Tests.D3Host.World, DelphiDoom.Tests.D3Host.HostWorld;

type
  /// <summary>
  ///   Runs the scenarios of Tests\Data\D3Host\scenarios_host on the Delphi classes, with the same commands and the
  ///   same trace lines as harness_host.cpp (see its header for the commands). It owns the world, the state and the
  ///   classes under test, built the way a program would build them.
  /// </summary>
  THostScenarioRunner = class
  strict private
    FWorld: THostWorld;
    FState: TD3CommonState;
    FKeyInput: TD3KeyInput;
    FKeyRef: IInterface;
    FUsercmd: TD3UsercmdGen;
    FUsercmdRef: IInterface;
    FConsole: TD3Console;
    FConsoleRef: IInterface;
    FField: TD3EditField;
    FLifecycle: TD3Lifecycle;
    FLifecycleRef: IInterface;
    procedure Command(const ACommand, ARest: string);
    procedure PrintUsercmd(const ATag: string; const ACmd: TD3Usercmd);
    procedure ShowField;
    procedure ShowConsole(const ACount: Integer);
    procedure ShowContext;
    procedure ShowUsercmdState;
    procedure ShowLifeState;
    function RunFakes(const ACommand: string; const AWords: TArray<string>; const AText: string): Boolean;
    function RunKeys(const ACommand: string; const AWords: TArray<string>; const ARest, AText: string): Boolean;
    function RunField(const ACommand: string; const AWords: TArray<string>; const AText: string): Boolean;
    function RunUsercmd(const ACommand: string; const AWords: TArray<string>; const AText: string): Boolean;
    function RunConsole(const ACommand: string; const AWords: TArray<string>; const AText: string): Boolean;
    function RunLife(const ACommand: string; const AWords: TArray<string>; const AText: string): Boolean;
    function ToInt(const AText: string): Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Run(const AScenario: TStrings);
    function Trace: TStringList;
  end;

implementation

uses
  DelphiDoom.Console.CmdSystem.Types;

function Words(const AText: string): TArray<string>;
var
  LList: TList<string>;
  LIndex: Integer;
  LStart: Integer;
begin
  LList := TList<string>.Create;
  try
    LIndex := 1;
    while LIndex <= Length(AText) do
    begin
      while (LIndex <= Length(AText)) and (AText[LIndex] = ' ') do
        Inc(LIndex);
      LStart := LIndex;
      while (LIndex <= Length(AText)) and (AText[LIndex] <> ' ') do
        Inc(LIndex);
      if LIndex > LStart then
        LList.Add(Copy(AText, LStart, LIndex - LStart));
    end;
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

function Tail(const AText: string; const ACount: Integer): string;
var
  LIndex: Integer;
  LStep: Integer;
begin
  LIndex := 1;
  for LStep := 1 to ACount do
  begin
    while (LIndex <= Length(AText)) and (AText[LIndex] = ' ') do
      Inc(LIndex);
    while (LIndex <= Length(AText)) and (AText[LIndex] <> ' ') do
      Inc(LIndex);
  end;
  if LIndex <= Length(AText) then
    Inc(LIndex);
  if LIndex <= Length(AText) then
    Result := Copy(AText, LIndex, MaxInt)
  else
    Result := '';
end;

function Fmt(const AValue: Double; const ADigits: Integer): string;
begin
  Result := Format('%.*f', [ADigits, AValue], TFormatSettings.Invariant);
end;

function B(const AValue: Boolean): string;
begin
  Result := IntToStr(Ord(AValue));
end;

constructor THostScenarioRunner.Create;
var
  LEnvironment: TD3EditFieldEnvironment;
begin
  inherited Create;
  FWorld := THostWorld.Create;
  FState := TD3CommonState.Create;
  FKeyInput := TD3KeyInput.Create(FWorld.CommandsIntf, FWorld.Buffer, FWorld.Printer, FWorld.KeyText,
    FWorld.CVarServices);
  FKeyRef := FKeyInput;
  FUsercmd := TD3UsercmdGen.Create(FState, FWorld.CVarValues, FKeyInput, FWorld.Devices, FWorld.AsyncState,
    FWorld.Reporter, FWorld.Debug);
  FUsercmdRef := FUsercmd;
  FKeyInput.SetUsercmd(FUsercmd);
  LEnvironment.Keys := FKeyInput;
  LEnvironment.Clipboard := FWorld.Clip;
  LEnvironment.Printer := FWorld.Printer;
  LEnvironment.Commands := FWorld.CommandsIntf;
  LEnvironment.CVars := FWorld.CVarServices;
  FField := TD3EditField.Create(LEnvironment);
  FConsole := TD3Console.Create(FState, FWorld.CommandsIntf, FWorld.Buffer, FWorld.Printer, FWorld.Warnings, FKeyInput,
    FKeyInput, FWorld.CommonCVars, FWorld.CVarValues, FWorld.ConsolePlatform, FWorld.EventClock, FWorld.Screen,
    FWorld.FilesIntf, LEnvironment);
  FConsoleRef := FConsole;
  FLifecycle := nil;
end;

destructor THostScenarioRunner.Destroy;
begin
  FLifecycleRef := nil;
  FConsoleRef := nil;
  FField.Free;
  FUsercmdRef := nil;
  FKeyRef := nil;
  FState.Free;
  FWorld.Free;
  inherited Destroy;
end;

function THostScenarioRunner.Trace: TStringList;
begin
  Result := FWorld.Trace;
end;

function THostScenarioRunner.ToInt(const AText: string): Integer;
begin
  Result := TD3CNumbers.Atoi(AnsiString(AText));
end;

procedure THostScenarioRunner.Run(const AScenario: TStrings);
var
  LLine: string;
  LIndex: Integer;
  LSpace: Integer;
  LServices: TD3LifecycleServices;
begin
  LServices := FWorld.Services;
  LServices.Keys := FKeyInput as ID3Subsystem;
  LServices.Console := FConsole as ID3ConsoleControl;
  LServices.Usercmd := FUsercmd as ID3UsercmdGenerator;
  FLifecycle := TD3Lifecycle.Create(FState, LServices, 'DOOM 3', 'DOOM 3 harness 1.0');
  FLifecycleRef := FLifecycle;
  for LIndex := 0 to AScenario.Count - 1 do
  begin
    LLine := AScenario[LIndex];
    if (LLine = '') or (LLine[1] = '#') then
      Continue;
    FWorld.Outs('CMD', AnsiString(LLine));
    LSpace := Pos(' ', LLine);
    try
      if LSpace = 0 then
        Command(LLine, '')
      else
        Command(Copy(LLine, 1, LSpace - 1), Copy(LLine, LSpace + 1, MaxInt));
    except
      on E: ETestExit do
        FWorld.Line('EXIT ' + E.Why);
      on E: ED3HostException do
        FWorld.Outs('THROW', AnsiString(E.Message));
    end;
  end;
end;

procedure THostScenarioRunner.Command(const ACommand, ARest: string);
var
  LWords: TArray<string>;
  LText: string;
begin
  LWords := Words(ARest);
  LText := string(TD3Escape.Unescape(ARest));
  if RunFakes(ACommand, LWords, LText) or RunKeys(ACommand, LWords, ARest, LText) or RunField(ACommand, LWords, LText) or
    RunUsercmd(ACommand, LWords, LText) or RunConsole(ACommand, LWords, LText) or RunLife(ACommand, LWords, LText) then
    Exit;
  FWorld.Line('UNKNOWN ' + ACommand);
end;

function THostScenarioRunner.RunFakes(const ACommand: string; const AWords: TArray<string>;
  const AText: string): Boolean;
var
  LValue: Boolean;
  LNames: TArray<AnsiString>;
  LIndex: Integer;
begin
  Result := True;
  if ACommand = 'time' then
    FWorld.Time := ToInt(AWords[0])
  else if ACommand = 'evms' then
    FWorld.EventMs := ToInt(AWords[0])
  else if ACommand = 'cvar' then
  begin
    if Length(AWords) > 1 then
      FWorld.CommonCVars.SetCVarString(AnsiString(AWords[0]), AnsiString(AWords[1]))
    else
      FWorld.CommonCVars.SetCVarString(AnsiString(AWords[0]), '');
  end
  else if ACommand = 'fail' then
    FWorld.SetFailAt(AWords[0])
  else if ACommand = 'ret' then
  begin
    LValue := ToInt(AWords[1]) <> 0;
    if AWords[0] = 'already' then
      FWorld.Already := LValue
    else if AWords[0] = 'startupcmds' then
      FWorld.StartupCmds := LValue
    else if AWords[0] = 'safemode' then
      FWorld.SafeMode := LValue
    else if AWords[0] = 'fpuempty' then
      FWorld.FpuEmpty := LValue
    else if AWords[0] = 'soundworld' then
      FWorld.SoundWorld := LValue
    else if AWords[0] = 'specfile' then
      FWorld.SpecFile := LValue
    else if AWords[0] = 'net' then
      FWorld.Net := LValue;
  end
  else if ACommand = 'dedicated' then
    FWorld.Vars.AddOrSetValue('net_serverDedicated', AWords[0])
  else if ACommand = 'clipboard' then
  begin
    FWorld.HasClipboard := AText <> 'none';
    FWorld.Clipboard := AnsiString(AText);
  end
  else if ACommand = 'consolekey' then
  begin
    FWorld.ConsoleKeyA := ToInt(AWords[0]);
    FWorld.ConsoleKeyB := ToInt(AWords[1]);
  end
  else if (ACommand = 'cmds') or (ACommand = 'cvarnames') then
  begin
    SetLength(LNames, Length(AWords));
    for LIndex := 0 to High(AWords) do
      LNames[LIndex] := AnsiString(AWords[LIndex]);
    if ACommand = 'cmds' then
      FWorld.CmdNames := LNames
    else
      FWorld.CVarNames := LNames;
  end
  else if (ACommand = 'argcomp') or (ACommand = 'cvarargcomp') then
  begin
    SetLength(LNames, Length(AWords) - 1);
    for LIndex := 0 to High(LNames) do
      LNames[LIndex] := AnsiString(AWords[LIndex + 1]);
    if ACommand = 'argcomp' then
      FWorld.ArgCompletions.AddOrSetValue(AWords[0], LNames)
    else
      FWorld.CVarArgCompletions.AddOrSetValue(AWords[0], LNames);
  end
  else if ACommand = 'keyq' then
    FWorld.KeyQueue.Add(TPair<Integer, Boolean>.Create(ToInt(AWords[0]), ToInt(AWords[1]) <> 0))
  else if ACommand = 'mouseq' then
    FWorld.MouseQueue.Add(TPair<Integer, Integer>.Create(ToInt(AWords[0]), ToInt(AWords[1])))
  else
    Result := False;
end;

function THostScenarioRunner.RunKeys(const ACommand: string; const AWords: TArray<string>;
  const ARest, AText: string): Boolean;
var
  LArgs: TIdCmdArgs;
  LIndex: Integer;
  LFound: Boolean;
  LBinding: AnsiString;
  LFile: ID3CommonFile;
begin
  Result := True;
  if ACommand = 'keyinit' then
    FKeyInput.Init
  else if ACommand = 'keyshutdown' then
    FKeyInput.Shutdown
  else if ACommand = 's2k' then
    FWorld.Line('RET ' + IntToStr(TD3KeyNames.StringToKeyNum(AnsiString(AText))))
  else if ACommand = 'k2s' then
    FWorld.Outs('RETS', TD3KeyNames.KeyNumToString(ToInt(AWords[0]), ToInt(AWords[1]) <> 0, FWorld.KeyText))
  else if ACommand = 'exec' then
  begin
    LArgs := TIdCmdArgs.Create;
    try
      LArgs.TokenizeString(AnsiString(AText), False);
      LFound := False;
      for LIndex := 0 to FWorld.Commands.Count - 1 do
        if FWorld.Commands[LIndex].Key = string(LArgs.Argv(0)) then
        begin
          FWorld.Commands[LIndex].Value(LArgs);
          LFound := True;
          Break;
        end;
      if not LFound then
        FWorld.Outs('NOCMD', LArgs.Argv(0));
    finally
      LArgs.Free;
    end;
  end
  else if ACommand = 'getbinding' then
    FWorld.Outs('RETS', FKeyInput.GetBinding(ToInt(AWords[0])))
  else if ACommand = 'action' then
    FWorld.Line('RET ' + IntToStr(FKeyInput.GetUsercmdAction(ToInt(AWords[0]))))
  else if ACommand = 'execbinding' then
    FWorld.Line('RET ' + B(FKeyInput.ExecKeyBinding(ToInt(AWords[0]))))
  else if ACommand = 'keysfrom' then
    FWorld.Outs('RETS', FKeyInput.KeysFromBinding(AnsiString(AText)))
  else if ACommand = 'bindfrom' then
  begin
    LBinding := FKeyInput.BindingFromKey(AnsiString(AText), LFound);
    if LFound then
      FWorld.Outs('RETS', LBinding)
    else
      FWorld.Outs('RETS', '(null)');
  end
  else if ACommand = 'writebinds' then
  begin
    LFile := FWorld.NewFile('bindings');
    FKeyInput.WriteBindings(LFile);
  end
  else if ACommand = 'numbinds' then
    FWorld.Line('RET ' + IntToStr(FKeyInput.NumBinds(AnsiString(AText))))
  else if ACommand = 'unbindb' then
    FWorld.Line('RET ' + B(FKeyInput.UnbindBinding(AnsiString(AText))))
  else if ACommand = 'isbound' then
    FWorld.Line('RET ' + B(FKeyInput.KeyIsBoundTo(ToInt(AWords[0]), AnsiString(Tail(ARest, 1)))))
  else if ACommand = 'prelim' then
    FKeyInput.PreliminaryKeyEvent(ToInt(AWords[0]), ToInt(AWords[1]) <> 0)
  else if ACommand = 'isdown' then
    FWorld.Line('RET ' + B(FKeyInput.IsDown(ToInt(AWords[0]))))
  else if ACommand = 'clearstates' then
    FKeyInput.ClearStates
  else if ACommand = 'overstrike' then
  begin
    if Length(AWords) > 0 then
      FKeyInput.SetOverstrikeMode(ToInt(AWords[0]) <> 0);
    FWorld.Line('RET ' + B(FKeyInput.GetOverstrikeMode));
  end
  else if ACommand = 'argkeyname' then
  begin
    LArgs := TIdCmdArgs.Create;
    try
      LArgs.TokenizeString(AnsiString(AText), False);
      TD3KeyNames.ArgCompletionKeyName(LArgs.Argv(0),
        procedure(const AName: AnsiString)
        begin
          FWorld.Outs('COMP', AName);
        end);
    finally
      LArgs.Free;
    end;
  end
  else
    Result := False;
end;

procedure THostScenarioRunner.ShowField;
var
  LState: TD3AutoComplete;
begin
  LState := FField.CompletionState;
  FWorld.Line(Format('FIELD cursor=%d scroll=%d width=%d len=%d valid=%d match=%d index=%d',
    [FField.Cursor, FField.Scroll, FField.WidthInChars, LState.Length, Ord(LState.Valid), LState.MatchCount,
    LState.MatchIndex]));
  FWorld.Outs('FBUF', FField.Text);
  FWorld.Outs('FCOMP', LState.CompletionString);
  FWorld.Outs('FMATCH', LState.CurrentMatch);
end;

function THostScenarioRunner.RunField(const ACommand: string; const AWords: TArray<string>;
  const AText: string): Boolean;
begin
  Result := True;
  if (ACommand = 'fnew') or (ACommand = 'fclear') then
    FField.Clear
  else if ACommand = 'fwidth' then
    FField.SetWidthInChars(ToInt(AWords[0]))
  else if ACommand = 'fbuf' then
    FField.SetBuffer(AnsiString(AText))
  else if ACommand = 'fchar' then
    FField.CharEvent(ToInt(AWords[0]))
  else if ACommand = 'fkey' then
    FField.KeyDownEvent(ToInt(AWords[0]))
  else if ACommand = 'fauto' then
    FField.AutoComplete
  else if ACommand = 'fcursor' then
    FField.SetCursor(ToInt(AWords[0]))
  else if ACommand = 'fclearauto' then
    FField.ClearAutoComplete
  else if ACommand = 'fpaste' then
    FField.Paste
  else if ACommand = 'fshow' then
    ShowField
  else
    Result := False;
end;

procedure THostScenarioRunner.PrintUsercmd(const ATag: string; const ACmd: TD3Usercmd);
begin
  FWorld.Line(Format('%s frame=%d time=%d dup=%d buttons=%d fwd=%d right=%d up=%d angles=%d,%d,%d mx=%d my=%d ' +
    'impulse=%d flags=%d seq=%d', [ATag, ACmd.GameFrame, ACmd.GameTime, ACmd.DuplicateCount, ACmd.Buttons,
    ACmd.ForwardMove, ACmd.RightMove, ACmd.UpMove, ACmd.Angles[0], ACmd.Angles[1], ACmd.Angles[2], ACmd.Mx, ACmd.My,
    ACmd.Impulse, ACmd.Flags, ACmd.Sequence]));
end;

procedure THostScenarioRunner.ShowUsercmdState;
var
  LX, LY, LButton: Integer;
  LDown: Boolean;
begin
  FWorld.Line(Format('UCSTATE view=%s,%s,%s flags=%d impulse=%d inhibit=%d init=%d run=%d,%d crouch=%d,%d zoom=%d,%d',
    [Fmt(FUsercmd.ViewAngle(0), 4), Fmt(FUsercmd.ViewAngle(1), 4), Fmt(FUsercmd.ViewAngle(2), 4), FUsercmd.Flags,
    FUsercmd.Impulse, FUsercmd.InhibitMask, Ord(FUsercmd.IsInitialized), FUsercmd.ToggledRun,
    Ord(FUsercmd.ToggledRunHeld), FUsercmd.ToggledCrouch, Ord(FUsercmd.ToggledCrouchHeld), FUsercmd.ToggledZoom,
    Ord(FUsercmd.ToggledZoomHeld)]));
  FUsercmd.MouseState(LX, LY, LButton, LDown);
  FWorld.Line(Format('UCSTATE mouse=%d,%d down=%d button=%d dx=%d dy=%d', [LX, LY, Ord(LDown), LButton,
    FUsercmd.MouseDeltaX, FUsercmd.MouseDeltaY]));
end;

function THostScenarioRunner.RunUsercmd(const ACommand: string; const AWords: TArray<string>;
  const AText: string): Boolean;
var
  LX, LY, LButton: Integer;
  LDown: Boolean;
begin
  Result := True;
  if ACommand = 'ucinit' then
    FUsercmd.Init
  else if ACommand = 'ucnewmap' then
    FUsercmd.InitForNewMap
  else if ACommand = 'ucshutdown' then
    FUsercmd.Shutdown
  else if ACommand = 'ucclear' then
    FUsercmd.Clear
  else if ACommand = 'ucangles' then
    FUsercmd.ClearAngles
  else if ACommand = 'ucinhibit' then
    FUsercmd.InhibitUsercmd(ToInt(AWords[0]), ToInt(AWords[1]) <> 0)
  else if ACommand = 'uctic' then
    PrintUsercmd('UCTIC', FUsercmd.TicCmd(ToInt(AWords[0])))
  else if ACommand = 'ucint' then
    FUsercmd.UsercmdInterrupt
  else if ACommand = 'ucdirect' then
    PrintUsercmd('UCDIRECT', FUsercmd.GetDirectUsercmd)
  else if ACommand = 'ucbutton' then
    FWorld.Line('RET ' + IntToStr(FUsercmd.ButtonState(ToInt(AWords[0]))))
  else if ACommand = 'uckey' then
    FWorld.Line('RET ' + IntToStr(FUsercmd.KeyState(ToInt(AWords[0]))))
  else if ACommand = 'ucmouse' then
  begin
    FUsercmd.MouseState(LX, LY, LButton, LDown);
    FWorld.Line(Format('MOUSE %d %d %d %d', [LX, LY, LButton, Ord(LDown)]));
  end
  else if ACommand = 'ucnames' then
  begin
    FWorld.Line('NUM ' + IntToStr(FUsercmd.GetNumUserCommands));
    FWorld.Outs('NAME0', FUsercmd.GetUserCommandName(0));
    FWorld.Outs('NAMEN', FUsercmd.GetUserCommandName(FUsercmd.GetNumUserCommands - 1));
    FWorld.Outs('NAMEBAD', FUsercmd.GetUserCommandName(-1));
  end
  else if ACommand = 'ucdata' then
    FWorld.Line('RET ' + IntToStr(FUsercmd.CommandStringUsercmdData(AnsiString(AText))))
  else if ACommand = 'ticnum' then
    FState.TicNumber := ToInt(AWords[0])
  else if ACommand = 'ucstate' then
    ShowUsercmdState
  else
    Result := False;
end;

procedure THostScenarioRunner.ShowConsole(const ACount: Integer);
var
  LLine: Integer;
  LColumn: Integer;
  LText: AnsiString;
  LColors: AnsiString;
  LCell: Integer;
begin
  for LLine := FConsole.CurrentLine - ACount + 1 to FConsole.CurrentLine do
  begin
    if LLine < 0 then
      Continue;
    LText := '';
    LColors := '';
    for LColumn := 0 to D3_CON_LINE_WIDTH - 1 do
    begin
      LCell := FConsole.Cell(LLine, LColumn);
      LText := LText + AnsiChar(Byte(LCell and $FF));
      LColors := LColors + AnsiChar(Byte(Ord('0') + ((LCell shr 8) and $F)));
    end;
    FWorld.Outs('CONLINE ' + IntToStr(LLine), LText);
    FWorld.Outs('CONCOLOR ' + IntToStr(LLine), LColors);
  end;
end;

procedure THostScenarioRunner.ShowContext;
var
  LIndex: Integer;
begin
  FWorld.Line(Format('CONSOLE catching=%d current=%d x=%d display=%d lastKey=%d nextKey=%d frac=%s final=%s ' +
    'fracTime=%d history=%d,%d', [Ord(FConsole.KeyCatching), FConsole.CurrentLine, FConsole.Column,
    FConsole.DisplayLine, FConsole.LastKeyEvent, FConsole.NextKeyEvent, Fmt(FConsole.DisplayFraction, 3),
    Fmt(FConsole.FinalFraction, 3), FConsole.FractionTime, FConsole.NextHistory, FConsole.HistoryLine]));
  FWorld.Outs('CONFIELD', FConsole.Field.Text);
  FWorld.Line(Format('CONFIELDCURSOR %d %d', [FConsole.Field.Cursor, FConsole.Field.Scroll]));
  for LIndex := 0 to D3_CON_COMMAND_HISTORY - 1 do
    if FConsole.HistoryText(LIndex) <> '' then
      FWorld.Outs('HIST ' + IntToStr(LIndex), FConsole.HistoryText(LIndex));
end;

function THostScenarioRunner.RunConsole(const ACommand: string; const AWords: TArray<string>;
  const AText: string): Boolean;
var
  LEvent: TD3SysEvent;
begin
  Result := True;
  if ACommand = 'coninit' then
    FConsole.Init
  else if ACommand = 'conshutdown' then
    FConsole.Shutdown
  else if ACommand = 'conclear' then
    FConsole.Clear
  else if ACommand = 'conprint' then
    FConsole.Print(AnsiString(AText))
  else if ACommand = 'conevent' then
  begin
    LEvent := TD3SysEvent.Make(ToInt(AWords[0]), ToInt(AWords[1]), ToInt(AWords[2]));
    FWorld.Line('RET ' + B(FConsole.ProcessEvent(LEvent, ToInt(AWords[3]) <> 0)));
  end
  else if ACommand = 'conactive' then
    FWorld.Line('RET ' + B(FConsole.Active))
  else if ACommand = 'conclose' then
    FConsole.Close
  else if ACommand = 'condump' then
    FConsole.Dump(AnsiString(AText))
  else if ACommand = 'conframe' then
    FState.FrameTime := ToInt(AWords[0])
  else if ACommand = 'conscroll' then
    FConsole.Scroll
  else if ACommand = 'conupdate' then
    FConsole.UpdateDisplayFraction
  else if ACommand = 'contimes' then
    FWorld.Line(Format('TIMES %d %d %d %d', [FConsole.NotifyTime(0), FConsole.NotifyTime(1), FConsole.NotifyTime(2),
      FConsole.NotifyTime(3)]))
  else if ACommand = 'conshow' then
    ShowConsole(ToInt(AWords[0]))
  else if ACommand = 'context' then
    ShowContext
  else
    Result := False;
end;

procedure THostScenarioRunner.ShowLifeState;
var
  LIndex: Integer;
  LTic: Integer;
begin
  FWorld.Line(Format('STATE tic=%d frameTime=%d frame=%d fully=%d shutting=%d lastTic=%d lastlib=%d',
    [FState.TicNumber, FState.FrameTime, FState.FrameNumber, Ord(FLifecycle.IsInitialized),
    Ord(FLifecycle.ShuttingDown), FLifecycle.LastTicMsec, FState.FrameNumber]));
  for LIndex := 0 to 3 do
  begin
    LTic := FState.TicNumber - 1 - LIndex;
    if LTic < 0 then
      Break;
    FWorld.Line(Format('ASYNC %d ms=%d delta=%d consumed=%d', [LTic, FLifecycle.AsyncMilliseconds(LTic),
      FLifecycle.AsyncDelta(LTic), FLifecycle.AsyncConsumed(LTic)]));
  end;
end;

function THostScenarioRunner.RunLife(const ACommand: string; const AWords: TArray<string>;
  const AText: string): Boolean;
var
  LArguments: TArray<AnsiString>;
  LIndex: Integer;
begin
  Result := True;
  if ACommand = 'init' then
  begin
    SetLength(LArguments, Length(AWords));
    for LIndex := 0 to High(AWords) do
      LArguments[LIndex] := AnsiString(AWords[LIndex]);
    FLifecycle.Init(LArguments);
  end
  else if ACommand = 'initcmd' then
    FLifecycle.Init(nil, AnsiString(AText), True)
  else if ACommand = 'shutdown' then
    FLifecycle.Shutdown
  else if ACommand = 'initgame' then
    FLifecycle.InitGame
  else if ACommand = 'shutdowngame' then
    FLifecycle.ShutdownGame(ToInt(AWords[0]) <> 0)
  else if ACommand = 'frame' then
    FLifecycle.Frame
  else if ACommand = 'guiframe' then
    FLifecycle.GUIFrame(ToInt(AWords[0]) <> 0, ToInt(AWords[1]) <> 0)
  else if ACommand = 'async' then
    FLifecycle.Async
  else if ACommand = 'singletic' then
    FLifecycle.SingleAsyncTic
  else if ACommand = 'quit' then
    FLifecycle.Quit
  else if ACommand = 'errorentered' then
    FState.ErrorEntered := ToInt(AWords[0])
  else if ACommand = 'state' then
    ShowLifeState
  else
    Result := False;
end;

end.
