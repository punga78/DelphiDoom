{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom formats library - the .CAT containers          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (no code of OpenXcom in this unit)                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xcom.CatArchive;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Intf;

type
  [TestFixture]
  [Category('xcom')]
  TTestXcomCatArchive = class(TObject)
  private
    FArchive: IXcomCatArchive;
    /// <summary>Two entries: "ab" + xyz (size 3) and "" + q (size 1)</summary>
    function TwoEntries: TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeContareLeVoci;
    [Test]
    procedure DovrebbeDareOffsetEDimensioneDiUnaVoce;
    [Test]
    procedure DovrebbeSaltareIlNomeDiUnaVoce;
    [Test]
    procedure DovrebbeTenereIlNomeSeLoSiChiede;
    [Test]
    procedure DovrebbeLeggereUnaVoceSenzaNome;
    [Test]
    procedure DovrebbeNonSaltareUnNomeLungoPiuDiCinquantasei;
    [Test]
    procedure DovrebbeRiempireDiZeriCioCheIlFileNonHa;
    [Test]
    procedure DovrebbeRifiutareUnaVoceCheNonCe;
    [Test]
    procedure DovrebbeRifiutareUnFileTroppoCorto;
    [Test]
    procedure DovrebbeRifiutareUnIndiceCheEOltreIlFile;
    [Test]
    procedure DovrebbeRifiutareUnaVoceEnorme;
  end;

implementation

uses
  DelphiDoom.Xcom.Factory, DelphiDoom.Tests.Xcom.Builders;

{ TTestXcomCatArchive }

function TTestXcomCatArchive.TwoEntries: TBytes;
begin
  Result := nil;
  TXcomTestBuilders.AddCardinal(Result, 16);
  TXcomTestBuilders.AddCardinal(Result, 3);
  TXcomTestBuilders.AddCardinal(Result, 22);
  TXcomTestBuilders.AddCardinal(Result, 1);
  // entry 0 at 16: name of 2 bytes, then xyz
  TXcomTestBuilders.AddByte(Result, 2);
  TXcomTestBuilders.AddByte(Result, Ord('a'));
  TXcomTestBuilders.AddByte(Result, Ord('b'));
  TXcomTestBuilders.AddByte(Result, Ord('x'));
  TXcomTestBuilders.AddByte(Result, Ord('y'));
  TXcomTestBuilders.AddByte(Result, Ord('z'));
  // entry 1 at 22: no name, then q
  TXcomTestBuilders.AddByte(Result, 0);
  TXcomTestBuilders.AddByte(Result, Ord('q'));
end;

procedure TTestXcomCatArchive.Setup;
begin
  FArchive := TXcomFactory.CreateCatArchive(TwoEntries);
end;

procedure TTestXcomCatArchive.TearDown;
begin
  FArchive := nil;
end;

procedure TTestXcomCatArchive.DovrebbeContareLeVoci;
begin
  Assert.AreEqual(2, FArchive.Count);
end;

procedure TTestXcomCatArchive.DovrebbeDareOffsetEDimensioneDiUnaVoce;
begin
  Assert.AreEqual(22, Integer(FArchive.Entries[1].Offset));
  Assert.AreEqual(1, Integer(FArchive.Entries[1].Size));
end;

procedure TTestXcomCatArchive.DovrebbeSaltareIlNomeDiUnaVoce;
begin
  Assert.AreEqual('xyz', TEncoding.ASCII.GetString(FArchive.Load(0)));
  Assert.AreEqual('q', TEncoding.ASCII.GetString(FArchive.Load(1, False)));
end;

procedure TTestXcomCatArchive.DovrebbeTenereIlNomeSeLoSiChiede;
var
  LBytes: TBytes;
begin
  LBytes := FArchive.Load(0, True);
  Assert.AreEqual(6, Integer(Length(LBytes)));
  Assert.AreEqual(2, Integer(LBytes[0]));
  Assert.AreEqual('xyz', TEncoding.ASCII.GetString(LBytes, 3, 3));
end;

procedure TTestXcomCatArchive.DovrebbeLeggereUnaVoceSenzaNome;
var
  LBytes: TBytes;
begin
  LBytes := FArchive.Load(1, True);
  Assert.AreEqual(2, Integer(Length(LBytes)));
end;

procedure TTestXcomCatArchive.DovrebbeNonSaltareUnNomeLungoPiuDiCinquantasei;
var
  LFile: TBytes;
begin
  LFile := nil;
  TXcomTestBuilders.AddCardinal(LFile, 8);
  TXcomTestBuilders.AddCardinal(LFile, 3);
  // 57 is not a name length: the three bytes are data
  TXcomTestBuilders.AddByte(LFile, 57);
  TXcomTestBuilders.AddByte(LFile, 1);
  TXcomTestBuilders.AddByte(LFile, 2);
  Assert.AreEqual(3, Integer(Length(TXcomFactory.CreateCatArchive(LFile).Load(0))));
  Assert.AreEqual(57, Integer(TXcomFactory.CreateCatArchive(LFile).Load(0)[0]));
end;

procedure TTestXcomCatArchive.DovrebbeRiempireDiZeriCioCheIlFileNonHa;
var
  LFile: TBytes;
  LBytes: TBytes;
begin
  LFile := nil;
  TXcomTestBuilders.AddCardinal(LFile, 8);
  TXcomTestBuilders.AddCardinal(LFile, 5);
  TXcomTestBuilders.AddByte(LFile, 0);
  TXcomTestBuilders.AddByte(LFile, 9);
  LBytes := TXcomFactory.CreateCatArchive(LFile).Load(0);
  Assert.AreEqual(5, Integer(Length(LBytes)));
  Assert.AreEqual(9, Integer(LBytes[0]));
  Assert.AreEqual(0, Integer(LBytes[4]));
end;

procedure TTestXcomCatArchive.DovrebbeRifiutareUnaVoceCheNonCe;
begin
  Assert.WillRaise(procedure begin FArchive.Load(2); end, EXcomException);
  Assert.WillRaise(procedure begin FArchive.Load(-1); end, EXcomException);
  Assert.WillRaise(
    procedure
    var
      LEntry: TXcomCatEntry;
    begin
      LEntry := FArchive.Entries[5];
    end, EXcomException);
end;

procedure TTestXcomCatArchive.DovrebbeRifiutareUnFileTroppoCorto;
begin
  Assert.WillRaise(procedure begin TXcomFactory.CreateCatArchive(TXcomTestBuilders.Bytes([1, 2])); end,
    EXcomDataException);
end;

procedure TTestXcomCatArchive.DovrebbeRifiutareUnIndiceCheEOltreIlFile;
begin
  Assert.WillRaise(
    procedure
    begin
      TXcomFactory.CreateCatArchive(TXcomTestBuilders.Bytes([$00, $01, 0, 0, 0, 0, 0, 0]));
    end, EXcomDataException);
end;

procedure TTestXcomCatArchive.DovrebbeRifiutareUnaVoceEnorme;
var
  LFile: TBytes;
begin
  LFile := nil;
  TXcomTestBuilders.AddCardinal(LFile, 8);
  TXcomTestBuilders.AddCardinal(LFile, $FFFFFFF0);
  Assert.WillRaise(procedure begin TXcomFactory.CreateCatArchive(LFile).Load(0); end, EXcomDataException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomCatArchive);

end.
