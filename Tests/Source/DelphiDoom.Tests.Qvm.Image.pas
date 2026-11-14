{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the QVM library - reading and validating a .qvm file   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Qvm.Image;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Image;

type
  [TestFixture]
  [Category('Qvm')]
  TTestQvmImage = class
  strict private
    function Sample(AVersion2: Boolean = False): TBytes;
    function Patched(AField, AValue: Integer): TBytes;
    procedure ExpectBad(const AData: TBytes; const AText: string);
  public
    [Test]
    procedure LIntestazioneSuDiscoDovrebbeEssereDiTrentadueByte;
    [Test]
    procedure DovrebbeLeggereISegmentiDiUnFile;
    [Test]
    procedure LaMemoriaDovrebbeEssereLaPotenzaDiDueCheContieneDatiLetteraliEBss;
    [Test]
    [TestCase('niente dati', '0,1')]
    [TestCase('un byte', '1,1')]
    [TestCase('tre byte', '3,4')]
    [TestCase('potenza esatta', '4096,4096')]
    [TestCase('uno in piu', '4097,8192')]
    procedure LaDimensioneDovrebbeArrotondareComeLOriginale(ABss, AExpected: Integer);
    [Test]
    procedure DovrebbeLeggereLaTabellaDeiSaltiDellaVersioneDue;
    [Test]
    procedure UnFileDiVersioneUnoNonHaTabellaDeiSalti;
    [Test]
    procedure DovrebbeRifiutareUnFileTroppoCorto;
    [Test]
    procedure DovrebbeRifiutareLaVersioneDueSenzaIlCampoInPiu;
    [Test]
    [TestCase('magic', '0,305419896')]
    [TestCase('codice vuoto', '3,0')]
    [TestCase('codice negativo', '3,-4')]
    [TestCase('dati negativi', '5,-1')]
    [TestCase('letterali negativi', '6,-1')]
    [TestCase('bss negativo', '7,-1')]
    procedure DovrebbeRifiutareLIntestazioneCheRifiutaLOriginale(AField, AValue: Integer);
    [Test]
    [TestCase('codice oltre la fine', '3,100000,code')]
    [TestCase('codice prima dell inizio', '2,-8,code')]
    [TestCase('dati oltre la fine', '5,100000,data')]
    [TestCase('dati prima dell inizio', '4,-8,data')]
    [TestCase('letterali oltre la fine', '6,100000,data')]
    [TestCase('lunghezze che traboccano', '5,2147483647,data')]
    procedure DovrebbeRifiutareUnSegmentoFuoriDalFile(AField, AValue: Integer; const ASegment: string);
    [Test]
    [TestCase('zero', '0')]
    [TestCase('negativo', '-1')]
    [TestCase('piu dei byte del codice', '1000')]
    procedure DovrebbeRifiutareUnNumeroDiIstruzioniImpossibile(ACount: Integer);
    [Test]
    procedure DovrebbeRifiutareUnaMemoriaOltreIlLimite;
    [Test]
    procedure DovrebbeRifiutareUnBssCheNonStaInTrentaBit;
    [Test]
    procedure DovrebbeRifiutareUnaTabellaDeiSaltiFuoriDalFile;
    [Test]
    procedure DovrebbeRifiutareUnaTabellaDeiSaltiNegativa;
  end;

implementation

uses
  DelphiDoom.Qvm.Opcodes, DelphiDoom.Tests.Qvm.Assembler;

{ TTestQvmImage }

function TTestQvmImage.Sample(AVersion2: Boolean): TBytes;
var
  LAssembler: TQvmAssembler;
begin
  LAssembler := TQvmAssembler.Create;
  try
    LAssembler.Data([$11223344, $55667788]);
    LAssembler.Lit('abc');
    LAssembler.Bss(100);
    LAssembler.Op(OP_ENTER, 16);
    LAssembler.Op(OP_CONST, 7);
    LAssembler.Op(OP_LEAVE, 16);
    LAssembler.JumpTargets([0, 2]);
    Result := LAssembler.ToBytes(AVersion2);
  finally
    LAssembler.Free;
  end;
end;

function TTestQvmImage.Patched(AField, AValue: Integer): TBytes;
begin
  Result := Sample;
  Move(AValue, Result[AField * SizeOf(Integer)], SizeOf(Integer));
end;

procedure TTestQvmImage.ExpectBad(const AData: TBytes; const AText: string);
var
  LImage: TQvmImage;
begin
  try
    LImage := TQvmImage.Create(AData, TQvmLimits.Default, 'prova');
    LImage.Free;
    Assert.Fail('il file e'' stato accettato');
  except
    on E: EQvmFormatException do
      Assert.Contains(E.Message, AText);
  end;
end;

procedure TTestQvmImage.LIntestazioneSuDiscoDovrebbeEssereDiTrentadueByte;
begin
  Assert.AreEqual(32, SizeOf(TQvmHeader));
  Assert.AreEqual(64, SizeOf(TQvmSystemCallArguments));
end;

procedure TTestQvmImage.DovrebbeLeggereISegmentiDiUnFile;
var
  LImage: TQvmImage;
begin
  LImage := TQvmImage.Create(Sample, TQvmLimits.Default, 'prova');
  try
    Assert.IsFalse(LImage.Version2);
    Assert.AreEqual(3, LImage.InstructionCount);
    // 15 bytes of instructions padded to 16
    Assert.AreEqual<Integer>(16, Length(LImage.Code));
    Assert.AreEqual<Integer>(OP_ENTER, LImage.Code[0]);
    Assert.AreEqual<Integer>(OP_LEAVE, LImage.Code[10]);
    Assert.AreEqual(8, LImage.DataLength);
    Assert.AreEqual(3, LImage.LitLength);
    Assert.AreEqual(100, LImage.BssLength);
    Assert.AreEqual<Integer>(11, Length(LImage.InitialData));
    Assert.AreEqual<Integer>($44, LImage.InitialData[0]);
    Assert.AreEqual<Integer>(Ord('c'), LImage.InitialData[10]);
  finally
    LImage.Free;
  end;
end;

procedure TTestQvmImage.LaMemoriaDovrebbeEssereLaPotenzaDiDueCheContieneDatiLetteraliEBss;
var
  LImage: TQvmImage;
begin
  // 8 + 3 + 100 = 111
  LImage := TQvmImage.Create(Sample, TQvmLimits.Default, 'prova');
  try
    Assert.AreEqual(128, LImage.DataSize);
  finally
    LImage.Free;
  end;
end;

procedure TTestQvmImage.LaDimensioneDovrebbeArrotondareComeLOriginale(ABss, AExpected: Integer);
var
  LAssembler: TQvmAssembler;
  LImage: TQvmImage;
begin
  LAssembler := TQvmAssembler.Create;
  try
    LAssembler.Op(OP_LEAVE, 0);
    LAssembler.Bss(ABss);
    LImage := TQvmImage.Create(LAssembler.ToBytes, TQvmLimits.Default, 'prova');
    try
      Assert.AreEqual(AExpected, LImage.DataSize);
    finally
      LImage.Free;
    end;
  finally
    LAssembler.Free;
  end;
end;

procedure TTestQvmImage.DovrebbeLeggereLaTabellaDeiSaltiDellaVersioneDue;
var
  LImage: TQvmImage;
begin
  LImage := TQvmImage.Create(Sample(True), TQvmLimits.Default, 'prova');
  try
    Assert.IsTrue(LImage.Version2);
    Assert.AreEqual(3, LImage.InstructionCount);
    Assert.AreEqual<Integer>(2, Length(LImage.JumpTargets));
    Assert.AreEqual(0, LImage.JumpTargets[0]);
    Assert.AreEqual(2, LImage.JumpTargets[1]);
    // the table is not part of the data image
    Assert.AreEqual<Integer>(11, Length(LImage.InitialData));
    Assert.AreEqual(128, LImage.DataSize);
  finally
    LImage.Free;
  end;
end;

procedure TTestQvmImage.UnFileDiVersioneUnoNonHaTabellaDeiSalti;
var
  LImage: TQvmImage;
begin
  LImage := TQvmImage.Create(Sample, TQvmLimits.Default, 'prova');
  try
    Assert.AreEqual<Integer>(0, Length(LImage.JumpTargets));
  finally
    LImage.Free;
  end;
end;

procedure TTestQvmImage.DovrebbeRifiutareUnFileTroppoCorto;
begin
  ExpectBad(nil, 'too short');
  ExpectBad(Copy(Sample, 0, 31), 'too short');
end;

procedure TTestQvmImage.DovrebbeRifiutareLaVersioneDueSenzaIlCampoInPiu;
begin
  ExpectBad(Copy(Sample(True), 0, 34), 'too short');
end;

procedure TTestQvmImage.DovrebbeRifiutareLIntestazioneCheRifiutaLOriginale(AField, AValue: Integer);
begin
  ExpectBad(Patched(AField, AValue), 'prova has bad header');
end;

procedure TTestQvmImage.DovrebbeRifiutareUnSegmentoFuoriDalFile(AField, AValue: Integer; const ASegment: string);
begin
  ExpectBad(Patched(AField, AValue), 'the ' + ASegment + ' segment lies outside the file');
end;

procedure TTestQvmImage.DovrebbeRifiutareUnNumeroDiIstruzioniImpossibile(ACount: Integer);
begin
  ExpectBad(Patched(1, ACount), 'instructions cannot fit');
end;

procedure TTestQvmImage.DovrebbeRifiutareUnaMemoriaOltreIlLimite;
var
  LLimits: TQvmLimits;
  LImage: TQvmImage;
begin
  // the default refuses a bss of 100 MB
  ExpectBad(Patched(7, 100 * 1024 * 1024), 'above the limit');
  // 111 bytes need 128: a limit of 127 is not enough, one of 128 is
  LLimits := TQvmLimits.Default;
  LLimits.MaxDataSize := 127;
  Assert.WillRaise(
    procedure
    begin
      TQvmImage.Create(Sample, LLimits, 'prova').Free;
    end, EQvmFormatException);
  LLimits.MaxDataSize := 128;
  LImage := TQvmImage.Create(Sample, LLimits, 'prova');
  LImage.Free;
end;

procedure TTestQvmImage.DovrebbeRifiutareUnBssCheNonStaInTrentaBit;
var
  LLimits: TQvmLimits;
begin
  // even with no limit a data image is at most 2^30: the loop of the original never ends above that
  LLimits := TQvmLimits.Default;
  LLimits.MaxDataSize := High(Integer);
  Assert.WillRaise(
    procedure
    begin
      TQvmImage.Create(Patched(7, (1 shl 30) + 1), LLimits, 'prova').Free;
    end, EQvmFormatException);
end;

procedure TTestQvmImage.DovrebbeRifiutareUnaTabellaDeiSaltiFuoriDalFile;
var
  LData: TBytes;
  LValue: Integer;
begin
  LData := Sample(True);
  LValue := 1000;
  Move(LValue, LData[32], SizeOf(Integer));
  ExpectBad(LData, 'the jump table segment lies outside the file');
end;

procedure TTestQvmImage.DovrebbeRifiutareUnaTabellaDeiSaltiNegativa;
var
  LData: TBytes;
  LValue: Integer;
begin
  LData := Sample(True);
  LValue := -4;
  Move(LValue, LData[32], SizeOf(Integer));
  ExpectBad(LData, 'bad header');
end;

end.
