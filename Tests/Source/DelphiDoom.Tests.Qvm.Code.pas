{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the QVM library - the code prepared for the            }
{  interpreter, and the table of the instructions                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Qvm.Code;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Code;

type
  [TestFixture]
  [Category('Qvm')]
  TTestQvmCode = class
  strict private
    procedure ExpectBad(const ACode: TBytes; ACount: Integer; const AText: string);
  public
    [Test]
    procedure OgniIstruzioneDovrebbeStareAllOffsetDelSuoByte;
    [Test]
    procedure LOperandoDovrebbeStareNelloSlotDopoLIstruzione;
    [Test]
    procedure IlBersaglioDiUnSaltoCondizionatoDovrebbeDiventareUnOffset;
    [Test]
    procedure DopoLUltimaIstruzioneDovrebberoEsserciSentinelle;
    [Test]
    procedure DovrebbeDireDoveCominciaUnIstruzione;
    [Test]
    procedure DovrebbeRifiutareUnByteCheNonEUnIstruzione;
    [Test]
    procedure DovrebbeRifiutareUnOperandoTroncatoDallaFineDelCodice;
    [Test]
    procedure DovrebbeRifiutarePiuIstruzioniDiQuanteNeContieneIlCodice;
    [Test]
    [TestCase('oltre l ultima', '3')]
    [TestCase('negativo', '-1')]
    [TestCase('enorme', '2147483647')]
    procedure DovrebbeRifiutareUnSaltoVersoUnIstruzioneCheNonEsiste(ATarget: Integer);
    [Test]
    procedure UnaCostanteQualsiasiNonEUnBersaglioENonSiControlla;
  end;

  [TestFixture]
  [Category('Qvm')]
  TTestQvmOpcodes = class
  public
    [Test]
    procedure IlNumeroDelleIstruzioniDovrebbeEssereQuelloDellOriginale;
    [Test]
    procedure SoloLeIstruzioniConOperandoDovrebberoOccuparePiuDiUnByte;
    [Test]
    procedure ISaltiCondizionatiDovrebberoEssereSedici;
    [Test]
    procedure OgniIstruzioneDovrebbeAvereIlSuoNome;
  end;

implementation

uses
  DelphiDoom.Qvm.Opcodes;

{ TTestQvmCode }

procedure TTestQvmCode.ExpectBad(const ACode: TBytes; ACount: Integer; const AText: string);
var
  LCode: TQvmCode;
begin
  try
    LCode := TQvmCode.Create(ACode, ACount, 'prova');
    LCode.Free;
    Assert.Fail('il codice e'' stato accettato');
  except
    on E: EQvmFormatException do
      Assert.Contains(E.Message, AText);
  end;
end;

procedure TTestQvmCode.OgniIstruzioneDovrebbeStareAllOffsetDelSuoByte;
var
  LCode: TQvmCode;
begin
  // ENTER 16 | PUSH | ARG 8 | LEAVE 16
  LCode := TQvmCode.Create([OP_ENTER, 16, 0, 0, 0, OP_PUSH, OP_ARG, 8, OP_LEAVE, 16, 0, 0, 0], 4, 'prova');
  try
    Assert.AreEqual(13, LCode.CodeLength);
    Assert.AreEqual(4, LCode.InstructionCount);
    Assert.AreEqual(0, LCode.InstructionPointers[0]);
    Assert.AreEqual(5, LCode.InstructionPointers[1]);
    Assert.AreEqual(6, LCode.InstructionPointers[2]);
    Assert.AreEqual(8, LCode.InstructionPointers[3]);
    Assert.AreEqual(OP_ENTER, LCode.Image[0]);
    Assert.AreEqual(OP_PUSH, LCode.Image[5]);
    Assert.AreEqual(OP_ARG, LCode.Image[6]);
    Assert.AreEqual(OP_LEAVE, LCode.Image[8]);
  finally
    LCode.Free;
  end;
end;

procedure TTestQvmCode.LOperandoDovrebbeStareNelloSlotDopoLIstruzione;
var
  LCode: TQvmCode;
begin
  // CONST $89ABCDEF (little endian) | ARG 200
  LCode := TQvmCode.Create([OP_CONST, $EF, $CD, $AB, $89, OP_ARG, 200], 2, 'prova');
  try
    Assert.AreEqual(Integer($89ABCDEF), LCode.Image[1]);
    // the byte of OP_ARG is not sign extended
    Assert.AreEqual(200, LCode.Image[6]);
    // the other slots of a four byte operand stay empty
    Assert.AreEqual(0, LCode.Image[2]);
  finally
    LCode.Free;
  end;
end;

procedure TTestQvmCode.IlBersaglioDiUnSaltoCondizionatoDovrebbeDiventareUnOffset;
var
  LCode: TQvmCode;
begin
  // 0: PUSH | 1: EQ -> 3 | 2: CONST 2 | 3: LEAVE 0 ; the instruction 3 is at the offset 11
  LCode := TQvmCode.Create([OP_PUSH, OP_EQ, 3, 0, 0, 0, OP_CONST, 2, 0, 0, 0, OP_LEAVE, 0, 0, 0, 0], 4, 'prova');
  try
    Assert.AreEqual(11, LCode.Image[2]);
    // the operand of OP_CONST is left alone
    Assert.AreEqual(2, LCode.Image[7]);
  finally
    LCode.Free;
  end;
end;

procedure TTestQvmCode.DopoLUltimaIstruzioneDovrebberoEsserciSentinelle;
var
  LCode: TQvmCode;
  LIndex: Integer;
begin
  // two instructions and two bytes of padding the original would run as OP_UNDEF
  LCode := TQvmCode.Create([OP_PUSH, OP_POP, 0, 0], 2, 'prova');
  try
    Assert.IsTrue(Length(LCode.Image) > LCode.CodeLength);
    for LIndex := 2 to High(LCode.Image) do
      Assert.AreEqual(QVM_CODE_SENTINEL, LCode.Image[LIndex]);
  finally
    LCode.Free;
  end;
end;

procedure TTestQvmCode.DovrebbeDireDoveCominciaUnIstruzione;
var
  LCode: TQvmCode;
begin
  LCode := TQvmCode.Create([OP_CONST, 1, 0, 0, 0, OP_POP, 0, 0], 2, 'prova');
  try
    Assert.IsTrue(LCode.IsInstructionStart(0));
    Assert.IsTrue(LCode.IsInstructionStart(5));
    // inside an operand, in the padding, outside
    Assert.IsFalse(LCode.IsInstructionStart(1));
    Assert.IsFalse(LCode.IsInstructionStart(4));
    Assert.IsFalse(LCode.IsInstructionStart(6));
    Assert.IsFalse(LCode.IsInstructionStart(8));
    Assert.IsFalse(LCode.IsInstructionStart(-1));
    Assert.IsFalse(LCode.IsInstructionStart(High(Integer)));
  finally
    LCode.Free;
  end;
end;

procedure TTestQvmCode.DovrebbeRifiutareUnByteCheNonEUnIstruzione;
begin
  ExpectBad([OP_PUSH, 60, OP_POP], 3, 'Bad VM instruction');
  ExpectBad([255], 1, 'Bad VM instruction');
end;

procedure TTestQvmCode.DovrebbeRifiutareUnOperandoTroncatoDallaFineDelCodice;
begin
  ExpectBad([OP_PUSH, OP_CONST, 1, 2, 3], 2, 'pc > header->codeLength');
  ExpectBad([OP_ARG], 1, 'pc > header->codeLength');
end;

procedure TTestQvmCode.DovrebbeRifiutarePiuIstruzioniDiQuanteNeContieneIlCodice;
begin
  ExpectBad([OP_PUSH, OP_CONST, 1, 2, 3, 4], 3, 'pc > header->codeLength');
end;

procedure TTestQvmCode.DovrebbeRifiutareUnSaltoVersoUnIstruzioneCheNonEsiste(ATarget: Integer);
begin
  ExpectBad([OP_PUSH, OP_LTF, Byte(ATarget), Byte(ATarget shr 8), Byte(ATarget shr 16), Byte(ATarget shr 24),
    OP_POP], 3, 'jumps to instruction');
end;

procedure TTestQvmCode.UnaCostanteQualsiasiNonEUnBersaglioENonSiControlla;
var
  LCode: TQvmCode;
begin
  LCode := TQvmCode.Create([OP_CONST, $FF, $FF, $FF, $7F, OP_LOCAL, $FF, $FF, $FF, $FF], 2, 'prova');
  try
    Assert.AreEqual(High(Integer), LCode.Image[1]);
    Assert.AreEqual(-1, LCode.Image[6]);
  finally
    LCode.Free;
  end;
end;

{ TTestQvmOpcodes }

procedure TTestQvmOpcodes.IlNumeroDelleIstruzioniDovrebbeEssereQuelloDellOriginale;
begin
  Assert.AreEqual(0, OP_UNDEF);
  Assert.AreEqual(10, OP_JUMP);
  Assert.AreEqual(26, OP_GEF);
  Assert.AreEqual(34, OP_BLOCK_COPY);
  Assert.AreEqual(49, OP_BCOM);
  Assert.AreEqual(59, OP_CVFI);
  Assert.AreEqual(OP_CVFI, OP_LAST);
end;

procedure TTestQvmOpcodes.SoloLeIstruzioniConOperandoDovrebberoOccuparePiuDiUnByte;
var
  LOpcode, LFour, LOne: Integer;
begin
  LFour := 0;
  LOne := 0;
  for LOpcode := -1 to 300 do
    case TQvmOpcodes.OperandSize(LOpcode) of
      4:
        Inc(LFour);
      1:
        Inc(LOne);
    else
      Assert.AreEqual(0, TQvmOpcodes.OperandSize(LOpcode));
    end;
  // enter, leave, const, local, block copy and the sixteen branches; arg
  Assert.AreEqual(21, LFour);
  Assert.AreEqual(1, LOne);
  Assert.AreEqual(1, TQvmOpcodes.OperandSize(OP_ARG));
  Assert.AreEqual(4, TQvmOpcodes.OperandSize(OP_BLOCK_COPY));
  Assert.AreEqual(0, TQvmOpcodes.OperandSize(OP_JUMP));
  Assert.AreEqual(0, TQvmOpcodes.OperandSize(OP_CALL));
end;

procedure TTestQvmOpcodes.ISaltiCondizionatiDovrebberoEssereSedici;
var
  LOpcode, LCount: Integer;
begin
  LCount := 0;
  for LOpcode := -1 to 300 do
    if TQvmOpcodes.IsBranch(LOpcode) then
      Inc(LCount);
  Assert.AreEqual(16, LCount);
  Assert.IsTrue(TQvmOpcodes.IsBranch(OP_EQ));
  Assert.IsTrue(TQvmOpcodes.IsBranch(OP_GEF));
  Assert.IsFalse(TQvmOpcodes.IsBranch(OP_JUMP));
  Assert.IsFalse(TQvmOpcodes.IsBranch(OP_LOAD1));
end;

procedure TTestQvmOpcodes.OgniIstruzioneDovrebbeAvereIlSuoNome;
var
  LOpcode: Integer;
begin
  for LOpcode := 0 to OP_LAST do
    Assert.StartsWith('OP_', TQvmOpcodes.Name(LOpcode));
  Assert.AreEqual('OP_UNDEF', TQvmOpcodes.Name(OP_UNDEF));
  Assert.AreEqual('OP_BLOCK_COPY', TQvmOpcodes.Name(OP_BLOCK_COPY));
  Assert.AreEqual('OP_CVFI', TQvmOpcodes.Name(OP_CVFI));
  Assert.AreEqual('', TQvmOpcodes.Name(-1));
  Assert.AreEqual('', TQvmOpcodes.Name(60));
end;

end.
