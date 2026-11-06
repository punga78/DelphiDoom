{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the math core library - the bounding boxes             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.BoundingBox;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  /// <summary>Parity with the old m_bbox (golden file boundingbox.golden.txt) and the cases by hand</summary>
  [TestFixture]
  [Category('mathcore')]
  TTestMathCoreBoundingBox = class(TObject)
  public
    [Test]
    procedure DovrebbeSvuotareLaScatolaCometClearBox;
    [Test]
    procedure DovrebbeSeguireLaSequenzaDelVecchioAddToBox;
    [Test]
    procedure DovrebbeAllargarsiAUnPuntoACuiSiAggiunge;
    [Test]
    procedure DovrebbeConservareIlDifettoDelPrimoPuntoDopoLaPulizia;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.MathCore.BoundingBox, DelphiDoom.Tests.MathCore.Golden,
  DelphiDoom.Tests.MathCore.Fingerprint, DelphiDoom.Tests.MathCore.Samples;

{ TTestMathCoreBoundingBox }

procedure TTestMathCoreBoundingBox.DovrebbeSvuotareLaScatolaCometClearBox;
var
  LBox: TBoundingBox;
begin
  TBoundingBoxMath.Clear(LBox);
  Assert.AreEqual(FIXED_MIN, LBox[BOX_TOP]);
  Assert.AreEqual(FIXED_MIN, LBox[BOX_RIGHT]);
  Assert.AreEqual(FIXED_MAX, LBox[BOX_BOTTOM]);
  Assert.AreEqual(FIXED_MAX, LBox[BOX_LEFT]);
end;

procedure TTestMathCoreBoundingBox.DovrebbeSeguireLaSequenzaDelVecchioAddToBox;
var
  LGolden: TGoldenFile;
  LFingerprint: TFingerprint;
  LFirst, LSecond: TArray<Integer>;
  LBox: TBoundingBox;
  LIndex, LSide: Integer;
begin
  LGolden := TGoldenFile.Create('boundingbox.golden.txt');
  LFingerprint := TFingerprint.Create;
  try
    TMathCoreSamples.BuildPairs(LFirst, LSecond);
    TBoundingBoxMath.Clear(LBox);
    for LSide := 0 to 3 do
      LFingerprint.AddInteger(LBox[LSide]);
    for LIndex := 0 to 3999 do
    begin
      if LIndex mod 500 = 499 then
      begin
        TBoundingBoxMath.Clear(LBox);
        for LSide := 0 to 3 do
          LFingerprint.AddInteger(LBox[LSide]);
      end;
      TBoundingBoxMath.AddPoint(LBox, LFirst[LIndex], LSecond[LIndex]);
      for LSide := 0 to 3 do
        LFingerprint.AddInteger(LBox[LSide]);
    end;
    LGolden.Check('box.sequence', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
    LGolden.Free;
  end;
end;

procedure TTestMathCoreBoundingBox.DovrebbeAllargarsiAUnPuntoACuiSiAggiunge;
var
  LBox: TBoundingBox;
begin
  LBox[BOX_TOP] := 10;
  LBox[BOX_BOTTOM] := 0;
  LBox[BOX_LEFT] := 0;
  LBox[BOX_RIGHT] := 10;
  TBoundingBoxMath.AddPoint(LBox, 20, -5);
  Assert.AreEqual(20, LBox[BOX_RIGHT]);
  Assert.AreEqual(-5, LBox[BOX_BOTTOM]);
  Assert.AreEqual(10, LBox[BOX_TOP]);
  Assert.AreEqual(0, LBox[BOX_LEFT]);
  TBoundingBoxMath.AddPoint(LBox, -3, 40);
  Assert.AreEqual(-3, LBox[BOX_LEFT]);
  Assert.AreEqual(40, LBox[BOX_TOP]);
end;

procedure TTestMathCoreBoundingBox.DovrebbeConservareIlDifettoDelPrimoPuntoDopoLaPulizia;
var
  LBox: TBoundingBox;
begin
  // as in the old code: the first point only sets left and bottom (it is an "else if")
  TBoundingBoxMath.Clear(LBox);
  TBoundingBoxMath.AddPoint(LBox, 5, 7);
  Assert.AreEqual(5, LBox[BOX_LEFT]);
  Assert.AreEqual(7, LBox[BOX_BOTTOM]);
  Assert.AreEqual(FIXED_MIN, LBox[BOX_RIGHT]);
  Assert.AreEqual(FIXED_MIN, LBox[BOX_TOP]);
end;

end.
