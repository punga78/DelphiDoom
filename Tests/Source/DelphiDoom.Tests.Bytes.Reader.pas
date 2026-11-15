{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the bytes library - the cursor over a block of bytes   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Bytes.Reader;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Bytes.Types,
  DelphiDoom.Bytes.Reader;

type
  /// <summary>A reader with an exception of its own, as the libraries have</summary>
  ETestOwnException = class(Exception);

  TTestOwnReader = class(TByteReader)
  protected
    procedure RaiseOverrun(ACount: Integer); override;
  end;

  [TestFixture]
  [Category('bytes')]
  TTestBytesReader = class(TObject)
  public
    [Test]
    procedure DovrebbeLeggereNumeriLittleEndian;
    [Test]
    procedure DovrebbeLeggereNumeriBigEndian;
    [Test]
    procedure DovrebbeLeggereIlSegnoDegliInteriConSegno;
    [Test]
    procedure DovrebbeLeggereUnBloccoEAvanzare;
    [Test]
    procedure DovrebbeSaltareESpostare;
    [Test]
    procedure DovrebbeSollevareLEccezioneComuneOltreLaFine;
    [Test]
    procedure DovrebbeSollevareLEccezioneDellaSottoclasse;
    [Test]
    procedure DovrebbeRifiutareUnaLunghezzaNegativa;
    [Test]
    procedure DovrebbeRifiutareUnaPosizioneNegativa;
    [Test]
    procedure DovrebbeNonSpostarsiDopoUnaLetturaFallita;
    [Test]
    procedure DovrebbeLeggereSoloLaParteIndicata;
    [Test]
    procedure DovrebbeRifiutareUnaParteFuoriDaiDati;
    [Test]
    procedure DovrebbeTornareIndietroDiUnByteMaNonPrimaDellInizio;
    [Test]
    procedure DovrebbeDireLaDimensioneEIByteRimasti;
  end;

implementation

{ TTestOwnReader }

procedure TTestOwnReader.RaiseOverrun(ACount: Integer);
begin
  raise ETestOwnException.Create('own');
end;

{ TTestBytesReader }

procedure TTestBytesReader.DovrebbeLeggereNumeriLittleEndian;
var
  LReader: TByteReader;
begin
  LReader := TByteReader.Create([$01, $34, $12, $78, $56, $34, $12, $FF, $FF, $FF, $FF]);
  try
    Assert.AreEqual<Integer>($01, LReader.ReadByte);
    Assert.AreEqual<Integer>($1234, LReader.ReadWord);
    Assert.AreEqual<Cardinal>($12345678, LReader.ReadCardinal);
    Assert.AreEqual<Integer>(-1, LReader.ReadInteger);
  finally
    LReader.Free;
  end;
end;

procedure TTestBytesReader.DovrebbeLeggereNumeriBigEndian;
var
  LReader: TByteReader;
begin
  LReader := TByteReader.Create([$12, $34, $12, $34, $56, $78]);
  try
    Assert.AreEqual<Integer>($1234, LReader.ReadWordBE);
    Assert.AreEqual<Cardinal>($12345678, LReader.ReadCardinalBE);
  finally
    LReader.Free;
  end;
end;

procedure TTestBytesReader.DovrebbeLeggereIlSegnoDegliInteriConSegno;
var
  LReader: TByteReader;
begin
  LReader := TByteReader.Create([$FE, $FF, $00, $80, $00, $00, $00, $80]);
  try
    Assert.AreEqual<Integer>(-2, LReader.ReadSmallInt);
    Assert.AreEqual<Integer>(-32768, LReader.ReadSmallInt);
    Assert.AreEqual<Integer>(Low(Integer), LReader.ReadInteger);
  finally
    LReader.Free;
  end;
end;

procedure TTestBytesReader.DovrebbeLeggereUnBloccoEAvanzare;
var
  LReader: TByteReader;
  LBlock: TBytes;
begin
  LReader := TByteReader.Create([1, 2, 3, 4, 5]);
  try
    LBlock := LReader.ReadBlock(3);
    Assert.AreEqual<Integer>(3, Length(LBlock));
    Assert.AreEqual<Integer>(3, LBlock[2]);
    Assert.AreEqual<Integer>(3, LReader.Position);
    Assert.AreEqual<Integer>(0, Length(LReader.ReadBlock(0)));
  finally
    LReader.Free;
  end;
end;

procedure TTestBytesReader.DovrebbeSaltareESpostare;
var
  LReader: TByteReader;
begin
  LReader := TByteReader.Create([1, 2, 3, 4]);
  try
    LReader.Skip(2);
    Assert.AreEqual<Integer>(3, LReader.ReadByte);
    LReader.Seek(0);
    Assert.AreEqual<Integer>(1, LReader.ReadByte);
    LReader.Position := 3;
    Assert.AreEqual<Integer>(4, LReader.ReadByte);
    Assert.IsTrue(LReader.AtEnd);
  finally
    LReader.Free;
  end;
end;

procedure TTestBytesReader.DovrebbeSollevareLEccezioneComuneOltreLaFine;
var
  LReader: TByteReader;
begin
  LReader := TByteReader.Create([1, 2, 3]);
  try
    Assert.WillRaise(
      procedure
      begin
        LReader.ReadCardinal;
      end, EByteReaderException);
    LReader.Seek(3);
    Assert.WillRaise(
      procedure
      begin
        LReader.ReadByte;
      end, EByteReaderException);
  finally
    LReader.Free;
  end;
end;

procedure TTestBytesReader.DovrebbeSollevareLEccezioneDellaSottoclasse;
var
  LReader: TTestOwnReader;
begin
  LReader := TTestOwnReader.Create([1]);
  try
    Assert.WillRaise(
      procedure
      begin
        LReader.ReadWord;
      end, ETestOwnException);
    Assert.WillRaise(
      procedure
      begin
        LReader.Skip(2);
      end, ETestOwnException);
  finally
    LReader.Free;
  end;
end;

procedure TTestBytesReader.DovrebbeRifiutareUnaLunghezzaNegativa;
var
  LReader: TByteReader;
begin
  LReader := TByteReader.Create([1, 2]);
  try
    Assert.WillRaise(
      procedure
      begin
        LReader.ReadBlock(-1);
      end, EByteReaderException);
    Assert.WillRaise(
      procedure
      begin
        LReader.Skip(-1);
      end, EByteReaderException);
    Assert.WillRaise(
      procedure
      begin
        LReader.ReadBlock(MaxInt);
      end, EByteReaderException);
  finally
    LReader.Free;
  end;
end;

procedure TTestBytesReader.DovrebbeRifiutareUnaPosizioneNegativa;
var
  LReader: TByteReader;
begin
  LReader := TByteReader.Create([1, 2]);
  try
    LReader.Seek(-1);
    Assert.WillRaise(
      procedure
      begin
        LReader.ReadByte;
      end, EByteReaderException);
  finally
    LReader.Free;
  end;
end;

procedure TTestBytesReader.DovrebbeNonSpostarsiDopoUnaLetturaFallita;
var
  LReader: TByteReader;
begin
  LReader := TByteReader.Create([1, 2, 3]);
  try
    LReader.Skip(2);
    try
      LReader.ReadWord;
    except
      on EByteReaderException do
        ;
    end;
    Assert.AreEqual<Integer>(2, LReader.Position);
    Assert.AreEqual<Integer>(3, LReader.ReadByte);
  finally
    LReader.Free;
  end;
end;

procedure TTestBytesReader.DovrebbeLeggereSoloLaParteIndicata;
var
  LReader: TByteReader;
begin
  LReader := TByteReader.Create([9, 9, 1, 2, 3, 9], 2, 3);
  try
    Assert.AreEqual<Integer>(3, LReader.Remaining);
    Assert.AreEqual<Integer>(1, LReader.ReadByte);
    Assert.AreEqual<Integer>(2, LReader.ReadByte);
    Assert.AreEqual<Integer>(3, LReader.ReadByte);
    Assert.IsTrue(LReader.AtEnd);
    Assert.WillRaise(
      procedure
      begin
        LReader.ReadByte;
      end, EByteReaderException);
  finally
    LReader.Free;
  end;
end;

procedure TTestBytesReader.DovrebbeRifiutareUnaParteFuoriDaiDati;
begin
  Assert.WillRaise(
    procedure
    begin
      TByteReader.Create([1, 2], 1, 2).Free;
    end, EArgumentOutOfRangeException);
  Assert.WillRaise(
    procedure
    begin
      TByteReader.Create([1, 2], 3, 0).Free;
    end, EArgumentOutOfRangeException);
  Assert.WillRaise(
    procedure
    begin
      TByteReader.Create([1, 2], 0, -1).Free;
    end, EArgumentOutOfRangeException);
end;

procedure TTestBytesReader.DovrebbeTornareIndietroDiUnByteMaNonPrimaDellInizio;
var
  LReader: TByteReader;
begin
  LReader := TByteReader.Create([9, 1, 2], 1, 2);
  try
    LReader.StepBack;
    Assert.AreEqual<Integer>(1, LReader.Position);
    LReader.ReadByte;
    LReader.StepBack;
    Assert.AreEqual<Integer>(1, LReader.Position);
  finally
    LReader.Free;
  end;
end;

procedure TTestBytesReader.DovrebbeDireLaDimensioneEIByteRimasti;
var
  LReader: TByteReader;
begin
  LReader := TByteReader.Create([1, 2, 3, 4]);
  try
    Assert.AreEqual<Integer>(4, LReader.Size);
    LReader.Skip(1);
    Assert.AreEqual<Integer>(3, LReader.Remaining);
    LReader.Seek(6);
    Assert.AreEqual<Integer>(-2, LReader.Remaining);
  finally
    LReader.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestBytesReader);

end.
