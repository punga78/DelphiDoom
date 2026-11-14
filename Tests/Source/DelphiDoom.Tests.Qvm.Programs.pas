{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the QVM library - the programs of the parity with the  }
{  virtual machine of Quake III                                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Qvm.Programs;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Tests.Qvm.Assembler, DelphiDoom.Tests.Qvm.Support;

const
  /// <summary>The data image of the small programs</summary>
  QVM_TEST_IMAGE = 8192;
  /// <summary>The frame of a vmMain that calls nothing: the command is at FRAME + 8, the arguments follow</summary>
  QVM_TEST_FRAME = 16;

type
  /// <summary>
  ///   Every program the parity test runs, built with the assembler: one or more for each instruction and
  ///   the composed ones (recursion, jump tables, floats, block copies, system calls, re-entry, symbols),
  ///   and programs made at random from a fixed seed. The same list, written to disk, is what the driver
  ///   of the C runs to make the golden file (Tools\Verifica\120)
  /// </summary>
  TQvmPrograms = class
  strict private
    class var
      FSeed: Cardinal;
    class function Next: Cardinal; static;
    class function NewScenario(const AName: string; AAssembler: TQvmAssembler): TQvmScenario; static;
    class procedure AddIntegerScenarios(var AList: TArray<TQvmScenario>); static;
    class procedure AddFloatScenarios(var AList: TArray<TQvmScenario>); static;
    class procedure AddMemoryScenarios(var AList: TArray<TQvmScenario>); static;
    class procedure AddCallScenarios(var AList: TArray<TQvmScenario>); static;
    class procedure AddSystemCallScenarios(var AList: TArray<TQvmScenario>); static;
    class procedure AddComposedScenarios(var AList: TArray<TQvmScenario>); static;
    class procedure AddRandomScenarios(var AList: TArray<TQvmScenario>); static;
  public
    class function All: TArray<TQvmScenario>; static;
    /// <summary>vmMain( command, limit ): how many primes are below the limit (a sieve in the bss at 1024)</summary>
    class function Sieve(AImageSize: Integer): TBytes; static;
    /// <summary>OP_ENTER frame, the first two arguments, the instruction, OP_LEAVE</summary>
    class function Binary(AOpcode: Integer): TBytes; static;
    /// <summary>OP_ENTER frame, the first argument, the instruction, OP_LEAVE</summary>
    class function Unary(AOpcode: Integer): TBytes; static;
    /// <summary>1 when the branch on the first two arguments is taken, 0 otherwise</summary>
    class function Branching(AOpcode: Integer): TBytes; static;
    /// <summary>vmMain( command, number, a, b, c ): the system call of that number with three arguments</summary>
    class function AnySystemCall(out ATextAddress: Integer): TBytes; static;
    /// <summary>The write of the image at an address of the entry frame + offset (the nth argument is at 12 + 4n)</summary>
    class procedure Argument(AAssembler: TQvmAssembler; AFrame, AIndex: Integer); static;
  end;

implementation

uses
  DelphiDoom.Qvm.Opcodes, DelphiDoom.Tests.Shared.Fnv;

const
  INTEGER_VALUES: array[0..19] of Integer = (0, 1, -1, 2, -2, 7, 31, 32, 33, 255, -256, 32767, 32768, 65535,
    $7FFFFFFF, Integer($80000000), Integer($80000001), $12345678, -100, 1000003);
  FLOAT_VALUES: array[0..25] of Cardinal = ($00000000, $80000000, $3F800000, $BF800000, $40000000, $3F000000,
    $3DCCCCCD, $3EAAAAAB, $7F7FFFFF, $FF7FFFFF, $7F800000, $FF800000, $7FC00000, $FFC00000, $7F800001,
    $7FC12345, $FFA00000, $00000001, $007FFFFF, $00800000, $4B800000, $4F000000, $CF000000, $4EFFFFFF,
    $4F32D05E, $C7F12065);
  HOST_FLOATS: array[0..11] of Integer = ($40800000, $40000000, Integer($BF800000), Integer($80000000),
    $7F800000, $7FC00000, $3FC00000, Integer($BFC00000), $00000000, $4B800001, $3F7FFFFF, Integer($C0200000));
  SIEVE_LIMITS: array[0..6] of Integer = (0, 2, 3, 10, 100, 1000, 5000);
  HARMONIC_TERMS: array[0..7] of Integer = (0, 1, 2, 3, 10, 100, 1000, 20000);

{ TQvmPrograms }

class function TQvmPrograms.Next: Cardinal;
begin
  FSeed := FSeed * 1103515245 + 12345;
  Result := FSeed shr 8;
end;

class procedure TQvmPrograms.Argument(AAssembler: TQvmAssembler; AFrame, AIndex: Integer);
begin
  AAssembler.LoadLocal(AFrame + 8 + 4 * AIndex);
end;

class function TQvmPrograms.NewScenario(const AName: string; AAssembler: TQvmAssembler): TQvmScenario;
begin
  Result := Default(TQvmScenario);
  Result.Name := AName;
  Result.Profile := TQvmHostProfile.Test;
  try
    AAssembler.ImageSize(QVM_TEST_IMAGE);
    Result.Image := AAssembler.ToBytes;
  finally
    AAssembler.Free;
  end;
end;

class function TQvmPrograms.Binary(AOpcode: Integer): TBytes;
var
  LAssembler: TQvmAssembler;
begin
  LAssembler := TQvmAssembler.Create;
  try
    LAssembler.Op(OP_ENTER, QVM_TEST_FRAME);
    Argument(LAssembler, QVM_TEST_FRAME, 1);
    Argument(LAssembler, QVM_TEST_FRAME, 2);
    LAssembler.Op(AOpcode);
    LAssembler.Op(OP_LEAVE, QVM_TEST_FRAME);
    LAssembler.ImageSize(QVM_TEST_IMAGE);
    Result := LAssembler.ToBytes;
  finally
    LAssembler.Free;
  end;
end;

class function TQvmPrograms.Unary(AOpcode: Integer): TBytes;
var
  LAssembler: TQvmAssembler;
begin
  LAssembler := TQvmAssembler.Create;
  try
    LAssembler.Op(OP_ENTER, QVM_TEST_FRAME);
    Argument(LAssembler, QVM_TEST_FRAME, 1);
    LAssembler.Op(AOpcode);
    LAssembler.Op(OP_LEAVE, QVM_TEST_FRAME);
    LAssembler.ImageSize(QVM_TEST_IMAGE);
    Result := LAssembler.ToBytes;
  finally
    LAssembler.Free;
  end;
end;

class function TQvmPrograms.Branching(AOpcode: Integer): TBytes;
var
  LAssembler: TQvmAssembler;
  LTaken: Integer;
begin
  LAssembler := TQvmAssembler.Create;
  try
    LTaken := LAssembler.NewLabel;
    LAssembler.Op(OP_ENTER, QVM_TEST_FRAME);
    Argument(LAssembler, QVM_TEST_FRAME, 1);
    Argument(LAssembler, QVM_TEST_FRAME, 2);
    LAssembler.Branch(AOpcode, LTaken);
    LAssembler.Op(OP_CONST, 0);
    LAssembler.Op(OP_LEAVE, QVM_TEST_FRAME);
    LAssembler.Mark(LTaken);
    LAssembler.Op(OP_CONST, 1);
    LAssembler.Op(OP_LEAVE, QVM_TEST_FRAME);
    LAssembler.ImageSize(QVM_TEST_IMAGE);
    Result := LAssembler.ToBytes;
  finally
    LAssembler.Free;
  end;
end;

class function TQvmPrograms.Sieve(AImageSize: Integer): TBytes;
const
  FRAME = 24;
  SIEVE_BASE = 1024;
  INDEX = 8;
  COUNT = 12;
  MULTIPLE = 16;
var
  LAssembler: TQvmAssembler;
  LLoop, LInner, LNext, LDone: Integer;
begin
  LAssembler := TQvmAssembler.Create;
  try
    LNext := LAssembler.NewLabel;
    LDone := LAssembler.NewLabel;
    LAssembler.Op(OP_ENTER, FRAME);
    // count = 0; index = 2
    LAssembler.Op(OP_LOCAL, COUNT);
    LAssembler.Op(OP_CONST, 0);
    LAssembler.Op(OP_STORE4);
    LAssembler.Op(OP_LOCAL, INDEX);
    LAssembler.Op(OP_CONST, 2);
    LAssembler.Op(OP_STORE4);
    // while index < limit
    LLoop := LAssembler.MarkNew;
    LAssembler.LoadLocal(INDEX);
    Argument(LAssembler, FRAME, 1);
    LAssembler.Branch(OP_GEI, LDone);
    // a marked number is not a prime
    LAssembler.Op(OP_CONST, SIEVE_BASE);
    LAssembler.LoadLocal(INDEX);
    LAssembler.Op(OP_ADD);
    LAssembler.Op(OP_LOAD1);
    LAssembler.Op(OP_CONST, 0);
    LAssembler.Branch(OP_NE, LNext);
    // count++
    LAssembler.Op(OP_LOCAL, COUNT);
    LAssembler.LoadLocal(COUNT);
    LAssembler.Op(OP_CONST, 1);
    LAssembler.Op(OP_ADD);
    LAssembler.Op(OP_STORE4);
    // multiple = index + index
    LAssembler.Op(OP_LOCAL, MULTIPLE);
    LAssembler.LoadLocal(INDEX);
    LAssembler.LoadLocal(INDEX);
    LAssembler.Op(OP_ADD);
    LAssembler.Op(OP_STORE4);
    // while multiple < limit: mark it, multiple += index
    LInner := LAssembler.MarkNew;
    LAssembler.LoadLocal(MULTIPLE);
    Argument(LAssembler, FRAME, 1);
    LAssembler.Branch(OP_GEI, LNext);
    LAssembler.Op(OP_CONST, SIEVE_BASE);
    LAssembler.LoadLocal(MULTIPLE);
    LAssembler.Op(OP_ADD);
    LAssembler.Op(OP_CONST, 1);
    LAssembler.Op(OP_STORE1);
    LAssembler.Op(OP_LOCAL, MULTIPLE);
    LAssembler.LoadLocal(MULTIPLE);
    LAssembler.LoadLocal(INDEX);
    LAssembler.Op(OP_ADD);
    LAssembler.Op(OP_STORE4);
    LAssembler.Jump(LInner);
    // index++
    LAssembler.Mark(LNext);
    LAssembler.Op(OP_LOCAL, INDEX);
    LAssembler.LoadLocal(INDEX);
    LAssembler.Op(OP_CONST, 1);
    LAssembler.Op(OP_ADD);
    LAssembler.Op(OP_STORE4);
    LAssembler.Jump(LLoop);
    LAssembler.Mark(LDone);
    LAssembler.LoadLocal(COUNT);
    LAssembler.Op(OP_LEAVE, FRAME);
    LAssembler.ImageSize(AImageSize);
    Result := LAssembler.ToBytes;
  finally
    LAssembler.Free;
  end;
end;

class function TQvmPrograms.AnySystemCall(out ATextAddress: Integer): TBytes;
const
  FRAME = 32;
var
  LAssembler: TQvmAssembler;
begin
  LAssembler := TQvmAssembler.Create;
  try
    LAssembler.Data([$11111111, $22222222, $33333333, $44444444]);
    ATextAddress := LAssembler.DataText('hello \ world' + #10);
    LAssembler.DataText('second');
    LAssembler.Op(OP_ENTER, FRAME);
    Argument(LAssembler, FRAME, 2);
    LAssembler.Op(OP_ARG, 8);
    Argument(LAssembler, FRAME, 3);
    LAssembler.Op(OP_ARG, 12);
    Argument(LAssembler, FRAME, 4);
    LAssembler.Op(OP_ARG, 16);
    // the address of the system call is -1 - number
    LAssembler.Op(OP_CONST, -1);
    Argument(LAssembler, FRAME, 1);
    LAssembler.Op(OP_SUB);
    LAssembler.Op(OP_CALL);
    LAssembler.Op(OP_LEAVE, FRAME);
    LAssembler.ImageSize(QVM_TEST_IMAGE);
    Result := LAssembler.ToBytes;
  finally
    LAssembler.Free;
  end;
end;

class procedure TQvmPrograms.AddIntegerScenarios(var AList: TArray<TQvmScenario>);
const
  BINARY_OPS: array[0..13] of Integer = (OP_ADD, OP_SUB, OP_MULI, OP_MULU, OP_DIVI, OP_DIVU, OP_MODI, OP_MODU,
    OP_BAND, OP_BOR, OP_BXOR, OP_LSH, OP_RSHI, OP_RSHU);
  UNARY_OPS: array[0..3] of Integer = (OP_NEGI, OP_SEX8, OP_SEX16, OP_CVIF);
  BRANCH_OPS: array[0..9] of Integer = (OP_EQ, OP_NE, OP_LTI, OP_LEI, OP_GTI, OP_GEI, OP_LTU, OP_LEU, OP_GTU,
    OP_GEU);
  TRAP_OPS: array[0..3] of Integer = (OP_DIVI, OP_MODI, OP_DIVU, OP_MODU);
var
  LScenario: TQvmScenario;
  LAssembler: TQvmAssembler;
  LOpcode, LFirst, LSecond, LIndex: Integer;
  LSigned: Boolean;
begin
  for LOpcode in BINARY_OPS do
  begin
    LScenario := Default(TQvmScenario);
    LScenario.Name := 'int.' + TQvmOpcodes.Name(LOpcode);
    LScenario.Image := Binary(LOpcode);
    LSigned := (LOpcode = OP_DIVI) or (LOpcode = OP_MODI);
    for LFirst in INTEGER_VALUES do
      for LSecond in INTEGER_VALUES do
      begin
        // these stop the processor: they have their own scenarios
        if (LOpcode >= OP_DIVI) and (LOpcode <= OP_MODU) and (LSecond = 0) then
          Continue;
        if LSigned and (LSecond = -1) and (LFirst = Low(Integer)) then
          Continue;
        LScenario.AddCall([0, LFirst, LSecond]);
      end;
    for LIndex := 1 to 60 do
    begin
      LFirst := Integer(Next * 2654435761);
      LSecond := Integer(Next * 2246822519) or 1;
      if LSigned and (LSecond = -1) then
        LSecond := 3;
      LScenario.AddCall([0, LFirst, LSecond]);
    end;
    LScenario.Add('mem');
    AList := AList + [LScenario];
  end;

  for LOpcode in TRAP_OPS do
  begin
    LScenario := Default(TQvmScenario);
    LScenario.Name := 'trap.zero.' + TQvmOpcodes.Name(LOpcode);
    LScenario.Image := Binary(LOpcode);
    LScenario.AddCall([0, 5, 3]);
    LScenario.AddCall([0, 5, 0]);
    AList := AList + [LScenario];
  end;
  for LOpcode in [OP_DIVI, OP_MODI] do
  begin
    LScenario := Default(TQvmScenario);
    LScenario.Name := 'trap.overflow.' + TQvmOpcodes.Name(LOpcode);
    LScenario.Image := Binary(LOpcode);
    LScenario.AddCall([0, Low(Integer), -1]);
    AList := AList + [LScenario];
  end;

  for LOpcode in UNARY_OPS do
  begin
    LScenario := Default(TQvmScenario);
    LScenario.Name := 'int.' + TQvmOpcodes.Name(LOpcode);
    LScenario.Image := Unary(LOpcode);
    for LFirst in INTEGER_VALUES do
      LScenario.AddCall([0, LFirst]);
    for LIndex := 1 to 100 do
      LScenario.AddCall([0, Integer(Next * 2654435761)]);
    AList := AList + [LScenario];
  end;

  // the interpreter of 1.32 writes the complement below the top and leaves the top: (~b) - b
  LAssembler := TQvmAssembler.Create;
  LAssembler.Op(OP_ENTER, QVM_TEST_FRAME);
  Argument(LAssembler, QVM_TEST_FRAME, 1);
  Argument(LAssembler, QVM_TEST_FRAME, 2);
  LAssembler.Op(OP_BCOM);
  LAssembler.Op(OP_SUB);
  LAssembler.Op(OP_LEAVE, QVM_TEST_FRAME);
  LScenario := NewScenario('int.OP_BCOM.legacy', LAssembler);
  LScenario.LegacyBitComplement := True;
  for LFirst in INTEGER_VALUES do
    LScenario.AddCall([0, LFirst, LFirst xor $5A5A5A5A]);
  AList := AList + [LScenario];

  for LOpcode in BRANCH_OPS do
  begin
    LScenario := Default(TQvmScenario);
    LScenario.Name := 'branch.' + TQvmOpcodes.Name(LOpcode);
    LScenario.Image := Branching(LOpcode);
    for LFirst in INTEGER_VALUES do
      for LSecond in INTEGER_VALUES do
        LScenario.AddCall([0, LFirst, LSecond]);
    AList := AList + [LScenario];
  end;
end;

class procedure TQvmPrograms.AddFloatScenarios(var AList: TArray<TQvmScenario>);
const
  BINARY_OPS: array[0..3] of Integer = (OP_ADDF, OP_SUBF, OP_MULF, OP_DIVF);
  BRANCH_OPS: array[0..5] of Integer = (OP_EQF, OP_NEF, OP_LTF, OP_LEF, OP_GTF, OP_GEF);
  UNARY_OPS: array[0..1] of Integer = (OP_NEGF, OP_CVFI);
var
  LScenario: TQvmScenario;
  LOpcode, LIndex, LFirstBits, LSecondBits: Integer;
  LFirst, LSecond: Cardinal;

  // the bits of a float between 2^-7 and 2^9 of either sign (one draw for each statement: the order in which
  // an expression is evaluated is not the same at 32 and at 64 bit)
  function OrdinaryFloat: Integer;
  var
    LSign, LExponent, LMantissa: Cardinal;
  begin
    LSign := Next;
    LExponent := Next;
    LMantissa := Next;
    Result := Integer((LSign shl 31) or ((120 + LExponent mod 16) shl 23) or (LMantissa and $7FFFFF));
  end;

begin
  for LOpcode in BINARY_OPS do
  begin
    LScenario := Default(TQvmScenario);
    LScenario.Name := 'float.' + TQvmOpcodes.Name(LOpcode);
    LScenario.Image := Binary(LOpcode);
    for LFirst in FLOAT_VALUES do
      for LSecond in FLOAT_VALUES do
        LScenario.AddCall([0, Integer(LFirst), Integer(LSecond)]);
    // any bits: tiny, huge, denormal and NaN operands of every kind
    for LIndex := 1 to 300 do
    begin
      LFirstBits := Integer(Next * 2654435761);
      LSecondBits := Integer(Next * 2246822519);
      LScenario.AddCall([0, LFirstBits, LSecondBits]);
    end;
    // ordinary numbers, whose results must be rounded
    for LIndex := 1 to 300 do
    begin
      LFirstBits := OrdinaryFloat;
      LSecondBits := OrdinaryFloat;
      LScenario.AddCall([0, LFirstBits, LSecondBits]);
    end;
    AList := AList + [LScenario];
  end;

  for LOpcode in BRANCH_OPS do
  begin
    LScenario := Default(TQvmScenario);
    LScenario.Name := 'branch.' + TQvmOpcodes.Name(LOpcode);
    LScenario.Image := Branching(LOpcode);
    for LFirst in FLOAT_VALUES do
      for LSecond in FLOAT_VALUES do
        LScenario.AddCall([0, Integer(LFirst), Integer(LSecond)]);
    for LIndex := 1 to 100 do
    begin
      LFirstBits := Integer(Next * 2654435761);
      LSecondBits := Integer(Next * 2246822519);
      LScenario.AddCall([0, LFirstBits, LSecondBits]);
    end;
    AList := AList + [LScenario];
  end;

  for LOpcode in UNARY_OPS do
  begin
    LScenario := Default(TQvmScenario);
    LScenario.Name := 'float.' + TQvmOpcodes.Name(LOpcode);
    LScenario.Image := Unary(LOpcode);
    for LFirst in FLOAT_VALUES do
      LScenario.AddCall([0, Integer(LFirst)]);
    for LIndex := 1 to 200 do
      LScenario.AddCall([0, Integer(Next * 2654435761)]);
    // every exponent around the integers, both signs
    for LIndex := 120 to 162 do
    begin
      LScenario.AddCall([0, (LIndex shl 23) or $2AAAAA]);
      LScenario.AddCall([0, Integer($80000000) or (LIndex shl 23) or $7FFFFF]);
    end;
    AList := AList + [LScenario];
  end;
end;

class procedure TQvmPrograms.AddMemoryScenarios(var AList: TArray<TQvmScenario>);
const
  STORES: array[0..2] of Integer = (OP_STORE4, OP_STORE2, OP_STORE1);
  LOADS: array[0..2] of Integer = (OP_LOAD4, OP_LOAD2, OP_LOAD1);
  ADDRESSES: array[0..11] of Integer = (1024, 1025, 1026, 1027, 2048, 2051, 1024 + QVM_TEST_IMAGE,
    2049 + 5 * QVM_TEST_IMAGE, 1030 - QVM_TEST_IMAGE, Integer($80000404), -4, -1);
  COUNTS: array[0..7] of Integer = (0, 4, 8, 64, 1024, -4, QVM_TEST_IMAGE, QVM_TEST_IMAGE + 16);
var
  LScenario: TQvmScenario;
  LAssembler: TQvmAssembler;
  LEntries: array[0..7] of Integer;
  LIndex, LAddress, LCount, LTable: Integer;
begin
  // vmMain( command, address, value ): 0..2 store 4, 2, 1 bytes; 3..5 load 4, 2, 1 bytes, through a jump table
  LAssembler := TQvmAssembler.Create;
  for LIndex := 0 to 5 do
    LEntries[LIndex] := LAssembler.NewLabel;
  LTable := LAssembler.DataLength;
  for LIndex := 0 to 5 do
    LAssembler.DataLabel(LEntries[LIndex]);
  for LIndex := 0 to 63 do
    LAssembler.Data([Integer($A0B0C0D0) + LIndex * $01010101]);
  LAssembler.Op(OP_ENTER, QVM_TEST_FRAME);
  Argument(LAssembler, QVM_TEST_FRAME, 0);
  LAssembler.Op(OP_CONST, 2);
  LAssembler.Op(OP_LSH);
  LAssembler.Op(OP_CONST, LTable);
  LAssembler.Op(OP_ADD);
  LAssembler.Op(OP_LOAD4);
  LAssembler.Op(OP_JUMP);
  for LIndex := 0 to 2 do
  begin
    LAssembler.Mark(LEntries[LIndex]);
    Argument(LAssembler, QVM_TEST_FRAME, 1);
    Argument(LAssembler, QVM_TEST_FRAME, 2);
    LAssembler.Op(STORES[LIndex]);
    LAssembler.Op(OP_CONST, 0);
    LAssembler.Op(OP_LEAVE, QVM_TEST_FRAME);
  end;
  for LIndex := 0 to 2 do
  begin
    LAssembler.Mark(LEntries[3 + LIndex]);
    Argument(LAssembler, QVM_TEST_FRAME, 1);
    LAssembler.Op(LOADS[LIndex]);
    LAssembler.Op(OP_LEAVE, QVM_TEST_FRAME);
  end;
  LScenario := NewScenario('mem.loadstore', LAssembler);
  // the data as they are loaded, the last bytes of the image (the zeroes after it are read too)
  for LAddress := 0 to 40 do
    for LIndex := 3 to 5 do
      LScenario.AddCall([LIndex, 20 + LAddress]);
  for LAddress := QVM_TEST_IMAGE - 6 to QVM_TEST_IMAGE + 2 do
    for LIndex := 3 to 5 do
      LScenario.AddCall([LIndex, LAddress]);
  // a store, then the three loads around it
  LCount := 0;
  for LAddress in ADDRESSES do
    for LIndex := 0 to 2 do
    begin
      Inc(LCount);
      LScenario.AddCall([LIndex, LAddress, Integer($89ABCDEF) + LCount * $01020304]);
      LScenario.AddCall([3, LAddress]);
      LScenario.AddCall([4, LAddress + 1]);
      LScenario.AddCall([5, LAddress + 3]);
      LScenario.AddCall([3, (LAddress and (QVM_TEST_IMAGE - 1)) and not 3]);
    end;
  LScenario.Add('mem');
  AList := AList + [LScenario];

  // vmMain( command, destination, source ): OP_BLOCK_COPY with the count of the command
  LAssembler := TQvmAssembler.Create;
  for LIndex := 0 to High(COUNTS) do
    LEntries[LIndex] := LAssembler.NewLabel;
  LTable := LAssembler.DataLength;
  for LIndex := 0 to High(COUNTS) do
    LAssembler.DataLabel(LEntries[LIndex]);
  for LIndex := 0 to 511 do
    LAssembler.Data([Integer($01000000) * (LIndex and 127) + LIndex * 7919]);
  LAssembler.Op(OP_ENTER, QVM_TEST_FRAME);
  Argument(LAssembler, QVM_TEST_FRAME, 0);
  LAssembler.Op(OP_CONST, 2);
  LAssembler.Op(OP_LSH);
  LAssembler.Op(OP_CONST, LTable);
  LAssembler.Op(OP_ADD);
  LAssembler.Op(OP_LOAD4);
  LAssembler.Op(OP_JUMP);
  for LIndex := 0 to High(COUNTS) do
  begin
    LAssembler.Mark(LEntries[LIndex]);
    Argument(LAssembler, QVM_TEST_FRAME, 1);
    Argument(LAssembler, QVM_TEST_FRAME, 2);
    LAssembler.Op(OP_BLOCK_COPY, COUNTS[LIndex]);
    LAssembler.Op(OP_CONST, COUNTS[LIndex]);
    LAssembler.Op(OP_LEAVE, QVM_TEST_FRAME);
  end;
  LScenario := NewScenario('mem.blockcopy', LAssembler);
  // apart, overlapping forwards and backwards (the copy goes from the last word to the first)
  LScenario.AddCall([0, 3000, 100]);
  LScenario.AddCall([1, 3000, 100]);
  LScenario.AddCall([2, 3008, 104]);
  LScenario.AddCall([3, 3100, 200]);
  LScenario.Add('mem');
  LScenario.AddCall([3, 204, 200]);
  LScenario.Add('mem');
  LScenario.AddCall([3, 400, 404]);
  LScenario.Add('mem');
  LScenario.AddCall([4, 4096, 64]);
  LScenario.AddCall([4, 68, 64]);
  LScenario.Add('mem');
  // masked addresses
  LScenario.AddCall([2, 3200 + QVM_TEST_IMAGE, 300 - 3 * QVM_TEST_IMAGE]);
  LScenario.Add('mem');
  // the count is cut where the destination would pass the end: nothing is copied
  LScenario.AddCall([3, QVM_TEST_IMAGE - 32, 300]);
  LScenario.Add('mem');
  // a negative count and counts as large as the image, away from the address 0
  LScenario.AddCall([5, 3400, 500]);
  LScenario.AddCall([6, 3400, 500]);
  LScenario.AddCall([7, 3400, 500]);
  LScenario.AddCall([6, 0, 0]);
  LScenario.Add('mem');
  AList := AList + [LScenario];

  for LIndex := 0 to 2 do
  begin
    LAssembler := TQvmAssembler.Create;
    LAssembler.Op(OP_ENTER, QVM_TEST_FRAME);
    Argument(LAssembler, QVM_TEST_FRAME, 1);
    Argument(LAssembler, QVM_TEST_FRAME, 2);
    if LIndex = 0 then
      LAssembler.Op(OP_BLOCK_COPY, 6)
    else
      LAssembler.Op(OP_BLOCK_COPY, 8);
    LAssembler.Op(OP_CONST, 0);
    LAssembler.Op(OP_LEAVE, QVM_TEST_FRAME);
    LScenario := NewScenario('mem.blockcopy.unaligned' + IntToStr(LIndex), LAssembler);
    case LIndex of
      0:
        LScenario.AddCall([0, 3000, 100]);
      1:
        LScenario.AddCall([0, 3001, 100]);
    else
      LScenario.AddCall([0, 3000, 102]);
    end;
    AList := AList + [LScenario];
  end;
end;

class procedure TQvmPrograms.AddCallScenarios(var AList: TArray<TQvmScenario>);
const
  FRAME = 24;
var
  LScenario: TQvmScenario;
  LAssembler: TQvmAssembler;
  LFunction, LBase, LOther, LIndex: Integer;
  LCases: array[0..4] of Integer;
begin
  // factorial( n ) = n <= 1 ? 1 : n * factorial( n - 1 ), vmMain( command, n ) calls it
  LAssembler := TQvmAssembler.Create;
  LFunction := LAssembler.NewLabel;
  LBase := LAssembler.NewLabel;
  LAssembler.Op(OP_ENTER, FRAME);
  Argument(LAssembler, FRAME, 1);
  LAssembler.Op(OP_ARG, 8);
  LAssembler.CallLabel(LFunction);
  LAssembler.Op(OP_LEAVE, FRAME);
  LAssembler.Mark(LFunction);
  LAssembler.Op(OP_ENTER, FRAME);
  LAssembler.LoadLocal(FRAME + 8);
  LAssembler.Op(OP_CONST, 1);
  LAssembler.Branch(OP_LEI, LBase);
  LAssembler.LoadLocal(FRAME + 8);
  LAssembler.Op(OP_CONST, 1);
  LAssembler.Op(OP_SUB);
  LAssembler.Op(OP_ARG, 8);
  LAssembler.CallLabel(LFunction);
  LAssembler.LoadLocal(FRAME + 8);
  LAssembler.Op(OP_MULI);
  LAssembler.Op(OP_LEAVE, FRAME);
  LAssembler.Mark(LBase);
  LAssembler.Op(OP_CONST, 1);
  LAssembler.Op(OP_LEAVE, FRAME);
  LScenario := NewScenario('call.factorial', LAssembler);
  for LIndex := 0 to 20 do
    LScenario.AddCall([0, LIndex]);
  LScenario.AddCall([0, 200]);
  LScenario.Add('mem');
  AList := AList + [LScenario];

  // fibonacci( n ) with two recursive calls and a local
  LAssembler := TQvmAssembler.Create;
  LFunction := LAssembler.NewLabel;
  LBase := LAssembler.NewLabel;
  LAssembler.Op(OP_ENTER, FRAME);
  Argument(LAssembler, FRAME, 1);
  LAssembler.Op(OP_ARG, 8);
  LAssembler.CallLabel(LFunction);
  LAssembler.Op(OP_LEAVE, FRAME);
  LAssembler.Mark(LFunction);
  LAssembler.Op(OP_ENTER, FRAME);
  LAssembler.LoadLocal(FRAME + 8);
  LAssembler.Op(OP_CONST, 2);
  LAssembler.Branch(OP_LTI, LBase);
  // local 12 = fibonacci( n - 1 )
  LAssembler.Op(OP_LOCAL, 12);
  LAssembler.LoadLocal(FRAME + 8);
  LAssembler.Op(OP_CONST, 1);
  LAssembler.Op(OP_SUB);
  LAssembler.Op(OP_ARG, 8);
  LAssembler.CallLabel(LFunction);
  LAssembler.Op(OP_STORE4);
  LAssembler.LoadLocal(FRAME + 8);
  LAssembler.Op(OP_CONST, 2);
  LAssembler.Op(OP_SUB);
  LAssembler.Op(OP_ARG, 8);
  LAssembler.CallLabel(LFunction);
  LAssembler.LoadLocal(12);
  LAssembler.Op(OP_ADD);
  LAssembler.Op(OP_LEAVE, FRAME);
  LAssembler.Mark(LBase);
  LAssembler.LoadLocal(FRAME + 8);
  LAssembler.Op(OP_LEAVE, FRAME);
  LScenario := NewScenario('call.fibonacci', LAssembler);
  for LIndex := 0 to 18 do
    LScenario.AddCall([0, LIndex]);
  LScenario.Add('mem');
  AList := AList + [LScenario];

  // a switch through a table of instruction numbers, with a default
  LAssembler := TQvmAssembler.Create;
  for LIndex := 0 to 4 do
    LCases[LIndex] := LAssembler.NewLabel;
  LOther := LAssembler.NewLabel;
  LBase := LAssembler.DataLength;
  for LIndex := 0 to 4 do
    LAssembler.DataLabel(LCases[LIndex]);
  LAssembler.Op(OP_ENTER, QVM_TEST_FRAME);
  Argument(LAssembler, QVM_TEST_FRAME, 0);
  LAssembler.Op(OP_CONST, 5);
  LAssembler.Branch(OP_GEU, LOther);
  Argument(LAssembler, QVM_TEST_FRAME, 0);
  LAssembler.Op(OP_CONST, 2);
  LAssembler.Op(OP_LSH);
  LAssembler.Op(OP_CONST, LBase);
  LAssembler.Op(OP_ADD);
  LAssembler.Op(OP_LOAD4);
  LAssembler.Op(OP_JUMP);
  for LIndex := 0 to 4 do
  begin
    LAssembler.Mark(LCases[LIndex]);
    Argument(LAssembler, QVM_TEST_FRAME, 1);
    LAssembler.Op(OP_CONST, 100 * (LIndex + 1));
    LAssembler.Op(OP_ADD);
    LAssembler.Op(OP_LEAVE, QVM_TEST_FRAME);
  end;
  LAssembler.Mark(LOther);
  LAssembler.Op(OP_CONST, -1);
  LAssembler.Op(OP_LEAVE, QVM_TEST_FRAME);
  LScenario := NewScenario('call.switch', LAssembler);
  for LIndex := -2 to 7 do
    LScenario.AddCall([LIndex, 7]);
  AList := AList + [LScenario];

  // the instructions that do nothing, and push and pop
  LAssembler := TQvmAssembler.Create;
  LAssembler.Op(OP_ENTER, QVM_TEST_FRAME);
  LAssembler.Op(OP_UNDEF);
  LAssembler.Op(OP_IGNORE);
  LAssembler.Op(OP_BREAK);
  Argument(LAssembler, QVM_TEST_FRAME, 1);
  LAssembler.Op(OP_CONST, 77);
  LAssembler.Op(OP_POP);
  LAssembler.Op(OP_BREAK);
  // the value that was popped is still in the slot
  LAssembler.Op(OP_PUSH);
  LAssembler.Op(OP_ADD);
  LAssembler.Op(OP_IGNORE);
  LAssembler.Op(OP_LEAVE, QVM_TEST_FRAME);
  LScenario := NewScenario('misc.noops', LAssembler);
  LScenario.AddCall([0, 5]);
  LScenario.AddCall([0, -77]);
  AList := AList + [LScenario];

  // "Interpreter error: opStack = n" when the entry point leaves more or less than one value
  for LIndex := 0 to 3 do
  begin
    LAssembler := TQvmAssembler.Create;
    LAssembler.Op(OP_ENTER, QVM_TEST_FRAME);
    for LOther := 1 to LIndex do
      LAssembler.Op(OP_CONST, LOther);
    LAssembler.Op(OP_LEAVE, QVM_TEST_FRAME);
    LScenario := NewScenario('misc.balance' + IntToStr(LIndex), LAssembler);
    LScenario.AddCall([0]);
    AList := AList + [LScenario];
  end;

  // the nine arguments of VM_Call and the command, summed with weights
  LAssembler := TQvmAssembler.Create;
  LAssembler.Op(OP_ENTER, QVM_TEST_FRAME);
  LAssembler.Op(OP_CONST, 0);
  for LIndex := 0 to 9 do
  begin
    Argument(LAssembler, QVM_TEST_FRAME, LIndex);
    LAssembler.Op(OP_CONST, LIndex + 1);
    LAssembler.Op(OP_MULI);
    LAssembler.Op(OP_ADD);
  end;
  LAssembler.Op(OP_LEAVE, QVM_TEST_FRAME);
  LScenario := NewScenario('call.arguments', LAssembler);
  LScenario.AddCall([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  LScenario.AddCall([7]);
  LScenario.AddCall([-1, -2, -3]);
  LScenario.AddCall([1, 0, 0, 0, 0, 0, 0, 0, 0, 1000]);
  LScenario.Add('info');
  AList := AList + [LScenario];
end;

class procedure TQvmPrograms.AddSystemCallScenarios(var AList: TArray<TQvmScenario>);
const
  FRAME = 56;
  REENTER_FRAME = 32;
var
  LScenario: TQvmScenario;
  LAssembler: TQvmAssembler;
  LIndex, LText, LDouble, LChain, LCount, LDone: Integer;
begin
  // nine arguments to a system call
  LAssembler := TQvmAssembler.Create;
  LAssembler.Op(OP_ENTER, FRAME);
  for LIndex := 0 to 8 do
  begin
    Argument(LAssembler, FRAME, LIndex + 1);
    LAssembler.Op(OP_ARG, 8 + 4 * LIndex);
  end;
  LAssembler.SystemCall(203);
  LAssembler.Op(OP_LEAVE, FRAME);
  LScenario := NewScenario('sys.arguments', LAssembler);
  LScenario.AddCall([0, 11, 22, 33, 44, 55, 66, 77, 88, 99]);
  LScenario.AddCall([0, -1, Low(Integer), High(Integer)]);
  LScenario.Add('mem');
  AList := AList + [LScenario];

  // any system call with three arguments: the answers of the host
  LScenario := Default(TQvmScenario);
  LScenario.Name := 'sys.host';
  LScenario.Image := AnySystemCall(LText);
  // print, and a call nobody answers
  LScenario.AddCall([0, 0, LText]);
  LScenario.AddCall([0, 0, LText + 16]);
  LScenario.AddCall([0, 55, 1, 2, 3]);
  LScenario.AddCall([0, 203, 1234]);
  // memset, memcpy (overlapping too), strncpy (shorter and longer than the text)
  LScenario.AddCall([0, 100, 2000, $1AB, 37]);
  LScenario.AddCall([0, 101, 2100, 0, 40]);
  LScenario.AddCall([0, 101, 2104, 2100, 36]);
  LScenario.AddCall([0, 102, 2200, LText, 5]);
  LScenario.AddCall([0, 102, 2300, LText, 40]);
  LScenario.AddCall([0, 100, 2000 + 3 * QVM_TEST_IMAGE, 9, 3]);
  LScenario.Add('mem');
  // read (the address 0 is "no pointer" for VM_ArgPtr) and write a word
  LScenario.AddCall([0, 201, 0]);
  LScenario.AddCall([0, 201, 4]);
  LScenario.AddCall([0, 201, 4 - QVM_TEST_IMAGE]);
  LScenario.AddCall([0, 202, 2400, $600DF00D]);
  LScenario.AddCall([0, 201, 2400]);
  // sqrt, floor, ceil on the bits of a float
  for LIndex in HOST_FLOATS do
  begin
    LScenario.AddCall([0, 106, LIndex]);
    LScenario.AddCall([0, 107, LIndex]);
    LScenario.AddCall([0, 108, LIndex]);
  end;
  LScenario.AddCall([0, 103, $3F800000]);
  LScenario.AddCall([0, 104, $3F800000]);
  LScenario.AddCall([0, 105, $3F800000, $3F800000]);
  LScenario.Add('mem');
  // the error of the module ends the call
  LScenario.AddCall([0, 1, LText]);
  AList := AList + [LScenario];

  // what the host refuses
  for LIndex := 0 to 2 do
  begin
    LScenario := Default(TQvmScenario);
    LScenario.Name := 'sys.range' + IntToStr(LIndex);
    LScenario.Image := AnySystemCall(LText);
    case LIndex of
      0:
        LScenario.AddCall([0, 100, QVM_TEST_IMAGE - 8, 1, 9]);
      1:
        LScenario.AddCall([0, 101, 100, QVM_TEST_IMAGE - 4, 8]);
    else
      LScenario.AddCall([0, 202, QVM_TEST_IMAGE - 2, 1]);
    end;
    AList := AList + [LScenario];
  end;

  // the host enters the machine again: 0 = a + b; 1 = 2 * host( 0, a, b ); 2 = host( 1, a, b ) + 1;
  // 3 = a <= 0 ? b : host( 3, a - 1, b + a )
  LAssembler := TQvmAssembler.Create;
  LDouble := LAssembler.NewLabel;
  LChain := LAssembler.NewLabel;
  LCount := LAssembler.NewLabel;
  LDone := LAssembler.NewLabel;
  LAssembler.Op(OP_ENTER, REENTER_FRAME);
  Argument(LAssembler, REENTER_FRAME, 0);
  LAssembler.Op(OP_CONST, 1);
  LAssembler.Branch(OP_EQ, LDouble);
  Argument(LAssembler, REENTER_FRAME, 0);
  LAssembler.Op(OP_CONST, 2);
  LAssembler.Branch(OP_EQ, LChain);
  Argument(LAssembler, REENTER_FRAME, 0);
  LAssembler.Op(OP_CONST, 3);
  LAssembler.Branch(OP_EQ, LCount);
  Argument(LAssembler, REENTER_FRAME, 1);
  Argument(LAssembler, REENTER_FRAME, 2);
  LAssembler.Op(OP_ADD);
  LAssembler.Op(OP_LEAVE, REENTER_FRAME);
  LAssembler.Mark(LDouble);
  LAssembler.Op(OP_CONST, 0);
  LAssembler.Op(OP_ARG, 8);
  Argument(LAssembler, REENTER_FRAME, 1);
  LAssembler.Op(OP_ARG, 12);
  Argument(LAssembler, REENTER_FRAME, 2);
  LAssembler.Op(OP_ARG, 16);
  LAssembler.SystemCall(200);
  LAssembler.Op(OP_CONST, 2);
  LAssembler.Op(OP_MULI);
  LAssembler.Op(OP_LEAVE, REENTER_FRAME);
  LAssembler.Mark(LChain);
  LAssembler.Op(OP_CONST, 1);
  LAssembler.Op(OP_ARG, 8);
  Argument(LAssembler, REENTER_FRAME, 1);
  LAssembler.Op(OP_ARG, 12);
  Argument(LAssembler, REENTER_FRAME, 2);
  LAssembler.Op(OP_ARG, 16);
  LAssembler.SystemCall(200);
  LAssembler.Op(OP_CONST, 1);
  LAssembler.Op(OP_ADD);
  LAssembler.Op(OP_LEAVE, REENTER_FRAME);
  LAssembler.Mark(LCount);
  Argument(LAssembler, REENTER_FRAME, 1);
  LAssembler.Op(OP_CONST, 0);
  LAssembler.Branch(OP_LEI, LDone);
  LAssembler.Op(OP_CONST, 3);
  LAssembler.Op(OP_ARG, 8);
  Argument(LAssembler, REENTER_FRAME, 1);
  LAssembler.Op(OP_CONST, 1);
  LAssembler.Op(OP_SUB);
  LAssembler.Op(OP_ARG, 12);
  Argument(LAssembler, REENTER_FRAME, 2);
  Argument(LAssembler, REENTER_FRAME, 1);
  LAssembler.Op(OP_ADD);
  LAssembler.Op(OP_ARG, 16);
  LAssembler.SystemCall(200);
  LAssembler.Op(OP_LEAVE, REENTER_FRAME);
  LAssembler.Mark(LDone);
  Argument(LAssembler, REENTER_FRAME, 2);
  LAssembler.Op(OP_LEAVE, REENTER_FRAME);
  LScenario := NewScenario('sys.reenter', LAssembler);
  LScenario.AddCall([0, 3, 4]);
  LScenario.AddCall([1, 3, 4]);
  LScenario.AddCall([2, 3, 4]);
  LScenario.AddCall([3, 0, 9]);
  LScenario.AddCall([3, 5, 0]);
  LScenario.AddCall([3, 30, 1]);
  LScenario.Add('mem');
  LScenario.Add('info');
  AList := AList + [LScenario];
end;

class procedure TQvmPrograms.AddComposedScenarios(var AList: TArray<TQvmScenario>);
const
  FRAME = 32;
  TOTAL = 8;
  INDEX = 12;
  OTHER = 16;
  SWAP = 20;
  TABLE_WORDS = 48;
var
  LScenario: TQvmScenario;
  LAssembler: TQvmAssembler;
  LLoop, LInner, LNoSwap, LNext, LDone, LTable, LIndex, LStruct: Integer;
  LMap: AnsiString;
begin
  LScenario := Default(TQvmScenario);
  LScenario.Name := 'comp.sieve';
  LScenario.Image := Sieve(QVM_TEST_IMAGE);
  for LIndex in SIEVE_LIMITS do
    LScenario.AddCall([0, LIndex]);
  LScenario.Add('mem');
  LScenario.Add('restart');
  LScenario.Add('mem');
  LScenario.AddCall([0, 2000]);
  LScenario.Add('mem');
  AList := AList + [LScenario];

  // bubble sort of a table of words (signed), then a checksum with shifts: total = (total << 5) ^
  // (total >>u 27) ^ word, and the first word is returned added to it
  LAssembler := TQvmAssembler.Create;
  LTable := LAssembler.DataLength;
  for LIndex := 0 to TABLE_WORDS - 1 do
    LAssembler.Data([Integer(Next * 2654435761)]);
  LNoSwap := LAssembler.NewLabel;
  LNext := LAssembler.NewLabel;
  LDone := LAssembler.NewLabel;
  LAssembler.Op(OP_ENTER, FRAME);
  // for index = 0 .. words - 2
  LAssembler.Op(OP_LOCAL, INDEX);
  LAssembler.Op(OP_CONST, 0);
  LAssembler.Op(OP_STORE4);
  LLoop := LAssembler.MarkNew;
  LAssembler.LoadLocal(INDEX);
  LAssembler.Op(OP_CONST, TABLE_WORDS - 1);
  LAssembler.Branch(OP_GEI, LDone);
  // for other = 0 .. words - 2 - index
  LAssembler.Op(OP_LOCAL, OTHER);
  LAssembler.Op(OP_CONST, 0);
  LAssembler.Op(OP_STORE4);
  LInner := LAssembler.MarkNew;
  LAssembler.LoadLocal(OTHER);
  LAssembler.Op(OP_CONST, TABLE_WORDS - 1);
  LAssembler.LoadLocal(INDEX);
  LAssembler.Op(OP_SUB);
  LAssembler.Branch(OP_GEI, LNext);
  // if table[other] <= table[other + 1] no swap
  LAssembler.LoadLocal(OTHER);
  LAssembler.Op(OP_CONST, 4);
  LAssembler.Op(OP_MULI);
  LAssembler.Op(OP_CONST, LTable);
  LAssembler.Op(OP_ADD);
  LAssembler.Op(OP_LOAD4);
  LAssembler.LoadLocal(OTHER);
  LAssembler.Op(OP_CONST, 2);
  LAssembler.Op(OP_LSH);
  LAssembler.Op(OP_CONST, LTable + 4);
  LAssembler.Op(OP_ADD);
  LAssembler.Op(OP_LOAD4);
  LAssembler.Branch(OP_LEI, LNoSwap);
  // swap = table[other]; table[other] = table[other + 1]; table[other + 1] = swap
  LAssembler.Op(OP_LOCAL, SWAP);
  LAssembler.LoadLocal(OTHER);
  LAssembler.Op(OP_CONST, 2);
  LAssembler.Op(OP_LSH);
  LAssembler.Op(OP_CONST, LTable);
  LAssembler.Op(OP_ADD);
  LAssembler.Op(OP_LOAD4);
  LAssembler.Op(OP_STORE4);
  LAssembler.LoadLocal(OTHER);
  LAssembler.Op(OP_CONST, 2);
  LAssembler.Op(OP_LSH);
  LAssembler.Op(OP_CONST, LTable);
  LAssembler.Op(OP_ADD);
  LAssembler.LoadLocal(OTHER);
  LAssembler.Op(OP_CONST, 2);
  LAssembler.Op(OP_LSH);
  LAssembler.Op(OP_CONST, LTable + 4);
  LAssembler.Op(OP_ADD);
  LAssembler.Op(OP_LOAD4);
  LAssembler.Op(OP_STORE4);
  LAssembler.LoadLocal(OTHER);
  LAssembler.Op(OP_CONST, 2);
  LAssembler.Op(OP_LSH);
  LAssembler.Op(OP_CONST, LTable + 4);
  LAssembler.Op(OP_ADD);
  LAssembler.LoadLocal(SWAP);
  LAssembler.Op(OP_STORE4);
  LAssembler.Mark(LNoSwap);
  LAssembler.Op(OP_LOCAL, OTHER);
  LAssembler.LoadLocal(OTHER);
  LAssembler.Op(OP_CONST, 1);
  LAssembler.Op(OP_ADD);
  LAssembler.Op(OP_STORE4);
  LAssembler.Jump(LInner);
  LAssembler.Mark(LNext);
  LAssembler.Op(OP_LOCAL, INDEX);
  LAssembler.LoadLocal(INDEX);
  LAssembler.Op(OP_CONST, 1);
  LAssembler.Op(OP_ADD);
  LAssembler.Op(OP_STORE4);
  LAssembler.Jump(LLoop);
  LAssembler.Mark(LDone);
  // the checksum
  LAssembler.Op(OP_LOCAL, TOTAL);
  Argument(LAssembler, FRAME, 1);
  LAssembler.Op(OP_STORE4);
  LAssembler.Op(OP_LOCAL, INDEX);
  LAssembler.Op(OP_CONST, 0);
  LAssembler.Op(OP_STORE4);
  LLoop := LAssembler.MarkNew;
  LDone := LAssembler.NewLabel;
  LAssembler.LoadLocal(INDEX);
  LAssembler.Op(OP_CONST, TABLE_WORDS);
  LAssembler.Branch(OP_GEU, LDone);
  LAssembler.Op(OP_LOCAL, TOTAL);
  LAssembler.LoadLocal(TOTAL);
  LAssembler.Op(OP_CONST, 5);
  LAssembler.Op(OP_LSH);
  LAssembler.LoadLocal(TOTAL);
  LAssembler.Op(OP_CONST, 27);
  LAssembler.Op(OP_RSHU);
  LAssembler.Op(OP_BXOR);
  LAssembler.LoadLocal(INDEX);
  LAssembler.Op(OP_CONST, 2);
  LAssembler.Op(OP_LSH);
  LAssembler.Op(OP_CONST, LTable);
  LAssembler.Op(OP_ADD);
  LAssembler.Op(OP_LOAD4);
  LAssembler.Op(OP_BXOR);
  LAssembler.Op(OP_STORE4);
  LAssembler.Op(OP_LOCAL, INDEX);
  LAssembler.LoadLocal(INDEX);
  LAssembler.Op(OP_CONST, 1);
  LAssembler.Op(OP_ADD);
  LAssembler.Op(OP_STORE4);
  LAssembler.Jump(LLoop);
  LAssembler.Mark(LDone);
  LAssembler.LoadLocal(TOTAL);
  LAssembler.Op(OP_CONST, LTable);
  LAssembler.Op(OP_LOAD4);
  LAssembler.Op(OP_ADD);
  LAssembler.Op(OP_LEAVE, FRAME);
  LScenario := NewScenario('comp.sort', LAssembler);
  LScenario.AddCall([0, 0]);
  LScenario.Add('mem');
  LScenario.AddCall([0, 12345]);
  LScenario.Add('restart');
  LScenario.Add('mem');
  AList := AList + [LScenario];

  // floats: total = sum of 1 / i for i = n .. 1, then total * total - 0.5, returned as bits
  LAssembler := TQvmAssembler.Create;
  LDone := LAssembler.NewLabel;
  LAssembler.Op(OP_ENTER, FRAME);
  LAssembler.Op(OP_LOCAL, TOTAL);
  LAssembler.ConstFloat(0);
  LAssembler.Op(OP_STORE4);
  LAssembler.Op(OP_LOCAL, INDEX);
  Argument(LAssembler, FRAME, 1);
  LAssembler.Op(OP_STORE4);
  LLoop := LAssembler.MarkNew;
  LAssembler.LoadLocal(INDEX);
  LAssembler.Op(OP_CONST, 0);
  LAssembler.Branch(OP_LEI, LDone);
  LAssembler.Op(OP_LOCAL, TOTAL);
  LAssembler.LoadLocal(TOTAL);
  LAssembler.ConstFloat(1);
  LAssembler.LoadLocal(INDEX);
  LAssembler.Op(OP_CVIF);
  LAssembler.Op(OP_DIVF);
  LAssembler.Op(OP_ADDF);
  LAssembler.Op(OP_STORE4);
  LAssembler.Op(OP_LOCAL, INDEX);
  LAssembler.LoadLocal(INDEX);
  LAssembler.Op(OP_CONST, 1);
  LAssembler.Op(OP_SUB);
  LAssembler.Op(OP_STORE4);
  LAssembler.Jump(LLoop);
  LAssembler.Mark(LDone);
  LAssembler.LoadLocal(TOTAL);
  LAssembler.LoadLocal(TOTAL);
  LAssembler.Op(OP_MULF);
  LAssembler.ConstFloat(0.5);
  LAssembler.Op(OP_SUBF);
  LAssembler.Op(OP_LEAVE, FRAME);
  LScenario := NewScenario('comp.harmonic', LAssembler);
  for LIndex in HARMONIC_TERMS do
    LScenario.AddCall([0, LIndex]);
  LScenario.Add('mem');
  AList := AList + [LScenario];

  // a structure of 24 bytes copied to a local and back with OP_BLOCK_COPY, a field changed on the way,
  // with the literal segment after the data and the symbols of a .map
  LAssembler := TQvmAssembler.Create;
  LStruct := LAssembler.Data([1, 2, 3, 4, 5, 6]);
  LAssembler.Data([0, 0, 0, 0, 0, 0]);
  LAssembler.Lit('literal' + #0 + 'text' + #0);
  LNext := LAssembler.NewLabel;
  LAssembler.Op(OP_ENTER, 48);
  LAssembler.Op(OP_LOCAL, 16);
  LAssembler.Op(OP_CONST, LStruct);
  LAssembler.Op(OP_BLOCK_COPY, 24);
  LAssembler.Op(OP_LOCAL, 16 + 8);
  Argument(LAssembler, 48, 1);
  LAssembler.Op(OP_STORE4);
  LAssembler.Op(OP_LOCAL, 16);
  LAssembler.Op(OP_ARG, 8);
  LAssembler.CallLabel(LNext);
  LAssembler.Op(OP_LEAVE, 48);
  // copyBack( pointer ): the structure goes to the second place; returns the byte of the literal at arg
  LAssembler.Mark(LNext);
  LTable := LAssembler.Here;
  LAssembler.Op(OP_ENTER, 16);
  LAssembler.Op(OP_CONST, LStruct + 24);
  LAssembler.LoadLocal(16 + 8);
  LAssembler.Op(OP_BLOCK_COPY, 24);
  LAssembler.Op(OP_CONST, LStruct + 48 + 2);
  LAssembler.Op(OP_LOAD1);
  LAssembler.Op(OP_SEX8);
  LAssembler.Op(OP_LEAVE, 16);
  LMap := '0 0 vmMain' + #13#10 + '0 ' + AnsiString(IntToHex(LTable, 1)) + ' copyBack' + #13#10 +
    '1 0 data' + #13#10 + '// a comment' + #13#10 + '0 fff beyond' + #13#10 + '2 30 lit' + #13#10 + '0 9';
  LScenario := NewScenario('comp.struct', LAssembler);
  LScenario.MapText := LMap;
  LScenario.AddCall([0, 99]);
  LScenario.Add('mem');
  LScenario.Add('info');
  LScenario.Add('symbols');
  LScenario.Add('symval vmMain');
  LScenario.Add('symval copyBack');
  LScenario.Add('symval beyond');
  LScenario.Add('symval nothing');
  AList := AList + [LScenario];
end;

class procedure TQvmPrograms.AddRandomScenarios(var AList: TArray<TQvmScenario>);
const
  BINARY_OPS: array[0..13] of Integer = (OP_ADD, OP_SUB, OP_MULI, OP_MULU, OP_BAND, OP_BOR, OP_BXOR, OP_LSH,
    OP_RSHI, OP_RSHU, OP_ADDF, OP_SUBF, OP_MULF, OP_DIVF);
  UNARY_OPS: array[0..5] of Integer = (OP_NEGI, OP_SEX8, OP_SEX16, OP_CVIF, OP_CVFI, OP_NEGF);
  BRANCH_OPS: array[0..15] of Integer = (OP_EQ, OP_NE, OP_LTI, OP_LEI, OP_GTI, OP_GEI, OP_LTU, OP_LEU, OP_GTU,
    OP_GEU, OP_EQF, OP_NEF, OP_LTF, OP_LEF, OP_GTF, OP_GEF);
var
  LScenario: TQvmScenario;
  LAssembler: TQvmAssembler;
  LProgram, LStep, LDepth, LChoice, LSkip: Integer;
  LValue: Cardinal;
begin
  for LProgram := 0 to 59 do
  begin
    LAssembler := TQvmAssembler.Create;
    LAssembler.Op(OP_ENTER, QVM_TEST_FRAME);
    Argument(LAssembler, QVM_TEST_FRAME, 1);
    LDepth := 1;
    for LStep := 1 to 120 do
    begin
      LChoice := Integer(Next mod 10);
      if (LChoice < 3) or (LDepth < 3) then
      begin
        // a constant: an interesting value, an argument or anything
        LValue := Next;
        case LValue mod 4 of
          0:
            LAssembler.Op(OP_CONST, INTEGER_VALUES[(LValue shr 2) mod Cardinal(Length(INTEGER_VALUES))]);
          1:
            LAssembler.Op(OP_CONST, Integer(FLOAT_VALUES[(LValue shr 2) mod Cardinal(Length(FLOAT_VALUES))]));
          2:
            Argument(LAssembler, QVM_TEST_FRAME, 1 + Integer((LValue shr 2) mod 3));
        else
          LAssembler.Op(OP_CONST, Integer(LValue * 2654435761));
        end;
        Inc(LDepth);
      end
      else if LChoice < 7 then
      begin
        LValue := Next;
        LAssembler.Op(BINARY_OPS[LValue mod Cardinal(Length(BINARY_OPS))]);
        Dec(LDepth);
      end
      else if LChoice < 9 then
      begin
        LValue := Next;
        LAssembler.Op(UNARY_OPS[LValue mod Cardinal(Length(UNARY_OPS))]);
      end
      else if LDepth >= 4 then
      begin
        // a branch over a change of the value that is left on top
        LValue := Next;
        LSkip := LAssembler.NewLabel;
        LAssembler.Branch(BRANCH_OPS[LValue mod Cardinal(Length(BRANCH_OPS))], LSkip);
        Dec(LDepth, 2);
        LAssembler.Op(OP_CONST, Integer(LValue));
        LAssembler.Op(OP_BXOR);
        LAssembler.Mark(LSkip);
      end;
    end;
    while LDepth > 1 do
    begin
      LAssembler.Op(OP_BXOR);
      Dec(LDepth);
    end;
    LAssembler.Op(OP_LEAVE, QVM_TEST_FRAME);
    LScenario := NewScenario('random.' + IntToStr(LProgram), LAssembler);
    LScenario.AddCall([0, 0, 0, 0]);
    LScenario.AddCall([0, 1, 2, 3]);
    LValue := Next;
    LScenario.AddCall([0, Integer(LValue * 2654435761), Integer(LValue * 40503), Integer(LValue)]);
    LScenario.AddCall([0, $3F800000, $40490FDB, Integer($C2F6E979)]);
    AList := AList + [LScenario];
  end;
end;

class function TQvmPrograms.All: TArray<TQvmScenario>;
var
  LIndex: Integer;
begin
  Result := nil;
  FSeed := 120;
  AddIntegerScenarios(Result);
  AddFloatScenarios(Result);
  AddMemoryScenarios(Result);
  AddCallScenarios(Result);
  AddSystemCallScenarios(Result);
  AddComposedScenarios(Result);
  AddRandomScenarios(Result);
  // the golden file is good only for these very images
  for LIndex := 0 to High(Result) do
    Result[LIndex].Commands := ['note image ' + TQvmScenarioRunner.Hex64(TTestFnv.Hash64(Result[LIndex].Image))] +
      Result[LIndex].Commands;
end;

end.
