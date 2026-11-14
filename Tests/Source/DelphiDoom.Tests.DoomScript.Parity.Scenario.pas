{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom script library - scenarios of the        }
{  parity driver                                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DoomScript.Parity.Scenario;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.Defs,
  DelphiDoom.DoomScript.EventDef, DelphiDoom.DoomScript.Thread, DelphiDoom.Tests.DoomScript.Parity.Output,
  DelphiDoom.Tests.DoomScript.Parity.FileSystem, DelphiDoom.Tests.DoomScript.Parity.Entity,
  DelphiDoom.Tests.DoomScript.Parity.Game, DelphiDoom.Tests.DoomScript.Parity.Dump;

type
  /// <summary>
  ///   Runs a scenario of the C++ harness (the commands of the header of Tools\Verifica\110\main.cpp) on
  ///   the script machine of the library and gives the lines the harness would write in a golden.
  /// </summary>
  TDoomScriptParityScenario = class
  strict private
    FOutput: TDoomScriptParityOutput;
    FFileSystem: TDoomScriptParityFileSystem;
    FGame: TDoomScriptParityGame;
    FDump: TDoomScriptParityDump;
    class function Split(const ALine: AnsiString): TArray<AnsiString>; static;
    class function AllDigits(const AText: AnsiString): Boolean; static;
    class function Atoi(const AText: AnsiString): Integer; static;
    procedure Fail(const AText: string);
    function EntityArg(const AText: AnsiString): TDoomScriptParityEntity;
    function ThreadArg(const AText: AnsiString): TDoomScriptThread;
    function FunctionArg(const AName: AnsiString): TDoomScriptFunction;
    procedure RunCommand(const AArgs: TArray<AnsiString>; const AText: AnsiString);
    procedure RunDump(const AArgs: TArray<AnsiString>);
    procedure RunEvent(const AArgs: TArray<AnsiString>; const APost: Boolean);
    procedure RunScriptVar(const AArgs: TArray<AnsiString>);
  public
    /// <param name="ARoot">The root of the fake file system (the folder that holds "script")</param>
    constructor Create(const ARoot: string);
    destructor Destroy; override;
    /// <summary>Runs the lines of a scenario file</summary>
    procedure Run(const AScenario: TStrings);
    /// <summary>The lines written so far</summary>
    function Lines: TStrings;
  end;

implementation

uses
  DelphiDoom.IdLib.Core.Exceptions, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.Scanner.IdDict,
  DelphiDoom.Scanner.IdCNumbers, DelphiDoom.DoomScript.ScriptObject, DelphiDoom.DoomScript.ScriptProgram;

type
  TOut = TDoomScriptParityOutput;

constructor TDoomScriptParityScenario.Create(const ARoot: string);
begin
  inherited Create;
  FOutput := TDoomScriptParityOutput.Create;
  FFileSystem := TDoomScriptParityFileSystem.Create(ARoot, FOutput);
  FGame := TDoomScriptParityGame.Create(FOutput, FFileSystem);
  FDump := TDoomScriptParityDump.Create(FGame);
end;

destructor TDoomScriptParityScenario.Destroy;
begin
  FDump.Free;
  // the game frees the machine, which holds the log and the file system as interfaces
  FGame.Free;
  FFileSystem.Free;
  FOutput.Free;
  inherited;
end;

function TDoomScriptParityScenario.Lines: TStrings;
begin
  Result := FOutput.Lines;
end;

class function TDoomScriptParityScenario.Split(const ALine: AnsiString): TArray<AnsiString>;
var
  LIndex: Integer;
  LLength: Integer;
  LToken: AnsiString;
begin
  Result := nil;
  LIndex := 1;
  LLength := Length(ALine);
  while LIndex <= LLength do
  begin
    while (LIndex <= LLength) and (ALine[LIndex] in [' ', #9]) do
      Inc(LIndex);
    if LIndex > LLength then
      Break;
    LToken := '';
    if ALine[LIndex] = '"' then
    begin
      Inc(LIndex);
      while (LIndex <= LLength) and (ALine[LIndex] <> '"') do
        if (ALine[LIndex] = '\') and (LIndex + 1 <= LLength) then
        begin
          Inc(LIndex);
          case ALine[LIndex] of
            'n': LToken := LToken + #10;
            't': LToken := LToken + #9;
          else
            LToken := LToken + ALine[LIndex];
          end;
          Inc(LIndex);
        end
        else
        begin
          LToken := LToken + ALine[LIndex];
          Inc(LIndex);
        end;
      Inc(LIndex);
    end
    else
      while (LIndex <= LLength) and not (ALine[LIndex] in [' ', #9]) do
      begin
        LToken := LToken + ALine[LIndex];
        Inc(LIndex);
      end;
    Result := Result + [LToken];
  end;
end;

class function TDoomScriptParityScenario.AllDigits(const AText: AnsiString): Boolean;
var
  LIndex: Integer;
begin
  Result := AText <> '';
  for LIndex := 1 to Length(AText) do
    if not (AText[LIndex] in ['0'..'9']) then
      Exit(False);
end;

class function TDoomScriptParityScenario.Atoi(const AText: AnsiString): Integer;
begin
  Result := TIdCNumbers.Atoi(AText);
end;

procedure TDoomScriptParityScenario.Fail(const AText: string);
begin
  raise EDoomScriptParityHarness.Create('harness: ' + AText);
end;

function TDoomScriptParityScenario.EntityArg(const AText: AnsiString): TDoomScriptParityEntity;
begin
  if AText = 'null' then
    Exit(nil);
  Result := FGame.EntityAt(Atoi(AText));
  if not Assigned(Result) then
    Fail('no such entity');
end;

function TDoomScriptParityScenario.ThreadArg(const AText: AnsiString): TDoomScriptThread;
begin
  Result := FGame.Machine.GetThread(Atoi(AText));
  if not Assigned(Result) then
    Fail('no such thread');
end;

function TDoomScriptParityScenario.FunctionArg(const AName: AnsiString): TDoomScriptFunction;
begin
  Result := FGame.Machine.ScriptProgram.FindFunction(AName);
  if not Assigned(Result) then
    Fail('function not found');
end;

procedure TDoomScriptParityScenario.RunDump(const AArgs: TArray<AnsiString>);
var
  LWhat: AnsiString;
begin
  if Length(AArgs) < 2 then
    Fail('missing arguments');
  LWhat := AArgs[1];
  if LWhat = 'program' then
    FDump.ScriptProgram
  else if LWhat = 'statements' then
  begin
    if Length(AArgs) < 4 then
      Fail('missing arguments');
    FDump.Statements(Atoi(AArgs[2]), Atoi(AArgs[3]));
  end
  else if LWhat = 'globals' then
    FDump.Globals
  else if LWhat = 'disasm' then
    FGame.Machine.ScriptProgram.Disassemble
  else if LWhat = 'threads' then
    FDump.Threads(True)
  else if LWhat = 'stacks' then
    FDump.Stacks
  else if LWhat = 'events' then
    FDump.Events
  else if LWhat = 'entities' then
    FDump.Entities
  else if LWhat = 'return' then
    FDump.ReturnValue
  else
    Fail('unknown dump');
end;

procedure TDoomScriptParityScenario.RunEvent(const AArgs: TArray<AnsiString>; const APost: Boolean);
var
  LEntity: TDoomScriptParityEntity;
  LEvent: TDoomScriptEventDef;
  LAt: Integer;
  LIndex: Integer;
  LArgs: TDoomScriptEventArgs;
  LList: TArray<TDoomScriptEventArg>;
  LText: AnsiString;
  LValues: array[0..2] of Single;
  LTarget: TDoomScriptParityEntity;
  LResult: Boolean;
begin
  if APost then
    LAt := 3
  else
    LAt := 2;
  if Length(AArgs) < LAt + 1 then
    Fail('missing arguments');
  LEntity := EntityArg(AArgs[1]);
  LEvent := FGame.Machine.Events.FindEvent(AArgs[LAt]);
  if not Assigned(LEvent) then
    Fail('unknown event');
  if Length(AArgs) - (LAt + 1) <> LEvent.GetNumArgs then
    Fail('wrong number of event arguments');
  LArgs := Default(TDoomScriptEventArgs);
  SetLength(LList, LEvent.GetNumArgs);
  for LIndex := 0 to LEvent.GetNumArgs - 1 do
  begin
    LText := AArgs[LAt + 1 + LIndex];
    case LEvent.ArgFormat[LIndex + 1] of
      DS_EVENT_FLOAT:
        LArgs[LIndex] := TDoomScriptConvert.FloatArg(TIdCNumbers.Atof(LText));
      DS_EVENT_INTEGER:
        LArgs[LIndex] := TDoomScriptConvert.IntArg(Atoi(LText));
      DS_EVENT_STRING:
        LArgs[LIndex] := TDoomScriptConvert.StringArg(LText);
      DS_EVENT_VECTOR:
        begin
          LValues[0] := 0;
          LValues[1] := 0;
          LValues[2] := 0;
          TIdCNumbers.ScanFloats(LText, LValues);
          LArgs[LIndex] := TDoomScriptConvert.VectorArg(TIdVec3.Create(LValues[0], LValues[1], LValues[2]));
        end;
      DS_EVENT_ENTITY, DS_EVENT_ENTITY_NULL:
        begin
          LTarget := EntityArg(LText);
          if Assigned(LTarget) then
            LArgs[LIndex] := TDoomScriptConvert.EntityArg(LTarget.EntityNumber)
          else
            LArgs[LIndex] := TDoomScriptConvert.EntityArg(-1);
        end;
    else
      Fail('event argument type not supported');
    end;
    LList[LIndex] := LArgs[LIndex];
  end;
  if APost then
  begin
    LResult := FGame.Machine.Queue.PostEventMS(LEntity, LEvent, Atoi(AArgs[2]), LList);
    FOutput.Line('POSTED ' + TOut.Num(Ord(LResult)));
  end
  else
  begin
    LResult := LEntity.ProcessHostEvent(LEvent, LList);
    FOutput.Line('PROCESSED ' + TOut.Num(Ord(LResult)));
  end;
end;

procedure TDoomScriptParityScenario.RunScriptVar(const AArgs: TArray<AnsiString>);
var
  LObject: TDoomScriptObject;
  LKind: TDoomScriptEType;
  LOffset: Integer;
  LValue: AnsiString;
  LVector: TIdVec3;
begin
  if Length(AArgs) < 4 then
    Fail('missing arguments');
  LObject := FGame.ScriptObjectOf(EntityArg(AArgs[1]));
  LKind := evVoid;
  if AArgs[3] = 'float' then
    LKind := evFloat
  else if AArgs[3] = 'vector' then
    LKind := evVector
  else if AArgs[3] = 'string' then
    LKind := evString
  else if AArgs[3] = 'boolean' then
    LKind := evBoolean
  else if AArgs[3] = 'entity' then
    LKind := evEntity
  else if AArgs[3] = 'object' then
    LKind := evObject
  else
    Fail('unknown type');
  LOffset := LObject.GetVariable(AArgs[2], LKind);
  if LOffset < 0 then
  begin
    FOutput.Line('SCRIPTVAR -1');
    Exit;
  end;
  case LKind of
    evFloat:
      LValue := TOut.FloatBits(PSingle(LObject.DataPtr(LOffset, 4))^);
    evVector:
      begin
        Move(LObject.DataPtr(LOffset, 12)^, LVector, 12);
        LValue := TOut.Vec3(LVector);
      end;
    evString:
      LValue := TOut.Quoted(TDoomScriptMemory.ReadString(LObject.DataPtr(LOffset, DS_MAX_STRING_LEN)));
  else
    LValue := TOut.Num(PInteger(LObject.DataPtr(LOffset, 4))^);
  end;
  FOutput.Line('SCRIPTVAR ' + TOut.Num(LOffset) + ' ' + LValue);
end;

procedure TDoomScriptParityScenario.RunCommand(const AArgs: TArray<AnsiString>; const AText: AnsiString);
var
  LCommand: AnsiString;
  LProgram: TDoomScriptProgram;
  LThread: TDoomScriptThread;
  LEntity: TDoomScriptParityEntity;
  LFunction: TDoomScriptFunction;
  LIndex: Integer;
  LCount: Integer;
  LInner: Integer;
  LValue: Integer;
  LText: AnsiString;
  LNumber: AnsiString;
  LDict: TIdDict;
  LOk: Boolean;

  procedure Need(const ACount: Integer);
  begin
    if Length(AArgs) < ACount + 1 then
      Fail('missing arguments');
  end;

begin
  LProgram := FGame.Machine.ScriptProgram;
  LCommand := AArgs[0];
  if LCommand = 'startup' then
  begin
    Need(1);
    if AArgs[1] = '-' then
      LProgram.Startup('')
    else
      LProgram.Startup(AArgs[1]);
  end
  else if LCommand = 'begin' then
    LProgram.BeginCompilation
  else if LCommand = 'finish' then
    LProgram.FinishCompilation
  else if LCommand = 'restart' then
    LProgram.Restart
  else if LCommand = 'compilefile' then
  begin
    Need(1);
    LProgram.CompileFile(AArgs[1]);
  end
  else if LCommand = 'compiletext' then
  begin
    Need(2);
    LOk := LProgram.CompileText(AArgs[1], AText, Atoi(AArgs[2]) <> 0);
    FOutput.Line('RESULT ' + TOut.Num(Ord(LOk)));
  end
  else if LCommand = 'compilefunction' then
  begin
    Need(1);
    LFunction := LProgram.CompileFunction(AArgs[1], AText);
    FOutput.Line('FUNCTION ' + TOut.Num(FDump.FuncIndex(LFunction)));
  end
  else if LCommand = 'genfile' then
  begin
    Need(2);
    LText := '';
    LCount := Atoi(AArgs[2]);
    for LIndex := 0 to LCount - 1 do
    begin
      LNumber := TOut.Num(LIndex);
      LText := LText + AnsiString(StringReplace(string(AText), '@', string(LNumber), [rfReplaceAll]));
    end;
    FFileSystem.SetMemoryFile(AArgs[1], LText);
  end
  else if LCommand = 'dump' then
    RunDump(AArgs)
  else if LCommand = 'spawn' then
  begin
    Need(3);
    LValue := Atoi(AArgs[1]);
    if (LValue < 0) or (LValue >= PARITY_ENTITYNUM_WORLD) or Assigned(FGame.EntityAt(LValue)) then
      Fail('bad entity slot');
    LDict := TIdDict.Create;
    try
      LInner := 4;
      while LInner + 1 < Length(AArgs) do
      begin
        LDict.SetValue(AArgs[LInner], AArgs[LInner + 1]);
        Inc(LInner, 2);
      end;
      if not Assigned(FGame.MakeEntity(LValue, AArgs[2], AArgs[3], LDict)) then
        Fail('unknown entity class');
    finally
      LDict.Free;
    end;
  end
  else if LCommand = 'setobject' then
  begin
    Need(2);
    LEntity := EntityArg(AArgs[1]);
    LOk := FGame.ScriptObjectOf(LEntity).SetType(AArgs[2]);
    FOutput.Line('SETTYPE ' + TOut.Num(Ord(LOk)));
    if LOk then
      FGame.ConstructScriptObject(LEntity);
  end
  else if LCommand = 'remove' then
  begin
    Need(1);
    FGame.RemoveEntity(EntityArg(AArgs[1]));
  end
  else if LCommand = 'thread' then
  begin
    Need(1);
    LThread := FGame.Machine.CreateThread(FunctionArg(AArgs[1]));
    LThread.DelayedStart(0);
    FOutput.Line('THREADNUM ' + TOut.Num(LThread.ThreadNum));
  end
  else if LCommand = 'objthread' then
  begin
    Need(2);
    LEntity := EntityArg(AArgs[1]);
    LFunction := FGame.ScriptObjectOf(LEntity).GetFunction(AArgs[2]);
    if not Assigned(LFunction) then
      Fail('function not found');
    LThread := FGame.Machine.CreateThread;
    LThread.SetThreadName(LEntity.Name);
    LThread.CallFunction(LEntity.EntityNumber, LFunction, True);
    LThread.DelayedStart(0);
    FOutput.Line('THREADNUM ' + TOut.Num(LThread.ThreadNum));
  end
  else if LCommand = 'callnow' then
  begin
    Need(1);
    LThread := FGame.Machine.CreateThread(FunctionArg(AArgs[1]));
    LOk := LThread.Start;
    FOutput.Line('DONE ' + TOut.Num(Ord(LOk)));
    FDump.ReturnValue;
  end
  else if LCommand = 'frame' then
  begin
    LCount := 1;
    if Length(AArgs) > 1 then
      LCount := Atoi(AArgs[1]);
    for LIndex := 0 to LCount - 1 do
    begin
      Inc(FGame.Time, FGame.Msec);
      FGame.RealClientTime := FGame.Time;
      Inc(FGame.FrameNum);
      FGame.Machine.ServiceEvents;
      FOutput.Line('FRAME time=' + TOut.Num(FGame.Time) + ' framenum=' + TOut.Num(FGame.FrameNum) + ' events=' +
        TOut.Num(FGame.Machine.Queue.Count));
      FDump.Threads(False);
    end;
  end
  else if LCommand = 'displayinfo' then
  begin
    Need(1);
    ThreadArg(AArgs[1]).DisplayInfo;
  end
  else if LCommand = 'listthreads' then
    TDoomScriptThread.ListThreads(FGame.Machine.Context)
  else if LCommand = 'getvar' then
  begin
    Need(2);
    LValue := -1;
    if Length(AArgs) > 3 then
      LValue := Atoi(AArgs[3]);
    LOk := ThreadArg(AArgs[1]).Interpreter.GetRegisterValue(AArgs[2], LText, LValue);
    FOutput.Line('GETVAR ' + TOut.Num(Ord(LOk)) + ' ' + TOut.Esc(LText));
  end
  else if LCommand = 'setcvar' then
  begin
    Need(2);
    FGame.SetCVar(string(AArgs[1]), AArgs[2]);
  end
  else if LCommand = 'set' then
  begin
    Need(2);
    LValue := Atoi(AArgs[2]);
    if AArgs[1] = 'isClient' then
      FGame.IsClient := LValue <> 0
    else if AArgs[1] = 'isMultiplayer' then
      FGame.IsMultiplayer := LValue <> 0
    else if AArgs[1] = 'influence' then
    begin
      if FGame.LocalPlayer < 0 then
        Fail('no player');
      FGame.EntityAt(FGame.LocalPlayer).InfluenceLevel := LValue;
    end
    else if AArgs[1] = 'time' then
    begin
      FGame.Time := LValue;
      FGame.RealClientTime := LValue;
    end
    else if AArgs[1] = 'msec' then
      FGame.Msec := LValue
    else
      Fail('unknown set');
  end
  else if LCommand = 'settrace' then
  begin
    Need(3);
    FGame.ClipFraction := TIdCNumbers.Atof(AArgs[1]);
    FGame.ClipEntity := Atoi(AArgs[2]);
    FGame.ClipId := Atoi(AArgs[3]);
  end
  else if LCommand = 'event' then
    RunEvent(AArgs, False)
  else if LCommand = 'postevent' then
    RunEvent(AArgs, True)
  else if LCommand = 'signal' then
  begin
    Need(2);
    FGame.Signal(EntityArg(AArgs[1]), Atoi(AArgs[2]));
  end
  else if LCommand = 'movedone' then
  begin
    Need(2);
    TDoomScriptThread.ObjectMoveDone(FGame.Machine.Context, Atoi(AArgs[1]), EntityArg(AArgs[2]).EntityNumber);
  end
  else if LCommand = 'killthread' then
  begin
    Need(1);
    if AllDigits(AArgs[1]) then
      FGame.Machine.KillThread(Atoi(AArgs[1]))
    else
      FGame.Machine.KillThread(AArgs[1]);
  end
  else if LCommand = 'endthread' then
  begin
    Need(1);
    ThreadArg(AArgs[1]).EndThread;
  end
  else if LCommand = 'debuginfo' then
  begin
    Need(2);
    if Atoi(AArgs[2]) <> 0 then
      ThreadArg(AArgs[1]).EnableDebugInfo
    else
      ThreadArg(AArgs[1]).DisableDebugInfo;
  end
  else if LCommand = 'save' then
    FDump.Save
  else if LCommand = 'restore' then
    FDump.Restore
  else if LCommand = 'findfunction' then
  begin
    Need(1);
    FOutput.Line('FUNCTION ' + TOut.Num(FDump.FuncIndex(LProgram.FindFunction(AArgs[1]))));
  end
  else if LCommand = 'scriptvar' then
    RunScriptVar(AArgs)
  else
    Fail('unknown command');
end;

procedure TDoomScriptParityScenario.Run(const AScenario: TStrings);
var
  LIndex: Integer;
  LLine: AnsiString;
  LTrimmed: AnsiString;
  LArgs: TArray<AnsiString>;
  LText: AnsiString;
begin
  LIndex := 0;
  while LIndex < AScenario.Count do
  begin
    LLine := AnsiString(AScenario[LIndex]);
    LTrimmed := AnsiString(TrimLeft(string(LLine)));
    if (LTrimmed = '') or (LTrimmed[1] = '#') then
    begin
      Inc(LIndex);
      Continue;
    end;
    LArgs := Split(LLine);
    LText := '';
    if (Length(LArgs) > 0) and (LArgs[High(LArgs)] = '<<EOF') then
    begin
      SetLength(LArgs, Length(LArgs) - 1);
      Inc(LIndex);
      while (LIndex < AScenario.Count) and (AScenario[LIndex] <> 'EOF') do
      begin
        LText := LText + AnsiString(AScenario[LIndex]) + #10;
        Inc(LIndex);
      end;
    end;
    FOutput.Line('CMD ' + LLine);
    try
      RunCommand(LArgs, LText);
    except
      // an Error of the game ends the command; anything else is a defect and ends the test
      on E: EIdLibException do
        FOutput.Line('ERROR ' + TOut.Esc(AnsiString(E.Message)));
      on E: EDoomScriptParityHarness do
        FOutput.Line('ERROR ' + TOut.Esc(AnsiString(E.Message)));
    end;
    FOutput.FlushPending;
    Inc(LIndex);
  end;
  FOutput.FlushPending;
end;

end.
