{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TImagingWallScale                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Imaging.WallScale;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Imaging.Types, DelphiDoom.Imaging.Intf,
  DelphiDoom.Imaging.WallScale, DelphiDoom.Imaging.Factory, DelphiDoom.Tests.Imaging.Samples,
  DelphiDoom.Tests.Imaging.Golden;

type
  /// <summary>A table that gives always the same sine</summary>
  TConstantSineTable = class(TInterfacedObject, IImagingSineTable)
  private
    FValue: Integer;
  public
    constructor Create(AValue: Integer);
    function Sine(AIndex: Integer): Integer;
  end;

  [TestFixture]
  [Category('imaging')]
  TTestImagingWallScale = class(TObject)
  private
    function Context(ADistance, AProjection, AMaxScale: Integer; APrecise: Boolean): TImagingScaleContext;
    function ScaleWith(ASine: Integer): IImagingWallScale;
    procedure CheckDoubles(const ADoubles: TBytes);
  public
    [Test]
    procedure TestScalesMatchTheOldCode;
    [Test]
    procedure TestFixedScaleIsTheQuotientOfProjectionAndDistance;
    [Test]
    procedure TestScaleBelowTheMinimumGives256AndOverflows;
    [Test]
    procedure TestScaleAboveTheMaximumGivesTheMaximumAndOverflows;
    [Test]
    procedure TestNoOverflowFlagWhenNotPrecise;
    [Test]
    procedure TestCloseWallGivesTheMaximum;
    [Test]
    procedure TestFixedAndFlaggedScalesAgree;
    [Test]
    procedure TestDoubleScaleWithZeroDenominatorGivesTheMaximum;
    [Test]
    procedure TestDoubleScaleWithZeroDenominatorAndNegativeNumeratorGivesTheMinimum;
    [Test]
    procedure TestDoubleScaleIsLimited;
    [Test]
    procedure TestSineIndexOutOfTheTableIsNotRead;
  end;

implementation

{ TConstantSineTable }

constructor TConstantSineTable.Create(AValue: Integer);
begin
  inherited Create;
  FValue := AValue;
end;

function TConstantSineTable.Sine(AIndex: Integer): Integer;
begin
  Result := FValue;
end;

{ TTestImagingWallScale }

function TTestImagingWallScale.Context(ADistance, AProjection, AMaxScale: Integer;
  APrecise: Boolean): TImagingScaleContext;
begin
  Result.ViewAngle := 0;
  Result.NormalAngle := 0;
  Result.Distance := ADistance;
  Result.ProjectionY := AProjection;
  Result.MaxScale := AMaxScale;
  Result.PreciseOverflow := APrecise;
end;

function TTestImagingWallScale.ScaleWith(ASine: Integer): IImagingWallScale;
begin
  Result := TImagingWallScale.Create(TConstantSineTable.Create(ASine));
end;

procedure TTestImagingWallScale.TestScalesMatchTheOldCode;
var
  LScale: IImagingWallScale;
  LCases: TArray<TSampleScaleCase>;
  LCase: TSampleScaleCase;
  LContext: TImagingScaleContext;
  LInts: TArray<Integer>;
  LDoubles: TBytes;
  LOverflow: Boolean;
  LDouble: Double;
  LIndex: Integer;
begin
  LScale := TImagingFactory.CreateWallScale;
  LCases := TImagingSamples.ScaleCases;
  SetLength(LDoubles, Length(LCases) * 8);
  for LIndex := 0 to High(LCases) do
  begin
    LCase := LCases[LIndex];
    LContext.ViewAngle := LCase.ViewAngle;
    LContext.NormalAngle := LCase.NormalAngle;
    LContext.Distance := LCase.Distance;
    LContext.ProjectionY := LCase.ProjectionY;
    LContext.MaxScale := LCase.MaxScale;
    LContext.PreciseOverflow := LCase.Precise;
    SetLength(LInts, Length(LInts) + 3);
    LInts[High(LInts) - 2] := LScale.FromGlobalAngle(LContext, LCase.VisAngle, LOverflow);
    LInts[High(LInts) - 1] := Ord(LOverflow);
    LInts[High(LInts)] := LScale.FromGlobalAngleFixed(LContext, LCase.VisAngle);
    LDouble := LScale.FromGlobalAngleDouble(LContext, LCase.VisAngle);
    Move(LDouble, LDoubles[LIndex * 8], 8);
  end;
  TImagingGolden.Check('scale.golden.txt', 'scale_ints', TImagingSamples.Hex(TImagingSamples.Hash(LInts)));
  CheckDoubles(LDoubles);
end;

// The doubles come from Sin of an Extended and a quotient kept in the 64 bits of mantissa of the x87 FPU. At 32 bit
// the hash of their bytes is the golden file (made by the old code). At 64 bit (SSE, 53 bits) the same chain of
// operations gives numbers a few ULPs away, and a sine that the C library rounds in another way is the same: the
// values are compared one by one with the ones that the 32 bit run wrote (scale.doubles.golden.txt, hex of the bits)
// and may be at most 1E-12 apart in relative terms, which is far under the effect of a wrong formula
procedure TTestImagingWallScale.CheckDoubles(const ADoubles: TBytes);
{$IF SizeOf(Extended) = SizeOf(Double)}
var
  LExpected: TStringList;
  LIndex: Integer;
  LValue: Double;
  LBits: UInt64;
  LExpectedValue: Double;
begin
  LExpected := TImagingGolden.Load('scale.doubles.golden.txt');
  try
    Assert.AreEqual<Integer>(Length(ADoubles) div 8, LExpected.Count, 'number of values');
    for LIndex := 0 to LExpected.Count - 1 do
    begin
      Move(ADoubles[LIndex * 8], LValue, 8);
      LBits := StrToUInt64('$' + LExpected[LIndex]);
      Move(LBits, LExpectedValue, 8);
      if LValue <> LExpectedValue then
        Assert.IsTrue(Abs(LValue - LExpectedValue) <= 1E-12 * Abs(LExpectedValue),
          Format('value %d: %.17g and %.17g', [LIndex, LExpectedValue, LValue]));
    end;
  finally
    LExpected.Free;
  end;
end;
{$ELSE}
var
  LPath: string;
  LList: TStringList;
  LIndex: Integer;
  LBits: UInt64;
begin
  LPath := GetEnvironmentVariable('DELPHIDOOM_IMAGING_SCALE_DOUBLES_OUT');
  if LPath <> '' then
  begin
    LList := TStringList.Create;
    try
      for LIndex := 0 to Length(ADoubles) div 8 - 1 do
      begin
        Move(ADoubles[LIndex * 8], LBits, 8);
        LList.Add(IntToHex(LBits, 16));
      end;
      LList.SaveToFile(LPath);
    finally
      LList.Free;
    end;
  end;
  TImagingGolden.Check('scale.golden.txt', 'scale_doubles', TImagingSamples.Hex(TImagingSamples.Hash(ADoubles)));
end;
{$IFEND}

procedure TTestImagingWallScale.TestFixedScaleIsTheQuotientOfProjectionAndDistance;
begin
  // with a sine of 1 the numerator is the projection and the denominator the distance
  Assert.AreEqual(32768,
    ScaleWith(65536).FromGlobalAngleFixed(Context(320 * 65536, 160 * 65536, 64 * 65536, True), 0),
    'dovrebbe dare 0,5 per proiezione 160 e distanza 320');
end;

procedure TTestImagingWallScale.TestScaleBelowTheMinimumGives256AndOverflows;
var
  LOverflow: Boolean;
begin
  Assert.AreEqual(256, ScaleWith(65536).FromGlobalAngle(Context(10 * 65536, 1, 64 * 65536, True), 0, LOverflow),
    'dovrebbe dare il minimo 256');
  Assert.IsTrue(LOverflow, 'dovrebbe segnalare l''overflow');
end;

procedure TTestImagingWallScale.TestScaleAboveTheMaximumGivesTheMaximumAndOverflows;
var
  LOverflow: Boolean;
begin
  Assert.AreEqual(10 * 65536, ScaleWith(65536).FromGlobalAngle(Context(3 * 65536, 160 * 65536, 10 * 65536, True), 0, LOverflow),
    'dovrebbe dare il massimo del contesto');
  Assert.IsTrue(LOverflow, 'dovrebbe segnalare l''overflow');
end;

procedure TTestImagingWallScale.TestNoOverflowFlagWhenNotPrecise;
var
  LOverflow: Boolean;
begin
  ScaleWith(65536).FromGlobalAngle(Context(3 * 65536, 160 * 65536, 10 * 65536, False), 0, LOverflow);
  Assert.IsFalse(LOverflow, 'non dovrebbe segnalare l''overflow se non e'' preciso');
end;

procedure TTestImagingWallScale.TestCloseWallGivesTheMaximum;
var
  LOverflow: Boolean;
begin
  Assert.AreEqual(64 * 65536, ScaleWith(65536).FromGlobalAngle(Context(100, 160 * 65536, 64 * 65536, True), 0, LOverflow),
    'dovrebbe dare il massimo per un muro vicinissimo');
  Assert.IsTrue(LOverflow, 'dovrebbe segnalare l''overflow');
end;

procedure TTestImagingWallScale.TestFixedAndFlaggedScalesAgree;
var
  LScale: IImagingWallScale;
  LContext: TImagingScaleContext;
  LOverflow: Boolean;
  LAngle: Cardinal;
begin
  LScale := TImagingFactory.CreateWallScale;
  LContext := Context(200 * 65536, 200 * 65536, 64 * 65536, True);
  LContext.ViewAngle := $20000000;
  LContext.NormalAngle := $10000000;
  LAngle := $30000000;
  while LAngle < $60000000 do
  begin
    Assert.AreEqual(LScale.FromGlobalAngleFixed(LContext, LAngle), LScale.FromGlobalAngle(LContext, LAngle, LOverflow),
      'dovrebbe dare lo stesso valore con e senza il segnale, angolo ' + IntToHex(LAngle, 8));
    LAngle := LAngle + $01000000;
  end;
end;

procedure TTestImagingWallScale.TestDoubleScaleWithZeroDenominatorGivesTheMaximum;
var
  LContext: TImagingScaleContext;
begin
  LContext := Context(100 * 65536, 160 * 65536, 64 * 65536, True);
  // the angle of the denominator is 0: the visible angle is 90 degrees before the view
  LContext.ViewAngle := $40000000;
  LContext.NormalAngle := 0;
  Assert.AreEqual(Double(64 * 65536), TImagingFactory.CreateWallScale.FromGlobalAngleDouble(LContext, 0),
    'dovrebbe dare il massimo con denominatore zero');
end;

procedure TTestImagingWallScale.TestDoubleScaleWithZeroDenominatorAndNegativeNumeratorGivesTheMinimum;
var
  LContext: TImagingScaleContext;
begin
  LContext := Context(100 * 65536, 160 * 65536, 64 * 65536, True);
  LContext.ViewAngle := $40000000;
  // the angle of the numerator is 270 degrees: the sine is negative
  LContext.NormalAngle := $80000000;
  Assert.AreEqual(Double(256), TImagingFactory.CreateWallScale.FromGlobalAngleDouble(LContext, 0),
    'dovrebbe dare il minimo con numeratore negativo');
end;

procedure TTestImagingWallScale.TestDoubleScaleIsLimited;
var
  LContext: TImagingScaleContext;
  LValue: Double;
begin
  LContext := Context(65536, 160 * 65536, 4 * 65536, True);
  LContext.ViewAngle := $10000000;
  LContext.NormalAngle := $30000000;
  LValue := TImagingFactory.CreateWallScale.FromGlobalAngleDouble(LContext, $20000000);
  Assert.IsTrue((LValue >= 256) and (LValue <= 4 * 65536), 'dovrebbe stare fra il minimo e il massimo');
end;

procedure TTestImagingWallScale.TestSineIndexOutOfTheTableIsNotRead;
begin
  // the angles are shifted by 16 bits: the index is always inside of the 65536 entries
  Assert.WillNotRaise(
    procedure
    var
      LOverflow: Boolean;
    begin
      TImagingFactory.CreateWallScale.FromGlobalAngle(Context(65536, 65536, 65536, True), $FFFFFFFF, LOverflow);
    end, EImagingException, 'non dovrebbe leggere fuori dalla tabella');
end;

end.
