{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TTextureByteReader                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Texture.ByteReader;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Texture.ByteReader;

type
  [TestFixture]
  [Category('texture')]
  TTestTextureByteReader = class(TObject)
  private
    FReader: TTextureByteReader;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLeggereIByteInOrdine;
    [Test]
    procedure DovrebbeLeggereUnaParolaInLittleEndian;
    [Test]
    procedure DovrebbeDareZeroOltreLaFineERicordarlo;
    [Test]
    procedure DovrebbeDireQuantiByteCeranoDavvero;
    [Test]
    procedure DovrebbeRiposizionarsiConSeek;
    [Test]
    procedure DovrebbeLeggereUnBloccoDiByte;
    [Test]
    procedure DovrebbeRiportareLaPosizioneAnchePassandoLaFine;
  end;

implementation

procedure TTestTextureByteReader.Setup;
begin
  FReader := TTextureByteReader.Create(TBytes.Create(1, 2, 3, 4, 5));
end;

procedure TTestTextureByteReader.TearDown;
begin
  FReader.Free;
end;

procedure TTestTextureByteReader.DovrebbeLeggereIByteInOrdine;
begin
  Assert.AreEqual(Byte(1), FReader.ReadByte, 'dovrebbe leggere il primo byte');
  Assert.AreEqual(Byte(2), FReader.ReadByte, 'dovrebbe leggere il secondo byte');
  Assert.AreEqual(2, FReader.Position, 'dovrebbe avanzare di uno per byte');
end;

procedure TTestTextureByteReader.DovrebbeLeggereUnaParolaInLittleEndian;
begin
  Assert.AreEqual(Word($0201), FReader.ReadWord, 'dovrebbe mettere il primo byte nella parte bassa');
end;

procedure TTestTextureByteReader.DovrebbeDareZeroOltreLaFineERicordarlo;
var
  LIndex: Integer;
begin
  Assert.IsFalse(FReader.Overrun, 'non dovrebbe segnalare nulla all''inizio');
  for LIndex := 1 to 5 do
    FReader.ReadByte;
  Assert.IsFalse(FReader.Overrun, 'non dovrebbe segnalare nulla finche'' ci sono byte');
  Assert.AreEqual(Byte(0), FReader.ReadByte, 'dovrebbe dare zero oltre la fine');
  Assert.IsTrue(FReader.Overrun, 'dovrebbe ricordare che ha letto oltre la fine');
end;

procedure TTestTextureByteReader.DovrebbeDireQuantiByteCeranoDavvero;
var
  LBuffer: array[0..7] of Byte;
begin
  FillChar(LBuffer, SizeOf(LBuffer), $AA);
  Assert.AreEqual(5, FReader.Read(LBuffer, 8), 'dovrebbe dare i byte che c''erano');
  Assert.AreEqual(Byte(5), LBuffer[4], 'dovrebbe copiare i byte che ci sono');
  Assert.AreEqual(Byte(0), LBuffer[5], 'dovrebbe azzerare gli altri');
  Assert.AreEqual(Byte(0), LBuffer[7], 'dovrebbe azzerare fino alla fine del blocco');
end;

procedure TTestTextureByteReader.DovrebbeRiposizionarsiConSeek;
begin
  FReader.Seek(3);
  Assert.AreEqual(Byte(4), FReader.ReadByte, 'dovrebbe leggere dalla posizione richiesta');
  FReader.Seek(-5);
  Assert.AreEqual(0, FReader.Position, 'dovrebbe fermarsi all''inizio per una posizione negativa');
end;

procedure TTestTextureByteReader.DovrebbeLeggereUnBloccoDiByte;
var
  LBytes: TBytes;
begin
  LBytes := FReader.ReadBytes(7);
  Assert.AreEqual<Integer>(7, Length(LBytes), 'dovrebbe dare tanti byte quanti richiesti');
  Assert.AreEqual(Byte(5), LBytes[4], 'dovrebbe avere i byte del file');
  Assert.AreEqual(Byte(0), LBytes[6], 'dovrebbe avere zeri dopo');
  Assert.AreEqual<Integer>(0, Length(FReader.ReadBytes(-3)), 'dovrebbe dare un blocco vuoto per un numero negativo');
end;

procedure TTestTextureByteReader.DovrebbeRiportareLaPosizioneAnchePassandoLaFine;
begin
  FReader.ReadBytes(9);
  Assert.AreEqual(9, FReader.Position, 'dovrebbe avanzare anche quando i byte mancano');
  Assert.AreEqual(5, FReader.Size, 'dovrebbe dare la lunghezza del file');
end;

end.
