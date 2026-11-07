{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TJpegSlowInverseDct                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.SlowInverseDct;

interface

uses
  System.SysUtils, System.Math, DUnitX.TestFramework, DelphiDoom.Jpeg.InverseDct,
  DelphiDoom.Jpeg.Types;

type
  [TestFixture]
  [Category('jpeg')]
  TTestJpegSlowInverseDct = class(TObject)
  private
    FDct: IJpegInverseDct;
    FQuantization: array[0..63] of Integer;
    FBlock: TJpegBlock;
    FOutput: array[0..8 * 12 - 1] of Byte;
    procedure Transform;
    function Reference(AX, AY: Integer): Double;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestEmptyBlockIsMidGray;
    [Test]
    procedure TestOnlyTheDcGivesAFlatBlock;
    [Test]
    procedure TestSamplesAreLimitedTo0And255;
    [Test]
    procedure TestQuantizationMultipliesTheCoefficients;
    [Test]
    procedure TestAgreesWithTheDefinitionOfTheTransform;
    [Test]
    procedure TestWritesRowsAtTheStrideAndNothingElse;
  end;

implementation

uses
  DelphiDoom.Jpeg.SlowInverseDct, DelphiDoom.Tests.Jpeg.Random;

{ TTestJpegSlowInverseDct }

procedure TTestJpegSlowInverseDct.Setup;
var
  LIndex: Integer;
begin
  FDct := TJpegSlowInverseDct.Create;
  for LIndex := 0 to 63 do
  begin
    FQuantization[LIndex] := 1;
    FBlock[LIndex] := 0;
  end;
  FillChar(FOutput, SizeOf(FOutput), $77);
end;

procedure TTestJpegSlowInverseDct.Transform;
begin
  FDct.Transform(FBlock, FQuantization, @FOutput[0], 12);
end;

function TTestJpegSlowInverseDct.Reference(AX, AY: Integer): Double;
var
  LU, LV: Integer;
  LCu, LCv: Double;
begin
  Result := 0;
  for LV := 0 to 7 do
    for LU := 0 to 7 do
    begin
      if LU = 0 then
        LCu := Sqrt(0.5)
      else
        LCu := 1;
      if LV = 0 then
        LCv := Sqrt(0.5)
      else
        LCv := 1;
      Result := Result + LCu * LCv * FBlock[LV * 8 + LU] * FQuantization[LV * 8 + LU] *
        Cos((2 * AX + 1) * LU * Pi / 16) * Cos((2 * AY + 1) * LV * Pi / 16);
    end;
  Result := Result / 4 + 128;
end;

procedure TTestJpegSlowInverseDct.TestEmptyBlockIsMidGray;
var
  LRow, LColumn: Integer;
begin
  Transform;
  for LRow := 0 to 7 do
    for LColumn := 0 to 7 do
      Assert.AreEqual(128, Integer(FOutput[LRow * 12 + LColumn]));
end;

procedure TTestJpegSlowInverseDct.TestOnlyTheDcGivesAFlatBlock;
var
  LRow, LColumn: Integer;
begin
  // A DC of 80 is 10 more than the middle: 80 / 8
  FBlock[0] := 80;
  Transform;
  for LRow := 0 to 7 do
    for LColumn := 0 to 7 do
      Assert.AreEqual(138, Integer(FOutput[LRow * 12 + LColumn]));

  FBlock[0] := -83;
  Transform;
  Assert.AreEqual(118, Integer(FOutput[0]));
end;

procedure TTestJpegSlowInverseDct.TestSamplesAreLimitedTo0And255;
begin
  FBlock[0] := 4000;
  Transform;
  Assert.AreEqual(255, Integer(FOutput[3]));
  FBlock[0] := -4000;
  Transform;
  Assert.AreEqual(0, Integer(FOutput[3]));
end;

procedure TTestJpegSlowInverseDct.TestQuantizationMultipliesTheCoefficients;
begin
  FBlock[0] := 10;
  FQuantization[0] := 8;
  Transform;
  Assert.AreEqual(138, Integer(FOutput[0]));
end;

procedure TTestJpegSlowInverseDct.TestAgreesWithTheDefinitionOfTheTransform;
var
  LRandom: TJpegRandom;
  LRound: Integer;
  LIndex: Integer;
  LRow, LColumn: Integer;
  LExpected: Double;
begin
  // The integer algorithm differs from the real one by at most one level
  LRandom := TJpegRandom.Create(5);
  for LRound := 1 to 200 do
  begin
    for LIndex := 0 to 63 do
    begin
      FQuantization[LIndex] := LRandom.Between(1, 12);
      if LRandom.Chance(40) then
        FBlock[LIndex] := LRandom.Between(-12, 12)
      else
        FBlock[LIndex] := 0;
    end;
    FBlock[0] := LRandom.Between(-30, 30);
    Transform;
    for LRow := 0 to 7 do
      for LColumn := 0 to 7 do
      begin
        LExpected := Reference(LColumn, LRow);
        if LExpected < 0 then
          LExpected := 0
        else if LExpected > 255 then
          LExpected := 255;
        Assert.IsTrue(Abs(FOutput[LRow * 12 + LColumn] - LExpected) <= 1.0,
          Format('Round %d, sample %d,%d: %d instead of %f', [LRound, LColumn, LRow,
          FOutput[LRow * 12 + LColumn], LExpected]));
      end;
  end;
end;

procedure TTestJpegSlowInverseDct.TestWritesRowsAtTheStrideAndNothingElse;
var
  LRow, LColumn: Integer;
begin
  FBlock[0] := 16;
  Transform;
  for LRow := 0 to 7 do
    for LColumn := 8 to 11 do
      Assert.AreEqual($77, Integer(FOutput[LRow * 12 + LColumn]), 'Outside of the block');
end;

end.
