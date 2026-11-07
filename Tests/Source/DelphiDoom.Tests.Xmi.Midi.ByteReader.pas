{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TXmiByteReader                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xmi.Midi.ByteReader;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xmi.Midi.Types,
  DelphiDoom.Xmi.Midi.ByteReader;

type
  [TestFixture]
  [Category('xmi')]
  TTestXmiMidiByteReader = class(TObject)
  public
    [Test]
    [TestCase('inizio negativo', '-1,2')]
    [TestCase('conteggio negativo', '0,-1')]
    [TestCase('inizio oltre i dati', '5,0')]
    [TestCase('fine oltre i dati', '2,3')]
    procedure DovrebbeRifiutareUnaParteFuoriDaiDati(AStart, ACount: Integer);
    [Test]
    procedure DovrebbeLeggereSoloLaParteData;
    [Test]
    procedure DovrebbeNonTornarePrimaDellInizio;
    [Test]
    procedure DovrebbeLeggereUnNumeroMidi;
    [Test]
    procedure DovrebbeSegnalareUnNumeroMidiDiPiuDi64Bit;
    [Test]
    procedure DovrebbeSegnalareUnNumeroMidiTroncato;
    [Test]
    procedure DovrebbeSommareLeAtteseXmi;
  end;

implementation

{ TTestXmiMidiByteReader }

procedure TTestXmiMidiByteReader.DovrebbeRifiutareUnaParteFuoriDaiDati(AStart, ACount: Integer);
begin
  Assert.WillRaise(
    procedure
    begin
      TXmiByteReader.Create(TBytes.Create(1, 2, 3, 4), AStart, ACount).Free;
    end, EArgumentOutOfRangeException);
end;

procedure TTestXmiMidiByteReader.DovrebbeLeggereSoloLaParteData;
var
  LReader: TXmiByteReader;
begin
  LReader := TXmiByteReader.Create(TBytes.Create(1, 2, 3, 4), 1, 2);
  try
    Assert.AreEqual(2, LReader.Remaining);
    Assert.AreEqual(2, Integer(LReader.ReadByte));
    Assert.AreEqual(3, Integer(LReader.ReadByte));
    Assert.IsTrue(LReader.AtEnd);
    Assert.AreEqual(0, LReader.Remaining);
    Assert.WillRaise(
      procedure
      begin
        LReader.ReadByte;
      end, EXmiDataException);
  finally
    LReader.Free;
  end;
end;

procedure TTestXmiMidiByteReader.DovrebbeNonTornarePrimaDellInizio;
var
  LReader: TXmiByteReader;
begin
  LReader := TXmiByteReader.Create(TBytes.Create(7, 8), 1, 1);
  try
    LReader.StepBack;
    Assert.AreEqual(8, Integer(LReader.ReadByte));
    LReader.StepBack;
    Assert.AreEqual(8, Integer(LReader.ReadByte));
  finally
    LReader.Free;
  end;
end;

procedure TTestXmiMidiByteReader.DovrebbeLeggereUnNumeroMidi;
var
  LReader: TXmiByteReader;
  LValue: UInt64;
begin
  // $81 $80 $00 = 1 shl 14, as in the specification of the standard MIDI file
  LReader := TXmiByteReader.Create(TBytes.Create($81, $80, $00, $7F), 0, 4);
  try
    Assert.AreEqual(Ord(TXmiVarLengthStatus.Complete), Ord(LReader.ReadMidiNumber(LValue)));
    Assert.AreEqual(UInt64(16384), LValue);
    Assert.AreEqual(Ord(TXmiVarLengthStatus.Complete), Ord(LReader.ReadMidiNumber(LValue)));
    Assert.AreEqual(UInt64(127), LValue);
    Assert.AreEqual(Ord(TXmiVarLengthStatus.EndOfData), Ord(LReader.ReadMidiNumber(LValue)));
    Assert.AreEqual(UInt64(0), LValue);
  finally
    LReader.Free;
  end;
end;

procedure TTestXmiMidiByteReader.DovrebbeSegnalareUnNumeroMidiDiPiuDi64Bit;
var
  LData: TBytes;
  LReader: TXmiByteReader;
  LValue: UInt64;
begin
  // Ten bytes with the high bit: the tenth would make 70 bits
  SetLength(LData, 11);
  FillChar(LData[0], 10, $FF);
  LData[10] := $01;
  LReader := TXmiByteReader.Create(LData, 0, Length(LData));
  try
    Assert.AreEqual(Ord(TXmiVarLengthStatus.Overflow), Ord(LReader.ReadMidiNumber(LValue)));
    Assert.AreEqual(1, LReader.Remaining);
  finally
    LReader.Free;
  end;
end;

procedure TTestXmiMidiByteReader.DovrebbeSegnalareUnNumeroMidiTroncato;
var
  LReader: TXmiByteReader;
  LValue: UInt64;
begin
  LReader := TXmiByteReader.Create(TBytes.Create($81, $82), 0, 2);
  try
    Assert.AreEqual(Ord(TXmiVarLengthStatus.EndOfData), Ord(LReader.ReadMidiNumber(LValue)));
  finally
    LReader.Free;
  end;
end;

procedure TTestXmiMidiByteReader.DovrebbeSommareLeAtteseXmi;
var
  LReader: TXmiByteReader;
  LValue: UInt64;
begin
  // 127 + 127 + 5, then a status that is not consumed, then a delay that ends the data
  LReader := TXmiByteReader.Create(TBytes.Create($7F, $7F, $05, $90, $7F), 0, 5);
  try
    Assert.AreEqual(Ord(TXmiVarLengthStatus.Complete), Ord(LReader.ReadXmiDelay(LValue)));
    Assert.AreEqual(UInt64(259), LValue);
    Assert.AreEqual(Ord(TXmiVarLengthStatus.Complete), Ord(LReader.ReadXmiDelay(LValue)));
    Assert.AreEqual(UInt64(0), LValue);
    Assert.AreEqual($90, Integer(LReader.ReadByte));
    Assert.AreEqual(Ord(TXmiVarLengthStatus.EndOfData), Ord(LReader.ReadXmiDelay(LValue)));
    Assert.AreEqual(Ord(TXmiVarLengthStatus.EndOfData), Ord(LReader.ReadXmiDelay(LValue)));
  finally
    LReader.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXmiMidiByteReader);

end.
