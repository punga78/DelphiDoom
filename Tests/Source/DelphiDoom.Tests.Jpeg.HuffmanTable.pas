{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TJpegHuffmanTable                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.HuffmanTable;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Jpeg.Types;

type
  [TestFixture]
  [Category('jpeg')]
  TTestJpegHuffmanTable = class(TObject)
  private
    function Definition(const ABits: array of Byte; const AValues: array of Byte): TJpegHuffmanDefinition;
    function StandardDc: TJpegHuffmanDefinition;
  public
    [Test]
    procedure TestShortCodesAreInTheLookTable;
    [Test]
    procedure TestLongCodesAreNotInTheLookTable;
    [Test]
    procedure TestMaxCodeOfLengthsWithoutCodesIsMinusOne;
    [Test]
    procedure TestMaxCodeOfSeventeenBitsStopsTheSearch;
    [Test]
    procedure TestSymbolOfFindsTheSymbolOfALongCode;
    [Test]
    procedure TestMoreThan256CodesAreRefused;
    [Test]
    procedure TestMoreCodesThanTheLengthHasAreRefused;
    [Test]
    procedure TestDcSymbolsAboveFifteenAreRefused;
    [Test]
    procedure TestAcSymbolsAboveFifteenAreAccepted;
    [Test]
    procedure TestAnEmptyTableIsAccepted;
  end;

implementation

uses
  DelphiDoom.Jpeg.HuffmanTable;

{ TTestJpegHuffmanTable }

function TTestJpegHuffmanTable.Definition(const ABits: array of Byte;
  const AValues: array of Byte): TJpegHuffmanDefinition;
var
  LIndex: Integer;
begin
  Result := Default(TJpegHuffmanDefinition);
  Result.Defined := True;
  for LIndex := 0 to High(ABits) do
    Result.Bits[LIndex + 1] := ABits[LIndex];
  for LIndex := 0 to High(AValues) do
    Result.Values[LIndex] := AValues[LIndex];
end;

function TTestJpegHuffmanTable.StandardDc: TJpegHuffmanDefinition;
begin
  // The DC table for the luminance of annex K: 00 is 0; 010 to 110 are 1 to 5;
  // then 1110, 11110, ... are 6 to 11
  Result := Definition([0, 1, 5, 1, 1, 1, 1, 1, 1],
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]);
end;

procedure TTestJpegHuffmanTable.TestShortCodesAreInTheLookTable;
var
  LTable: TJpegHuffmanTable;
begin
  LTable := TJpegHuffmanTable.Create(StandardDc, True);
  try
    // 00xxxxxx is the symbol 0 in 2 bits
    Assert.AreEqual(2, LTable.LookBits($00));
    Assert.AreEqual(0, LTable.LookSymbol($3F));
    // 011xxxxx is the symbol 2 in 3 bits, 110xxxxx is the symbol 5
    Assert.AreEqual(3, LTable.LookBits($60));
    Assert.AreEqual(2, LTable.LookSymbol($7F));
    Assert.AreEqual(5, LTable.LookSymbol($C0));
    // 1110xxxx is the symbol 6 in 4 bits
    Assert.AreEqual(4, LTable.LookBits($E0));
    Assert.AreEqual(6, LTable.LookSymbol($EF));
  finally
    LTable.Free;
  end;
end;

procedure TTestJpegHuffmanTable.TestLongCodesAreNotInTheLookTable;
var
  LTable: TJpegHuffmanTable;
begin
  // 111111110 is the symbol 11 in 9 bits, so no 8 bits give it
  LTable := TJpegHuffmanTable.Create(StandardDc, True);
  try
    Assert.AreEqual(0, LTable.LookBits($FF));
  finally
    LTable.Free;
  end;
end;

procedure TTestJpegHuffmanTable.TestMaxCodeOfLengthsWithoutCodesIsMinusOne;
var
  LTable: TJpegHuffmanTable;
begin
  LTable := TJpegHuffmanTable.Create(StandardDc, True);
  try
    Assert.AreEqual(-1, LTable.MaxCode(1));
    Assert.AreEqual(0, LTable.MaxCode(2));
    Assert.AreEqual(6, LTable.MaxCode(3));
    Assert.AreEqual(-1, LTable.MaxCode(10));
  finally
    LTable.Free;
  end;
end;

procedure TTestJpegHuffmanTable.TestMaxCodeOfSeventeenBitsStopsTheSearch;
var
  LTable: TJpegHuffmanTable;
begin
  LTable := TJpegHuffmanTable.Create(StandardDc, True);
  try
    Assert.AreEqual($FFFFF, LTable.MaxCode(17));
  finally
    LTable.Free;
  end;
end;

procedure TTestJpegHuffmanTable.TestSymbolOfFindsTheSymbolOfALongCode;
var
  LTable: TJpegHuffmanTable;
begin
  // The last symbol (11) has the code 111111110 of 9 bits: 510
  LTable := TJpegHuffmanTable.Create(StandardDc, True);
  try
    Assert.AreEqual(11, LTable.SymbolOf(9, 510));
    Assert.AreEqual(10, LTable.SymbolOf(8, 254));
  finally
    LTable.Free;
  end;
end;

procedure TTestJpegHuffmanTable.TestMoreThan256CodesAreRefused;
var
  LDefinition: TJpegHuffmanDefinition;
begin
  LDefinition := Definition([0, 0, 0, 0, 0, 0, 0, 200, 100], []);
  Assert.WillRaise(
    procedure
    begin
      TJpegHuffmanTable.Create(LDefinition, False).Free;
    end, EJpegDecodeException);
end;

procedure TTestJpegHuffmanTable.TestMoreCodesThanTheLengthHasAreRefused;
var
  LDefinition: TJpegHuffmanDefinition;
begin
  // Three codes of one bit do not exist
  LDefinition := Definition([3], [1, 2, 3]);
  Assert.WillRaise(
    procedure
    begin
      TJpegHuffmanTable.Create(LDefinition, False).Free;
    end, EJpegDecodeException);
end;

procedure TTestJpegHuffmanTable.TestDcSymbolsAboveFifteenAreRefused;
var
  LDefinition: TJpegHuffmanDefinition;
begin
  LDefinition := Definition([1], [16]);
  Assert.WillRaise(
    procedure
    begin
      TJpegHuffmanTable.Create(LDefinition, True).Free;
    end, EJpegDecodeException);
end;

procedure TTestJpegHuffmanTable.TestAcSymbolsAboveFifteenAreAccepted;
var
  LTable: TJpegHuffmanTable;
begin
  LTable := TJpegHuffmanTable.Create(Definition([1], [$F0]), False);
  try
    Assert.AreEqual($F0, LTable.LookSymbol($00));
  finally
    LTable.Free;
  end;
end;

procedure TTestJpegHuffmanTable.TestAnEmptyTableIsAccepted;
var
  LTable: TJpegHuffmanTable;
begin
  LTable := TJpegHuffmanTable.Create(Definition([], []), False);
  try
    Assert.AreEqual(0, LTable.LookBits($00));
    Assert.AreEqual(-1, LTable.MaxCode(5));
  finally
    LTable.Free;
  end;
end;

end.
