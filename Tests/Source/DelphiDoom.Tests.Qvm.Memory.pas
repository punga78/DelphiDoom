{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the QVM library - the data image and its checked       }
{  accesses                                                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Qvm.Memory;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Image, DelphiDoom.Qvm.Memory;

type
  [TestFixture]
  [Category('Qvm')]
  TTestQvmMemory = class
  strict private
    FImage: TQvmImage;
    FMemory: TQvmMemory;
    function NewImage(ASize: Integer): TQvmImage;
    procedure ExpectOutOfRange(const AAction: TProc);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeCaricareDatiELetteraliEAzzerareIlResto;
    [Test]
    procedure DopoLaMemoriaDovrebberoEsserciByteAZeroPerLeLettureOltreLaFine;
    [Test]
    procedure LIndirizzoDovrebbeEssereMascheratoComeNellOriginale;
    [Test]
    procedure ArgPtrDovrebbeDareNilPerLIndirizzoZero;
    [Test]
    procedure RangeDovrebbeTrattareLoZeroComeUnIndirizzo;
    [Test]
    [TestCase('un byte oltre', '1020,5')]
    [TestCase('lunghezza negativa', '100,-1')]
    [TestCase('tutta la memoria da uno', '1,1024')]
    [TestCase('enorme', '0,2147483647')]
    procedure DovrebbeRifiutareUnIntervalloCheEsceDallaMemoria(AAddress, ALength: Integer);
    [Test]
    procedure LUltimoByteELInteraMemoriaDovrebberoEssereAccessibili;
    [Test]
    procedure DovrebbeLeggereEScrivereByteEInteri;
    [Test]
    procedure UnInteroAcavalloDellaFineDovrebbeEssereRifiutato;
    [Test]
    procedure DovrebbeLeggereUnaStringaFinoAlloZero;
    [Test]
    procedure UnaStringaSenzaFineDovrebbeEssereRifiutata;
    [Test]
    procedure DovrebbeScrivereUnaStringaTroncandolaAlBuffer;
    [Test]
    procedure ScrivereUnaStringaInUnBufferVuotoNonFaNulla;
    [Test]
    procedure UnaStringaCheNonStaNellaMemoriaDovrebbeEssereRifiutata;
    [Test]
    procedure DovrebbeLeggereEScrivereBlocchiDiByte;
    [Test]
    procedure DovrebbeRiempireECopiareAncheSovrapposto;
    [Test]
    procedure RicaricareDovrebbeRiportareLaMemoriaAllInizio;
    [Test]
    procedure RicaricareUnImmagineDiUnAltraDimensioneDovrebbeEssereRifiutato;
    [Test]
    procedure LaCopiaABlocchiDovrebbeCopiareParolePartendoDallUltima;
    [Test]
    procedure LaCopiaABlocchiNonAllineataDovrebbeEssereSegnalata;
    [Test]
    procedure LaCopiaABlocchiCheSuperaLaFineDovrebbeEssereTagliataComeNellOriginale;
    [Test]
    procedure LaCopiaABlocchiConContoNegativoNonDovrebbeMaiUscireDallaMemoria;
  end;

implementation

uses
  DelphiDoom.Qvm.Opcodes, DelphiDoom.Tests.Qvm.Assembler;

const
  SIZE = 1024;

{ TTestQvmMemory }

function TTestQvmMemory.NewImage(ASize: Integer): TQvmImage;
var
  LAssembler: TQvmAssembler;
begin
  LAssembler := TQvmAssembler.Create;
  try
    LAssembler.Op(OP_LEAVE, 0);
    LAssembler.Data([$04030201, $08070605]);
    LAssembler.Lit('lit' + #0);
    LAssembler.ImageSize(ASize);
    Result := TQvmImage.Create(LAssembler.ToBytes, TQvmLimits.Default, 'prova');
  finally
    LAssembler.Free;
  end;
end;

procedure TTestQvmMemory.Setup;
begin
  FImage := NewImage(SIZE);
  FMemory := TQvmMemory.Create(FImage);
end;

procedure TTestQvmMemory.TearDown;
begin
  FMemory.Free;
  FImage.Free;
end;

procedure TTestQvmMemory.ExpectOutOfRange(const AAction: TProc);
begin
  Assert.WillRaise(
    procedure
    begin
      AAction();
    end, EQvmExecutionException);
end;

procedure TTestQvmMemory.DovrebbeCaricareDatiELetteraliEAzzerareIlResto;
var
  LIndex: Integer;
begin
  Assert.AreEqual(SIZE, FMemory.Size);
  Assert.AreEqual(SIZE - 1, FMemory.Mask);
  Assert.AreEqual($04030201, FMemory.ReadInt32(0));
  Assert.AreEqual($08070605, FMemory.ReadInt32(4));
  Assert.AreEqual<AnsiString>('lit', FMemory.ReadString(8));
  for LIndex := 12 to SIZE - 1 do
    Assert.AreEqual<Integer>(0, FMemory.ReadByte(LIndex));
end;

procedure TTestQvmMemory.DopoLaMemoriaDovrebberoEsserciByteAZeroPerLeLettureOltreLaFine;
var
  LIndex: Integer;
begin
  for LIndex := 0 to QVM_DATA_PADDING - 1 do
    Assert.AreEqual<Integer>(0, (FMemory.Base + SIZE + LIndex)^);
end;

procedure TTestQvmMemory.LIndirizzoDovrebbeEssereMascheratoComeNellOriginale;
begin
  Assert.AreEqual($04030201, FMemory.ReadInt32(SIZE));
  Assert.AreEqual($08070605, FMemory.ReadInt32(4 + 7 * SIZE));
  Assert.AreEqual($08070605, FMemory.ReadInt32(4 - SIZE));
  Assert.AreEqual($04030201, FMemory.ReadInt32(Low(Integer)));
  Assert.IsTrue(FMemory.Range(SIZE + 5, 1) = FMemory.Base + 5);
end;

procedure TTestQvmMemory.ArgPtrDovrebbeDareNilPerLIndirizzoZero;
begin
  Assert.IsNull(FMemory.ArgPtr(0, 4));
  Assert.IsTrue(FMemory.ArgPtr(4, 4) = FMemory.Base + 4);
  // an address that the mask turns into zero is not "no pointer"
  Assert.IsTrue(FMemory.ArgPtr(SIZE, 4) = FMemory.Base);
  ExpectOutOfRange(
    procedure
    begin
      FMemory.ArgPtr(SIZE - 2, 4);
    end);
end;

procedure TTestQvmMemory.RangeDovrebbeTrattareLoZeroComeUnIndirizzo;
begin
  Assert.IsTrue(FMemory.Range(0, 4) = FMemory.Base);
end;

procedure TTestQvmMemory.DovrebbeRifiutareUnIntervalloCheEsceDallaMemoria(AAddress, ALength: Integer);
begin
  ExpectOutOfRange(
    procedure
    begin
      FMemory.Range(AAddress, ALength);
    end);
end;

procedure TTestQvmMemory.LUltimoByteELInteraMemoriaDovrebberoEssereAccessibili;
begin
  Assert.IsTrue(FMemory.Range(SIZE - 1, 1) = FMemory.Base + SIZE - 1);
  Assert.IsTrue(FMemory.Range(0, SIZE) = FMemory.Base);
  Assert.IsTrue(FMemory.Range(SIZE - 1, 0) = FMemory.Base + SIZE - 1);
end;

procedure TTestQvmMemory.DovrebbeLeggereEScrivereByteEInteri;
begin
  FMemory.WriteByte(100, $AB);
  FMemory.WriteInt32(200, Integer($DEADBEEF));
  Assert.AreEqual<Integer>($AB, FMemory.ReadByte(100));
  Assert.AreEqual(Integer($DEADBEEF), FMemory.ReadInt32(200));
  // little endian, at any alignment
  Assert.AreEqual<Integer>($EF, FMemory.ReadByte(200));
  FMemory.WriteInt32(301, $01020304);
  Assert.AreEqual<Integer>($04, FMemory.ReadByte(301));
  Assert.AreEqual<Integer>($01, FMemory.ReadByte(304));
end;

procedure TTestQvmMemory.UnInteroAcavalloDellaFineDovrebbeEssereRifiutato;
begin
  FMemory.WriteInt32(SIZE - 4, 1);
  ExpectOutOfRange(
    procedure
    begin
      FMemory.WriteInt32(SIZE - 3, 1);
    end);
  ExpectOutOfRange(
    procedure
    begin
      FMemory.ReadInt32(SIZE - 1);
    end);
end;

procedure TTestQvmMemory.DovrebbeLeggereUnaStringaFinoAlloZero;
begin
  FMemory.WriteBytes(500, [Ord('a'), 200, Ord('z'), 0, Ord('x')]);
  Assert.AreEqual<AnsiString>('a'#200'z', FMemory.ReadString(500));
  Assert.AreEqual<AnsiString>('', FMemory.ReadString(503));
  Assert.AreEqual<AnsiString>('a'#200'z', FMemory.ReadString(500 + 3 * SIZE));
end;

procedure TTestQvmMemory.UnaStringaSenzaFineDovrebbeEssereRifiutata;
begin
  FMemory.Fill(SIZE - 8, Ord('x'), 8);
  ExpectOutOfRange(
    procedure
    begin
      FMemory.ReadString(SIZE - 8);
    end);
  // with its zero as the last byte it is good
  FMemory.WriteByte(SIZE - 1, 0);
  Assert.AreEqual<AnsiString>('xxxxxxx', FMemory.ReadString(SIZE - 8));
end;

procedure TTestQvmMemory.DovrebbeScrivereUnaStringaTroncandolaAlBuffer;
begin
  FMemory.Fill(600, $FF, 16);
  FMemory.WriteString(600, 'hello', 16);
  Assert.AreEqual<AnsiString>('hello', FMemory.ReadString(600));
  // the rest of the buffer is zero, as strncpy leaves it; what follows the buffer is not touched
  Assert.AreEqual<Integer>(0, FMemory.ReadByte(606));
  Assert.AreEqual<Integer>(0, FMemory.ReadByte(615));
  FMemory.Fill(600, $FF, 16);
  FMemory.WriteString(600, 'truncated', 4);
  Assert.AreEqual<AnsiString>('tru', FMemory.ReadString(600));
  Assert.AreEqual<Integer>($FF, FMemory.ReadByte(604));
  FMemory.WriteString(600, '', 1);
  Assert.AreEqual<AnsiString>('', FMemory.ReadString(600));
end;

procedure TTestQvmMemory.ScrivereUnaStringaInUnBufferVuotoNonFaNulla;
begin
  FMemory.WriteByte(700, $55);
  FMemory.WriteString(700, 'x', 0);
  FMemory.WriteString(700, 'x', -5);
  Assert.AreEqual<Integer>($55, FMemory.ReadByte(700));
end;

procedure TTestQvmMemory.UnaStringaCheNonStaNellaMemoriaDovrebbeEssereRifiutata;
begin
  ExpectOutOfRange(
    procedure
    begin
      FMemory.WriteString(SIZE - 3, 'hello', 16);
    end);
  // cut by the buffer it fits
  FMemory.WriteString(SIZE - 3, 'hello', 3);
  Assert.AreEqual<AnsiString>('he', FMemory.ReadString(SIZE - 3));
end;

procedure TTestQvmMemory.DovrebbeLeggereEScrivereBlocchiDiByte;
var
  LBytes: TBytes;
begin
  FMemory.WriteBytes(800, [1, 2, 3, 4, 5]);
  LBytes := FMemory.ReadBytes(801, 3);
  Assert.AreEqual<Integer>(3, Length(LBytes));
  Assert.AreEqual<Integer>(2, LBytes[0]);
  Assert.AreEqual<Integer>(4, LBytes[2]);
  Assert.AreEqual<Integer>(0, Length(FMemory.ReadBytes(801, 0)));
  FMemory.WriteBytes(801, nil);
  Assert.AreEqual<Integer>(2, FMemory.ReadByte(801));
  ExpectOutOfRange(
    procedure
    begin
      FMemory.ReadBytes(SIZE - 2, 3);
    end);
  ExpectOutOfRange(
    procedure
    begin
      FMemory.WriteBytes(SIZE - 2, [1, 2, 3]);
    end);
end;

procedure TTestQvmMemory.DovrebbeRiempireECopiareAncheSovrapposto;
begin
  FMemory.Fill(900, 7, 4);
  Assert.AreEqual($07070707, FMemory.ReadInt32(900));
  Assert.AreEqual<Integer>(0, FMemory.ReadByte(904));
  FMemory.WriteBytes(900, [1, 2, 3, 4, 5, 6]);
  // memmove: the source is read before it is overwritten
  FMemory.Copy(902, 900, 6);
  Assert.AreEqual<Integer>(1, FMemory.ReadByte(902));
  Assert.AreEqual<Integer>(6, FMemory.ReadByte(907));
  FMemory.Copy(900, 902, 6);
  Assert.AreEqual<Integer>(1, FMemory.ReadByte(900));
  Assert.AreEqual<Integer>(6, FMemory.ReadByte(905));
  ExpectOutOfRange(
    procedure
    begin
      FMemory.Fill(SIZE - 4, 0, 5);
    end);
  ExpectOutOfRange(
    procedure
    begin
      FMemory.Copy(0, SIZE - 4, 5);
    end);
  ExpectOutOfRange(
    procedure
    begin
      FMemory.Copy(SIZE - 4, 0, 5);
    end);
end;

procedure TTestQvmMemory.RicaricareDovrebbeRiportareLaMemoriaAllInizio;
begin
  FMemory.Fill(0, $EE, SIZE);
  FMemory.Load(FImage);
  Assert.AreEqual($04030201, FMemory.ReadInt32(0));
  Assert.AreEqual<Integer>(0, FMemory.ReadByte(12));
  Assert.AreEqual<Integer>(0, FMemory.ReadByte(SIZE - 1));
end;

procedure TTestQvmMemory.RicaricareUnImmagineDiUnAltraDimensioneDovrebbeEssereRifiutato;
var
  LOther: TQvmImage;
begin
  LOther := NewImage(2 * SIZE);
  try
    Assert.WillRaise(
      procedure
      begin
        FMemory.Load(LOther);
      end, EQvmFormatException);
  finally
    LOther.Free;
  end;
end;

procedure TTestQvmMemory.LaCopiaABlocchiDovrebbeCopiareParolePartendoDallUltima;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 7 do
    FMemory.WriteInt32(100 + 4 * LIndex, LIndex + 1);
  Assert.IsTrue(FMemory.BlockCopy(200, 100, 16) = TQvmBlockCopyResult.Copied);
  Assert.AreEqual(1, FMemory.ReadInt32(200));
  Assert.AreEqual(4, FMemory.ReadInt32(212));
  Assert.AreEqual(0, FMemory.ReadInt32(216));
  // the destination after the source: as memmove
  Assert.IsTrue(FMemory.BlockCopy(104, 100, 16) = TQvmBlockCopyResult.Copied);
  Assert.AreEqual(1, FMemory.ReadInt32(104));
  Assert.AreEqual(4, FMemory.ReadInt32(116));
  // the destination before the source, from the last word: the last word is smeared over the block
  for LIndex := 0 to 7 do
    FMemory.WriteInt32(300 + 4 * LIndex, LIndex + 1);
  Assert.IsTrue(FMemory.BlockCopy(300, 304, 16) = TQvmBlockCopyResult.Copied);
  Assert.AreEqual(5, FMemory.ReadInt32(300));
  Assert.AreEqual(5, FMemory.ReadInt32(304));
  Assert.AreEqual(5, FMemory.ReadInt32(312));
  // masked addresses, and nothing to copy
  Assert.IsTrue(FMemory.BlockCopy(400 + SIZE, 100 - SIZE, 4) = TQvmBlockCopyResult.Copied);
  Assert.AreEqual(1, FMemory.ReadInt32(400));
  Assert.IsTrue(FMemory.BlockCopy(500, 100, 0) = TQvmBlockCopyResult.Copied);
  Assert.AreEqual(0, FMemory.ReadInt32(500));
end;

procedure TTestQvmMemory.LaCopiaABlocchiNonAllineataDovrebbeEssereSegnalata;
begin
  Assert.IsTrue(FMemory.BlockCopy(201, 100, 16) = TQvmBlockCopyResult.NotAligned);
  Assert.IsTrue(FMemory.BlockCopy(200, 102, 16) = TQvmBlockCopyResult.NotAligned);
  Assert.IsTrue(FMemory.BlockCopy(200, 100, 6) = TQvmBlockCopyResult.NotAligned);
  Assert.AreEqual(0, FMemory.ReadInt32(200));
end;

procedure TTestQvmMemory.LaCopiaABlocchiCheSuperaLaFineDovrebbeEssereTagliataComeNellOriginale;
begin
  FMemory.Fill(100, $11, 64);
  // the destination would pass the end: the count of the original becomes negative, nothing is copied
  Assert.IsTrue(FMemory.BlockCopy(SIZE - 8, 100, 16) = TQvmBlockCopyResult.Copied);
  Assert.AreEqual(0, FMemory.ReadInt32(SIZE - 8));
  // a count as large as the image is no count at all
  Assert.IsTrue(FMemory.BlockCopy(200, 100, SIZE) = TQvmBlockCopyResult.Copied);
  Assert.AreEqual(0, FMemory.ReadInt32(200));
  // one word more than the image is one word
  Assert.IsTrue(FMemory.BlockCopy(200, 100, SIZE + 4) = TQvmBlockCopyResult.Copied);
  Assert.AreEqual($11111111, FMemory.ReadInt32(200));
  Assert.AreEqual(0, FMemory.ReadInt32(204));
end;

procedure TTestQvmMemory.LaCopiaABlocchiConContoNegativoNonDovrebbeMaiUscireDallaMemoria;
var
  LSource, LTarget, LCount: Integer;
begin
  // the two cuts of the original, one after the other, let these through with a count that leaves the image
  // from the source: the original reads what follows the image
  Assert.IsTrue(FMemory.BlockCopy(0, 8, -4) = TQvmBlockCopyResult.OutOfRange);
  Assert.IsTrue(FMemory.BlockCopy(300, SIZE - 32, 64) = TQvmBlockCopyResult.OutOfRange);
  // away from those cases a negative count copies nothing
  Assert.IsTrue(FMemory.BlockCopy(200, 100, -4) = TQvmBlockCopyResult.Copied);
  // whatever the three numbers, the padding after the image is never written
  for LSource := -3 to 3 do
    for LTarget := -3 to 3 do
      for LCount := -6 to 6 do
        FMemory.BlockCopy(LTarget * 340, LSource * 172, LCount * 300);
  for LCount := 0 to QVM_DATA_PADDING - 1 do
    Assert.AreEqual<Integer>(0, (FMemory.Base + SIZE + LCount)^);
end;

end.
