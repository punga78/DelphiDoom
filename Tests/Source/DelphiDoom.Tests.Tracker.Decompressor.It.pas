{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the IT sample decompressor of the tracker              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Tracker.Decompressor.It;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Tracker.Decompressor.It,
  DelphiDoom.Tracker.Types;

type
  [TestFixture]
  [Category('tracker')]
  TTestTrackerItDecompressor = class(TObject)
  private
    FBytes: TBytes;
    // Packs the codes into bits, least significant first, and puts the
    // size of the block in front
    function Pack(const ACodes: array of Integer; const AWidths: array of Integer): TBytes;
  public
    [Test]
    procedure TestOttoBitConLarghezzaNove;
    [Test]
    procedure TestSecondoOrdineDiIt215;
    [Test]
    procedure TestCambioDiLarghezza;
    [Test]
    procedure TestSedicibit;
    [Test]
    procedure TestBloccoTroncatoSollevaEccezione;
    [Test]
    procedure TestSenzaIlBloccoSollevaEccezione;
  end;

implementation

{ TTestTrackerItDecompressor }

function TTestTrackerItDecompressor.Pack(const ACodes: array of Integer;
  const AWidths: array of Integer): TBytes;
var
  LIndex, LBit, LTotalBits, LBlockSize: Integer;
begin
  LTotalBits := 0;
  for LIndex := 0 to High(AWidths) do
    Inc(LTotalBits, AWidths[LIndex]);
  LBlockSize := (LTotalBits + 7) div 8;
  SetLength(Result, 2 + LBlockSize);
  Result[0] := Byte(LBlockSize);
  Result[1] := Byte(LBlockSize shr 8);

  LTotalBits := 0;
  for LIndex := 0 to High(ACodes) do
  begin
    for LBit := 0 to AWidths[LIndex] - 1 do
    begin
      if ((ACodes[LIndex] shr LBit) and 1) <> 0 then
        Result[2 + LTotalBits div 8] := Result[2 + LTotalBits div 8] or (1 shl (LTotalBits mod 8));
      Inc(LTotalBits);
    end;
  end;
end;

procedure TTestTrackerItDecompressor.TestOttoBitConLarghezzaNove;
var
  LData: TArray<SmallInt>;
begin
  // Differences +5, +3 and -2 with the initial width of 9 bits
  LData := TTrackerItDecompressor.Unpack(Pack([5, 3, 254], [9, 9, 9]), 3, False, False);

  Assert.AreEqual(3, Length(LData));
  Assert.AreEqual(5 * 256, Integer(LData[0]));
  Assert.AreEqual(8 * 256, Integer(LData[1]));
  Assert.AreEqual(6 * 256, Integer(LData[2]));
end;

procedure TTestTrackerItDecompressor.TestSecondoOrdineDiIt215;
var
  LData: TArray<SmallInt>;
begin
  // The same differences: the sums of the sums are 5, 13 and 19
  LData := TTrackerItDecompressor.Unpack(Pack([5, 3, 254], [9, 9, 9]), 3, False, True);

  Assert.AreEqual(5 * 256, Integer(LData[0]));
  Assert.AreEqual(13 * 256, Integer(LData[1]));
  Assert.AreEqual(19 * 256, Integer(LData[2]));
end;

procedure TTestTrackerItDecompressor.TestCambioDiLarghezza;
var
  LData: TArray<SmallInt>;
begin
  // $105 at the width of 9 makes the width 6; then +3; then the code 32 (only
  // the top bit) at the width of 6 announces a width of 5 (read as 4 + 1);
  // then -1 in 5 bits
  LData := TTrackerItDecompressor.Unpack(Pack([$105, 3, 32, 4, 31], [9, 6, 6, 3, 5]), 2,
    False, False);

  Assert.AreEqual(3 * 256, Integer(LData[0]));
  Assert.AreEqual(2 * 256, Integer(LData[1]));
end;

procedure TTestTrackerItDecompressor.TestSedicibit;
var
  LData: TArray<SmallInt>;
begin
  // 16 bit samples start with a width of 17 bits
  LData := TTrackerItDecompressor.Unpack(Pack([1000, 24], [17, 17]), 2, True, False);

  Assert.AreEqual(1000, Integer(LData[0]));
  Assert.AreEqual(1024, Integer(LData[1]));
end;

procedure TTestTrackerItDecompressor.TestBloccoTroncatoSollevaEccezione;
begin
  FBytes := Pack([5, 3, 254], [9, 9, 9]);
  SetLength(FBytes, Length(FBytes) - 1);

  Assert.WillRaise(
    procedure
    begin
      TTrackerItDecompressor.Unpack(FBytes, 3, False, False);
    end, ETrackerException);
end;

procedure TTestTrackerItDecompressor.TestSenzaIlBloccoSollevaEccezione;
begin
  FBytes := nil;

  Assert.WillRaise(
    procedure
    begin
      TTrackerItDecompressor.Unpack(FBytes, 3, False, False);
    end, ETrackerException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestTrackerItDecompressor);

end.
