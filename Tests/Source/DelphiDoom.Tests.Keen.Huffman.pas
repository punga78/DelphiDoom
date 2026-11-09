{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - Huffman expansion                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.Huffman;

{$Q-}{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenHuffman = class(TObject)
  private
    function SmallDictionary: TBytes;
  public
    /// <summary>A dictionary written by hand: A = 0, B = 10, C = 11, the first bit is the lowest of the byte</summary>
    [Test]
    procedure DovrebbeLeggereIBitDalMenoSignificativo;
    [Test]
    procedure DovrebbeRipartireDallaTestaDopoOgniByte;
    [Test]
    procedure DovrebbeRiprodurreIDatiCodificatiConPesiCasuali;
    [Test]
    procedure DovrebbeLeggereDaUnOffsetDelBuffer;
    [Test]
    procedure DovrebbeDareUnaRispostaVuotaPerLunghezzaZero;
    [Test]
    procedure DovrebbeAccettareUnaFineSullUltimoBitDelByte;
    [Test]
    procedure DovrebbeDareQuelloCheICodiciDannoQuandoSiAmmetteLaFineAnticipata;
    [Test]
    procedure DovrebbeDareSoloZeriSeIlBufferEFinitoPrimaDellInizio;
    [Test]
    procedure DovrebbeRifiutareUnOffsetNegativoAncheSeSiAmmetteLaFineAnticipata;
    [Test]
    procedure DovrebbeRifiutareDatiTroncati;
    [Test]
    procedure DovrebbeRifiutareUnOffsetFuoriDalBuffer;
    [Test]
    procedure DovrebbeRifiutareUnaLunghezzaNegativa;
    [Test]
    procedure DovrebbeRifiutareUnDizionarioTroppoCorto;
    [Test]
    procedure DovrebbeRifiutareUnNodoFuoriDalDizionario;
    [Test]
    procedure DovrebbeAccettareUnDizionarioDi1020Byte;
  end;

implementation

uses
  DelphiDoom.Keen.Factory, DelphiDoom.Tests.Keen.Builders;

function Hex(const ABytes: TBytes): string;
var
  LByte: Byte;
begin
  Result := '';
  for LByte in ABytes do
    Result := Result + IntToHex(LByte, 2);
end;

procedure SetNode(var ADictionary: TBytes; ANode, ABit0, ABit1: Integer);
begin
  ADictionary[ANode * 4] := Byte(ABit0);
  ADictionary[ANode * 4 + 1] := Byte(ABit0 shr 8);
  ADictionary[ANode * 4 + 2] := Byte(ABit1);
  ADictionary[ANode * 4 + 3] := Byte(ABit1 shr 8);
end;

{ TTestKeenHuffman }

function TTestKeenHuffman.SmallDictionary: TBytes;
begin
  SetLength(Result, 1024);
  FillChar(Result[0], Length(Result), 0);
  // head: 0 -> 'A', 1 -> node 0; node 0: 0 -> 'B', 1 -> 'C'
  SetNode(Result, KEEN_HUFF_HEAD, Ord('A'), 256 + 0);
  SetNode(Result, 0, Ord('B'), Ord('C'));
end;

procedure TTestKeenHuffman.DovrebbeLeggereIBitDalMenoSignificativo;
var
  LHuffman: IKeenHuffman;
  LResult: TBytes;
begin
  LHuffman := TKeenFactory.CreateHuffman(SmallDictionary);
  // A B C A = 0 | 1 0 | 1 1 | 0 = bits 0..5 of the byte: 0,1,0,1,1,0 = $1A
  LResult := LHuffman.Expand(TBytes.Create($1A), 0, 4);
  Assert.AreEqual('ABCA', TEncoding.ASCII.GetString(LResult));
end;

procedure TTestKeenHuffman.DovrebbeRipartireDallaTestaDopoOgniByte;
var
  LHuffman: IKeenHuffman;
  LResult: TBytes;
begin
  LHuffman := TKeenFactory.CreateHuffman(SmallDictionary);
  // eight zeros are 8 times A, over the end of a byte the next byte goes on: 0xFF = 1 1 -> C, 4 times
  LResult := LHuffman.Expand(TBytes.Create($00, $FF), 0, 12);
  Assert.AreEqual('AAAAAAAACCCC', TEncoding.ASCII.GetString(LResult));
end;

procedure TTestKeenHuffman.DovrebbeRiprodurreIDatiCodificatiConPesiCasuali;
var
  LSeed: Integer;
  LLength: Integer;
  LCode: TTestHuffmanCode;
  LPlain: TBytes;
  LIndex: Integer;
  LHuffman: IKeenHuffman;
  LState: Cardinal;
begin
  LState := 99;
  for LSeed := 1 to 12 do
  begin
    LCode := TTestHuffmanCode.Create(LSeed);
    try
      LHuffman := TKeenFactory.CreateHuffman(LCode.Dictionary);
      for LLength in [1, 2, 7, 255, 256, 1000, 5000] do
      begin
        SetLength(LPlain, LLength);
        for LIndex := 0 to LLength - 1 do
        begin
          LState := LState * 1664525 + 1013904223;
          LPlain[LIndex] := Byte(LState shr 24);
        end;
        Assert.AreEqual(Hex(LPlain), Hex(LHuffman.Expand(LCode.Encode(LPlain), 0, LLength)),
          Format('seed %d, %d byte', [LSeed, LLength]));
      end;
    finally
      LCode.Free;
    end;
  end;
end;

procedure TTestKeenHuffman.DovrebbeLeggereDaUnOffsetDelBuffer;
var
  LHuffman: IKeenHuffman;
begin
  LHuffman := TKeenFactory.CreateHuffman(SmallDictionary);
  Assert.AreEqual('ABCA', TEncoding.ASCII.GetString(LHuffman.Expand(TBytes.Create($77, $77, $1A), 2, 4)));
end;

procedure TTestKeenHuffman.DovrebbeDareUnaRispostaVuotaPerLunghezzaZero;
begin
  Assert.AreEqual(0, Length(TKeenFactory.CreateHuffman(SmallDictionary).Expand(nil, 0, 0)));
end;

procedure TTestKeenHuffman.DovrebbeAccettareUnaFineSullUltimoBitDelByte;
var
  LHuffman: IKeenHuffman;
begin
  LHuffman := TKeenFactory.CreateHuffman(SmallDictionary);
  // 8 times A fill the byte: no other byte is needed (the C loads one more, and does not use it)
  Assert.AreEqual('AAAAAAAA', TEncoding.ASCII.GetString(LHuffman.Expand(TBytes.Create($00), 0, 8)));
end;

procedure TTestKeenHuffman.DovrebbeDareQuelloCheICodiciDannoQuandoSiAmmetteLaFineAnticipata;
var
  LResult: TBytes;
begin
  // $1A = A B C A and then the two padding bits (0, 0): two more A; the 4 bytes that the data cannot give are zero
  LResult := TKeenFactory.CreateHuffman(SmallDictionary).ExpandAvailable(TBytes.Create($1A), 0, 10);
  Assert.AreEqual(10, Length(LResult));
  Assert.AreEqual('ABCAAA', TEncoding.ASCII.GetString(Copy(LResult, 0, 6)));
  Assert.AreEqual(0, Integer(LResult[6]));
  Assert.AreEqual(0, Integer(LResult[9]));
end;

procedure TTestKeenHuffman.DovrebbeDareSoloZeriSeIlBufferEFinitoPrimaDellInizio;
var
  LResult: TBytes;
begin
  LResult := TKeenFactory.CreateHuffman(SmallDictionary).ExpandAvailable(TBytes.Create($1A), 1, 3);
  Assert.AreEqual(3, Length(LResult));
  Assert.AreEqual(0, Integer(LResult[0]) + Integer(LResult[1]) + Integer(LResult[2]));
end;

procedure TTestKeenHuffman.DovrebbeRifiutareUnOffsetNegativoAncheSeSiAmmetteLaFineAnticipata;
begin
  Assert.WillRaise(
    procedure
    begin
      TKeenFactory.CreateHuffman(SmallDictionary).ExpandAvailable(TBytes.Create($1A), -1, 3);
    end, EKeenDataException);
end;

procedure TTestKeenHuffman.DovrebbeRifiutareDatiTroncati;
var
  LHuffman: IKeenHuffman;
begin
  LHuffman := TKeenFactory.CreateHuffman(SmallDictionary);
  Assert.WillRaise(
    procedure
    begin
      LHuffman.Expand(TBytes.Create($00), 0, 9);
    end, EKeenDataException);
end;

procedure TTestKeenHuffman.DovrebbeRifiutareUnOffsetFuoriDalBuffer;
var
  LHuffman: IKeenHuffman;
begin
  LHuffman := TKeenFactory.CreateHuffman(SmallDictionary);
  Assert.WillRaise(
    procedure
    begin
      LHuffman.Expand(TBytes.Create($00), 1, 1);
    end, EKeenDataException);
  Assert.WillRaise(
    procedure
    begin
      LHuffman.Expand(TBytes.Create($00), -1, 1);
    end, EKeenDataException);
end;

procedure TTestKeenHuffman.DovrebbeRifiutareUnaLunghezzaNegativa;
var
  LHuffman: IKeenHuffman;
begin
  LHuffman := TKeenFactory.CreateHuffman(SmallDictionary);
  Assert.WillRaise(
    procedure
    begin
      LHuffman.Expand(TBytes.Create($00), 0, -1);
    end, EKeenDataException);
end;

procedure TTestKeenHuffman.DovrebbeRifiutareUnDizionarioTroppoCorto;
begin
  Assert.WillRaise(
    procedure
    begin
      TKeenFactory.CreateHuffman(Copy(SmallDictionary, 0, 1019));
    end, EKeenDataException);
end;

procedure TTestKeenHuffman.DovrebbeRifiutareUnNodoFuoriDalDizionario;
var
  LDictionary: TBytes;
begin
  LDictionary := SmallDictionary;
  // 256 + 255 would be the node 255: there are only 255 nodes (0..254)
  SetNode(LDictionary, 7, 0, 256 + 255);
  Assert.WillRaise(
    procedure
    begin
      TKeenFactory.CreateHuffman(LDictionary);
    end, EKeenDataException);
end;

procedure TTestKeenHuffman.DovrebbeAccettareUnDizionarioDi1020Byte;
var
  LHuffman: IKeenHuffman;
begin
  LHuffman := TKeenFactory.CreateHuffman(Copy(SmallDictionary, 0, 1020));
  Assert.AreEqual('ABCA', TEncoding.ASCII.GetString(LHuffman.Expand(TBytes.Create($1A), 0, 4)));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenHuffman);

end.
