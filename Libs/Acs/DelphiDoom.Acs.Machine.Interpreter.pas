{******************************************************************************}
{                                                                              }
{  DelphiDoom: ACS library - the interpreter of the commands                   }
{  Port of the interpreter of Hexen (p_acs.c, Raven Software)                  }
{  Copyright (C) 1995 Raven Software, Corp.                                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Acs.Machine.Interpreter;

// The numbers of a script wrap around at 32 bits, as they did in the engine of Raven
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Acs.Machine.Types, DelphiDoom.Acs.Machine.Intf,
  DelphiDoom.Acs.Machine.Behavior, DelphiDoom.Acs.Machine.Variables, DelphiDoom.Logging.Intf;

type
  /// <summary>Why a script stopped running in this tic</summary>
  TAcsRunResult = (
    /// <summary>A delay, a wait or a suspend: the script goes on in a later tic</summary>
    arrStopped,
    /// <summary>The script ended (or a command that cannot be done made it end)</summary>
    arrTerminated
  );

  /// <summary>
  ///   Runs the commands of a script, one after the other, until it has to wait or ends. The
  ///   script keeps its own stack, variables and position (TAcsScript); everything that touches
  ///   the game goes to the host. A command that cannot be done (a jump out of the object code, a
  ///   stack that overflows, a variable that does not exist, a command that does not exist) warns
  ///   the log and ends the script: the old interpreter went on to write out of its arrays
  /// </summary>
  TAcsInterpreter = class
  strict private
    type
      TAction = (acContinue, acStop, acTerminate);
    var
      FHost: IAcsHost;
      FLog: ILog;
      FBehavior: TAcsBehavior;
      FVariables: TAcsVariables;
      FScript: PAcsScript;
      FIp: PInteger;
      FFaulted: Boolean;
      /// <summary>
      ///   The arguments of the special that was called last stay: a special with fewer
      ///   arguments than the one before sees the ones of the one before, as it always did
      /// </summary>
      FSpecialArguments: TAcsSpecialArguments;
      FPrintBuffer: string;
    procedure Fault(const AFormat: string; const AArguments: array of const);
    procedure Push(AValue: Integer);
    function Pop: Integer;
    function Top: Integer;
    function NextLong: Integer;
    function PopString(out AText: string): Boolean;
    function StringOfOperand(out AText: string): Boolean;
    function SlotOf(AScope, AIndex: Integer): PInteger;
    procedure JumpTo(AOffset: Integer);
    function Quotient(ADividend, ADivisor: Integer): Integer;
    function Remainder(ADividend, ADivisor: Integer): Integer;
    function ExecuteVariableCommand(AOperation, AScope: Integer): TAction;
    function ExecuteLineSpecial(AArgumentCount: Integer; ADirect: Boolean): TAction;
    function ExecuteWait(AState: TAcsScriptState; ADirect: Boolean): TAction;
    function ExecuteChangeFlat(AFloor, ADirect: Boolean): TAction;
    function ExecuteThingCount(ADirect: Boolean): TAction;
    function ExecuteSetLineSpecial: TAction;
    function ExecuteSetLineTexture: TAction;
    function Execute(ACommand: Integer): TAction;
  public
    /// <param name="ALog">May be nil</param>
    constructor Create(const AHost: IAcsHost; const ALog: ILog; ABehavior: TAcsBehavior;
      AVariables: TAcsVariables);
    /// <summary>
    ///   Runs the script from its position. The position is saved in the script when it stops. The
    ///   index of its table entry has to be right
    /// </summary>
    function Run(AScript: PAcsScript): TAcsRunResult;
  end;

implementation

uses
  DelphiDoom.Acs.Machine.Arithmetic, DelphiDoom.Acs.PCodes;

const
  SFaultStack = 'ACS script %d: the stack overflows or underflows';
  SFaultJump = 'ACS script %d: a jump goes out of the object code';
  SFaultCode = 'ACS script %d: the code runs out of the object code';
  SFaultVariable = 'ACS script %d: the variable %d does not exist';
  SFaultString = 'ACS script %d: the string %d does not exist';
  SFaultCommand = 'ACS script %d: the command %d does not exist';
  SDivisionByZero = 'ACS script %d: division by zero (the result is 0)';

  // the commands on variables come in groups of three: script, map and world
  SCOPE_SCRIPT = 0;
  SCOPE_MAP = 1;
  SCOPE_WORLD = 2;
  OPERATION_ASSIGN = 0;
  OPERATION_PUSH = 1;
  OPERATION_ADD = 2;
  OPERATION_SUBTRACT = 3;
  OPERATION_MULTIPLY = 4;
  OPERATION_DIVIDE = 5;
  OPERATION_MODULUS = 6;
  OPERATION_INCREMENT = 7;
  OPERATION_DECREMENT = 8;

{ TAcsInterpreter }

constructor TAcsInterpreter.Create(const AHost: IAcsHost; const ALog: ILog;
  ABehavior: TAcsBehavior; AVariables: TAcsVariables);
begin
  inherited Create;
  if not Assigned(AHost) then
    raise EArgumentNilException.Create('AHost');
  if not Assigned(ABehavior) then
    raise EArgumentNilException.Create('ABehavior');
  if not Assigned(AVariables) then
    raise EArgumentNilException.Create('AVariables');
  FHost := AHost;
  FLog := ALog;
  FBehavior := ABehavior;
  FVariables := AVariables;
end;

procedure TAcsInterpreter.Fault(const AFormat: string; const AArguments: array of const);
begin
  if not FFaulted then
  begin
    FFaulted := True;
    if Assigned(FLog) then
      FLog.Warning(Format(AFormat, AArguments));
  end;
end;

procedure TAcsInterpreter.Push(AValue: Integer);
begin
  if FFaulted then
    Exit; // the script is about to end: its stack is not touched any more
  if FScript.StackPtr >= ACS_STACK_DEPTH then
  begin
    Fault(SFaultStack, [FScript.Number]);
    Exit;
  end;
  FScript.Stack[FScript.StackPtr] := AValue;
  Inc(FScript.StackPtr);
end;

function TAcsInterpreter.Pop: Integer;
begin
  if (FScript.StackPtr <= 0) or (FScript.StackPtr > ACS_STACK_DEPTH) then
  begin
    Fault(SFaultStack, [FScript.Number]);
    Exit(0);
  end;
  Dec(FScript.StackPtr);
  Result := FScript.Stack[FScript.StackPtr];
end;

function TAcsInterpreter.Top: Integer;
begin
  if (FScript.StackPtr <= 0) or (FScript.StackPtr > ACS_STACK_DEPTH) then
  begin
    Fault(SFaultStack, [FScript.Number]);
    Exit(0);
  end;
  Result := FScript.Stack[FScript.StackPtr - 1];
end;

function TAcsInterpreter.NextLong: Integer;
begin
  if not FBehavior.Contains(FIp) then
  begin
    Fault(SFaultCode, [FScript.Number]);
    Exit(0);
  end;
  Result := FIp^;
  Inc(FIp);
end;

function TAcsInterpreter.PopString(out AText: string): Boolean;
var
  LIndex: Integer;
begin
  LIndex := Pop;
  Result := FBehavior.TryGetString(LIndex, AText);
  if not Result and not FFaulted then
    Fault(SFaultString, [FScript.Number, LIndex]);
end;

function TAcsInterpreter.StringOfOperand(out AText: string): Boolean;
var
  LIndex: Integer;
begin
  LIndex := NextLong;
  Result := FBehavior.TryGetString(LIndex, AText);
  if not Result and not FFaulted then
    Fault(SFaultString, [FScript.Number, LIndex]);
end;

function TAcsInterpreter.SlotOf(AScope, AIndex: Integer): PInteger;
begin
  Result := nil;
  case AScope of
    SCOPE_SCRIPT:
      if (AIndex >= 0) and (AIndex < ACS_SCRIPT_VARIABLE_COUNT) then
        Result := @FScript.Vars[AIndex];
    SCOPE_MAP:
      Result := FVariables.MapSlot(AIndex);
    SCOPE_WORLD:
      Result := FVariables.WorldSlot(AIndex);
  end;
  if not Assigned(Result) and not FFaulted then
    Fault(SFaultVariable, [FScript.Number, AIndex]);
end;

procedure TAcsInterpreter.JumpTo(AOffset: Integer);
var
  LAddress: PInteger;
begin
  LAddress := FBehavior.AddressAt(AOffset);
  if Assigned(LAddress) then
    FIp := LAddress
  else
    Fault(SFaultJump, [FScript.Number]);
end;

function TAcsInterpreter.Quotient(ADividend, ADivisor: Integer): Integer;
begin
  if (ADivisor = 0) and not FFaulted and Assigned(FLog) then
    FLog.Warning(Format(SDivisionByZero, [FScript.Number]));
  Result := TAcsArithmetic.Divide(ADividend, ADivisor);
end;

function TAcsInterpreter.Remainder(ADividend, ADivisor: Integer): Integer;
begin
  if (ADivisor = 0) and not FFaulted and Assigned(FLog) then
    FLog.Warning(Format(SDivisionByZero, [FScript.Number]));
  Result := TAcsArithmetic.Modulo(ADividend, ADivisor);
end;

function TAcsInterpreter.ExecuteVariableCommand(AOperation, AScope: Integer): TAction;
var
  LSlot: PInteger;
  LIndex: Integer;
begin
  Result := acContinue;
  LIndex := NextLong;
  case AOperation of
    OPERATION_ASSIGN:
      begin
        LSlot := SlotOf(AScope, LIndex);
        if Assigned(LSlot) then
          LSlot^ := Pop;
      end;
    OPERATION_PUSH:
      begin
        LSlot := SlotOf(AScope, LIndex);
        if Assigned(LSlot) then
          Push(LSlot^);
      end;
    OPERATION_ADD:
      begin
        LSlot := SlotOf(AScope, LIndex);
        if Assigned(LSlot) then
          LSlot^ := LSlot^ + Pop;
      end;
    OPERATION_SUBTRACT:
      begin
        LSlot := SlotOf(AScope, LIndex);
        if Assigned(LSlot) then
          LSlot^ := LSlot^ - Pop;
      end;
    OPERATION_MULTIPLY:
      begin
        LSlot := SlotOf(AScope, LIndex);
        if Assigned(LSlot) then
          LSlot^ := LSlot^ * Pop;
      end;
    OPERATION_DIVIDE:
      begin
        LSlot := SlotOf(AScope, LIndex);
        if Assigned(LSlot) then
          LSlot^ := Quotient(LSlot^, Pop);
      end;
    OPERATION_MODULUS:
      begin
        LSlot := SlotOf(AScope, LIndex);
        if Assigned(LSlot) then
          LSlot^ := Remainder(LSlot^, Pop);
      end;
    OPERATION_INCREMENT:
      begin
        LSlot := SlotOf(AScope, LIndex);
        if Assigned(LSlot) then
          Inc(LSlot^);
      end;
    OPERATION_DECREMENT:
      begin
        LSlot := SlotOf(AScope, LIndex);
        if Assigned(LSlot) then
          Dec(LSlot^);
      end;
  end;
end;

function TAcsInterpreter.ExecuteLineSpecial(AArgumentCount: Integer; ADirect: Boolean): TAction;
var
  LSpecial: Integer;
  LIndex: Integer;
begin
  LSpecial := NextLong;
  if ADirect then
  begin
    for LIndex := 0 to AArgumentCount - 1 do
      FSpecialArguments[LIndex] := Byte(NextLong and $FF);
  end
  else
  begin
    for LIndex := AArgumentCount - 1 downto 0 do
      FSpecialArguments[LIndex] := Byte(Pop and $FF);
  end;
  if not FFaulted then
    FHost.ExecuteLineSpecial(LSpecial, FSpecialArguments, FScript.Line, FScript.Activator,
      FScript.Side);
  Result := acContinue;
end;

function TAcsInterpreter.ExecuteWait(AState: TAcsScriptState; ADirect: Boolean): TAction;
var
  LValue: Integer;
begin
  if ADirect then
    LValue := NextLong
  else
    LValue := Pop;
  FBehavior.WaitValue[FScript.InfoIndex] := LValue;
  FBehavior.State[FScript.InfoIndex] := AState;
  Result := acStop;
end;

function TAcsInterpreter.ExecuteChangeFlat(AFloor, ADirect: Boolean): TAction;
var
  LTag: Integer;
  LName: string;
  LFound: Boolean;
begin
  if ADirect then
  begin
    LTag := NextLong;
    LFound := StringOfOperand(LName);
  end
  else
  begin
    LFound := PopString(LName);
    LTag := Pop;
  end;
  if LFound and not FFaulted then
    FHost.ChangeSectorFlat(LTag, LName, AFloor);
  Result := acContinue;
end;

function TAcsInterpreter.ExecuteThingCount(ADirect: Boolean): TAction;
var
  LType: Integer;
  LTid: Integer;
begin
  if ADirect then
  begin
    LType := NextLong;
    LTid := NextLong;
  end
  else
  begin
    LTid := Pop;
    LType := Pop;
  end;
  // with neither a type nor a tid there is nothing to count and nothing is pushed: as it always was
  if (LType + LTid <> 0) and not FFaulted then
    Push(FHost.CountThings(LType, LTid));
  Result := acContinue;
end;

function TAcsInterpreter.ExecuteSetLineSpecial: TAction;
var
  LArguments: TAcsLineSpecialArguments;
  LSpecial: Integer;
  LTag: Integer;
  LIndex: Integer;
begin
  for LIndex := 4 downto 0 do
    LArguments[LIndex] := Pop;
  LSpecial := Pop;
  LTag := Pop;
  if not FFaulted then
    FHost.SetLineSpecial(LTag, LSpecial, LArguments);
  Result := acContinue;
end;

function TAcsInterpreter.ExecuteSetLineTexture: TAction;
var
  LName: string;
  LPosition: Integer;
  LSide: Integer;
  LTag: Integer;
  LFound: Boolean;
begin
  LFound := PopString(LName);
  LPosition := Pop;
  LSide := Pop;
  LTag := Pop;
  if LFound and not FFaulted then
    FHost.SetLineTexture(LTag, LSide, LPosition, LName);
  Result := acContinue;
end;

function TAcsInterpreter.Execute(ACommand: Integer): TAction;
var
  LValue: Integer;
  LOther: Integer;
  LLow: Integer;
  LHigh: Integer;
  LName: string;
begin
  Result := acContinue;
  case ACommand of
    PCD_NOP:
      ;
    PCD_TERMINATE:
      Result := acTerminate;
    PCD_SUSPEND:
      begin
        FBehavior.State[FScript.InfoIndex] := assSuspended;
        Result := acStop;
      end;
    PCD_PUSHNUMBER:
      Push(NextLong);
    PCD_LSPEC1..PCD_LSPEC5:
      Result := ExecuteLineSpecial(ACommand - PCD_LSPEC1 + 1, False);
    PCD_LSPEC1DIRECT..PCD_LSPEC5DIRECT:
      Result := ExecuteLineSpecial(ACommand - PCD_LSPEC1DIRECT + 1, True);
    PCD_ADD:
      Push(Pop + Pop);
    PCD_SUBTRACT:
      begin
        LOther := Pop;
        Push(Pop - LOther);
      end;
    PCD_MULTIPLY:
      Push(Pop * Pop);
    PCD_DIVIDE:
      begin
        LOther := Pop;
        Push(Quotient(Pop, LOther));
      end;
    PCD_MODULUS:
      begin
        LOther := Pop;
        Push(Remainder(Pop, LOther));
      end;
    PCD_EQ:
      Push(Ord(Pop = Pop));
    PCD_NE:
      Push(Ord(Pop <> Pop));
    PCD_LT:
      begin
        LOther := Pop;
        Push(Ord(Pop < LOther));
      end;
    PCD_GT:
      begin
        LOther := Pop;
        Push(Ord(Pop > LOther));
      end;
    PCD_LE:
      begin
        LOther := Pop;
        Push(Ord(Pop <= LOther));
      end;
    PCD_GE:
      begin
        LOther := Pop;
        Push(Ord(Pop >= LOther));
      end;
    PCD_ASSIGNSCRIPTVAR..PCD_DECWORLDVAR:
      Result := ExecuteVariableCommand((ACommand - PCD_ASSIGNSCRIPTVAR) div 3,
        (ACommand - PCD_ASSIGNSCRIPTVAR) mod 3);
    PCD_GOTO:
      JumpTo(NextLong);
    PCD_IFGOTO:
      begin
        LValue := NextLong;
        if Pop <> 0 then
          JumpTo(LValue);
      end;
    PCD_DROP:
      Pop;
    PCD_DELAY:
      begin
        FScript.DelayCount := Pop;
        Result := acStop;
      end;
    PCD_DELAYDIRECT:
      begin
        FScript.DelayCount := NextLong;
        Result := acStop;
      end;
    PCD_RANDOM:
      begin
        LHigh := Pop;
        LLow := Pop;
        Push(LLow + TAcsArithmetic.Modulo(FHost.NextRandom, LHigh - LLow + 1));
      end;
    PCD_RANDOMDIRECT:
      begin
        LLow := NextLong;
        LHigh := NextLong;
        Push(LLow + TAcsArithmetic.Modulo(FHost.NextRandom, LHigh - LLow + 1));
      end;
    PCD_THINGCOUNT:
      Result := ExecuteThingCount(False);
    PCD_THINGCOUNTDIRECT:
      Result := ExecuteThingCount(True);
    PCD_TAGWAIT:
      Result := ExecuteWait(assWaitingForTag, False);
    PCD_TAGWAITDIRECT:
      Result := ExecuteWait(assWaitingForTag, True);
    PCD_POLYWAIT:
      Result := ExecuteWait(assWaitingForPolyobj, False);
    PCD_POLYWAITDIRECT:
      Result := ExecuteWait(assWaitingForPolyobj, True);
    PCD_CHANGEFLOOR:
      Result := ExecuteChangeFlat(True, False);
    PCD_CHANGEFLOORDIRECT:
      Result := ExecuteChangeFlat(True, True);
    PCD_CHANGECEILING:
      Result := ExecuteChangeFlat(False, False);
    PCD_CHANGECEILINGDIRECT:
      Result := ExecuteChangeFlat(False, True);
    PCD_RESTART:
      FIp := FBehavior.GetScript(FScript.InfoIndex).Address;
    PCD_ANDLOGICAL:
      begin
        LOther := Pop;
        LValue := Pop;
        Push(Ord((LValue <> 0) and (LOther <> 0)));
      end;
    PCD_ORLOGICAL:
      begin
        LOther := Pop;
        LValue := Pop;
        Push(Ord((LValue <> 0) or (LOther <> 0)));
      end;
    PCD_ANDBITWISE:
      Push(Pop and Pop);
    PCD_ORBITWISE:
      Push(Pop or Pop);
    PCD_EORBITWISE:
      Push(Pop xor Pop);
    PCD_NEGATELOGICAL:
      Push(Ord(Pop = 0));
    PCD_LSHIFT:
      begin
        LOther := Pop;
        Push(TAcsArithmetic.ShiftLeft(Pop, LOther));
      end;
    PCD_RSHIFT:
      begin
        LOther := Pop;
        Push(TAcsArithmetic.ShiftRight(Pop, LOther));
      end;
    PCD_UNARYMINUS:
      Push(-Pop);
    PCD_IFNOTGOTO:
      begin
        LValue := NextLong;
        if Pop = 0 then
          JumpTo(LValue);
      end;
    PCD_LINESIDE:
      Push(FScript.Side);
    PCD_SCRIPTWAIT:
      Result := ExecuteWait(assWaitingForScript, False);
    PCD_SCRIPTWAITDIRECT:
      Result := ExecuteWait(assWaitingForScript, True);
    PCD_CLEARLINESPECIAL:
      if Assigned(FScript.Line) then
        FHost.ClearLineSpecial(FScript.Line);
    PCD_CASEGOTO:
      begin
        LValue := NextLong;
        LOther := NextLong;
        if Top = LValue then
        begin
          JumpTo(LOther);
          Pop;
        end;
      end;
    PCD_BEGINPRINT:
      FPrintBuffer := '';
    PCD_ENDPRINT:
      FHost.ShowMessage(FScript.Activator, FPrintBuffer);
    PCD_PRINTSTRING:
      if PopString(LName) then
        FPrintBuffer := FPrintBuffer + LName;
    PCD_PRINTNUMBER:
      FPrintBuffer := FPrintBuffer + IntToStr(Pop);
    PCD_PRINTCHARACTER:
      FPrintBuffer := FPrintBuffer + Char(Pop and $FF);
    PCD_PLAYERCOUNT:
      Push(FHost.PlayerCount);
    PCD_GAMETYPE:
      Push(Ord(FHost.GameType));
    PCD_GAMESKILL:
      Push(FHost.GameSkill);
    PCD_TIMER:
      Push(FHost.LevelTime);
    PCD_SECTORSOUND:
      begin
        LValue := Pop;
        if PopString(LName) then
          FHost.PlaySectorSound(FScript.Line, LName, LValue);
      end;
    PCD_AMBIENTSOUND:
      begin
        LValue := Pop;
        if PopString(LName) then
          FHost.PlayAmbientSound(LName, LValue);
      end;
    PCD_SOUNDSEQUENCE:
      if PopString(LName) then
        FHost.StartSoundSequence(FScript.Line, LName);
    PCD_SETLINETEXTURE:
      Result := ExecuteSetLineTexture;
    PCD_SETLINEBLOCKING:
      begin
        LValue := Pop;
        LOther := Pop;
        FHost.SetLineBlocking(LOther, LValue <> 0);
      end;
    PCD_SETLINESPECIAL:
      Result := ExecuteSetLineSpecial;
    PCD_THINGSOUND:
      begin
        LValue := Pop;
        if PopString(LName) then
          FHost.PlayThingSound(Pop, LName, LValue);
      end;
    PCD_ENDPRINTBOLD:
      FHost.ShowMessageToAll(FPrintBuffer);
  else
    Fault(SFaultCommand, [FScript.Number, ACommand]);
  end;
end;

function TAcsInterpreter.Run(AScript: PAcsScript): TAcsRunResult;
var
  LAction: TAction;
  LCommand: Integer;
begin
  FScript := AScript;
  FIp := AScript.Ip;
  FFaulted := False;
  repeat
    if not FBehavior.Contains(FIp) then
    begin
      Fault(SFaultCode, [FScript.Number]);
      LAction := acTerminate;
    end
    else
    begin
      LCommand := FIp^;
      Inc(FIp);
      LAction := Execute(LCommand);
      if FFaulted then
        LAction := acTerminate;
    end;
  until LAction <> acContinue;
  AScript.Ip := FIp;
  if LAction = acTerminate then
    Result := arrTerminated
  else
    Result := arrStopped;
end;

end.