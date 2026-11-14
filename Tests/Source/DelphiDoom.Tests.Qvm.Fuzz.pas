{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the QVM library - fuzzing with a fixed seed: no file   }
{  and no program may take the machine outside its memory                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Qvm.Fuzz;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf;

type
  /// <summary>How the attempts of a test ended</summary>
  TQvmFuzzTally = record
    Refused: Integer;
    Returned: Integer;
    Faulted: Integer;
    Limited: Integer;
    HostErrors: Integer;
    Instructions: Int64;
    function Total: Integer;
    function Text: string;
  end;

  /// <summary>
  ///   A .qvm is input that is not trusted. Files of random bytes, good files cut short or with bytes
  ///   changed, and programs of random instructions (seed fixed: the same every run) are loaded and, when
  ///   they load, run with a limit of instructions, a small limit of memory and the fake host. The only
  ///   outcomes allowed are a value, an EQvmException or the error the host raises: an access violation,
  ///   a range error or any other exception fails the test, and so does a byte written after the data
  ///   image.
  ///   QVM_FUZZ_DIVISOR=n runs one attempt in n (the same ones every time) and does not look at how many
  ///   ended in which way: for the coverage tool, a debugger that takes a long time for every exception
  /// </summary>
  [TestFixture]
  [Category('Qvm')]
  TTestQvmFuzz = class
  strict private
    FSeed: Cardinal;
    FTally: TQvmFuzzTally;
    FDivisor: Integer;
    function Scaled(ACount: Integer): Integer;
    procedure Check(ACondition: Boolean);
    function Next: Cardinal;
    function Pick(ACount: Integer): Integer;
    function Interesting: Integer;
    function RandomProgram(ATracked: Boolean): TBytes;
    procedure Attempt(const AFile: TBytes; ACalls: Integer);
    procedure Report(const ATitle: string);
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure ByteCasualiNonDovrebberoMaiFarCadereIlCaricamento;
    [Test]
    procedure UnFileTroncatoInOgniPuntoDovrebbeEssereRifiutatoOEseguitoSenzaDanni;
    [Test]
    procedure UnFileConByteAlteratiDovrebbeEssereRifiutatoOEseguitoSenzaDanni;
    [Test]
    procedure UnIntestazioneAlterataNonDovrebbeFarAllocareOltreIlLimite;
    [Test]
    procedure IstruzioniCasualiNonDovrebberoMaiUscireDallaMemoria;
    [Test]
    procedure ProgrammiCasualiBenFormatiNonDovrebberoMaiUscireDallaMemoria;
  end;

implementation

uses
  DelphiDoom.Qvm.Opcodes, DelphiDoom.Qvm.Factory, DelphiDoom.Tests.Qvm.Assembler, DelphiDoom.Tests.Qvm.Support,
  DelphiDoom.Tests.Qvm.Programs;

const
  FUZZ_IMAGE = 4096;
  INSTRUCTION_LIMIT = 4000;
  DATA_LIMIT = 1 shl 16;
  DIVISOR_VARIABLE = 'QVM_FUZZ_DIVISOR';

{ TQvmFuzzTally }

function TQvmFuzzTally.Total: Integer;
begin
  Result := Refused + Returned + Faulted + Limited + HostErrors;
end;

function TQvmFuzzTally.Text: string;
begin
  Result := Format('%d tentativi: %d rifiutati al caricamento, %d arrivati in fondo, %d fermati da un controllo, ' +
    '%d dal limite di istruzioni, %d dall''host; %d istruzioni eseguite',
    [Total, Refused, Returned, Faulted, Limited, HostErrors, Instructions]);
end;

{ TTestQvmFuzz }

procedure TTestQvmFuzz.Setup;
begin
  FSeed := 2463534242;
  FTally := Default(TQvmFuzzTally);
  FDivisor := StrToIntDef(GetEnvironmentVariable(DIVISOR_VARIABLE), 1);
  if FDivisor < 1 then
    FDivisor := 1;
end;

function TTestQvmFuzz.Scaled(ACount: Integer): Integer;
begin
  Result := ACount div FDivisor;
end;

procedure TTestQvmFuzz.Check(ACondition: Boolean);
begin
  // the numbers are the ones of the whole run
  if FDivisor = 1 then
    Assert.IsTrue(ACondition, FTally.Text);
end;

function TTestQvmFuzz.Next: Cardinal;
begin
  FSeed := FSeed xor (FSeed shl 13);
  FSeed := FSeed xor (FSeed shr 17);
  FSeed := FSeed xor (FSeed shl 5);
  Result := FSeed;
end;

function TTestQvmFuzz.Pick(ACount: Integer): Integer;
begin
  Result := Integer(Next mod Cardinal(ACount));
end;

function TTestQvmFuzz.Interesting: Integer;
const
  VALUES: array[0..23] of Integer = (0, 1, -1, 2, 3, 4, 7, 8, 16, 31, 32, 48, 255, 256, FUZZ_IMAGE - 4,
    FUZZ_IMAGE - 1, FUZZ_IMAGE, FUZZ_IMAGE + 4, -FUZZ_IMAGE, High(Integer), Low(Integer), $3F800000, $7FC00000,
    Integer($FF800000));
begin
  case Pick(4) of
    0:
      Result := VALUES[Pick(Length(VALUES))];
    1:
      begin
        // an address somewhere in the image, mostly aligned (one draw for each statement: the order in
        // which an expression is evaluated is not the same at 32 and at 64 bit)
        Result := Pick(FUZZ_IMAGE);
        Result := Result and not Pick(4);
      end;
    2:
      Result := Pick(64) - 16;
  else
    Result := Integer(Next);
  end;
end;

procedure TTestQvmFuzz.Attempt(const AFile: TBytes; ACalls: Integer);
var
  LLimits: TQvmLimits;
  LHost: IQvmHost;
  LMachine: IQvmMachine;
  LMemory: IQvmMemory;
  LIndex, LFirst, LSecond, LCommand, LGuard: Integer;
  LBefore: Int64;
begin
  LLimits := TQvmLimits.Default;
  LLimits.MaxDataSize := DATA_LIMIT;
  LLimits.InstructionLimit := INSTRUCTION_LIMIT;
  LLimits.MaxCallDepth := 8;
  // the host of the test programs, without its lines
  LHost := TQvmFakeHost.Create(TQvmHostProfile.Test, nil);
  try
    LMachine := TQvmFactory.CreateMachine('fuzz', AFile, LHost, LLimits);
  except
    on E: EQvmFormatException do
    begin
      Inc(FTally.Refused);
      Exit;
    end;
  end;
  LMemory := LMachine.Memory;
  Assert.IsTrue(LMemory.Size <= DATA_LIMIT);
  for LIndex := 1 to ACalls do
  begin
    LFirst := Interesting;
    LSecond := Interesting;
    LBefore := LMachine.InstructionsExecuted;
    LCommand := Pick(4);
    try
      LMachine.Call(LCommand, [LFirst, LSecond]);
      Inc(FTally.Returned);
    except
      on E: EQvmInstructionLimitException do
        Inc(FTally.Limited);
      on E: EQvmException do
        Inc(FTally.Faulted);
      on E: EQvmFakeHostError do
        Inc(FTally.HostErrors);
    end;
    Inc(FTally.Instructions, LMachine.InstructionsExecuted - LBefore);
    // whatever happened: the machine is not half way, the limit held, nothing was written after the image
    if LMachine.CallDepth <> 0 then
      Assert.Fail('la macchina e'' rimasta dentro una chiamata');
    if LMachine.ProgramStack <> LMemory.Size then
      Assert.Fail('lo stack del programma non e'' tornato in cima');
    if LMachine.InstructionsExecuted - LBefore > INSTRUCTION_LIMIT then
      Assert.Fail('il limite di istruzioni e'' stato superato');
    if LMemory.Size >= 64 then
      for LGuard := 0 to QVM_DATA_PADDING div 4 - 1 do
        if PInteger(PByte(LMemory.Range(0, LMemory.Size)) + LMemory.Size + 4 * LGuard)^ <> 0 then
          Assert.Fail('un byte e'' stato scritto dopo la memoria della macchina');
  end;
end;

procedure TTestQvmFuzz.Report(const ATitle: string);
begin
  TQvmScenarioRunner.Report(ATitle + ': ' + FTally.Text);
end;

function TTestQvmFuzz.RandomProgram(ATracked: Boolean): TBytes;
var
  LAssembler: TQvmAssembler;
  LCount, LIndex, LOpcode, LDepth, LNeeded, LFrame, LOperand: Integer;
  LLabels: TArray<Integer>;
begin
  LAssembler := TQvmAssembler.Create;
  try
    LCount := 4 + Pick(60);
    SetLength(LLabels, LCount);
    for LIndex := 0 to LCount - 1 do
      LLabels[LIndex] := LAssembler.NewLabel;
    for LIndex := 0 to 15 do
      LAssembler.Data([Interesting]);
    LFrame := 8 * (1 + Pick(6));
    LAssembler.Op(OP_ENTER, LFrame);
    LDepth := 0;
    for LIndex := 0 to LCount - 1 do
    begin
      LAssembler.Mark(LLabels[LIndex]);
      LOpcode := Pick(OP_LAST + 1);
      if ATracked then
      begin
        // an instruction that has its operands on the stack; frames are left to the last instruction
        case LOpcode of
          OP_STORE1, OP_STORE2, OP_STORE4, OP_BLOCK_COPY, OP_EQ..OP_GEF:
            LNeeded := 2;
          OP_ADD..OP_BXOR, OP_LSH..OP_RSHU, OP_ADDF..OP_MULF, OP_BCOM:
            LNeeded := 2;
          OP_POP, OP_ARG, OP_JUMP, OP_CALL, OP_LOAD1..OP_LOAD4, OP_SEX8..OP_NEGI, OP_NEGF, OP_CVIF, OP_CVFI:
            LNeeded := 1;
        else
          LNeeded := 0;
        end;
        if (LDepth < LNeeded) or (LOpcode = OP_ENTER) or (LOpcode = OP_LEAVE) or (LDepth > 200) then
          LOpcode := OP_CONST;
        case LOpcode of
          OP_STORE1, OP_STORE2, OP_STORE4, OP_BLOCK_COPY, OP_EQ..OP_GEF:
            Dec(LDepth, 2);
          OP_ADD..OP_BAND, OP_BOR, OP_BXOR, OP_LSH..OP_RSHU, OP_ADDF..OP_MULF, OP_POP, OP_ARG, OP_JUMP:
            Dec(LDepth);
          OP_CONST, OP_LOCAL, OP_PUSH:
            Inc(LDepth);
        end;
      end;
      if TQvmOpcodes.IsBranch(LOpcode) then
      begin
        // now and then a target that does not exist: the file is refused
        if Pick(40) = 0 then
          LAssembler.Op(LOpcode, Interesting)
        else
          LAssembler.Branch(LOpcode, LLabels[Pick(LCount)]);
      end
      else if (LOpcode = OP_CONST) and (Pick(3) = 0) then
        // the number of an instruction, for a jump or a call, or of a system call of the host
        if Pick(3) = 0 then
        begin
          LOperand := 100 + Pick(4);
          LOperand := LOperand + 100 * Pick(2);
          LAssembler.Op(OP_CONST, -1 - LOperand);
        end
        else
          LAssembler.ConstLabel(LLabels[Pick(LCount)])
      else if LOpcode = OP_ARG then
      begin
        LOperand := 8 + 4 * Pick(8);
        if Pick(2) = 0 then
          LOperand := LOperand + Pick(256);
        LAssembler.Op(OP_ARG, LOperand);
      end
      else if (LOpcode = OP_ENTER) or (LOpcode = OP_LEAVE) then
      begin
        LOperand := 8 * Pick(8);
        if Pick(2) = 0 then
          LOperand := LOperand + Interesting;
        LAssembler.Op(LOpcode, LOperand);
      end
      else if TQvmOpcodes.OperandSize(LOpcode) = 4 then
        LAssembler.Op(LOpcode, Interesting)
      else
        LAssembler.Op(LOpcode);
    end;
    if ATracked then
    begin
      if LDepth < 1 then
        LAssembler.Op(OP_CONST, 0);
      while LDepth > 1 do
      begin
        LAssembler.Op(OP_BXOR);
        Dec(LDepth);
      end;
    end;
    LAssembler.Op(OP_LEAVE, LFrame);
    LAssembler.ImageSize(FUZZ_IMAGE);
    Result := LAssembler.ToBytes(Pick(8) = 0);
  finally
    LAssembler.Free;
  end;
end;

procedure TTestQvmFuzz.ByteCasualiNonDovrebberoMaiFarCadereIlCaricamento;
var
  LIndex, LByte: Integer;
  LFile: TBytes;
  LMagic: Integer;
begin
  for LIndex := 1 to Scaled(20000) do
  begin
    SetLength(LFile, Pick(160));
    for LByte := 0 to High(LFile) do
      LFile[LByte] := Byte(Next);
    // half of them with the magic number, to get past the first test
    if (Length(LFile) >= 4) and (Pick(2) = 0) then
    begin
      LMagic := QVM_MAGIC + Pick(2);
      Move(LMagic, LFile[0], 4);
    end;
    Attempt(LFile, 1);
  end;
  Report('byte casuali');
  Check(FTally.Total = 20000);
  Check(FTally.Refused > 19000);
end;

procedure TTestQvmFuzz.UnFileTroncatoInOgniPuntoDovrebbeEssereRifiutatoOEseguitoSenzaDanni;
var
  LScenario: TQvmScenario;
  LLength, LFiles: Integer;
begin
  LFiles := 0;
  for LScenario in TQvmPrograms.All do
  begin
    // one program in seven, every length
    Inc(LFiles);
    if LFiles mod 7 <> 0 then
      Continue;
    for LLength := 0 to Scaled(Length(LScenario.Image)) - 1 do
      Attempt(Copy(LScenario.Image, 0, LLength), 1);
  end;
  Report('file troncati');
  // a file without its last bytes has a segment outside: it never loads
  Assert.AreEqual(FTally.Total, FTally.Refused);
  Check(FTally.Total > 6000);
end;

procedure TTestQvmFuzz.UnFileConByteAlteratiDovrebbeEssereRifiutatoOEseguitoSenzaDanni;
var
  LScenarios: TArray<TQvmScenario>;
  LFile: TBytes;
  LIndex, LChange, LKind, LWhere: Integer;
begin
  LScenarios := TQvmPrograms.All;
  for LIndex := 1 to Scaled(30000) do
  begin
    LFile := Copy(LScenarios[Pick(Length(LScenarios))].Image);
    for LChange := 0 to Pick(4) do
    begin
      LKind := Pick(3);
      case LKind of
        0:
          begin
            LWhere := Pick(Length(LFile));
            LFile[LWhere] := Byte(Next);
          end;
        1:
          begin
            // in the header
            LWhere := Pick(SizeOf(TQvmHeader));
            LFile[LWhere] := Byte(Interesting);
          end;
      else
        // in the code, which follows the header: an instruction or the byte of an operand
        LWhere := SizeOf(TQvmHeader) + Pick(64) mod (Length(LFile) - SizeOf(TQvmHeader));
        LFile[LWhere] := Byte(Pick(OP_LAST + 4));
      end;
    end;
    Attempt(LFile, 2);
  end;
  Report('byte alterati');
  Check(FTally.Refused > 20000);
  Check(FTally.Returned > 7000);
  Check(FTally.Faulted > 5000);
end;

procedure TTestQvmFuzz.UnIntestazioneAlterataNonDovrebbeFarAllocareOltreIlLimite;
var
  LFile: TBytes;
  LIndex, LField, LValue: Integer;
begin
  for LIndex := 1 to Scaled(20000) do
  begin
    LFile := TQvmPrograms.Binary(OP_ADD);
    // one or two fields of the header (not the magic) take any value
    LField := 1 + Pick(7);
    LValue := Interesting;
    Move(LValue, LFile[4 * LField], 4);
    if Pick(2) = 0 then
    begin
      LField := 1 + Pick(7);
      LValue := Integer(Next);
      Move(LValue, LFile[4 * LField], 4);
    end;
    Attempt(LFile, 1);
  end;
  Report('intestazioni alterate');
  Check(FTally.Refused > 15000);
  Check(FTally.Returned > 1000);
end;

procedure TTestQvmFuzz.IstruzioniCasualiNonDovrebberoMaiUscireDallaMemoria;
var
  LIndex: Integer;
begin
  for LIndex := 1 to Scaled(30000) do
    Attempt(RandomProgram(False), 2);
  Report('istruzioni casuali');
  Check(FTally.Faulted > 45000);
  Check(FTally.Instructions > 300000);
end;

procedure TTestQvmFuzz.ProgrammiCasualiBenFormatiNonDovrebberoMaiUscireDallaMemoria;
var
  LIndex: Integer;
begin
  for LIndex := 1 to Scaled(30000) do
    Attempt(RandomProgram(True), 3);
  Report('programmi ben formati');
  // these get far: every kind of ending is met
  Check(FTally.Returned > 10000);
  Check(FTally.Faulted > 50000);
  Check(FTally.Limited > 3000);
  Check(FTally.HostErrors > 100);
  Check(FTally.Instructions > 20000000);
end;

end.
