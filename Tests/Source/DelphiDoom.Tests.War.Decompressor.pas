{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the decompression                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.Decompressor;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Types, DelphiDoom.War.Decompressor,
  DelphiDoom.Tests.War.Builders;

type
  [TestFixture]
  [Category('war')]
  TTestWarDecompressor = class(TObject)
  public
    [Test]
    procedure DovrebbeDareUnBufferVuotoPerLunghezzaZero;
    [Test]
    procedure DovrebbeCopiareIByteLetterali;
    [Test]
    procedure DovrebbeRipetereUnByteCopiandoDallaFinestraMentreSiScrive;
    [Test]
    procedure DovrebbeLeggereZeriDallaFinestraAncoraVuota;
    [Test]
    procedure DovrebbeCopiareDallaFinestraDopoUnGiroDi4096Byte;
    [Test]
    procedure DovrebbeUsareIQuattroBitAltiComeLunghezzaMenoTre;
    [Test]
    procedure DovrebbeFermarsiAllaLunghezzaDichiarata;
    [Test]
    procedure DovrebbeFermarsiAllaLunghezzaDentroUnaCopia;
    [Test]
    procedure DovrebbeLeggereUnaMascheraPerOgniOttoElementi;
    [Test]
    procedure DovrebbeRifiutareDatiCheFinisconoPrima;
    [Test]
    procedure DovrebbeRifiutareUnaCopiaSenzaIDueByte;
    [Test]
    procedure DovrebbeRifiutareUnaLunghezzaImpossibile;
    [Test]
    procedure DovrebbeRifiutareUnLetteraleSenzaIlByte;
  end;

implementation

function Expand(const APayload: TBytes; ALength: Cardinal): TBytes;
begin
  Result := TWarDecompressor.Expand(APayload, ALength, 7);
end;

{ TTestWarDecompressor }

procedure TTestWarDecompressor.DovrebbeDareUnBufferVuotoPerLunghezzaZero;
begin
  Assert.AreEqual(0, Length(Expand(nil, 0)));
end;

procedure TTestWarDecompressor.DovrebbeCopiareIByteLetterali;
var
  LWriter: TWarTokenWriter;
  LResult: TBytes;
begin
  LWriter := TWarTokenWriter.Create;
  try
    LWriter.Literal(Ord('W'));
    LWriter.Literal(Ord('A'));
    LWriter.Literal(Ord('R'));
    LResult := Expand(LWriter.ToBytes, 3);
  finally
    LWriter.Free;
  end;
  Assert.AreEqual(3, Length(LResult));
  Assert.AreEqual(Integer(Ord('W')), Integer(LResult[0]));
  Assert.AreEqual(Integer(Ord('A')), Integer(LResult[1]));
  Assert.AreEqual(Integer(Ord('R')), Integer(LResult[2]));
end;

procedure TTestWarDecompressor.DovrebbeRipetereUnByteCopiandoDallaFinestraMentreSiScrive;
var
  LWriter: TWarTokenWriter;
  LResult: TBytes;
  LIndex: Integer;
begin
  // la copia legge la posizione che ha appena scritto: da una A ne escono sei
  LWriter := TWarTokenWriter.Create;
  try
    LWriter.Literal(Ord('A'));
    LWriter.Copy(0, 5);
    LResult := Expand(LWriter.ToBytes, 6);
  finally
    LWriter.Free;
  end;
  Assert.AreEqual(6, Length(LResult));
  for LIndex := 0 to 5 do
    Assert.AreEqual(Integer(Ord('A')), Integer(LResult[LIndex]));
end;

procedure TTestWarDecompressor.DovrebbeLeggereZeriDallaFinestraAncoraVuota;
var
  LWriter: TWarTokenWriter;
  LResult: TBytes;
begin
  LWriter := TWarTokenWriter.Create;
  try
    LWriter.Copy(100, 3);
    LResult := Expand(LWriter.ToBytes, 3);
  finally
    LWriter.Free;
  end;
  Assert.AreEqual(3, Length(LResult));
  Assert.AreEqual(0, Integer(LResult[0]) + Integer(LResult[1]) + Integer(LResult[2]));
end;

procedure TTestWarDecompressor.DovrebbeCopiareDallaFinestraDopoUnGiroDi4096Byte;
var
  LWriter: TWarTokenWriter;
  LResult: TBytes;
  LIndex: Integer;
begin
  LWriter := TWarTokenWriter.Create;
  try
    for LIndex := 0 to 4099 do
      LWriter.Literal(Byte(LIndex mod 251));
    // la finestra ha i byte 4098 e 4099 nelle posizioni 2 e 3
    LWriter.Copy(2, 3);
    LResult := Expand(LWriter.ToBytes, 4103);
  finally
    LWriter.Free;
  end;
  Assert.AreEqual(4103, Length(LResult));
  Assert.AreEqual(Integer(4098 mod 251), Integer(LResult[4100]));
  Assert.AreEqual(Integer(4099 mod 251), Integer(LResult[4101]));
  // la terza lettura e' la posizione 4, che la prima scrittura (4100 mod 4096) ha gia' sostituito
  Assert.AreEqual(Integer(4098 mod 251), Integer(LResult[4102]));
end;

procedure TTestWarDecompressor.DovrebbeUsareIQuattroBitAltiComeLunghezzaMenoTre;
var
  LWriter: TWarTokenWriter;
  LResult: TBytes;
begin
  LWriter := TWarTokenWriter.Create;
  try
    LWriter.Literal(7);
    LWriter.Copy(0, 18);
    LResult := Expand(LWriter.ToBytes, 19);
  finally
    LWriter.Free;
  end;
  Assert.AreEqual(19, Length(LResult));
  Assert.AreEqual(Integer(7), Integer(LResult[18]));
end;

procedure TTestWarDecompressor.DovrebbeFermarsiAllaLunghezzaDichiarata;
var
  LWriter: TWarTokenWriter;
  LResult: TBytes;
begin
  LWriter := TWarTokenWriter.Create;
  try
    LWriter.Literal(1);
    LWriter.Literal(2);
    LWriter.Literal(3);
    LResult := Expand(LWriter.ToBytes, 2);
  finally
    LWriter.Free;
  end;
  Assert.AreEqual(2, Length(LResult));
end;

procedure TTestWarDecompressor.DovrebbeFermarsiAllaLunghezzaDentroUnaCopia;
var
  LWriter: TWarTokenWriter;
  LResult: TBytes;
begin
  LWriter := TWarTokenWriter.Create;
  try
    LWriter.Literal(9);
    LWriter.Copy(0, 18);
    LResult := Expand(LWriter.ToBytes, 4);
  finally
    LWriter.Free;
  end;
  Assert.AreEqual(4, Length(LResult));
  Assert.AreEqual(Integer(9), Integer(LResult[3]));
end;

procedure TTestWarDecompressor.DovrebbeLeggereUnaMascheraPerOgniOttoElementi;
var
  LWriter: TWarTokenWriter;
  LPayload: TBytes;
  LResult: TBytes;
  LIndex: Integer;
begin
  LWriter := TWarTokenWriter.Create;
  try
    for LIndex := 0 to 19 do
      LWriter.Literal(Byte(LIndex + 1));
    LPayload := LWriter.ToBytes;
  finally
    LWriter.Free;
  end;
  // 20 letterali: 3 maschere e 20 byte
  Assert.AreEqual(23, Length(LPayload));
  LResult := Expand(LPayload, 20);
  for LIndex := 0 to 19 do
    Assert.AreEqual(LIndex + 1, Integer(LResult[LIndex]));
end;

procedure TTestWarDecompressor.DovrebbeRifiutareDatiCheFinisconoPrima;
var
  LWriter: TWarTokenWriter;
  LPayload: TBytes;
begin
  LWriter := TWarTokenWriter.Create;
  try
    LWriter.Literal(1);
    LPayload := LWriter.ToBytes;
  finally
    LWriter.Free;
  end;
  Assert.WillRaise(
    procedure
    begin
      Expand(LPayload, 5);
    end, EWarException);
end;

procedure TTestWarDecompressor.DovrebbeRifiutareUnaCopiaSenzaIDueByte;
begin
  // maschera 0 (una copia) e un solo byte
  Assert.WillRaise(
    procedure
    begin
      Expand(TBytes.Create(0, 5), 3);
    end, EWarException);
end;

procedure TTestWarDecompressor.DovrebbeRifiutareUnLetteraleSenzaIlByte;
begin
  Assert.WillRaise(
    procedure
    begin
      Expand(TBytes.Create(1), 1);
    end, EWarException);
end;

procedure TTestWarDecompressor.DovrebbeRifiutareUnaLunghezzaImpossibile;
begin
  // 3 byte di dati non possono dare 100000 byte (il massimo e' 2049 per byte): niente allocazione enorme
  Assert.WillRaise(
    procedure
    begin
      Expand(TBytes.Create(1, 1, 1), 100000);
    end, EWarException);
end;

end.
