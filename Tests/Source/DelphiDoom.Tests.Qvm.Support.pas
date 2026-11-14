{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the QVM library - the fake host, the files in memory   }
{  and the runner of the parity scenarios                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Qvm.Support;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.BotAi.Import.Intf, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf;

type
  /// <summary>Which numbers the system calls of a module have (the test programs, qagame, cgame, ui)</summary>
  TQvmHostProfile = (Test, Game, CGame, Ui);

  /// <summary>What the fake host raises for the Com_Error of the driver of the C</summary>
  EQvmFakeHostError = class(Exception);

  /// <summary>
  ///   The same host as Tools\Verifica\120\qvmrun.c, line by line: it records every system call (the lines
  ///   "S number nine-arguments" and "= value" when the trace is on, and always a fingerprint and a count)
  ///   and answers the least a module needs: print and error, memset, memcpy, strncpy, sqrt, floor, ceil,
  ///   the entity tokens and the game state; the test profile can also enter the machine again, read and
  ///   write a word. Every other call answers 0
  /// </summary>
  TQvmFakeHost = class(TInterfacedObject, IQvmHost)
  strict private
    FProfile: TQvmHostProfile;
    FOutput: TStrings;
    FTrace: Boolean;
    FCount: Integer;
    FHash: UInt64;
    FEntityToken: Integer;
    function Answer(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer;
    function StringLength(const AMemory: IQvmMemory; AAddress: Integer): Integer;
    function HostPtr(const AMemory: IQvmMemory; AAddress, ALength: Integer): PByte;
    class function Round(ABits: Integer; AUp: Boolean): Integer; static;
  public
    /// <param name="AOutput">Where the lines go; may be nil</param>
    constructor Create(AProfile: TQvmHostProfile; AOutput: TStrings);
    function SystemCall(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer;
    property Trace: Boolean read FTrace write FTrace;
    property Count: Integer read FCount;
    property Hash: UInt64 read FHash;
  end;

  /// <summary>A host that answers 0 to everything and counts</summary>
  TQvmNullHost = class(TInterfacedObject, IQvmHost)
  strict private
    FCount: Integer;
    FLast: TQvmSystemCallArguments;
  public
    function SystemCall(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer;
    property Count: Integer read FCount;
    property Last: TQvmSystemCallArguments read FLast;
  end;

  /// <summary>Files in memory by path</summary>
  TQvmMemoryFiles = class(TInterfacedObject, IBotFileSource)
  strict private
    FNames: TArray<AnsiString>;
    FData: TArray<TBytes>;
  public
    procedure Put(const APath: AnsiString; const AData: TBytes);
    procedure Remove(const APath: AnsiString);
    function TryReadFile(const APath: AnsiString; out AData: TBytes): Boolean;
  end;

  /// <summary>One image and what to do with it: the lines of the scenario file of the driver of the C</summary>
  TQvmScenario = record
    Name: string;
    Profile: TQvmHostProfile;
    Image: TBytes;
    MapText: AnsiString;
    /// <summary>OP_BCOM as the interpreter of 1.32 (the driver of the C is that interpreter)</summary>
    LegacyBitComplement: Boolean;
    Commands: TArray<string>;
    procedure Add(const ACommand: string);
    procedure AddCall(const AValues: array of Integer);
  end;

  /// <summary>Does on the classes of Libs\Qvm what the driver does on the C, and writes the same lines</summary>
  TQvmScenarioRunner = class
  strict private
    class var
      FDumpSerial: Integer;
  public
    class procedure Run(const AScenario: TQvmScenario; AOutput: TStrings); static;
    /// <summary>The fingerprint (FNV-1a 64) of the data image of a machine, as the "M" line has it</summary>
    class function MemoryFingerprint(const AMachine: IQvmMachine): string; static;
    class function ProfileName(AProfile: TQvmHostProfile): string; static;
    /// <summary>The bytes below 32, above 126 and the backslash as \xNN</summary>
    class function Escaped(const AText: AnsiString): string; static;
    class function Hex64(AValue: UInt64): string; static;
    /// <summary>
    ///   A number a test has measured (instructions a second, how the attempts of the fuzzing ended): to the
    ///   log of the test and, as the console logger is quiet, to the standard output
    /// </summary>
    class procedure Report(const AText: string); static;
  end;

implementation

uses
  System.IOUtils, DUnitX.TestFramework, DelphiDoom.Tests.Shared.Fnv, DelphiDoom.Qvm.Factory;

const
  MEMORY_DUMP_VARIABLE = 'QVM_MEMDUMP';
  SHostRange = 'host: out of range';
  // what Windows reports for the two faults of idiv
  TRAP_DIVIDE_BY_ZERO = 'T C0000094';
  TRAP_OVERFLOW = 'T C0000095';
  SDivisionByZero = 'VM division by zero';
  SDivisionOverflow = 'VM division overflow';
  ENTITY_TOKENS: array[0..3] of AnsiString = ('{', 'classname', 'worldspawn', '}');
  GAME_STATE_OFFSETS = 4 * 1024;
  GAME_STATE_CHARS = 16000;

{ TQvmFakeHost }

constructor TQvmFakeHost.Create(AProfile: TQvmHostProfile; AOutput: TStrings);
begin
  inherited Create;
  FProfile := AProfile;
  FOutput := AOutput;
  FTrace := True;
  FHash := TTestFnv.OFFSET_64;
end;

function TQvmFakeHost.HostPtr(const AMemory: IQvmMemory; AAddress, ALength: Integer): PByte;
begin
  if (ALength < 0) or (Int64(AAddress and AMemory.Mask) + ALength > AMemory.Size) then
    raise EQvmFakeHostError.Create(SHostRange);
  Result := AMemory.Range(AAddress, ALength);
end;

function TQvmFakeHost.StringLength(const AMemory: IQvmMemory; AAddress: Integer): Integer;
var
  LMasked: Integer;
begin
  LMasked := AAddress and AMemory.Mask;
  Result := 0;
  while True do
  begin
    if LMasked + Result > AMemory.Mask then
      raise EQvmFakeHostError.Create(SHostRange);
    if AMemory.ReadByte(LMasked + Result) = 0 then
      Exit;
    Inc(Result);
  end;
end;

class function TQvmFakeHost.Round(ABits: Integer; AUp: Boolean): Integer;
var
  LValue, LWhole: Single;
begin
  // 2^23 and above, infinite, NaN: already whole
  if (Cardinal(ABits) and $7FFFFFFF) >= $4B000000 then
    Exit(ABits);
  LValue := PSingle(@ABits)^;
  LWhole := Trunc(LValue);
  if AUp then
  begin
    if LWhole < LValue then
      LWhole := LWhole + 1;
  end
  else if LWhole > LValue then
    LWhole := LWhole - 1;
  Result := PInteger(@LWhole)^;
end;

function TQvmFakeHost.Answer(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer;
var
  LMemory: IQvmMemory;
  LNumber, LPrint, LError, LFloor, LCeil, LLength, LIndex: Integer;
  LText: AnsiString;
  LTarget, LSource, LState: PByte;
  LValue: Single;
begin
  LMemory := AMachine.Memory;
  LNumber := AArguments[0];
  LPrint := 0;
  LError := 1;
  LFloor := 107;
  LCeil := 108;
  if FProfile = TQvmHostProfile.Ui then
  begin
    LPrint := 1;
    LError := 0;
  end;
  if FProfile = TQvmHostProfile.Game then
  begin
    LFloor := 110;
    LCeil := 111;
  end;

  if (LNumber = LPrint) or (LNumber = LError) then
  begin
    LLength := StringLength(LMemory, AArguments[1]);
    SetString(LText, PAnsiChar(HostPtr(LMemory, AArguments[1], LLength)), LLength);
    if LNumber = LError then
    begin
      if Assigned(FOutput) then
        FOutput.Add('X ' + TQvmScenarioRunner.Escaped(LText));
      raise EQvmFakeHostError.Create(string(Copy(LText, 1, 1023)));
    end;
    if Assigned(FOutput) then
      FOutput.Add('P ' + TQvmScenarioRunner.Escaped(LText));
    Exit(0);
  end;
  if LNumber = LFloor then
    Exit(Round(AArguments[1], False));
  if LNumber = LCeil then
    Exit(Round(AArguments[1], True));
  case LNumber of
    100:
      begin
        LTarget := HostPtr(LMemory, AArguments[1], AArguments[3]);
        FillChar(LTarget^, AArguments[3], Byte(AArguments[2]));
        Exit(AArguments[1]);
      end;
    101:
      begin
        LTarget := HostPtr(LMemory, AArguments[1], AArguments[3]);
        LSource := HostPtr(LMemory, AArguments[2], AArguments[3]);
        Move(LSource^, LTarget^, AArguments[3]);
        Exit(AArguments[1]);
      end;
    102:
      begin
        LTarget := HostPtr(LMemory, AArguments[1], AArguments[3]);
        LLength := StringLength(LMemory, AArguments[2]);
        // byte by byte, as the driver does
        for LIndex := 0 to AArguments[3] - 1 do
        begin
          if LIndex < LLength then
            LTarget[LIndex] := HostPtr(LMemory, AArguments[2] + LIndex, 1)^
          else
            LTarget[LIndex] := 0;
        end;
        Exit(AArguments[1]);
      end;
    103, 105:
      Exit(0);
    104:
      Exit($3F800000);
    106:
      begin
        LValue := PSingle(@AArguments[1])^;
        if (Cardinal(AArguments[1]) and $7FFFFFFF > $7F800000) or
           ((AArguments[1] < 0) and (Cardinal(AArguments[1]) <> $80000000)) then
          Exit($7FC00000);
        LValue := Sqrt(LValue);
        Exit(PInteger(@LValue)^);
      end;
  end;
  if FProfile = TQvmHostProfile.Test then
    case LNumber of
      200:
        Exit(AMachine.Call(AArguments[1], [AArguments[2], AArguments[3]]));
      201:
        begin
          if LMemory.ArgPtr(AArguments[1], 0) = nil then
            Exit(-1);
          Exit(PInteger(HostPtr(LMemory, AArguments[1], 4))^);
        end;
      202:
        begin
          PInteger(HostPtr(LMemory, AArguments[1], 4))^ := AArguments[2];
          Exit(0);
        end;
      203:
        Exit(AArguments[1]);
    end;
  if (FProfile = TQvmHostProfile.Game) and (LNumber = 37) then
  begin
    if (FEntityToken >= Length(ENTITY_TOKENS)) or (AArguments[2] <= 0) then
      Exit(0);
    HostPtr(LMemory, AArguments[1], AArguments[2]);
    LMemory.WriteString(AArguments[1], ENTITY_TOKENS[FEntityToken], AArguments[2]);
    Inc(FEntityToken);
    Exit(1);
  end;
  if (FProfile = TQvmHostProfile.Game) and (LNumber = 19) then
  begin
    if AArguments[3] > 0 then
      HostPtr(LMemory, AArguments[2], 1)^ := 0;
    Exit(0);
  end;
  if (FProfile = TQvmHostProfile.CGame) and (LNumber = 50) then
  begin
    LState := HostPtr(LMemory, AArguments[1], GAME_STATE_OFFSETS + GAME_STATE_CHARS + 4);
    FillChar(LState^, GAME_STATE_OFFSETS + GAME_STATE_CHARS + 4, 0);
    PInteger(LState + 4 * 20)^ := 1;
    LText := 'baseoa-1';
    Move(LText[1], (LState + GAME_STATE_OFFSETS + 1)^, 9);
    PInteger(LState + GAME_STATE_OFFSETS + GAME_STATE_CHARS)^ := 10;
    Exit(0);
  end;
  Result := 0;
end;

function TQvmFakeHost.SystemCall(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer;
var
  LLine: string;
  LIndex: Integer;
begin
  Inc(FCount);
  TTestFnv.Mix64(FHash, @AArguments[0], 40);
  if FTrace and Assigned(FOutput) then
  begin
    LLine := 'S ' + IntToStr(AArguments[0]);
    for LIndex := 1 to 9 do
      LLine := LLine + ' ' + IntToStr(AArguments[LIndex]);
    FOutput.Add(LLine);
  end;
  Result := Answer(AMachine, AArguments);
  TTestFnv.Mix64(FHash, @Result, 4);
  if FTrace and Assigned(FOutput) then
    FOutput.Add('= ' + IntToStr(Result));
end;

{ TQvmNullHost }

function TQvmNullHost.SystemCall(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer;
begin
  Inc(FCount);
  FLast := AArguments;
  Result := 0;
end;

{ TQvmMemoryFiles }

procedure TQvmMemoryFiles.Put(const APath: AnsiString; const AData: TBytes);
begin
  Remove(APath);
  FNames := FNames + [APath];
  FData := FData + [AData];
end;

procedure TQvmMemoryFiles.Remove(const APath: AnsiString);
var
  LIndex: Integer;
begin
  for LIndex := High(FNames) downto 0 do
    if FNames[LIndex] = APath then
    begin
      Delete(FNames, LIndex, 1);
      Delete(FData, LIndex, 1);
    end;
end;

function TQvmMemoryFiles.TryReadFile(const APath: AnsiString; out AData: TBytes): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FNames) do
    if FNames[LIndex] = APath then
    begin
      AData := FData[LIndex];
      Exit(True);
    end;
  AData := nil;
  Result := False;
end;

{ TQvmScenario }

procedure TQvmScenario.Add(const ACommand: string);
begin
  Commands := Commands + [ACommand];
end;

procedure TQvmScenario.AddCall(const AValues: array of Integer);
var
  LLine: string;
  LValue: Integer;
begin
  LLine := 'call';
  for LValue in AValues do
    LLine := LLine + ' ' + IntToStr(LValue);
  Add(LLine);
end;

{ TQvmScenarioRunner }

class function TQvmScenarioRunner.Escaped(const AText: AnsiString): string;
var
  LIndex: Integer;
  LByte: Byte;
begin
  Result := '';
  for LIndex := 1 to Length(AText) do
  begin
    LByte := Byte(AText[LIndex]);
    if (LByte < 32) or (LByte > 126) or (LByte = Ord('\')) then
      Result := Result + '\x' + IntToHex(LByte, 2)
    else
      Result := Result + Char(LByte);
  end;
end;

class function TQvmScenarioRunner.Hex64(AValue: UInt64): string;
begin
  Result := LowerCase(IntToHex(AValue, 16));
end;

class function TQvmScenarioRunner.MemoryFingerprint(const AMachine: IQvmMachine): string;
var
  LMemory: IQvmMemory;
begin
  LMemory := AMachine.Memory;
  Result := Hex64(TTestFnv.Hash64(LMemory.Range(0, LMemory.Size), LMemory.Size));
end;

class procedure TQvmScenarioRunner.Report(const AText: string);
begin
  TDUnitX.CurrentRunner.Log(TLogLevel.Information, AText);
  System.Writeln;
  System.Writeln('[Qvm] ' + AText);
end;

class function TQvmScenarioRunner.ProfileName(AProfile: TQvmHostProfile): string;
const
  NAMES: array[TQvmHostProfile] of string = ('test', 'game', 'cgame', 'ui');
begin
  Result := NAMES[AProfile];
end;

class procedure TQvmScenarioRunner.Run(const AScenario: TQvmScenario; AOutput: TStrings);
var
  LHost: TQvmFakeHost;
  LHostKeeper: IQvmHost;
  LMachine: IQvmMachine;
  LLimits: TQvmLimits;
  LCommand: string;
  LWords: TArray<string>;
  LArguments: TArray<Integer>;
  LIndex, LValue: Integer;
  LDead: Boolean;

  procedure MemoryLine;
  var
    LFolder: string;
  begin
    // the data image, to compare it with the one the driver of the C writes with the same variable
    LFolder := GetEnvironmentVariable(MEMORY_DUMP_VARIABLE);
    if LFolder <> '' then
    begin
      TFile.WriteAllBytes(TPath.Combine(LFolder, Format('p_%d.bin', [FDumpSerial])),
        LMachine.Memory.ReadBytes(0, LMachine.Memory.Size));
      Inc(FDumpSerial);
    end;
    AOutput.Add(Format('M %s %d %s', [MemoryFingerprint(LMachine), LHost.Count, Hex64(LHost.Hash)]));
  end;

begin
  AOutput.Add('scenario ' + AScenario.Name);
  LHost := TQvmFakeHost.Create(AScenario.Profile, AOutput);
  LHostKeeper := LHost;
  LLimits := TQvmLimits.Default;
  LLimits.LegacyBitComplement := AScenario.LegacyBitComplement;
  LDead := False;
  try
    LMachine := TQvmFactory.CreateMachine('m', AScenario.Image, LHostKeeper, LLimits);
    if AScenario.MapText <> '' then
      LMachine.Symbols.Load(AScenario.MapText);
  except
    on E: EQvmException do
    begin
      AOutput.Add('E ' + Escaped(AnsiString(E.Message)));
      LDead := True;
    end;
  end;

  for LCommand in AScenario.Commands do
  begin
    LWords := LCommand.Split([' '], TStringSplitOptions.ExcludeEmpty);
    if Length(LWords) = 0 then
      Continue;
    if LWords[0] = 'trace' then
      LHost.Trace := LWords[1] = 'on'
    else if LWords[0] = 'note' then
      AOutput.Add(LCommand)
    else if LDead then
      Continue
    else if LWords[0] = 'call' then
    begin
      SetLength(LArguments, Length(LWords) - 2);
      for LIndex := 2 to High(LWords) do
        LArguments[LIndex - 2] := StrToInt(LWords[LIndex]);
      try
        LValue := LMachine.Call(StrToInt(LWords[1]), LArguments);
        AOutput.Add('R ' + IntToStr(LValue));
      except
        on E: EQvmFakeHostError do
        begin
          AOutput.Add('E ' + Escaped(AnsiString(E.Message)));
          LDead := True;
        end;
        on E: EQvmExecutionException do
        begin
          if E.Message = SDivisionByZero then
            AOutput.Add(TRAP_DIVIDE_BY_ZERO)
          else if E.Message = SDivisionOverflow then
            AOutput.Add(TRAP_OVERFLOW)
          else
            AOutput.Add('E ' + Escaped(AnsiString(E.Message)));
          LDead := True;
        end;
      end;
      if LDead then
        MemoryLine;
    end
    else if LWords[0] = 'mem' then
      MemoryLine
    else if LWords[0] = 'restart' then
    begin
      LMachine.Restart(AScenario.Image);
      AOutput.Add('restarted');
    end
    else if LWords[0] = 'info' then
      AOutput.Add(Format('I %d %d %d %d %d %d', [LMachine.Info.CodeLength, LMachine.Info.TableLength,
        LMachine.Info.DataLength, LMachine.ProgramStack, LMachine.StackBottom, LMachine.Symbols.Count]))
    else if LWords[0] = 'symbols' then
    begin
      for LValue := -1 to LMachine.Info.CodeLength do
        AOutput.Add(Format('Y %d %s', [LValue, string(LMachine.Symbols.ValueToSymbol(LValue))]));
    end
    else if LWords[0] = 'symval' then
      AOutput.Add(Format('V %s %d', [LWords[1], LMachine.Symbols.SymbolToValue(AnsiString(LWords[1]))]));
  end;
  AOutput.Add('end');
end;

end.
